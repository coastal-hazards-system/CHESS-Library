function [Dn50_SS, Dn50_LS] = ann_rubblemound_stability(Hs, Tm, Tm10, d, Rc, duration, hc, B, cot_a, cot_b, tan_m, P, gamma_f, S_SS, S_LS, delta, g)
% chess.Equations.ann_rubblemound_stability  Rubblemound armor stone size from the ANNs.
%   [Dn50_SS, Dn50_LS] = chess.Equations.ann_rubblemound_stability(Hs, Tm, Tm10, d, Rc,
%       duration, hc, B, cot_a, cot_b, tan_m, P, gamma_f, S_SS, S_LS,
%       delta, g) returns the seaside and leeside median nominal armor
%       stone diameters that reach the design damage levels S_SS and S_LS.
%
%   Component-stability artificial neural networks of J. A. Melby
%   (trained 2026-10-29 on the full Scaravaglione et al. 2026 + DELOS data
%   set, screened 0.2 < S < 2*Smax: 1338 seaside / 200 leeside
%   observations). Each network returns the stability number Ns and
%   Dn50 = Hs/Ns/delta. The networks run without the Deep Learning
%   Toolbox from plain weights exported once (2026-10-30) from the trained
%   dlnetworks (ann_weights_Ns_component_GS_seaside_full_data_screened_SS.mat
%   and _LS.mat in this folder; each file also holds X_test/Y_test from
%   the toolbox predict). Architecture (both): feature input with z-score
%   normalization (Mean, StandardDeviation) -> fully connected (32) ->
%   ReLU -> dropout (inactive at prediction) -> fully connected (16) ->
%   ReLU -> fully connected (1) -> softplus log(1 + exp(x)) = Ns.
%
%   Predictors (network input order):
%     Seaside (10): [P, cot_a, tan_m, gamma_f, Nwaves, hc/Hs, Rc/Hs, s_om,
%                   Hs/d, S_SS]
%     Leeside (12): [P, cot_a, cot_b, tan_m, gamma_f, Nwaves, B/Hs, hc/Hs,
%                   Rc/Hs, s_om, Hs/d, S_LS]
%     Nwaves = duration/Tm, s_om = Hs/(g*Tm^2/(2*pi)).
%   Periods: Tm for the number of waves Nwaves and the steepness s_om;
%   Tm10 for the run-up z1p and crest velocity u1p of the validity rules.
%
%   Validity rules (chess.Equations.stone_size_validity, the same rules as
%   chess.Equations.legacy_rubblemound_stability), each gives NaN:
%     Both sides: Hs <= 0.1 m; dry toe d <= 0.
%     Seaside: Rc/Dn50_SS < 1 (also where Rc < 0: the ANN has no
%              submerged correction).
%     Leeside (Van Gent and Pozueta 2004): z1p - Rc < 0; u1p <= 0;
%              Rc <= 0; Rc/Hs outside [0.3, 6] (z1p and u1p with Tm10).
%   The ANN training ranges are not applied.
%
%   Inputs (arrays of any sizes compatible with implicit expansion, e.g.
%   nT x nReps forcing, nT x 1 durations and scalar structure properties;
%   g scalar):
%     Hs       - spectral significant wave height at the toe (Hm0) [m]
%     Tm       - mean wave period [s] (CHESS: period_from_peak(Tp, 'mean'))
%     Tm10     - spectral wave period T_m-1,0 [s] (CHESS: period_from_peak(Tp, 'spectral'))
%     d        - water depth at the toe, SWL - toe elevation [m]
%     Rc       - freeboard, crest elevation - SWL [m]
%     duration - storm duration for the number of waves [s] (CHESS: the
%                event length storm_duration, never dt)
%     hc       - crest height above the toe, crest - toe elevation [m]
%     B        - crest width [m]
%     cot_a    - seaside slope cot(alpha) [-]
%     cot_b    - leeside slope cot(beta) [-]
%     tan_m    - nearshore approach slope tan(m) [-] (CHESS: 1/nearshore_slope)
%     P        - notional permeability [-]
%     gamma_f  - roughness influence factor [-]
%     S_SS     - seaside design damage level [-]
%     S_LS     - leeside design damage level [-]
%     delta    - armor relative buoyant density [-]
%     g        - gravitational acceleration [m/s^2], scalar
%   Outputs (size of the expanded inputs):
%     Dn50_SS  - seaside median nominal stone diameter [m] (NaN outside
%                the validity rules)
%     Dn50_LS  - leeside median nominal stone diameter [m] (NaN outside
%                the validity rules)
%
%   See also chess.Equations.stone_size_validity, chess.Equations.legacy_rubblemound_stability,
%   chess.Equations.z1p_calc, chess.ProtectionSystem.RubbleMound.
%
%   Developed by: Jeffrey A. Melby (networks); Fabian A. Garcia Moreno (port)

%% LOAD NETWORKS (ONCE)
persistent net
if isempty(net)
    ann_dir = fileparts(mfilename('fullpath'));
    net.SS = load(fullfile(ann_dir, 'ann_weights_Ns_component_GS_seaside_full_data_screened_SS.mat'), 'layers');
    net.LS = load(fullfile(ann_dir, 'ann_weights_Ns_component_GS_seaside_full_data_screened_LS.mat'), 'layers');
end

%% VECTORIZE INPUTS
% Common Size Of The Inputs
dims = size(Hs + Tm + Tm10 + d + Rc + duration + hc + B + cot_a + cot_b + tan_m + P + gamma_f + S_SS + S_LS + delta);
row = @(x) reshape(x + zeros(dims), 1, []);
Hs = row(Hs);
Tm = row(Tm);
Tm10 = row(Tm10);
d = row(d);
Rc = row(Rc);
duration = row(duration);
Nwaves = duration./Tm;
hc = row(hc);
B = row(B);
cot_a = row(cot_a);
cot_b = row(cot_b);
tan_m = row(tan_m);
P = row(P);
gamma_f = row(gamma_f);
S_SS = row(S_SS);
S_LS = row(S_LS);
delta = row(delta);
% Deep Water Wave Steepness (Mean Period)
s_om = Hs./(g.*Tm.^2./(2*pi));

%% PREDICTORS
X_SS = [P; cot_a; tan_m; gamma_f; Nwaves; hc./Hs; Rc./Hs; s_om; Hs./d; S_SS];
X_LS = [P; cot_a; cot_b; tan_m; gamma_f; Nwaves; B./Hs; hc./Hs; Rc./Hs; s_om; Hs./d; S_LS];

%% STONE SIZE
Dn50_SS = Hs./ann_forward(net.SS.layers, X_SS)./delta;
Dn50_LS = Hs./ann_forward(net.LS.layers, X_LS)./delta;

%% VALIDITY RULES
[invalid_SS, invalid_LS] = chess.Equations.stone_size_validity(Dn50_SS, Dn50_LS, Hs, Tm, Tm10, d, Rc, duration, B, cot_a,...
    cot_b, delta, g, 0);
Dn50_SS(invalid_SS) = NaN;
Dn50_LS(invalid_LS) = NaN;
Dn50_SS = reshape(Dn50_SS, dims);
Dn50_LS = reshape(Dn50_LS, dims);
end

function y = ann_forward(layers, X)
% Plain Forward Pass Of An Exported Network (Predictors x Samples -> 1 x Samples)
y = X;
for kk = 1:numel(layers)
    L = layers{kk};
    switch char(L.Class)
        case 'nnet.cnn.layer.FeatureInputLayer' % Z-Score Normalization
            y = (y - L.Mean(:))./L.StandardDeviation(:);
        case 'nnet.cnn.layer.FullyConnectedLayer'
            y = L.Weights*y + L.Bias;
        case 'nnet.cnn.layer.ReLULayer' % NaN Kept (max Would Drop It)
            y(y < 0) = 0;
        case 'nnet.cnn.layer.DropoutLayer' % Inactive At Prediction
        case 'rl.layer.SoftplusLayer'
            y = log1p(exp(y));
        otherwise
            error('chess:Equations:ann_rubblemound_stability:unknownLayer', 'Unsupported network layer class "%s".', char(L.Class));
    end
end
end

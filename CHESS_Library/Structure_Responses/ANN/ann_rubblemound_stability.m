function [Dn50_SS, Dn50_LS] = ann_rubblemound_stability(Hs, Tm, Tm10, d, Rc, duration, hc, B, cot_a, cot_b, tan_m, P, gamma_f, S_SS, S_LS, delta, g)
% ann_rubblemound_stability  Rubblemound armor stone size from the ANNs.
%   [Dn50_SS, Dn50_LS] = ann_rubblemound_stability(Hs, Tm, Tm10, d, Rc,
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
%   Cut-offs (only these): Hs < 0.1 m gives NaN on both sides; no
%   overtopping (z1p - Rc < 0, z1p_calc with Tm10) gives Dn50_LS = 0.
%   Training ranges (not enforced, for reference only):
%     Seaside: P 0.1-0.64, cot_a 1.5-6, tan_m 0-0.05, gamma_f 0.55-1,
%              Nwaves 698-9456, hc/Hs 1.2-59, Rc/Hs -6.7-44,
%              s_om 5e-4-0.07, Hs/d 0.038-1.1
%     Leeside: P 0.4-0.64, cot_a 1.5-3, cot_b 1.25-2, tan_m 0-0.05,
%              gamma_f 0.56-0.91, Nwaves 972-9456, B/Hs 0.4-7,
%              hc/Hs 1.2-12, Rc/Hs -0.87-3.4, s_om 6e-3-0.06,
%              Hs/d 0.08-0.79
%
%   Inputs (arrays of any sizes compatible with implicit expansion, e.g.
%   nT x nReps forcing, nT x 1 durations and scalar structure properties;
%   g scalar):
%     Hs       - spectral significant wave height at the toe (Hm0) [m]
%     Tm       - mean wave period [s] (CHESS: Tp/1.2)
%     Tm10     - spectral wave period T_m-1,0 [s] (CHESS: Tp/1.1)
%     d        - water depth at the toe, SWL - toe elevation [m]
%     Rc       - freeboard, crest elevation - SWL [m]
%     duration - storm duration for the number of waves [s] (CHESS: the
%                event length storm_duration, never dt)
%     hc       - crest height above the toe, crest - toe elevation [m]
%     B        - crest width [m]
%     cot_a    - seaside slope cot(alpha) [-]
%     cot_b    - leeside slope cot(beta) [-]
%     tan_m    - offshore (approach) slope tan(m) [-]
%     P        - notional permeability [-]
%     gamma_f  - roughness influence factor [-]
%     S_SS     - seaside design damage level [-]
%     S_LS     - leeside design damage level [-]
%     delta    - armor relative buoyant density [-]
%     g        - gravitational acceleration [m/s^2], scalar
%   Outputs (size of the expanded inputs):
%     Dn50_SS  - seaside median nominal stone diameter [m]
%     Dn50_LS  - leeside median nominal stone diameter [m]
%
%   Tier: public
%
%   See also z1p_calc, compute_structure_response.
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
Nwaves = row(duration)./Tm;
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
% Very Small Waves: No Stone Size
Hs(Hs < 0.1) = NaN;
% Deep Water Wave Steepness (Mean Period)
s_om = Hs./(g.*Tm.^2./(2*pi));

%% PREDICTORS
X_SS = [P; cot_a; tan_m; gamma_f; Nwaves; hc./Hs; Rc./Hs; s_om; Hs./d; S_SS];
X_LS = [P; cot_a; cot_b; tan_m; gamma_f; Nwaves; B./Hs; hc./Hs; Rc./Hs; s_om; Hs./d; S_LS];

%% STONE SIZE
Dn50_SS = reshape(Hs./ann_forward(net.SS.layers, X_SS)./delta, dims);
Dn50_LS = Hs./ann_forward(net.LS.layers, X_LS)./delta;
% No Overtopping (Run-Up Exceeded By 1% Of The Waves Below The Crest): No Leeside Damage
z1p = z1p_calc(Hs, Tm10, Rc, cot_a, g);
Dn50_LS((z1p - Rc) < 0) = 0;
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
            error('ann_rubblemound_stability:unknownLayer', 'Unsupported network layer class "%s".', char(L.Class));
    end
end
end

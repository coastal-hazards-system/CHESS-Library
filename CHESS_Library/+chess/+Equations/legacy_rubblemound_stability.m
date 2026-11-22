function [Dn50_SS, Dn50_LS] = legacy_rubblemound_stability(Hs, Tm, Tm10, d, Rc, duration, hc, B, cot_a, cot_b, tan_m, P, gamma_f, S_SS, S_LS, delta, g, Tp, km1, km2, K_ls1, K_ls2, submerged_correction)
% chess.Equations.legacy_rubblemound_stability  Rubblemound armor stone size from the legacy equations.
%   [Dn50_SS, Dn50_LS] = chess.Equations.legacy_rubblemound_stability(Hs, Tm, Tm10, d,
%       Rc, duration, hc, B, cot_a, cot_b, tan_m, P, gamma_f, S_SS, S_LS,
%       delta, g, Tp, km1, km2, K_ls1, K_ls2, submerged_correction) returns
%       the seaside and leeside median nominal armor stone diameters that
%       reach the design damage levels S_SS and S_LS. The first 17 inputs
%       are those of chess.Equations.ann_rubblemound_stability, in the same
%       order. Used by chess.ProtectionSystem.RubbleMound.stone_sizes when
%       dn50_use_legacy_model = 1.
%
%   Seaside: Melby momentum-flux stability
%     (chess.Equations.melby_Dn50_seaside_stability with Tm, d, Nz =
%     duration/Tm, km1, km2).
%   Leeside: Van Gent overtopped-crest stability
%     (chess.Equations.van_gent_Dn50_leeside_stability with run-up z1p and
%     crest velocity u1p from Tm10, Nz = duration/Tm, K_ls1, K_ls2).
%   Submerged crest correction (submerged_correction = 1, both sides):
%     chess.Equations.submerged_stone_armor_stability (van der Meer and
%     Daemen 1994, with Tp and hc) replaces the stone size where Rc < 0.
%   Periods: Tm for Nz and the steepness s_om; Tm10 for z1p and u1p; Tp
%   for the submerged correction only.
%
%   Validity rules, each gives NaN:
%     Equation rules (kept):
%       Melby: Hs <= 0.1 m, d <= 0, Rc/Dn50_SS < 1.
%       Van Gent: z1p - Rc < 0, u1p <= 0, Rc <= 0.
%       Submerged correction: Hs <= 0.1 m, d <= 0 (where it replaces
%       Rc < 0).
%     With submerged_correction = 1 the corrected values replace the
%     equation values (NaN included) where Rc < 0; Rc = 0 stays NaN on
%     the leeside (Van Gent Rc <= 0).
%     Then on the final values, chess.Equations.stone_size_validity (the
%     same rules as chess.Equations.ann_rubblemound_stability):
%       Both sides: Hs <= 0.1 m; dry toe d <= 0.
%       Seaside: Rc/Dn50_SS < 1.
%       Leeside (Van Gent and Pozueta 2004): z1p - Rc < 0; u1p <= 0;
%                Rc <= 0; Rc/Hs outside [0.3, 6].
%       With submerged_correction = 1 the seaside and leeside rules apply
%       only where Rc >= 0 (the submerged stone size governs Rc < 0).
%
%   Inputs (Hs, Tm, Tm10, d, Rc, duration, Tp and gamma_f of sizes
%   compatible with implicit expansion, e.g. nT x nReps forcing and nT x 1
%   durations; the structure properties hc, B, cot_a, cot_b, tan_m, P,
%   S_SS, S_LS, delta, the coefficients and g scalars):
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
%     tan_m    - nearshore approach slope tan(m) [-] (CHESS:
%                1/nearshore_slope; not used, kept for the input order
%                shared with chess.Equations.ann_rubblemound_stability)
%     P        - notional permeability [-]
%     gamma_f  - roughness influence factor [-] (passed to the Van Gent
%                leeside equation, which does not use it)
%     S_SS     - seaside design damage level [-]
%     S_LS     - leeside design damage level [-]
%     delta    - armor relative buoyant density [-]
%     g        - gravitational acceleration [m/s^2]
%     Tp       - peak wave period [s] (submerged correction)
%     km1      - Melby plunging empirical coefficient [-]
%     km2      - Melby surging empirical coefficient [-]
%     K_ls1    - Van Gent leeside empirical coefficient 1 [-]
%     K_ls2    - Van Gent leeside empirical coefficient 2 [-]
%     submerged_correction - 1 = submerged crest correction on, 0 = off
%   Outputs (size of the expanded inputs):
%     Dn50_SS  - seaside median nominal stone diameter [m]
%     Dn50_LS  - leeside median nominal stone diameter [m]
%
%   See also chess.Equations.melby_Dn50_seaside_stability, chess.Equations.van_gent_Dn50_leeside_stability,
%   chess.Equations.submerged_stone_armor_stability, chess.Equations.stone_size_validity,
%   chess.Equations.ann_rubblemound_stability, chess.ProtectionSystem.RubbleMound.

%% VECTORIZE INPUTS
% The Equations Flatten The Forcing But Not The Duration: Every Forcing Input As One Column Of The Common Size
dims = size(Hs + Tm + Tm10 + d + Rc + duration + Tp + gamma_f);
column = @(x) reshape(x + zeros(dims), [], 1);
Hs = column(Hs);
Tm = column(Tm);
Tm10 = column(Tm10);
d = column(d);
Rc = column(Rc);
duration = column(duration);
Tp = column(Tp);
gamma_f = column(gamma_f);

%% STONE SIZE
Dn50_SS = chess.Equations.melby_Dn50_seaside_stability(Hs, Tm, d, duration, cot_a, delta, P, S_SS, g, km1, km2, Rc);
Dn50_LS = chess.Equations.van_gent_Dn50_leeside_stability(S_LS, Hs, Tm10, Tm, Rc, B, cot_a, cot_b, duration, delta, g,...
    K_ls1, K_ls2, gamma_f);
if submerged_correction == 1
    Dn50_SS = chess.Equations.submerged_stone_armor_stability(Hs, Tp, d, Rc, Dn50_SS, hc, S_SS, delta, g);
    Dn50_LS = chess.Equations.submerged_stone_armor_stability(Hs, Tp, d, Rc, Dn50_LS, hc, S_LS, delta, g);
end

%% VALIDITY RULES
[invalid_SS, invalid_LS] = chess.Equations.stone_size_validity(Dn50_SS, Dn50_LS, Hs, Tm, Tm10, d, Rc, duration, B, cot_a,...
    cot_b, delta, g, submerged_correction);
Dn50_SS(invalid_SS) = NaN;
Dn50_LS(invalid_LS) = NaN;
Dn50_SS = reshape(Dn50_SS, dims);
Dn50_LS = reshape(Dn50_LS, dims);
end

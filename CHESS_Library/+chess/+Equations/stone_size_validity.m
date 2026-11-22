function [invalid_SS, invalid_LS, rule] = stone_size_validity(Dn50_SS, Dn50_LS, Hs, Tm, Tm10, d, Rc, duration, B, cot_a, cot_b, delta, g, submerged_correction)
% chess.Equations.stone_size_validity  Validity rules of the rubblemound armor stone sizes (ANN and legacy).
%   [invalid_SS, invalid_LS, rule] = chess.Equations.stone_size_validity(Dn50_SS, Dn50_LS,
%       Hs, Tm, Tm10, d, Rc, duration, B, cot_a, cot_b, delta, g,
%       submerged_correction) returns where the seaside and leeside stone
%       sizes are outside the validity of the stability models; the callers
%       set those stone sizes to NaN. The one place of these rules, shared
%       by chess.Equations.ann_rubblemound_stability and
%       chess.Equations.legacy_rubblemound_stability (same rules for both).
%
%   Rules (limits are literals in SI units; leeside ranges from Van Gent
%   and Pozueta 2004, ICCE, Table 2 p. 5), each gives NaN:
%     Both sides:
%       (0)  Hs <= 0.1 m; dry toe d <= 0
%     Leeside (rear side, Van Gent and Pozueta 2004):
%       (1)  no overtopping: z1p - Rc < 0
%       (2)  no crest velocity: u1p <= 0
%       (3)  crest not emergent: Rc <= 0
%       (4)  Nz = duration/Tm >= 4000                  (not applied)
%       (5)  Rc/Hs outside [0.3, 6]
%       (6)  Hs/(delta*Dn50_LS) outside [5.5, 8.5]    (not applied)
%       (7)  (z1p - Rc)/(gamma_f*Hs) outside [0, 1.4], gamma_f the rock
%            roughness factor of the run-up
%            (chess.Equations.rock_roughness_influence_factor) (not applied:
%            too restrictive for now)
%       (8)  B/Hs outside [1.3, 1.6]                  (not applied)
%       (9)  s_m-1,0 = Hs/(g*Tm10^2/(2*pi)) outside [0.019, 0.036]
%                                                     (not applied)
%       (10) leeside slope cot_b outside [2, 4]       (not applied)
%     Seaside:
%       (11) Rc/Dn50_SS < 1
%   z1p from chess.Equations.z1p_calc and u1p from chess.Equations.u1p_calc
%   (Tm10, seaside slope cot_a). Rules marked "not applied" are the test
%   ranges of the paper; they stay in the code, commented out.
%   With submerged_correction = 1 (legacy submerged crest correction) the
%   submerged stone size governs Rc < 0 on both sides: rules (1)-(11) apply
%   only where Rc >= 0. With submerged_correction = 0 (ANN, or legacy
%   without the correction) they apply everywhere.
%
%   Inputs (arrays of any sizes compatible with implicit expansion; g
%   scalar):
%     Dn50_SS  - seaside stone size the rules are checked against [m]
%     Dn50_LS  - leeside stone size [m] (rule 6, not applied)
%     Hs       - spectral significant wave height at the toe (Hm0) [m]
%     Tm       - mean wave period [s] (rule 4, not applied)
%     Tm10     - spectral wave period T_m-1,0 [s]
%     d        - water depth at the toe, SWL - toe elevation [m]
%     Rc       - freeboard, crest elevation - SWL [m]
%     duration - storm duration for the number of waves [s] (rule 4, not
%                applied)
%     B        - crest width [m]
%     cot_a    - seaside slope cot(alpha) [-]
%     cot_b    - leeside slope cot(beta) [-] (rule 10, not applied)
%     delta    - armor relative buoyant density [-] (rule 6, not applied)
%     g        - gravitational acceleration [m/s^2], scalar
%     submerged_correction - 1 = the legacy submerged stone size replaces
%                Rc < 0 (rules (1)-(11) apply to Rc >= 0 only); 0 = the
%                rules apply everywhere
%   Outputs (logical, size of the expanded inputs):
%     invalid_SS - true where the seaside stone size is NaN
%     invalid_LS - true where the leeside stone size is NaN
%     rule       - struct of one logical mask per applied rule:
%                  small_wave (0), dry_toe (0), leeside_no_overtopping (1),
%                  leeside_no_crest_velocity (2),
%                  leeside_crest_not_emergent (3),
%                  leeside_freeboard_ratio (5),
%                  seaside_low_freeboard (11)
%
%   See also chess.Equations.ann_rubblemound_stability, chess.Equations.legacy_rubblemound_stability,
%   chess.Equations.z1p_calc, chess.Equations.u1p_calc, chess.Equations.rock_roughness_influence_factor.

dims = size(Dn50_SS + Dn50_LS + Hs + Tm + Tm10 + d + Rc + duration + B + cot_a + cot_b + delta);
expand = @(x) x + zeros(dims);
Hs = expand(Hs);
Tm10 = expand(Tm10);
Rc = expand(Rc);
B = expand(B);
cot_a = expand(cot_a);

z1p = chess.Equations.z1p_calc(Hs, Tm10, Rc, cot_a, g);
u1p = chess.Equations.u1p_calc(B, Rc, z1p, Tm10, Hs, cot_a, g);
% (7) gamma_f = chess.Equations.rock_roughness_influence_factor(Hs, Tm10, cot_a, g);
% (7) relative_runup = (z1p - Rc)./(gamma_f.*Hs);

rules_apply = true(dims);
if submerged_correction == 1
    rules_apply = Rc >= 0;
end

rule.small_wave = Hs <= 0.1;
rule.dry_toe = expand(d) <= 0;
rule.leeside_no_overtopping = rules_apply & z1p - Rc < 0;
rule.leeside_no_crest_velocity = rules_apply & u1p <= 0;
rule.leeside_crest_not_emergent = rules_apply & Rc <= 0;
% (4) rule.leeside_number_of_waves = rules_apply & duration./Tm >= 4000;
rule.leeside_freeboard_ratio = rules_apply & (Rc./Hs < 0.3 | Rc./Hs > 6);
% (6) rule.leeside_stability_number = rules_apply & (Hs./(delta.*Dn50_LS) < 5.5 | Hs./(delta.*Dn50_LS) > 8.5);
% (7) rule.leeside_relative_runup = rules_apply & (relative_runup < 0 | relative_runup > 1.4);
% (8) rule.leeside_crest_width_ratio = rules_apply & (B./Hs < 1.3 | B./Hs > 1.6);
% (9) rule.leeside_wave_steepness = rules_apply & (Hs./(g.*Tm10.^2./(2*pi)) < 0.019 | Hs./(g.*Tm10.^2./(2*pi)) > 0.036);
% (10) rule.leeside_slope = rules_apply & (cot_b < 2 | cot_b > 4);
rule.seaside_low_freeboard = rules_apply & Rc./expand(Dn50_SS) < 1;

no_waves = rule.small_wave | rule.dry_toe;
invalid_SS = no_waves | rule.seaside_low_freeboard;
invalid_LS = no_waves | rule.leeside_no_overtopping | rule.leeside_no_crest_velocity | rule.leeside_crest_not_emergent |...
    rule.leeside_freeboard_ratio;
end

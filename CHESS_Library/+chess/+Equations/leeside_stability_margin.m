function G_ls = leeside_stability_margin(Hm0, Tm10, h, Nz, structure_height, crest_width, leeside_slope, seaside_slope, Dn_ls, armor_delta, S_ls, k_ls1, k_ls2, g)
% leeside_stability_margin  Leeside armor stability limit state (resistance - loading).
%   G_ls = chess.Equations.leeside_stability_margin(Hm0, Tm10, h, Nz,
%       structure_height, crest_width, leeside_slope, seaside_slope, Dn_ls,
%       armor_delta, S_ls, k_ls1, k_ls2, g)
%
%   Leeside (rear-side) stability limit state of a rubble mound for each
%   storm (Van Gent and Pozueta 2004; Melby 2009): G_ls = R_ls - F_ls, with
%   the resistance R_ls = sqrt(armor_delta)*Dn_ls*S_ls^(1/6)/a_ls and the
%   loading F_ls = k_ls2^(1/6)*Nz^(1/12)*u1p*Tm10/k_ls1. The leeside slope
%   enters only through a_ls (chess.Equations.van_gent_leeside_slope_factor,
%   r = 6, freeboard Rc = structure_height - h). The run-up z1% and the
%   crest velocity u1% are those of the seaward slope
%   (chess.Equations.z1p_calc and chess.Equations.u1p_calc with
%   seaside_slope): z1p = 0 where Rc < 0.6 m, and u1p = 0 where there is no
%   run-up, where the run-up stays below the crest (z1p < Rc) and where
%   Rc/Hm0 < 0.3. G_ls < 0 is a failure. Dry toe (h <= 0): G_ls = NaN (no
%   wave attack, not a failure).
%
%   Inputs:
%     Hm0              - significant wave height at the toe [m], column
%     Tm10             - spectral wave period T_m-1,0 [s], same size as Hm0
%     h                - water depth at the toe [m], same size as Hm0
%     Nz               - number of waves of the storm [-], same size as Hm0
%     structure_height - crest elevation above the toe [m], scalar double
%     crest_width      - crest width [m]
%     leeside_slope    - leeside slope (cot) [-], used only in a_ls
%     seaside_slope    - seaward slope (cot) [-], for the run-up z1% and
%                        the crest velocity u1%
%     Dn_ls            - leeside nominal stone diameter [m]
%     armor_delta      - relative buoyant density of the armor stone [-]
%     S_ls             - leeside design damage [-]
%     k_ls1, k_ls2     - leeside empirical coefficients [-]
%     g                - gravity [m/s^2]
%   Outputs:
%     G_ls - stability margin, same size as Hm0 (NaN where h <= 0)
%
%   See also chess.Equations.seaside_stability_margin,
%   chess.Equations.z1p_calc, chess.Equations.u1p_calc,
%   chess.Equations.van_gent_leeside_slope_factor,
%   chess.ProtectionSystem.RubbleMound.

% Dry Toe: NaN Margin
h(h<=0) = NaN;
r = 6;
Rc_ls = structure_height-h;
a_ls = chess.Equations.van_gent_leeside_slope_factor(leeside_slope, Rc_ls, Hm0, r);
R_ls = (sqrt(armor_delta).*Dn_ls.*S_ls.^(1/6))./a_ls;
z1p = chess.Equations.z1p_calc(Hm0, Tm10, Rc_ls, seaside_slope, g);
u1p = chess.Equations.u1p_calc(crest_width, Rc_ls, z1p, Tm10, Hm0, seaside_slope, g);
F_ls = k_ls2.^(1/6).*Nz.^(1/12).*(u1p.*Tm10./k_ls1);
G_ls = R_ls-F_ls;
end

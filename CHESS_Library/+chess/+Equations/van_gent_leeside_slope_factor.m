function a_ls = van_gent_leeside_slope_factor(leeside_slope, Rc, Hm0, r)
% chess.Equations.van_gent_leeside_slope_factor  Leeside slope and freeboard factor of the Van Gent and Pozueta leeside stability (single source).
%   a_ls = chess.Equations.van_gent_leeside_slope_factor(leeside_slope, Rc, Hm0, r)
%   returns, element-wise,
%     a_ls = leeside_slope^(-2.5/r)*(1 + 10*exp(-Rc/Hm0))^(1/r)
%
%   Inputs:
%     leeside_slope - leeside slope cot(alpha) [-], scalar double
%     Rc            - freeboard, crest elevation - SWL [m], double scalar
%                     or array
%     Hm0           - spectral significant wave height at the toe [m],
%                     same size as Rc (or scalar)
%     r             - exponent [-], scalar double (6 for the stability and
%                     the first damage, 1 for the damage progression)
%   Outputs:
%     a_ls - leeside slope factor [-], size of Rc and Hm0 combined
%
%   See also chess.Equations.van_gent_Dn50_leeside_stability,
%   chess.Equations.leeside_armor_stone_damage,
%   chess.Equations.leeside_stability_margin.
%
%   Developed by: Jeffrey A. Melby (JAM)

a_ls = leeside_slope.^(-2.5/r).*(1+10*exp(-1*Rc./Hm0)).^(1/r);
end

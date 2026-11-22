function [Mf, A0, A1] = melby_momentum_flux(Hm0, h, Tm, g)
% chess.Equations.melby_momentum_flux  Wave momentum flux parameter of Melby and Kobayashi (single source).
%   [Mf, A0, A1] = chess.Equations.melby_momentum_flux(Hm0, h, Tm, g)
%   returns the depth-limited wave momentum flux parameter used by the
%   seaside armor stability and damage equations, element-wise:
%     A0 = 0.639*(Hm0/h)^2.026
%     A1 = 0.180*(Hm0/h)^(-0.391)
%     Mf = A0*(h/g/Tm^2)^(-A1)
%
%   Inputs:
%     Hm0 - spectral significant wave height at the toe [m], double scalar
%           or array
%     h   - water depth at the toe [m], same size as Hm0 (or scalar)
%     Tm  - mean wave period [s], same size as Hm0 (or scalar)
%     g   - acceleration of gravity [m/s^2], scalar double
%   Outputs:
%     Mf - momentum flux parameter [-], size of Hm0
%     A0 - Fourier solution coefficient [-], size of Hm0
%     A1 - Fourier solution exponent [-], size of Hm0
%
%   See also chess.Equations.melby_Dn50_seaside_stability,
%   chess.Equations.seaside_armor_stone_damage,
%   chess.Equations.seaside_stability_margin.
%
%   Developed by: Jeffrey A. Melby (JAM)

A0 = 0.639.*(Hm0./h).^2.026;
A1 = 0.180.*(Hm0./h).^-0.391;
Mf = A0.*(h./g./Tm.^2).^-A1;
end

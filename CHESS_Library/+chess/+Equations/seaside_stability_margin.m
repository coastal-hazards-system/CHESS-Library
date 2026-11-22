function G_ss = seaside_stability_margin(Hm0, Tm, h, Nz, Dn_ss, armor_delta, S_ss, cem_P, seaside_slope, km1, k_ss, g)
% seaside_stability_margin  Seaside armor stability limit state (resistance - loading).
%   G_ss = chess.Equations.seaside_stability_margin(Hm0, Tm, h, Nz, Dn_ss,
%       armor_delta, S_ss, cem_P, seaside_slope, km1, k_ss, g)
%
%   Seaside stability limit state of a rubble mound for each storm (Melby
%   and Kobayashi 2011, wave momentum flux): G_ss = R_ss - F_ss, with the
%   resistance R_ss = sqrt(armor_delta)*Dn_ss*S_ss^0.2/am and the loading
%   F_ss = h*Nz^0.1*k_ss*sqrt(Mf), with the momentum flux parameter Mf of
%   chess.Equations.melby_momentum_flux. G_ss < 0 is a failure. Dry toe
%   (h <= 0): G_ss = NaN (no wave attack, not a failure).
%
%   Inputs:
%     Hm0           - significant wave height at the toe [m], double array
%     Tm            - mean wave period [s], same size as Hm0
%     h             - water depth at the toe [m], same size as Hm0
%     Nz            - number of waves of the storm [-], same size as Hm0
%     Dn_ss         - seaside nominal stone diameter [m], scalar double
%     armor_delta   - relative buoyant density of the armor stone [-]
%     S_ss          - seaside design damage [-]
%     cem_P         - notional permeability [-]
%     seaside_slope - seaside slope (cot) [-]
%     km1           - plunging stability coefficient [-]
%     k_ss          - seaside damage initiation coefficient [-]
%     g             - gravity [m/s^2]
%   Outputs:
%     G_ss - stability margin, same size as Hm0 (NaN where h <= 0)
%
%   See also chess.Equations.leeside_stability_margin,
%   chess.Equations.melby_momentum_flux, chess.ProtectionSystem.RubbleMound.

% Dry Toe: NaN Margin (Set On The Depth So The Momentum Flux Powers Stay Real)
h(h<=0) = NaN;
% Momentum Flux Parameter (Melby And Kobayashi)
Mf = chess.Equations.melby_momentum_flux(Hm0, h, Tm, g);
% Plunging Waves Coefficient
am = 1./(km1.*(cem_P.^0.18).*sqrt(seaside_slope));
% Compute Response Component
R_ss = (sqrt(armor_delta).*Dn_ss.*(S_ss.^0.2))./am;
% Compute Forcing Component
F_ss = h.*(Nz.^0.1).*k_ss.*(Mf.^0.5);
% Seaside Stability Performance
G_ss = R_ss-F_ss;
end

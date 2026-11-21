function [Hm0, Tp] = floor_wave_height(Hm0, Tp)
% floor_wave_height  Wave height floor with its Wilson peak period (the one place of this rule).
%   [Hm0, Tp] = floor_wave_height(Hm0, Tp)
%
%   Hm0 <= 0.01 m: Hm0 = 0.01 m and Tp = 1.1*3.3*Hm0^0.63 (Wilson wind-sea
%   period of that height, about 0.199 s) on exactly those entries; the
%   other entries and NaN are kept. Used by the storm database curation
%   (curate_storm_forcing) and by PROS after the forcing uncertainty
%   (apply_uncertainty, chess_pros_frequency_base EB2 samples).
%
%   Inputs:
%     Hm0 - significant wave height [m], numeric array
%     Tp  - peak wave period [s], numeric array of the size of Hm0
%   Outputs:
%     Hm0 - floored wave height [m], size of the input
%     Tp  - peak wave period [s], Wilson value where Hm0 was floored
%
%   Tier: internal
%
%   See also curate_storm_forcing, apply_uncertainty,
%   chess_pros_frequency_base.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

floored = Hm0 <= 0.01;
Hm0(floored) = 0.01;
Tp(floored) = 1.1*3.3*Hm0(floored).^0.63;
end

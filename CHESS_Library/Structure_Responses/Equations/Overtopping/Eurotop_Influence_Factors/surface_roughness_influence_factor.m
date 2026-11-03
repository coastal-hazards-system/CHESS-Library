function [gamma_f] = surface_roughness_influence_factor(gamma_f,Hm0)
% surface_roughness_influence_factor  EurOtop surface roughness factor gamma_f.
%   gamma_f = surface_roughness_influence_factor(gamma_f, Hm0) expands the
%       structure roughness factor to the size of Hm0, with the grass rule
%       for small waves.
%
%   gamma_f <= 1: the value is repeated for every forcing row.
%   gamma_f > 1 flags a grass surface (2 in the input file): EurOtop (2018)
%   Eq. 5.23, gamma_f = 1.15*sqrt(Hm0) for Hm0 < 0.75 m, else 1 (also 1
%   where Hm0 is NaN). Roughness values are tabulated in the CEM and in
%   EurOtop; the floodwall overtopping equations do not use gamma_f.
%
%   Inputs:
%     gamma_f - structure roughness influence factor [-], scalar (> 1 for
%               grass)
%     Hm0     - spectral significant wave height at the toe [m]
%   Outputs:
%     gamma_f - roughness influence factor [-], size of Hm0
%
%   Tier: public
%
%   See also Eurotop_r2p_q_Final, berm_influence_factor,
%   oblique_waves_influence_factor, wall_influence_factor.

% Surface roughness coefficient
% Not used in floodwall overtopping equations
% Coefficients are found in CEM and in Eurotop. For levees with grass, the
% surface roughness influence increses for small wave heights.
if gamma_f>1 % 2 denotes grass in input file
    % Use Eurotop equation 5.23 if grass and Hm0 < 0.75 m, otherwise set
    % gamma_f to 1 for grass
    gamma_f = ones(size(Hm0));
    gamma_f(Hm0 < 0.75)= 1.15*Hm0(Hm0 < 0.75).^0.5;
    gamma_f(Hm0 >= 0.75) = 1;
else
    gamma_f = repmat(gamma_f, size(Hm0));
end
end
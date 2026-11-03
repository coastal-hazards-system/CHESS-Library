function [gamma_v,gamma_star] = wall_influence_factor(crest_elevation,toe_elevation,Rc,strucType)
% wall_influence_factor  EurOtop wall influence factors gamma_v and gamma_star.
%   [gamma_v, gamma_star] = wall_influence_factor(crest_elevation,
%       toe_elevation, Rc, strucType) returns the wave wall factors used
%       by the levee overtopping equations of Eurotop_r2p_q_Final.
%
%   strucType 2 (floodwall): gamma_v = gamma_star =
%   exp(-0.56*h_wall/Rc), h_wall = crest_elevation - toe_elevation.
%   Other structure types return ones. Note that the floodwall branch of
%   Eurotop_r2p_q_Final does not apply gamma_v or gamma_star.
%
%   Inputs:
%     crest_elevation - wall crest elevation [m, study datum, positive up],
%                       scalar
%     toe_elevation   - wall toe elevation [m, study datum, positive up],
%                       scalar (CHESS passes the wall bottom elevation for
%                       floodwalls)
%     Rc              - freeboard, crest elevation - SWL [m]
%     strucType       - structure type (1 levee, 2 floodwall, 3 rubble
%                       mound), scalar
%   Outputs (size of Rc):
%     gamma_v         - wall influence factor (Eq. 5.10) [-]
%     gamma_star      - wall influence factor (Eq. 5.11) [-]
%
%   Tier: public
%
%   See also Eurotop_r2p_q_Final, berm_influence_factor,
%   surface_roughness_influence_factor, oblique_waves_influence_factor.

    % Wall influence coefficients
    if strucType== 2 % Floodwall
        h_wall = crest_elevation-toe_elevation;
        % gamma_v and gamma_star are for influence of floodwall on a levee
        gamma_v = exp(-0.56*h_wall./Rc);
        gamma_star = gamma_v;
    else
        gamma_v    = ones(size(Rc));
        gamma_star = ones(size(Rc));
    end
end
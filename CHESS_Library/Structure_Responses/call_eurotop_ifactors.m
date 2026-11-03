function gammas = call_eurotop_ifactors(config, structure, SWL, Hm0)
% call_eurotop_ifactors  EurOtop influence factors of the structure.
%   gammas = call_eurotop_ifactors(config, structure, SWL, Hm0)
%
%   Influence factors for Eurotop_r2p_q_Final (EurOtop 2018) at every
%   forcing row: wall (wall_influence_factor; floodwalls only, from the
%   wall height crest elevation - wall bottom elevation and the freeboard
%   Rc = crest elevation - SWL; 1 otherwise), surface roughness
%   (surface_roughness_influence_factor; roughness_ifactor > 1 means grass,
%   Hm0 dependent), oblique waves (oblique_waves_influence_factor; always
%   1, oblique waves are not implemented) and berm (berm_influence_factor
%   with a toe berm, else 1).
%
%   Inputs:
%     config    - CHESS configuration, 1x1 struct; reads struc_type (1
%                 levee, 2 floodwall, 3 rubble mound) and add_toe_berm
%                 (0/1)
%     structure - structure geometry, 1x1 struct; reads roughness_ifactor
%                 [-], crest_elevation and toe_elevation [m, study datum,
%                 positive up], wall_bottom_elevation (floodwall) and,
%                 with add_toe_berm = 1, berm_crest_elevation [m, study
%                 datum, positive up], berm_crest_width [m] and
%                 berm_seaward_slope (cot) [-]
%     SWL       - still water level [m, study datum, positive up], array
%     Hm0       - spectral significant wave height at the toe [m], size of
%                 SWL
%   Outputs:
%     gammas - influence factors [-], 1x1 struct with fields gamma_v,
%              gamma_star (wall), gamma_f (roughness), gamma_beta_r2p,
%              gamma_beta_q (oblique waves) and gamma_b (berm), each the
%              size of Hm0
%
%   Tier: internal
%
%   See also compute_structure_response, Eurotop_r2p_q_Final,
%   wall_influence_factor, surface_roughness_influence_factor,
%   oblique_waves_influence_factor, berm_influence_factor.

%% GRAB DETAILS FROM "config"
strucType = config.struc_type;
% Surface roughness coefficient
gamma_f = structure.roughness_ifactor;
% Get Berm Logical Flag
add_berm = config.add_toe_berm;

%% GRAB DETAILS FROM "structure"
% Crest Elevation
crest_ele = structure.crest_elevation;
% Toe Elevation
toe_ele = structure.toe_elevation;
if strucType == 2
    % Wall Bottom Elevation
    wall_bottom_elev = structure.wall_bottom_elevation;
else
    wall_bottom_elev = structure.toe_elevation;
end
% Seaward Slope
% seaward_slope = structure.seaside_slope;
% Compute Freeboard
Rc = crest_ele - SWL;

if add_berm
    % Berm Elevation (<0 Below Datum Zero)
    berm_elev = structure.berm_crest_elevation;
    % Berm Width
    berm_width = structure.berm_crest_width;
    % Berm Slope
    berm_slope_tana = 1./structure.berm_seaward_slope;
else
    % Berm Elevation (<0 Below Datum Zero)
    berm_elev = toe_ele; % This Translates to h == hb
    % Berm Width
    berm_width = 0;
    % Berm Slope
    berm_slope_tana = 1;  % Can't set to 0, Will cause 1/0 in Goda Pressure Calcs
end


%% COMPUTE INFLUENCE FACTORS
% Wall Influence Factor
[gammas.gamma_v, gammas.gamma_star] = wall_influence_factor(crest_ele,wall_bottom_elev,Rc,strucType);
% Surface roughness Influence Factor
gammas.gamma_f = surface_roughness_influence_factor(gamma_f, Hm0);
% Oblique wave coefficients - Not implemented in CHESS as of 9/03/20
[gammas.gamma_beta_r2p, gammas.gamma_beta_q] = oblique_waves_influence_factor(size(Hm0));
% Berm Influence Factor (Not used)
if add_berm == 1
    [gammas.gamma_b] = berm_influence_factor(berm_width, berm_elev, Hm0, SWL, berm_slope_tana);
else
    gammas.gamma_b = ones(size(Hm0));
end
end
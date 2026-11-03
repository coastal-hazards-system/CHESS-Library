function [structure] = create_structure_geometry(config)
% create_structure_geometry  Structure geometry struct from config.
%   structure = create_structure_geometry(config) applies the
%   structure-level rules (finalize_structure_config) and copies the
%   geometry and material fields of the structure type from config into
%   structure (prints 'Creating <type> geometry....'). Berm fields are
%   copied only when add_toe_berm is 1 (toe berms are hidden, so never at
%   present). Shared by the library (call_input_parser) and the GUI; must
%   stay directly under Setup/ (chessProject finds PSE_Templates through
%   it).
%
%   Inputs:
%     config - CHESS configuration, 1x1 struct; reads struc_type (1 Levee,
%              2 Floodwall, 3 Rubblemound), add_toe_berm and the fields
%              listed under Outputs
%   Outputs:
%     structure - structure geometry, 1x1 struct; elevations [m, study
%                 datum, positive up], lengths [m]:
%                   all types   - crest_elevation, crest_width,
%                                 toe_elevation, water_density,
%                                 roughness_ifactor, offshore_slope,
%                                 struc_type
%                   Levee       - seaside_slope, leeside_slope
%                   Floodwall   - wall_bottom_elevation
%                   Rubblemound - seaside_slope, leeside_slope, armor_delta,
%                                 seaside_mass, leeside_mass, cem_P,
%                                 seaside_design_S, leeside_design_S,
%                                 seaside_S_uls, leeside_S_uls
%                   with a toe berm (add_toe_berm = 1) - berm_crest_width,
%                                 berm_crest_elevation, berm_seaward_slope
%                                 (Levee also berm_toe_elevation)
%
%   Tier: internal
%
%   See also finalize_structure_config, call_input_parser, read_chess_input.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% GRAB INPUT FROM "config"
%{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
%}
% Apply Structure-Level Rules (Idempotent, Already Applied When Called From call_input_parser)
config = finalize_structure_config(config);
% Structure Type
struc_type = config.struc_type;

%% DEFINE VARIBALES TO GRAB FROM CONFIG PER STRUCTURE TYPE & WORKFLOW
% Evaluate Case Per Structure Type
switch struc_type
    case 1 % Levee
        % Define Structure Type String
        s_type = 'levee';
        % Define "config" Vars To Grab
        vars_2_grab = {'crest_elevation','crest_width','toe_elevation','seaside_slope',...
            'leeside_slope','berm_crest_width','berm_crest_elevation',...
            'water_density','roughness_ifactor', 'berm_seaward_slope','berm_toe_elevation','offshore_slope'};
    case 2 % Floodwall
        % Define Structure Type String
        s_type = 'floodwall';
        % Define "config" Vars To Grab
        vars_2_grab = {'crest_elevation','crest_width','toe_elevation',...
            'berm_crest_width','berm_crest_elevation',...
            'water_density','roughness_ifactor', 'berm_seaward_slope', 'wall_bottom_elevation','offshore_slope'};
    case 3 % Rubblemound
        % Define Structure Type String
        s_type = 'rubblemound';
        % Define Vars To Grab
        vars_2_grab = {'crest_elevation','crest_width','toe_elevation','seaside_slope',...
            'leeside_slope','berm_crest_width','berm_crest_elevation','berm_seaward_slope',...
            'armor_delta','seaside_mass','leeside_mass','water_density','cem_P',...
            'seaside_design_S','leeside_design_S',...
            'roughness_ifactor', 'seaside_S_uls', 'leeside_S_uls','offshore_slope'};
end

% Temp Patch (Remove Berm Fields)
if config.add_toe_berm == 0
    vars_2_grab(contains(vars_2_grab, 'berm')) = [];
end

%% EXTRACT AND FORMAT "config" DATA
% Display Status Message
disp(['Creating ',s_type,' geometry....']);
% Loop Through All Variables
for ii = 1:length(vars_2_grab)
    % Extract Data And Store On Structure Variable
    structure.(vars_2_grab{ii}) = config.(vars_2_grab{ii});
end
structure.struc_type = struc_type;
end


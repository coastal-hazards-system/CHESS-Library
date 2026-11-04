function [project_forcing, config] = adjust_project_forcing(config, structure, project_forcing, st_type)
% adjust_project_forcing  Apply tides, SLR and toe wave height to a dataset.
%   [project_forcing, config] = adjust_project_forcing(config, structure,
%       project_forcing, st_type)
%
%   Adjustment step of one project forcing dataset (boundary_conditions_adjust):
%     - Random tide (apply_random_tides = 1 and an existing tide_file): the
%       tide record is added to SWL from each storm's start hour
%       (apply_random_tide). Start hours already in config
%       (tide_indx_<st_type>, e.g. drawn by draw_tide_indices) are kept;
%       otherwise they are drawn here and returned in config.
%     - Sea level rise: swl_slr is added to SWL (when not 0).
%     - Hm0_toe: wave height at the toe from Hm0_offshore, the adjusted SWL
%       and Tp (adjust_wave_height: depth limitation when
%       apply_depth_limitation = 1, Hm0 = 0 where the toe is emergent).
%       The toe is structure.toe_elevation; a floodwall (struc_type 2)
%       without a toe berm (add_toe_berm ~= 1) uses
%       structure.wall_bottom_elevation. Hm0_offshore is kept as is.
%
%   Inputs:
%     config          - CHESS configuration, 1x1 struct; reads workflow,
%                       tide_file, apply_random_tides, tide_indx_<st_type>
%                       (when present), swl_slr [m], apply_depth_limitation,
%                       gravity_constant [m/s^2], struc_type, add_toe_berm
%     structure       - CHESS structure geometry, 1x1 struct; reads
%                       toe_elevation and wall_bottom_elevation [m, study
%                       datum, positive up]
%     project_forcing - one project forcing dataset: PROS/DET struct (SWL,
%                       Hm0_offshore, Tp; chess_forcing_formatter) or LCS
%                       cell of life-cycle matrices (lcs_columns)
%     st_type         - storm type, 'XC', 'TC' or 'CC', char
%   Outputs:
%     project_forcing - adjusted dataset: PROS/DET SWL replaced and Hm0_toe
%                       added; LCS SWL and Hm0_toe columns set, struct or
%                       cell
%     config          - input config with tide_indx_<st_type> (random
%                       tides), struct
%
%   Tier: internal
%
%   See also boundary_conditions_adjust, adjust_wave_height,
%   apply_random_tide, forcing_storm_lengths, draw_tide_indices.

%% GRAB DETAILS FROM "config"
% Define Tide File
tide_file = config.tide_file;
% Define Use Tide Switch
use_tides = config.apply_random_tides;
% Define Project SWL Adjustment
swl_slr = config.swl_slr;
% Depth Limitation Switch
apply_DL = config.apply_depth_limitation;
% gravity constant 
g = config.gravity_constant;

%% GRAB DETAILS FROM "structure"
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation;
% Floodwall: Berm Toe When A Toe Berm Is Included, Else The Wall Bottom
if isfield(config, 'struc_type') && config.struc_type == 2 && ~(isfield(config, 'add_toe_berm') && config.add_toe_berm == 1)
    toe_elev = structure.wall_bottom_elevation;
end

%% GRAB PROJECT FORCING DATA
switch config.workflow
    case  {1, 2, 4}
        SWL = project_forcing.('SWL');% Water Level
        Hm0 = project_forcing.('Hm0_offshore');% Wave Height (After Uncertainty, Before Depth Limitation)
        Tp = project_forcing.('Tp'); % Wave Period
    case {3} % LCS
        C = lcs_columns();
        SWL = cellfun(@(x) x(:, C.SWL), project_forcing, 'un', false); % Get SWL From LC
        Hm0 = cellfun(@(x) x(:, C.Hm0_offshore), project_forcing, 'un', false); % Get Hm0 (Offshore) From LC
        Tp = cellfun(@(x) x(:, C.Tp), project_forcing, 'un', false); % Get Tp From LC
end
% Time Steps Per Storm
t_size = forcing_storm_lengths(config.workflow, project_forcing);

%% SWL ADJUSTMENTS
% Apply Random Tide To SWL
if exist(tide_file,'file') == 2 && use_tides == 1
    if ~isfield(config, ['tide_indx_' lower(st_type)])
        config.(['tide_indx_' lower(st_type)]) = [];
    end
    [SWL, config.(['tide_indx_' lower(st_type)])] = apply_random_tide(tide_file, SWL, t_size, config.(['tide_indx_' lower(st_type)]));
end
% Apply SLR
if swl_slr~=0
    for kk = 1:size(SWL, 2)
        SWL(:, kk) = cellfun(@(x) x + swl_slr, SWL(:, kk), 'un', false);
    end
end

%% Hm0 ADJUSTMENTS
% Hm0 At The Toe: Depth Limitation + Emergent Toe (Hm0 = 0) From The Water Depth @ Toe. Hm0_offshore Is Kept As Is
Hm0_toe = adjust_wave_height(Hm0, Tp, SWL, toe_elev, apply_DL, g);

%% STORE ADJUSTED DATA
% Store Modifications
switch config.workflow
    case  {1, 2, 4}
        project_forcing.SWL = SWL; % Adjusted SWL
        project_forcing.Hm0_toe = Hm0_toe;
    case {3}
        for jj = 1:length(SWL)
            project_forcing{jj}(:, C.SWL) = SWL{jj}; % Adjusted SWL
            project_forcing{jj}(:, C.Hm0_toe) = Hm0_toe{jj};
        end
end
end

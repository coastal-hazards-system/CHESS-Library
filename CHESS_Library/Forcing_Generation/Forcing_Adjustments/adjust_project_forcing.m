function [project_forcing, config] = adjust_project_forcing(config, structure, project_forcing, st_type)
%% GRAB DETAILS FROM "config"
% Define Tide File
tide_file = config.tide_file;
% Define Use Tide Switch
use_tides = config.apply_random_tides;
% Define Project SWL ADjustment
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
        SWL = [project_forcing.('SWL'), project_forcing.('SWL_no_rep')];% Water Level
        Hm0 = project_forcing.('Hm0');% Wave Height
        Tp = project_forcing.('Tp'); % Wave Period
    case {3} % LCS
        SWL = cellfun(@(x) x(:, 5), project_forcing, 'un', false); % Get SWL From LC
        Hm0 = cellfun(@(x) x(:, 6), project_forcing, 'un', false); % Get Hm0 From LC
        Tp = cellfun(@(x) x(:, 7), project_forcing, 'un', false); % Get Tp From LC
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
% Depth Limitation + Emergent Toe (Hm0 = 0) From The Water Depth @ Toe
Hm0 = adjust_wave_height(Hm0, Tp, SWL(:, 1), toe_elev, apply_DL, g);

%% STORE ADJUSTED DATA
% Store Modifications
switch config.workflow
    case  {1, 2, 4}
        project_forcing.SWL = SWL(:, 1); % Get SWL From LC
        project_forcing.SWL_no_rep = SWL(:,2);
        project_forcing.Hm0 = Hm0; % Get SWL From LC
    case {3}
        for jj = 1:length(SWL)
            project_forcing{jj}(:,5) = SWL{jj}; % Get SWL From LC
            project_forcing{jj}(:,6) = Hm0{jj}; % Get SWL From LC
        end
end
end

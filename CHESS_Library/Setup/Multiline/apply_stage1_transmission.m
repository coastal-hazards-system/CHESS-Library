function project_forcing = apply_stage1_transmission(config, project_forcing)
% apply_stage1_transmission  Multi-line stage 2 forcing from stage 1's forcing.
%   project_forcing = apply_stage1_transmission(config)
%   project_forcing = apply_stage1_transmission(config, project_forcing)
%   builds the multi-line transect stage 2 forcing from stage 1's adjusted
%   forcing (config.multiline, set by multiline_stage2_config).
%
%   Every workflow (PROS-RB, PROS-FB, DET, LCS Peaks/Timeseries), every
%   data, match and storm type:
%       Hm0_offshore (stage 2) = Hm0_toe (stage 1) x Kt (stage 1)
%       Hm0_toe (stage 2)      = adjust_wave_height(Hm0_offshore, Tp, SWL,
%                                stage 2 toe, apply_DL, g)
%   per replicate (z = 0 included) and per life-cycle row or time step. Kt
%   as in compute_structure_response for a rubble mound:
%   eurotop_wave_transmission(Hm0_toe, Tp, crest_elevation - SWL,
%   crest_width, 1/seaside_slope, g) of the stage 1 run's geometry. Kt = 0
%   (e.g. Hm0_toe = 0 at a dry stage 1 toe) gives Hm0 = 0: the waves are
%   dissipated, surge-only responses still run. The stage 2 toe is
%   toe_elevation, or wall_bottom_elevation for a floodwall without a toe
%   berm (as in adjust_project_forcing). SWL, Tp, wDir, dt, storm_duration,
%   storms/life cycles and replicates are kept as is: stage 1's
%   uncertainty, random tides and SLR are already in them, so stage 2 skips
%   the sampling, the uncertainty step and the adjustment step
%   (call_chess_boundary_conditions: built here by
%   build_boundary_conditions; boundary_conditions_uncertainty and
%   boundary_conditions_adjust return it untouched). Limits: no
%   ponding/setup between the stages, no distance between them, Tp and
%   direction unchanged.
%
%   Inputs:
%     config          - stage 2 run configuration, 1x1 struct; reads
%                       multiline.stage1_alt, multiline.stage1_structure,
%                       workflow, toe_elevation, struc_type, add_toe_berm,
%                       wall_bottom_elevation (floodwall),
%                       apply_depth_limitation, gravity_constant (and the
%                       chess_paths fields when project_forcing is omitted)
%     project_forcing - forcing holding stage 1's Hm0_toe: one dataset
%                       (PROS/DET struct, LCS cell of life cycles) or a
%                       whole project_forcing, struct or cell (optional;
%                       omitted: stage 1's saved
%                       <db>_<wflow_name>_project_forcing.mat, chess_paths)
%   Outputs:
%     project_forcing - stage 2 forcing (same layout), struct or cell
%
%   Tier: internal
%
%   See also multiline_stage2_config, multiline_inherited_fields,
%   eurotop_wave_transmission, adjust_wave_height.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin < 2
    s1 = config;
    s1.case_name = config.multiline.stage1_alt;
    S = load(chess_paths(s1).out_files.project_forcing, 'project_forcing');
    project_forcing = S.project_forcing;
end
% Stage 2 Toe: Same Rule As adjust_project_forcing.m (Floodwall Without A Toe Berm: Wall Bottom)
toe_elev = config.toe_elevation;
if config.struc_type == 2 && ~(isfield(config, 'add_toe_berm') && config.add_toe_berm == 1)
    toe_elev = config.wall_bottom_elevation;
end
geo = config.multiline.stage1_structure;
g = config.gravity_constant;
transmit = @(Hm0, Tp, SWL) cellfun(@(h, t, s) h.*eurotop_wave_transmission(h, t, geo.crest_elevation - s,...
    geo.crest_width, 1/geo.seaside_slope, g), Hm0, Tp, SWL, 'un', false);
project_forcing = transform(project_forcing);

    function data = transform(data)
        % One Dataset (PROS/DET Struct With Hm0_toe, LCS Cell Of Life Cycles), Else Recurse Into Data/Match/Storm Types
        if config.workflow == 3 && iscell(data)
            C = lcs_columns();
            SWL = cellfun(@(x) x(:, C.SWL), data, 'un', false);
            Tp = cellfun(@(x) x(:, C.Tp), data, 'un', false);
            Hm0_off = transmit(cellfun(@(x) x(:, C.Hm0_toe), data, 'un', false), Tp, SWL);
            Hm0_toe = adjust_wave_height(Hm0_off, Tp, SWL, toe_elev, config.apply_depth_limitation, g);
            for jj = 1:numel(data)
                data{jj}(:, C.Hm0_offshore) = Hm0_off{jj};
                data{jj}(:, C.Hm0_toe) = Hm0_toe{jj};
            end
        elseif isstruct(data) && isfield(data, 'Hm0_toe')
            data.Hm0_offshore = transmit(data.Hm0_toe, data.Tp, data.SWL);
            data.Hm0_toe = adjust_wave_height(data.Hm0_offshore, data.Tp, data.SWL, toe_elev, config.apply_depth_limitation, g);
        elseif isstruct(data)
            for fn = fieldnames(data)'
                data.(fn{1}) = transform(data.(fn{1}));
            end
        end
    end
end

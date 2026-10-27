function [config, structure] = multiline_stage2_config(config, structure)
%{
    %% DESCRIPTION
        Couples a multi-line transect stage 2 run to its stage 1 run: same
        project, PSE (struc_id), storm database and workflow, stage 1
        alternative config.multiline.stage1_alt (always a rubble mound).
        Stage 1's run files come from chess_paths.m (no paths are stored
        in config.multiline, so a moved project is not a change).
        Call after the config is built (GUI: create_resp_config, after
        storm_db_info 'apply' and finalize_config) and before
        check_offshore_elevation.m; the forcing itself is built by
        apply_stage1_transmission.m (call_chess_boundary_conditions.m,
        build_boundary_conditions.m).
            - config.multiline gets stage1_stamp (stage 1 config
              forcing_stamp, set when its forcing was built) and
              stage1_structure (the stage 1 run's crest_elevation,
              crest_width, seaside_slope, toe_elevation, offshore_slope).
              config.multiline is a hotstart dependency
              (hotstart_cache_dependencies.m deps.forcing_build): a stage 1
              re-run or geometry change rebuilds the stage 2 forcing.
            - Fields of multiline_inherited_fields.m are copied from the
              stage 1 config (tide_file moved into this project folder
              when the project was moved since).
            - Offshore end of the stage 2 transect = stage 1 toe:
              offshore_elevation = stage 1 toe_elevation (source
              'stage 1 toe'), offshore_slope = stage 1 offshore_slope
              (config and structure). Never the storm DB grid; no check
              that the stage 2 toe is deeper.
        Documented limits: no ponding/setup between the stages and no
        distance between them (display only); Tp and wave direction are
        unchanged by the transmission.

    %% INPUTS
        config: Stage 2 run config. | struct
            multiline.stage1_alt: Stage 1 alternative name. | char
            outfolder, project_name, struc_id, workflow, storm_db (or
            region/sp_ID), storm_sampling, use_peaks, create_wlp,
            create_whp, use_timeseries.
        structure: Stage 2 structure. | struct

    %% OUTPUTS
        config: Coupled config. | struct
        structure: structure with the stage 1 offshore_slope. | struct
        Errors multiline_stage2_config:noStage1Run (no completed stage 1
        run for this storm database and workflow) and
        multiline_stage2_config:stage1Mismatch (stage 1 run has another
        storm type, lacks a requested data type, or is not a rubble mound).

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
s1 = config;
s1.case_name = config.multiline.stage1_alt;
p1 = chess_paths(s1);
run_txt = sprintf('%s/%s with %s', config.struc_id, s1.case_name, p1.wflow_name);
if ~all(isfile({p1.out_files.config, p1.out_files.project_forcing}))
    error('multiline_stage2_config:noStage1Run', 'Multi-line stage 2 needs a completed run of stage 1 %s (storm DB %s): run stage 1 first.',...
        run_txt, p1.db);
end
S = load(p1.out_files.config, 'config', 'structure');
% forcing_stamp: Set Once The Forcing Is Complete (call_chess_boundary_conditions.m), So A Run Stopped Midway Has None
if ~isfield(S, 'structure') || ~isfield(S.config, 'forcing_stamp')
    error('multiline_stage2_config:noStage1Run', 'Multi-line stage 2 needs a completed run of stage 1 %s (storm DB %s): run stage 1 first.',...
        run_txt, p1.db);
end
s1_cfg = S.config;
if s1_cfg.struc_type ~= 3
    error('multiline_stage2_config:stage1Mismatch', 'Multi-line stage 1 %s must be a rubble mound.', run_txt);
end
if ~strcmp(s1_cfg.storm_sampling, config.storm_sampling)
    error('multiline_stage2_config:stage1Mismatch', 'Stage 1 %s was run with storm type %s, stage 2 requests %s.',...
        run_txt, s1_cfg.storm_sampling, config.storm_sampling);
end
dt_flags = {'use_peaks', 'create_wlp', 'create_whp', 'use_timeseries'};
missing = dt_flags(cellfun(@(f) config.(f) == 1 && s1_cfg.(f) ~= 1, dt_flags));
if ~isempty(missing)
    error('multiline_stage2_config:stage1Mismatch', 'Stage 1 %s has no %s data, requested by stage 2.', run_txt, strjoin(missing, ', '));
end
% Stage 1 Forcing Descriptors (Storms/Life Cycles, Duration, Tides, SLR)
for fld = multiline_inherited_fields()
    if isfield(s1_cfg, fld{1})
        config.(fld{1}) = s1_cfg.(fld{1});
    end
end
old_dir = fullfile(s1_cfg.outfolder, s1_cfg.project_name);
if ischar(config.tide_file) && strncmpi(config.tide_file, old_dir, numel(old_dir))
    config.tide_file = fullfile(config.outfolder, config.project_name, config.tide_file(numel(old_dir)+1:end));
end
% Stage 1 Geometry Of That Run (Kt In apply_stage1_transmission.m) And Its Forcing Build Stamp
geo = S.structure;
config.multiline.stage1_stamp = s1_cfg.forcing_stamp;
config.multiline.stage1_structure = struct('crest_elevation', geo.crest_elevation, 'crest_width', geo.crest_width,...
    'seaside_slope', geo.seaside_slope, 'toe_elevation', geo.toe_elevation, 'offshore_slope', geo.offshore_slope);
% Stage 2 Offshore End = Stage 1 Toe
config.offshore_elevation = geo.toe_elevation;
config.offshore_elevation_source = 'stage 1 toe';
config.offshore_slope = geo.offshore_slope;
structure.offshore_slope = geo.offshore_slope;
end

classdef (Abstract) Model < handle
    % Model  A CHESS run: builds the forcing and computes the responses.
    %   model = chess.Model.create('CHESS_rubble_mound_inputs.xlsx');
    %   model.run();
    %
    %   or step by step:
    %     model.prepare_storm_database();
    %     forcing = model.build_forcing();
    %     responses = model.compute_responses(forcing);
    %
    %   chess.Model.create returns the child of the workflow of the inputs:
    %     chess.Model.Pros           - probabilistic response of structures
    %                                  (workflow 1 response based, 4 frequency based)
    %     chess.Model.Deterministic  - responses straight from the storms (workflow 2)
    %     chess.Model.LifeCycle      - life-cycle simulation and reliability (workflow 3)
    %
    %   The model owns the run logic (which storms, which responses, the
    %   order of the steps, what is saved). The calculations are done by the
    %   objects it holds and by the function folders:
    %     protection_system - chess.ProtectionSystem (geometry and responses)
    %     storm_database    - chess.CoastalHazardSystem (storm data)
    %     hotstart          - chess.Hotstart (reuse of a saved run)
    %     chess.BoundaryConditions, chess.ExtremeValueAnalysis
    %
    %   The forcing and the responses are returned and saved, not kept in
    %   the object.
    %
    %   See also chess.Model.Pros, chess.Model.Deterministic,
    %   chess.Model.LifeCycle, chess.Config.read, chess.ProjectPaths.build.

    properties
        config              % run configuration, plain struct (chess.Config)
        protection_system   % chess.ProtectionSystem child
        storm_database = [] % chess.CoastalHazardSystem ([] = storm data given to build_forcing)
        hotstart = []       % chess.Hotstart of this run
    end

    properties (Dependent)
        paths               % output folders and files (chess.ProjectPaths.build)
    end

    methods (Static)
        function rules = input_rules(workflow)
            % input_rules  Inputs a run of the workflow needs.
            %   rules = chess.Model.input_rules(workflow)
            %   Rules (chess.Config.input_rule) of the run settings shared by
            %   every workflow and of the inputs of the child class
            %   (workflow_input_rules of Pros, Deterministic or LifeCycle).
            %   chess.Config.validate checks a config against them. Storm
            %   data inputs (chs_zip, chs_dependencies) are optional: a
            %   config without chs_zip takes its storm data in build_forcing.
            shared = [...
                chess.Config.input_rule('project_name', 'text'),...
                chess.Config.input_rule('struc_id', 'text'),...
                chess.Config.input_rule('case_name', 'text'),...
                chess.Config.input_rule('outfolder', 'text'),...
                chess.Config.input_rule('project_datum', 'text', 'allow_blank', true),...
                chess.Config.input_rule('project_CLs', 'text'),...
                chess.Config.input_rule('unit_system', 'choice', 'choices', {'SI', 'Imperial'}, 'optional', true),...
                chess.Config.input_rule('storm_sampling', 'choice', 'choices', {'XC', 'TC', 'CC'}),...
                chess.Config.input_rule('swl_slr', 'number', 'unit_kind', 'length'),...
                chess.Config.input_rule('apply_random_tides', 'switch'),...
                chess.Config.input_rule('tide_file', 'text'),...
                chess.Config.input_rule('apply_depth_limitation', 'switch'),...
                chess.Config.input_rule('use_peaks', 'switch'),...
                chess.Config.input_rule('use_timeseries', 'switch'),...
                chess.Config.input_rule('create_wlp', 'switch'),...
                chess.Config.input_rule('create_whp', 'switch'),...
                chess.Config.input_rule('storm_duration', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('compute_storm_duration', 'switch', 'optional', true),...
                chess.Config.input_rule('chs_zip', 'text', 'optional', true),...
                chess.Config.input_rule('chs_dependencies', 'text', 'optional', true)];
            [shared.owner] = deal('run');
            switch workflow
                case {1, 4}
                    own = chess.Model.Pros.workflow_input_rules();
                case 2
                    own = chess.Model.Deterministic.workflow_input_rules();
                case 3
                    own = chess.Model.LifeCycle.workflow_input_rules();
                otherwise
                    error('chess:Model:unknownWorkflow', 'workflow must be 1 (PROS-RB), 2 (DET), 3 (LCS) or 4 (PROS-FB).');
            end
            [own.owner] = deal(chess.Model.workflows(workflow).wflow_name);
            rules = [shared, own];
        end

        function model = create(source)
            % create  Set up a CHESS run from its inputs.
            %   model = chess.Model.create(input_file)   CHESS input file (.xlsx or .csv)
            %   model = chess.Model.create(config)       configuration struct (SI)
            %   model = chess.Model.create(config_file)  saved run (<db>_<workflow>_config_file.mat)
            %
            %   Input file or config struct: the inputs are checked against
            %   the rules of the workflow and of the structure
            %   (chess.Config.validate), the storm data given in chs_zip is
            %   checked by file name, the storm database and run folders are
            %   prepared, the configuration rules are applied
            %   (chess.Config.apply_rules), the hotstart level is resolved
            %   (chess.Hotstart), the protection system is built and the run
            %   configuration is saved. A config struct without chs_zip sets
            %   up a run whose storm data is passed to build_forcing.
            %   Units: an input file is read in its unit_system and converted
            %   to SI (chess.Config.read); a config struct must already be SI
            %   (it is not converted, so a saved config passed back in is
            %   never converted twice; its unit_system only labels the
            %   exported results).
            %   Saved run: the model is rebuilt as saved, nothing is written.
            if ischar(source) || isstring(source)
                [~, ~, extension] = fileparts(char(source));
                if strcmpi(extension, '.mat')
                    model = saved_run_model(char(source));
                    return
                end
                config = chess.Config.read(source);
            else
                config = source;
                if ~isfield(config, 'gravity_constant') || isempty(config.gravity_constant)
                    config.gravity_constant = chess.Common.physical_constants().gravity;
                end
            end
            % Every Missing Or Invalid Input, Reported Before Anything Runs
            chess.Config.validate(config);

            %% STORM DATA AND RUN FOLDERS
            storm_database = [];
            first_run = false;
            if isfield(config, 'chs_zip') && ~isempty(config.chs_zip)
                [config, storm_database, first_run] = connect_storm_data(config);
            else
                run_paths = chess.ProjectPaths.build(config);
                if ~exist(run_paths.wf_dir, 'dir')
                    mkdir(run_paths.wf_dir);
                end
            end

            %% CONFIGURATION RULES
            config = chess.Config.apply_rules(config);

            %% COMPUTATIONAL ENVIRONMENT
            if first_run
                print_welcome_banner(config.workflow);
            end
            if isfield(config, 'chs_dependencies')
                report_chs_dependencies(config);
            end
            run_paths = chess.ProjectPaths.build(config);
            config.out_files.storm_and_prob_mass = run_paths.storm_db;
            config.out_files.chs_data = run_paths.chs_data;
            % Hotstart State
            hotstart = chess.Hotstart(config);
            config = hotstart.resolve();
            % DET: No Uncertainty Unless Provided
            if config.workflow == 2
                for name = {'chs_swl_u_a', 'chs_swl_u_r', 'chs_hm0_u_a', 'chs_hm0_u_r'}
                    if ~isfield(config, name{1}) || isempty(config.(name{1}))
                        config.(name{1}) = 0;
                    end
                end
            end
            % Protection System
            protection_system = chess.ProtectionSystem.create(config);
            disp(['Creating ', protection_system.structure_name, ' geometry....']);
            if isfield(config, 'multiline') && ~isempty(config.multiline)
                protection_system.multiline_stage = 2;
            end
            model = chess.Model.for_workflow(config, protection_system, storm_database);
            model.hotstart = hotstart;
            structure = protection_system.to_struct(); %#ok<NASGU>
            save(config.out_files.config, 'config', 'structure', '-v7.3');
        end

        function model = for_workflow(config, protection_system, storm_database)
            % for_workflow  Model of a ready configuration (no parsing, no disk writes).
            %   model = chess.Model.for_workflow(config, protection_system)
            %   model = chess.Model.for_workflow(config, protection_system, storm_database)
            %   config: configuration with the rules applied; protection_system:
            %   chess.ProtectionSystem child, or a structure struct (the
            %   stone size model switches, which the structure struct does
            %   not hold, are taken from config).
            if nargin < 3
                storm_database = [];
            end
            if isstruct(protection_system)
                protection_system = chess.ProtectionSystem.create(chess.Model.stone_size_inputs(protection_system, config));
            end
            switch config.workflow
                case {1, 4}
                    model = chess.Model.Pros(config, protection_system, storm_database);
                case 2
                    model = chess.Model.Deterministic(config, protection_system, storm_database);
                case 3
                    model = chess.Model.LifeCycle(config, protection_system, storm_database);
                otherwise
                    error('chess:Model:unknownWorkflow', 'workflow must be 1 (PROS-RB), 2 (DET), 3 (LCS) or 4 (PROS-FB).');
            end
        end

        function workflows = workflows(workflow_number)
        % workflows  Table of the CHESS workflows (number, folder, name).
        %   workflows = chess.Model.workflows() returns the whole table.
        %   workflows = chess.Model.workflows(workflow_number) returns the row of that
        %   workflow.
        %
        %   Table of the CHESS workflows: the workflow number (config.workflow), the
        %   output folder of its runs and the workflow name used in its run file
        %   names (chess.ProjectPaths.build). Single source of these names for the library and
        %   the GUI.
        %       number | folder | wflow_name
        %          1   |  PROS  |  PROS-RB   (PROS, response based)
        %          2   |  DET   |  DET       (deterministic)
        %          3   |  LCS   |  LCS       (life cycle simulation)
        %          4   |  PROS  |  PROS-FB   (PROS, frequency based)
        %
        %   An unknown workflow number raises chess:Model:unknownWorkflow.
        %
        %   Inputs:
        %     workflow_number - (optional) workflow number (config.workflow) [-],
        %                       scalar double; without it the whole table is returned
        %   Outputs:
        %     workflows - table rows ordered by number (4x1 without input, 1x1 with
        %                 workflow_number), struct array with fields:
        %                   number     - workflow number [-], double
        %                   folder     - run folder name under the alternative folder,
        %                                char
        %                   wflow_name - workflow name in the run file names (upper
        %                                case), char
        %
        %   See also chess.ProjectPaths.build, chess.Model.create.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        workflows = struct('number', {1; 2; 3; 4},...
            'folder', {'PROS'; 'DET'; 'LCS'; 'PROS'},...
            'wflow_name', {'PROS-RB'; 'DET'; 'LCS'; 'PROS-FB'});
        if nargin == 0
            return
        end
        row = [];
        if isnumeric(workflow_number) && isscalar(workflow_number)
            row = find([workflows.number] == workflow_number, 1);
        end
        if isempty(row)
            error('chess:Model:unknownWorkflow', 'workflow must be 1 (PROS-RB), 2 (DET), 3 (LCS) or 4 (PROS-FB).');
        end
        workflows = workflows(row);
        end

        function config = apply_storm_database_info(db_info, config)
            % apply_storm_database_info  Copy the storm database details into config.
            %   config = chess.Model.apply_storm_database_info(db_info, config)
            %   tc_bias_corrected and the bias and uncertainty values replace
            %   the config values; Nyrs_XC and Nstm_XC when the database holds
            %   them; storm_db_build_date; offshore_elevation when the database
            %   has a study grid value (offshore_elevation_source 'Storm DB
            %   grid', else 'config').
            fields = {'tc_bias_corrected', 'chs_swl_b_a', 'chs_swl_b_r', 'chs_swl_u_a', 'chs_swl_u_r', 'chs_swl_bu_source',...
                'chs_hm0_b_a', 'chs_hm0_b_r', 'chs_hm0_u_a', 'chs_hm0_u_r', 'chs_hm0_bu_source'};
            for ff = fields
                config.(ff{1}) = db_info.(ff{1});
            end
            for ff = {'Nyrs_XC', 'Nstm_XC'}
                if ~isempty(db_info.(ff{1}))
                    config.(ff{1}) = db_info.(ff{1});
                end
            end
            config.storm_db_build_date = db_info.build_date;
            if isfield(db_info, 'offshore_elevation') && ~isempty(db_info.offshore_elevation)
                config.offshore_elevation = db_info.offshore_elevation;
                config.offshore_elevation_source = 'Storm DB grid';
            else
                config.offshore_elevation_source = 'config';
            end
        end

        function check_offshore_elevation(config)
        % chess.Model.check_offshore_elevation  Stop a run that has no usable offshore elevation.
        %   chess.Model.check_offshore_elevation(config) returns when offshore_elevation is a
        %   finite numeric scalar and errors otherwise. offshore_elevation is always
        %   required (offshore end of the PSE transect conceptual model, used by
        %   the damaging depth and the transect): it comes from the storm database's
        %   study grid value (config is only overwritten when the grid has one,
        %   chess.CoastalHazardSystem.create_db_info 'apply'), else from the PSE geometry (input file row / GUI
        %   PSE table). Shared by the library (chess.Model.prepare_storm_database, after the
        %   storm database's db_info is applied) and the GUI (create_resp_config,
        %   Run).
        %
        %   Inputs:
        %     config - CHESS configuration, 1x1 struct; reads:
        %                offshore_elevation - offshore elevation [m, study datum,
        %                                     positive up], scalar double (optional;
        %                                     missing, empty or NaN fails)
        %                region, sp_ID      - CHS region and savepoint (error
        %                                     message)
        %                storm_db, out_files.storm_and_prob_mass - storm database
        %                                     name / file (optional, error message)
        %                chs_dependencies   - CHS_Dependencies folder (optional,
        %                                     error message)
        %   Outputs:
        %     none; error chess:Model:missingOffshoreElevation when the value is
        %     missing, naming the reason the storm database has no grid value
        %
        %   See also chess.Model.prepare_storm_database, chess.Equations.damaging_depth, chess.CoastalHazardSystem.dependency_files,
        %   chess.CoastalHazardSystem.create_db_info.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        if isfield(config, 'offshore_elevation') && isnumeric(config.offshore_elevation) &&...
                isscalar(config.offshore_elevation) && isfinite(config.offshore_elevation)
            return
        end
        % Why The Storm Database Has No Study Grid Value
        region = char(config.region);
        chs_dependencies = '';
        if isfield(config, 'chs_dependencies')
            chs_dependencies = config.chs_dependencies;
        end
        chs_files = chess.CoastalHazardSystem.dependency_files(chs_dependencies, region);
        if ~startsWith(region, 'CHS-')
            reason = 'Custom Modeling storm data, no CHS study grid';
        elseif chs_files.region_supported && ~chs_files.study_grid_has_elevation
            reason = sprintf('the %s study grid has no value column', region);
        elseif ~isempty(chs_dependencies) && ~chs_files.study_grid_available
            reason = sprintf('no CHS_Dependencies for %s', region);
        else
            reason = 'grid fill value at the savepoint, no CHS_Dependencies, or a storm database built before offshore elevations were stored';
        end
        sp_str = '';
        if isnumeric(config.sp_ID) && isscalar(config.sp_ID)
            sp_str = sprintf(' for SP%d', config.sp_ID);
        end
        % Storm Database Name: storm_db, Else The Database File Name (chess.ProjectPaths.build Default <region>_SP<sp_ID>)
        db_name = '';
        if isfield(config, 'storm_db')
            db_name = char(string(config.storm_db));
        end
        if isempty(db_name) && isfield(config, 'out_files') && isfield(config.out_files, 'storm_and_prob_mass')
            [~, db_name] = fileparts(config.out_files.storm_and_prob_mass);
        end
        error('chess:Model:missingOffshoreElevation',...
            ['CHESS needs offshore_elevation (offshore end of the PSE transect; elevation, positive up, study datum): the storm database %s has no study grid value%s (%s) and the PSE geometry gives none.\n'...
            'Enter offshore_elevation in the PSE geometry (GUI: PSE creation; input file: row offshore_elevation).'], db_name, sp_str, reason);
        end

        function [config, structure] = couple_to_stage1(config, structure)
        % couple_to_stage1  Couple a multi-line stage 2 run to its stage 1 run.
        %   [config, structure] = chess.Model.couple_to_stage1(config, structure) couples
        %   a multi-line transect stage 2 run to its stage 1 run: same project, PSE
        %   (struc_id), storm database and workflow, stage 1 alternative
        %   config.multiline.stage1_alt (always a rubble mound).
        %
        %   Stage 1's run files come from chess.ProjectPaths.build (no paths are stored in
        %   config.multiline, so a moved project is not a change). Call after the
        %   config is built (GUI: create_resp_config, after chess.CoastalHazardSystem.create_db_info 'apply'
        %   and chess.Config.apply_rules) and before chess.Model.check_offshore_elevation; the forcing
        %   itself is built by stage1_forcing
        %   (chess.Model.build_forcing, chess.Model.build_forcing).
        %     - config.multiline gets stage1_stamp (stage 1 config forcing_stamp,
        %       set when its forcing was built) and stage1_structure (the stage 1
        %       run's crest_elevation, crest_width, seaside_slope, toe_elevation,
        %       offshore_slope). multiline is a hotstart dependency
        %       (chess.Hotstart.dependency_fields forcing_build_fields): a stage 1 re-run
        %       or geometry change rebuilds the stage 2 forcing.
        %     - Fields of chess.Model.multiline_inherited_fields are copied from the stage 1
        %       config (tide_file moved into this project folder when the project
        %       was moved since).
        %     - Offshore end of the stage 2 transect = stage 1 toe:
        %       offshore_elevation = stage 1 toe_elevation
        %       (offshore_elevation_source 'stage 1 toe'), offshore_slope = stage 1
        %       offshore_slope (config and structure). Never the storm DB grid; no
        %       check that the stage 2 toe is deeper. nearshore_slope is not
        %       inherited (stage 2's own input).
        %   Documented limits: no ponding/setup between the stages and no distance
        %   between them (display only); Tp and wave direction are unchanged by the
        %   transmission.
        %
        %   Inputs:
        %     config    - stage 2 run configuration, 1x1 struct; reads
        %                 multiline.stage1_alt (stage 1 alternative name, char),
        %                 outfolder, project_name, struc_id, workflow, storm_db (or
        %                 region/sp_ID), storm_sampling, use_peaks, create_wlp,
        %                 create_whp, use_timeseries, tide_file
        %     structure - stage 2 structure geometry, 1x1 struct
        %   Outputs:
        %     config    - coupled configuration, 1x1 struct
        %     structure - structure with the stage 1 offshore_slope, 1x1 struct
        %   Errors chess:Model:noStage1Run (no completed stage 1 run
        %   for this storm database and workflow) and
        %   chess:Model:stage1Mismatch (stage 1 run has another storm
        %   type, lacks a requested data type, or is not a rubble mound).
        %
        %   See also stage1_forcing, chess.Model.multiline_inherited_fields,
        %   chess.ProjectPaths.build, chess.Model.check_offshore_elevation.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        s1 = config;
        s1.case_name = config.multiline.stage1_alt;
        p1 = chess.ProjectPaths.build(s1);
        run_txt = sprintf('%s/%s with %s', config.struc_id, s1.case_name, p1.wflow_name);
        if ~all(isfile({p1.out_files.config, p1.out_files.project_forcing}))
            error('chess:Model:noStage1Run', 'Multi-line stage 2 needs a completed run of stage 1 %s (storm DB %s): run stage 1 first.',...
                run_txt, p1.db);
        end
        S = load(p1.out_files.config, 'config', 'structure');
        % forcing_stamp: Set Once The Forcing Is Complete (chess.Model.build_forcing), So A Run Stopped Midway Has None
        if ~isfield(S, 'structure') || ~isfield(S.config, 'forcing_stamp')
            error('chess:Model:noStage1Run', 'Multi-line stage 2 needs a completed run of stage 1 %s (storm DB %s): run stage 1 first.',...
                run_txt, p1.db);
        end
        s1_cfg = S.config;
        if s1_cfg.struc_type ~= 3
            error('chess:Model:stage1Mismatch', 'Multi-line stage 1 %s must be a rubble mound.', run_txt);
        end
        if ~strcmp(s1_cfg.storm_sampling, config.storm_sampling)
            error('chess:Model:stage1Mismatch', 'Stage 1 %s was run with storm type %s, stage 2 requests %s.',...
                run_txt, s1_cfg.storm_sampling, config.storm_sampling);
        end
        dt_flags = {'use_peaks', 'create_wlp', 'create_whp', 'use_timeseries'};
        missing = dt_flags(cellfun(@(f) config.(f) == 1 && s1_cfg.(f) ~= 1, dt_flags));
        if ~isempty(missing)
            error('chess:Model:stage1Mismatch', 'Stage 1 %s has no %s data, requested by stage 2.', run_txt, strjoin(missing, ', '));
        end
        % Stage 1 Forcing Descriptors (Storms/Life Cycles, Duration, Tides, SLR)
        for fld = chess.Model.multiline_inherited_fields()
            if isfield(s1_cfg, fld{1})
                config.(fld{1}) = s1_cfg.(fld{1});
            end
        end
        old_dir = fullfile(s1_cfg.outfolder, s1_cfg.project_name);
        if ischar(config.tide_file) && strncmpi(config.tide_file, old_dir, numel(old_dir))
            config.tide_file = fullfile(config.outfolder, config.project_name, config.tide_file(numel(old_dir)+1:end));
        end
        % Stage 1 Geometry Of That Run (Kt In stage1_forcing) And Its Forcing Build Stamp
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

        function fields = multiline_inherited_fields()
        % chess.Model.multiline_inherited_fields  Config fields stage 2 takes from stage 1.
        %   fields = chess.Model.multiline_inherited_fields() returns the config fields a
        %   multi-line transect stage 2 run takes from the stage 1 run it is
        %   coupled to (chess.Model.couple_to_stage1).
        %
        %   They describe the stage 1 forcing that stage 2 reuses (its storms or
        %   life cycles, storm duration and its per-storm switch, tides and SLR),
        %   so stage 2's own values are not used. Read by chess.Model.couple_to_stage1
        %   and by the GUI (stage 2 inputs shown from stage 1, not editable).
        %
        %   Inputs:
        %     none
        %   Outputs:
        %     fields - config field names (fields missing from the stage 1 config,
        %              e.g. LCS fields of a PROS run, are skipped by the caller),
        %              cellstr
        %
        %   See also chess.Model.couple_to_stage1, stage1_forcing.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        fields = {'storm_duration', 'compute_storm_duration', 'mcs_nYears', 'mcs_nLC', 'lcs_restrict_sampling_rate', 'lcs_effective_sampling_rate',...
            'lcs_convergence_results', 'swl_slr', 'apply_random_tides', 'tide_file', 'tide_indx_xc', 'tide_indx_tc', 'tide_indx_cc'};
        end
    end

    methods (Static, Hidden)
        function structure = stone_size_inputs(structure, config)
            % stone_size_inputs  Structure struct with the stone size model switches of config.
            %   structure = chess.Model.stone_size_inputs(structure, config)
            %   to_struct holds the geometry only, so the switches
            %   dn50_use_legacy_model and dn50_legacy_submerged_correction are
            %   copied from config before chess.ProtectionSystem.create.
            %   Inputs:
            %     structure - structure struct (geometry), struct
            %     config    - run configuration, struct
            %   Outputs:
            %     structure - structure with the switches present in config
            %                 (a switch the structure already holds is kept), struct
            %
            %   See also chess.ProtectionSystem.create, chess.Model.for_workflow.
            %
            %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
            for name = {'dn50_use_legacy_model', 'dn50_legacy_submerged_correction'}
                if isfield(config, name{1}) && ~isempty(config.(name{1})) && ~isfield(structure, name{1})
                    structure.(name{1}) = config.(name{1});
                end
            end
        end
    end

    methods
        function obj = Model(config, protection_system, storm_database)
            % Model  Hold a ready configuration and its objects (see chess.Model.create).
            %   obj = chess.Model(config, protection_system, storm_database)
            obj.config = config;
            obj.protection_system = protection_system;
            if nargin > 2
                obj.storm_database = storm_database;
            end
        end

        function paths = get.paths(obj)
            paths = chess.ProjectPaths.build(obj.config);
        end

        function [responses, forcing] = run(obj)
            % run  Run every step: storm database, forcing, responses.
            %   [responses, forcing] = model.run()
            timer = tic;
            obj.prepare_storm_database();
            forcing = obj.build_forcing();
            responses = obj.compute_responses(forcing);
            disp(['Simulation Completed. Total run time: ' num2str(round(toc(timer)/60, 2)) ' mins...']);
        end

        function prepare_storm_database(obj)
            % prepare_storm_database  Make sure the storm database holds what the run requests.
            %   model.prepare_storm_database()
            %   An existing database that covers the request (storm types,
            %   Peaks / Timeseries, WLP / WHP) is kept. Otherwise it is built
            %   from the CHS input (chess.CoastalHazardSystem.build): the saved
            %   forcing of this run is then discarded and the database details
            %   (bias and uncertainty, XC record, offshore elevation) are
            %   copied into config. The offshore elevation is checked last.
            if isempty(obj.storm_database)
                chess.Model.check_offshore_elevation(obj.config);
                return
            end
            config = obj.config;
            database = obj.storm_database;
            disp_on = config.print_progress;
            request = storm_request(config);
            database_exists = isfile(database.database_file);
            is_storm_mat_input = strcmp(database.source_kind, 'storm_mat');
            can_build = ~is_storm_mat_input;
            if database_exists
                chess.Common.disp_toggle(disp_on, 'CHESS generated storm .mat detected. Checking its datasets...');
            end
            [compatible, storm_type_ok, data_type_ok, datasets_ok] = database.covers(request.storm_sampling, request.use_peaks,...
                request.use_timeseries, request.create_wlp, request.create_whp);
            has_info = chess.CoastalHazardSystem.is_valid_db_info(database.db_info);
            % Report The Decision
            if database_exists && compatible
                chess.Common.disp_toggle(disp_on, 'Processed CHS data (storm) detected. Loading....');
            elseif can_build
                if database_exists
                    if ~has_info
                        chess.Common.disp_toggle(disp_on, 'Processed CHS data (storm) has no db_info (older CHESS version). Rebuilding the storm database....');
                    else
                        chess.Common.disp_toggle(disp_on, 'Processed CHS data (storm) does not have necessary dependencies. Restarting import process....');
                    end
                end
            else
                storm_request_error(database_exists, storm_type_ok, data_type_ok, datasets_ok, has_info, request, is_storm_mat_input);
            end
            % Build The Storm Database From The CHS Input
            if ~(database_exists && compatible) && can_build
                database.build(request.storm_sampling, request.use_peaks, request.use_timeseries, request.create_wlp,...
                    request.create_whp, disp_on);
                % The Saved Forcing Belongs To The Replaced Database
                config = reset_forcing_cache(config);
                config = chess.Model.apply_storm_database_info(database.db_info, config);
                save(config.out_files.config, 'config', '-append');
            end
            chess.Model.check_offshore_elevation(config);
            obj.config = config;
        end

        function forcing = build_forcing(obj, storm, prob_mass, progress_function)
            % build_forcing  Build, adjust and save the project forcing.
            %   forcing = model.build_forcing()
            %   forcing = model.build_forcing(storm, prob_mass)
            %   forcing = model.build_forcing(storm, prob_mass, progress_function)
            %   Steps:
            %     0. A complete saved forcing that covers the request is loaded
            %        and returned (hotstart).
            %     1. Build: the storms of the database are laid out for the
            %        workflow (replicates, single values or life cycles). A
            %        multi-line stage 2 run takes the forcing of stage 1 with
            %        its waves transmitted.
            %     2. Uncertainty (PROS).
            %     3. Adjustments: random tide, sea level change, wave height
            %        at the toe.
            %     4. The forcing is stamped and saved.
            %   storm, prob_mass: storm data to use instead of the storm
            %   database. progress_function(step, message): default prints.
            %   forcing: struct forcing.<Peaks|Timeseries>.<Default|WLP|WHP>.<XC|TC|CC>.
            if nargin < 2
                storm = [];
            end
            if nargin < 3
                prob_mass = [];
            end
            if nargin < 4 || isempty(progress_function)
                progress_function = @(~, message) disp(message);
            end
            config = obj.config;
            existing_file = config.out_files.project_forcing;
            is_stage2 = isfield(config, 'multiline') && ~isempty(config.multiline);

            %% STEP 0: SAVED COMPLETE PROJECT FORCING
            if exist(existing_file, 'file') == 2
                if isfield(config, 'forcing_stamp')
                    saved_run = chess.Hotstart(config, []);
                    [covers, forcing, missing_desc] = saved_run.forcing_covers();
                    if covers
                        progress_function(0, ['Successfully loaded the complete cached project forcing: ' existing_file]);
                        obj.config = obj.note_saved_forcing(config, existing_file);
                        return
                    end
                    chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: cached project forcing does not cover requested permutation (missing: %s) -- deleting, will be regenerated....', missing_desc));
                else
                    chess.Common.disp_toggle(config.print_progress, 'Hotstart: cached project forcing is not from a completed run -- deleting, will be regenerated....');
                end
                delete(existing_file);
            end

            %% STEP 1: BUILD
            if is_stage2
                progress_function(1, ['Multi-line stage 2: transmitting the waves of stage 1 (' config.multiline.stage1_alt ')....']);
                forcing = obj.stage1_forcing();
            else
                if isempty(storm)
                    [storm, prob_mass] = obj.read_requested_storms();
                end
                progress_function(1, 'Preping project forcing data....');
                % Timeseries storm_duration: config.storm_duration, Or Per Storm From Its SWL (compute_storm_duration = 1)
                if ~isfield(config, 'compute_storm_duration') || isempty(config.compute_storm_duration)
                    config.compute_storm_duration = 0;
                end
                obj.config = config;
                forcing = obj.build_storm_forcing(storm, prob_mass);
                % Tide Start Hours Shared Across Datasets
                obj.shared_tide_start_hours(forcing);
            end

            %% STEPS 2-3: UNCERTAINTY AND ADJUSTMENTS PER DATASET
            data_types = fieldnames(forcing);
            for dt = 1:length(data_types) % Peaks, Timeseries
                match_types = fieldnames(forcing.(data_types{dt}));
                for mt = 1:length(match_types) % Default, WLP, WHP
                    storm_types = fieldnames(forcing.(data_types{dt}).(match_types{mt}));
                    for st = 1:length(storm_types) % XC, TC, CC
                        dataset_label = [data_types{dt} ' ' match_types{mt} ' ' storm_types{st}];
                        data = forcing.(data_types{dt}).(match_types{mt}).(storm_types{st});
                        progress_function(2, ['Uncertainty step: ' dataset_label '....']);
                        if ~is_stage2
                            data = obj.apply_forcing_uncertainty(data, storm_types{st});
                        end
                        progress_function(3, ['Adjustment step: ' dataset_label '....']);
                        if ~is_stage2
                            data = obj.apply_adjustments(data, storm_types{st});
                        end
                        forcing.(data_types{dt}).(match_types{mt}).(storm_types{st}) = data;
                    end
                end
            end

            %% STEP 4: STAMP AND SAVE
            % Forcing Build Stamp: Marks The Forcing On Disk As Complete (Step 0); A Multi-Line Stage 2 Run Records It
            config = obj.config;
            config.forcing_stamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            progress_function(4, 'Saving project forcing....');
            project_forcing = forcing; %#ok<NASGU>
            save(existing_file, 'project_forcing', '-v7.3');
            save(config.out_files.config, 'config', '-append');
            obj.config = config;
        end

        function responses = compute_responses(obj, forcing)
            % compute_responses  Compute and save the responses of every forcing dataset.
            %   responses = model.compute_responses(forcing)
            %   forcing: project forcing (build_forcing). The offshore elevation
            %   resolved for the run is set on the protection system, which is
            %   saved with the run configuration. Each requested dataset
            %   (Peaks Default / WLP / WHP, Timeseries Default) goes through
            %   the workflow of the model; the result is saved to
            %   config.out_files.resp_data (variable Resp).
            config = obj.config;
            % Resolved Offshore Elevation Into The Protection System (Full Transect In One Place)
            if isfield(config, 'offshore_elevation')
                obj.protection_system.offshore_elevation = config.offshore_elevation;
            end
            if isfield(config, 'offshore_elevation_source')
                obj.protection_system.offshore_elevation_source = config.offshore_elevation_source;
            end
            structure = obj.protection_system.to_struct();
            if ~isfield(structure, 'offshore_elevation')
                structure.offshore_elevation = [];
                structure.offshore_elevation_source = '';
            end
            save(config.out_files.config, 'structure', '-append');

            responses = struct();
            output_folder = obj.paths.wf_dir;
            if ~exist(output_folder, 'dir')
                mkdir(output_folder);
            end
            obj.announce_run();

            % Peaks Datasets
            if config.use_peaks && isfield(forcing, 'Peaks')
                disp(['Running CHESS: ' obj.run_label ' - Peaks....']);
                dataset_names = fieldnames(forcing.Peaks);
                for ii = 1:numel(dataset_names)
                    name = dataset_names{ii};
                    if ~obj.uses_peaks_dataset(name)
                        continue
                    end
                    fprintf('   Processing %s dataset....\n', name);
                    responses.Peaks.(name) = obj.dataset_responses(forcing.Peaks.(name), 'Peaks', name);
                end
            end
            % Timeseries Dataset
            if config.use_timeseries && isfield(forcing, 'Timeseries')
                disp(['Running CHESS: ' obj.run_label ' - Timeseries....']);
                responses.Timeseries.Default = obj.dataset_responses(forcing.Timeseries.Default, 'Timeseries', 'Default');
            end

            disp('Saving project responses....');
            Resp = responses; %#ok<NASGU>
            save(config.out_files.resp_data, 'Resp', '-v7.3');
            obj.export_results(responses);
        end

        function export_folder = export_results(obj, responses)
            % export_results  Write the result tables of the run as CSV files (config as JSON).
            %   export_folder = model.export_results()
            %   export_folder = model.export_results(responses)
            %   Readable copy of the project responses, written to
            %   <workflow folder>\Export at the end of compute_responses
            %   (chess.Export.results lists the files). Without responses,
            %   the saved project responses file of the run is exported. A
            %   failed export warns and does not stop the run: the .mat
            %   results are already saved.
            if nargin < 2
                saved = load(obj.config.out_files.resp_data, 'Resp');
                responses = saved.Resp;
            end
            export_folder = '';
            try
                export_folder = chess.Export.results(responses, obj.config, obj.paths);
                disp(['Result tables (CSV) written to: ' export_folder]);
            catch export_error
                warning('chess:Model:exportFailed', 'Result tables (CSV) were not written: %s', export_error.message);
            end
        end

        function responses = compute_hydraulic_responses(obj, forcing, storm_maxima)
            % compute_hydraulic_responses  Structure responses of one forcing dataset.
            %   responses = model.compute_hydraulic_responses(forcing)
            %   responses = model.compute_hydraulic_responses(forcing, storm_maxima)
            %   forcing: one dataset of one storm type, PROS/DET struct (SWL,
            %   Hm0_toe, Hm0_offshore, Tp, storm_duration and dt for
            %   Timeseries; one cell per storm) or LCS cell of life-cycle
            %   matrices. The responses switched on in config are computed with
            %   the protection system:
            %     toe wave height Hm0_toe   -> run-up, overtopping, stone size,
            %                                  transmitted wave height, nappe
            %     offshore wave height      -> wall pressures, damaging depth
            %     Timeseries only           -> overtopping volume
            %   storm_maxima = true keeps only the responses fitted by PROS and
            %   returns their maximum per storm (default false: full histories).
            if nargin < 3
                storm_maxima = false;
            end
            responses = obj.hydraulic_responses(obj.config, forcing, double(storm_maxima));
        end
    end

    methods (Abstract, Access = protected)
        % Lay out the storms of the database for the workflow
        forcing = build_storm_forcing(obj, storm, prob_mass)
        % Responses of one forcing dataset (all its storm types)
        responses = dataset_responses(obj, dataset, data_type, dataset_name)
    end

    properties (Abstract, Constant, Access = protected)
        run_label   % name of the workflow in the progress messages
    end

    methods (Access = protected)
        function announce_run(obj) %#ok<MANU>
            % Messages printed before the responses (none by default)
        end

        function tf = uses_peaks_dataset(obj, name) %#ok<INUSD>
            % Peaks datasets processed by compute_responses (all by default)
            tf = true;
        end

        function config = note_saved_forcing(obj, config, forcing_file) %#ok<INUSD>
            % Details kept when a saved forcing is reused (none by default)
        end

        function data = apply_forcing_uncertainty(obj, data, storm_type) %#ok<INUSD>
            % Forcing uncertainty of one dataset (none by default)
        end

        function [storm, prob_mass] = read_requested_storms(obj)
            % Storm data of the database, cut down to what the run requests
            [storm, prob_mass] = obj.storm_database.read();
            storm = select_request(storm, storm_request(obj.config));
            if isfield(storm, 'TC') && (isempty(prob_mass) || isempty(prob_mass.TC_Freq))
                error('chess:Model:emptyProbabilityMass', 'The storm database holds TC storms but no probability masses (prob_mass.TC_Freq is empty): rebuild it with the CHS_Dependencies of the region.');
            end
        end

        function forcing = format_storm_forcing(obj, storm, prob_mass, with_replicates)
            % Storm database -> forcing with one cell per storm (PROS: one column per replicate; DET: one column)
            %   Each dataset: SWL, Hm0_offshore, Tp (nSteps x n_replicates per
            %   storm), storm_id, time, storm_duration [days], dt for
            %   Timeseries, TC_Prob for TC with replicates.
            config = obj.config;
            check_peaks_timeseries_ids(storm, config.storm_sampling);
            storm_types = chess.Common.storm_types_for_sampling(config.storm_sampling, {'TC','XC'});
            % Storm Data Columns: Peaks [SWL Hm0 Tp wDir datenum]; Timeseries [SWL Hm0 Tp wDir datenum dt]
            col_time = 5;
            for st = 1:length(storm_types)
                if with_replicates
                    chess.Common.disp_toggle(config.print_progress, ['Reshaping ' storm_types{st} ' forcing data for response base analysis....']);
                    % One Column Per Discrete Normal z-Score (XC 21, TC 445; z = 0 In The Middle Column)
                    n_replicates = numel(chess.Common.discrete_standard_normal_scores(storm_types{st}));
                else
                    chess.Common.disp_toggle(config.print_progress, ['Formatting ' storm_types{st} ' forcing data for deterministic analysis....']);
                    n_replicates = 1;
                end
                data_type = fieldnames(storm.(storm_types{st}));
                data_type(~contains(data_type, {'Peaks', 'Timeseries'})) = [];
                for kk = 1:length(data_type)
                    match_types = fieldnames(storm.(storm_types{st}).(data_type{kk}));
                    for ii = 1:length(match_types)
                        storm_rows = storm.(storm_types{st}).(data_type{kk}).(match_types{ii});
                        storm_data = storm_rows(:, 2);
                        data_out = struct();
                        data_out.SWL = cellfun(@(x) repmat(x(:, 1), 1, n_replicates), storm_data, 'un', false);
                        data_out.Hm0_offshore = cellfun(@(x) repmat(x(:, 2), 1, n_replicates), storm_data, 'un', false);
                        data_out.Tp = cellfun(@(x) repmat(x(:, 3), 1, n_replicates), storm_data, 'un', false);
                        data_out.storm_id = cell2mat(storm_rows(:, 1));
                        data_out.time = cellfun(@(x) x(:, col_time), storm_data, 'un', false);
                        if with_replicates && strcmp(storm_types{st}, 'TC')
                            data_out.TC_Prob = prob_mass.TC_Freq;
                        end
                        if strcmp(data_type{kk}, 'Timeseries')
                            data_out.dt = cellfun(@(x) x(:, end), storm_data, 'un', false);
                            durations = chess.Model.storm_durations(storm_data, config.storm_duration, config.compute_storm_duration,...
                                data_out.storm_id, storm_types{st});
                            data_out.storm_duration = cellfun(@(x, d) repmat(d, size(x, 1), 1), storm_data, num2cell(durations), 'un', false);
                        else % Peaks: config.storm_duration [days], no dt
                            data_out.storm_duration = num2cell(repmat(chess.Common.chess_units('convert', config.storm_duration, 'h', 'day'), size(storm_rows, 1), 1));
                        end
                        forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}) = data_out;
                    end
                end
            end
        end

        function data = apply_adjustments(obj, data, storm_type)
            % Random tide, sea level change and toe wave height of one dataset
            %   Random tide (apply_random_tides = 1 and an existing tide_file):
            %   the tide record is added to SWL from each storm's start hour;
            %   start hours already in config (tide_indx_<type>) are kept,
            %   else they are drawn and stored in config. Sea level change:
            %   swl_slr added to SWL. Hm0_toe: toe_wave_height of
            %   Hm0_offshore with the adjusted SWL. Hm0_offshore is kept.
            config = obj.config;
            switch config.workflow
                case {1, 2, 4}
                    SWL = data.SWL;
                    Hm0 = data.Hm0_offshore; % After Uncertainty, Before Depth Limitation
                    Tp = data.Tp;
                case 3 % LCS
                    C = chess.Common.lcs_columns();
                    SWL = cellfun(@(x) x(:, C.SWL), data, 'un', false);
                    Hm0 = cellfun(@(x) x(:, C.Hm0_offshore), data, 'un', false);
                    Tp = cellfun(@(x) x(:, C.Tp), data, 'un', false);
            end
            % Time Steps Per Storm
            storm_steps = forcing_storm_lengths(config.workflow, data);
            % Random Tide
            if exist(config.tide_file, 'file') == 2 && config.apply_random_tides == 1
                index_field = ['tide_indx_' lower(storm_type)];
                if ~isfield(config, index_field)
                    config.(index_field) = [];
                end
                tide = chess.BoundaryConditions.tides.read_series(config.tide_file);
                % Start Hours: Drawn If None Were Given; Each Storm Hydrograph Fits The Tide Record
                config.(index_field) = chess.BoundaryConditions.tides.start_hours(length(tide), storm_steps, config.(index_field));
                for column = 1:size(SWL, 2)
                    SWL(:, column) = cellfun(@(x, first_hour, n_steps) chess.BoundaryConditions.tides.random_tide(tide, x, first_hour, n_steps),...
                        SWL(:, column), config.(index_field), storm_steps, 'un', false);
                end
            end
            % Sea Level Change
            if config.swl_slr ~= 0
                for column = 1:size(SWL, 2)
                    SWL(:, column) = cellfun(@(x) chess.BoundaryConditions.water_levels.sea_level_change(x, config.swl_slr), SWL(:, column), 'un', false);
                end
            end
            % Wave Height At The Toe (Hm0_offshore Is Kept As Is)
            Hm0_toe = cellfun(@(h, t, s) obj.toe_wave_height(h, t, s), Hm0, Tp, SWL, 'un', false);
            switch config.workflow
                case {1, 2, 4}
                    data.SWL = SWL;
                    data.Hm0_toe = Hm0_toe;
                case 3
                    for jj = 1:length(SWL)
                        data{jj}(:, C.SWL) = SWL{jj};
                        data{jj}(:, C.Hm0_toe) = Hm0_toe{jj};
                    end
            end
            obj.config = config;
        end

        function Hm0_toe = toe_wave_height(obj, Hm0_offshore, Tp, SWL)
            % Wave height at the toe of the protection system
            %   Depth = SWL - toe elevation. With apply_depth_limitation = 1
            %   the wave height is limited to the depth-limited height and is
            %   NaN where the toe is dry (depth <= 0,
            %   chess.BoundaryConditions.waves.depth_limitation). With
            %   apply_depth_limitation = 0 Hm0_toe = Hm0_offshore; a dry toe is
            %   then caught by the depth rules of the responses (d <= 0: wave
            %   responses NaN). Surge-only responses are still computed.
            Hm0_toe = Hm0_offshore;
            if obj.config.apply_depth_limitation == 1
                depth = SWL - obj.protection_system.toe_elevation;
                Hm0_toe = chess.BoundaryConditions.waves.depth_limitation(Hm0_toe, Tp, depth, obj.config.gravity_constant);
            end
        end

        function shared_tide_start_hours(obj, forcing)
            % Tide start hours shared by the datasets of a storm (stored in config.tide_indx_<type>)
            %   LCS reference case: its start hours are reused when its life
            %   cycles were. Storm types with Timeseries: one start hour per
            %   storm, shared by Peaks and Timeseries. LCS CC: TC and XC start
            %   hours first, CC derived from them.
            config = load_reference_tide_indices(obj.config, forcing);
            obj.config = draw_tide_indices(config, forcing);
        end

        function forcing = stage1_forcing(obj)
            % Multi-line stage 2: the saved forcing of stage 1 with its waves transmitted behind stage 1
            %   Stage 1's storms, uncertainty, tides and sea level change are
            %   kept. Hm0_offshore of stage 2 = Hm0_toe of stage 1 times the
            %   transmission coefficient of the stage 1 rubble mound; Hm0_toe
            %   of stage 2 = toe_wave_height of it. A dry stage 1 toe (depth
            %   SWL - stage 1 toe elevation <= 0) gives Kt = NaN, so stage 2
            %   Hm0_offshore and Hm0_toe are NaN on that row.
            config = obj.config;
            stage1_config = config;
            stage1_config.case_name = config.multiline.stage1_alt;
            stage1_paths = chess.ProjectPaths.build(stage1_config);
            S = load(stage1_paths.out_files.project_forcing, 'project_forcing');
            % Stage 1 Rubble Mound Of The Run Its Forcing Comes From (Geometry Recorded When The Runs Were Coupled)
            saved = load(stage1_paths.out_files.config, 'structure');
            stage1_inputs = saved.structure;
            recorded = config.multiline.stage1_structure;
            for name = fieldnames(recorded)'
                stage1_inputs.(name{1}) = recorded.(name{1});
            end
            stage1_inputs.struc_type = 3;
            stage1_inputs.gravity_constant = config.gravity_constant;
            stage1 = chess.ProtectionSystem.create(stage1_inputs);
            stage1.multiline_stage = 1;
            transmit = @(Hm0, Tp, SWL) cellfun(@(h, t, s) stage1.transmitted_wave_height(h, t, s), Hm0, Tp, SWL, 'un', false);
            toe_height = @(Hm0, Tp, SWL) cellfun(@(h, t, s) obj.toe_wave_height(h, t, s), Hm0, Tp, SWL, 'un', false);
            forcing = transmit_stage1_waves(S.project_forcing, config.workflow, transmit, toe_height);
        end

        function Resp = hydraulic_responses(obj, config, project_forcing, get_max)
            % Structure responses of one forcing dataset for the response switches of config
            %   config may be a copy of the run configuration with other
            %   switches (PROS turns responses off and on between its steps).
            pse = obj.protection_system;
            workflow = config.workflow;
            response_switch = resolve_response_switches(config);
            [forcing, response_switch] = unpack_forcing(project_forcing, workflow, response_switch);
            % Any Primary (Non-Secondary) Structure Response Requested
            primary_switches = chess.Common.response_registry('output', 'switches', 'kind', 'response', 'pros_secondary_eb1', false);
            any_primary_response = any(cellfun(@(name) response_switch.(name), primary_switches) ~= 0);
            if any_primary_response
                switch pse.structure_type
                    case 2 % Floodwall
                        type_responses = floodwall_responses(pse, response_switch, forcing);
                    case {1, 3} % Levee & Rubblemound
                        type_responses = embankment_responses(pse, response_switch, forcing);
                end
                % Resp Is Created By Its First Response Field
                for name = fieldnames(type_responses)'
                    Resp.(name{1}) = type_responses.(name{1});
                end
                % Transmitted Wave Height (Incident Hm0 At The Toe x Kt)
                if response_switch.compute_wave_transmission == 1
                    [~, Kt] = cellfun(@(a, b, c) pse.transmitted_wave_height(a, b, c), forcing.Hm0, forcing.Tp, forcing.SWL, 'un', false);
                    switch workflow
                        case 1 % PROS-RB: Best-Estimate (z = 0) Incident Hm0 x Kt Replicates (Same As Forcing HCs)
                            Resp.Hm0t = cellfun(@(x, y) x(:, chess.Common.replicate_z0_col(size(x, 2))).*y, forcing.Hm0, Kt, 'un', false);
                        case {2, 3, 4} % DET, LCS, PROS-FB (Hm0 Is The Per-Sample Forcing)
                            Resp.Hm0t = cellfun(@(x, y) x.*y, forcing.Hm0, Kt, 'un', false);
                        otherwise
                            error('chess:Model:unsupportedWorkflow', 'Unsupported workflow %d (1 = PROS, 2 = DET, 3 = LCS, 4 = PROS-FB).', workflow);
                    end
                end
                % Damaging Depth: Offshore Elevation Of The Protection System (Set By compute_responses), Else Of config
                if response_switch.compute_damaging_depth == 1
                    if isempty(pse.offshore_elevation)
                        pse.offshore_elevation = config.offshore_elevation;
                    end
                    damaging_depth_ks = config.compute_damaging_depth_Ks;
                    [Resp.DamDepthElev, Resp.DamDepth] = cellfun(@(swl, hm0, tp) pse.damaging_depth(hm0, tp, swl, damaging_depth_ks),...
                        forcing.SWL, forcing.Hm0_off, forcing.Tp, 'un', false);
                end
                % Overtopping Volume: Timeseries Only, Progressive Per Storm [m^3/m]
                if response_switch.compute_q_vol == 1 && isfield(Resp, 'q') && isfield(Resp, 'q_wave_ot')
                    Resp.Q_vol = cellfun(@(q, dt, step) pse.overtopping_volume(q, dt, step), Resp.q, forcing.dt, forcing.q_step, 'un', false);
                    Resp.Q_vol_wave_ot = cellfun(@(q, dt, step) pse.overtopping_volume(q, dt, step), Resp.q_wave_ot, forcing.dt, forcing.q_step, 'un', false);
                end
            else % No Responses Computed
                Resp = [];
            end
            % Per-Storm Maxima Of The Fitted Responses
            if get_max == 1
                Resp = per_storm_peak_responses(Resp, response_switch, workflow);
            end
        end
    end

    methods (Static, Access = protected)
        function durations = storm_durations(storm_data, storm_duration, compute_storm_duration, storm_ids, storm_type)
            % Event length of each Timeseries storm of the storm database [days]
            %   compute_storm_duration ~= 1: storm_duration [hours] for every
            %   storm. compute_storm_duration == 1: duration of the SWL
            %   hydrograph of each storm (chess.BoundaryConditions.storm_duration:
            %   98 percent of the amplitude, shifted threshold, 1 h minimum)
            %   from its own database record, so a storm has the same duration
            %   in every replicate and life cycle. Flagged storms are printed.
            durations = repmat(chess.Common.chess_units('convert', storm_duration, 'h', 'day'), numel(storm_data), 1);
            if compute_storm_duration == 1 && ~isempty(storm_data)
                rows = cell(numel(storm_data), 1);
                for kk = 1:numel(storm_data)
                    rows{kk} = chess.BoundaryConditions.storm_duration(storm_data{kk}(:, 1), storm_data{kk}(:, 5), 0.98, true, 1);
                end
                T = struct2table(vertcat(rows{:}), 'AsArray', true);
                durations = chess.Common.chess_units('convert', T.duration_hr, 'h', 'day');
                report_flagged_storms(T, storm_ids(:), storm_type);
            end
        end
    end
end

%% LOCAL FUNCTIONS: SET-UP
function model = saved_run_model(config_file)
% Model of a saved run (config and structure of its config file)
S = load(config_file);
if ~isfield(S, 'config')
    error('chess:Model:notARunFile', '%s has no config variable: not a CHESS run configuration file.', config_file);
end
if isfield(S, 'structure')
    protection_system = chess.ProtectionSystem.create(chess.Model.stone_size_inputs(S.structure, S.config));
else
    protection_system = chess.ProtectionSystem.create(S.config);
end
storm_database = [];
if isfield(S.config, 'out_files') && isfield(S.config.out_files, 'storm_and_prob_mass') && isfile(S.config.out_files.storm_and_prob_mass)
    chs_dependencies = '';
    if isfield(S.config, 'chs_dependencies')
        chs_dependencies = S.config.chs_dependencies;
    end
    storm_database = chess.CoastalHazardSystem.load(S.config.out_files.storm_and_prob_mass, chs_dependencies);
end
model = chess.Model.for_workflow(S.config, protection_system, storm_database);
end

function [config, database, first_run] = connect_storm_data(config)
% Storm data of config.chs_zip: study details, run folders, storm database object
if ~exist(config.chs_zip, 'file')
    error('chess:Model:stormDataNotFound', 'Storm data file not found (config.chs_zip): %s.', config.chs_zip);
end
[~, file_name] = fileparts(config.chs_zip);
info = chess.CoastalHazardSystem.inspect(config.chs_zip);
request = storm_request(config);
is_storm_mat_input = strcmp(info.kind, 'storm_mat');
if is_storm_mat_input
    config.chs_files_2_convert = cell(0, 2);
    config.sp_ID = info.savepoint_id;
    config.sp_ID_wave = [];
    config.region = info.region;
    % Storm Database Named After The Provided File (Different Storm .mat Files Never Share A Database)
    if ~isfield(config, 'storm_db') || isempty(config.storm_db)
        config.storm_db = file_name;
    end
else
    % Study Identity, Storm File Slots & This Run's Request, By File Name (Before Any Unzip Or Conversion)
    [~, slot_errors] = chess.CoastalHazardSystem.storm_file_slots(info.storm_files, request);
    if ~isempty(slot_errors)
        error('chess:Model:incompleteStormFiles', 'CHS input ''%s'' does not meet the storm data requirements: %s.', config.chs_zip, strjoin(slot_errors, '; '));
    end
    config.region = info.region;
    config.sp_ID = info.savepoint_id;
    config.sp_ID_wave = info.wave_savepoint_id;
    % Without CHS_Dependencies For The Region CHESS Runs XC Only (TC Needs Its Probability Masses)
    chs_files = chess.CoastalHazardSystem.dependency_files(config.chs_dependencies, config.region);
    if ~strcmp(config.storm_sampling, 'XC') && ~chs_files.tropical_statistics_available
        error('chess:Model:noTropicalStatistics', '%s', chess.CoastalHazardSystem.dependencies_message(config.storm_sampling, config.region));
    end
end
% Storm Database & Alternative Folders
run_paths = chess.ProjectPaths.build(config);
if ~exist(run_paths.event_db_dir, 'dir')
    mkdir(run_paths.event_db_dir);
end
if ~exist(run_paths.wf_dir, 'dir')
    mkdir(run_paths.wf_dir);
end
database_exists = isfile(run_paths.storm_db);
raw_exists = isfile(run_paths.chs_data);
database = chess.CoastalHazardSystem(config.chs_zip, config.chs_dependencies, run_paths.storm_db);
% Existing Database: Its db_info Sets Nyrs_XC/Nstm_XC, TC Bias Correction, Bias & Uncertainty
if database_exists
    if chess.CoastalHazardSystem.is_valid_db_info(database.db_info)
        config = chess.Model.apply_storm_database_info(database.db_info, config);
    elseif is_storm_mat_input
        % Older Database (No db_info) Of A Storm .mat Input: Created Again From The Provided File
        database_exists = false;
    end
end
if is_storm_mat_input
    if ~database_exists
        database.import_user_storm(request.storm_sampling, request.use_peaks, request.use_timeseries, request.create_wlp, request.create_whp);
        config = chess.Model.apply_storm_database_info(database.db_info, config);
    end
else
    config.chs_files_2_convert = [info.storm_file_folders(:), info.storm_files(:)];
    config.sp_lat = database.savepoint_latitude;
    config.sp_lon = database.savepoint_longitude;
end
first_run = ~database_exists && ~raw_exists;
end

function request = storm_request(config)
% Storm data a run requests (WLP/WHP need Peaks and Timeseries)
both = config.use_peaks == 1 && config.use_timeseries == 1;
request = struct('storm_sampling', config.storm_sampling, 'use_peaks', config.use_peaks, 'use_timeseries', config.use_timeseries,...
    'create_wlp', +(both && config.create_wlp == 1), 'create_whp', +(both && config.create_whp == 1));
end

function storm_request_error(database_exists, storm_type_ok, data_type_ok, datasets_ok, has_info, request, is_storm_mat_input)
if is_storm_mat_input
    error_msg = "The request on the configuration file is not in the provided storm data (storm .mat input: no rebuild possible):";
else
    error_msg = "The storm data does not cover the run request: provided storm data failed to meet user request on configuration file. inspection failed on:";
end
if ~database_exists
    error_msg = error_msg + newline + "No storm database and no CHS files to build it from.";
elseif ~storm_type_ok
    error_msg = error_msg + newline + sprintf("Missing storm data per requested storm sampling (%s; TC needs its probability masses).", request.storm_sampling);
elseif ~data_type_ok
    error_msg = error_msg + newline + sprintf("Missing peaks or timeseries data per use_peaks = %d / use_timeseries = %d.", request.use_peaks, request.use_timeseries);
elseif ~datasets_ok
    error_msg = error_msg + newline + sprintf("Missing peaks data, make sure you have the requested datasets (Default, WLP = %d, WHP = %d).", request.create_wlp, request.create_whp);
elseif ~has_info
    error_msg = error_msg + newline + "The storm database has no db_info (older CHESS version) and no raw file to rebuild it from: rebuild the storm database from its original input.";
end
error('chess:Model:stormDataNotCovered', '%s', error_msg);
end

function report_chs_dependencies(config)
if ~isfield(config, 'region')
    chs_region = 'NoRegion';
else
    chs_region = config.region;
end
chs_files = chess.CoastalHazardSystem.dependency_files(config.chs_dependencies, chs_region);
if chs_files.tropical_statistics_available
    disp('External CHS_Dependencies folder found...');
elseif chs_files.folder_exists && chs_files.region_supported
    disp(['External CHS_Dependencies folder found (no TC statistics for ' chs_region ': XC only)...']);
else
    disp('CHS_Dependencies not found. Running in XC-only mode...');
end
end

function print_welcome_banner(workflow)
switch workflow
    case {1, 4}
        workflow_line = '***       CHESS: Probabilistic Responses of Structures (PROS)        ***';
    case 2
        workflow_line = '***          CHESS: Deterministic Structure Responses (DET)          ***';
    case 3
        workflow_line = '***                CHESS: Life Cycle Simulation (LCS)                ***';
end
disp(['************************************************************************' newline...
    '***    Coastal Hazards, Engineering and Structures System (CHESS)    ***' newline...
    workflow_line newline...
    '***                          Version 1.0.0                           ***' newline...
    '***                        FOR  TESTING  ONLY                        ***' newline...
    '************************************************************************']);
end

%% LOCAL FUNCTIONS: MULTI-LINE
function data = transmit_stage1_waves(data, workflow, transmit, toe_height)
% One dataset (PROS/DET struct with Hm0_toe, LCS cell of life cycles), else recurse into data / match / storm types
%   Rows with a dry stage 1 toe come back with NaN stage 2 waves (Kt NaN in transmitted_wave_height).
if workflow == 3 && iscell(data)
    C = chess.Common.lcs_columns();
    SWL = cellfun(@(x) x(:, C.SWL), data, 'un', false);
    Tp = cellfun(@(x) x(:, C.Tp), data, 'un', false);
    Hm0_off = transmit(cellfun(@(x) x(:, C.Hm0_toe), data, 'un', false), Tp, SWL);
    Hm0_toe = toe_height(Hm0_off, Tp, SWL);
    for jj = 1:numel(data)
        data{jj}(:, C.Hm0_offshore) = Hm0_off{jj};
        data{jj}(:, C.Hm0_toe) = Hm0_toe{jj};
    end
elseif isstruct(data) && isfield(data, 'Hm0_toe')
    data.Hm0_offshore = transmit(data.Hm0_toe, data.Tp, data.SWL);
    data.Hm0_toe = toe_height(data.Hm0_offshore, data.Tp, data.SWL);
elseif isstruct(data)
    for fn = fieldnames(data)'
        data.(fn{1}) = transmit_stage1_waves(data.(fn{1}), workflow, transmit, toe_height);
    end
end
end

%% LOCAL FUNCTIONS: STRUCTURE RESPONSES
function [forcing, response_switch] = unpack_forcing(project_forcing, workflow, response_switch)
% Forcing fields per workflow (PROS/DET datasets or LCS life cycles), one cell per storm or life cycle
%   Hm0: at the toe (depth limited), used by every toe response. Hm0_off:
%   before depth limitation, used by the wall pressures and the damaging
%   depth. storm_dur and dt in days.
switch workflow
    case {1, 2, 4} % RB, DET, FB
        forcing.SWL = project_forcing.SWL;
        forcing.Hm0 = project_forcing.Hm0_toe;
        forcing.Hm0_off = project_forcing.Hm0_offshore;
        forcing.Tp = project_forcing.Tp;
        forcing.storm_dur = project_forcing.storm_duration; % Event Length [days]
        % Row Time Step [days]: Timeseries Only (Peaks Have No dt, So No Overtopping Volume)
        if isfield(project_forcing, 'dt')
            forcing.dt = project_forcing.dt;
        else
            forcing.dt = [];
            response_switch.compute_q_vol = 0;
        end
        forcing.q_step = cell(size(forcing.SWL));
    case 3 % LCS
        C = chess.Common.lcs_columns();
        forcing.SWL = cellfun(@(x) x(:, C.SWL), project_forcing, 'un', false);
        forcing.Hm0 = cellfun(@(x) x(:, C.Hm0_toe), project_forcing, 'un', false);
        forcing.Hm0_off = cellfun(@(x) x(:, C.Hm0_offshore), project_forcing, 'un', false);
        forcing.Tp = cellfun(@(x) x(:, C.Tp), project_forcing, 'un', false);
        % Timeseries Life Cycles (Storms Start At step == 0); Peaks Life Cycles Have One Row Per Storm
        is_ts = cellfun(@(x) size(x, 2) == C.n_timeseries, project_forcing);
        % Event Length [days]: Last Column Of Either Layout (Peaks 10, Timeseries 12)
        sd_col = [C.storm_duration, chess.Common.lcs_columns('Timeseries').storm_duration];
        forcing.storm_dur = cellfun(@(x, a) x(:, sd_col(1 + a)), project_forcing, num2cell(is_ts), 'un', false);
        % Row Time Step [days] And Storm Step: Timeseries Life Cycles Only (Empty For Peaks)
        forcing.dt = cellfun(@(x, a) ts_column(x, C.dt, a), project_forcing, num2cell(is_ts), 'un', false);
        forcing.q_step = cellfun(@(x, a) ts_column(x, C.step, a), project_forcing, num2cell(is_ts), 'un', false);
        % Overtopping Volume Is Timeseries Only, Even If The Switch Arrives On For Peaks Life Cycles
        if ~any(is_ts)
            response_switch.compute_q_vol = 0;
        end
end
end

function Resp = floodwall_responses(pse, response_switch, forcing)
% Floodwall: overtopping, Goda wall pressures (offshore wave height), nappe
Resp = struct();
if response_switch.compute_q == 1 || response_switch.compute_nappe == 1
    [~, ~, Resp.q, ~, Resp.q_wave_ot] = cellfun(@(hm0, tp, swl) pse.runup_and_overtopping(hm0, tp, swl),...
        forcing.Hm0, forcing.Tp, forcing.SWL, 'un', false);
end
if response_switch.compute_p1 == 1 || response_switch.compute_p2_p3 == 1
    distribution = response_switch.compute_p2_p3 == 1;
    P = cellfun(@(hm0, tp, swl) pse.wall_pressures(hm0, tp, swl, [], distribution), forcing.Hm0_off, forcing.Tp, forcing.SWL, 'un', false);
    Resp.p1 = cellfun(@(s) s.p1, P, 'un', false);
    if response_switch.compute_p2_p3 == 1
        p_names = chess.Common.response_registry('output', 'names', 'compute_switch', 'compute_p2_p3');
        for pp = 1:length(p_names)
            Resp.(p_names{pp}) = cellfun(@(s) s.(p_names{pp}), P, 'un', false);
        end
    end
end
if response_switch.compute_nappe == 1
    nappe = cellfun(@(hm0, swl, q) pse.nappe_jet(hm0, swl, q), forcing.Hm0, forcing.SWL, Resp.q, 'un', false);
    n_names = chess.Common.response_registry('output', 'names', 'compute_switch', 'compute_nappe');
    for nn = 1:length(n_names)
        Resp.(n_names{nn}) = cellfun(@(s) s.(n_names{nn}), nappe, 'un', false);
    end
end
end

function Resp = embankment_responses(pse, response_switch, forcing)
% Levee and rubble mound: run-up and overtopping; rubble mound stone sizes
Resp = struct();
if response_switch.compute_r2p == 1 || response_switch.compute_q == 1 || response_switch.compute_q_vol == 1
    [Resp.R2p, Resp.R2p_SWL, Resp.q, ~, Resp.q_wave_ot] = cellfun(@(hm0, tp, swl) pse.runup_and_overtopping(hm0, tp, swl),...
        forcing.Hm0, forcing.Tp, forcing.SWL, 'un', false);
end
% Rubble Mound Stone Size: The Number Of Waves Uses The Storm Duration (Event Length), Never dt
if pse.structure_type == 3 && (response_switch.compute_dn50_seaside == 1 || response_switch.compute_dn50_leeside == 1)
    [Dn50_seaside, Dn50_leeside] = cellfun(@(hm0, tp, swl, duration) pse.stone_sizes(hm0, tp, swl, duration),...
        forcing.Hm0, forcing.Tp, forcing.SWL, forcing.storm_dur, 'un', false);
    if response_switch.compute_dn50_seaside == 1
        Resp.Dn50 = Dn50_seaside;
    end
    if response_switch.compute_dn50_leeside == 1
        Resp.Dn50_Lee = Dn50_leeside;
    end
end
end

function response_switch = resolve_response_switches(config)
% Grab Structure Response Switches (Registry Compute Switches; compute_q_vol Is 0 For Peaks Calls And FB)
response_switch = struct();
for switch_name = chess.Common.response_registry('output', 'switches')
    response_switch.(switch_name{1}) = config.(switch_name{1});
end
% Remove Responses Not Applicable To The Structure Type
switches_off = setdiff(chess.Common.response_registry('output', 'switches'),...
    chess.Common.response_registry('output', 'switches', 'structure_type', config.struc_type), 'stable');
for switch_name = switches_off
    response_switch.(switch_name{1}) = 0;
end
% Dependencies: P2/P3 Need P1 (Floodwall); Nappe And Overtopping Volume Need q
if response_switch.compute_p2_p3 == 1
    response_switch.compute_p1 = 1;
end
% compute_q_vol turns compute_q on for the run (chess.Config.apply_rules applies the same rule), even on calls
% where unpack_forcing later switches Q_vol off (Peaks)
if response_switch.compute_nappe == 1 || response_switch.compute_q_vol == 1
    response_switch.compute_q = 1;
end
end

function Resp = per_storm_peak_responses(Resp, response_switch, workflow)
% No Responses Computed (Every Switch Off): Nothing To Reduce
if isempty(Resp)
    return
end
% Responses Fitted By PROS-RB Whose Compute Switch Is On (Q_vol* Only When compute_q_vol Is On)
fitted_rows = chess.Common.response_registry('fitted_by_pros_rb', true);
fitted_on = arrayfun(@(row) response_switch.(row.compute_switch) == 1, fitted_rows);
vars_to_find = {fitted_rows(fitted_on).name};
% Evaluate According To Workflow
switch workflow
    case {1, 2, 4} % Find Max Responses For Timeseries (RB3)
        % Remove Unwanted Fields
        rm_indx = sum(cell2mat(cellfun(@(x) strcmp(fieldnames(Resp), x), vars_to_find, 'un', false)), 2) == 0;
        if any(rm_indx)
            rm_names = fieldnames(Resp);
            Resp = rmfield(Resp, rm_names(rm_indx));
        end
        % Loop Through Each Response
        vars_to_find = vars_to_find(isfield(Resp, vars_to_find)); % Q_vol* Only When The Overtopping Fields Exist
        for vv = 1:length(vars_to_find)
            Resp.(vars_to_find{vv}) = cell2mat(cellfun(@(x) max(x,[],1), Resp.(vars_to_find{vv}), 'un', false));
        end
end
end

function v = ts_column(x, col, is_timeseries)
% Column Of A Timeseries Life Cycle (dt, step), Empty For Peaks
if is_timeseries
    v = x(:, col);
else
    v = [];
end
end

function t_size = forcing_storm_lengths(workflow, data)
% forcing_storm_lengths  Time steps per storm of one project forcing dataset.
%   t_size = forcing_storm_lengths(workflow, data)
%
%   Time steps per storm of one project forcing dataset (one data type >
%   match type > storm type), as used by the random tide: a storm covers
%   tide hours idx : idx + t_size - 1. Peaks storms have one time step.
%
%   Inputs:
%     workflow - workflow number (config workflow), double
%     data     - PROS/DET dataset (SWL: one cell per storm), struct; or LCS
%                dataset (one life-cycle matrix per cell; Peaks or
%                Timeseries layout, chess.Common.lcs_columns), cell
%   Outputs:
%     t_size - PROS/DET: one cell per storm holding its row count. LCS: one
%              cell per life cycle holding a column of per-storm lengths
%              (empty life cycle: 0x1), cell
%
%   See also chess.BoundaryConditions.tides.random_tide, chess.BoundaryConditions.tides.start_hours, draw_tide_indices,
%   chess.Common.lcs_columns.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

switch workflow
    case {1, 2, 4}
        t_size = cellfun(@(x) size(x,1), data.SWL, 'un', false);
    case {3} % LCS
        if size(data{1}, 2) == chess.Common.lcs_columns().n_timeseries % Timeseries Layout (Step Counter Column)
            t_size = cellfun(@storm_lengths, data, 'un', false);
        else
            t_size = cellfun(@(x) ones(size(x, 1), 1), data, 'un', false);
        end
        % Logic Behind storm_lengths
        % Add nan on top -> Keep Dimensions Consistent But Remove 0 of first Storm
        % Add Zero To End -> Want to flag final timestep of final storm
        % - 1 -> Gives the end row index of each storm
        % + 1 -> The Step Counter Goes From 0:n_stsp-1 Hence Need To Add 1 To Get Proper Length
end
end

function t_size = storm_lengths(x)
if isempty(x) % Life Cycle Without Storms
    t_size = zeros(0, 1);
else
    step = chess.Common.lcs_columns().step;
    t_size = x(find([nan;x(2:end, step);0]== 0)-1, step)+1;
end
end

function config = draw_tide_indices(config, project_forcing)

if config.apply_random_tides ~= 1 || exist(config.tide_file, 'file') ~= 2
    return
end
has_ts = isfield(project_forcing, 'Timeseries');
has_peaks = isfield(project_forcing, 'Peaks');
is_cc = config.workflow == 3 && ((has_peaks && isfield(project_forcing.Peaks.Default, 'CC')) ||...
    (has_ts && isfield(project_forcing.Timeseries.Default, 'CC')));
if ~has_ts && ~is_cc
    return
end
n_tide = numel(chess.BoundaryConditions.tides.read_series(config.tide_file));
if has_ts
    for st = setdiff(fieldnames(project_forcing.Timeseries.Default)', {'CC'}, 'stable')
        config = draw_type(config, st{1}, project_forcing.Timeseries.Default.(st{1}), n_tide);
    end
end
if is_cc
    if has_peaks
        % Storms Already Drawn From Their Timeseries Fit, So The Peaks Pass Keeps Them As Given
        for st = chess.Common.storm_types_for_sampling('CC', {'TC', 'XC'})
            config = draw_type(config, st{1}, project_forcing.Peaks.Default.(st{1}), n_tide);
        end
        storm_rows = project_forcing.Peaks.Default;
    else
        storm_rows = timeseries_first_step_rows(project_forcing.Timeseries.Default);
    end
    config.tide_indx_cc = cc_tide_indices(config.tide_indx_tc, config.tide_indx_xc, storm_rows);
end
end

function config = draw_type(config, st_type, data, n_tide)
fld = ['tide_indx_' lower(st_type)];
if ~isfield(config, fld)
    config.(fld) = [];
end
config.(fld) = chess.BoundaryConditions.tides.start_hours(n_tide, forcing_storm_lengths(config.workflow, data), config.(fld));
end

function storm_rows = timeseries_first_step_rows(timeseries)
step = chess.Common.lcs_columns().step;
for st = {'TC', 'XC', 'CC'}
    storm_rows.(st{1}) = cellfun(@(x) x(x(:, step) == 0, :), timeseries.(st{1}), 'un', false);
end
end

function cc = cc_tide_indices(tc, xc, storm_rows)
cc = cell(size(storm_rows.CC));
for lc = 1:numel(cc)
    C = chess.Common.lcs_columns();
    [~, p] = sortrows([storm_rows.TC{lc}; storm_rows.XC{lc}], [C.year, C.order, C.bin]);
    stacked = [tc{lc}(:); xc{lc}(:)];
    cc{lc} = stacked(p);
end
end

function config = load_reference_tide_indices(config, project_forcing)

if ~isfield(config, 'workflow') || config.workflow ~= 3 ||...
        ~isfield(config, 'load_project_forcing') || config.load_project_forcing ~= 1 ||...
        ~isfield(config, 'apply_random_tides') || config.apply_random_tides ~= 1
    return
end
% Reference Case Config: Same Project/PSE, Alternative ref_case_name, LCS, Same Storm DB (chess.ProjectPaths.build)
paths = chess.ProjectPaths.build(config);
ref_paths = chess.ProjectPaths.build(config.outfolder, config.project_name, config.struc_id, config.ref_case_name, 3, paths.db);
ref_cfg = ref_paths.out_files.config;
if ~isfile(ref_cfg)
    return
end
ref = load(ref_cfg, 'config');
ref = ref.config;
% Same Tide File Only (Start Hours Point Into That File)
if ~isfield(ref, 'tide_file') || ~strcmp(char(ref.tide_file), char(config.tide_file))
    disp(['     Tides: reference case ' config.ref_case_name ' used a different tide file; drawing new tide start hours.']);
    return
end
% Storm Types Whose Life Cycles Were Reused From The Reference (Same Rule As chess.Model.LifeCycle)
reuse = chess.Model.LifeCycle.reference_reuse(config);
for st = chess.Common.storm_types_for_sampling(config.storm_sampling, {'TC', 'XC'})
    fld = ['tide_indx_' lower(st{1})];
    if ~isfield(ref, fld) || isempty(ref.(fld)) || (isfield(config, fld) && ~isempty(config.(fld)))
        continue
    end
    storms_per_lc = lc_storm_counts(project_forcing, st{1});
    if isempty(storms_per_lc)
        continue
    end
    if ~strcmp(reuse.src.(st{1}), 'Reference')
        disp(['     Tides: ' st{1} ' life cycles were not reused from reference case ' config.ref_case_name '; drawing new tide start hours.']);
        continue
    end
    ref_idx = ref.(fld)(:);
    if numel(ref_idx) == numel(storms_per_lc) && isequal(cellfun(@numel, ref_idx), storms_per_lc)
        config.(fld) = ref.(fld);
        disp(['     Tides: reusing ' st{1} ' tide start hours from reference case ' config.ref_case_name '.']);
    else
        disp(['     Tides: ' st{1} ' life cycles differ from reference case ' config.ref_case_name '; drawing new tide start hours.']);
    end
end
end

function counts = lc_storm_counts(project_forcing, st_type)
counts = [];
if isfield(project_forcing, 'Peaks') && isfield(project_forcing.Peaks, 'Default') && isfield(project_forcing.Peaks.Default, st_type)
    counts = cellfun(@(x) size(x, 1), project_forcing.Peaks.Default.(st_type)(:));
elseif isfield(project_forcing, 'Timeseries') && isfield(project_forcing.Timeseries.Default, st_type)
    step = chess.Common.lcs_columns().step;
    counts = cellfun(@(x) sum(x(:, step) == 0), project_forcing.Timeseries.Default.(st_type)(:));
end
end

function report_flagged_storms(T, storm_ids, storm_type)
flags = {
    'edge_start',        'no up-crossing before the peak, record start used'
    'edge_end',          'no down-crossing after the peak, record end used'
    'threshold_shifted', 'record starts or ends above the threshold, threshold raised'
    'min_applied',       'duration below the 1 h minimum, minimum used'
    'flat_signal',       'flat SWL, whole record used'};
flagged = false(height(T), 1);
for k = 1:size(flags, 1)
    flagged = flagged | T.(flags{k, 1});
end
fprintf('               %s storm durations (compute_storm_duration = 1): %d of %d storms flagged\n', storm_type, nnz(flagged), height(T));
for k = 1:size(flags, 1)
    ids = storm_ids(T.(flags{k, 1}));
    if ~isempty(ids)
        fprintf('                  %s (%s), %d storms: %s\n', flags{k, 1}, flags{k, 2}, numel(ids), strjoin(compose('%d', ids), ', '));
    end
end
end

function storm = select_request(storm, request)
switch request.storm_sampling
    case 'TC'
        if isfield(storm,'XC'), storm = rmfield(storm,'XC'); end
    case 'XC'
        if isfield(storm,'TC'), storm = rmfield(storm,'TC'); end
end
for jj = intersect(fieldnames(storm)', {'TC','XC'})
    if request.use_peaks == 0 && isfield(storm.(jj{:}), 'Peaks')
        storm.(jj{:}) = rmfield(storm.(jj{:}), 'Peaks');
    end
    if request.use_timeseries == 0 && isfield(storm.(jj{:}), 'Timeseries')
        storm.(jj{:}) = rmfield(storm.(jj{:}), 'Timeseries');
    end
    if isfield(storm.(jj{:}), 'Peaks')
        if request.create_wlp == 0 && isfield(storm.(jj{:}).Peaks, 'WLP')
            storm.(jj{:}).Peaks = rmfield(storm.(jj{:}).Peaks, 'WLP');
        end
        if request.create_whp == 0 && isfield(storm.(jj{:}).Peaks, 'WHP')
            storm.(jj{:}).Peaks = rmfield(storm.(jj{:}).Peaks, 'WHP');
        end
    end
end
end

function config = reset_forcing_cache(config)
for ff = {config.out_files.project_forcing, chess.ProjectPaths.sampling_seed_file(config.out_files.project_forcing)}
    if isfile(ff{1})
        delete(ff{1});
    end
end
config.hotstart_level = 'resample';
config = rmfield(config, intersect(fieldnames(config), {'tide_indx_tc', 'tide_indx_xc', 'tide_indx_cc', 'forcing_stamp'}));
end

function check_peaks_timeseries_ids(storm, storm_sampling)
storm_types = chess.Common.storm_types_for_sampling(storm_sampling, {'TC', 'XC'});
for st = storm_types
    if ~all(isfield(storm.(st{1}), {'Peaks', 'Timeseries'}))
        continue
    end
    ts_id = cell2mat(storm.(st{1}).Timeseries.Default(:, 1));
    for mt = fieldnames(storm.(st{1}).Peaks)'
        pk_id = cell2mat(storm.(st{1}).Peaks.(mt{1})(:, 1));
        n = min(numel(pk_id), numel(ts_id));
        k = find(pk_id(1:n) ~= ts_id(1:n), 1);
        if ~isempty(k)
            error('chess:Model:peaksTimeseriesIdMismatch',...
                '%s storm IDs of Peaks (%s) and Timeseries differ: first mismatch at row %d (Peaks ID %d, Timeseries ID %d).',...
                st{1}, mt{1}, k, pk_id(k), ts_id(k));
        elseif numel(pk_id) ~= numel(ts_id)
            error('chess:Model:peaksTimeseriesIdMismatch',...
                '%s storm counts of Peaks (%s) and Timeseries differ: %d vs %d storms.',...
                st{1}, mt{1}, numel(pk_id), numel(ts_id));
        end
    end
end
end

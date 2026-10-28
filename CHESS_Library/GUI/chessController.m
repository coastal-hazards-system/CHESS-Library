classdef chessController < handle
    % CHESS GUI Controller (No Widgets): Loaded Projects, Active Selection, Run Tab Inputs And The Run Path. The App Writes
    % inputs / selection (set_input, set_run_selection) And Shows What The Controller Reports; The Controller Never Reads
    % Widgets. Usable From Scripts And Tests Without The App.
    %   Questions: plan_run Returns Them As Data (struct id, kind, title, text, items, choices, default, size); The Caller
    %   Answers In answers.(id) And Calls Again (An Empty Answer Cancels).
    %   Messages: Queued (severity 'info' | 'warning' | 'error' | 'status', title, text); take_messages Returns And Clears
    %   Them ('status': Run Tab Status Bar Text).
    %   View Flags: Every Mutating Method Marks The Views It Made Stale (VIEWS, Fixed Refresh Order); take_changed Returns
    %   And Clears Them.

    properties (SetAccess = private)
        project = [] % Active chessProject ([] If None)
        projects = [] % Loaded chessProject Column
        selection = struct('pse', '', 'alt', '', 'db', '', 'workflow', 1) % Active PSE/Alternative, Run Tab Storm DB + Workflow
        inputs = struct() % Run Tab Values: CONTROL_INPUTS + Inputs Table Values Of Every Workflow (Config Field Names)
        results = [] % Loaded Results (Stage 2)
        simKey = '' % Saved Simulation Key Last Resolved (Stage 2)
        declinedKey = '' % Saved Simulation Key Whose Load Was Declined (Stage 2)
        runActive = false % A Run Is In Progress (run_guard)
        lock = [] % Lock Of The Active Project Folder (lock_project: struct proj, lock); Released By The Destructor
        snapshot = struct('context', '', 'values', {cell(0, 2)}) % Run Tab Snapshot (Control, Value Rows) And Its Context '<project>|<pse>|<alt>'
        storm % Loaded storm / CHS_Data Keyed By File (containers.Map, Stage 2)
        changed = {} % Stale Views (VIEWS Names)
    end

    properties (Access = private)
        messages = struct('severity', {}, 'title', {}, 'text', {}) % Queued Messages (take_messages)
        drift = cell(0, 5) % Multi-Line Stage 1 Drift To Ask About (take_drift): {proj, pse, s1_alt, db_wf, kind}
        runRequest = [] % Run Tab Storm DB + Workflow Of A Clicked Bundle (select_bundle), Taken Once By The Run Tab Refresh
        lcsCheck = [] % Last LCS Convergence Question (lcs_question): struct(config, q, n_req), Reused While config Is Unchanged
        oldDbWarned = {} % Storm DB Files (output_paths.storm_db) Already Warned As Older CHESS Version (Once Per Session)
    end

    properties (Constant)
        % Refresh Order: The PSE Tab After The Run Tab (A Multi-Line Stage 2 Plot Follows Its Storm DB + Workflow)
        VIEWS = {'tree', 'project_panel', 'stormdb', 'run_controls', 'inputs_table', 'pse', 'constants', 'results', 'status'}
        CONTROL_INPUTS = {'storm_sampling', 'data_types', 'swl_slr', 'tide_file', 'apply_depth_limitation', 'responses'}
        GRAVITY = 9.80665 % m/s^2, Library Value (Setup/call_input_parser.m)
    end

    %% CONSTRUCTOR / DESTRUCTOR
    methods
        function obj = chessController()
            % Empty Controller: Every View Stale (The First Refresh Draws The Empty State)
            obj.storm = containers.Map();
            obj.mark(obj.VIEWS);
        end

        function delete(obj)
            % Project Lock Released However The Controller Goes
            if ~isempty(obj.lock)
                chessProject.release_lock(obj.lock.lock);
            end
        end
    end

    %% STAGE 0: PROJECTS, SELECTION, INPUTS, FLAGS
    methods
        function add_project(obj, proj)
            % Append A Loaded Project And Make It Active (Per-Alternative Fields Kept Sized)
            obj.projects = [obj.projects; proj];
            obj.select(proj.name, '', '');
            proj.sync_alt_fields();
        end

        function remove_project(obj, proj)
            % Drop A Loaded Project (Import Rollback). The Active Selection Is Left To The Caller (select)
            if ~isempty(obj.projects)
                obj.projects = obj.projects(obj.projects ~= proj);
            end
            if isequal(obj.project, proj)
                obj.project = [];
            end
            obj.mark({'tree', 'project_panel'});
        end

        function select(obj, proj_name, pse_name, alt_name)
            % Single Place That Resolves The Active Project/PSE/Alternative. Unknown Or Empty Names Fall Back To The First
            % Available Entry
            obj.project = [];
            obj.selection.pse = '';
            obj.selection.alt = '';
            obj.mark(obj.VIEWS);
            if isempty(obj.projects)
                return
            end
            k = find(strcmp(proj_name, {obj.projects.name}), 1);
            if isempty(k)
                k = 1;
            end
            obj.project = obj.projects(k);
            pse_list = obj.project.pse_list;
            if isempty(pse_list)
                return
            end
            if ~any(strcmp(pse_name, pse_list))
                pse_name = pse_list{1};
            end
            obj.project.set_working_pse(pse_name);
            obj.selection.pse = pse_name;
            alt_list = obj.project.alternative_list{obj.project.pse_indx};
            if isempty(alt_list)
                return
            end
            if ~any(strcmp(alt_name, alt_list))
                alt_name = alt_list{1};
            end
            obj.project.set_working_alt(pse_name, alt_name);
            obj.selection.alt = alt_name;
        end

        function set_run_selection(obj, db_name, workflow)
            % Run Tab Storm DB ('' Without One) And Workflow (1 PROS-RB, 2 DET, 3 LCS, 4 PROS-FB)
            obj.selection.db = char(db_name);
            obj.selection.workflow = workflow;
        end

        function set_input(obj, name, value)
            % One Run Tab Value (CONTROL_INPUTS Or An Inputs Table Row)
            obj.inputs.(name) = value;
        end

        function clear_table_inputs(obj)
            % Inputs Table Values Of Every Workflow Dropped (Run Tab Controls Kept)
            obj.inputs = rmfield(obj.inputs, obj.table_fields());
        end

        function drop_inputs(obj, names)
            % Inputs Table Values Dropped (Names Not Held Are Ignored)
            obj.inputs = rmfield(obj.inputs, intersect(fieldnames(obj.inputs), names));
        end

        function names = table_fields(obj)
            % Inputs Table Value Names Held (Every Workflow, Hidden Rows Included)
            names = setdiff(fieldnames(obj.inputs), obj.CONTROL_INPUTS, 'stable');
        end

        function [pse_name, alt_name] = active_names(obj)
            % Active PSE/Alternative Names ('' When None)
            pse_name = obj.selection.pse;
            alt_name = obj.selection.alt;
        end

        function tf = has_active_alt(obj)
            % True When The Active Project Has An Active PSE And Alternative
            tf = ~isempty(obj.project) && ~isempty(obj.selection.pse) && ~isempty(obj.selection.alt);
        end

        function touch(obj, views)
            % Views The Caller Made Stale (e.g. A Run Tab Widget Changed); Drawn By The Next Refresh
            obj.mark(views);
        end

        function views = take_changed(obj)
            % Stale Views In Refresh Order (VIEWS), Then Cleared
            views = obj.VIEWS(ismember(obj.VIEWS, obj.changed));
            obj.changed = {};
        end

        function msgs = take_messages(obj)
            % Queued Messages In Order, Then Cleared
            msgs = obj.messages;
            obj.messages(:) = [];
        end

        function d = take_drift(obj)
            % Multi-Line Stage 1 Drift Found By sim_rows ({proj, pse, s1_alt, db_wf, kind} Rows), Then Cleared
            d = obj.drift;
            obj.drift = cell(0, 5);
        end
    end

    %% STAGE 1: RUN PATH
    methods
        function [out_path, out_dir, wflow_folder, wflow_name, out_files] = config_path(obj)
            % Run Folder & File Names From The Library's chess_paths (Same Layout As The Library):
            % <project>\PSE\<pse>\<alt>\<workflow folder>\<db>_<workflow>_*, Per Storm DB So Runs With Different DBs Do Not
            % Overwrite Each Other
            paths = chess_paths(obj.project.path, obj.project.name, obj.selection.pse, obj.selection.alt,...
                obj.selection.workflow, obj.selection.db);
            out_dir = paths.wf_dir;
            wflow_folder = paths.wf_folder;
            wflow_name = paths.wflow_name;
            out_files = paths.out_files;
            out_path = out_files.config;
        end

        function key = sim_key(obj)
            % Saved Simulation Key: Config File Of Alternative + Workflow + Run Tab Storm DB ('' Without Both)
            key = '';
            if obj.has_active_alt() && ~isempty(obj.selection.db)
                key = obj.config_path();
            end
        end

        function [tf, label, run_date] = saved_sim(obj)
            % Saved Simulation For The Current Key (Config + Responses Files), "<alt> / <workflow> / <DB>", Run Date
            [config_file, ~, ~, wflow_name, out_files] = obj.config_path();
            tf = isfile(config_file) && isfile(out_files.resp_data);
            label = sprintf('%s / %s / %s', obj.selection.alt, wflow_name, obj.selection.db);
            run_date = '';
            if tf
                run_date = char(datetime(dir(out_files.resp_data).datenum, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm'));
            end
        end

        function save_project(obj, proj)
            % Save Project State (Default: The Active Project)
            if nargin < 2
                proj = obj.project;
            end
            if isempty(proj)
                return
            end
            chess_project = proj;
            save(fullfile(proj.path, proj.name, ['CHESS_project_' proj.name '.mat']), 'chess_project', '-v7.3');
        end

        function config = localize_saved_config(obj, config)
            % Saved Run config Of A Moved Project (chessProject.relocate): A tide_file Under The Run's Project Folder
            % (<outfolder>\<project_name>) Points Into The Active Project Folder. 'None' And Paths Elsewhere Unchanged
            config.tide_file = chessProject.relocate_path(config.tide_file,...
                fullfile(config.outfolder, config.project_name), fullfile(obj.project.path, obj.project.name));
        end

        function [config, pseObj] = run_config(obj, for_run, plan)
            % Run Step: Build config From The Run Tab Inputs + Project + Storm DB, Then Apply Library Run Rules
            %   for_run = false: Input Comparison Only (No Hotstart Actions, Nothing Saved)
            %   plan: Run Start (plan_run): plan.level 'cold' (Default) | 'full' | 'reuse_sampling', plan.old: Saved Run's config
            if nargin < 2
                for_run = true;
            end
            if nargin < 3
                plan = struct('level', 'cold', 'old', []);
            end
            proj = obj.project;
            [pse_name, alt_name] = obj.active_names();
            pseObj = proj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            dbObj = proj.get_project_field('stormDB_list', obj.selection.db, '', 'db');
            [~, ~, ~, ~, out_files] = obj.config_path();
            % Library Template Defaults For storm_duration (Fresh Table) And Workflow Sections (Library Functions Read Them Regardless Of Workflow)
            tpl = proj.get_library_template(pseObj.pse_type);
            wf_rows = [tpl.forcing(strcmp(tpl.forcing(:, 1), 'storm_duration'), :); tpl.mcs; tpl.csr; tpl.pros];
            for rr = 1:size(wf_rows, 1)
                config.(wf_rows{rr, 1}) = wf_rows{rr, 4};
            end
            % Every Library Response Switch Defaults To Off (Union Of All Templates)
            types = {'Levee', 'Floodwall', 'Rubble Mound', 'Low Crested Breakwater'};
            for tt = 1:length(types)
                tpl_t = proj.get_library_template(types{tt});
                for rr = 1:size(tpl_t.responses, 1)
                    config.(tpl_t.responses{rr, 1}) = 0;
                end
            end
            % Response Parameter Defaults (e.g. compute_damaging_depth_Ks)
            is_param = ~startsWith(tpl.responses(:, 2), 'Comput');
            for rr = find(is_param)'
                config.(tpl.responses{rr, 1}) = tpl.responses{rr, 4};
            end
            % Model Switches
            config.workflow = obj.selection.workflow;
            config.storm_sampling = obj.input('storm_sampling', '');
            % Data Types (Run Tab Tree Symbols)
            dt_checked = obj.input('data_types', {});
            config.use_peaks = +any(ismember({'peaks_default','create_wlp','create_whp'}, dt_checked));
            config.use_timeseries = +ismember('use_timeseries', dt_checked);
            config.create_wlp = +ismember('create_wlp', dt_checked);
            config.create_whp = +ismember('create_whp', dt_checked);
            % Project Forcing Adjustments
            config.swl_slr = obj.input('swl_slr', 0);
            config.tide_file = obj.input('tide_file', 'None');
            config.apply_random_tides = +~strcmp(config.tide_file, 'None');
            config.apply_depth_limitation = +obj.input('apply_depth_limitation', false);
            config.load_project_forcing = 0; % GUI Builds Project Forcing Itself
            config.ref_case_name = 'none';
            % Responses (Run Tab Tree Symbols)
            resp_checked = obj.input('responses', {});
            for rr = 1:length(resp_checked)
                config.(resp_checked{rr}) = 1;
            end
            % Inputs Of Every Workflow (Visible And Hidden Rows): Config Records The Full Input State
            input_fields = obj.table_fields();
            for rr = 1:length(input_fields)
                config.(input_fields{rr}) = +obj.inputs.(input_fields{rr});
            end
            % Storm DB Fields
            config.region = dbObj.study;
            config.sp_ID = '';
            config.sp_ID_wave = '';
            config.storm_db = obj.selection.db;
            % Project Pathing
            config.outfolder = proj.path;
            config.project_name = proj.name;
            config.struc_id = pse_name;
            config.case_name = alt_name;
            % Project CLs ([CL1 CL2 ...], Library Sorts & Formats)
            cls = proj.get_project_field('CLs', '', '', 'proj');
            cls(cls==0) = [];
            config.project_CLs = ['[' strjoin(arrayfun(@num2str, cls, 'un', false), ' ') ']'];
            config.project_datum = proj.vdatum;
            % Constants
            config.gravity_constant = obj.GRAVITY;
            % Structure -> Config Bridge (Library Reads These From config, e.g. Hotstart Dependencies)
            geo_fields = fieldnames(pseObj);
            for rr = 1:length(geo_fields)
                config.(geo_fields{rr}) = pseObj.(geo_fields{rr});
            end
            % Storm DB Details (db_info, Library storm_db_info): Nyrs_XC/Nstm_XC, TC Bias Correction, Modeling Bias & Uncertainty,
            % storm_db_build_date (Re-Imported Storm DB: Library Hotstart Dependency, 'resample'), Offshore Elevation (Study
            % Grid Value Wins Over The PSE Geometry Value Copied Above). After The Structure Bridge So The Grid Value Is Kept
            config = storm_db_info('apply', CHSStormDBImportUI.get_db_info(dbObj), config);
            % Library Run Rules (Restrictions, Dependencies, CLs, Uncertainties, out_files)
            config = finalize_config(config);
            % Multi-Line Transect: Stage 1 Always Computes Hm0t (Locked In The Responses Tree). Stage 2 Is Coupled To Stage 1's
            % Run Of This Storm DB + Workflow (Library multiline_stage2_config: Forcing Inputs Inherited, Offshore End = Stage 1
            % Toe, Stage 1 Forcing Stamp); Without That Run Only The Link Is Recorded (Run Disabled: stage1_row)
            switch proj.alt_stage(pse_name, alt_name)
                case 1
                    config.compute_wave_transmission = 1;
                case 2
                    config.multiline = struct('stage1_alt', proj.stage1_alt(pse_name));
                    if ~isempty(obj.stage1_row())
                        [config, pseObj] = multiline_stage2_config(config, pseObj);
                    end
            end
            % LCS Convergence: Asked Before The Run (plan_run); The Library Must Never Prompt In The Command Window
            config.lcs_convergence_prompt = 0;
            % GUI File Names (Per Storm DB)
            config.out_files = out_files;
            if ~for_run
                return
            end
            % Hotstart: Library Level Actions (apply_hotstart_level). Not resolve_hotstart_state: The Level Comes From The
            % Run Question (plan_run). Coldstart: Cached Forcing And LCS Seed Deleted (Already Moved To *_prev By backup_sim_files)
            if strcmp(plan.level, 'cold')
                for ff = {out_files.project_forcing, lcs_sampling_seed_file(out_files.project_forcing)}
                    if isfile(ff{1})
                        delete(ff{1});
                    end
                end
                config.hotstart_level = 'cold';
            else
                config = apply_hotstart_level(config, plan.old, plan.level, config.workflow == 3 && isempty(config.multiline));
            end
            % Save Config (Library Drivers Append To This File During The Run). execute_run Backs Up The Previous One First
            % (backup_sim_files) And Deletes The Backup Once The Results Are Saved, Or Restores It If The Run Fails
            out_pth = fileparts(out_files.config);
            if ~exist(out_pth, 'dir')
                mkdir(out_pth);
            end
            save(out_files.config, 'config', '-v7.3');
        end

        function [changed, fld] = inputs_changed(obj, saved_config, config_now)
            % Current Run Tab Inputs Vs A Saved Run's config (Library any_field_changed, No Side Effects)
            if nargin < 3
                config_now = obj.run_config(false);
            end
            % outfolder: Project Location (Moves With An Imported/Relocated Project), Not A Run Input
            ignore = {'out_files', 'in_files', 'outfolder'};
            [changed, fld] = any_field_changed(config_now, saved_config, setdiff(fieldnames(config_now), ignore));
        end

        function [s1_row, msg, run_label] = stage1_row(obj)
            % Multi-Line Stage 2 Active: Its Stage 1's Registry Row (sim_rows: Responses File Checked, No Config Load) Of The Run
            % Tab Storm DB + Workflow. None: [] And The Status Bar Text Naming The Run Needed (Current Data Types And Storm
            % Type). Not A Stage 2 (Or No Storm DB): [] And ''
            %   run_label: '<storm DB> | <workflow>' Of The Run Tab ('' Without A Storm DB Or When Not A Stage 2)
            s1_row = [];
            msg = '';
            run_label = '';
            if ~obj.has_active_alt() || isempty(obj.selection.db)
                return
            end
            [pse_name, alt_name] = obj.active_names();
            if obj.project.alt_stage(pse_name, alt_name) ~= 2
                return
            end
            s1_alt = obj.project.stage1_alt(pse_name);
            [~, ~, ~, wflow_name] = obj.config_path();
            db_name = obj.selection.db;
            run_label = [db_name ' | ' wflow_name];
            rows = obj.sim_rows(obj.project, pse_name, s1_alt);
            rows = rows(strcmpi(db_name, {rows.db}) & strcmpi(wflow_name, {rows.workflow}));
            if ~isempty(rows)
                s1_row = rows(1);
                return
            end
            dt_checked = obj.input('data_types', {});
            dts = {};
            if any(ismember({'peaks_default', 'create_wlp', 'create_whp'}, dt_checked))
                dts{end+1} = 'Peaks';
            end
            if ismember('use_timeseries', dt_checked)
                dts{end+1} = 'Timeseries';
            end
            msg = sprintf('Run %s/%s with %s, %s first.', pse_name, s1_alt, wflow_name,...
                strjoin([dts, {obj.input('storm_sampling', '')}], ', '));
        end

        function rows = sim_rows(obj, proj, pse_name, alt_name)
            % Registry Rows Of An Alternative Of proj (chessProject.sim_rows: One isfile Per Row). Active Project: A Missing
            % Responses File Drops Its Row And Re-Syncs That Alternative Only; The Project Is Saved, A 'status' Message Says
            % So, And A Dropped Multi-Line Stage 1 Bundle Queues Its Stage 2 Rows For A Drift Question ('removed', take_drift),
            % As Does One The Re-Sync Reloaded With Another forcing_stamp / structure_kt ('changed'). Other Loaded Projects
            % (Not Locked By This Session): Missing Rows Only Left Out
            is_active = ~isempty(obj.project) && proj == obj.project;
            [rows, dropped, changed_rows] = proj.sim_rows(pse_name, alt_name, is_active);
            if isempty(dropped)
                return
            end
            obj.save_project(proj);
            obj.message('status', '', sprintf('Results no longer on disk, removed from the project: %s/%s %s.', pse_name, alt_name,...
                strjoin(arrayfun(@chessProject.sim_label, dropped, 'un', false), ', ')));
            obj.mark('tree');
            if proj.alt_stage(pse_name, alt_name) == 1
                obj.drift(end+1, :) = {proj, pse_name, alt_name, [{dropped.db}', {dropped.workflow}'], 'removed'};
                if ~isempty(changed_rows)
                    obj.drift(end+1, :) = {proj, pse_name, alt_name, changed_rows(:, 3:4), 'changed'};
                end
            end
        end

        function cascade = cascade_sims(obj, proj, pse_name, alt_name, db_wf)
            % Stage 2 Registry Rows (sim_rows) Coupled To alt_name (A Multi-Line Stage 1) With A Storm DB + Workflow Of db_wf
            % (Rows {db, workflow}). cascade: Rows {stage 2 alternative, db, workflow}; None (Or Not A Stage 1): Empty
            cascade = cell(0, 3);
            for s2 = proj.multiline_stage2(pse_name, alt_name)'
                rows = obj.sim_rows(proj, pse_name, s2{1});
                for rr = 1:numel(rows)
                    if any(strcmpi(rows(rr).db, db_wf(:, 1)) & strcmpi(rows(rr).workflow, db_wf(:, 2)))
                        cascade(end+1, :) = {s2{1}, rows(rr).db, rows(rr).workflow}; %#ok<AGROW>
                    end
                end
            end
        end

        function failed = delete_sim_rows(obj, proj, pse_name, rows)
            % Deletes Simulation Bundles Of PSE pse_name (Rows {alternative, db, workflow}): Files And Registry Row
            % (chessProject.delete_sim). failed: Files Not Deleted
            failed = cell(0, 1);
            for dd = 1:size(rows, 1)
                failed = [failed; proj.delete_sim(pse_name, rows{dd, :})]; %#ok<AGROW>
            end
            obj.mark('tree');
        end

        function guard = run_guard(obj)
            % Run In Progress Until guard Is Cleared (onCleanup): Rename / Remove / Rebuild Are Refused Meanwhile
            obj.runActive = true;
            guard = onCleanup(@() obj.end_run());
        end

        function out = plan_run(obj, answers)
            % Run Start, Re-Entrant: Re-Evaluated From The Start On Every Call, Each Question Asked Once Its Answer Is Missing.
            %   answers: struct, answers.(question id) ('saved_sim', 'cascade', 'lcs_convergence'); An Empty Answer Cancels
            %   out.status: 'ask' (out.question) | 'run' (out.plan For execute_run) | 'load' (Load The Saved Simulation) |
            %               'cancel' | 'failed' (Error Message Queued; Nothing Touched)
            % Leftover Backups Of A Run That Never Finished Are Put Back First. Every Run Needs An Offshore Elevation (Storm DB
            % Study Grid, Else The PSE Geometry): Checked Before Any Question (Library check_offshore_elevation)
            if nargin < 2 || isempty(answers)
                answers = struct();
            end
            out = struct('status', 'run', 'question', [], 'plan', []);
            try
                [pse_name, alt_name] = obj.active_names();
                [~, ~, ~, wflow_name, out_files] = obj.config_path();
                bk = obj.sim_backup_paths(out_files);
                obj.restore_leftover_backups(bk);
                pseObj = obj.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                dbObj = obj.project.get_project_field('stormDB_list', obj.selection.db, '', 'db');
                check_offshore_elevation(obj.run_config(false));
                % Saved Simulation For This Alternative / Workflow / Storm DB: "Hotstart" (Hidden When Not Available) |
                % "Coldstart" | "Load existing" | "Cancel". No Saved Simulation: Coldstart
                plan = struct('level', 'cold', 'reason', '', 'available', false, 'text', '', 'old', []);
                if obj.saved_sim()
                    [q, plan] = obj.saved_sim_question();
                    [a, out] = obj.answer_of(q, answers, out);
                    if isempty(a)
                        return
                    end
                    switch a
                        case 'Coldstart'
                            plan.level = 'cold';
                        case 'Load existing'
                            out.status = 'load';
                            return
                        case 'Cancel'
                            out.status = 'cancel';
                            return
                    end
                end
                % Multi-Line Stage 1 Run With Stage 2 Registry Rows Of This Storm DB + Workflow (Stale Ones Included): They Get
                % Their Forcing From It. Asked When That Input Changes: Stage 1 Forcing Rebuilt (No Stage 1 Row, Or Any Level But
                % 'full') Or, At 'full', Its Kt Geometry Differs From Its Row's structure_kt (Library multiline_stage2_config
                % stage1_structure). Deleted Only After The Run Succeeds (A Failed Run Restores Stage 1's Files)
                plan.cascade = cell(0, 3);
                plan.res_str = 'The results';
                if obj.project.alt_stage(pse_name, alt_name) == 1
                    plan.res_str = 'Stage 1 results';
                    db_wf = {obj.selection.db, wflow_name};
                    cascade = obj.cascade_sims(obj.project, pse_name, alt_name, db_wf);
                    why = obj.cascade_reason(cascade, pse_name, alt_name, db_wf, plan.level, pseObj);
                    if ~isempty(why)
                        lines = strcat({['  ' char(8226) ' ']}, cascade(:, 1), {' | '}, cascade(:, 2), {' | '}, cascade(:, 3));
                        q = obj.question('cascade', 'Run Multi-Line Stage 1', sprintf(['"%s" is the first stage of multi-line PSE ',...
                            '"%s". These second-stage simulations get their forcing from its %s run and are deleted once this run ',...
                            'succeeds:\n%s\n%s'], alt_name, pse_name, strjoin(db_wf, ' | '), strjoin(lines, newline), why),...
                            {'Continue', 'Cancel'}, 560); % Last Button = Default (Enter): Cancel
                        [a, out] = obj.answer_of(q, answers, out);
                        if isempty(a)
                            return
                        elseif ~strcmp(a, 'Continue')
                            out.status = 'cancel';
                            return
                        end
                        plan.cascade = cascade;
                    end
                end
                % LCS, Full Poisson Sampling: Convergence Question (May Update mcs_nLC) Before The Config Is Built, Only When
                % Life Cycles Are Sampled (A Hotstart Reuses The Cached Forcing Or This Case's Sampling)
                if obj.selection.workflow == 3 && strcmp(plan.level, 'cold')
                    P = load(dbObj.output_paths.storm_db, 'prob_mass');
                    [q, n_req] = obj.lcs_question(P.prob_mass);
                    if ~isempty(q)
                        [a, out] = obj.answer_of(q, answers, out);
                        if isempty(a)
                            return
                        elseif strcmp(a, 'Cancel')
                            out.status = 'cancel';
                            return
                        elseif startsWith(a, 'Set mcs_nLC')
                            obj.inputs.mcs_nLC = n_req; % The Inputs Table Shows (And The Run Reads) The New mcs_nLC
                            obj.mark('inputs_table');
                        end
                    end
                end
                plan.bk = bk;
                out.plan = plan;
            catch ME
                obj.message('error', 'Error Message', ['CHESS run failed: ' ME.message]);
                out.status = 'failed';
            end
        end

        function out = execute_run(obj, plan, progress_fcn)
            % Run The Active Alternative / Workflow / Run Tab Storm DB With A plan_run Plan. progress_fcn(value, message):
            % Progress (0-1, Never Called Before The Slot Is Backed Up; Callers Keep The Bar From Moving Back).
            % Two Phases:
            %   Before The Results Are Saved, An Error Puts The Slot Back To The Previous Run (Config, Forcing, LCS Seed
            %   Matching The Results On Disk; Best Effort, A Restore Failure Is Reported With The Run Error): out.status
            %   'failed', Error Message Queued.
            %   After: A Project Update Failure (Stage 2 Delete, Registry Row, Save) Is A Warning, Not A Failed Run: The
            %   Registry Row Retried Once When It Was Not Added (Failed Again: The Next Import Sync Or Rebuild Adds It From
            %   Disk), Then The Save Retried Once. out.status 'done'.
            % out.status_text: How The Forcing Was Obtained ('status' View). Multi-Line Stage 1: The Confirmed Stage 2 Bundles
            % (plan.cascade) Deleted Once The Results Are Saved; Files Not Deleted Reported In The Warning
            if nargin < 3
                progress_fcn = @(~, ~) [];
            end
            out = struct('status', 'done', 'status_text', '');
            [pse_name, alt_name] = obj.active_names();
            backed = [];
            results_saved = false;
            row_added = false; % Registry Row Of This Bundle In The Project (upsert_sim)
            update_msg = '';
            failed = cell(0, 1); % Stage 2 Files Not Deleted
            config = [];
            pseObj = [];
            try
                dbObj = obj.project.get_project_field('stormDB_list', obj.selection.db, '', 'db');
                S = load(dbObj.output_paths.storm_db, 'storm', 'prob_mass');
                backed = obj.backup_sim_files(plan.bk, plan.level);
                [config, pseObj] = obj.run_config(true, plan); % Includes Hotstart Actions

                %%%% ------ 2-4. Project Forcing (Library call_chess_boundary_conditions: Build, Uncertainty, Adjustments, One Save)
                step_str = 'Creating Replicates';
                unc_str = 'Applying Uncertainty';
                adj_str = 'Adjust Project Forcing';
                if ~isempty(config.multiline) % Multi-Line Stage 2: Stage 1's Forcing, Transmitted (Library apply_stage1_transmission)
                    step_str = 'Transmitting Stage 1 Waves';
                    unc_str = 'Uncertainty From Stage 1';
                    adj_str = 'Adjustments From Stage 1';
                elseif config.workflow == 3
                    step_str = 'Creating Life Cycles';
                elseif config.workflow == 2 % Deterministic: Storms As Recorded, No Uncertainty
                    step_str = 'Formatting Storms';
                    unc_str = 'No Uncertainty (Deterministic)';
                end
                progress_fcn(1/5, step_str);
                bar_msg = {'Loading Project Forcing', step_str, unc_str, adj_str, 'Saving Project Forcing'}; % Library Steps 0-4
                [project_forcing, config] = call_chess_boundary_conditions(config, S.storm, S.prob_mass, pseObj,...
                    @(step, msg) obj.run_progress(progress_fcn, step, msg, bar_msg));

                %%%% ---- 5. Run CHESS Simulation
                progress_fcn(4/5, 'Computing Project Responses');
                call_project_response(config, project_forcing, pseObj);
                % Results Saved (Written Once, At The End Of call_project_response): Previous Run's Files No Longer Needed
                for kk = 1:numel(backed)
                    if backed(kk).existed && isfile(backed(kk).prev)
                        delete(backed(kk).prev);
                    end
                end
                backed = [];
                results_saved = true;
                % Multi-Line Stage 1 Run Done: The Confirmed Stage 2 Bundles Deleted, Files And Registry Rows (Saved In Step 6).
                % First Statement After results_saved, So It Has Run (Once, Never Repeated By The Catch) Whenever A Later Step Fails
                if ~isempty(plan.cascade)
                    failed = obj.delete_sim_rows(obj.project, pse_name, plan.cascade);
                end

                %%%% ---- 6. Store Outputs On Project
                progress_fcn(4.99/5, 'Saving Outputs');
                obj.project.upsert_sim(pse_name, alt_name, chessProject.sim_row_from_config(config, pseObj,...
                    dir(config.out_files.resp_data).datenum)); % Registry Row Of This Bundle
                row_added = true;
                obj.save_project();
                obj.mark('tree'); % New Simulation Bundle Node
                progress_fcn(1, 'Done');
            catch ME
                if ~results_saved
                    restore_failed = obj.restore_sim_files(backed);
                    msg = ['CHESS run failed: ' ME.message];
                    if ~isempty(restore_failed)
                        msg = [msg newline newline 'Previous run files not restored: ' strjoin(restore_failed, '; ')];
                    end
                    obj.message('error', 'Error Message', msg);
                    out.status = 'failed';
                    return
                end
                update_msg = sprintf('%s were saved, but updating the project failed: %s', plan.res_str, ME.message);
                if ~row_added
                    try
                        obj.project.upsert_sim(pse_name, alt_name, chessProject.sim_row_from_config(config, pseObj,...
                            dir(config.out_files.resp_data).datenum));
                    catch
                        update_msg = [update_msg newline newline 'The simulation is not in the project list: use "Rebuild ',...
                            'simulations from disk" on the project.'];
                    end
                end
                try
                    obj.save_project();
                catch
                    update_msg = [update_msg newline newline 'The project is not saved: save it before closing.'];
                end
                obj.mark('tree');
            end
            % Status: How The Forcing Was Obtained
            switch plan.level
                case 'full'
                    out.status_text = 'Hotstart (full): reused cached forcing.';
                case 'reuse_sampling'
                    if config.workflow == 3
                        out.status_text = ['Hotstart: same life cycles, forcing rebuilt (' plan.reason ').'];
                    else
                        out.status_text = ['Hotstart: forcing rebuilt (' plan.reason ').'];
                    end
                otherwise
                    out.status_text = 'Coldstart: forcing regenerated.';
            end
            obj.mark({'status', 'results'});
            % One Warning: Project Update Failure And/Or Stage 2 Files Not Deleted
            if ~isempty(update_msg) || ~isempty(failed)
                alert_msg = update_msg;
                if ~isempty(failed)
                    del_str = 'Stage 1 run done, but these';
                    if ~isempty(update_msg)
                        alert_msg = [alert_msg newline newline];
                        del_str = 'These';
                    end
                    alert_msg = [alert_msg sprintf(['%s second-stage files could not be deleted (a file may be open in another ',...
                        'program):\n%s\nClose it and remove those simulations.'], del_str, strjoin(failed, newline))];
                end
                title_str = 'CHESS Run';
                if ~isempty(plan.cascade)
                    title_str = 'Run Multi-Line Stage 1';
                end
                obj.message('warning', title_str, alert_msg);
            end
        end
    end

    %% STAGE 2: STATUS, SAVED SIMULATIONS, RESULTS DATA
    methods
        function msg = status(obj, msg)
            % Run Tab Status Bar Text: msg, Unless The Run Tab Storm DB Has No layout (stormdb_note) Or A Multi-Line Stage 2
            % Has No Matching Stage 1 Run (stage1_row): That Text Instead
            [~, ml_msg] = obj.stage1_row();
            db_msg = obj.stormdb_note();
            if ~isempty(db_msg)
                msg = db_msg;
            elseif ~isempty(ml_msg)
                msg = ml_msg;
            end
        end

        function msg = stormdb_note(obj)
            % Run Tab Storm DB Record Without A layout (Its Storm DB File Was Missing Or Unreadable; chessProject.sync_sims
            % Retries It): Status Text Asking For A Re-Import; '' Otherwise
            msg = '';
            if ~obj.has_active_alt() || isempty(obj.project.stormDB_list)
                return
            end
            recs = obj.project.stormDB_list;
            k = find(strcmp({recs.db_name}, obj.selection.db), 1);
            if ~isempty(k) && isempty(recs(k).layout)
                msg = sprintf('Storm DB %s: file missing or unreadable, re-import it.', recs(k).db_name);
            end
        end

        function msg = results_status(obj)
            % Status Text: Do The Loaded Results Match The Active PSE Geometry And The Current Run Tab Inputs? (No Side Effects)
            msg = '';
            try
                [pse_name, alt_name] = obj.active_names();
                pseObj = obj.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                config_now = obj.run_config(false);
                saved_config = obj.results.config;
                % Geometry: PSE Geometry Fields (Bridged Into config; offshore_elevation As Resolved, Storm DB Grid Wins)
                geo_fields = fieldnames(pseObj);
                [geo_changed, geo_fld] = any_field_changed(config_now, saved_config, geo_fields);
                % Run Tab Inputs: Every Other Field (inputs_changed Compares The Fields Of config_now)
                [inp_changed, inp_fld] = obj.inputs_changed(saved_config, rmfield(config_now, geo_fields));
                if geo_changed && inp_changed
                    msg = ['PSE geometry differs from the loaded results (' geo_fld '); Run tab inputs also changed (' inp_fld '). Press Run to update.'];
                elseif geo_changed
                    msg = ['PSE geometry differs from the loaded results (' geo_fld '). Press Run to update.'];
                elseif inp_changed
                    msg = ['Run tab inputs changed since the loaded results (' inp_fld '). Press Run to update.'];
                else
                    msg = obj.loaded_status();
                end
            catch
            end
        end

        function msg = loaded_status(obj)
            % Status Text Of The Saved Simulation Shown
            [~, ~, ~, wflow_name] = obj.config_path();
            [~, ~, run_date] = obj.saved_sim();
            msg = sprintf('Saved simulation loaded (%s_%s, run %s).', obj.selection.db, wflow_name, run_date);
        end

        function out = sync_saved(obj, ask, answers)
            % After A Switch Of Alternative / Workflow / Run Tab Storm DB (Key Changed), A Saved Simulation Of The New Key Is
            % Loaded Silently When The Current Inputs Match It, Or Without ask (Internal Refresh). Otherwise ask: Question
            % 'load_saved' ("Load" | "Keep current inputs"; Closed Or Empty: Inputs Kept). No Saved Simulation: Inputs Kept.
            % Run Tab Storm DB Of An Older CHESS Version (No db_info, Inputs Cannot Be Compared): Warning (db_info_ok), Then
            % Asked As Changed Inputs. A Declined Load Is Remembered (declinedKey) Until The Key Changes: Switching Back Asks
            % Again. Nothing Changes Before The Question Is Answered (Re-Entrant)
            %   out.status: 'none' | 'ask' (out.question) | 'load' (Caller Restores The Inputs And Loads: use_key) | 'declined'
            if nargin < 3
                answers = struct();
            end
            out = struct('status', 'none', 'question', []);
            key = obj.sim_key();
            if isequal(key, obj.simKey)
                return
            end
            [has_sim, label] = deal(false, '');
            if ~isempty(key)
                [has_sim, label] = obj.saved_sim();
            end
            if ~has_sim
                obj.simKey = key;
                obj.declinedKey = '';
                if ~isempty(key)
                    obj.message('status', '', obj.status(['No saved simulation for ' label '.']));
                end
                return
            end
            S = load(key, 'config');
            S.config = obj.localize_saved_config(S.config);
            load_it = ~ask;
            if ask
                dbObj = obj.project.get_project_field('stormDB_list', obj.selection.db, '', 'db');
                load_it = obj.db_info_ok(dbObj) && ~obj.inputs_changed(S.config);
            end
            if ~load_it
                if ~isfield(answers, 'load_saved')
                    out.status = 'ask';
                    out.question = obj.question('load_saved', 'Saved Simulation Found',...
                        ['A simulation for ' label ' already exists. Load it?'], {'Load', 'Keep current inputs'}, 440);
                    return
                end
                load_it = isequal(answers.load_saved, 'Load');
            end
            obj.simKey = key;
            obj.declinedKey = '';
            if load_it
                out.status = 'load';
            else
                out.status = 'declined';
                obj.declinedKey = key;
                obj.results = [];
                obj.mark('results');
                obj.message('status', '', obj.status('Current simulation already exists. Load declined.'));
            end
        end

        function use_key(obj)
            % The Current Key Is Resolved (Loaded Or Just Run): Its Results Load (load_results)
            obj.simKey = obj.sim_key();
            obj.declinedKey = '';
            obj.mark({'results', 'status'});
        end

        function reset_key(obj)
            % Saved Simulation Key Re-Resolved On The Next sync_saved, Loaded Results Dropped
            obj.simKey = [];
            obj.declinedKey = '';
            obj.results = [];
            obj.mark({'results', 'status'});
        end

        function clear_results(obj)
            % Loaded Results Dropped (Key Kept)
            obj.results = [];
            obj.mark('results');
        end

        function remap_paths(obj, remap)
            % Session State Holding Paths Under A Moved Folder (Rename): Keys And Older-DB Warnings Remapped (remap(path)),
            % Cached storm / CHS_Data Of Moved Files Dropped, Loaded Results Dropped (Reloaded From The New Paths)
            keys = obj.storm.keys();
            moved = keys(~strcmp(keys, cellfun(remap, keys, 'un', false)));
            if ~isempty(moved)
                remove(obj.storm, moved);
            end
            obj.simKey = remap(obj.simKey);
            obj.declinedKey = remap(obj.declinedKey);
            obj.oldDbWarned = cellfun(remap, obj.oldDbWarned, 'un', false);
            obj.clear_results();
        end

        function forget_files(obj, files)
            % Storm DB Files Removed Or Overwritten: Their Cached storm / CHS_Data And Older-DB Warnings Dropped
            keys = obj.storm.keys();
            stale = keys(ismember(lower(keys), lower(files)));
            if ~isempty(stale)
                remove(obj.storm, stale);
            end
            obj.oldDbWarned = obj.oldDbWarned(~ismember(lower(obj.oldDbWarned), lower(files)));
        end

        function [loaded, msg] = load_results(obj)
            % Results Of The Active Alternative / Workflow / Run Tab Storm DB (Saved Run's Resp, config, structure; Project
            % Forcing For DET / LCS Plots) Into results, Only Once The Key Is Resolved (sync_saved / use_key) And Not Declined.
            % msg: Status Text (status Applied): The Comparison With The Current Inputs (results_status) When Loaded, Else Why Not
            obj.results = [];
            loaded = false;
            msg = '';
            if ~obj.has_active_alt() || isempty(obj.selection.db) || ~isequal(obj.sim_key(), obj.simKey)
                msg = obj.status(msg);
                return
            end
            if ~isempty(obj.declinedKey) && isequal(obj.sim_key(), obj.declinedKey)
                msg = obj.status('Current simulation already exists. Load declined.');
                return
            end
            [config_file, ~, ~, ~, out_files] = obj.config_path();
            [has_sim, label] = obj.saved_sim();
            if ~has_sim
                msg = obj.status(['No saved simulation for ' label '.']);
                return
            end
            S = load(out_files.resp_data, 'Resp');
            % Run's Structure (Saved By The Library call_project_response, With The Run's Resolved Offshore Elevation), Not The Current PSE
            C = load(config_file, 'config', 'structure');
            C.config = obj.localize_saved_config(C.config);
            state = struct('Resp', S.Resp, 'config', C.config, 'structure', C.structure,...
                'project_forcing', [], 'prob_mass', [], 'out_files', out_files,...
                'dbObj', obj.project.get_project_field('stormDB_list', obj.selection.db, '', 'db'));
            if any(C.config.workflow == [2 3]) && isfile(out_files.project_forcing) % DET (Forcing Not Copied Into Resp) & LCS Plots Need Project Forcing
                P = load(out_files.project_forcing, 'project_forcing');
                state.project_forcing = P.project_forcing;
            end
            obj.results = state;
            loaded = true;
            msg = obj.status(obj.results_status());
        end

        function [project_forcing, dsw] = results_forcing(obj)
            % Project Forcing & Storm DB Probability Masses For The Loaded Results (Loaded Once, Kept In results)
            if isempty(obj.results.project_forcing) && isfile(obj.results.out_files.project_forcing)
                P = load(obj.results.out_files.project_forcing, 'project_forcing');
                obj.results.project_forcing = P.project_forcing;
            end
            if isempty(obj.results.prob_mass)
                S = load(obj.results.dbObj.output_paths.storm_db, 'prob_mass');
                obj.results.prob_mass = S.prob_mass;
            end
            project_forcing = obj.results.project_forcing;
            dsw = obj.results.prob_mass;
        end

        function ok = db_info_ok(obj, dbObj)
            % Storm DB Has Its db_info (Library storm_db_info 'valid'); Imported With An Older CHESS Version: Warning (Must Be
            % Re-Imported) Once Per Storm DB Per Session, Callers Still Block Silently Afterwards. The Run Path Keeps Its Own
            % Error (CHSStormDBImportUI.get_db_info In run_config)
            ok = storm_db_info('valid', dbObj.db_info);
            if ~ok && ~any(strcmp(obj.oldDbWarned, dbObj.output_paths.storm_db))
                obj.oldDbWarned{end+1} = dbObj.output_paths.storm_db;
                obj.message('warning', ['Storm DB: ' dbObj.db_name], 'This storm database was built with an older CHESS version and must be re-imported.');
            end
        end

        function storm = load_storm(obj, dbObj)
            % Cached Load Of Storm DB "storm" Variable
            key = dbObj.output_paths.storm_db;
            if ~isKey(obj.storm, key)
                S = load(key, 'storm');
                obj.storm(key) = S.storm;
            end
            storm = obj.storm(key);
        end

        function chs_data = load_chs_data(obj, dbObj)
            % Cached Load Of Raw CHS_Data (Storm DB "_raw_files.mat"); [] If Unavailable
            chs_data = [];
            if ~isfield(dbObj.output_paths, 'chs_data') || ~isfile(dbObj.output_paths.chs_data)
                return
            end
            key = dbObj.output_paths.chs_data;
            if ~isKey(obj.storm, key)
                S = load(key, 'CHS_Data');
                obj.storm(key) = S.CHS_Data;
            end
            chs_data = obj.storm(key);
        end

        function cat = plot_catalog(obj)
            % Results Plot Types -> CHESS-Library Plot Methods (One Row Per Plot), Filtered For The Loaded Results.
            %   key | label | workflows | data types | needs S (armor damage) | rubble mound only | multi-panel (pop-out only) | plot options
            rows = {
                'hc',          'Hazard Curve',                    [1 4],   {'Peaks','Timeseries'}, false, false, false, {}
                'det_scatter', 'Response vs Forcing',             2,       {'Peaks','Timeseries'}, false, false, false, {'c_field'}
                'det_table',   'Response Table',                  2,       {'Peaks','Timeseries'}, false, false, true,  {}
                'det_compare', 'Peaks vs Timeseries',             2,       {'Peaks'},              false, false, false, {}
                'event',       'Storm Event Viewer',              [1 2 3 4], {'Peaks','Timeseries'}, false, false, true,  {}
                'annual',      'Annual Response Distribution',    3,       {'Peaks','Timeseries'}, false, false, false, {'bin_edges','cb_lim','grid_on','cb_log'}
                'armor',       'Slope Armor Damage',              3,       {'Timeseries'},         true,  true,  false, {}
                'sampling',    'Event Sampling Distribution',     3,       {'Peaks','Timeseries'}, false, false, false, {}
                'damaging',    'Damaging Instances Distribution', 3,       {'Peaks','Timeseries'}, true,  false, false, {}
                'submergence', 'PSE Submergence Distribution',    3,       {'Timeseries'},         false, false, false, {'cb_lim','cb_log'}
                'final',       'Final Damage State',              3,       {'Timeseries'},         true,  false, false, {}
                'dashboard',   'Mound Damage Dashboard',          3,       {'Timeseries'},         true,  true,  true,  {'bin_edges','cb_lim'}
                'scheme',      'Sampling Scheme Dashboard',       3,       {'Peaks','Timeseries'}, false, false, true,  {}};
            cat = cell2struct(rows, {'key','label','workflows','data_types','needs_s','rubble_mound','multi_panel','options'}, 2);
            state = obj.results;
            if isempty(state)
                return
            end
            keep = false(size(cat));
            for cc = 1:numel(cat)
                cat(cc).data_types = obj.results_data_types(cat(cc));
                keep(cc) = ismember(state.config.workflow, cat(cc).workflows) && ~isempty(cat(cc).data_types) &&...
                    (~cat(cc).rubble_mound || state.structure.struc_type == 3) &&...
                    (~strcmp(cat(cc).key, 'det_compare') || isfield(state.Resp, 'Timeseries')); % Needs Peaks & Timeseries
            end
            cat = cat(keep);
        end

        function [lbl, items] = field_items(obj, key, data)
            % Field To Plot Items Per Plot Type (Library Method Field Lists)
            lbl = 'Field To Plot:';
            s_fields = {};
            if isstruct(data) && isfield(data, 'S')
                s_fields = fieldnames(data(1).S)';
            end
            s_series = intersect({'S_seaside_no_repairs', 'S_seaside_with_repairs', 'S_leeside_no_repairs', 'S_leeside_with_repairs'}, s_fields, 'stable');
            switch key
                case 'hc'
                    items = {data.var};
                case {'det_scatter', 'det_compare'} % Deterministic: Forcing & Responses (Y Axis / Compared Field)
                    if strcmp(key, 'det_scatter')
                        lbl = 'Y Axis:';
                    end
                    items = obj.det_fields(data);
                case 'det_table' % Columns Are Picked In The Table Pop-Out
                    items = {};
                case 'event' % Responses The Event Viewer Recomputes For This Structure Type (And The Run Computed)
                    if isfield(data, 'var')
                        run_fields = {data.var};
                    else
                        run_fields = fieldnames(data)';
                    end
                    items = intersect(obj.response_list('event'), run_fields, 'stable');
                case 'annual'
                    items = intersect(obj.response_list('annual'), [fieldnames(data)', s_fields], 'stable');
                case 'armor'
                    items = [intersect({'Smax', 'LSmax'}, s_fields, 'stable'), s_series];
                case {'damaging', 'dashboard'}
                    items = s_series;
                case 'final'
                    items = intersect({'S_seaside_no_repairs', 'S_leeside_no_repairs'}, s_fields, 'stable');
                case 'submergence' % Field To Plot Relabeled As An Option
                    lbl = 'Normalize:';
                    items = {'percent', 'count'};
                otherwise % Event Sampling: No Field
                    items = {};
            end
        end

        function [lbl, items, on] = aux_items(obj, key, data, ds_query, field)
            % Storm ID Dropdown Per Plot Type: Event ID, Life Cycle Or A Plot Option (field: Field To Plot Selected)
            lbl = 'Storm ID:';
            items = {'-'};
            on = false;
            lc_items = @(n) [{'All'}, arrayfun(@num2str, 1:n, 'un', false)];
            switch key
                case 'hc' % No Numeric Run Sample (CC Is Derived, FB POT Is A Note): Nothing To Overlay (pros_methods.hc_plot Gate)
                    lbl = 'Add Events:';
                    sel = data(strcmp({data.var}, field));
                    if strcmp(ds_query.storm_type, 'CC') || isempty(sel) || ~isnumeric(sel(1).POT)
                        items = {'Off'};
                    else
                        items = {'Off', 'Run Sample', 'Storm Values'};
                        on = true;
                    end
                case 'det_scatter' % X Axis (Color: Right-Click Plot Options)
                    lbl = 'X Axis:';
                    items = obj.det_fields(data);
                    on = true;
                case 'det_table' % Timeseries: Storm Whose Hydrographs Are Shown | Peaks: All Storms
                    if strcmp(ds_query.data_type, 'Timeseries')
                        items = arrayfun(@num2str, data.storm_id, 'un', false);
                        on = true;
                    else
                        items = {'All'};
                    end
                case 'event' % Timeseries: One Event | Peaks: All Events
                    if strcmp(ds_query.data_type, 'Timeseries')
                        stm_data = aux_methods.pull_data(ds_query, obj.load_storm(obj.results.dbObj));
                        items = arrayfun(@num2str, cell2mat(stm_data(:, 1)), 'un', false);
                        on = true;
                    else
                        items = {'All'};
                    end
                case 'annual'
                    lbl = 'Normalize:';
                    items = {'percent', 'count'};
                    on = true;
                case 'armor' % Life Cycle Selection Applies To S_* Damage Series Only
                    lbl = 'Life Cycle:';
                    items = {'All'};
                    if startsWith(field, 'S_') && isfield(data, 'S') && isfield(data.S, field)
                        items = lc_items(numel(data.S.(field)));
                        on = true;
                    end
                case 'sampling'
                    lbl = 'Life Cycle:';
                    items = lc_items(numel(aux_methods.pull_data(ds_query, obj.results.project_forcing)));
                    on = true;
                case 'submergence'
                    lbl = 'X Scale:';
                    items = {'Linear', 'Log'};
                    on = true;
            end
        end

        function [edges, labels] = bin_edges(obj, chessPlot, ds_query, field, edges)
            % Annual Distribution Bin Edges (Plot Option Or Library Estimate) & Results Table Column Labels.
            % No Finite Response Values: No Edges, No Labels (The Library Plot Shows "No finite response values to plot")
            if isempty(edges)
                data = aux_methods.pull_data(ds_query, obj.results.Resp);
                if isfield(data, field)
                    resp_vector = data.(field);
                else
                    resp_vector = data.S.(field);
                end
                if ~any(cellfun(@(x) any(isfinite(x(:))), resp_vector))
                    labels = {};
                    return
                end
                [~, ~, ~, ~, ~, ~, x_log] = response_library_headers(obj.results.config, field);
                edges = chessPlot.generate_bin_guess(resp_vector, 5, x_log);
            end
            edges = edges(:)';
            % Library Binning Uses [-Inf, edges, edges(end)+1, Inf]
            final_edges = [-Inf, edges, edges(end)+1, Inf];
            labels = arrayfun(@(a, b) sprintf('%g to %g', a, b), final_edges(1:end-1), final_edges(2:end), 'un', false);
            labels{1} = sprintf('< %g', edges(1));
            labels{end} = sprintf('>= %g', final_edges(end-1));
        end

        function fields = det_fields(~, data)
            % Deterministic Results: Plottable Fields (Forcing First, Then Responses), Same Order As det_methods.available_fields
            forcing = {'SWL', 'Hm0_offshore', 'Hm0_toe', 'Tp', 'h', 'Rc'};
            names = setdiff(fieldnames(data.Max), {'storm_id', 'time'}, 'stable')';
            fields = [forcing(ismember(forcing, names)), setdiff(names, forcing, 'stable')];
        end
    end

    %% STAGE 3: MULTI-LINE AND CONSTANTS
    methods
        function rules = stage2_rules(obj)
            % Multi-Line Run Tab Rules (Before The Inputs Table Rows). Stage 1: Hm0t Kept Checked (force_responses, Its Stage 2
            % Forcing). Stage 2 With A Stage 1 Run Of The Run Tab Storm DB + Workflow (stage1_row: Its Registry Row): Storm
            % Type, Data Types, SLR And Tide File (By File Name) Set To That Run's And Locked (The Stage 2 Forcing Is Stage
            % 1's); Fields The Row Does Not Hold Are Left Empty. Otherwise Unlocked. s1_row / msg: stage1_row
            [s1_row, msg] = obj.stage1_row();
            rules = struct('force_responses', {{}}, 'locked', ~isempty(s1_row), 'storm_type', '', 'swl_slr', [],...
                'tide_name', '', 'data_types', {{}}, 's1_row', s1_row, 'msg', msg);
            [pse_name, alt_name] = obj.active_names();
            if obj.has_active_alt() && obj.project.alt_stage(pse_name, alt_name) == 1
                rules.force_responses = {'compute_wave_transmission'};
            end
            if rules.locked
                rules.storm_type = s1_row.storm_type;
                rules.data_types = s1_row.data_types;
                if isfield(s1_row.inherited, 'swl_slr')
                    rules.swl_slr = s1_row.inherited.swl_slr;
                end
                if isfield(s1_row.inherited, 'tide_file') % Row Holds The File Name
                    rules.tide_name = s1_row.inherited.tide_file;
                end
            end
        end

        function tf = sim_is_stale(~, row, s1_rows)
            % Multi-Line Stage 2 Registry Row Stale: No Stage 1 Row (s1_rows) Of Its Storm DB + Workflow, Or Its stage1_stamp Is
            % Not That Row's forcing_stamp (Kept With Keep At A Stage 1 Drift Question; Offered Again Only By The Next Stage 1
            % Run That Rebuilds Its Forcing Or Changes Its Kt Geometry, plan_run)
            s1 = s1_rows(strcmpi(row.db, {s1_rows.db}) & strcmpi(row.workflow, {s1_rows.workflow}));
            tf = isempty(s1) || ~strcmp(row.stage1_stamp, s1(1).forcing_stamp);
        end

        function asked = queue_sync_drift(obj, proj, info)
            % After A Registry Sync (chessProject.sync_sims info): Drift Queued (take_drift) Per Multi-Line Stage 1 Alternative
            % Whose Bundles Were Dropped ('removed') Or Reloaded With Another forcing_stamp / structure_kt ('changed').
            % asked: Any Bundle Queued
            asked = false;
            lists = {info.stage1_dropped, 'removed'; info.stage1_changed, 'changed'};
            for ll = 1:size(lists, 1)
                rows = lists{ll, 1};
                if isempty(rows)
                    continue
                end
                asked = true;
                [~, first, grp] = unique(strcat(rows(:, 1), '|', rows(:, 2)), 'stable');
                for gg = 1:numel(first)
                    obj.drift(end+1, :) = {proj, rows{first(gg), 1}, rows{first(gg), 2}, rows(grp == gg, 3:4), lists{ll, 2}};
                end
            end
        end

        function q = drift_question(obj, d)
            % Question Of A Drift Entry (take_drift: {proj, pse, s1_alt, db_wf, kind}): Multi-Line Stage 1 Bundles (Rows
            % {db, workflow} Of db_wf) Removed ('removed') Or Changed ('changed') Outside CHESS; Their Stage 2 Rows Of The Same
            % Storm DB + Workflow (cascade_sims) Listed With "Delete" | "Keep" (Default). [] When None Depends On Them
            [proj, pse_name, s1_alt, db_wf, kind] = d{:};
            q = [];
            cascade = obj.cascade_sims(proj, pse_name, s1_alt, db_wf);
            if isempty(cascade)
                return
            end
            pairs = strjoin(unique(strcat(db_wf(:, 1), {' | '}, db_wf(:, 2))), ', ');
            lines = strjoin(strcat({['  ' char(8226) ' ']}, cascade(:, 1), {': '}, cascade(:, 2), {' | '}, cascade(:, 3)), newline);
            if strcmp(kind, 'removed')
                msg = sprintf('Stage 1 results for %s (%s/%s) were removed outside CHESS. These stage 2 results depend on them:\n%s',...
                    pairs, pse_name, s1_alt, lines);
            else
                msg = sprintf('Stage 1 results for %s (%s/%s) changed outside CHESS; these stage 2 results are stale:\n%s',...
                    pairs, pse_name, s1_alt, lines);
            end
            q = obj.question('drift', 'Multi-Line Stage 1 Results', msg, {'Delete', 'Keep'}, 560); % Last Button = Default: Keep
        end

        function apply_drift(obj, d, answer)
            % Answer To drift_question: "Delete": The Stage 2 Rows Deleted (delete_sim_rows), Those Alternatives Re-Synced,
            % Project Saved; Files Not Deleted: Warning. Anything Else (Keep): Files And Rows Stay (Stale: Marked In The Tree,
            % Offered Again By The Next Stage 1 Run)
            if ~strcmp(answer, 'Delete')
                return
            end
            [proj, pse_name, s1_alt, db_wf] = d{1:4};
            cascade = obj.cascade_sims(proj, pse_name, s1_alt, db_wf);
            failed = obj.delete_sim_rows(proj, pse_name, cascade);
            for aa = unique(cascade(:, 1))'
                proj.sync_sims({pse_name, aa{1}}, 'sync');
            end
            obj.save_project(proj);
            obj.mark(obj.VIEWS); % The Active Alternative's Bundles May Be Gone
            if ~isempty(failed)
                obj.message('warning', 'Multi-Line Stage 1 Results', sprintf(['These second-stage files could not be deleted (a ',...
                    'file may be open in another program):\n%s\nClose it and remove those simulations.'], strjoin(failed, newline)));
            end
        end

        function elev = db_offshore_elevation(~, dbObj)
            % Offshore Elevation Of A Storm DB: db_info Study Grid Value (Library storm_db_bias_uncertainty). [] When The Storm
            % DB Has None (Custom Modeling, No CHS_Dependencies, Grid Without Values): The PSE Geometry Value Is Used
            elev = [];
            if isstruct(dbObj.db_info) && isfield(dbObj.db_info, 'offshore_elevation') && ~isempty(dbObj.db_info.offshore_elevation)
                elev = dbObj.db_info.offshore_elevation;
            end
        end

        function [elev, source] = offshore_elevation(obj, alt_name)
            % Offshore Elevation Shown On The Run Tab And In The PSE Pop-Out: Run Tab Storm DB Study Grid Value (Wins, As In
            % run_config), Else The PSE Geometry Value Of alt_name (Default: The Active Alternative; Fallback Entered At PSE
            % Creation), Else NaN. No Run Tab Storm DB: The PSE Value. The Active Multi-Line Stage 2: Its Stage 1's Toe In
            % Stage 1's Saved Run Of The Run Tab Storm DB + Workflow (Library multiline_stage2_config; stage1_row: Row
            % structure_kt), NaN Without That Run
            [pse_name, act_alt] = obj.active_names();
            if nargin < 2
                alt_name = act_alt;
            end
            if obj.project.alt_stage(pse_name, alt_name) == 2
                s1_row = obj.stage1_row();
                elev = NaN;
                if ~isempty(s1_row)
                    elev = s1_row.structure_kt.toe_elevation;
                end
                source = 'stage 1 toe';
                return
            end
            elev = [];
            dbObj = obj.run_db();
            if ~isempty(dbObj)
                elev = obj.db_offshore_elevation(dbObj);
            end
            source = 'Storm DB grid';
            if isempty(elev)
                elev = NaN;
                source = '';
                pse_geo = obj.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                if isstruct(pse_geo) && isfield(pse_geo, 'offshore_elevation') && ~isempty(pse_geo.offshore_elevation)
                    elev = pse_geo.offshore_elevation;
                    source = 'PSE geometry';
                end
            end
        end

        function [elev, source] = popout_offshore_elevation(obj)
            % Offshore Elevation For The PSE Pop-Out Text Box: Study Grid Value Of The Run Tab Storm DB, Else The PSE Geometry
            % Value. None -> [] (chessProject.plot_geometry Keeps The PSE Value, Else The Library Shows 'n/a'). Multi-Line
            % Stage 2: Stage 1's Offshore End As Its Runs Resolve It (No Stage 1 Run: [], Stage 2 Plotted Alone)
            elev = [];
            source = '';
            if isempty(obj.project) || isempty(obj.project.stormDB_list) || isempty(obj.run_db())
                return
            end
            [pse_name, alt_name] = obj.active_names();
            if obj.project.alt_stage(pse_name, alt_name) == 2
                if isempty(obj.stage1_row())
                    return
                end
                alt_name = obj.project.stage1_alt(pse_name);
            end
            [elev, source] = obj.offshore_elevation(alt_name);
            if strcmp(source, 'Storm DB grid')
                source = ['Storm DB: ' obj.selection.db];
            elseif isnan(elev)
                elev = [];
            end
        end

        function tbl = pse_table(obj)
            % PSE Viewer Table: The Active Alternative's pse_tables. The offshore_elevation Row (Fallback Value) Is Shown Only
            % When The Run Tab Storm DB Has No Study Grid Value, Or There Is No Run Tab Storm DB; Multi-Line Stage 2: Neither It
            % Nor offshore_slope (From Stage 1). Display Only: pse_tables Keeps Them
            tbl = cell(0, 4);
            if ~obj.has_active_alt()
                return
            end
            [pse_name, alt_name] = obj.active_names();
            tbl = obj.project.get_project_field('pse_tables', pse_name, alt_name, 'alt');
            dbObj = obj.run_db();
            if obj.project.alt_stage(pse_name, alt_name) == 2 % Multi-Line Stage 2: Offshore End From Stage 1 (multiline_stage2_config)
                tbl = tbl(~ismember(tbl(:, 1), {'offshore_elevation', 'offshore_slope'}), :);
            elseif ~isempty(dbObj) && ~isempty(obj.db_offshore_elevation(dbObj))
                tbl = tbl(~strcmp(tbl(:, 1), 'offshore_elevation'), :);
            end
        end

        function data = constants(obj)
            % Project Panel Constants Table Rows {Field, Units, Value}: Water Density (Active PSE, As Used By Runs), Gravity
            % (Library Value), Offshore Elevation (offshore_elevation), Multi-Line Transect Rows And The Run Tab Storm DB's Bias &
            % Uncertainty (db_info, Library storm_db_info). No Storm DB: '-'. db_info Missing Fields: Re-Import
            density = {'-', NaN};
            offshore = {'-', '-'};
            dbObj = [];
            % Multi-Line Transect Row; Stage 2: Offshore End From Stage 1 (Library multiline_stage2_config), Slope Row Added
            ml_rows = {'Multi-Line Transect', '-', '-'};
            offshore_lbl = 'Offshore Elevation (Storm DB / PSE)';
            if obj.has_active_alt()
                [pse_name, alt_name] = obj.active_names();
                switch obj.project.alt_stage(pse_name, alt_name)
                    case 1
                        ml_rows{3} = sprintf('Stage 1 (%d coupled)', numel(obj.project.multiline_stage2(pse_name, alt_name)));
                    case 2
                        % From Stage 1's Registry Row Of The Run Tab Storm DB + Workflow (stage1_row), Never Its PSE Table
                        s1_alt = obj.project.stage1_alt(pse_name);
                        s1_row = obj.stage1_row();
                        s1_note = 'Run stage 1 first';
                        if isempty(obj.selection.db)
                            s1_note = 'No storm DB in project';
                        end
                        s1_slope = s1_note;
                        if ~isempty(s1_row)
                            s1_slope = s1_row.structure_kt.offshore_slope;
                        end
                        ml_rows(1, 3) = {sprintf('Stage 2 of %s/%s', pse_name, s1_alt)};
                        ml_rows(2, :) = {'Offshore Slope (From Stage 1)', '-', s1_slope};
                        offshore_lbl = 'Offshore Elevation (From Stage 1 Toe)';
                end
                tbl = obj.project.get_project_field('pse_tables', pse_name, alt_name, 'alt');
                geo = obj.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                density = {erase(tbl{strcmp(tbl(:, 1), 'water_density'), 3}, {'[', ']'}), geo.water_density};
                dbObj = obj.run_db();
                unitLib = auxUIFunctions.update_unit_system(obj.project.unitsys);
                offshore = {unitLib.unitSymbols.length, obj.offshore_elevation()};
                if obj.project.alt_stage(pse_name, alt_name) == 2 && isnan(offshore{2})
                    offshore{2} = s1_note;
                end
            end
            % Storm DB Rows. DET Runs Without Forcing Uncertainty
            u_note = '';
            if obj.selection.workflow == 2
                u_note = ' (Not Used By DET)';
            end
            db_rows = {['SWL Ua' u_note], 'm'; ['SWL Ur' u_note], '-'; ['Hm0 Ua' u_note], 'm'; ['Hm0 Ur' u_note], '-';...
                ['Tp Ur (From Hm0 Ur)' u_note], '-'; 'SWL Ba (Applied To TC At DB Build)', 'm'; 'SWL Br (Applied To TC At DB Build)', '-';...
                'TC Bias Corrected', '-'; 'B&U Source (SWL / Hm0)', '-'};
            if isempty(dbObj)
                db_rows(:, 3) = {'-'};
            elseif ~storm_db_info('valid', dbObj.db_info)
                db_rows(:, 3) = {'n/a (re-import DB)'};
            else
                info = dbObj.db_info;
                yes_no = {'No', 'Yes'};
                db_rows(:, 3) = {info.chs_swl_u_a; info.chs_swl_u_r; info.chs_hm0_u_a; info.chs_hm0_u_r;...
                    sqrt(1 + info.chs_hm0_u_r) - 1; info.chs_swl_b_a; info.chs_swl_b_r;... % Tp Ur As In apply_uncertainty
                    yes_no{1 + isequal(info.tc_bias_corrected, 1)}; [info.chs_swl_bu_source ' / ' info.chs_hm0_bu_source]};
            end
            data = [{'Water Density', density{:}; 'Gravity Constant', 'm/s^2', obj.GRAVITY;...
                offshore_lbl, offshore{:}}; ml_rows; db_rows];
        end
    end

    %% STAGE 4: PROJECT MANAGEMENT
    methods
        function q = lock_project(obj, proj)
            % One CHESS Session Per Project: Locks proj's Folder (chessProject.acquire_lock) Before It Becomes Active, Then
            % Releases The Previous Project's Lock. Already Held: Nothing To Do. Not Lockable (Held By Another Session, Folder
            % Missing Or Read-Only): q = Notice ('info' Question, OK Only), The Caller Keeps The Previous Selection; Else []
            q = [];
            if ~isempty(obj.lock) && obj.lock.proj == proj
                return
            end
            [lk, msg] = obj.try_lock(proj);
            if isempty(lk)
                q = obj.notice(msg);
                return
            end
            obj.release_lock();
            obj.lock = struct('proj', proj, 'lock', lk);
        end

        function release_lock(obj)
            % Releases The Active Project's Lock, If Any (Project Switch, Project Folder Rename, App Close). Idempotent
            if ~isempty(obj.lock)
                chessProject.release_lock(obj.lock.lock);
                obj.lock = [];
            end
        end

        function out = open_project(obj, mat_file)
            % Import A Project From Its Project File <root>\<name>\CHESS_project_<name>.mat. Project Folder Not Where It Was
            % Saved (Moved, Copied, Extracted Archive): Stored Paths Relocated To <root>\<name>; A Bundled CHS_Dependencies
            % Folder Is Always Used. Then Locked (Not Lockable: out.status 'refused', out.question = Notice, Not Imported),
            % Its Simulation Registry Synced With Disk (chessProject.sync_sims 'sync'), Made Active And Saved There. The
            % Previous Project Keeps Its Lock Until The Import Has Succeeded; A Failure Releases The New Lock, Drops The Project
            % And Re-Activates The Previous Selection (out.status 'error', out.text, out.rolled_back).
            %   out.status 'opened': out.info (sync_sims, For queue_sync_drift), out.note (Sync Counts, '' When Nothing Changed)
            out = struct('status', 'error', 'text', '', 'question', [], 'info', [], 'note', '', 'rolled_back', false);
            S = load(mat_file);
            if ~isfield(S, 'chess_project') || ~isa(S.chess_project, 'chessProject')
                out.text = 'Please select a valid "chessProject" class object.';
                return
            end
            proj = S.chess_project;
            if obj.is_loaded(proj.name)
                out.text = ['Project "' proj.name '" is already loaded.'];
                return
            end
            [new_root, folder_name] = fileparts(fileparts(mat_file));
            if ~strcmp(folder_name, proj.name)
                out.text = ['The project file must be inside its project folder "' proj.name '" (found in "' folder_name '").'];
                return
            end
            if ~chessProject.same_path(new_root, proj.path)
                proj.relocate(new_root);
            end
            bundle_dir = fullfile(new_root, proj.name, 'CHS_Dependencies');
            if isfolder(bundle_dir)
                proj.chs_dependencies = bundle_dir;
            end
            [lk, lock_msg] = obj.try_lock(proj);
            if isempty(lk)
                out.status = 'refused';
                out.question = obj.notice(lock_msg);
                return
            end
            prev_proj = '';
            if ~isempty(obj.project)
                prev_proj = obj.project.name;
            end
            [prev_pse, prev_alt] = obj.active_names();
            try
                out.info = proj.sync_sims('project', 'sync');
                obj.add_project(proj);
                obj.save_project();
            catch ME
                chessProject.release_lock(lk);
                obj.remove_project(proj);
                obj.select(prev_proj, prev_pse, prev_alt);
                out.rolled_back = true;
                out.text = ['Could not import project "' proj.name '": ' ME.message];
                return
            end
            obj.release_lock();
            obj.lock = struct('proj', proj, 'lock', lk);
            out.status = 'opened';
            out.note = obj.sync_note(out.info);
        end

        function tf = is_loaded(obj, name)
            % A Loaded Project Has This Name
            tf = ~isempty(obj.projects) && any(strcmp(name, {obj.projects.name}));
        end

        function msg = refusal(obj, proj, action, verb)
            % Project Changes Only On The Active Project (The One This Session Holds The Lock Of) And Never During A Run.
            % action: 'Removing' | 'Rebuilding' | 'Rename'; verb: 'changed' | 'rebuilt' | 'renamed'. '' When Allowed
            msg = '';
            if obj.runActive
                msg = sprintf('%s is not available while a run is in progress.', action);
            elseif isempty(obj.project) || proj ~= obj.project
                msg = sprintf('Select project "%s" first: only the active project can be %s.', proj.name, verb);
            end
        end

        function out = rebuild_sims(obj, proj)
            % "Rebuild simulations from disk": The Active Project's Registry Rebuilt From Every Bundle On Disk
            % (chessProject.sync_sims 'full'), Saved; Multi-Line Stage 1 Drift Queued (queue_sync_drift); Saved Simulation Key
            % Re-Resolved, Loaded Results Dropped. out.text: The Counts
            out = struct('done', false, 'text', obj.refusal(proj, 'Rebuilding', 'rebuilt'));
            if ~isempty(out.text)
                return
            end
            info = proj.sync_sims('project', 'full');
            obj.save_project(proj);
            obj.queue_sync_drift(proj, info);
            obj.reset_key();
            [act_pse, act_alt] = obj.active_names();
            obj.select(proj.name, act_pse, act_alt);
            out.done = true;
            out.text = sprintf('Simulations rebuilt from disk: %d added, %d refreshed, %d dropped.', info.added, info.refreshed, info.dropped);
            if info.skipped > 0
                out.text = sprintf('%s\n%d simulation(s) skipped: their config file could not be read.', out.text, info.skipped);
            end
        end

        function labels = sim_labels(~, proj, pse_name, alt_name)
            % Bundle Labels ('<db> | <workflow>') Of An Alternative, Without Registry Repair (Dialog Lists)
            labels = arrayfun(@chessProject.sim_label, proj.sim_rows(pse_name, alt_name, false), 'un', false);
        end

        function out = remove_sims(obj, proj, pse_name, alt_name, labels, answers)
            % Delete Simulation Bundles (Registry Rows: Run Files Of One Storm DB + Workflow) labels Of An Alternative Of proj.
            % A Multi-Line Stage 1 Bundle Takes The Stage 2 Bundles Of The Same Storm DB + Workflow With It: Question 'cascade'
            % ("Delete" | "Cancel"; Re-Entrant, Nothing Deleted Before It Is Answered). Files And Rows Through
            % chessProject.delete_sim; Saved Simulation Key Re-Resolved; Project Saved; Files Not Deleted: Warning.
            %   out.status: 'ask' (out.question) | 'cancel' | 'none' (No Such Bundle) | 'done'
            if nargin < 6
                answers = struct();
            end
            out = struct('status', 'none', 'question', []);
            rows = obj.sim_rows(proj, pse_name, alt_name);
            rows = rows(ismember(arrayfun(@chessProject.sim_label, rows, 'un', false), labels));
            if isempty(rows)
                return
            end
            del = [repmat({alt_name}, numel(rows), 1), {rows.db}', {rows.workflow}'];
            cascade = obj.cascade_sims(proj, pse_name, alt_name, del(:, 2:3));
            if ~isempty(cascade)
                lines = strcat({['  ' char(8226) ' ']}, cascade(:, 1), {': '}, cascade(:, 2), {' | '}, cascade(:, 3));
                q = obj.question('cascade', 'Remove Alternative Simulation', sprintf(['"%s" is the first stage of a multi-line ',...
                    'transect. These second-stage simulations use its results and are deleted too:\n%s'], alt_name,...
                    strjoin(lines, newline)), {'Delete', 'Cancel'}, 560);
                [a, out] = obj.answer_of(q, answers, out);
                if isempty(a)
                    return
                elseif ~strcmp(a, 'Delete')
                    out.status = 'cancel';
                    return
                end
                del = [del; cascade];
            end
            failed = obj.delete_sim_rows(proj, pse_name, del);
            obj.reset_key();
            [act_pse, act_alt] = obj.active_names();
            obj.select(obj.project.name, act_pse, act_alt);
            obj.save_project(proj);
            out.status = 'done';
            if ~isempty(failed)
                obj.message('warning', 'Remove Alternative Simulation', sprintf(['Deleted, but these files could not be deleted ',...
                    '(a file may be open in another program):\n%s\nClose it and remove the simulation again.'], strjoin(failed, newline)));
            end
        end

        function out = rename(obj, proj, level, new_name, pse_name, alt_name, siblings)
            % Rename A Project, PSE Or Alternative Of The Active Project (chessProject.rename: Folder, Stored Paths, Saved Run
            % Configs). The Active Project's Lock File Is Open Inside Its Folder: Released For The Folder Move, Taken Again After
            % (Not Taken: Warning, The Project Stays Open Without A Lock). The Active Selection And The Run Tab Snapshot Follow
            % The Rename; Session State Holding The Old Paths Is Remapped (remap_paths); Project Saved, Selection Re-Applied.
            %   out.status 'done' | 'error' (out.text: Rename Error); Warnings (Lock, Files Not Updated) Queued
            out = struct('status', 'error', 'text', '');
            current = new_name;
            switch level
                case 'proj'
                    current = proj.name;
                case 'pse'
                    current = pse_name;
                case 'alt'
                    current = alt_name;
            end
            act_proj = obj.project.name;
            [act_pse, act_alt] = obj.active_names();
            ctx_before = strjoin({act_proj, act_pse, act_alt}, '|');
            relock = strcmp(level, 'proj') && ~isempty(obj.lock) && obj.lock.proj == proj;
            if relock
                obj.release_lock();
            end
            rename_err = [];
            try
                info = proj.rename(level, new_name, pse_name, alt_name, siblings);
            catch rename_err
            end
            lock_warn = '';
            if relock
                [lk, lock_msg] = obj.try_lock(proj);
                if isempty(lk)
                    lock_warn = sprintf(['%s\nThe project is open without a lock: another CHESS session could open and change ',...
                        'it too. Select the project again to retry.'], lock_msg);
                else
                    obj.lock = struct('proj', proj, 'lock', lk);
                end
            end
            if ~isempty(rename_err)
                out.text = ['Could not rename "' current '": ' rename_err.message];
                if ~isempty(lock_warn)
                    obj.message('warning', 'Project Not Locked', lock_warn);
                end
                return
            end
            is_active = proj == obj.project;
            switch level
                case 'proj'
                    if is_active
                        act_proj = new_name;
                    end
                case 'pse'
                    if is_active && strcmp(act_pse, current)
                        act_pse = new_name;
                    end
                case 'alt'
                    if is_active && strcmp(act_pse, pse_name) && strcmp(act_alt, current)
                        act_alt = new_name;
                    end
            end
            if strcmp(obj.snapshot.context, ctx_before)
                obj.snapshot.context = strjoin({act_proj, act_pse, act_alt}, '|');
            end
            obj.remap_paths(@(p) chessProject.relocate_path(p, info.old_dir, info.new_dir));
            obj.save_project(proj);
            obj.select(act_proj, act_pse, act_alt);
            out.status = 'done';
            if ~isempty(info.failed)
                lock_warn = strtrim(sprintf('%s\n\n%s', sprintf('Renamed to "%s", but these files could not be updated:\n%s',...
                    new_name, strjoin(info.failed, newline)), lock_warn));
            end
            if ~isempty(lock_warn)
                obj.message('warning', 'Rename', lock_warn);
            end
        end

        function text = remove_alt_prompt(obj, pse_name, alt_name)
            % Confirmation Text Of Removing An Alternative: The Last Alternative Or A Multi-Line Stage 1 Takes The PSE With It
            % (chessProject.remove_alternative)
            if obj.project.alt_stage(pse_name, alt_name) == 1
                text = sprintf(['"%s" is the first stage of multi-line PSE "%s": its second stages use its results.\n',...
                    'Removing it deletes the WHOLE multi-line PSE "%s" (all its alternatives and run results, files ',...
                    'included). Remove PSE "%s"?'], alt_name, pse_name, pse_name, pse_name);
            elseif numel(obj.project.get_project_field('alternative_list', pse_name, '', 'pse')) == 1
                text = sprintf(['"%s" is the last alternative of PSE "%s", so the PSE is removed too.\n',...
                    'Remove PSE "%s" and delete its folder (all alternatives and run results)?'], alt_name, pse_name, pse_name);
            else
                text = sprintf('Remove alternative "%s" of PSE "%s" and delete its folder (all run results)?', alt_name, pse_name);
            end
        end

        function err = remove_element(obj, kind, pse_name, alt_name)
            % Remove A PSE ('pse'), Alternative ('alt': Folder Deleted, chessProject.delete_folder; Nothing Changes If That Fails)
            % Or Tide File ('tide': alt_name = File Name) Of The Active Project; Loaded Results Dropped, Selection Re-Applied,
            % Saved. A Folder Not Fully Deleted: Warning. err: Error Text ('' On Success, Nothing Changed Otherwise)
            err = '';
            leftover = '';
            try
                switch kind
                    case 'pse'
                        leftover = obj.project.remove_pse(pse_name, true);
                        obj.clear_results();
                    case 'alt'
                        leftover = obj.project.remove_alternative(pse_name, alt_name, true);
                        obj.clear_results();
                    case 'tide'
                        tide_files = obj.project.tide_files_list;
                        [~, tide_names, tide_ext] = cellfun(@fileparts, tide_files, 'un', false);
                        obj.project.tide_files_list(strcmp(strcat(tide_names, tide_ext), alt_name)) = [];
                end
            catch ME
                switch kind
                    case 'pse'
                        err = ['Could not remove PSE "' pse_name '": ' ME.message];
                    otherwise
                        err = ['Could not remove alternative "' alt_name '": ' ME.message];
                end
                return
            end
            obj.reselect();
            obj.save_project();
            if ~isempty(leftover)
                obj.message('warning', 'Project Management: Remove', sprintf(['Removed, but this folder could not be fully ',...
                    'deleted (a file inside may be open):\n%s\nDelete it manually.'], leftover));
            end
        end

        function finish_element(obj, created, pse_name, alt_name, kind, stage)
            % After The PSE Creation Wizard: Created -> Multi-Line Link (stage 1 | 2, 0: None), Selected, Per-Alternative Fields
            % Kept Sized, Saved. Not Created -> The In-Progress PSE ('pse') Or Alternative ('alt') Removed (Keeps All Per-PSE
            % Fields Aligned), Selection Re-Applied
            if nargin < 6
                stage = 0;
            end
            if ~created
                if strcmp(kind, 'pse')
                    obj.project.remove_pse(pse_name);
                else
                    obj.project.remove_alternative(pse_name, alt_name);
                end
                obj.reselect();
                return
            end
            if stage > 0
                obj.project.link_multiline(pse_name, alt_name, stage);
            end
            obj.select(obj.project.name, pse_name, alt_name);
            obj.project.sync_alt_fields();
            obj.save_project();
        end

        function reselect(obj)
            % Active Selection Re-Applied By Name (Removed Items Fall Back To The First Available)
            if isempty(obj.project)
                obj.select('', '', '');
                return
            end
            [pse_name, alt_name] = obj.active_names();
            obj.select(obj.project.name, pse_name, alt_name);
        end

        function plan = stormdb_removal(obj, db_name)
            % Removing A Storm Database From The Active Project: Its Files (storm/prob_mass + Raw CHS_Data, If Any) And The
            % Question. Tied To Simulations (Registry Rows, chessProject.stormdb_tied_sims): "Delete" (Its Files And Those
            % Bundles' Run Files) | "Cancel". Otherwise "Remove" (Files Kept) | "Remove & Delete Files" (When It Has Files) |
            % "Cancel". plan.question: 'choice' Question 'remove_db'
            dbObj = obj.project.get_project_field('stormDB_list', db_name, '', 'db');
            plan = struct('db_name', db_name, 'db_files', {{}}, 'question', []);
            for ff = {'storm_db', 'chs_data'}
                if isfield(dbObj.output_paths, ff{1}) && isfile(dbObj.output_paths.(ff{1}))
                    plan.db_files{end+1} = dbObj.output_paths.(ff{1});
                end
            end
            tied = obj.project.stormdb_tied_sims(db_name);
            if ~isempty(tied)
                n_max = 15;
                lines = strcat({['  ' char(8226) ' ']}, tied);
                if numel(lines) > n_max
                    lines = [lines(1:n_max-1); {sprintf('  %sand %d more', char(8230), numel(tied) - n_max + 1)}];
                end
                msg = sprintf('Storm DB "%s" is tied to the following simulations:\n%s\n\nDeleting the storm DB will remove these alternatives'' simulation results.',...
                    db_name, strjoin(lines, newline));
                plan.question = obj.question('remove_db', 'Remove Storm Database', msg, {'Delete', 'Cancel'}, 560); % Last Button = Default (Enter): Cancel
            else
                msg = sprintf('Remove storm database "%s"?', db_name);
                options = {'Remove', 'Cancel'};
                if ~isempty(plan.db_files)
                    msg = sprintf('%s\n"Remove" keeps its files in Event_Database; "Remove & Delete Files" deletes them.', msg);
                    options = {'Remove', 'Remove & Delete Files', 'Cancel'};
                end
                plan.question = obj.question('remove_db', 'Remove Storm Database', msg, options, 440);
            end
        end

        function remove_stormdb(obj, plan, answer)
            % Execute A stormdb_removal Plan With Its Answer ('Delete' | 'Remove & Delete Files' | 'Remove'; Anything Else:
            % Nothing). Cached Data Dropped; 'Delete' Also Deletes Its Simulations' Run Files And Re-Resolves The Saved
            % Simulation Key. Last CHS Storm DB Removed: The Project's CHS_Dependencies Is Free Again. Selection Re-Applied,
            % Saved. Files Not Deleted: Warning
            if ~ismember(answer, {'Delete', 'Remove & Delete Files', 'Remove'})
                return
            end
            db_name = plan.db_name;
            obj.forget_files(plan.db_files);
            failed = {};
            switch answer
                case 'Delete'
                    run_files = obj.project.stormdb_run_files(db_name);
                    obj.project.remove_stormdb(db_name);
                    for ff = [run_files; plan.db_files']'
                        delete(ff{1});
                        if isfile(ff{1})
                            failed{end+1} = ff{1}; %#ok<AGROW>
                        end
                    end
                    obj.reset_key();
                case 'Remove & Delete Files'
                    obj.project.remove_stormdb(db_name);
                    cellfun(@delete, plan.db_files);
                otherwise
                    obj.project.remove_stormdb(db_name);
            end
            if isempty(obj.project.project_region())
                obj.project.chs_dependencies = '';
            end
            obj.reselect();
            obj.save_project();
            if ~isempty(failed)
                obj.message('warning', 'Remove Storm Database', sprintf('Storm DB "%s" removed, but these files could not be deleted:\n%s',...
                    db_name, strjoin(failed, newline)));
            end
        end

        function add_stormdb(obj, dbObj, overwrite, event_db_dir)
            % Storm DB Record From The Import Wizard Into The Active Project. Overwrite Of A Project Storm DB (Index Kept): Its Run
            % Files And Registry Rows Deleted (Old Results Would Otherwise Show As Saved), Cached Data Of The Old DB Dropped,
            % Saved Simulation Key Re-Resolved; Run Files Not Deleted: Warning. Project CHS_Dependencies: Set By The First CHS
            % (Non-Custom) Storm DB, Or Re-Pointed When The Stored Folder Is No Longer Valid; Cleared When No CHS Storm DB Is
            % Left. Selection Re-Applied, Saved
            indx = find(strcmpi(dbObj.db_name, {obj.project.stormDB_list.db_name}), 1);
            if overwrite && ~isempty(indx)
                old = obj.project.stormDB_list(indx);
                failed = {};
                for ff = obj.project.stormdb_run_files(old.db_name)'
                    delete(ff{1});
                    if isfile(ff{1})
                        failed{end+1} = ff{1}; %#ok<AGROW>
                    end
                end
                obj.project.drop_db_sims(old.db_name);
                obj.project.stormDB_list(indx) = dbObj;
                db_files = {dbObj.output_paths.storm_db, fullfile(event_db_dir, [dbObj.db_name '_raw_files.mat'])};
                if isstruct(old.output_paths)
                    db_files = [db_files, struct2cell(old.output_paths)'];
                end
                obj.forget_files(db_files);
                obj.reset_key();
                if ~isempty(failed)
                    obj.message('warning', 'Storm DB Overwrite', sprintf('Storm DB "%s" overwritten, but these run files could not be deleted:\n%s',...
                        dbObj.db_name, strjoin(failed, newline)));
                end
            else
                obj.project.add_project_field('stormDB_list', dbObj, '', '', 'pse');
            end
            region = obj.project.project_region();
            if isempty(region)
                obj.project.chs_dependencies = '';
            elseif ~strcmp(dbObj.study, 'Custom_Modeling') && ~isempty(chessProject.chs_dependencies_problem(obj.project.chs_dependencies, region))
                obj.project.chs_dependencies = dbObj.source_paths.chs_dependencies_path;
            end
            obj.reselect();
            obj.save_project();
        end

        function ok = select_bundle(obj, proj_name, pse_name, alt_name, label)
            % Project Tree Bundle Node Clicked: Its Alternative Selected, The Run Tab Storm DB + Workflow Set To The Bundle's
            % (run_request: Applied By The Run Tab Refresh Over Its Defaults And Snapshot) And Its Saved Simulation Key
            % Re-Resolved, So The Refresh Loads It Without A Question (An Explicit Pick). ok: The Bundle Is In The Registry
            obj.select(proj_name, pse_name, alt_name);
            rows = obj.sim_rows(obj.project, pse_name, alt_name);
            row = rows(strcmp(arrayfun(@chessProject.sim_label, rows, 'un', false), label));
            ok = ~isempty(row);
            if ~ok
                return
            end
            obj.runRequest = struct('db', row(1).db, 'workflow', chessProject.workflow_number(row(1).workflow));
            obj.set_run_selection(obj.runRequest.db, obj.runRequest.workflow);
            obj.reset_key();
        end

        function req = take_run_request(obj)
            % Storm DB + Workflow Requested By select_bundle ([] If None), Then Cleared
            req = obj.runRequest;
            obj.runRequest = [];
        end

        function set_snapshot(obj, values)
            % Run Tab Snapshot (Control Name, Value Rows) Of The Run Tab Context Shown (snapshot.context)
            obj.snapshot.values = values;
        end

        function new_context = set_context(obj)
            % Run Tab Context ('<project>|<pse>|<alt>', '' Without An Alternative And A Storm DB) Now Shown; new_context: It
            % Differs From The One The Snapshot Was Taken In
            context = '';
            if obj.has_active_alt() && ~isempty(obj.project.stormDB_list)
                [pse_name, alt_name] = obj.active_names();
                context = strjoin({obj.project.name, pse_name, alt_name}, '|');
            end
            new_context = ~strcmp(context, obj.snapshot.context);
            obj.snapshot.context = context;
        end
    end

    %% PRIVATE HELPERS
    methods (Access = private)
        function [lk, msg] = try_lock(~, proj)
            % chessProject.acquire_lock Of proj's Folder, Nothing Else Changed. Refused: lk = [], msg = The Notice Text
            % (Another Session Holds It, Or Why The Lock File Is Not Usable)
            msg = '';
            [lk, holder, problem] = chessProject.acquire_lock(fullfile(proj.path, proj.name));
            if isempty(lk) && isempty(problem)
                msg = sprintf('Project %s is open in another CHESS session (%s).', proj.name, holder);
            elseif isempty(lk)
                msg = sprintf('Project %s cannot be locked: %s.', proj.name, problem);
            end
        end

        function q = notice(~, text)
            % Modal Notice With OK Only ('info' Question)
            q = struct('id', 'notice', 'kind', 'info', 'title', 'Project Not Opened', 'text', text, 'items', {{}},...
                'choices', {{'OK'}}, 'default', 'OK', 'size', 440);
        end

        function note = sync_note(~, info)
            % Status Text Of A Registry Sync (chessProject.sync_sims info); '' When Nothing Changed
            parts = {};
            if info.added + info.refreshed + info.dropped > 0
                parts{end+1} = sprintf('%d added, %d refreshed, %d dropped', info.added, info.refreshed, info.dropped);
            end
            if info.converted > 0
                parts{end+1} = sprintf('%d storm DB record(s) converted', info.converted);
            end
            if info.skipped > 0
                parts{end+1} = sprintf('%d skipped (config file could not be read)', info.skipped);
            end
            note = '';
            if ~isempty(parts)
                note = ['Simulations synced from disk: ' strjoin(parts, '; ') '.'];
            end
        end

        function dbObj = run_db(obj)
            % Storm DB Record Of The Run Tab Selection ([] Without One)
            dbObj = [];
            if ~isempty(obj.project) && ~isempty(obj.selection.db)
                dbObj = obj.project.get_project_field('stormDB_list', obj.selection.db, '', 'db');
            end
        end

        function dts = results_data_types(obj, row)
            % Data Types In The Loaded Results That A Plot Type Supports
            Resp = obj.results.Resp;
            dts = intersect(row.data_types, fieldnames(Resp), 'stable');
            if row.needs_s % Armor Damage Plots: Results Must Include Damage (S)
                has_s = cellfun(@(dt) any(structfun(@(mt) any(structfun(@(st) isstruct(st) && isfield(st, 'S'), mt)), Resp.(dt))), dts);
                dts = dts(has_s);
            end
        end

        function fields = response_list(obj, list_name)
            % Response Names Accepted By Library Plot Methods (Mirror Of Their Argument Validation)
            %   'annual': lcs_methods.annual_response_distribution | 'event': CHESSPlotsBase.storm_event_viewer (Per Structure Type)
            switch list_name
                case 'annual'
                    fields = {'Hm0t', 'R2p', 'R2p_SWL', 'Dn50', 'Dn50_LCBW', 'Dn50_Lee', 'p1', 'q', 'q_overflow', 'q_wave_ot',...
                        'Q_vol', 'Q_vol_overflow', 'Q_vol_wave_ot', 'DamDepthElev', 'DamDepth', 'p2dyn', 'p2sta', 'p2total',...
                        'p3dyn', 'p3sta', 'p3total', 'pu', 'X_low', 'X_up', 'X_c_surge', 'Bx', 'theta_low', 'theta_up',...
                        'theta_center', 'Bjet', 'Vjet', 'Fjet', 'S_seaside_with_repairs', 'S_seaside_no_repairs',...
                        'S_leeside_no_repairs', 'S_leeside_with_repairs'};
                case 'event'
                    overtopping = {'q', 'q_overflow', 'q_wave_ot', 'Q_vol', 'Q_vol_overflow', 'Q_vol_wave_ot', 'DamDepthElev', 'DamDepth'};
                    switch obj.results.structure.struc_type
                        case 1
                            fields = [{'Hm0t', 'R2p', 'R2p_SWL'}, overtopping];
                        case 2
                            fields = [{'p1'}, overtopping, {'p2dyn', 'p2sta', 'p2total', 'p3dyn', 'p3sta', 'p3total', 'pu',...
                                'X_low', 'X_up', 'X_c_surge', 'Bx', 'theta_low', 'theta_up', 'theta_center', 'Bjet', 'Vjet', 'Fjet'}];
                        case 3
                            fields = [{'Hm0t', 'R2p', 'R2p_SWL', 'Dn50', 'Dn50_LCBW', 'Dn50_Lee'}, overtopping];
                        otherwise
                            fields = [{'Hm0t', 'R2p', 'R2p_SWL', 'Dn50_LCBW'}, overtopping];
                    end
            end
        end

        function mark(obj, views)
            % Views Made Stale (VIEWS Names)
            obj.changed = union(obj.changed, cellstr(views));
        end

        function message(obj, severity, title_str, text)
            % Queue A Message (take_messages)
            obj.messages(end+1) = struct('severity', severity, 'title', title_str, 'text', text);
        end

        function v = input(obj, name, default)
            % Run Tab Value (default When Not Set)
            v = default;
            if isfield(obj.inputs, name)
                v = obj.inputs.(name);
            end
        end

        function end_run(obj)
            % run_guard Cleared
            if isvalid(obj)
                obj.runActive = false;
            end
        end

        function q = question(~, id, title_str, text, choices, fig_size)
            % Choice Question (One Button Per Choice; Last = Default)
            q = struct('id', id, 'kind', 'choice', 'title', title_str, 'text', text, 'items', {{}}, 'choices', {choices},...
                'default', choices{end}, 'size', fig_size);
        end

        function [a, out] = answer_of(~, q, answers, out)
            % Answer To q, Else out Asks It ('ask') Or Is Cancelled (Empty Answer); a Is Empty In Both Cases
            a = [];
            if ~isfield(answers, q.id)
                out.status = 'ask';
                out.question = q;
            elseif isempty(answers.(q.id))
                out.status = 'cancel';
            else
                a = answers.(q.id);
            end
        end

        function [q, plan] = saved_sim_question(obj)
            % Run With A Saved Simulation Of The Current Key: Its Hotstart Plan And The Run Question
            config = obj.run_config(false);
            S = load(config.out_files.config, 'config');
            S.config = obj.localize_saved_config(S.config); % Saved tide_file In This Project Folder: Not A Change (Hotstart Dependency)
            plan = obj.hotstart_plan(config, S.config);
            [~, label, run_date] = obj.saved_sim();
            options = {'Hotstart', 'Coldstart', 'Load existing', 'Cancel'};
            if ~plan.available
                options = options(2:end);
            end
            q = obj.question('saved_sim', 'Existing Simulation', sprintf('A simulation for %s already exists (run %s).\n%s',...
                label, run_date, plan.text), options, [560 170]);
        end

        function plan = hotstart_plan(obj, config, old)
            % Run With A Saved Simulation: Library Hotstart Level (hotstart_plan) Of The Current Inputs (config, Not For Run)
            % Against The Saved Run (old). GUI Inputs The Library Lists Do Not Cover (DB Uncertainties, Region) Count As
            % 'resample'. plan.available: Hotstart Offered (Not 'resample', Needed Cached Forcing/Seed Present). plan.text:
            % Question Line
            plan = struct('level', 'resample', 'reason', '', 'available', false, 'text', '', 'old', old);
            if ~isfield(old, 'forcing_stamp') % Complete Forcing Of The Saved Run (Library call_chess_boundary_conditions)
                plan.text = 'Hotstart not available: the saved run has no complete forcing.';
                return
            end
            is_lcs = config.workflow == 3 && isempty(config.multiline); % Multi-Line Stage 2 Samples Nothing (Stage 1's Life Cycles)
            why_not = '';
            gui_deps = {'region', 'chs_swl_u_a', 'chs_swl_u_r', 'chs_hm0_u_a', 'chs_hm0_u_r'};
            [changed_dep, plan.reason] = any_field_changed(config, old, gui_deps);
            if ~changed_dep
                [plan.level, plan.reason, why_not] = hotstart_plan(config, old, is_lcs);
            end
            if ~isempty(why_not)
                plan.text = sprintf('Hotstart not available: ''%s'' changed, but %s.', plan.reason, why_not);
            elseif strcmp(plan.level, 'resample')
                plan.text = sprintf('Hotstart not available: ''%s'' changed.', plan.reason);
            elseif strcmp(plan.level, 'full') && ~isfile(config.out_files.project_forcing)
                plan.text = 'Hotstart not available: the cached forcing is missing.';
            else
                plan.available = true;
                if strcmp(plan.level, 'reuse_sampling') && is_lcs
                    plan.text = sprintf('Hotstart keeps the sampled life cycles; forcing rebuilt because ''%s'' changed.', plan.reason);
                elseif strcmp(plan.level, 'reuse_sampling')
                    plan.text = sprintf('Hotstart rebuilds the forcing because ''%s'' changed.', plan.reason);
                elseif obj.inputs_changed(old, config)
                    plan.text = 'Hotstart reuses the cached forcing.';
                else
                    plan.text = 'Inputs are identical; a hotstart reproduces the saved results.';
                end
            end
        end

        function why = cascade_reason(obj, cascade, pse_name, alt_name, db_wf, level, pseObj)
            % Why A Multi-Line Stage 1 Run Invalidates Its Coupled Stage 2 Bundles (cascade); '' When It Does Not
            why = '';
            if isempty(cascade)
                return
            end
            s1_rows = obj.sim_rows(obj.project, pse_name, alt_name);
            s1_row = s1_rows(strcmpi(db_wf{1}, {s1_rows.db}) & strcmpi(db_wf{2}, {s1_rows.workflow}));
            if isempty(s1_row) || ~strcmp(level, 'full')
                why = 'Stage 1 forcing will be rebuilt.';
            else
                kt = fieldnames(s1_row(1).structure_kt)';
                if ~all(cellfun(@(f) isfield(pseObj, f) && isequaln(s1_row(1).structure_kt.(f), pseObj.(f)), kt))
                    why = 'Stage 1 crest, crest width, seaside slope, offshore slope or toe changed (stage 2 waves / offshore end).';
                end
            end
        end

        function [q, n_req] = lcs_question(obj, prob_mass)
            % LCS Convergence Question, Replacing The Library's Command-Window Prompt. Same Rule As chess_lcs
            % (lcs_reference_reuse): Effective Mode 0, Storm Types Not Reused From The Reference Case. Not Converged:
            % "Set mcs_nLC To <nLC_req> And Run" | "Run Anyway" | "Cancel". q Empty: Nothing To Ask
            q = [];
            n_req = [];
            config = obj.run_config(false);
            if ~isempty(obj.lcsCheck) && isequaln(obj.lcsCheck.config, config) % plan_run Passes Of The Same Run Start
                q = obj.lcsCheck.q;
                n_req = obj.lcsCheck.n_req;
                return
            end
            if config.workflow ~= 3 || ~isempty(config.multiline) % Multi-Line Stage 2: Stage 1's Life Cycles, Nothing Sampled
                return
            end
            reuse = lcs_reference_reuse(config);
            if isempty(reuse.check_types)
                return
            end
            checks = lcs_convergence_checks(config, prob_mass, reuse.check_types, true);
            checks = checks(~[checks.converged]);
            if isempty(checks)
                return
            end
            n_txt = @(n) aux_methods.tern(isinf(n), sprintf('> %s', regexprep(num2str(checks(1).nLC_cap), '(\d)(?=(\d{3})+$)', '$1,')), sprintf('%d', n));
            msg = sprintf('mcs_nLC = %d is below the number of life cycles needed for convergence (tol %g, confidence %g):',...
                config.mcs_nLC, config.lcs_convergence_tol, config.lcs_convergence_confidence);
            for cc = 1:numel(checks)
                msg = sprintf('%s\n%s: lambda x N = %.2f storms per life cycle; needed: mean %d, percentiles %s -> %s.', msg,...
                    checks(cc).stm_type, checks(cc).lamN, checks(cc).nLC_mean, n_txt(checks(cc).nLC_pct), n_txt(checks(cc).nLC_req));
            end
            n_req = max([checks.nLC_req]);
            options = {'Run anyway', 'Cancel'};
            if isfinite(n_req)
                options = [{sprintf('Set mcs_nLC to %d and run', n_req)}, options];
            end
            q = obj.question('lcs_convergence', 'LCS Convergence Check', msg, options, [620, 150 + 20*numel(checks)]);
            obj.lcsCheck = struct('config', config, 'q', q, 'n_req', n_req);
        end

        function run_progress(~, progress_fcn, step, message, labels)
            % Library call_chess_boundary_conditions progress_fcn: Steps 0-4 (Cache, Build, Uncertainty, Adjust, Save) ->
            % Bar Value And labels{step + 1}. The Library Message Still Goes To The Command Window
            disp(message);
            bar_val = [1 1 2 3 3.5]/5;
            progress_fcn(bar_val(step + 1), labels{step + 1});
        end

        function bk = sim_backup_paths(~, out_files)
            % Run Files Of A Slot A Run Overwrites (Saved Config, Project Forcing, LCS Sampling Seed) And Their Backups
            % While The Run Lasts (Same Folder: <file>_prev.mat). bk(k).name: 'config' | 'forcing' | 'seed'
            files = {out_files.config, out_files.project_forcing, lcs_sampling_seed_file(out_files.project_forcing)};
            prev = cellfun(@(f) [f(1:end-4) '_prev.mat'], files, 'un', false);
            bk = struct('name', {'config', 'forcing', 'seed'}, 'file', files, 'prev', prev);
        end

        function restore_leftover_backups(~, bk)
            % *_prev Files At Run Start: The Last Run Never Finished (e.g. MATLAB Closed), Put The Previous Run Back First
            for kk = 1:numel(bk)
                if isfile(bk(kk).prev)
                    movefile(bk(kk).prev, bk(kk).file, 'f');
                end
            end
        end

        function backed = backup_sim_files(obj, bk, level)
            % Back Up The Slot Before The Run Touches It (Before apply_hotstart_level Deletes Anything), By Hotstart Level:
            %   Config: Copied. Forcing: Moved (cold | resample | reuse_sampling: Rebuilt By The Run); 'full' Reuses It As Is
            %   (Nothing Re-Saves It), No Backup. Seed: Moved (cold | resample: Sampled Again), Copied (reuse_sampling: Read,
            %   Then Saved Again); 'full': No Backup. backed: Files This Run Backed Up (existed = false: Not There Before The
            %   Run, Its File Is Deleted On Failure). A Failure While Backing Up Restores What Was Done And Rethrows
            act = struct('config', 'copy', 'forcing', 'move', 'seed', 'move');
            switch level
                case 'full'
                    act.forcing = '';
                    act.seed = '';
                case 'reuse_sampling'
                    act.seed = 'copy';
            end
            backed = struct('name', {}, 'file', {}, 'prev', {}, 'existed', {});
            try
                for kk = 1:numel(bk)
                    entry = bk(kk);
                    if isempty(act.(entry.name))
                        continue
                    end
                    entry.existed = isfile(entry.file);
                    if entry.existed && strcmp(act.(entry.name), 'copy')
                        copyfile(entry.file, entry.prev, 'f');
                    elseif entry.existed
                        movefile(entry.file, entry.prev, 'f');
                    end
                    backed(end+1) = entry; %#ok<AGROW>
                end
            catch ME
                obj.restore_sim_files(backed);
                rethrow(ME);
            end
        end

        function failed = restore_sim_files(~, backed)
            % Failed Run: Put Back What This Run Backed Up (*_prev Moved Over Whatever The Run Left) And Delete The Files
            % It Created Where There Were None. Best Effort: failed Lists What Could Not Be Restored
            failed = {};
            for kk = 1:numel(backed)
                try
                    if backed(kk).existed
                        if isfile(backed(kk).prev)
                            movefile(backed(kk).prev, backed(kk).file, 'f');
                        end
                    elseif isfile(backed(kk).file)
                        delete(backed(kk).file);
                    end
                catch ME
                    failed{end+1} = sprintf('%s (%s)', backed(kk).file, ME.message); %#ok<AGROW>
                end
            end
        end
    end
end

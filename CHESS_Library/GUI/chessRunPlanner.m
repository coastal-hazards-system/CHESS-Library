classdef chessRunPlanner
    % CHESS GUI Run Planning (No Widgets, No State): Builds The Run config From The Run Tab Inputs (run_config), Compares
    % It With A Saved Run (inputs_changed), Asks The Run Questions (plan_run: Saved Simulation / Hotstart, Multi-Line Stage
    % 2 Cascade, LCS Convergence) And Runs The Plan (execute_run: Backup Of The Run Files, Library Forcing + Responses,
    % Registry Row, Restore On Failure).
    %   Static Helpers: Every Public Method Takes The chessController Handle (ctrl) First; All State (inputs, lcsCheck, Messages,
    %   View Flags) Stays On The Controller. Callers Use The Controller's One-Line Facades Of The Same Name
    %   (controller.plan_run(...)), Which Forward Here.

    methods (Static)
        function [config, pseObj] = run_config(ctrl, for_run, plan)
            % Run Step: Build config From The Run Tab Inputs + Project + Storm DB, Then Apply Library Run Rules
            %   for_run = false: Input Comparison Only (No Hotstart Actions, Nothing Saved)
            %   plan: Run Start (plan_run): plan.level 'cold' (Default) | 'full' | 'reuse_sampling', plan.old: Saved Run's config
            if nargin < 2
                for_run = true;
            end
            if nargin < 3
                plan = struct('level', 'cold', 'old', []);
            end
            proj = ctrl.project;
            [pse_name, alt_name] = ctrl.active_names();
            pseObj = proj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            dbObj = proj.get_project_field('stormDB_list', ctrl.selection.db, '', 'db');
            [~, ~, ~, ~, out_files] = ctrl.config_path();
            % Library Template Defaults For The Forcing Rows (Fresh Table) And Workflow Sections (Library Functions Read Them Regardless Of Workflow)
            tpl = proj.get_library_template(pseObj.pse_type);
            wf_rows = [tpl.forcing(ismember(tpl.forcing(:, 1), ctrl.FORCING_INPUTS), :); tpl.mcs; tpl.csr; tpl.pros];
            for rr = 1:size(wf_rows, 1)
                config.(wf_rows{rr, 1}) = wf_rows{rr, 4};
            end
            % Every Library Response Switch Defaults To Off (Union Of All Templates)
            types = {'Levee', 'Floodwall', 'Rubble Mound'};
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
            config.workflow = ctrl.selection.workflow;
            config.storm_sampling = ctrl.input('storm_sampling', '');
            % Data Types (Run Tab Tree Symbols)
            dt_checked = ctrl.input('data_types', {});
            config.use_peaks = +any(ismember({'peaks_default','create_wlp','create_whp'}, dt_checked));
            config.use_timeseries = +ismember('use_timeseries', dt_checked);
            config.create_wlp = +ismember('create_wlp', dt_checked);
            config.create_whp = +ismember('create_whp', dt_checked);
            % Project Forcing Adjustments
            config.swl_slr = ctrl.input('swl_slr', 0);
            config.tide_file = ctrl.input('tide_file', 'None');
            config.apply_random_tides = +~strcmp(config.tide_file, 'None');
            config.apply_depth_limitation = +ctrl.input('apply_depth_limitation', false);
            config.load_project_forcing = 0; % GUI Builds Project Forcing Itself
            config.ref_case_name = 'none';
            % Responses (Run Tab Tree Symbols)
            resp_checked = ctrl.input('responses', {});
            for rr = 1:length(resp_checked)
                config.(resp_checked{rr}) = 1;
            end
            % Inputs Of Every Workflow (Visible And Hidden Rows): Config Records The Full Input State
            input_fields = ctrl.table_fields();
            for rr = 1:length(input_fields)
                config.(input_fields{rr}) = +ctrl.inputs.(input_fields{rr});
            end
            % Storm DB Fields
            config.region = dbObj.study;
            config.sp_ID = '';
            config.sp_ID_wave = '';
            config.storm_db = ctrl.selection.db;
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
            config.gravity_constant = ctrl.GRAVITY;
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
                    if ~isempty(ctrl.stage1_row())
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

        function [changed, fld] = inputs_changed(ctrl, saved_config, config_now)
            % Current Run Tab Inputs Vs A Saved Run's config (Library any_field_changed, No Side Effects)
            if nargin < 3
                config_now = chessRunPlanner.run_config(ctrl, false);
            end
            % outfolder: Project Location (Moves With An Imported/Relocated Project), Not A Run Input
            ignore = {'out_files', 'outfolder'};
            [changed, fld] = any_field_changed(config_now, saved_config, setdiff(fieldnames(config_now), ignore));
        end

        function cascade = cascade_sims(ctrl, proj, pse_name, alt_name, db_wf)
            % Stage 2 Registry Rows (sim_rows) Coupled To alt_name (A Multi-Line Stage 1) With A Storm DB + Workflow Of db_wf
            % (Rows {db, workflow}). cascade: Rows {stage 2 alternative, db, workflow}; None (Or Not A Stage 1): Empty
            cascade = cell(0, 3);
            for s2 = proj.multiline_stage2(pse_name, alt_name)'
                rows = ctrl.sim_rows(proj, pse_name, s2{1});
                for rr = 1:numel(rows)
                    if any(strcmpi(rows(rr).db, db_wf(:, 1)) & strcmpi(rows(rr).workflow, db_wf(:, 2)))
                        cascade(end+1, :) = {s2{1}, rows(rr).db, rows(rr).workflow}; %#ok<AGROW>
                    end
                end
            end
        end

        function failed = delete_sim_rows(ctrl, proj, pse_name, rows)
            % Deletes Simulation Bundles Of PSE pse_name (Rows {alternative, db, workflow}): Files And Registry Row
            % (chessProject.delete_sim). failed: Files Not Deleted
            failed = cell(0, 1);
            for dd = 1:size(rows, 1)
                failed = [failed; proj.delete_sim(pse_name, rows{dd, :})]; %#ok<AGROW>
            end
            ctrl.mark('tree');
        end

        function out = plan_run(ctrl, answers)
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
                [pse_name, alt_name] = ctrl.active_names();
                [~, ~, ~, wflow_name, out_files] = ctrl.config_path();
                bk = chessRunPlanner.sim_backup_paths(out_files);
                chessRunPlanner.restore_leftover_backups(bk);
                pseObj = ctrl.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                dbObj = ctrl.project.get_project_field('stormDB_list', ctrl.selection.db, '', 'db');
                check_offshore_elevation(chessRunPlanner.run_config(ctrl, false));
                % Saved Simulation For This Alternative / Workflow / Storm DB: "Hotstart" (Hidden When Not Available) |
                % "Coldstart" | "Load existing" | "Cancel". No Saved Simulation: Coldstart
                plan = struct('level', 'cold', 'reason', '', 'available', false, 'text', '', 'old', []);
                if ctrl.saved_sim()
                    [q, plan] = chessRunPlanner.saved_sim_question(ctrl);
                    [a, out] = ctrl.answer_of(q, answers, out);
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
                if ctrl.project.alt_stage(pse_name, alt_name) == 1
                    plan.res_str = 'Stage 1 results';
                    db_wf = {ctrl.selection.db, wflow_name};
                    cascade = chessRunPlanner.cascade_sims(ctrl, ctrl.project, pse_name, alt_name, db_wf);
                    why = chessRunPlanner.cascade_reason(ctrl, cascade, pse_name, alt_name, db_wf, plan.level, pseObj);
                    if ~isempty(why)
                        lines = strcat({['  ' char(8226) ' ']}, cascade(:, 1), {' | '}, cascade(:, 2), {' | '}, cascade(:, 3));
                        q = ctrl.question('cascade', 'Run Multi-Line Stage 1', sprintf(['"%s" is the first stage of multi-line PSE ',...
                            '"%s". These second-stage simulations get their forcing from its %s run and are deleted once this run ',...
                            'succeeds:\n%s\n%s'], alt_name, pse_name, strjoin(db_wf, ' | '), strjoin(lines, newline), why),...
                            {'Continue', 'Cancel'}, 560); % Last Button = Default (Enter): Cancel
                        [a, out] = ctrl.answer_of(q, answers, out);
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
                if ctrl.selection.workflow == 3 && strcmp(plan.level, 'cold')
                    P = load(dbObj.output_paths.storm_db, 'prob_mass');
                    [q, n_req] = chessRunPlanner.lcs_question(ctrl, P.prob_mass);
                    if ~isempty(q)
                        [a, out] = ctrl.answer_of(q, answers, out);
                        if isempty(a)
                            return
                        elseif strcmp(a, 'Cancel')
                            out.status = 'cancel';
                            return
                        elseif startsWith(a, 'Set mcs_nLC')
                            ctrl.inputs.mcs_nLC = n_req; % The Inputs Table Shows (And The Run Reads) The New mcs_nLC
                            ctrl.mark('inputs_table');
                        end
                    end
                end
                plan.bk = bk;
                out.plan = plan;
            catch ME
                ctrl.message('error', 'Error Message', ['CHESS run failed: ' ME.message]);
                out.status = 'failed';
            end
        end

        function out = execute_run(ctrl, plan, progress_fcn)
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
            [pse_name, alt_name] = ctrl.active_names();
            backed = [];
            results_saved = false;
            row_added = false; % Registry Row Of This Bundle In The Project (upsert_sim)
            update_msg = '';
            failed = cell(0, 1); % Stage 2 Files Not Deleted
            config = [];
            pseObj = [];
            try
                dbObj = ctrl.project.get_project_field('stormDB_list', ctrl.selection.db, '', 'db');
                S = load(dbObj.output_paths.storm_db, 'storm', 'prob_mass');
                backed = chessRunPlanner.backup_sim_files(plan.bk, plan.level);
                [config, pseObj] = chessRunPlanner.run_config(ctrl, true, plan); % Includes Hotstart Actions

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
                    @(step, msg) chessRunPlanner.run_progress(progress_fcn, step, msg, bar_msg));

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
                    failed = chessRunPlanner.delete_sim_rows(ctrl, ctrl.project, pse_name, plan.cascade);
                end

                %%%% ---- 6. Store Outputs On Project
                progress_fcn(4.99/5, 'Saving Outputs');
                ctrl.project.upsert_sim(pse_name, alt_name, chessProject.sim_row_from_config(config, pseObj,...
                    dir(config.out_files.resp_data).datenum)); % Registry Row Of This Bundle
                row_added = true;
                ctrl.save_project();
                ctrl.mark('tree'); % New Simulation Bundle Node
                progress_fcn(1, 'Done');
            catch ME
                if ~results_saved
                    restore_failed = chessRunPlanner.restore_sim_files(backed);
                    msg = ['CHESS run failed: ' ME.message];
                    if ~isempty(restore_failed)
                        msg = [msg newline newline 'Previous run files not restored: ' strjoin(restore_failed, '; ')];
                    end
                    ctrl.message('error', 'Error Message', msg);
                    out.status = 'failed';
                    return
                end
                update_msg = sprintf('%s were saved, but updating the project failed: %s', plan.res_str, ME.message);
                if ~row_added
                    try
                        ctrl.project.upsert_sim(pse_name, alt_name, chessProject.sim_row_from_config(config, pseObj,...
                            dir(config.out_files.resp_data).datenum));
                    catch
                        update_msg = [update_msg newline newline 'The simulation is not in the project list: use "Rebuild ',...
                            'simulations from disk" on the project.'];
                    end
                end
                try
                    ctrl.save_project();
                catch
                    update_msg = [update_msg newline newline 'The project is not saved: save it before closing.'];
                end
                ctrl.mark('tree');
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
            ctrl.mark({'status', 'results'});
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
                ctrl.message('warning', title_str, alert_msg);
            end
        end
    end

    %% PRIVATE HELPERS
    methods (Static, Access = private)
        function [q, plan] = saved_sim_question(ctrl)
            % Run With A Saved Simulation Of The Current Key: Its Hotstart Plan And The Run Question
            config = chessRunPlanner.run_config(ctrl, false);
            S = load(config.out_files.config, 'config');
            S.config = ctrl.localize_saved_config(S.config); % Saved tide_file In This Project Folder: Not A Change (Hotstart Dependency)
            plan = chessRunPlanner.saved_run_hotstart_plan(ctrl, config, S.config);
            [~, label, run_date] = ctrl.saved_sim();
            options = {'Hotstart', 'Coldstart', 'Load existing', 'Cancel'};
            if ~plan.available
                options = options(2:end);
            end
            q = ctrl.question('saved_sim', 'Existing Simulation', sprintf('A simulation for %s already exists (run %s).\n%s',...
                label, run_date, plan.text), options, [560 170]);
        end

        function plan = saved_run_hotstart_plan(ctrl, config, old)
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
                elseif chessRunPlanner.inputs_changed(ctrl, old, config)
                    plan.text = 'Hotstart reuses the cached forcing.';
                else
                    plan.text = 'Inputs are identical; a hotstart reproduces the saved results.';
                end
            end
        end

        function why = cascade_reason(ctrl, cascade, pse_name, alt_name, db_wf, level, pseObj)
            % Why A Multi-Line Stage 1 Run Invalidates Its Coupled Stage 2 Bundles (cascade); '' When It Does Not
            why = '';
            if isempty(cascade)
                return
            end
            s1_rows = ctrl.sim_rows(ctrl.project, pse_name, alt_name);
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

        function [q, n_req] = lcs_question(ctrl, prob_mass)
            % LCS Convergence Question, Replacing The Library's Command-Window Prompt. Same Rule As chess_lcs
            % (lcs_reference_reuse): Effective Mode 0, Storm Types Not Reused From The Reference Case. Not Converged:
            % "Set mcs_nLC To <nLC_req> And Run" | "Run Anyway" | "Cancel". q Empty: Nothing To Ask
            q = [];
            n_req = [];
            config = chessRunPlanner.run_config(ctrl, false);
            if ~isempty(ctrl.lcsCheck) && isequaln(ctrl.lcsCheck.config, config) % plan_run Passes Of The Same Run Start
                q = ctrl.lcsCheck.q;
                n_req = ctrl.lcsCheck.n_req;
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
            q = ctrl.question('lcs_convergence', 'LCS Convergence Check', msg, options, [620, 150 + 20*numel(checks)]);
            ctrl.lcsCheck = struct('config', config, 'q', q, 'n_req', n_req);
        end

        function run_progress(progress_fcn, step, message, labels)
            % Library call_chess_boundary_conditions progress_fcn: Steps 0-4 (Cache, Build, Uncertainty, Adjust, Save) ->
            % Bar Value And labels{step + 1}. The Library Message Still Goes To The Command Window
            disp(message);
            bar_val = [1 1 2 3 3.5]/5;
            progress_fcn(bar_val(step + 1), labels{step + 1});
        end

        function bk = sim_backup_paths(out_files)
            % Run Files Of A Slot A Run Overwrites (Saved Config, Project Forcing, LCS Sampling Seed) And Their Backups
            % While The Run Lasts (Same Folder: <file>_prev.mat). bk(k).name: 'config' | 'forcing' | 'seed'
            files = {out_files.config, out_files.project_forcing, lcs_sampling_seed_file(out_files.project_forcing)};
            prev = cellfun(@(f) [f(1:end-4) '_prev.mat'], files, 'un', false);
            bk = struct('name', {'config', 'forcing', 'seed'}, 'file', files, 'prev', prev);
        end

        function restore_leftover_backups(bk)
            % *_prev Files At Run Start: The Last Run Never Finished (e.g. MATLAB Closed), Put The Previous Run Back First
            for kk = 1:numel(bk)
                if isfile(bk(kk).prev)
                    movefile(bk(kk).prev, bk(kk).file, 'f');
                end
            end
        end

        function backed = backup_sim_files(bk, level)
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
                chessRunPlanner.restore_sim_files(backed);
                rethrow(ME);
            end
        end

        function failed = restore_sim_files(backed)
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

classdef chessRunPlanner
    % CHESS GUI Run Planning (No Widgets, No State): Turns The Run Tab Inputs Into The Run Settings Of The Library Project
    % (run_settings; chess.Project.run_config Builds The config From Them), Compares Them With A Saved Run (inputs_changed),
    % Asks The Run Questions (plan_run: Saved Simulation / Hotstart, Multi-Line Stage 2 Cascade, LCS Convergence) And Runs
    % The Plan (execute_run: chess.Project.run Backs Up The Run Files, Builds The Forcing, Computes The Responses, Records
    % The Run And Puts The Files Back If The Run Fails).
    %   Static Helpers: Every Public Method Takes The chessController Handle (ctrl) First; All State (inputs, lcsCheck, Messages,
    %   View Flags) Stays On The Controller. Callers Use The Controller's One-Line Facades Of The Same Name
    %   (controller.plan_run(...)), Which Forward Here.

    methods (Static)
        function settings = run_settings(ctrl)
            % Run Settings Of The Active Alternative / Workflow / Run Tab Storm DB (chess.Project.run_settings Fields) From
            % The Run Tab Inputs: Storm Type, Data Types (Tree Symbols), Project Forcing Adjustments, Responses (Checked
            % Tree Symbols On, Every Other Switch Off; Parameters At Their Template Default Unless Held In inputs) And The
            % Inputs Table Values Of Every Workflow (Visible And Hidden Rows)
            proj = ctrl.project;
            [pse_name, alt_name] = ctrl.active_names();
            settings = proj.run_settings(pse_name, alt_name, ctrl.selection.workflow, ctrl.selection.db);
            % Every Response Switch Of The Structure Type Off Until Checked
            tpl = chessProjectView.template(proj.alternative(pse_name, alt_name).structure_type);
            for rr = find(startsWith(tpl.responses(:, 2), 'Comput'))'
                settings.(tpl.responses{rr, 1}) = 0;
            end
            settings.storm_sampling = ctrl.input('storm_sampling', '');
            % Data Types (Run Tab Tree Symbols)
            dt_checked = ctrl.input('data_types', {});
            settings.use_peaks = +any(ismember({'peaks_default','create_wlp','create_whp'}, dt_checked));
            settings.use_timeseries = +ismember('use_timeseries', dt_checked);
            settings.create_wlp = +ismember('create_wlp', dt_checked);
            settings.create_whp = +ismember('create_whp', dt_checked);
            % Project Forcing Adjustments
            settings.swl_slr = ctrl.input('swl_slr', 0);
            settings.tide_file = ctrl.input('tide_file', 'None');
            settings.apply_depth_limitation = +ctrl.input('apply_depth_limitation', false);
            % Responses (Run Tab Tree Symbols)
            resp_checked = ctrl.input('responses', {});
            for rr = 1:length(resp_checked)
                settings.(resp_checked{rr}) = 1;
            end
            % Inputs Of Every Workflow (Visible And Hidden Rows): Config Records The Full Input State
            input_fields = intersect(ctrl.table_fields(), fieldnames(settings), 'stable');
            for rr = 1:length(input_fields)
                settings.(input_fields{rr}) = +ctrl.inputs.(input_fields{rr});
            end
            % LCS Convergence: Asked Before The Run (plan_run); The Library Must Never Prompt In The Command Window
            settings.lcs_convergence_prompt = 0;
        end

        function [config, pseObj] = run_config(ctrl, varargin)
            % config Of The Run Tab Inputs (chess.Project.run_config Of run_settings: Project, Storm DB Details, Structure,
            % Library Run Rules, Multi-Line Coupling). Nothing Is Written: Input Comparison, Checks And Labels
            %   pseObj: The Structure Of The Run (Struct). Extra Inputs Are Ignored (Earlier for_run / plan)
            [pse_name, alt_name] = ctrl.active_names();
            [config, pseObj] = ctrl.project.run_config(pse_name, alt_name, chessRunPlanner.run_settings(ctrl));
        end

        function [changed, fld] = inputs_changed(ctrl, saved_config, config_now)
            % Current Run Tab Inputs Vs A Saved Run's config (Library chess.Hotstart.any_field_changed, No Side Effects)
            if nargin < 3
                config_now = chessRunPlanner.run_config(ctrl);
            end
            % outfolder: Project Location (Moves With An Imported/Relocated Project), Not A Run Input
            ignore = {'out_files', 'outfolder'};
            [changed, fld] = chess.Hotstart.any_field_changed(config_now, saved_config, setdiff(fieldnames(config_now), ignore));
        end

        function cascade = cascade_sims(ctrl, proj, pse_name, alt_name, db_wf)
            % Stage 2 Registry Rows (sim_rows) Coupled To alt_name (A Multi-Line Stage 1) With A Storm DB + Workflow Of db_wf
            % (Rows {db, workflow}). cascade: Rows {stage 2 alternative, db, workflow}; None (Or Not A Stage 1): Empty
            cascade = cell(0, 3);
            if proj.stage(pse_name, alt_name) ~= 1
                return
            end
            for s2 = proj.stage2_alternatives(pse_name)'
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
            % (chess.Project.delete_run, Which Saves The Project). failed: Files Not Deleted
            failed = cell(0, 1);
            for dd = 1:size(rows, 1)
                failed = [failed; proj.delete_run(pse_name, rows{dd, :})]; %#ok<AGROW>
            end
            ctrl.mark('tree');
        end

        function out = plan_run(ctrl, answers)
            % Run Start, Re-Entrant: Re-Evaluated From The Start On Every Call, Each Question Asked Once Its Answer Is Missing.
            %   answers: struct, answers.(question id) ('saved_sim', 'cascade', 'lcs_convergence'); An Empty Answer Cancels
            %   out.status: 'ask' (out.question) | 'run' (out.plan For execute_run) | 'load' (Load The Saved Simulation) |
            %               'cancel' | 'failed' (Error Message Queued; Nothing Touched)
            % Leftover Backups Of A Run That Never Finished Are Put Back First (chess.Project.restore_interrupted_run). The Run Inputs Are Checked Against The Library
            % Rules (chess.Config.validate; Problems: 'failed'). Every Run Needs An Offshore Elevation (Storm DB
            % Study Grid, Else The PSE Geometry): Checked Before Any Question (Library chess.Model.check_offshore_elevation)
            if nargin < 2 || isempty(answers)
                answers = struct();
            end
            out = struct('status', 'run', 'question', [], 'plan', []);
            try
                [pse_name, alt_name] = ctrl.active_names();
                [~, ~, ~, wflow_name] = ctrl.config_path();
                ctrl.project.restore_interrupted_run(pse_name, alt_name, ctrl.selection.workflow, ctrl.selection.db);
                pseObj = chessProjectView.geometry(ctrl.project, pse_name, alt_name);
                dbObj = ctrl.project.storm_database(ctrl.selection.db);
                % Every Missing Or Invalid Input Of The Run (Library chess.Config.validate: Workflow And Structure Rules,
                % Tide File Found When Random Tides Are On), In One Message, Before Any Question
                run_inputs = chessRunPlanner.run_config(ctrl);
                problems = chess.Config.validate(run_inputs);
                if ~isempty(problems)
                    ctrl.message('error', 'Error Message', sprintf('The run inputs have %d problem(s):\n%s', numel(problems),...
                        strjoin(strcat({'   - '}, problems), newline)));
                    out.status = 'failed';
                    return
                end
                chess.Model.check_offshore_elevation(run_inputs);
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
                % 'full') Or, At 'full', Its Kt Geometry Differs From Its Row's structure_kt (Library chess.Model.couple_to_stage1
                % stage1_structure). Deleted Only After The Run Succeeds (A Failed Run Restores Stage 1's Files)
                plan.cascade = cell(0, 3);
                plan.res_str = 'The results';
                if ctrl.project.stage(pse_name, alt_name) == 1
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
                out.plan = plan;
            catch ME
                ctrl.message('error', 'Error Message', ['CHESS run failed: ' ME.message]);
                out.status = 'failed';
            end
        end

        function out = execute_run(ctrl, plan, progress_fcn)
            % Run The Active Alternative / Workflow / Run Tab Storm DB With A plan_run Plan (chess.Project.run: The Run Files
            % Are Backed Up, The Forcing Is Built, The Responses Are Computed, The Run Is Recorded And The Project Saved).
            % progress_fcn(value, message): Progress (0-1; Callers Keep The Bar From Moving Back).
            %   The Run Fails: The Library Puts The Slot Back To The Previous Run (Config, Forcing, LCS Seed Matching The
            %   Results On Disk; A Restore Failure Is Reported With The Run Error): out.status 'failed', Error Message Queued.
            %   The Results Are Saved But The Project File Is Not: A Warning, Not A Failed Run. out.status 'done'.
            % out.status_text: How The Forcing Was Obtained ('status' View). Multi-Line Stage 1: The Confirmed Stage 2 Bundles
            % (plan.cascade) Deleted Once The Results Are Saved; Files Not Deleted Reported In The Warning
            if nargin < 3
                progress_fcn = @(~, ~) [];
            end
            out = struct('status', 'done', 'status_text', '');
            [pse_name, alt_name] = ctrl.active_names();
            try
                settings = chessRunPlanner.run_settings(ctrl);
                config = chessRunPlanner.run_config(ctrl);
                % Progress Bar Labels Of The Library Steps 0-6 (Cache, Build, Uncertainty, Adjust, Save, Responses, Recorded)
                step_str = 'Creating Replicates';
                unc_str = 'Applying Uncertainty';
                adj_str = 'Adjust Project Forcing';
                if ~isempty(config.multiline) % Multi-Line Stage 2: Stage 1's Forcing, Transmitted
                    step_str = 'Transmitting Stage 1 Waves';
                    unc_str = 'Uncertainty From Stage 1';
                    adj_str = 'Adjustments From Stage 1';
                elseif config.workflow == 3
                    step_str = 'Creating Life Cycles';
                elseif config.workflow == 2 % Deterministic: Storms As Recorded, No Uncertainty
                    step_str = 'Formatting Storms';
                    unc_str = 'No Uncertainty (Deterministic)';
                end
                bar_msg = {'Loading Project Forcing', step_str, unc_str, adj_str, 'Saving Project Forcing',...
                    'Computing Project Responses', 'Saving Outputs'};
                % The Run Question Decides: "Coldstart" Builds Everything Again, "Hotstart" Lets The Library Reuse What The
                % Saved Run Still Covers (Same Rules As saved_run_hotstart_plan)
                hotstart = 'auto';
                if strcmp(plan.level, 'cold')
                    hotstart = 'cold';
                end
                progress_fcn(1/5, step_str);
                [~, info] = ctrl.project.run(pse_name, alt_name, settings, hotstart,...
                    @(step, msg) chessRunPlanner.run_progress(progress_fcn, step, msg, bar_msg));
            catch ME
                ctrl.message('error', 'Error Message', ['CHESS run failed: ' ME.message]);
                out.status = 'failed';
                return
            end
            % Multi-Line Stage 1 Run Done: The Confirmed Stage 2 Bundles Deleted (Files And Registry Rows)
            failed = cell(0, 1);
            if ~isempty(plan.cascade)
                failed = chessRunPlanner.delete_sim_rows(ctrl, ctrl.project, pse_name, plan.cascade);
            end
            update_msg = '';
            if ~info.project_saved
                update_msg = sprintf('%s were saved, but the project file could not be written. The project is not saved: save it before closing.', plan.res_str);
            end
            ctrl.mark('tree'); % New Simulation Bundle Node
            progress_fcn(1, 'Done');
            % Status: How The Forcing Was Obtained
            switch info.hotstart_level
                case 'full'
                    out.status_text = 'Hotstart (full): reused cached forcing.';
                case 'reuse_sampling'
                    if info.config.workflow == 3
                        out.status_text = ['Hotstart: same life cycles, forcing rebuilt (' info.hotstart_reason ').'];
                    else
                        out.status_text = ['Hotstart: forcing rebuilt (' info.hotstart_reason ').'];
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
            config = chessRunPlanner.run_config(ctrl);
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
            % Run With A Saved Simulation: Library Hotstart Level (chess.Hotstart.plan) Of The Current Inputs (config, Not For Run)
            % Against The Saved Run (old). GUI Inputs The Library Lists Do Not Cover (DB Uncertainties, Region) Count As
            % 'resample'. plan.available: Hotstart Offered (Not 'resample', Needed Cached Forcing/Seed Present). plan.text:
            % Question Line
            plan = struct('level', 'resample', 'reason', '', 'available', false, 'text', '', 'old', old);
            if ~isfield(old, 'forcing_stamp') % Complete Forcing Of The Saved Run (Library chess.Model.build_forcing)
                plan.text = 'Hotstart not available: the saved run has no complete forcing.';
                return
            end
            is_lcs = config.workflow == 3 && isempty(config.multiline); % Multi-Line Stage 2 Samples Nothing (Stage 1's Life Cycles)
            why_not = '';
            gui_deps = {'region', 'chs_swl_u_a', 'chs_swl_u_r', 'chs_hm0_u_a', 'chs_hm0_u_r'};
            [changed_dep, plan.reason] = chess.Hotstart.any_field_changed(config, old, gui_deps);
            if ~changed_dep
                saved_run = chess.Hotstart(config, old);
                [plan.level, plan.reason, why_not] = saved_run.plan(is_lcs);
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
            % LCS Convergence Question, Replacing The Library's Command-Window Prompt. Same Rule As chess.Model.LifeCycle
            % (chess.Model.LifeCycle.reference_reuse): Effective Mode 0, Storm Types Not Reused From The Reference Case. Not Converged:
            % "Set mcs_nLC To <nLC_req> And Run" | "Run Anyway" | "Cancel". q Empty: Nothing To Ask
            q = [];
            n_req = [];
            config = chessRunPlanner.run_config(ctrl);
            if ~isempty(ctrl.lcsCheck) && isequaln(ctrl.lcsCheck.config, config) % plan_run Passes Of The Same Run Start
                q = ctrl.lcsCheck.q;
                n_req = ctrl.lcsCheck.n_req;
                return
            end
            if config.workflow ~= 3 || ~isempty(config.multiline) % Multi-Line Stage 2: Stage 1's Life Cycles, Nothing Sampled
                return
            end
            reuse = chess.Model.LifeCycle.reference_reuse(config);
            if isempty(reuse.check_types)
                return
            end
            checks = chess.Model.LifeCycle.convergence_checks(config, prob_mass, reuse.check_types, true);
            checks = checks(~[checks.converged]);
            if isempty(checks)
                return
            end
            n_txt = @(n) chess.Visualization.aux_methods.tern(isinf(n), sprintf('> %s', regexprep(num2str(checks(1).nLC_cap), '(\d)(?=(\d{3})+$)', '$1,')), sprintf('%d', n));
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
            % chess.Project.run progress_function: Steps 0-6 (Cache, Build, Uncertainty, Adjust, Save, Responses, Recorded) ->
            % Bar Value And labels{step + 1}. The Library Message Still Goes To The Command Window
            disp(message);
            bar_val = [1 1 2 3 3.5 4 4.99]/5;
            progress_fcn(bar_val(step + 1), labels{step + 1});
        end
    end
end

classdef chessResults
    % CHESS GUI Results Data (No State, No App Designer References): Loads A Saved Simulation's Results Into
    % controller.results (load_results), Loads Forcing / Storm DB Data On Demand (Cached On The Controller), Lists What The
    % Results Tab Offers: Plot Catalog, Field / Storm ID Dropdown Items, Annual Bin Edges, RB vs Frequency-Based (FB) Curves
    % And Table, And Draws One Results Plot Into The Axes / Figure / Grid Handles The Caller Passes In (draw_results_plot).
    %   Static Helpers: Every Public Method Takes The chessController Handle (ctrl) First; All State (results, The storm
    %   Cache, The FB Curve Cache results.frequency_based_curves) Stays On The Controller. Callers Use The Controller's
    %   One-Line Facades Of The Same Name (controller.load_results(...)), Which Forward Here.

    methods (Static)
        function [loaded, msg] = load_results(ctrl)
            % Results Of The Active Alternative / Workflow / Run Tab Storm DB (Saved Run's Resp, config, structure; Project
            % Forcing For DET / LCS Plots) Into results, Only Once The Key Is Resolved (sync_saved / use_key) And Not Declined.
            % msg: Status Text (status Applied): The Comparison With The Current Inputs (results_status) When Loaded, Else Why Not
            ctrl.results = [];
            loaded = false;
            msg = '';
            if ~ctrl.has_active_alt() || isempty(ctrl.selection.db) || ~isequal(ctrl.sim_key(), ctrl.simKey)
                msg = ctrl.status(msg);
                return
            end
            if ~isempty(ctrl.declinedKey) && isequal(ctrl.sim_key(), ctrl.declinedKey)
                msg = ctrl.status('Current simulation already exists. Load declined.');
                return
            end
            [config_file, ~, ~, ~, out_files] = ctrl.config_path();
            [has_sim, label] = ctrl.saved_sim();
            if ~has_sim
                msg = ctrl.status(['No saved simulation for ' label '.']);
                return
            end
            S = load(out_files.resp_data, 'Resp');
            % Run's Structure (Saved By The Library call_project_response, With The Run's Resolved Offshore Elevation), Not The Current PSE
            C = load(config_file, 'config', 'structure');
            C.config = ctrl.localize_saved_config(C.config);
            state = struct('Resp', S.Resp, 'config', C.config, 'structure', C.structure,...
                'project_forcing', [], 'prob_mass', [], 'out_files', out_files,...
                'dbObj', ctrl.project.get_project_field('stormDB_list', ctrl.selection.db, '', 'db'),...
                'frequency_based_curves', containers.Map());
            if any(C.config.workflow == [2 3]) && isfile(out_files.project_forcing) % DET (Forcing Not Copied Into Resp) & LCS Plots Need Project Forcing
                P = load(out_files.project_forcing, 'project_forcing');
                state.project_forcing = P.project_forcing;
            end
            ctrl.results = state;
            loaded = true;
            msg = ctrl.status(ctrl.results_status());
        end

        function project_forcing = results_project_forcing(ctrl)
            % Saved Project Forcing Of The Loaded Results (Loaded Once, Kept In results; [] When The File Is Missing). The Storm
            % Event Viewer And Response Table Read It Alone: No Storm DB File Needed
            if isempty(ctrl.results.project_forcing) && isfile(ctrl.results.out_files.project_forcing)
                P = load(ctrl.results.out_files.project_forcing, 'project_forcing');
                ctrl.results.project_forcing = P.project_forcing;
            end
            project_forcing = ctrl.results.project_forcing;
        end

        function [project_forcing, dsw] = results_forcing(ctrl)
            % Project Forcing & Storm DB Probability Masses For The Loaded Results (Loaded Once, Kept In results)
            chessResults.results_project_forcing(ctrl);
            if isempty(ctrl.results.prob_mass)
                S = load(ctrl.results.dbObj.output_paths.storm_db, 'prob_mass');
                ctrl.results.prob_mass = S.prob_mass;
            end
            project_forcing = ctrl.results.project_forcing;
            dsw = ctrl.results.prob_mass;
        end

        function storm = load_storm(ctrl, dbObj)
            % Cached Load Of Storm DB "storm" Variable
            key = dbObj.output_paths.storm_db;
            if ~isKey(ctrl.storm, key)
                S = load(key, 'storm');
                ctrl.storm(key) = S.storm;
            end
            storm = ctrl.storm(key);
        end

        function chs_data = load_chs_data(ctrl, dbObj)
            % Cached Load Of Raw CHS_Data (Storm DB "_raw_files.mat"); [] If Unavailable
            chs_data = [];
            if ~isfield(dbObj.output_paths, 'chs_data') || ~isfile(dbObj.output_paths.chs_data)
                return
            end
            key = dbObj.output_paths.chs_data;
            if ~isKey(ctrl.storm, key)
                S = load(key, 'CHS_Data');
                ctrl.storm(key) = S.CHS_Data;
            end
            chs_data = ctrl.storm(key);
        end

        function cat = plot_catalog(ctrl)
            % Results Plot Types -> CHESS-Library Plot Methods (One Row Per Plot), Filtered For The Loaded Results.
            %   key | label | workflows | data types | needs S (armor damage) | rubble mound only | multi-panel (pop-out only) | plot options
            rows = {
                'hc',          'Hazard Curve',                    [1 4],   {'Peaks','Timeseries'}, false, false, false, {}
                'fb_compare',  'Hazard Curve: RB vs Frequency-Based', 1,   {'Peaks','Timeseries'}, false, false, false, {}
                'det_scatter', 'Response vs Forcing',             2,       {'Peaks','Timeseries'}, false, false, false, {'c_field'}
                'det_table',   'Response Table',                  [1 2 3 4], {'Peaks','Timeseries'}, false, false, true,  {}
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
            state = ctrl.results;
            if isempty(state)
                return
            end
            keep = false(size(cat));
            for cc = 1:numel(cat)
                cat(cc).data_types = chessResults.results_data_types(ctrl, cat(cc));
                keep(cc) = ismember(state.config.workflow, cat(cc).workflows) && ~isempty(cat(cc).data_types) &&...
                    (~cat(cc).rubble_mound || state.structure.struc_type == 3) &&...
                    (~strcmp(cat(cc).key, 'det_compare') || isfield(state.Resp, 'Timeseries')) &&... % Needs Peaks & Timeseries
                    (~strcmp(cat(cc).key, 'fb_compare') || chessResults.results_have_forcing_curves(ctrl)); % Needs The Forcing Hazard Curves
            end
            cat = cat(keep);
        end

        function [lbl, items] = field_items(ctrl, key, data, data_type)
            % Field To Plot Items Per Plot Type (Library Method Field Lists). data_type ('Peaks' / 'Timeseries', Optional):
            % Registry Responses Not Computed For The Data Type (Q_vol* For Peaks) Are Not Offered
            if nargin < 4
                data_type = '';
            end
            lbl = 'Field To Plot:';
            s_fields = {};
            if isstruct(data) && isfield(data, 'S')
                s_fields = fieldnames(data(1).S)';
            end
            series_names = response_registry('output', 'names', 'damage_summary', 'series');
            s_series = intersect(series_names, s_fields, 'stable');
            switch key
                case 'hc'
                    items = {data.var};
                case 'fb_compare' % Registry Responses With An FB Curve That This Entry Holds (Needs The Forcing Curves)
                    items = {};
                    if chessResults.has_forcing_curves(data)
                        items = intersect(chessResults.frequency_based_responses(), {data.var}, 'stable');
                    end
                case {'det_scatter', 'det_compare'} % Deterministic: Forcing & Responses (Y Axis / Compared Field)
                    if strcmp(key, 'det_scatter')
                        lbl = 'Y Axis:';
                    end
                    items = chessResults.det_fields(ctrl, data);
                case 'det_table' % Columns Are Picked In The Table Pop-Out
                    items = {};
                case 'event' % Responses The Event Viewer Draws For This Structure Type (Hazard Curve Entries, Saved Responses, Saved S)
                    if isfield(data, 'var')
                        run_fields = {data.var};
                    else
                        run_fields = [fieldnames(data)', s_fields];
                    end
                    items = intersect(chessResults.response_list(ctrl, 'event', data_type), run_fields, 'stable');
                case 'annual'
                    items = intersect(chessResults.response_list(ctrl, 'annual', data_type), [fieldnames(data)', s_fields], 'stable');
                case 'armor'
                    items = [intersect(response_registry('output', 'names', 'damage_summary', 'yearly_mean_max'), s_fields, 'stable'), s_series];
                case {'damaging', 'dashboard'}
                    items = s_series;
                case 'final'
                    items = intersect(response_registry('output', 'names', 'damage_summary', 'series', 'with_repairs', false), s_fields, 'stable');
                case 'submergence' % Field To Plot Relabeled As An Option
                    lbl = 'Normalize:';
                    items = {'percent', 'count'};
                otherwise % Event Sampling: No Field
                    items = {};
            end
            items = chessResults.keep_fields_for_data_type(items, data_type);
        end

        function [lbl, items, on] = aux_items(ctrl, key, data, ds_query, field)
            % Storm ID Dropdown Per Plot Type: Life Cycle Or A Plot Option (field: Field To Plot Selected). The Storm Event Viewer
            % And Response Table Select Their Storm In The Figure: No Item Here
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
                case 'det_scatter' % X Axis (Color: Right-Click Plot Options); Registry Responses Not Computed For The Data Type Dropped
                    lbl = 'X Axis:';
                    items = chessResults.det_fields(ctrl, data);
                    items = chessResults.keep_fields_for_data_type(items, ds_query.data_type);
                    on = true;
                case 'annual'
                    lbl = 'Normalize:';
                    items = {'percent', 'count'};
                    on = true;
                case 'armor' % Life Cycle Selection Applies To S_* Damage Series Only
                    lbl = 'Life Cycle:';
                    items = {'All'};
                    if ismember(field, response_registry('output', 'names', 'damage_summary', 'series')) && isfield(data, 'S') && isfield(data.S, field)
                        items = lc_items(numel(data.S.(field)));
                        on = true;
                    end
                case 'sampling'
                    lbl = 'Life Cycle:';
                    items = lc_items(numel(aux_methods.pull_data(ds_query, ctrl.results.project_forcing)));
                    on = true;
                case 'submergence'
                    lbl = 'X Scale:';
                    items = {'Linear', 'Log'};
                    on = true;
            end
        end

        function [edges, labels] = bin_edges(ctrl, chessPlot, ds_query, field, edges)
            % Annual Distribution Bin Edges (Plot Option Or Library Estimate) & Results Table Column Labels.
            % No Finite Response Values: No Edges, No Labels (The Library Plot Shows "No finite response values to plot")
            if isempty(edges)
                data = aux_methods.pull_data(ds_query, ctrl.results.Resp);
                if isfield(data, field)
                    resp_vector = data.(field);
                else
                    resp_vector = data.S.(field);
                end
                if ~any(cellfun(@(x) any(isfinite(x(:))), resp_vector))
                    labels = {};
                    return
                end
                [~, ~, ~, ~, ~, ~, x_log] = response_library_headers(ctrl.results.config, field);
                edges = chessPlot.generate_bin_guess(resp_vector, 5, x_log);
            end
            edges = edges(:)';
            % Library Binning Uses [-Inf, edges, edges(end)+1, Inf]
            final_edges = [-Inf, edges, edges(end)+1, Inf];
            labels = arrayfun(@(a, b) sprintf('%g to %g', a, b), final_edges(1:end-1), final_edges(2:end), 'un', false);
            labels{1} = sprintf('< %g', edges(1));
            labels{end} = sprintf('>= %g', final_edges(end-1));
        end

        function tf = results_have_forcing_curves(ctrl)
            % Any Dataset / Match Type / Storm Type Of The Loaded Resp Holds All PROS Forcing Hazard Curves (pros_forcing_curves.m)
            tf = false;
            Resp = ctrl.results.Resp;
            for dt = fieldnames(Resp)'
                for mt = fieldnames(Resp.(dt{1}))'
                    for st = fieldnames(Resp.(dt{1}).(mt{1}))'
                        if chessResults.has_forcing_curves(Resp.(dt{1}).(mt{1}).(st{1}))
                            tf = true;
                            return
                        end
                    end
                end
            end
        end

        function fb_curve = frequency_based_curve(ctrl, ds_query, response_name)
            % Frequency-Based (FB) Hazard Curve Of One Response Of The Loaded PROS-RB Results (frequency_based_hazard_curve.m,
            % Run's Saved config And structure), Computed Once Per Results Load ([] If The Response Was Not Produced)
            key = strjoin({ds_query.data_type, ds_query.match_type, ds_query.storm_type, response_name}, '|');
            curves = ctrl.results.frequency_based_curves;
            if ~isKey(curves, key)
                curves(key) = frequency_based_hazard_curve(ctrl.results.config, ctrl.results.structure,...
                    aux_methods.pull_data(ds_query, ctrl.results.Resp), ds_query.storm_type, response_name);
            end
            fb_curve = curves(key);
        end

        function [column_names, data] = frequency_based_table(ctrl, ds_query, response_name, fb_curve)
            % Results Table Of The RB vs FB Comparison: AEF/AEP | RB Best Estimate And CLs | FB Best Estimate And CLs, One Row
            % Per Table AEF/AEP Of Either Curve (NaN Where A Curve Has No Value). fb_curve Omitted -> frequency_based_curve
            if nargin < 4
                fb_curve = chessResults.frequency_based_curve(ctrl, ds_query, response_name);
            end
            hazard_curves = aux_methods.pull_data(ds_query, ctrl.results.Resp);
            rb_curve = hazard_curves(strcmp({hazard_curves.var}, response_name));
            if ctrl.results.config.pros_use_aep == 1
                x_label = 'AEP';
            else
                x_label = 'AEF [1/yr]';
            end
            x_table = rb_curve.x_table(:, 1);
            if ~isempty(fb_curve)
                x_table = union(x_table, fb_curve.x_table(:, 1));
                if rb_curve.x_table(1, 1) > rb_curve.x_table(end, 1)
                    x_table = flipud(x_table);
                end
            end
            [rb_names, rb_values] = curve_columns(rb_curve, 'RB', x_table);
            if isempty(fb_curve)
                fb_curve = struct('CL', rb_curve.CL, 'x_table', zeros(0, 1), 'y_table', zeros(0, numel(rb_curve.CL)));
            end
            [fb_names, fb_values] = curve_columns(fb_curve, 'FB', x_table);
            column_names = [{x_label}, rb_names, fb_names];
            data = [x_table, rb_values, fb_values];
        end

        function [results_table, plot_error] = draw_results_plot(ctrl, row, target, request)
            % Draw One Results Plot Type (plot_catalog Row) Of The Loaded Results With Its CHESS-Library Plot Method And Build
            % Its Results Table. No App Widgets: The Caller Reads The Selection And Passes Plain Values And Handles.
            %   target: Axes, Classic Figure (Single-Panel Plots Get New Axes In It), uigridlayout (Multi-Panel Plots) Or []
            %   request: ds_query | field (Field To Plot) | aux (Storm ID Dropdown: Life Cycle, Add Events, X Axis, Normalize,
            %     X Scale) | options (Plot Options: bin_edges, cb_lim, grid_on, cb_log, c_field) | base_font |
            %     in_results_tab (true: Fill results_table, Storm Event Viewer In target; false: Pop-Out, No Table) |
            %     busy_parent (uifigure Of The FB Curve Progress Dialog; [] = No Dialog) | event_selection, event_on_change
            %     (storm_event_viewer sel / on_change) | open_viewer_popout (Function Handle, No Arguments: Response Table,
            %     And The Storm Event Viewer Outside The Tab)
            %   results_table: struct(column_names, data) ({} / {} When The Plot Has No Table Or in_results_tab Is false)
            %   plot_error: MException Of The Plot Method ([] If None); Data Loading Errors Are Thrown
            results_table = struct('column_names', {{}}, 'data', {{}});
            plot_error = [];
            state = ctrl.results;
            ds_query = request.ds_query;
            field = request.field;
            aux = request.aux;
            opts = request.options;
            base_fnt = request.base_font;
            % Single-Panel Plots Need Axes, Multi-Panel Plots Take The Figure
            if ~row.multi_panel && isa(target, 'matlab.ui.Figure')
                target = axes('Parent', target);
            end
            ax = target;
            lc_index = str2double(aux); % Life Cycle ('All' -> [])
            if isnan(lc_index)
                lc_index = [];
            end
            % Plot Data Loaded On Demand
            config = state.config;
            storm = [];
            dsw = [];
            add_events = 0; % Hazard Curve Events Overlay Mode: 0 Off, 1 Run Sample, 2 Storm Values
            if strcmp(row.key, 'hc') && ~strcmp(ds_query.storm_type, 'CC') % CC: No Overlays
                add_events = max([0, find(strcmp(aux, {'Run Sample', 'Storm Values'}), 1)]);
            end
            if any(strcmp(row.key, {'event', 'scheme'}))
                config.sp_ID = CHSStormDBImportUI.get_savepoint_id(state.dbObj); % Title (GUI Run Configs Leave sp_ID Empty)
            end
            if strcmp(row.key, 'scheme')
                storm = chessResults.load_storm(ctrl, state.dbObj);
            end
            project_forcing = state.project_forcing;
            if any(strcmp(row.key, {'event', 'det_table'})) % Saved Forcing Only (No Storm DB)
                project_forcing = chessResults.results_project_forcing(ctrl);
            elseif add_events > 0 || strcmp(row.key, 'scheme') % Events Overlay / Sampling Scheme Need Project Forcing + TC Probability Masses
                [project_forcing, dsw] = chessResults.results_forcing(ctrl);
            end
            chessPlot = CHESSPlots(config, state.Resp, storm, project_forcing, dsw, state.structure, base_fnt, ctrl.project.unitsys);
            try
                switch row.key
                    case 'hc' % PROS Hazard Curve (+ Table)
                        chessPlot.hc_plot(ax, ds_query, field, add_events);
                        if request.in_results_tab
                            data = aux_methods.pull_data(ds_query, state.Resp);
                            data = data(strcmp({data.var}, field));
                            cls = arrayfun(@(x) ['CL' num2str(x)], data.CL, 'un', false);
                            cls(data.CL == 50) = {'BE'};
                            if state.config.pros_use_aep == 1
                                x_lbl = 'AEP';
                            else
                                x_lbl = 'AEF [1/yr]';
                            end
                            results_table.column_names = [{x_lbl}, cls];
                            results_table.data = [data.x_table, data.y_table];
                        end
                    case 'fb_compare' % PROS-RB Hazard Curve vs Its Frequency-Based (FB) Curve (+ Table)
                        if strcmp(field, '-') % No Response With An FB Curve For This Storm Type
                            ax = aux_methods.initiate_axes(ax, '', '', '', base_fnt);
                            aux_methods.display_no_data(ax, base_fnt, 'No response with a frequency-based curve for this storm type');
                        else
                            % FB Monte Carlo Runs Once Per Response (Cached On The Controller Until The Next Results Load)
                            busy_dialog = [];
                            if ~isempty(request.busy_parent)
                                busy_dialog = uiprogressdlg(request.busy_parent, 'Title', 'Frequency-Based Curve', ...
                                    'Message', ['Computing the frequency-based curve of ' field ' ...'], 'Indeterminate', 'on');
                            end
                            try
                                fb_curve = chessResults.frequency_based_curve(ctrl, ds_query, field);
                            catch err
                                if ~isempty(busy_dialog)
                                    delete(busy_dialog);
                                end
                                rethrow(err);
                            end
                            if ~isempty(busy_dialog)
                                delete(busy_dialog);
                            end
                            chessPlot.frequency_based_comparison_plot(ax, ds_query, field, fb_curve);
                            if request.in_results_tab
                                [results_table.column_names, results_table.data] = chessResults.frequency_based_table(ctrl, ds_query, field, fb_curve);
                            end
                        end
                    case 'det_scatter' % Deterministic: Response vs Forcing (X: Storm ID Dropdown, Y: Field, Color: Plot Options)
                        fields = chessResults.det_fields(ctrl, aux_methods.pull_data(ds_query, state.Resp));
                        c_field = opts.c_field;
                        if isempty(c_field) || ~any(strcmp(fields, c_field))
                            c_field = fields{max([1, find(strcmp(fields, 'Hm0_toe'), 1)])};
                        end
                        chessPlot.response_vs_forcing_plot(ax, ds_query, aux, field, c_field);
                        if request.in_results_tab % Table: The Plotted Values (Per Storm; Timeseries -> Storm Maxima)
                            mx = aux_methods.pull_data(ds_query, state.Resp).Max;
                            results_table.column_names = {'Storm ID', aux, field, c_field};
                            results_table.data = [mx.storm_id(:), mx.(aux)(:), mx.(field)(:), mx.(c_field)(:)];
                        end
                    case 'det_table' % Response Table Pop-Out (Caller's Window, Replaces The Previous One)
                        request.open_viewer_popout();
                    case 'det_compare' % Deterministic: Peaks Value vs Timeseries Peak (Same Storms, 1:1 Line)
                        chessPlot.peaks_vs_timeseries_plot(ax, ds_query, field);
                        if request.in_results_tab
                            pk = aux_methods.pull_data(ds_query, state.Resp).Max;
                            q_ts = ds_query;
                            q_ts.data_type = 'Timeseries';
                            ts = aux_methods.pull_data(q_ts, state.Resp).Max;
                            [ids, ia, ib] = intersect(pk.storm_id, ts.storm_id);
                            results_table.column_names = {'Storm ID', ['Peaks ' field], ['Timeseries ' field]};
                            results_table.data = [ids(:), pk.(field)(ia), ts.(field)(ib)];
                        end
                    case 'event' % Storm Event Viewer: Saved Results, Selectors In The Figure (Outside The Tab: Caller's Pop-Out)
                        if request.in_results_tab
                            chessPlot.storm_event_viewer(target, ds_query, field, request.event_selection, 0, request.event_on_change);
                        else
                            request.open_viewer_popout();
                        end
                    case 'annual' % LCS Annual Response Distribution (+ Table Of Binned Values Per Sim Year)
                        [edges, labels] = chessResults.bin_edges(ctrl, chessPlot, ds_query, field, opts.bin_edges);
                        [~, bin_data] = chessPlot.annual_response_distribution(ax, ds_query, field, edges, string(aux),...
                            opts.cb_lim, opts.grid_on, opts.cb_log);
                        if request.in_results_tab && isempty(bin_data) % No Finite Values: Library "No Data" Axes, Empty Table
                            results_table.column_names = {'Sim Year'};
                            results_table.data = zeros(0, 1);
                        elseif request.in_results_tab
                            results_table.column_names = [{'Sim Year'}, labels];
                            results_table.data = [(1:size(bin_data, 1))', bin_data(:, 1:numel(labels))];
                        end
                    case 'armor' % Slope Armor Damage (S_* Fields: All Or One Life Cycle)
                        hold(ax, 'on');
                        chessPlot.slope_armor_damage_plot(ax, ds_query, field, lc_index);
                    case 'sampling' % Event Sampling Distribution (All Or One Life Cycle)
                        chessPlot.event_sampling_distribution(ax, ds_query, lc_index);
                    case 'damaging'
                        chessPlot.plot_mound_damaging_instances_distribution(ax, ds_query, field);
                    case 'submergence' % Field To Plot -> Normalize, Storm ID -> X Scale
                        chessPlot.plot_pse_submergance_distribution(ax, ds_query, strcmp(aux, 'Log'), strcmp(field, 'count'),...
                            opts.cb_log, opts.cb_lim);
                    case 'final'
                        chessPlot.plot_mound_final_damage_state(ax, ds_query, field);
                    case 'dashboard' % Mound Damage Dashboard (Pop-Out)
                        chessPlot.mound_damage_dashboard(target, ds_query, field, opts.bin_edges, opts.cb_lim);
                    case 'scheme' % LCS Storm Sampling Diagnostics (Pop-Out)
                        chessPlot.sampling_scheme_dashboard(target, ds_query);
                end
            catch me
                plot_error = me;
            end
        end

        function fields = det_fields(~, data)
            % Deterministic Results: Plottable Fields (Forcing First, Then Responses), Same Order As det_methods.available_fields
            forcing = response_registry('output', 'names', 'kind', 'forcing');
            data_names = setdiff(fieldnames(data.Max), {'storm_id', 'time'}, 'stable')';
            fields = [forcing(ismember(forcing, data_names)), setdiff(data_names, forcing, 'stable')];
        end
    end

    %% PRIVATE HELPERS
    methods (Static, Access = private)
        function dts = results_data_types(ctrl, row)
            % Data Types In The Loaded Results That A Plot Type Supports
            Resp = ctrl.results.Resp;
            dts = intersect(row.data_types, fieldnames(Resp), 'stable');
            if row.needs_s % Armor Damage Plots: Results Must Include Damage (S)
                has_s = cellfun(@(dt) any(structfun(@(mt) any(structfun(@(st) isstruct(st) && isfield(st, 'S'), mt)), Resp.(dt))), dts);
                dts = dts(has_s);
            end
        end

        function fields = response_list(ctrl, list_name, data_type)
            % Response Names Accepted By Library Plot Methods (Registry Per-Event Responses)
            %   'annual': lcs_methods.annual_response_distribution | 'event': CHESSPlotsBase.storm_event_viewer (Per Structure Type)
            %   data_type 'Peaks': Registry Responses Not Computed For Peaks Dropped (Q_vol*)
            switch list_name
                case 'annual'
                    fields = response_registry('output', 'names', 'per_event', true);
                case 'event'
                    fields = response_registry('output', 'names', 'per_event', true, 'structure_type', ctrl.results.structure.struc_type);
            end
            fields = chessResults.keep_fields_for_data_type(fields, data_type);
        end

        function names = frequency_based_responses()
            % Responses With A Frequency-Based Curve: PROS-RB Fitted Registry Responses Computed For Peaks (Not Q_vol*)
            names = response_registry('output', 'names', 'fitted_by_pros_rb', true, 'data_type', 'Peaks');
        end

        function tf = has_forcing_curves(hazard_curves)
            % Saved Hazard Curve Entries Hold All PROS Forcing Hazard Curves (pros_forcing_curves.m)
            tf = isstruct(hazard_curves) && isfield(hazard_curves, 'var') && all(ismember(pros_forcing_curves(), {hazard_curves.var}));
        end

        function fields = keep_fields_for_data_type(fields, data_type)
            % Drop Registry Responses Not Computed For The Data Type; Unregistered Names And An Empty Data Type Are Kept
            if ~isempty(data_type)
                registered = response_registry('output', 'names');
                fields = fields(~ismember(fields, registered) | ismember(fields, response_registry('output', 'names', 'data_type', data_type)));
            end
        end
    end
end

function [names, values] = curve_columns(curve, method_tag, x_table)
% frequency_based_table Columns Of One Curve: '<tag> CL<cl>' Names ('<tag> BE' For CL 50) And Its y_table Values On
% x_table (NaN Where The Curve Has No Value)
names = arrayfun(@(cl) sprintf('%s CL%g', method_tag, cl), curve.CL(:)', 'un', false);
names(curve.CL == 50) = {[method_tag ' BE']};
values = NaN(numel(x_table), numel(curve.CL));
[found, row] = ismember(x_table, curve.x_table(:, 1));
values(found, :) = curve.y_table(row(found), :);
end

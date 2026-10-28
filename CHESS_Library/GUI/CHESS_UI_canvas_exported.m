classdef CHESS_UI_canvas_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        ProjectManagementMenu         matlab.ui.container.Menu
        CreateNewProjectMenu          matlab.ui.container.Menu
        ImportExportProjectMenu       matlab.ui.container.Menu
        ImportProjectMenu             matlab.ui.container.Menu
        ExportProjectMenu             matlab.ui.container.Menu
        AddProjectElementMenu         matlab.ui.container.Menu
        PSEMenu                       matlab.ui.container.Menu
        LeveeMenu                     matlab.ui.container.Menu
        RubbleMoundMenu               matlab.ui.container.Menu
        FloodwallMenu                 matlab.ui.container.Menu
        LowCrestedBreakwaterMenu      matlab.ui.container.Menu
        MultilineTransectMenu         matlab.ui.container.Menu
        AlternativeMenu               matlab.ui.container.Menu
        TidesMenu                     matlab.ui.container.Menu
        RemoveProjectElementMenu      matlab.ui.container.Menu
        RemovePSEMenu                 matlab.ui.container.Menu
        RemoveAlternativeMenu         matlab.ui.container.Menu
        RemoveTidesMenu               matlab.ui.container.Menu
        RemoveAlternativeSimulationMenu  matlab.ui.container.Menu
        StormDatabaseManagementMenu   matlab.ui.container.Menu
        AddStormDatabaseMenu          matlab.ui.container.Menu
        ImportCHSStudyHDF5Menu        matlab.ui.container.Menu
        RemoveStormDatabaseMenu       matlab.ui.container.Menu
        GridLayout                    matlab.ui.container.GridLayout
        ParentPanel                   matlab.ui.container.Panel
        MasterGrid                    matlab.ui.container.GridLayout
        TabGroup                      matlab.ui.container.TabGroup
        PSEViewerTab                  matlab.ui.container.Tab
        PSEViewerGrid                 matlab.ui.container.GridLayout
        PSETable                      matlab.ui.control.Table
        PSEButtonGrid                 matlab.ui.container.GridLayout
        ExtrudeFigureButton           matlab.ui.control.Button
        ExtrudeTableButton            matlab.ui.control.Button
        PSEAxes                       matlab.ui.control.UIAxes
        StormDBViewerTab              matlab.ui.container.Tab
        StormDBViewerGrid             matlab.ui.container.GridLayout
        StormDBViewerSplitGrid        matlab.ui.container.GridLayout
        StormDBTable                  matlab.ui.control.Table
        Panel                         matlab.ui.container.Panel
        StormDBViewerNavigationPanelGrid  matlab.ui.container.GridLayout
        StormDBDropDown               matlab.ui.control.DropDown
        StormDBDropDownLabel          matlab.ui.control.Label
        StormTypeDropDown             matlab.ui.control.DropDown
        StormTypeDropDownLabel        matlab.ui.control.Label
        DataTypeDropDown              matlab.ui.control.DropDown
        DataTypeDropDownLabel         matlab.ui.control.Label
        MatchTypeDropDown             matlab.ui.control.DropDown
        MatchTypeDropDownLabel        matlab.ui.control.Label
        FieldToPlotDropDown           matlab.ui.control.DropDown
        FieldToPlotLabel              matlab.ui.control.Label
        StormIDDropDown               matlab.ui.control.DropDown
        StormIDDropDownLabel          matlab.ui.control.Label
        StormDBViewerButtonGrid       matlab.ui.container.GridLayout
        ExtrudeFigureButton_2         matlab.ui.control.Button
        ExtrudeTableButton_2          matlab.ui.control.Button
        StormDBAxes                   matlab.ui.control.UIAxes
        CHESSRunTab                   matlab.ui.container.Tab
        RunViewerGrid                 matlab.ui.container.GridLayout
        GridLayout3_7                 matlab.ui.container.GridLayout
        simStatusBar                  matlab.ui.control.TextArea
        RunSimulationButton           matlab.ui.control.Button
        GridLayout3_6                 matlab.ui.container.GridLayout
        DataTypesTree                 matlab.ui.container.CheckBoxTree
        ResponsesTree                 matlab.ui.container.CheckBoxTree
        GridLayout3_5                 matlab.ui.container.GridLayout
        DataTypesToProcessLabel       matlab.ui.control.Label
        PSEResponsesLabel             matlab.ui.control.Label
        WorkflowInputsTable           matlab.ui.control.Table
        GridLayout3_4                 matlab.ui.container.GridLayout
        WorkflowDropDown              matlab.ui.control.DropDown
        DefineCHESSWorkflowLabel      matlab.ui.control.Label
        GridLayout3_3                 matlab.ui.container.GridLayout
        TidesFileDropDown             matlab.ui.control.DropDown
        TideFileDropDownLabel         matlab.ui.control.Label
        GridLayout3_2                 matlab.ui.container.GridLayout
        SeaLevelChangeEditField       matlab.ui.control.NumericEditField
        SeaLevelChangeEditFieldLabel  matlab.ui.control.Label
        StormTypeDropDown_2           matlab.ui.control.DropDown
        StormTypeDropDown_2Label_2    matlab.ui.control.Label
        GridLayout3                   matlab.ui.container.GridLayout
        StormDBDropDown_run           matlab.ui.control.DropDown
        StormDBDropDown_2Label        matlab.ui.control.Label
        ApplyDepthLimitationCheckBox  matlab.ui.control.CheckBox
        RunSimulationLabel            matlab.ui.control.Label
        DefineProjectResponsesDataTypesToComputeLabel  matlab.ui.control.Label
        DefineProjectForcingLabel_2   matlab.ui.control.Label
        ResultsViewerTab              matlab.ui.container.Tab
        StormDBViewerGrid_2           matlab.ui.container.GridLayout
        StormDBViewerSplitGrid_2      matlab.ui.container.GridLayout
        PSETable_3                    matlab.ui.control.Table
        Panel_2                       matlab.ui.container.Panel
        StormDBViewerNavigationPanelGrid_2  matlab.ui.container.GridLayout
        StormIDDropDown_results       matlab.ui.control.DropDown
        StormIDDropDown_2Label        matlab.ui.control.Label
        FieldToPlotDropDown_results   matlab.ui.control.DropDown
        FieldToPlotDropDown_2Label    matlab.ui.control.Label
        MatchTypeDropDown_results     matlab.ui.control.DropDown
        MatchTypeDropDown_2Label      matlab.ui.control.Label
        DataTypeDropDown_results      matlab.ui.control.DropDown
        DataTypeDropDown_2Label       matlab.ui.control.Label
        StormTypeDropDown_results     matlab.ui.control.DropDown
        StormTypeDropDown_2Label      matlab.ui.control.Label
        PlotTypeDropDown              matlab.ui.control.DropDown
        PlotTypeDropDownLabel         matlab.ui.control.Label
        StormDBViewerButtonGrid_2     matlab.ui.container.GridLayout
        Button_6                      matlab.ui.control.Button
        Button_5                      matlab.ui.control.Button
        PSEAxes_3                     matlab.ui.control.UIAxes
        ProjectPanelGrid              matlab.ui.container.GridLayout
        ConstantsTable                matlab.ui.control.Table
        Image                         matlab.ui.control.Image
        ConstantsLabel                matlab.ui.control.Label
        ProjectPanel                  matlab.ui.container.Panel
        GridLayout8                   matlab.ui.container.GridLayout
        ProjectPathEditField          matlab.ui.control.EditField
        ProjectPathEditFieldLabel     matlab.ui.control.Label
        AlternativeDropDown           matlab.ui.control.DropDown
        AlternativeDropDownLabel      matlab.ui.control.Label
        PSEDropDown                   matlab.ui.control.DropDown
        PSEDropDownLabel              matlab.ui.control.Label
        ProjectDropDown               matlab.ui.control.DropDown
        ProjectLabel                  matlab.ui.control.Label
        ProjectNavigationLabel        matlab.ui.control.Label
        ProjectTree                   matlab.ui.container.Tree
        ProjectTreeLabel              matlab.ui.control.Label
    end


    properties (Access = private)
        controller % chessController: Loaded Projects, Active Selection, Run Tab Inputs, Run Path (Created In startupFcn)
        auxLib
        resultsPlotOptions % [NEW] Results Plot Options Per Plot Type (Right-Click "Plot Options...", Session Only)
        resultsMenu % [NEW] Results Axes Right-Click Menu (Created In startupFcn)
        resultsPopout % [NEW] Classic Figure Reused For Multi-Panel Results Plots
        resultsTablePopout % DET Response Table Pop-Out (uifigure From det_methods.response_table)
        plotFontSize = 12 % Base Font Of Every GUI Plot, Tab And Pop-Out (Library Rule: Title +2, Labels Base, Ticks -2)
        resultsMirror % Panel Over PSEAxes_3 (Same Grid Cell) Showing A Multi-Panel Results Plot When The Cell Is Big Enough (Created In startupFcn)
        resultsMirrorFits = [] % Fit State Of The Shown Multi-Panel Results Plot ([] If None): The Tab Resize Redraws Only When It Flips
    end

    methods (Access = private)
        function append_project(app, wProj)
            % Append SS Project & Make It Active (chessController.add_project), Then Refresh UI
            app.controller.add_project(wProj);
            app.refresh();
        end

        function answer = ask_question(app, q)
            % Asks A chessController Question (Struct id, kind, title, text, items, choices, default, size) Through auxLib;
            % Returns The Answer ([] When Closed)
            switch q.kind
                case {'choice', 'info'} % info: Notice With OK Only
                    app.auxLib.choice_dlgbox(q.text, q.choices, q.title, q.size);
            end
            answer = app.auxLib.dialog_answer;
        end

        function controller_done(app)
            % After A chessController Call: Its Queued Messages Shown (show_messages), Then The Multi-Line Stage 1 Drift It
            % Found Asked (drift_question / apply_drift)
            app.show_messages();
            drift = app.controller.take_drift();
            for dd = 1:size(drift, 1)
                q = app.controller.drift_question(drift(dd, :));
                if ~isempty(q)
                    app.controller.apply_drift(drift(dd, :), app.ask_question(q));
                    app.show_messages();
                end
            end
        end

        function [s1_row, msg] = apply_multiline_locks(app)
            % Multi-Line Run Tab Rules (chessController.stage2_rules; set_input_table, Before The Inputs Table Rows) Applied To
            % The Widgets: Responses Kept Checked (Stage 1 Hm0t), Then Storm Type, SLR, Tide File (Matched By File Name) And Data
            % Types Set To Stage 1's Run And Locked, Or Unlocked. s1_row / msg: chessController.stage1_row
            app.push_inputs();
            rules = app.controller.stage2_rules();
            app.controller_done();
            s1_row = rules.s1_row;
            msg = rules.msg;
            for sym = rules.force_responses
                nodes = app.get_tree_nodes(app.ResponsesTree);
                node = nodes(strcmp({nodes.NodeData}, sym{1}));
                if isscalar(node) && isempty(app.ResponsesTree.CheckedNodes)
                    app.ResponsesTree.CheckedNodes = node;
                elseif isscalar(node) && ~ismember(sym{1}, app.get_checked_symbols(app.ResponsesTree))
                    app.ResponsesTree.CheckedNodes = [app.ResponsesTree.CheckedNodes; node];
                end
            end
            if rules.locked
                if any(strcmp(app.StormTypeDropDown_2.Items, rules.storm_type))
                    app.StormTypeDropDown_2.Value = rules.storm_type;
                end
                if ~isempty(rules.swl_slr)
                    app.SeaLevelChangeEditField.Value = rules.swl_slr;
                end
                if ~isempty(rules.tide_name) % ItemsData Are Paths ('None' Kept)
                    [~, tide_names, tide_ext] = cellfun(@fileparts, app.TidesFileDropDown.ItemsData, 'un', false);
                    tide_k = find(strcmp(strcat(tide_names, tide_ext), rules.tide_name), 1);
                    if ~isempty(tide_k)
                        app.TidesFileDropDown.Value = app.TidesFileDropDown.ItemsData{tide_k};
                    end
                end
                nodes = app.get_tree_nodes(app.DataTypesTree);
                if ~isempty(nodes)
                    nodes = nodes(ismember({nodes.NodeData}, rules.data_types));
                end
                if isempty(nodes)
                    app.DataTypesTree.CheckedNodes = [];
                else
                    app.DataTypesTree.CheckedNodes = nodes;
                end
            end
            for comp = {app.StormTypeDropDown_2, app.SeaLevelChangeEditField, app.TidesFileDropDown, app.DataTypesTree}
                comp{1}.Enable = ~rules.locked;
            end
        end

        function ok = db_info_ok(app, dbObj)
            % [NEW] Storm DB Of The Current CHESS Version (chessController.db_info_ok: Older Ones Warned Once Per Session)
            ok = app.controller.db_info_ok(dbObj);
            app.show_messages();
        end

        function extract_project_zip(app, zip_file)
            % [NEW] Import An Exported Project Archive: Exactly One Top-Level Folder <top>/ Holding <top>/CHESS_project_<top>.mat
            % (Export Project Layout), No Top-Level Files. Unzipped Into A Chosen Folder, Never Over An Existing <dest>\<top>,
            % Then Imported From There (import_project_mat). The Extracted Folder Is Kept If The Import Fails Afterwards
            try
                entries = zip_entries(zip_file);
            catch
                app.auxLib.error_dlgbox('Could not read the selected file as a zip archive.');
                return
            end
            has_sep = contains(entries, '/');
            tops = unique(extractBefore(entries(has_sep), '/'));
            top = '';
            if all(has_sep) && isscalar(tops)
                top = tops{1};
            end
            if isempty(top) || ~any(strcmp(entries, [top '/CHESS_project_' top '.mat']))
                app.auxLib.error_dlgbox('Not a CHESS project archive: it must hold one project folder <name> with <name>/CHESS_project_<name>.mat.');
                return
            end
            if app.controller.is_loaded(top)
                app.auxLib.error_dlgbox(['Project "' top '" is already loaded.']);
                return
            end
            dest = uigetdir('', ['Extract Project "' top '" Into Folder']);
            if isequal(dest, 0)
                return
            end
            if exist(fullfile(dest, top), 'file')
                app.auxLib.error_dlgbox(['"' fullfile(dest, top) '" already exists. Choose another folder.']);
                return
            end
            try
                unzip(zip_file, dest);
            catch ME
                app.auxLib.error_dlgbox(['Could not extract the archive: ' ME.message]);
                return
            end
            app.import_project_mat(fullfile(dest, top, ['CHESS_project_' top '.mat']));

            function names = zip_entries(file)
                % Entry Names Without Extracting ('\' Normalised To '/'); Directory Entries Are Skipped
                zf = java.util.zip.ZipFile(file);
                closer = onCleanup(@() zf.close());
                names = {};
                en = zf.entries();
                while en.hasMoreElements()
                    nm = strrep(char(en.nextElement().getName()), '\', '/');
                    if ~endsWith(nm, '/')
                        names{end+1} = nm; %#ok<AGROW>
                    end
                end
            end
        end

        function symbols = get_checked_symbols(app, tree)
            % [NEW] Library Symbols (NodeData) Of Checked Nodes
            if isempty(tree.CheckedNodes)
                symbols = {};
            else
                symbols = {tree.CheckedNodes.NodeData};
            end
        end

        function [out_path, out_dir, wflow_folder, wflow_name, out_files] = get_config_path(app)
            % Run Folder & File Names Of The Run Tab Selection (chessController.config_path)
            app.push_inputs();
            [out_path, out_dir, wflow_folder, wflow_name, out_files] = app.controller.config_path();
        end

        function [proj_node, pse_node, alt_node, active_node, active_type] = get_node_family(app)
            % Get Active Node (Tree Nodes Carry Their Level In NodeData)
            active_node = app.ProjectTree.SelectedNodes;
            active_type = active_node.NodeData.type;
            pse_node = [];
            alt_node = [];
            switch active_type
                case 'proj' % Active Node Is Project (First PSE/Alternative If Any)
                    proj_node = active_node;
                    if ~isempty(proj_node.Children)
                        pse_node = proj_node.Children(1);
                    end
                    if ~isempty(pse_node) && ~isempty(pse_node.Children)
                        alt_node = pse_node.Children(1);
                    end
                case 'pse' % Active Node Is PSE (First Alternative)
                    pse_node = active_node;
                    proj_node = pse_node.Parent;
                    if ~isempty(pse_node.Children)
                        alt_node = pse_node.Children(1);
                    end
                case 'alt' % Active Node Is Alternative
                    alt_node = active_node;
                    pse_node = alt_node.Parent;
                    proj_node = pse_node.Parent;
                case 'sim' % Simulation Bundle Node: Its Alternative
                    alt_node = active_node.Parent;
                    pse_node = alt_node.Parent;
                    proj_node = pse_node.Parent;
            end
        end

        function opts = get_results_options(app, key)
            % [NEW] Plot Options (Right-Click) For A Plot Type: Session Values, Else Library Defaults
            opts = struct('bin_edges', [], 'cb_lim', [], 'grid_on', false, 'cb_log', false, 'c_field', '');
            if isstruct(app.resultsPlotOptions) && isfield(app.resultsPlotOptions, key)
                opts = app.resultsPlotOptions.(key);
            end
        end

        function get_sim_state(app)
            % Snapshot Of Run Tab Controls (Component Name, Value; chessController.snapshot, With Its Context). Inputs Table
            % Values Live In controller.inputs
            sim_tab = [{'StormDBDropDown_run', app.StormDBDropDown_run.Value};...
                {'ApplyDepthLimitationCheckBox', app.ApplyDepthLimitationCheckBox.Value};...
                {'StormTypeDropDown_2',app.StormTypeDropDown_2.Value};...
                {'TidesFileDropDown', app.TidesFileDropDown.Value};...
                {'WorkflowDropDown', app.WorkflowDropDown.Value};...
                {'SeaLevelChangeEditField', app.SeaLevelChangeEditField.Value};...
                {'ResponsesTree', {app.get_checked_symbols(app.ResponsesTree)}};...
                {'DataTypesTree', {app.get_checked_symbols(app.DataTypesTree)}};...
                {'ResponseSymbols', {app.get_tree_symbols(app.ResponsesTree)}};... % Tree Nodes Shown (New Context: Template Defaults Only For Others)
                {'DataTypeSymbols', {app.get_tree_symbols(app.DataTypesTree)}}];
            % Unwrap Cell-Wrapped Entries
            sim_tab(7:10, 2) = cellfun(@(x) x{1}, sim_tab(7:10, 2), 'un', false);
            app.controller.set_snapshot(sim_tab);
        end

        function nodes = get_tree_nodes(app, tree)
            % [NEW] All Tree Nodes (Two Levels) As A Column
            nodes = tree.Children(:);
            for kk = 1:length(tree.Children)
                nodes = [nodes; tree.Children(kk).Children(:)]; %#ok<AGROW>
            end
        end

        function symbols = get_tree_symbols(app, tree)
            % [NEW] Library Symbols (NodeData) Of All Nodes
            nodes = app.get_tree_nodes(tree);
            if isempty(nodes)
                symbols = {};
            else
                symbols = {nodes.NodeData};
            end
        end

        function hide_results_mirror(app)
            % [NEW] Results Tab Back To Its Axes: Clear And Hide The Multi-Panel Mirror Panel
            delete(app.resultsMirror.Children);
            app.resultsMirror.Visible = 'off';
            app.PSEAxes_3.Visible = 'on';
        end

        function import_project_mat(app, mat_file)
            % [NEW] Import A Project From Its Project File (chessController.open_project: Relocated, Locked, Registry Synced,
            % Saved; A Failure Rolls Back To The Previous Selection). Not Lockable: Notice, Not Imported. Then Refreshed, Multi-Line
            % Stage 1 Drift Asked (queue_sync_drift), Sync Counts In The Status Bar (None When Nothing Changed)
            out = app.controller.open_project(mat_file);
            switch out.status
                case 'refused'
                    app.ask_question(out.question);
                case 'error'
                    if out.rolled_back % Failed After The Lock: Back To The Previous Selection
                        try
                            app.refresh();
                        catch
                        end
                    end
                    app.auxLib.error_dlgbox(out.text);
                case 'opened'
                    app.refresh();
                    if app.controller.queue_sync_drift(app.controller.project, out.info)
                        app.controller_done();
                        app.refresh();
                    end
                    if ~isempty(out.note)
                        app.simStatusBar.Value = out.note;
                    end
            end
        end

        function [s1_row, msg, run_label] = multiline_stage1_row(app)
            % Multi-Line Stage 2: Its Stage 1's Registry Row Of The Run Tab Storm DB + Workflow (chessController.stage1_row)
            app.push_inputs();
            [s1_row, msg, run_label] = app.controller.stage1_row();
            app.controller_done();
        end

        function ok = lock_project(app, proj)
            % One CHESS Session Per Project (chessController.lock_project). Not Lockable: Modal Notice With OK Only (The GUI Waits
            % For It), false: The Caller Keeps The Previous Selection
            q = app.controller.lock_project(proj);
            ok = isempty(q);
            if ~ok
                app.ask_question(q);
            end
        end

        function load_saved_sim(app)
            % [NEW] Restore The Saved Simulation Of The Current Key: Run Tab Inputs (Saved Config) And Results
            app.push_inputs();
            app.controller.use_key(); % Resolved: populateResultsTab Loads It
            app.set_sim_state(2, app.get_config_path());
            app.populate_pse_table();
            app.populate_constants_table();
            app.set_input_table();
            app.populateResultsTab();
        end

        function open_results_popout(app)
            % [NEW] Multi-Panel Results Plots: Draw In One Reused Classic Figure
            % (DET Response Table Builds Its Own uifigure: No Classic Figure Needed)
            row = app.results_plot_row();
            if strcmp(app.StormTypeDropDown_results.Value, '-') % No Storm Type For This Plot: No Empty Pop-Out
                return
            end
            if ~isempty(row) && strcmp(row.key, 'det_table')
                app.plot_project_responses([], app.plotFontSize);
                return
            end
            if isempty(app.resultsPopout) || ~isvalid(app.resultsPopout)
                app.resultsPopout = figure('Name', 'CHESS Results');
            else
                clf(app.resultsPopout);
                figure(app.resultsPopout);
            end
            app.plot_project_responses(app.resultsPopout, app.plotFontSize);
        end

        function vals = parse_numeric_list(app, txt)
            % [NEW] Numbers From Text Without eval: "0 0.5 1", "0, 0.5, 1", "[0 1]" Or "start:step:end" ([] If Blank, NaN If Invalid)
            txt = strtrim(regexprep(char(txt), '[\[\]]', ''));
            vals = [];
            if isempty(txt)
                return
            end
            if contains(txt, ':')
                parts = str2double(strsplit(txt, ':'));
                if any(isnan(parts)) || ~ismember(numel(parts), [2 3])
                    vals = NaN;
                elseif numel(parts) == 2
                    vals = parts(1):parts(2);
                else
                    vals = parts(1):parts(2):parts(3);
                end
                if isempty(vals)
                    vals = NaN;
                end
            else
                vals = str2double(regexp(txt, '[,;\s]+', 'split'));
            end
        end

        function plot_project_responses(app, target, base_fnt)
            % [NEW] Results Viewer: Draw The Selected Plot Type With Its CHESS-Library Method.
            %   plot_project_responses(app)                   -> Results Tab Axes + Results Table (Multi-Panel Plots: Drawn
            %                                                    In The Tab Mirror Panel If The Cell Is Big Enough, Else A Note)
            %   plot_project_responses(app, target, base_fnt) -> Pop-Out (Classic Figure Or Axes)
            tab_mode = nargin < 2;
            if tab_mode
                target = app.PSEAxes_3;
                base_fnt = app.plotFontSize;
            end
            state = app.controller.results;
            row = app.results_plot_row();
            if isempty(state) || isempty(row)
                return
            end
            no_storm_type = strcmp(app.StormTypeDropDown_results.Value, '-');
            if tab_mode
                app.reset_results_axes();
                app.resultsMirrorFits = [];
                app.PSETable_3.Data = {};
                app.PSETable_3.ColumnName = {};
                if no_storm_type
                    title(app.PSEAxes_3, 'No storm type with data for this plot');
                    return
                end
                if row.multi_panel % Also In The Pop-Out: Mirror In The Tab If It Fits, Else Grey Out The Tab Axes
                    app.resultsMirrorFits = app.results_mirror_fits(row);
                    if ~app.resultsMirrorFits
                        app.show_popout_note(row);
                        return
                    end
                    app.PSEAxes_3.Visible = 'off';
                    app.resultsMirror.Visible = 'on';
                    target = uigridlayout(app.resultsMirror, [1 1]);
                end
            elseif no_storm_type
                return
            end
            % Single-Panel Plots Need Axes, Multi-Panel Plots Take The Figure
            if ~row.multi_panel && isa(target, 'matlab.ui.Figure')
                target = axes('Parent', target);
            end
            ax = target;
            % Selection
            ds_query = struct('storm_type', app.StormTypeDropDown_results.Value,...
                'data_type', app.DataTypeDropDown_results.Value,...
                'match_type', app.MatchTypeDropDown_results.Value);
            field = app.FieldToPlotDropDown_results.Value;
            aux = app.StormIDDropDown_results.Value;
            lc_index = str2double(aux); % Life Cycle ('All' -> [])
            if isnan(lc_index)
                lc_index = [];
            end
            opts = app.get_results_options(row.key);
            % Plot Data Loaded On Demand
            config = state.config;
            storm = [];
            dsw = [];
            add_events = 0; % Hazard Curve Events Overlay Mode: 0 Off, 1 Run Sample, 2 Storm Values
            if strcmp(row.key, 'hc') && ~strcmp(ds_query.storm_type, 'CC') % CC: No Overlays
                add_events = max([0, find(strcmp(aux, {'Run Sample', 'Storm Values'}), 1)]);
            end
            if any(strcmp(row.key, {'event', 'scheme'}))
                storm = app.controller.load_storm(state.dbObj);
                config.sp_ID = CHSStormDBImportUI.get_savepoint_id(state.dbObj); % Title (GUI Run Configs Leave sp_ID Empty)
            end
            project_forcing = state.project_forcing;
            if add_events > 0 || strcmp(row.key, 'scheme') % Events Overlay / Sampling Scheme Need Project Forcing + TC Probability Masses
                [project_forcing, dsw] = app.controller.results_forcing();
            end
            chessPlot = CHESSPlots(config, state.Resp, storm, project_forcing, dsw, state.structure, base_fnt, app.controller.project.unitsys);
            try
                switch row.key
                    case 'hc' % PROS Hazard Curve (+ Table)
                        chessPlot.hc_plot(ax, ds_query, field, add_events);
                        if tab_mode
                            data = aux_methods.pull_data(ds_query, state.Resp);
                            data = data(strcmp({data.var}, field));
                            cls = arrayfun(@(x) ['CL' num2str(x)], data.CL, 'un', false);
                            cls(data.CL == 50) = {'BE'};
                            if state.config.pros_use_aep == 1
                                x_lbl = 'AEP';
                            else
                                x_lbl = 'AEF [1/yr]';
                            end
                            app.PSETable_3.ColumnName = [{x_lbl}, cls];
                            app.PSETable_3.Data = [data.x_table, data.y_table];
                        end
                    case 'det_scatter' % Deterministic: Response vs Forcing (X: Storm ID Dropdown, Y: Field, Color: Plot Options)
                        fields = app.controller.det_fields(aux_methods.pull_data(ds_query, state.Resp));
                        c_field = opts.c_field;
                        if isempty(c_field) || ~any(strcmp(fields, c_field))
                            c_field = fields{max([1, find(strcmp(fields, 'Hm0_toe'), 1)])};
                        end
                        chessPlot.response_vs_forcing_plot(ax, ds_query, aux, field, c_field);
                        if tab_mode % Table: The Plotted Values (Per Storm; Timeseries -> Storm Maxima)
                            mx = aux_methods.pull_data(ds_query, state.Resp).Max;
                            app.PSETable_3.ColumnName = {'Storm ID', aux, field, c_field};
                            app.PSETable_3.Data = [mx.storm_id(:), mx.(aux)(:), mx.(field)(:), mx.(c_field)(:)];
                        end
                    case 'det_table' % Deterministic: Response Table Pop-Out (uifigure, Replaces The Previous One)
                        if ~isempty(app.resultsTablePopout) && isvalid(app.resultsTablePopout)
                            delete(app.resultsTablePopout);
                        end
                        storm_id = str2double(aux);
                        if isnan(storm_id)
                            storm_id = [];
                        end
                        app.resultsTablePopout = chessPlot.response_table(ds_query, storm_id);
                        app.resultsTablePopout.Position(1:2) = app.UIFigure.Position(1:2) + (app.UIFigure.Position(3:4) - app.resultsTablePopout.Position(3:4))/2;
                    case 'det_compare' % Deterministic: Peaks Value vs Timeseries Peak (Same Storms, 1:1 Line)
                        chessPlot.peaks_vs_timeseries_plot(ax, ds_query, field);
                        if tab_mode
                            pk = aux_methods.pull_data(ds_query, state.Resp).Max;
                            q_ts = ds_query;
                            q_ts.data_type = 'Timeseries';
                            ts = aux_methods.pull_data(q_ts, state.Resp).Max;
                            [ids, ia, ib] = intersect(pk.storm_id, ts.storm_id);
                            app.PSETable_3.ColumnName = {'Storm ID', ['Peaks ' field], ['Timeseries ' field]};
                            app.PSETable_3.Data = [ids(:), pk.(field)(ia), ts.(field)(ib)];
                        end
                    case 'event' % Storm Event Viewer (Pop-Out): Forcing + Recomputed Response For One Event (Peaks: All)
                        event_id = 0;
                        if strcmp(ds_query.data_type, 'Timeseries')
                            event_id = str2double(aux);
                        end
                        chessPlot.storm_event_viewer(target, ds_query, event_id, field, 0);
                    case 'annual' % LCS Annual Response Distribution (+ Table Of Binned Values Per Sim Year)
                        [edges, labels] = app.controller.bin_edges(chessPlot, ds_query, field, opts.bin_edges);
                        [~, bin_data] = chessPlot.annual_response_distribution(ax, ds_query, field, edges, string(aux),...
                            opts.cb_lim, opts.grid_on, opts.cb_log);
                        if tab_mode && isempty(bin_data) % No Finite Values: Library "No Data" Axes, Empty Table
                            app.PSETable_3.ColumnName = {'Sim Year'};
                            app.PSETable_3.Data = zeros(0, 1);
                        elseif tab_mode
                            app.PSETable_3.ColumnName = [{'Sim Year'}, labels];
                            app.PSETable_3.Data = [(1:size(bin_data, 1))', bin_data(:, 1:numel(labels))];
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
                if tab_mode
                    app.reset_results_axes();
                    title(app.PSEAxes_3, 'Plot not available for this selection');
                end
                app.auxLib.alert_dlgbox(me.message, ['Results Plot: ' row.label], 'warning');
            end
            % Right-Click Plot Options On The Tab Plot (And The Mirrored Multi-Panel Axes)
            if tab_mode
                set(findobj([app.PSEAxes_3; app.resultsMirror.Children], '-property', 'ContextMenu'), 'ContextMenu', app.resultsMenu);
            end
        end

        function plot_storm_db(app, ax, base_fnt)
            % [NEW] Plot Storm DB Viewer Selection With CHESS-Library Plot Classes.
            %   plot_storm_db(app)               -> Storm DB Tab Axes + Storm DB Table
            %   plot_storm_db(app, ax, base_fnt) -> Given Axes Only (e.g. Pop-Out Figure)
            tab_mode = nargin < 2;
            if tab_mode
                ax = app.StormDBAxes;
                base_fnt = app.plotFontSize;
            end
            % Pull Storm DB (Cached). Storm DB Of An Older CHESS Version (No db_info): Alert, No Plot
            dbObj = app.controller.project.get_project_field('stormDB_list', app.StormDBDropDown.Value, '', 'db');
            if ~app.db_info_ok(dbObj)
                cla(ax);
                legend(ax, 'off');
                if tab_mode
                    app.StormDBTable.Data = cell(0, 2);
                end
                return
            end
            storm = app.controller.load_storm(dbObj);
            ds_query = struct('storm_type', app.StormTypeDropDown.Value,...
                'data_type', app.DataTypeDropDown.Value,...
                'match_type', app.MatchTypeDropDown.Value);
            % Library Plot Object (Storm Database Only: No PSE, Workflow Or Results)
            config = struct('project_datum', app.controller.project.vdatum, 'apply_random_tides', 0,...
                'region', dbObj.study, 'sp_ID', CHSStormDBImportUI.get_savepoint_id(dbObj), 'struc_id', '', 'case_name', '',...
                'r2p_u', 0, 'q_u', 0, 'dn50_u', 0, 'p1_u', 0,... % Axis Labels Only (response_library_headers)
                'chs_swl_u_a', 0, 'chs_swl_u_r', 0, 'chs_hm0_u_a', 0, 'chs_hm0_u_r', 0);
            % TC SWL Bias Correction State & Coefficients From The Storm DB's db_info (Raw Signal Is Corrected Like The Imported storm)
            db_info = CHSStormDBImportUI.get_db_info(dbObj);
            config.tc_bias_corrected = db_info.tc_bias_corrected;
            config.chs_swl_b_a = db_info.chs_swl_b_a;
            config.chs_swl_b_r = db_info.chs_swl_b_r;
            chessPlot = CHESSPlotsBase(config, [], storm, [], [], [], base_fnt, app.controller.project.unitsys);
            % Plot (And Tab Table) According To Data Type
            cla(ax);
            legend(ax, 'off');
            field_names = {'SWL', 'Hm0', 'Tp'};
            stm_data = aux_methods.pull_data(ds_query, storm);
            stm_list = cell2mat(stm_data(:, 1));
            y_field = app.FieldToPlotDropDown.Value;
            y_lbl = app.FieldToPlotDropDown.Items{strcmp(field_names, y_field)};
            switch app.DataTypeDropDown.Value
                case 'Peaks' % Storm Data Space: Y Field Vs X Field
                    x_field = app.StormIDDropDown.Value;
                    chessPlot.storm_data_space_plot(ax, ds_query, y_field, x_field);
                    if tab_mode
                        x_lbl = app.StormIDDropDown.Items{strcmp(field_names, x_field)};
                        peak_of = @(col) cellfun(@(x) max(x(:, col), [], 'omitnan'), stm_data(:, 2));
                        app.StormDBTable.ColumnName = {'Storm ID', y_lbl, x_lbl};
                        app.StormDBTable.Data = [stm_list, peak_of(strcmp(field_names, y_field)), peak_of(strcmp(field_names, x_field))];
                    end
                case 'Timeseries' % Event Hydrograph: storm (Interpolated) + CHS_Data (Raw)
                    event_id = str2double(app.StormIDDropDown.Value);
                    chessPlot.event_hydrograph_plot(ax, ds_query, event_id, y_field, app.controller.load_chs_data(dbObj));
                    if tab_mode
                        hydrograph = stm_data{stm_list == event_id, 2};
                        app.StormDBTable.ColumnName = {'Event Duration [hrs]', y_lbl};
                        app.StormDBTable.Data = [(hydrograph(:, 5) - hydrograph(1, 5))*24, hydrograph(:, strcmp(field_names, y_field))];
                    end
            end
        end

        function [st_types, has_peaks, has_timeseries] = populate_data_types(app, layout)
            % Data Type Tree From A Storm DB Record's layout (CHSStormDBImportUI.storm_layout; No Storm Data Loaded). NodeData
            % Holds Library Symbol. No layout (Storm DB File Missing Or Unreadable, stormdb_missing_note): Empty Tree
            delete(app.DataTypesTree.Children(:));
            st_types = cell(0, 1);
            has_peaks = false;
            has_timeseries = false;
            if isempty(layout) || isempty(layout.storm_types)
                return
            end
            st_types = layout.storm_types(:);
            data_types = layout.data_types.(st_types{1});
            has_peaks = any(strcmp(data_types, 'Peaks'));
            has_timeseries = any(strcmp(data_types, 'Timeseries'));
            if has_peaks
                match_types = layout.match_types.(st_types{1}).Peaks;
                peaksTree = uitreenode(app.DataTypesTree, "Text", 'Peaks', 'NodeData', 'use_peaks');
                for i = 1:length(match_types)
                    switch match_types{i}
                        case 'WLP'
                            symbol = 'create_wlp';
                        case 'WHP'
                            symbol = 'create_whp';
                        otherwise
                            symbol = 'peaks_default';
                    end
                    uitreenode(peaksTree, "Text", match_types{i}, 'NodeData', symbol);
                end
            end
            if has_timeseries
                uitreenode(app.DataTypesTree, "Text", 'Timeseries', 'NodeData', 'use_timeseries');
            end
        end

        function populate_inputs_table(app)
            % Inputs Table: Pertinent Rows Only (Library Template), Values From controller.inputs (All Workflows)
            app.store_table_values();
            [pse_name, alt_name] = app.controller.active_names();
            pse_obj = app.controller.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            if isempty(pse_obj)
                app.WorkflowInputsTable.Data = cell(0, 3);
                return
            end
            tpl = app.controller.project.get_library_template(pse_obj.pse_type);
            resp_checked = app.get_checked_symbols(app.ResponsesTree);
            rows = cell(0, 4);
            % Forcing: Storm Duration Always Shown (Dn50 Uses It For Timeseries Runs Too)
            rows = [rows; tpl.forcing(strcmp(tpl.forcing(:, 1), 'storm_duration'), :)];
            % Response Parameters (Template Rows Not Described As "Compute...", e.g. compute_damaging_depth_Ks)
            % Shown When The Response They Extend Is Checked
            resp_sym = tpl.responses(:, 1);
            is_switch = startsWith(tpl.responses(:, 2), 'Comput');
            for rr = find(~is_switch)'
                parent = resp_sym(is_switch & cellfun(@(x) startsWith(resp_sym{rr}, [x '_']), resp_sym));
                if any(ismember(parent, resp_checked))
                    rows = [rows; tpl.responses(rr, :)]; %#ok<AGROW>
                end
            end
            % Workflow Sections
            switch app.WorkflowDropDown.Value
                case 1 % PROS-RB
                    rows = [rows; tpl.pros];
                case 4 % PROS-FB (Library Forces Forcing HCs)
                    rows = [rows; tpl.pros(~strcmp(tpl.pros(:, 1), 'pros_compute_forcing_HC'), :)];
                case 2 % Deterministic: No Hazard Curve, CL Or LCS Inputs
                case 3 % LCS
                    rows = [rows; tpl.mcs];
                    % CSR-DPA (Library chess_csr): Rubble Mound Timeseries Runs Only; Its Settings Only While csr_call_dpa Is 1.
                    % csr_compute_S_submerged Is Never Shown. Hidden Values Stay In controller.inputs
                    if chessProject.get_struc_type(pse_obj.pse_type) == 3 && ismember('use_timeseries', app.get_checked_symbols(app.DataTypesTree))
                        csr = tpl.csr(~strcmp(tpl.csr(:, 1), 'csr_compute_S_submerged'), :);
                        is_call = strcmp(csr(:, 1), 'csr_call_dpa');
                        dpa_on = csr{is_call, 4};
                        if isfield(app.controller.inputs, 'csr_call_dpa')
                            dpa_on = app.controller.inputs.csr_call_dpa;
                        end
                        if ~isequal(dpa_on, 1)
                            csr = csr(is_call, :);
                        end
                        rows = [rows; csr];
                    end
            end
            % 0/1 Switch Rows (Template Description Marks Them) Shown As Checkboxes: Logical Values In The Data Cell
            is_flag = contains(rows(:, 2), {'(0/1)', '(0 - Off / 1 - On)'});
            % Field Label = Description [Units]
            has_units = ~strcmp(rows(:, 3), 'NA') & ~cellfun(@isempty, rows(:, 3));
            rows(has_units, 2) = strcat(rows(has_units, 2), {' '}, rows(has_units, 3));
            % Values: controller.inputs (Entered/Restored) Else Template Default
            tbl = [rows(:, 1:2), rows(:, 4)];
            for kk = 1:size(tbl, 1)
                if isfield(app.controller.inputs, tbl{kk, 1})
                    tbl{kk, 3} = app.controller.inputs.(tbl{kk, 1});
                end
            end
            tbl(is_flag, 3) = cellfun(@(v) isequal(v, 1), tbl(is_flag, 3), 'un', false);
            app.WorkflowInputsTable.Data = tbl;
        end

        function populate_project_panel(app)
            % Update Project Tree
            app.update_project_tree();
            % No Projects Loaded
            if isempty(app.controller.projects)
                app.ProjectDropDown.Items = {};
                app.PSEDropDown.Items = {};
                app.AlternativeDropDown.Items = {};
                app.ProjectPathEditField.Value = '';
                app.PSEMenu.Enable = false;
                app.AlternativeMenu.Enable = false;
                return
            end
            % Project Dropdown
            projList = {app.controller.projects.name};
            app.ProjectDropDown.Items = projList;
            app.ProjectDropDown.Value = app.controller.project.name;
            app.ProjectPathEditField.Value = app.controller.project.get_project_field('path', '', '', 'proj');
            % PSE & Alternative Dropdowns
            [pse_name, alt_name] = app.controller.active_names();
            pseList = app.controller.project.pse_list;
            app.PSEDropDown.Items = pseList;
            if ~isempty(pse_name)
                app.PSEDropDown.Value = pse_name;
                app.AlternativeDropDown.Items = app.controller.project.get_project_field('alternative_list', pse_name, '', 'pse');
            else
                app.AlternativeDropDown.Items = {};
            end
            if ~isempty(alt_name)
                app.AlternativeDropDown.Value = alt_name;
            end
            % Menus
            app.PSEMenu.Enable = true;
            app.AlternativeMenu.Enable = ~isempty(pseList);
        end

        function populate_pse_responses(app, has_timeseries)
            % Response Tree From Library Template "Structure Responses" (NodeData Holds Library Symbol)
            delete(app.ResponsesTree.Children(:));
            [pse_name, alt_name] = app.controller.active_names();
            pse_obj = app.controller.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            if isempty(pse_obj)
                return
            end
            tpl = app.controller.project.get_library_template(pse_obj.pse_type);
            resp_sym = tpl.responses(:, 1);
            for rr = 1:length(resp_sym)
                % Response Switches Are Described As "Compute..."; Parameter Rows Go To Inputs Table
                if ~startsWith(tpl.responses{rr, 2}, 'Comput')
                    continue
                end
                % Overtopping Volume Requires Timeseries
                if strcmp(resp_sym{rr}, 'compute_q_vol') && ~has_timeseries
                    continue
                end
                txt = tpl.responses{rr, 2};
                % Multi-Line Stage 1: Hm0t Is Its Stage 2 Forcing, Always On (chessController.run_config; Re-Checked By set_input_table)
                if strcmp(resp_sym{rr}, 'compute_wave_transmission') && app.controller.project.alt_stage(pse_name, alt_name) == 1
                    txt = [txt ' (Multi-Line Stage 1: Always On)'];
                end
                uitreenode(app.ResponsesTree, "Text", txt, 'NodeData', resp_sym{rr});
            end
        end

        function populate_constants_table(app)
            % [NEW] Project Panel Constants Table (Display Only; chessController.constants): Water Density, Gravity, Offshore
            % Elevation, Multi-Line Transect Rows And The Run Tab Storm DB's Bias & Uncertainty
            app.push_inputs();
            app.ConstantsTable.Data = app.controller.constants();
            app.controller_done();
        end

        function populate_pse_table(app)
            % [NEW] PSE Viewer Table (chessController.pse_table: Offshore Rows Shown Only Where Runs Use Them)
            app.push_inputs();
            app.PSETable.Data = app.controller.pse_table();
            app.controller_done();
        end

        function populate_stormDB_panel(app, dbObj, db_list)
            % Load Storm (Cached). Storm DB File Missing Or Unreadable: Empty Tab With The Storm DB Listed And A Re-Import Note
            try
                storm = app.controller.load_storm(dbObj);
            catch
                app.reset_tab('db');
                app.StormDBDropDown.Items = db_list;
                app.StormDBDropDown.Value = dbObj.db_name;
                text(app.StormDBAxes, 0.5, 0.5, sprintf('Storm DB %s: file missing or unreadable, re-import it.', dbObj.db_name),...
                    'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', app.plotFontSize);
                return
            end
            % Storm DB
            app.StormDBDropDown.Items = db_list;
            app.StormDBDropDown.Value = dbObj.db_name;
            % Cascade: Storm Type -> Data Type -> Match Type (Keeps Valid Selections)
            app.StormTypeDropDown.Items = fieldnames(storm);
            data_type = fieldnames(storm.(app.StormTypeDropDown.Value));
            app.DataTypeDropDown.Items = data_type(contains(data_type, {'Peaks','Timeseries'}));
            app.MatchTypeDropDown.Items = fieldnames(storm.(app.StormTypeDropDown.Value).(app.DataTypeDropDown.Value));
            % Field To Plot (ItemsData = Library Field Names)
            fields_to_plot = {'Water Level','Wave Height (Hm0)', 'Peak Period'};
            field_names = {'SWL', 'Hm0', 'Tp'};
            app.FieldToPlotDropDown.Items = fields_to_plot;
            app.FieldToPlotDropDown.ItemsData = field_names;
            % Second Dropdown: X Field For Peaks (Data Space Plot), Storm ID For Timeseries (Hydrograph)
            switch app.DataTypeDropDown.Value
                case 'Peaks'
                    app.StormIDDropDownLabel.Text = 'X Field:';
                    app.StormIDDropDown.Items = fields_to_plot;
                    app.StormIDDropDown.ItemsData = field_names;
                    if strcmp(app.StormIDDropDown.Value, app.FieldToPlotDropDown.Value)
                        app.StormIDDropDown.Value = field_names{2}; % Default: SWL Vs Hm0
                    end
                case 'Timeseries'
                    app.StormIDDropDownLabel.Text = 'Storm ID:';
                    app.StormIDDropDown.ItemsData = {};
                    app.StormIDDropDown.Items = cellfun(@num2str, storm.(app.StormTypeDropDown.Value).(app.DataTypeDropDown.Value).(app.MatchTypeDropDown.Value)(:,1), 'UniformOutput', false);
            end
            app.StormIDDropDown.Enable = true;
            app.updateStormDBPlot([]);
        end

        function populateResultsTab(app)
            % Results Of Active Alternative / Workflow / Storm DB (chessController.load_results: Only Once The Saved Simulation
            % Key Is Resolved And Not Declined) + Status Line; Plot Types Of The Loaded Run (Library Plot Catalog)
            app.push_inputs();
            [loaded, msg] = app.controller.load_results();
            app.controller_done();
            app.simStatusBar.Value = msg;
            if ~loaded
                app.reset_tab('results');
                return
            end
            cat = app.controller.plot_catalog();
            app.PlotTypeDropDown.Items = {cat.label};
            app.PlotTypeDropDown.ItemsData = {cat.key};
            app.Panel_2.Enable = true;
            app.update_results_controls('plot');
            app.plot_project_responses();
        end

        function populateSimulationTab(app)
            % Snapshot Current Run Tab State (Restored If Context Is Unchanged: chessController.set_context)
            app.get_sim_state();
            new_context = app.controller.set_context();
            % Nothing To Show Without An Alternative And A Storm DB
            dbList = [];
            if app.controller.has_active_alt()
                dbList = app.controller.project.get_project_field('stormDB_list', '', '', 'proj');
            end
            if isempty(dbList)
                app.reset_tab('sim');
                return
            end
            [pse_name, alt_name] = app.controller.active_names();

            % 1. Storm DB (New Context: The Alternative's Newest Simulation, chessProject.default_db; Else Keep User Choice)
            db_names = {dbList.db_name};
            current_db = app.StormDBDropDown_run.Value;
            app.StormDBDropDown_run.Items = db_names;
            default_db = app.controller.project.default_db(pse_name, alt_name);
            if new_context && ~isempty(default_db)
                app.StormDBDropDown_run.Value = default_db;
            elseif ~new_context && any(strcmp(current_db, db_names))
                app.StormDBDropDown_run.Value = current_db;
            end
            dbObj = dbList(strcmp(db_names, app.StormDBDropDown_run.Value));

            % 2. Storm Types & Data Types From The Storm DB Record's layout (No Storm Data Loaded). No layout: Both Empty, Run
            % Disabled And The Status Bar Asks For A Re-Import (set_input_table, stormdb_missing_note)
            [st_types, ~, has_timeseries] = app.populate_data_types(dbObj.layout);
            if all(ismember({'XC','TC'}, st_types))
                st_types = [{'CC'}; st_types];
            end
            app.set_dropdown_items(app.StormTypeDropDown_2, st_types);

            % 3. Tides (File Names Shown, Full Paths Passed To The Library As config.tide_file)
            tide_files = app.controller.project.tide_files_list(:);
            [~, tide_names, tide_ext] = cellfun(@fileparts, tide_files, 'un', false);
            app.TidesFileDropDown.Items = [{'None'}; strcat(tide_names, tide_ext)];
            app.TidesFileDropDown.ItemsData = [{'None'}; tide_files];

            % 4. Responses (Library Template For PSE Type)
            app.populate_pse_responses(has_timeseries);

            % 5. Restore State: New Context Keeps The Current Inputs (Mapped To This PSE's Template), Same Context The Snapshot.
            % A Saved Simulation Of A New Alternative / Workflow / Storm DB Is Offered Afterwards (sync_saved_sim)
            if new_context
                app.set_sim_state(3, '');
            else
                app.set_sim_state(1, '');
            end

            % 6. Inputs Table & Run Button (Constants Table: Callers Run populate_constants_table Next)
            app.set_input_table();
        end

        function plot_pse_geometry(app, ax, base_fnt, keep_text_box)
            % Active Alternative's Transect Into ax (chessProject.plot_geometry). keep_text_box: Pop-Out Text Box (Offshore End:
            % chessController.popout_offshore_elevation). Multi-Line Stage 2: In Line Behind Stage 1 As Run For The Run Tab Storm DB +
            % Workflow (multiline_stage1_row: Stage 1's PSE Geometry With That Run's Kt Geometry, Row structure_kt); No Such Run:
            % Stage 2 Alone With A Note
            [pse_name, alt_name] = app.controller.active_names();
            [offshore_elevation, elevation_source] = deal([], '');
            if keep_text_box
                app.push_inputs();
                [offshore_elevation, elevation_source] = app.controller.popout_offshore_elevation();
                app.controller_done();
            end
            stage1 = [];
            if app.controller.project.alt_stage(pse_name, alt_name) == 2
                [s1_row, ~, run_label] = app.multiline_stage1_row();
                if isempty(run_label)
                    stage1 = 'Stage 1 not shown: no Run tab storm DB';
                elseif isempty(s1_row)
                    stage1 = ['Stage 1 not run for ' run_label];
                else
                    stage1 = app.controller.project.get_project_field('pse_geometry', pse_name, app.controller.project.stage1_alt(pse_name), 'alt');
                    for fld = fieldnames(s1_row.structure_kt)'
                        stage1.(fld{1}) = s1_row.structure_kt.(fld{1});
                    end
                end
            end
            app.controller.project.plot_geometry(pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source, stage1);
        end

        function push_inputs(app)
            % Run Tab Widgets -> chessController (selection.db / workflow, inputs: Controls And Visible Inputs Table Rows; Hidden
            % Rows Keep Their Stored Values). Called Before Every Controller Call That Reads Them: The Controller Never Reads Widgets
            db_name = '';
            if ~isempty(app.StormDBDropDown_run.Items)
                db_name = app.StormDBDropDown_run.Value;
            end
            app.controller.set_run_selection(db_name, app.WorkflowDropDown.Value);
            app.controller.set_input('storm_sampling', app.StormTypeDropDown_2.Value);
            app.controller.set_input('data_types', app.get_checked_symbols(app.DataTypesTree));
            app.controller.set_input('swl_slr', app.SeaLevelChangeEditField.Value);
            app.controller.set_input('tide_file', app.TidesFileDropDown.Value);
            app.controller.set_input('apply_depth_limitation', app.ApplyDepthLimitationCheckBox.Value);
            app.controller.set_input('responses', app.get_checked_symbols(app.ResponsesTree));
            app.store_table_values();
        end

        function value = pull_input_table_value(app, table_data, field_to_get)
            pull_indx = strcmp(table_data(:, 1), field_to_get);
            if ~any(pull_indx)
                value = [];
            else
                value = +table_data{find(pull_indx, 1), end};
            end
        end

        function rebuild_sims(app, proj)
            % Project Tree Right-Click "Rebuild simulations from disk" (chessController.rebuild_sims: Only The Active Project,
            % Never During A Run): Multi-Line Stage 1 Drift Asked, Refreshed; Counts Reported
            title_str = 'Rebuild Simulations From Disk';
            out = app.controller.rebuild_sims(proj);
            if ~out.done
                app.auxLib.alert_dlgbox(out.text, title_str, 'info');
                return
            end
            app.controller_done();
            app.refresh();
            app.auxLib.alert_dlgbox(out.text, title_str, 'info');
        end

        function remove_alt_sims(app, proj, pse_name, alt_name, sim_label)
            % Delete Simulation Bundles Of An Alternative Of proj (chessController.remove_sims; Only The Active Project, Never
            % During A Run). sim_label '': Dialog (Alternatives Of pse_name, Starting On alt_name; Its Bundles, One Or More),
            % Else That Bundle After A Confirmation. A Multi-Line Stage 1 Bundle Takes Its Stage 2 Bundles (Asked)
            title_str = 'Remove Alternative Simulation';
            msg = app.controller.refusal(proj, 'Removing', 'changed');
            if ~isempty(msg)
                app.auxLib.alert_dlgbox(msg, title_str, 'info');
                return
            end
            % Dialog Lists: Rows Without Repair (No Save Or Drift Question From Inside The Dialog)
            if isempty(sim_label)
                alts = proj.alternative_list{strcmp(proj.pse_list, pse_name)};
                app.auxLib.dropdown_list_dlgbox(sprintf(['Delete simulations of PSE "%s" with all their run files. Choose the ',...
                    'alternative, then one or more simulations (storm DB | workflow; Ctrl+click selects several).'], pse_name),...
                    title_str, 'Alternative:', alts, alt_name, @(a) app.controller.sim_labels(proj, pse_name, a), 'Delete');
                answer = app.auxLib.dialog_answer;
                if isempty(answer)
                    return
                end
                alt_name = answer.choice;
                labels = answer.items;
            else
                app.auxLib.choice_dlgbox(sprintf('Delete simulation "%s" of alternative "%s" (PSE %s) with all its run files?',...
                    sim_label, alt_name, pse_name), {'Delete', 'Cancel'}, title_str); % Last Button = Default (Enter): Cancel
                if ~strcmp(app.auxLib.dialog_answer, 'Delete')
                    return
                end
                labels = {sim_label};
            end
            out = app.controller.remove_sims(proj, pse_name, alt_name, labels);
            app.controller_done();
            if strcmp(out.status, 'ask')
                out = app.controller.remove_sims(proj, pse_name, alt_name, labels, struct(out.question.id, {app.ask_question(out.question)}));
            end
            if strcmp(out.status, 'done')
                msgs = app.controller.take_messages();
                app.refresh();
                app.show_messages(msgs);
            end
        end

        function refresh(app, ask)
            % [NEW] Flagged Refresh: The Views The Controller Marked Stale (chessController.take_changed, VIEWS Order) Redrawn:
            % Project Panel & Tree -> Storm DB Tab -> Run Tab Controls (Or Inputs Table Only) -> PSE Tab (After The Run Tab:
            % A Multi-Line Stage 2 Plot Follows Its Storm DB + Workflow) -> Constants -> Results Tab, Then Its Saved Simulation
            % (Dialog Only When ask: A User Switch). Flags Raised While Redrawing Are Dropped (Drawn In This Pass)
            if nargin < 2
                ask = false;
            end
            views = app.controller.take_changed();
            has = @(v) any(strcmp(views, v));
            if has('project_panel')
                app.populate_project_panel(); % Tree Included
            elseif has('tree')
                app.update_project_tree();
            end
            if has('stormdb') % Storm DB Viewer: The Alternative's Newest Simulation (chessProject.default_db), Else First
                dbList = [];
                if ~isempty(app.controller.project)
                    dbList = app.controller.project.get_project_field('stormDB_list', '', '', 'proj');
                end
                if isempty(dbList)
                    app.reset_tab('db');
                else
                    db_indx = [];
                    if app.controller.has_active_alt()
                        [pse_name, alt_name] = app.controller.active_names();
                        db_indx = find(strcmp(app.controller.project.default_db(pse_name, alt_name), {dbList.db_name}), 1);
                    end
                    if isempty(db_indx)
                        db_indx = 1;
                    end
                    app.populate_stormDB_panel(dbList(db_indx), {dbList.db_name});
                end
            end
            if has('run_controls')
                app.populateSimulationTab();
            elseif has('inputs_table')
                app.set_input_table();
            end
            if has('pse')
                if app.controller.has_active_alt()
                    app.plot_pse_geometry(app.PSEAxes, app.plotFontSize, false);
                else
                    app.reset_tab('pse');
                end
                app.populate_pse_table();
            end
            if has('constants')
                app.populate_constants_table();
            end
            if has('results')
                app.populateResultsTab();
                app.sync_saved_sim(ask);
            elseif has('status') && ~isempty(app.controller.results)
                app.push_inputs();
                app.set_sim_status(app.controller.results_status());
            end
            app.controller.take_changed();
        end

        function rename_tree_node(app, node)
            % Project Tree Right-Click "Rename...": Project, PSE Or Alternative Of node (chessController.rename). Only The Active
            % Project (Locked By This Session), Never During A Run. The View Stays As It Was, Under The New Name
            level = node.NodeData.type;
            [pse_name, alt_name] = deal('');
            switch level
                case 'proj'
                    proj_node = node;
                case 'pse'
                    proj_node = node.Parent;
                    pse_name = node.NodeData.name;
                case 'alt'
                    proj_node = node.Parent.Parent;
                    pse_name = node.Parent.NodeData.name;
                    alt_name = node.NodeData.name;
            end
            proj_names = {app.controller.projects.name};
            proj = app.controller.projects(strcmp(proj_names, proj_node.NodeData.name));
            msg = app.controller.refusal(proj, 'Rename', 'renamed');
            if ~isempty(msg)
                app.auxLib.alert_dlgbox(msg, 'Rename', 'info');
                return
            end
            current = node.NodeData.name;
            stage = 0; % Multi-Line Alternative: Its Suffix Is Kept (chessProject.stage_name_problem)
            % parent_dir: Folder Holding The Item (A Folder Or File Of The New Name There Is Shown While Typing)
            switch level
                case 'proj'
                    siblings = proj_names(~strcmp(proj_names, current));
                    title_str = 'Rename Project';
                    prompt = sprintf('New name for project "%s":', current);
                    parent_dir = proj.path;
                case 'pse'
                    siblings = proj.pse_list(~strcmp(proj.pse_list, current));
                    title_str = 'Rename PSE';
                    prompt = sprintf('New name for PSE "%s":', current);
                    parent_dir = fullfile(proj.path, proj.name, 'PSE');
                case 'alt'
                    alts = proj.alternative_list{strcmp(proj.pse_list, pse_name)};
                    siblings = alts(~strcmp(alts, current));
                    title_str = 'Rename Alternative';
                    prompt = sprintf('New name for alternative "%s" (PSE %s):', current, pse_name);
                    parent_dir = fullfile(proj.path, proj.name, 'PSE', pse_name);
                    stage = proj.alt_stage(pse_name, alt_name);
                    if stage > 0
                        prompt = sprintf('%s\nMulti-line stage %d: keep the "%s" ending.', prompt, stage, chessProject.stage_suffix(stage));
                    end
            end
            app.auxLib.editfield_input_dlgbox(prompt, title_str, current, @name_check, 'Rename');
            new_name = app.auxLib.dialog_answer;
            if isempty(new_name)
                return
            end
            out = app.controller.rename(proj, level, new_name, pse_name, alt_name, siblings);
            msgs = app.controller.take_messages();
            if strcmp(out.status, 'error')
                app.auxLib.error_dlgbox(out.text);
            else
                app.refresh();
            end
            app.show_messages(msgs);

            function msg = name_check(v)
                msg = chessProject.name_problem(v, siblings, current, parent_dir);
                if isempty(msg)
                    msg = chessProject.stage_name_problem(v, stage);
                end
            end
        end

        function reset_empty_axes(app, ax)
            % [NEW] Empty Viewer Axes (Nothing Plotted): Full Reset, Then The Design View Look, So An Axes Cleared After A
            % Plot Looks The Same As At Startup. Plots Are Free To Restyle It
            cla(ax, 'reset');
            set(ax, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on', 'ZGrid', 'on', 'XMinorGrid', 'on', 'YMinorGrid', 'on',...
                'XMinorTick', 'on', 'YMinorTick', 'on');
            xlabel(ax, 'X Distance');
            ylabel(ax, 'Elevation');
        end

        function reset_results_axes(app)
            % [NEW] Clean Results Axes Between Plot Types (Plots, Colorbar, Legend, Rulers, Scales) & Keep Its Right-Click Menu
            ax = app.PSEAxes_3;
            app.hide_results_mirror();
            colorbar(ax, 'off');
            legend(ax, 'off');
            cla(ax, 'reset');
            ax.ContextMenu = app.resultsMenu;
        end

        function reset_tab(app, tab_to_reset)
            switch tab_to_reset
                case 'pse'
                    %%% PSE Tab
                    app.reset_empty_axes(app.PSEAxes);
                    app.PSETable.Data = cell(0, 4);
                case 'db'
                    %%% Storm Database Tab
                    app.reset_empty_axes(app.StormDBAxes);
                    app.StormDBDropDown.Items = {}; % Reset Items For All Dropdowns
                    app.StormIDDropDown.Items = {};
                    app.FieldToPlotDropDown.Items = {};
                    app.MatchTypeDropDown.Items = {};
                    app.DataTypeDropDown.Items = {};
                    app.StormTypeDropDown.Items = {};
                    app.StormDBTable.Data = cell(0, 2);
                case 'sim'
                    %%% CHESS Run Tab
                    app.ApplyDepthLimitationCheckBox.Value = false; % Reset Depth Limitation
                    app.SeaLevelChangeEditField.Value = 0; % Reset Sea Level Change
                    app.StormDBDropDown_run.Items = {}; % Reset Items On Dropdowns
                    app.StormTypeDropDown_2.Items = {};
                    app.TidesFileDropDown.ItemsData = {};
                    app.TidesFileDropDown.Items = {'None'};
                    delete(app.ResponsesTree.Children); % Reset Checkbox Trees
                    delete(app.DataTypesTree.Children);
                    app.WorkflowInputsTable.Data = cell(0, 3);
                    app.RunSimulationButton.Enable = false; % Disable Run Button
                    for comp = {app.StormTypeDropDown_2, app.SeaLevelChangeEditField, app.TidesFileDropDown, app.DataTypesTree}
                        comp{1}.Enable = true; % Multi-Line Locks Off (apply_multiline_locks)
                    end
                case 'results'
                    %%% CHESS Results Viewer Tab
                    app.reset_results_axes(); % Clear Axis (Plots, Colorbar, Legend, Rulers)
                    app.reset_empty_axes(app.PSEAxes_3); % Empty State:
                    app.PSETable_3.Data = cell(0, 3); % Clear Data Table
                    app.PlotTypeDropDown.ItemsData = {};
                    app.PlotTypeDropDown.Items = {};
                    app.StormIDDropDown_results.Items = {}; % Reset Storm ID
                    app.FieldToPlotDropDown_results.Items = {};
                    app.MatchTypeDropDown_results.Items = {};
                    app.DataTypeDropDown_results.Items = {};
                    app.StormTypeDropDown_results.Items = {};
                    app.Panel_2.Enable = false; % Make Sure To Disable All Items For New Project
            end
        end

        function results_control_changed(app, src)
            % [NEW] Results Dropdown Changed (Assigned In startupFcn): Refresh Dependent Dropdowns, Then Redraw.
            % Multi-Panel Plots Open (Or Refresh) The Results Pop-Out Automatically.
            levels = {app.PlotTypeDropDown, 'plot'; app.DataTypeDropDown_results, 'data'; app.MatchTypeDropDown_results, 'match';...
                app.StormTypeDropDown_results, 'storm'; app.FieldToPlotDropDown_results, 'field'};
            for ll = 1:size(levels, 1)
                if isequal(src, levels{ll, 1})
                    app.update_results_controls(levels{ll, 2});
                end
            end
            app.plot_project_responses();
            row = app.results_plot_row();
            if ~isempty(row) && row.multi_panel
                app.open_results_popout();
            end
        end

        function fits = results_mirror_fits(app, row)
            % [NEW] Does The Results Plot Cell (StormDBViewerGrid_2 Row 1) Reach The Plot's Minimum Mirror Size?
            % The Cell Is Derived From The Results Tab Size: After A Resize The Grid's Own Positions Are Still The Old Ones
            % In The Tab's SizeChangedFcn, The Tab Size Is Already The New One
            gl = app.StormDBViewerGrid_2;
            tab = app.ResultsViewerTab.Position;
            rows = gl.RowHeight;
            is_fixed = cellfun(@isnumeric, rows);
            weights = cellfun(@(r) str2double(erase(r, 'x')), rows(~is_fixed));
            free_h = tab(4) - gl.Padding(2) - gl.Padding(4) - gl.RowSpacing*(numel(rows) - 1) - sum([rows{is_fixed}]);
            cell_size = [tab(3) - gl.Padding(1) - gl.Padding(3), free_h*weights(1)/sum(weights)]; % Row 1 Is Weighted
            fits = all(cell_size >= app.results_mirror_min_size(row.key));
        end

        function sz = results_mirror_min_size(app, key)
            % [NEW] Minimum Results Plot Cell [Width Height] (px) To Also Draw A Multi-Panel Plot In The Tab (Inf: Pop-Out Only)
            switch key
                case 'event'
                    sz = [560 420];
                case {'dashboard', 'scheme'}
                    sz = [1000 600];
                otherwise % det_table: Its Own Table Window
                    sz = [Inf Inf];
            end
        end

        function results_plot_options_dialog(app)
            % [NEW] Right-Click "Plot Options...": Library Plot Arguments Not Covered By The Dropdowns (Session Only)
            row = app.results_plot_row();
            if isempty(row)
                return
            end
            if isempty(row.options)
                app.auxLib.alert_dlgbox(['"' row.label '" has no plot options.'], 'Plot Options', 'info');
                return
            end
            opts = app.get_results_options(row.key);
            n_opt = numel(row.options);
            fig = uifigure('Name', ['Plot Options: ' row.label], 'WindowStyle', 'modal', 'Visible', 'off', 'Position', [100 100 460 70 + 32*n_opt]);
            app.auxLib.center_on_parent(fig);
            gl = uigridlayout(fig, [n_opt + 1, 2]);
            gl.ColumnWidth = {'1x', 190};
            gl.RowHeight = [repmat({22}, 1, n_opt), {'fit'}];
            ctrl = struct();
            for oo = 1:n_opt
                switch row.options{oo}
                    case 'bin_edges'
                        lbl = 'Bin Edges (blank = auto):';
                        c = uieditfield(gl, 'text', 'Value', num2str(opts.bin_edges), 'Placeholder', 'e.g. 0 0.5 1 2  or  0:0.5:5');
                    case 'cb_lim'
                        lbl = 'Colorbar Limits (blank = auto):';
                        c = uieditfield(gl, 'text', 'Value', num2str(opts.cb_lim), 'Placeholder', 'min max');
                    case 'grid_on'
                        lbl = 'Grid:';
                        c = uicheckbox(gl, 'Text', '', 'Value', opts.grid_on);
                    case 'cb_log'
                        lbl = 'Log Colorbar:';
                        c = uicheckbox(gl, 'Text', '', 'Value', opts.cb_log);
                    case 'c_field' % Deterministic Scatter Color Variable
                        lbl = 'Color By:';
                        ds_query = struct('storm_type', app.StormTypeDropDown_results.Value,...
                            'data_type', app.DataTypeDropDown_results.Value, 'match_type', app.MatchTypeDropDown_results.Value);
                        c_items = app.controller.det_fields(aux_methods.pull_data(ds_query, app.controller.results.Resp));
                        c = uidropdown(gl, 'Items', c_items);
                        if any(strcmp(c_items, opts.c_field))
                            c.Value = opts.c_field;
                        elseif any(strcmp(c_items, 'Hm0_toe'))
                            c.Value = 'Hm0_toe';
                        end
                end
                c.Layout.Row = oo;
                c.Layout.Column = 2;
                l = uilabel(gl, 'Text', lbl);
                l.Layout.Row = oo;
                l.Layout.Column = 1;
                ctrl.(row.options{oo}) = c;
            end
            btn_gl = uigridlayout(gl, [1 3], 'Padding', [0 0 0 0]);
            btn_gl.Layout.Row = n_opt + 1;
            btn_gl.Layout.Column = [1 2];
            btn_gl.RowHeight = {'fit'};
            uibutton(btn_gl, 'Text', 'Reset To Defaults', 'ButtonPushedFcn', @(~, ~) finish('reset'));
            uibutton(btn_gl, 'Text', 'Cancel', 'ButtonPushedFcn', @(~, ~) finish('cancel'));
            ok_btn = uibutton(btn_gl, 'Text', 'OK', 'ButtonPushedFcn', @(~, ~) finish('ok'));
            fig.CloseRequestFcn = @(~, ~) finish('cancel');
            app.auxLib.add_dialog_keys(fig, @() finish('ok'), @() finish('cancel'), ok_btn);
            redraw = false;
            fig.Visible = 'on';
            uiwait(fig);
            if isvalid(fig)
                delete(fig);
            end
            % Redraw With The New Options (Tab, Or Pop-Out For Multi-Panel Plots)
            if redraw
                app.plot_project_responses();
                if row.multi_panel
                    app.open_results_popout();
                end
            end

            function finish(action)
                switch action
                    case 'ok'
                        new_opts = opts;
                        names = fieldnames(ctrl);
                        for kk = 1:numel(names)
                            val = ctrl.(names{kk}).Value;
                            switch names{kk}
                                case {'bin_edges', 'cb_lim'}
                                    val = app.parse_numeric_list(val);
                                    bad = any(isnan(val)) ||...
                                        (strcmp(names{kk}, 'cb_lim') && ~isempty(val) && (numel(val) ~= 2 || val(1) >= val(2))) ||...
                                        (strcmp(names{kk}, 'bin_edges') && any(diff(val) <= 0));
                                    if bad
                                        uialert(fig, 'Bin edges must be increasing numbers; colorbar limits must be "min max" with min < max.', 'Invalid Input');
                                        return
                                    end
                            end
                            new_opts.(names{kk}) = val;
                        end
                        app.resultsPlotOptions.(row.key) = new_opts;
                        redraw = true;
                    case 'reset'
                        if isfield(app.resultsPlotOptions, row.key)
                            app.resultsPlotOptions = rmfield(app.resultsPlotOptions, row.key);
                        end
                        redraw = true;
                end
                uiresume(fig);
            end
        end

        function row = results_plot_row(app)
            % [NEW] Catalog Row Of The Selected Plot Type ([] If None)
            row = [];
            if isempty(app.controller.results) || isempty(app.PlotTypeDropDown.Items)
                return
            end
            cat = app.controller.plot_catalog();
            row = cat(strcmp({cat.key}, app.PlotTypeDropDown.Value));
        end

        function results_tab_resized(app)
            % [NEW] Results Tab SizeChangedFcn (Set In startupFcn): Redraw A Shown Multi-Panel Plot Only When It Starts Or
            % Stops Fitting The Tab (A Fitting Mirror Rescales With Its Grid), So Dragging The Window Does Not Redraw It
            row = app.results_plot_row();
            if isempty(app.resultsMirrorFits) || isempty(row) || ~row.multi_panel
                return
            end
            if app.results_mirror_fits(row) ~= app.resultsMirrorFits
                app.plot_project_responses();
            end
        end

        function run_simulation(app, plan)
            % Run A chessController.plan_run Plan (execute_run) With An App-Scoped Progress Dialog (Locks The CHESS Window
            % Only), Then Show The Results Of The Current Key. The Inputs Table Shows An mcs_nLC Set By The LCS Convergence
            % Question First. Failed: The Error Dialog Only (Slot Restored By The Controller). Done: Tree, Results Tab,
            % Status Bar (How The Forcing Was Obtained), Then One Warning If The Project Update Failed
            if ismember('inputs_table', app.controller.take_changed())
                tbl = app.WorkflowInputsTable.Data;
                for kk = 1:size(tbl, 1)
                    if isfield(app.controller.inputs, tbl{kk, 1})
                        tbl{kk, 3} = app.controller.inputs.(tbl{kk, 1});
                    end
                end
                app.WorkflowInputsTable.Data = tbl;
                app.set_input_table();
            end
            prog = [];
            res = app.controller.execute_run(plan, @progress);
            if ~isempty(prog) && isvalid(prog)
                close(prog);
            end
            msgs = app.controller.take_messages();
            if strcmp(res.status, 'failed')
                app.show_messages(msgs);
                return
            end
            if ismember('tree', app.controller.take_changed()) % New Simulation Bundle Node
                try
                    app.update_project_tree();
                catch
                end
            end
            app.push_inputs();
            app.controller.use_key();
            app.populateResultsTab();
            app.set_sim_status(res.status_text);
            app.TabGroup.SelectedTab = app.ResultsViewerTab;
            app.show_messages(msgs);

            function progress(value, message)
                % Bar Created At The First Step, Never Moves Back
                if isempty(prog)
                    prog = uiprogressdlg(app.UIFigure, 'Title', 'CHESS Simulation Progress', 'Message', message, 'Value', value);
                elseif isvalid(prog)
                    set(prog, 'Value', max(prog.Value, value), 'Message', message);
                end
            end
        end

        function [tf, label, run_date] = saved_sim(app)
            % [NEW] Saved Simulation Of The Run Tab Selection (chessController.saved_sim)
            app.push_inputs();
            [tf, label, run_date] = app.controller.saved_sim();
        end

        function set_dropdown_items(app, dd, items)
            % [NEW] Replace Dropdown Items, Keeping The Current Value When Still Available
            prev = dd.Value;
            items = cellstr(items(:)');
            if isempty(items)
                items = {'-'};
            end
            dd.Items = items;
            if ischar(prev) && any(strcmp(items, prev))
                dd.Value = prev;
            end
        end

        function set_input_table(app)
            % Light Update (No Tree Rebuild): Multi-Line Locks, Inputs Table Rows, Run Button, State Snapshot
            [s1_row, ml_msg] = app.apply_multiline_locks();
            app.populate_inputs_table();
            % Multi-Line Stage 2: Inputs Describing Stage 1's Forcing Shown From Its Run (Registry Row inherited, Library
            % multiline_inherited_fields; Not Editable: WorkflowInputsTableCellEdit)
            if ~isempty(s1_row)
                for fld = fieldnames(s1_row.inherited)'
                    row = strcmp(app.WorkflowInputsTable.Data(:, 1), fld{1});
                    if any(row)
                        app.WorkflowInputsTable.Data{row, 3} = s1_row.inherited.(fld{1});
                        app.controller.set_input(fld{1}, s1_row.inherited.(fld{1}));
                    end
                end
            end
            % Run Needs A Response, A Data Type, And Workflow Inputs Defined For This PSE Type; Multi-Line Stage 2 Also Its Stage 1 Run
            has_inputs = true;
            if app.WorkflowDropDown.Value == 3
                has_inputs = any(strcmp(app.WorkflowInputsTable.Data(:, 1), 'mcs_nLC'));
            end
            app.push_inputs();
            db_msg = app.controller.stormdb_note();
            app.RunSimulationButton.Enable = has_inputs && ~isempty(app.ResponsesTree.CheckedNodes) &&...
                ~isempty(app.DataTypesTree.CheckedNodes) && isempty(ml_msg) && isempty(db_msg);
            app.get_sim_state();
            % Status Bar Follows Run Tab Edits (set_sim_status Shows A Missing Storm DB File Or Stage 1 Run First)
            if ~isempty(ml_msg) || ~isempty(db_msg)
                app.set_sim_status('');
            elseif ~isempty(app.controller.results)
                app.set_sim_status(app.controller.results_status());
            end
        end

        function set_sim_state(app, opMode, config_file)
            % opMode: 1 - Snapshot (chessController.snapshot), 2 - Saved Config, 3 - Keep Current Inputs In A New Context (Snapshot Mapped To
            % The Active PSE's Library Template). Inputs Table Values Live In controller.inputs (All Workflows), Table Shows The Pertinent Rows
            [pse_name, alt_name] = app.controller.active_names();
            switch opMode
                case 1 % Snapshot (controller.inputs Kept As Is)
                    restore_snapshot({});
                case 2 % With Config
                    S = load(config_file, 'config');
                    config = app.controller.localize_saved_config(S.config);
                    set_value(app.StormDBDropDown_run, config.storm_db);
                    set_value(app.StormTypeDropDown_2, config.storm_sampling);
                    set_value(app.TidesFileDropDown, config.tide_file);
                    app.ApplyDepthLimitationCheckBox.Value = logical(config.apply_depth_limitation);
                    app.SeaLevelChangeEditField.Value = config.swl_slr;
                    % Responses: Checked Where Config Switch Is On
                    resp = app.get_tree_symbols(app.ResponsesTree);
                    set_checked(app.ResponsesTree, resp(cellfun(@(x) isfield(config, x) && config.(x) == 1, resp)));
                    % Data Types
                    dt = {};
                    if config.use_peaks == 1, dt = [dt, {'peaks_default'}]; end
                    if config.create_wlp == 1, dt = [dt, {'create_wlp'}]; end
                    if config.create_whp == 1, dt = [dt, {'create_whp'}]; end
                    if config.use_timeseries == 1, dt = [dt, {'use_timeseries'}]; end
                    set_checked(app.DataTypesTree, dt);
                    % Inputs Of Every Workflow From Config
                    pse_geo = app.controller.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                    tpl = app.controller.project.get_library_template(pse_geo.pse_type);
                    is_param = ~startsWith(tpl.responses(:, 2), 'Comput');
                    inputs = [{'storm_duration'}; tpl.responses(is_param, 1); tpl.mcs(:, 1); tpl.csr(:, 1); tpl.pros(:, 1)];
                    app.controller.clear_table_inputs();
                    app.WorkflowInputsTable.Data = cell(0, 3); % Else populate_inputs_table Stores The Visible (Previous) Values Over The Config's
                    for kk = 1:length(inputs)
                        if isfield(config, inputs{kk})
                            app.controller.set_input(inputs{kk}, config.(inputs{kk}));
                        end
                    end
                case 3 % Keep Current Inputs: Snapshot Values Where The Template Has The Response/Row (PSE Type Can Differ),
                    % Template Defaults Only For Responses, Data Types And Rows The Previous State Lacked
                    restore_snapshot({'StormDBDropDown_run'}); % New Context: Storm DB Already Chosen (populateSimulationTab)
                    pse_geo = app.controller.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                    tpl = app.controller.project.get_library_template(pse_geo.pse_type);
                    on = tpl.responses(cellfun(@(x) isequal(x, 1), tpl.responses(:, 4)), 1);
                    set_checked(app.ResponsesTree, [app.get_checked_symbols(app.ResponsesTree), setdiff(on(:)', snapshot_value('ResponseSymbols'))]);
                    gen = tpl.general;
                    is_on = @(s) any(strcmp(gen(:, 1), s)) && isequal(gen{strcmp(gen(:, 1), s), 4}, 1);
                    dt = {};
                    if is_on('use_peaks'), dt = [dt, {'peaks_default'}]; end
                    if is_on('create_wlp'), dt = [dt, {'create_wlp'}]; end
                    if is_on('create_whp'), dt = [dt, {'create_whp'}]; end
                    if is_on('use_timeseries'), dt = [dt, {'use_timeseries'}]; end
                    set_checked(app.DataTypesTree, [app.get_checked_symbols(app.DataTypesTree), setdiff(dt, snapshot_value('DataTypeSymbols'))]);
                    % Inputs: Visible Values Stored First, Then Only The Rows Of This Template Are Kept
                    app.store_table_values();
                    is_param = ~startsWith(tpl.responses(:, 2), 'Comput');
                    inputs = [{'storm_duration'}; tpl.responses(is_param, 1); tpl.mcs(:, 1); tpl.csr(:, 1); tpl.pros(:, 1)];
                    app.controller.drop_inputs(setdiff(app.controller.table_fields(), inputs));
                    app.WorkflowInputsTable.Data = cell(0, 3);
            end
            % Rebuild Inputs Table For Restored Checks & Workflow
            app.populate_inputs_table();

            function restore_snapshot(skip)
                % Run Tab Controls From The Snapshot (Component Name, Value), Except skip
                winState = app.controller.snapshot.values;
                for ii = 1:size(winState, 1)
                    switch winState{ii, 1}
                        case [{'ResponseSymbols', 'DataTypeSymbols'}, skip]
                        case {'ResponsesTree', 'DataTypesTree'}
                            set_checked(app.(winState{ii, 1}), winState{ii, 2});
                        otherwise
                            if ~isempty(winState{ii, 2}) && ~any(strcmp(winState{ii, 2}, {'-','None'}))
                                set_value(app.(winState{ii, 1}), winState{ii, 2});
                            end
                    end
                end
            end
            function v = snapshot_value(name)
                % Snapshot Entry ({} If Absent)
                v = {};
                snap = app.controller.snapshot.values;
                if ~isempty(snap) && any(strcmp(snap(:, 1), name))
                    v = snap{strcmp(snap(:, 1), name), 2};
                end
            end

            function set_checked(tree, symbols)
                % Check Nodes (Any Level) Whose NodeData Is In symbols
                nodes = app.get_tree_nodes(tree);
                if ~isempty(nodes) && ~isempty(symbols)
                    nodes = nodes(ismember({nodes.NodeData}, symbols));
                end
                if isempty(nodes) || isempty(symbols)
                    tree.CheckedNodes = []; % R2022b Rejects An Empty TreeNode Array (No Remembered Node In The Rebuilt Tree)
                else
                    tree.CheckedNodes = nodes;
                end
            end
            function set_value(comp, value)
                % Dropdowns: Set Only If Available (ItemsData When Defined). Other Components: Set Directly
                if isprop(comp, 'Items')
                    if iscell(comp.ItemsData) && ~isempty(comp.ItemsData) % e.g. Tide Files (Paths)
                        valid = any(cellfun(@(x) isequal(x, value), comp.ItemsData));
                    elseif ~isempty(comp.ItemsData)
                        valid = isnumeric(value) && ismember(value, comp.ItemsData);
                    else
                        valid = any(strcmp(comp.Items, value));
                    end
                    if valid
                        comp.Value = value;
                    end
                else
                    comp.Value = value;
                end
            end
        end

        function set_sim_status(app, msg)
            % [NEW] Run Tab Status Bar (Display Only): msg, Or Why The Run Tab Cannot Run (chessController.status)
            app.push_inputs();
            app.simStatusBar.Value = app.controller.status(msg);
            app.controller_done();
        end

        function show_messages(app, msgs)
            % chessController Messages (Default: The Queued Ones), In Order: 'error' -> Error Dialog, 'warning' / 'info' -> Alert
            % (auxLib), 'status' -> Run Tab Status Bar
            if nargin < 2
                msgs = app.controller.take_messages();
            end
            for mm = 1:numel(msgs)
                switch msgs(mm).severity
                    case 'error'
                        app.auxLib.error_dlgbox(msgs(mm).text);
                    case 'status'
                        app.simStatusBar.Value = msgs(mm).text;
                    otherwise
                        app.auxLib.alert_dlgbox(msgs(mm).text, msgs(mm).title, msgs(mm).severity);
                end
            end
        end

        function show_popout_note(app, row)
            % [NEW] Multi-Panel Results Plot Not Drawn In The Tab: Grey Out The Tab Axes With A Note (+ Resize Hint If The
            % Plot Can Be Mirrored In A Bigger Window)
            ax = app.PSEAxes_3;
            ax.Color = [0.92 0.92 0.92];
            ax.XTick = [];
            ax.YTick = [];
            note = {'Multi-panel plot', 'Shown in the pop-out window'};
            if all(isfinite(app.results_mirror_min_size(row.key)))
                note{end + 1} = 'Enlarge the CHESS window to show it here';
            end
            text(ax, 0.5, 0.5, note, 'Units', 'normalized', 'HorizontalAlignment', 'center',...
                'FontSize', app.plotFontSize, 'Color', [0.45 0.45 0.45], 'ContextMenu', app.resultsMenu);
        end

        function rows = sim_rows(app, proj, pse_name, alt_name)
            % Registry Rows Of An Alternative Of proj (chessController.sim_rows: Repairs The Active Project's Registry), Then
            % Its Status Note And Multi-Line Stage 1 Drift Questions (controller_done)
            rows = app.controller.sim_rows(proj, pse_name, alt_name);
            app.controller_done();
        end

        function key = sim_key(app)
            % [NEW] Saved Simulation Key Of The Run Tab Selection (chessController.sim_key)
            app.push_inputs();
            key = app.controller.sim_key();
        end

        function store_table_values(app)
            % [NEW] Save Visible Inputs Table Values Into controller.inputs
            tbl = app.WorkflowInputsTable.Data;
            for kk = 1:size(tbl, 1)
                app.controller.set_input(tbl{kk, 1}, tbl{kk, 3});
            end
        end

        function sync_saved_sim(app, ask)
            % [NEW] After A Switch Of Alternative / Workflow / Run Tab Storm DB: The Saved Simulation Of The New Key Loaded,
            % Asked About (ask: "Load" | "Keep current inputs") Or Declined (chessController.sync_saved). The Callers'
            % populateResultsTab Loads Nothing While The Key Differs, So Results Appear Only Once Resolved Here
            app.push_inputs();
            out = app.controller.sync_saved(ask);
            app.controller_done();
            if strcmp(out.status, 'ask')
                out = app.controller.sync_saved(ask, struct('load_saved', {app.ask_question(out.question)}));
                app.controller_done();
            end
            switch out.status
                case 'load'
                    app.load_saved_sim();
                case 'declined'
                    app.reset_tab('results');
            end
        end

        function proj = tree_node_project(app, node)
            % Project Of A Project Tree Node (Any Level)
            while ~strcmp(node.NodeData.type, 'proj')
                node = node.Parent;
            end
            proj = app.controller.projects(strcmp({app.controller.projects.name}, node.NodeData.name));
        end

        function tree_show_level(app, level)
            % Project Tree Right-Click Expand/Collapse: Nodes Down To level Shown (1 Projects, 2 PSEs, 3 Alternatives,
            % 4 All, Simulation Bundles Included)
            if level == 4
                expand(app.ProjectTree, 'all');
                return
            end
            collapse(app.ProjectTree, 'all');
            nodes = app.ProjectTree.Children(:);
            for lvl = 2:level
                for nn = 1:numel(nodes)
                    expand(nodes(nn));
                end
                nodes = vertcat(nodes.Children);
            end
        end

        function update_project_tree(app)
            % Project Tree: Project > PSE > Alternative > Simulation Bundle Nodes. NodeData: type ('proj' | 'pse' | 'alt' | 'sim')
            % And name (Item Name; An Alternative's Text Adds A Multi-Line Stage Marker). Bundles From The Registry (sim_rows: One
            % isfile Each, No Folder Scan); A Stale Multi-Line Stage 2 Bundle (sim_is_stale) Is Marked '[stale]'
            % Clear Project Tree (And The Nodes' Right-Click Menus, Which Belong To The Figure)
            delete(app.ProjectTree.Children);
            delete(findall(app.UIFigure, 'Type', 'uicontextmenu', 'Tag', 'ProjectTreeNodeMenu'));
            act_node = [];
            [act_pse, act_alt] = app.controller.active_names();
            for kk = 1:length(app.controller.projects)
                wObj = app.controller.projects(kk);
                % Create Project Node
                proj_node = uitreenode(app.ProjectTree, 'Text', wObj.name,...
                    'NodeData', struct('type', 'proj', 'name', wObj.name));
                add_node_menu(proj_node);
                if wObj == app.controller.project
                    act_node = proj_node;
                end
                % Loop Across PSEs (Read Lists Directly, No Working Index Side Effects)
                for jj = 1:length(wObj.pse_list)
                    pse_node = uitreenode(proj_node, 'Text', wObj.pse_list{jj},...
                        'NodeData', struct('type', 'pse', 'name', wObj.pse_list{jj}));
                    add_node_menu(pse_node);
                    if wObj == app.controller.project && strcmp(wObj.pse_list{jj}, act_pse)
                        act_node = pse_node;
                    end
                    s1_rows = [];
                    if wObj.is_multiline(wObj.pse_list{jj})
                        s1_rows = app.sim_rows(wObj, wObj.pse_list{jj}, wObj.stage1_alt(wObj.pse_list{jj}));
                    end
                    % Loop Across Alternatives
                    altList = wObj.alternative_list{jj};
                    for ii = 1:length(altList)
                        % Multi-Line Alternatives: Stage Marker In The Text (Names Are Read From NodeData.name)
                        alt_text = altList{ii};
                        stage = wObj.alt_stage(wObj.pse_list{jj}, altList{ii});
                        if stage > 0
                            alt_text = sprintf('%s  [multi-line stage %d]', alt_text, stage);
                        end
                        alt_node = uitreenode(pse_node, 'Text', alt_text,...
                            'NodeData', struct('type', 'alt', 'name', altList{ii}));
                        add_node_menu(alt_node);
                        if wObj == app.controller.project && strcmp(wObj.pse_list{jj}, act_pse) && strcmp(altList{ii}, act_alt)
                            act_node = alt_node;
                        end
                        % Simulation Bundles (Storm DB | Workflow), Display Only
                        rows = app.sim_rows(wObj, wObj.pse_list{jj}, altList{ii});
                        for ss = 1:numel(rows)
                            label = chessProject.sim_label(rows(ss));
                            sim_text = label;
                            if stage == 2 && app.controller.sim_is_stale(rows(ss), s1_rows)
                                sim_text = [label '  [stale]'];
                            end
                            sim_node = uitreenode(alt_node, 'Text', sim_text,...
                                'NodeData', struct('type', 'sim', 'name', label, 'label', label));
                            add_node_menu(sim_node);
                        end
                    end
                end
            end
            % Highlight Active Node
            if ~isempty(act_node)
                expand(app.ProjectTree, 'all');
                app.ProjectTree.SelectedNodes = act_node;
            end

            function add_node_menu(node)
                % One Menu Per Node: R2022b ContextMenuOpeningFcn Event Data Does Not Say Which Tree Node Was Right-Clicked
                cm = uicontextmenu(app.UIFigure, 'Tag', 'ProjectTreeNodeMenu');
                switch node.NodeData.type
                    case {'proj', 'pse'}
                        uimenu(cm, 'Text', 'Rename...', 'MenuSelectedFcn', @(~, ~) app.rename_tree_node(node));
                        uimenu(cm, 'Text', 'Expand all', 'Separator', 'on', 'MenuSelectedFcn', @(~, ~) app.tree_show_level(4));
                        uimenu(cm, 'Text', 'Collapse to projects', 'MenuSelectedFcn', @(~, ~) app.tree_show_level(1));
                        uimenu(cm, 'Text', 'Collapse to PSEs', 'MenuSelectedFcn', @(~, ~) app.tree_show_level(2));
                        uimenu(cm, 'Text', 'Collapse to alternatives', 'MenuSelectedFcn', @(~, ~) app.tree_show_level(3));
                        if strcmp(node.NodeData.type, 'proj')
                            uimenu(cm, 'Text', 'Rebuild simulations from disk', 'Separator', 'on',...
                                'MenuSelectedFcn', @(~, ~) app.rebuild_sims(app.tree_node_project(node)));
                        end
                    case 'alt'
                        uimenu(cm, 'Text', 'Rename...', 'MenuSelectedFcn', @(~, ~) app.rename_tree_node(node));
                        uimenu(cm, 'Text', 'Remove simulations...', 'MenuSelectedFcn', @(~, ~) app.remove_alt_sims(...
                            app.tree_node_project(node), node.Parent.NodeData.name, node.NodeData.name, ''));
                    case 'sim'
                        uimenu(cm, 'Text', 'Remove simulation...', 'MenuSelectedFcn', @(~, ~) app.remove_alt_sims(...
                            app.tree_node_project(node), node.Parent.Parent.NodeData.name, node.Parent.NodeData.name, node.NodeData.label));
                end
                node.ContextMenu = cm;
            end
        end

        function update_results_controls(app, level)
            % [NEW] Results Dropdowns Follow The Selected Plot Type (Library Method Inputs).
            %   Data/Match/Storm Type -> ds_query | Field To Plot -> Response (Or Relabeled Option) | Storm ID -> Event, Life Cycle Or Option
            %   level: 'plot' | 'data' | 'match' | 'storm' | 'field' (Control That Changed; Dependent Controls Below It Refresh)
            row = app.results_plot_row();
            if isempty(row)
                return
            end
            Resp = app.controller.results.Resp;
            lvl = find(strcmp(level, {'plot', 'data', 'match', 'storm', 'field'}));
            if lvl <= 1
                app.set_dropdown_items(app.DataTypeDropDown_results, row.data_types);
            end
            dt = app.DataTypeDropDown_results.Value;
            if lvl <= 2
                app.set_dropdown_items(app.MatchTypeDropDown_results, fieldnames(Resp.(dt)));
            end
            mt = app.MatchTypeDropDown_results.Value;
            if lvl <= 3
                st_list = fieldnames(Resp.(dt).(mt))';
                if strcmp(row.key, 'event') % Event Viewer Reads The Storm DB (XC/TC Only; CC Is Derived): Its Record's layout
                    lay = app.controller.results.dbObj.layout;
                    if isempty(lay) % Storm DB File Missing Or Unreadable: No Event To Show
                        st_list = {};
                    else
                        st_list = st_list(cellfun(@(s) isfield(lay.match_types, s) && isfield(lay.match_types.(s), dt) &&...
                            any(strcmp(lay.match_types.(s).(dt), mt)), st_list));
                    end
                elseif row.needs_s % Damage Plots: Storm Types Whose Results Hold S (Same Test As results_field_items)
                    st_list = st_list(cellfun(@(s) isstruct(Resp.(dt).(mt).(s)) && isfield(Resp.(dt).(mt).(s), 'S'), st_list));
                end
                app.set_dropdown_items(app.StormTypeDropDown_results, st_list);
            end
            st = app.StormTypeDropDown_results.Value;
            if ~isfield(Resp.(dt).(mt), st) % '-': No Storm Type For This Plot (plot_project_responses Draws Nothing)
                app.set_dropdown_items(app.FieldToPlotDropDown_results, {});
                app.FieldToPlotDropDown_results.Enable = false;
                app.set_dropdown_items(app.StormIDDropDown_results, {});
                app.StormIDDropDown_results.Enable = false;
                return
            end
            data = Resp.(dt).(mt).(st);
            ds_query = struct('storm_type', st, 'data_type', dt, 'match_type', mt);
            % Field To Plot
            if lvl <= 4
                [f_lbl, f_items] = app.controller.field_items(row.key, data);
                app.FieldToPlotDropDown_2Label.Text = f_lbl;
                app.set_dropdown_items(app.FieldToPlotDropDown_results, f_items);
                app.FieldToPlotDropDown_results.Enable = ~isempty(f_items);
            end
            % Storm ID Dropdown (Event, Life Cycle Or Option)
            [a_lbl, a_items, a_on] = app.controller.aux_items(row.key, data, ds_query, app.FieldToPlotDropDown_results.Value);
            app.StormIDDropDown_2Label.Text = a_lbl;
            app.set_dropdown_items(app.StormIDDropDown_results, a_items);
            app.StormIDDropDown_results.Enable = a_on;
        end

    end



    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % One CHESS Window Per MATLAB Session: An Open One Is Brought To The Front And This One Closes
            open_fig = findall(groot, 'Type', 'figure', 'Tag', 'CHESS_UI');
            open_fig = open_fig(open_fig ~= app.UIFigure);
            if ~isempty(open_fig)
                figure(open_fig(1));
                delete(app);
                return
            end
            app.UIFigure.Tag = 'CHESS_UI';
            % Initialize Aux Library Class
            app.auxLib = auxUIFunctions();
            app.auxLib.set_parent(app.UIFigure); % auxLib Dialogs Open Centered On The CHESS Window
            % CHESS_Library Path: The App Lives In CHESS_Library\GUI, So The Library Is Its Parent Folder
            app_dir = fileparts(mfilename('fullpath'));
            lib_dir = fileparts(app_dir);
            if ~isfile(fullfile(lib_dir, 'Setup', 'create_structure_geometry.m'))
                app.auxLib.error_dlgbox(['CHESS_Library not found. The app must be located in CHESS_Library' filesep 'GUI.']);
            else
                addpath(genpath(lib_dir));
            end
            app.controller = chessController();
            % Constants Table (Columns Sized To Their Text; No Project Yet: '-' Rows)
            app.ConstantsTable.ColumnWidth = {'fit', 'fit', 'fit'};
            app.populate_constants_table();
            % Results Tab (Created In Code, No Design View Changes): Dropdown Callbacks, Right-Click Plot Options
            set([app.PlotTypeDropDown, app.StormTypeDropDown_results, app.DataTypeDropDown_results,...
                app.MatchTypeDropDown_results, app.FieldToPlotDropDown_results, app.StormIDDropDown_results],...
                'ValueChangedFcn', @(src, ~) app.results_control_changed(src));
            app.resultsMenu = uicontextmenu(app.UIFigure);
            uimenu(app.resultsMenu, 'Text', 'Plot Options...', 'MenuSelectedFcn', @(~, ~) app.results_plot_options_dialog());
            app.PSEAxes_3.ContextMenu = app.resultsMenu;
            app.resultsPlotOptions = struct();
            % Multi-Panel Results Plots Mirrored In The Tab (Same Grid Cell As PSEAxes_3) When It Is Big Enough; Fit Re-Checked
            % When The Results Tab Is Resized (SizeChangedFcn Needs AutoResizeChildren Off; The Tab's Only Child Is A Grid)
            app.resultsMirror = uipanel(app.StormDBViewerGrid_2, 'BorderType', 'none', 'Visible', 'off');
            app.resultsMirror.Layout.Row = 1;
            app.resultsMirror.Layout.Column = 1;
            app.ResultsViewerTab.AutoResizeChildren = 'off';
            app.ResultsViewerTab.SizeChangedFcn = @(~, ~) app.results_tab_resized();
            % Empty State
            app.refresh();
        end

        % Menu selected function: CreateNewProjectMenu
        function CreateNewProjectMenuSelected(app, event)
            % Call Project Creation UI (Loaded Project Names: A New Project Cannot Take One)
            proj_names = {};
            if ~isempty(app.controller.projects)
                proj_names = {app.controller.projects.name};
            end
            obj = ProjectCreationUI(app.UIFigure, proj_names);
            % Wait For UI Figure To Close
            uiwait(obj.uifig);
            % If User Submited Project, Lock It (lock_project), Then Populate UI
            if obj.project_created && app.lock_project(obj.chess_project)
                app.append_project(obj.chess_project);
                % Save Project State
                app.controller.save_project();
                % Long Project Folder Path (Windows 260-Character Limit): Warn, Project Kept
                if ~isempty(obj.path_warning)
                    app.auxLib.alert_dlgbox(obj.path_warning, 'Long Project Path', 'warning');
                end
            end
        end

        % Menu selected function: ImportProjectMenu
        function LoadProjectMenuSelected(app, event)
            % [NEW] Prompt User: Project File (CHESS_project_<name>.mat In Its Project Folder) Or Exported Project Archive (.zip)
            [file, location] = uigetfile({'*.mat;*.zip', 'CHESS Project (*.mat, *.zip)'}, 'Import CHESS Project', '');
            if isequal(file, 0)
                return
            end
            [~, ~, ext] = fileparts(file);
            try
                if strcmpi(ext, '.zip')
                    app.extract_project_zip(fullfile(location, file));
                else
                    app.import_project_mat(fullfile(location, file));
                end
            catch ME % e.g. An Unreadable Project File (import_project_mat Rolls Back Its Own Failures)
                app.auxLib.error_dlgbox(['Could not import the project: ' ME.message]);
            end
        end

        % Menu selected function: ExportProjectMenu
        function ExportProjectMenuSelected(app, event)
            if isempty(app.controller.project)
                return
            end
            % Wait For User To Define Export Location And Name
            [file, fPath] = uiputfile({'.zip'}, 'Export CHESS Project', ['CHESS_project_'  app.controller.project.name '_archive.zip']);
            % Export Project
            if ~all(file == 0)
                % Save out Project state
                app.controller.save_project();
                % Create Project Archive: <name>/ + The Region's CHS_Dependencies Files (chessProject.export_archive)
                try
                    note = app.controller.project.export_archive(fullfile(fPath, file));
                catch ME
                    app.auxLib.error_dlgbox(['Could not export the project: ' ME.message]);
                    return
                end
                app.set_sim_status(note);
            end
        end

        % Selection changed function: ProjectTree
        function ProjectTree_SelectionChanged(app, event)
            % Simulation Bundle Nodes Are Display Only: The Previous Selection Stays
            if strcmp(event.SelectedNodes.NodeData.type, 'sim')
                app.ProjectTree.SelectedNodes = event.PreviousSelectedNodes;
                return
            end
            % Resolve Clicked Node To Project/PSE/Alternative Names (NodeData.name: Alternative Texts Carry A Multi-Line Stage Marker)
            [proj_node, pse_node, alt_node] = app.get_node_family();
            % Another Project: Locked First (lock_project); Open In Another Session: Notice, The Previous Selection Stays
            if ~app.lock_project(app.tree_node_project(proj_node))
                app.ProjectTree.SelectedNodes = event.PreviousSelectedNodes;
                return
            end
            pse_name = '';
            alt_name = '';
            if ~isempty(pse_node)
                pse_name = pse_node.NodeData.name;
            end
            if ~isempty(alt_node)
                alt_name = alt_node.NodeData.name;
            end
            app.controller.select(proj_node.NodeData.name, pse_name, alt_name);
            app.refresh(true);
        end

        % Menu selected function: FloodwallMenu, LeveeMenu, 
        % ...and 2 other components
        function PSECreationMenuSelected(app, event)
            if isempty(app.controller.project)
                return
            end
            % Call PSE Creation UI; Created: Selected And Saved, Else The In-Progress PSE Removed (chessController.finish_element)
            obj = PSECreationUI(event.Source.Text, app.controller.project, '', app.UIFigure);
            uiwait(obj.uifig);
            app.controller.finish_element(obj.pse_created, obj.pse_name, obj.alt_name, 'pse');
            if obj.pse_created
                app.refresh();
            end
        end

        % Menu selected function: AlternativeMenu
        function AlternativeMenuSelected(app, event)
            % Get PSE List For Active Project
            pseList = app.controller.project.get_project_field('pse_list', '', '', 'proj');
            % Ask User For PSE Template
            app.auxLib.dropdown_input_dlgbox('Choose PSE to use as template for alternative.', pseList, 'Add New Alternative To Project PSE', 'OK');
            pse_name = app.auxLib.dialog_answer;
            if isempty(pse_name)
                return
            end
            % Multi-Line PSEs Hold Only Multi-Line Alternatives: Stage 2 Alternatives Come From The Multi-Line Transect Menu
            if app.controller.project.is_multiline(pse_name)
                app.auxLib.alert_dlgbox(sprintf(['PSE "%s" is a multi-line transect. Add a second-stage alternative with ',...
                    'Add Project Element > PSE > Multi-line Transect.'], pse_name), 'Add New Alternative To Project PSE', 'info');
                return
            end
            % PSE Type: The Active Alternative's When The Chosen PSE Is The Active One, Else The First Alternative's
            pse_geo = app.controller.project.get_project_field('pse_geometry', pse_name, '', 'pse');
            pse_type = pse_geo{1}.pse_type;
            [act_pse, act_alt] = app.controller.active_names();
            if strcmp(act_pse, pse_name) && ~isempty(act_alt)
                act_geo = app.controller.project.get_project_field('pse_geometry', pse_name, act_alt, 'alt');
                pse_type = act_geo.pse_type;
            end
            % Call PSE Creation UI; Created: Selected And Saved, Else The In-Progress Alternative Removed
            obj = PSECreationUI(pse_type, app.controller.project, pse_name, app.UIFigure);
            uiwait(obj.uifig);
            app.controller.finish_element(obj.pse_created, obj.pse_name, obj.alt_name, 'alt');
            if obj.pse_created
                app.refresh();
            end
        end

        % Menu selected function: RemoveAlternativeMenu, RemovePSEMenu, 
        % ...and 1 other component
        function RemoveProjectElem(app, event)
            if isempty(app.controller.project)
                return
            end
            % Not While A Run Writes Into The Project Folders
            if app.controller.runActive
                app.auxLib.alert_dlgbox('Removing is not available while a run is in progress.', 'Project Management: Remove', 'info');
                return
            end
            % PSE / Alternative: Confirmed, Then Its Folder Deleted; Tide File: Dropped (chessController.remove_element)
            proj = app.controller.project;
            switch event.Source.Text
                case 'PSE'
                    choices = proj.get_project_field('pse_list', '', '', 'proj');
                    if isempty(choices)
                        return
                    end
                    app.auxLib.dropdown_input_dlgbox(['Remove PSE from project ' proj.name '.'], choices, 'Project Management: Remove');
                    pse_name = app.auxLib.dialog_answer;
                    if isempty(pse_name)
                        return
                    end
                    app.auxLib.confirmation_dlgbox(sprintf('Remove PSE "%s" and delete its folder (all alternatives and run results)?',...
                        pse_name), 'Remove', 'Remove PSE');
                    if ~app.auxLib.dialog_answer
                        return
                    end
                    err = app.controller.remove_element('pse', pse_name, '');
                case 'Alternative'
                    choices = proj.get_project_field('pse_list', '', '', 'proj');
                    if isempty(choices)
                        return
                    end
                    app.auxLib.dropdown_input_dlgbox('Choose PSE.', choices, 'Project Management: Remove');
                    pse_name = app.auxLib.dialog_answer;
                    if isempty(pse_name)
                        return
                    end
                    choices = proj.get_project_field('alternative_list', pse_name, '', 'pse');
                    app.auxLib.dropdown_input_dlgbox(['Remove alternative from PSE ' pse_name '.'], choices, 'Project Management: Remove');
                    alt_name = app.auxLib.dialog_answer;
                    if isempty(alt_name)
                        return
                    end
                    app.auxLib.confirmation_dlgbox(app.controller.remove_alt_prompt(pse_name, alt_name), 'Remove', 'Remove Alternative');
                    if ~app.auxLib.dialog_answer
                        return
                    end
                    err = app.controller.remove_element('alt', pse_name, alt_name);
                case 'Tides'
                    tide_files = proj.get_project_field('tide_files_list', '', '', 'proj');
                    if isempty(tide_files)
                        return
                    end
                    [~, tide_names, tide_ext] = cellfun(@fileparts, tide_files, 'un', false); % Show File Names
                    app.auxLib.dropdown_input_dlgbox(['Remove tide file from project ' proj.name '.'], strcat(tide_names, tide_ext),...
                        'Project Management: Remove');
                    if isempty(app.auxLib.dialog_answer)
                        return
                    end
                    err = app.controller.remove_element('tide', '', app.auxLib.dialog_answer);
            end
            if ~isempty(err)
                app.auxLib.error_dlgbox(err);
                return
            end
            % Refresh, Then A Folder Not Fully Deleted
            msgs = app.controller.take_messages();
            app.refresh();
            app.show_messages(msgs);
        end

        % Value changed function: ProjectDropDown
        function ProjectDropDownValueChanged(app, event)
            % Project Locked First (lock_project); Open In Another Session: Notice, The Previous Project Stays Active
            if ~app.lock_project(app.controller.projects(strcmp({app.controller.projects.name}, app.ProjectDropDown.Value)))
                app.populate_project_panel();
                return
            end
            app.controller.select(app.ProjectDropDown.Value, '', '');
            app.refresh(true);
        end

        % Value changed function: PSEDropDown
        function PSEDropDownValueChanged(app, event)
            app.controller.select(app.ProjectDropDown.Value, app.PSEDropDown.Value, '');
            app.refresh(true);
        end

        % Value changed function: AlternativeDropDown
        function AlternativeDropDownValueChanged(app, event)
            app.controller.select(app.ProjectDropDown.Value, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            app.refresh(true);
        end

        % Button pushed function: Button_5, ExtrudeTableButton, 
        % ...and 1 other component
        function ExtrudeTableButtonPushed(app, event)
            % The Tab's Table (One Per Tab; The Button Sits In A Nested Grid, Not On The Tab)
            tab = ancestor(event.Source, 'matlab.ui.container.Tab');
            tbl = findobj(tab, '-isa', 'matlab.ui.control.Table');
            % Create new uifigure
            newFig = uifigure("WindowStyle","normal");
            % Create 1x1 grid layout
            gl = uigridlayout(newFig, [1, 1]);
            gl.RowHeight = {'1x'};
            gl.ColumnWidth = {'fit'};
            % Copy table properties
            newTbl = uitable(gl);
            newTbl.Data = tbl.Data;
            newTbl.ColumnName = tbl.ColumnName;
            newTbl.RowName = tbl.RowName;
            newTbl.ColumnEditable = tbl.ColumnEditable;
            if any(ismember(newTbl.ColumnName, 'model_var'))
                newTbl.ColumnName(ismember(newTbl.ColumnName, 'model_var'))=[];
            end
            newFig.Position(3) = newFig.Position(3)+25;
        end

        % Button pushed function: Button_6, ExtrudeFigureButton, 
        % ...and 1 other component
        function ExtrudeFigureButtonPushed(app, event)
            % Pop-Out: Redraw The Tab's Plot With Its CHESS-Library Plot Method In A Classic Figure
            base_fnt = app.plotFontSize; % Same Base Font As The Tab Plots
            tab = ancestor(event.Source, 'matlab.ui.container.Tab'); % Button Sits In A Nested Grid, Not On The Tab
            % Nothing To Plot -> Inform User (No Empty Figure)
            if isequal(tab, app.PSEViewerTab)
                ready = app.controller.has_active_alt();
            elseif isequal(tab, app.StormDBViewerTab)
                ready = ~isempty(app.StormDBDropDown.Items);
            elseif isequal(tab, app.ResultsViewerTab)
                ready = ~isempty(app.controller.results) && ~strcmp(app.StormTypeDropDown_results.Value, '-');
            else
                ready = false;
            end
            if ~ready
                app.auxLib.alert_dlgbox('There is nothing to plot on this tab yet.', 'Nothing To Plot', 'info');
                return
            end
            % Tab Plot Method In A Stand-Alone Classic Figure
            if isequal(tab, app.PSEViewerTab) % PSE Geometry (With Offshore Slope/Elevation Text Box)
                app.plot_pse_geometry(axes('Parent', figure()), base_fnt, true);
            elseif isequal(tab, app.StormDBViewerTab) % Peaks: Data Space | Timeseries: Event Hydrograph
                if app.db_info_ok(app.controller.project.get_project_field('stormDB_list', app.StormDBDropDown.Value, '', 'db'))
                    app.plot_storm_db(axes('Parent', figure()), base_fnt);
                end
            else % Results: Selected Plot Type (Multi-Panel Plots Reuse The Results Pop-Out)
                row = app.results_plot_row();
                if ~isempty(row) && row.multi_panel
                    app.open_results_popout();
                else
                    app.plot_project_responses(figure(), base_fnt);
                end
            end

        end

        % Menu selected function: ImportCHSStudyHDF5Menu
        function CHSDatabaseMenu(app, event)
            if isempty(app.controller.project)
                return
            end
            % Initialize CHS Library (The Project's CHS_Dependencies And Region: The Wizard Keeps Them). The Project's Storm DB
            % Names And Their Usage (Alternatives, Run Files): A Clash Is An Overwrite, Confirmed In The Wizard At Import
            proj = app.controller.project;
            paths = chess_paths(proj.path, proj.name);
            wizard = CHSStormDBImportUI(proj.chs_dependencies, paths.event_db_dir,...
                chessController.GRAVITY, proj.vdatum, proj.unitsys, app.UIFigure, proj.project_region(), {proj.stormDB_list.db_name},...
                @(name) [proj.stormdb_usage(name), numel(proj.stormdb_run_files(name))]);
            % Call import Wizard (A New Wizard Every Time; The Project Keeps Only Its Record, CHSStormDBImportUI.to_record)
            wizard.create_ui();
            uiwait(wizard.figUI); % Wait for uifigure to close
            if ~wizard.db_created
                return
            end
            % Record Into The Project (chessController.add_stormdb: Overwrite, CHS_Dependencies, Save)
            dbObj = wizard.to_record();
            app.controller.add_stormdb(dbObj, wizard.overwrite_flag, paths.event_db_dir);
            msgs = app.controller.take_messages();
            % Refresh UI & Show New DB On Storm DB Viewer
            app.refresh();
            app.populate_stormDB_panel(dbObj, {proj.stormDB_list.db_name});
            app.show_messages(msgs);
        end

        % Value changed function: FieldToPlotDropDown, MatchTypeDropDown, 
        % ...and 1 other component
        function updateStormDBPlot(app, event)
            % Match Type Changes Storm ID List: Refresh Panel (Which Replots)
            if ~isempty(event) && event.Source == app.MatchTypeDropDown
                app.StormDBDropDown_dbValueChanged(event);
                return
            end
            % Draw On Storm DB Tab (Axes + Table)
            app.plot_storm_db();
        end

        % Value changed function: StormDBDropDown
        function StormDBDropDown_dbValueChanged(app, event)
            %  Repopulate Storm DB Viewer Cascade For Selected DB
            dbObj = app.controller.project.get_project_field('stormDB_list', app.StormDBDropDown.Value, '', 'db');
            app.populate_stormDB_panel(dbObj, app.StormDBDropDown.Items);
        end

        % Value changed function: StormTypeDropDown
        function StormTypeDropDown_dbOpening(app, event)
            app.StormDBDropDown_dbValueChanged(event);
        end

        % Value changed function: DataTypeDropDown
        function DataTypeDropDown_dbOpening(app, event)
            app.StormDBDropDown_dbValueChanged(event);
        end

        % Value changed function: WorkflowDropDown
        function WorkflowDropDownValueChanged(app, event)
            % Inputs Table Rows Depend On Workflow; Results Are Per Workflow (Saved Simulation Of This Workflow Asked). Constants
            % Table: Uncertainty Rows Marked Unused By DET. Multi-Line Stage 2: Plot Of Stage 1's Run Of This Workflow
            app.controller.touch({'inputs_table', 'pse', 'constants', 'results'});
            app.refresh(true);
        end

        % Button pushed function: RunSimulationButton
        function RunSimulationButtonPushed(app, event)
            % Run In Progress Until This Callback Exits (chessController.run_guard: Project Tree Rename / Remove Refused; They
            % Could Run At A Queued-Event Point). Questions Of The Run Start (plan_run) Asked Here, Then The Run (run_simulation)
            run_flag = app.controller.run_guard(); %#ok<NASGU>
            app.push_inputs();
            app.controller.take_changed(); % Only The Flags Of This Run Are Read Below
            answers = struct();
            out = app.controller.plan_run(answers);
            app.controller_done();
            while strcmp(out.status, 'ask')
                answers.(out.question.id) = app.ask_question(out.question);
                out = app.controller.plan_run(answers);
                app.controller_done();
            end
            switch out.status
                case 'load'
                    app.load_saved_sim();
                case 'run'
                    app.run_simulation(out.plan);
            end
        end

        % Callback function: DataTypesTree, ResponsesTree
        function TreeCheckedNodesChanged(app, event)
            % Light Update: Inputs Table Rows & Run Button
            app.controller.touch({'inputs_table'});
            app.refresh();
        end

        % Value changed function: ApplyDepthLimitationCheckBox, 
        % ...and 4 other components
        function StormDBDropDown_runValueChanged(app, event)
            % Storm DB Change Rebuilds The Run Tab Controls (Data Types), Its Multi-Line Stage 2 Plot (Stage 1's Run Of This
            % Storm DB), Constants And Results (Saved Simulation Of This Storm DB Asked); Other Controls Only The Inputs Table
            if event.Source == app.StormDBDropDown_run
                app.controller.touch({'run_controls', 'pse', 'constants', 'results'});
                app.refresh(true);
            elseif app.controller.has_active_alt() % Without An Active Alternative There Are No Inputs To Refresh
                app.controller.touch({'inputs_table'});
                app.refresh();
            end
        end

        % Cell edit callback: WorkflowInputsTable
        function WorkflowInputsTableCellEdit(app, event)
            % [NEW] Only The Value Column Is Editable
            row = event.Indices(1);
            col = event.Indices(2);
            if col ~= 3
                app.WorkflowInputsTable.Data{row, col} = event.PreviousData;
                return
            end
            symbol = app.WorkflowInputsTable.Data{row, 1};
            val = event.NewData;
            % Multi-Line Stage 2: Inputs Of Stage 1's Forcing Come From Its Run (Library multiline_inherited_fields)
            [pse_name, alt_name] = app.controller.active_names();
            if app.controller.project.alt_stage(pse_name, alt_name) == 2 && ismember(symbol, multiline_inherited_fields())
                app.WorkflowInputsTable.Data{row, col} = event.PreviousData;
                app.auxLib.alert_dlgbox(sprintf('Multi-line stage 2: %s is taken from the stage 1 run (%s/%s).', symbol, pse_name,...
                    app.controller.project.stage1_alt(pse_name)), 'Inputs: From Stage 1', 'info');
                return
            end
            if strcmp(symbol, 'csr_apply_structure_repair') && ~(isnumeric(val) && isscalar(val) && ismember(val, 0:3))
                app.WorkflowInputsTable.Data{row, col} = event.PreviousData;
                app.auxLib.alert_dlgbox('Structure Repair must be 0 (None), 1 (Above SLS), 2 (Above ULS) or 3 (Above SLS Or ULS).',...
                    'Inputs: Invalid Value', 'warning');
                return
            end
            app.controller.set_input(symbol, val);
            % DPA Settings Rows Follow csr_call_dpa
            if strcmp(symbol, 'csr_call_dpa')
                app.controller.touch({'inputs_table'});
                app.refresh();
            end
        end

        % Menu selected function: RemoveStormDatabaseMenu
        function RemoveStormDatabaseMenuSelected(app, event)
            % Remove A Storm Database From The Active Project (chessController.stormdb_removal / remove_stormdb). Tied To
            % Simulations: Deleted With Its Files And Those Bundles' Run Files. Otherwise: Remove (Files Kept) Or Remove & Delete Files
            if isempty(app.controller.project) || isempty(app.controller.project.stormDB_list)
                return
            end
            % Not While A Run Writes Into The Project Folders
            if app.controller.runActive
                app.auxLib.alert_dlgbox('Removing is not available while a run is in progress.', 'Storm Database Management: Remove', 'info');
                return
            end
            app.auxLib.dropdown_input_dlgbox(['Remove storm database from project ' app.controller.project.name '.'],...
                {app.controller.project.stormDB_list.db_name}, 'Storm Database Management: Remove', 'Remove');
            db_name = app.auxLib.dialog_answer;
            if isempty(db_name)
                return
            end
            plan = app.controller.stormdb_removal(db_name);
            answer = app.ask_question(plan.question);
            if isempty(answer) || strcmp(answer, 'Cancel') % Cancel Or Window Closed
                return
            end
            app.controller.remove_stormdb(plan, answer);
            msgs = app.controller.take_messages();
            app.refresh();
            app.show_messages(msgs);
        end

        % Menu selected function: TidesMenu
        function TidesMenuSelected(app, event)
            % Download A NOAA Tidal Prediction File Into The Project (Tides UI), Then Refresh The Run Tab
            if isempty(app.controller.project)
                return
            end
            tidesUI = NOAATidesPredictionsUI(app.controller.project, app.UIFigure);
            try % Wait Until The Tides UI Closes (It Closes Itself After A Successful Download)
                waitfor(tidesUI.UIFigure);
            catch % Already Closed
            end
            % Refresh & Save
            app.controller.select(app.controller.project.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            app.refresh();
            app.controller.save_project();
        end

        % Cell edit callback: PSETable
        function PSETableCellEdit(app, event)
            % [NEW] PSE Viewer: Edit A Value Of The Active PSE/Alternative (Rows Are Added/Removed In The PSE Creation Dialog Only)
            row = event.Indices(1);
            col = event.Indices(2);
            if col ~= 4 || ~app.controller.has_active_alt()
                app.PSETable.Data{row, col} = event.PreviousData;
                return
            end
            val = event.NewData;
            if ~(isnumeric(val) && isscalar(val) && isreal(val) && isfinite(val))
                app.PSETable.Data{row, col} = event.PreviousData;
                app.auxLib.alert_dlgbox(sprintf('%s must be a finite number.', app.PSETable.Data{row, 2}),...
                    'PSE Viewer: Invalid Value', 'warning');
                return
            end
            [pse_name, alt_name] = app.controller.active_names();
            old_tbl = app.controller.project.get_project_field('pse_tables', pse_name, alt_name, 'alt');
            geo = app.controller.project.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            % Rebuild The Geometry (Library Rules); A Library Error Restores The Previous Table (pse_geometry Is Only Set On Success)
            symbol = app.PSETable.Data{row, 1};
            new_tbl = old_tbl;
            new_tbl{strcmp(old_tbl(:, 1), symbol), 4} = val;
            app.controller.project.set_project_field('pse_tables', new_tbl, pse_name, alt_name, 'alt');
            try
                app.controller.project.create_geometry(pse_name, alt_name, geo.pse_type);
            catch ME
                app.PSETable.Data{row, col} = event.PreviousData;
                app.controller.project.set_project_field('pse_tables', old_tbl, pse_name, alt_name, 'alt');
                app.auxLib.alert_dlgbox(['Could not rebuild the PSE geometry: ' ME.message], 'PSE Viewer: Invalid Value', 'error');
                return
            end
            app.controller.save_project();
            % PSE Tab, Constants Table (Water Density, Resolved Offshore Elevation) And Status Bar (PSE Geometry Vs Loaded
            % Results). Same Key: No Saved Simulation Question
            app.controller.touch({'pse', 'constants', 'status'});
            app.refresh();

        end

        % Menu selected function: RemoveAlternativeSimulationMenu
        function RemoveAlternativeSimulationMenuSelected(app, event)
            % Delete Simulations (Storm DB | Workflow Run Files) Of An Alternative Of The Active PSE (remove_alt_sims Dialog)
            if ~app.controller.has_active_alt()
                return
            end
            [pse_name, alt_name] = app.controller.active_names();
            app.remove_alt_sims(app.controller.project, pse_name, alt_name, '');

        end

        % Menu selected function: MultilineTransectMenu
        function MultilineTransectMenuSelected(app, event)
            % Multi-Line Transect: A New Multi-Line PSE (Its '<name>_stage_1' Rubble Mound) Or A '<name>_stage_2' Alternative
            % (Any PSE Type) Of An Existing One, Through The PSE Creation Wizard (Locked Suffix). The Multi-Line Link
            % (chessProject.link_multiline, chessController.finish_element) Is Written Only Once The Wizard Created The Alternative
            if isempty(app.controller.project)
                return
            end
            new_item = 'New multi-line PSE';
            app.auxLib.dropdown_input_dlgbox('Choose multi-line transect first stage PSE', [{new_item}, app.controller.project.multiline_pses()],...
                'Choose multi-line transect first stage PSE', 'OK');
            choice = app.auxLib.dialog_answer;
            if isempty(choice)
                return
            end
            if strcmp(choice, new_item)
                % Stage 1: Always A New Rubble Mound
                obj = PSECreationUI(app.RubbleMoundMenu.Text, app.controller.project, '', app.UIFigure, 1);
                uiwait(obj.uifig);
                app.controller.finish_element(obj.pse_created, obj.pse_name, obj.alt_name, 'pse', 1);
            else
                % Stage 2: PSE Type Picked From The Add PSE Menu Labels
                types = {app.LeveeMenu.Text, app.RubbleMoundMenu.Text, app.FloodwallMenu.Text, app.LowCrestedBreakwaterMenu.Text};
                app.auxLib.dropdown_input_dlgbox(sprintf('PSE type of the second-stage alternative of "%s".', choice), types,...
                    'Multi-line Transect: Stage 2', 'OK');
                pse_type = app.auxLib.dialog_answer;
                if isempty(pse_type)
                    return
                end
                obj = PSECreationUI(pse_type, app.controller.project, choice, app.UIFigure, 2);
                uiwait(obj.uifig);
                app.controller.finish_element(obj.pse_created, obj.pse_name, obj.alt_name, 'alt', 2);
            end
            if obj.pse_created
                app.refresh();
            end

        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % Active Project's Lock Released (Another Session Can Open It), Then The App Closes
            app.controller.release_lock();
            delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [250 110 800 520];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create ProjectManagementMenu
            app.ProjectManagementMenu = uimenu(app.UIFigure);
            app.ProjectManagementMenu.Text = 'Project Management';

            % Create CreateNewProjectMenu
            app.CreateNewProjectMenu = uimenu(app.ProjectManagementMenu);
            app.CreateNewProjectMenu.MenuSelectedFcn = createCallbackFcn(app, @CreateNewProjectMenuSelected, true);
            app.CreateNewProjectMenu.Text = 'Create New Project';

            % Create ImportExportProjectMenu
            app.ImportExportProjectMenu = uimenu(app.ProjectManagementMenu);
            app.ImportExportProjectMenu.Text = 'Import/Export Project';

            % Create ImportProjectMenu
            app.ImportProjectMenu = uimenu(app.ImportExportProjectMenu);
            app.ImportProjectMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadProjectMenuSelected, true);
            app.ImportProjectMenu.Text = 'Import Project';

            % Create ExportProjectMenu
            app.ExportProjectMenu = uimenu(app.ImportExportProjectMenu);
            app.ExportProjectMenu.MenuSelectedFcn = createCallbackFcn(app, @ExportProjectMenuSelected, true);
            app.ExportProjectMenu.Text = 'Export Project';

            % Create AddProjectElementMenu
            app.AddProjectElementMenu = uimenu(app.ProjectManagementMenu);
            app.AddProjectElementMenu.Text = 'Add Project Element';

            % Create PSEMenu
            app.PSEMenu = uimenu(app.AddProjectElementMenu);
            app.PSEMenu.Text = 'PSE';

            % Create LeveeMenu
            app.LeveeMenu = uimenu(app.PSEMenu);
            app.LeveeMenu.MenuSelectedFcn = createCallbackFcn(app, @PSECreationMenuSelected, true);
            app.LeveeMenu.Text = 'Levee';

            % Create RubbleMoundMenu
            app.RubbleMoundMenu = uimenu(app.PSEMenu);
            app.RubbleMoundMenu.MenuSelectedFcn = createCallbackFcn(app, @PSECreationMenuSelected, true);
            app.RubbleMoundMenu.Text = 'Rubble Mound';

            % Create FloodwallMenu
            app.FloodwallMenu = uimenu(app.PSEMenu);
            app.FloodwallMenu.MenuSelectedFcn = createCallbackFcn(app, @PSECreationMenuSelected, true);
            app.FloodwallMenu.Text = 'Floodwall';

            % Create LowCrestedBreakwaterMenu
            app.LowCrestedBreakwaterMenu = uimenu(app.PSEMenu);
            app.LowCrestedBreakwaterMenu.MenuSelectedFcn = createCallbackFcn(app, @PSECreationMenuSelected, true);
            app.LowCrestedBreakwaterMenu.Text = 'Low Crested Breakwater';

            % Create MultilineTransectMenu
            app.MultilineTransectMenu = uimenu(app.PSEMenu);
            app.MultilineTransectMenu.MenuSelectedFcn = createCallbackFcn(app, @MultilineTransectMenuSelected, true);
            app.MultilineTransectMenu.Text = 'Multi-line Transect';

            % Create AlternativeMenu
            app.AlternativeMenu = uimenu(app.AddProjectElementMenu);
            app.AlternativeMenu.MenuSelectedFcn = createCallbackFcn(app, @AlternativeMenuSelected, true);
            app.AlternativeMenu.Text = 'Alternative';

            % Create TidesMenu
            app.TidesMenu = uimenu(app.AddProjectElementMenu);
            app.TidesMenu.MenuSelectedFcn = createCallbackFcn(app, @TidesMenuSelected, true);
            app.TidesMenu.Text = 'Tides';

            % Create RemoveProjectElementMenu
            app.RemoveProjectElementMenu = uimenu(app.ProjectManagementMenu);
            app.RemoveProjectElementMenu.Text = 'Remove Project Element';

            % Create RemovePSEMenu
            app.RemovePSEMenu = uimenu(app.RemoveProjectElementMenu);
            app.RemovePSEMenu.MenuSelectedFcn = createCallbackFcn(app, @RemoveProjectElem, true);
            app.RemovePSEMenu.Text = 'PSE';

            % Create RemoveAlternativeMenu
            app.RemoveAlternativeMenu = uimenu(app.RemoveProjectElementMenu);
            app.RemoveAlternativeMenu.MenuSelectedFcn = createCallbackFcn(app, @RemoveProjectElem, true);
            app.RemoveAlternativeMenu.Text = 'Alternative';

            % Create RemoveTidesMenu
            app.RemoveTidesMenu = uimenu(app.RemoveProjectElementMenu);
            app.RemoveTidesMenu.MenuSelectedFcn = createCallbackFcn(app, @RemoveProjectElem, true);
            app.RemoveTidesMenu.Text = 'Tides';

            % Create RemoveAlternativeSimulationMenu
            app.RemoveAlternativeSimulationMenu = uimenu(app.ProjectManagementMenu);
            app.RemoveAlternativeSimulationMenu.MenuSelectedFcn = createCallbackFcn(app, @RemoveAlternativeSimulationMenuSelected, true);
            app.RemoveAlternativeSimulationMenu.Text = 'Remove Alternative Simulation';

            % Create StormDatabaseManagementMenu
            app.StormDatabaseManagementMenu = uimenu(app.UIFigure);
            app.StormDatabaseManagementMenu.Text = 'Storm Database Management';

            % Create AddStormDatabaseMenu
            app.AddStormDatabaseMenu = uimenu(app.StormDatabaseManagementMenu);
            app.AddStormDatabaseMenu.Text = 'Add Storm Database';

            % Create ImportCHSStudyHDF5Menu
            app.ImportCHSStudyHDF5Menu = uimenu(app.AddStormDatabaseMenu);
            app.ImportCHSStudyHDF5Menu.MenuSelectedFcn = createCallbackFcn(app, @CHSDatabaseMenu, true);
            app.ImportCHSStudyHDF5Menu.Text = 'Import CHS Study (HDF5)';

            % Create RemoveStormDatabaseMenu
            app.RemoveStormDatabaseMenu = uimenu(app.StormDatabaseManagementMenu);
            app.RemoveStormDatabaseMenu.MenuSelectedFcn = createCallbackFcn(app, @RemoveStormDatabaseMenuSelected, true);
            app.RemoveStormDatabaseMenu.Text = 'Remove Storm Database';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.Padding = [0 0 0 0];

            % Create ParentPanel
            app.ParentPanel = uipanel(app.GridLayout);
            app.ParentPanel.Layout.Row = 1;
            app.ParentPanel.Layout.Column = 1;

            % Create MasterGrid
            app.MasterGrid = uigridlayout(app.ParentPanel);
            app.MasterGrid.ColumnWidth = {264, '1x', 4, 453, '3x'};
            app.MasterGrid.RowHeight = {'1x'};
            app.MasterGrid.ColumnSpacing = 0;
            app.MasterGrid.Padding = [4 4 4 4];

            % Create ProjectPanelGrid
            app.ProjectPanelGrid = uigridlayout(app.MasterGrid);
            app.ProjectPanelGrid.ColumnWidth = {'1x'};
            app.ProjectPanelGrid.RowHeight = {73, 22, '1x', 22, 113, 22, '1x'};
            app.ProjectPanelGrid.RowSpacing = 2;
            app.ProjectPanelGrid.Padding = [0 0 0 0];
            app.ProjectPanelGrid.Layout.Row = 1;
            app.ProjectPanelGrid.Layout.Column = [1 2];

            % Create ProjectTreeLabel
            app.ProjectTreeLabel = uilabel(app.ProjectPanelGrid);
            app.ProjectTreeLabel.FontWeight = 'bold';
            app.ProjectTreeLabel.Layout.Row = 2;
            app.ProjectTreeLabel.Layout.Column = 1;
            app.ProjectTreeLabel.Text = 'Project Tree';

            % Create ProjectTree
            app.ProjectTree = uitree(app.ProjectPanelGrid);
            app.ProjectTree.SelectionChangedFcn = createCallbackFcn(app, @ProjectTree_SelectionChanged, true);
            app.ProjectTree.Layout.Row = 3;
            app.ProjectTree.Layout.Column = 1;

            % Create ProjectNavigationLabel
            app.ProjectNavigationLabel = uilabel(app.ProjectPanelGrid);
            app.ProjectNavigationLabel.FontWeight = 'bold';
            app.ProjectNavigationLabel.Layout.Row = 4;
            app.ProjectNavigationLabel.Layout.Column = 1;
            app.ProjectNavigationLabel.Text = 'Project Navigation:';

            % Create ProjectPanel
            app.ProjectPanel = uipanel(app.ProjectPanelGrid);
            app.ProjectPanel.Layout.Row = 5;
            app.ProjectPanel.Layout.Column = 1;

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.ProjectPanel);
            app.GridLayout8.ColumnWidth = {75, '1x'};
            app.GridLayout8.RowHeight = {22, 22, 22, 22};
            app.GridLayout8.RowSpacing = 4;
            app.GridLayout8.Padding = [5 5 5 5];

            % Create ProjectLabel
            app.ProjectLabel = uilabel(app.GridLayout8);
            app.ProjectLabel.Layout.Row = 1;
            app.ProjectLabel.Layout.Column = 1;
            app.ProjectLabel.Text = 'Project:';

            % Create ProjectDropDown
            app.ProjectDropDown = uidropdown(app.GridLayout8);
            app.ProjectDropDown.Items = {};
            app.ProjectDropDown.ValueChangedFcn = createCallbackFcn(app, @ProjectDropDownValueChanged, true);
            app.ProjectDropDown.Layout.Row = 1;
            app.ProjectDropDown.Layout.Column = 2;
            app.ProjectDropDown.Value = {};

            % Create PSEDropDownLabel
            app.PSEDropDownLabel = uilabel(app.GridLayout8);
            app.PSEDropDownLabel.Layout.Row = 2;
            app.PSEDropDownLabel.Layout.Column = 1;
            app.PSEDropDownLabel.Text = 'PSE:';

            % Create PSEDropDown
            app.PSEDropDown = uidropdown(app.GridLayout8);
            app.PSEDropDown.Items = {};
            app.PSEDropDown.ValueChangedFcn = createCallbackFcn(app, @PSEDropDownValueChanged, true);
            app.PSEDropDown.Layout.Row = 2;
            app.PSEDropDown.Layout.Column = 2;
            app.PSEDropDown.Value = {};

            % Create AlternativeDropDownLabel
            app.AlternativeDropDownLabel = uilabel(app.GridLayout8);
            app.AlternativeDropDownLabel.Layout.Row = 3;
            app.AlternativeDropDownLabel.Layout.Column = 1;
            app.AlternativeDropDownLabel.Text = 'Alternative:';

            % Create AlternativeDropDown
            app.AlternativeDropDown = uidropdown(app.GridLayout8);
            app.AlternativeDropDown.Items = {};
            app.AlternativeDropDown.ValueChangedFcn = createCallbackFcn(app, @AlternativeDropDownValueChanged, true);
            app.AlternativeDropDown.Layout.Row = 3;
            app.AlternativeDropDown.Layout.Column = 2;
            app.AlternativeDropDown.Value = {};

            % Create ProjectPathEditFieldLabel
            app.ProjectPathEditFieldLabel = uilabel(app.GridLayout8);
            app.ProjectPathEditFieldLabel.Layout.Row = 4;
            app.ProjectPathEditFieldLabel.Layout.Column = 1;
            app.ProjectPathEditFieldLabel.Text = 'Project Path:';

            % Create ProjectPathEditField
            app.ProjectPathEditField = uieditfield(app.GridLayout8, 'text');
            app.ProjectPathEditField.Editable = 'off';
            app.ProjectPathEditField.Layout.Row = 4;
            app.ProjectPathEditField.Layout.Column = 2;

            % Create ConstantsLabel
            app.ConstantsLabel = uilabel(app.ProjectPanelGrid);
            app.ConstantsLabel.FontWeight = 'bold';
            app.ConstantsLabel.Layout.Row = 6;
            app.ConstantsLabel.Layout.Column = 1;
            app.ConstantsLabel.Text = 'Constants';

            % Create Image
            app.Image = uiimage(app.ProjectPanelGrid);
            app.Image.Layout.Row = 1;
            app.Image.Layout.Column = 1;
            app.Image.ImageSource = fullfile(pathToMLAPP, 'SS_comb_logo.png');

            % Create ConstantsTable
            app.ConstantsTable = uitable(app.ProjectPanelGrid);
            app.ConstantsTable.ColumnName = {'Field'; 'Units'; 'Value'};
            app.ConstantsTable.RowName = {};
            app.ConstantsTable.Layout.Row = 7;
            app.ConstantsTable.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.MasterGrid);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = [4 5];

            % Create PSEViewerTab
            app.PSEViewerTab = uitab(app.TabGroup);
            app.PSEViewerTab.Title = 'PSE Viewer';

            % Create PSEViewerGrid
            app.PSEViewerGrid = uigridlayout(app.PSEViewerTab);
            app.PSEViewerGrid.ColumnWidth = {'1x'};
            app.PSEViewerGrid.RowHeight = {'2x', 25, '1x'};
            app.PSEViewerGrid.Padding = [4 2 4 2];

            % Create PSEAxes
            app.PSEAxes = uiaxes(app.PSEViewerGrid);
            xlabel(app.PSEAxes, 'X Distance')
            ylabel(app.PSEAxes, 'Elevation')
            app.PSEAxes.XMinorTick = 'on';
            app.PSEAxes.YMinorTick = 'on';
            app.PSEAxes.XGrid = 'on';
            app.PSEAxes.XMinorGrid = 'on';
            app.PSEAxes.YGrid = 'on';
            app.PSEAxes.YMinorGrid = 'on';
            app.PSEAxes.ZGrid = 'on';
            app.PSEAxes.Box = 'on';
            app.PSEAxes.Layout.Row = 1;
            app.PSEAxes.Layout.Column = 1;

            % Create PSEButtonGrid
            app.PSEButtonGrid = uigridlayout(app.PSEViewerGrid);
            app.PSEButtonGrid.ColumnWidth = {24, 24, '1x'};
            app.PSEButtonGrid.RowHeight = {'1x'};
            app.PSEButtonGrid.Padding = [0 0 0 0];
            app.PSEButtonGrid.Layout.Row = 2;
            app.PSEButtonGrid.Layout.Column = 1;

            % Create ExtrudeTableButton
            app.ExtrudeTableButton = uibutton(app.PSEButtonGrid, 'push');
            app.ExtrudeTableButton.ButtonPushedFcn = createCallbackFcn(app, @ExtrudeTableButtonPushed, true);
            app.ExtrudeTableButton.Icon = fullfile(pathToMLAPP, 'table_icon.png');
            app.ExtrudeTableButton.Layout.Row = 1;
            app.ExtrudeTableButton.Layout.Column = 1;
            app.ExtrudeTableButton.Text = '';

            % Create ExtrudeFigureButton
            app.ExtrudeFigureButton = uibutton(app.PSEButtonGrid, 'push');
            app.ExtrudeFigureButton.ButtonPushedFcn = createCallbackFcn(app, @ExtrudeFigureButtonPushed, true);
            app.ExtrudeFigureButton.Icon = fullfile(pathToMLAPP, 'plot_icon.png');
            app.ExtrudeFigureButton.Layout.Row = 1;
            app.ExtrudeFigureButton.Layout.Column = 2;
            app.ExtrudeFigureButton.Text = '';

            % Create PSETable
            app.PSETable = uitable(app.PSEViewerGrid);
            app.PSETable.ColumnName = {'model_var'; 'Description'; 'Units'; 'Value'};
            app.PSETable.ColumnWidth = {0.1, 'auto', 'auto', 'auto'};
            app.PSETable.RowName = {};
            app.PSETable.ColumnSortable = [false true false false];
            app.PSETable.ColumnEditable = [false false false true];
            app.PSETable.CellEditCallback = createCallbackFcn(app, @PSETableCellEdit, true);
            app.PSETable.Layout.Row = 3;
            app.PSETable.Layout.Column = 1;

            % Create StormDBViewerTab
            app.StormDBViewerTab = uitab(app.TabGroup);
            app.StormDBViewerTab.Title = 'Storm DB Viewer';

            % Create StormDBViewerGrid
            app.StormDBViewerGrid = uigridlayout(app.StormDBViewerTab);
            app.StormDBViewerGrid.ColumnWidth = {'1x'};
            app.StormDBViewerGrid.RowHeight = {'1.5x', 25, '1x'};
            app.StormDBViewerGrid.Padding = [4 2 4 2];

            % Create StormDBAxes
            app.StormDBAxes = uiaxes(app.StormDBViewerGrid);
            xlabel(app.StormDBAxes, 'X Distance')
            ylabel(app.StormDBAxes, 'Elevation')
            app.StormDBAxes.XMinorTick = 'on';
            app.StormDBAxes.YMinorTick = 'on';
            app.StormDBAxes.XGrid = 'on';
            app.StormDBAxes.XMinorGrid = 'on';
            app.StormDBAxes.YGrid = 'on';
            app.StormDBAxes.YMinorGrid = 'on';
            app.StormDBAxes.ZGrid = 'on';
            app.StormDBAxes.Box = 'on';
            app.StormDBAxes.Layout.Row = 1;
            app.StormDBAxes.Layout.Column = 1;

            % Create StormDBViewerButtonGrid
            app.StormDBViewerButtonGrid = uigridlayout(app.StormDBViewerGrid);
            app.StormDBViewerButtonGrid.ColumnWidth = {24, 24, '1x'};
            app.StormDBViewerButtonGrid.RowHeight = {'1x'};
            app.StormDBViewerButtonGrid.Padding = [0 0 0 0];
            app.StormDBViewerButtonGrid.Layout.Row = 2;
            app.StormDBViewerButtonGrid.Layout.Column = 1;

            % Create ExtrudeTableButton_2
            app.ExtrudeTableButton_2 = uibutton(app.StormDBViewerButtonGrid, 'push');
            app.ExtrudeTableButton_2.ButtonPushedFcn = createCallbackFcn(app, @ExtrudeTableButtonPushed, true);
            app.ExtrudeTableButton_2.Icon = fullfile(pathToMLAPP, 'table_icon.png');
            app.ExtrudeTableButton_2.Layout.Row = 1;
            app.ExtrudeTableButton_2.Layout.Column = 1;
            app.ExtrudeTableButton_2.Text = '';

            % Create ExtrudeFigureButton_2
            app.ExtrudeFigureButton_2 = uibutton(app.StormDBViewerButtonGrid, 'push');
            app.ExtrudeFigureButton_2.ButtonPushedFcn = createCallbackFcn(app, @ExtrudeFigureButtonPushed, true);
            app.ExtrudeFigureButton_2.Icon = fullfile(pathToMLAPP, 'plot_icon.png');
            app.ExtrudeFigureButton_2.Layout.Row = 1;
            app.ExtrudeFigureButton_2.Layout.Column = 2;
            app.ExtrudeFigureButton_2.Text = '';

            % Create StormDBViewerSplitGrid
            app.StormDBViewerSplitGrid = uigridlayout(app.StormDBViewerGrid);
            app.StormDBViewerSplitGrid.ColumnWidth = {'0.9x', '1x'};
            app.StormDBViewerSplitGrid.RowHeight = {'1x'};
            app.StormDBViewerSplitGrid.ColumnSpacing = 3;
            app.StormDBViewerSplitGrid.Padding = [0 0 0 0];
            app.StormDBViewerSplitGrid.Layout.Row = 3;
            app.StormDBViewerSplitGrid.Layout.Column = 1;

            % Create Panel
            app.Panel = uipanel(app.StormDBViewerSplitGrid);
            app.Panel.Layout.Row = 1;
            app.Panel.Layout.Column = 1;

            % Create StormDBViewerNavigationPanelGrid
            app.StormDBViewerNavigationPanelGrid = uigridlayout(app.Panel);
            app.StormDBViewerNavigationPanelGrid.ColumnWidth = {78, '1x'};
            app.StormDBViewerNavigationPanelGrid.RowHeight = {22, 22, 22, 22, 22, 22};
            app.StormDBViewerNavigationPanelGrid.RowSpacing = 2;
            app.StormDBViewerNavigationPanelGrid.Padding = [4 2 4 2];

            % Create StormIDDropDownLabel
            app.StormIDDropDownLabel = uilabel(app.StormDBViewerNavigationPanelGrid);
            app.StormIDDropDownLabel.Layout.Row = 6;
            app.StormIDDropDownLabel.Layout.Column = 1;
            app.StormIDDropDownLabel.Text = 'Storm ID:';

            % Create StormIDDropDown
            app.StormIDDropDown = uidropdown(app.StormDBViewerNavigationPanelGrid);
            app.StormIDDropDown.Items = {};
            app.StormIDDropDown.ValueChangedFcn = createCallbackFcn(app, @updateStormDBPlot, true);
            app.StormIDDropDown.Layout.Row = 6;
            app.StormIDDropDown.Layout.Column = 2;
            app.StormIDDropDown.Value = {};

            % Create FieldToPlotLabel
            app.FieldToPlotLabel = uilabel(app.StormDBViewerNavigationPanelGrid);
            app.FieldToPlotLabel.Layout.Row = 5;
            app.FieldToPlotLabel.Layout.Column = 1;
            app.FieldToPlotLabel.Text = 'Field To Plot:';

            % Create FieldToPlotDropDown
            app.FieldToPlotDropDown = uidropdown(app.StormDBViewerNavigationPanelGrid);
            app.FieldToPlotDropDown.Items = {};
            app.FieldToPlotDropDown.ValueChangedFcn = createCallbackFcn(app, @updateStormDBPlot, true);
            app.FieldToPlotDropDown.Layout.Row = 5;
            app.FieldToPlotDropDown.Layout.Column = 2;
            app.FieldToPlotDropDown.Value = {};

            % Create MatchTypeDropDownLabel
            app.MatchTypeDropDownLabel = uilabel(app.StormDBViewerNavigationPanelGrid);
            app.MatchTypeDropDownLabel.Layout.Row = 4;
            app.MatchTypeDropDownLabel.Layout.Column = 1;
            app.MatchTypeDropDownLabel.Text = 'Match Type:';

            % Create MatchTypeDropDown
            app.MatchTypeDropDown = uidropdown(app.StormDBViewerNavigationPanelGrid);
            app.MatchTypeDropDown.Items = {};
            app.MatchTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @updateStormDBPlot, true);
            app.MatchTypeDropDown.Layout.Row = 4;
            app.MatchTypeDropDown.Layout.Column = 2;
            app.MatchTypeDropDown.Value = {};

            % Create DataTypeDropDownLabel
            app.DataTypeDropDownLabel = uilabel(app.StormDBViewerNavigationPanelGrid);
            app.DataTypeDropDownLabel.Layout.Row = 3;
            app.DataTypeDropDownLabel.Layout.Column = 1;
            app.DataTypeDropDownLabel.Text = 'Data Type:';

            % Create DataTypeDropDown
            app.DataTypeDropDown = uidropdown(app.StormDBViewerNavigationPanelGrid);
            app.DataTypeDropDown.Items = {};
            app.DataTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @DataTypeDropDown_dbOpening, true);
            app.DataTypeDropDown.Layout.Row = 3;
            app.DataTypeDropDown.Layout.Column = 2;
            app.DataTypeDropDown.Value = {};

            % Create StormTypeDropDownLabel
            app.StormTypeDropDownLabel = uilabel(app.StormDBViewerNavigationPanelGrid);
            app.StormTypeDropDownLabel.Layout.Row = 2;
            app.StormTypeDropDownLabel.Layout.Column = 1;
            app.StormTypeDropDownLabel.Text = 'Storm Type:';

            % Create StormTypeDropDown
            app.StormTypeDropDown = uidropdown(app.StormDBViewerNavigationPanelGrid);
            app.StormTypeDropDown.Items = {};
            app.StormTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @StormTypeDropDown_dbOpening, true);
            app.StormTypeDropDown.Layout.Row = 2;
            app.StormTypeDropDown.Layout.Column = 2;
            app.StormTypeDropDown.Value = {};

            % Create StormDBDropDownLabel
            app.StormDBDropDownLabel = uilabel(app.StormDBViewerNavigationPanelGrid);
            app.StormDBDropDownLabel.Layout.Row = 1;
            app.StormDBDropDownLabel.Layout.Column = 1;
            app.StormDBDropDownLabel.Text = 'Storm DB:';

            % Create StormDBDropDown
            app.StormDBDropDown = uidropdown(app.StormDBViewerNavigationPanelGrid);
            app.StormDBDropDown.Items = {};
            app.StormDBDropDown.ValueChangedFcn = createCallbackFcn(app, @StormDBDropDown_dbValueChanged, true);
            app.StormDBDropDown.Layout.Row = 1;
            app.StormDBDropDown.Layout.Column = 2;
            app.StormDBDropDown.Value = {};

            % Create StormDBTable
            app.StormDBTable = uitable(app.StormDBViewerSplitGrid);
            app.StormDBTable.ColumnName = {'Storm Timestamp'; 'Water Level'};
            app.StormDBTable.RowName = {};
            app.StormDBTable.Layout.Row = 1;
            app.StormDBTable.Layout.Column = 2;

            % Create CHESSRunTab
            app.CHESSRunTab = uitab(app.TabGroup);
            app.CHESSRunTab.Title = 'CHESS Run';

            % Create RunViewerGrid
            app.RunViewerGrid = uigridlayout(app.CHESSRunTab);
            app.RunViewerGrid.ColumnWidth = {'1x'};
            app.RunViewerGrid.RowHeight = {22, 22, 22, 22, 22, '1.1x', 22, 22, '1x', 22, '0.3x'};
            app.RunViewerGrid.RowSpacing = 4;
            app.RunViewerGrid.Padding = [8 6 8 6];

            % Create DefineProjectForcingLabel_2
            app.DefineProjectForcingLabel_2 = uilabel(app.RunViewerGrid);
            app.DefineProjectForcingLabel_2.FontSize = 15;
            app.DefineProjectForcingLabel_2.FontWeight = 'bold';
            app.DefineProjectForcingLabel_2.Layout.Row = 1;
            app.DefineProjectForcingLabel_2.Layout.Column = 1;
            app.DefineProjectForcingLabel_2.Text = '1. Define Project Forcing';

            % Create DefineProjectResponsesDataTypesToComputeLabel
            app.DefineProjectResponsesDataTypesToComputeLabel = uilabel(app.RunViewerGrid);
            app.DefineProjectResponsesDataTypesToComputeLabel.FontSize = 15;
            app.DefineProjectResponsesDataTypesToComputeLabel.FontWeight = 'bold';
            app.DefineProjectResponsesDataTypesToComputeLabel.Layout.Row = 7;
            app.DefineProjectResponsesDataTypesToComputeLabel.Layout.Column = 1;
            app.DefineProjectResponsesDataTypesToComputeLabel.Text = '3. Define Project Responses & Data Types To Compute';

            % Create RunSimulationLabel
            app.RunSimulationLabel = uilabel(app.RunViewerGrid);
            app.RunSimulationLabel.FontSize = 15;
            app.RunSimulationLabel.FontWeight = 'bold';
            app.RunSimulationLabel.Layout.Row = 10;
            app.RunSimulationLabel.Layout.Column = 1;
            app.RunSimulationLabel.Text = '4. Run Simulation';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.RunViewerGrid);
            app.GridLayout3.ColumnWidth = {80, '1x', 138, 22};
            app.GridLayout3.RowHeight = {'1x'};
            app.GridLayout3.ColumnSpacing = 6;
            app.GridLayout3.RowSpacing = 0;
            app.GridLayout3.Padding = [0 0 0 0];
            app.GridLayout3.Layout.Row = 2;
            app.GridLayout3.Layout.Column = 1;

            % Create ApplyDepthLimitationCheckBox
            app.ApplyDepthLimitationCheckBox = uicheckbox(app.GridLayout3);
            app.ApplyDepthLimitationCheckBox.ValueChangedFcn = createCallbackFcn(app, @StormDBDropDown_runValueChanged, true);
            app.ApplyDepthLimitationCheckBox.Text = 'Apply Depth Limitation';
            app.ApplyDepthLimitationCheckBox.Layout.Row = 1;
            app.ApplyDepthLimitationCheckBox.Layout.Column = 3;

            % Create StormDBDropDown_2Label
            app.StormDBDropDown_2Label = uilabel(app.GridLayout3);
            app.StormDBDropDown_2Label.Layout.Row = 1;
            app.StormDBDropDown_2Label.Layout.Column = 1;
            app.StormDBDropDown_2Label.Text = 'Storm  DB:';

            % Create StormDBDropDown_run
            app.StormDBDropDown_run = uidropdown(app.GridLayout3);
            app.StormDBDropDown_run.Items = {};
            app.StormDBDropDown_run.ValueChangedFcn = createCallbackFcn(app, @StormDBDropDown_runValueChanged, true);
            app.StormDBDropDown_run.Layout.Row = 1;
            app.StormDBDropDown_run.Layout.Column = 2;
            app.StormDBDropDown_run.Value = {};

            % Create GridLayout3_2
            app.GridLayout3_2 = uigridlayout(app.RunViewerGrid);
            app.GridLayout3_2.ColumnWidth = {80, '1x', 110, 50};
            app.GridLayout3_2.RowHeight = {'1x'};
            app.GridLayout3_2.ColumnSpacing = 6;
            app.GridLayout3_2.RowSpacing = 0;
            app.GridLayout3_2.Padding = [0 0 0 0];
            app.GridLayout3_2.Layout.Row = 3;
            app.GridLayout3_2.Layout.Column = 1;

            % Create StormTypeDropDown_2Label_2
            app.StormTypeDropDown_2Label_2 = uilabel(app.GridLayout3_2);
            app.StormTypeDropDown_2Label_2.Layout.Row = 1;
            app.StormTypeDropDown_2Label_2.Layout.Column = 1;
            app.StormTypeDropDown_2Label_2.Text = 'Storm Type:';

            % Create StormTypeDropDown_2
            app.StormTypeDropDown_2 = uidropdown(app.GridLayout3_2);
            app.StormTypeDropDown_2.Items = {};
            app.StormTypeDropDown_2.ValueChangedFcn = createCallbackFcn(app, @StormDBDropDown_runValueChanged, true);
            app.StormTypeDropDown_2.Layout.Row = 1;
            app.StormTypeDropDown_2.Layout.Column = 2;
            app.StormTypeDropDown_2.Value = {};

            % Create SeaLevelChangeEditFieldLabel
            app.SeaLevelChangeEditFieldLabel = uilabel(app.GridLayout3_2);
            app.SeaLevelChangeEditFieldLabel.Layout.Row = 1;
            app.SeaLevelChangeEditFieldLabel.Layout.Column = 3;
            app.SeaLevelChangeEditFieldLabel.Text = 'Sea Level Change:';

            % Create SeaLevelChangeEditField
            app.SeaLevelChangeEditField = uieditfield(app.GridLayout3_2, 'numeric');
            app.SeaLevelChangeEditField.ValueChangedFcn = createCallbackFcn(app, @StormDBDropDown_runValueChanged, true);
            app.SeaLevelChangeEditField.HorizontalAlignment = 'center';
            app.SeaLevelChangeEditField.Layout.Row = 1;
            app.SeaLevelChangeEditField.Layout.Column = 4;

            % Create GridLayout3_3
            app.GridLayout3_3 = uigridlayout(app.RunViewerGrid);
            app.GridLayout3_3.ColumnWidth = {80, '1x'};
            app.GridLayout3_3.RowHeight = {'1x'};
            app.GridLayout3_3.ColumnSpacing = 6;
            app.GridLayout3_3.RowSpacing = 0;
            app.GridLayout3_3.Padding = [0 0 0 0];
            app.GridLayout3_3.Layout.Row = 4;
            app.GridLayout3_3.Layout.Column = 1;

            % Create TideFileDropDownLabel
            app.TideFileDropDownLabel = uilabel(app.GridLayout3_3);
            app.TideFileDropDownLabel.Layout.Row = 1;
            app.TideFileDropDownLabel.Layout.Column = 1;
            app.TideFileDropDownLabel.Text = 'Tide File:';

            % Create TidesFileDropDown
            app.TidesFileDropDown = uidropdown(app.GridLayout3_3);
            app.TidesFileDropDown.Items = {'None'};
            app.TidesFileDropDown.ValueChangedFcn = createCallbackFcn(app, @StormDBDropDown_runValueChanged, true);
            app.TidesFileDropDown.Layout.Row = 1;
            app.TidesFileDropDown.Layout.Column = 2;
            app.TidesFileDropDown.Value = 'None';

            % Create GridLayout3_4
            app.GridLayout3_4 = uigridlayout(app.RunViewerGrid);
            app.GridLayout3_4.ColumnWidth = {'1x', 166};
            app.GridLayout3_4.RowHeight = {'1x'};
            app.GridLayout3_4.ColumnSpacing = 6;
            app.GridLayout3_4.RowSpacing = 0;
            app.GridLayout3_4.Padding = [0 0 0 0];
            app.GridLayout3_4.Layout.Row = 5;
            app.GridLayout3_4.Layout.Column = 1;

            % Create DefineCHESSWorkflowLabel
            app.DefineCHESSWorkflowLabel = uilabel(app.GridLayout3_4);
            app.DefineCHESSWorkflowLabel.FontSize = 15;
            app.DefineCHESSWorkflowLabel.FontWeight = 'bold';
            app.DefineCHESSWorkflowLabel.Layout.Row = 1;
            app.DefineCHESSWorkflowLabel.Layout.Column = 1;
            app.DefineCHESSWorkflowLabel.Text = '2. Define CHESS Workflow ';

            % Create WorkflowDropDown
            app.WorkflowDropDown = uidropdown(app.GridLayout3_4);
            app.WorkflowDropDown.Items = {'CHESS: PROS-RB', 'CHESS: Deterministic', 'CHESS:LCS', 'CHESS: PROS-FB'};
            app.WorkflowDropDown.ItemsData = [1 2 3 4];
            app.WorkflowDropDown.ValueChangedFcn = createCallbackFcn(app, @WorkflowDropDownValueChanged, true);
            app.WorkflowDropDown.Layout.Row = 1;
            app.WorkflowDropDown.Layout.Column = 2;
            app.WorkflowDropDown.Value = 1;

            % Create WorkflowInputsTable
            app.WorkflowInputsTable = uitable(app.RunViewerGrid);
            app.WorkflowInputsTable.ColumnName = {'model_var'; 'Field'; 'Value'};
            app.WorkflowInputsTable.ColumnWidth = {0.1, 'auto', 'auto'};
            app.WorkflowInputsTable.RowName = {};
            app.WorkflowInputsTable.ColumnEditable = [false false true];
            app.WorkflowInputsTable.CellEditCallback = createCallbackFcn(app, @WorkflowInputsTableCellEdit, true);
            app.WorkflowInputsTable.Layout.Row = 6;
            app.WorkflowInputsTable.Layout.Column = 1;

            % Create GridLayout3_5
            app.GridLayout3_5 = uigridlayout(app.RunViewerGrid);
            app.GridLayout3_5.ColumnWidth = {'1x', 166};
            app.GridLayout3_5.RowHeight = {'1x'};
            app.GridLayout3_5.ColumnSpacing = 6;
            app.GridLayout3_5.RowSpacing = 0;
            app.GridLayout3_5.Padding = [0 0 0 0];
            app.GridLayout3_5.Layout.Row = 8;
            app.GridLayout3_5.Layout.Column = 1;

            % Create PSEResponsesLabel
            app.PSEResponsesLabel = uilabel(app.GridLayout3_5);
            app.PSEResponsesLabel.Layout.Row = 1;
            app.PSEResponsesLabel.Layout.Column = 1;
            app.PSEResponsesLabel.Text = 'PSE Responses:';

            % Create DataTypesToProcessLabel
            app.DataTypesToProcessLabel = uilabel(app.GridLayout3_5);
            app.DataTypesToProcessLabel.Layout.Row = 1;
            app.DataTypesToProcessLabel.Layout.Column = 2;
            app.DataTypesToProcessLabel.Text = 'Data Types To Process:';

            % Create GridLayout3_6
            app.GridLayout3_6 = uigridlayout(app.RunViewerGrid);
            app.GridLayout3_6.ColumnWidth = {'1x', 166};
            app.GridLayout3_6.RowHeight = {'1x'};
            app.GridLayout3_6.ColumnSpacing = 6;
            app.GridLayout3_6.RowSpacing = 0;
            app.GridLayout3_6.Padding = [0 0 0 0];
            app.GridLayout3_6.Layout.Row = 9;
            app.GridLayout3_6.Layout.Column = 1;

            % Create ResponsesTree
            app.ResponsesTree = uitree(app.GridLayout3_6, 'checkbox');
            app.ResponsesTree.Layout.Row = 1;
            app.ResponsesTree.Layout.Column = 1;

            % Assign Checked Nodes
            app.ResponsesTree.CheckedNodesChangedFcn = createCallbackFcn(app, @TreeCheckedNodesChanged, true);

            % Create DataTypesTree
            app.DataTypesTree = uitree(app.GridLayout3_6, 'checkbox');
            app.DataTypesTree.Layout.Row = 1;
            app.DataTypesTree.Layout.Column = 2;

            % Assign Checked Nodes
            app.DataTypesTree.CheckedNodesChangedFcn = createCallbackFcn(app, @TreeCheckedNodesChanged, true);

            % Create GridLayout3_7
            app.GridLayout3_7 = uigridlayout(app.RunViewerGrid);
            app.GridLayout3_7.ColumnWidth = {96, '1x'};
            app.GridLayout3_7.RowHeight = {24, '1x'};
            app.GridLayout3_7.ColumnSpacing = 6;
            app.GridLayout3_7.RowSpacing = 0;
            app.GridLayout3_7.Padding = [0 0 0 0];
            app.GridLayout3_7.Layout.Row = 11;
            app.GridLayout3_7.Layout.Column = 1;

            % Create RunSimulationButton
            app.RunSimulationButton = uibutton(app.GridLayout3_7, 'push');
            app.RunSimulationButton.ButtonPushedFcn = createCallbackFcn(app, @RunSimulationButtonPushed, true);
            app.RunSimulationButton.Enable = 'off';
            app.RunSimulationButton.Layout.Row = 1;
            app.RunSimulationButton.Layout.Column = 1;
            app.RunSimulationButton.Text = 'Run Simulation';

            % Create simStatusBar
            app.simStatusBar = uitextarea(app.GridLayout3_7);
            app.simStatusBar.Editable = 'off';
            app.simStatusBar.Layout.Row = [1 2];
            app.simStatusBar.Layout.Column = 2;

            % Create ResultsViewerTab
            app.ResultsViewerTab = uitab(app.TabGroup);
            app.ResultsViewerTab.Title = 'Results Viewer';

            % Create StormDBViewerGrid_2
            app.StormDBViewerGrid_2 = uigridlayout(app.ResultsViewerTab);
            app.StormDBViewerGrid_2.ColumnWidth = {'1x'};
            app.StormDBViewerGrid_2.RowHeight = {'1.5x', 25, '1x'};
            app.StormDBViewerGrid_2.Padding = [4 2 4 2];

            % Create PSEAxes_3
            app.PSEAxes_3 = uiaxes(app.StormDBViewerGrid_2);
            xlabel(app.PSEAxes_3, 'X Distance')
            ylabel(app.PSEAxes_3, 'Elevation')
            app.PSEAxes_3.XMinorTick = 'on';
            app.PSEAxes_3.YMinorTick = 'on';
            app.PSEAxes_3.XGrid = 'on';
            app.PSEAxes_3.XMinorGrid = 'on';
            app.PSEAxes_3.YGrid = 'on';
            app.PSEAxes_3.YMinorGrid = 'on';
            app.PSEAxes_3.ZGrid = 'on';
            app.PSEAxes_3.Box = 'on';
            app.PSEAxes_3.Layout.Row = 1;
            app.PSEAxes_3.Layout.Column = 1;

            % Create StormDBViewerButtonGrid_2
            app.StormDBViewerButtonGrid_2 = uigridlayout(app.StormDBViewerGrid_2);
            app.StormDBViewerButtonGrid_2.ColumnWidth = {24, 24, '1x'};
            app.StormDBViewerButtonGrid_2.RowHeight = {'1x'};
            app.StormDBViewerButtonGrid_2.Padding = [0 0 0 0];
            app.StormDBViewerButtonGrid_2.Layout.Row = 2;
            app.StormDBViewerButtonGrid_2.Layout.Column = 1;

            % Create Button_5
            app.Button_5 = uibutton(app.StormDBViewerButtonGrid_2, 'push');
            app.Button_5.ButtonPushedFcn = createCallbackFcn(app, @ExtrudeTableButtonPushed, true);
            app.Button_5.Icon = fullfile(pathToMLAPP, 'table_icon.png');
            app.Button_5.Layout.Row = 1;
            app.Button_5.Layout.Column = 1;
            app.Button_5.Text = '';

            % Create Button_6
            app.Button_6 = uibutton(app.StormDBViewerButtonGrid_2, 'push');
            app.Button_6.ButtonPushedFcn = createCallbackFcn(app, @ExtrudeFigureButtonPushed, true);
            app.Button_6.Icon = fullfile(pathToMLAPP, 'plot_icon.png');
            app.Button_6.Layout.Row = 1;
            app.Button_6.Layout.Column = 2;
            app.Button_6.Text = '';

            % Create StormDBViewerSplitGrid_2
            app.StormDBViewerSplitGrid_2 = uigridlayout(app.StormDBViewerGrid_2);
            app.StormDBViewerSplitGrid_2.ColumnWidth = {'0.9x', '1x'};
            app.StormDBViewerSplitGrid_2.RowHeight = {'1x'};
            app.StormDBViewerSplitGrid_2.ColumnSpacing = 3;
            app.StormDBViewerSplitGrid_2.Padding = [0 0 0 0];
            app.StormDBViewerSplitGrid_2.Layout.Row = 3;
            app.StormDBViewerSplitGrid_2.Layout.Column = 1;

            % Create Panel_2
            app.Panel_2 = uipanel(app.StormDBViewerSplitGrid_2);
            app.Panel_2.Layout.Row = 1;
            app.Panel_2.Layout.Column = 1;

            % Create StormDBViewerNavigationPanelGrid_2
            app.StormDBViewerNavigationPanelGrid_2 = uigridlayout(app.Panel_2);
            app.StormDBViewerNavigationPanelGrid_2.ColumnWidth = {82, '1x'};
            app.StormDBViewerNavigationPanelGrid_2.RowHeight = {22, 22, 22, 22, 22, 22};
            app.StormDBViewerNavigationPanelGrid_2.RowSpacing = 2;
            app.StormDBViewerNavigationPanelGrid_2.Padding = [4 2 4 2];

            % Create PlotTypeDropDownLabel
            app.PlotTypeDropDownLabel = uilabel(app.StormDBViewerNavigationPanelGrid_2);
            app.PlotTypeDropDownLabel.Layout.Row = 1;
            app.PlotTypeDropDownLabel.Layout.Column = 1;
            app.PlotTypeDropDownLabel.Text = 'Plot Type:';

            % Create PlotTypeDropDown
            app.PlotTypeDropDown = uidropdown(app.StormDBViewerNavigationPanelGrid_2);
            app.PlotTypeDropDown.Items = {};
            app.PlotTypeDropDown.Layout.Row = 1;
            app.PlotTypeDropDown.Layout.Column = 2;
            app.PlotTypeDropDown.Value = {};

            % Create StormTypeDropDown_2Label
            app.StormTypeDropDown_2Label = uilabel(app.StormDBViewerNavigationPanelGrid_2);
            app.StormTypeDropDown_2Label.Layout.Row = 2;
            app.StormTypeDropDown_2Label.Layout.Column = 1;
            app.StormTypeDropDown_2Label.Text = 'Storm Type:';

            % Create StormTypeDropDown_results
            app.StormTypeDropDown_results = uidropdown(app.StormDBViewerNavigationPanelGrid_2);
            app.StormTypeDropDown_results.Items = {};
            app.StormTypeDropDown_results.Layout.Row = 2;
            app.StormTypeDropDown_results.Layout.Column = 2;
            app.StormTypeDropDown_results.Value = {};

            % Create DataTypeDropDown_2Label
            app.DataTypeDropDown_2Label = uilabel(app.StormDBViewerNavigationPanelGrid_2);
            app.DataTypeDropDown_2Label.Layout.Row = 3;
            app.DataTypeDropDown_2Label.Layout.Column = 1;
            app.DataTypeDropDown_2Label.Text = 'Data Type:';

            % Create DataTypeDropDown_results
            app.DataTypeDropDown_results = uidropdown(app.StormDBViewerNavigationPanelGrid_2);
            app.DataTypeDropDown_results.Items = {};
            app.DataTypeDropDown_results.Layout.Row = 3;
            app.DataTypeDropDown_results.Layout.Column = 2;
            app.DataTypeDropDown_results.Value = {};

            % Create MatchTypeDropDown_2Label
            app.MatchTypeDropDown_2Label = uilabel(app.StormDBViewerNavigationPanelGrid_2);
            app.MatchTypeDropDown_2Label.Layout.Row = 4;
            app.MatchTypeDropDown_2Label.Layout.Column = 1;
            app.MatchTypeDropDown_2Label.Text = 'Match Type:';

            % Create MatchTypeDropDown_results
            app.MatchTypeDropDown_results = uidropdown(app.StormDBViewerNavigationPanelGrid_2);
            app.MatchTypeDropDown_results.Items = {};
            app.MatchTypeDropDown_results.Layout.Row = 4;
            app.MatchTypeDropDown_results.Layout.Column = 2;
            app.MatchTypeDropDown_results.Value = {};

            % Create FieldToPlotDropDown_2Label
            app.FieldToPlotDropDown_2Label = uilabel(app.StormDBViewerNavigationPanelGrid_2);
            app.FieldToPlotDropDown_2Label.Layout.Row = 5;
            app.FieldToPlotDropDown_2Label.Layout.Column = 1;
            app.FieldToPlotDropDown_2Label.Text = 'Field To Plot:';

            % Create FieldToPlotDropDown_results
            app.FieldToPlotDropDown_results = uidropdown(app.StormDBViewerNavigationPanelGrid_2);
            app.FieldToPlotDropDown_results.Items = {};
            app.FieldToPlotDropDown_results.Layout.Row = 5;
            app.FieldToPlotDropDown_results.Layout.Column = 2;
            app.FieldToPlotDropDown_results.Value = {};

            % Create StormIDDropDown_2Label
            app.StormIDDropDown_2Label = uilabel(app.StormDBViewerNavigationPanelGrid_2);
            app.StormIDDropDown_2Label.Layout.Row = 6;
            app.StormIDDropDown_2Label.Layout.Column = 1;
            app.StormIDDropDown_2Label.Text = 'Storm ID:';

            % Create StormIDDropDown_results
            app.StormIDDropDown_results = uidropdown(app.StormDBViewerNavigationPanelGrid_2);
            app.StormIDDropDown_results.Items = {};
            app.StormIDDropDown_results.Layout.Row = 6;
            app.StormIDDropDown_results.Layout.Column = 2;
            app.StormIDDropDown_results.Value = {};

            % Create PSETable_3
            app.PSETable_3 = uitable(app.StormDBViewerSplitGrid_2);
            app.PSETable_3.ColumnName = {'Storm Timestamp'; 'Water Level'};
            app.PSETable_3.RowName = {};
            app.PSETable_3.Layout.Row = 1;
            app.PSETable_3.Layout.Column = 2;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CHESS_UI_canvas_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
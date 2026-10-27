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
        chess_projects % Loaded CHESS projects
        wProj % Active project Handle
        proj_indx
        pse_indx
        alt_indx
        auxLib
        simState % Description
        tableState % Description
        stormCache % [NEW] Loaded storm Data Keyed By File (containers.Map)
        simContext % [NEW] Project|PSE|Alternative Last Shown On CHESS Run Tab
        resultsState % [NEW] Loaded Results (Resp, config, structure, project_forcing, storm DB) For plot_project_responses
        resultsPlotOptions % [NEW] Results Plot Options Per Plot Type (Right-Click "Plot Options...", Session Only)
        resultsMenu % [NEW] Results Axes Right-Click Menu (Created In startupFcn)
        resultsPopout % [NEW] Classic Figure Reused For Multi-Panel Results Plots
        resultsTablePopout % DET Response Table Pop-Out (uifigure From det_methods.response_table)
        simKey % [NEW] Saved Simulation Key (Config File Of Alternative + Workflow + Run Tab Storm DB) Last Resolved By sync_saved_sim
        declinedSimKey = '' % Saved Simulation Key Whose Load Was Declined ("Keep current inputs"): Results Tab Kept Cleared While sim_key() Equals It
        oldDbWarned = {} % Storm DB Files (output_paths.storm_db) Already Alerted As Older CHESS Version (Once Per Session)
        plotFontSize = 12 % Base Font Of Every GUI Plot, Tab And Pop-Out (Library Rule: Title +2, Labels Base, Ticks -2)
        resultsMirror % Panel Over PSEAxes_3 (Same Grid Cell) Showing A Multi-Panel Results Plot When The Cell Is Big Enough (Created In startupFcn)
        resultsMirrorFits = [] % Fit State Of The Shown Multi-Panel Results Plot ([] If None): The Tab Resize Redraws Only When It Flips
        runActive = false
        projectLock = [] % Lock Of The Active Project Folder (lock_project): struct('proj', chessProject, 'lock', chessProject.acquire_lock Output), [] If None
    end

    methods (Access = private)
        function append_project(app, wProj)
            % Append SS Project & Make It Active
            app.chess_projects = [app.chess_projects; wProj];
            app.set_active_selection(wProj.name, '', '');
            % Keep Per-Alternative Fields Sized
            app.project_field_ini();
            % Refresh UI
            app.refresh_active_view();
        end

        function [s1_row, msg] = apply_multiline_locks(app)
            % Multi-Line Run Tab Rules (set_input_table, Before The Inputs Table Rows). Stage 1: Hm0t Kept Checked (Its Stage 2
            % Forcing). Stage 2 With A Stage 1 Run Of The Run Tab Storm DB + Workflow (multiline_stage1_row: Its Registry Row):
            % Storm Type, Data Types, SLR And Tide File (Matched By File Name) Set To That Run's And Locked (The Stage 2 Forcing
            % Is Stage 1's). Otherwise Unlocked. s1_row / msg: multiline_stage1_row
            [s1_row, msg] = app.multiline_stage1_row();
            [pse_name, alt_name] = app.get_active_names();
            if app.has_active_alt() && app.wProj.alt_stage(pse_name, alt_name) == 1
                nodes = app.get_tree_nodes(app.ResponsesTree);
                node = nodes(strcmp({nodes.NodeData}, 'compute_wave_transmission'));
                if isscalar(node) && isempty(app.ResponsesTree.CheckedNodes)
                    app.ResponsesTree.CheckedNodes = node;
                elseif isscalar(node) && ~ismember('compute_wave_transmission', app.get_checked_symbols(app.ResponsesTree))
                    app.ResponsesTree.CheckedNodes = [app.ResponsesTree.CheckedNodes; node];
                end
            end
            locked = ~isempty(s1_row);
            if locked
                if any(strcmp(app.StormTypeDropDown_2.Items, s1_row.storm_type))
                    app.StormTypeDropDown_2.Value = s1_row.storm_type;
                end
                if isfield(s1_row.inherited, 'swl_slr')
                    app.SeaLevelChangeEditField.Value = s1_row.inherited.swl_slr;
                end
                if isfield(s1_row.inherited, 'tide_file') % Row Holds The File Name; ItemsData Are Paths ('None' Kept)
                    [~, tide_names, tide_ext] = cellfun(@fileparts, app.TidesFileDropDown.ItemsData, 'un', false);
                    tide_k = find(strcmp(strcat(tide_names, tide_ext), s1_row.inherited.tide_file), 1);
                    if ~isempty(tide_k)
                        app.TidesFileDropDown.Value = app.TidesFileDropDown.ItemsData{tide_k};
                    end
                end
                % Data Types (Row Holds The Tree Symbols)
                nodes = app.get_tree_nodes(app.DataTypesTree);
                if ~isempty(nodes)
                    nodes = nodes(ismember({nodes.NodeData}, s1_row.data_types));
                end
                if isempty(nodes)
                    app.DataTypesTree.CheckedNodes = [];
                else
                    app.DataTypesTree.CheckedNodes = nodes;
                end
            end
            for comp = {app.StormTypeDropDown_2, app.SeaLevelChangeEditField, app.TidesFileDropDown, app.DataTypesTree}
                comp{1}.Enable = ~locked;
            end
        end

        function backed = backup_sim_files(app, bk, level)
            % [NEW] Back Up The Slot Before The Run Touches It (Before apply_hotstart_level Deletes Anything), By Hotstart Level:
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
                app.restore_sim_files(backed);
                rethrow(ME);
            end
        end

        function [config, pseObj] = create_resp_config(app, pseObj, dbObj, for_run, plan)
            % Run Step: Build config From Run Tab + Project + Storm DB, Then Apply Library Run Rules
            %   for_run = false: Input Comparison Only (No Hotstart Actions, Nothing Saved)
            %   plan: Run Start (run_hotstart_plan): plan.level 'cold' (Default) | 'full' | 'reuse_sampling', plan.old: Saved Run's config
            if nargin < 4
                for_run = true;
            end
            if nargin < 5
                plan = struct('level', 'cold', 'old', []);
            end
            [pse_name, alt_name] = app.get_active_names();
            [~, ~, ~, ~, out_files] = app.get_config_path();
            % Library Template Defaults For storm_duration (Fresh Table) And Workflow Sections (Library Functions Read Them Regardless Of Workflow)
            tpl = app.wProj.get_library_template(pseObj.pse_type);
            wf_rows = [tpl.forcing(strcmp(tpl.forcing(:, 1), 'storm_duration'), :); tpl.mcs; tpl.csr; tpl.pros];
            for rr = 1:size(wf_rows, 1)
                config.(wf_rows{rr, 1}) = wf_rows{rr, 4};
            end
            % Every Library Response Switch Defaults To Off (Union Of All Templates)
            types = {'Levee', 'Floodwall', 'Rubble Mound', 'Low Crested Breakwater'};
            for tt = 1:length(types)
                tpl_t = app.wProj.get_library_template(types{tt});
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
            config.workflow = app.WorkflowDropDown.Value;  % Workflow
            config.storm_sampling = app.StormTypeDropDown_2.Value; % Storm Types To Process
            % Data Types (Tree NodeData Holds Library Symbols)
            dt_checked = app.get_checked_symbols(app.DataTypesTree);
            config.use_peaks = +any(ismember({'peaks_default','create_wlp','create_whp'}, dt_checked));
            config.use_timeseries = +ismember('use_timeseries', dt_checked);
            config.create_wlp = +ismember('create_wlp', dt_checked);
            config.create_whp = +ismember('create_whp', dt_checked);
            % Project Forcing Adjustments
            config.swl_slr = app.SeaLevelChangeEditField.Value; % SLR
            config.tide_file = app.TidesFileDropDown.Value; % Tides
            config.apply_random_tides = +~strcmp(config.tide_file, 'None');
            config.apply_depth_limitation = +app.ApplyDepthLimitationCheckBox.Value; % Depth Limitation
            config.load_project_forcing = 0; % GUI Builds Project Forcing Itself
            config.ref_case_name = 'none';
            % Responses (Tree NodeData Holds Library Symbols)
            resp_checked = app.get_checked_symbols(app.ResponsesTree);
            for rr = 1:length(resp_checked)
                config.(resp_checked{rr}) = 1;
            end
            % Inputs Of Every Workflow (Visible And Hidden Rows): Config Records The Full Input State
            app.store_table_values();
            input_fields = fieldnames(app.tableState);
            for rr = 1:length(input_fields)
                config.(input_fields{rr}) = +app.tableState.(input_fields{rr});
            end
            % Storm DB Fields
            config.region = dbObj.study;
            config.sp_ID = '';
            config.sp_ID_wave = '';
            config.storm_db = app.StormDBDropDown_run.Value;
            % Project Pathing
            config.outfolder = app.wProj.path;
            config.project_name = app.wProj.name;
            config.struc_id = pse_name;
            config.case_name = alt_name;
            % Project CLs ([CL1 CL2 ...], Library Sorts & Formats)
            cls = app.wProj.get_project_field('CLs', '', '', 'proj');
            cls(cls==0) = [];
            config.project_CLs = ['[' strjoin(arrayfun(@num2str, cls, 'un', false), ' ') ']'];
            config.project_datum = app.wProj.vdatum;
            % Constants
            config.gravity_constant = app.pull_input_table_value(app.ConstantsTable.Data, 'Gravity Constant');
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
            % Toe, Stage 1 Forcing Stamp); Without That Run Only The Link Is Recorded (Run Disabled: multiline_stage1_row)
            switch app.wProj.alt_stage(pse_name, alt_name)
                case 1
                    config.compute_wave_transmission = 1;
                case 2
                    config.multiline = struct('stage1_alt', app.wProj.stage1_alt(pse_name));
                    if ~isempty(app.multiline_stage1_row())
                        [config, pseObj] = multiline_stage2_config(config, pseObj);
                    end
            end
            % LCS Convergence: The GUI Asks Before The Run (lcs_convergence_confirm); The Library Must Never Prompt In The Command Window
            config.lcs_convergence_prompt = 0;
            % GUI File Names (Per Storm DB)
            config.out_files = out_files;
            if ~for_run
                return
            end
            % Hotstart: Library Level Actions (apply_hotstart_level). Not resolve_hotstart_state: The GUI Takes The Level From
            % The Run Dialog (run_hotstart_plan). Coldstart: Cached Forcing And LCS Seed Deleted (Already Moved To *_prev By backup_sim_files)
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
            % Save Config (Library Drivers Append To This File During The Run). RunSimulationButtonPushed Backs Up The Previous
            % One First (backup_sim_files) And Deletes The Backup Once The Results Are Saved, Or Restores It If The Run Fails
            out_pth = fileparts(out_files.config);
            if ~exist(out_pth, 'dir')
                mkdir(out_pth);
            end
            save(out_files.config, 'config', '-v7.3');
        end

        function elev = db_offshore_elevation(app, dbObj)
            % [NEW] Offshore Elevation Of A Storm DB: db_info Study Grid Value (Library storm_db_bias_uncertainty). [] When
            % The Storm DB Has None (Custom Modeling, No CHS_Dependencies, Grid Without Values): Inputs Table Value Is Used
            elev = [];
            if isstruct(dbObj.db_info) && isfield(dbObj.db_info, 'offshore_elevation') && ~isempty(dbObj.db_info.offshore_elevation)
                elev = dbObj.db_info.offshore_elevation;
            end
        end

        function fields = det_field_list(app, data)
            % [NEW] Deterministic Results: Plottable Fields (Forcing First, Then Responses), Same Order As det_methods.available_fields
            forcing = {'SWL', 'Hm0_offshore', 'Hm0_toe', 'Tp', 'h', 'Rc'};
            names = setdiff(fieldnames(data.Max), {'storm_id', 'time'}, 'stable')';
            fields = [forcing(ismember(forcing, names)), setdiff(names, forcing, 'stable')];
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
            if ~isempty(app.chess_projects) && any(strcmp(top, {app.chess_projects.name}))
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

        function [pse_name, alt_name] = get_active_names(app)
            % [NEW] Active PSE/Alternative Names ('' When None)
            pse_name = '';
            alt_name = '';
            if isempty(app.wProj) || isempty(app.pse_indx)
                return
            end
            pse_name = app.wProj.pse_list{app.pse_indx};
            if ~isempty(app.alt_indx)
                alt_name = app.wProj.alternative_list{app.pse_indx}{app.alt_indx};
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
            % Run Folder & File Names From The Library's chess_paths (Same Layout As The Library):
            % <project>\PSE\<pse>\<alt>\<workflow folder>\<db>_<workflow>_*, Per Storm DB So Runs With Different DBs Do Not Overwrite Each Other
            [pse_name, alt_name] = app.get_active_names();
            paths = chess_paths(app.wProj.path, app.wProj.name, pse_name, alt_name,...
                app.WorkflowDropDown.Value, app.StormDBDropDown_run.Value);
            out_dir = paths.wf_dir;
            wflow_folder = paths.wf_folder;
            wflow_name = paths.wflow_name;
            out_files = paths.out_files;
            out_path = out_files.config;
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
            % Snapshot Of Run Tab Controls (Component Name, Value). Inputs Table Values Live In tableState
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
            app.simState = sim_tab;
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

        function tf = has_active_alt(app)
            % [NEW] True When Active Project Has An Active PSE And Alternative
            tf = ~isempty(app.wProj) && ~isempty(app.pse_indx) && ~isempty(app.alt_indx);
        end

        function hide_results_mirror(app)
            % [NEW] Results Tab Back To Its Axes: Clear And Hide The Multi-Panel Mirror Panel
            delete(app.resultsMirror.Children);
            app.resultsMirror.Visible = 'off';
            app.PSEAxes_3.Visible = 'on';
        end

        function import_project_mat(app, mat_file)
            % [NEW] Import A Project From Its Project File <root>\<name>\CHESS_project_<name>.mat. Project Folder Not Where It
            % Was Saved (Moved, Copied, Extracted Archive): Stored Paths Relocated To <root>\<name> (Before append_project:
            % refresh_active_view Reads The Storm DB Paths). Then Locked (try_project_lock: Not Lockable -> Notice, Not
            % Imported), Its Simulation Registry Synced With Disk (chessProject.sync_sims 'sync'; Also Converts An Older
            % Project's Storm DB Objects To Records), Saved There; Multi-Line Stage 1 Drift Asked (stage1_sync_prompts); Sync
            % Counts In The Status Bar (None When Nothing Changed). The Previous Project Keeps Its Lock Until The Import Has
            % Succeeded; A Failure Releases The New Lock, Drops The Project And Re-Activates The Previous Selection
            S = load(mat_file);
            if ~isfield(S, 'chess_project') || ~isa(S.chess_project, 'chessProject')
                app.auxLib.error_dlgbox('Please select a valid "chessProject" class object.');
                return
            end
            wProj = S.chess_project;
            if ~isempty(app.chess_projects) && any(strcmp(wProj.name, {app.chess_projects.name}))
                app.auxLib.error_dlgbox(['Project "' wProj.name '" is already loaded.']);
                return
            end
            [new_root, folder_name] = fileparts(fileparts(mat_file));
            if ~strcmp(folder_name, wProj.name)
                app.auxLib.error_dlgbox(['The project file must be inside its project folder "' wProj.name '" (found in "' folder_name '").']);
                return
            end
            if ~chessProject.same_path(new_root, wProj.path)
                wProj.relocate(new_root);
            end
            % A CHS_Dependencies Folder Bundled In The Project (Export Project) Is Always Used
            bundle_dir = fullfile(new_root, wProj.name, 'CHS_Dependencies');
            if isfolder(bundle_dir)
                wProj.chs_dependencies = bundle_dir;
            end
            [lock, lock_msg] = app.try_project_lock(wProj);
            if isempty(lock)
                app.auxLib.choice_dlgbox(lock_msg, {'OK'}, 'Project Not Opened');
                return
            end
            prev_proj = '';
            if ~isempty(app.wProj)
                prev_proj = app.wProj.name;
            end
            [prev_pse, prev_alt] = app.get_active_names();
            try
                info = wProj.sync_sims('project', 'sync');
                app.append_project(wProj);
                app.save_project();
            catch ME
                chessProject.release_lock(lock);
                if ~isempty(app.chess_projects)
                    app.chess_projects = app.chess_projects(app.chess_projects ~= wProj);
                end
                try
                    app.set_active_selection(prev_proj, prev_pse, prev_alt);
                    app.refresh_active_view();
                catch
                end
                app.auxLib.error_dlgbox(['Could not import project "' wProj.name '": ' ME.message]);
                return
            end
            app.release_project_lock();
            app.set_project_lock(wProj, lock);
            if app.stage1_sync_prompts(wProj, info)
                app.refresh_active_view();
            end
            note = app.sync_note(info);
            if ~isempty(note)
                app.simStatusBar.Value = note;
            end
        end

        function proceed = lcs_convergence_confirm(app, pseObj, dbObj, prob_mass)
            % [NEW] LCS Convergence Dialog, Replacing The Library's Command-Window Prompt. Same Rule As chess_lcs
            % (lcs_reference_reuse): Effective Mode 0, Storm Types Not Reused From The Reference Case. Called Only When
            % Life Cycles Are Sampled (Coldstart; After The Run Dialog: A Hotstart Reuses The Cached Forcing Or Sampling).
            % Not Converged: "Set mcs_nLC To <nLC_req> And Run" | "Run Anyway" | "Cancel". Returns false On Cancel (Or Dialog Closed).
            proceed = true;
            config = app.create_resp_config(pseObj, dbObj, false);
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
            app.auxLib.choice_dlgbox(msg, options, 'LCS Convergence Check', [620, 150 + 20*numel(checks)]);
            answer = app.auxLib.dialog_answer;
            if isempty(answer) || strcmp(answer, 'Cancel')
                proceed = false;
            elseif startsWith(answer, 'Set mcs_nLC')
                % Write The Visible Table Row Too: set_input_table First Stores The Visible Table Into tableState
                row = strcmp(app.WorkflowInputsTable.Data(:, 1), 'mcs_nLC');
                app.WorkflowInputsTable.Data(row, 3) = {n_req};
                app.tableState.mcs_nLC = n_req;
                app.set_input_table(); % Inputs Table Shows (And The Run Reads) The New mcs_nLC
            end
        end

        function [s1_row, msg, run_label] = multiline_stage1_row(app)
            % Multi-Line Stage 2 Active: Its Stage 1's Registry Row (sim_rows: Responses File Checked, No Config Load) Of The Run
            % Tab Storm DB + Workflow. None: [] And The Status Bar Text Naming The Run Needed (Current Data Types And Storm
            % Type). Not A Stage 2 (Or No Storm DB): [] And ''
            %   run_label: '<storm DB> | <workflow>' Of The Run Tab ('' Without A Storm DB Or When Not A Stage 2)
            s1_row = [];
            msg = '';
            run_label = '';
            if ~app.has_active_alt() || isempty(app.StormDBDropDown_run.Items)
                return
            end
            [pse_name, alt_name] = app.get_active_names();
            if app.wProj.alt_stage(pse_name, alt_name) ~= 2
                return
            end
            s1_alt = app.wProj.stage1_alt(pse_name);
            [~, ~, ~, wflow_name] = app.get_config_path();
            db_name = app.StormDBDropDown_run.Value;
            run_label = [db_name ' | ' wflow_name];
            rows = app.sim_rows(app.wProj, pse_name, s1_alt);
            rows = rows(strcmpi(db_name, {rows.db}) & strcmpi(wflow_name, {rows.workflow}));
            if ~isempty(rows)
                s1_row = rows(1);
                return
            end
            dt_checked = app.get_checked_symbols(app.DataTypesTree);
            dts = {};
            if any(ismember({'peaks_default', 'create_wlp', 'create_whp'}, dt_checked))
                dts{end+1} = 'Peaks';
            end
            if ismember('use_timeseries', dt_checked)
                dts{end+1} = 'Timeseries';
            end
            msg = sprintf('Run %s/%s with %s, %s, %s first.', pse_name, s1_alt, wflow_name,...
                strjoin([dts, {app.StormTypeDropDown_2.Value}], ', '));
        end

        function cascade = multiline_cascade_sims(app, proj, pse_name, alt_name, db_wf)
            % Stage 2 Registry Rows (sim_rows) Coupled To alt_name (A Multi-Line Stage 1) With A Storm DB + Workflow Of db_wf
            % (Rows {db, workflow}). cascade: Rows {stage 2 alternative, db, workflow}; None (Or Not A Stage 1): Empty
            cascade = cell(0, 3);
            for s2 = proj.multiline_stage2(pse_name, alt_name)'
                rows = app.sim_rows(proj, pse_name, s2{1});
                for rr = 1:numel(rows)
                    if any(strcmpi(rows(rr).db, db_wf(:, 1)) & strcmpi(rows(rr).workflow, db_wf(:, 2)))
                        cascade(end+1, :) = {s2{1}, rows(rr).db, rows(rr).workflow}; %#ok<AGROW>
                    end
                end
            end
        end

        function ok = lock_project(app, proj)
            % One CHESS Session Per Project: Locks proj's Folder (try_project_lock) Before It Becomes Active, Then Releases The
            % Previous Project's Lock. Already Held By This App: true. Not Lockable (Held By Another Session, Folder Missing Or
            % Read-Only): Modal Notice With OK Only (The GUI Waits For It), false: The Caller Keeps The Previous Selection
            ok = true;
            if ~isempty(app.projectLock) && app.projectLock.proj == proj
                return
            end
            [lock, msg] = app.try_project_lock(proj);
            if isempty(lock)
                ok = false;
                app.auxLib.choice_dlgbox(msg, {'OK'}, 'Project Not Opened');
                return
            end
            app.release_project_lock();
            app.set_project_lock(proj, lock);
        end

        function [lock, msg] = try_project_lock(app, proj)
            % chessProject.acquire_lock Of proj's Folder, Nothing Else Changed (projectLock Untouched). Refused: lock = [], msg =
            % The Notice Text (Another Session Holds It, Or Why The Lock File Is Not Usable)
            msg = '';
            [lock, holder, problem] = chessProject.acquire_lock(fullfile(proj.path, proj.name));
            if isempty(lock) && isempty(problem)
                msg = sprintf('Project %s is open in another CHESS session (%s).', proj.name, holder);
            elseif isempty(lock)
                msg = sprintf('Project %s cannot be locked: %s.', proj.name, problem);
            end
        end

        function release_project_lock(app)
            % Releases The Active Project's Lock (lock_project), If Any: Project Switch, Project Folder Rename, App Close (Close
            % Request; A Bypassed Close Request Is Covered By The UIFigure DeleteFcn, startupFcn). Idempotent
            if ~isempty(app.projectLock)
                chessProject.release_lock(app.projectLock.lock);
                app.set_project_lock([], []);
            end
        end

        function set_project_lock(app, proj, lock)
            % projectLock Of The Active Project (proj [] : None), Mirrored In The UIFigure's Application Data
            % 'chess_project_lock': The DeleteFcn (startupFcn) Releases It From There, As The App Object Can Already Be Gone
            if isempty(proj)
                app.projectLock = [];
            else
                app.projectLock = struct('proj', proj, 'lock', lock);
            end
            setappdata(app.UIFigure, 'chess_project_lock', lock);
        end

        function chs_data = load_chs_data(app, dbObj)
            % [NEW] Cached Load Of Raw CHS_Data (Storm DB "_raw_files.mat"); [] If Unavailable
            chs_data = [];
            if ~isfield(dbObj.output_paths, 'chs_data') || ~isfile(dbObj.output_paths.chs_data)
                return
            end
            key = dbObj.output_paths.chs_data;
            if isempty(app.stormCache)
                app.stormCache = containers.Map();
            end
            if ~isKey(app.stormCache, key)
                S = load(key, 'CHS_Data');
                app.stormCache(key) = S.CHS_Data;
            end
            chs_data = app.stormCache(key);
        end

        function load_saved_sim(app)
            % [NEW] Restore The Saved Simulation Of The Current Key: Run Tab Inputs (Saved Config) And Results
            app.simKey = app.sim_key(); % Resolved: populateResultsTab Loads It
            app.declinedSimKey = '';
            app.set_sim_state(2, app.get_config_path());
            app.populate_pse_table();
            app.populate_constants_table();
            app.set_input_table();
            app.populateResultsTab();
        end

        function storm = load_storm(app, dbObj)
            % [NEW] Cached Load Of Storm DB "storm" Variable
            key = dbObj.output_paths.storm_db;
            if isempty(app.stormCache)
                app.stormCache = containers.Map();
            end
            if ~isKey(app.stormCache, key)
                S = load(key, 'storm');
                app.stormCache(key) = S.storm;
            end
            storm = app.stormCache(key);
        end

        function msg = loaded_sim_status(app)
            % [NEW] Status Bar Text Of The Saved Simulation Shown
            [~, ~, ~, wflow_name] = app.get_config_path();
            [~, ~, run_date] = app.saved_sim();
            msg = sprintf('Saved simulation loaded (%s_%s, run %s).', app.StormDBDropDown_run.Value, wflow_name, run_date);
        end

        function config = localize_saved_config(app, config)
            % [NEW] Saved Run config Of A Moved Project (chessProject.relocate): A tide_file Under The Run's Project Folder
            % (<outfolder>\<project_name>) Points Into The Active Project Folder. 'None' And Paths Elsewhere Unchanged
            config.tide_file = chessProject.relocate_path(config.tide_file,...
                fullfile(config.outfolder, config.project_name), fullfile(app.wProj.path, app.wProj.name));
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
            state = app.resultsState;
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
                storm = app.load_storm(state.dbObj);
                config.sp_ID = CHSStormDBImportUI.get_savepoint_id(state.dbObj); % Title (GUI Run Configs Leave sp_ID Empty)
            end
            project_forcing = state.project_forcing;
            if add_events > 0 || strcmp(row.key, 'scheme') % Events Overlay / Sampling Scheme Need Project Forcing + TC Probability Masses
                [project_forcing, dsw] = app.results_forcing_and_dsw();
            end
            chessPlot = CHESSPlots(config, state.Resp, storm, project_forcing, dsw, state.structure, base_fnt, app.wProj.unitsys);
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
                        fields = app.det_field_list(aux_methods.pull_data(ds_query, state.Resp));
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
                        [edges, labels] = app.results_bin_edges(chessPlot, ds_query, field, opts.bin_edges);
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
                uialert(app.UIFigure, me.message, ['Results Plot: ' row.label], 'Icon', 'warning');
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
            dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown.Value, '', 'db');
            if ~app.storm_db_info_ok(dbObj)
                cla(ax);
                legend(ax, 'off');
                if tab_mode
                    app.StormDBTable.Data = cell(0, 2);
                end
                return
            end
            storm = app.load_storm(dbObj);
            ds_query = struct('storm_type', app.StormTypeDropDown.Value,...
                'data_type', app.DataTypeDropDown.Value,...
                'match_type', app.MatchTypeDropDown.Value);
            % Library Plot Object (Storm Database Only: No PSE, Workflow Or Results)
            config = struct('project_datum', app.wProj.vdatum, 'apply_random_tides', 0,...
                'region', dbObj.study, 'sp_ID', CHSStormDBImportUI.get_savepoint_id(dbObj), 'struc_id', '', 'case_name', '',...
                'r2p_u', 0, 'q_u', 0, 'dn50_u', 0, 'p1_u', 0,... % Axis Labels Only (response_library_headers)
                'chs_swl_u_a', 0, 'chs_swl_u_r', 0, 'chs_hm0_u_a', 0, 'chs_hm0_u_r', 0);
            % TC SWL Bias Correction State & Coefficients From The Storm DB's db_info (Raw Signal Is Corrected Like The Imported storm)
            db_info = CHSStormDBImportUI.get_db_info(dbObj);
            config.tc_bias_corrected = db_info.tc_bias_corrected;
            config.chs_swl_b_a = db_info.chs_swl_b_a;
            config.chs_swl_b_r = db_info.chs_swl_b_r;
            chessPlot = CHESSPlotsBase(config, [], storm, [], [], [], base_fnt, app.wProj.unitsys);
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
                    chessPlot.event_hydrograph_plot(ax, ds_query, event_id, y_field, app.load_chs_data(dbObj));
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
            % Inputs Table: Pertinent Rows Only (Library Template), Values From tableState (All Workflows)
            app.store_table_values();
            [pse_name, alt_name] = app.get_active_names();
            pse_obj = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            if isempty(pse_obj)
                app.WorkflowInputsTable.Data = cell(0, 3);
                return
            end
            tpl = app.wProj.get_library_template(pse_obj.pse_type);
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
                    % csr_compute_S_submerged Is Never Shown. Hidden Values Stay In tableState
                    if chessProject.get_struc_type(pse_obj.pse_type) == 3 && ismember('use_timeseries', app.get_checked_symbols(app.DataTypesTree))
                        csr = tpl.csr(~strcmp(tpl.csr(:, 1), 'csr_compute_S_submerged'), :);
                        is_call = strcmp(csr(:, 1), 'csr_call_dpa');
                        dpa_on = csr{is_call, 4};
                        if isfield(app.tableState, 'csr_call_dpa')
                            dpa_on = app.tableState.csr_call_dpa;
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
            % Values: tableState (Entered/Restored) Else Template Default
            tbl = [rows(:, 1:2), rows(:, 4)];
            for kk = 1:size(tbl, 1)
                if isfield(app.tableState, tbl{kk, 1})
                    tbl{kk, 3} = app.tableState.(tbl{kk, 1});
                end
            end
            tbl(is_flag, 3) = cellfun(@(v) isequal(v, 1), tbl(is_flag, 3), 'un', false);
            app.WorkflowInputsTable.Data = tbl;
        end

        function populate_project_panel(app)
            % Update Project Tree
            app.update_project_tree();
            % No Projects Loaded
            if isempty(app.chess_projects)
                app.ProjectDropDown.Items = {};
                app.PSEDropDown.Items = {};
                app.AlternativeDropDown.Items = {};
                app.ProjectPathEditField.Value = '';
                app.PSEMenu.Enable = false;
                app.AlternativeMenu.Enable = false;
                return
            end
            % Project Dropdown
            projList = {app.chess_projects.name};
            app.ProjectDropDown.Items = projList;
            app.ProjectDropDown.Value = projList{app.proj_indx};
            app.ProjectPathEditField.Value = app.wProj.get_project_field('path', '', '', 'proj');
            % PSE & Alternative Dropdowns
            [pse_name, alt_name] = app.get_active_names();
            pseList = app.wProj.pse_list;
            app.PSEDropDown.Items = pseList;
            if ~isempty(pse_name)
                app.PSEDropDown.Value = pse_name;
                app.AlternativeDropDown.Items = app.wProj.alternative_list{app.pse_indx};
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
            [pse_name, alt_name] = app.get_active_names();
            pse_obj = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            if isempty(pse_obj)
                return
            end
            tpl = app.wProj.get_library_template(pse_obj.pse_type);
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
                % Multi-Line Stage 1: Hm0t Is Its Stage 2 Forcing, Always On (create_resp_config; Re-Checked By set_input_table)
                if strcmp(resp_sym{rr}, 'compute_wave_transmission') && app.wProj.alt_stage(pse_name, alt_name) == 1
                    txt = [txt ' (Multi-Line Stage 1: Always On)'];
                end
                uitreenode(app.ResponsesTree, "Text", txt, 'NodeData', resp_sym{rr});
            end
        end

        function populate_constants_table(app)
            % [NEW] Project Panel Constants Table (Display Only; Gravity Constant Is Read By Label): Water Density (Active PSE,
            % As Used By Runs), Gravity (Library Value), Offshore Elevation (shown_offshore_elevation) And The Run Tab Storm
            % DB's Bias & Uncertainty (db_info, Library storm_db_info). No Storm DB: '-'. db_info Missing Fields: Re-Import
            gravity = 9.80665; % m/s^2, Library Value (Setup/call_input_parser.m)
            density = {'-', NaN};
            offshore = {'-', '-'};
            dbObj = [];
            % Multi-Line Transect Row; Stage 2: Offshore End From Stage 1 (Library multiline_stage2_config), Slope Row Added
            ml_rows = {'Multi-Line Transect', '-', '-'};
            offshore_lbl = 'Offshore Elevation (Storm DB / PSE)';
            if app.has_active_alt()
                [pse_name, alt_name] = app.get_active_names();
                switch app.wProj.alt_stage(pse_name, alt_name)
                    case 1
                        ml_rows{3} = sprintf('Stage 1 (%d coupled)', numel(app.wProj.multiline_stage2(pse_name, alt_name)));
                    case 2
                        % From Stage 1's Registry Row Of The Run Tab Storm DB + Workflow (multiline_stage1_row), Never Its PSE Table
                        s1_alt = app.wProj.stage1_alt(pse_name);
                        s1_row = app.multiline_stage1_row();
                        s1_note = 'Run stage 1 first';
                        if isempty(app.StormDBDropDown_run.Items)
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
                tbl = app.wProj.get_project_field('pse_tables', pse_name, alt_name, 'alt');
                geo = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                density = {erase(tbl{strcmp(tbl(:, 1), 'water_density'), 3}, {'[', ']'}), geo.water_density};
                if ~isempty(app.StormDBDropDown_run.Items)
                    dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown_run.Value, '', 'db');
                end
                unitLib = app.auxLib.update_unit_system(app.wProj.unitsys);
                offshore = {unitLib.unitSymbols.length, app.shown_offshore_elevation(dbObj)};
                if app.wProj.alt_stage(pse_name, alt_name) == 2 && isnan(offshore{2})
                    offshore{2} = s1_note;
                end
            end
            % Storm DB Rows. DET Runs Without Forcing Uncertainty
            u_note = '';
            if app.WorkflowDropDown.Value == 2
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
            app.ConstantsTable.Data = [{'Water Density', density{:}; 'Gravity Constant', 'm/s^2', gravity;...
                offshore_lbl, offshore{:}}; ml_rows; db_rows];
        end

        function populate_pse_table(app)
            % [NEW] PSE Viewer Table: The Active Alternative's pse_tables. The offshore_elevation Row (Fallback Value) Is Shown Only
            % When The Run Tab Storm DB Has No Study Grid Value, Or There Is No Run Tab Storm DB; Multi-Line Stage 2: Neither It Nor
            % offshore_slope (From Stage 1). Display Only: pse_tables Keeps Them
            if ~app.has_active_alt()
                app.PSETable.Data = cell(0, 4);
                return
            end
            [pse_name, alt_name] = app.get_active_names();
            tbl = app.wProj.get_project_field('pse_tables', pse_name, alt_name, 'alt');
            dbObj = [];
            if ~isempty(app.StormDBDropDown_run.Items)
                dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown_run.Value, '', 'db');
            end
            if app.wProj.alt_stage(pse_name, alt_name) == 2 % Multi-Line Stage 2: Offshore End From Stage 1 (multiline_stage2_config)
                tbl = tbl(~ismember(tbl(:, 1), {'offshore_elevation', 'offshore_slope'}), :);
            elseif ~isempty(dbObj) && ~isempty(app.db_offshore_elevation(dbObj))
                tbl = tbl(~strcmp(tbl(:, 1), 'offshore_elevation'), :);
            end
            app.PSETable.Data = tbl;
        end

        function populate_stormDB_panel(app, dbObj, db_list)
            % Load Storm (Cached). Storm DB File Missing Or Unreadable: Empty Tab With The Storm DB Listed And A Re-Import Note
            try
                storm = app.load_storm(dbObj);
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
            % Load Results For Active Alternative / Workflow / Storm DB (Auto-Load) + Status Line
            app.resultsState = [];
            if ~app.has_active_alt() || isempty(app.StormDBDropDown_run.Value)
                app.reset_tab('results');
                app.set_sim_status('');
                return
            end
            % Switch Pending (Key Differs From The Last Resolved One): sync_saved_sim Decides Whether To Load
            if ~isequal(app.sim_key(), app.simKey)
                app.reset_tab('results');
                app.set_sim_status('');
                return
            end
            % Load Declined ("Keep current inputs") For This Key: Results Stay Cleared Until The Key Changes, The Run Dialog's
            % "Load existing" Loads It Or A Run Succeeds (Internal Refreshes Do Not Load It)
            if ~isempty(app.declinedSimKey) && isequal(app.sim_key(), app.declinedSimKey)
                app.reset_tab('results');
                app.set_sim_status('Current simulation already exists. Load declined.');
                return
            end
            [config_file, ~, ~, ~, out_files] = app.get_config_path();
            [has_sim, label] = app.saved_sim();
            if ~has_sim
                app.reset_tab('results');
                app.set_sim_status(['No saved simulation for ' label '.']);
                return
            end
            % Load Results & Run Config (Other Plot Data Is Loaded On Demand By plot_project_responses)
            S = load(out_files.resp_data, 'Resp');
            % Run's Structure (Saved By The Library call_project_response, With The Run's Resolved Offshore Elevation), Not The Current PSE
            C = load(config_file, 'config', 'structure');
            C.config = app.localize_saved_config(C.config);
            state = struct('Resp', S.Resp, 'config', C.config, 'structure', C.structure,...
                'project_forcing', [], 'prob_mass', [], 'out_files', out_files,...
                'dbObj', app.wProj.get_project_field('stormDB_list', app.StormDBDropDown_run.Value, '', 'db'));
            if any(C.config.workflow == [2 3]) && isfile(out_files.project_forcing) % DET (Forcing Not Copied Into Resp) & LCS Plots Need Project Forcing
                P = load(out_files.project_forcing, 'project_forcing');
                state.project_forcing = P.project_forcing;
            end
            app.resultsState = state;
            % Status: Saved Run Config Vs Current Run Tab Inputs
            app.set_sim_status(app.results_status());
            % Plot Types Available For This Run (Library Plot Catalog)
            cat = app.results_plot_catalog();
            app.PlotTypeDropDown.Items = {cat.label};
            app.PlotTypeDropDown.ItemsData = {cat.key};
            app.Panel_2.Enable = true;
            app.update_results_controls('plot');
            app.plot_project_responses();
        end

        function populateSimulationTab(app)
            % Snapshot Current Run Tab State (Restored If Context Is Unchanged)
            app.get_sim_state();
            % Nothing To Show Without An Alternative And A Storm DB
            dbList = [];
            if app.has_active_alt()
                dbList = app.wProj.get_project_field('stormDB_list', '', '', 'proj');
            end
            if isempty(dbList)
                app.reset_tab('sim');
                app.simContext = '';
                return
            end
            [pse_name, alt_name] = app.get_active_names();
            context = strjoin({app.wProj.name, pse_name, alt_name}, '|');
            new_context = ~strcmp(context, app.simContext);

            % 1. Storm DB (New Context: The Alternative's Newest Simulation, chessProject.default_db; Else Keep User Choice)
            db_names = {dbList.db_name};
            current_db = app.StormDBDropDown_run.Value;
            app.StormDBDropDown_run.Items = db_names;
            default_db = app.wProj.default_db(pse_name, alt_name);
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
            tide_files = app.wProj.tide_files_list(:);
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
            app.simContext = context;

            % 6. Inputs Table & Run Button (Constants Table: Callers Run populate_constants_table Next)
            app.set_input_table();
        end

        function project_field_ini(app)
            % This function ensures all chess_project fields dimensions stay
            % in sync. Needs to be called once a PSE/Alternative is created
            if ~isempty(app.wProj)
                app.wProj.sync_alt_fields();
            end
        end % End Function

        function [offshore_elevation, elevation_source] = pse_popout_offshore_elevation(app)
            % [NEW] Offshore Elevation For The PSE Pop-Out Text Box: Study Grid Value Of The Storm DB Selected On The Run Tab
            % (Defaults To The Alternative's Last-Run DB), Else The PSE Geometry Value. None -> [] (chessProject.plot_geometry
            % Keeps The PSE Value, Else The Library Shows 'n/a').
            offshore_elevation = [];
            elevation_source = '';
            if isempty(app.wProj) || isempty(app.wProj.stormDB_list) || isempty(app.StormDBDropDown_run.Items)
                return
            end
            db_name = app.StormDBDropDown_run.Value;
            dbObj = app.wProj.get_project_field('stormDB_list', db_name, '', 'db');
            if isempty(dbObj)
                return
            end
            % Multi-Line Stage 2: The Plot Starts With Stage 1 (plot_pse_geometry), The Text Box Is Stage 1's Offshore End As
            % Its Runs Resolve It (Storm DB Grid, Else Stage 1's PSE Value). No Stage 1 Run (multiline_stage1_row): Stage 2
            % Plotted Alone, No Text Box
            [pse_name, alt_name] = app.get_active_names();
            if app.wProj.alt_stage(pse_name, alt_name) == 2
                if isempty(app.multiline_stage1_row())
                    return
                end
                alt_name = app.wProj.stage1_alt(pse_name);
            end
            [offshore_elevation, elevation_source] = app.shown_offshore_elevation(dbObj, alt_name);
            if strcmp(elevation_source, 'Storm DB grid')
                elevation_source = ['Storm DB: ' db_name];
            elseif isnan(offshore_elevation)
                offshore_elevation = [];
            end
        end

        function plot_pse_geometry(app, ax, base_fnt, keep_text_box)
            % Active Alternative's Transect Into ax (chessProject.plot_geometry). keep_text_box: Pop-Out Text Box (Offshore End:
            % pse_popout_offshore_elevation). Multi-Line Stage 2: In Line Behind Stage 1 As Run For The Run Tab Storm DB +
            % Workflow (multiline_stage1_row: Stage 1's PSE Geometry With That Run's Kt Geometry, Row structure_kt); No Such Run:
            % Stage 2 Alone With A Note
            [pse_name, alt_name] = app.get_active_names();
            [offshore_elevation, elevation_source] = deal([], '');
            if keep_text_box
                [offshore_elevation, elevation_source] = app.pse_popout_offshore_elevation();
            end
            stage1 = [];
            if app.wProj.alt_stage(pse_name, alt_name) == 2
                [s1_row, ~, run_label] = app.multiline_stage1_row();
                if isempty(run_label)
                    stage1 = 'Stage 1 not shown: no Run tab storm DB';
                elseif isempty(s1_row)
                    stage1 = ['Stage 1 not run for ' run_label];
                else
                    stage1 = app.wProj.get_project_field('pse_geometry', pse_name, app.wProj.stage1_alt(pse_name), 'alt');
                    for fld = fieldnames(s1_row.structure_kt)'
                        stage1.(fld{1}) = s1_row.structure_kt.(fld{1});
                    end
                end
            end
            app.wProj.plot_geometry(pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source, stage1);
        end

        function replot_multiline_stage2(app)
            % Run Tab Storm DB / Workflow Changed: A Multi-Line Stage 2 Plot Shows Stage 1's Run Of The New Pair
            if ~app.has_active_alt()
                return
            end
            [pse_name, alt_name] = app.get_active_names();
            if app.wProj.alt_stage(pse_name, alt_name) == 2
                app.plot_pse_geometry(app.PSEAxes, app.plotFontSize, false);
            end
        end

        function value = pull_input_table_value(app, table_data, field_to_get)
            pull_indx = strcmp(table_data(:, 1), field_to_get);
            if ~any(pull_indx)
                value = [];
            else
                value = +table_data{find(pull_indx, 1), end};
            end
        end

        function refresh_active_view(app, user_switch)
            % [NEW] Single Refresh Pipeline: Project Panel & Tree -> PSE Tab -> Storm DB Tab -> Run Tab -> Results Tab -> Saved Simulation.
            %   user_switch = true: Tree / Project / PSE / Alternative Selection By The User (May Ask To Load A Saved Simulation)
            if nargin < 2
                user_switch = false;
            end
            app.populate_project_panel();
            % Storm DB Viewer (The Alternative's Newest Simulation, chessProject.default_db; Else First)
            dbList = [];
            if ~isempty(app.wProj)
                dbList = app.wProj.get_project_field('stormDB_list', '', '', 'proj');
            end
            if isempty(dbList)
                app.reset_tab('db');
            else
                db_indx = [];
                if app.has_active_alt()
                    [pse_name, alt_name] = app.get_active_names();
                    db_indx = find(strcmp(app.wProj.default_db(pse_name, alt_name), {dbList.db_name}), 1);
                end
                if isempty(db_indx)
                    db_indx = 1;
                end
                app.populate_stormDB_panel(dbList(db_indx), {dbList.db_name});
            end
            % CHESS Run & Results Viewer. PSE Viewer After The Run Tab (A Multi-Line Stage 2 Plot Follows Its Storm DB + Workflow)
            app.populateSimulationTab();
            if app.has_active_alt()
                app.plot_pse_geometry(app.PSEAxes, app.plotFontSize, false);
            else
                app.reset_tab('pse');
            end
            app.populate_pse_table();
            app.populate_constants_table();
            app.populateResultsTab();
            % Saved Simulation Of A New Alternative / Workflow / Storm DB (Dialog Only On A User Switch)
            app.sync_saved_sim(user_switch);
        end

        function rebuild_sims(app, proj)
            % Project Tree Right-Click "Rebuild simulations from disk": The Active Project's Registry Rebuilt From Every Bundle On
            % Disk (chessProject.sync_sims 'full'), Saved, Multi-Line Stage 1 Drift Asked (stage1_sync_prompts), Refreshed;
            % Counts Reported. Only The Active Project (The One This Session Holds The Lock Of)
            title_str = 'Rebuild Simulations From Disk';
            if app.runActive
                uialert(app.UIFigure, 'Rebuilding is not available while a run is in progress.', title_str, 'Icon', 'info');
                return
            end
            if isempty(app.wProj) || proj ~= app.wProj
                uialert(app.UIFigure, sprintf('Select project "%s" first: only the active project can be rebuilt.', proj.name),...
                    title_str, 'Icon', 'info');
                return
            end
            info = proj.sync_sims('project', 'full');
            app.save_project(proj);
            app.stage1_sync_prompts(proj, info);
            % Saved Simulation Key Re-Resolved, Loaded Results Dropped; Refresh (Tree Included)
            app.simKey = [];
            app.declinedSimKey = '';
            app.resultsState = [];
            [act_pse, act_alt] = app.get_active_names();
            app.set_active_selection(proj.name, act_pse, act_alt);
            app.refresh_active_view();
            msg = sprintf('Simulations rebuilt from disk: %d added, %d refreshed, %d dropped.', info.added, info.refreshed, info.dropped);
            if info.skipped > 0
                msg = sprintf('%s\n%d simulation(s) skipped: their config file could not be read.', msg, info.skipped);
            end
            uialert(app.UIFigure, msg, title_str, 'Icon', 'info');
        end

        function remove_alt_sims(app, proj, pse_name, alt_name, sim_label)
            % Delete Simulation Bundles (Registry Rows, sim_rows: Run Files Of One Storm DB + Workflow) Of An Alternative Of proj.
            % sim_label '': Dialog (Alternatives Of pse_name, Starting On alt_name; Its Bundles, One Or More), Else That Bundle
            % After A Confirmation. A Multi-Line Stage 1 Bundle Takes The Stage 2 Bundles Of The Same Storm DB + Workflow With
            % It. Files And Rows Go Through chessProject.delete_sim (delete_sim_rows). Only The Active Project (Locked)
            title_str = 'Remove Alternative Simulation';
            if app.runActive
                uialert(app.UIFigure, 'Removing is not available while a run is in progress.', title_str, 'Icon', 'info');
                return
            end
            if isempty(app.wProj) || proj ~= app.wProj
                uialert(app.UIFigure, sprintf('Select project "%s" first: only the active project can be changed.', proj.name),...
                    title_str, 'Icon', 'info');
                return
            end
            % Dialog Lists: Rows Without Repair (No Save Or Drift Prompt From Inside The Dialog); The Chosen Alternative Is
            % Repaired Once The Dialog Has Closed (app.sim_rows Below)
            labels_of = @(a) arrayfun(@chessProject.sim_label, proj.sim_rows(pse_name, a, false), 'un', false);
            if isempty(sim_label)
                alts = proj.alternative_list{strcmp(proj.pse_list, pse_name)};
                app.auxLib.dropdown_list_dlgbox(sprintf(['Delete simulations of PSE "%s" with all their run files. Choose the ',...
                    'alternative, then one or more simulations (storm DB | workflow; Ctrl+click selects several).'], pse_name),...
                    title_str, 'Alternative:', alts, alt_name, labels_of, 'Delete');
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
            rows = app.sim_rows(proj, pse_name, alt_name);
            rows = rows(ismember(arrayfun(@chessProject.sim_label, rows, 'un', false), labels));
            if isempty(rows)
                return
            end
            del = [repmat({alt_name}, numel(rows), 1), {rows.db}', {rows.workflow}'];
            % Multi-Line Stage 1: Stage 2 Bundles Of The Same Storm DB + Workflow Use Its Results
            cascade = app.multiline_cascade_sims(proj, pse_name, alt_name, del(:, 2:3));
            if ~isempty(cascade)
                lines = strcat({['  ' char(8226) ' ']}, cascade(:, 1), {': '}, cascade(:, 2), {' | '}, cascade(:, 3));
                app.auxLib.choice_dlgbox(sprintf(['"%s" is the first stage of a multi-line transect. These second-stage ',...
                    'simulations use its results and are deleted too:\n%s'], alt_name, strjoin(lines, newline)),...
                    {'Delete', 'Cancel'}, title_str, 560);
                if ~strcmp(app.auxLib.dialog_answer, 'Delete')
                    return
                end
                del = [del; cascade];
            end
            failed = app.delete_sim_rows(proj, pse_name, del);
            % Saved Simulation Key Re-Resolved, Loaded Results Dropped; Refresh (Tree Included) & Save
            app.simKey = [];
            app.declinedSimKey = '';
            app.resultsState = [];
            [act_pse, act_alt] = app.get_active_names();
            app.set_active_selection(app.wProj.name, act_pse, act_alt);
            app.refresh_active_view();
            app.save_project(proj);
            if ~isempty(failed)
                uialert(app.UIFigure, sprintf(['Deleted, but these files could not be deleted (a file may be open in another ',...
                    'program):\n%s\nClose it and remove the simulation again.'], strjoin(failed, newline)), title_str, 'Icon', 'warning');
            end
        end

        function failed = delete_sim_rows(app, proj, pse_name, rows)
            % Deletes Simulation Bundles Of PSE pse_name (Rows {alternative, db, workflow}): Files And Registry Row
            % (chessProject.delete_sim). failed: Files Not Deleted
            failed = cell(0, 1);
            for dd = 1:size(rows, 1)
                failed = [failed; proj.delete_sim(pse_name, rows{dd, :})]; %#ok<AGROW>
            end
        end

        function rename_tree_node(app, node)
            % Project Tree Right-Click "Rename...": Project, PSE Or Alternative Of node (chessProject.rename: Folder, Stored Paths,
            % Saved Run Configs). Session State Holding The Old Paths/Names Follows The Rename, So The View Stays As It Was.
            % Only The Active Project (Locked By This Session)
            if app.runActive
                uialert(app.UIFigure, 'Rename is not available while a run is in progress.', 'Rename', 'Icon', 'info');
                return
            end
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
            proj_names = {app.chess_projects.name};
            proj = app.chess_projects(strcmp(proj_names, proj_node.NodeData.name));
            if isempty(app.wProj) || proj ~= app.wProj % Only The Project This Session Holds The Lock Of
                uialert(app.UIFigure, sprintf('Select project "%s" first: only the active project can be renamed.', proj.name),...
                    'Rename', 'Icon', 'info');
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
            % Active Selection And Run Tab Context Before The Rename (Kept, Under The New Name)
            act_proj = app.wProj.name;
            [act_pse, act_alt] = app.get_active_names();
            ctx_before = strjoin({act_proj, act_pse, act_alt}, '|');
            % The Active Project's Lock File Is Open Inside Its Folder: Released For The Folder Move, Taken Again After (Not
            % Taken: Warning, The Project Stays Open Without A Lock; Selecting It Again Retries)
            relock = strcmp(level, 'proj') && ~isempty(app.projectLock) && app.projectLock.proj == proj;
            if relock
                app.release_project_lock();
            end
            rename_err = [];
            try
                info = proj.rename(level, new_name, pse_name, alt_name, siblings);
            catch rename_err
            end
            lock_warn = '';
            if relock
                [lock, lock_msg] = app.try_project_lock(proj);
                if isempty(lock)
                    lock_warn = sprintf(['%s\nThe project is open without a lock: another CHESS session could open and change ',...
                        'it too. Select the project again to retry.'], lock_msg);
                else
                    app.set_project_lock(proj, lock);
                end
            end
            if ~isempty(rename_err)
                app.auxLib.error_dlgbox(['Could not rename "' current '": ' rename_err.message]);
                if ~isempty(lock_warn)
                    uialert(app.UIFigure, lock_warn, 'Project Not Locked', 'Icon', 'warning');
                end
                return
            end
            is_active = proj == app.wProj;
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
            if strcmp(app.simContext, ctx_before)
                app.simContext = strjoin({act_proj, act_pse, act_alt}, '|');
            end
            % Paths Under The Moved Folder: Cached storm/CHS_Data Dropped (Reloaded From The New Paths); Saved Simulation Keys
            % (get_config_path) And Older-DB Alerts Remapped; Loaded Results Reloaded By refresh_active_view
            remap = @(p) chessProject.relocate_path(p, info.old_dir, info.new_dir);
            keys = app.stormCache.keys();
            moved = keys(~strcmp(keys, cellfun(remap, keys, 'un', false)));
            if ~isempty(moved)
                remove(app.stormCache, moved);
            end
            app.simKey = remap(app.simKey);
            app.declinedSimKey = remap(app.declinedSimKey);
            app.oldDbWarned = cellfun(remap, app.oldDbWarned, 'un', false);
            app.resultsState = [];
            app.save_project(proj);
            app.set_active_selection(act_proj, act_pse, act_alt);
            app.refresh_active_view();
            if ~isempty(info.failed)
                lock_warn = strtrim(sprintf('%s\n\n%s', sprintf('Renamed to "%s", but these files could not be updated:\n%s',...
                    new_name, strjoin(info.failed, newline)), lock_warn));
            end
            if ~isempty(lock_warn)
                uialert(app.UIFigure, lock_warn, 'Rename', 'Icon', 'warning');
            end

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

        function restore_leftover_backups(app, bk)
            % [NEW] *_prev Files At Run Start: The Last Run Never Finished (e.g. MATLAB Closed), Put The Previous Run Back First
            for kk = 1:numel(bk)
                if isfile(bk(kk).prev)
                    movefile(bk(kk).prev, bk(kk).file, 'f');
                end
            end
        end

        function failed = restore_sim_files(app, backed)
            % [NEW] Failed Run: Put Back What This Run Backed Up (*_prev Moved Over Whatever The Run Left) And Delete The Files
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

        function [lbl, items, on] = results_aux_items(app, key, data, ds_query)
            % [NEW] Storm ID Dropdown Per Plot Type: Event ID, Life Cycle Or A Plot Option
            lbl = 'Storm ID:';
            items = {'-'};
            on = false;
            lc_items = @(n) [{'All'}, arrayfun(@num2str, 1:n, 'un', false)];
            switch key
                case 'hc' % No Numeric Run Sample (CC Is Derived, FB POT Is A Note): Nothing To Overlay (pros_methods.hc_plot Gate)
                    lbl = 'Add Events:';
                    sel = data(strcmp({data.var}, app.FieldToPlotDropDown_results.Value));
                    if strcmp(ds_query.storm_type, 'CC') || isempty(sel) || ~isnumeric(sel(1).POT)
                        items = {'Off'};
                    else
                        items = {'Off', 'Run Sample', 'Storm Values'};
                        on = true;
                    end
                case 'det_scatter' % X Axis (Color: Right-Click Plot Options)
                    lbl = 'X Axis:';
                    items = app.det_field_list(data);
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
                        stm_data = aux_methods.pull_data(ds_query, app.load_storm(app.resultsState.dbObj));
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
                    field = app.FieldToPlotDropDown_results.Value;
                    items = {'All'};
                    if startsWith(field, 'S_') && isfield(data, 'S') && isfield(data.S, field)
                        items = lc_items(numel(data.S.(field)));
                        on = true;
                    end
                case 'sampling'
                    lbl = 'Life Cycle:';
                    items = lc_items(numel(aux_methods.pull_data(ds_query, app.resultsState.project_forcing)));
                    on = true;
                case 'submergence'
                    lbl = 'X Scale:';
                    items = {'Linear', 'Log'};
                    on = true;
            end
        end

        function [edges, labels] = results_bin_edges(app, chessPlot, ds_query, field, edges)
            % [NEW] Annual Distribution Bin Edges (Plot Option Or Library Estimate) & Results Table Column Labels.
            % No Finite Response Values: No Edges, No Labels (The Library Plot Shows "No finite response values to plot")
            if isempty(edges)
                data = aux_methods.pull_data(ds_query, app.resultsState.Resp);
                if isfield(data, field)
                    resp_vector = data.(field);
                else
                    resp_vector = data.S.(field);
                end
                if ~any(cellfun(@(x) any(isfinite(x(:))), resp_vector))
                    labels = {};
                    return
                end
                [~, ~, ~, ~, ~, ~, x_log] = response_library_headers(app.resultsState.config, field);
                edges = chessPlot.generate_bin_guess(resp_vector, 5, x_log);
            end
            edges = edges(:)';
            % Library Binning Uses [-Inf, edges, edges(end)+1, Inf]
            final_edges = [-Inf, edges, edges(end)+1, Inf];
            labels = arrayfun(@(a, b) sprintf('%g to %g', a, b), final_edges(1:end-1), final_edges(2:end), 'un', false);
            labels{1} = sprintf('< %g', edges(1));
            labels{end} = sprintf('>= %g', final_edges(end-1));
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

        function dts = results_data_types(app, row)
            % [NEW] Data Types In The Loaded Results That A Plot Type Supports
            Resp = app.resultsState.Resp;
            dts = intersect(row.data_types, fieldnames(Resp), 'stable');
            if row.needs_s % Armor Damage Plots: Results Must Include Damage (S)
                has_s = cellfun(@(dt) any(structfun(@(mt) any(structfun(@(st) isstruct(st) && isfield(st, 'S'), mt)), Resp.(dt))), dts);
                dts = dts(has_s);
            end
        end

        function [lbl, items] = results_field_items(app, key, data)
            % [NEW] Field To Plot Items Per Plot Type (Library Method Field Lists)
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
                    items = app.det_field_list(data);
                case 'det_table' % Columns Are Picked In The Table Pop-Out
                    items = {};
                case 'event' % Responses The Event Viewer Recomputes For This Structure Type (And The Run Computed)
                    if isfield(data, 'var')
                        run_fields = {data.var};
                    else
                        run_fields = fieldnames(data)';
                    end
                    items = intersect(app.results_response_list('event'), run_fields, 'stable');
                case 'annual'
                    items = intersect(app.results_response_list('annual'), [fieldnames(data)', s_fields], 'stable');
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

        function [project_forcing, dsw] = results_forcing_and_dsw(app)
            % [NEW] Project Forcing & Storm DB Probability Masses For The Loaded Results (Loaded Once, Kept In resultsState)
            if isempty(app.resultsState.project_forcing) && isfile(app.resultsState.out_files.project_forcing)
                P = load(app.resultsState.out_files.project_forcing, 'project_forcing');
                app.resultsState.project_forcing = P.project_forcing;
            end
            if isempty(app.resultsState.prob_mass)
                S = load(app.resultsState.dbObj.output_paths.storm_db, 'prob_mass');
                app.resultsState.prob_mass = S.prob_mass;
            end
            project_forcing = app.resultsState.project_forcing;
            dsw = app.resultsState.prob_mass;
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

        function cat = results_plot_catalog(app)
            % [NEW] Results Plot Types -> CHESS-Library Plot Methods (One Row Per Plot), Filtered For The Loaded Run.
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
            state = app.resultsState;
            if isempty(state)
                return
            end
            keep = false(size(cat));
            for cc = 1:numel(cat)
                cat(cc).data_types = app.results_data_types(cat(cc));
                keep(cc) = ismember(state.config.workflow, cat(cc).workflows) && ~isempty(cat(cc).data_types) &&...
                    (~cat(cc).rubble_mound || state.structure.struc_type == 3) &&...
                    (~strcmp(cat(cc).key, 'det_compare') || isfield(state.Resp, 'Timeseries')); % Needs Peaks & Timeseries
            end
            cat = cat(keep);
        end

        function results_plot_options_dialog(app)
            % [NEW] Right-Click "Plot Options...": Library Plot Arguments Not Covered By The Dropdowns (Session Only)
            row = app.results_plot_row();
            if isempty(row)
                return
            end
            if isempty(row.options)
                uialert(app.UIFigure, ['"' row.label '" has no plot options.'], 'Plot Options', 'Icon', 'info');
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
                        c_items = app.det_field_list(aux_methods.pull_data(ds_query, app.resultsState.Resp));
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
            if isempty(app.resultsState) || isempty(app.PlotTypeDropDown.Items)
                return
            end
            cat = app.results_plot_catalog();
            row = cat(strcmp({cat.key}, app.PlotTypeDropDown.Value));
        end

        function fields = results_response_list(app, list_name)
            % [NEW] Response Names Accepted By Library Plot Methods (Mirror Of Their Argument Validation)
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
                    switch app.resultsState.structure.struc_type
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

        function msg = results_status(app)
            % [NEW] Status Bar Text: Do The Loaded Results Match The Active PSE Geometry And The Current Run Tab Inputs? (No Side Effects)
            msg = '';
            try
                [pse_name, alt_name] = app.get_active_names();
                pseObj = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown_run.Value, '', 'db');
                config_now = app.create_resp_config(pseObj, dbObj, false);
                saved_config = app.resultsState.config;
                % Geometry: PSE Geometry Fields (Bridged Into config; offshore_elevation As Resolved, Storm DB Grid Wins)
                geo_fields = fieldnames(pseObj);
                [geo_changed, geo_fld] = any_field_changed(config_now, saved_config, geo_fields);
                % Run Tab Inputs: Every Other Field (sim_inputs_changed Compares The Fields Of config_now)
                [inp_changed, inp_fld] = app.sim_inputs_changed(saved_config, rmfield(config_now, geo_fields));
                if geo_changed && inp_changed
                    msg = ['PSE geometry differs from the loaded results (' geo_fld '); Run tab inputs also changed (' inp_fld '). Press Run to update.'];
                elseif geo_changed
                    msg = ['PSE geometry differs from the loaded results (' geo_fld '). Press Run to update.'];
                elseif inp_changed
                    msg = ['Run tab inputs changed since the loaded results (' inp_fld '). Press Run to update.'];
                else
                    msg = app.loaded_sim_status();
                end
            catch
            end
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

        function plan = run_hotstart_plan(app, config, old)
            % [NEW] Run With A Saved Simulation: Library Hotstart Level (hotstart_plan) Of The Current Inputs (config, Not For Run)
            % Against The Saved Run (old). GUI Inputs The Library Lists Do Not Cover (DB Uncertainties, Region)
            % Count As 'resample'. plan.available: Hotstart Offered (Not 'resample', Needed Cached Forcing/Seed Present). plan.text: Dialog Line
            plan = struct('level', 'resample', 'reason', '', 'available', false, 'text', '', 'old', old);
            if ~isfield(old, 'forcing_stamp') % Complete Forcing Of The Saved Run (Library call_chess_boundary_conditions)
                plan.text = 'Hotstart not available: the saved run has no complete forcing.';
                return
            end
            is_lcs = config.workflow == 3 && isempty(config.multiline); % Multi-Line Stage 2 Samples Nothing (Stage 1's Life Cycles)
            why_not = '';
            gui_deps = {'region', 'chs_swl_u_a', 'chs_swl_u_r', 'chs_hm0_u_a', 'chs_hm0_u_r'};
            [changed, plan.reason] = any_field_changed(config, old, gui_deps);
            if ~changed
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
                elseif app.sim_inputs_changed(old, config)
                    plan.text = 'Hotstart reuses the cached forcing.';
                else
                    plan.text = 'Inputs are identical; a hotstart reproduces the saved results.';
                end
            end
        end

        function run_progress(app, prog, step, message, labels)
            % [NEW] Library call_chess_boundary_conditions progress_fcn: Steps 0-4 (Cache, Build, Uncertainty, Adjust, Save) ->
            % Bar Value And labels{step + 1}. Uncertainty And Adjust Alternate Per Dataset: The Bar Never Moves Back. The Library
            % Message Still Goes To The Command Window
            disp(message);
            bar_val = [1 1 2 3 3.5]/5;
            set(prog, 'Value', max(prog.Value, bar_val(step + 1)), 'Message', labels{step + 1});
        end

        function [choice, plan] = run_start_choice(app, pseObj, dbObj)
            % [NEW] Run With A Saved Simulation Of The Current Key: "Hotstart" (Hidden When Not Available) | "Coldstart" |
            % "Load existing" | "Cancel" ('Cancel' Also When The Dialog Is Closed)
            config = app.create_resp_config(pseObj, dbObj, false);
            S = load(config.out_files.config, 'config');
            S.config = app.localize_saved_config(S.config); % Saved tide_file In This Project Folder: Not A Change (Hotstart Dependency)
            plan = app.run_hotstart_plan(config, S.config);
            [~, label, run_date] = app.saved_sim();
            options = {'Hotstart', 'Coldstart', 'Load existing', 'Cancel'};
            if ~plan.available
                options = options(2:end);
            end
            app.auxLib.choice_dlgbox(sprintf('A simulation for %s already exists (run %s).\n%s', label, run_date, plan.text),...
                options, 'Existing Simulation', [560 170]);
            choice = app.auxLib.dialog_answer;
            if isempty(choice)
                choice = 'Cancel';
            end
        end

        function save_project(app, chess_project)
            % Save out Project state (Default: The Active Project)
            if nargin < 2
                if isempty(app.proj_indx)
                    return
                end
                chess_project = app.chess_projects(app.proj_indx); %#ok<ADPROP,*ADPROPLC>
            end
            save(fullfile(chess_project.path, chess_project.name, ['CHESS_project_' chess_project.name '.mat']), 'chess_project', '-v7.3'); %#ok<ADPROP>
        end

        function [tf, label, run_date] = saved_sim(app)
            % [NEW] Saved Simulation For The Current Key (Config + Responses Files), "<alt> / <workflow> / <DB>", Run Date
            [config_file, ~, ~, wflow_name, out_files] = app.get_config_path();
            [~, alt_name] = app.get_active_names();
            tf = isfile(config_file) && isfile(out_files.resp_data);
            label = sprintf('%s / %s / %s', alt_name, wflow_name, app.StormDBDropDown_run.Value);
            run_date = '';
            if tf
                run_date = char(datetime(dir(out_files.resp_data).datenum, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm'));
            end
        end

        function set_active_selection(app, proj_name, pse_name, alt_name)
            % [NEW] Single Place That Resolves The Active Project/PSE/Alternative.
            % Unknown Or Empty Names Fall Back To The First Available Entry.
            app.wProj = [];
            app.proj_indx = [];
            app.pse_indx = [];
            app.alt_indx = [];
            if isempty(app.chess_projects)
                return
            end
            app.proj_indx = find(strcmp(proj_name, {app.chess_projects.name}), 1);
            if isempty(app.proj_indx)
                app.proj_indx = 1;
            end
            app.wProj = app.chess_projects(app.proj_indx);
            % PSE
            pseList = app.wProj.pse_list;
            if isempty(pseList)
                return
            end
            if ~any(strcmp(pse_name, pseList))
                pse_name = pseList{1};
            end
            app.wProj.set_working_pse(pse_name);
            app.pse_indx = app.wProj.pse_indx;
            % Alternative
            altList = app.wProj.alternative_list{app.pse_indx};
            if isempty(altList)
                return
            end
            if ~any(strcmp(alt_name, altList))
                alt_name = altList{1};
            end
            app.wProj.set_working_alt(pse_name, alt_name);
            app.alt_indx = app.wProj.alt_indx;
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
                        app.tableState.(fld{1}) = s1_row.inherited.(fld{1});
                    end
                end
            end
            % Run Needs A Response, A Data Type, And Workflow Inputs Defined For This PSE Type; Multi-Line Stage 2 Also Its Stage 1 Run
            has_inputs = true;
            if app.WorkflowDropDown.Value == 3
                has_inputs = any(strcmp(app.WorkflowInputsTable.Data(:, 1), 'mcs_nLC'));
            end
            db_msg = app.stormdb_missing_note();
            app.RunSimulationButton.Enable = has_inputs && ~isempty(app.ResponsesTree.CheckedNodes) &&...
                ~isempty(app.DataTypesTree.CheckedNodes) && isempty(ml_msg) && isempty(db_msg);
            app.get_sim_state();
            % Status Bar Follows Run Tab Edits (set_sim_status Shows A Missing Storm DB File Or Stage 1 Run First)
            if ~isempty(ml_msg) || ~isempty(db_msg)
                app.set_sim_status('');
            elseif ~isempty(app.resultsState)
                app.set_sim_status(app.results_status());
            end
        end

        function set_run_active(app, tf)
            % [NEW] Run In Progress Flag (RunSimulationButtonPushed Clears It On Every Exit Through onCleanup)
            app.runActive = tf;
        end

        function set_sim_state(app, opMode, config_file)
            % opMode: 1 - Snapshot (simState), 2 - Saved Config, 3 - Keep Current Inputs In A New Context (Snapshot Mapped To
            % The Active PSE's Library Template). Inputs Table Values Live In tableState (All Workflows), Table Shows The Pertinent Rows
            [pse_name, alt_name] = app.get_active_names();
            switch opMode
                case 1 % Snapshot (tableState Kept As Is)
                    restore_snapshot({});
                case 2 % With Config
                    S = load(config_file, 'config');
                    config = app.localize_saved_config(S.config);
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
                    pse_geo = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                    tpl = app.wProj.get_library_template(pse_geo.pse_type);
                    is_param = ~startsWith(tpl.responses(:, 2), 'Comput');
                    inputs = [{'storm_duration'}; tpl.responses(is_param, 1); tpl.mcs(:, 1); tpl.csr(:, 1); tpl.pros(:, 1)];
                    app.tableState = struct();
                    app.WorkflowInputsTable.Data = cell(0, 3); % Else populate_inputs_table Stores The Visible (Previous) Values Over The Config's
                    for kk = 1:length(inputs)
                        if isfield(config, inputs{kk})
                            app.tableState.(inputs{kk}) = config.(inputs{kk});
                        end
                    end
                case 3 % Keep Current Inputs: Snapshot Values Where The Template Has The Response/Row (PSE Type Can Differ),
                    % Template Defaults Only For Responses, Data Types And Rows The Previous State Lacked
                    restore_snapshot({'StormDBDropDown_run'}); % New Context: Storm DB Already Chosen (populateSimulationTab)
                    pse_geo = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                    tpl = app.wProj.get_library_template(pse_geo.pse_type);
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
                    drop = setdiff(fieldnames(app.tableState), inputs);
                    if ~isempty(drop)
                        app.tableState = rmfield(app.tableState, drop);
                    end
                    app.WorkflowInputsTable.Data = cell(0, 3);
            end
            % Rebuild Inputs Table For Restored Checks & Workflow
            app.populate_inputs_table();

            function restore_snapshot(skip)
                % Run Tab Controls From simState (Component Name, Value), Except skip
                winState = app.simState;
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
                % simState Entry ({} If Absent)
                v = {};
                if ~isempty(app.simState) && any(strcmp(app.simState(:, 1), name))
                    v = app.simState{strcmp(app.simState(:, 1), name), 2};
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
            % [NEW] Run Tab Status Bar (Display Only). Run Tab Storm DB Without A layout (stormdb_missing_note), Else Multi-Line
            % Stage 2 Without A Matching Stage 1 Run: That Message Instead
            [~, ml_msg] = app.multiline_stage1_row();
            db_msg = app.stormdb_missing_note();
            if ~isempty(db_msg)
                msg = db_msg;
            elseif ~isempty(ml_msg)
                msg = ml_msg;
            end
            app.simStatusBar.Value = msg;
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

        function [elev, source] = shown_offshore_elevation(app, dbObj, alt_name)
            % [NEW] Offshore Elevation Shown On The Run Tab And In The PSE Pop-Out: Storm DB Study Grid Value (Wins, As In
            % create_resp_config), Else The Active PSE's Geometry Value (Fallback Entered At PSE Creation), Else NaN. dbObj
            % Empty (No Run Tab Storm DB): The PSE Value. alt_name: Alternative Of The Active PSE (Default: The Active One);
            % The Active Multi-Line Stage 2: Its Stage 1's Toe In Stage 1's Saved Run Of The Run Tab Storm DB + Workflow (Library
            % multiline_stage2_config; multiline_stage1_row: Row structure_kt), NaN Without That Run
            [pse_name, act_alt] = app.get_active_names();
            if nargin < 3
                alt_name = act_alt;
            end
            if app.wProj.alt_stage(pse_name, alt_name) == 2
                s1_row = app.multiline_stage1_row();
                elev = NaN;
                if ~isempty(s1_row)
                    elev = s1_row.structure_kt.toe_elevation;
                end
                source = 'stage 1 toe';
                return
            end
            elev = [];
            if ~isempty(dbObj)
                elev = app.db_offshore_elevation(dbObj);
            end
            source = 'Storm DB grid';
            if isempty(elev)
                elev = NaN;
                source = '';
                pse_geo = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                if isstruct(pse_geo) && isfield(pse_geo, 'offshore_elevation') && ~isempty(pse_geo.offshore_elevation)
                    elev = pse_geo.offshore_elevation;
                    source = 'PSE geometry';
                end
            end
        end

        function bk = sim_backup_paths(app, out_files)
            % [NEW] Run Files Of A Slot A Run Overwrites (Saved Config, Project Forcing, LCS Sampling Seed) And Their Backups
            % While The Run Lasts (Same Folder: <file>_prev.mat). bk(k).name: 'config' | 'forcing' | 'seed'
            files = {out_files.config, out_files.project_forcing, lcs_sampling_seed_file(out_files.project_forcing)};
            prev = cellfun(@(f) [f(1:end-4) '_prev.mat'], files, 'un', false);
            bk = struct('name', {'config', 'forcing', 'seed'}, 'file', files, 'prev', prev);
        end

        function [changed, fld] = sim_inputs_changed(app, saved_config, config_now)
            % [NEW] Current Run Tab Inputs Vs A Saved Run's config (Library any_field_changed, No Side Effects)
            if nargin < 3
                [pse_name, alt_name] = app.get_active_names();
                pseObj = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown_run.Value, '', 'db');
                config_now = app.create_resp_config(pseObj, dbObj, false);
            end
            % outfolder: Project Location (Moves With An Imported/Relocated Project), Not A Run Input
            ignore = {'out_files', 'in_files', 'outfolder'};
            [changed, fld] = any_field_changed(config_now, saved_config, setdiff(fieldnames(config_now), ignore));
        end

        function tf = sim_is_stale(app, row, s1_rows)
            % Multi-Line Stage 2 Registry Row Stale: No Stage 1 Row (s1_rows) Of Its Storm DB + Workflow, Or Its stage1_stamp Is
            % Not That Row's forcing_stamp (Kept With Keep At A Stage 1 Drift Prompt; Offered Again Only By The Next Stage 1 Run
            % That Rebuilds Its Forcing Or Changes Its Kt Geometry, RunSimulationButtonPushed)
            s1 = s1_rows(strcmpi(row.db, {s1_rows.db}) & strcmpi(row.workflow, {s1_rows.workflow}));
            tf = isempty(s1) || ~strcmp(row.stage1_stamp, s1(1).forcing_stamp);
        end

        function rows = sim_rows(app, proj, pse_name, alt_name)
            % Registry Rows Of An Alternative Of proj (chessProject.sim_rows: One isfile Per Row). Active Project: A Missing
            % Responses File Drops Its Row And Re-Syncs That Alternative Only; The Project Is Saved, The Status Bar Says So, And
            % A Dropped Multi-Line Stage 1 Bundle Asks About Its Stage 2 Rows (stage1_drift 'removed'), As Does One The Re-Sync
            % Reloaded With Another forcing_stamp / structure_kt ('changed'). Other Loaded Projects (Not Locked By This
            % Session): Missing Rows Only Left Out
            is_active = ~isempty(app.wProj) && proj == app.wProj;
            [rows, dropped, changed] = proj.sim_rows(pse_name, alt_name, is_active);
            if isempty(dropped)
                return
            end
            app.save_project(proj);
            app.simStatusBar.Value = sprintf('Results no longer on disk, removed from the project: %s/%s %s.', pse_name, alt_name,...
                strjoin(arrayfun(@chessProject.sim_label, dropped, 'un', false), ', '));
            if proj.alt_stage(pse_name, alt_name) == 1
                app.stage1_drift(proj, pse_name, alt_name, [{dropped.db}', {dropped.workflow}'], 'removed');
                if ~isempty(changed)
                    app.stage1_drift(proj, pse_name, alt_name, changed(:, 3:4), 'changed');
                end
            end
        end

        function key = sim_key(app)
            % [NEW] Saved Simulation Key: Config File Of Alternative + Workflow + Run Tab Storm DB ('' Without Both)
            key = '';
            if app.has_active_alt() && ~isempty(app.StormDBDropDown_run.Items)
                key = app.get_config_path();
            end
        end

        function stage1_drift(app, proj, pse_name, s1_alt, db_wf, kind)
            % Multi-Line Stage 1 Bundles (Rows {db, workflow} Of db_wf) Removed ('removed') Or Changed ('changed') Outside CHESS:
            % Their Stage 2 Rows Of The Same Storm DB + Workflow (multiline_cascade_sims) Listed With Delete / Keep (Default).
            % Delete: delete_sim_rows, Those Alternatives Re-Synced, Project Saved. Keep: Files And Rows Stay (Stale: Marked In
            % The Tree, Offered Again By The Next Stage 1 Run)
            cascade = app.multiline_cascade_sims(proj, pse_name, s1_alt, db_wf);
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
            app.auxLib.choice_dlgbox(msg, {'Delete', 'Keep'}, 'Multi-Line Stage 1 Results', 560); % Last Button = Default: Keep
            if ~strcmp(app.auxLib.dialog_answer, 'Delete')
                return
            end
            failed = app.delete_sim_rows(proj, pse_name, cascade);
            for aa = unique(cascade(:, 1))'
                proj.sync_sims({pse_name, aa{1}}, 'sync');
            end
            app.save_project(proj);
            if ~isempty(failed)
                uialert(app.UIFigure, sprintf(['These second-stage files could not be deleted (a file may be open in another ',...
                    'program):\n%s\nClose it and remove those simulations.'], strjoin(failed, newline)),...
                    'Multi-Line Stage 1 Results', 'Icon', 'warning');
            end
        end

        function asked = stage1_sync_prompts(app, proj, info)
            % After A Registry Sync (chessProject.sync_sims info): stage1_drift Per Multi-Line Stage 1 Alternative Whose Bundles
            % Were Dropped ('removed') Or Reloaded With Another forcing_stamp / structure_kt ('changed'). asked: Any Bundle Listed
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
                    app.stage1_drift(proj, rows{first(gg), 1}, rows{first(gg), 2}, rows(grp == gg, 3:4), lists{ll, 2});
                end
            end
        end

        function store_table_values(app)
            % [NEW] Save Visible Inputs Table Values Into tableState
            if ~isstruct(app.tableState)
                app.tableState = struct();
            end
            tbl = app.WorkflowInputsTable.Data;
            for kk = 1:size(tbl, 1)
                app.tableState.(tbl{kk, 1}) = tbl{kk, 3};
            end
        end

        function ok = storm_db_info_ok(app, dbObj)
            % [NEW] Storm DB Has Its db_info (Library storm_db_info 'valid'); Imported With An Older CHESS Version: Alert (Must
            % Be Re-Imported) Once Per Storm DB Per Session, Callers Still Block Silently Afterwards. The Run Path Keeps Its Own
            % Error (CHSStormDBImportUI.get_db_info In create_resp_config, Run-Failed Dialog)
            ok = storm_db_info('valid', dbObj.db_info);
            if ~ok && ~any(strcmp(app.oldDbWarned, dbObj.output_paths.storm_db))
                app.oldDbWarned{end+1} = dbObj.output_paths.storm_db;
                uialert(app.UIFigure, 'This storm database was built with an older CHESS version and must be re-imported.',...
                    ['Storm DB: ' dbObj.db_name], 'Icon', 'warning');
            end
        end

        function msg = stormdb_missing_note(app)
            % Run Tab Storm DB Record Without A layout (Its Storm DB File Was Missing Or Unreadable; chessProject.sync_sims
            % Retries It): Status Text Asking For A Re-Import; '' Otherwise
            msg = '';
            if ~app.has_active_alt() || isempty(app.wProj.stormDB_list)
                return
            end
            recs = app.wProj.stormDB_list;
            k = find(strcmp({recs.db_name}, app.StormDBDropDown_run.Value), 1);
            if ~isempty(k) && isempty(recs(k).layout)
                msg = sprintf('Storm DB %s: file missing or unreadable, re-import it.', recs(k).db_name);
            end
        end

        function sync_saved_sim(app, ask)
            % [NEW] After A Switch Of Alternative / Workflow / Run Tab Storm DB (Key Changed), A Saved Simulation Of The New Key Is
            % Loaded Silently When The Current Inputs Match It, Or Without ask (Internal Refresh). Otherwise ask:
            % "Load" | "Keep current inputs" (Or Closed: Inputs Kept, Results Tab Cleared). No Saved Simulation: Inputs Kept.
            % Run Tab Storm DB Of An Older CHESS Version (No db_info, Inputs Cannot Be Compared): Alert, Then Ask As Changed Inputs.
            % The Callers' populateResultsTab Loads Nothing While The Key Differs, So Results Appear Only Once Resolved Here.
            % A Declined Load Is Remembered (declinedSimKey) Until The Key Changes: Switching Back Asks Again
            key = app.sim_key();
            if isequal(key, app.simKey)
                return
            end
            app.simKey = key;
            app.declinedSimKey = '';
            if isempty(key)
                return
            end
            [has_sim, label] = app.saved_sim();
            if ~has_sim
                app.set_sim_status(['No saved simulation for ' label '.']);
                return
            end
            S = load(key, 'config');
            S.config = app.localize_saved_config(S.config);
            load_it = ~ask;
            if ask
                dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown_run.Value, '', 'db');
                load_it = app.storm_db_info_ok(dbObj) && ~app.sim_inputs_changed(S.config);
            end
            if ~load_it
                app.auxLib.choice_dlgbox(['A simulation for ' label ' already exists. Load it?'], {'Load', 'Keep current inputs'},...
                    'Saved Simulation Found');
                load_it = isequal(app.auxLib.dialog_answer, 'Load');
            end
            if load_it
                app.load_saved_sim();
            else
                app.declinedSimKey = key;
                app.resultsState = [];
                app.reset_tab('results');
                app.set_sim_status('Current simulation already exists. Load declined.');
            end
        end

        function note = sync_note(app, info)
            % Status Bar Text Of A Registry Sync (chessProject.sync_sims info); '' When Nothing Changed
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

        function proj = tree_node_project(app, node)
            % Project Of A Project Tree Node (Any Level)
            while ~strcmp(node.NodeData.type, 'proj')
                node = node.Parent;
            end
            proj = app.chess_projects(strcmp({app.chess_projects.name}, node.NodeData.name));
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
            for kk = 1:length(app.chess_projects)
                wObj = app.chess_projects(kk);
                % Create Project Node
                proj_node = uitreenode(app.ProjectTree, 'Text', wObj.name,...
                    'NodeData', struct('type', 'proj', 'name', wObj.name));
                add_node_menu(proj_node);
                if kk == app.proj_indx
                    act_node = proj_node;
                end
                % Loop Across PSEs (Read Lists Directly, No Working Index Side Effects)
                for jj = 1:length(wObj.pse_list)
                    pse_node = uitreenode(proj_node, 'Text', wObj.pse_list{jj},...
                        'NodeData', struct('type', 'pse', 'name', wObj.pse_list{jj}));
                    add_node_menu(pse_node);
                    if kk == app.proj_indx && isequal(jj, app.pse_indx)
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
                        if kk == app.proj_indx && isequal(jj, app.pse_indx) && isequal(ii, app.alt_indx)
                            act_node = alt_node;
                        end
                        % Simulation Bundles (Storm DB | Workflow), Display Only
                        rows = app.sim_rows(wObj, wObj.pse_list{jj}, altList{ii});
                        for ss = 1:numel(rows)
                            label = chessProject.sim_label(rows(ss));
                            sim_text = label;
                            if stage == 2 && app.sim_is_stale(rows(ss), s1_rows)
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
            Resp = app.resultsState.Resp;
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
                    lay = app.resultsState.dbObj.layout;
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
                [f_lbl, f_items] = app.results_field_items(row.key, data);
                app.FieldToPlotDropDown_2Label.Text = f_lbl;
                app.set_dropdown_items(app.FieldToPlotDropDown_results, f_items);
                app.FieldToPlotDropDown_results.Enable = ~isempty(f_items);
            end
            % Storm ID Dropdown (Event, Life Cycle Or Option)
            [a_lbl, a_items, a_on] = app.results_aux_items(row.key, data, ds_query);
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
            % Project Lock Released However The Window Goes (delete(app), close all force, Figure Deleted: No Close Request).
            % Read From The Figure (set_project_lock), Not The App: Deleting The Figure Deletes The App First. Set After The
            % Single-Instance Check: That Path Never Takes A Lock
            app.UIFigure.DeleteFcn = @(fig, ~) chessProject.release_lock(getappdata(fig, 'chess_project_lock'));
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
            app.stormCache = containers.Map();
            app.tableState = struct();
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
            app.refresh_active_view();
        end

        % Menu selected function: CreateNewProjectMenu
        function CreateNewProjectMenuSelected(app, event)
            % Call Project Creation UI (Loaded Project Names: A New Project Cannot Take One)
            proj_names = {};
            if ~isempty(app.chess_projects)
                proj_names = {app.chess_projects.name};
            end
            obj = ProjectCreationUI(app.UIFigure, proj_names);
            % Wait For UI Figure To Close
            uiwait(obj.uifig);
            % If User Submited Project, Lock It (lock_project), Then Populate UI
            if obj.project_created && app.lock_project(obj.chess_project)
                app.append_project(obj.chess_project);
                % Save Project State
                app.save_project();
                % Long Project Folder Path (Windows 260-Character Limit): Warn, Project Kept
                if ~isempty(obj.path_warning)
                    uialert(app.UIFigure, obj.path_warning, 'Long Project Path', 'Icon', 'warning');
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
            if isempty(app.wProj)
                return
            end
            % Wait For User To Define Export Location And Name
            [file, fPath] = uiputfile({'.zip'}, 'Export CHESS Project', ['CHESS_project_'  app.wProj.name '_archive.zip']);
            % Export Project
            if ~all(file == 0)
                % Save out Project state
                app.save_project();
                % Create Project Archive: <name>/ + The Region's CHS_Dependencies Files (chessProject.export_archive)
                try
                    note = app.wProj.export_archive(fullfile(fPath, file));
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
            app.set_active_selection(proj_node.NodeData.name, pse_name, alt_name);
            app.refresh_active_view(true);
        end

        % Menu selected function: FloodwallMenu, LeveeMenu, 
        % ...and 2 other components
        function PSECreationMenuSelected(app, event)
            if isempty(app.wProj)
                return
            end
            % Call PSE Creation UI
            obj = PSECreationUI(event.Source.Text, app.wProj, '', app.UIFigure);
            uiwait(obj.uifig);
            if obj.pse_created
                app.set_active_selection(app.wProj.name, obj.pse_name, obj.alt_name);
                app.project_field_ini();
                app.refresh_active_view();
                app.save_project();
            else % Remove In-Progress PSE (Keeps All Per-PSE Fields Aligned)
                app.wProj.remove_pse(obj.pse_name);
                app.set_active_selection(app.wProj.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            end
        end

        % Menu selected function: AlternativeMenu
        function AlternativeMenuSelected(app, event)
            % Get PSE List For Active Project
            pseList = app.wProj.get_project_field('pse_list', '', '', 'proj');
            % Ask User For PSE Template
            app.auxLib.dropdown_input_dlgbox('Choose PSE to use as template for alternative.', pseList, 'Add New Alternative To Project PSE', 'OK');
            pse_name = app.auxLib.dialog_answer;
            if isempty(pse_name)
                return
            end
            % Multi-Line PSEs Hold Only Multi-Line Alternatives: Stage 2 Alternatives Come From The Multi-Line Transect Menu
            if app.wProj.is_multiline(pse_name)
                uialert(app.UIFigure, sprintf(['PSE "%s" is a multi-line transect. Add a second-stage alternative with ',...
                    'Add Project Element > PSE > Multi-line Transect.'], pse_name), 'Add New Alternative To Project PSE', 'Icon', 'info');
                return
            end
            % PSE Type: The Active Alternative's When The Chosen PSE Is The Active One, Else The First Alternative's
            pse_geo = app.wProj.get_project_field('pse_geometry', pse_name, '', 'pse');
            pse_type = pse_geo{1}.pse_type;
            [act_pse, act_alt] = app.get_active_names();
            if strcmp(act_pse, pse_name) && ~isempty(act_alt)
                act_geo = app.wProj.get_project_field('pse_geometry', pse_name, act_alt, 'alt');
                pse_type = act_geo.pse_type;
            end
            % Call PSE Creation UI
            obj = PSECreationUI(pse_type, app.wProj, pse_name, app.UIFigure);
            uiwait(obj.uifig);
            if obj.pse_created
                app.set_active_selection(app.wProj.name, obj.pse_name, obj.alt_name);
                app.project_field_ini();
                app.refresh_active_view();
                app.save_project();
            else % Remove In-Progress Alternative
                app.wProj.remove_alternative(obj.pse_name, obj.alt_name);
                app.set_active_selection(app.wProj.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            end
        end

        % Menu selected function: RemoveAlternativeMenu, RemovePSEMenu, 
        % ...and 1 other component
        function RemoveProjectElem(app, event)
            if isempty(app.wProj)
                return
            end
            % Not While A Run Writes Into The Project Folders
            if app.runActive
                uialert(app.UIFigure, 'Removing is not available while a run is in progress.', 'Project Management: Remove', 'Icon', 'info');
                return
            end
            % PSE / Alternative: Confirmed, Then Its Folder Deleted (chessProject.delete_folder: Nothing Changes If That Fails)
            leftover = '';
            switch event.Source.Text
                case 'PSE'
                    choices = app.wProj.get_project_field('pse_list', '', '', 'proj');
                    if isempty(choices)
                        return
                    end
                    app.auxLib.dropdown_input_dlgbox(['Remove PSE from project ' app.wProj.name '.'], choices, 'Project Management: Remove');
                    pse_name = app.auxLib.dialog_answer;
                    if isempty(pse_name)
                        return
                    end
                    app.auxLib.confirmation_dlgbox(sprintf('Remove PSE "%s" and delete its folder (all alternatives and run results)?',...
                        pse_name), 'Remove', 'Remove PSE');
                    if ~app.auxLib.dialog_answer
                        return
                    end
                    try
                        leftover = app.wProj.remove_pse(pse_name, true);
                    catch ME
                        app.auxLib.error_dlgbox(['Could not remove PSE "' pse_name '": ' ME.message]);
                        return
                    end
                    app.resultsState = [];
                case 'Alternative'
                    choices = app.wProj.get_project_field('pse_list', '', '', 'proj');
                    if isempty(choices)
                        return
                    end
                    app.auxLib.dropdown_input_dlgbox('Choose PSE.', choices, 'Project Management: Remove');
                    pse_name = app.auxLib.dialog_answer;
                    if isempty(pse_name)
                        return
                    end
                    choices = app.wProj.get_project_field('alternative_list', pse_name, '', 'pse');
                    app.auxLib.dropdown_input_dlgbox(['Remove alternative from PSE ' pse_name '.'], choices, 'Project Management: Remove');
                    alt_name = app.auxLib.dialog_answer;
                    if isempty(alt_name)
                        return
                    end
                    % Last Alternative Or Multi-Line Stage 1: The PSE Goes With It (chessProject.remove_alternative)
                    if app.wProj.alt_stage(pse_name, alt_name) == 1
                        prompt = sprintf(['"%s" is the first stage of multi-line PSE "%s": its second stages use its results.\n',...
                            'Removing it deletes the WHOLE multi-line PSE "%s" (all its alternatives and run results, files ',...
                            'included). Remove PSE "%s"?'], alt_name, pse_name, pse_name, pse_name);
                    elseif numel(choices) == 1
                        prompt = sprintf(['"%s" is the last alternative of PSE "%s", so the PSE is removed too.\n',...
                            'Remove PSE "%s" and delete its folder (all alternatives and run results)?'], alt_name, pse_name, pse_name);
                    else
                        prompt = sprintf('Remove alternative "%s" of PSE "%s" and delete its folder (all run results)?', alt_name, pse_name);
                    end
                    app.auxLib.confirmation_dlgbox(prompt, 'Remove', 'Remove Alternative');
                    if ~app.auxLib.dialog_answer
                        return
                    end
                    try
                        leftover = app.wProj.remove_alternative(pse_name, alt_name, true);
                    catch ME
                        app.auxLib.error_dlgbox(['Could not remove alternative "' alt_name '": ' ME.message]);
                        return
                    end
                    app.resultsState = [];
                case 'Tides'
                    tide_files = app.wProj.get_project_field('tide_files_list', '', '', 'proj');
                    if isempty(tide_files)
                        return
                    end
                    [~, tide_names, tide_ext] = cellfun(@fileparts, tide_files, 'un', false); % Show File Names
                    choices = strcat(tide_names, tide_ext);
                    app.auxLib.dropdown_input_dlgbox(['Remove tide file from project ' app.wProj.name '.'], choices, 'Project Management: Remove');
                    if isempty(app.auxLib.dialog_answer)
                        return
                    end
                    app.wProj.tide_files_list(strcmp(choices, app.auxLib.dialog_answer)) = [];
            end
            % Reselect & Refresh
            app.set_active_selection(app.wProj.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            app.refresh_active_view();
            app.save_project();
            if ~isempty(leftover)
                uialert(app.UIFigure, sprintf('Removed, but this folder could not be fully deleted (a file inside may be open):\n%s\nDelete it manually.',...
                    leftover), 'Project Management: Remove', 'Icon', 'warning');
            end
        end

        % Value changed function: ProjectDropDown
        function ProjectDropDownValueChanged(app, event)
            % Project Locked First (lock_project); Open In Another Session: Notice, The Previous Project Stays Active
            if ~app.lock_project(app.chess_projects(strcmp({app.chess_projects.name}, app.ProjectDropDown.Value)))
                app.populate_project_panel();
                return
            end
            app.set_active_selection(app.ProjectDropDown.Value, '', '');
            app.refresh_active_view(true);
        end

        % Value changed function: PSEDropDown
        function PSEDropDownValueChanged(app, event)
            app.set_active_selection(app.ProjectDropDown.Value, app.PSEDropDown.Value, '');
            app.refresh_active_view(true);
        end

        % Value changed function: AlternativeDropDown
        function AlternativeDropDownValueChanged(app, event)
            app.set_active_selection(app.ProjectDropDown.Value, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            app.refresh_active_view(true);
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
                ready = app.has_active_alt();
            elseif isequal(tab, app.StormDBViewerTab)
                ready = ~isempty(app.StormDBDropDown.Items);
            elseif isequal(tab, app.ResultsViewerTab)
                ready = ~isempty(app.resultsState) && ~strcmp(app.StormTypeDropDown_results.Value, '-');
            else
                ready = false;
            end
            if ~ready
                uialert(app.UIFigure, 'There is nothing to plot on this tab yet.', 'Nothing To Plot', 'Icon', 'info');
                return
            end
            % Tab Plot Method In A Stand-Alone Classic Figure
            if isequal(tab, app.PSEViewerTab) % PSE Geometry (With Offshore Slope/Elevation Text Box)
                app.plot_pse_geometry(axes('Parent', figure()), base_fnt, true);
            elseif isequal(tab, app.StormDBViewerTab) % Peaks: Data Space | Timeseries: Event Hydrograph
                if app.storm_db_info_ok(app.wProj.get_project_field('stormDB_list', app.StormDBDropDown.Value, '', 'db'))
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
            if isempty(app.wProj)
                return
            end
            % Initialize CHS Library (The Project's CHS_Dependencies And Region: The Wizard Keeps Them). The Project's Storm DB
            % Names And Their Usage (Alternatives, Run Files): A Clash Is An Overwrite, Confirmed In The Wizard At Import
            paths = chess_paths(app.wProj.path, app.wProj.name);
            db_list = {app.wProj.stormDB_list.db_name};
            wizard = CHSStormDBImportUI(app.wProj.chs_dependencies, paths.event_db_dir,...
                app.pull_input_table_value(app.ConstantsTable.Data, 'Gravity Constant'), app.wProj.vdatum, app.wProj.unitsys,...
                app.UIFigure, app.wProj.project_region(), db_list,...
                @(name) [app.wProj.stormdb_usage(name), numel(app.wProj.stormdb_run_files(name))]);
            % Call import Wizard (A New Wizard Every Time; The Project Keeps Only Its Record, CHSStormDBImportUI.to_record)
            wizard.create_ui();
            uiwait(wizard.figUI); % Wait for uifigure to close
            if ~wizard.db_created
                return
            end
            dbObj = wizard.to_record();
            indx = find(strcmpi(dbObj.db_name, db_list), 1);
            if wizard.overwrite_flag && ~isempty(indx)
                % Overwrite Of A Project Storm DB (Index Kept): Its Run Files And Registry Rows Deleted (Old Results Would
                % Otherwise Show As Saved); Session State Of The Old DB Dropped
                old = app.wProj.stormDB_list(indx);
                failed = {};
                for ff = app.wProj.stormdb_run_files(old.db_name)'
                    delete(ff{1});
                    if isfile(ff{1})
                        failed{end+1} = ff{1}; %#ok<AGROW>
                    end
                end
                app.wProj.drop_db_sims(old.db_name);
                app.wProj.stormDB_list(indx) = dbObj;
                db_files = {dbObj.output_paths.storm_db, fullfile(paths.event_db_dir, [dbObj.db_name '_raw_files.mat'])};
                if isstruct(old.output_paths)
                    db_files = [db_files, struct2cell(old.output_paths)'];
                end
                keys = app.stormCache.keys();
                stale = keys(ismember(lower(keys), lower(db_files)));
                if ~isempty(stale)
                    remove(app.stormCache, stale);
                end
                app.oldDbWarned = app.oldDbWarned(~ismember(lower(app.oldDbWarned), lower(db_files)));
                app.simKey = [];
                app.declinedSimKey = '';
                app.resultsState = [];
                if ~isempty(failed)
                    uialert(app.UIFigure, sprintf('Storm DB "%s" overwritten, but these run files could not be deleted:\n%s',...
                        dbObj.db_name, strjoin(failed, newline)), 'Storm DB Overwrite', 'Icon', 'warning');
                end
            else
                app.wProj.add_project_field('stormDB_list', dbObj, '', '', 'pse');
            end
            % Project CHS_Dependencies: Set By The First CHS (Non-Custom) Storm DB, Or Re-Pointed When The Stored Folder Is No
            % Longer Valid; Cleared When An Overwrite Left No CHS Storm DB
            region = app.wProj.project_region();
            if isempty(region)
                app.wProj.chs_dependencies = '';
            elseif ~strcmp(dbObj.study, 'Custom_Modeling') && ~isempty(chessProject.chs_dependencies_problem(app.wProj.chs_dependencies, region))
                app.wProj.chs_dependencies = dbObj.source_paths.chs_dependencies_path;
            end
            % Refresh UI & Show New DB On Storm DB Viewer
            app.refresh_active_view();
            app.populate_stormDB_panel(dbObj, {app.wProj.get_project_field('stormDB_list','','','proj').db_name});
            % Save out Project state
            app.save_project();
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
            dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown.Value, '', 'db');
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
            % Inputs Table Rows Depend On Workflow; Results Are Per Workflow (Saved Simulation Of This Workflow: sync_saved_sim).
            % Constants Table: Uncertainty Rows Marked Unused By DET. Multi-Line Stage 2: Plot Of Stage 1's Run Of This Workflow
            app.set_input_table();
            app.replot_multiline_stage2();
            app.populate_constants_table();
            app.populateResultsTab();
            app.sync_saved_sim(true);
        end

        % Button pushed function: RunSimulationButton
        function RunSimulationButtonPushed(app, event)
            % Run In Progress Until This Callback Exits (Project Tree Rename Refused; It Could Run At A Queued-Event Point)
            app.set_run_active(true);
            run_flag = onCleanup(@() app.set_run_active(false));
            prog = []; % App-Scoped Progress Dialog: Locks The CHESS Window Only (Other MATLAB Windows Stay Usable)
            % Slot Files This Run Backed Up (backup_sim_files): Restored If The Run Fails, Dropped Once The Results Are Saved
            backed = [];
            % Multi-Line Stage 1 Re-Run: Coupled Stage 2 Bundles Deleted Once It Succeeds (Rows {stage 2 alternative, db, workflow})
            cascade = cell(0, 3);
            % Results Saved (Backups Dropped): A Later Error Is A Project Update Failure, Not A Failed Run (Results Still Shown)
            results_saved = false;
            row_added = false; % Registry Row Of This Bundle In The Project (upsert_sim)
            res_str = 'The results';
            update_msg = '';
            failed = cell(0, 1); % Stage 2 Files Not Deleted
            try
                % Backups Left By A Run That Never Finished: Previous Run Back First
                [~, ~, ~, wflow_name, out_files] = app.get_config_path();
                bk = app.sim_backup_paths(out_files);
                app.restore_leftover_backups(bk);
                [pse_name, alt_name] = app.get_active_names();
                %%%% ------- 1. Pull Simulation Inputs ---------
                dbObj = app.wProj.get_project_field('stormDB_list', app.StormDBDropDown_run.Value, '', 'db');
                pseObj = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
                % Every Run Needs An Offshore Elevation (Storm DB Study Grid, Else The PSE Geometry): Checked Before Any Dialog Or
                % Backup, So A Failed Check Touches Nothing (Library check_offshore_elevation, Error Shown In The Run-Failed Dialog)
                check_offshore_elevation(app.create_resp_config(pseObj, dbObj, false));
                % Saved Simulation For This Alternative / Workflow / Storm DB: Run Dialog First. No Saved Simulation: Coldstart
                plan = struct('level', 'cold', 'reason', '', 'old', []);
                if app.saved_sim()
                    [choice, plan] = app.run_start_choice(pseObj, dbObj);
                    switch choice
                        case 'Coldstart'
                            plan.level = 'cold';
                        case 'Load existing'
                            app.load_saved_sim();
                            return
                        case 'Cancel'
                            return
                    end
                end
                % Multi-Line Stage 1 Run With Stage 2 Registry Rows Of This Storm DB + Workflow (Stale Ones Included): They Get
                % Their Forcing From It. Asked When That Input Changes: Stage 1 Forcing Rebuilt (No Stage 1 Row, Or Any Level But
                % 'full') Or, At 'full', Its Kt Geometry Differs From Its Row's structure_kt (Library multiline_stage2_config
                % stage1_structure). Confirmed Here (Plan Known, No File Touched Yet), Deleted Only After The Run Succeeds (A Failed
                % Run Restores Stage 1's Files)
                if app.wProj.alt_stage(pse_name, alt_name) == 1
                    res_str = 'Stage 1 results';
                    db_wf = {app.StormDBDropDown_run.Value, wflow_name};
                    cascade = app.multiline_cascade_sims(app.wProj, pse_name, alt_name, db_wf);
                    why = '';
                    if ~isempty(cascade)
                        s1_rows = app.sim_rows(app.wProj, pse_name, alt_name);
                        s1_row = s1_rows(strcmpi(db_wf{1}, {s1_rows.db}) & strcmpi(db_wf{2}, {s1_rows.workflow}));
                        if isempty(s1_row) || ~strcmp(plan.level, 'full')
                            why = 'Stage 1 forcing will be rebuilt.';
                        else
                            kt = fieldnames(s1_row(1).structure_kt)';
                            if ~all(cellfun(@(f) isfield(pseObj, f) && isequaln(s1_row(1).structure_kt.(f), pseObj.(f)), kt))
                                why = 'Stage 1 crest, crest width, seaside slope, offshore slope or toe changed (stage 2 waves / offshore end).';
                            end
                        end
                    end
                    if isempty(why)
                        cascade = cell(0, 3);
                    else
                        lines = strcat({['  ' char(8226) ' ']}, cascade(:, 1), {' | '}, cascade(:, 2), {' | '}, cascade(:, 3));
                        app.auxLib.choice_dlgbox(sprintf(['"%s" is the first stage of multi-line PSE "%s". These second-stage ',...
                            'simulations get their forcing from its %s run and are deleted once this run succeeds:\n%s\n%s'],...
                            alt_name, pse_name, strjoin(db_wf, ' | '), strjoin(lines, newline), why), {'Continue', 'Cancel'},...
                            'Run Multi-Line Stage 1', 560); % Last Button = Default (Enter): Cancel
                        if ~strcmp(app.auxLib.dialog_answer, 'Continue')
                            return
                        end
                    end
                end
                S = load(dbObj.output_paths.storm_db, 'storm', 'prob_mass');
                % LCS, Full Poisson Sampling: Convergence Dialog (May Update mcs_nLC) Before The Config Is Built, Only When
                % Life Cycles Are Sampled (A Hotstart Reuses The Cached Forcing Or This Case's Sampling)
                if app.WorkflowDropDown.Value == 3 && strcmp(plan.level, 'cold') && ~app.lcs_convergence_confirm(pseObj, dbObj, S.prob_mass)
                    return
                end
                backed = app.backup_sim_files(bk, plan.level);
                [config, pseObj] = create_resp_config(app, pseObj, dbObj, true, plan); % Includes Hotstart Actions

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
                prog = uiprogressdlg(app.UIFigure, 'Title', 'CHESS Simulation Progress', 'Message', step_str, 'Value', 1/5);
                bar_msg = {'Loading Project Forcing', step_str, unc_str, adj_str, 'Saving Project Forcing'}; % Library Steps 0-4
                [project_forcing, config] = call_chess_boundary_conditions(config, S.storm, S.prob_mass, pseObj,...
                    @(step, msg) app.run_progress(prog, step, msg, bar_msg));

                %%%% ---- 5. Run CHESS Simulation
                set(prog, 'Value', 4/5, 'Message', 'Computing Project Responses');
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
                if ~isempty(cascade)
                    failed = app.delete_sim_rows(app.wProj, pse_name, cascade);
                end

                %%%% ---- 6. Store Outputs On Project
                set(prog, 'Value', 4.99/5, 'Message', 'Saving Outputs');
                app.wProj.upsert_sim(pse_name, alt_name, chessProject.sim_row_from_config(config, pseObj,...
                    dir(config.out_files.resp_data).datenum)); % Registry Row Of This Bundle
                row_added = true;
                app.save_project();
                app.update_project_tree(); % New Simulation Bundle Node
                set(prog, 'Value', 1, 'Message', 'Done');
                close(prog);
            catch ME
                if ~isempty(prog) && isvalid(prog)
                    close(prog);
                end
                if ~results_saved
                    % Failed Before The Results Were Saved: Slot Back To The Previous Run (Config, Forcing, LCS Seed Matching The
                    % Results On Disk). Best Effort: A Restore Failure Is Reported With, Not Instead Of, The Run Error
                    failed = app.restore_sim_files(backed);
                    msg = ['CHESS run failed: ' ME.message];
                    if ~isempty(failed)
                        msg = [msg newline newline 'Previous run files not restored: ' strjoin(failed, '; ')];
                    end
                    app.auxLib.error_dlgbox(msg);
                    return
                end
                % Results Saved, Project Update Failed (Stage 2 Delete, Registry Row, Save Or Tree): The Registry Row Retried Once
                % When It Was Not Added (Failed Again: The Next Import Sync Or Rebuild Adds It From Disk), Then The Save Retried
                % Once (Failed Again: The Row Is In Memory Only Until The Project Is Saved), Warning Below, Results Shown
                update_msg = sprintf('%s were saved, but updating the project failed: %s', res_str, ME.message);
                if ~row_added
                    try
                        app.wProj.upsert_sim(pse_name, alt_name, chessProject.sim_row_from_config(config, pseObj,...
                            dir(config.out_files.resp_data).datenum));
                    catch
                        update_msg = [update_msg newline newline 'The simulation is not in the project list: use "Rebuild ',...
                            'simulations from disk" on the project.'];
                    end
                end
                try
                    app.save_project();
                catch
                    update_msg = [update_msg newline newline 'The project is not saved: save it before closing.'];
                end
                try
                    app.update_project_tree();
                catch
                end
            end
            % Show Results (Of The Current Key); Status Bar: How The Forcing Was Obtained
            app.simKey = app.sim_key();
            app.declinedSimKey = '';
            app.populateResultsTab();
            switch plan.level
                case 'full'
                    app.set_sim_status('Hotstart (full): reused cached forcing.');
                case 'reuse_sampling'
                    if config.workflow == 3
                        app.set_sim_status(['Hotstart: same life cycles, forcing rebuilt (' plan.reason ').']);
                    else
                        app.set_sim_status(['Hotstart: forcing rebuilt (' plan.reason ').']);
                    end
                otherwise
                    app.set_sim_status('Coldstart: forcing regenerated.');
            end
            app.TabGroup.SelectedTab = app.ResultsViewerTab;
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
                if ~isempty(cascade)
                    title_str = 'Run Multi-Line Stage 1';
                end
                uialert(app.UIFigure, alert_msg, title_str, 'Icon', 'warning');
            end
        end

        % Callback function: DataTypesTree, ResponsesTree
        function TreeCheckedNodesChanged(app, event)
            % Light Update: Inputs Table Rows & Run Button
            app.set_input_table();
        end

        % Value changed function: ApplyDepthLimitationCheckBox, 
        % ...and 4 other components
        function StormDBDropDown_runValueChanged(app, event)
            % Storm DB Change Rebuilds Data Types; Other Controls Only Need A Light Update
            if event.Source == app.StormDBDropDown_run
                app.populateSimulationTab();
                app.replot_multiline_stage2(); % Stage 1's Run Of This Storm DB
                app.populate_pse_table();
                app.populate_constants_table();
                app.populateResultsTab();
                app.sync_saved_sim(true); % Saved Simulation Of This Storm DB
            elseif app.has_active_alt() % Without An Active Alternative There Are No Inputs To Refresh
                app.set_input_table();
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
            [pse_name, alt_name] = app.get_active_names();
            if app.wProj.alt_stage(pse_name, alt_name) == 2 && ismember(symbol, multiline_inherited_fields())
                app.WorkflowInputsTable.Data{row, col} = event.PreviousData;
                uialert(app.UIFigure, sprintf('Multi-line stage 2: %s is taken from the stage 1 run (%s/%s).', symbol, pse_name,...
                    app.wProj.stage1_alt(pse_name)), 'Inputs: From Stage 1', 'Icon', 'info');
                return
            end
            if strcmp(symbol, 'csr_apply_structure_repair') && ~(isnumeric(val) && isscalar(val) && ismember(val, 0:3))
                app.WorkflowInputsTable.Data{row, col} = event.PreviousData;
                uialert(app.UIFigure, 'Structure Repair must be 0 (None), 1 (Above SLS), 2 (Above ULS) or 3 (Above SLS Or ULS).',...
                    'Inputs: Invalid Value', 'Icon', 'warning');
                return
            end
            app.tableState.(symbol) = val;
            % DPA Settings Rows Follow csr_call_dpa
            if strcmp(symbol, 'csr_call_dpa')
                app.set_input_table();
            end
        end

        % Menu selected function: RemoveStormDatabaseMenu
        function RemoveStormDatabaseMenuSelected(app, event)
            % Remove A Storm Database From The Active Project. Tied To Simulations (Registry Rows, chessProject.stormdb_tied_sims):
            % Deleted With Its Files And Those Bundles' Run Files. Otherwise: Remove (Files Kept) Or Remove & Delete Files
            if isempty(app.wProj) || isempty(app.wProj.stormDB_list)
                return
            end
            % Not While A Run Writes Into The Project Folders
            if app.runActive
                uialert(app.UIFigure, 'Removing is not available while a run is in progress.', 'Storm Database Management: Remove', 'Icon', 'info');
                return
            end
            app.auxLib.dropdown_input_dlgbox(['Remove storm database from project ' app.wProj.name '.'],...
                {app.wProj.stormDB_list.db_name}, 'Storm Database Management: Remove', 'Remove');
            db_name = app.auxLib.dialog_answer;
            if isempty(db_name)
                return
            end
            % Storm DB Files (storm/prob_mass + Raw CHS_Data, If Any)
            dbObj = app.wProj.get_project_field('stormDB_list', db_name, '', 'db');
            db_files = {};
            for ff = {'storm_db', 'chs_data'}
                if isfield(dbObj.output_paths, ff{1}) && isfile(dbObj.output_paths.(ff{1}))
                    db_files{end+1} = dbObj.output_paths.(ff{1}); %#ok<AGROW>
                end
            end
            tied = app.wProj.stormdb_tied_sims(db_name);
            if ~isempty(tied)
                % Tied Simulations: Only Delete (Results Of A Removed Storm DB Could Not Be Shown Or Rerun)
                n_max = 15;
                lines = strcat({['  ' char(8226) ' ']}, tied);
                if numel(lines) > n_max
                    lines = [lines(1:n_max-1); {sprintf('  %sand %d more', char(8230), numel(tied) - n_max + 1)}];
                end
                msg = sprintf('Storm DB "%s" is tied to the following simulations:\n%s\n\nDeleting the storm DB will remove these alternatives'' simulation results.',...
                    db_name, strjoin(lines, newline));
                app.auxLib.choice_dlgbox(msg, {'Delete', 'Cancel'}, 'Remove Storm Database', 560); % Last Button = Default (Enter): Cancel
                answer = app.auxLib.dialog_answer;
                if ~strcmp(answer, 'Delete') % Cancel Or Window Closed
                    return
                end
            else
                msg = sprintf('Remove storm database "%s"?', db_name);
                options = {'Remove', 'Cancel'};
                if ~isempty(db_files)
                    msg = sprintf('%s\n"Remove" keeps its files in Event_Database; "Remove & Delete Files" deletes them.', msg);
                    options = {'Remove', 'Remove & Delete Files', 'Cancel'};
                end
                app.auxLib.choice_dlgbox(msg, options, 'Remove Storm Database');
                answer = app.auxLib.dialog_answer;
                if isempty(answer) || strcmp(answer, 'Cancel') % Cancel Or Window Closed
                    return
                end
            end
            % Drop Cached storm / CHS_Data Of This Database
            keys = app.stormCache.keys();
            stale = keys(ismember(lower(keys), lower(db_files)));
            if ~isempty(stale)
                remove(app.stormCache, stale);
            end
            failed = {};
            switch answer
                case 'Delete'
                    % Run Files Of Its Simulations And The Storm DB Files Deleted; Session State Of The DB Dropped
                    run_files = app.wProj.stormdb_run_files(db_name);
                    app.wProj.remove_stormdb(db_name);
                    for ff = [run_files; db_files']'
                        delete(ff{1});
                        if isfile(ff{1})
                            failed{end+1} = ff{1}; %#ok<AGROW>
                        end
                    end
                    app.oldDbWarned = app.oldDbWarned(~ismember(lower(app.oldDbWarned), lower(db_files)));
                    app.simKey = [];
                    app.declinedSimKey = '';
                    app.resultsState = [];
                case 'Remove & Delete Files'
                    app.wProj.remove_stormdb(db_name);
                    cellfun(@delete, db_files);
                otherwise
                    app.wProj.remove_stormdb(db_name);
            end
            % Last CHS (Non-Custom) Storm DB Removed: The Project Has No Region, Its CHS_Dependencies Is Free Again
            if isempty(app.wProj.project_region())
                app.wProj.chs_dependencies = '';
            end
            % Refresh & Save
            app.set_active_selection(app.wProj.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            app.refresh_active_view();
            app.save_project();
            if ~isempty(failed)
                uialert(app.UIFigure, sprintf('Storm DB "%s" removed, but these files could not be deleted:\n%s',...
                    db_name, strjoin(failed, newline)), 'Remove Storm Database', 'Icon', 'warning');
            end
        end

        % Menu selected function: TidesMenu
        function TidesMenuSelected(app, event)
            % Download A NOAA Tidal Prediction File Into The Project (Tides UI), Then Refresh The Run Tab
            if isempty(app.wProj)
                return
            end
            tidesUI = NOAATidesPredictionsUI(app.wProj, app.UIFigure);
            try % Wait Until The Tides UI Closes (It Closes Itself After A Successful Download)
                waitfor(tidesUI.UIFigure);
            catch % Already Closed
            end
            % Refresh & Save
            app.set_active_selection(app.wProj.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
            app.refresh_active_view();
            app.save_project();
        end

        % Cell edit callback: PSETable
        function PSETableCellEdit(app, event)
            % [NEW] PSE Viewer: Edit A Value Of The Active PSE/Alternative (Rows Are Added/Removed In The PSE Creation Dialog Only)
            row = event.Indices(1);
            col = event.Indices(2);
            if col ~= 4 || ~app.has_active_alt()
                app.PSETable.Data{row, col} = event.PreviousData;
                return
            end
            val = event.NewData;
            if ~(isnumeric(val) && isscalar(val) && isreal(val) && isfinite(val))
                app.PSETable.Data{row, col} = event.PreviousData;
                uialert(app.UIFigure, sprintf('%s must be a finite number.', app.PSETable.Data{row, 2}),...
                    'PSE Viewer: Invalid Value', 'Icon', 'warning');
                return
            end
            [pse_name, alt_name] = app.get_active_names();
            old_tbl = app.wProj.get_project_field('pse_tables', pse_name, alt_name, 'alt');
            geo = app.wProj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            % Rebuild The Geometry (Library Rules); A Library Error Restores The Previous Table (pse_geometry Is Only Set On Success)
            symbol = app.PSETable.Data{row, 1};
            new_tbl = old_tbl;
            new_tbl{strcmp(old_tbl(:, 1), symbol), 4} = val;
            app.wProj.set_project_field('pse_tables', new_tbl, pse_name, alt_name, 'alt');
            try
                app.wProj.create_geometry(pse_name, alt_name, geo.pse_type);
            catch ME
                app.PSETable.Data{row, col} = event.PreviousData;
                app.wProj.set_project_field('pse_tables', old_tbl, pse_name, alt_name, 'alt');
                uialert(app.UIFigure, ['Could not rebuild the PSE geometry: ' ME.message], 'PSE Viewer: Invalid Value');
                return
            end
            app.plot_pse_geometry(app.PSEAxes, app.plotFontSize, false);
            app.save_project();
            % Constants Table (Water Density, Resolved Offshore Elevation) And Status Bar (PSE Geometry Vs Loaded Results). Same Key: No sync_saved_sim
            app.populate_constants_table();
            if ~isempty(app.resultsState)
                app.set_sim_status(app.results_status());
            end
        end

        % Menu selected function: RemoveAlternativeSimulationMenu
        function RemoveAlternativeSimulationMenuSelected(app, event)
            % Delete Simulations (Storm DB | Workflow Run Files) Of An Alternative Of The Active PSE (remove_alt_sims Dialog)
            if ~app.has_active_alt()
                return
            end
            [pse_name, alt_name] = app.get_active_names();
            app.remove_alt_sims(app.wProj, pse_name, alt_name, '');
        end

        % Menu selected function: MultilineTransectMenu
        function MultilineTransectMenuSelected(app, event)
            % Multi-Line Transect: A New Multi-Line PSE (Its '<name>_stage_1' Rubble Mound) Or A '<name>_stage_2' Alternative
            % (Any PSE Type) Of An Existing One, Through The PSE Creation Wizard (Locked Suffix). The Multi-Line Link
            % (chessProject.link_multiline) Is Written Only Once The Wizard Created The Alternative
            if isempty(app.wProj)
                return
            end
            new_item = 'New multi-line PSE';
            app.auxLib.dropdown_input_dlgbox('Choose multi-line transect first stage PSE', [{new_item}, app.wProj.multiline_pses()],...
                'Choose multi-line transect first stage PSE', 'OK');
            choice = app.auxLib.dialog_answer;
            if isempty(choice)
                return
            end
            if strcmp(choice, new_item)
                % Stage 1: Always A New Rubble Mound
                obj = PSECreationUI(app.RubbleMoundMenu.Text, app.wProj, '', app.UIFigure, 1);
                uiwait(obj.uifig);
                if ~obj.pse_created
                    app.wProj.remove_pse(obj.pse_name);
                    app.set_active_selection(app.wProj.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
                    return
                end
                app.wProj.link_multiline(obj.pse_name, obj.alt_name, 1);
            else
                % Stage 2: PSE Type Picked From The Add PSE Menu Labels
                types = {app.LeveeMenu.Text, app.RubbleMoundMenu.Text, app.FloodwallMenu.Text, app.LowCrestedBreakwaterMenu.Text};
                app.auxLib.dropdown_input_dlgbox(sprintf('PSE type of the second-stage alternative of "%s".', choice), types,...
                    'Multi-line Transect: Stage 2', 'OK');
                pse_type = app.auxLib.dialog_answer;
                if isempty(pse_type)
                    return
                end
                obj = PSECreationUI(pse_type, app.wProj, choice, app.UIFigure, 2);
                uiwait(obj.uifig);
                if ~obj.pse_created
                    app.wProj.remove_alternative(obj.pse_name, obj.alt_name);
                    app.set_active_selection(app.wProj.name, app.PSEDropDown.Value, app.AlternativeDropDown.Value);
                    return
                end
                app.wProj.link_multiline(obj.pse_name, obj.alt_name, 2);
            end
            app.set_active_selection(app.wProj.name, obj.pse_name, obj.alt_name);
            app.project_field_ini();
            app.refresh_active_view();
            app.save_project();
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % Active Project's Lock Released (Another Session Can Open It), Then The App Closes
            app.release_project_lock();
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
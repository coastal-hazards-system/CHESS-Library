classdef CHSStormDBImportUI < handle

    % Properties that correspond to UI components
    properties (Access = private)
        GridLayout8                    matlab.ui.container.GridLayout
        Panel_2                        matlab.ui.container.Panel
        GridLayout9                    matlab.ui.container.GridLayout
        PlotControlsPanel              matlab.ui.container.Panel
        GridLayout10                   matlab.ui.container.GridLayout
        GridLayout12                   matlab.ui.container.GridLayout
        StormIDDropDown                matlab.ui.control.DropDown
        StormIDToPlotDropDownLabel     matlab.ui.control.Label
        FieldtoPlotDropDown            matlab.ui.control.DropDown
        FieldtoPlotDropDownLabel       matlab.ui.control.Label
        GridLayout11                   matlab.ui.container.GridLayout
        MatchTypeDropDown              matlab.ui.control.DropDown
        MatchTypeDropDownLabel         matlab.ui.control.Label
        DataTypeDropDown               matlab.ui.control.DropDown
        DataTypeDropDownLabel          matlab.ui.control.Label
        StormTypeDropDown              matlab.ui.control.DropDown
        StormTypeDropDownLabel         matlab.ui.control.Label
        PlotControlsLabel              matlab.ui.control.Label
        StudyPreviewTable              matlab.ui.control.Table
        PreviewStudyDetailsLabel       matlab.ui.control.Label
        Panel                          matlab.ui.container.Panel
        GridLayout                     matlab.ui.container.GridLayout
        GridLayout2_5                  matlab.ui.container.GridLayout
        ImportButton                   matlab.ui.control.Button
        CreateStormDBButton            matlab.ui.control.Button
        VerticalOffsetEditField        matlab.ui.control.NumericEditField
        VerticalDatumLabel             matlab.ui.control.Label
        GridLayout2_4                  matlab.ui.container.GridLayout
        StormDBNameLamp                matlab.ui.control.Lamp
        StormDBNameMessageLabel        matlab.ui.control.Label
        StormDBNameEditField           matlab.ui.control.EditField
        StormDBNameEditFieldLabel      matlab.ui.control.Label
        GridLayout2_3                  matlab.ui.container.GridLayout
        CreateWLPStormDBCheckBox       matlab.ui.control.CheckBox
        CreateWHPStormDBCheckBox       matlab.ui.control.CheckBox
        OptionalStormDBLabel           matlab.ui.control.Label
        GridLayout2_2                  matlab.ui.container.GridLayout
        studyDependenciesLamp          matlab.ui.control.Lamp
        CHSStudyDependenciesEditField  matlab.ui.control.EditField
        chsDependenciesFolderButton    matlab.ui.control.Button
        CHSStudyDependenciesFolderLabel  matlab.ui.control.Label
        GridLayout2                    matlab.ui.container.GridLayout
        CHSZipFolderLamp               matlab.ui.control.Lamp
        CHSZipFolderEditField          matlab.ui.control.EditField
        chsZipFolderButton             matlab.ui.control.Button
        chsURLButton                   matlab.ui.control.Button
        CHSZipFolderLabel              matlab.ui.control.Label
        ImportCHSStudyLabel            matlab.ui.control.Label
        DefineCHSStudyFilesLabel       matlab.ui.control.Label
        StormDBPanel                   matlab.ui.container.Panel
        GridLayout6                    matlab.ui.container.GridLayout
        StormDBTable                   matlab.ui.control.Table
        GridLayout7                    matlab.ui.container.GridLayout
        ExpandTableButton              matlab.ui.control.Button
        ExpandFigureButton             matlab.ui.control.Button
        StormDBAxes                    matlab.ui.control.UIAxes
    end

    properties (Access=public)
        figUI                          matlab.ui.Figure
        db_created logical
        modeling_imported logical
        db_name char
        source_paths
        output_paths
        outpath char
        sp_coords double % Savepoint [Latitude Longitude] (First ADCIRC Storm File Root Attributes; [] Unknown): Study Grid Lookup
        create_wlp logical
        create_whp logical
        gravity_constant double
        storm_duration double % [hrs] Stamped On Peaks Column 6 As hours/24 (datenum Days)
        overwrite_flag logical
        study char
        study_datum char
        db_info % Storm Database Details (Library storm_db_info.m): Bias & Uncertainty, TC Bias Correction, Nyrs_XC/Nstm_XC
    end

    properties (Access=private)
        auxLib
        has_peaks logical
        has_timeseries logical
        h5_names cell
        storm_types cell
        sp_ids
        outpath_dirlist
        unc_applied logical
        f_adjusted logical
        dlgObj
        project_datum
        project_unitsys
        unitLib
        db_for_ui
        chs_data_cache % CHS_Data Loaded From A .mat (src, CHS_Data)
        storm_data_input % storm & prob_mass .mat Import (src, storm, prob_mass, create_wlp, create_whp, BnU)
        expected_region char % Project Region (chessProject.project_region; '': None): CHS_Dependencies Must Hold It, CHS Data Must Match
        name_state % Storm DB Name Status: 'red' (Invalid) | 'green' | 'yellow' (Exists: Overwrite Confirmed At Import)
    end

    properties (Access=private, Transient)
        parent_fig % Window The Wizard Opens Centered On ([]: Screen). Transient: The Storm DB Is Saved In The Project File, The App Window Must Not Be
        existing_db_names cell = {} % Storm DB Names Of The Project (Case-Insensitive Clash: Overwrite, Confirmed At Import)
        db_usage_fcn % @(db_name) [n_alt, n_run_files] Of A Project Storm DB, For The Overwrite Confirmation ([]: Not Shown)
    end

    %% CONSTRUCTOR
    % App creation and deletion
    methods (Access = public)
        % Construct app
        function obj = CHSStormDBImportUI(chs_dependencies_path, outpath, gravity_constant, project_datum, project_unitsys, parent_fig, expected_region, existing_db_names, db_usage_fcn)
            arguments
                chs_dependencies_path {mustBeText(chs_dependencies_path)}
                outpath {mustBeText(outpath)}
                gravity_constant {mustBeFloat(gravity_constant)}
                project_datum {mustBeText(project_datum)}
                project_unitsys {mustBeMember(project_unitsys, {'SI','Imperial'})}
                parent_fig = []
                expected_region {mustBeText(expected_region)} = ''
                existing_db_names cell = {}
                db_usage_fcn = []
            end
            obj.parent_fig = parent_fig;
            obj.expected_region = expected_region;
            obj.existing_db_names = existing_db_names;
            obj.db_usage_fcn = db_usage_fcn;
            obj.overwrite_flag = false;
            obj.source_paths.chs_dependencies_path = chs_dependencies_path;
            obj.outpath = outpath;
            obj.modeling_imported = false;
            obj.db_created = false;
            obj.auxLib = auxUIFunctions();
            obj.outpath_dirlist = dir(outpath);
            obj.unc_applied = false;
            obj.f_adjusted = false;
            obj.gravity_constant = gravity_constant;
            obj.project_datum = project_datum;
            obj.project_unitsys = project_unitsys;
            obj.create_wlp = false;
            obj.create_whp = false;
            obj.unitLib = obj.auxLib.update_unit_system(project_unitsys);
        end
    end

    %% UI METHODS
    % Component initialization
    methods (Access = public)
        % Create uifig and components
        function create_ui(obj)
            obj.reset_db_state();
            obj.clear_staging(); % Left By A Session That Ended Without Closing The Wizard
            obj.figUI = uifigure('Visible', 'off');
            obj.figUI.Position = [100 100 972 444];
            obj.figUI.Name = 'CHS Storm Database Import Wizard';

            % Create GridLayout8
           obj.GridLayout8 = uigridlayout(obj.figUI);
           obj.GridLayout8.ColumnWidth = {'1.14x', '1x'};
           obj.GridLayout8.RowHeight = {'1x'};
           obj.GridLayout8.ColumnSpacing = 0;
           obj.GridLayout8.Padding = [2 2 2 2];

            % Create StormDBPanel
           obj.StormDBPanel = uipanel(obj.GridLayout8);
           obj.StormDBPanel.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.StormDBPanel.BorderType = 'line';
           obj.StormDBPanel.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.StormDBPanel.Layout.Row = 1;
           obj.StormDBPanel.Layout.Column = 2;

            % Create GridLayout6
           obj.GridLayout6 = uigridlayout(obj.StormDBPanel);
           obj.GridLayout6.ColumnWidth = {'1x'};
           obj.GridLayout6.RowHeight = {'1x', 'fit', '0.8x'};
           obj.GridLayout6.Padding = [3 3 3 3];

            % Create StormDBAxes
           obj.StormDBAxes = uiaxes(obj.GridLayout6);
            xlabel(obj.StormDBAxes, 'X')
            ylabel(obj.StormDBAxes, 'Elevation [m] (NAVD88)')
            zlabel(obj.StormDBAxes, 'Z')
           obj.StormDBAxes.XGrid = 'on';
           obj.StormDBAxes.XMinorGrid = 'on';
           obj.StormDBAxes.YGrid = 'on';
           obj.StormDBAxes.YMinorGrid = 'on';
           obj.StormDBAxes.ZGrid = 'on';
           obj.StormDBAxes.ZMinorGrid = 'on';
           obj.StormDBAxes.Box = 'on';
           obj.StormDBAxes.Layout.Row = 1;
           obj.StormDBAxes.Layout.Column = 1;

            % Create GridLayout7
           obj.GridLayout7 = uigridlayout(obj.GridLayout6);
           obj.GridLayout7.ColumnWidth = {'fit', 'fit'};
           obj.GridLayout7.RowHeight = {'1x'};
           obj.GridLayout7.ColumnSpacing = 3;
           obj.GridLayout7.Padding = [0 0 0 0];
           obj.GridLayout7.Layout.Row = 2;
           obj.GridLayout7.Layout.Column = 1;

            % Create ExpandFigureButton
           obj.ExpandFigureButton = uibutton(obj.GridLayout7, 'push');
           obj.ExpandFigureButton.Icon = 'eye_icon.png';
           obj.ExpandFigureButton.IconAlignment = 'center';
           obj.ExpandFigureButton.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.ExpandFigureButton.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.ExpandFigureButton.Layout.Row = 1;
           obj.ExpandFigureButton.Layout.Column = 1;
           obj.ExpandFigureButton.Text = '';

            % Create ExpandTableButton
           obj.ExpandTableButton = uibutton(obj.GridLayout7, 'push');
           obj.ExpandTableButton.Icon = 'table_icon.png';
           obj.ExpandTableButton.IconAlignment = 'center';
           obj.ExpandTableButton.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.ExpandTableButton.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.ExpandTableButton.Layout.Row = 1;
           obj.ExpandTableButton.Layout.Column = 2;
           obj.ExpandTableButton.Text = '';

            % Create StormDBTable
           obj.StormDBTable = uitable(obj.GridLayout6);
           obj.StormDBTable.BackgroundColor = [1 1 1;0.96078431372549 0.96078431372549 0.96078431372549];
           obj.StormDBTable.ColumnName = {'Column 1'; 'Column 2'};
           obj.StormDBTable.RowName = {};
           obj.StormDBTable.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.StormDBTable.Layout.Row = 3;
           obj.StormDBTable.Layout.Column = 1;

            % Create Panel_2
           obj.Panel_2 = uipanel(obj.GridLayout8);
           obj.Panel_2.Layout.Row = 1;
           obj.Panel_2.Layout.Column = 1;

            % Create GridLayout9
           obj.GridLayout9 = uigridlayout(obj.Panel_2);
           obj.GridLayout9.ColumnWidth = {'1x'};
           obj.GridLayout9.RowHeight = {'fit', 'fit', '1x', 'fit', 'fit'};
           obj.GridLayout9.Padding = [3 3 3 3];

            % Create Panel
           obj.Panel = uipanel(obj.GridLayout9);
           obj.Panel.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.Panel.BorderType = 'line';
           obj.Panel.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.Panel.Layout.Row = 1;
           obj.Panel.Layout.Column = 1;

            % Create GridLayout
           obj.GridLayout = uigridlayout(obj.Panel);
           obj.GridLayout.ColumnWidth = {'1x'};
           obj.GridLayout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
           obj.GridLayout.RowSpacing = 5;
           obj.GridLayout.Padding = [3 3 3 3];

            % Create DefineCHSStudyFilesLabel
           obj.DefineCHSStudyFilesLabel = uilabel(obj.GridLayout);
           obj.DefineCHSStudyFilesLabel.FontSize = 16;
           obj.DefineCHSStudyFilesLabel.FontWeight = 'bold';
           obj.DefineCHSStudyFilesLabel.Layout.Row = 1;
           obj.DefineCHSStudyFilesLabel.Layout.Column = 1;
           obj.DefineCHSStudyFilesLabel.Text = '1. Define CHS Study Files';

            % Create ImportCHSStudyLabel
           obj.ImportCHSStudyLabel = uilabel(obj.GridLayout);
           obj.ImportCHSStudyLabel.FontSize = 16;
           obj.ImportCHSStudyLabel.FontWeight = 'bold';
           obj.ImportCHSStudyLabel.Layout.Row = 4;
           obj.ImportCHSStudyLabel.Layout.Column = 1;
           obj.ImportCHSStudyLabel.Text = '2. Import CHS Study';

            % Create GridLayout2
           obj.GridLayout2 = uigridlayout(obj.GridLayout);
           obj.GridLayout2.ColumnWidth = {'fit', 30, 30, '1x', 20};
           obj.GridLayout2.RowHeight = {'fit'};
           obj.GridLayout2.ColumnSpacing = 5;
           obj.GridLayout2.Padding = [5 0 0 0];
           obj.GridLayout2.Layout.Row = 2;
           obj.GridLayout2.Layout.Column = 1;

            % Create CHSZipFolderLabel
           obj.CHSZipFolderLabel = uilabel(obj.GridLayout2);
           obj.CHSZipFolderLabel.Layout.Row = 1;
           obj.CHSZipFolderLabel.Layout.Column = 1;
           obj.CHSZipFolderLabel.Text = 'CHS Zip Folder:';

            % Create chsURLButton
           obj.chsURLButton = uibutton(obj.GridLayout2, 'push');
           obj.chsURLButton.Icon = 'web_icon.png';
           obj.chsURLButton.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.chsURLButton.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.chsURLButton.Layout.Row = 1;
           obj.chsURLButton.Layout.Column = 2;
           obj.chsURLButton.Text = '';

            % Create chsZipFolderButton
           obj.chsZipFolderButton = uibutton(obj.GridLayout2, 'push');
           obj.chsZipFolderButton.Icon = 'file_icon.png';
           obj.chsZipFolderButton.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.chsZipFolderButton.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.chsZipFolderButton.Enable = 'off';
           obj.chsZipFolderButton.Layout.Row = 1;
           obj.chsZipFolderButton.Layout.Column = 3;
           obj.chsZipFolderButton.Text = '';

            % Create CHSZipFolderEditField
           obj.CHSZipFolderEditField = uieditfield(obj.GridLayout2, 'text');
           obj.CHSZipFolderEditField.Placeholder = 'Choose CHS modeling .zip or CHS_Data .mat...';
           obj.CHSZipFolderEditField.Layout.Row = 1;
           obj.CHSZipFolderEditField.Layout.Column = 4;

            % Create CHSZipFolderLamp
           obj.CHSZipFolderLamp = uilamp(obj.GridLayout2);
           obj.CHSZipFolderLamp.Layout.Row = 1;
           obj.CHSZipFolderLamp.Layout.Column = 5;
           obj.CHSZipFolderLamp.Color = [1 0 0];

            % Create GridLayout2_2
           obj.GridLayout2_2 = uigridlayout(obj.GridLayout);
           obj.GridLayout2_2.ColumnWidth = {'fit', 30, '1x', 20};
           obj.GridLayout2_2.RowHeight = {'1x'};
           obj.GridLayout2_2.ColumnSpacing = 5;
           obj.GridLayout2_2.Padding = [5 0 0 0];
           obj.GridLayout2_2.Layout.Row = 3;
           obj.GridLayout2_2.Layout.Column = 1;

            % Create CHSStudyDependenciesFolderLabel
           obj.CHSStudyDependenciesFolderLabel = uilabel(obj.GridLayout2_2);
           obj.CHSStudyDependenciesFolderLabel.WordWrap = 'on';
           obj.CHSStudyDependenciesFolderLabel.Layout.Row = 1;
           obj.CHSStudyDependenciesFolderLabel.Layout.Column = 1;
           obj.CHSStudyDependenciesFolderLabel.Text = 'CHS Study Dependencies Folder:';

            % Create chsDependenciesFolderButton
           obj.chsDependenciesFolderButton = uibutton(obj.GridLayout2_2, 'push');
           obj.chsDependenciesFolderButton.Icon = 'file_icon.png';
           obj.chsDependenciesFolderButton.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.chsDependenciesFolderButton.FontColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.chsDependenciesFolderButton.Layout.Row = 1;
           obj.chsDependenciesFolderButton.Layout.Column = 2;
           obj.chsDependenciesFolderButton.Text = '';

            % Create CHSStudyDependenciesEditField
           obj.CHSStudyDependenciesEditField = uieditfield(obj.GridLayout2_2, 'text');
           obj.CHSStudyDependenciesEditField.Placeholder = 'Choose CHS dependencies folder...';
           obj.CHSStudyDependenciesEditField.Layout.Row = 1;
           obj.CHSStudyDependenciesEditField.Layout.Column = 3;

            % Create studyDependenciesLamp
           obj.studyDependenciesLamp = uilamp(obj.GridLayout2_2);
           obj.studyDependenciesLamp.Layout.Row = 1;
           obj.studyDependenciesLamp.Layout.Column = 4;
           obj.studyDependenciesLamp.Color = [1 0 0];

            % Create GridLayout2_3
           obj.GridLayout2_3 = uigridlayout(obj.GridLayout);
           obj.GridLayout2_3.ColumnWidth = {'fit', '1x', '1x'};
           obj.GridLayout2_3.RowHeight = {'1x'};
           obj.GridLayout2_3.Padding = [5 0 0 0];
           obj.GridLayout2_3.Layout.Row = 5;
           obj.GridLayout2_3.Layout.Column = 1;

            % Create OptionalStormDBLabel
           obj.OptionalStormDBLabel = uilabel(obj.GridLayout2_3);
           obj.OptionalStormDBLabel.Layout.Row = 1;
           obj.OptionalStormDBLabel.Layout.Column = 1;
           obj.OptionalStormDBLabel.Text = 'Optional Storm DB:';

            % Create CreateWHPStormDBCheckBox
           obj.CreateWHPStormDBCheckBox = uicheckbox(obj.GridLayout2_3);
           obj.CreateWHPStormDBCheckBox.Text = 'Create WHP Storm DB';
           obj.CreateWHPStormDBCheckBox.Layout.Row = 1;
           obj.CreateWHPStormDBCheckBox.Layout.Column = 2;

            % Create CreateWLPStormDBCheckBox
           obj.CreateWLPStormDBCheckBox = uicheckbox(obj.GridLayout2_3);
           obj.CreateWLPStormDBCheckBox.Text = 'Create WLP Storm DB';
           obj.CreateWLPStormDBCheckBox.Layout.Row = 1;
           obj.CreateWLPStormDBCheckBox.Layout.Column = 3;

            % Create GridLayout2_4
           obj.GridLayout2_4 = uigridlayout(obj.GridLayout);
           obj.GridLayout2_4.ColumnWidth = {'fit', '1x', 20};
           obj.GridLayout2_4.RowHeight = {'fit', 'fit'};
           obj.GridLayout2_4.RowSpacing = 2;
           obj.GridLayout2_4.Padding = [5 0 0 0];
           obj.GridLayout2_4.Layout.Row = 6;
           obj.GridLayout2_4.Layout.Column = 1;

            % Create StormDBNameEditFieldLabel
           obj.StormDBNameEditFieldLabel = uilabel(obj.GridLayout2_4);
           obj.StormDBNameEditFieldLabel.Layout.Row = 1;
           obj.StormDBNameEditFieldLabel.Layout.Column = 1;
           obj.StormDBNameEditFieldLabel.Text = 'Storm DB Name:';

            % Create StormDBNameEditField
           obj.StormDBNameEditField = uieditfield(obj.GridLayout2_4, 'text');
           obj.StormDBNameEditField.Placeholder = 'Set Database Name';
           obj.StormDBNameEditField.Layout.Row = 1;
           obj.StormDBNameEditField.Layout.Column = 2;

            % Create StormDBNameLamp
           obj.StormDBNameLamp = uilamp(obj.GridLayout2_4);
           obj.StormDBNameLamp.Layout.Row = 1;
           obj.StormDBNameLamp.Layout.Column = 3;
           obj.StormDBNameLamp.Color = [1 0 0];

            % Create StormDBNameMessageLabel
           obj.StormDBNameMessageLabel = uilabel(obj.GridLayout2_4);
           obj.StormDBNameMessageLabel.Layout.Row = 2;
           obj.StormDBNameMessageLabel.Layout.Column = [2 3];
           obj.StormDBNameMessageLabel.FontSize = 11;
           obj.StormDBNameMessageLabel.Text = '';

            % Create GridLayout2_5
           obj.GridLayout2_5 = uigridlayout(obj.GridLayout);
           obj.GridLayout2_5.ColumnWidth = {'fit', '1x', 'fit', 'fit'};
           obj.GridLayout2_5.RowHeight = {'fit'};
           obj.GridLayout2_5.Padding = [0 0 0 0];
           obj.GridLayout2_5.Layout.Row = 7;
           obj.GridLayout2_5.Layout.Column = 1;

            % Create VerticalDatumLabel
           obj.VerticalDatumLabel = uilabel(obj.GridLayout2_5);
           obj.VerticalDatumLabel.WordWrap = 'on';
           obj.VerticalDatumLabel.Layout.Row = 1;
           obj.VerticalDatumLabel.Layout.Column = 1;
           obj.VerticalDatumLabel.Text = 'MSLLL To NAVD88 Vertical Offset:';

            % Create VerticalOffsetEditField
           obj.VerticalOffsetEditField = uieditfield(obj.GridLayout2_5, 'numeric');
           obj.VerticalOffsetEditField.HorizontalAlignment = 'center';
           obj.VerticalOffsetEditField.Layout.Row = 1;
           obj.VerticalOffsetEditField.Layout.Column = 2;

            % Create CreateStormDBButton
           obj.CreateStormDBButton = uibutton(obj.GridLayout2_5, 'push');
           obj.CreateStormDBButton.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.CreateStormDBButton.Enable = 'off';
           obj.CreateStormDBButton.Layout.Row = 1;
           obj.CreateStormDBButton.Layout.Column = 3;
           obj.CreateStormDBButton.Text = 'Create Storm DB';

            % Create ImportButton
           obj.ImportButton = uibutton(obj.GridLayout2_5, 'push');
           obj.ImportButton.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.ImportButton.Enable = 'off';
           obj.ImportButton.Layout.Row = 1;
           obj.ImportButton.Layout.Column = 4;
           obj.ImportButton.Text = 'Import to Project';

            % Create PreviewStudyDetailsLabel
           obj.PreviewStudyDetailsLabel = uilabel(obj.GridLayout9);
           obj.PreviewStudyDetailsLabel.FontSize = 16;
           obj.PreviewStudyDetailsLabel.FontWeight = 'bold';
           obj.PreviewStudyDetailsLabel.Layout.Row = 2;
           obj.PreviewStudyDetailsLabel.Layout.Column = 1;
           obj.PreviewStudyDetailsLabel.Text = 'Preview Study Details';

            % Create StudyPreviewTable
           obj.StudyPreviewTable = uitable(obj.GridLayout9);
           obj.StudyPreviewTable.BackgroundColor = [1 1 1;0.96078431372549 0.96078431372549 0.96078431372549];
           obj.StudyPreviewTable.ColumnName = {'Study Details'; 'Value'};
           obj.StudyPreviewTable.RowName = {};
           obj.StudyPreviewTable.ColumnSortable = [true false];
           obj.StudyPreviewTable.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.StudyPreviewTable.Layout.Row = 3;
           obj.StudyPreviewTable.Layout.Column = 1;

            % Create PlotControlsLabel
           obj.PlotControlsLabel = uilabel(obj.GridLayout9);
           obj.PlotControlsLabel.FontSize = 16;
           obj.PlotControlsLabel.FontWeight = 'bold';
           obj.PlotControlsLabel.Layout.Row = 4;
           obj.PlotControlsLabel.Layout.Column = 1;
           obj.PlotControlsLabel.Text = 'Plot Controls';

            % Create PlotControlsPanel
           obj.PlotControlsPanel = uipanel(obj.GridLayout9);
           obj.PlotControlsPanel.Enable = 'off';
           obj.PlotControlsPanel.ForegroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
           obj.PlotControlsPanel.BorderType = 'line';
           obj.PlotControlsPanel.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.PlotControlsPanel.Layout.Row = 5;
           obj.PlotControlsPanel.Layout.Column = 1;

            % Create GridLayout10
           obj.GridLayout10 = uigridlayout(obj.PlotControlsPanel);
           obj.GridLayout10.ColumnWidth = {'1x'};
           obj.GridLayout10.RowSpacing = 5;
           obj.GridLayout10.Padding = [3 3 3 3];

            % Create GridLayout11
           obj.GridLayout11 = uigridlayout(obj.GridLayout10);
           obj.GridLayout11.ColumnWidth = {70, '1x', 'fit', '1x', 'fit', '1x'};
           obj.GridLayout11.RowHeight = {'fit'};
           obj.GridLayout11.ColumnSpacing = 5;
           obj.GridLayout11.Padding = [0 0 0 0];
           obj.GridLayout11.Layout.Row = 1;
           obj.GridLayout11.Layout.Column = 1;

            % Create StormTypeDropDownLabel
           obj.StormTypeDropDownLabel = uilabel(obj.GridLayout11);
           obj.StormTypeDropDownLabel.Layout.Row = 1;
           obj.StormTypeDropDownLabel.Layout.Column = 1;
           obj.StormTypeDropDownLabel.Text = 'Storm Type:';

            % Create StormTypeDropDown
           obj.StormTypeDropDown = uidropdown(obj.GridLayout11);
           obj.StormTypeDropDown.Items = {'-'};
           obj.StormTypeDropDown.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.StormTypeDropDown.Layout.Row = 1;
           obj.StormTypeDropDown.Layout.Column = 2;
           obj.StormTypeDropDown.Value = '-';

            % Create DataTypeDropDownLabel
           obj.DataTypeDropDownLabel = uilabel(obj.GridLayout11);
           obj.DataTypeDropDownLabel.Layout.Row = 1;
           obj.DataTypeDropDownLabel.Layout.Column = 3;
           obj.DataTypeDropDownLabel.Text = 'Data Type:';

            % Create DataTypeDropDown
           obj.DataTypeDropDown = uidropdown(obj.GridLayout11);
           obj.DataTypeDropDown.Items = {'-'};
           obj.DataTypeDropDown.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.DataTypeDropDown.Layout.Row = 1;
           obj.DataTypeDropDown.Layout.Column = 4;
           obj.DataTypeDropDown.Value = '-';

            % Create MatchTypeDropDownLabel
           obj.MatchTypeDropDownLabel = uilabel(obj.GridLayout11);
           obj.MatchTypeDropDownLabel.Layout.Row = 1;
           obj.MatchTypeDropDownLabel.Layout.Column = 5;
           obj.MatchTypeDropDownLabel.Text = 'Match Type:';

            % Create MatchTypeDropDown
           obj.MatchTypeDropDown = uidropdown(obj.GridLayout11);
           obj.MatchTypeDropDown.Items = {'-'};
           obj.MatchTypeDropDown.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.MatchTypeDropDown.Layout.Row = 1;
           obj.MatchTypeDropDown.Layout.Column = 6;
           obj.MatchTypeDropDown.Value = '-';

            % Create GridLayout12
           obj.GridLayout12 = uigridlayout(obj.GridLayout10);
           obj.GridLayout12.ColumnWidth = {70, '1x', 'fit', '1x'};
           obj.GridLayout12.RowHeight = {'fit'};
           obj.GridLayout12.ColumnSpacing = 5;
           obj.GridLayout12.Padding = [0 0 0 0];
           obj.GridLayout12.Layout.Row = 2;
           obj.GridLayout12.Layout.Column = 1;

            % Create FieldtoPlotDropDownLabel
           obj.FieldtoPlotDropDownLabel = uilabel(obj.GridLayout12);
           obj.FieldtoPlotDropDownLabel.Layout.Row = 1;
           obj.FieldtoPlotDropDownLabel.Layout.Column = 1;
           obj.FieldtoPlotDropDownLabel.Text = 'Field to Plot:';

            % Create FieldtoPlotDropDown
           obj.FieldtoPlotDropDown = uidropdown(obj.GridLayout12);
           obj.FieldtoPlotDropDown.Items = {'-'};
           obj.FieldtoPlotDropDown.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.FieldtoPlotDropDown.Layout.Row = 1;
           obj.FieldtoPlotDropDown.Layout.Column = 2;
           obj.FieldtoPlotDropDown.Value = '-';

            % Create StormIDToPlotDropDownLabel
           obj.StormIDToPlotDropDownLabel = uilabel(obj.GridLayout12);
           obj.StormIDToPlotDropDownLabel.Layout.Row = 1;
           obj.StormIDToPlotDropDownLabel.Layout.Column = 3;
           obj.StormIDToPlotDropDownLabel.Text = 'Storm ID To Plot:';

            % Create StormIDDropDown
           obj.StormIDDropDown = uidropdown(obj.GridLayout12);
           obj.StormIDDropDown.Items = {'-', ''};
           obj.StormIDDropDown.BackgroundColor = [0.96078431372549 0.96078431372549 0.96078431372549];
           obj.StormIDDropDown.Layout.Row = 1;
           obj.StormIDDropDown.Layout.Column = 4;
           obj.StormIDDropDown.Value = '-';

            obj.init_chs_dependencies();

            % Show the figure after all components are created (Centered On The Parent; Wizard Dialogs Center On The Wizard)
            obj.auxLib.center_on_parent(obj.figUI, obj.parent_fig);
            obj.auxLib.set_parent(obj.figUI);
            obj.figUI.Visible = 'on';

            % Assgin UI Component Callbacks
            obj.figUI.CloseRequestFcn = @(src, event) UIWindowCloseRequest(obj, event);
            % Buttons
            obj.ExpandTableButton.ButtonPushedFcn = @(src, event) popupTableButtonPressed(obj, event);
            obj.ExpandFigureButton.ButtonPushedFcn = @(src, event) popupFigureButtonPressed(obj, event);
            obj.chsURLButton.ButtonPushedFcn = @(src, event) chsButtonPressed(obj, event);
            obj.ImportButton.ButtonPushedFcn = @(src, event) importToProjectButtonPressed(obj, event);
            obj.CreateStormDBButton.ButtonPushedFcn = @(src, event) createStormDbButtonPressed(obj, event);
            obj.chsZipFolderButton.ButtonPushedFcn = @(src, event) getChsZipButtonPressed(obj, event);
            obj.chsDependenciesFolderButton.ButtonPushedFcn = @(src, event) getChsDependenciesButtonPressed(obj, event);
            % EditFields
            obj.StormDBNameEditField.ValueChangedFcn = @(src, event) stormDBNameChanged(obj, event);
            obj.StormDBNameEditField.ValueChangingFcn = @(src, event) update_name_status(obj, event.Value);
            obj.VerticalOffsetEditField.ValueChangedFcn = @(src, event) verticalOffsetValueChanged(obj, event);
            % Check Boxes
            obj.CreateWHPStormDBCheckBox.ValueChangedFcn = @(src, event) checkBoxValueChanged(obj, event);
            obj.CreateWLPStormDBCheckBox.ValueChangedFcn = @(src, event) checkBoxValueChanged(obj, event);
            % Plot Controls (Dropdowns)
            obj.StormTypeDropDown.ValueChangedFcn = @(src, event) stormTypeDropDownValueChanged(obj, event);
            obj.DataTypeDropDown.ValueChangedFcn = @(src, event) dataTypeDropdownValueChanged(obj, event);
            obj.MatchTypeDropDown.ValueChangedFcn = @(src, event) plotControlsChanged(obj, event);
            obj.FieldtoPlotDropDown.ValueChangedFcn = @(src, event) plotControlsChanged(obj, event);
            obj.StormIDDropDown.ValueChangedFcn = @(src, event) plotControlsChanged(obj, event);
            obj.update_name_status(obj.StormDBNameEditField.Value);
        end

    end

    % Callbacks
    methods (Access = private)
        function checkBoxValueChanged(obj, event)
            fstr = strsplit(event.Source.Text, ' ');
            obj.(['create_' lower(fstr{2})]) = event.Source.Value;
        end

        function chsButtonPressed(obj, event)
            web('https://chs.erdc.dren.mil/Home/Index');
        end

        function importToProjectButtonPressed(obj, event)
            % Commit Point: An Existing Storm DB Of That Name (Project Or Event_Database Files) Is Overwritten Once Confirmed
            % (Cancel: Back To The Wizard, Staged Files Kept). Then The Staged Files Take The Final Names (commit_staged)
            [exists, in_project, existing_name] = obj.name_clash(obj.db_name);
            if exists
                if in_project
                    msg = sprintf('Storm DB "%s" already exists. Overwrite?', existing_name);
                    usage = [0 0];
                    if ~isempty(obj.db_usage_fcn)
                        usage = obj.db_usage_fcn(existing_name);
                    end
                    if any(usage > 0)
                        msg = sprintf(['%s\n%d alternative(s) were last run with it. Its %d run file(s) will be deleted and ',...
                            'those alternatives will show no results.'], msg, usage(1), usage(2));
                    end
                else
                    msg = sprintf(['Storm DB "%s" already exists. Overwrite?\nIts files in Event_Database are not part of ',...
                        'the project; they will be replaced.'], obj.db_name);
                end
                obj.auxLib.confirmation_dlgbox(msg, 'Overwrite');
                if ~obj.auxLib.dialog_answer
                    return
                end
            end
            try
                obj.commit_staged();
            catch me
                obj.auxLib.error_dlgbox(['Could not import storm DB "' obj.db_name '": ' me.message]);
                return
            end
            obj.overwrite_flag = exists;
            % Bring project over to parent gui and close ui
            delete(obj.figUI);
            obj.db_created = true;
        end

        function createStormDbButtonPressed(obj, event)
            % Process Provided CHS Modeling zip folder
            obj.import_chs_modeling(obj.CHSZipFolderEditField.Value);
            if obj.modeling_imported
                % storm_duration 1 h: Placeholder Stamped On Peaks Column 6 And WLP/WHP. Not Used As Is: Runs Restamp It With
                % config.storm_duration (Library call_project_forcing_formater) Or Read The Config (Dn50, CSR, FB, LCS)
                [storm, ~] = obj.create_storm_database(obj.create_wlp, obj.create_whp, 1, obj.VerticalOffsetEditField.Value);
                %
                obj.PlotControlsPanel.Enable = 'on';
                obj.update_buttons();
                % Overwrite Variable
                save(obj.output_paths.storm_db, '-append', 'storm');
                %
                stm_types = fieldnames(storm);
                data_types = {'Peaks','Timeseries'}; % There are additional fields at this level
                data_types = data_types([obj.has_peaks, obj.has_timeseries]);
                match_types = fieldnames(storm.(stm_types{1}).(data_types{1}));
                obj.FieldtoPlotDropDown.Items = {'Water Level', 'Wave Height (Hm0)', 'Peak Period'};
                obj.FieldtoPlotDropDown.ItemsData = [1,2,3]; % Col Index To Pull From Storm
                obj.MatchTypeDropDown.Items = match_types;
                obj.DataTypeDropDown.Items = data_types;
                obj.StormTypeDropDown.Items = stm_types;
                obj.StormIDDropDown.Items = cellfun(@num2str, storm.(obj.StormTypeDropDown.Value).(obj.DataTypeDropDown.Value).(obj.MatchTypeDropDown.Value)(:,1), 'UniformOutput', false);
                obj.dataTypeDropdownValueChanged(event);
            else
                obj.ImportButton.Enable = 'off';
                obj.FieldtoPlotDropDown.Items = {'-'};
                obj.MatchTypeDropDown.Items = {'-'};
                obj.DataTypeDropDown.Items = {'-'};
                obj.StormTypeDropDown.Items = {'-'};
                obj.StormIDDropDown.Items = {'-'};
                obj.StormIDDropDown.Enable = 'off';
                obj.StormIDDropDown.Items = {'-'};
                obj.PlotControlsPanel.Enable = 'off';
            end
            obj.outpath_dirlist = dir(obj.outpath);
        end

        function stormTypeDropDownValueChanged(obj, event)
            load(obj.output_paths.storm_db, 'storm');
            obj.StormIDDropDown.Items = cellfun(@num2str, storm.(obj.StormTypeDropDown.Value).(obj.DataTypeDropDown.Value).(obj.MatchTypeDropDown.Value)(:,1), 'UniformOutput', false);
            obj.StormIDDropDown.Value = obj.StormIDDropDown.Items{1};
            obj.plotControlsChanged(event);
        end
        
        function dataTypeDropdownValueChanged(obj, event)
            switch obj.DataTypeDropDown.Value
                case 'Peaks'
                    obj.StormIDDropDown.Enable = 'off';
                    dummy = {'Default','WLP','WHP'};
                    obj.MatchTypeDropDown.Items = dummy([true, obj.create_wlp, obj.create_whp]); % Need to limit to Default
                case 'Timeseries'
                    obj.StormIDDropDown.Enable = 'on';
                    obj.MatchTypeDropDown.Items = {'Default'}; % Need to limit to Default
            end
            obj.plotControlsChanged(event);
        end

        function plotControlsChanged(obj, event) %#ok<*INUSD>
            cla(obj.StormDBAxes);
            load(obj.output_paths.storm_db, 'storm');
            ydata = storm.(obj.StormTypeDropDown.Value).(obj.DataTypeDropDown.Value).(obj.MatchTypeDropDown.Value)(:, 2);
            stm_list = cell2mat(storm.(obj.StormTypeDropDown.Value).(obj.DataTypeDropDown.Value).(obj.MatchTypeDropDown.Value)(:, 1));
            switch obj.DataTypeDropDown.Value
                case 'Peaks'
                    ydata = cell2mat(ydata);
                    ydata = ydata(:, obj.FieldtoPlotDropDown.Value);
                    xlabel(obj.StormDBAxes, 'Events');
                    plot(obj.StormDBAxes, ydata, 'or','LineWidth',1.5, 'MarkerSize', 2);
                    obj.StormDBTable.ColumnName = {'Storm ID', obj.FieldtoPlotDropDown.Items{obj.FieldtoPlotDropDown.Value}};
                    obj.StormDBTable.Data = [num2cell(stm_list), num2cell(ydata)];
                case 'Timeseries'
                    st_indx = str2double(obj.StormIDDropDown.Value) == stm_list;
                    ydata = ydata{st_indx}(:, obj.FieldtoPlotDropDown.Value);
                    xlabel(obj.StormDBAxes, 'Event Timesteps');
                    plot(obj.StormDBAxes, ydata, '-r','LineWidth',1.5);
                    obj.StormDBTable.ColumnName = {'Storm Timestep', obj.FieldtoPlotDropDown.Items{obj.FieldtoPlotDropDown.Value}};
                    obj.StormDBTable.Data = [num2cell(1:length(ydata))', num2cell(ydata)];
            end
            ylabel(obj.StormDBAxes, obj.FieldtoPlotDropDown.Items{obj.FieldtoPlotDropDown.Value});
        end

        function popupFigureButtonPressed(obj, event)
            % Get UI Axes Handle
            ui_axes = obj.StormDBAxes;
            % Create a new figure and axes
            newFig = figure;
            newAxes = axes(newFig);
            % Copy the children (plot contents) of the UI Axes to the new axes
            copyobj(ui_axes.Children, newAxes);
            % Copy properties like limits, labels, etc.
            newAxes.XLim = ui_axes.XLim;
            newAxes.YLim = ui_axes.YLim;
            newAxes.ZLim = ui_axes.ZLim; % If it's a 3D plot
            newAxes.Title.String = ui_axes.Title.String;
            newAxes.XLabel.String = ui_axes.XLabel.String;
            newAxes.YLabel.String = ui_axes.YLabel.String;
            newAxes.XGrid = true;
            newAxes.YGrid = true;
            newAxes.XMinorGrid = true;
            newAxes.YMinorGrid = true;
        end

        function popupTableButtonPressed(obj, event)
            newfig = uifigure;
            newObj = copyobj(obj.StormDBTable, newfig);
            newObj.Position(3:4) = [0.98*newfig.Position(3) 0.98*newfig.Position(4)];
        end

        function stormDBNameChanged(obj, event)
            % Name Only Recorded Here (The Staged Files Do Not Depend On It); Clash Decided At Import
            obj.db_name = obj.StormDBNameEditField.Value;
            obj.update_name_status(obj.db_name);
        end

        function verticalOffsetValueChanged(obj, event)
            % Update Values For Surge/SWL In Storm DB
            if obj.modeling_imported
                % Load Storm DB
                load(obj.output_paths.storm_db, 'storm');
                % Remove Previous Adjustment
                storm = obj.study_datum_adjustment(storm, -1*event.PreviousValue);
                % Adjust Water Level/Surge Response For All Events
                storm = obj.study_datum_adjustment(storm, event.Value);
                % Overwrite Variable
                save(obj.output_paths.storm_db, '-append', 'storm');
                %
                switch obj.FieldtoPlotDropDown.Value
                    case 1
                        % Call Plot Updater Function
                        obj.plotControlsChanged(event);
                end
            end
        end

        function getChsZipButtonPressed(obj, event)
            obj.figUI.Pointer = 'watch';
            fig = obj.figUI;
            pointer_cleanup = onCleanup(@() CHSStormDBImportUI.restore_pointer(fig));
            drawnow;
            obj.reset_db_state();
            % Prompt USer To Select Path
            [sel_file, sel_pth] = uigetfile({'*.zip;*.mat', 'CHS Modeling (*.zip, CHS_Data or storm + prob_mass *.mat)'}, 'Select CHS Modeling Zip Folder Or .mat File');
            %
            if any(sel_file ~= 0)
                % Inspect provided CHS zip folder
                obj.chs_zip_inspect(fullfile(sel_pth, sel_file));
                obj.region_ok();
                % WLP/WHP: Built From CHS Files | Fixed By A storm + prob_mass .mat
                storm_file = ~isempty(obj.storm_data_input);
                obj.CreateWLPStormDBCheckBox.Enable = matlab.lang.OnOffSwitchState(~storm_file);
                obj.CreateWHPStormDBCheckBox.Enable = matlab.lang.OnOffSwitchState(~storm_file);
                if storm_file
                    obj.CreateWLPStormDBCheckBox.Value = obj.create_wlp;
                    obj.CreateWHPStormDBCheckBox.Value = obj.create_whp;
                else
                    obj.create_wlp = obj.CreateWLPStormDBCheckBox.Value;
                    obj.create_whp = obj.CreateWHPStormDBCheckBox.Value;
                end
                %
                if ~isempty(obj.study)
                    obj.CHSZipFolderEditField.Value = obj.auxLib.relative_path(fullfile(sel_pth, sel_file), pwd);
                    obj.VerticalDatumLabel.Text = [obj.study_datum ' To ' obj.project_datum ' Vertical Offset:'];
                    sp_location = 'n/a';
                    if ~isempty(obj.sp_coords)
                        sp_location = sprintf('%.6f, %.6f', obj.sp_coords);
                    end
                    obj.StudyPreviewTable.Data = [
                        {'CHS Study'; 'Study Vertical Datum'; 'Save Point Lat, Lon [deg]'; 'Incudes Peaks'; 'Includes Timeseries'},...
                        {obj.study; obj.study_datum; sp_location; obj.has_peaks; obj.has_timeseries},...
                        ];
                    obj.CHSZipFolderLamp.Color = [0 1 0];
                    obj.update_buttons();
                else
                    obj.CreateStormDBButton.Enable = 'off';
                    obj.CHSZipFolderEditField.Value = '';
                    obj.ImportButton.Enable = 'off';
                    obj.CHSZipFolderLamp.Color = [1 0 0];
                    obj.StudyPreviewTable.Data = [{},{}];
                end
            else
                obj.CHSZipFolderEditField.Value = '';
                obj.ImportButton.Enable = 'off';
                obj.CreateStormDBButton.Enable = 'off';
                obj.CHSZipFolderLamp.Color = [1 0 0];
                obj.StudyPreviewTable.Data = [{},{}];
            end
        end

        function getChsDependenciesButtonPressed(obj, event)
            obj.reset_db_state();
            % Prompt User To Select Path
            sel_path = uigetdir('', 'Select CHS_Dependencies Folder');
            if any(sel_path~=0)
                msg = obj.set_chs_dependencies(sel_path);
                if ~isempty(msg)
                    obj.auxLib.error_dlgbox(msg);
                end
            end
        end

        function UIWindowCloseRequest(obj, event)
            % Closed Without Import: Staged Files Deleted, An Existing Storm DB Untouched
            obj.clear_staging();
            delete(obj.figUI);
            obj.db_created = false;
        end
    end

    %% PRIVATE METHODS
    methods (Access=private)

        function init_chs_dependencies(obj)
            % Start-Up (No Error Dialog): The Stored CHS_Dependencies Folder Is Applied. A Project With A Region Keeps A Valid
            % Folder (Browse Disabled); Missing Or Invalid, Browse Stays Enabled To Re-Point It
            msg = 'none';
            if ~isempty(obj.source_paths.chs_dependencies_path)
                msg = obj.set_chs_dependencies(obj.source_paths.chs_dependencies_path);
            end
            if isempty(obj.expected_region)
                return
            end
            if isempty(msg)
                obj.chsDependenciesFolderButton.Enable = 'off';
                obj.chsDependenciesFolderButton.Tooltip = 'CHS_Dependencies is fixed for this project. Create a new project to use a different source.';
            else
                obj.CHSStudyDependenciesEditField.Placeholder = sprintf('CHS_Dependencies not found. Select a folder containing region %s.', obj.expected_region);
            end
        end

        function update_name_status(obj, name)
            % Name Lamp + Message (While Typing And On Change), Then Buttons. Red: Invalid (chessProject.db_name_problem).
            % Yellow: Exists (name_clash), Overwrite Confirmed At Import. Green: OK
            name = char(name);
            msg = chessProject.db_name_problem(name);
            state = 'red';
            if isempty(msg)
                state = 'green';
                [exists, in_project] = obj.name_clash(name);
                if exists && in_project
                    state = 'yellow';
                    msg = sprintf('Storm DB "%s" exists: you will be asked to overwrite it at import.', name);
                elseif exists
                    state = 'yellow';
                    msg = sprintf('Storm DB files "%s" exist in Event_Database: you will be asked to overwrite them at import.', name);
                end
            end
            obj.name_state = state;
            switch state
                case 'red'
                    obj.StormDBNameLamp.Color = [1 0 0];
                    obj.StormDBNameMessageLabel.FontColor = [0.75 0.1 0.1];
                case 'yellow'
                    obj.StormDBNameLamp.Color = [1 1 0];
                    obj.StormDBNameMessageLabel.FontColor = [0.6 0.45 0];
                otherwise
                    obj.StormDBNameLamp.Color = [0 1 0];
            end
            obj.StormDBNameMessageLabel.Text = msg;
            obj.update_buttons();
        end

        function update_buttons(obj)
            % Create: Valid Name And CHS Data Selected. Import: Valid Name And A Storm DB Staged (Created)
            name_ok = ~strcmp(obj.name_state, 'red');
            obj.CreateStormDBButton.Enable = name_ok && isequal(obj.CHSZipFolderLamp.Color, [0 1 0]);
            obj.ImportButton.Enable = name_ok && isstruct(obj.output_paths) && isfield(obj.output_paths, 'storm_db')...
                && isfile(obj.output_paths.storm_db);
        end

        function [exists, in_project, existing_name] = name_clash(obj, name)
            % Case-Insensitive Clash With A Project Storm DB (existing_name: Its Stored Name) Or With <name>.mat /
            % <name>_raw_files.mat In Event_Database (Windows File Names Are Case-Insensitive)
            indx = find(strcmpi(name, obj.existing_db_names), 1);
            in_project = ~isempty(indx);
            existing_name = name;
            if in_project
                existing_name = obj.existing_db_names{indx};
            end
            exists = in_project || isfile(fullfile(obj.outpath, [name '.mat'])) || isfile(fullfile(obj.outpath, [name '_raw_files.mat']));
        end

        function stage = staging_dir(obj)
            % Created Storm DB Files Wait Here (staged.mat, staged_raw_files.mat) Until Import (commit_staged)
            stage = fullfile(obj.outpath, '_import_staging');
        end

        function clear_staging(obj)
            % Staging Folder Removed (Wizard Start, Close, Commit); Best Effort
            try
                CHSStormDBImportUI.remove_temp_folder(obj.staging_dir());
            catch
            end
        end

        function commit_staged(obj)
            % Import Commit: Existing <db>.mat / <db>_raw_files.mat Moved Aside (Staging prev*.mat), Staged Files Moved To The
            % Final Names, Then The Old Files Deleted With The Staging Folder. A Failed Move Puts Everything Back (Error
            % Rethrown). A storm .mat Import Stages No _raw_files.mat, So An Old One Is Dropped. A Case-Only Name Change Works
            % Too: The Old File Is Moved Aside First
            stage = obj.staging_dir();
            flds = {'storm_db', 'chs_data'};
            final = {fullfile(obj.outpath, [obj.db_name '.mat']), fullfile(obj.outpath, [obj.db_name '_raw_files.mat'])};
            prev = {fullfile(stage, 'prev.mat'), fullfile(stage, 'prev_raw_files.mat')};
            staged = cellfun(@(f) isfield(obj.output_paths, f) && isfile(obj.output_paths.(f)), flds);
            [aside, placed] = deal(false(1, 2));
            try
                for kk = 1:2
                    if isfile(final{kk})
                        chessProject.move_item(final{kk}, prev{kk});
                        aside(kk) = true;
                    end
                end
                for kk = find(staged)
                    chessProject.move_item(obj.output_paths.(flds{kk}), final{kk});
                    placed(kk) = true;
                end
            catch me
                for kk = find(placed)
                    try
                        chessProject.move_item(final{kk}, obj.output_paths.(flds{kk}));
                    catch
                    end
                end
                for kk = find(aside)
                    try
                        chessProject.move_item(prev{kk}, final{kk});
                    catch
                    end
                end
                rethrow(me);
            end
            for kk = find(staged)
                obj.output_paths.(flds{kk}) = final{kk};
            end
            obj.clear_staging();
        end

        function ok = region_ok(obj)
            % CHS Data Inspected (study Set): A Project With A Region Takes Only That Region (Custom_Modeling Has None). Else
            % Error Dialog And State Reset (study Empty)
            ok = isempty(obj.expected_region) || isempty(obj.study) || any(strcmp(obj.study, {'Custom_Modeling', obj.expected_region}));
            if ~ok
                obj.auxLib.error_dlgbox(sprintf('This project uses region %s; the selected CHS data is %s. Create a new project for another region.',...
                    obj.expected_region, obj.study));
                obj.reset_db_state();
            end
        end

        function chs_zip_inspect(obj, chs_modeling)
            % Get File Extension
            [~, ~, fext] = fileparts(chs_modeling);
            % CHS Zip Folder (.h5 Files) Or CHS_Data .mat (Converted .h5 Files)
            switch fext
                case '.zip'
                    % Storm File Names Read Without Unzipping; Storm File Check By Name (Library)
                    try
                        file_list = chs_storm_file_names(zip_h5_names(chs_modeling));
                    catch me
                        obj.auxLib.error_dlgbox(['Could not read the zip ' chs_modeling ': ' me.message]);
                        reset_db_state(obj);
                        return;
                    end
                    [files_ok, chs_id] = obj.storm_files_ok(file_list);
                    if ~files_ok
                        return;
                    end
                case '.mat'
                    % Library Rule (call_input_parser): "CHS_Data" Or "storm" + "prob_mass", Not Both
                    try
                        vars = who(matfile(chs_modeling));
                    catch me
                        obj.auxLib.error_dlgbox(['Could not read the file ' chs_modeling ': ' me.message]);
                        reset_db_state(obj);
                        return;
                    end
                    has_chs = any(strcmp(vars, 'CHS_Data'));
                    has_storm = any(strcmp(vars, 'storm'));
                    if has_chs && has_storm
                        obj.auxLib.error_dlgbox('Provided .mat file must have "CHS_Data" or "storm" variables (not both).');
                        return;
                    elseif has_storm % Storm Suite Already Matched (No CHS Files To Process)
                        obj.storm_data_inspect(chs_modeling, vars);
                        return;
                    elseif ~has_chs
                        obj.auxLib.error_dlgbox('Provided .mat file must include "CHS_Data" or "storm" + "prob_mass" variables.');
                        return;
                    end
                    try
                        CHS_Data = obj.load_chs_data_mat(chs_modeling);
                    catch me
                        obj.auxLib.error_dlgbox(['Could not read the file ' chs_modeling ': ' me.message]);
                        reset_db_state(obj);
                        return;
                    end
                    file_list = chs_storm_file_names({CHS_Data.Filename}');
                    % Storm File Check By Name (Library)
                    [files_ok, chs_id] = obj.storm_files_ok(file_list);
                    if ~files_ok
                        return;
                    end
                otherwise
                    obj.auxLib.error_dlgbox('Unsupported file type. Provide a CHS modeling .zip folder, a CHS_Data .mat or a storm + prob_mass .mat file.');
                    return;
            end
            if ~isempty(file_list)
                %
                obj.source_paths.chs_zip = chs_modeling;
                %
                % File Names As Stored (.h5 Extension Case Kept: Matched To The Zip Entries By Name)
                [~, h5_base, h5_ext] = fileparts(file_list);
                obj.h5_names = strcat(h5_base, h5_ext);
                % Determine File Types Available
                chs_identifiers = cellfun(@(x) strsplit(x, '_'), h5_base, 'un', false);
                % Grab CHS Study (Library chs_study_identity.m: Region & Save Points From The Storm File Names)
                obj.study = chs_id.region;
                obj.has_peaks = any(contains(obj.h5_names, {'Peaks'}));
                obj.has_timeseries = any(contains(obj.h5_names, {'Timeseries'}));
                % Savepoint Ids (One ADCIRC & One Wave Save Point: Library Storm File Check)
                obj.sp_ids.adcirc = chs_id.sp_ID;
                obj.sp_ids.wave = chs_id.sp_ID_wave;
                % Grab Study Vertical Datum
                ad_file = obj.h5_names(contains(obj.h5_names, 'ADCIRC'));
                try
                    switch fext
                        case '.zip' % Attributes Of The First ADCIRC File (Only That Entry Is Extracted)
                            [obj.study_datum, obj.sp_coords] = CHSStormDBImportUI.zip_h5_attributes(chs_modeling, ad_file{1});
                        case '.mat' % Library: Datum & Savepoint Coordinates From Converted .h5 Attributes
                            [obj.study_datum, obj.sp_coords] = chs_data_attributes(obj.load_chs_data_mat(chs_modeling));
                    end
                catch me
                    obj.auxLib.error_dlgbox(['Could not read the study vertical datum from ' ad_file{1} ': ' me.message]);
                    reset_db_state(obj);
                    return;
                end
                % Define Storm Sampling Based On Storm Types Available
                obj.storm_types = unique(cellfun(@(x) x(2), chs_identifiers, 'un', true));
                % Correct Storm Type Naming
                obj.storm_types = unique(strrep(strrep(obj.storm_types, 'TS', 'TC'), 'XH', 'XC'));
            else
                obj.auxLib.error_dlgbox('Nothing to process: no CHS storm files (Peaks/Timeseries .h5) in the CHS modeling data.');
                reset_db_state(obj);
                return;
            end
        end

        function reset_db_state(obj)
            obj.f_adjusted = false;
            obj.unc_applied =false;
            obj.output_paths = [];
            keep_path = obj.source_paths.chs_dependencies_path;
            obj.source_paths = [];
            obj.source_paths.chs_dependencies_path = keep_path;
            obj.h5_names = [];
            obj.study = [];
            obj.has_peaks = [];
            obj.has_timeseries = [];
            obj.sp_ids = [];
            obj.storm_types = [];
            obj.sp_coords = [];
            obj.modeling_imported = false;
            obj.storm_data_input = [];
            obj.auxLib.dialog_answer = false;
        end

        function ok = set_study_dependencies(obj)
            % Storm Database Bias & Uncertainty And Offshore Elevation From The Library (storm_db_bias_uncertainty.m, No Prompt):
            % Study Grid Point Nearest To The Savepoint (sp_coords; Savepoint ID Without Them), Hm0 Regional Values.
            % Errors (e.g. Savepoint Not In The Study Grid) Shown In The Error Dialog
            ok = false;
            try
                bnu = storm_db_bias_uncertainty(obj.source_paths.chs_dependencies_path, obj.study, obj.sp_ids.adcirc, obj.sp_coords, [], false);
                if isempty(bnu.chs_swl_bu_source) || isempty(bnu.chs_hm0_bu_source)
                    error('the CHS_Dependencies folder has no %s bias & uncertainty files', obj.study);
                end
            catch me
                obj.auxLib.error_dlgbox(['Could not load ' obj.study ' bias & uncertainty for SP' num2str(obj.sp_ids.adcirc) ' from CHS_Dependencies: ' me.message]);
                return;
            end
            obj.db_info = bnu;
            % TC SWL Bias Correction Files (Library call_chs_storm_quality_check Applies It When Both Exist)
            BnU_dir = dir(fullfile(obj.source_paths.chs_dependencies_path, 'Bias_and_Uncertainty', obj.study, '*.mat'));
            circ = find(contains({BnU_dir.name}, {'Comb','WL'}), 1);
            wave = find(contains({BnU_dir.name}, {'STWAVE','SWAN'}), 1);
            obj.source_paths.BnU_circulation = fullfile(BnU_dir(circ).folder, BnU_dir(circ).name);
            obj.source_paths.BnU_waves = fullfile(BnU_dir(wave).folder, BnU_dir(wave).name);
            ok = true;
        end

        function create_dir(obj, path_to_check)
            if ~exist(path_to_check, 'dir')
                mkdir(path_to_check);
            end
        end

        function [storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass, tc_bias_corrected] = call_chs_storm_quality_check(obj, step_start, CHS_Data, prob_mass, storm_type)
            % Storm QA/QC & Matching Through The Library (Progress Printed To Command Window)
            [obj.dlgObj] = obj.auxLib.progress_window(step_start/9, ['Matching ' storm_type ' modeling results (surge+waves)'],...
                'Storm Database Creation Progress', obj.dlgObj, false);
            % Library Config For The Quality Check (storm_duration In Hours)
            config = struct('use_peaks', +obj.has_peaks, 'use_timeseries', +obj.has_timeseries,...
                'create_wlp', +obj.create_wlp, 'create_whp', +obj.create_whp,...
                'region', obj.study, 'sp_ID', obj.sp_ids.adcirc,...
                'storm_duration', obj.storm_duration, 'print_progress', true);
            % TC SWL Bias Correction: The Library Decides (Applied When Both Bias Files Exist), With The Database Bias
            config.in_files = struct('BnU_circulation', obj.source_paths.BnU_circulation, 'BnU_waves', obj.source_paths.BnU_waves);
            config.chs_swl_b_a = obj.get_model_bias('swl', 'absolute');
            config.chs_swl_b_r = obj.get_model_bias('swl', 'relative');
            [config, storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass] = call_chs_storm_quality_check(config, CHS_Data, prob_mass, storm_type);
            % TC Bias Correction State (db_info; Plots Apply The Same Correction To Raw CHS SWL)
            tc_bias_corrected = 0;
            if strcmp(storm_type, 'TC')
                tc_bias_corrected = config.tc_bias_corrected;
            end
        end

        function import_progress(obj, percent, msg)
            % CHS Modeling Import Progress (Wizard Dialog); A Cancel (Seen Here, Between Steps) Stops The Import
            obj.dlgObj = obj.auxLib.progress_window(percent, msg, 'CHS Modeling Import', obj.dlgObj, true);
            if obj.auxLib.dialog_answer
                error('CHESS:importCancelled', 'Import cancelled.');
            end
        end

        function close_progress(obj)
            if ~isempty(obj.dlgObj) && isvalid(obj.dlgObj)
                close(obj.dlgObj);
            end
        end

        function [ok, chs_id] = storm_files_ok(obj, file_names)
            % Storm File Slots (Library chs_storm_file_slots): One ADCIRC + One Wave File Per Storm Type & Data Type. The
            % Request Is The Import (Every Storm Type & Data Type In The Input); WLP/WHP Are Decided At Database Creation
            [slots, errs, chs_id] = chs_storm_file_slots(file_names);
            present = cellfun(@numel, slots.water_level) + cellfun(@numel, slots.wave) > 0;
            if isempty(errs) && any(present)
                types = unique(slots.storm_type(present));
                if numel(types) > 1
                    sampling = 'CC';
                else
                    sampling = types{1};
                end
                request = struct('storm_sampling', sampling, 'use_peaks', +any(present & strcmp(slots.data_type, 'Peaks')),...
                    'use_timeseries', +any(present & strcmp(slots.data_type, 'Timeseries')), 'create_wlp', 0, 'create_whp', 0);
                [~, errs] = chs_storm_file_slots(file_names, request);
            end
            ok = isempty(errs);
            if ~ok
                obj.auxLib.error_dlgbox(['Imported CHS modeling data does not meet the storm file requirements: ' strjoin(errs, '; ') '.']);
                obj.reset_db_state();
            end
        end
    end

    %% PUBLIC METHODS
    methods (Access=public)
        function msg = set_chs_dependencies(obj, chs_dir)
            % CHS_Dependencies Folder Of The Import (Browse And Start-Up): Layout Check, Plus The Project Region's Files When
            % expected_region Is Set (chessProject.chs_dependencies_problem). Sets The Path, Lamp, CHS File Button And Field
            % (Full Path). msg: '' If Valid, Else The Reason (Path Cleared)
            msg = chessProject.chs_dependencies_problem(chs_dir, obj.expected_region);
            if isempty(msg)
                obj.source_paths.chs_dependencies_path = chs_dir;
                obj.studyDependenciesLamp.Color = [0 1 0];
                obj.chsZipFolderButton.Enable = 'on';
                obj.CHSStudyDependenciesEditField.Value = chs_dir;
            else
                obj.source_paths.chs_dependencies_path = [];
                obj.studyDependenciesLamp.Color = [1 0 0];
                obj.chsZipFolderButton.Enable = 'off';
                obj.CHSStudyDependenciesEditField.Value = '';
            end
        end

        % Adjust Modeling Datum
        function storm = study_datum_adjustment(obj, storm, datum_offset)
            %
            stm_types = fieldnames(storm);
            data_types = fieldnames(storm.(stm_types{1}));
            data_types = data_types(contains(data_types, {'Peaks','Timeseries'}));
            % Loop For Each Dataset
            for ii = 1:length(stm_types) % XC, TC
                for jj = 1:length(data_types) % Peaks, Timeseries
                    match_types = fieldnames(storm.(stm_types{ii}).(data_types{jj}));
                    for kk = 1:length(match_types) % Default, WLP, WHP
                        a = stm_types{ii};b = data_types{jj};c = match_types{kk};
                        stm_mat = storm.(a).(b).(c);
                        for gg = 1:length(stm_mat)
                            % First Col Is Expected To Be The Surge/Water Level
                            storm.(a).(b).(c){gg, 2}(:, 1) = storm.(a).(b).(c){gg, 2}(:, 1)+datum_offset;
                        end
                    end
                end
            end
        end

        % Import CHS Modeling Data
        function import_chs_modeling(obj, chs_modeling)
            % storm & prob_mass .mat Already Inspected (Details Given Through Dialog): Do Not Inspect Again
            if ~obj.is_storm_data_input(chs_modeling)
                obj.reset_db_state();
                obj.chs_zip_inspect(chs_modeling);
                obj.region_ok();
                if isempty(obj.study)
                    return;
                end
            end
            % storm & prob_mass .mat: Nothing To Convert
            if ~isempty(obj.storm_data_input)
                obj.import_storm_data();
                return;
            end
            % Get File Extension
            [~, ~, fext] = fileparts(chs_modeling);
            obj.dlgObj = []; % .zip: Progress Dialog In The Wizard (Unzip, H5 Conversion, Raw Files Write); Cancel Between Files
            % Convert CHS Data
            switch fext
                case '.zip' % Library H5 Conversion (Progress Also Printed To Command Window)
                    % Unzipped Into A System Temp Folder Removed On Every Exit (Success, Converter Error, Cancel)
                    temp_path = tempname;
                    temp_cleanup = onCleanup(@() CHSStormDBImportUI.remove_temp_folder(temp_path));
                    try
                        obj.import_progress(NaN, 'Unzipping CHS modeling files...');
                        unzip(chs_modeling, temp_path);
                        % .h5 Extension In Any Case (dir '*.h5' Is Case-Sensitive Off Windows)
                        h5_dir = dir(fullfile(temp_path, '**', '*'));
                        h5_dir = h5_dir(~[h5_dir.isdir]' & endsWith({h5_dir.name}', '.h5', 'IgnoreCase', true));
                        [~, h5_loc] = ismember(lower(obj.h5_names), lower({h5_dir.name}'));
                        if any(h5_loc == 0)
                            error('%s not found in the unzipped folder', strjoin(obj.h5_names(h5_loc == 0), ', '));
                        end
                        % Bar Shows Files Done ((jj - 1)/n): jj/n Would Close The Dialog Before The Last File
                        CHS_Data = call_chs_h5_converter(fullfile({h5_dir(h5_loc).folder}', {h5_dir(h5_loc).name}'), true,...
                            @(jj, n, file_name) obj.import_progress((jj - 1)/n, sprintf('Converting CHS .h5 files (%d of %d): %s', jj, n, file_name)));
                        obj.import_progress(NaN, ['Writing ' obj.db_name '_raw_files.mat...']);
                    catch me
                        obj.close_progress();
                        if strcmp(me.identifier, 'CHESS:importCancelled')
                            obj.auxLib.error_dlgbox('Import cancelled.');
                        else
                            obj.auxLib.error_dlgbox(['Could not convert the CHS modeling files of ' chs_modeling ': ' me.message]);
                        end
                        return;
                    end
                    clear temp_cleanup;
                case '.mat' % Already Converted (Loaded During Inspection)
                    CHS_Data = obj.load_chs_data_mat(chs_modeling);
                    obj.chs_data_cache = [];
            end
            % Keep File Names Only (Drop Temp/Source Folders)
            [~, fnames, fexts] = cellfun(@fileparts, {CHS_Data.Filename}, 'un', false);
            fnames = strcat(fnames, fexts);
            [CHS_Data.Filename] = fnames{:};
            % Write Out File And Store Pointer
            % Staged Until Import (commit_staged Gives It The Name <db>_raw_files.mat)
            disp(['Writing CHS_Data to ' obj.db_name, '_raw_files.mat....']);
            obj.create_dir(obj.staging_dir());
            obj.output_paths.chs_data = fullfile(obj.staging_dir(), 'staged_raw_files.mat');
            save(obj.output_paths.chs_data, 'CHS_Data','-v7.3');
            obj.close_progress();
            obj.modeling_imported = obj.set_study_dependencies();
        end

        % Load CHS_Data .mat Once (Shared By Inspection & Import)
        function CHS_Data = load_chs_data_mat(obj, chs_modeling)
            % Absolute Path (Inspection & Import May Pass Full Or Relative Paths)
            finfo = dir(chs_modeling);
            chs_modeling = fullfile(finfo.folder, finfo.name);
            if isempty(obj.chs_data_cache) || ~strcmp(obj.chs_data_cache.src, chs_modeling)
                data = load(chs_modeling, 'CHS_Data');
                obj.chs_data_cache = struct('src', chs_modeling, 'CHS_Data', data.CHS_Data);
            end
            CHS_Data = obj.chs_data_cache.CHS_Data;
        end

        % storm & prob_mass .mat: Validate With Library & Ask User For Study Details
        function storm_data_inspect(obj, chs_modeling, vars)
            if ~any(strcmp(vars, 'prob_mass'))
                obj.auxLib.error_dlgbox('Provided storm .mat file must include both "storm" and "prob_mass" variables.');
                return;
            end
            try
                data = load(chs_modeling, 'storm', 'prob_mass');
            catch me
                obj.auxLib.error_dlgbox(['Could not read the file ' chs_modeling ': ' me.message]);
                reset_db_state(obj);
                return;
            end
            % Library Validation (Same As call_input_parser For storm Data)
            try
                st_types = intersect({'TC','XC'}, fieldnames(data.storm), 'stable');
                has_dtype = @(dtype) ~isempty(st_types) && all(cellfun(@(x) isfield(data.storm.(x), dtype), st_types));
                use = struct('use_peaks', +has_dtype('Peaks'), 'use_timeseries', +has_dtype('Timeseries'));
                storm_validation(use, data.storm);
                if isfield(data.storm, 'TC')
                    prob_mass_validation(use, data.prob_mass, data.storm);
                end
            catch me
                obj.auxLib.error_dlgbox(me.message);
                return;
            end
            % Region & Savepoint Defaults From File Name (Library Naming Rule)
            [~, fname] = fileparts(chs_modeling);
            tokens = strsplit(fname, '_');
            region = tokens(startsWith(tokens, 'CHS-'));
            sp_id = tokens(~cellfun(@isempty, regexp(tokens, '^SP\d+$', 'once')));
            if isempty(region), region = 'Custom_Modeling'; else, region = region{1}; end
            if isempty(sp_id), sp_id = []; else, sp_id = str2double(strrep(sp_id{1}, 'SP', '')); end
            % User Provides Region, Savepoint (And Uncertainties For Custom Modeling); Offshore Elevation: Study Grid (By
            % Savepoint ID: No Coordinates In A storm .mat), Else The Run Tab Inputs Table
            details = obj.storm_data_dialog(region, sp_id);
            if isempty(details)
                return;
            end
            % Alternate Peaks Datasets Present In File
            create_wlp = false; create_whp = false;
            if use.use_peaks
                match_types = fieldnames(data.storm.(st_types{1}).Peaks);
                create_wlp = any(strcmp(match_types, 'WLP'));
                create_whp = any(strcmp(match_types, 'WHP'));
            end
            finfo = dir(chs_modeling);
            obj.storm_data_input = struct('src', fullfile(finfo.folder, finfo.name), 'storm', data.storm, 'prob_mass', data.prob_mass,...
                'create_wlp', create_wlp, 'create_whp', create_whp, 'BnU', details.BnU);
            obj.create_wlp = create_wlp;
            obj.create_whp = create_whp;
            obj.source_paths.chs_zip = chs_modeling;
            obj.storm_types = st_types;
            obj.has_peaks = logical(use.use_peaks);
            obj.has_timeseries = logical(use.use_timeseries);
            obj.sp_ids = struct('adcirc', details.sp_id, 'wave', []);
            obj.sp_coords = [];
            obj.study_datum = 'Unknown';
            obj.study = details.region; % Set Last: Non-Empty Study Flags A Successful Inspection
        end

        % storm & prob_mass .mat: Region, Savepoint ID (+ Custom Modeling Uncertainties)
        function details = storm_data_dialog(obj, region, sp_id)
            details = [];
            % CHS Regions Available In CHS_Dependencies + Custom Modeling
            regions = {};
            grid_dir = dir(fullfile(obj.source_paths.chs_dependencies_path, 'Grid_Files'));
            if ~isempty(grid_dir)
                regions = {grid_dir([grid_dir.isdir] & ~startsWith({grid_dir.name}, '.')).name};
            end
            regions = [regions(:)', {'Custom_Modeling'}];
            if ~any(strcmp(regions, region))
                region = 'Custom_Modeling';
            end
            % Dialog Window
            fig = uifigure('Name', 'Storm Database Details', 'WindowStyle', 'modal', 'Position', [100 100 440 330]);
            obj.auxLib.center_on_parent(fig);
            gl = uigridlayout(fig, [9 2]);
            gl.ColumnWidth = {'1x', 160};
            gl.RowHeight = [repmat({22}, 1, 8), {'1x'}];
            info = uilabel(gl, 'Text', 'Study details not stored in the storm .mat file:', 'FontWeight', 'bold');
            info.Layout.Row = 1; info.Layout.Column = [1 2];
            add_label(2, 'Region:');
            region_dd = uidropdown(gl, 'Items', regions, 'Value', region);
            region_dd.Layout.Row = 2; region_dd.Layout.Column = 2;
            add_label(3, 'Savepoint ID:');
            sp_ef = add_field(3, num2str(sp_id));
            unc_lbl = uilabel(gl, 'Text', 'Modeling uncertainty (Custom_Modeling only):', 'FontWeight', 'bold');
            unc_lbl.Layout.Row = 4; unc_lbl.Layout.Column = [1 2];
            unc_text = {'SWL Absolute Uncertainty (Ua) [m]:', 'SWL Relative Uncertainty (Ur) [-]:',...
                'Hm0 Absolute Uncertainty (Ua) [m]:', 'Hm0 Relative Uncertainty (Ur) [-]:'};
            unc_ef = gobjects(1, 4);
            for uu = 1:4
                add_label(4+uu, unc_text{uu});
                unc_ef(uu) = add_field(4+uu, '');
            end
            btn_gl = uigridlayout(gl, [1 3], 'Padding', [0 0 0 0]);
            btn_gl.Layout.Row = 9; btn_gl.Layout.Column = [1 2];
            btn_gl.ColumnWidth = {'1x', 90, 90};
            btn_gl.RowHeight = {'fit'};
            cancel_btn = uibutton(btn_gl, 'Text', 'Cancel', 'ButtonPushedFcn', @(~, ~) uiresume(fig));
            cancel_btn.Layout.Column = 2;
            ok_btn = uibutton(btn_gl, 'Text', 'OK', 'ButtonPushedFcn', @(~, ~) ok_pressed());
            ok_btn.Layout.Column = 3;
            region_dd.ValueChangedFcn = @(~, ~) toggle_uncertainty();
            fig.CloseRequestFcn = @(~, ~) uiresume(fig);
            obj.auxLib.add_dialog_keys(fig, @() ok_pressed(), @() uiresume(fig), ok_btn);
            toggle_uncertainty();
            % Wait For User (OK Stores The Details In fig.UserData)
            uiwait(fig);
            if isvalid(fig)
                details = fig.UserData;
                delete(fig);
            end

            function add_label(row, txt)
                lbl = uilabel(gl, 'Text', txt);
                lbl.Layout.Row = row; lbl.Layout.Column = 1;
            end

            function ef = add_field(row, val)
                ef = uieditfield(gl, 'text', 'Value', val);
                ef.Layout.Row = row; ef.Layout.Column = 2;
            end

            function toggle_uncertainty()
                set(unc_ef, 'Enable', matlab.lang.OnOffSwitchState(strcmp(region_dd.Value, 'Custom_Modeling')));
            end

            function ok_pressed()
                is_custom = strcmp(region_dd.Value, 'Custom_Modeling');
                sp_val = str2double(sp_ef.Value);
                unc_val = str2double({unc_ef.Value});
                % Validate Inputs
                if is_custom && isempty(strtrim(sp_ef.Value))
                    sp_val = 1; % Library Default For Custom Modeling
                end
                if ~isfinite(sp_val) || sp_val <= 0 || sp_val ~= round(sp_val)
                    uialert(fig, 'Savepoint ID must be a positive integer.', 'Invalid Input');
                    return;
                end
                if is_custom && (any(~isfinite(unc_val)) || any(unc_val < 0))
                    uialert(fig, 'Custom modeling requires SWL & Hm0 uncertainties (Ua, Ur) as non-negative numbers.', 'Invalid Input');
                    return;
                end
                % Custom Modeling: User Uncertainties, No Model Bias, No Study Grid (db_info Field Names: storm_db_info.m)
                BnU = [];
                if is_custom
                    BnU = struct('chs_swl_b_a', 0, 'chs_swl_b_r', 0, 'chs_swl_u_a', unc_val(1), 'chs_swl_u_r', unc_val(2),...
                        'chs_swl_bu_source', 'provided', 'chs_hm0_b_a', 0, 'chs_hm0_b_r', 0, 'chs_hm0_u_a', unc_val(3),...
                        'chs_hm0_u_r', unc_val(4), 'chs_hm0_bu_source', 'provided', 'offshore_elevation', [],...
                        'offshore_elevation_source', '', 'grid_distance_m', [], 'sp_lat', [], 'sp_lon', []);
                end
                fig.UserData = struct('region', region_dd.Value, 'sp_id', sp_val, 'BnU', BnU);
                uiresume(fig);
            end
        end

        % True If chs_modeling Is The storm & prob_mass .mat Already Inspected
        function tf = is_storm_data_input(obj, chs_modeling)
            tf = false;
            if isempty(obj.storm_data_input) || ~isfile(chs_modeling)
                return;
            end
            finfo = dir(chs_modeling);
            tf = strcmp(fullfile(finfo.folder, finfo.name), obj.storm_data_input.src);
        end

        % storm & prob_mass .mat Import: Bias & Uncertainty Only (Storm Suite And db_info Are Saved At Database Creation)
        function import_storm_data(obj)
            obj.output_paths = struct();
            if strcmp(obj.study, 'Custom_Modeling') % User Provided Uncertainties
                obj.db_info = obj.storm_data_input.BnU;
            elseif ~obj.set_study_dependencies() % CHS Study: CHS_Dependencies
                return;
            end
            obj.modeling_imported = true;
        end

        % Create storm & prob_mass
        function [storm, prob_mass] = create_storm_database(obj, create_wlp, create_whp, storm_duration, study_datum_offset)
            obj.dlgObj = [];
            obj.auxLib.dialog_answer = false;
            obj.storm_duration = storm_duration;
            obj.create_wlp = create_wlp;
            obj.create_whp = create_whp;
            fields_to_del = fieldnames(obj.output_paths);
            obj.output_paths = rmfield(obj.output_paths, fields_to_del(~strcmp(fields_to_del, {'chs_data'})));
            % storm & prob_mass .mat: Storm Suite Provided (Only The Datum Offset Is Applied)
            if obj.modeling_imported && ~isempty(obj.storm_data_input)
                obj.create_wlp = obj.storm_data_input.create_wlp; % Alternate Datasets Come From The File
                obj.create_whp = obj.storm_data_input.create_whp;
                storm = obj.study_datum_adjustment(obj.storm_data_input.storm, study_datum_offset);
                prob_mass = obj.storm_data_input.prob_mass;
                % XC Record Moves From storm.XC To db_info; Storm Suite Already Processed: No TC Bias Correction
                [Nyrs_XC, Nstm_XC] = deal([]);
                if isfield(storm, 'XC')
                    Nyrs_XC = storm.XC.Nyrs_XC;
                    Nstm_XC = storm.XC.Nstm_XC;
                    storm.XC = rmfield(storm.XC, {'Nyrs_XC', 'Nstm_XC'});
                end
                [~, src_name, src_ext] = fileparts(obj.storm_data_input.src);
                obj.db_info = storm_db_info('create', obj.db_info, 0, Nyrs_XC, Nstm_XC, [src_name src_ext]);
                db_info = obj.db_info; %#ok<PROPLC> Saved By Name
                % Staged Until Import (commit_staged Gives It The Name <db>.mat)
                obj.create_dir(obj.staging_dir());
                obj.output_paths.storm_db = fullfile(obj.staging_dir(), 'staged.mat');
                save(obj.output_paths.storm_db, 'storm', 'prob_mass', 'db_info');
                return;
            end
            %
            if ~obj.modeling_imported
                storm = [];prob_mass = [];
                obj.auxLib.error_dlgbox('CHS modeling data needs to be imported before database creation. Please use import_chs_modeling() method.');
                return;
            else
                % load CHS_Data
                load(obj.output_paths.chs_data, 'CHS_Data');
                % Define Storm Sampling Allowed
                if length(obj.storm_types)>1
                    storm_sampling = 'CC';
                else
                    storm_sampling = obj.storm_types{:};
                end
                % Ensure Dependencies Are Met For Alternate Datasets
                if ~obj.has_peaks || ~obj.has_timeseries
                    obj.create_wlp = false;
                    obj.create_whp = false;
                end
                % Storm File Slots (Library chs_storm_file_slots): Every Storm Type & Data Type Imported, WLP/WHP As Selected
                [~, slot_errors] = chs_storm_file_slots(obj.h5_names, struct('storm_sampling', storm_sampling,...
                    'use_peaks', +obj.has_peaks, 'use_timeseries', +obj.has_timeseries,...
                    'create_wlp', +obj.create_wlp, 'create_whp', +obj.create_whp));
                if isempty(slot_errors)
                    % No Probability Masses Unless TCs Are Present (XC Only)
                    prob_mass = [];
                    [tc_bias_corrected, Nyrs_XC, Nstm_XC] = deal(0, [], []);
                    % Process Tropical Cyclones
                    if contains(storm_sampling, {'TC','CC'})
                        %
                        [obj.dlgObj] = obj.auxLib.progress_window(1/9, 'Setting-up TC modeling suite regional statistics',...
                            'Storm Database Creation Progress', obj.dlgObj, false);
                        % Load DSW's & SRRs
                        [prob_mass.Param, prob_mass.TC_SRR,...
                            prob_mass.TC_Freq, prob_mass.TotalFreq,...
                            prob_mass.smpl1, prob_mass.smpl2, prob_mass.smpl3] = chs_probability_mass_loader(obj.source_paths.chs_dependencies_path,...
                            obj.study, obj.sp_ids.adcirc);
                        % Match ADCIRC & Wave Modeling Datasets
                        [storm.('TC'), storm.('TC').removed_storms,...
                            ~, ~, prob_mass, tc_bias_corrected] = obj.call_chs_storm_quality_check(2, CHS_Data, prob_mass, 'TC');
                    end
                    % Process Extra-tropical Storms
                    if contains(storm_sampling, {'XC','CC'})
                        [storm.('XC'), storm.('XC').removed_storms,...
                            Nyrs_XC, Nstm_XC, ~] = obj.call_chs_storm_quality_check(4, CHS_Data, [], 'XC');
                    end
                    % Replace Hydrograph Peaks
                    if obj.has_timeseries && obj.has_peaks
                        [obj.dlgObj] = obj.auxLib.progress_window(7/9, 'Adjusting hydrographs peak responses',...
                            'Storm Database Creation Progress', obj.dlgObj, false);
                        [storm, ~] = chs_timeseries_peak_replacer(storm);
                    end
                    % Save Out And Store Pointer
                    [obj.dlgObj] = obj.auxLib.progress_window(8.9/9, ['Writting storm & prob_mass to ' obj.db_name '.mat'],...
                        'Storm Database Creation Progress', obj.dlgObj, false);
                    obj.create_dir(obj.staging_dir());
                    storm = obj.study_datum_adjustment(storm, study_datum_offset);
                    % Storm Database Details (Library storm_db_info.m): Bias & Uncertainty Set At Import, TC Bias Correction, XC Record
                    [~, src_name, src_ext] = fileparts(obj.source_paths.chs_zip);
                    obj.db_info = storm_db_info('create', obj.db_info, tc_bias_corrected, Nyrs_XC, Nstm_XC, [src_name src_ext]);
                    db_info = obj.db_info; %#ok<PROPLC> Saved By Name
                    % Staged Until Import (commit_staged Gives It The Name <db>.mat)
                    obj.output_paths.storm_db = fullfile(obj.staging_dir(), 'staged.mat');
                    save(obj.output_paths.storm_db, 'storm', 'prob_mass', 'db_info');
                    [obj.dlgObj] = obj.auxLib.progress_window(9/9, 'Complete',...
                        'Storm Database Creation Progress', obj.dlgObj);
                else
                    obj.auxLib.error_dlgbox(['Imported CHS modeling data does not meet the storm file requirements: ' strjoin(slot_errors, '; ') '.']);
                    storm = [];
                    prob_mass = [];
                    return;
                end
            end
        end

        function info = get_db_info(obj)
            % Storm Database Details (Library storm_db_info.m). Databases Imported Before db_info Existed Have None
            if ~storm_db_info('valid', obj.db_info)
                error('Storm database "%s" has no db_info (imported with an older CHESS version): rebuild the storm database (import it again).', obj.db_name);
            end
            info = obj.db_info;
        end

        function sp_id = get_savepoint_id(obj)
            % CHS ADCIRC Savepoint ID Of This Storm Database ([] If Unknown)
            sp_id = [];
            if isstruct(obj.sp_ids) && isfield(obj.sp_ids, 'adcirc')
                sp_id = obj.sp_ids.adcirc;
            end
        end

        function out = get_model_uncertainty(obj, field, component)
            arguments
                obj
                field {mustBeMember(field, {'swl','hm0'})}
                component {mustBeMember(component, {'relative','absolute','combined'})}
            end
            switch component
                case 'relative'
                    out = obj.db_info.(['chs_' field '_u_r']);
                case 'absolute'
                    out = obj.db_info.(['chs_' field '_u_a']);
                case 'combined'
                    out = [[{'Ua'};{'Ur'}],[{obj.db_info.(['chs_' field '_u_a'])};{obj.db_info.(['chs_' field '_u_r'])}]];
            end
        end

        function out = get_model_bias(obj, field, component)
            arguments
                obj
                field {mustBeMember(field, {'swl','hm0'})}
                component {mustBeMember(component, {'relative','absolute','combined'})}
            end
            switch component
                case 'relative'
                    out = obj.db_info.(['chs_' field '_b_r']);
                case 'absolute'
                    out = obj.db_info.(['chs_' field '_b_a']);
                case 'combined'
                    out = [[{'Ba'};{'Br'}],[{obj.db_info.(['chs_' field '_b_a'])};{obj.db_info.(['chs_' field '_b_r'])}]];
            end
        end
    end

    %% STATIC PRIVATE METHODS
    methods (Static, Access=private)
        % Study Vertical Datum & Save Point [Latitude Longitude] (Root Attributes, Text Or Numeric; [] If Missing) Of One .h5
        % Entry Of A CHS Zip Folder: Only That Entry Is Extracted, Into A System Temp Folder Removed On Return (Errors Included)
        function [study_datum, sp_coords] = zip_h5_attributes(chs_zip, h5_file)
            temp_path = tempname;
            temp_cleanup = onCleanup(@() CHSStormDBImportUI.remove_temp_folder(temp_path));
            h5_path = zip_extract_entry(chs_zip, h5_file, temp_path);
            study_datum = h5readatt(h5_path, '/', 'Vertical Datum');
            try
                sp_coords = [CHSStormDBImportUI.attr_to_double(h5readatt(h5_path, '/', 'Save Point Latitude')),...
                    CHSStormDBImportUI.attr_to_double(h5readatt(h5_path, '/', 'Save Point Longitude'))];
            catch
                % Could Not Find The Save Point Coordinates
                sp_coords = [];
            end
            if any(isnan(sp_coords))
                sp_coords = [];
            end
        end

        % HDF5 Attribute Value (Text Or Numeric) To Double
        function val = attr_to_double(val)
            if iscell(val)
                val = val{1};
            end
            if ischar(val) || isstring(val)
                val = str2double(val);
            end
            val = double(val(1));
        end

        % Remove A Temp Folder (If Created)
        function remove_temp_folder(temp_path)
            if isfolder(temp_path)
                rmdir(temp_path, 's');
            end
        end

        % Arrow Pointer On Exit (Errors Included; The Window May Already Be Closed)
        function restore_pointer(fig)
            if isvalid(fig)
                fig.Pointer = 'arrow';
            end
        end
    end

end
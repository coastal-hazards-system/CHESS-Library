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
        db_created logical = false % Import To Project Pressed And Done: The Storm DB Is In The Project (record)
        db_name char
        create_wlp logical = false
        create_whp logical = false
        record % Storm DB Record Added To The Project (chess.Project.add_built_storm_database)
        replaced % Record Of The Project Storm DB It Replaced ([]: None)
        not_deleted cell = {} % Run Files Of The Replaced Storm DB That Could Not Be Deleted
    end

    properties (Access=private)
        auxLib
        dlgObj
        project % chess.Project The Storm DB Is Imported Into. Every Step Is A Library Call: inspect_storm_data,
                % build_storm_database, add_built_storm_database (The Same Steps As chess.Project.import_storm_database)
        chs_dependencies char % CHS_Dependencies Folder Of The Import (The Project's; Browsed When The Project Has No Usable One)
        database % chess.CoastalHazardSystem Of The Selected Storm Data (chess.Project.inspect_storm_data; []: None Selected)
        contents % What The Storm Data Holds (chess.CoastalHazardSystem.source_contents)
        built logical = false % Storm DB Built In The Project's Holding Folder (Create Storm DB), Not Yet In The Project
        name_state % Storm DB Name Status: 'red' (Invalid) | 'green' | 'yellow' (Exists: Overwrite Confirmed At Import)
        parent_fig % Window The Wizard Opens Centered On ([]: Screen)
    end

    %% CONSTRUCTOR
    % App creation and deletion
    methods (Access = public)
        % Construct app
        function obj = CHSStormDBImportUI(project, parent_fig)
            % project: chess.Project The Storm DB Goes Into (Its CHS_Dependencies, Region, Datum And Storm DB Names)
            % parent_fig: Optional Window The Wizard Opens Centered On ([]: Screen)
            if nargin < 2
                parent_fig = [];
            end
            obj.project = project;
            obj.parent_fig = parent_fig;
            obj.chs_dependencies = project.chs_dependencies;
            obj.auxLib = auxUIFunctions();
        end
    end

    %% UI METHODS
    % Component initialization
    methods (Access = public)
        % Create uifig and components
        function create_ui(obj)
            obj.reset_db_state();
            obj.project.discard_built_storm_database(); % Left By A Session That Ended Without Closing The Wizard
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
           obj.CreateWHPStormDBCheckBox.Tooltip = 'Requires Peaks and Timeseries files';

            % Create CreateWLPStormDBCheckBox
           obj.CreateWLPStormDBCheckBox = uicheckbox(obj.GridLayout2_3);
           obj.CreateWLPStormDBCheckBox.Text = 'Create WLP Storm DB';
           obj.CreateWLPStormDBCheckBox.Layout.Row = 1;
           obj.CreateWLPStormDBCheckBox.Layout.Column = 3;
           obj.CreateWLPStormDBCheckBox.Tooltip = 'Requires Peaks and Timeseries files';

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
           obj.VerticalDatumLabel.Text = 'MSL To NAVD88 Vertical Offset:';

            % Create VerticalOffsetEditField
           obj.VerticalOffsetEditField = uieditfield(obj.GridLayout2_5, 'numeric');
           obj.VerticalOffsetEditField.HorizontalAlignment = 'center';
           obj.VerticalOffsetEditField.Layout.Row = 1;
           obj.VerticalOffsetEditField.Layout.Column = 2;
            % Datum Offset Disabled (Value 0): No Storm DB Gets An SWL Shift Until The Project Datum Is Supported
           obj.VerticalOffsetEditField.Value = 0;
           obj.VerticalOffsetEditField.Enable = 'off';
           obj.VerticalOffsetEditField.Tooltip = 'Not available yet: requires a project datum';

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
            % Commit Point: An Existing Storm DB Of That Name (Project Or Event_Database Files, chess.Project.storm_database_clash)
            % Is Replaced Once Confirmed (Cancel: Back To The Wizard, The Built Storm DB Kept). Then The Built Storm DB Goes
            % Into The Project (chess.Project.add_built_storm_database: Files Renamed, Old Runs Deleted, Record Added)
            [in_project, on_disk, existing_name] = obj.project.storm_database_clash(obj.db_name);
            if in_project
                msg = sprintf('Storm DB "%s" already exists. Overwrite?', existing_name);
                n_alternatives = obj.project.storm_database_usage(existing_name);
                n_run_files = numel(obj.project.storm_database_run_files(existing_name));
                if n_alternatives > 0 || n_run_files > 0
                    msg = sprintf(['%s\n%d alternative(s) have simulations with it. Its %d run file(s) will be deleted and ',...
                        'those simulations removed.'], msg, n_alternatives, n_run_files);
                end
            elseif on_disk
                msg = sprintf(['Storm DB "%s" already exists. Overwrite?\nIts files in Event_Database are not part of ',...
                    'the project; they will be replaced.'], obj.db_name);
            end
            if in_project || on_disk
                obj.auxLib.confirmation_dlgbox(msg, 'Overwrite');
                if ~obj.auxLib.dialog_answer
                    return
                end
            end
            try
                [obj.record, obj.replaced, obj.not_deleted] = obj.project.add_built_storm_database(obj.db_name, obj.database,...
                    in_project || on_disk);
            catch me
                obj.auxLib.error_dlgbox(['Could not import storm DB "' obj.db_name '": ' me.message]);
                return
            end
            % Bring project over to parent gui and close ui
            delete(obj.figUI);
            obj.db_created = true;
        end

        function createStormDbButtonPressed(obj, event)
            % Storm DB Built In The Project's Holding Folder (chess.Project.build_storm_database), Then Shown In The Preview
            obj.built = obj.create_storm_database();
            if obj.built
                saved = load(obj.database.database_file, 'storm');
                storm = saved.storm;
                obj.PlotControlsPanel.Enable = 'on';
                stm_types = intersect(fieldnames(storm), {'XC', 'TC'}, 'stable');
                data_types = intersect(fieldnames(storm.(stm_types{1})), {'Peaks', 'Timeseries'}, 'stable');
                match_types = fieldnames(storm.(stm_types{1}).(data_types{1}));
                obj.FieldtoPlotDropDown.Items = {'Water Level', 'Wave Height (Hm0)', 'Peak Period'};
                obj.FieldtoPlotDropDown.ItemsData = [1,2,3]; % Col Index To Pull From Storm
                obj.MatchTypeDropDown.Items = match_types;
                obj.DataTypeDropDown.Items = data_types;
                obj.StormTypeDropDown.Items = stm_types;
                obj.StormIDDropDown.Items = cellfun(@num2str, storm.(obj.StormTypeDropDown.Value).(obj.DataTypeDropDown.Value).(obj.MatchTypeDropDown.Value)(:,1), 'UniformOutput', false);
                obj.dataTypeDropdownValueChanged(event);
            else
                obj.FieldtoPlotDropDown.Items = {'-'};
                obj.MatchTypeDropDown.Items = {'-'};
                obj.DataTypeDropDown.Items = {'-'};
                obj.StormTypeDropDown.Items = {'-'};
                obj.StormIDDropDown.Items = {'-'};
                obj.StormIDDropDown.Enable = 'off';
                obj.PlotControlsPanel.Enable = 'off';
            end
            obj.update_buttons();
        end

        function stormTypeDropDownValueChanged(obj, event)
            load(obj.database.database_file, 'storm');
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
            load(obj.database.database_file, 'storm');
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
            % Built Storm DB: Water Levels Moved By The Change Of The Offset (chess.CoastalHazardSystem.apply_datum_offset)
            if obj.built
                obj.database.apply_datum_offset(event.Value - event.PreviousValue);
                if obj.FieldtoPlotDropDown.Value == 1
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
            if any(sel_file ~= 0)
                obj.inspect_source(fullfile(sel_pth, sel_file));
            end
            obj.show_source();
        end

        function getChsDependenciesButtonPressed(obj, event)
            % Another CHS_Dependencies Folder: The Storm Data Is Selected Again (It Is Inspected And Built With The Folder)
            obj.reset_db_state();
            obj.show_source();
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
            obj.project.discard_built_storm_database();
            delete(obj.figUI);
            obj.db_created = false;
        end
    end

    %% PRIVATE METHODS
    methods (Access=private)

        function init_chs_dependencies(obj)
            % Start-Up (No Error Dialog): The Project's CHS_Dependencies Folder Is Applied. A Project With A Region Keeps A Valid
            % Folder (Browse Disabled); Missing Or Invalid, Browse Stays Enabled To Re-Point It
            msg = 'none';
            if ~isempty(obj.chs_dependencies)
                msg = obj.set_chs_dependencies(obj.chs_dependencies);
            end
            region = obj.project.region();
            if isempty(region)
                return
            end
            if isempty(msg)
                obj.chsDependenciesFolderButton.Enable = 'off';
                obj.chsDependenciesFolderButton.Tooltip = 'CHS_Dependencies is fixed for this project. Create a new project to use a different source.';
            else
                obj.CHSStudyDependenciesEditField.Placeholder = sprintf('CHS_Dependencies not found. Select a folder containing region %s.', region);
            end
        end

        function msg = set_chs_dependencies(obj, chs_dir)
            % CHS_Dependencies Folder Of The Import (Browse And Start-Up): Layout Check, Plus The Project Region's Files When
            % The Project Has A Region (chess.Project.chs_dependencies_problem). Sets The Folder, Lamp, CHS File Button And Field
            % (Full Path). msg: '' If Valid, Else The Reason (Folder Cleared)
            msg = chess.Project.chs_dependencies_problem(chs_dir, obj.project.region());
            if isempty(msg)
                obj.chs_dependencies = chs_dir;
                obj.studyDependenciesLamp.Color = [0 1 0];
                obj.chsZipFolderButton.Enable = 'on';
                obj.CHSStudyDependenciesEditField.Value = chs_dir;
            else
                obj.chs_dependencies = '';
                obj.studyDependenciesLamp.Color = [1 0 0];
                obj.chsZipFolderButton.Enable = 'off';
                obj.CHSStudyDependenciesEditField.Value = '';
            end
        end

        function update_name_status(obj, name)
            % Name Lamp + Message (While Typing And On Change), Then Buttons. Red: Invalid (chess.Project.storm_database_name_problem).
            % Yellow: Exists (chess.Project.storm_database_clash), Overwrite Confirmed At Import. Green: OK
            name = char(name);
            msg = chess.Project.storm_database_name_problem(name);
            state = 'red';
            if isempty(msg)
                state = 'green';
                [in_project, on_disk] = obj.project.storm_database_clash(name);
                if in_project
                    state = 'yellow';
                    msg = sprintf('Storm DB "%s" exists: you will be asked to overwrite it at import.', name);
                elseif on_disk
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
            % Create: Valid Name And Storm Data Selected. Import: Valid Name And A Storm DB Built
            name_ok = ~strcmp(obj.name_state, 'red');
            obj.CreateStormDBButton.Enable = name_ok && ~isempty(obj.database);
            obj.ImportButton.Enable = name_ok && obj.built;
        end

        function reset_db_state(obj)
            % No Storm Data Selected, Nothing Built
            obj.database = [];
            obj.contents = [];
            obj.built = false;
            obj.auxLib.dialog_answer = false;
        end

        function inspect_source(obj, source)
            % Selected Storm Data Described By The Library (chess.Project.inspect_storm_data: File Names And Attributes Only,
            % Region Checked Against The Project; chess.CoastalHazardSystem.source_contents: Storm Types And Data Types). A
            % CHS .zip Must State Its Vertical Datum. A storm + prob_mass .mat Does Not Hold Its Study: Asked
            % (storm_data_dialog) And Stated To The Library (set_study). Any Problem: Error Dialog, Nothing Selected
            try
                selected = obj.project.inspect_storm_data(source, obj.chs_dependencies);
                selected.prompt_for_uncertainty = false; % No Command Window Questions: Missing Bias & Uncertainty Is An Error
                held = selected.source_contents();
                if strcmp(selected.source_kind, 'chs_zip') && isempty(selected.vertical_datum)
                    error('the first ADCIRC storm file has no ''Vertical Datum'' root attribute.');
                end
                if strcmp(selected.source_kind, 'storm_mat')
                    details = obj.storm_data_dialog(selected.region, selected.savepoint_id);
                    if isempty(details)
                        return
                    end
                    selected.set_study(details.region, details.sp_id, details.swl_uncertainty, details.hm0_uncertainty);
                    problem = obj.project.storm_data_region_problem(selected);
                    if ~isempty(problem)
                        error('%s', problem);
                    end
                end
            catch me
                obj.auxLib.error_dlgbox(['Could not use the storm data ' source ': ' me.message]);
                return
            end
            obj.database = selected;
            obj.contents = held;
        end

        function show_source(obj)
            % Storm Data Field, Lamp, Study Preview, WLP/WHP Check Boxes And Buttons Of The Selected Storm Data (None: Cleared)
            if isempty(obj.database)
                obj.CHSZipFolderEditField.Value = '';
                obj.CHSZipFolderLamp.Color = [1 0 0];
                obj.StudyPreviewTable.Data = [{},{}];
                obj.update_buttons();
                return
            end
            % WLP/WHP: Built From CHS Files With Both Peaks And Timeseries | Fixed By A storm + prob_mass .mat
            storm_file = strcmp(obj.database.source_kind, 'storm_mat');
            can_build = ~storm_file && obj.contents.has_peaks && obj.contents.has_timeseries;
            obj.CreateWLPStormDBCheckBox.Enable = matlab.lang.OnOffSwitchState(can_build);
            obj.CreateWHPStormDBCheckBox.Enable = matlab.lang.OnOffSwitchState(can_build);
            if storm_file
                obj.create_wlp = obj.contents.has_wlp;
                obj.create_whp = obj.contents.has_whp;
                obj.CreateWLPStormDBCheckBox.Value = obj.create_wlp;
                obj.CreateWHPStormDBCheckBox.Value = obj.create_whp;
            elseif ~can_build
                obj.CreateWLPStormDBCheckBox.Value = false;
                obj.CreateWHPStormDBCheckBox.Value = false;
                obj.create_wlp = false;
                obj.create_whp = false;
            else
                obj.create_wlp = obj.CreateWLPStormDBCheckBox.Value;
                obj.create_whp = obj.CreateWHPStormDBCheckBox.Value;
            end
            obj.CHSZipFolderEditField.Value = obj.auxLib.relative_path(obj.database.source, pwd);
            study_datum = obj.database.vertical_datum;
            if isempty(study_datum)
                study_datum = 'Unknown';
            end
            obj.VerticalDatumLabel.Text = [study_datum ' To ' obj.project.vertical_datum ' Vertical Offset:'];
            sp_location = 'n/a';
            if isfinite(obj.database.savepoint_latitude) && isfinite(obj.database.savepoint_longitude)
                sp_location = sprintf('%.6f, %.6f', obj.database.savepoint_latitude, obj.database.savepoint_longitude);
            end
            obj.StudyPreviewTable.Data = [
                {'CHS Study'; 'Study Vertical Datum'; 'Save Point Lat, Lon [deg]'; 'Incudes Peaks'; 'Includes Timeseries'},...
                {obj.database.region; study_datum; sp_location; obj.contents.has_peaks; obj.contents.has_timeseries},...
                ];
            obj.CHSZipFolderLamp.Color = [0 1 0];
            obj.update_buttons();
        end

        function ok = create_storm_database(obj)
            % Storm DB Of The Selected Storm Data Built By The Library In The Project's Holding Folder
            % (chess.Project.build_storm_database: CHS Files Converted, Storm Types And Data Types Of The Storm Data, WLP/WHP As
            % Checked, Datum Offset). Progress And Cancel Through The Wizard Dialog. ok: Built
            ok = false;
            obj.dlgObj = [];
            obj.auxLib.dialog_answer = false;
            try
                obj.project.build_storm_database(obj.database, obj.create_wlp, obj.create_whp, obj.VerticalOffsetEditField.Value,...
                    @(fraction, message) obj.build_progress(fraction, message));
            catch me
                obj.close_progress();
                if strcmp(me.identifier, 'chess:GUI:CHSStormDBImportUI:importCancelled')
                    obj.auxLib.error_dlgbox('Storm database creation cancelled.');
                else
                    obj.auxLib.error_dlgbox(['Could not create the storm database: ' me.message]);
                end
                obj.auxLib.dialog_answer = false;
                return
            end
            obj.close_progress();
            obj.auxLib.dialog_answer = false;
            ok = true;
        end

        function build_progress(obj, fraction, message)
            % Storm Database Creation Progress (Library progress_function, Wizard Dialog); A Cancel (Seen Here, Between Build
            % Steps) Stops The Creation
            obj.dlgObj = obj.auxLib.progress_window(fraction, message, 'Storm Database Creation Progress', obj.dlgObj, true);
            if obj.auxLib.dialog_answer
                error('chess:GUI:CHSStormDBImportUI:importCancelled', 'Storm database creation cancelled.');
            end
        end

        function close_progress(obj)
            if ~isempty(obj.dlgObj) && isvalid(obj.dlgObj)
                close(obj.dlgObj);
            end
        end

        % storm & prob_mass .mat: Region, Savepoint ID (+ Custom Modeling Uncertainties)
        function details = storm_data_dialog(obj, region, sp_id)
            details = [];
            % CHS Regions Available In CHS_Dependencies + Custom Modeling
            chs_files = chess.CoastalHazardSystem.dependency_files(obj.chs_dependencies, '');
            regions = [chs_files.available_regions, {'Custom_Modeling'}];
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
                % Custom Modeling: User Uncertainties [Ua Ur] (chess.CoastalHazardSystem.set_study: No Model Bias, No Study Grid)
                [swl_uncertainty, hm0_uncertainty] = deal([]);
                if is_custom
                    swl_uncertainty = unc_val(1:2);
                    hm0_uncertainty = unc_val(3:4);
                end
                fig.UserData = struct('region', region_dd.Value, 'sp_id', sp_val, 'swl_uncertainty', swl_uncertainty,...
                    'hm0_uncertainty', hm0_uncertainty);
                uiresume(fig);
            end
        end

    end

    %% STORM DB RECORD HELPERS (chess.Project.storm_databases)
    methods (Static)
        function info = get_db_info(rec)
            % Storm Database Details Of A Record (Library chess.CoastalHazardSystem.create_db_info). Databases Imported Before db_info Existed Have None
            if ~chess.CoastalHazardSystem.is_valid_db_info(rec.db_info)
                error('Storm database "%s" has no db_info (imported with an older CHESS version): rebuild the storm database (import it again).', rec.db_name);
            end
            info = rec.db_info;
        end

        function sp_id = get_savepoint_id(rec)
            % CHS ADCIRC Savepoint ID Of A Storm DB Record ([] If Unknown)
            sp_id = [];
            if isstruct(rec.sp_ids) && isfield(rec.sp_ids, 'adcirc')
                sp_id = rec.sp_ids.adcirc;
            end
        end
    end

    %% STATIC PRIVATE METHODS
    methods (Static, Access=private)
        % Arrow Pointer On Exit (Errors Included; The Window May Already Be Closed)
        function restore_pointer(fig)
            if isvalid(fig)
                fig.Pointer = 'arrow';
            end
        end
    end

end

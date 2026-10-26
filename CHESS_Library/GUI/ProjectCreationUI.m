classdef ProjectCreationUI < handle
    %% DEFINE CLASS PROPERTIES
    properties (Access = private)
        VerticalDatumEditFieldLabel  matlab.ui.control.Label
        ProjectNameLamp              matlab.ui.control.Lamp
        CreateProjectButton          matlab.ui.control.Button
        ProjectPathLabel             matlab.ui.control.Label
        ProjectPathLamp              matlab.ui.control.Lamp
        ProjectPathButton            matlab.ui.control.Button
        ProjectNameEditFieldLabel    matlab.ui.control.Label
        ProjectNameMessageLabel      matlab.ui.control.Label % One-Line Name Status (Red: Invalid, Amber: Overwrite Asked At Create)
        ProjectCLsLabel              matlab.ui.control.Label
        UnitSystemDropDownLabel      matlab.ui.control.Label
        project_names % Names Of The Loaded Projects (A Clash Is Red)
        name_state % Project Name Status: 'red' | 'green' | 'yellow' (A CHESS Project Folder Of That Name Exists: Overwrite Asked)
        auxLib
        VerticalDatumEditField       matlab.ui.control.EditField
        ProjectPathEditField         matlab.ui.control.EditField
        ProjectNameEditField         matlab.ui.control.EditField
        ConfidenceLimitsEditField_4  matlab.ui.control.NumericEditField
        ConfidenceLimitsEditField_3  matlab.ui.control.NumericEditField
        ConfidenceLimitsEditField_2  matlab.ui.control.NumericEditField
        ConfidenceLimitsEditField    matlab.ui.control.NumericEditField
        UnitSystemDropDown           matlab.ui.control.DropDown
        ParentGL                     matlab.ui.container.GridLayout
        ChildGL_1                    matlab.ui.container.GridLayout
        ChildGL_2                    matlab.ui.container.GridLayout
        ChildGL_3                    matlab.ui.container.GridLayout
        ChildGL_4                    matlab.ui.container.GridLayout


    end
    properties (Access=public)
        uifig            matlab.ui.Figure
        project_created
        chess_project
        proj_name
        path_warning % Long Project Folder Warning Text For The Caller To Show ('' When The Path Is Short Enough)
    end

    %% DEFINE CLASS INSTANTIATION METHOD
    methods (Access = public)
        function obj = ProjectCreationUI(parent_fig, project_names)
            % parent_fig: Optional Window This Wizard Opens Centered On ([]: Screen)
            % project_names: Names Of The Loaded Projects (A New Project Cannot Take One)
            if nargin < 1
                parent_fig = [];
            end
            if nargin < 2
                project_names = {};
            end
            obj.auxLib = auxUIFunctions();
            obj.project_names = project_names;
            obj.path_warning = '';
            % Create UIFigure and components
            create_ui(obj, parent_fig);
            obj.update_status(obj.ProjectNameEditField.Value);
        end
    end

    %% DEFINE CLASS UI COMPONENT CREATION METHOD
    methods (Access = private)
        function create_ui(obj, parent_fig)
            %% CREATE UI OBJECTS & PARENT FIGURE
            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIWindow and hide until all components are created
            obj.uifig = uifigure('Visible', 'off');
            obj.uifig.Position = [100 100 407 135];
            obj.uifig.Name = 'Project Creation Wizard';

            % Create ParentGL
            obj.ParentGL = uigridlayout(obj.uifig);
            obj.ParentGL.ColumnWidth = {'1x'};
            obj.ParentGL.RowHeight = {'fit', 'fit', 'fit', 'fit'};
            obj.ParentGL.ColumnSpacing = 3;
            obj.ParentGL.RowSpacing = 3;
            obj.ParentGL.Padding = [3 3 3 3];

            % Create ChildGL_1
            obj.ChildGL_1 = uigridlayout(obj.ParentGL);
            obj.ChildGL_1.ColumnWidth = {90, '1x', 20};
            obj.ChildGL_1.RowHeight = {'fit', 'fit'};
            obj.ChildGL_1.Padding = [0 0 0 0];
            obj.ChildGL_1.Layout.Row = 1;
            obj.ChildGL_1.Layout.Column = 1;

            % Create ProjectNameEditFieldLabel
            obj.ProjectNameEditFieldLabel = uilabel(obj.ChildGL_1);
            obj.ProjectNameEditFieldLabel.Layout.Row = 1;
            obj.ProjectNameEditFieldLabel.Layout.Column = 1;
            obj.ProjectNameEditFieldLabel.Text = 'Project Name: ';

            % Create ProjectNameLamp
            obj.ProjectNameLamp = uilamp(obj.ChildGL_1);
            obj.ProjectNameLamp.Layout.Row = 1;
            obj.ProjectNameLamp.Layout.Column = 3;
            obj.ProjectNameLamp.Color = [1 0 0];

            % Create ProjectNameEditField
            obj.ProjectNameEditField = uieditfield(obj.ChildGL_1, 'text');
            obj.ProjectNameEditField.Layout.Row = 1;
            obj.ProjectNameEditField.Layout.Column = 2;
            obj.ProjectNameEditField.Value = 'New_project';

            % Create ProjectNameMessageLabel
            obj.ProjectNameMessageLabel = uilabel(obj.ChildGL_1);
            obj.ProjectNameMessageLabel.Layout.Row = 2;
            obj.ProjectNameMessageLabel.Layout.Column = [2 3];
            obj.ProjectNameMessageLabel.FontSize = 11;
            obj.ProjectNameMessageLabel.Text = '';

            % Create Child_GL2
            obj.ChildGL_2 = uigridlayout(obj.ParentGL);
            obj.ChildGL_2.ColumnWidth = {90, 21, '1x', 20};
            obj.ChildGL_2.RowHeight = {'fit'};
            obj.ChildGL_2.Padding = [0 0 0 0];
            obj.ChildGL_2.Layout.Row = 2;
            obj.ChildGL_2.Layout.Column = 1;

            % Create ProjectPathLabel
            obj.ProjectPathLabel = uilabel(obj.ChildGL_2);
            obj.ProjectPathLabel.Layout.Row = 1;
            obj.ProjectPathLabel.Layout.Column = 1;
            obj.ProjectPathLabel.Text = 'Project Path:';

            % Create ProjectPathButton
            obj.ProjectPathButton = uibutton(obj.ChildGL_2, 'push');
            obj.ProjectPathButton.Icon = 'file_icon.png';
            obj.ProjectPathButton.BackgroundColor = [0.9412 0.9412 0.9412];
            obj.ProjectPathButton.Layout.Row = 1;
            obj.ProjectPathButton.Layout.Column = 2;
            obj.ProjectPathButton.Text = '';

            % Create ProjectPathEditField
            obj.ProjectPathEditField = uieditfield(obj.ChildGL_2, 'text');
            obj.ProjectPathEditField.Editable = 'off';
            obj.ProjectPathEditField.Layout.Row = 1;
            obj.ProjectPathEditField.Layout.Column = 3;
            obj.ProjectPathEditField.Value = '';
            obj.ProjectPathEditField.Placeholder = 'Select the folder the project folder is created in...';

            % Create ProjectPathLamp
            obj.ProjectPathLamp = uilamp(obj.ChildGL_2);
            obj.ProjectPathLamp.Layout.Row = 1;
            obj.ProjectPathLamp.Layout.Column = 4;
            obj.ProjectPathLamp.Color = [1 0 0];

            % Create ChildGL_3
            obj.ChildGL_3 = uigridlayout(obj.ParentGL);
            obj.ChildGL_3.ColumnWidth = {90, 70, 'fit', '1x', 20};
            obj.ChildGL_3.RowHeight = {'1x'};
            obj.ChildGL_3.Padding = [0 0 0 0];
            obj.ChildGL_3.Layout.Row = 3;
            obj.ChildGL_3.Layout.Column = 1;

            % Create UnitSystemDropDownLabel
            obj.UnitSystemDropDownLabel = uilabel(obj.ChildGL_3);
            obj.UnitSystemDropDownLabel.Layout.Row = 1;
            obj.UnitSystemDropDownLabel.Layout.Column = 1;
            obj.UnitSystemDropDownLabel.Text = 'Unit System:';

            % Create UnitSystemDropDown
            obj.UnitSystemDropDown = uidropdown(obj.ChildGL_3);
            obj.UnitSystemDropDown.Items = {'SI', 'Imperial'};
            obj.UnitSystemDropDown.BackgroundColor = [0.9412 0.9412 0.9412];
            obj.UnitSystemDropDown.Layout.Row = 1;
            obj.UnitSystemDropDown.Layout.Column = 2;
            obj.UnitSystemDropDown.Value = 'SI';

            % Create VerticalDatumEditFieldLabel
            obj.VerticalDatumEditFieldLabel = uilabel(obj.ChildGL_3);
            obj.VerticalDatumEditFieldLabel.Layout.Row = 1;
            obj.VerticalDatumEditFieldLabel.Layout.Column = 3;
            obj.VerticalDatumEditFieldLabel.Text = 'Vertical Datum:';

            % Create VerticalDatumEditField
            obj.VerticalDatumEditField = uieditfield(obj.ChildGL_3, 'text');
            obj.VerticalDatumEditField.Layout.Row = 1;
            obj.VerticalDatumEditField.Layout.Column = 4;
            obj.VerticalDatumEditField.Value = 'NAVD88';

            % Create ChildGL_4
            obj.ChildGL_4 = uigridlayout(obj.ParentGL);
            obj.ChildGL_4.ColumnWidth = {90, '1x', '1x', '1x', '1x', 'fit'};
            obj.ChildGL_4.RowHeight = {'1x'};
            obj.ChildGL_4.Padding = [0 0 0 0];
            obj.ChildGL_4.Layout.Row = 4;
            obj.ChildGL_4.Layout.Column = 1;

            % Create ProjectCLsLabel
            obj.ProjectCLsLabel = uilabel(obj.ChildGL_4);
            obj.ProjectCLsLabel.Layout.Row = 1;
            obj.ProjectCLsLabel.Layout.Column = 1;
            obj.ProjectCLsLabel.Text = 'Project CLs (%):';

            % Create ConfidenceLimitsEditField
            obj.ConfidenceLimitsEditField = uieditfield(obj.ChildGL_4, 'numeric');
            obj.ConfidenceLimitsEditField.Limits = [0 100];
            obj.ConfidenceLimitsEditField.RoundFractionalValues = 'on';
            obj.ConfidenceLimitsEditField.ValueDisplayFormat = '%.0f';
            obj.ConfidenceLimitsEditField.HorizontalAlignment = 'center';
            obj.ConfidenceLimitsEditField.Layout.Row = 1;
            obj.ConfidenceLimitsEditField.Layout.Column = 2;
            obj.ConfidenceLimitsEditField.Value = 100;

            % Create ConfidenceLimitsEditField_2
            obj.ConfidenceLimitsEditField_2 = uieditfield(obj.ChildGL_4, 'numeric');
            obj.ConfidenceLimitsEditField_2.Limits = [0 100];
            obj.ConfidenceLimitsEditField_2.RoundFractionalValues = 'on';
            obj.ConfidenceLimitsEditField_2.ValueDisplayFormat = '%.0f';
            obj.ConfidenceLimitsEditField_2.HorizontalAlignment = 'center';
            obj.ConfidenceLimitsEditField_2.Layout.Row = 1;
            obj.ConfidenceLimitsEditField_2.Layout.Column = 3;

            % Create ConfidenceLimitsEditField_3
            obj.ConfidenceLimitsEditField_3 = uieditfield(obj.ChildGL_4, 'numeric');
            obj.ConfidenceLimitsEditField_3.Limits = [0 100];
            obj.ConfidenceLimitsEditField_3.RoundFractionalValues = 'on';
            obj.ConfidenceLimitsEditField_3.ValueDisplayFormat = '%.0f';
            obj.ConfidenceLimitsEditField_3.HorizontalAlignment = 'center';
            obj.ConfidenceLimitsEditField_3.Layout.Row = 1;
            obj.ConfidenceLimitsEditField_3.Layout.Column = 4;
            obj.ConfidenceLimitsEditField_3.Value = 84;

            % Create ConfidenceLimitsEditField_4
            obj.ConfidenceLimitsEditField_4 = uieditfield(obj.ChildGL_4, 'numeric');
            obj.ConfidenceLimitsEditField_4.Limits = [0 100];
            obj.ConfidenceLimitsEditField_4.RoundFractionalValues = 'on';
            obj.ConfidenceLimitsEditField_4.ValueDisplayFormat = '%.0f';
            obj.ConfidenceLimitsEditField_4.HorizontalAlignment = 'center';
            obj.ConfidenceLimitsEditField_4.Layout.Row = 1;
            obj.ConfidenceLimitsEditField_4.Layout.Column = 5;

            % Create CreateProjectButton
            obj.CreateProjectButton = uibutton(obj.ChildGL_4, 'push');
            obj.CreateProjectButton.BackgroundColor = [0.9412 0.9412 0.9412];
            obj.CreateProjectButton.Layout.Row = 1;
            obj.CreateProjectButton.Layout.Column = 6;
            obj.CreateProjectButton.Text = 'Create Project';
            obj.CreateProjectButton.Enable = false;


            % Show the figure after all components are created
            obj.auxLib.center_on_parent(obj.uifig, parent_fig);
            obj.auxLib.set_parent(obj.uifig); % Wizard Dialogs Center On The Wizard
            obj.uifig.Visible = 'on';
            obj.project_created = 0;
            % Assign Callbacks
            obj.ProjectNameEditField.ValueChangedFcn = @(src, event) ProjectNameChanged(obj, event);
            obj.ProjectNameEditField.ValueChangingFcn = @(src, event) update_status(obj, event.Value);
            obj.VerticalDatumEditField.ValueChangedFcn = @(src, event) VerticalDatumChanged(obj, event);
            obj.ProjectPathButton.ButtonPushedFcn = @(src, event) ProjectPathButtonPushed(obj, event);
            obj.CreateProjectButton.ButtonPushedFcn = @(src, event) CreateProjectButtonPushed(obj, event);
            obj.uifig.CloseRequestFcn = @(src, event) UIWindowCloseRequest(obj, event);
        end
    end

    %% DEFINE UI COMPONENT CALLBACK FUNCTIONS
    methods (Access = private)
        function UIWindowCloseRequest(obj, event)
            delete(obj.uifig);
            obj.project_created = 0;
        end

        function ProjectPathButtonPushed(obj, event)
            selpath = uigetdir([], 'Select Output Folder For CHESS Project');
            if ~isequal(selpath, 0)
                obj.ProjectPathEditField.Value = selpath;
            end
            % Name Re-Checked Against The (New) Folder
            obj.update_status(obj.ProjectNameEditField.Value);
        end

        function CreateProjectButtonPushed(obj, event)
            name = obj.ProjectNameEditField.Value;
            folder = obj.ProjectPathEditField.Value;
            % Re-Checked At Submission (The Folder May Have Changed Since)
            obj.update_status(name);
            if ~obj.CreateProjectButton.Enable
                return
            end
            proj_dir = fullfile(folder, name);
            % Existing CHESS Project Folder: Overwrite Confirmed, Then Deleted As A Whole (Nothing Created If That Fails)
            if strcmp(obj.name_state, 'yellow')
                obj.auxLib.confirmation_dlgbox(sprintf(['Project folder "%s" already exists. Overwrite it?\n',...
                    'The folder and everything in it will be deleted.'], proj_dir), 'Overwrite');
                if ~obj.auxLib.dialog_answer
                    return
                end
                try
                    leftover = chessProject.delete_folder(proj_dir);
                catch ME
                    obj.auxLib.error_dlgbox(ME.message);
                    return
                end
                if ~isempty(leftover)
                    obj.auxLib.error_dlgbox(sprintf(['The old project folder was moved to "%s" but could not be fully ',...
                        'deleted. Delete it manually.'], leftover));
                end
            end
            mkdir(proj_dir);
            CLs = [obj.ConfidenceLimitsEditField.Value, obj.ConfidenceLimitsEditField_2.Value,...
                obj.ConfidenceLimitsEditField_3.Value, obj.ConfidenceLimitsEditField_4.Value];
            obj.chess_project = chessProject(name, folder, obj.VerticalDatumEditField.Value, CLs, obj.UnitSystemDropDown.Value);
            obj.proj_name = name;
            % Long Folder Path: Warning Text For The Caller (Creation Proceeds)
            n_max = ProjectCreationUI.max_output_path_length(folder, name);
            if n_max > 260
                obj.path_warning = sprintf(['The project folder path is long (%d chars): output files may exceed the Windows ',...
                    '260-character path limit (estimated longest output path: %d chars). Consider a shorter project folder.'],...
                    numel(proj_dir), n_max);
            end
            delete(obj.uifig); % Delete New Project UI Window
            obj.project_created = 1;
        end

        function ProjectNameChanged(obj, event)
            obj.update_status(obj.ProjectNameEditField.Value);
        end

        function VerticalDatumChanged(obj, event)
            if isempty(obj.VerticalDatumEditField.Value)
                obj.VerticalDatumEditField.Value = 'NAVD88';
            end
        end
    end

    %% AUXILIARY FUNCTION
    methods (Access=private)
        function update_status(obj, name)
            % Name Lamp + Message (While Typing, On Change, On A New Folder), Folder Lamp, Folder Button And Create Button.
            % Red: Invalid Or A Loaded Project's Name (chessProject.name_problem), Or A File / Non-Project Folder Of That Name
            % In The Folder. Yellow: A CHESS Project Folder (CHESS_project_<name>.mat Inside) Of That Name, Overwrite Asked At
            % Create. Green: OK. Create Needs An Existing Folder And A Green Or Yellow Name
            name = char(name);
            folder = obj.ProjectPathEditField.Value;
            has_folder = ~isempty(folder) && isfolder(folder);
            msg = chessProject.name_problem(name, obj.project_names, '');
            obj.ProjectPathButton.Enable = isempty(msg);
            state = 'red';
            if isempty(msg)
                state = 'green';
                target = fullfile(folder, name);
                if ~has_folder
                    % Checked On Disk Once A Folder Is Selected
                elseif isfile(target)
                    state = 'red';
                    msg = sprintf('A file named "%s" exists in this folder. Choose another name.', name);
                elseif isfolder(target) && isfile(fullfile(target, ['CHESS_project_' name '.mat']))
                    state = 'yellow';
                    msg = sprintf('Project "%s" exists in this folder: you will be asked to overwrite it.', name);
                elseif isfolder(target)
                    state = 'red';
                    msg = sprintf('A folder named "%s" that is not a CHESS project exists in this folder. Choose another name.', name);
                end
            end
            obj.name_state = state;
            switch state
                case 'red'
                    obj.ProjectNameLamp.Color = [1 0 0];
                    obj.ProjectNameMessageLabel.FontColor = [0.75 0.1 0.1];
                case 'yellow'
                    obj.ProjectNameLamp.Color = [1 1 0];
                    obj.ProjectNameMessageLabel.FontColor = [0.6 0.45 0];
                otherwise
                    obj.ProjectNameLamp.Color = [0 1 0];
            end
            obj.ProjectNameMessageLabel.Text = msg;
            if has_folder
                obj.ProjectPathLamp.Color = [0 1 0];
            else
                obj.ProjectPathLamp.Color = [1 0 0];
            end
            obj.CreateProjectButton.Enable = has_folder && ~strcmp(state, 'red');
        end
    end

    methods (Static)
        function n = max_output_path_length(base_path, proj_name)
            % Estimated Longest Output Path Under The Project Folder (Characters). Longest Writer: The Run Files
            % (Library chess_paths, Used By CHESS_UI_canvas get_config_path):
            %   <base>\<project>\PSE\<pse>\<alt>\<workflow folder>\<db>_<workflow name>_project_responses.mat
            % Workflow 1: Longest Folder/Name ('PROS'/'PROS-RB'); '_project_responses.mat' Is The Longest Suffix
            % (Of _config_file/_project_forcing/_sampling_seed/_project_responses .mat). PSE, Alternative And
            % Storm DB Names Are Not Known At Project Creation: 32 Characters Allowed For Each
            name_allowance = repmat('x', 1, 32);
            paths = chess_paths(base_path, proj_name, name_allowance, name_allowance, 1, name_allowance);
            n = numel(paths.out_files.resp_data);
        end
    end
end

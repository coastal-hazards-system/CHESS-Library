classdef PSECreationUI < handle
    %% DEFINE CLASS PROPERTIES
    properties (Access = private)
        PSENameEditFieldLabel          matlab.ui.control.Label
        AlternativeNameEditFieldLabel  matlab.ui.control.Label
        Panel
        unitslib
        convlib
        vDatum char
        unitSys
        CreatePSEButton                matlab.ui.control.Button
        AddBermCheckBox                matlab.ui.control.CheckBox
        PSETable                        matlab.ui.control.Table
        PSEAxes matlab.ui.control.UIAxes
        PSENameEditField               matlab.ui.control.EditField
        AlternativeNameEditField       matlab.ui.control.EditField
        NameMessageLabel               matlab.ui.control.Label % One-Line Name Problem (Red); Empty When Both Names Are Valid
        StageSuffixLabel               matlab.ui.control.Label % Locked Multi-Line Suffix After The Alternative Name ('_stage_1' / '_stage_2')
        pse_to_copy
        berm_rows % Template Berm Rows (Added When Berm Is Checked)
        GridLayout                     matlab.ui.container.GridLayout
        controlGridLayout              matlab.ui.container.GridLayout
    end
    properties (Access=public)
        uifig                       matlab.ui.Figure
        pse_created logical
        pse_geometry struct
        pse_table cell
        pse_type char
        chess_project
        pse_name
        alt_name
        auxLib
        ml_stage double = 0 % Multi-Line Stage Being Created: 0 Regular, 1 New Multi-Line PSE + Its Stage 1, 2 Stage 2 Of PSE alt_pse_name
    end

    %% DEFINE CLASS INSTANTIATION METHOD (CONSTRUCTOR)
    methods (Access = public)
        function obj = PSECreationUI(pse_type, chess_project, alt_pse_name, parent_fig, ml_stage)
            % parent_fig: Optional Window This Wizard Opens Centered On ([]: Screen)
            % ml_stage: Optional Multi-Line Stage (Default 0): 1 New Multi-Line PSE (alt_pse_name ''), 2 Stage 2 Alternative Of
            %   Multi-Line PSE alt_pse_name. The Alternative Name Gets The Locked Suffix chessProject.stage_suffix(ml_stage)
            if nargin < 4
                parent_fig = [];
            end
            if nargin < 5
                ml_stage = 0;
            end
            obj.ml_stage = ml_stage;
            obj.chess_project = chess_project;
            obj.auxLib = auxUIFunctions();
            % Create UIFigure and components
            create_ui(obj, pse_type, parent_fig);
            % Placeholder PSE & Alternative Names Until Create ('<new>': Never A Valid Name, So It Cannot Clash)
            obj.pse_name = '<new>';
            obj.alt_name = '<new>';
            obj.pse_type = pse_type;
            obj.pse_to_copy = alt_pse_name;
            % Populate PSE Table
            intialize_table(obj, pse_type, obj.chess_project.unitsys);
            %
            pse_list = obj.chess_project.get_project_field('pse_list', '', '', 'proj');
            passCond = ~isempty(pse_list);
            %
            if passCond % Already Have 1 or More PSEs
                if isempty(alt_pse_name) % New PSE Being Added
                    % Add Alternative
                    obj.chess_project.add_project_field('pse_list', obj.alt_name, obj.pse_name, obj.alt_name, 'pse');
                    obj.chess_project.add_project_field('alternative_list', {{obj.alt_name}}, obj.pse_name, obj.alt_name, 'pse');
                    obj.chess_project.add_project_field('pse_tables', obj.PSETable.Data, obj.pse_name, obj.alt_name, 'alt');
                else % New Alternative Being Added
                    % Set PSE Name To Existing
                    obj.pse_name = alt_pse_name;
                    % Get ALternative List
                    alt_list = obj.chess_project.get_project_field('alternative_list', obj.pse_name, obj.alt_name, 'pse');
                    % Grab Table From The First Existing Alternative Of This PSE Type (Multi-Line PSEs Mix Types), Else The Template
                    geo_list = obj.chess_project.get_project_field('pse_geometry', obj.pse_name, '', 'pse');
                    same_type = find(cellfun(@(g) isstruct(g) && isfield(g, 'pse_type') && strcmp(g.pse_type, pse_type), geo_list), 1);
                    load_pse_table = obj.PSETable.Data;
                    if ~isempty(same_type)
                        load_pse_table = obj.chess_project.get_project_field('pse_tables', obj.pse_name, alt_list{same_type}, 'alt');
                    end
                    % Assign Loaded Table To Alternative
                    obj.chess_project.add_project_field('alternative_list', obj.alt_name, obj.pse_name, obj.alt_name, 'alt');
                    obj.chess_project.add_project_field('pse_tables', {load_pse_table}, obj.pse_name, obj.alt_name, 'alt');
                    obj.PSETable.Data = load_pse_table;
                    % Set PSE Name And Lock It
                    obj.PSENameEditField.Value = alt_pse_name;
                    obj.PSENameEditField.Editable = false;
                    obj.PSENameEditField.Enable = false;
                end
            else % First PSE In Project
                obj.chess_project.set_project_field('pse_list', obj.pse_name, obj.pse_name, obj.alt_name, 'pse');
                obj.chess_project.set_project_field('pse_tables', {obj.PSETable.Data}, obj.pse_name, obj.alt_name, 'pse');
                obj.chess_project.set_project_field('alternative_list', {obj.alt_name}, obj.pse_name, obj.alt_name, 'pse');
            end
            % Create Geometry
            obj.pse_geometry = obj.chess_project.create_geometry(obj.pse_name, obj.alt_name, pse_type);
            % Plot Geometry
            obj.plot_pse();
            % Verify If Berm BOx SHould Be Checked
            obj.AddBermCheckBox.Value = logical(obj.pse_geometry.add_toe_berm);
            obj.check_names(obj.PSENameEditField.Value, obj.AlternativeNameEditField.Value);
        end
    end

    %% DEFINE CLASS UI COMPONENT CREATION METHOD
    methods (Access = private)
        function intialize_table(obj, pse_type, unitsys)
            % PSE Table Rows Come From CHESS-Library Template (Geometry + Properties)
            tpl = obj.chess_project.get_library_template(pse_type);
            rows = [tpl.geometry; tpl.properties];
            % Toe Berm Is Optional Only When Template Defines add_toe_berm
            % (Hidden For Floodwalls Until Conceptual Models Are Set: Library finalize_structure_config Removes Them)
            berm_indx = strcmp(rows(:, 1), 'add_toe_berm');
            berm_allowed = any(berm_indx) && ~strcmp(pse_type, 'Floodwall');
            obj.AddBermCheckBox.Enable = berm_allowed;
            obj.AddBermCheckBox.Visible = ~strcmp(pse_type, 'Floodwall');
            obj.AddBermCheckBox.Value = berm_allowed && isequal(rows{berm_indx, 4}, 1);
            rows(berm_indx, :) = [];
            % Berm Rows Shown Only When Berm Is Checked
            is_berm = startsWith(rows(:, 1), 'berm_');
            obj.berm_rows = rows(is_berm & berm_allowed, :);
            rows(is_berm, :) = [];
            if obj.AddBermCheckBox.Value
                rows = [rows; obj.berm_rows];
            end
            % Template Values Are SI; Convert Lengths & Masses For Imperial Projects
            if strcmp(unitsys, 'Imperial')
                rows = obj.convert_rows(rows, unitsys);
                obj.berm_rows = obj.convert_rows(obj.berm_rows, unitsys);
            end
            % Populate Table
            obj.PSETable.Data = rows;
        end

        function rows = convert_rows(obj, rows, unitsys)
            % Convert Template SI Values ([m], [kg]) To Project Unit System
            dims = {'[m]', 'length'; '[kg]', 'mass'};
            for dd = 1:size(dims, 1)
                pull_indx = strcmp(rows(:, 3), dims{dd, 1});
                [conv, ~, lbl] = obj.chess_project.convert_units(1, dims{dd, 2}, 'SI', unitsys);
                rows(pull_indx, 4) = cellfun(@(x) x*conv, rows(pull_indx, 4), 'un', false);
                rows(pull_indx, 3) = {['[' lbl ']']};
            end
        end
        function plot_pse(obj)
            % Wizard Plot: The Alternative Being Created; A Multi-Line Stage 2 In Line Behind Its PSE's Stage 1, Drawn From
            % Stage 1's Current PSE Geometry (No Run Tab Storm DB / Workflow Here To Pick A Stage 1 Run)
            if obj.ml_stage == 2
                s1_alt = obj.chess_project.stage1_alt(obj.pse_name);
                obj.chess_project.plot_multiline(obj.pse_name, s1_alt,...
                    obj.chess_project.get_project_field('pse_geometry', obj.pse_name, s1_alt, 'alt'), obj.alt_name, obj.PSEAxes);
            else
                obj.chess_project.plot_geometry(obj.pse_name, obj.alt_name, obj.PSEAxes);
            end
        end

        % Create UI Component
        function create_ui(obj, pse_type, parent_fig)
            %% CREATE UI OBJECTS & PARENT FIGURE
            % Create UIFigure and hide until all components are created
            obj.uifig = uifigure('Visible', 'off');
            obj.uifig.Position = [100 100 575 495];
            obj.uifig.Name = [pse_type ' Creation Wizard'];
            if obj.ml_stage > 0
                obj.uifig.Name = sprintf('Multi-line Transect Stage %d: %s', obj.ml_stage, obj.uifig.Name);
            end

            % Create GridLayout
            obj.GridLayout = uigridlayout(obj.uifig);
            obj.GridLayout.ColumnWidth = {'1x'};
            obj.GridLayout.RowHeight = {'1x', 'fit', 'fit', '0.75x'};
            obj.GridLayout.RowSpacing = 3;
            obj.GridLayout.Padding = [3 3 3 3];

            % Create PSEAxes
            obj.PSEAxes = uiaxes(obj.GridLayout);
            title(obj.PSEAxes, ['Project: ' obj.chess_project.name ' | PSE Type: ' pse_type]);
            switch obj.chess_project.unitsys
                case 'SI'
                    lunit = 'm';
                case 'Imperial'
                    lunit = 'ft';
            end
            xlabel(obj.PSEAxes, ['X Distance [' lunit ']']);
            ylabel(obj.PSEAxes, ['Elevation [' lunit '] (' obj.chess_project.vdatum ')']);
            zlabel(obj.PSEAxes, 'Z');
            obj.PSEAxes.Box = 'on';
            obj.PSEAxes.XGrid = 'on';
            obj.PSEAxes.XMinorGrid = 'on';
            obj.PSEAxes.YGrid = 'on';
            obj.PSEAxes.YMinorGrid = 'on';
            obj.PSEAxes.ZGrid = 'on';
            obj.PSEAxes.ZMinorGrid = 'on';
%             obj.PSEAxes.Position = [5 189 564 296];
            obj.PSEAxes.Layout.Row = 1;
            obj.PSEAxes.Layout.Column = 1;

            % Create controlGridLayout
            obj.controlGridLayout = uigridlayout(obj.GridLayout);
            obj.controlGridLayout.ColumnWidth = {75, 105, '1x', 0, 65, '1x', 70};
            if obj.ml_stage > 0
                obj.controlGridLayout.ColumnWidth{4} = 'fit';
            end
            obj.controlGridLayout.RowHeight = {'1x'};
            obj.controlGridLayout.ColumnSpacing = 5;
            obj.controlGridLayout.Padding = [5 0 5 0];
            obj.controlGridLayout.Layout.Row = 2;
            obj.controlGridLayout.Layout.Column = 1;


            % Create AddBermCheckBox
            obj.AddBermCheckBox = uicheckbox(obj.controlGridLayout);
            obj.AddBermCheckBox.Text = 'Add Berm ';
%             obj.AddBermCheckBox.Position = [4 3 79 22];
            obj.AddBermCheckBox.Layout.Row = 1;
            obj.AddBermCheckBox.Layout.Column = 1;

            % Create AlternativeNameEditFieldLabel
            obj.AlternativeNameEditFieldLabel = uilabel(obj.controlGridLayout);
%             obj.AlternativeNameEditFieldLabel.Position = [95 3 100 22];
            obj.AlternativeNameEditFieldLabel.Text = 'Alternative Name:';
            obj.AlternativeNameEditFieldLabel.Layout.Row = 1;
            obj.AlternativeNameEditFieldLabel.Layout.Column = 2;

            % Create AlternativeNameEditField
            obj.AlternativeNameEditField = uieditfield(obj.controlGridLayout, 'text');
            obj.AlternativeNameEditField.Placeholder = 'Set Name';
%             obj.AlternativeNameEditField.Position = [201 3 93 22];
            obj.AlternativeNameEditField.Layout.Row = 1;
            obj.AlternativeNameEditField.Layout.Column = 3;

            % Create StageSuffixLabel (Multi-Line: Locked Name Suffix)
            obj.StageSuffixLabel = uilabel(obj.controlGridLayout);
            obj.StageSuffixLabel.Text = chessProject.stage_suffix(obj.ml_stage);
            obj.StageSuffixLabel.Layout.Row = 1;
            obj.StageSuffixLabel.Layout.Column = 4;

            % Create PSENameEditFieldLabel
            obj.PSENameEditFieldLabel = uilabel(obj.controlGridLayout);
%             obj.PSENameEditFieldLabel.Position = [306 3 68 22];
            obj.PSENameEditFieldLabel.Text = 'PSE Name:';
            obj.PSENameEditFieldLabel.Layout.Row = 1;
            obj.PSENameEditFieldLabel.Layout.Column = 5;

            % Create PSENameEditField
            obj.PSENameEditField = uieditfield(obj.controlGridLayout, 'text');
            obj.PSENameEditField.Placeholder = 'Set Name';
            %             obj.PSENameEditField.Position = [380 3 93 22];
            obj.PSENameEditField.Layout.Row = 1;
            obj.PSENameEditField.Layout.Column = 6;

            % Create CreatePSEButton
            obj.CreatePSEButton = uibutton(obj.controlGridLayout, 'push');
            %             obj.CreatePSEButton.Position = [485 3 75 23];
            obj.CreatePSEButton.Text = 'Create PSE';
            obj.CreatePSEButton.Enable = false;
            obj.CreatePSEButton.Layout.Row = 1;
            obj.CreatePSEButton.Layout.Column = 7;

            % Create NameMessageLabel
            obj.NameMessageLabel = uilabel(obj.GridLayout);
            obj.NameMessageLabel.FontSize = 11;
            obj.NameMessageLabel.FontColor = [0.75 0.1 0.1];
            obj.NameMessageLabel.Text = '';
            obj.NameMessageLabel.Layout.Row = 3;
            obj.NameMessageLabel.Layout.Column = 1;

            % Create PSETable
            obj.PSETable = uitable(obj.GridLayout);
            obj.PSETable.ColumnWidth = {0, 'auto', 'auto', 'auto'};
            obj.PSETable.RowName = {};
            obj.PSETable.ColumnName = {'Model Variable','Description','Units','Value'};
            obj.PSETable.ColumnSortable = [true false false false];
            obj.PSETable.ColumnEditable = [false false false true];
            obj.PSETable.Layout.Row = 4;
            obj.PSETable.Layout.Column = 1;
%             obj.PSETable.Position = [6 6 564 152];

            % Show the figure after all components are created
            obj.auxLib.center_on_parent(obj.uifig, parent_fig);
            obj.auxLib.set_parent(obj.uifig); % Wizard Dialogs Center On The Wizard
            obj.uifig.Visible = 'on';
            obj.pse_created = 0;
            % Assign Callbacks
            obj.AddBermCheckBox.ValueChangedFcn = @(src, event) AddBermCheckBoxValueChanged(obj, event);
            obj.uifig.CloseRequestFcn = @(src, event) UIWindowCloseRequest(obj, event);
            obj.AlternativeNameEditField.ValueChangedFcn = @(src, event) EditFieldValueChanged(obj, []);
            obj.PSENameEditField.ValueChangedFcn = @(src, event) EditFieldValueChanged(obj, []);
            obj.AlternativeNameEditField.ValueChangingFcn = @(src, event) check_names(obj, obj.PSENameEditField.Value, event.Value);
            obj.PSENameEditField.ValueChangingFcn = @(src, event) check_names(obj, event.Value, obj.AlternativeNameEditField.Value);
            obj.CreatePSEButton.ButtonPushedFcn = @(src, event) CreatePSEButtonPushed(obj, event);
            obj.PSETable.CellEditCallback = @(src, event) PSETableCellEdit(obj, event);
        end
    end

    %% DEFINE UI COMPONENT CALLBACK FUNCTIONS
    methods (Access = private)
        function UIWindowCloseRequest(obj, event)
            delete(obj.uifig);
            obj.pse_created = 0;
%             if isempty(obj.pse_to_copy)
%                 opMode = 'pse';
%             else
%                 opMode = 'alt';
%             end
%             obj.chess_project.delete_project_field('pse_tables', obj.pse_name, obj.alt_name, opMode);
%             obj.chess_project.delete_project_field('pse_geometry', obj.pse_name, obj.alt_name, opMode);
%             alt_list = obj.chess_project.get_project_field('alternative_list', obj.pse_name, obj.alt_name, 'pse');
%             if length(alt_list) == 1
%                 obj.chess_project.delete_project_field('alternative_list', obj.pse_name, obj.alt_name, 'pse');
%                 obj.chess_project.delete_project_field('pse_list', obj.pse_name, obj.alt_name, 'pse');
%             else
%                 obj.chess_project.delete_project_field('alternative_list', obj.pse_name, obj.alt_name, 'alt');
%             end
        end

        function AddBermCheckBoxValueChanged(obj, event)
            % Add/Remove Template Berm Rows
            is_berm = startsWith(obj.PSETable.Data(:, 1), 'berm_');
            if obj.AddBermCheckBox.Value && ~any(is_berm)
                obj.PSETable.Data = [obj.PSETable.Data; obj.berm_rows];
            elseif ~obj.AddBermCheckBox.Value
                obj.PSETable.Data(is_berm, :) = [];
            end
            % Create Geometry
            obj.chess_project.set_project_field('pse_tables', obj.PSETable.Data, obj.pse_name, obj.alt_name, 'alt');
            obj.pse_geometry = obj.chess_project.create_geometry(obj.pse_name, obj.alt_name, obj.pse_type);
            % Plot Geometry
            obj.plot_pse();
        end

        function EditFieldValueChanged(obj, event)
            obj.check_names(obj.PSENameEditField.Value, obj.AlternativeNameEditField.Value);
        end

        function ok = check_names(obj, pse_value, alt_value)
            % PSE And Alternative Names (While Typing And On Change): chessProject.name_problem Against The Project's Names
            % And The Folders On Disk (An Orphan Folder Blocks The Name). First Problem Shown Under The Fields; Create
            % Enabled Only When Both Are Valid. The Names Are Applied To The Project At Create
            proj_dir = fullfile(obj.chess_project.path, obj.chess_project.name);
            msg = '';
            if isempty(obj.pse_to_copy) % New PSE Being Added
                pse_list = obj.chess_project.get_project_field('pse_list', '', '', 'proj');
                pse_msg = chessProject.name_problem(pse_value, pse_list, '', fullfile(proj_dir, 'PSE'));
                if ~isempty(pse_msg)
                    msg = ['PSE name: ' pse_msg];
                end
                alt_dir = ''; % New PSE: No Alternative Folder Can Exist Under It Yet
            else % New Alternative Being Added
                alt_dir = fullfile(proj_dir, 'PSE', obj.pse_name);
            end
            if isempty(msg)
                alt_list = obj.chess_project.get_project_field('alternative_list', obj.pse_name, '', 'pse');
                alt_msg = '';
                if isempty(alt_value) && obj.ml_stage > 0 % The Suffix Alone Is Not A Name
                    alt_msg = 'Enter a name.';
                end
                if isempty(alt_msg)
                    alt_msg = chessProject.name_problem([char(alt_value) obj.StageSuffixLabel.Text], alt_list, '', alt_dir);
                end
                if ~isempty(alt_msg)
                    msg = ['Alternative name: ' alt_msg];
                end
            end
            obj.NameMessageLabel.Text = msg;
            ok = isempty(msg);
            obj.CreatePSEButton.Enable = ok;
        end

        function PSETableCellEdit(obj, event)
            indices = event.Indices;
            newData = event.NewData;
            % Create Geometry
            obj.chess_project.set_project_field('pse_tables', obj.PSETable.Data, obj.pse_name, obj.alt_name, 'alt');
            obj.pse_geometry = obj.chess_project.create_geometry(obj.pse_name, obj.alt_name, obj.pse_type);
            % Plot Geometry
            obj.plot_pse();
        end

        function CreatePSEButtonPushed(obj, event)
            % Names Re-Checked (The Disk May Have Changed), Then Applied Over The Placeholders (Alternative: Name + Locked Suffix)
            if ~obj.check_names(obj.PSENameEditField.Value, obj.AlternativeNameEditField.Value)
                return
            end
            if isempty(obj.pse_to_copy)
                obj.chess_project.set_project_field('pse_list', obj.PSENameEditField.Value, obj.pse_name, obj.alt_name, 'pse');
                obj.pse_name = obj.PSENameEditField.Value;
            end
            new_alt = [obj.AlternativeNameEditField.Value obj.StageSuffixLabel.Text];
            obj.chess_project.set_project_field('alternative_list', new_alt, obj.pse_name, obj.alt_name, 'alt');
            obj.alt_name = new_alt;
            % Store Project Component Mapping
            obj.pse_created = 1;
            % Store UI Data
            obj.pse_table = obj.PSETable.Data;
            delete(obj.uifig); % Delete New Project UI Window
        end
    end
end

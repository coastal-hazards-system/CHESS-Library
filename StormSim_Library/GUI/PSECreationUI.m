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
        ss_project
        pse_name
        alt_name
        auxLib
    end

    %% DEFINE CLASS INSTANTIATION METHOD (CONSTRUCTOR)
    methods (Access = public)
        function obj = PSECreationUI(pse_type, ss_project, alt_pse_name)
            %
            obj.ss_project = ss_project;
            obj.auxLib = auxUIFunctions();
            % Create UIFigure and components
            create_ui(obj, pse_type);
            % Add Dummy PSE & ALternative Names
            obj.pse_name = 'dummy';
            obj.alt_name = 'dummy';
            obj.pse_type = pse_type;
            obj.pse_to_copy = alt_pse_name;
            % Populate PSE Table
            intialize_table(obj, pse_type, obj.ss_project.unitsys);
            %
            pse_list = obj.ss_project.get_project_field('pse_list', '', '', 'proj');
            passCond = ~isempty(pse_list);
            %
            if passCond % Already Have 1 or More PSEs
                if isempty(alt_pse_name) % New PSE Being Added
                    % Add Alternative
                    obj.ss_project.add_project_field('pse_list', obj.alt_name, obj.pse_name, obj.alt_name, 'pse');
                    obj.ss_project.add_project_field('alternative_list', {{obj.alt_name}}, obj.pse_name, obj.alt_name, 'pse');
                    obj.ss_project.add_project_field('pse_tables', obj.PSETable.Data, obj.pse_name, obj.alt_name, 'alt');
                else % New Alternative Being Added
                    % Set PSE Name To Existing
                    obj.pse_name = alt_pse_name;
                    % Get ALternative List
                    alt_list = obj.ss_project.get_project_field('alternative_list', obj.pse_name, obj.alt_name, 'pse');
                    % Grab Table From Existing Alternative
                    load_pse_table = obj.ss_project.get_project_field('pse_tables', obj.pse_name, alt_list{1}, 'alt');
                    % Assign Loaded Table To Alternative
                    obj.ss_project.add_project_field('alternative_list', 'dummy', obj.pse_name, obj.alt_name, 'alt');
                    obj.ss_project.add_project_field('pse_tables', {load_pse_table}, obj.pse_name, obj.alt_name, 'alt');
                    obj.PSETable.Data = load_pse_table;
                    % Set PSE Name And Lock It
                    obj.PSENameEditField.Value = alt_pse_name;
                    obj.PSENameEditField.Editable = false;
                    obj.PSENameEditField.Enable = false;
                end
            else % First PSE In Project
                obj.ss_project.set_project_field('pse_list', obj.pse_name, obj.pse_name, obj.alt_name, 'pse');
                obj.ss_project.set_project_field('pse_tables', {obj.PSETable.Data}, obj.pse_name, obj.alt_name, 'pse');
                obj.ss_project.set_project_field('alternative_list', {obj.alt_name}, obj.pse_name, obj.alt_name, 'pse');
            end
            % Create Geometry
            obj.pse_geometry = obj.ss_project.create_geometry(obj.pse_name, obj.alt_name, pse_type);
            % Plot Geometry
            obj.ss_project.plot_geometry(obj.pse_name, obj.alt_name, obj.PSEAxes);
            % Verify If Berm BOx SHould Be Checked
            obj.AddBermCheckBox.Value = logical(obj.pse_geometry.add_toe_berm);
        end
    end

    %% DEFINE CLASS UI COMPONENT CREATION METHOD
    methods (Access = private)
        function intialize_table(obj, pse_type, unitsys)
            % PSE Table Rows Come From StormSim-Library Template (Geometry + Properties)
            tpl = obj.ss_project.get_library_template(pse_type);
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
                [conv, ~, lbl] = obj.ss_project.convert_units(1, dims{dd, 2}, 'SI', unitsys);
                rows(pull_indx, 4) = cellfun(@(x) x*conv, rows(pull_indx, 4), 'un', false);
                rows(pull_indx, 3) = {['[' lbl ']']};
            end
        end
        % Create UI Component
        function create_ui(obj, pse_type)
            %% CREATE UI OBJECTS & PARENT FIGURE
            % Create UIFigure and hide until all components are created
            obj.uifig = uifigure('Visible', 'off');
            obj.uifig.Position = [100 100 575 495];
            obj.uifig.Name = [pse_type ' Creation Wizard'];

            % Create GridLayout
            obj.GridLayout = uigridlayout(obj.uifig);
            obj.GridLayout.ColumnWidth = {'1x'};
            obj.GridLayout.RowHeight = {'1x', 'fit', '0.75x'};
            obj.GridLayout.RowSpacing = 3;
            obj.GridLayout.Padding = [3 3 3 3];

            % Create PSEAxes
            obj.PSEAxes = uiaxes(obj.GridLayout);
            title(obj.PSEAxes, ['Project: ' obj.ss_project.name ' | PSE Type: ' pse_type]);
            switch obj.ss_project.unitsys
                case 'SI'
                    lunit = 'm';
                case 'Imperial'
                    lunit = 'ft';
            end
            xlabel(obj.PSEAxes, ['X Distance [' lunit ']']);
            ylabel(obj.PSEAxes, ['Elevation [' lunit '] (' obj.ss_project.vdatum ')']);
            zlabel(obj.PSEAxes, 'Z');
            obj.PSEAxes.Box = 'on';
            obj.PSEAxes.XGrid = 'on';
            obj.PSEAxes.XMinorGrid = 'on';
            obj.PSEAxes.YGrid = 'on';
            obj.PSEAxes.YMinorGrid = 'on';
            obj.PSEAxes.ZGrid = 'on';
            obj.PSEAxes.ZMinorGrid = 'on';
%             obj.PSEAxes.Position = [5 189 564 296];
            axis(obj.PSEAxes, 'equal');
            obj.PSEAxes.Layout.Row = 1;
            obj.PSEAxes.Layout.Column = 1;

            % Create controlGridLayout
            obj.controlGridLayout = uigridlayout(obj.GridLayout);
            obj.controlGridLayout.ColumnWidth = {75, 105, '1x', 65, '1x', 70};
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

            % Create PSENameEditFieldLabel
            obj.PSENameEditFieldLabel = uilabel(obj.controlGridLayout);
%             obj.PSENameEditFieldLabel.Position = [306 3 68 22];
            obj.PSENameEditFieldLabel.Text = 'PSE Name:';
            obj.PSENameEditFieldLabel.Layout.Row = 1;
            obj.PSENameEditFieldLabel.Layout.Column = 4;

            % Create PSENameEditField
            obj.PSENameEditField = uieditfield(obj.controlGridLayout, 'text');
            obj.PSENameEditField.Placeholder = 'Set Name';
            %             obj.PSENameEditField.Position = [380 3 93 22];
            obj.PSENameEditField.Layout.Row = 1;
            obj.PSENameEditField.Layout.Column = 5;

            % Create CreatePSEButton
            obj.CreatePSEButton = uibutton(obj.controlGridLayout, 'push');
            %             obj.CreatePSEButton.Position = [485 3 75 23];
            obj.CreatePSEButton.Text = 'Create PSE';
            obj.CreatePSEButton.Enable = false;
            obj.CreatePSEButton.Layout.Row = 1;
            obj.CreatePSEButton.Layout.Column = 6;

            % Create PSETable
            obj.PSETable = uitable(obj.GridLayout);
            obj.PSETable.ColumnWidth = {0, 'auto', 'auto', 'auto'};
            obj.PSETable.RowName = {};
            obj.PSETable.ColumnName = {'Model Variable','Description','Units','Value'};
            obj.PSETable.ColumnSortable = [true false false false];
            obj.PSETable.ColumnEditable = [false false false true];
            obj.PSETable.Layout.Row = 3;
            obj.PSETable.Layout.Column = 1;
%             obj.PSETable.Position = [6 6 564 152];

            % Show the figure after all components are created
            obj.uifig.Units = 'normalize';
            obj.uifig.Position(1:2) = 0.4;
            obj.uifig.Visible = 'on';
            obj.pse_created = 0;
            % Assign Callbacks
            obj.AddBermCheckBox.ValueChangedFcn = @(src, event) AddBermCheckBoxValueChanged(obj, event);
            obj.uifig.CloseRequestFcn = @(src, event) UIWindowCloseRequest(obj, event);
            obj.AlternativeNameEditField.ValueChangedFcn = @(src, event) EditFieldValueChanged(obj, []);
            obj.PSENameEditField.ValueChangedFcn = @(src, event) EditFieldValueChanged(obj, []);
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
%             obj.ss_project.delete_project_field('pse_tables', obj.pse_name, obj.alt_name, opMode);
%             obj.ss_project.delete_project_field('pse_geometry', obj.pse_name, obj.alt_name, opMode);
%             alt_list = obj.ss_project.get_project_field('alternative_list', obj.pse_name, obj.alt_name, 'pse');
%             if length(alt_list) == 1
%                 obj.ss_project.delete_project_field('alternative_list', obj.pse_name, obj.alt_name, 'pse');
%                 obj.ss_project.delete_project_field('pse_list', obj.pse_name, obj.alt_name, 'pse');
%             else
%                 obj.ss_project.delete_project_field('alternative_list', obj.pse_name, obj.alt_name, 'alt');
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
            obj.ss_project.set_project_field('pse_tables', obj.PSETable.Data, obj.pse_name, obj.alt_name, 'alt');
            obj.pse_geometry = obj.ss_project.create_geometry(obj.pse_name, obj.alt_name, obj.pse_type);
            % Plot Geometry
            obj.ss_project.plot_geometry(obj.pse_name, obj.alt_name, obj.PSEAxes);
        end

        function EditFieldValueChanged(obj, event)
            % Get PSE Listing For Project
            if isempty(obj.pse_to_copy) % New PSE Being Added
                % Check For Unique PSE
                pse_listing = obj.ss_project.get_project_field('pse_list', obj.pse_name, obj.alt_name, 'proj'); % Selected Projects PSE's
                pse_name_pass = ~ismember(obj.PSENameEditField.Value, pse_listing);
                %
                if ~pse_name_pass % PSE Name Is Not Unique
                    % Check If Name Is Internal Or External
                    if strcmp(obj.PSENameEditField.Value, obj.pse_name)
                        % Internal Name (Pass) 
                    else % Name Is External 
                        % Throw Error
                        obj.auxLib.error_dlgbox(['Error: PSE "' obj.PSENameEditField.Value '" already exist. Define a unique name.']);
                        obj.PSENameEditField.Value = obj.pse_name; % Revert To Previous Name
                    end
                elseif ~isempty(obj.PSENameEditField.Value)
                    % Update Names
                    obj.ss_project.set_project_field('pse_list', obj.PSENameEditField.Value, obj.pse_name, obj.alt_name, 'pse');
                    obj.pse_name = obj.PSENameEditField.Value;
                end
                % Alternative Check Runs For A Unique Or Internal (Already Assigned) PSE Name
                if pse_name_pass || strcmp(obj.PSENameEditField.Value, obj.pse_name)
                    % PSE Name Is Valid
                    % Get Alternative Listing
                    alt_listing = obj.ss_project.get_project_field('alternative_list', obj.pse_name, obj.alt_name, 'pse'); % Selected Projects Alternatives
                    % 
                    if ~isempty(alt_listing)
                        alt_name_pass = ~ismember(obj.AlternativeNameEditField.Value, alt_listing);
                        %
                         if ~alt_name_pass % Alternative Name Is Not Unique
                             % Check If Name Is Internal Or External
                             if strcmp(obj.AlternativeNameEditField.Value, obj.alt_name)
                                 % Internal Name (Pass)
                             else % Name Is External
                                 % Throw Error
                                 obj.auxLib.error_dlgbox(['Error: Alternative "' obj.AlternativeNameEditField.Value '" already exist. Define a unique name.']);
                                 % Clear Name
                                 obj.AlternativeNameEditField.Value = obj.alt_name;
                             end
                         elseif ~isempty(obj.AlternativeNameEditField.Value)
                             % Update Names
                             obj.ss_project.set_project_field('alternative_list', obj.AlternativeNameEditField.Value, obj.pse_name, obj.alt_name,  'alt');
                             obj.alt_name = obj.AlternativeNameEditField.Value;
                         end
                    end
                end
            else % New Alternative Being Added
                % Get Alternative Listing
                alt_listing = obj.ss_project.get_project_field('alternative_list', obj.pse_to_copy, obj.alt_name, 'pse'); % Selected Projects Alternatives
                %
                if ~isempty(alt_listing)
                    alt_name_pass = ~any(ismember(obj.AlternativeNameEditField.Value, alt_listing));
                    %
                    if ~alt_name_pass % Alternative Name Is Not Unique
                        % Check If Name Is Internal Or External
                        if strcmp(obj.AlternativeNameEditField.Value, obj.alt_name)
                            % Internal Name (Pass)
                        else % Name Is External
                            % Throw Error
                            obj.auxLib.error_dlgbox(['Error: Alternative "' obj.AlternativeNameEditField.Value '" already exist. Define a unique name.']);
                            % Clear Name
                            obj.AlternativeNameEditField.Value = obj.alt_name;
                        end
                    elseif ~isempty(obj.AlternativeNameEditField.Value)
                        % Update Names
                        obj.ss_project.set_project_field('alternative_list', obj.AlternativeNameEditField.Value, obj.pse_name, obj.alt_name,  'alt');
                        obj.alt_name = obj.AlternativeNameEditField.Value;
                    end
                end
            end
            % Check If Create Button Should Be Enabled
            if ~isempty(obj.AlternativeNameEditField.Value) && ~isempty(obj.PSENameEditField.Value)
                obj.CreatePSEButton.Enable = true;
            else
                obj.CreatePSEButton.Enable = false;
            end
            %
        end

        function PSETableCellEdit(obj, event)
            indices = event.Indices;
            newData = event.NewData;
            % Create Geometry
            obj.ss_project.set_project_field('pse_tables', obj.PSETable.Data, obj.pse_name, obj.alt_name, 'alt');
            obj.pse_geometry = obj.ss_project.create_geometry(obj.pse_name, obj.alt_name, obj.pse_type);
            % Plot Geometry
            obj.ss_project.plot_geometry(obj.pse_name, obj.alt_name, obj.PSEAxes);
        end

        function CreatePSEButtonPushed(obj, event)
            % Store Project Component Mapping
            obj.pse_created = 1;
            %
%             obj.ss_project.set_project_field('alternative_list', obj.AlternativeNameEditField.Value, obj.pse_name, obj.alt_name,  'alt');
%             obj.ss_project.set_project_field('pse_list', obj.PSENameEditField.Value, obj.pse_name, obj.alt_name, 'pse');
            % Store UI Data
            obj.pse_table = obj.PSETable.Data;
            delete(obj.uifig); % Delete New Project UI Window
        end
    end
end

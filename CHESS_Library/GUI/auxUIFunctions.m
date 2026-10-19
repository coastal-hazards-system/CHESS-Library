classdef auxUIFunctions < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access=public)
        windowParentPos
        windowX
        windowY
        dialog_answer
    end
    %% CONSTRUCTOR
    methods (Access=public)
        function obj = auxUIFunctions()
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
        end
    end

    %% DATA PARSING METHODS
    methods (Static)
        function relPath = relative_path(absPath, basePath)
            % absolute2relative Convert an absolute path to a relative path (Windows-style)
            %   relPath = absolute2relative(absPath, basePath) returns the relative
            %   path from basePath to absPath using .\ and ..\ notation.

            % Normalize paths
            absPath = fullfile(absPath);
            basePath = fullfile(basePath);

            % Remove trailing separators
            if endsWith(absPath, filesep), absPath(end) = []; end
            if endsWith(basePath, filesep), basePath(end) = []; end

            % Split into parts
            absParts = splitPath(absPath);
            baseParts = splitPath(basePath);

            % Check for different drives (Windows)
            if ispc && ~strcmpi(absParts{1}, baseParts{1})
                relPath = absPath;  % Cannot compute relative path across drives
                return;
            end

            % Find common prefix
            minLen = min(length(absParts), length(baseParts));
            commonIdx = find(~strcmpi(absParts(1:minLen), baseParts(1:minLen)), 1) - 1;
            if isempty(commonIdx)
                commonIdx = minLen;
            end

            % Construct relative path
            upLevels = repmat({'..'}, 1, length(baseParts) - commonIdx);
            downLevels = absParts(commonIdx+1:end);
            relParts = [upLevels, downLevels];

            if isempty(relParts)
                relPath = '.\';
            else
                relPath = strjoin(relParts, '\');
                if ~startsWith(relPath, '..')
                    relPath = ['.\' relPath];
                end
            end
            %
            function parts = splitPath(p)
                % Helper function to split a path into components
                parts = {};
                while true
                    [p, name, ext] = fileparts(p);
                    if isempty(name) && isempty(ext)
                        if ~isempty(p)
                            parts = [{p}, parts];
                        end
                        break;
                    end
                    parts = [{[name, ext]}, parts];
                end
            end
        end

        function unitLib = update_unit_system(unit_system)
            switch unit_system
                case 'SI'
                    % Define Conversion Factors For Fundamental Units
                    unitLib.conversionCoeffs.length = 3.2808399;% m to ft
                    unitLib.conversionCoeffs.mass = 2.20462262;% kg to lbm
                    unitLib.conversionCoeffs.density = unitLib.conversionCoeffs.mass/(unitLib.conversionCoeffs.length^3);% kg/m^3 to lbm/ft^3
                    unitLib.conversionCoeffs.force = 0.22480894;% N to lbf
                    unitLib.conversionCoeffs.pressure = 0.00014504;% Pa to Psi
                    % Define Symmbols For Fundamental Units
                    unitLib.unitSymbols.length = 'm';% m to ft
                    unitLib.unitSymbols.mass = 'Kg';% kg to lbm
                    unitLib.unitSymbols.density = 'Kg/m^3';% kg/m^3 to lbm/ft^3
                    unitLib.unitSymbols.force = 'N';% N to lbf
                    unitLib.unitSymbols.pressure = 'Pa';% Pa to Psi
                case 'Imperial'
                    % Initialize Unit Conversion Factors
                    unitLib.conversionCoeffs.length = 1/3.2808399;% ft to m
                    unitLib.conversionCoeffs.mass = 1/2.20462262;% lbm to Kg
                    unitLib.conversionCoeffs.density = unitLib.conversionCoeffs.mass/(unitLib.conversionCoeffs.length^3);% lbm/ft^3 to kg/m^3
                    unitLib.conversionCoeffs.force = 1/0.22480894;% lbf to N
                    unitLib.conversionCoeffs.pressure = 1/0.00014504;% Psi to Pa
                    % Define Symmbols For Fundamental Units
                    unitLib.unitSymbols.length = 'ft';% m to ft
                    unitLib.unitSymbols.mass = 'lb';% kg to lbm
                    unitLib.unitSymbols.density = 'lb/m^3';% kg/m^3 to lbm/ft^3
                    unitLib.unitSymbols.force = 'lb_f';% N to lbf
                    unitLib.unitSymbols.pressure = 'Psi';% Pa to Psi
            end
        end
    end

    %% DIALOG WINDOWS
    methods (Access=public)
        function set_window_position(obj, val)
            obj.windowParentPos = val;
            obj.windowX = @(xi, w, tw) xi+0.5*w - 0.5*tw;
            obj.windowY = @(yi, h, th) yi+0.5*h - 0.5*th;
        end


        function data_out = uncertainty_uifig(obj, data_in, reset_val, xi, yi)
            % Initialize output with data_in values
            data_out = data_in(:, 3);

            % Get the file path for locating images (relative to this function)
            pathToFunc = fileparts(mfilename('fullpath'));

            % --- Component Creation ---
            % Updated UIFigure Position (using xi, yi but new width/height)
            fig = uifigure('Name', '', 'NumberTitle', 'off', 'Visible', 'off');
            fig.Position = [100 100 444 175];

            % Anchor DIalog WIndow To Parent Figure
            if ~isempty(obj.windowParentPos)
                window_pos = [obj.windowX(obj.windowParentPos(1), obj.windowParentPos(3), fig.Position(3)),...
                    obj.windowY(obj.windowParentPos(2), obj.windowParentPos(4), fig.Position(4))];
                % Update Position
                fig.Position(1:2) = window_pos;
            end
            

            % Set CloseRequestFcn to handle window "X" as a save
            fig.CloseRequestFcn = @(src, event) saveAndClose();

            % Create UITable with updated Position [5 3 437 144]
            UITable = uitable(fig);
            UITable.ColumnName = {'Field', 'Units', 'Value'};
            UITable.RowName = {};
            UITable.ColumnEditable = [false, false, true];
            UITable.Position = [5 3 437 144];
            UITable.Data = data_in;

            % Create titleLabel with updated Position [5 150 380 22]
            titleLabel = uilabel(fig);
            titleLabel.FontSize = 15;
            titleLabel.FontWeight = 'bold';
            titleLabel.Position = [5 150 380 22];
            titleLabel.Text = 'Storm Database Surge/Waves Modeling Uncertainty';

            % Create resetButton with updated Position [412 148 30 27]
            resetButton = uibutton(fig, 'push');
            resetButton.Icon = 'reset_icon.png';
            resetButton.IconAlignment = 'top';
            resetButton.Position = [412 148 30 27];
            resetButton.Text = '';
            resetButton.ButtonPushedFcn = @(btn, event) resetCallback();

            % Create saveButton with updated Position [380 148 30 27]
            saveButton = uibutton(fig, 'push');
            saveButton.Icon = fullfile(pathToFunc, 'save_icon.png');
            saveButton.Position = [380 148 30 27];
            saveButton.Text = '';
            saveButton.ButtonPushedFcn = @(btn, event) saveAndClose();

            % Show the figure
            fig.Visible = 'on';

            % Block execution until window is closed or save is pressed
            uiwait(fig);

            % --- Nested Functions ---

            function resetCallback()
                currentData = UITable.Data;
                if isnumeric(reset_val)
                    currentData(:, 3) = num2cell(reset_val);
                else
                    currentData(:, 3) = reset_val;
                end
                UITable.Data = currentData;
            end

            function saveAndClose()
                % Capture the current state of the table
                tempData = UITable.Data;
                data_out = tempData(:, 3);

                % Resume and cleanup
                uiresume(fig);
                delete(fig);
            end

        end

        function editfield_input_dlgbox(obj, prompt, choices, title_str)

            % Create the main figure
            fig = uifigure('Position', [100 100 425, 125], 'Name', title_str);
            % Anchor DIalog WIndow To Parent Figure
            if ~isempty(obj.windowParentPos)
                window_pos = [obj.windowX(obj.windowParentPos(1), obj.windowParentPos(3), fig.Position(3)),...
                    obj.windowY(obj.windowParentPos(2), obj.windowParentPos(4), fig.Position(4))];
                % Update Position
                fig.Position(1:2) = window_pos;
            end
            % Reset Dialog ANswer
            obj.dialog_answer = [];

            % Create a top-level grid layout with 2 rows: one for content, one for button
            mainGL = uigridlayout(fig, [2 1]);
            mainGL.RowHeight = {'fit', 'fit'};
            mainGL.ColumnWidth = {'1x'};
            mainGL.Padding = [0 0 0 0];
            mainGL.RowSpacing = 5;

            %% Panel for label and dropdown
            contentPanel = uipanel(mainGL);
            contentPanel.BorderType = 'none';  % Remove border
            contentPanel.Layout.Row = 1;
            contentPanel.Layout.Column = 1;

            % Grid layout inside content panel
            panelGL = uigridlayout(contentPanel, [3 1]);
            panelGL.RowHeight = {'fit','fit', 'fit'};
            panelGL.ColumnWidth = {'1x'};
            panelGL.Padding = [0 0 0 0];
            panelGL.RowSpacing = 5;

            % Wrapping label
            lblTop = uilabel(panelGL);
            lblTop.Text = prompt;
            lblTop.WordWrap = 'on';
            lblTop.HorizontalAlignment = 'center';
            lblTop.FontSize = 12;
            lblTop.FontWeight = 'bold';

            % Edit field
            dd = uieditfield(panelGL);
            dd.FontSize = 12;
            dd.Placeholder = 'Set unique name';

            %% Panel for button
            buttonPanel = uipanel(mainGL);
            buttonPanel.BorderType = 'none';  % Remove border
            buttonPanel.Layout.Row = 2;
            buttonPanel.Layout.Column = 1;

            % Grid layout inside button panel to center the button
            buttonGL = uigridlayout(buttonPanel, [1 3]);
            buttonGL.RowHeight = {'fit'};
            buttonGL.ColumnWidth = {'1x', 'fit', '1x'};  % Center column for button
            buttonGL.Padding = [0 0 0 0];
            buttonGL.ColumnSpacing = 0;

            % Button in center column
            btn = uibutton(buttonGL, 'push');
            btn.Text = 'Submit';
            btn.Layout.Row = 1;
            btn.Layout.Column = 2;
            btn.FontSize = 12;
            btn.ButtonPushedFcn = @(src, event) button_pushed(fig, dd.Value, obj);
            btn.Enable = false;

            %
            dd.ValueChangedFcn = @(src, event) name_change(src, event, dd.Value, obj, choices, btn);

            % Wait for user to close the dialog
            uiwait(fig);

            % Define Callbacks
            function button_pushed(fig, answer, chess_ui)
                chess_ui.dialog_answer = answer;
                close(fig);
            end

            function name_change(src, event, answer, chess_ui, name_list, btn_obj)
                if any(ismember(answer, name_list))
                    % Set Name Field To Empty
                    src.Value = '';
                    chess_ui.dialog_answer = [];
                    % Call Error Window
                    chess_ui.error_dlgbox('Defined name must be unique. Please look at project tree.');
                    % Enable SUbmit Button
                    btn_obj.Enable = false;
                elseif ~isempty(chess_ui.dialog_answer)
                    % Enable SUbmit Button
                    btn_obj.Enable = true;
                elseif isempty(chess_ui.dialog_answer)
                    % Enable SUbmit Button
                    btn_obj.Enable = false;
                end
            end
        end

        function dropdown_input_dlgbox(obj, prompt, choices, title_str)
            % Create the main figure
            fig = uifigure('Position', [100 100 425, 125], 'Name', title_str);
            % Anchor DIalog WIndow To Parent Figure
            if ~isempty(obj.windowParentPos)
                window_pos = [obj.windowX(obj.windowParentPos(1), obj.windowParentPos(3), fig.Position(3)),...
                    obj.windowY(obj.windowParentPos(2), obj.windowParentPos(4), fig.Position(4))];
                % Update Position
                fig.Position(1:2) = window_pos;
            end
            % Reset Dialog ANswer
            obj.dialog_answer = [];

            % Create a top-level grid layout with 2 rows: one for content, one for button
            mainGL = uigridlayout(fig, [2 1]);
            mainGL.RowHeight = {'fit', 'fit'};
            mainGL.ColumnWidth = {'1x'};
            mainGL.Padding = [0 0 0 0];
            mainGL.RowSpacing = 5;

            %% Panel for label and dropdown
            contentPanel = uipanel(mainGL);
            contentPanel.BorderType = 'none';  % Remove border
            contentPanel.Layout.Row = 1;
            contentPanel.Layout.Column = 1;

            % Grid layout inside content panel
            panelGL = uigridlayout(contentPanel, [4 1]);
            panelGL.RowHeight = {'fit','fit', 'fit', 'fit'};
            panelGL.ColumnWidth = {'1x'};
            panelGL.Padding = [0 0 0 0];
            panelGL.RowSpacing = 5;

            % Wrapping label
            lblTop = uilabel(panelGL);
            lblTop.Text = prompt;
            lblTop.WordWrap = 'on';
            lblTop.HorizontalAlignment = 'center';
            lblTop.FontSize = 12;
            lblTop.FontWeight = 'bold';

            % Label for dropdown
            lblDrop = uilabel(panelGL);
            lblDrop.Text = 'Choose an option:';
            lblDrop.HorizontalAlignment = 'center';
            lblDrop.FontSize = 12;

            % Dropdown
            dd = uidropdown(panelGL);
            dd.Items = choices;
            dd.FontSize = 12;

            %% Panel for button
            buttonPanel = uipanel(mainGL);
            buttonPanel.BorderType = 'none';  % Remove border
            buttonPanel.Layout.Row = 2;
            buttonPanel.Layout.Column = 1;

            % Grid layout inside button panel to center the button
            buttonGL = uigridlayout(buttonPanel, [1 3]);
            buttonGL.RowHeight = {'fit'};
            buttonGL.ColumnWidth = {'1x', 'fit', '1x'};  % Center column for button
            buttonGL.Padding = [0 0 0 0];
            buttonGL.ColumnSpacing = 0;

            % Button in center column
            btn = uibutton(buttonGL, 'push');
            btn.Text = 'Submit';
            btn.Layout.Row = 1;
            btn.Layout.Column = 2;
            btn.FontSize = 12;
            btn.ButtonPushedFcn = @(src, event) button_pushed(fig, dd.Value, obj);

            % Wait for user to close the dialog
            uiwait(fig);

            % Define Callbacks
            function button_pushed(fig, answer, chess_ui)
                chess_ui.dialog_answer = answer;
                close(fig);
            end
        end

        function [waitbar_obj] = progress_window(obj, percent, disp_str, window_title, waitbar_obj, include_cancel)
            % Replace Underscores
            disp_str = strrep(disp_str, '_','\_');
            if isempty(waitbar_obj)
                if include_cancel
                    waitbar_obj = waitbar(percent, disp_str, 'Name', window_title,...
                        'WindowStyle','modal',...
                        'CreateCancelBtn', @(source, event, obj) cancelButtonPressed(source, event),...
                        'CloseRequestFcn', @(source, event) closeWindowRequest(source, event));
                else
                    waitbar_obj = waitbar(percent, disp_str, 'Name', window_title,...
                        'WindowStyle','modal',...
                        'CloseRequestFcn', @(source, event) closeWindowRequest(source, event));
                end
                obj.dialog_answer = false;
                % Anchor To Parent Figure
                if ~isempty(obj.windowParentPos)
                    window_pos = [obj.windowX(obj.windowParentPos(1), obj.windowParentPos(3),  waitbar_obj.Position(3)),...
                        obj.windowY(obj.windowParentPos(2), obj.windowParentPos(4),  waitbar_obj.Position(4))];
                    % Update Position
                    waitbar_obj.Position(1:2) = window_pos;
                end
                %                 waitbar_obj.Units = 'normalize';
                %                 waitbar_obj.Position(1:2) = 0.45;
            end
            if ~obj.dialog_answer
                waitbar(percent, waitbar_obj, disp_str);
                % Check for completion
                if percent == 1 || percent == 100
                    % Process Is Finished, Close Window
                    delete(waitbar_obj);
                end
            end
            % Callbacks
            function cancelButtonPressed(source, event)
                obj.dialog_answer = true;
                delete(waitbar_obj);
            end
            function closeWindowRequest(source, event)
                obj.dialog_answer = true;
                delete(waitbar_obj);
            end
        end

        function warning_dlgbox(obj, prompt)
            % Create the main figure
            fig = uifigure('Position', [100 100 425, 125], 'Name', 'Warning Message');
            % Anchor DIalog WIndow To Parent Figure
            if ~isempty(obj.windowParentPos)
                window_pos = [obj.windowX(obj.windowParentPos(1), obj.windowParentPos(3), fig.Position(3)),...
                    obj.windowY(obj.windowParentPos(2), obj.windowParentPos(4), fig.Position(4))];
                % Update Position
                fig.Position(1:2) = window_pos;
            end
            %Reset Dialog ANswer
            obj.dialog_answer = [];

            % Grid layout inside content panel
            panelGL = uigridlayout(fig, [1 1]);
            panelGL.RowHeight = {'1x'};
            panelGL.ColumnWidth = {'1x'};
            panelGL.Padding = [0 0 0 0];
            panelGL.RowSpacing = 5;

            % Wrapping label
            lblTop = uilabel(panelGL);
            lblTop.Text = prompt;
            lblTop.WordWrap = 'on';
            lblTop.HorizontalAlignment = 'center';
            lblTop.FontSize = 16;
            lblTop.FontWeight = 'bold';

            % Wait for user to close the dialog
            uiwait(fig);
        end

        function error_dlgbox(obj, prompt)
            % Create the main figure
            fig = uifigure('Position', [100 100 425, 125], 'Name', 'Error Message');
            % Anchor DIalog WIndow To Parent Figure
            if ~isempty(obj.windowParentPos)
                window_pos = [obj.windowX(obj.windowParentPos(1), obj.windowParentPos(3), fig.Position(3)),...
                    obj.windowY(obj.windowParentPos(2), obj.windowParentPos(4), fig.Position(4))];
                % Update Position
                fig.Position(1:2) = window_pos;
            end
            % Reset Dialog ANswer
            obj.dialog_answer = [];

            % Grid layout inside content panel
            panelGL = uigridlayout(fig, [1 1]);
            panelGL.RowHeight = {'1x'};
            panelGL.ColumnWidth = {'1x'};
            panelGL.Padding = [0 0 0 0];
            panelGL.RowSpacing = 5;

            % Wrapping label
            lblTop = uilabel(panelGL);
            lblTop.Text = prompt;
            lblTop.WordWrap = 'on';
            lblTop.HorizontalAlignment = 'center';
            lblTop.FontSize = 16;
            lblTop.FontWeight = 'bold';

            % Wait for user to close the dialog
            uiwait(fig);
        end

        function choice_dlgbox(obj, prompt, options, title_str, fig_size)
            % Modal Message With One Button Per Option; dialog_answer = Clicked Option ([] If Closed)
            % fig_size: Optional [width height] (Default [460 150])
            if nargin < 5
                fig_size = [460 150];
            end
            fig = uifigure('Position', [100 100 fig_size], 'Name', title_str, 'WindowStyle', 'modal');
            % Anchor Dialog Window To Parent Figure
            if ~isempty(obj.windowParentPos)
                fig.Position(1:2) = [obj.windowX(obj.windowParentPos(1), obj.windowParentPos(3), fig.Position(3)),...
                    obj.windowY(obj.windowParentPos(2), obj.windowParentPos(4), fig.Position(4))];
            end
            obj.dialog_answer = [];
            mainGL = uigridlayout(fig, [2 1]);
            mainGL.RowHeight = {'1x', 'fit'};
            % Wrapping Message
            lbl = uilabel(mainGL);
            lbl.Text = prompt;
            lbl.WordWrap = 'on';
            lbl.HorizontalAlignment = 'center';
            lbl.FontSize = 12;
            % One Button Per Option
            btnGL = uigridlayout(mainGL, [1 numel(options)]);
            btnGL.Padding = [0 0 0 0];
            btnGL.RowHeight = {'fit'};
            for bb = 1:numel(options)
                uibutton(btnGL, 'push', 'Text', options{bb}, 'FontSize', 12,...
                    'ButtonPushedFcn', @(src, ~) button_pushed(src.Text));
            end
            % Wait For User
            uiwait(fig);

            function button_pushed(answer)
                obj.dialog_answer = answer;
                close(fig);
            end
        end

        function confirmation_dlgbox(obj, prompt)
            opts.Interpreter = 'tex';
            opts.Default = 'Cancel';
            opts.Units = 'normalize';
            opts.Position = [0.5 0.5 0.15, 0.1];
            dlg_ans = questdlg(['\fontsize{10}\fontname{Helvetica}' prompt], ...
                'Data Overwrite Warning','Ok', 'Cancel', opts);
            switch dlg_ans
                case 'Ok'
                    obj.dialog_answer = true;
                case 'Cancel'
                    obj.dialog_answer = false;
            end

        end
    end
end
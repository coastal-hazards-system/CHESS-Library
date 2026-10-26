classdef auxUIFunctions < handle
    % CHESS GUI Helpers: Path & Unit Utilities And Modal Dialogs Centered On A Parent Window (Answer In dialog_answer)

    properties (Access=public)
        parentFig % Window The Dialogs Center On (set_parent); Empty: Primary Screen
        dialog_answer
    end
    %% CONSTRUCTOR
    methods (Access=public)
        function obj = auxUIFunctions()
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
        function set_parent(obj, fig)
            % Window The Dialogs Open Centered On (Its Position Is Read When Each Dialog Opens)
            obj.parentFig = fig;
        end

        function center_on_parent(obj, dlg, parent)
            % Center dlg On parent (Default: The set_parent Window; None: Primary Screen), Kept Inside The Monitor
            % Holding The Parent's Center
            if nargin < 3
                parent = obj.parentFig;
            end
            dlg.Units = 'pixels';
            sz = dlg.Position(3:4);
            mon = get(groot, 'MonitorPositions');
            if ~isempty(parent) && isvalid(parent)
                p = getpixelposition(parent);
                c = p(1:2) + p(3:4)/2;
                in_mon = find(c(1) >= mon(:, 1) & c(1) < mon(:, 1) + mon(:, 3) & c(2) >= mon(:, 2) & c(2) < mon(:, 2) + mon(:, 4), 1);
                if isempty(in_mon) % Parent Center Off Every Monitor: Primary Monitor
                    in_mon = 1;
                end
                m = mon(in_mon, :);
            else
                m = mon(1, :);
                c = m(1:2) + m(3:4)/2;
            end
            title_bar = 32; % Position Excludes The Window Title Bar
            pos = c - sz/2;
            pos = max(min(pos, m(1:2) + m(3:4) - sz - [0 title_bar]), m(1:2));
            dlg.Position(1:2) = round(pos);
        end

        function editfield_input_dlgbox(obj, prompt, title_str, initial_value, validate_fcn, ok_label)
            % Text Input Prefilled With initial_value. validate_fcn(value) Returns '' When Valid, Else The Message Shown
            % Under The Field (ok_label Disabled Meanwhile). dialog_answer = Value On ok_label, [] Otherwise
            if nargin < 4
                initial_value = '';
            end
            if nargin < 5 || isempty(validate_fcn)
                validate_fcn = @(~) '';
            end
            if nargin < 6
                ok_label = 'OK';
            end
            obj.dialog_answer = [];
            current = char(initial_value);
            [fig, gl, btns] = obj.build_dialog(title_str, prompt, {'Cancel', ok_label}, 440, [22 16]);
            ef = uieditfield(gl, 'text', 'Value', current, 'FontSize', 12);
            ef.Layout.Row = 2;
            msg_lbl = uilabel(gl, 'Text', '', 'FontSize', 11, 'FontColor', [0.75 0.1 0.1]);
            msg_lbl.Layout.Row = 3;
            ef.ValueChangingFcn = @(~, event) validate(event.Value);
            ef.ValueChangedFcn = @(src, ~) validate(src.Value);
            validate(current);
            fig.Visible = 'on';
            focus(ef);
            if strcmp(obj.run_dialog(fig), ok_label)
                obj.dialog_answer = current;
            end

            function validate(value)
                current = char(value);
                msg = validate_fcn(current);
                msg_lbl.Text = msg;
                if isempty(msg)
                    ef.BackgroundColor = [1 1 1];
                else
                    ef.BackgroundColor = [1 0.93 0.93];
                end
                btns(end).Enable = isempty(msg);
            end
        end

        function dropdown_input_dlgbox(obj, prompt, choices, title_str, ok_label)
            % Pick One Of choices. dialog_answer = Selected Item On ok_label, [] Otherwise
            if nargin < 5
                ok_label = 'OK';
            end
            obj.dialog_answer = [];
            [fig, gl] = obj.build_dialog(title_str, prompt, {'Cancel', ok_label}, 440, 22);
            dd = uidropdown(gl, 'Items', choices, 'FontSize', 12);
            dd.Layout.Row = 2;
            fig.Visible = 'on';
            [answer, value] = obj.run_dialog(fig, @() dd.Value);
            if strcmp(answer, ok_label)
                obj.dialog_answer = value;
            end
        end

        function [dlg] = progress_window(obj, percent, disp_str, window_title, dlg, include_cancel)
            % Progress Dialog Inside The set_parent Window (uiprogressdlg): Created On The First Call (dlg Empty), Updated
            % After, Closed At percent 1 (Or 100). percent NaN: Indeterminate Bar. A Cancel (include_cancel) Closes It And
            % Sets dialog_answer = true (Seen On The Next Call)
            if nargin < 6
                include_cancel = false;
            end
            if isempty(dlg)
                obj.dialog_answer = false;
                if isempty(obj.parentFig) || ~isvalid(obj.parentFig)
                    return
                end
                dlg = uiprogressdlg(obj.parentFig, 'Title', window_title, 'Message', disp_str,...
                    'Cancelable', matlab.lang.OnOffSwitchState(include_cancel));
            end
            if ~isvalid(dlg)
                return
            end
            if dlg.CancelRequested
                obj.dialog_answer = true;
                close(dlg);
                return
            end
            dlg.Message = disp_str;
            if isnan(percent)
                dlg.Indeterminate = 'on';
            else
                dlg.Indeterminate = 'off';
                dlg.Value = min(percent, 1);
                if percent == 1 || percent == 100
                    close(dlg);
                end
            end
        end

        function error_dlgbox(obj, prompt)
            obj.dialog_answer = [];
            fig = obj.build_dialog('Error Message', prompt, {'OK'}, 440, []);
            fig.Visible = 'on';
            obj.run_dialog(fig);
        end

        function choice_dlgbox(obj, prompt, options, title_str, fig_size)
            % Modal Message With One Button Per Option; dialog_answer = Clicked Option ([] If Closed)
            % fig_size: Optional [width height] (Default: Width 440, Height Fits The Message)
            if nargin < 5
                fig_size = 440;
            end
            obj.dialog_answer = [];
            fig = obj.build_dialog(title_str, prompt, options, fig_size, []);
            fig.Visible = 'on';
            obj.dialog_answer = obj.run_dialog(fig);
        end

        function confirmation_dlgbox(obj, prompt, ok_label, title_str)
            % dialog_answer = true Only For ok_label (Cancel, Esc Or The Window X: false)
            if nargin < 3
                ok_label = 'OK';
            end
            if nargin < 4
                title_str = 'Confirm';
            end
            obj.dialog_answer = false;
            fig = obj.build_dialog(title_str, prompt, {'Cancel', ok_label}, 440, []);
            fig.Visible = 'on';
            obj.dialog_answer = strcmp(obj.run_dialog(fig), ok_label);
        end
    end

    methods (Static)
        function add_dialog_keys(fig, ok_fcn, cancel_fcn, ok_btn)
            % Keys Of A Custom Dialog, As In build_dialog: Enter Runs ok_fcn While ok_btn Is Enabled, Esc Runs cancel_fcn.
            % ok_btn Shown Bold (The Default Button)
            ok_btn.FontWeight = 'bold';
            fig.KeyPressFcn = @(~, event) key_pressed(event.Key);

            function key_pressed(key)
                switch key
                    case 'return'
                        if ok_btn.Enable
                            ok_fcn();
                        end
                    case 'escape'
                        cancel_fcn();
                end
            end
        end
    end

    methods (Access=private)
        function [fig, gl, btns] = build_dialog(obj, title_str, prompt, buttons, fig_size, content_rows)
            % Hidden Modal Dialog Centered On The Parent: Wrapped Prompt (Row 1), Content Rows Of content_rows Pixel Heights
            % (Rows 2..), Right-Aligned Buttons (Last = Default: Bold, Enter). A Button Stores Its Text In fig.UserData;
            % Esc / Window X Store []. fig_size: Width (Height Fits The Prompt) Or [width height]
            if isempty(content_rows)
                row_gap = 12;
            else
                row_gap = 8;
            end
            pad = [16 12 16 12];
            if isscalar(fig_size)
                txt = strsplit(char(prompt), newline);
                chars_per_line = floor((fig_size - pad(1) - pad(3))/7.5);
                n_lines = sum(max(1, ceil(cellfun(@numel, txt)/chars_per_line)));
                fig_size(2) = pad(2) + pad(4) + 18*n_lines + 10 + sum(content_rows) + row_gap*(numel(content_rows) + 1) + 26;
            end
            fig = uifigure('Name', title_str, 'WindowStyle', 'modal', 'Visible', 'off', 'Resize', 'off',...
                'Position', [100 100 fig_size]);
            obj.center_on_parent(fig);
            fig.UserData = [];
            gl = uigridlayout(fig, [numel(content_rows) + 2, 1], 'Padding', pad, 'RowSpacing', row_gap);
            gl.RowHeight = [{'1x'}, num2cell(content_rows(:)'), {26}];
            uilabel(gl, 'Text', prompt, 'WordWrap', 'on', 'FontSize', 12, 'VerticalAlignment', 'top');
            n_btn = numel(buttons);
            btn_gl = uigridlayout(gl, [1 n_btn + 1], 'Padding', [0 0 0 0], 'ColumnSpacing', 8, 'RowHeight', {26});
            btn_gl.Layout.Row = numel(content_rows) + 2;
            btn_gl.ColumnWidth = [{'1x'}, cellfun(@(b) max(90, ceil(7.5*numel(b)) + 16), buttons, 'un', false)];
            btns = gobjects(1, n_btn);
            for bb = 1:n_btn
                btns(bb) = uibutton(btn_gl, 'push', 'Text', buttons{bb}, 'FontSize', 12,...
                    'ButtonPushedFcn', @(src, ~) finish(src.Text));
                btns(bb).Layout.Column = bb + 1;
            end
            btns(end).FontWeight = 'bold';
            fig.CloseRequestFcn = @(~, ~) finish([]);
            fig.KeyPressFcn = @(~, event) key_pressed(event.Key);

            function key_pressed(key)
                switch key
                    case 'return'
                        if btns(end).Enable
                            finish(btns(end).Text);
                        end
                    case 'escape'
                        finish([]);
                end
            end

            function finish(answer)
                fig.UserData = answer;
                uiresume(fig);
            end
        end

        function [answer, value] = run_dialog(~, fig, value_fcn)
            % Wait For The Dialog (build_dialog), Return The Pressed Button Text ([] If Closed) And value_fcn() Read Before
            % The Dialog Is Deleted ([] If Closed)
            uiwait(fig);
            [answer, value] = deal([]);
            if isvalid(fig)
                answer = fig.UserData;
                if nargin > 2 && ~isempty(answer)
                    value = value_fcn();
                end
                delete(fig);
            end
        end
    end
end

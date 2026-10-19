classdef NOAATidesPredictionsUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        GridLayout3_2               matlab.ui.container.GridLayout
        EditField                   matlab.ui.control.EditField
        OutputFileLabel             matlab.ui.control.Label
        GridLayout4                 matlab.ui.container.GridLayout
        GetDataButton               matlab.ui.control.Button
        progresAxes                 matlab.ui.control.UIAxes
        SubmitDataRequestLabel      matlab.ui.control.Label
        GridLayout3                 matlab.ui.container.GridLayout
        VerticalDatumDropDown       matlab.ui.control.DropDown
        VerticalDatumDropDownLabel  matlab.ui.control.Label
        StationIDDropDown           matlab.ui.control.DropDown
        StationIDDropDownLabel      matlab.ui.control.Label
        PickNOAATidalPredictionStationLabel  matlab.ui.control.Label
        DefineDataRangeLabel        matlab.ui.control.Label
        GridLayout2_2               matlab.ui.container.GridLayout
        DatePicker                  matlab.ui.control.DatePicker
        EndDateLabel                matlab.ui.control.Label
        DatePicker_2                matlab.ui.control.DatePicker
        StartDateLabel              matlab.ui.control.Label
    end

    properties (Access = private)
        wProj % Active CHESS Project (Tide Files Are Saved In <project>\Tides And Added To wProj.tide_files_list)
        stations % NOAA Harmonic Tidal Prediction Stations (Library: noaa_tide_stations)
        autoFileName % Last Output File Name Set Automatically (User Edits Are Kept)
        progressPatch % Progress Bar Patch In progresAxes
        progressText % Progress Bar Label
    end

    methods (Access = private)

        function set_progress(app, fraction, msg)
            % Progress Bar (0-1) With Label
            app.progressPatch.XData = [0 fraction fraction 0];
            app.progressText.String = msg;
            drawnow;
        end

        function update_file_name(app)
            % Default Output File Name: <station>_<datum>_<start year>.csv (Unless The User Typed A Name)
            if isempty(app.StationIDDropDown.ItemsData) || isempty(app.VerticalDatumDropDown.ItemsData)
                return
            end
            name = sprintf('%s_%s_%s.csv', app.StationIDDropDown.Value, app.VerticalDatumDropDown.Value,...
                char(string(app.DatePicker_2.Value, 'yyyy')));
            if isempty(app.autoFileName) || strcmp(app.EditField.Value, app.autoFileName) || strcmp(app.EditField.Value, 'chess_tidal_file.csv')
                app.EditField.Value = name;
            end
            app.autoFileName = name;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, wProj)
            % NOAA Tidal Prediction Download For A CHESS Project
            app.wProj = wProj;
            app.GetDataButton.Enable = 'off'; % Enabled Once A Station And Its Datums Are Loaded
            % Progress Bar
            ax = app.progresAxes;
            ax.XLim = [0 1];
            ax.YLim = [0 1];
            hold(ax, 'on');
            app.progressPatch = patch(ax, [0 0 0 0], [0 0 1 1], [0.30 0.60 0.85], 'EdgeColor', 'none');
            app.progressText = text(ax, 0.5, 0.5, '', 'HorizontalAlignment', 'center', 'FontSize', 10);
            % Data Range: 1 Year From The Start Date (create_tide_file)
            app.DatePicker_2.Value = dateshift(datetime('today'), 'start', 'year');
            app.DatePicker_2ValueChanged([]);
            % Harmonic Tidal Prediction Stations (Library: noaa_tide_stations)
            app.UIFigure.Pointer = 'watch';
            drawnow;
            try
                app.stations = noaa_tide_stations('R');
            catch me
                app.UIFigure.Pointer = 'arrow';
                app.GetDataButton.Enable = 'off';
                app.StationIDDropDown.Items = {'-'};
                app.VerticalDatumDropDown.Items = {'-'};
                uialert(app.UIFigure, ['Could not load NOAA tidal prediction stations (check the internet connection): ' me.message],...
                    'NOAA Stations');
                return
            end
            app.UIFigure.Pointer = 'arrow';
            st = app.stations;
            state = st.state;
            state(state == "") = "--";
            app.StationIDDropDown.Items = cellstr(state + " - " + st.name + " (" + st.id + ")");
            app.StationIDDropDown.ItemsData = cellstr(st.id);
            app.StationIDDropDownValueChanged([]);
        end

        % Value changed function: StationIDDropDown
        function StationIDDropDownValueChanged(app, event)
            % Datums Available At The Station (Library: noaa_station_datums). The Datum Must Match The CHS Data Datum.
            app.GetDataButton.Enable = 'off'; % No Download While Datums Load
            app.UIFigure.Pointer = 'watch';
            drawnow;
            try
                datums = noaa_station_datums(app.StationIDDropDown.Value);
            catch me
                datums = table();
                if isvalid(app)
                    uialert(app.UIFigure, ['Could not load the station datums: ' me.message], 'NOAA Datums');
                end
            end
            if ~isvalid(app) % Window Closed While Loading
                return
            end
            app.UIFigure.Pointer = 'arrow';
            if isempty(datums)
                app.VerticalDatumDropDown.ItemsData = {};
                app.VerticalDatumDropDown.Items = {'-'};
                app.GetDataButton.Enable = 'off';
                return
            end
            prev = app.VerticalDatumDropDown.Value;
            app.VerticalDatumDropDown.Items = cellstr(datums.name);
            app.VerticalDatumDropDown.ItemsData = cellstr(datums.api_code);
            if ischar(prev) && any(strcmp(app.VerticalDatumDropDown.ItemsData, prev)) % Keep The Datum When Switching Stations
                app.VerticalDatumDropDown.Value = prev;
            elseif any(strcmp(app.VerticalDatumDropDown.ItemsData, 'MSL'))
                app.VerticalDatumDropDown.Value = 'MSL';
            end
            app.GetDataButton.Enable = 'on';
            app.update_file_name();
        end

        % Value changed function: VerticalDatumDropDown
        function VerticalDatumDropDownValueChanged(app, event)
            app.update_file_name();
        end

        % Value changed function: DatePicker_2
        function DatePicker_2ValueChanged(app, event)
            % End Date = Start + 1 Year - 1 Day (create_tide_file Downloads One Year)
            if isnat(app.DatePicker_2.Value)
                app.DatePicker_2.Value = dateshift(datetime('today'), 'start', 'year');
            end
            app.DatePicker.Value = app.DatePicker_2.Value + calyears(1) - caldays(1);
            app.update_file_name();
        end

        % Button pushed function: GetDataButton
        function GetDataButtonPushed(app, event)
            % Download One Year Of Hourly Predictions (Library: create_tide_file) Into <project>\Tides
            [~, name, ~] = fileparts(strtrim(app.EditField.Value));
            name = regexprep(name, '[\\/:*?"<>|]', '_');
            if isempty(name)
                uialert(app.UIFigure, 'Enter an output file name.', 'Output File');
                return
            end
            out_dir = fullfile(app.wProj.path, app.wProj.name, 'Tides');
            out_file = fullfile(out_dir, [name '.csv']);
            if isfile(out_file)
                answer = uiconfirm(app.UIFigure, [name '.csv already exists in the project. Overwrite it?'], 'Output File',...
                    'Options', {'Overwrite', 'Cancel'}, 'DefaultOption', 2, 'CancelOption', 2);
                if strcmp(answer, 'Cancel')
                    return
                end
            end
            if ~isfolder(out_dir)
                mkdir(out_dir);
            end
            app.GetDataButton.Enable = 'off';
            app.set_progress(0, 'Requesting predictions...');
            try
                create_tide_file(app.StationIDDropDown.Value, app.VerticalDatumDropDown.Value,...
                    char(string(app.DatePicker_2.Value, 'yyyyMMdd')), out_file,...
                    @(f) app.set_progress(f, sprintf('%.0f%%', 100*f)));
            catch me
                app.set_progress(0, '');
                app.GetDataButton.Enable = 'on';
                uialert(app.UIFigure, me.message, 'NOAA Tidal Predictions');
                return
            end
            % Add To The Project (Full Path; The Run Tab Shows The File Name)
            if ~any(strcmp(app.wProj.tide_files_list, out_file))
                app.wProj.tide_files_list = [app.wProj.tide_files_list(:); {out_file}];
            end
            delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 452 237];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};

            % Create GridLayout2_2
            app.GridLayout2_2 = uigridlayout(app.GridLayout);
            app.GridLayout2_2.ColumnWidth = {'fit', '1x', 'fit', '1x'};
            app.GridLayout2_2.RowHeight = {'fit'};
            app.GridLayout2_2.Padding = [5 0 0 0];
            app.GridLayout2_2.Layout.Row = 4;
            app.GridLayout2_2.Layout.Column = 1;

            % Create StartDateLabel
            app.StartDateLabel = uilabel(app.GridLayout2_2);
            app.StartDateLabel.HorizontalAlignment = 'right';
            app.StartDateLabel.Layout.Row = 1;
            app.StartDateLabel.Layout.Column = 1;
            app.StartDateLabel.Text = 'Start Date:';

            % Create DatePicker_2
            app.DatePicker_2 = uidatepicker(app.GridLayout2_2);
            app.DatePicker_2.Limits = [datetime([0 1 5]) datetime([9999 12 31])];
            app.DatePicker_2.DisplayFormat = 'uuuu-MMM-dd';
            app.DatePicker_2.ValueChangedFcn = createCallbackFcn(app, @DatePicker_2ValueChanged, true);
            app.DatePicker_2.Layout.Row = 1;
            app.DatePicker_2.Layout.Column = 2;

            % Create EndDateLabel
            app.EndDateLabel = uilabel(app.GridLayout2_2);
            app.EndDateLabel.Layout.Row = 1;
            app.EndDateLabel.Layout.Column = 3;
            app.EndDateLabel.Text = 'End Date:';

            % Create DatePicker
            app.DatePicker = uidatepicker(app.GridLayout2_2);
            app.DatePicker.Limits = [datetime([0 1 5]) datetime([9999 12 31])];
            app.DatePicker.DisplayFormat = 'uuuu-MMM-dd';
            app.DatePicker.Enable = 'off';
            app.DatePicker.Layout.Row = 1;
            app.DatePicker.Layout.Column = 4;

            % Create DefineDataRangeLabel
            app.DefineDataRangeLabel = uilabel(app.GridLayout);
            app.DefineDataRangeLabel.FontSize = 16;
            app.DefineDataRangeLabel.FontWeight = 'bold';
            app.DefineDataRangeLabel.Layout.Row = 3;
            app.DefineDataRangeLabel.Layout.Column = 1;
            app.DefineDataRangeLabel.Text = 'Define Data Range';

            % Create PickNOAATidalPredictionStationLabel
            app.PickNOAATidalPredictionStationLabel = uilabel(app.GridLayout);
            app.PickNOAATidalPredictionStationLabel.FontSize = 16;
            app.PickNOAATidalPredictionStationLabel.FontWeight = 'bold';
            app.PickNOAATidalPredictionStationLabel.Layout.Row = 1;
            app.PickNOAATidalPredictionStationLabel.Layout.Column = 1;
            app.PickNOAATidalPredictionStationLabel.Text = 'Pick NOAA Tidal Prediction Station:';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.GridLayout);
            app.GridLayout3.ColumnWidth = {'fit', '1x', '1x', '1x'};
            app.GridLayout3.RowHeight = {'fit'};
            app.GridLayout3.Padding = [5 0 0 0];
            app.GridLayout3.Layout.Row = 2;
            app.GridLayout3.Layout.Column = 1;

            % Create StationIDDropDownLabel
            app.StationIDDropDownLabel = uilabel(app.GridLayout3);
            app.StationIDDropDownLabel.Layout.Row = 1;
            app.StationIDDropDownLabel.Layout.Column = 1;
            app.StationIDDropDownLabel.Text = 'Station ID:';

            % Create StationIDDropDown
            app.StationIDDropDown = uidropdown(app.GridLayout3);
            app.StationIDDropDown.ValueChangedFcn = createCallbackFcn(app, @StationIDDropDownValueChanged, true);
            app.StationIDDropDown.Layout.Row = 1;
            app.StationIDDropDown.Layout.Column = 2;

            % Create VerticalDatumDropDownLabel
            app.VerticalDatumDropDownLabel = uilabel(app.GridLayout3);
            app.VerticalDatumDropDownLabel.Layout.Row = 1;
            app.VerticalDatumDropDownLabel.Layout.Column = 3;
            app.VerticalDatumDropDownLabel.Text = 'Vertical Datum:';

            % Create VerticalDatumDropDown
            app.VerticalDatumDropDown = uidropdown(app.GridLayout3);
            app.VerticalDatumDropDown.ValueChangedFcn = createCallbackFcn(app, @VerticalDatumDropDownValueChanged, true);
            app.VerticalDatumDropDown.Items = {'Option 4'};
            app.VerticalDatumDropDown.Layout.Row = 1;
            app.VerticalDatumDropDown.Layout.Column = 4;
            app.VerticalDatumDropDown.Value = 'Option 4';

            % Create SubmitDataRequestLabel
            app.SubmitDataRequestLabel = uilabel(app.GridLayout);
            app.SubmitDataRequestLabel.FontSize = 16;
            app.SubmitDataRequestLabel.FontWeight = 'bold';
            app.SubmitDataRequestLabel.Layout.Row = 5;
            app.SubmitDataRequestLabel.Layout.Column = 1;
            app.SubmitDataRequestLabel.Text = 'Submit Data Request';

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.GridLayout);
            app.GridLayout4.ColumnWidth = {100, '1x'};
            app.GridLayout4.RowHeight = {30};
            app.GridLayout4.ColumnSpacing = 5;
            app.GridLayout4.Padding = [5 0 0 0];
            app.GridLayout4.Layout.Row = 7;
            app.GridLayout4.Layout.Column = 1;

            % Create progresAxes
            app.progresAxes = uiaxes(app.GridLayout4);
            app.progresAxes.XTick = [0 0.2 0.4 0.6 0.8 1];
            app.progresAxes.XTickLabel = '';
            app.progresAxes.YTickLabel = '';
            app.progresAxes.TickDir = 'none';
            app.progresAxes.GridColor = 'none';
            app.progresAxes.MinorGridColor = 'none';
            app.progresAxes.Box = 'on';
            app.progresAxes.Layout.Row = 1;
            app.progresAxes.Layout.Column = 2;
            app.progresAxes.Tag = 'progress_bar';

            % Create GetDataButton
            app.GetDataButton = uibutton(app.GridLayout4, 'push');
            app.GetDataButton.ButtonPushedFcn = createCallbackFcn(app, @GetDataButtonPushed, true);
            app.GetDataButton.Layout.Row = 1;
            app.GetDataButton.Layout.Column = 1;
            app.GetDataButton.Text = 'Get Data';

            % Create GridLayout3_2
            app.GridLayout3_2 = uigridlayout(app.GridLayout);
            app.GridLayout3_2.ColumnWidth = {'fit', '1x'};
            app.GridLayout3_2.RowHeight = {'fit'};
            app.GridLayout3_2.Padding = [5 0 0 0];
            app.GridLayout3_2.Layout.Row = 6;
            app.GridLayout3_2.Layout.Column = 1;

            % Create OutputFileLabel
            app.OutputFileLabel = uilabel(app.GridLayout3_2);
            app.OutputFileLabel.Layout.Row = 1;
            app.OutputFileLabel.Layout.Column = 1;
            app.OutputFileLabel.Text = 'Output File:';

            % Create EditField
            app.EditField = uieditfield(app.GridLayout3_2, 'text');
            app.EditField.Placeholder = 'Tidal file';
            app.EditField.Layout.Row = 1;
            app.EditField.Layout.Column = 2;
            app.EditField.Value = 'chess_tidal_file.csv';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = NOAATidesPredictionsUI(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

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
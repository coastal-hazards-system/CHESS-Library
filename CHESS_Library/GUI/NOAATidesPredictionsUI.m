classdef NOAATidesPredictionsUI < matlab.apps.AppBase
%{
    %% DESCRIPTION
        CHESS tide file from NOAA CO-OPS harmonic tide predictions (plain
        .m app, no .mlapp). Harmonic ('R') stations only
        (noaa_station_catalog.m); two dropdowns (Filter by / filter value, e.g.
        state or territory with station counts) narrow the station list;
        stations outside US states are grouped as Other and listed last.
        Datums from noaa_station_details.m (MSL by
        default; the user's datum is kept when switching stations if the
        new station offers it). Get Data writes one year of hourly
        predictions (create_tide_file.m) to <project>\<name>\Tides\<file>.csv
        and adds the file to wProj.tide_files_list.

    %% INPUTS
        wProj: Active CHESS project (chessProject). | handle
        parent_fig: (Optional) Window this UI opens centered on ([]:
            screen). | matlab.ui.Figure

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        MainGrid                    matlab.ui.container.GridLayout
        StationSectionLabel         matlab.ui.control.Label
        FilterLabel                 matlab.ui.control.Label
        FilterGrid                  matlab.ui.container.GridLayout
        FilterTypeDropDown          matlab.ui.control.DropDown
        FilterValueDropDown         matlab.ui.control.DropDown
        StationCountLabel           matlab.ui.control.Label
        StationLabel                matlab.ui.control.Label
        StationDropDown             matlab.ui.control.DropDown
        VerticalDatumLabel          matlab.ui.control.Label
        VerticalDatumDropDown       matlab.ui.control.DropDown
        DataRangeSectionLabel       matlab.ui.control.Label
        StartDateLabel              matlab.ui.control.Label
        DateRangeGrid               matlab.ui.container.GridLayout
        StartDatePicker             matlab.ui.control.DatePicker
        EndDateLabel                matlab.ui.control.Label
        EndDatePicker               matlab.ui.control.DatePicker
        OutputSectionLabel          matlab.ui.control.Label
        OutputFileLabel             matlab.ui.control.Label
        OutputFileEditField         matlab.ui.control.EditField
        RequestGrid                 matlab.ui.container.GridLayout
        GetDataButton               matlab.ui.control.Button
        ProgressAxes                matlab.ui.control.UIAxes
    end

    properties (Access = private)
        wProj % Active CHESS Project (Tide Files Are Saved In <project>\Tides And Added To wProj.tide_files_list)
        stations % NOAA Harmonic Tide Prediction Stations, Sorted By State Code (Stations Outside US States Last) Then Name (Library: noaa_station_catalog)
        datumsStationId = '' % Station Whose Datums Fill VerticalDatumDropDown ('': None Shown)
        stationDatums % Datums Already Loaded This Session, By Station Id (No Repeated Request When A Station Is Shown Again)
        preferredDatum = 'MSL' % Datum Kept When Switching Stations (Last User Choice)
        autoFileName % Last Output File Name Set Automatically (User Edits Are Kept)
        progressPatch % Progress Bar Patch In ProgressAxes
        progressText % Progress Bar Label
    end

    methods (Access = private)

        function set_progress(app, fraction, message)
            % Progress Bar (0-1) With Label (Default Label: Percentage)
            if nargin < 3
                message = sprintf('%.0f%%', 100*fraction);
            end
            app.progressPatch.XData = [0 fraction fraction 0];
            app.progressText.String = message;
            drawnow;
        end

        function group_keys = station_group_keys(app, filter_id)
            % Group Of Each Station For A Filter Type (To Add A Filter Type: Add Its Item In createComponents, A Case
            % Here And A Case In filter_group_label)
            switch filter_id
                case 'state'
                    group_keys = app.stations.state;
                    group_keys(group_keys == "") = "OTHER";
                otherwise
                    group_keys = repmat("ALL", height(app.stations), 1);
            end
        end

        function label = filter_group_label(app, filter_id, group_key, n_stations) %#ok<INUSL>
            % Filter Value Dropdown Text: Group Name With Its Station Count
            switch filter_id
                case 'state'
                    if group_key == "OTHER"
                        label = sprintf('Other (outside US states) (%d stations)', n_stations);
                    else
                        label = sprintf('%s - %s (%d stations)', group_key, NOAATidesPredictionsUI.state_name(group_key), n_stations);
                    end
                otherwise
                    label = 'All';
            end
        end

        function populate_filter_values(app)
            % Unique Options Of The Selected Filter Type (Groups Sorted By Code, Other Last)
            filter_id = app.FilterTypeDropDown.Value;
            if strcmp(filter_id, 'all')
                app.FilterValueDropDown.Items = {'All'};
                app.FilterValueDropDown.ItemsData = {'ALL'};
                app.FilterValueDropDown.Enable = 'off';
                return
            end
            group_keys = app.station_group_keys(filter_id);
            [unique_keys, ~, group_index] = unique(group_keys);
            counts = accumarray(group_index, 1);
            [~, order] = sort(unique_keys == "OTHER"); % Stable: Other Last
            unique_keys = unique_keys(order);
            counts = counts(order);
            labels = cell(numel(unique_keys), 1);
            for k = 1:numel(unique_keys)
                labels{k} = app.filter_group_label(filter_id, unique_keys(k), counts(k));
            end
            app.FilterValueDropDown.Items = labels;
            app.FilterValueDropDown.ItemsData = cellstr(unique_keys);
            app.FilterValueDropDown.Enable = 'on';
        end

        function filter_stations(app)
            % Station List Limited To The Selected Filter Value. The Selected Station Is Kept While Visible; Otherwise The
            % First One Is Selected. Its Datums Are Loaded (Cache Used)
            all_stations = app.stations;
            filter_id = app.FilterTypeDropDown.Value;
            if strcmp(filter_id, 'all')
                visible = true(height(all_stations), 1);
            else
                visible = app.station_group_keys(filter_id) == string(app.FilterValueDropDown.Value);
            end
            app.StationCountLabel.Text = sprintf('%d of %d stations', nnz(visible), height(all_stations));
            previous_id = app.StationDropDown.Value;
            shown = all_stations(visible, :);
            state = shown.state;
            state(state == "") = "Other";
            app.StationDropDown.Items = cellstr(state + " - " + shown.name + " (" + shown.id + ")");
            app.StationDropDown.ItemsData = cellstr(shown.id);
            app.StationDropDown.Enable = 'on';
            if ischar(previous_id) && any(strcmp(app.StationDropDown.ItemsData, previous_id))
                app.StationDropDown.Value = previous_id;
            end
            app.load_station_datums();
        end

        function clear_datums(app)
            % No Datums Shown (No Download Until A Station's Datums Are Loaded)
            app.datumsStationId = '';
            app.VerticalDatumDropDown.ItemsData = {};
            app.VerticalDatumDropDown.Items = {'-'};
            app.GetDataButton.Enable = 'off';
        end

        function show_datums(app, station_id)
            % Datums Of A Loaded Station (Display Name And Value; The Request Uses api_code). Datum: The User's Last
            % Choice If Offered, Else MSL
            datums = app.stationDatums(station_id);
            app.VerticalDatumDropDown.Items = cellstr(compose('%s (%.3f m)', datums.name, datums.value));
            app.VerticalDatumDropDown.ItemsData = cellstr(datums.api_code);
            if any(strcmp(app.VerticalDatumDropDown.ItemsData, app.preferredDatum))
                app.VerticalDatumDropDown.Value = app.preferredDatum;
            elseif any(strcmp(app.VerticalDatumDropDown.ItemsData, 'MSL'))
                app.VerticalDatumDropDown.Value = 'MSL';
            end
            app.datumsStationId = station_id;
            app.GetDataButton.Enable = 'on';
            app.update_file_name();
        end

        function load_station_datums(app)
            % Datums Available At The Selected Station (Library: noaa_station_details). The Datum Must Match The CHS
            % Data Datum.
            station_id = app.StationDropDown.Value;
            if strcmp(station_id, app.datumsStationId)
                return
            end
            app.clear_datums();
            if isempty(station_id)
                return
            end
            if isKey(app.stationDatums, station_id)
                app.show_datums(station_id);
                return
            end
            app.UIFigure.Pointer = 'watch';
            drawnow;
            try
                details = noaa_station_details(station_id, struct('greatlakes', false, 'harmonic_predictions', true,...
                    'water_level_inventory', false)); % Datums Only (No Water Level Inventory Request)
                datums = details.datums;
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
                return
            end
            app.stationDatums(station_id) = datums;
            if strcmp(app.StationDropDown.Value, station_id) % Another Station May Have Been Picked Meanwhile
                app.show_datums(station_id);
            end
        end

        function update_file_name(app)
            % Default Output File Name: <station>_<datum>_<start year>.csv (Unless The User Typed A Name)
            if isempty(app.datumsStationId) || isempty(app.VerticalDatumDropDown.ItemsData)
                return
            end
            name = sprintf('%s_%s_%s.csv', app.datumsStationId, app.VerticalDatumDropDown.Value,...
                char(string(app.StartDatePicker.Value, 'yyyy')));
            if isempty(app.autoFileName) || strcmp(app.OutputFileEditField.Value, app.autoFileName)...
                    || strcmp(app.OutputFileEditField.Value, 'chess_tidal_file.csv')
                app.OutputFileEditField.Value = name;
            end
            app.autoFileName = name;
        end
    end

    methods (Static, Access = private)

        function name = state_name(code)
            % Full Name Of A US State, Territory Or Freely Associated State Code (Unknown Codes: The Code)
            codes = ["AL" "AK" "AZ" "AR" "CA" "CO" "CT" "DE" "DC" "FL" "GA" "HI" "ID" "IL" "IN" "IA" "KS" "KY" "LA" "ME" "MD"...
                "MA" "MI" "MN" "MS" "MO" "MT" "NE" "NV" "NH" "NJ" "NM" "NY" "NC" "ND" "OH" "OK" "OR" "PA" "RI" "SC" "SD" "TN"...
                "TX" "UT" "VT" "VA" "WA" "WV" "WI" "WY" "PR" "VI" "GU" "AS" "FM" "MP" "MH" "PW"];
            names = ["Alabama" "Alaska" "Arizona" "Arkansas" "California" "Colorado" "Connecticut" "Delaware"...
                "District of Columbia" "Florida" "Georgia" "Hawaii" "Idaho" "Illinois" "Indiana" "Iowa" "Kansas" "Kentucky"...
                "Louisiana" "Maine" "Maryland" "Massachusetts" "Michigan" "Minnesota" "Mississippi" "Missouri" "Montana"...
                "Nebraska" "Nevada" "New Hampshire" "New Jersey" "New Mexico" "New York" "North Carolina" "North Dakota" "Ohio"...
                "Oklahoma" "Oregon" "Pennsylvania" "Rhode Island" "South Carolina" "South Dakota" "Tennessee" "Texas" "Utah"...
                "Vermont" "Virginia" "Washington" "West Virginia" "Wisconsin" "Wyoming" "Puerto Rico" "US Virgin Islands" "Guam"...
                "American Samoa" "Micronesia" "Northern Mariana Islands" "Marshall Islands" "Palau"];
            name = char(code);
            hit = find(codes == string(code), 1);
            if ~isempty(hit)
                name = char(names(hit));
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, wProj, parent_fig)
            if nargin < 3
                parent_fig = [];
            end
            center_on_parent(auxUIFunctions(), app.UIFigure, parent_fig);
            app.wProj = wProj;
            app.stationDatums = containers.Map('KeyType', 'char', 'ValueType', 'any');
            app.GetDataButton.Enable = 'off'; % Enabled Once A Station And Its Datums Are Loaded
            % Progress Bar
            ax = app.ProgressAxes;
            ax.XLim = [0 1];
            ax.YLim = [0 1];
            hold(ax, 'on');
            app.progressPatch = patch(ax, [0 0 0 0], [0 0 1 1], [0.30 0.60 0.85], 'EdgeColor', 'none');
            app.progressText = text(ax, 0.5, 0.5, '', 'HorizontalAlignment', 'center', 'FontSize', 10);
            % Data Range: 1 Year From The Start Date (create_tide_file)
            app.StartDatePicker.Value = dateshift(datetime('today'), 'start', 'year');
            app.StartDatePickerValueChanged([]);
            % Harmonic Tide Prediction Stations (Library: noaa_station_catalog)
            app.UIFigure.Pointer = 'watch';
            drawnow;
            try
                catalog = noaa_station_catalog(struct('lists', {{'tidepredictions'}}));
            catch me
                app.UIFigure.Pointer = 'arrow';
                app.StationDropDown.Items = {'-'};
                app.StationDropDown.Enable = 'off';
                app.FilterTypeDropDown.Enable = 'off';
                app.FilterValueDropDown.Enable = 'off';
                app.clear_datums();
                uialert(app.UIFigure, ['Could not load NOAA tidal prediction stations (check the internet connection): ' me.message],...
                    'NOAA Stations');
                return
            end
            app.UIFigure.Pointer = 'arrow';
            station_table = catalog(catalog.harmonic_predictions, :);
            station_table.is_other = station_table.state == ""; % Stations Outside US States Sort Last
            station_table = sortrows(station_table, {'is_other', 'state', 'name'});
            app.stations = removevars(station_table, 'is_other');
            app.populate_filter_values();
            app.filter_stations();
        end

        % Value changed function: FilterTypeDropDown
        function FilterTypeDropDownValueChanged(app, event)
            app.populate_filter_values();
            app.filter_stations();
        end

        % Value changed function: FilterValueDropDown
        function FilterValueDropDownValueChanged(app, event)
            app.filter_stations();
        end

        % Value changed function: StationDropDown
        function StationDropDownValueChanged(app, event)
            app.load_station_datums();
        end

        % Value changed function: VerticalDatumDropDown
        function VerticalDatumDropDownValueChanged(app, event)
            app.preferredDatum = app.VerticalDatumDropDown.Value;
            app.update_file_name();
        end

        % Value changed function: StartDatePicker
        function StartDatePickerValueChanged(app, event)
            % End Date = Start + 1 Year - 1 Day (create_tide_file Downloads One Year)
            if isnat(app.StartDatePicker.Value)
                app.StartDatePicker.Value = dateshift(datetime('today'), 'start', 'year');
            end
            app.EndDatePicker.Value = app.StartDatePicker.Value + calyears(1) - caldays(1);
            app.update_file_name();
        end

        % Button pushed function: GetDataButton
        function GetDataButtonPushed(app, event)
            % Download One Year Of Hourly Predictions (Library: create_tide_file) Into <project>\Tides
            [~, name, ~] = fileparts(strtrim(app.OutputFileEditField.Value));
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
                create_tide_file(app.datumsStationId, app.VerticalDatumDropDown.Value,...
                    char(string(app.StartDatePicker.Value, 'yyyyMMdd')), out_file,...
                    @(varargin) app.set_progress(varargin{:}), struct('harmonic_predictions', true));
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
            app.UIFigure.Position = [100 100 560 360];
            app.UIFigure.Name = 'NOAA Tide Predictions';

            % Create MainGrid
            app.MainGrid = uigridlayout(app.UIFigure);
            app.MainGrid.ColumnWidth = {'fit', '1x'};
            app.MainGrid.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 30};

            % Create StationSectionLabel
            app.StationSectionLabel = uilabel(app.MainGrid);
            app.StationSectionLabel.FontSize = 16;
            app.StationSectionLabel.FontWeight = 'bold';
            app.StationSectionLabel.Layout.Row = 1;
            app.StationSectionLabel.Layout.Column = [1 2];
            app.StationSectionLabel.Text = 'NOAA Harmonic Tide Prediction Station';

            % Create FilterLabel
            app.FilterLabel = uilabel(app.MainGrid);
            app.FilterLabel.Layout.Row = 2;
            app.FilterLabel.Layout.Column = 1;
            app.FilterLabel.Text = 'Filter by:';

            % Create FilterGrid
            app.FilterGrid = uigridlayout(app.MainGrid);
            app.FilterGrid.ColumnWidth = {160, '1x'};
            app.FilterGrid.RowHeight = {'fit'};
            app.FilterGrid.Padding = [0 0 0 0];
            app.FilterGrid.Layout.Row = 2;
            app.FilterGrid.Layout.Column = 2;

            % Create FilterTypeDropDown
            app.FilterTypeDropDown = uidropdown(app.FilterGrid);
            app.FilterTypeDropDown.Items = {'All stations', 'State / territory'};
            app.FilterTypeDropDown.ItemsData = {'all', 'state'};
            app.FilterTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @FilterTypeDropDownValueChanged, true);
            app.FilterTypeDropDown.Layout.Row = 1;
            app.FilterTypeDropDown.Layout.Column = 1;

            % Create FilterValueDropDown
            app.FilterValueDropDown = uidropdown(app.FilterGrid);
            app.FilterValueDropDown.Items = {'All'};
            app.FilterValueDropDown.ItemsData = {'ALL'};
            app.FilterValueDropDown.Enable = 'off';
            app.FilterValueDropDown.ValueChangedFcn = createCallbackFcn(app, @FilterValueDropDownValueChanged, true);
            app.FilterValueDropDown.Layout.Row = 1;
            app.FilterValueDropDown.Layout.Column = 2;

            % Create StationCountLabel
            app.StationCountLabel = uilabel(app.MainGrid);
            app.StationCountLabel.FontColor = [0.4 0.4 0.4];
            app.StationCountLabel.Layout.Row = 3;
            app.StationCountLabel.Layout.Column = 2;
            app.StationCountLabel.Text = '';

            % Create StationLabel
            app.StationLabel = uilabel(app.MainGrid);
            app.StationLabel.Layout.Row = 4;
            app.StationLabel.Layout.Column = 1;
            app.StationLabel.Text = 'Station:';

            % Create StationDropDown
            app.StationDropDown = uidropdown(app.MainGrid);
            app.StationDropDown.ValueChangedFcn = createCallbackFcn(app, @StationDropDownValueChanged, true);
            app.StationDropDown.Items = {'-'};
            app.StationDropDown.Layout.Row = 4;
            app.StationDropDown.Layout.Column = 2;

            % Create VerticalDatumLabel
            app.VerticalDatumLabel = uilabel(app.MainGrid);
            app.VerticalDatumLabel.Layout.Row = 5;
            app.VerticalDatumLabel.Layout.Column = 1;
            app.VerticalDatumLabel.Text = 'Vertical Datum:';

            % Create VerticalDatumDropDown
            app.VerticalDatumDropDown = uidropdown(app.MainGrid);
            app.VerticalDatumDropDown.ValueChangedFcn = createCallbackFcn(app, @VerticalDatumDropDownValueChanged, true);
            app.VerticalDatumDropDown.Items = {'-'};
            app.VerticalDatumDropDown.Tooltip = 'Must match the datum of the storm (CHS) data';
            app.VerticalDatumDropDown.Layout.Row = 5;
            app.VerticalDatumDropDown.Layout.Column = 2;

            % Create DataRangeSectionLabel
            app.DataRangeSectionLabel = uilabel(app.MainGrid);
            app.DataRangeSectionLabel.FontSize = 16;
            app.DataRangeSectionLabel.FontWeight = 'bold';
            app.DataRangeSectionLabel.Layout.Row = 6;
            app.DataRangeSectionLabel.Layout.Column = [1 2];
            app.DataRangeSectionLabel.Text = 'Data Range (One Year, UTC)';

            % Create StartDateLabel
            app.StartDateLabel = uilabel(app.MainGrid);
            app.StartDateLabel.Layout.Row = 7;
            app.StartDateLabel.Layout.Column = 1;
            app.StartDateLabel.Text = 'Start Date:';

            % Create DateRangeGrid
            app.DateRangeGrid = uigridlayout(app.MainGrid);
            app.DateRangeGrid.ColumnWidth = {'1x', 'fit', '1x'};
            app.DateRangeGrid.RowHeight = {'fit'};
            app.DateRangeGrid.Padding = [0 0 0 0];
            app.DateRangeGrid.Layout.Row = 7;
            app.DateRangeGrid.Layout.Column = 2;

            % Create StartDatePicker
            app.StartDatePicker = uidatepicker(app.DateRangeGrid);
            app.StartDatePicker.Limits = [datetime([0 1 5]) datetime([9999 12 31])];
            app.StartDatePicker.DisplayFormat = 'uuuu-MMM-dd';
            app.StartDatePicker.ValueChangedFcn = createCallbackFcn(app, @StartDatePickerValueChanged, true);
            app.StartDatePicker.Layout.Row = 1;
            app.StartDatePicker.Layout.Column = 1;

            % Create EndDateLabel
            app.EndDateLabel = uilabel(app.DateRangeGrid);
            app.EndDateLabel.Layout.Row = 1;
            app.EndDateLabel.Layout.Column = 2;
            app.EndDateLabel.Text = 'End Date:';

            % Create EndDatePicker
            app.EndDatePicker = uidatepicker(app.DateRangeGrid);
            app.EndDatePicker.Limits = [datetime([0 1 5]) datetime([9999 12 31])];
            app.EndDatePicker.DisplayFormat = 'uuuu-MMM-dd';
            app.EndDatePicker.Enable = 'off';
            app.EndDatePicker.Layout.Row = 1;
            app.EndDatePicker.Layout.Column = 3;

            % Create OutputSectionLabel
            app.OutputSectionLabel = uilabel(app.MainGrid);
            app.OutputSectionLabel.FontSize = 16;
            app.OutputSectionLabel.FontWeight = 'bold';
            app.OutputSectionLabel.Layout.Row = 8;
            app.OutputSectionLabel.Layout.Column = [1 2];
            app.OutputSectionLabel.Text = 'Tide File';

            % Create OutputFileLabel
            app.OutputFileLabel = uilabel(app.MainGrid);
            app.OutputFileLabel.Layout.Row = 9;
            app.OutputFileLabel.Layout.Column = 1;
            app.OutputFileLabel.Text = 'Output File:';

            % Create OutputFileEditField
            app.OutputFileEditField = uieditfield(app.MainGrid, 'text');
            app.OutputFileEditField.Placeholder = 'Tidal file';
            app.OutputFileEditField.Layout.Row = 9;
            app.OutputFileEditField.Layout.Column = 2;
            app.OutputFileEditField.Value = 'chess_tidal_file.csv';

            % Create RequestGrid
            app.RequestGrid = uigridlayout(app.MainGrid);
            app.RequestGrid.ColumnWidth = {100, '1x'};
            app.RequestGrid.RowHeight = {30};
            app.RequestGrid.ColumnSpacing = 5;
            app.RequestGrid.Padding = [0 0 0 0];
            app.RequestGrid.Layout.Row = 10;
            app.RequestGrid.Layout.Column = [1 2];

            % Create GetDataButton
            app.GetDataButton = uibutton(app.RequestGrid, 'push');
            app.GetDataButton.ButtonPushedFcn = createCallbackFcn(app, @GetDataButtonPushed, true);
            app.GetDataButton.Layout.Row = 1;
            app.GetDataButton.Layout.Column = 1;
            app.GetDataButton.Text = 'Get Data';

            % Create ProgressAxes
            app.ProgressAxes = uiaxes(app.RequestGrid);
            app.ProgressAxes.XTick = [0 0.2 0.4 0.6 0.8 1];
            app.ProgressAxes.XTickLabel = '';
            app.ProgressAxes.YTickLabel = '';
            app.ProgressAxes.TickDir = 'none';
            app.ProgressAxes.GridColor = 'none';
            app.ProgressAxes.MinorGridColor = 'none';
            app.ProgressAxes.Box = 'on';
            app.ProgressAxes.Layout.Row = 1;
            app.ProgressAxes.Layout.Column = 2;
            app.ProgressAxes.Tag = 'progress_bar';

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

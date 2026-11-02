function [data_table] = create_tide_file(station, datum, start_date, outName, progress_fcn, options)
%{
    %% DESCRIPTION
        Downloads one year of hourly NOAA CO-OPS harmonic tide predictions
        of one station and writes the CHESS tide file (CSV with columns
        Date, Prediction [m]; read by read_tide_series.m). The tide is
        added directly to the storm water levels (apply_random_tide.m),
        so the datum must match the datum of the storm (CHS) data.
        Span: start_date 00:00 through start_date + 1 year - 1 day 23:00
        (UTC), one row per hour (8760 rows, 8784 over a leap day).
        Request: one hourly ('h') predictions request through
        download_noaa_tide_predictions.m. The hourly values are the
        on-the-hour points of the 6-minute series (the older tool
        interpolated 6-minute requests to the hour, with the same result).
        Harmonic ('R') stations only (noaa_station_catalog.m
        harmonic_predictions); NOAA rejects subordinate stations. The
        harmonic flag is options.harmonic_predictions when given, else the
        station's flag in the noaa_station_catalog.m tidepredictions list
        (one extra request; a station not in the list is not harmonic). A
        station that is not harmonic raises noaa:notHarmonic
        (download_noaa_tide_predictions.m) and sends no prediction request.
        Errors: NOAA rejections and connection problems raise
        noaa:requestFailed / noaa:noConnection with NOAA's message. A reply
        that misses any hour of the year raises
        create_tide_file:missingHours and no file is written (a short tide
        file would shorten the tide record CHESS samples from).
        Station locations: <a href="matlab: web('https://tidesandcurrents.noaa.gov/stations.html?type=Water+Levels')">NOAA stations</a>.

    %% INPUTS
        station: NOAA CO-OPS station id (e.g. '8638660'). | char/string
        datum: Data API datum code (e.g. 'MSL', 'MLLW', 'NAVD'); datums
            endpoint names are accepted (noaa_datum_code.m: 'NAVD88' for
            'NAVD', 'GL_LWD' for 'LWD'). | char/string
        start_date: Start date (UTC), 'yyyyMMdd' text. | char/string
        outName: Output file name and location (.csv). | char/string
        progress_fcn: (Optional) Function handle called as
            progress_fcn(fraction, message) with fraction 0-1 and a short
            status text (e.g. to update a progress bar). | function_handle
        options: (Optional) Struct with the field | struct
            harmonic_predictions: true for a harmonic ('R') station (e.g.
                the caller already holds the catalog flag); when missing
                the station is looked up in noaa_station_catalog.m. | logical

    %% OUTPUTS
        data_table: Hourly predictions written to outName: Date
            (datetime, UTC without time zone), Prediction [m] (on the
            datum). | table

    %% EXAMPLE
        data = create_tide_file('8423898', 'MSL', '20260101', 'chess_tidal_file.csv');

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin < 5
    progress_fcn = [];
end
if nargin < 6 || isempty(options)
    options = struct();
end
station = char(station);
datum = noaa_datum_code(char(datum));

first_date = datetime(start_date, 'InputFormat', 'yyyyMMdd');
last_hour = first_date + calyears(1) - caldays(1) + hours(23);
target_date = (first_date : hours(1) : last_hour)';

% Harmonic Flag: Given By The Caller, Else The Tide Prediction Station Catalog
if isfield(options, 'harmonic_predictions')
    harmonic_predictions = options.harmonic_predictions;
else
    report_progress(progress_fcn, 0, 'Checking the station...');
    catalog = noaa_station_catalog(struct('lists', {{'tidepredictions'}}));
    harmonic_predictions = any(catalog.id == string(station) & catalog.harmonic_predictions);
end

report_progress(progress_fcn, 0, 'Requesting predictions...');
predictions = download_noaa_tide_predictions(station, datum, first_date, last_hour, 'h',...
    struct('harmonic_predictions', harmonic_predictions));

target_utc = target_date;
target_utc.TimeZone = 'UTC';
[found, prediction_row] = ismember(target_utc, predictions.DateTime);
if ~all(found)
    missing_hours = target_date(~found);
    error('create_tide_file:missingHours',...
        'NOAA returned %d of %d hourly predictions for station %s (datum %s); first missing hour %s UTC. No tide file was written.',...
        nnz(found), numel(target_date), station, datum, char(missing_hours(1), 'yyyy-MM-dd HH:mm'));
end
data_table = table(target_date, predictions.Prediction(prediction_row), 'VariableNames', {'Date', 'Prediction [m]'});

report_progress(progress_fcn, 0.9, 'Writing tide file...');
writetable(data_table, outName);
report_progress(progress_fcn, 1, 'Done');
end

function report_progress(progress_fcn, fraction, message)
if ~isempty(progress_fcn)
    progress_fcn(fraction, message);
end
end

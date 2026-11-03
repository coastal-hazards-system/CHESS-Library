function [data_table] = create_tide_file(station, datum, start_date, outName, progress_fcn, options)
% create_tide_file  Write a CHESS tide file from NOAA tide predictions.
%   data_table = create_tide_file(station, datum, start_date, outName)
%   data_table = create_tide_file(..., progress_fcn, options)
%
%   Downloads one year of hourly NOAA CO-OPS harmonic tide predictions of
%   one station and writes the CHESS tide file (CSV with columns Date,
%   Prediction [m]; read by read_tide_series). The tide is added directly
%   to the storm water levels (apply_random_tide), so the datum must match
%   the datum of the storm (CHS) data.
%   Span: start_date 00:00 through start_date + 1 year - 1 day 23:00
%   (UTC), one row per hour (8760 rows, 8784 over a leap day).
%   Request: hourly ('h') predictions through
%   download_noaa_tide_predictions (one request for one year). The hourly
%   values are the on-the-hour points of the 6-minute series.
%   Harmonic ('R') stations only (noaa_station_catalog
%   harmonic_predictions); NOAA rejects subordinate stations. The harmonic
%   flag is options.harmonic_predictions when given, else the station's
%   flag in the noaa_station_catalog tidepredictions list (one extra
%   request; a station not in the list is not harmonic). A station that
%   is not harmonic raises noaa:notHarmonic
%   (download_noaa_tide_predictions) and sends no prediction request.
%   Datums: whatever the station supports; noaa_station_details(station)
%   lists them (datums table: name, description, api_code, value [m]).
%   Errors: NOAA rejections and connection problems raise
%   noaa:requestFailed / noaa:noConnection with NOAA's message. A reply
%   that misses any hour of the year raises create_tide_file:missingHours
%   and no file is written (a short tide file would shorten the tide
%   record CHESS samples from).
%   Station locations: <a href="matlab: web('https://tidesandcurrents.noaa.gov/stations.html?type=Water+Levels')">NOAA stations</a>.
%
%   Example:
%     data = create_tide_file('8423898', 'MSL', '20260101', 'chess_tidal_file.csv');
%
%   Inputs:
%     station      - NOAA CO-OPS station id (e.g. '8638660'), char or
%                    string
%     datum        - Data API datum code, one the station offers (see
%                    noaa_station_details): CRD, IGLD, LWD, MHHW, MHW,
%                    MTL, MSL, MLLW, MLW, NAVD or STND. The datums
%                    endpoint names NAVD88 and GL_LWD are also accepted
%                    (noaa_datum_code maps them to NAVD and LWD), char or
%                    string
%     start_date   - start date (UTC), 'yyyyMMdd' text, char or string
%     outName      - output file name and location (.csv), char or string
%     progress_fcn - (optional, default none; [] = none) called as
%                    progress_fcn(fraction, message), with fraction 0-1
%                    and a short status text (e.g. to update a progress
%                    bar), function_handle
%     options      - struct (optional; [] = default); fields (all
%                    optional):
%                      .harmonic_predictions - true for a harmonic ('R')
%                          station (e.g. the caller already holds the
%                          catalog flag), logical, default: the station's
%                          flag in noaa_station_catalog (one request)
%   Outputs:
%     data_table - hourly predictions written to outName, table: Date
%                  (datetime, UTC without time zone), 'Prediction [m]'
%                  (on the datum), double
%
%   Tier: public
%
%   See also download_noaa_tide_predictions, download_noaa_water_levels,
%   noaa_station_catalog, noaa_station_details, select_noaa_stations,
%   plot_noaa_stations, read_tide_series.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
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

function predictions = download_noaa_tide_predictions(station_id, datum, first, last, interval, options)
% download_noaa_tide_predictions  Download NOAA harmonic tide predictions.
%   predictions = download_noaa_tide_predictions(station_id, datum, first,
%       last, interval, options)
%
%   Downloads NOAA CO-OPS harmonic tide predictions of one station from
%   the data API (product=predictions, csv, time_zone=gmt, units=metric),
%   in requests of up to 3655 days (noaa_request_chunks), concatenated,
%   sorted and de-duplicated on DateTime.
%   Harmonic ('R') stations only: subordinate ('S') stations are never
%   used. The caller passes the catalog flag (noaa_station_catalog
%   harmonic_predictions) as options.harmonic_predictions; without it (or
%   with it false) the function raises noaa:notHarmonic and sends no
%   request. An interval outside the list below raises
%   noaa:unknownInterval.
%   A request answered with "no data" raises warning noaa:noDataInChunk;
%   any other NOAA error raises noaa:requestFailed.
%
%   Inputs:
%     station_id  - NOAA CO-OPS station id, char or string
%     datum       - Data API datum code (e.g. 'MSL', 'MLLW', 'NAVD'), one
%                   the station offers (see noaa_station_details). Sent as
%                   given: datums endpoint names (NAVD88, GL_LWD) are not
%                   converted here (noaa_datum_code does that), char or
%                   string
%     first, last - requested range (converted to UTC; a datetime without
%                   time zone is taken as UTC), datetime
%     interval    - prediction interval: '1', '6', '15', '30' [min], 'h'
%                   (hourly) or 'hilo' (high/low) (default 'h'; [] =
%                   default; the data API rejects 'hi' and 'lo'), char or
%                   string
%     options     - struct; fields:
%                     .harmonic_predictions - true for a harmonic ('R')
%                         station; required (missing, empty options or
%                         false raises noaa:notHarmonic), logical
%                     .web_options - options for noaa_web_request
%                         (optional), struct, default struct()
%   Outputs:
%     predictions - table: DateTime (UTC), Prediction [m, on the datum],
%                   plus Type (string) for 'hilo'
%
%   Tier: public
%
%   See also create_tide_file, download_noaa_water_levels,
%   noaa_station_catalog, noaa_station_details, select_noaa_stations,
%   plot_noaa_stations.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin < 5 || isempty(interval)
    interval = 'h';
end
if nargin < 6 || isempty(options)
    options = struct();
end
station_id = char(station_id);
interval = char(interval);
if ~(isfield(options, 'harmonic_predictions') && isequal(logical(options.harmonic_predictions), true))
    error('noaa:notHarmonic',...
        'Station %s is not a harmonic (''R'') tide prediction station; tide predictions are only downloaded for harmonic stations.',...
        station_id);
end
if ~ismember(interval, {'1', '6', '15', '30', 'h', 'hilo'})
    error('noaa:unknownInterval', 'Unknown tide prediction interval ''%s'' (use 1, 6, 15, 30, h or hilo).', interval);
end
web_options = struct();
if isfield(options, 'web_options')
    web_options = options.web_options;
end
first.TimeZone = 'UTC';
last.TimeZone = 'UTC';

endpoints = noaa_endpoints();
request_url = [endpoints.data_api '?station=' station_id '&product=predictions&datum=' char(datum)...
    '&interval=' interval '&time_zone=gmt&units=metric&application=NOS.COOPS.TAC.WL&format=csv'];
predictions = table(datetime.empty(0, 1), zeros(0, 1), 'VariableNames', {'DateTime', 'Prediction'});
predictions.DateTime.TimeZone = 'UTC';
if strcmp(interval, 'hilo')
    predictions.Type = strings(0, 1);
end
[chunk_first, chunk_last] = noaa_request_chunks(first, last, 'predictions');
chunk_tables = cell(numel(chunk_first), 1);
for chunk_index = 1:numel(chunk_first)
    reply_text = noaa_web_request([request_url...
        '&begin_date=' char(chunk_first(chunk_index), 'yyyyMMdd') '%20' char(chunk_first(chunk_index), 'HH:mm')...
        '&end_date=' char(chunk_last(chunk_index), 'yyyyMMdd') '%20' char(chunk_last(chunk_index), 'HH:mm')],...
        web_options);
    [chunk_tables{chunk_index}, no_data] = parse_noaa_csv(reply_text, 'Prediction');
    if no_data
        warning('noaa:noDataInChunk', 'Station %s predictions: no data from %s to %s (UTC).', station_id,...
            char(chunk_first(chunk_index), 'yyyy-MM-dd HH:mm'), char(chunk_last(chunk_index), 'yyyy-MM-dd HH:mm'));
    end
end
predictions = vertcat(predictions, chunk_tables{:});
[~, unique_rows] = unique(predictions.DateTime);
predictions = predictions(unique_rows, :);
end

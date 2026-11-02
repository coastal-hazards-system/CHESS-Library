function predictions = download_noaa_tide_predictions(station_id, datum, first, last, interval, options)
%{
    %% DESCRIPTION
        Downloads NOAA CO-OPS harmonic tide predictions of one station from
        the data API (product=predictions, csv, time_zone=gmt,
        units=metric), in requests of up to 3655 days
        (noaa_request_chunks.m), concatenated, sorted and de-duplicated on
        DateTime.
        Harmonic ('R') stations only: subordinate ('S') stations are never
        used. The caller passes the catalog flag
        (noaa_station_catalog.m harmonic_predictions) as
        options.harmonic_predictions; without it the function raises
        noaa:notHarmonic and sends no request.
        A request answered with "no data" raises warning noaa:noDataInChunk;
        any other NOAA error raises noaa:requestFailed.

    %% INPUTS
        station_id: NOAA CO-OPS station id. | char/string
        datum: Data API datum code (e.g. 'MSL', 'MLLW', 'NAVD'). | char/string
        first, last: Requested range (converted to UTC; a datetime without
            time zone is taken as UTC). | datetime
        interval: (Optional) Prediction interval: '1', '6', '15', '30',
            'h' (default) or 'hilo' (the data API rejects 'hi' and
            'lo'). | char/string
        options: Struct with the fields | struct
            harmonic_predictions: true for a harmonic ('R') station
                (required). | logical
            web_options: (Optional) Options for noaa_web_request.m. | struct

    %% OUTPUTS
        predictions: Table DateTime (UTC), Prediction [m on datum], plus
            Type for 'hilo'. | table

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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

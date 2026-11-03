function catalog = noaa_station_catalog(options)
% noaa_station_catalog  NOAA CO-OPS station catalog, fetched live.
%   catalog = noaa_station_catalog()
%   catalog = noaa_station_catalog(options)
%
%   NOAA CO-OPS station catalog, fetched live (no cache) from the bulk
%   station lists of the metadata API (stations.json?type=<list>, one
%   request per list):
%     historicwl: every water level station (historical and active).
%     waterlevels: active water level stations.
%     tidepredictions: tide prediction stations, harmonic ('R') and
%         subordinate ('S').
%   The requested lists are joined by station id (one row per station,
%   sorted by id). Subordinate ('S') prediction stations are never flagged
%   for predictions, and a station listed only as 'S' in tidepredictions
%   is not added as a row.
%   A flag whose list was not requested is false (e.g. with
%   options.lists = {'tidepredictions'} the catalog holds the harmonic
%   stations only, with has_water_levels and active false).
%   Stations that come only from tidepredictions have greatlakes = false
%   (no Great Lakes station has tide predictions) and tidal = true.
%   An unknown list name raises noaa:unknownList; a reply without a
%   stations field raises noaa:requestFailed.
%
%   Inputs:
%     options - struct (optional; [] = default); fields (all optional):
%                 .lists - lists to fetch, any of 'historicwl',
%                     'waterlevels', 'tidepredictions', cell or string,
%                     default all three
%                 .web_options - options for noaa_web_request, struct,
%                     default struct()
%   Outputs:
%     catalog - one row per station, table:
%                 id - station id, string
%                 name - station name, string
%                 state - state (may be empty), string
%                 lat - latitude [deg] (NaN when missing), double
%                 lon - longitude [deg] (NaN when missing), double
%                 greatlakes - Great Lakes station, logical
%                 tidal - tidal station, logical
%                 has_water_levels - in historicwl or waterlevels, logical
%                 active - in waterlevels, logical
%                 harmonic_predictions - harmonic ('R') tide prediction
%                     station, logical
%
%   Tier: public
%
%   See also create_tide_file, download_noaa_tide_predictions,
%   download_noaa_water_levels, noaa_station_details,
%   select_noaa_stations, plot_noaa_stations, noaa_station_list.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin < 1 || isempty(options)
    options = struct();
end
lists = {'historicwl', 'waterlevels', 'tidepredictions'};
if isfield(options, 'lists')
    lists = cellstr(options.lists);
end
unknown_lists = setdiff(lists, {'historicwl', 'waterlevels', 'tidepredictions'});
if ~isempty(unknown_lists)
    error('noaa:unknownList', 'Unknown NOAA station list(s): %s (use historicwl, waterlevels, tidepredictions).',...
        strjoin(unknown_lists, ', '));
end
web_options = struct();
if isfield(options, 'web_options')
    web_options = options.web_options;
end

endpoints = noaa_endpoints();
catalog = empty_catalog();
station_lists = struct();
for list_index = 1:numel(lists)
    list_name = lists{list_index};
    reply_text = noaa_web_request([endpoints.metadata_api '/stations.json?type=' list_name], web_options);
    reply = jsondecode(reply_text);
    if ~isfield(reply, 'stations')
        error('noaa:requestFailed', 'NOAA CO-OPS station list ''%s'' has no stations field.', list_name);
    end
    station_lists.(list_name) = list_table(reply.stations, list_name);
end

% Measured Water Level Stations (Historical First, Then Active Ones Missing From It)
for list_name = {'historicwl', 'waterlevels'}
    if ~isfield(station_lists, list_name{1})
        continue
    end
    stations = station_lists.(list_name{1});
    new_rows = stations(~ismember(stations.id, catalog.id), :);
    new_rows.has_water_levels = true(height(new_rows), 1);
    catalog = [catalog; new_rows(:, catalog.Properties.VariableNames)]; %#ok<AGROW>
end
if isfield(station_lists, 'waterlevels')
    catalog.active = ismember(catalog.id, station_lists.waterlevels.id);
end

% Harmonic Prediction Stations Only (Subordinate 'S' Never Flagged Or Added)
if isfield(station_lists, 'tidepredictions')
    stations = station_lists.tidepredictions;
    harmonic = stations(stations.type == "R", :);
    catalog.harmonic_predictions = ismember(catalog.id, harmonic.id);
    new_rows = harmonic(~ismember(harmonic.id, catalog.id), :);
    new_rows.harmonic_predictions = true(height(new_rows), 1);
    catalog = [catalog; new_rows(:, catalog.Properties.VariableNames)];
end
catalog = sortrows(catalog, 'id');
end

function catalog = empty_catalog()
catalog = table(strings(0, 1), strings(0, 1), strings(0, 1), zeros(0, 1), zeros(0, 1),...
    false(0, 1), false(0, 1), false(0, 1), false(0, 1), false(0, 1),...
    'VariableNames', {'id', 'name', 'state', 'lat', 'lon', 'greatlakes', 'tidal',...
    'has_water_levels', 'active', 'harmonic_predictions'});
end

function stations = list_table(station_records, list_name)
if isstruct(station_records)
    station_records = num2cell(station_records(:));
end
station_count = numel(station_records);
stations = table(text_field(station_records, 'id'), text_field(station_records, 'name'),...
    text_field(station_records, 'state'), number_field(station_records, 'lat'),...
    number_field(station_records, 'lng'), false(station_count, 1), false(station_count, 1),...
    false(station_count, 1), false(station_count, 1), false(station_count, 1),...
    'VariableNames', {'id', 'name', 'state', 'lat', 'lon', 'greatlakes', 'tidal',...
    'has_water_levels', 'active', 'harmonic_predictions'});
if strcmp(list_name, 'tidepredictions')
    stations.tidal = true(station_count, 1);
    stations.type = text_field(station_records, 'type');
else
    stations.greatlakes = logical_field(station_records, 'greatlakes');
    stations.tidal = logical_field(station_records, 'tidal');
end
[~, unique_rows] = unique(stations.id, 'stable');
stations = stations(unique_rows, :);
end

function values = text_field(station_records, field_name)
values = strings(numel(station_records), 1);
for record_index = 1:numel(station_records)
    record = station_records{record_index};
    if isfield(record, field_name) && ~isempty(record.(field_name))
        values(record_index) = string(record.(field_name));
    end
end
end

function values = number_field(station_records, field_name)
values = NaN(numel(station_records), 1);
for record_index = 1:numel(station_records)
    record = station_records{record_index};
    if isfield(record, field_name) && isnumeric(record.(field_name)) && isscalar(record.(field_name))
        values(record_index) = record.(field_name);
    end
end
end

function values = logical_field(station_records, field_name)
values = false(numel(station_records), 1);
for record_index = 1:numel(station_records)
    record = station_records{record_index};
    if isfield(record, field_name) && ~isempty(record.(field_name))
        values(record_index) = logical(record.(field_name));
    end
end
end

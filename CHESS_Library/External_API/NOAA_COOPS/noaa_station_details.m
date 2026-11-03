function details = noaa_station_details(station_id, options)
% noaa_station_details  Datums and data inventory of one NOAA station.
%   details = noaa_station_details(station_id)
%   details = noaa_station_details(station_id, options)
%
%   Live details (no cache) of one NOAA CO-OPS station:
%     datums: metadata API stations/<id>/datums.json?units=metric. The
%         values are already in meters (no conversion). Records without a
%         numeric value or a name are skipped, and only the datums the data
%         API accepts are kept (api_code CRD, IGLD, LWD, MHHW, MHW, MTL,
%         MSL, MLLW, MLW, NAVD, STND), with NAVD88 -> NAVD and
%         GL_LWD -> LWD (noaa_datum_code). Great Lakes stations get an
%         IGLD row (value 0) when NOAA does not list it: their datum
%         values are listed relative to IGLD (e.g. LWD = 176.0 m).
%     water_level_segments: XML data inventory
%         (parse_noaa_data_inventory); empty for predictions-only stations.
%     prediction_intervals: data API prediction intervals, only for
%         harmonic ('R') stations (options.harmonic_predictions true);
%         empty otherwise.
%   Great Lakes flag: taken from options.greatlakes when given and not
%   empty (e.g. the catalog row, noaa_station_catalog), which saves a
%   request; otherwise read from the station JSON (stations/<id>.json).
%   Requests: 2 (datums, inventory), plus 1 when options.greatlakes is not
%   given; 1 less with options.water_level_inventory false.
%
%   Inputs:
%     station_id - NOAA CO-OPS station id (e.g. '8518750'), char or string
%     options    - struct (optional; [] = default); fields (all optional):
%                    .greatlakes - Great Lakes station (skips the station
%                        JSON request), logical, default: read from the
%                        station JSON
%                    .harmonic_predictions - harmonic ('R') prediction
%                        station, from the catalog, logical, default false
%                    .water_level_inventory - request the XML water level
%                        inventory, logical, default true; false skips it
%                        (e.g. the tide file UI, which needs datums only)
%                        and water_level_segments is then empty
%                    .web_options - options for noaa_web_request, struct,
%                        default struct()
%   Outputs:
%     details - struct:
%                 id - station id, char
%                 greatlakes - Great Lakes station, logical
%                 datums - table: name, description, api_code (string) and
%                     value [m]
%                 water_level_segments - parse_noaa_data_inventory table
%                 prediction_intervals - table: value ('1', '6', '15',
%                     '30', 'h', 'hilo') and description (string); empty
%                     for non-harmonic stations. The data API answers 'hi'
%                     and 'lo' with "No Predictions data was found"
%                     (checked 2026-11-01), so they are not offered.
%
%   Tier: public
%
%   See also create_tide_file, download_noaa_tide_predictions,
%   download_noaa_water_levels, noaa_station_catalog,
%   select_noaa_stations, plot_noaa_stations, noaa_station_list.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin < 2 || isempty(options)
    options = struct();
end
web_options = struct();
if isfield(options, 'web_options')
    web_options = options.web_options;
end
station_id = char(station_id);
endpoints = noaa_endpoints();

if isfield(options, 'greatlakes') && ~isempty(options.greatlakes)
    greatlakes = logical(options.greatlakes);
else
    station_reply = jsondecode(noaa_web_request(...
        [endpoints.metadata_api '/stations/' station_id '.json'], web_options));
    greatlakes = false;
    if isfield(station_reply, 'stations') && ~isempty(station_reply.stations)
        station_record = station_reply.stations(1);
        if iscell(station_record)
            station_record = station_record{1};
        end
        greatlakes = isfield(station_record, 'greatlakes') && isequal(station_record.greatlakes, true);
    end
end

% Datums [m] Accepted By The Data API
datum_reply = jsondecode(noaa_web_request(...
    [endpoints.metadata_api '/stations/' station_id '/datums.json?units=metric'], web_options));
name = strings(0, 1);
description = strings(0, 1);
value = zeros(0, 1);
if isfield(datum_reply, 'datums') && ~isempty(datum_reply.datums)
    datum_records = datum_reply.datums;
    if isstruct(datum_records)
        datum_records = num2cell(datum_records(:));
    end
    for datum_index = 1:numel(datum_records)
        record = datum_records{datum_index};
        if ~isnumeric(record.value) || isempty(record.value) || isempty(record.name)
            continue
        end
        name(end + 1, 1) = string(record.name); %#ok<AGROW>
        description(end + 1, 1) = ""; %#ok<AGROW>
        if isfield(record, 'description') && ~isempty(record.description)
            description(end) = string(record.description);
        end
        value(end + 1, 1) = record.value; %#ok<AGROW>
    end
end
api_code = noaa_datum_code(name);
accepted_codes = ["CRD", "IGLD", "LWD", "MHHW", "MHW", "MTL", "MSL", "MLLW", "MLW", "NAVD", "STND"];
keep = ismember(api_code, accepted_codes);
datums = table(name(keep), description(keep), api_code(keep), value(keep),...
    'VariableNames', {'name', 'description', 'api_code', 'value'});
if greatlakes && ~any(datums.api_code == "IGLD")
    datums = [datums; table("IGLD", "International Great Lakes Datum", "IGLD", 0,...
        'VariableNames', {'name', 'description', 'api_code', 'value'})];
end

% Water Level Inventory Segments (Skipped With options.water_level_inventory = false)
if isfield(options, 'water_level_inventory') && isequal(logical(options.water_level_inventory), false)
    water_level_segments = parse_noaa_data_inventory('');
else
    water_level_segments = parse_noaa_data_inventory(noaa_web_request(...
        [endpoints.data_inventory '?stationId=' station_id '&format=xml'], web_options));
end

% Harmonic Prediction Intervals ('R' Stations Only)
prediction_intervals = table(strings(0, 1), strings(0, 1), 'VariableNames', {'value', 'description'});
if isfield(options, 'harmonic_predictions') && isequal(logical(options.harmonic_predictions), true)
    prediction_intervals = table(["1"; "6"; "15"; "30"; "h"; "hilo"],...
        ["1 min"; "6 min"; "15 min"; "30 min"; "1 hour"; "High/Low"],...
        'VariableNames', {'value', 'description'});
end

details = struct('id', station_id, 'greatlakes', greatlakes, 'datums', datums,...
    'water_level_segments', water_level_segments, 'prediction_intervals', prediction_intervals);
end

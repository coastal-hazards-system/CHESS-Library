function [StationList, not_found] = noaa_station_list(ids, options)
%{
    %% DESCRIPTION
        Builds the StationList (one element per station) used by
        noaa_water_level_downloader.m, live from NOAA CO-OPS (no cache):
        the catalog row (noaa_station_catalog.m) plus the station details
        (noaa_station_details.m: datums, inventory segments, prediction
        intervals). Loop over every catalog id to pull every station.
        Ids missing from the catalog are returned in not_found. A station
        whose details request is rejected by NOAA (noaa:requestFailed) keeps
        its catalog fields, with no datums and no water level products, and
        raises warning noaa:stationDetailsFailed; noaa:noConnection stops
        the loop.

    %% INPUTS
        ids: NOAA CO-OPS station ids. | cell/string/char
        options: (Optional) Struct with any of the fields | struct
            catalog: Station catalog (default: noaa_station_catalog with
                all three lists, fetched once). | table
            progress_fcn: Called as progress_fcn(station_index,
                station_count, id) before each station. | function_handle
            web_options: Options for noaa_web_request.m. | struct

    %% OUTPUTS
        StationList: Struct array with fields | struct
            id, name, state: Station id, name and state. | char
            lon, lat: Longitude and latitude [deg]. | double
            greatlakes: Great Lakes station. | logical
            active_indx: Active water level station. | logical
            datums: Struct array name, description, api_code, value [m]
                (noaa_station_details.m). | struct
            WL_products: NOAA product name of each inventory segment (e.g.
                'Verified Hourly Height Water Level'). | string
            WL_api_product: Data API product of each segment. | string
            WL_quality: 'verified' or 'preliminary' per segment. | string
            startDate, endDate: First and last time stamp of each segment
                (UTC). | datetime
            record_length: Span of each segment. | calendarDuration
            predictions_products: Struct array value, description of the
                prediction intervals (harmonic 'R' stations only; empty
                otherwise). | struct
            has_water_levels: Measured water level station. | logical
            harmonic_predictions: Harmonic ('R') prediction station. | logical
        not_found: Ids missing from the catalog. | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin < 2 || isempty(options)
    options = struct();
end
web_options = struct();
if isfield(options, 'web_options')
    web_options = options.web_options;
end
if isfield(options, 'catalog')
    catalog = options.catalog;
else
    catalog = noaa_station_catalog(struct('web_options', web_options));
end
ids = cellstr(ids);
ids = ids(:);
[in_catalog, catalog_row] = ismember(string(ids), catalog.id);
not_found = ids(~in_catalog);
catalog_row = catalog_row(in_catalog);

StationList = repmat(struct('id', '', 'name', '', 'lon', NaN, 'lat', NaN, 'state', '',...
    'greatlakes', false, 'active_indx', false, 'datums', struct([]),...
    'WL_products', strings(0, 1), 'WL_api_product', strings(0, 1), 'WL_quality', strings(0, 1),...
    'startDate', datetime.empty(0, 1), 'endDate', datetime.empty(0, 1),...
    'record_length', calendarDuration.empty(0, 1), 'predictions_products', struct([]),...
    'has_water_levels', false, 'harmonic_predictions', false), numel(catalog_row), 1);
for station_index = 1:numel(catalog_row)
    station = catalog(catalog_row(station_index), :);
    station_id = char(station.id);
    if isfield(options, 'progress_fcn') && ~isempty(options.progress_fcn)
        options.progress_fcn(station_index, numel(catalog_row), station_id);
    end
    StationList(station_index).id = station_id;
    StationList(station_index).name = char(station.name);
    StationList(station_index).lon = station.lon;
    StationList(station_index).lat = station.lat;
    StationList(station_index).state = char(station.state);
    StationList(station_index).greatlakes = station.greatlakes;
    StationList(station_index).active_indx = station.active;
    StationList(station_index).has_water_levels = station.has_water_levels;
    StationList(station_index).harmonic_predictions = station.harmonic_predictions;

    try
        details = noaa_station_details(station_id, struct('greatlakes', station.greatlakes,...
            'harmonic_predictions', station.harmonic_predictions, 'web_options', web_options));
    catch details_error
        if ~strcmp(details_error.identifier, 'noaa:requestFailed')
            rethrow(details_error);
        end
        warning('noaa:stationDetailsFailed', 'Station %s: details not available (%s).',...
            station_id, details_error.message);
        continue
    end
    StationList(station_index).datums = table2struct(details.datums);
    segments = details.water_level_segments;
    StationList(station_index).WL_products = segments.product_name;
    StationList(station_index).WL_api_product = segments.api_product;
    StationList(station_index).WL_quality = segments.quality;
    StationList(station_index).startDate = segments.first;
    StationList(station_index).endDate = segments.last;
    StationList(station_index).record_length = between(segments.first, segments.last);
    StationList(station_index).predictions_products = table2struct(details.prediction_intervals);
end
end

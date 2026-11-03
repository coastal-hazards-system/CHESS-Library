function [water_levels, windows] = download_noaa_water_levels(station_id, api_product, datum, first, last, options)
% download_noaa_water_levels  Download NOAA measured water levels.
%   water_levels = download_noaa_water_levels(station_id, api_product,
%       datum, first, last)
%   [water_levels, windows] = download_noaa_water_levels(..., options)
%
%   Downloads measured water levels of one NOAA CO-OPS station from the
%   data API (csv, time_zone=gmt, units=metric).
%     1. [first, last] is intersected with the station's inventory
%        segments of the product and quality (options.segments, or the
%        XML data inventory fetched live); overlapping windows are merged,
%        so no time is requested twice.
%     2. Each window is split into requests within NOAA's size limit
%        (noaa_request_chunks).
%     3. Replies are parsed (parse_noaa_csv), concatenated, sorted and
%        de-duplicated on DateTime.
%     4. Regular products (water_level 6 min, hourly_height 1 h,
%        daily_mean 1 day, monthly_mean 1 month) are put on a regular grid
%        from the first window start (rounded up to the step; start of the
%        month for monthly_mean) to the last window end; gaps (inside and
%        between windows) are NaN. high_low is never filled.
%   A request answered with "no data" leaves NaN on regular grids and
%   raises warning noaa:noDataInChunk. Any other NOAA error raises
%   noaa:requestFailed (noaa_web_request, parse_noaa_csv). An unknown
%   api_product raises noaa:unknownProduct.
%   No window (product not in the inventory, or no overlap with
%   [first, last]): empty table and no data request.
%
%   Inputs:
%     station_id  - NOAA CO-OPS station id, char or string
%     api_product - 'water_level', 'hourly_height', 'high_low',
%                   'daily_mean' or 'monthly_mean', char or string
%     datum       - Data API datum code (e.g. 'MSL', 'NAVD', 'IGLD'), one
%                   the station offers (see noaa_station_details). Sent as
%                   given: datums endpoint names (NAVD88, GL_LWD) are not
%                   converted here (noaa_datum_code does that), char or
%                   string
%     first, last - requested range (converted to UTC; a datetime without
%                   time zone is taken as UTC); [] for the start / end of
%                   the inventory, datetime
%     options     - struct (optional; [] = default); fields (all
%                   optional):
%                     .segments - inventory segments
%                         (parse_noaa_data_inventory layout: api_product,
%                         quality, first, last), table, default: the XML
%                         data inventory fetched live (one request)
%                     .quality - 'verified' or 'preliminary' (6-minute
%                         water_level only), char or string, default
%                         'verified'
%                     .web_options - options for noaa_web_request, struct,
%                         default struct()
%   Outputs:
%     water_levels - table: DateTime (UTC), WaterLevel [m, on the datum],
%                    plus Type (string) for high_low
%     windows      - downloaded windows, table: first, last (UTC)
%
%   Tier: public
%
%   See also create_tide_file, download_noaa_tide_predictions,
%   noaa_station_catalog, noaa_station_details, select_noaa_stations,
%   plot_noaa_stations, noaa_water_level_downloader.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin < 6 || isempty(options)
    options = struct();
end
web_options = struct();
if isfield(options, 'web_options')
    web_options = options.web_options;
end
quality = "verified";
if isfield(options, 'quality')
    quality = string(options.quality);
end
station_id = char(station_id);
api_product = char(api_product);
if ~ismember(api_product, {'water_level', 'hourly_height', 'high_low', 'daily_mean', 'monthly_mean'})
    error('noaa:unknownProduct', 'Unknown NOAA CO-OPS water level product ''%s''.', api_product);
end
endpoints = noaa_endpoints();

if isfield(options, 'segments')
    segments = options.segments;
else
    segments = parse_noaa_data_inventory(noaa_web_request(...
        [endpoints.data_inventory '?stationId=' station_id '&format=xml'], web_options));
end
segments = segments(segments.api_product == api_product & segments.quality == quality, :);

% Requested Range Intersected With The Inventory Segments
window_first = segments.first;
window_last = segments.last;
if ~isempty(first)
    window_first = max(window_first, as_utc(first));
end
if ~isempty(last)
    window_last = min(window_last, as_utc(last));
end
keep = window_first <= window_last;
windows = merge_windows(window_first(keep), window_last(keep));

water_levels = table(datetime.empty(0, 1), zeros(0, 1), 'VariableNames', {'DateTime', 'WaterLevel'});
water_levels.DateTime.TimeZone = 'UTC';
if strcmp(api_product, 'high_low')
    water_levels.Type = strings(0, 1);
end
if isempty(windows)
    return
end

% Requests
request_url = [endpoints.data_api '?station=' station_id '&product=' api_product...
    '&datum=' char(datum) '&time_zone=gmt&units=metric&application=NOS.COOPS.TAC.WL&format=csv'];
chunk_tables = {};
for window_index = 1:height(windows)
    [chunk_first, chunk_last] = noaa_request_chunks(windows.first(window_index),...
        windows.last(window_index), api_product);
    for chunk_index = 1:numel(chunk_first)
        reply_text = noaa_web_request([request_url...
            '&begin_date=' api_date(chunk_first(chunk_index))...
            '&end_date=' api_date(chunk_last(chunk_index))], web_options);
        [chunk_table, no_data] = parse_noaa_csv(reply_text, 'WaterLevel');
        if no_data
            warning('noaa:noDataInChunk', 'Station %s %s: no data from %s to %s (UTC).',...
                station_id, api_product, char(chunk_first(chunk_index), 'yyyy-MM-dd HH:mm'),...
                char(chunk_last(chunk_index), 'yyyy-MM-dd HH:mm'));
        end
        chunk_tables{end + 1, 1} = chunk_table; %#ok<AGROW>
    end
end
water_levels = vertcat(water_levels, chunk_tables{:});
[~, unique_rows] = unique(water_levels.DateTime);
water_levels = water_levels(unique_rows, :);

% NaN-Filled Regular Grid (Not For high_low)
if strcmp(api_product, 'high_low')
    return
end
grid_time = regular_grid(api_product, windows.first(1), windows.last(end));
grid_time = union(grid_time, water_levels.DateTime);
grid_level = NaN(numel(grid_time), 1);
[~, grid_rows] = ismember(water_levels.DateTime, grid_time);
grid_level(grid_rows) = water_levels.WaterLevel;
water_levels = table(grid_time, grid_level, 'VariableNames', {'DateTime', 'WaterLevel'});
end

function time = as_utc(time)
time.TimeZone = 'UTC';
end

function date_text = api_date(time)
date_text = [char(time, 'yyyyMMdd') '%20' char(time, 'HH:mm')];
end

function windows = merge_windows(window_first, window_last)
[window_first, order] = sort(window_first);
window_last = window_last(order);
merged_first = window_first([]);
merged_last = window_last([]);
for window_index = 1:numel(window_first)
    if ~isempty(merged_last) && window_first(window_index) <= merged_last(end)
        merged_last(end) = max(merged_last(end), window_last(window_index));
    else
        merged_first(end + 1, 1) = window_first(window_index); %#ok<AGROW>
        merged_last(end + 1, 1) = window_last(window_index); %#ok<AGROW>
    end
end
windows = table(merged_first(:), merged_last(:), 'VariableNames', {'first', 'last'});
end

function grid_time = regular_grid(api_product, window_first, window_last)
if strcmp(api_product, 'monthly_mean')
    grid_first = dateshift(window_first, 'start', 'month');
    month_count = calmonths(between(grid_first, dateshift(window_last, 'start', 'month'), 'months'));
    grid_time = grid_first + calmonths(0:month_count)';
    return
end
switch api_product
    case 'water_level'
        step = minutes(6);
    case 'hourly_height'
        step = hours(1);
    case 'daily_mean'
        step = days(1);
end
day_start = dateshift(window_first, 'start', 'day');
grid_first = day_start + step*ceil((window_first - day_start)/step);
grid_time = (grid_first:step:window_last)';
end

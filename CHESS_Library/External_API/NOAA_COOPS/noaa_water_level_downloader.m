function [Sdata, notFound] = noaa_water_level_downloader(idList, StationList, requested_datum, products, opMode, dBeg, dEnd)
% noaa_water_level_downloader  Download NOAA water levels of many stations.
%   [Sdata, notFound] = noaa_water_level_downloader(idList, StationList,
%       requested_datum, products, 1)
%   [Sdata, notFound] = noaa_water_level_downloader(idList, StationList,
%       requested_datum, products, 2, dBeg, dEnd)
%
%   Downloads NOAA CO-OPS measured water levels (and, next to 6-minute,
%   hourly and high/low data, harmonic tide predictions) for a list of
%   stations. Replaces WL_downloader_V2.m
%   (Retired\NOAA_Water_Level_Downloader\).
%   One Sdata element per (station, product), stations in idList order.
%   Prints one status line per element.
%     Product segments: the StationList segments whose WL_products equals
%         the product name (the name carries the quality, e.g.
%         'Preliminary 6-Minute Water Level'); a product the station does
%         not offer gives status 'product not offered'.
%     Window: opMode 1 = whole inventory of the product (first segment
%         start to last segment end); opMode 2 = [dBeg, dEnd], the same for
%         every station (never narrowed by a previous station).
%     Datum (WL_datum), as currently coded: requested_datum is upper-cased
%         and mapped by noaa_datum_code (NAVD88 -> NAVD, GL_LWD -> LWD).
%         Great Lakes stations (checked first): IGLD, or LWD when LWD is
%         requested and the station offers it. Other stations: the
%         requested code when the station offers it (StationList datums
%         api_code); otherwise the first offered of NAVD, MSL, MLLW (when
%         the requested code contains NAVD) or of MSL, MLLW, NAVD (any
%         other request); else STND (also when the station has no datums).
%         TP_datum = WL_datum.
%     Measured data: download_noaa_water_levels (window intersected with
%         the segments, each time requested once, NaN on regular grids,
%         high_low never filled).
%     Tide predictions (TP): only for harmonic ('R') stations
%         (StationList.harmonic_predictions) and only next to water_level
%         ('6'), hourly_height ('h') and high_low ('hilo') data, from the
%         first downloaded window start to the last window end; none for
%         daily or monthly means (TP empty, TP_downloaded_product '').
%     WL/TP layout: two tables. For 6-minute and hourly data, WL and TP
%         are outer-joined on DateTime, so both tables have the same
%         DateTime column (NaN where one of them has no value). For
%         high_low, the observed and predicted highs/lows happen at
%         different times, so WL and TP keep their own time stamps.
%     record_length: inventory span of the product in years (sum of its
%         segment durations, each limited to the window in opMode 2;
%         years = 365.2425 days), not the count of valid data.
%     Beg, End: first and last DateTime of WL (NaT when empty).
%     status: 'ok'; 'product not offered'; 'no inventory in the requested
%         window'; 'no data returned' (WL all NaN or empty); 'download
%         failed: <NOAA message>'; '; tide predictions failed: <message>'
%         is appended when only TP failed.
%   NOAA rejections (noaa:requestFailed) are reported in status and the
%   loop continues; any other error (e.g. noaa:noConnection) stops it.
%   An opMode other than 1 or 2, opMode 2 without dBeg and dEnd, or
%   dBeg after dEnd raises noaa:invalidMode.
%
%   Inputs:
%     idList          - station ids to download, cell, string or char
%     StationList     - station list (noaa_station_list), struct array
%     requested_datum - preferred datum: Data API code or datums endpoint
%                       name (e.g. 'MSL', 'NAVD', 'NAVD88'; see
%                       noaa_station_details for a station's datums),
%                       char or string
%     products        - NOAA product names, any of 'Verified 6-Minute
%                       Water Level', 'Preliminary 6-Minute Water Level',
%                       'Verified Hourly Height Water Level', 'Verified
%                       High/Low Water Level', 'Verified Daily Mean Water
%                       Level', 'Verified Monthly Mean Water Level', cell,
%                       string or char
%     opMode          - 1 = full record, 2 = [dBeg, dEnd], double
%     dBeg, dEnd      - (opMode 2) window start and end, UTC (a datetime
%                       with a time zone is converted), datetime, datenum
%                       or date text
%   Outputs:
%     Sdata    - struct array (column), fields:
%                  id, name, state - station id, name and state, char
%                  lon, lat - longitude and latitude [deg], double
%                  WL_datum, TP_datum - data API datum used, char
%                  WL_downloaded_product - product name, char
%                  TP_downloaded_product - prediction interval ('6', 'h',
%                      'hilo') or '', char
%                  record_length - inventory span [years], double
%                  WL - table: DateTime (UTC), WaterLevel [m] (+ Type for
%                      high_low)
%                  TP - table: DateTime (UTC), Prediction [m] (+ Type for
%                      hilo)
%                  Beg, End - first and last WL time stamp (UTC), datetime
%                  status - download status, char
%     notFound - ids missing from StationList, cell column
%
%   Tier: public
%
%   See also noaa_station_list, create_tide_file,
%   download_noaa_tide_predictions, download_noaa_water_levels,
%   noaa_station_catalog, noaa_station_details, select_noaa_stations,
%   plot_noaa_stations.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if ~ismember(opMode, 1:2)
    error('noaa:invalidMode', 'Please use a valid operational mode (1 - full record, 2 - specific dates).');
end
if opMode == 2
    if nargin < 7
        error('noaa:invalidMode', 'opMode 2 needs dBeg and dEnd.');
    end
    window_begin = as_utc_datetime(dBeg);
    window_end = as_utc_datetime(dEnd);
    if window_begin > window_end
        error('noaa:invalidMode', 'dBeg must be before dEnd.');
    end
end

idList = cellstr(idList);
idList = idList(:);
products = cellstr(products);
station_ids = {StationList.id}';
[in_list, list_row] = ismember(idList, station_ids);
notFound = idList(~in_list);
list_row = list_row(in_list);

no_time = NaT('TimeZone', 'UTC');
empty_wl = table(repmat(no_time, 0, 1), zeros(0, 1), 'VariableNames', {'DateTime', 'WaterLevel'});
empty_tp = table(repmat(no_time, 0, 1), zeros(0, 1), 'VariableNames', {'DateTime', 'Prediction'});
entry_template = struct('id', '', 'name', '', 'lon', NaN, 'lat', NaN, 'state', '',...
    'WL_datum', '', 'TP_datum', '', 'WL_downloaded_product', '', 'TP_downloaded_product', '',...
    'record_length', 0, 'WL', empty_wl, 'TP', empty_tp, 'Beg', no_time, 'End', no_time,...
    'status', '');
Sdata = repmat(entry_template, 0, 1);

for station_index = 1:numel(list_row)
    station = StationList(list_row(station_index));
    for product_index = 1:numel(products)
        product_name = products{product_index};
        entry = entry_template;
        entry.id = station.id;
        entry.name = station.name;
        entry.lon = station.lon;
        entry.lat = station.lat;
        entry.state = station.state;
        entry.WL_downloaded_product = product_name;

        product_segments = string(station.WL_products) == string(product_name);
        if ~any(product_segments)
            entry.status = 'product not offered';
            Sdata(end + 1, 1) = entry; %#ok<AGROW>
            report_entry(station_index, numel(list_row), entry);
            continue
        end
        segment_first = station.startDate(product_segments);
        segment_last = station.endDate(product_segments);
        if opMode == 1
            entry_begin = min(segment_first);
            entry_end = max(segment_last);
        else
            entry_begin = window_begin;
            entry_end = window_end;
        end
        segment_span = min(segment_last, entry_end) - max(segment_first, entry_begin);
        entry.record_length = years(sum(max(segment_span, 0)));
        if ~any(segment_span >= 0)
            entry.status = 'no inventory in the requested window';
            Sdata(end + 1, 1) = entry; %#ok<AGROW>
            report_entry(station_index, numel(list_row), entry);
            continue
        end

        entry.WL_datum = select_datum(station, requested_datum);
        api_product = char(station.WL_api_product(find(product_segments, 1)));
        segments = table(string(station.WL_api_product(product_segments)),...
            string(station.WL_quality(product_segments)), segment_first, segment_last,...
            'VariableNames', {'api_product', 'quality', 'first', 'last'});
        try
            [entry.WL, windows] = download_noaa_water_levels(station.id, api_product, entry.WL_datum,...
                entry_begin, entry_end, struct('segments', segments,...
                'quality', station.WL_quality(find(product_segments, 1))));
        catch download_error
            if ~strcmp(download_error.identifier, 'noaa:requestFailed')
                rethrow(download_error);
            end
            entry.status = ['download failed: ' download_error.message];
            Sdata(end + 1, 1) = entry; %#ok<AGROW>
            report_entry(station_index, numel(list_row), entry);
            continue
        end
        entry.status = 'ok';
        if isempty(entry.WL) || all(isnan(entry.WL.WaterLevel))
            entry.status = 'no data returned';
        end

        % Harmonic Tide Predictions Next To 6-Minute, Hourly And High/Low Data
        prediction_interval = '';
        switch api_product
            case 'water_level'
                prediction_interval = '6';
            case 'hourly_height'
                prediction_interval = 'h';
            case 'high_low'
                prediction_interval = 'hilo';
        end
        if station.harmonic_predictions && ~isempty(prediction_interval) && ~isempty(windows)
            entry.TP_datum = entry.WL_datum;
            try
                entry.TP = download_noaa_tide_predictions(station.id, entry.TP_datum,...
                    windows.first(1), windows.last(end), prediction_interval,...
                    struct('harmonic_predictions', true));
                entry.TP_downloaded_product = prediction_interval;
            catch prediction_error
                if ~strcmp(prediction_error.identifier, 'noaa:requestFailed')
                    rethrow(prediction_error);
                end
                entry.TP_datum = '';
                entry.status = [entry.status '; tide predictions failed: ' prediction_error.message];
            end
            if ~isempty(entry.TP_downloaded_product) && ~strcmp(api_product, 'high_low')
                joined = outerjoin(entry.WL, entry.TP, 'Keys', 'DateTime', 'MergeKeys', true);
                entry.WL = joined(:, {'DateTime', 'WaterLevel'});
                entry.TP = joined(:, {'DateTime', 'Prediction'});
            end
        end

        if ~isempty(entry.WL)
            entry.Beg = entry.WL.DateTime(1);
            entry.End = entry.WL.DateTime(end);
        end
        Sdata(end + 1, 1) = entry; %#ok<AGROW>
        report_entry(station_index, numel(list_row), entry);
    end
end
end

function time = as_utc_datetime(time_input)
if isdatetime(time_input)
    time = time_input;
elseif isnumeric(time_input)
    time = datetime(time_input, 'ConvertFrom', 'datenum');
else
    time = datetime(time_input);
end
time.TimeZone = 'UTC';
end

function datum = select_datum(station, requested_datum)
offered = strings(0, 1);
if ~isempty(station.datums)
    offered = string({station.datums.api_code}');
end
requested = noaa_datum_code(upper(string(requested_datum)));
if station.greatlakes
    datum = 'IGLD';
    if requested == "LWD" && any(offered == "LWD")
        datum = 'LWD';
    end
    return
end
if any(offered == requested)
    datum = char(requested);
    return
end
if contains(requested, "NAVD")
    fallback_order = ["NAVD", "MSL", "MLLW"];
else
    fallback_order = ["MSL", "MLLW", "NAVD"];
end
datum = 'STND';
first_offered = find(ismember(fallback_order, offered), 1);
if ~isempty(first_offered)
    datum = char(fallback_order(first_offered));
end
end

function report_entry(station_index, station_count, entry)
fprintf('NOAA station %s (%d/%d) %s: %s\n', entry.id, station_index, station_count,...
    entry.WL_downloaded_product, entry.status);
end

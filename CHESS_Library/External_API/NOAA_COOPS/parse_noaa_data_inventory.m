function segments = parse_noaa_data_inventory(xml_text)
% parse_noaa_data_inventory  Water level segments of a NOAA inventory reply.
%   segments = parse_noaa_data_inventory(xml_text)
%
%   Parses the reply of the NOAA CO-OPS XML data inventory service
%   (data_inventory endpoint) into the water level segments of a station:
%   one row per <parameter first=... last=... name=.../>.
%   Only water level products are kept:
%     'Verified 6-Minute Water Level' / 'Preliminary 6-Minute Water
%         Level' -> water_level
%     'Verified Hourly Height Water Level' -> hourly_height
%     'Verified High/Low Water Level' -> high_low
%     'Verified Daily Mean Water Level' -> daily_mean
%     'Verified Monthly Mean Water Level' -> monthly_mean
%   Other parameters (winds, temperatures, pressure, ...) are dropped.
%   A SOAP Fault (e.g. "No data inventory available from this station",
%   the reply for predictions-only stations) or a reply without
%   parameters (e.g. '') returns an empty table.
%
%   Inputs:
%     xml_text - raw XML reply (noaa_web_request), char or string
%   Outputs:
%     segments - one row per inventory segment, table:
%                  product_name - NOAA product name (e.g. 'Verified
%                      6-Minute Water Level'), string
%                  api_product - data API product (water_level,
%                      hourly_height, high_low, daily_mean,
%                      monthly_mean), string
%                  quality - 'verified' or 'preliminary', string
%                  first - first time stamp of the segment (UTC), datetime
%                  last - last time stamp of the segment (UTC), datetime
%
%   Tier: internal
%
%   See also noaa_station_details, download_noaa_water_levels,
%   noaa_web_request.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
product_names = ["Verified 6-Minute Water Level", "Preliminary 6-Minute Water Level",...
    "Verified Hourly Height Water Level", "Verified High/Low Water Level",...
    "Verified Daily Mean Water Level", "Verified Monthly Mean Water Level"];
api_products = ["water_level", "water_level", "hourly_height", "high_low", "daily_mean", "monthly_mean"];

segments = table(strings(0, 1), strings(0, 1), strings(0, 1),...
    datetime.empty(0, 1), datetime.empty(0, 1),...
    'VariableNames', {'product_name', 'api_product', 'quality', 'first', 'last'});
segments.first.TimeZone = 'UTC';
segments.last.TimeZone = 'UTC';

xml_text = char(xml_text);
if contains(xml_text, ':Fault>')
    return
end
parameter_tags = regexp(xml_text, '<parameter\s[^>]*>', 'match');
if isempty(parameter_tags)
    return
end
name = strings(numel(parameter_tags), 1);
first_text = strings(numel(parameter_tags), 1);
last_text = strings(numel(parameter_tags), 1);
for tag_index = 1:numel(parameter_tags)
    name(tag_index) = attribute_value(parameter_tags{tag_index}, 'name');
    first_text(tag_index) = attribute_value(parameter_tags{tag_index}, 'first');
    last_text(tag_index) = attribute_value(parameter_tags{tag_index}, 'last');
end
[is_water_level, product_index] = ismember(name, product_names);
if ~any(is_water_level)
    return
end
name = name(is_water_level);
quality = repmat("verified", numel(name), 1);
quality(startsWith(name, "Preliminary")) = "preliminary";
segments = table(name, api_products(product_index(is_water_level))', quality,...
    datetime(first_text(is_water_level), 'InputFormat', 'yyyy-MM-dd HH:mm', 'TimeZone', 'UTC'),...
    datetime(last_text(is_water_level), 'InputFormat', 'yyyy-MM-dd HH:mm', 'TimeZone', 'UTC'),...
    'VariableNames', {'product_name', 'api_product', 'quality', 'first', 'last'});
end

function value = attribute_value(tag, attribute_name)
value = regexp(tag, ['\s' attribute_name '="([^"]*)"'], 'tokens', 'once');
if isempty(value)
    value = "";
else
    value = string(strrep(value{1}, '&amp;', '&'));
end
end

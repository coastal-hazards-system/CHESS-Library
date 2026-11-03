function [chunk_first, chunk_last] = noaa_request_chunks(first, last, api_product)
% noaa_request_chunks  Split a time range into NOAA data API requests.
%   [chunk_first, chunk_last] = noaa_request_chunks(first, last,
%       api_product)
%
%   Splits [first, last] into consecutive data API requests within the
%   NOAA CO-OPS size limit of the product (found by testing, not
%   documented by NOAA):
%     water_level (6-minute): 31 days
%     hourly_height, high_low: 365 days
%     daily_mean: 3655 days
%     monthly_mean: no limit (one request)
%     predictions (any interval): 3655 days
%   Chunks do not overlap: each chunk ends 1 minute before the next one
%   starts (NOAA time stamps are whole minutes), and the last chunk ends
%   at last. first > last gives no chunk. Any other product raises
%   noaa:unknownProduct.
%
%   Inputs:
%     first       - first time of the range, datetime
%     last        - last time of the range, datetime
%     api_product - data API product: 'water_level', 'hourly_height',
%                   'high_low', 'daily_mean', 'monthly_mean' or
%                   'predictions', char or string
%   Outputs:
%     chunk_first - first time of each request, datetime column
%     chunk_last  - last time of each request, datetime column
%
%   Tier: internal
%
%   See also download_noaa_water_levels, download_noaa_tide_predictions.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
switch char(api_product)
    case 'water_level'
        limit_days = 31;
    case {'hourly_height', 'high_low'}
        limit_days = 365;
    case {'daily_mean', 'predictions'}
        limit_days = 3655;
    case 'monthly_mean'
        limit_days = Inf;
    otherwise
        error('noaa:unknownProduct', 'Unknown NOAA CO-OPS data API product ''%s''.', char(api_product));
end
if first > last
    chunk_first = first([]);
    chunk_last = last([]);
    chunk_first = chunk_first(:);
    chunk_last = chunk_last(:);
    return
end
if isinf(limit_days)
    chunk_first = first;
    chunk_last = last;
    return
end
chunk_first = (first:days(limit_days):last)';
chunk_last = [chunk_first(2:end) - minutes(1); last];
end

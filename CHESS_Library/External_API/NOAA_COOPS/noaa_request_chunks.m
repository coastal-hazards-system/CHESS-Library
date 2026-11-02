function [chunk_first, chunk_last] = noaa_request_chunks(first, last, api_product)
%{
    %% DESCRIPTION
        Splits [first, last] into consecutive data API requests within the
        NOAA CO-OPS size limit of the product (found by testing, not
        documented by NOAA):
            water_level (6-minute): 31 days
            hourly_height, high_low: 365 days
            daily_mean: 3655 days
            monthly_mean: no limit (one request)
            predictions (any interval): 3655 days
        Chunks do not overlap: each chunk ends 1 minute before the next one
        starts (NOAA time stamps are whole minutes), and the last chunk ends
        at last. first > last gives no chunk.

    %% INPUTS
        first: First time of the range. | datetime
        last: Last time of the range. | datetime
        api_product: Data API product (water_level, hourly_height, high_low,
            daily_mean, monthly_mean, predictions). | char/string

    %% OUTPUTS
        chunk_first: First time of each request. | datetime (column)
        chunk_last: Last time of each request. | datetime (column)

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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

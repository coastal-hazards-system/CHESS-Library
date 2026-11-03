function reply_text = noaa_web_request(url, options)
% noaa_web_request  Send one NOAA CO-OPS GET request and return the reply.
%   reply_text = noaa_web_request(url)
%   reply_text = noaa_web_request(url, options)
%
%   The single network access point of the NOAA tools: every NOAA CO-OPS
%   request of External_API\NOAA_COOPS goes through this function (tests
%   shadow it to run offline).
%   Sends an HTTP GET and returns the raw reply text.
%     HTTP 200: the reply text is returned as is (NOAA error texts sent
%         with HTTP 200, e.g. "Error: No data was found", are left to the
%         parsers: parse_noaa_csv).
%     HTTP 4xx: NOAA rejected the request (e.g. "Range Limit Exceeded",
%         "There is no MSL for the station", unknown station). No retry;
%         error noaa:requestFailed carrying NOAA's message from the reply
%         body.
%     Unknown host: no retry; error noaa:noConnection.
%     Timeouts, other connection errors, HTTP 5xx: retried up to
%         options.retries attempts with a pause of retry_pause_s*attempt
%         seconds, then error noaa:requestFailed.
%   matlab.net.http is used instead of webread because webread drops the
%   reply body of HTTP 4xx replies, where NOAA puts its error message.
%
%   Inputs:
%     url     - full request URL (query already encoded), char or string
%     options - struct (optional; [] = default); fields (all optional):
%                 .timeout - connection and response timeout [s], double,
%                     default 120
%                 .retries - maximum number of attempts (at least 1),
%                     double, default 5
%                 .retry_pause_s - pause scale [s]; the pause before
%                     attempt k+1 is retry_pause_s*k, double, default 5
%                     (tests set 0)
%   Outputs:
%     reply_text - raw reply text, char
%
%   Tier: internal
%
%   See also noaa_station_catalog, noaa_station_details,
%   download_noaa_water_levels, download_noaa_tide_predictions.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin < 2 || isempty(options)
    options = struct();
end
timeout = 120;
if isfield(options, 'timeout')
    timeout = options.timeout;
end
retries = 5;
if isfield(options, 'retries')
    retries = max(1, options.retries);
end
retry_pause_s = 5;
if isfield(options, 'retry_pause_s')
    retry_pause_s = options.retry_pause_s;
end

url = char(url);
http_options = matlab.net.http.HTTPOptions('ConnectTimeout', timeout,...
    'ResponseTimeout', timeout, 'ConvertResponse', false);
request = matlab.net.http.RequestMessage('GET');
last_problem = '';
for attempt = 1:retries
    try
        response = request.send(matlab.net.URI(url), http_options);
    catch request_error
        if strcmp(request_error.identifier, 'MATLAB:webservices:UnknownHost')
            error('noaa:noConnection',...
                'Could not reach NOAA CO-OPS (no internet connection or unknown host). URL: %s', url);
        end
        last_problem = request_error.message;
        pause_before_retry(attempt, retries, retry_pause_s);
        continue
    end

    status_code = double(response.StatusCode);
    reply_text = body_text(response);
    if status_code == 200
        return
    end
    if status_code >= 400 && status_code < 500
        noaa_message = strtrim(regexprep(reply_text, '\s+', ' '));
        if isempty(noaa_message)
            noaa_message = char(response.StatusLine.ReasonPhrase);
        end
        error('noaa:requestFailed', 'NOAA CO-OPS rejected the request (HTTP %d): %s URL: %s',...
            status_code, noaa_message, url);
    end
    last_problem = sprintf('HTTP %d', status_code);
    pause_before_retry(attempt, retries, retry_pause_s);
end
error('noaa:requestFailed', 'NOAA CO-OPS request failed after %d attempts (%s). URL: %s',...
    retries, last_problem, url);
end

function pause_before_retry(attempt, retries, retry_pause_s)
if attempt < retries && retry_pause_s > 0
    pause(retry_pause_s*attempt);
end
end

function reply_text = body_text(response)
reply_text = '';
if isempty(response.Body) || isempty(response.Body.Data)
    return
end
data = response.Body.Data;
if isnumeric(data)
    reply_text = native2unicode(uint8(data(:))', 'UTF-8');
else
    reply_text = char(data);
end
end

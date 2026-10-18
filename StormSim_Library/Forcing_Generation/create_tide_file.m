function [data_table] = create_tide_file(station, datum, start_date, outName, progress_fcn)
% create_tide_file Downloads a Year's worth of tidal predictions from NOAA
% CO-OPS API and writes an hourly tide file for StormSim. Stations location
% and data availability can be found
% <a href="matlab: web('https://tidesandcurrents.noaa.gov/stations.html?type=Water+Levels')">here</a>.
%
% Inputs:
%       station: NOAA CO-OPS unique station identifier. Number string with
%                7 characters (i.e. '8638660').
%
%       datum: Vertical datum of the predictions. Any NOAA API datum code
%              (e.g. 'MSL', 'MLLW', 'NAVD'); 'NAVD88' is accepted for 'NAVD'.
%              It must match the datum of the storm (CHS) data, because the
%              tide is added directly to the storm water levels.
%
%       start_date: Start date for data download. Must be a datestring with
%                   'yyyyMMdd' format. Time must be in the GMT timezone.
%                   Data and product availability can be seen in the
%                   station's data inventory page.
%
%       outName: Output file name and location (.csv).
%
%       progress_fcn: (Optional) Function handle called as progress_fcn(fraction)
%                     after each data request (e.g. to update a progress bar).
%
% Outputs:
%       data_table: Hourly tidal predictions written to outName
%                   (columns: Date, Prediction [m]). StormSim adds one row per
%                   hourly storm time step (apply_random_tide.m).
%
% Notes:
%       Predictions are requested at a 6-minute interval (interval=6) in
%       31-day chunks (API data request restriction) and interpolated to an
%       hourly signal, which is what gets stored.
%
% Example Usage:
%       data = create_tide_file('8423898', 'MSL', '20260101', 'stormsim_tidal_file.csv');

if nargin < 5
    progress_fcn = [];
end
station = char(station);
datum = char(datum);
% NOAA Datums Endpoint Uses NAVD88, The Data API Uses NAVD
if strcmpi(datum, 'NAVD88')
    datum = 'NAVD';
end

%% INPUTS
% 1. Define your starting date
initial_stdate = datetime(start_date, 'InputFormat', 'yyyyMMdd');

% 2. Define the absolute final date for the year (1 year later, minus 1 day)
final_endate = initial_stdate + calyears(1) - caldays(1);

% 3. Generate start dates stepping by 31 days (column vector)
stdate = (initial_stdate : caldays(31) : final_endate)';

% 4. Generate end dates (start date + 30 days = 31 total days per pull)
endate = stdate + caldays(30);

% 5. Cap the final end date so it doesn't overshoot the 1-year mark
endate = min(endate, final_endate);

% 6. (Optional) Convert back to strings if your data API requires text inputs
stdate_str = string(stdate, 'yyyyMMdd');
endate_str = string(endate, 'yyyyMMdd');

%% DOWNLOAD 6-MINUTE PREDICTIONS (31-DAY REQUESTS)
opts = weboptions("Timeout",300);
data_table = [];
for kk = 1:length(endate_str)
    url_pth =['https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?begin_date='...
        char(stdate_str(kk)) '&end_date=' char(endate_str(kk)) '&station=' station...
        '&product=predictions&datum=' datum '&time_zone=gmt&units=metric&interval=6&format=csv'];
    data = webread(url_pth, opts);
    % NOAA Returns Its Error Message As A One-Row Table Instead Of Data
    if ~istable(data) || ~all(ismember({'DateTime', 'Prediction'}, data.Properties.VariableNames))
        if istable(data) && ~isempty(data) % Message Text Is Split Across The Table Columns
            parts = string(table2cell(data(1, :)));
            msg = strjoin(parts(~ismissing(parts) & strlength(strtrim(parts)) > 0), ' ');
        else
            msg = strtrim(char(string(data)));
        end
        error('create_tide_file:noaaRequest', 'NOAA request failed for station %s (datum %s, %s-%s): %s',...
            station, datum, char(stdate_str(kk)), char(endate_str(kk)), msg);
    end
    data_table = [data_table; data]; %#ok<AGROW>
    if ~isempty(progress_fcn)
        progress_fcn(kk/length(endate_str));
    end
end

%% INTERPOLATE TO AN HOURLY SIGNAL (STORM DATA ARE HOURLY)
target_date = (initial_stdate : hours(1) : final_endate + hours(23))';
hourly_tide = interp1(data_table.DateTime, data_table.Prediction, target_date);
data_table = table(target_date, hourly_tide, 'VariableNames', {'Date', 'Prediction [m]'});

%% CREATE TIDAL FILE (MEANT FOR 1 STATION)
% Parse Tidal File
writetable(data_table,outName);
end

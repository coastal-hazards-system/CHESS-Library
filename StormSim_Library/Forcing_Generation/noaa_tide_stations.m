function stations = noaa_tide_stations(station_type)
% noaa_tide_stations Lists NOAA CO-OPS tidal prediction stations (metadata API).
%
% Inputs:
%       station_type: (Optional) 'R' (harmonic stations, default), 'S'
%                     (subordinate stations) or 'all'.
%
% Outputs:
%       stations: Table with columns id, name, state, lat, lng, type,
%                 sorted by state then name.
%
% Example Usage:
%       stations = noaa_tide_stations();   % harmonic stations only

if nargin < 1
    station_type = 'R';
end
url_pth = 'https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=tidepredictions&units=metric';
response = webread(url_pth, weboptions('Timeout', 60));
st = response.stations;
if iscell(st)
    st = [st{:}];
end
stations = table(string({st.id})', string({st.name})', string({st.state})', [st.lat]', [st.lng]', string({st.type})',...
    'VariableNames', {'id', 'name', 'state', 'lat', 'lng', 'type'});
if ~strcmpi(station_type, 'all')
    stations = stations(stations.type == upper(string(station_type)), :);
end
stations = sortrows(stations, {'state', 'name'});
end

function datums = noaa_station_datums(station)
% noaa_station_datums Vertical datums available at a NOAA CO-OPS station
% that can be used to request tidal predictions (create_tide_file.m).
%
% Inputs:
%       station: NOAA CO-OPS station identifier (e.g. '8423898').
%
% Outputs:
%       datums: Table with columns name (as listed by NOAA, e.g. 'NAVD88'),
%               api_code (datum code for the data API, e.g. 'NAVD') and
%               value [m] (relative to station datum STND). Tidal ranges and
%               intervals (GT, MN, DHQ, DLQ, HWI, LWI) and datums the data API
%               does not accept are left out.
%
% Example Usage:
%       datums = noaa_station_datums('8423898');

url_pth = ['https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations/' char(station) '/datums.json?units=metric'];
response = webread(url_pth, weboptions('Timeout', 60));
names = strings(0, 1);
values = zeros(0, 1);
if isfield(response, 'datums') && ~isempty(response.datums)
    dd = response.datums;
    if iscell(dd)
        dd = [dd{:}];
    end
    names = string({dd.name})';
    values = [dd.value]';
end
% Data API Datum Codes (NOAA CO-OPS API: datum parameter)
api_codes = ["CRD", "IGLD", "LWD", "MHHW", "MHW", "MTL", "MSL", "MLLW", "MLW", "NAVD", "STND"];
codes = replace(names, "NAVD88", "NAVD");
keep = ismember(codes, api_codes);
datums = table(names(keep), codes(keep), values(keep), 'VariableNames', {'name', 'api_code', 'value'});
end

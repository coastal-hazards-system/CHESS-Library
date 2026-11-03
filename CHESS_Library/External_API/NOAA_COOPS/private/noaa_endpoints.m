function endpoints = noaa_endpoints()
% noaa_endpoints  Base URLs of the NOAA CO-OPS web services.
%   endpoints = noaa_endpoints()
%
%   Base URLs of the NOAA CO-OPS web services used by the NOAA tools of
%   CHESS (External_API\NOAA_COOPS). Every request goes through
%   noaa_web_request.
%
%   Inputs: none
%   Outputs:
%     endpoints - struct:
%                   metadata_api - metadata API (station lists, station
%                       JSON, datums), char
%                   data_api - data API (water levels and tide
%                       predictions, csv), char
%                   data_inventory - XML data inventory service (date
%                       ranges of each product of a station), char
%
%   Tier: internal
%
%   See also noaa_web_request, noaa_station_catalog, noaa_station_details,
%   download_noaa_water_levels, download_noaa_tide_predictions.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
endpoints = struct(...
    'metadata_api', 'https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi',...
    'data_api', 'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter',...
    'data_inventory', 'https://opendap.co-ops.nos.noaa.gov/axis/webservices/datainventory/response.jsp');
end

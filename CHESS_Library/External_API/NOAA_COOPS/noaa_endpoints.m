function endpoints = noaa_endpoints()
%{
    %% DESCRIPTION
        Base URLs of the NOAA CO-OPS web services used by the NOAA tools of
        CHESS (External_API\NOAA_COOPS). Every request goes through
        noaa_web_request.m.

    %% INPUTS
        None.

    %% OUTPUTS
        endpoints: Struct with fields | struct
            metadata_api: Metadata API (station lists, station JSON,
                datums). | char
            data_api: Data API (water levels and tide predictions,
                csv). | char
            data_inventory: XML data inventory service (date ranges of each
                product of a station). | char

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
endpoints = struct(...
    'metadata_api', 'https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi',...
    'data_api', 'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter',...
    'data_inventory', 'https://opendap.co-ops.nos.noaa.gov/axis/webservices/datainventory/response.jsp');
end

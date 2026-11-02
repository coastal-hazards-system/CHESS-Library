function code = noaa_datum_code(name)
%{
    %% DESCRIPTION
        Data API datum code of a NOAA CO-OPS datum name. The datums
        endpoint (noaa_station_details.m) names two datums differently
        from the data API: NAVD88 is requested as NAVD and GL_LWD as LWD.
        The match is case-insensitive; every other name is returned
        unchanged. Used by create_tide_file.m, noaa_station_details.m and
        noaa_water_level_downloader.m.

    %% INPUTS
        name: Datum name(s) (e.g. 'NAVD88', "GL_LWD", 'MSL'). | char/string

    %% OUTPUTS
        code: Data API datum code(s), char for a char input, else
            string (same size). | char/string

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
is_char = ischar(name);
code = string(name);
code(strcmpi(code, "NAVD88")) = "NAVD";
code(strcmpi(code, "GL_LWD")) = "LWD";
if is_char
    code = char(code);
end
end

function code = noaa_datum_code(name)
% chess.NOAA.noaa_datum_code  Data API datum code of a NOAA CO-OPS datum name.
%   code = chess.NOAA.noaa_datum_code(name)
%
%   The datums endpoint (chess.NOAA.noaa_station_details) names two datums
%   differently from the data API: NAVD88 is requested as NAVD and GL_LWD
%   as LWD. The match is case-insensitive; every other name is returned
%   unchanged. Used by chess.NOAA.create_tide_file, chess.NOAA.download_noaa_tide_predictions,
%   chess.NOAA.download_noaa_water_levels, chess.NOAA.noaa_station_details and
%   chess.NOAA.noaa_water_level_downloader.
%
%   Inputs:
%     name - datum name(s) (e.g. 'NAVD88', "GL_LWD", 'MSL'), char or
%            string
%   Outputs:
%     code - Data API datum code(s): char for a char input, else string
%            (same size)
%
%   See also chess.NOAA.noaa_station_details, chess.NOAA.create_tide_file,
%   chess.NOAA.noaa_water_level_downloader.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
is_char = ischar(name);
code = string(name);
code(strcmpi(code, "NAVD88")) = "NAVD";
code(strcmpi(code, "GL_LWD")) = "LWD";
if is_char
    code = char(code);
end
end

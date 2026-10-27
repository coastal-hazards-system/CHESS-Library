function tide = read_tide_series(tide_file)
%{
    %% DESCRIPTION
        Tide record of a tide file: the last column, header row skipped
        (create_tide_file.m layout: Date, Prediction [m]). Parsed files are
        cached for the MATLAB session (apply_random_tide.m runs once per
        dataset, draw_tide_indices.m once per run, the storm event viewer on
        every draw). A cached record is used only while the file's
        modification date and size are unchanged, so an edited or replaced
        file is read again. `clear read_tide_series` empties the cache.

    %% INPUTS
        tide_file: Tide file path. | char/string

    %% OUTPUTS
        tide: Tide record (last column). | numeric column vector

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
persistent cache
if isempty(cache)
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
end
% A File Found Only On The MATLAB Path (Callers Check exist(...,'file')): Resolved To Its Full Path First
if ~isfile(tide_file) && ~isempty(which(tide_file))
    tide_file = which(tide_file);
end
info = dir(tide_file);
key = sprintf('%s|%.10f|%d', lower(char(tide_file)), info.datenum, info.bytes);
if ~isKey(cache, key)
    data = readmatrix(tide_file, 'NumHeaderLines', 1);
    cache(key) = data(:, end);
end
tide = cache(key);
end

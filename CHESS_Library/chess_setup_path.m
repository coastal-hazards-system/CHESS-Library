function library_folder = chess_setup_path()
%CHESS_SETUP_PATH Put CHESS_Library on the MATLAB path, without Tools and Retired.
%{
%% DESCRIPTION
Adds this file's folder and every subfolder to the MATLAB path, then removes
every folder that has a path segment named 'Tools' or 'Retired'. Those folders
hold stand-alone utilities and retired code that must stay off the path (see
the README.md in each). Call it once after adding CHESS_Library itself:
    addpath('CHESS_Library'); chess_setup_path;

%% INPUTS
None.

%% OUTPUTS
library_folder: Full path of the CHESS_Library folder. | char

%% DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
library_folder = fileparts(mfilename('fullpath'));
library_paths = strsplit(genpath(library_folder), pathsep);
library_paths = library_paths(~cellfun(@isempty, library_paths));
addpath(strjoin(library_paths, pathsep));

excluded_segments = {'Tools', 'Retired'};
for path_index = 1:numel(library_paths)
    relative_path = library_paths{path_index}(numel(library_folder) + 1:end);
    path_segments = strsplit(relative_path, filesep);
    if any(ismember(path_segments, excluded_segments))
        rmpath(library_paths{path_index});
    end
end
end

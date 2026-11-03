function library_folder = chess_setup_path()
% chess_setup_path  Put CHESS_Library on the MATLAB path, without Tools and Retired.
%   library_folder = chess_setup_path() adds the folder of this file and
%   every subfolder to the MATLAB path, then removes every folder that has a
%   path segment named 'Tools' or 'Retired'.
%
%   Those folders hold stand-alone utilities and retired code that must stay
%   off the path (see the README.md in each). Call it once after adding
%   CHESS_Library itself:
%       addpath('CHESS_Library'); chess_setup_path;
%
%   Inputs:
%     none
%   Outputs:
%     library_folder - full path of the CHESS_Library folder, char row vector
%
%   Tier: public
%
%   See also call_input_parser, call_chs_data_formatter,
%   call_chess_boundary_conditions, call_project_response.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

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

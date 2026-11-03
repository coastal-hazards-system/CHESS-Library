function CHS_Data = strip_chs_data_folders(CHS_Data)
% strip_chs_data_folders  Keep only the file name in CHS_Data.Filename.
%   CHS_Data = strip_chs_data_folders(CHS_Data)
%
%   Keeps only the file name (name + extension) in CHS_Data.Filename.
%   Storm files are selected by name tokens (chs_file_name_parts reads the
%   name only), and a folder (temp folder, user folder) must never reach
%   the stored file names. Used by convert_chs_zip (raw files hold names
%   only), build_storm_database (CHS_Data .mat inputs), call_input_parser
%   and the GUI storm database wizard (CHS_Data .mat import).
%
%   Inputs:
%     CHS_Data - converted CHS files (Filename, Conv_Data),
%                1 x number_of_files struct
%   Outputs:
%     CHS_Data - same, Filename without folders, 1 x number_of_files
%                struct
%
%   Tier: internal
%
%   See also convert_chs_zip, build_storm_database, chs_file_name_parts.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
[~, file_names, file_extensions] = cellfun(@fileparts, {CHS_Data.Filename}, 'un', false);
file_names = strcat(file_names, file_extensions);
[CHS_Data.Filename] = file_names{:};
end

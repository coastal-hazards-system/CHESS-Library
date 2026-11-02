function CHS_Data = convert_chs_zip(chs_zip, h5_names, print_progress, progress_fcn)
%{
    %% DESCRIPTION
        Converts the named CHS .h5 files of a CHS zip folder (call_chs_h5_converter.m).
        The zip is unzipped into a system temp folder (tempname) that is
        removed on every exit (success, converter error, a cancel raised by
        progress_fcn). The .h5 files are matched by name in any case (dir
        '*.h5' is case-sensitive off Windows). CHS_Data.Filename holds the
        file name only (strip_chs_data_folders.m). Shared by
        call_chs_data_formatter.m and the GUI storm database wizard
        (CHSStormDBImportUI.import_chs_modeling).

    %% INPUTS
        chs_zip: CHS zip folder. | char
        h5_names: .h5 file names to convert (no folders). | cell | number_of_files x 1
        print_progress: Print progress to the command window. (0/1) | double | 1 x 1
        progress_fcn: Optional. Called before each file as | function_handle | 1 x 1
                      progress_fcn(jj, n, file_name) (call_chs_h5_converter.m).
                      Omitted or empty: command window only.

    %% OUTPUTS
        CHS_Data: Converted CHS files (Filename: name only, Conv_Data). | struct | 1 x number_of_files

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin < 4
    progress_fcn = [];
end
temp_path = tempname;
temp_cleanup = onCleanup(@() remove_temp_folder(temp_path)); %#ok<NASGU>
unzip(chs_zip, temp_path);
h5_files = dir(fullfile(temp_path, '**', '*'));
h5_files = h5_files(~[h5_files.isdir]' & endsWith({h5_files.name}', '.h5', 'IgnoreCase', true));
[~, h5_location] = ismember(lower(h5_names), lower({h5_files.name}'));
if any(h5_location == 0)
    error('%s not found in the unzipped CHS input ''%s''.', strjoin(reshape(h5_names(h5_location == 0), 1, []), ', '), chs_zip);
end
CHS_Data = call_chs_h5_converter(fullfile({h5_files(h5_location).folder}', {h5_files(h5_location).name}'),...
    print_progress, progress_fcn);
CHS_Data = strip_chs_data_folders(CHS_Data);
end

%% LOCAL FUNCTIONS
% Remove The Unzipped CHS Input Folder
function remove_temp_folder(temp_path)
if isfolder(temp_path)
    rmdir(temp_path, 's');
end
end

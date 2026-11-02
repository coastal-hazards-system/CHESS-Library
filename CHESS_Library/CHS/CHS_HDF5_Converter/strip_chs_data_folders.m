function CHS_Data = strip_chs_data_folders(CHS_Data)
%{
    %% DESCRIPTION
        Keeps only the file name (name + extension) in CHS_Data.Filename.
        Storm files are selected by name tokens (chs_file_name_parts.m reads
        the name only), and a folder (temp folder, user folder) must never
        reach the stored file names. Used by convert_chs_zip.m (raw files hold
        names only), build_storm_database.m (CHS_Data .mat inputs) and the
        GUI storm database wizard (CHS_Data .mat import).

    %% INPUTS
        CHS_Data: Converted CHS files (Filename, Conv_Data). | struct | 1 x number_of_files

    %% OUTPUTS
        CHS_Data: Same, Filename without folders. | struct | 1 x number_of_files

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
[~, file_names, file_extensions] = cellfun(@fileparts, {CHS_Data.Filename}, 'un', false);
file_names = strcat(file_names, file_extensions);
[CHS_Data.Filename] = file_names{:};
end

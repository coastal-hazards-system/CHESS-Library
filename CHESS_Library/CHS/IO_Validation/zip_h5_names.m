function h5_names = zip_h5_names(zip_name)
%{
    %% DESCRIPTION
        HDF5 file names in a zip folder (sorted, folders stripped, .h5
        extension in any case, names kept as stored), read without
        decompressing. macOS metadata (entries under __MACOSX/, names
        starting with '._') is skipped. Shared by call_input_parser.m and
        the GUI storm database wizard (storm file check before any unzip).

    %% INPUTS
        zip_name: Zip folder (relative or full path). | char

    %% OUTPUTS
        h5_names: .h5 file names (name + extension). | cell | n x 1

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
% Absolute Path (Java Resolves Relative Paths Against Its Own Working Folder; exist() Also Finds Files On The MATLAB Path)
zip_info = dir(zip_name);
if isscalar(zip_info) && ~zip_info.isdir
    zip_path = fullfile(zip_info.folder, zip_info.name);
else
    zip_path = which(zip_name);
end
if isempty(zip_path)
    error('zip_h5_names:badZip', 'Error: could not resolve the full path of zip folder ''%s''.', zip_name);
end
try
    zip_obj = java.util.zip.ZipFile(zip_path);
catch
    error('zip_h5_names:badZip', 'Error: ''%s'' is not a readable zip folder.', zip_path);
end
zip_cleanup = onCleanup(@() zip_obj.close());
try
    zip_entries = zip_obj.entries();
    h5_names = cell(0, 1);
    while zip_entries.hasMoreElements()
        entry_path = char(zip_entries.nextElement().getName());
        [~, entry_name, entry_ext] = fileparts(entry_path);
        if contains(['/' entry_path], '/__MACOSX/') || startsWith(entry_name, '._')
            continue
        end
        if strcmpi(entry_ext, '.h5')
            h5_names{end+1, 1} = [entry_name entry_ext]; %#ok<AGROW>
        end
    end
catch
    error('zip_h5_names:badZip', 'Error: ''%s'' is not a readable zip folder.', zip_path);
end
h5_names = sort(h5_names);
end

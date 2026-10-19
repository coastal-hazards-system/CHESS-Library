function out_file = zip_extract_entry(zip_name, entry_file, out_dir)
%{
    %% DESCRIPTION
        Extract one entry of a zip folder, by file name (any zip
        subfolder, case-insensitive), into out_dir without decompressing the rest. Shared by
        call_input_parser.m (savepoint depth) and the GUI storm database
        wizard (study datum & savepoint depth).

    %% INPUTS
        zip_name: Zip folder (relative or full path). | char
        entry_file: Entry file name (name + extension, no folder). | char
        out_dir: Destination folder (created if missing). | char

    %% OUTPUTS
        out_file: Full path of the extracted file. | char

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
zip_obj = java.util.zip.ZipFile(zip_path);
zip_cleanup = onCleanup(@() zip_obj.close());
zip_entries = zip_obj.entries();
while zip_entries.hasMoreElements()
    zip_entry = zip_entries.nextElement();
    [~, entry_name, entry_ext] = fileparts(char(zip_entry.getName()));
    if strcmpi([entry_name entry_ext], entry_file)
        if ~isfolder(out_dir)
            mkdir(out_dir);
        end
        out_file = fullfile(out_dir, entry_file);
        in_stream = zip_obj.getInputStream(zip_entry);
        stream_cleanup = onCleanup(@() in_stream.close());
        copy_options = javaArray('java.nio.file.CopyOption', 1);
        copy_options(1) = java.nio.file.StandardCopyOption.REPLACE_EXISTING;
        java.nio.file.Files.copy(in_stream, java.io.File(out_file).toPath(), copy_options);
        return
    end
end
error('zip_extract_entry:entryNotFound', 'Error: ''%s'' not found in zip folder ''%s''.', entry_file, zip_path);
end

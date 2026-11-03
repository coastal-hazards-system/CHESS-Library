function out_file = zip_extract_entry(zip_name, entry_file, out_dir)
% zip_extract_entry  Extract one entry of a zip file by name, without the rest.
%   out_file = zip_extract_entry(zip_name, entry_file, out_dir)
%
%   Extracts one entry of a zip folder, by file name (any zip subfolder,
%   case-insensitive), into out_dir without decompressing the rest; a
%   file of that name in out_dir is replaced. Used by zip_h5_attributes
%   (study datum and savepoint coordinates for call_input_parser and the
%   GUI storm database wizard). An entry not in the zip folder is an
%   error (zip_extract_entry:entryNotFound).
%
%   Inputs:
%     zip_name   - zip folder (relative or full path), char
%     entry_file - entry file name (name + extension, no folder), char
%     out_dir    - destination folder (created if missing), char
%   Outputs:
%     out_file   - full path of the extracted file, char
%
%   Tier: internal
%
%   See also zip_h5_attributes, zip_h5_names.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

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

function [vertical_datum, sp_coords] = zip_h5_attributes(zip_name, h5_file)
% zip_h5_attributes  Study datum and savepoint coordinates from a CHS zip.
%   [vertical_datum, sp_coords] = zip_h5_attributes(zip_name, h5_file)
%
%   Study vertical datum and ADCIRC save point coordinates from the root
%   attributes ('Vertical Datum', 'Save Point Latitude', 'Save Point
%   Longitude') of one ADCIRC storm .h5 entry of a CHS zip folder, with
%   the same contract as chs_data_attributes (which reads them from
%   converted CHS data and is reused here). Only that entry is extracted
%   (zip_extract_entry), into a system temp folder removed on return,
%   errors included. An entry that cannot be extracted is an error
%   (zip_extract_entry errors). Shared by call_input_parser and the GUI
%   storm database wizard (CHSStormDBImportUI).
%
%   Inputs:
%     zip_name       - CHS zip folder (relative or full path), char
%     h5_file        - ADCIRC storm .h5 entry name (name + extension),
%                      char
%   Outputs:
%     vertical_datum - study vertical datum ('' if not found), char
%     sp_coords      - ADCIRC save point [latitude longitude] [deg],
%                      1x2 double ([] if either is not found)
%
%   Tier: internal
%
%   See also chs_data_attributes, zip_extract_entry, zip_h5_names.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
temp_path = tempname;
temp_cleanup = onCleanup(@() remove_temp_folder(temp_path)); %#ok<NASGU>
h5_path = zip_extract_entry(zip_name, h5_file, temp_path);
% Root Attributes Found, In The Converted CHS Data Layout Read By chs_data_attributes.m
attribute_names = {'Vertical Datum', 'Save Point Latitude', 'Save Point Longitude'};
root_attributes = struct('Name', {}, 'Value', {});
for k = 1:numel(attribute_names)
    try
        attribute_value = h5readatt(h5_path, '/', attribute_names{k});
        root_attributes(end+1).Name = attribute_names{k}; %#ok<AGROW>
        root_attributes(end).Value = attribute_value;
    catch
        % Attribute Not In The File
    end
end
CHS_Data = struct('Filename', h5_file, 'Conv_Data', struct('Attributes', root_attributes));
[vertical_datum, sp_coords] = chs_data_attributes(CHS_Data);
end

%% AUX FUNCTION: REMOVE THE TEMP FOLDER (IF CREATED)
function remove_temp_folder(temp_path)
if isfolder(temp_path)
    rmdir(temp_path, 's');
end
end

function [storm_names, is_storm] = chs_storm_file_names(file_names)
% chs_storm_file_names  Keep the CHS storm files (.h5 Peaks or Timeseries).
%   [storm_names, is_storm] = chs_storm_file_names(file_names)
%
%   CHS storm files of a list of file names: the one rule deciding which
%   CHS files CHESS reads. A storm file has a .h5 extension (any case)
%   and a Peaks or Timeseries data type token (last name token:
%   chs_file_name_parts, the CHS file name rule <region>_<storm
%   flag>_<simulation>_<post type>_SP<id>_<model>_<data type>). Every
%   other file (HC/AEP/AEF .h5 files, other extensions) is dropped
%   silently. Used where the CHS input file names are read
%   (call_input_parser: .zip and CHS_Data .mat; call_chs_data_formatter;
%   the GUI storm database wizard), so the storm file check
%   (chs_storm_file_slots, chs_study_identity, also applying it), the
%   study datum and savepoint coordinates read and the conversion lists
%   only see storm files.
%
%   Inputs:
%     file_names  - file names (folders allowed, only the name is read),
%                   cell
%   Outputs:
%     storm_names - the storm files of file_names, as given, cell
%     is_storm    - storm file flag of each file name, logical,
%                   size(file_names)
%
%   Tier: internal
%
%   See also chs_file_name_parts, chs_storm_file_slots, zip_h5_names.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
name_parts = chs_file_name_parts(file_names);
is_storm = reshape(logical([name_parts.is_storm_file]), size(file_names));
storm_names = file_names(is_storm);
end

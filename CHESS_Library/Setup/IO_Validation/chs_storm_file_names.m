function [storm_names, is_storm] = chs_storm_file_names(file_names)
%{
    %% DESCRIPTION
        CHS storm files of a list of file names: the one rule deciding which
        CHS files CHESS reads. A storm file has a .h5 extension (any case)
        and a Peaks or Timeseries data type token (last name token, as read
        by chs_h5_converter.m: <region>_<storm type>_<simulation>_<post
        type>_SP<id>_<model>_<data type>). Every other file (HC/AEP/AEF .h5
        files, other extensions) is dropped silently. Used where the CHS
        input file names are read (call_input_parser.m: .zip and CHS_Data
        .mat; call_chs_data_formater.m; chs_data_attributes.m; the GUI storm
        database wizard), so the storm file check (chs_storm_file_slots.m,
        chs_study_identity.m, also applying it), the savepoint depth/datum
        read and the conversion lists only see storm files.

    %% INPUTS
        file_names: File names (folders allowed, only the name is read). | cell

    %% OUTPUTS
        storm_names: The storm files of file_names, as given. | cell
        is_storm: Storm file flag of each file name. | logical | size(file_names)

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
is_storm = false(size(file_names));
for ff = 1:numel(file_names)
    [~, fname, fext] = fileparts(file_names{ff});
    tokens = strsplit(fname, '_');
    is_storm(ff) = strcmpi(fext, '.h5') && ismember(tokens{end}, {'Peaks', 'Timeseries'});
end
storm_names = file_names(is_storm);
end

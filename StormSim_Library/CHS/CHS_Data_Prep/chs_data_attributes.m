function [vertical_datum, sp_coords] = chs_data_attributes(CHS_Data)
%{
    %% DESCRIPTION
        Pulls the CHS study vertical datum and ADCIRC save point coordinates
        from converted CHS data (output of call_chs_h5_converter). Lets
        callers that only have a CHS_Data .mat (no .h5 files) recover the
        same details read from the .h5 root attributes ('Vertical Datum',
        'Save Point Latitude', 'Save Point Longitude'). Read from the first
        ADCIRC storm file (chs_storm_file_names.m: Peaks/Timeseries; HC/AEF
        files are ignored). The coordinates locate the savepoint in the
        CHS_Dependencies study grid (storm_db_bias_uncertainty.m).

    %% INPUTS
        CHS_Data: Converted CHS files (Filename, Conv_Data).            | struct | 1 x number_of_files

    %% OUTPUTS
        vertical_datum: Study vertical datum ('' if not found).         | char | 1 x any_length
        sp_coords: ADCIRC save point [latitude longitude] in degrees    | double | 1 x 2
                   ([] if either is not found).

    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
vertical_datum = '';
sp_coords = [];
% ADCIRC Reference File (First Storm File Found)
[~, is_storm] = chs_storm_file_names({CHS_Data.Filename});
ad_indx = find(is_storm & contains({CHS_Data.Filename}, 'ADCIRC'), 1);
if isempty(ad_indx)
    return
end
cData = CHS_Data(ad_indx).Conv_Data;
% File (Root) Attributes: Vertical Datum & Save Point Coordinates
if isfield(cData, 'Attributes') && isstruct(cData.Attributes) && ~isempty(cData.Attributes)
    att_names = {cData.Attributes.Name};
    att_indx = strcmp(att_names, 'Vertical Datum');
    if any(att_indx)
        vertical_datum = char(cData.Attributes(att_indx).Value);
    end
    lat_indx = find(strcmp(att_names, 'Save Point Latitude'), 1);
    lon_indx = find(strcmp(att_names, 'Save Point Longitude'), 1);
    if ~isempty(lat_indx) && ~isempty(lon_indx)
        sp_coords = [to_double(cData.Attributes(lat_indx).Value), to_double(cData.Attributes(lon_indx).Value)];
        if any(isnan(sp_coords))
            sp_coords = [];
        end
    end
end
end

%% AUX FUNCTION: ATTRIBUTE VALUE TO DOUBLE
function val = to_double(val)
if iscell(val)
    val = val{1};
end
if ischar(val) || isstring(val)
    val = str2double(val);
end
if isempty(val)
    val = NaN;
end
val = double(val(1));
end

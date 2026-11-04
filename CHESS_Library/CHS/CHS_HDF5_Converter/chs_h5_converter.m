function [cData] = chs_h5_converter(Filein)
% chs_h5_converter  Read a Coastal Hazards System (CHS) .h5 file into MATLAB.
%   cData = chs_h5_converter(Filein)
%
%   Converts any Coastal Hazards System (CHS) project file (.h5) and
%   imports it into the MATLAB environment. The region, data type and
%   storm type come from the file name (CHS file name rule,
%   chs_file_name_parts), the file layout version from the file
%   attributes. A single-entry file with a 'Landfall Time' column (or of
%   version 3) gets a yyyymmddHHMM datetime column after 'Storm Name',
%   and numeric storm IDs become text. Great Lakes regions
%   (mean_lake_level not 0): the ADCIRC 'Water Elevation' gets the
%   'Steric Adjustment' of each storm group and the mean lake level
%   added. Used per file by convert_chs_zip.
%
%   Inputs:
%     Filein - CHS .h5 file, name with the .h5 extension (folder allowed)
%              following the CHS file name rule, e.g.
%              NACCS_TS_SimB_Post0_SP00008_ADCIRC01_Timeseries.h5, char
%   Outputs:
%     cData - converted file, struct (1 x number_of_curves for a hazard
%             curve file (AEP, AEF, AEFcond) with several curves, else
%             1x1); fields:
%               Attributes             - file (root) HDF5 attributes
%                                        (h5info: Name, Value, ...), struct
%                                        array; files with attributes only
%               headers                - column names, 1 x
%                                        number_of_columns cell
%               units                  - column units, 1 x
%                                        number_of_columns cell
%               StormData              - data, one row per storm or curve
%                                        (Timeseries cells hold the
%                                        series), cell
%               Table_StormData        - StormData as a table (variable
%                                        names = headers), table
%               Storm_Data_Description - dataset names and descriptions
%                                        (version 2/3 files with datasets),
%                                        cell
%               StormData_Description  - hazard curve group attributes,
%                                        struct
%               Parameter              - hazard curve group name (files
%                                        with several curves), char
%             SRR files also hold headers2, units2, StormData2 and
%             Table_StormData2 (Storm Relative Probabilities), NLR files
%             header2.
%
%   Tier: public
%
%   See also convert_chs_zip, chs_file_name_parts, call_chs_data_formatter,
%   mean_lake_level.
%
%   Developed by: Fabian Garcia-Moreno, USACE-ERDC-CHL

% HISTORY:
%  Written By:  Fabian Garcia-Moreno, USACE-ERDC-CHL, Vicksburg, MS 39180
%  Date:  April 27, 2021
%  Last Modified: August 19, 2026

%-----------------------------------------------------------------------------------------------------------------------------
%% GET CHS FILE IDENTIFIERS
[chs_region, FileType, storm_type] = parse_chs_file_name(Filein);
%-----------------------------------------------------------------------------------------------------------------------------

%% CHECK HDF5 FILE HIERARCHY (VERSION, BASE LEVEL AND GROUPS CONTENTS, SPECIAL CASES)
% Get HDF5 Internal Structure
info = h5info(Filein);
layout = inspect_hdf5_layout(info, FileType);
File_version = layout.File_version;

%% GET ALL NAMELIST BASED ON CHECKS
%%%% HDF5 BASE LEVEL (info.field) %%%%
[lists, cData] = file_attribute_lists(info, layout.Has_Attributes);
[lists, cData] = file_dataset_lists(lists, cData, info, layout);

%% FIELD: GROUPS (info.Groups)
if layout.Has_Groups
    % Get File Groups Name List
    lists.FileGroups = info.Groups;
else
    lists.FileGroups = {};
end

%%%% HDF5 GROUPS LEVEL (info.Groups.field) %%%%
lists = group_attribute_lists(lists, info, layout.Has_Gattributes);
lists = group_dataset_lists(lists, info, layout);

%% BUILD DATA HEADERS
if (File_version == "V1" || File_version == "V3")
    if (layout.SRR_special==0 && layout.v1_special==0)
        [cData.headers, cData.units] = build_headers_and_units(layout, lists);

        %% EXTRACT DATA FROM HDF5
        %%%% DATA IS STORED IN GROUPS %%%%
        if layout.Has_Groups
            data = read_grouped_storm_data(Filein, info, layout, lists);
        end % END Has Groups If

    else
        %% SPECIAL CASES
        switch FileType
            case 'Peaks'
                [cData,data] = read_flat_dataset_entry(cData, Filein, info, layout, lists);
            otherwise
                [data,cData] = chs_h5_special_cases_importer(Filein,info,lists.FA_units,lists.FileDatasets,FileType);
        end
    end % END V1 Special (NLR) or SRR (Special)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% FORMAT EXPORT DATA
    % Store Extracted Data Into Output Data Structure
    cData.StormData = data;
    if ismember(FileType,{'AEP','AEF','AEFcond'}) && size(data,1) > 1
        cData = split_hazard_curve_entries(cData, data, info);
    else
        cData = format_single_entry_export(cData, data, info, FileType);
    end
else % V2
    if (layout.SRR_special==0 && layout.v1_special==0) || (File_version=="V2" && layout.SRR_special==0)
        [cData,data] = read_flat_dataset_entry(cData, Filein, info, layout, lists); %#ok<ASGLU>
    else
        [data,cData] = chs_h5_special_cases_importer(Filein,info,lists.FA_units,lists.FileDatasets,FileType); %#ok<ASGLU>
    end
end % END V1 or V2 If

if length(cData) == 1
    %% DEAL WITH LADFALL TIME
    cData = add_storm_reference_time(cData, File_version, storm_type, FileType);

    %% STORM ID Wrong Format
    cData = storm_ids_as_text(cData);
end

%% STERIC WATER LEVEL ADJUSTMENTS  + DATUM SHIFT
cData = great_lakes_water_level_adjustments(cData, chs_region, Filein);
end

%% AUX FUNCTION: CHS FILE IDENTIFIERS FROM THE FILE NAME (REGION, POST PROCESSING TYPE, FILE TYPE, STORM TYPE)
function [chs_region, FileType, storm_type] = parse_chs_file_name(Filein)
% Split Filein Path
[~,AA,~] = fileparts(Filein);
% Get CHS Identifiers
A = strsplit(AA,'_');
% Post Processing Type (Not Used; Read So A File Name With Fewer Than Four Identifiers Still Errors Here)
PostType = A{1,4}; %#ok<NASGU>
% CHS File Name Rule (chs_file_name_parts.m): Region, File Type (Last Token), Storm Type ('XC'/'TC', '' Unrecognized Flag)
name_parts = chs_file_name_parts(Filein);
chs_region = name_parts.region;
FileType = name_parts.data_type;
storm_type = name_parts.storm_type;
end

%% AUX FUNCTION: HDF5 FILE HIERARCHY (VERSION, BASE LEVEL AND GROUPS CONTENTS, SPECIAL CASES)
function layout = inspect_hdf5_layout(info, FileType)
layout.FileType = FileType;
% Check What Version Of HDF5 File Is
layout.File_version = resolve_chs_file_version(info, FileType);

% Check If HDF5 File Has Groups
layout.Has_Groups = length(info.Groups)>0; %#ok<*ISMT>
% Check If HDF5 File Has Datasets (Base Level)
layout.Has_Datasets =   length(info.Datasets)>0;
% Check If HDF5 File Has Attributes (Base Level)
layout.Has_Attributes =  length(info.Attributes)>0;

%% CHECK HDF5 GROUPS (IF ANY) INTERNAL HIERARCHY
% If File Is V1 And Has No Groups, Mark Special Case (NLR Files)
layout.v1_special = layout.Has_Groups==0;
% If File Has Groups But They're SRR's Own Non-Standard Named Subgroups, Mark Special Case
layout.SRR_special = layout.Has_Groups~=0 && strcmp(FileType,'SRR');
% Check If Groups Have Attributes
if layout.Has_Groups
    layout.Has_Gattributes =  any(cellfun(@(x) length(x)>0, {info.Groups.Attributes}));
    layout.Has_Gdatasets = any(cellfun(@(x) length(x)>0, {info.Groups.Datasets}));
    if layout.Has_Gdatasets
        layout.Has_Gdatasets_Attributes = any(cellfun(@(x) length(x)>0, {info.Groups(1).Datasets.Attributes}));
    else
        layout.Has_Gdatasets_Attributes = false;
    end
else
    layout.Has_Gattributes  = false;
    layout.Has_Gdatasets = false;
    layout.Has_Gdatasets_Attributes = false;
end
end

%% AUX FUNCTION: FILE ATTRIBUTES NAME LISTS AND UNITS (info.Attributes)
function [lists, cData] = file_attribute_lists(info, Has_Attributes)
cData = struct();
% "sp_depth_on_FA" Is Only Set When The File Has Attributes (group_attribute_lists Reads It)
if Has_Attributes
    %%%% PROCESS NAME LISTS %%%%
    % Get File Attributes Name List
    FileAttributes = info.Attributes;
    % Define File Attributes To Look For (superset covering V1/V2/V3 -- a
    % given file simply won't have the ones that don't apply to its layout)
    FA = {'Save Point ID';'Save Point Latitude';'Save Point Longitude';'Save Point Depth';'Storm Type'};
    %
    lists.sp_depth_on_FA = ismember('Save Point Depth', {FileAttributes.Name});
    % Get Location In HDF5 File Attributes Name List, In FA's Order
    [found_mask, FA_indx_raw] = ismember(FA, {FileAttributes.Name});
    FA_indx = FA_indx_raw(found_mask);
    % Add To Output Var
    cData.Attributes = FileAttributes;

    %%%% FIND UNITS ROW INDEX %%%%
    % Define File Attributes To Look For
    FA_units_dummy = {'Latitude Units';'Longitude Units';'Save Point Depth Units'};
    % Get Location In HDF5 File Attributes Name List
    FA_units_indx = ismember({FileAttributes.Name}, FA_units_dummy);
    % Initialize Units Variable
    FA_units = repmat({''},1,length(FA_indx));
    % Assigned Found Units To Storage Var
    if ~isempty(FA_indx)
        FA_units(contains({FileAttributes(FA_indx).Name},{'Lat','Lon','Depth'})) = {FileAttributes(FA_units_indx).Value};
    end
else
    FileAttributes = [];
    FA_indx = [];
    FA_units = {};
end
lists.FileAttributes = FileAttributes;
lists.FA_indx = FA_indx;
lists.FA_units = FA_units;
end

%% AUX FUNCTION: FILE DATASETS NAME LISTS, DESCRIPTIONS AND UNITS (info.Datasets)
function [lists, cData] = file_dataset_lists(lists, cData, info, layout)
if layout.Has_Datasets
    if (layout.File_version=="V2" || layout.File_version=="V3")
        %%%% HEADERS
        % Extract Dataset Info
        FileDatasets = info.Datasets;
        % Search For Storm Props In Datasets
        DS_indx = find(contains({FileDatasets.Name},{'ID','Name','Storm Type'})==1);
        % Extract From Dataset List
        dummy = FileDatasets(DS_indx);
        % Remove From List
        FileDatasets(DS_indx) = [];
        % Add to Top Of List
        FileDatasets = [dummy;FileDatasets];

        %%%% DESCRIPTIONS
        DatasetDescription = h5_attr_values({FileDatasets.Attributes}, 'Description', 'char')';
        % Assign To Output Var
        dummy = [{FileDatasets.Name}',DatasetDescription];
        cData.Storm_Data_Description = dummy(length(DS_indx)+1:end,:);
        %%%% UNITS
        FDS_units = h5_attr_values({FileDatasets.Attributes}, 'Units', 'char');

    else % V1
        FileDatasets = info.Datasets;
        FDS_units = {};
    end
else
    FileDatasets =  {};
    FDS_units = {};
end
lists.FileDatasets = FileDatasets;
lists.FDS_units = FDS_units;
end

%% AUX FUNCTION: GROUP ATTRIBUTES NAME LISTS AND UNITS (info.Groups.Attributes)
function lists = group_attribute_lists(lists, info, Has_Gattributes)
if Has_Gattributes
    %%%% PROCESS NAME LISTS %%%%
    % Taking First Group As Model For Rest
    GAttributes = info.Groups(1).Attributes;
    % Define Group Attributes To Look For
    if lists.sp_depth_on_FA
        GA = {'Storm Name';'Storm ID';'Storm Type';'Storm Group'};
    else
        GA = {'Save Point Depth';'Storm Name';'Storm ID';'Storm Type';'Storm Group'};
    end
    % Get Location In HDF5 File Attributes Name List
    [GA_found, GA_indx_raw] = ismember(GA, {GAttributes.Name});
    GA_indx = GA_indx_raw(GA_found);
    %%%% FIND UNITS ROW INDEX %%%%
    % Find Units Location In File Groups Attributes
    GA_units_indx = strcmp({GAttributes.Name}, 'Save Point Depth Units');
    % Initialize Units Variable (kept aligned with GA_indx's length regardless
    % of whether a Depth-Units attribute is actually present in this file)
    GA_units = repmat({''},1,length(GA_indx));
    if any(GA_units_indx)
        GA_units(strcmp({GAttributes(GA_indx).Name},'Save Point Depth')) = {GAttributes(GA_units_indx).Value};
    end
else
    GAttributes = {};
    GA_indx = [];
    GA_units = [];
end
lists.GAttributes = GAttributes;
lists.GA_indx = GA_indx;
lists.GA_units = GA_units;
end

%% AUX FUNCTION: GROUP DATASETS NAME LISTS AND UNITS (info.Groups.Datasets, info.Groups.Datasets.Attributes)
function lists = group_dataset_lists(lists, info, layout)
% "AEP_val" Is Only Set For AEP V1 Files With Group Dataset Attributes (read_grouped_storm_data Reads It)
FileType = layout.FileType;
File_version = layout.File_version;
%% FIELD: GROUPS DATASETS (info.Groups.Datasets)
if layout.Has_Gdatasets
    %%%% PROCESS NAME LISTS %%%%
    % Taking First Group As Model For Rest
    GDatasets = info.Groups(1).Datasets;
    % Identify yyyymmddHHMM Col In Datasets
    GDS_indx = find(strcmp({GDatasets.Name},'yyyymmddHHMM')==1);
    % Move yyyymmmddHHMM Col
    if ~isempty(GDS_indx) % This Only Applies To V1 Files
        % Reorder Group Dataset Name List
        GDatasets =  [GDatasets(GDS_indx);GDatasets(1:GDS_indx-1);GDatasets(GDS_indx+1:end)];
    end

else
    GDatasets = {};
end

%% FIELD: GROUPS DATASETS ATTRIBUTES (info.Groups.Datasets.Attributes)
if layout.Has_Gdatasets_Attributes

    %%%% PROCESS NAME LISTS %%%%
    % Taking First Group As Model For Rest
    GDatasetsAttributes = {GDatasets.Attributes};
    %%%% FIND UNITS ROW INDEX %%%%
    % Find Units Location In Group Datasets Attributes
    GDA_units = h5_attr_values(GDatasetsAttributes, 'Units', 'char');
    if (FileType == "AEP" && File_version == "V1")
        % Add AEP Values
        AEP_val = GDatasetsAttributes{1};
        lists.AEP_val = str2double(split(AEP_val(contains({AEP_val.Name},{'AEP'})).Value,','));
        %
        GDA_units = [{'yr^-1'},GDA_units];
    end
else
    GDA_units = {};
end
lists.GDatasets = GDatasets;
lists.GDA_units = GDA_units;
end

%% AUX FUNCTION: READ STORM DATA STORED IN GROUPS (ONE GROUP PER STORM; V1/V3)
function data = read_grouped_storm_data(Filein, info, layout, lists)
FileType = layout.FileType;
File_version = layout.File_version;
FileAttributes = lists.FileAttributes;
FA_indx = lists.FA_indx;
FileGroups = lists.FileGroups;
GAttributes = lists.GAttributes;
GA_indx = lists.GA_indx;
GDatasets = lists.GDatasets;
% Initialize Data Storage Var
data = {};
%%%% FILE ATTRIBUTES %%%%%
if layout.Has_Attributes
    % Convert Any Character-Stored Numeric Values (e.g. Lat/Lon/Depth) To Numbers
    dummy = numeric_convert_char_values({FileAttributes(FA_indx).Value});
    % Allocate Attributes To Data Matrix (Assuming: SP spatial coords are constant for all storms in dataset)
    data = [data,repmat(dummy,length(FileGroups),1)];
end
%%%% GROUPS ATTRIBUTES %%%%
if layout.Has_Gattributes
    % Find Save Point Depth Location In Group Attributes (Assuming: constant for all storms in dataset)
    % (Index Into GAttributes, Not Into The GA_indx Subset)
    dummy_indx = GA_indx(strcmp({GAttributes(GA_indx).Name},'Save Point Depth'));
    % Change Save Point Depth To Number
    if ~isempty(dummy_indx) && (ischar(GAttributes(dummy_indx).Value) || isstring(GAttributes(dummy_indx).Value))
        GAttributes(dummy_indx).Value = str2double(GAttributes(dummy_indx).Value);
    end
    % Repeate Save Point Depth For All Storms In Dataset
    dummy = repmat({GAttributes(dummy_indx).Value},length(FileGroups),1);
    % If Save Point Depth Was Found Then Add It To Output Var
    if ~isempty(dummy)
        data = [data,dummy];
    end

end
%%%% READ MISSING FIELDS %%%%
%%%%%%%%%%%                       % Define Group Attributes To Look For
GA = {GAttributes(GA_indx).Name};
GA = GA(strcmp('Save Point Depth',GA)==0);
%%%%%%%                     % Initialize Dummy Storage Vars
nStorms = length(FileGroups(:,1));
DScat = cell(nStorms, length(GDatasets));
GAcat = cell(nStorms, length(GA));
for stm = 1:nStorms
    % Get Location In HDF5 File Attributes Name List
    [GA_found2, GA_indx2_raw] = ismember(GA, {FileGroups(stm).Attributes.Name});
    % Get Storm Dependant Group Attributes
    GA_dummy = {FileGroups(stm).Attributes(GA_indx2_raw(GA_found2)).Value};

    % Get Storm Group Attributes
    GAcat(stm, :) = GA_dummy;
    % Loop Through ALl Datasets
    for DS = 1:length(GDatasets)
        % Datasets
        try
            if strcmp(GDatasets(DS).Name,'yyyymmddHHMM')
                raw = h5_read_typed(Filein,[info.Groups(stm).Name,'/',GDatasets(DS).Name],GDatasets(DS),FileType);
                DScat(stm,DS) = cellfun(@(x) datetime(num2str(x,'%012d'),'InputFormat','yyyyMMddHHmm'), raw, 'un',false);
            else
                DScat(stm,DS) = h5_read_typed(Filein,[info.Groups(stm).Name,'/',GDatasets(DS).Name],GDatasets(DS),FileType);
            end
        catch % Missing Data Filler
            if strcmp(GDatasets(DS).Name,'yyyymmddHHMM')
                DScat(stm,DS) = {NaT};
            else
                DScat(stm,DS) = {'NaN'};
            end
        end
        %
    end
end

if (FileType == "AEP" && File_version == "V1")
    AEP_val = lists.AEP_val;
    % Add To Output Var (replicate AEP_val across rows unless there's only one)
    if size(DScat,1) == 1
        data = [data,GAcat,{AEP_val},DScat];
    else
        data = [data,GAcat,repmat({AEP_val},size(DScat,1),1),DScat];
    end
else
    % Add To Output Var
    data = [data,GAcat,DScat];
end
end

%% AUX FUNCTION: SPLIT A MULTI-ROW HAZARD CURVE FILE (AEP/AEF/AEFcond) INTO ONE cData ENTRY PER GROUP
function cData = split_hazard_curve_entries(cData, data, info)
% V2 Hazard Curves (SWL,Hm0, Tp in same file) -- genuinely multi-row, no V2-path equivalent
% Repeat cData  for each dataset
for ll = 2:length(data(:,1))
    cData(ll).Attributes = cData(1).Attributes;
    cData(ll).units = cData(1).units;
    cData(ll).headers = cData(1).headers;
    cData(ll).StormData = cData(1).StormData(ll,:);
end
% Remove Extra Entries
cData(1).StormData = cData(1).StormData(1,:);
% Loop Through Hazard Curve Files
for ll = 1:length(data(:,1))
    % Store Table Data
    cData(ll).Table_StormData = cell2table(expand_aep_cells(data(ll,:)),'VariableNames',cData(ll).headers);
    % Group Attributes
    cData(ll).StormData_Description = info.Groups(ll).Attributes;
    % Fix Units
    cData(ll).units(5:end) = repmat({info.Groups(ll).Datasets(3).Attributes(2).Value},1,length(cData(ll).units(5:end)));
    % Add Parameter Field
    cData(ll).Parameter = info.Groups(ll).Name;
end
end

%% AUX FUNCTION: STORM DATE-TIME COLUMN (yyyymmddHHMM) FROM THE LANDFALL / REFERENCE TIME
function cData = add_storm_reference_time(cData, File_version, storm_type, FileType)
if any(contains(cData.headers, {'Landfall Time'})) || File_version == "V3"
    % Find Peak Time Index
    p_indx = find(strcmp(cData.headers, 'Storm Name'));
    % Find Reference Time Header Index
    l_indx = find(strcmp(cData.headers, 'Landfall Time'));
    % Timeseries Flag
    if isempty(l_indx)
        % Find Reference Time Header Index
        l_indx = find(strcmp(cData.headers, 'Time'));
    end
    % Grab Reference Time
    switch File_version
        case "V2"
            ref_time = strsplit(lower(cData.units{l_indx}), {'hrs since ', 'z', 'utc'});
            time_f = @(x) hours(x);
        case "V3"
            ref_time = strsplit(lower(cData.units{l_indx}), {'seconds since ', 'z','utc'});
            time_f = @(x) second(x);
    end
    if any(strcmp(cData.headers, 'Peak Time'))
        peak_time = cellfun(@(x) time_f(x), cData.StormData(:, string(cData.headers)=="Peak Time"),'un',false);
    else
        peak_time =  cellfun(@(x) zeros(size(x)), cData.StormData(:, l_indx),'un',false);
    end
    ref_time = datetime(ref_time{2},'InputFormat','yyyy-MM-dd HH:mm:SS','Format', 'yyyyMMddHHmm');

    % Grab Peak Time
    switch storm_type
        case 'XC'
            switch FileType
                case 'Peaks'
                    total_time = datetime([char(cData.Table_StormData.("Storm Name")), repmat('00', height(cData.Table_StormData), 1)], 'InputFormat', 'yyyyMMddHHmm');
                case 'Timeseries'
                    total_time =  cellfun(@(x,y) ref_time+time_f(x)-time_f(y), cData.StormData(:, l_indx), peak_time, 'UniformOutput', false);
            end
        otherwise
            total_time =  cellfun(@(x,y) ref_time+time_f(x)-time_f(y), cData.StormData(:, l_indx), peak_time, 'UniformOutput', false);
    end

    cData.headers = [cData.headers(1:p_indx), {'yyyymmddHHMM'}, cData.headers(p_indx+1:end)];
    cData.units = [cData.units(1:p_indx), {''}, cData.units(p_indx+1:end)];
    cData.StormData = [cData.StormData(:, 1:p_indx), num2cell(total_time), cData.StormData(:, p_indx+1:end)];
    cData.Table_StormData = [cData.Table_StormData(:, 1:p_indx), table(total_time, 'VariableNames', {'yyyymmddHHMM'}), cData.Table_StormData(:, p_indx+1:end)];
end
end

%% AUX FUNCTION: NUMERIC STORM IDs CONVERTED TO TEXT (StormData AND Table_StormData)
function cData = storm_ids_as_text(cData)
if any(strcmp(cData.headers, "Storm ID"))
    if ~ischar(cData.Table_StormData.("Storm ID")(1))
        % Get Storm ID Col Index
        col_indx = strcmp('Storm ID', cData.headers);
        % Convert Form Number To Char (Table)
        cData.Table_StormData.("Storm ID") = cellfun(@num2str, cData.StormData(:, col_indx), 'UniformOutput', false);
        % Convert From Number To Char
        cData.StormData(:, col_indx) = cellfun(@num2str, cData.StormData(:, col_indx), 'UniformOutput', false);
    end
end
end

%% AUX FUNCTION: GREAT LAKES STERIC WATER LEVEL ADJUSTMENT + DATUM SHIFT (ADCIRC FILES)
function cData = great_lakes_water_level_adjustments(cData, chs_region, Filein)
lake_level = mean_lake_level(struct('region', chs_region));
if lake_level ~= 0
    % Steric Adjustment
    [cData] = steric_adjustment(cData, Filein);
    % Datum Adjustment
    [cData] = datum_adjustment(cData, lake_level, Filein);
end
end

%% AUX FUNCTION: CHARACTER-STORED NUMERIC VALUES CONVERTED TO NUMBERS
function vals = numeric_convert_char_values(vals)
% Converts any char-valued entries in a cell array to double, leaving
% already-numeric entries untouched -- content-driven, not positional
% (replaces the old approach of hardcoding which index positions were
% expected to be numeric).
for kk = 1:length(vals)
    % Make Sure Its In Fact A String
    fail_test = all(isnan(str2double(vals{kk})));
    if fail_test % True Means Failure , hence its a string
        % Do Nothing
        continue;
    else % its a number stored as a string
        vals{kk} = str2double(vals{kk});
    end
end
end

%% AUX FUNCTION: DATA HEADERS AND UNITS
function [headers, units] = build_headers_and_units(layout, lists)
% Assembles headers/units from whichever HDF5 fields are actually present
% in this file (Has_* flags) -- shared by both the Groups-based (V1/V3)
% and flat (V2) extraction paths, so header/units assembly no longer needs
% its own File_version branch.
FileType = layout.FileType;
File_version = layout.File_version;
Has_Attributes = layout.Has_Attributes;
Has_Gattributes = layout.Has_Gattributes;
Has_Datasets = layout.Has_Datasets;
Has_Gdatasets = layout.Has_Gdatasets;
FileAttributes = lists.FileAttributes;
FA_indx = lists.FA_indx;
FA_units = lists.FA_units;
GAttributes = lists.GAttributes;
GA_indx = lists.GA_indx;
GA_units = lists.GA_units;
FileDatasets = lists.FileDatasets;
FDS_units = lists.FDS_units;
GDatasets = lists.GDatasets;
GDA_units = lists.GDA_units;
if (FileType == "AEP" && File_version == "V1")
    headers = [{FileAttributes(FA_indx).Name},{GAttributes(GA_indx).Name},{'AEP Values'},{GDatasets.Name}];
    units = [FA_units,GA_units,GDA_units];
else
    headers = {};
    units = {};
    if Has_Attributes,  headers = [headers, {FileAttributes(FA_indx).Name}]; units = [units, FA_units]; end
    if Has_Gattributes, headers = [headers, {GAttributes(GA_indx).Name}];    units = [units, GA_units]; end
    if Has_Datasets,    headers = [headers, {FileDatasets.Name}];            units = [units, FDS_units]; end
    if Has_Gdatasets,   headers = [headers, {GDatasets.Name}];               units = [units, GDA_units]; end
end
end

%% AUX FUNCTION: CHS FILE VERSION (V1/V2/V3)
function File_version = resolve_chs_file_version(info, FileType)
% Determines the CHS file version ("V1"/"V2"/"V3") from the file's own
% declared version attribute (CHS File Format / CHS Data Format), with a
% Timeseries-specific override: Timeseries files are always treated as V1
% unless the file is genuinely V3.
versions_to_look = {'V2','Version_1','V3','V1'};
versions = ["V2","V1","V3","V1"];

has_versioned_attr = ismember(string({info.Attributes.Name}), ["CHS File Format","CHS Data Format"]);
if ~any(has_versioned_attr)
    dummystr = '<a href="matlab: web(''https://chswebtool.erdc.dren.mil/'')">here</a>';
    error(['Error: Unrecognized CHS hdf5 storm data file. Please download data from ',dummystr,'']);
end
if sum(has_versioned_attr)>1 % V2 File Indication
    chs_file_version = info.Attributes(ismember({info.Attributes.Name}, 'CHS File Format')).Value;
    if string(chs_file_version) ~= "V3"
        if contains(FileType,{'AEFcond','AEF'})
            has_versioned_attr = ismember({info.Attributes.Name}, 'CHS Data Format');
        else
            has_versioned_attr = ismember({info.Attributes.Name}, 'CHS File Format');
        end
    else
        has_versioned_attr = ismember({info.Attributes.Name}, 'CHS File Format');
    end
end
File_version = versions(strcmp(info.Attributes(has_versioned_attr).Value,versions_to_look));
% CHS Timeseries files always use V1 format regardless of header attribute, except when the file is actually V3
if strcmp(FileType, 'Timeseries') & File_version ~= "V3"
    File_version = "V1";
end
end

%% AUX FUNCTION: DATUM SHIFT OF THE WATER ELEVATION (ADCIRC FILES)
function [CHS_Data] = datum_adjustment(CHS_Data, datum_shift, Filein)
% Find Row For ADCIRC HDF5 File
ad_bool = contains(Filein, 'ADCIRC');

if any(ad_bool)
    % Get SSL Header Location
    ssl_indx = strcmp(CHS_Data.headers, {'Water Elevation'});
    % Apply Steric Adjustments (StormData)
    CHS_Data.StormData(:, ssl_indx) = cellfun(@(x) x+datum_shift,...
        CHS_Data.StormData(:, ssl_indx), 'un', false);
    % Apply Steric Adjustments (Table_StormData)
    CHS_Data.Table_StormData.('Water Elevation') = cellfun(@(x) x+datum_shift,...
        CHS_Data.Table_StormData.('Water Elevation'), 'un', false);
end
end

%% AUX FUNCTION: STERIC ADJUSTMENT OF THE WATER ELEVATION (ADCIRC FILES)
function [CHS_Data] = steric_adjustment(CHS_Data, Filein)
% Find Row For ADCIRC HDF5 File
ad_bool = contains(Filein, 'ADCIRC');
if any(ad_bool)
    % Grab Storm Group H5 Keys
    hinfo = h5info(Filein);
    % Get Steric Adjustments (datatype taken from the first group, same "model for the rest" convention used elsewhere in this file)
    attrInfo = {hinfo.Groups.Attributes};
    steric_adj = h5_attr_values(attrInfo, 'Steric Adjustment', 'number');
    % Get SSL Header Location
    ssl_indx = strcmp(CHS_Data.headers, {'Water Elevation'});
    CHS_Data.StormData(:, ssl_indx) = cellfun(@(x, y) x+y,...
        CHS_Data.StormData(:, ssl_indx), steric_adj(:), 'un', false);
    % Apply Steric Adjustments (Table_StormData)
    CHS_Data.Table_StormData.('Water Elevation') = cellfun(@(x, y) x+y,...
        CHS_Data.Table_StormData.('Water Elevation'), steric_adj(:), 'un', false);
end
end

%% AUX FUNCTION: SINGLE-ENTRY EXPORT TABLE (Table_StormData)
function cData = format_single_entry_export(cData, data, info, FileType)
% Shared single-entry table-building tail for AEP/AEF/AEFcond files (V1/V2/V3 alike)
% and for the plain (non-AEP-family) case. The V1/V3 multi-row Hazard Curve case
% (multiple storm-group entries in one file) is handled separately by the caller
% before this is reached.
if ismember(FileType,{'AEP','AEF','AEFcond'})
    % Group Attributes
    cData.StormData_Description = info.Groups.Attributes;
    data = expand_aep_cells(data);
end
cData.Table_StormData = cell2table(data,'VariableNames',cData.headers);
end

%% AUX FUNCTION: HAZARD CURVE ROW EXPANDED TO ONE ROW PER CURVE VALUE
function expanded = expand_aep_cells(data_row)
% Expands a 1-x-N cell row where some cols hold vectors and others hold
% scalars into an nRows-x-N cell array ready for cell2table.
n_rows      = length(data_row{end});
n_cols      = length(data_row);
expanded    = cell(n_rows, n_cols);
vec_cols    = cellfun(@(x) length(x) > 1, data_row);
scalar_cols = ~vec_cols;
for ii = find(vec_cols)
    expanded(:, ii) = num2cell(data_row{ii});
end
expanded(:, scalar_cols) = repmat(data_row(scalar_cols), n_rows, 1);
end

%% AUX FUNCTION: HDF5 DATASET READ WITH ITS DECLARED TYPE
function val = h5_read_typed(Filein, path, datasetInfo, FileType)
% Reads an HDF5 dataset and casts it to double unless the dataset's own
% declared HDF5 datatype is a string -- the double-vs-char decision is
% driven entirely by datasetInfo.Datatype.Class (as reported by h5info),
% not by which code path happens to call this.
val = h5read(Filein, path);
switch datasetInfo.Datatype.Class
    case 'H5T_STRING'
        % Make Sure Its In Fact A String
        fail_test = all(isnan(str2double(val)));

        if fail_test % True Means Failure , hence its a string
            val = char(val);
        else % its a number stored as a string
            val = str2double(val);
        end
    otherwise % Expect Numerical Fields
        val = double(val);
end
switch FileType
    case {'Peaks','NLR','SRR'}
        if ischar(val(1))
            val = cellstr(val);
        else
            val = num2cell(val);
        end
    otherwise
        val = {val};
end
end

%% AUX FUNCTION: HDF5 ATTRIBUTE VALUES PER ELEMENT
function vals = h5_attr_values(attributesList, attrName, data_type)
% Applies h5_attr_value across a list of per-element Attributes struct
% arrays (e.g. {FileDatasets.Attributes}), returning one value per element,
% each defaultVal if that element doesn't have the named attribute.
vals = repmat({''}, 1, length(attributesList));
for kk = 1:length(attributesList)
    if ~isempty(attributesList{kk})
        row_indx = strcmp({attributesList{kk}.Name}, attrName);
        if any(row_indx)
            %
            vals{kk} = attributesList{kk}(row_indx).Value;
            switch data_type
                case 'char'
                    if ~ischar(vals{kk})
                        vals{kk} = char(vals{kk});
                    end
                case 'number'
                    if ischar(vals{kk})
                        vals{kk} = str2double(vals{kk});
                    end
            end
        elseif strcmp(data_type,'number')
            % 'char' not-found case already defaults to '' from initialization above
            vals{kk} = [];
        elseif strcmp(data_type,'char')
            vals{kk} = {''};
        end
    else
        if strcmp(data_type,'number')
            % 'char' not-found case already defaults to '' from initialization above
            vals{kk} = [];
        elseif strcmp(data_type,'char')
            vals{kk} = {''};
        end
    end
end
end

%% AUX FUNCTION: READ A FLAT DATASET FILE (V2, OR GROUPLESS V1 PEAKS)
function [cData,data] = read_flat_dataset_entry(cData, Filein, info, layout, lists)
% Shared by both genuinely-V2 files and flat/groupless V1 "Peaks" files --
% both read datasets directly off the file's flat FileDatasets list.
FileType = layout.FileType;
Has_Attributes = layout.Has_Attributes;
FileAttributes = lists.FileAttributes;
FA_indx = lists.FA_indx;
FileDatasets = lists.FileDatasets;
% BUILD DATA HEADERS
[cData.headers, cData.units] = build_headers_and_units(layout, lists);

% PULL DATA FROM HDF5 V2 FILE
data = [];
% Loop Through ALl Datasets
for DS = 1:length(FileDatasets)
    % Read Datasets
    dummy  = h5_read_typed(Filein,['/',FileDatasets(DS).Name],FileDatasets(DS),FileType);

    data = [data,dummy];
end
%%%% ADD DATA FROM ATTRIBUTES IF ANY %%%%
if Has_Attributes
    data = [repmat(numeric_convert_char_values({FileAttributes(FA_indx).Value}),size(data,1),1),data];
end

%% FORMAT EXPORT DATA V2
% Store Extracted Data Into Output Data Structure
cData.StormData = data;
cData = format_single_entry_export(cData, data, info, FileType);
end

%% AUX FUNCTION: SPECIAL CASES (SRR, NLR)
function [data,cData] = chs_h5_special_cases_importer(Filein,info,FA_units,FileDatasets,FileType)
switch FileType
    case 'SRR'

        %% SPECIAL CASES: CHS HDF5 V1 SRR
        %%%% GROUP DATASETS %%%%
        % Get "Storm Rate" Group -- Always Present
        srr_group = info.Groups(contains({info.Groups.Name},{'/Storm Rate'}));
        GDatasets1 = srr_group.Datasets;
        % Get "Storm Relative Probabilities" Group -- Optional, Not Every SRR File Has One
        srp_mask = contains({info.Groups.Name},{'/Storm Relative Probabilities'});
        has_srp = any(srp_mask);
        if has_srp
            srp_group = info.Groups(srp_mask);
            GDatasets2 = srp_group.Datasets;
        end

        %%%% PULL COORDINATE DATA (SHARED BY BOTH TABLES) %%%%
        % Get Coordinate Data: Save Point ID, Latitude, Longitude
        [coord_pass, coord_idx] = ismember('Save Point Locations', {info.Datasets.Name});
        if any(coord_pass)
            coord_data = h5_read_typed(Filein,'/Save Point Locations',info.Datasets(coord_idx),FileType)';
            ds_headers = h5_attr_values({info.Datasets(coord_idx).Attributes}, 'Columns', 'char');
            ds_headers = strsplit(ds_headers{:}, {' ',','});
            coord_units = {'','deg','deg'};
            % The Dataset's "Columns" Attribute Claims A Fixed [ID,Lat,Lon] Order, But This
            % Is Not Reliable Across File Vintages -- Confirmed Empirically: Legacy SRR
            % Files Can Physically Store [ID,Lon,Lat] While Advertising The Same
            % "ID, Latitude, Longitude" Attribute Text As Newer Files That Really Are
            % [ID,Lat,Lon]. Resolve By Sign Instead Of Trusting The Attribute -- Every CHS
            % Region Is Northern/Western Hemisphere, So Latitude Is Always Positive And
            % Longitude Is Always Negative.
            if mean(cell2mat(coord_data(:,2))) < 0
                coord_data = coord_data(:,[1 3 2]);
            end
        else
            ds_headers = {''};
            coord_units = {''};
        end

        %%%% PRIMARY TABLE: Save Point ID/Lat/Lon, SRR_<Storm Rate dataset name> %%%%
        % Header Per Dataset Is Dynamic -- Available SRR Intensity Classes Vary By File
        cData.headers = [ds_headers,strcat('SRR_',{GDatasets1.Name})];
        cData.units = [coord_units,h5_attr_values({GDatasets1.Attributes}, 'Units', 'char')];
        %{
        Importing HDF5 data as a self contained cell array first is much
        faster thant importing the full list as an array
        %}

        row_num = max(GDatasets1(1).Dataspace.MaxSize);
        col_num = size(coord_units, 2)+length(GDatasets1);

        data = repmat({0}, row_num, col_num);
        data(:, 1:3) = coord_data;

        for DS = 1:length(GDatasets1)
            % Read Datasets For Group
            data(:, 3+DS)  = h5_read_typed(Filein,[srr_group.Name,'/',GDatasets1(DS).Name],GDatasets1(DS),FileType);
        end

        cData.StormData = data;
        cData.Table_StormData = cell2table(data,'VariableNames',cData.headers);

        %%%% SECONDARY TABLE: Save Point ID/Lat/Lon, <Storm Relative Probabilities dataset name> %%%%
        % Mirrors The StormData/Table_StormData Pattern, Under A "2" Suffix, Since This Is A
        % Second, Independently-Shaped Table -- Only Built When The Group Is Present.
        if has_srp
            headers2 = [ds_headers,{GDatasets2.Name}];

            row_num = GDatasets2(1).Dataspace.MaxSize;
            col_num = size(coord_units, 2)+length(GDatasets2);

            data2 = repmat({0}, row_num, col_num);
            data2(:, 1:3) = coord_data;

            for DS = 1:length(GDatasets2)
                % Read Datasets For Group
                data2(:, 3+DS)  = h5_read_typed(Filein,[srp_group.Name,'/',GDatasets2(DS).Name],GDatasets2(DS),FileType);
            end
            cData.headers2 = headers2;
            cData.units2 = [coord_units,h5_attr_values({GDatasets2.Attributes}, 'Units', 'char')];
            cData.StormData2 = data2;
            cData.Table_StormData2 = cell2table(data2,'VariableNames',headers2);
        end
    case {'NLR'}

        %%%% DATASETS
        % Fill Empty Attributes
        empty_attrs = cellfun(@(x) isempty(x), {FileDatasets.Attributes});
        [FileDatasets(empty_attrs).Attributes] = deal(struct('Name','Units','Value',''));
        % Define String Pattern To Search
        FA = {'Save Point ID','Save Point Latitude','Save Point Longitude'};
        % Find Within Datasets
        [~, FA_indx] = ismember(FA, {FileDatasets.Name});
        % Extract Found Objects
        dummy = FileDatasets(FA_indx);
        % Remove From Original Listing
        FileDatasets(FA_indx) = [];
        % Reorder
        FileDatasets = [dummy;FileDatasets];

        %%%% HEADERS
        cData.headers = {FileDatasets.Name};
        % Header 2
        cData.header2 = h5_attr_values({FileDatasets.Attributes}, 'Data Variable', 'char');

        %%%% UNITS
        cData.units = h5_attr_values({FileDatasets.Attributes}, 'Units', 'char');

        %%%% PULL DATA
        data=[];
        % Loop Through ALl Datasets
        for DS = 1:length(FileDatasets)
            % Read Datasets
            dummy = h5_read_typed(Filein,['/',FileDatasets(DS).Name],FileDatasets(DS),FileType);
            data = [data,dummy];
        end
end
end
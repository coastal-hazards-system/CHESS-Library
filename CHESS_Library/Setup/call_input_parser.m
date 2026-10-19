function [config, structure] = call_input_parser(input_filename)
%{
    %% DESCRIPTION
    This function parses CHESS's project input file and creates "config"
    data structure. Variable names are controlled by symbols in "str_ref"
    column.
    CHS input (.zip / CHS_Data .mat): the storm files are checked by name
    (chs_storm_file_slots.m: one study identity, chs_study_identity.m, and
    one ADCIRC + one wave file per slot) before any unzip, and a TC/CC request needs
    CHS_Dependencies for the region (chs_dependencies_available.m).
    A .zip input is never unzipped here: the savepoint depth is read from
    the first ADCIRC .h5 entry alone, extracted to a system temp folder
    (tempname) removed before returning; call_chs_data_formater.m unzips
    the input when it converts it.
    Storm .mat input (storm + prob_mass): validated, checked against this
    run's request and saved as the storm database with its db_info
    (storm_db_info.m; Nyrs_XC/Nstm_XC moved out of storm.XC). An existing
    storm database's db_info is applied to config.

    %% INPUTS
    fname: CHESS project input file name.
    
    %% OUTPUTS
    config: MATLAB data structure containing input file data parsed out as
    individual strucutre fields.
    
    %R DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}

%% GRAB AND DEFINE INPUTS
% Add Filename To Config
config.chess_input_file = input_filename;
% Add Gravity Constant
config.gravity_constant = 9.80665; % m/s^2

%% PARSE INPUT FILE AND CREATE CONFIG STRUCTURE
% Every Section Row Of The Input File (.xlsx Or .csv, Layout Independent: read_chess_input.m), By Symbol (Last Wins)
[~, input_rows] = read_chess_input(input_filename);
for jj = 1:size(input_rows, 1)
    config.(input_rows{jj, 1}) = input_rows{jj, 4};
end
%
if ~ismember(config.workflow, [1,2,3,4])
    error('Error: config.workflow must be 1 (PROS), 2 (DET), 3 (LCS), or 4 (PROS-FB).');
end
% Make Sure Specified File Exist
if ~exist(config.chs_zip, 'file') % Valid Zip Folder Detected
    error('Error: Provided file through config.chs_zip not found. Please verify path...');
end
% Get File Extension For "config.chs_zip"
[~,fname, fext] = fileparts(config.chs_zip);
% Get config.chs_zip Data Type
data_case = identify_storm_data_type(config.chs_zip);

%% GRAB STUDY DETAILS
% CHS Region & Savepoint ID Come From The Provided Data (File Names). They Name The Storm
% Database (<region>_SP<sp_ID>) Unless config.storm_db Is Given, So They Are Read First.
switch data_case
    case 'chs_data'
        switch fext
            case '.mat'
                % Load CHS_Data
                load(config.chs_zip, 'CHS_Data');
                % Storm File Names From Loaded Data Structure
                [file_list_paths, file_list, h5_ext] = ...
                    cellfun(@fileparts, chs_storm_file_names({CHS_Data.Filename}), 'un', false);
                file_list = strcat(file_list, h5_ext);
            case '.zip'
                % Storm .h5 File Names In The Zip Folder (No Decompression)
                file_list = chs_storm_file_names(zip_h5_names(config.chs_zip));
        end
        % Study Identity, Storm File Slots & This Run's Request, By File Name (Before Any Unzip Or Conversion)
        [~, slot_errors, study] = chs_storm_file_slots(file_list, run_request(config));
        if ~isempty(slot_errors)
            error('Error: CHS input ''%s'' does not meet the storm data requirements: %s.', config.chs_zip, strjoin(slot_errors, '; '));
        end
        % CHS Study Details (Region, ADCIRC & Wave Save Points) From The Storm File Names
        config.region = study.region;
        config.sp_ID = study.sp_ID;
        config.sp_ID_wave = study.sp_ID_wave;
        % Without CHS_Dependencies For The Region CHESS Runs XC Only (TC Needs Its Probability Masses)
        if ~strcmp(config.storm_sampling, 'XC') && ~chs_dependencies_available(config.chs_dependencies, config.region)
            error(chs_dependencies_message(config.storm_sampling, config.region));
        end
    case 'storm_data'
        % Add CHS Files 2 Convert In Cell Array
        config.chs_files_2_convert = cell(0, 2);
        % Try To Find Savepoint ID On Filename
        if contains(fname, {'SP'})
            sp_id = strsplit(fname, {'_'});
            sp_id = sp_id{contains(sp_id, {'SP'})};
            sp_id = str2double(strrep(sp_id,'SP',''));
            config.sp_ID = sp_id;
        else
            % Define Save Point ID As Empty
            config.sp_ID = 1;
        end
        config.sp_ID_wave = []; % Not important
        % Try And Find CHS Region On File Name
        if contains(fname, {'CHS-'})
            chs_region = strsplit(fname, '_');
            chs_region = chs_region{contains(chs_region, {'CHS-'})};
            config.region = chs_region;
        else
            config.region = 'Custom_Modeling';% User Needs To Provide Prob Mass
        end
        % Storm Database Named After The Provided File (Different Storm .mat Files Never Share A Database)
        if ~isfield(config, 'storm_db') || isempty(config.storm_db)
            config.storm_db = fname;
        end
end

%% STORM DATABASE & ALTERNATIVE FOLDERS
% <outfolder>\<project>\Event_Database\<db>.mat (+ _raw_files.mat), Shared By Every PSE/Alternative;
% Run Files Under <outfolder>\<project>\PSE\<struc_id>\<case_name>\<workflow folder> (chess_paths.m)
paths = chess_paths(config);
if ~exist(paths.event_db_dir,'dir')
    mkdir(paths.event_db_dir);
end
if ~exist(paths.wf_dir,'dir')
    mkdir(paths.wf_dir);
end

%% VERIFY IF CHESS FILES ALREADY EXIST FOR CURRENT SIMULATION
chess_storm = isfile(paths.storm_db); % Existing storm .mat created by CHESS
chess_raw = isfile(paths.chs_data); % Existing CHS_Data .mat created by CHESS
% Check For CHESS Processed storm .mat: Its db_info Sets Nyrs_XC/Nstm_XC, TC Bias Correction, Bias & Uncertainty
if chess_storm
    db_info = [];
    if any(strcmp(who('-file', paths.storm_db), 'db_info'))
        load(paths.storm_db, 'db_info');
    end
    if storm_db_info('valid', db_info)
        config = storm_db_info('apply', db_info, config);
    elseif strcmp(data_case, 'storm_data')
        % Older Database (No db_info) Of A Storm .mat Input: Created Again From The Provided File Below
        chess_storm = false;
    end
    % CHS Input Without db_info: call_chs_data_formater.m Rebuilds The Database From The Raw File (Or Stops)
end

%% GRAB CHS_DATA DETAILS
% This code section is executed if user provided a "CHS_Data" type dataset
% through config.chs_zip. This can be a .mat file or .zip folder (with HDF5 files).
if strcmp(data_case, 'chs_data')
    switch fext
        case '.mat'
            % Write Out Files On Loaded Data
            config.chs_files_2_convert = [file_list_paths(:), file_list(:)];
            % Savepoint Coordinates On Converted HDF5 Attributes (Study Grid Lookup When The Storm Database Is Built)
            [~, sp_coords] = chs_data_attributes(CHS_Data);
            config = set_sp_coords(config, sp_coords, 'CHS_Data attributes');
            % Copy File To Add Naming Convention
            if ~chess_raw
                copyfile(config.chs_zip, paths.chs_data);
            end
        case '.zip'
            if chess_raw
                % Load CHESS Processed CHS_Data
                load(paths.chs_data, 'CHS_Data');
                % Storm File Names From Loaded Data Structure
                [file_list_paths, file_list, h5_ext] = ...
                    cellfun(@fileparts, chs_storm_file_names({CHS_Data.Filename}), 'un', false);
                file_list = strcat(file_list, h5_ext);
                % Write Out Files On Loaded Data
                config.chs_files_2_convert = [file_list_paths(:), file_list(:)];
                % Savepoint Coordinates On Converted HDF5 Attributes (Study Grid Lookup When The Storm Database Is Built)
                [~, sp_coords] = chs_data_attributes(CHS_Data);
                config = set_sp_coords(config, sp_coords, 'CHS_Data attributes');
            else
                % File Names Only: call_chs_data_formater.m Unzips The Input (System Temp Folder) Right Before Conversion
                config.chs_files_2_convert = [repmat({''}, numel(file_list), 1), file_list(:)];
                % Savepoint Coordinates On The HDF5 Attributes Of The First ADCIRC Storm File (Only That Entry Extracted)
                sp_coords = zip_sp_coords(config.chs_zip, file_list(contains(file_list, 'ADCIRC')));
                config = set_sp_coords(config, sp_coords, 'h5 attributes');
            end
    end
end

%% GRAB STORM DETAILS
% This code section is executed if user provided a "storm" type dataset
% through config.chs_zip. "storm" meaning a dataset containing surge and
% wave data for each event matched in time.
if ~chess_storm && strcmp(data_case, 'storm_data')
    % Load storm & prob_mass From Provided .mat
    load(config.chs_zip, 'storm', 'prob_mass');
    % Validate "storm" dataset
    storm_validation(config, storm);
    % Validate prob_mass Based On Storm Content
    if isfield(storm, 'TC')
        prob_mass_validation(config, prob_mass, storm);
    end
    % This Run's Request Must Be In The Provided Storm Data (No CHS Files To Rebuild From)
    req = run_request(config);
    [stm_ok, dtype_ok, alt_ok] = storm_db_check(storm, prob_mass, req.storm_sampling,...
        req.use_peaks, req.use_timeseries, req.create_wlp, req.create_whp);
    if ~alt_ok
        missing = {'storm types (storm_sampling; TC needs prob_mass)', 'data types (use_peaks/use_timeseries)', 'Peaks datasets (create_wlp/create_whp)'};
        error('Error: Requested %s not in the provided storm data ''%s''.', missing{find(~[stm_ok, dtype_ok, alt_ok], 1)}, config.chs_zip);
    end
    % XC Record (Nyrs_XC, Nstm_XC) Moves From storm.XC To db_info
    Nyrs_XC = [];
    Nstm_XC = [];
    if isfield(storm,'XC')
        Nyrs_XC = storm.XC.Nyrs_XC;
        Nstm_XC = storm.XC.Nstm_XC;
        storm.XC = rmfield(storm.XC, {'Nyrs_XC','Nstm_XC'});
    end
    % Bias & Uncertainty (CHS_Dependencies, Else Entered Once Here); Processed Storm Data: No TC Bias Correction
    % No Savepoint Coordinates In A Storm .mat: Study Grid Row By Savepoint ID
    bnu = storm_db_bias_uncertainty(config.chs_dependencies, config.region, config.sp_ID, []);
    db_info = storm_db_info('create', bnu, 0, Nyrs_XC, Nstm_XC, [fname fext]);
    % Create CHESS storm file
    save(paths.storm_db, 'storm', 'prob_mass', 'db_info');
    config = storm_db_info('apply', db_info, config);
end

%% FINALIZE CONFIGURATION
% Structure-Level Rules (Berms, Floodwall Toe, Hidden Features)
config = finalize_structure_config(config);
% Run-Level Rules (Response Restrictions & Dependencies, CLs, Uncertainties, Output Files)
config = finalize_config(config);

%% LOAD COMPUTATIONAL ENVIRONMENT
% No Storm Database Files Yet -> 1 (Print Welcome Message) , 0 (No Print)
% Set-up Computational Environment
[config, structure] = call_environment_setup(config, ~chess_storm && ~chess_raw);

%% AUX FUNCTIONS
% Function 1: Identify What Type Of Modeling Data Is Provided By User
    function data_case = identify_storm_data_type(chs_zip)
        % Get File Extension
        [~, ~, file_extension] = fileparts(chs_zip);
        % Determine Modeling Data Provided Through config.chs_zip
        switch file_extension
            case '.mat' % Option 1: mat file with "storm" & "prob_mass" | Option 2: mat file with "CHS_Data"
                data_case = {'chs_data', 'storm_data'};
                % Verify Variable Inside .mat File
                mf = matfile(chs_zip);
                vars = who(mf);
                % Make Sure We Only Allow For Supported Vars
                var_pass = contains({'CHS_Data','storm'}, vars);
                %
                if sum(var_pass) == 0 || sum(var_pass) >1
                    error('Error: Provided .mat file under chs_zip must have "CHS_Data" or "storm" variables (not both).')
                else
                    data_case = data_case{var_pass};
                end
                % For storm_data: require prob_mass variable to also be present
                if strcmp(data_case, 'storm_data') && ~any(contains(vars, 'prob_mass'))
                    error('Error: storm_data .mat must contain both "storm" and "prob_mass" variables.');
                end
            case '.zip' % Zip Folder Downloaded From CHS
                data_case = 'chs_data';
            otherwise
                error('Error: Unsuported file type for config.chs_zip. Please provide valid .mat file or CHS .zip folder')
        end
    end
% Function 2: This Run's Storm Data Request (WLP/WHP Need Peaks And Timeseries: finalize_config.m Rule)
    function req = run_request(cfg)
        both = cfg.use_peaks == 1 && cfg.use_timeseries == 1;
        req = struct('storm_sampling', cfg.storm_sampling, 'use_peaks', cfg.use_peaks, 'use_timeseries', cfg.use_timeseries,...
            'create_wlp', +(both && cfg.create_wlp == 1), 'create_whp', +(both && cfg.create_whp == 1));
    end
end % End of Function

%% LOCAL FUNCTIONS
% Savepoint Coordinates ('Save Point Latitude'/'Save Point Longitude' Root Attributes, [lat lon]) Of The First ADCIRC .h5
% File Of A CHS Zip Folder. Only That Entry Is Extracted, Into A System Temp Folder Removed On Return; [] When The File
% Or An Attribute Is Missing
function sp_coords = zip_sp_coords(zip_name, adcirc_files)
sp_coords = [];
if isempty(adcirc_files)
    return
end
temp_path = tempname;
temp_cleanup = onCleanup(@() remove_temp_folder(temp_path));
try
    h5_path = zip_extract_entry(zip_name, adcirc_files{1}, temp_path);
    sp_coords = [attr_to_double(h5readatt(h5_path, '/', 'Save Point Latitude')),...
        attr_to_double(h5readatt(h5_path, '/', 'Save Point Longitude'))];
catch
    sp_coords = [];
end
end

% HDF5 Attribute Value (Text Or Numeric) To Double
function val = attr_to_double(val)
if iscell(val)
    val = val{1};
end
if ischar(val) || isstring(val)
    val = str2double(val);
end
val = double(val(1));
end

% Savepoint Coordinates Into config (sp_lat/sp_lon, NaN When Not Found: The Storm Database Build Matches The Savepoint ID)
function config = set_sp_coords(config, sp_coords, where)
if numel(sp_coords) == 2 && all(isfinite(sp_coords))
    config.sp_lat = sp_coords(1);
    config.sp_lon = sp_coords(2);
else
    config.sp_lat = NaN;
    config.sp_lon = NaN;
    fprintf('Warning: could not find ADCIRC savepoint coordinates on %s. The storm database build will match the savepoint ID in the study grid instead....\n', where);
end
end

% Remove A Temp Folder (If Created)
function remove_temp_folder(temp_path)
if isfolder(temp_path)
    rmdir(temp_path, 's');
end
end

function [storm, CHS_Data, prob_mass, config] = call_chs_data_formatter(config)
%{
    %% DESCRIPTION
        This function is responsible for reading, formatting and screening
        Coastal Hazards System (CHS) .h5 storm "Peaks" & "Timeseries"
        files. Additionally, it loads and formats TC's probability masses
        if supported by library.
        The storm database is project wide (Event_Database, shared by every
        PSE/alternative), so it is always built from every CHS Peaks and
        Timeseries .h5 file in the input (every storm type and data type
        present), like the GUI storm database wizard. Each run then selects
        its request (storm_sampling, use_peaks, use_timeseries, create_wlp,
        create_whp) from it. WLP/WHP datasets are built when requested (or
        already present in the database being rebuilt); a run requesting a
        WLP/WHP dataset the database lacks rebuilds the database from
        <db>_raw_files.mat (no .h5 conversion).
        The input's storm files must pass chs_storm_file_slots.m (one study
        identity: no repeated file name, one ADCIRC and one wave save point,
        one simulation and post type; one ADCIRC + one wave file per storm
        type/data type slot, request covered).
        Without CHS_Dependencies TC statistics for the region
        (chs_dependency_files.m tropical_statistics_available)
        an XC request builds the database with XC only (the raw file still
        holds every file) and a TC/CC request stops with an error
        (chs_dependencies_message.m); a later run with CHS_Dependencies
        requesting TC/CC rebuilds it from the raw file.
        Building the database also sets its db_info (storm_db_info.m: TC
        bias correction, bias & uncertainty from
        storm_db_bias_uncertainty.m, Nyrs_XC/Nstm_XC), applied to config.
        A database without db_info (older version) is rebuilt from the raw
        file.
        Storm .mat input (storm + prob_mass, copied as the database by
        call_input_parser.m) is never rebuilt: a request it does not hold
        is an error.

    %% INPUTS
        config.
            chs_files_2_convert: CHS files in the input [path, name]; | cell | number_of_files x 2
                        path '' for a .zip input (unzipped at conversion, convert_chs_zip.m).
            use_peaks: Run uses CHS peaks data. (0/1) | double | 1 x 1
            use_timeseries: Run uses CHS timeseries data. (0/1) | double | 1 x 1
            storm_sampling: Storm sampling type.('TC','XC' or 'CC') | char | 1 x 2
            create_wlp: Run uses the Water Level Priority (WLP) | double | 1 x 1
                        dataset. Requires peaks and timeseries files. (0/1)
            create_whp: Run uses the Wave Height Priority (WHP) | double | 1 x 1
                        dataset. Requires peaks and timeseries files. (0/1)
            chs_dependencies, region, sp_ID: CHS_Dependencies folder, region, savepoint.
            sp_lat, sp_lon: Savepoint coordinates (call_input_parser.m; NaN when
                        not found): study grid lookup (storm_db_bias_uncertainty.m).
            out_files.chs_data, out_files.storm_and_prob_mass: Storm
                        database files (chess_paths.m). | char

    %% OUTPUTS
        Additional to data outputs 2 files are exported from this function
        (<event_db_dir> = <outfolder>\<project>\Event_Database, chess_paths.m).
        <event_db_dir>\<db>_raw_files.mat: MAT-file containing every converted
                             CHS file of the input with no screening applied to them.
        <event_db_dir>\<db>.mat: MAT-file containing formated and screened
                             CHS data (storm, prob_mass) for every storm
                             type and data type of the input, and db_info.

        config.
            tc_bias_corrected, chs_swl_*, chs_hm0_*, Nyrs_XC, Nstm_XC,
                        offshore_elevation (study grid value, when it has one): From
                        db_info (storm_db_info.m 'apply') when the database is built.
            hotstart_level: 'resample' when the
                        database is built (fresh or rebuild): once every build
                        step succeeded (before the database is saved), this
                        case's cached project forcing and LCS sampling seed
                        file are deleted and carried tide_indx_tc/_xc/_cc and
                        forcing_stamp removed (the hotstart level, decided before the build,
                        cannot see a missing or rebuilt database). Appended to
                        the config file with the db_info fields. A build that
                        stops leaves the cache, the database and the config
                        file untouched.
        A .zip input that needs conversion (no raw file) is unzipped right
        before conversion (convert_chs_zip.m) into a system temp folder
        (tempname) that is removed on every exit (onCleanup), errors
        included. The database itself is built by build_storm_database.m,
        shared with the GUI storm database wizard.

        storm: Data structure containing formated and screened CHS storm  | struc | size_varies
               peaks data, reduced to this run's request. First level of
               data structure can have 'XC' and/or 'TC'. This depends on
               storm_sampling.
               Storm peaks datasets provided (Maxima, WLP, WHP) have the
               same format: one 1x5 row per storm with cols: SWL, Hm0, Tp,
               wave dir, peak datenum (no storm duration; the forcing
               builders attach config.storm_duration).
               Additional field labeled "removed_storms" is a structure
               containing removed storm IDs fore ach dataset. WHP and WLP
               datasets are optional and require the use_timeseries switch
               to be enabled in conjunction with WLP_switch/WHP_switch.

        "storm" Fields:
            storm.(storm_type).
                Maxima: Dataset is built using only CHS "Peaks"files.    | double | 1 x 5
                         ADCIRC (SWL) peak and STWAVE (Hm0,TP,wave dir)
                         are matched together for each storm ID.

                WLP: Dataset is built using ADCIRC "Peaks" file and
                      STWAVE timeseries file to match peak water level
                      with its corresponding wave. A time window of +/- 3
                      hours is used to find nearest STWAVE data point. In
                      the case that ADCIRC peak resides outside the
                      temporal range of STWAVE timeseries output then a
                      "new" peak water level is computed from ADCIRC's
                      timeseries output by matching timesteps with STWAVE
                      and finding the maximum of the resulting water level
                      timeseries.

                WHP: Dataset is built using STWAVE "Peaks" file and
                      ADCIRC timeseries file to match peak wave height
                      with its corresponding water level. A time window of +/- 3
                      hours is used to find nearest ADCIRC data point. In
                      the case that STWAVE model output offers water level
                      output, then that will be used instead.

                removed_storms - Structure containing removed storm IDs for | struc | size_varies
                                 each dataset in "storm".

    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% GRAB INPUT FROM "config"
%{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
%}
% This Run's Request, CHS Input (A .zip Input Is Unzipped Right Before Conversion) And Print Out Switch
[request, chs_input, disp_on] = formatter_request(config);

%% CHECK IF PROCESSED SAVEPOINT DATA EXIST FOR TRANSECT
[storm_mat_exists, chs_data_mat_exists, storm, prob_mass, db_info, CHS_Data] = load_existing_storm_database(config, disp_on);
can_coldstart = ~chs_input.is_storm_mat_input && (chs_data_mat_exists || strcmp(chs_input.ext, '.zip'));

%% EVALUATE DATASET FOR HOTSTART
db_check = storm_database_compatibility(storm, prob_mass, db_info, request, storm_mat_exists);
compatible = db_check.compatible;

%% HOTSTART / COLDSTART DECISION
report_hotstart_decision(db_check, storm_mat_exists, can_coldstart, request, chs_input.is_storm_mat_input, disp_on);

%% CHESS COLDSTART - STORM SUITE QA/QC AND FORMATTING (.ZIP)
% Execute Pre-Processing If Needed
if ~(storm_mat_exists && compatible) && can_coldstart % CHESS needs to create and process storm datasets.
    [storm, prob_mass, CHS_Data, config] = build_database_from_chs_input(config, request, chs_input, disp_on,...
        storm_mat_exists, chs_data_mat_exists, db_check.has_info, storm, db_info, CHS_Data);
end

%% OFFSHORE ELEVATION, ALWAYS REQUIRED (db_info Applied: call_input_parser.m Or The Build Above)
check_offshore_elevation(config);

%% SELECT THIS RUN'S REQUEST FROM THE STORM DATABASE
storm = select_request(storm, request);
if isfield(storm, 'TC') && (isempty(prob_mass) || isempty(prob_mass.TC_Freq))
    error('Probability masses came out empty. Please verify path on input file.');
end
end

%% AUX FUNCTION: THIS RUN'S REQUEST, CHS INPUT AND PRINT OUT SWITCH FROM "config"
function [request, chs_input, disp_on] = formatter_request(config)
% Define CHS_Data file (.zip, .mat) And Its Extension
[~, chs_zip_name, fext] = fileparts(config.chs_zip);
% CHS Files (Names) And CHS_Data File; Storm .mat Input (storm + prob_mass): Copied As The Storm Database By
% call_input_parser, No CHS Files To Rebuild From
chs_input = struct('files_2_convert', {config.chs_files_2_convert(:,2)}, 'zip', config.chs_zip,...
    'zip_name', chs_zip_name, 'ext', fext, 'is_storm_mat_input', isempty(config.chs_files_2_convert(:,2)));
% This Run's Request (Storm Sampling, Use Peaks/Timeseries Switches, WLP & WHP Switches)
request = struct('storm_sampling', config.storm_sampling, 'use_peaks', config.use_peaks, 'use_timeseries', config.use_timeseries,...
    'create_wlp', config.create_wlp, 'create_whp', config.create_whp);
% Print Out Switch
disp_on = config.print_progress;
end

%% AUX FUNCTION: PROCESSED SAVEPOINT DATA (STORM DATABASE, CHS_Data .mat), LOADED IF PRESENT
function [storm_mat_exists, chs_data_mat_exists, storm, prob_mass, db_info, CHS_Data] = load_existing_storm_database(config, disp_on)
storm_mat_exists    = exist(config.out_files.storm_and_prob_mass, 'file') == 2;
chs_data_mat_exists = exist(config.out_files.chs_data, 'file') == 2;
% Missing Files: Empty Outputs (Unused Without A Build)
storm     = [];
prob_mass = [];
db_info   = [];
CHS_Data  = [];
if storm_mat_exists
    disp_toggle(disp_on, 'CHESS generated storm .mat detected. Loading data...');
    storm_vars = {'storm', 'prob_mass'};
    if any(strcmp(who('-file', config.out_files.storm_and_prob_mass), 'db_info'))
        storm_vars{end+1} = 'db_info';
    end
    S = load(config.out_files.storm_and_prob_mass, storm_vars{:});
    storm     = S.storm;
    prob_mass = S.prob_mass;
    if isfield(S, 'db_info')
        db_info = S.db_info;
    end
end
if chs_data_mat_exists
    disp_toggle(disp_on, 'CHESS generated CHS_Data .mat detected. Loading data...');
    S = load(config.out_files.chs_data, 'CHS_Data');
    CHS_Data = S.CHS_Data;
end
end

%% AUX FUNCTION: STORM DATABASE COMPATIBILITY WITH THIS RUN'S REQUEST
% The Storm Database Holds Every Storm/Data Type Of The Input: It Is Compatible When It Holds This Run's Request
% (TC Only With Its Probability Masses) And Its db_info (Databases Of Older Versions Have None)
function db_check = storm_database_compatibility(storm, prob_mass, db_info, request, storm_mat_exists)
db_check.compatible            = false;
db_check.storm_type_ok         = false;
db_check.data_type_ok          = false;
db_check.alternate_datasets_ok = false;
db_check.has_info              = storm_db_info('valid', db_info);
if storm_mat_exists
    [db_check.storm_type_ok, db_check.data_type_ok, db_check.alternate_datasets_ok] = storm_db_check(storm, prob_mass,...
        request.storm_sampling, request.use_peaks, request.use_timeseries, request.create_wlp, request.create_whp);
    db_check.compatible = db_check.alternate_datasets_ok && db_check.has_info;
end
end

%% AUX FUNCTION: HOTSTART (COMPATIBLE DATABASE) / COLDSTART (BUILD OR REBUILD) MESSAGES, ELSE ERROR
function report_hotstart_decision(db_check, storm_mat_exists, can_coldstart, request, is_storm_mat_input, disp_on)
if storm_mat_exists && db_check.compatible
    disp_toggle(disp_on, 'Processed CHS data (storm) detected. Loading....');
elseif can_coldstart
    if storm_mat_exists
        if ~db_check.has_info
            disp_toggle(disp_on, 'Processed CHS data (storm) has no db_info (older CHESS version). Rebuilding the storm database....');
        else
            disp_toggle(disp_on, 'Processed CHS data (storm) does not have necessary dependencies. Restarting import process....');
        end
    end
else
    storm_simulation_error_msg(storm_mat_exists, db_check, request, is_storm_mat_input);
end
end

%% AUX FUNCTION: BUILD (OR REBUILD) THE STORM DATABASE FROM THE CHS INPUT, RESET THE FORCING CACHE AND SAVE
function [storm, prob_mass, CHS_Data, config] = build_database_from_chs_input(config, request, chs_input, disp_on,...
    storm_mat_exists, chs_data_mat_exists, has_info, storm, db_info, CHS_Data)
chs_zip = chs_input.zip;
% STORM DATABASE CONTENT: EVERY CHS PEAKS/TIMESERIES FILE OF THE INPUT
chs_files_2_convert = chs_input.files_2_convert;
if chs_data_mat_exists
    [~, chs_files_2_convert, h5_ext] = cellfun(@fileparts, {CHS_Data.Filename}', 'un', false);
    chs_files_2_convert = strcat(chs_files_2_convert, h5_ext);
end
chs_files_2_convert = chs_storm_file_names(chs_files_2_convert);
% Storm File Slots (Storm Type x Data Type: One ADCIRC + One Wave File) And This Run's Request
[slots, slot_errors] = chs_storm_file_slots(chs_files_2_convert, request);
if ~isempty(slot_errors)
    error('Error ID: 001 | call_chs_data_formatter.missing_dependency | CHS input ''%s'' does not meet the storm data requirements: %s.', chs_zip, strjoin(slot_errors, '; '));
end
% Storm Types Of The Database: Every Complete Slot, TC Only With CHS_Dependencies (Probability Masses)
db_types = intersect({'TC','XC'}, slots.storm_type(slots.complete)', 'stable');
chs_files = chs_dependency_files(config.chs_dependencies, config.region);
if ismember('TC', db_types) && ~chs_files.tropical_statistics_available
    if ~strcmp(request.storm_sampling, 'XC')
        error(chs_dependencies_message(request.storm_sampling, config.region));
    end
    disp_toggle(disp_on, 'CHS_Dependencies not available for this region: storm database built with XC only (TC files kept in the raw file)....');
    db_types = setdiff(db_types, {'TC'}, 'stable');
end
% WLP/WHP: Built When Requested Or Already In The Storm Database Being Rebuilt (Peaks + Timeseries Needed)
had_wlp = false;
had_whp = false;
if storm_mat_exists
    for ii = fieldnames(storm)'
        if isstruct(storm.(ii{:})) && isfield(storm.(ii{:}), 'Peaks')
            had_wlp = had_wlp || isfield(storm.(ii{:}).Peaks, 'WLP');
            had_whp = had_whp || isfield(storm.(ii{:}).Peaks, 'WHP');
        end
    end
end
% Bias & Uncertainty Of The Database (CHS_Dependencies, Else Manual Values Of The Database Being Rebuilt, Else Prompted)
% And Offshore Elevation: Study Grid Point Nearest To The Savepoint Coordinates (call_input_parser.m; NaN: ID Match)
if has_info
    bnu = storm_db_bias_uncertainty(config.chs_dependencies, config.region, config.sp_ID, [config.sp_lat config.sp_lon], db_info);
else
    bnu = storm_db_bias_uncertainty(config.chs_dependencies, config.region, config.sp_ID, [config.sp_lat config.sp_lon]);
end
% Storm Database Build Settings (build_storm_database.m; This Run's config Keeps Its Own Request): Data Types And
% WLP/WHP Per Storm Type From The Slots, WLP/WHP Requested By This Run Or Already In The Database Being Rebuilt
build_options = struct('chs_dependencies', config.chs_dependencies, 'region', config.region, 'sp_ID', config.sp_ID,...
    'storm_types', {db_types}, 'storm_file_slots', slots,...
    'create_wlp', +(request.create_wlp == 1 || had_wlp), 'create_whp', +(request.create_whp == 1 || had_whp),...
    'bias_uncertainty', bnu, 'source_file', [chs_input.zip_name chs_input.ext], 'print_progress', disp_on, 'progress_fcn', []);

% CONVERT CHS DATA
%{
    Run every CHS h5 storm file of the input through h5 to MATLAB converter
    (convert_chs_zip.m: system temp unzip, removed on every exit).
    Converted CHS data gets exported to <db>_raw_files.mat.
%}
if ~chs_data_mat_exists
    disp_toggle(disp_on,'Begin CHS h5 file conversion....');
    CHS_Data = convert_chs_zip(chs_zip, chs_files_2_convert, disp_on);
    save(config.out_files.chs_data,'CHS_Data','-v7.3');
else  % CHS_Data .mat exists — Loaded By load_existing_storm_database
    disp_toggle(disp_on,'Building storm database from CHESS generated CHS_Data .mat....');
end

% FORMAT AND INSPECT CHS STORMS, TIMESERIES PEAK REPLACER, db_info
[storm, prob_mass, db_info] = build_storm_database(CHS_Data, build_options);

% A Built Storm Database Invalidates This Case's Cached Forcing, LCS Sampling And Tides (Fresh Build Or Rebuild).
% Done Here, Not In resolve_hotstart_state.m: storm_db_build_date Is Unknown There When <db>.mat Is Missing.
% After Every Build Step, Before The Database Is Saved: A Build That Stops Leaves Cache, Database And Config File As They Were
config = reset_forcing_cache(config);

% EXPORT PROJECT CONFIGURATION FILE & FORMATTED CHS DATA
% Export Storm Database
save(config.out_files.storm_and_prob_mass, 'storm', 'prob_mass', 'db_info', '-v7.3');
% Append Storm Data Dependent Fields To Configuration File
config = storm_db_info('apply', db_info, config);
save(config.out_files.config, 'config', '-append');
end

%% AUX FUNCTION: STORM DATABASE BUILT: THIS CASE'S CACHED PROJECT FORCING, LCS SAMPLING SEED AND CARRIED TIDE START HOURS ARE STALE
function config = reset_forcing_cache(config)
for ff = {config.out_files.project_forcing, lcs_sampling_seed_file(config.out_files.project_forcing)}
    if isfile(ff{1})
        delete(ff{1});
    end
end
config.hotstart_level = 'resample';
config = rmfield(config, intersect(fieldnames(config), {'tide_indx_tc', 'tide_indx_xc', 'tide_indx_cc', 'forcing_stamp'}));
end

%% AUX FUNCTION: REDUCE THE STORM DATABASE TO THE REQUESTED STORM TYPES, DATA TYPES AND ALTERNATE DATASETS
function storm = select_request(storm, request)
switch request.storm_sampling
    case 'TC'
        if isfield(storm,'XC'), storm = rmfield(storm,'XC'); end
    case 'XC'
        if isfield(storm,'TC'), storm = rmfield(storm,'TC'); end
end
for jj = intersect(fieldnames(storm)', {'TC','XC'})
    if request.use_peaks == 0 && isfield(storm.(jj{:}), 'Peaks')
        storm.(jj{:}) = rmfield(storm.(jj{:}), 'Peaks');
    end
    if request.use_timeseries == 0 && isfield(storm.(jj{:}), 'Timeseries')
        storm.(jj{:}) = rmfield(storm.(jj{:}), 'Timeseries');
    end
    if isfield(storm.(jj{:}), 'Peaks')
        if request.create_wlp == 0 && isfield(storm.(jj{:}).Peaks, 'WLP')
            storm.(jj{:}).Peaks = rmfield(storm.(jj{:}).Peaks, 'WLP');
        end
        if request.create_whp == 0 && isfield(storm.(jj{:}).Peaks, 'WHP')
            storm.(jj{:}).Peaks = rmfield(storm.(jj{:}).Peaks, 'WHP');
        end
    end
end
end

%% AUX FUNCTION: ERROR MESSAGE MANAGER FOR LOADED STORM DATA
function storm_simulation_error_msg(storm_mat_exists, db_check, request, is_storm_mat_input)
% Initialize Error Message
if is_storm_mat_input
    error_msg = "Error: The request on the configuration file is not in the provided storm data (storm .mat input: no rebuild possible):";
else
    error_msg = "Error: Provided storm data failed to meet user request on configuration file. inspection failed on:";
end
% Add Storm Type Error Message
if ~storm_mat_exists
    error_msg = error_msg + newline + "No storm database and no CHS files to build it from.";
elseif ~db_check.storm_type_ok
    error_msg = error_msg + newline + sprintf("Missing storm data per requested storm sampling (%s; TC needs its probability masses).", request.storm_sampling);
elseif ~db_check.data_type_ok
    error_msg = error_msg + newline + sprintf("Missing peaks or timeseries data per use_peaks = %d / use_timeseries = %d.", request.use_peaks, request.use_timeseries);
elseif ~db_check.alternate_datasets_ok
    error_msg = error_msg + newline + sprintf("Missing peaks data, make sure you have the requested datasets (Default, WLP = %d, WHP = %d).", request.create_wlp, request.create_whp);
elseif ~db_check.has_info
    error_msg = error_msg + newline + "The storm database has no db_info (older CHESS version) and no raw file to rebuild it from: rebuild the storm database from its original input.";
end
% Display error Message
error(error_msg);
end

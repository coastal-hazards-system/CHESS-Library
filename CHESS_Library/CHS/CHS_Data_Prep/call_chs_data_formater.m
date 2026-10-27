function [storm, CHS_Data, prob_mass, config] = call_chs_data_formater(config)
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
        Without CHS_Dependencies for the region (chs_dependencies_available.m)
        an XC request builds the database with XC only (the raw file still
        holds every file) and a TC/CC request stops with an error
        (chs_dependencies_message.m); a later run with CHS_Dependencies
        requesting TC/CC rebuilds it from the raw file. Building the database also sets its db_info (storm_db_info.m:
        TC bias correction, bias & uncertainty from storm_db_bias_uncertainty.m,
        Nyrs_XC/Nstm_XC), applied to config. A database without db_info
        (older version) is rebuilt from the raw file.
        Storm .mat input (storm + prob_mass, copied as the database by
        call_input_parser.m) is never rebuilt: a request it does not hold
        is an error.

    %% INPUTS
        config.
            chs_files_2_convert: CHS files in the input [path, name]; | cell | number_of_files x 2
                        path '' for a .zip input (unzipped here).
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
        A .zip input that needs conversion (no raw file) is unzipped here,
        right before conversion, into a system temp folder (tempname) that
        is removed on every exit (onCleanup), errors and an aborted manual
        prompt included.

        storm: Data structure containing formated and screened CHS storm  | struc | size_varies
               peaks data, reduced to this run's request. First level of
               data structure can have 'XC' and/or 'TC'. This depends on
               storm_sampling.
               Storm peaks datasets provided (Maxima, WLP, WHP) have the
               same format 4x1 matrix with cols: SWL,Hm0,Tp, wave dir.
               Additional field labeled "removed_storms" is a structure
               containing removed storm IDs fore ach dataset. WHP and WLP
               datasets are optional and require the use_timeseries switch
               to be enabled in conjunction with WLP_switch/WHP_switch.

        "storm" Fields:
            storm.(storm_type).
                Maxima: Dataset is built using only CHS "Peaks"files.    | double | 1 x 4
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
% Define CHS Files (Names; A .zip Input Is Unzipped Here, Right Before Conversion)
chs_files_2_convert = config.chs_files_2_convert(:,2);
% Use Peaks Switch
use_peaks = config.use_peaks;
% Use Timeseries Switch
use_timeseries = config.use_timeseries;
% Storm Sampling
storm_sampling = config.storm_sampling;
% Define CHS_Data file (.zip, .mat)
chs_zip = config.chs_zip;
% Define CHS_Data Fiel Extension
[~,chs_zip_name,fext] = fileparts(chs_zip);
% Deifne WLP & WHP Switches
create_wlp = config.create_wlp;
create_whp = config.create_whp;
% Print Out Switch
disp_on = config.print_progress;
% Storm .mat Input (storm + prob_mass): Copied As The Storm Database By call_input_parser, No CHS Files To Rebuild From
storm_input = isempty(chs_files_2_convert);
% This Run's Request
request = struct('storm_sampling', storm_sampling, 'use_peaks', use_peaks, 'use_timeseries', use_timeseries,...
    'create_wlp', create_wlp, 'create_whp', create_whp);

%% CHECK IF PROCESSED SAVEPOINT DATA EXIST FOR TRANSECT
storm_mat_exists    = exist(config.out_files.storm_and_prob_mass, 'file') == 2;
chs_data_mat_exists = exist(config.out_files.chs_data, 'file') == 2;
can_coldstart       = ~storm_input && (chs_data_mat_exists || strcmp(fext, '.zip'));
% Load Files If Present
db_info = [];
if storm_mat_exists
    disp_toggle(disp_on, 'CHESS generated storm .mat detected. Loading data...');
    load(config.out_files.storm_and_prob_mass, 'storm', 'prob_mass');
    if any(strcmp(who('-file', config.out_files.storm_and_prob_mass), 'db_info'))
        load(config.out_files.storm_and_prob_mass, 'db_info');
    end
end
if chs_data_mat_exists
    disp_toggle(disp_on, 'CHESS generated CHS_Data .mat detected. Loading data...');
    load(config.out_files.chs_data, 'CHS_Data');
else
    CHS_Data = []; % Ensures output arg is always assigned
end

%% EVALUATE DATASET FOR HOTSTART
% The Storm Database Holds Every Storm/Data Type Of The Input: It Is Compatible When It Holds This Run's Request
% (TC Only With Its Probability Masses) And Its db_info (Databases Of Older Versions Have None)
compatible    = false;
stm_type_chk  = false;
data_type_chk = false;
alt_chk       = false;
has_info      = storm_db_info('valid', db_info);
if storm_mat_exists
    [stm_type_chk, data_type_chk, alt_chk] = storm_db_check(storm, prob_mass, storm_sampling,...
        use_peaks, use_timeseries, create_wlp, create_whp);
    compatible = alt_chk && has_info;
end

%% HOTSTART / COLDSTART DECISION
if storm_mat_exists && compatible
    disp_toggle(disp_on, 'Processed CHS data (storm) detected. Loading....');
elseif can_coldstart
    if storm_mat_exists
        if ~has_info
            disp_toggle(disp_on, 'Processed CHS data (storm) has no db_info (older CHESS version). Rebuilding the storm database....');
        else
            disp_toggle(disp_on, 'Processed CHS data (storm) does not have necessary dependencies. Restarting import process....');
        end
    end
else
    storm_simulation_error_msg(storm_mat_exists, has_info, stm_type_chk, data_type_chk, alt_chk, request, storm_input);
end

%% CHESS COLDSTART - STORM SUITE QA/QC AND FORMATTING (.ZIP)
% Execute Pre-Processing If Needed
if ~(storm_mat_exists && compatible) && can_coldstart % CHESS needs to create and process storm datasets.
    % STORM DATABASE CONTENT: EVERY CHS PEAKS/TIMESERIES FILE OF THE INPUT
    if chs_data_mat_exists
        [~, chs_files_2_convert, h5_ext] = cellfun(@fileparts, {CHS_Data.Filename}', 'un', false);
        chs_files_2_convert = strcat(chs_files_2_convert, h5_ext);
    end
    chs_files_2_convert = chs_storm_file_names(chs_files_2_convert);
    % Storm File Slots (Storm Type x Data Type: One ADCIRC + One Wave File) And This Run's Request
    [slots, slot_errors] = chs_storm_file_slots(chs_files_2_convert, request);
    if ~isempty(slot_errors)
        error('Error ID: 001 | call_chs_data_formater.missing_dependency | CHS input ''%s'' does not meet the storm data requirements: %s.', chs_zip, strjoin(slot_errors, '; '));
    end
    % Storm Types Of The Database: Every Complete Slot, TC Only With CHS_Dependencies (Probability Masses)
    db_types = intersect({'TC','XC'}, slots.storm_type(slots.complete)', 'stable');
    if ismember('TC', db_types) && ~chs_dependencies_available(config.chs_dependencies, config.region)
        if ~strcmp(storm_sampling, 'XC')
            error(chs_dependencies_message(storm_sampling, config.region));
        end
        disp_toggle(disp_on, 'CHS_Dependencies not available for this region: storm database built with XC only (TC files kept in the raw file)....');
        db_types = setdiff(db_types, {'TC'}, 'stable');
    end
    slot_ok = @(st, dt) any(slots.complete & strcmp(slots.storm_type, st) & strcmp(slots.data_type, dt));
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
    % Storm Database Build Settings (This Run's config Keeps Its Own Request); TC SWL Bias Correction Uses The Database Bias
    db_config = config;
    db_config.chs_swl_b_a = bnu.chs_swl_b_a;
    db_config.chs_swl_b_r = bnu.chs_swl_b_r;
    storm = struct();
    prob_mass = [];
    tc_bias_corrected = 0;
    Nyrs_XC = [];
    Nstm_XC = [];

    % CONVERT CHS DATA
    %{
        Run every CHS h5 storm file of the input through h5 to MATLAB converter.
        Additionally, extract ADCIRC save point: region, ID.
        Converted CHS data gets exported to <db>_raw_files.mat.
    %}
    if ~chs_data_mat_exists
        % Unzip The CHS Input Into A System Temp Folder: Removed On Every Exit, Errors And Ctrl+C At The Manual Prompt Included
        temp_path = tempname;
        temp_cleanup = onCleanup(@() remove_temp_folder(temp_path));
        unzip(chs_zip, temp_path);
        % .h5 Extension In Any Case (dir '*.h5' Is Case-Sensitive Off Windows)
        h5_dir = dir(fullfile(temp_path, '**', '*'));
        h5_dir = h5_dir(~[h5_dir.isdir]' & endsWith({h5_dir.name}', '.h5', 'IgnoreCase', true));
        [~, h5_loc] = ismember(lower(chs_files_2_convert), lower({h5_dir.name}'));
        if any(h5_loc == 0)
            error('Error: %s not found in the unzipped CHS input ''%s''.', strjoin(chs_files_2_convert(h5_loc == 0), ', '), chs_zip);
        end
        % Append Filenames With Paths
        full_file_path = fullfile({h5_dir(h5_loc).folder}', {h5_dir(h5_loc).name}');
        % Print Status
        disp_toggle(disp_on,'Begin CHS h5 file conversion....');
        % Convert CHS Data
        CHS_Data = call_chs_h5_converter(full_file_path, disp_on);
        % Export Data
        save(config.out_files.chs_data,'CHS_Data','-v7.3');
        % Remove Temp Dir
        remove_temp_folder(temp_path);
    else  % CHS_Data .mat exists — Loaded Above
        disp_toggle(disp_on,'Building storm database from CHESS generated CHS_Data .mat....');
    end

    % FORMAT AND INSPECT CHS STORMS (TC First: Probability Masses), Data Types Per Storm Type
    for st = db_types
        has_pk = slot_ok(st{1}, 'Peaks');
        has_ts = slot_ok(st{1}, 'Timeseries');
        db_config.use_peaks = +has_pk;
        db_config.use_timeseries = +has_ts;
        db_config.create_wlp = +(has_pk && has_ts && (create_wlp == 1 || had_wlp));
        db_config.create_whp = +(has_pk && has_ts && (create_whp == 1 || had_whp));
        switch st{1}
            case 'TC'
                [prob_mass.Param, prob_mass.TC_SRR,...
                    prob_mass.TC_Freq, prob_mass.TotalFreq,...
                    prob_mass.smpl1, prob_mass.smpl2, prob_mass.smpl3] = chs_probability_mass_loader(config.chs_dependencies, config.region, config.sp_ID);
                % Format And Inspect Storm Peaks Files
                [db_config, storm.('TC'), storm.('TC').removed_storms,...
                    ~, ~, prob_mass] = call_chs_storm_quality_check(db_config, CHS_Data, prob_mass, 'TC');
                tc_bias_corrected = db_config.tc_bias_corrected;
            case 'XC'
                % Format And Inspect Storm Peaks Files
                [~, storm.('XC'), storm.('XC').removed_storms,...
                    Nyrs_XC, Nstm_XC, ~] = call_chs_storm_quality_check(db_config, CHS_Data, [], 'XC');
        end
        % TIMESERIES PEAK REPLACER: Replace Hydrograph Peak Responses With Peaks Files Responses
        if has_pk && has_ts
            one_type = chs_timeseries_peak_replacer(struct(st{1}, storm.(st{1})));
            storm.(st{1}) = one_type.(st{1});
        end
    end

    % A Built Storm Database Invalidates This Case's Cached Forcing, LCS Sampling And Tides (Fresh Build Or Rebuild).
    % Done Here, Not In resolve_hotstart_state.m: storm_db_build_date Is Unknown There When <db>.mat Is Missing.
    % After Every Build Step, Before The Database Is Saved: A Build That Stops Leaves Cache, Database And Config File As They Were
    config = reset_forcing_cache(config);

    % EXPORT PROJECT CONFIGURATION FILE & FORMATTED CHS DATA
    % Storm Database Details (Bias & Uncertainty, TC Bias Correction, XC Record)
    db_info = storm_db_info('create', bnu, tc_bias_corrected, Nyrs_XC, Nstm_XC, [chs_zip_name fext]);
    % Export Storm Database
    save(config.out_files.storm_and_prob_mass, 'storm', 'prob_mass', 'db_info', '-v7.3');
    % Append Storm Data Dependent Fields To Configuration File
    config = storm_db_info('apply', db_info, config);
    save(config.out_files.config, 'config', '-append');
end

%% OFFSHORE ELEVATION, ALWAYS REQUIRED (db_info Applied: call_input_parser.m Or The Build Above)
check_offshore_elevation(config);

%% SELECT THIS RUN'S REQUEST FROM THE STORM DATABASE
storm = select_request(storm, storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp);
if isfield(storm, 'TC') && (isempty(prob_mass) || isempty(prob_mass.TC_Freq))
    error('Probability masses came out empty. Please verify path on input file.');
end

%% AUX FUNCTIONS
% Reduce The Storm Database To The Requested Storm Types, Data Types And Alternate Datasets
    function storm = select_request(storm, storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp)
        switch storm_sampling
            case 'TC'
                if isfield(storm,'XC'), storm = rmfield(storm,'XC'); end
            case 'XC'
                if isfield(storm,'TC'), storm = rmfield(storm,'TC'); end
        end
        for jj = intersect(fieldnames(storm)', {'TC','XC'})
            if use_peaks == 0 && isfield(storm.(jj{:}), 'Peaks')
                storm.(jj{:}) = rmfield(storm.(jj{:}), 'Peaks');
            end
            if use_timeseries == 0 && isfield(storm.(jj{:}), 'Timeseries')
                storm.(jj{:}) = rmfield(storm.(jj{:}), 'Timeseries');
            end
            if isfield(storm.(jj{:}), 'Peaks')
                if create_wlp == 0 && isfield(storm.(jj{:}).Peaks, 'WLP')
                    storm.(jj{:}).Peaks = rmfield(storm.(jj{:}).Peaks, 'WLP');
                end
                if create_whp == 0 && isfield(storm.(jj{:}).Peaks, 'WHP')
                    storm.(jj{:}).Peaks = rmfield(storm.(jj{:}).Peaks, 'WHP');
                end
            end
        end
    end
% Error Message Manager For Loaded Storm Data
    function storm_simulation_error_msg(storm_mat_exists, has_info, stm_type_chk, data_type_chk, alt_chk, request, storm_input)
        % Initialize Error Message
        if storm_input
            error_msg = "Error: The request on the configuration file is not in the provided storm data (storm .mat input: no rebuild possible):";
        else
            error_msg = "Error: Provided storm data failed to meet user request on configuration file. inspection failed on:";
        end
        % Add Storm Type Error Message
        if ~storm_mat_exists
            error_msg = error_msg + newline + "No storm database and no CHS files to build it from.";
        elseif ~stm_type_chk
            error_msg = error_msg + newline + sprintf("Missing storm data per requested storm sampling (%s; TC needs its probability masses).", request.storm_sampling);
        elseif ~data_type_chk
            error_msg = error_msg + newline + sprintf("Missing peaks or timeseries data per use_peaks = %d / use_timeseries = %d.", request.use_peaks, request.use_timeseries);
        elseif ~alt_chk
            error_msg = error_msg + newline + sprintf("Missing peaks data, make sure you have the requested datasets (Default, WLP = %d, WHP = %d).", request.create_wlp, request.create_whp);
        elseif ~has_info
            error_msg = error_msg + newline + "The storm database has no db_info (older CHESS version) and no raw file to rebuild it from: rebuild the storm database from its original input.";
        end
        % Display error Message
        error(error_msg);
    end
end

%% LOCAL FUNCTIONS
% Storm Database Built: This Case's Cached Project Forcing, LCS Sampling Seed And Carried Tide Start Hours Are Stale
function config = reset_forcing_cache(config)
for ff = {config.out_files.project_forcing, lcs_sampling_seed_file(config.out_files.project_forcing)}
    if isfile(ff{1})
        delete(ff{1});
    end
end
config.hotstart_level = 'resample';
config = rmfield(config, intersect(fieldnames(config), {'tide_indx_tc', 'tide_indx_xc', 'tide_indx_cc', 'forcing_stamp'}));
end

% Remove The Unzipped CHS Input Folder
function remove_temp_folder(temp_path)
if isfolder(temp_path)
    rmdir(temp_path, 's');
end
end

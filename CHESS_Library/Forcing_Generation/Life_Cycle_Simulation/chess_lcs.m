function [project_forcing, config] = chess_lcs(config, storm, prob_mass)
%{
INPUTS:
     config.StormSamplingDropDown.Value; -> 'Extratropical Only' , 'Tropical Only' , 'Combined Sampling'
     config.nLifeCycles.Value -> Number of life cycles
     config.SimLength.Value -> Simulation Length
     config.SPID; -> Savepoint ID
     config.UseTimeseriesCheckBox.Value; -> True or False
     config.Data; -> CHS Data from matlab CHS Data Converter
     config.WaterLevelPriorityCheckBox.Value; -> True or False
     config.WaveHeightPriorityCheckBox.Value; -> True or False
     config.SaveNameEditField.Value; -> Output Dir Save Name

OUTPUTS HEADERS (Column Map: lcs_columns.m):
    LC_MCSimOUT:
        Size (# of events, 10) -> (Rows,Col)
            (01) Storm ID                       [-]
            (02) Storm type                     [0 = extratropical]
            (03) Storm Year                     [-]
            (04) Number of storm in storm year  [-]
            (05) Water Level                    [meters, MSL]
            (06) Wave Height At Toe             [meters] (Depth Limited By adjust_project_forcing)
            (07) Wave Height Offshore           [meters] (Before Depth Limitation)
            (08) Peak Wave Period               [seconds]
            (09) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]
            (10) Storm Duration                 [days]
    LC_SimOUT_hyd:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a matrix which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm ID                       [-]
            (02) Storm type                     [0 = extratropical]
            (03) Storm Year                     [-]
            (04) Number of storm in storm year  [-]
            (05) Water Level                    [meters, MSL]
            (06) Wave Height At Toe             [meters]
            (07) Wave Height Offshore           [meters]
            (08) Peak Wave Period               [seconds]
            (09) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]
            (10) Time Step                      [days]
            (11) Timestep Counter               [0:storm_tstp-1]
    MC_indx:
        First Level:
            Size (# of LC's, 1) -> (Rows,Col)
            Each row contains a vector which size depends on the ammount of
            storms sampled for that specific life cyccle.
        Second Level:
            (01) Storm Year               [-]
            (02) Storm Type               [-]
            (03) Same Year Counter        [-]
            (04) Storm ID                 [-]

MATCHING METHODS (create_wlp / create_whp):
    XC: WLP and WHP life cycles are an exact copy of the Default XC life
        cycles (same storms, same copula-sampled values; the copula is
        never re-sampled), fresh sampling and reuse alike.
        storm.XC.Peaks.WLP/WHP are not read.
    TC: WLP and WHP life cycles hold the same sampled storms as Default
        with each storm's WLP/WHP database values.
    CC: TC and XC life cycles of each matching method combined.

SAMPLING SEED FILE (lcs_sampling_seed_file.m):
    lcs_restrict_sampling_rate, sampled_ids.XC/.TC and, with XC sampling,
    xc_peaks.Default (raw XC copula life cycles, before uncertainty and
    adjustment).
%}
warning('off','all');

%% GRAB INPUT FROM "config"
% Storm Sampling Scheme
storm_sampling = config.storm_sampling;
% Number Of Life Cycles
number_of_life_cyles = config.mcs_nLC;
% Simulation Length
simulation_years = config.mcs_nYears;
% Create Water Level Priority Switch
wlp_switch = config.create_wlp;
% Create Wave Height Priority Switch
whp_switch = config.create_whp;
switch storm_sampling
    case 'TC'
        XC_Nstm = [];
        XC_Nyrs = [];
    otherwise
        % Define Number Of Extratropical Storms In Data
        XC_Nstm = config.Nstm_XC;
        % Define Number of Years In Extratropical Data
        XC_Nyrs = config.Nyrs_XC;
end

% Command Prompts
disp('   Running CHESS: Monte Carlo Simulation (Storm Sampling)....');

%% REFERENCE CASE SAMPLING SEED (load_project_forcing = 1) OR OWN CACHED SAMPLING (hotstart_level 'reuse_sampling')
% Storm Types Reused, Effective Sampling Mode And Convergence-Check Storm Types (Shared With The GUI)
reuse = lcs_reference_reuse(config);
mcs_ref_pth = reuse.file;
% Seed Source Per Storm Type: 'Reference', 'Seed', Or '' (Not Reused, Sampled Fresh)
ref_src = reuse.src;
% Storm Types To Sample (In Sampling Order)
smpl_list = reuse.types;
reused = reuse.reused;
if config.load_project_forcing == 1
    if reuse.found && ~reuse.seed_found
        % warning('off','all') Is Active Here: Enable This One So It Is Shown
        warning('on', 'chess_lcs:referenceSeedNotFound');
        warning('chess_lcs:referenceSeedNotFound', ['Reference case ''%s'' has no sampling seed file; its sampling cannot be ',...
            'reused. Life cycles will be sampled fresh (as if load_project_forcing = 0).\n   %s'],...
            config.ref_case_name, lcs_sampling_seed_file(mcs_ref_pth));
        warning('off', 'chess_lcs:referenceSeedNotFound');
    elseif reuse.found
        for kk = find(~reused)
            disp(['     Warning: ref_case_name ('  config.ref_case_name ') does not have ' smpl_list{kk} ' sampling information...']);
        end
    else
        if reuse.own
            fallback = 'The cached sampling of this case is reused instead.';
        else
            fallback = 'Storms are sampled fresh instead.';
        end
        % warning('off','all') Is Active Here: Enable This One So It Is Shown
        warning('on', 'chess_lcs:referenceNotFound');
        warning('chess_lcs:referenceNotFound', ['load_project_forcing = 1, but the project forcing of ref_case_name (%s) ',...
            'was not found at:\n   %s\n%s'], config.ref_case_name, mcs_ref_pth, fallback);
        warning('off', 'chess_lcs:referenceNotFound');
    end
end
if reuse.own
    disp(['     Hotstart: reusing ' strjoin(smpl_list(reused), ' and ') ' life cycles from ' reuse.label ', storm values from the storm database.']);
end
% Tide Start Hours Carried From The Cached Run (resolve_hotstart_state.m) Belong To Its Own Life Cycles Only
for kk = 1:numel(smpl_list)
    fld = ['tide_indx_' lower(smpl_list{kk})];
    if isfield(config, fld) && ~(reuse.own && reused(kk))
        config.(fld) = [];
    end
end
% Life-Cycle Sampling Mode (0 = Full Poisson, 1 = Rate Matched)
% Reused Storms Were Sampled Under The Reference's Mode, So That Mode Drives Everything Downstream.
% Stored As lcs_effective_sampling_rate: lcs_restrict_sampling_rate Keeps The Configured Value (Hotstart Dependency).
lcs_mode = reuse.mode;
if lcs_mode ~= config.lcs_restrict_sampling_rate
    fprintf(['   Notice: lcs_restrict_sampling_rate = %d is used instead of the configured %d: the storms are reused from ',...
        '%s, which was sampled with lcs_restrict_sampling_rate = %d.\n'], lcs_mode, config.lcs_restrict_sampling_rate, reuse.label, lcs_mode);
end
config.lcs_effective_sampling_rate = lcs_mode;

%% SAMPLING MODE CHECKS (BEFORE SAMPLING)
if lcs_mode == 1
    disp(['   Notice: LCS sampling is rate restricted (lcs_restrict_sampling_rate = 1): each life cycle holds lambda x mcs_nYears +/- 1 storms ',...
        'and no convergence check is run. Life-cycle percentiles are conditional on rate-matched storm counts: they include storm ',...
        'selection, intensity and timing variability, but not storm-count variability.']);
end
for kk = 1:length(smpl_list)
    if reused(kk)
        disp(['     ' smpl_list{kk} ' storms are reused from ' reuse.label ': convergence check skipped (sampled storms are fixed).']);
        continue
    end
    switch smpl_list{kk}
        case 'XC'
            stm_rate = XC_Nstm/XC_Nyrs;
        case 'TC'
            stm_rate = prob_mass.TC_SRR(end);
    end
    check_storms_per_life_cycle(smpl_list{kk}, stm_rate, simulation_years, lcs_mode);
end
% Results Kept Per Storm Type (Sampling Dashboard Reuses Them Instead Of Re-Running The Check)
config.lcs_convergence_results = struct();
if ~isempty(reuse.check_types)
    checks = lcs_convergence_checks(config, prob_mass, reuse.check_types);
    for conv = checks
        config.lcs_convergence_results.(conv.stm_type) = conv;
    end
    for conv = checks(~[checks.converged])
        confirm_not_converged(conv, conv.stm_type, config.lcs_convergence_prompt);
    end
end

%% LIFE-CYCLE COLUMN MAP
C = lcs_columns();

%% CREATE DUMMY PEAKS DATASET IF NEEDED
if config.use_peaks == 0
    % Define Storm Types
    switch config.storm_sampling
        case 'CC'
            stm_list = {'TC','XC'};
        otherwise
            stm_list = {config.storm_sampling};
    end
    % Create Dummy Peak Dataset
    for kk = 1:length(stm_list)
        % Get Max Responses [ ]
        dummy_data = cell2mat(cellfun(@(x) max(x,[],1),...
            storm.(stm_list{kk}).('Timeseries').Default(:,2), 'un', false));
        % Replace Storm Duration For Peak Response (Storm Database Layout: Last Column)
        dummy_data(:, end) = config.storm_duration/24;
        % Create Dummy Dataset
        storm.(stm_list{kk}).('Peaks').('Default') = [ storm.(stm_list{kk}).('Timeseries').Default(:,1),...
            num2cell(dummy_data, 2)];
    end
end

%% DEFINE ADDITIONAL VARIABLES
% Initialize Life Cycle Storage Vars
if contains(storm_sampling,{'XC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('XC') = repmat({},number_of_life_cyles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('XC') = repmat({},number_of_life_cyles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('XC') = repmat({},number_of_life_cyles,1);
end
if contains(storm_sampling,{'TC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('TC') = repmat({},number_of_life_cyles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('TC') = repmat({},number_of_life_cyles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('TC') = repmat({},number_of_life_cyles,1);
end

%% CYCLE THROUGH LIFE CYCLES

    %% SAMPLE EXTRATROPICAL STORMS
    if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'XC')==1
        % Sample XC Storms According To Peak Responses
        hot_start = ~isempty(ref_src.XC);
        if hot_start
            disp(['     Loading XC sampling seed from ' reuse.label]);
            % Pull Sampling Seed
            sampled_xc = reuse.ids.XC;
            fprintf(1,'      Completion Progress: %3d%%\n',0);
            storm_data = storm.XC.Peaks.Default;
            % Populate Storm Data
            for lc=1:number_of_life_cyles
                % Create LCs
                project_forcing.Peaks.Default.('XC'){lc, 1} = reference_lc_peaks(sampled_xc{lc}, storm_data, config.storm_duration/24); % Life-Cycle Peaks Layout (lcs_columns.m)
                fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
            end
            % XC Peaks Are Copula Samples: Use The Reference's Sampled Values (Sampling Seed File) Instead Of Database Peaks
            xc_seed = load_reference_xc_seed(reuse.seed_pf, sampled_xc, reuse.label);
            % Only The Copula Values (SWL, Hm0, Tp, wDir) Are Kept: Identity And Storm Duration Come From This Run (As For TC)
            if ~isempty(xc_seed)
                copula_cols = [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir];
                project_forcing.Peaks.Default.('XC') = cellfun(@(s, d) copy_columns(d, s, copula_cols), xc_seed,...
                    project_forcing.Peaks.Default.('XC'), 'un', false);
            end
        end
        if ~hot_start
            disp('     Sampling Extratropical Events .....');
            fprintf(1,'      Completion Progress: %3d%%\n',0);
            for lc=1:number_of_life_cyles
                %
                [sampled_xc{lc, 1},...
                    project_forcing.Peaks.Default.('XC'){lc, 1}] = ...
                    sample_xc_storm(cell2mat(storm.XC.Peaks.Default), simulation_years, XC_Nstm/XC_Nyrs, lcs_mode);
                %
                fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
            end
        end
        % Replicate Storm Sampling With Storm Timeseries
        if config.use_timeseries == 1
            for lc=1:number_of_life_cyles
                % Build LCS Timeseries Dataset
                project_forcing.Timeseries.Default.('XC'){lc, 1} = timeseries_lc_creation(sampled_xc{lc, 1},...
                    storm.('XC').('Timeseries').('Default'));
            end
        end
        % Alternate Datasets: XC Peaks Are Copula Draws Fitted To The Default Peaks, Not Database Values Of The Sampled Storms.
        % WLP/WHP Are An Exact Copy Of The Default Life Cycles (The Copula Is Never Re-Sampled), So The Matching Methods
        % Compare On The Same XC Storms And Values; storm.XC.Peaks.WLP/WHP Are Not Read Here
        if config.create_wlp == 1
            project_forcing.Peaks.WLP.('XC') = project_forcing.Peaks.Default.('XC');
        end
        if config.create_whp == 1
            project_forcing.Peaks.WHP.('XC') = project_forcing.Peaks.Default.('XC');
        end
    end

    %% SAMPLE TROPICAL CYCLONES
    if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'TC')==1
        % Sample XC Storms According To Peak Responses
        hot_start = ~isempty(ref_src.TC);
        if hot_start
            disp(['     Loading TC sampling seed from ' reuse.label]);
            % Pull Sampling Seed
            sampled_tc = reuse.ids.TC;
            fprintf(1,'      Completion Progress: %3d%%\n',0);
            storm_data = storm.TC.Peaks.Default;
            % Populate Storm Data
            for lc=1:number_of_life_cyles
                % Create LCs
                project_forcing.Peaks.Default.('TC'){lc, 1} = reference_lc_peaks(sampled_tc{lc}, storm_data, config.storm_duration/24); % Life-Cycle Peaks Layout (lcs_columns.m)
                fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
            end
        end
        if ~hot_start
            disp('     Sampling Tropical Events .....');
            fprintf(1,'      Completion Progress: %3d%%\n',0);
            for lc=1:number_of_life_cyles
            [sampled_tc{lc, 1},...
                project_forcing.Peaks.Default.('TC'){lc, 1}] = ...
                sample_tc_storm(cell2mat(storm.TC.Peaks.Default), simulation_years, prob_mass, lcs_mode);
            %
            fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cyles)));
            end
        end
        % Replicate Storm Sampling With Storm Timeseries
        for lc=1:number_of_life_cyles
            if config.use_timeseries == 1
                % Build LCS Timeseries Dataset
                project_forcing.Timeseries.Default.('TC'){lc, 1} = timeseries_lc_creation(sampled_tc{lc, 1},...
                    storm.('TC').('Timeseries').('Default'));
            end
            % Create Alternate Datasets
            if config.create_wlp == 1
                project_forcing.Peaks.WLP.('TC'){lc, 1} = ...
                    sample_alternate_dataset(cell2mat(storm.TC.Peaks.WLP),...
                    sampled_tc{lc, 1}, project_forcing.Peaks.Default.('TC'){lc, 1});
            end
            if config.create_whp == 1
                project_forcing.Peaks.WHP.('TC'){lc, 1} = ...
                    sample_alternate_dataset(cell2mat(storm.TC.Peaks.WHP),...
                    sampled_tc{lc, 1}, project_forcing.Peaks.Default.('TC'){lc, 1});
            end
        end
    end

    %% COMBINE TROPICAL AND EXTRATROPICAL SAMPLED STORMS
    if strcmp(storm_sampling,'CC')==1
        for lc=1:number_of_life_cyles
            % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
            project_forcing.Peaks.Default.('CC'){lc, 1} = sortrows([project_forcing.Peaks.Default.('TC'){lc, 1};...
                project_forcing.Peaks.Default.('XC'){lc, 1}],[C.year, C.order, C.bin]);

            if whp_switch
                % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
                project_forcing.Peaks.WHP.('CC'){lc, 1} = sortrows([project_forcing.Peaks.WHP.('TC'){lc, 1};...
                    project_forcing.Peaks.WHP.('XC'){lc, 1}],[C.year, C.order, C.bin]);
            end
            if wlp_switch
                % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
                project_forcing.Peaks.WLP.('CC'){lc, 1} = sortrows([project_forcing.Peaks.WLP.('TC'){lc, 1};...
                    project_forcing.Peaks.WLP.('XC'){lc, 1}],[C.year, C.order, C.bin]);
            end
            % Combine Timseries Data
            if config.use_timeseries == 1
                project_forcing.Timeseries.Default.('CC'){lc, 1} = sortrows([project_forcing.Timeseries.Default.('TC'){lc, 1};...
                    project_forcing.Timeseries.Default.('XC'){lc, 1}],[C.year, C.order, C.bin]);
            end
        end
    end
    disp(newline);

%% REMOVE ADDITIONAL FIELDS (IF NEEDED)
% Wave Height Priority
if whp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WHP');
end
% Water Level Priority
if wlp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WLP');
end

%% SAVE SAMPLING SEED FILE (SAMPLING MODE, SAMPLED LIFE CYCLES & RAW XC PEAKS)
% Sampling Mode Used (Effective Mode When Storms Were Reused): Cases Reusing This One As Reference Inherit It.
% Sampled Life Cycles (Identity Columns Per Storm Type, Empty Life Cycles Included): Hotstart Level 'reuse_sampling'
% Rebuilds This Case's Forcing From Them Without Reading The Adjusted project_forcing.mat.
% XC Peak Values Are Copula Samples (Not Database Values). Keep Them As Sampled (Before Uncertainty And
% Adjustment) So Cases Reusing This One As Reference (load_project_forcing = 1) Get The Exact Same Values.
% Default Only (xc_peaks.Default): XC WLP/WHP Life Cycles Are Copies Of It.
% Stored Outside project_forcing: The Uncertainty/Adjustment Drivers Treat Every project_forcing Field As A Data Type.
if isfield(config, 'out_files') && isfield(config.out_files, 'project_forcing')
    lcs_restrict_sampling_rate = lcs_mode;
    sampled_ids = struct();
    if contains(storm_sampling, {'XC','CC'})
        sampled_ids.XC = sampled_xc;
    end
    if contains(storm_sampling, {'TC','CC'})
        sampled_ids.TC = sampled_tc;
    end
    seed_vars = {'lcs_restrict_sampling_rate', 'sampled_ids'};
    if contains(storm_sampling, {'XC','CC'})
        xc_peaks = struct('Default', {project_forcing.Peaks.Default.('XC')});
        seed_vars{end+1} = 'xc_peaks';
    end
    seed_file = lcs_sampling_seed_file(config.out_files.project_forcing);
    if ~isfolder(fileparts(seed_file))
        mkdir(fileparts(seed_file));
    end
    save(seed_file, seed_vars{:}, '-v7.3');
end

warning('on','all');
%% AUX FUNCTION: EXPECTED STORMS PER LIFE CYCLE CHECK
% A Rate <= 0 Can Never Produce Storms: Stop Before Sampling (Both Modes).
% Rate Matched (mode 1): Life Cycles Are Matched To rate x mcs_nYears +/- 1 Storm (sample_tc_storm / sample_xc_storm;
% ERDC/CHL TR-20-5 Sec. 3.2-3.3), Which Is Meaningless For rate x mcs_nYears <= 1: Stop Before Sampling.
% Full Poisson (mode 0): Life Cycles Without Storms Are Valid Outcomes, No Further Restriction.
    function check_storms_per_life_cycle(stm_type, stm_rate, n_years, mode)
        if ~(stm_rate > 0)
            error('chess_lcs:rateTooLow', 'chess_lcs: the %s storm rate is %g storms/yr; no %s storms can be sampled.', stm_type, stm_rate, stm_type);
        elseif mode == 1 && ~(stm_rate*n_years > 1)
            error('chess_lcs:rateTooLow', ['chess_lcs: expected %s storms per life cycle = %.2f (%.3f storms/yr x %d yr). ',...
                'Rate-matched life-cycle sampling needs more than 1; increase mcs_nYears to at least %d.'],...
                stm_type, stm_rate*n_years, stm_rate, n_years, floor(1/stm_rate) + 1);
        end
    end
%% AUX FUNCTION: TIMESERIES LC CREATOR
    function lc_out = timeseries_lc_creation(sample_indx, storm)
        % Life Cycle Without Storms
        if isempty(sample_indx)
            lc_out = zeros(0, C.n_timeseries);
            return
        end
        % Compute Stride To Make Data Hourly 
        hourly_stride = num2cell(1./(cellfun(@(x) x(1, 6), storm(:,2), 'un', true).*24));
        % Make storm data hourly 
        storm(:, 2) = cellfun(@(x, y) y(1:x:end,:), hourly_stride, storm(:, 2), 'un', false);
        % Indentify Storm IDs To Pull Hydrographs For
        [~, pull_indx] = arrayfun(@(x) ismember(x,...
            cell2mat(storm(:, 1))),...
            sample_indx(:, 1), 'un', true);
        % Pull Hydrographs
        stm_mat = cell2mat(storm(pull_indx, 2));
        % Pull And Reshape Sampling Index Information
        % (Row Count, Not length(): length Returns The Largest Dimension, So A Hydrograph With
        %  Fewer Time Steps Than Data Columns Would Get The Column Count)
        sample_indx_hyd = cell2mat(arrayfun(@(y, z) repmat(sample_indx(z, :), y, 1),...
            cellfun(@(x) size(x, 1), storm(pull_indx, 2)),...
            [1:size(sample_indx, 1)]', 'un', false));
        % Create Timestep Arrays To Append
        stm_tstp = arrayfun(@(x) [0:x-1]',...
            cellfun(@(x) size(x, 1), storm(pull_indx, 2)),'un', false);
        % Build LCS Timeseries Dataset (Storm Database Columns: SWL Hm0 Tp wDir datenum dt)
        lc_out = zeros(size(stm_mat, 1), C.n_timeseries);
        lc_out(:, [C.id, C.bin, C.year, C.order]) = sample_indx_hyd;
        lc_out(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir, C.dt]) = stm_mat(:, [1 2 2 3 4 6]);
        lc_out(:, C.step) = cell2mat(stm_tstp);
    end
%% AUX FUNCTION: REFERENCE CASE XC PEAK VALUES (SAMPLING SEED FILE)
    function seed = load_reference_xc_seed(ref_pf_file, sampled, ref_label)
        % Returns The Reference's Raw XC Default Peaks (Life Cycles) When They Match The Loaded Sampling Seed, Else []
        seed = [];
        S = load(lcs_sampling_seed_file(ref_pf_file), 'xc_peaks');
        ok = isfield(S, 'xc_peaks') && isfield(S.xc_peaks, 'Default') && numel(S.xc_peaks.Default) == numel(sampled) &&...
            all(cellfun(@(a, b) isequal(a(:, [C.id, C.bin, C.year, C.order]), b), S.xc_peaks.Default(:), sampled(:)));
        if ok
            seed = S.xc_peaks.Default;
            disp(['     Loading XC sampled peak values (copula) from ' ref_label]);
        else
            disp(['     Warning: sampling seed file of ' ref_label ' does not match its sampled storms; XC peak values are rebuilt from the storm database.']);
        end
    end
%% AUX FUNCTION: REFERENCE CASE LIFE CYCLE PEAKS FROM THE STORM DATABASE
    function lc_peaks = reference_lc_peaks(sampled, storm_data, duration_days)
        % Life-Cycle Peaks Layout (lcs_columns.m)
        % Find Sampled Event On Storm Suite
        stm_indx = arrayfun(@(x) find(cell2mat(storm_data(:, 1)) == x), sampled(:, 1), 'un', true);
        % Pull Storm Data (Explicit Size: A Life Cycle Without Storms Must Still Have All Columns)
        lc_peaks = zeros(numel(stm_indx), C.n_peaks);
        lc_peaks(:, [C.id, C.bin, C.year, C.order]) = sampled;
        for ss = 1:numel(stm_indx)
            % Storm Database Columns: SWL Hm0 Tp wDir
            lc_peaks(ss, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir]) = storm_data{stm_indx(ss), 2}(:, [1 2 2 3 4]);
        end
        lc_peaks(:, C.dt) = duration_days;
    end
%% AUX FUNCTION: COPY COLUMNS OF ONE LIFE-CYCLE MATRIX INTO ANOTHER
    function d = copy_columns(d, s, cols)
        d(:, cols) = s(:, cols);
    end
%% AUX FUNCTION: NOT CONVERGED LIFE CYCLE COUNT (PROMPT OR WARN)
    function confirm_not_converged(conv, stm_type, prompt)
        msg = sprintf('%s: mcs_nLC = %d is below the %d life cycles required for convergence.', stm_type, conv.nLC, conv.nLC_req);
        if prompt ~= 1
            % warning('off','all') Is Active Here: Enable This One So It Is Shown
            warning('on', 'chess_lcs:notConverged');
            warning('chess_lcs:notConverged', '%s Continuing (lcs_convergence_prompt = 0).', msg);
            warning('off', 'chess_lcs:notConverged');
            return
        end
        while true
            reply = lower(strtrim(input(sprintf('   %s Proceed or cancel? [p/c]: ', msg), 's')));
            if any(strcmp(reply, {'p', 'proceed'}))
                return
            elseif any(strcmp(reply, {'c', 'cancel'}))
                warning('on','all');
                error('chess_lcs:notConverged', ['chess_lcs: LCS cancelled. %s Set mcs_nLC >= %d in the input file ',...
                    '(or relax lcs_convergence_tol / lcs_convergence_confidence).'], msg, conv.nLC_req);
            end
        end
    end
%% AUX FUNCTION: SAMPLE ALTERNATE DATASETS (TC: WLP/WHP Database Values Of The Sampled Storms)
    function lcs_default = sample_alternate_dataset(storm_data, sampled_indx, lcs_default)
        % Get Row Index (Database Row Of Each Sampled Storm)
        [~, bi] = ismember(sampled_indx(:, 1), storm_data(:, 1));
        % Pull WLP/WHP Dataset For Sampled Storms (Life-Cycle Rows Keep Their Order; Was lcs_default(bi, ...),
        % Which Used Database Rows As Life-Cycle Rows And Padded The Life Cycle With Zero Rows)
        lcs_default(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir, C.dt]) = storm_data(bi, [2 3 3 4 5 7]);
    end
end
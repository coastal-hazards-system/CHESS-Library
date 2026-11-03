function [project_forcing, config] = chess_lcs(config, storm, prob_mass)
% chess_lcs  Sample the LCS life cycles of the project forcing.
%   [project_forcing, config] = chess_lcs(config, storm, prob_mass)
%
%   Life-cycle simulation (LCS, workflow 3) forcing build, called by
%   build_boundary_conditions. Draws mcs_nLC life cycles of mcs_nYears
%   years per storm type: XC storms with sample_xc_storm (Poisson storm
%   counts, uniform storm draw, Gaussian copula peak values), TC storms
%   with sample_tc_storm (Poisson storm counts, intensity bin by
%   recurrence rate, storm by probability mass). CC also holds, per life
%   cycle, the TC and XC life cycles combined and sorted by year, order
%   and bin.
%
%   Sampling mode lcs_restrict_sampling_rate: 0 = full Poisson (a life
%   cycle can hold no storms), 1 = rate matched (life cycles hold
%   rate x mcs_nYears +/- 1 storms). Before sampling, a storm rate <= 0,
%   or rate x mcs_nYears <= 1 in mode 1, stops with chess_lcs:rateTooLow.
%   In mode 0 the storm types sampled fresh get the convergence check
%   (lcs_convergence_checks); a mcs_nLC below the required count prompts
%   (lcs_convergence_prompt = 1; cancel errors chess_lcs:notConverged)
%   or warns.
%
%   Reuse (lcs_reference_reuse): with load_project_forcing = 1 the storm
%   types held by the sampling seed file of the reference case
%   (ref_case_name) are reused; otherwise, with hotstart level
%   'reuse_sampling', this case's own sampling seed file. Reused storms
%   keep the seed's sampling mode (lcs_effective_sampling_rate). Peak
%   values of reused storms come from the storm database, except XC
%   copula values, taken from the seed's xc_peaks when they match. The
%   tide start hours tide_indx_<type> are cleared unless the storm type is
%   this case's own reused sampling.
%
%   Matching methods (create_wlp / create_whp, Peaks only):
%     XC: WLP and WHP life cycles are an exact copy of the Default XC life
%         cycles (same storms, same copula-sampled values; the copula is
%         never re-sampled), fresh sampling and reuse alike.
%         storm.XC.Peaks.WLP/WHP are not read.
%     TC: WLP and WHP life cycles hold the same sampled storms as Default
%         with each storm's WLP/WHP database values.
%     CC: TC and XC life cycles of each matching method combined.
%
%   Life-cycle matrices (column map: lcs_columns):
%     Peaks (use_peaks = 1), nEvents x 10: id, bin (0 = XC; 1, 2, 3 = TC
%       low, mid, high intensity), year (1 to mcs_nYears), order (storm
%       number within the year), SWL [m, study datum], Hm0_toe [m] (equal
%       to Hm0_offshore here; depth limited later by
%       adjust_project_forcing), Hm0_offshore [m], Tp [s], wDir [deg; N=0,
%       E=+90, S=+/-180, W=-90], storm_duration [days] (storm_duration/24;
%       the storm database has none). No dt.
%     Timeseries (use_timeseries = 1, Default only), one row per time step
%       of each sampled storm's hydrograph, nRows x 12: columns 1-9 as
%       Peaks (values from the storm's Timeseries), dt [days] (row time
%       step), step (0 to n-1 per storm), storm_duration [days] (per storm,
%       on every row: storm_duration/24, or the storm's SWL duration with
%       compute_storm_duration = 1, timeseries_storm_durations).
%
%   use_peaks = 0 (Timeseries only): no Peaks life cycles; the samplers
%   draw the storm IDs from the Timeseries storms (same Poisson /
%   randsample draws as with Peaks) and the XC copula is not run.
%
%   File written (when out_files.project_forcing is set): the sampling
%   seed file (lcs_sampling_seed_file) with lcs_restrict_sampling_rate
%   (effective mode), sampled_ids.XC/.TC (per life cycle [storm ID, bin,
%   year, order], empty life cycles included) and, with XC sampling and
%   use_peaks = 1, xc_peaks.Default (raw XC copula life cycles, before
%   uncertainty and adjustment).
%
%   Inputs:
%     config    - CHESS configuration, 1x1 struct; reads storm_sampling
%                 ('XC', 'TC' or 'CC'), mcs_nLC, mcs_nYears [years],
%                 Nstm_XC and Nyrs_XC [years] (XC rate Nstm_XC/Nyrs_XC),
%                 storm_duration [hours], compute_storm_duration (0/1,
%                 missing = 0), use_peaks, use_timeseries, create_wlp,
%                 create_whp, lcs_restrict_sampling_rate (0/1),
%                 load_project_forcing, ref_case_name, hotstart_level
%                 (optional), lcs_convergence_tol,
%                 lcs_convergence_confidence, project_CLs,
%                 lcs_convergence_prompt, out_files.project_forcing and the
%                 chess_paths fields read by lcs_reference_reuse
%     storm     - storm database request (call_chs_data_formatter),
%                 storm.<XC|TC>.<Peaks|Timeseries>.<Default|WLP|WHP>
%                 (storm ID x data cells); Peaks read only with
%                 use_peaks = 1, XC WLP/WHP never read, struct
%     prob_mass - TC probability masses (TC_SRR, TC_Freq, smpl1, smpl2,
%                 smpl3; see sample_tc_storm), struct; unused for XC
%   Outputs:
%     project_forcing - life cycles,
%                       project_forcing.Peaks.<Default|WLP|WHP>.<st>{lc}
%                       and project_forcing.Timeseries.Default.<st>{lc}
%                       (st = the sampled storm types, plus CC for CC
%                       sampling; lc = 1 to mcs_nLC, mcs_nLC x 1 cell of
%                       double matrices as above); WLP/WHP only when
%                       requested, no Peaks with use_peaks = 0, struct
%     config          - input config plus lcs_effective_sampling_rate
%                       (0/1), lcs_convergence_results (check result per
%                       checked storm type) and the cleared
%                       tide_indx_<type> fields, struct
%
%   Tier: internal
%
%   See also build_boundary_conditions, sample_xc_storm, sample_tc_storm,
%   lcs_reference_reuse, lcs_convergence_checks, lcs_sampling_seed_file,
%   lcs_columns, timeseries_storm_durations.

%% GRAB INPUT FROM "config"
settings = read_life_cycle_settings(config);
storm_sampling = settings.storm_sampling;

% Command Prompts
disp('   Running CHESS: Monte Carlo Simulation (Storm Sampling)....');

%% REFERENCE CASE SAMPLING SEED (load_project_forcing = 1) OR OWN CACHED SAMPLING (hotstart_level 'reuse_sampling')
% Storm Types Reused, Effective Sampling Mode And Convergence-Check Storm Types (Shared With The GUI)
reuse = lcs_reference_reuse(config);
[config, lcs_mode] = report_reuse_and_clear_tides(config, reuse);

%% SAMPLING MODE CHECKS (BEFORE SAMPLING)
config = check_life_cycle_sampling(config, prob_mass, reuse, settings, lcs_mode);

%% LIFE-CYCLE COLUMN MAP
C = lcs_columns();
C_ts = lcs_columns('Timeseries');

%% DEFINE ADDITIONAL VARIABLES
% Initialize Life Cycle Storage Vars (Peaks Only With use_peaks = 1)
project_forcing = empty_life_cycle_storage(storm_sampling, settings.number_of_life_cycles, settings.use_peaks);
% Sampled Storms Per Storm Type (Sampling Seed File)
sampled_xc = [];
sampled_tc = [];

%% CYCLE THROUGH LIFE CYCLES
%% SAMPLE EXTRATROPICAL STORMS
if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'XC')==1
    [project_forcing, sampled_xc] = sample_extratropical_life_cycles(project_forcing, storm, config, reuse, settings, lcs_mode, C, C_ts);
end

%% SAMPLE TROPICAL CYCLONES
if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'TC')==1
    [project_forcing, sampled_tc] = sample_tropical_life_cycles(project_forcing, storm, prob_mass, config, reuse, settings, lcs_mode, C, C_ts);
end

%% COMBINE TROPICAL AND EXTRATROPICAL SAMPLED STORMS
if strcmp(storm_sampling,'CC')==1
    project_forcing = combine_storm_type_life_cycles(project_forcing, config, settings, C);
end
disp(newline);

%% REMOVE ADDITIONAL FIELDS (IF NEEDED)
project_forcing = remove_unrequested_alternate_datasets(project_forcing, settings);

%% SAVE SAMPLING SEED FILE (SAMPLING MODE, SAMPLED LIFE CYCLES & RAW XC PEAKS WITH use_peaks = 1)
save_sampling_seed(config, lcs_mode, sampled_xc, sampled_tc, project_forcing);
end

%% AUX FUNCTION: LIFE-CYCLE SAMPLING SETTINGS FROM "config"
function settings = read_life_cycle_settings(config)
% Storm Sampling Scheme
settings.storm_sampling = config.storm_sampling;
% Peaks Life Cycles (use_peaks = 0: Timeseries Only, Storm IDs Drawn From The Timeseries Storms)
settings.use_peaks = config.use_peaks == 1;
% Number Of Life Cycles
settings.number_of_life_cycles = config.mcs_nLC;
% Simulation Length
settings.simulation_years = config.mcs_nYears;
% Create Water Level Priority Switch
settings.wlp_switch = config.create_wlp;
% Timeseries Storm Duration From Each Storm's SWL (Missing = 0: config.storm_duration)
settings.compute_storm_duration = isfield(config, 'compute_storm_duration') && isequal(config.compute_storm_duration, 1);
% Create Wave Height Priority Switch
settings.whp_switch = config.create_whp;
switch settings.storm_sampling
    case 'TC'
        settings.xc_storm_count = [];
        settings.xc_record_years = [];
    otherwise
        % Define Number Of Extratropical Storms In Data
        settings.xc_storm_count = config.Nstm_XC;
        % Define Number of Years In Extratropical Data
        settings.xc_record_years = config.Nyrs_XC;
end
end

%% AUX FUNCTION: REPORT REFERENCE / CACHED SAMPLING REUSE, CLEAR TIDE START HOURS AND SET THE EFFECTIVE SAMPLING MODE
function [config, lcs_mode] = report_reuse_and_clear_tides(config, reuse)
mcs_ref_pth = reuse.file;
% Storm Types To Sample (In Sampling Order)
storm_types_to_sample = reuse.types;
reused = reuse.reused;
if config.load_project_forcing == 1
    if reuse.found && ~reuse.seed_found
        warning('chess_lcs:referenceSeedNotFound', ['Reference case ''%s'' has no sampling seed file; its sampling cannot be ',...
            'reused. Life cycles will be sampled fresh (as if load_project_forcing = 0).\n   %s'],...
            config.ref_case_name, lcs_sampling_seed_file(mcs_ref_pth));
    elseif reuse.found
        for kk = find(~reused)
            disp(['     Warning: ref_case_name ('  config.ref_case_name ') does not have ' storm_types_to_sample{kk} ' sampling information...']);
        end
    else
        if reuse.own
            fallback = 'The cached sampling of this case is reused instead.';
        else
            fallback = 'Storms are sampled fresh instead.';
        end
        warning('chess_lcs:referenceNotFound', ['load_project_forcing = 1, but the project forcing of ref_case_name (%s) ',...
            'was not found at:\n   %s\n%s'], config.ref_case_name, mcs_ref_pth, fallback);
    end
end
if reuse.own
    disp(['     Hotstart: reusing ' strjoin(storm_types_to_sample(reused), ' and ') ' life cycles from ' reuse.label ', storm values from the storm database.']);
end
% Tide Start Hours Carried From The Cached Run (resolve_hotstart_state.m) Belong To Its Own Life Cycles Only
for kk = 1:numel(storm_types_to_sample)
    fld = ['tide_indx_' lower(storm_types_to_sample{kk})];
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
end

%% AUX FUNCTION: SAMPLING MODE CHECKS (BEFORE SAMPLING): STORM RATES AND LIFE-CYCLE CONVERGENCE
function config = check_life_cycle_sampling(config, prob_mass, reuse, settings, lcs_mode)
% Storm Types To Sample (In Sampling Order)
storm_types_to_sample = reuse.types;
reused = reuse.reused;
if lcs_mode == 1
    disp(['   Notice: LCS sampling is rate restricted (lcs_restrict_sampling_rate = 1): each life cycle holds lambda x mcs_nYears +/- 1 storms ',...
        'and no convergence check is run. Life-cycle percentiles are conditional on rate-matched storm counts: they include storm ',...
        'selection, intensity and timing variability, but not storm-count variability.']);
end
for kk = 1:length(storm_types_to_sample)
    if reused(kk)
        disp(['     ' storm_types_to_sample{kk} ' storms are reused from ' reuse.label ': convergence check skipped (sampled storms are fixed).']);
        continue
    end
    switch storm_types_to_sample{kk}
        case 'XC'
            storm_rate = settings.xc_storm_count/settings.xc_record_years;
        case 'TC'
            storm_rate = prob_mass.TC_SRR(end);
    end
    check_storms_per_life_cycle(storm_types_to_sample{kk}, storm_rate, settings.simulation_years, lcs_mode);
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
end

%% AUX FUNCTION: EMPTY LIFE-CYCLE STORAGE PER STORM TYPE AND DATASET
function project_forcing = empty_life_cycle_storage(storm_sampling, number_of_life_cycles, use_peaks)
project_forcing = struct();
if ~use_peaks
    return
end
if contains(storm_sampling,{'XC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('XC') = repmat({},number_of_life_cycles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('XC') = repmat({},number_of_life_cycles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('XC') = repmat({},number_of_life_cycles,1);
end
if contains(storm_sampling,{'TC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('TC') = repmat({},number_of_life_cycles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('TC') = repmat({},number_of_life_cycles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('TC') = repmat({},number_of_life_cycles,1);
end
end

%% AUX FUNCTION: SAMPLE EXTRATROPICAL STORMS (OR REUSE THE REFERENCE / CACHED SAMPLING SEED)
function [project_forcing, sampled_xc] = sample_extratropical_life_cycles(project_forcing, storm, config, reuse, settings, lcs_mode, C, C_ts)
number_of_life_cycles = settings.number_of_life_cycles;
% Sample XC Storms According To Peak Responses
hot_start = ~isempty(reuse.src.XC);
if hot_start
    disp(['     Loading XC sampling seed from ' reuse.label]);
    % Pull Sampling Seed
    sampled_xc = reuse.ids.XC;
    if settings.use_peaks
        fprintf(1,'      Completion Progress: %3d%%\n',0);
        storm_data = storm.XC.Peaks.Default;
        % Populate Storm Data
        for lc=1:number_of_life_cycles
            % Create LCs
            project_forcing.Peaks.Default.('XC'){lc, 1} = reference_lc_peaks(sampled_xc{lc}, storm_data, config.storm_duration/24, C); % Life-Cycle Peaks Layout (lcs_columns.m)
            fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
        end
        % XC Peaks Are Copula Samples: Use The Reference's Sampled Values (Sampling Seed File) Instead Of Database Peaks
        xc_seed = load_reference_xc_seed(reuse.seed_pf, sampled_xc, reuse.label, C);
        % Only The Copula Values (SWL, Hm0, Tp, wDir) Are Kept: Identity And Storm Duration Come From This Run (As For TC)
        if ~isempty(xc_seed)
            copula_cols = [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir];
            project_forcing.Peaks.Default.('XC') = cellfun(@(s, d) copy_columns(d, s, copula_cols), xc_seed,...
                project_forcing.Peaks.Default.('XC'), 'un', false);
        end
    end
end
if ~hot_start
    disp('     Sampling Extratropical Events .....');
    fprintf(1,'      Completion Progress: %3d%%\n',0);
    if ~settings.use_peaks
        % Timeseries Only: Storm IDs Drawn From The Timeseries Storms, No Copula Peaks
        xc_storm_ids = cell2mat(storm.XC.Timeseries.Default(:, 1));
    end
    for lc=1:number_of_life_cycles
        if settings.use_peaks
            [sampled_xc{lc, 1},...
                project_forcing.Peaks.Default.('XC'){lc, 1}] = ...
                sample_xc_storm(cell2mat(storm.XC.Peaks.Default), settings.simulation_years, settings.xc_storm_count/settings.xc_record_years, lcs_mode, config.storm_duration/24);
        else
            sampled_xc{lc, 1} = sample_xc_storm(xc_storm_ids, settings.simulation_years, settings.xc_storm_count/settings.xc_record_years, lcs_mode, config.storm_duration/24);
        end
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
    end
end
% Replicate Storm Sampling With Storm Timeseries
if config.use_timeseries == 1
    ts_dur = sampled_storm_durations(sampled_xc, storm.('XC').('Timeseries').('Default'), config.storm_duration, settings.compute_storm_duration);
    for lc=1:number_of_life_cycles
        % Build LCS Timeseries Dataset
        project_forcing.Timeseries.Default.('XC'){lc, 1} = timeseries_lc_creation(sampled_xc{lc, 1},...
            storm.('XC').('Timeseries').('Default'), ts_dur, C, C_ts);
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

%% AUX FUNCTION: SAMPLE TROPICAL CYCLONES (OR REUSE THE REFERENCE / CACHED SAMPLING SEED)
function [project_forcing, sampled_tc] = sample_tropical_life_cycles(project_forcing, storm, prob_mass, config, reuse, settings, lcs_mode, C, C_ts)
number_of_life_cycles = settings.number_of_life_cycles;
% Sample TC Storms According To Their Probability Masses
hot_start = ~isempty(reuse.src.TC);
if hot_start
    disp(['     Loading TC sampling seed from ' reuse.label]);
    % Pull Sampling Seed
    sampled_tc = reuse.ids.TC;
    if settings.use_peaks
        fprintf(1,'      Completion Progress: %3d%%\n',0);
        storm_data = storm.TC.Peaks.Default;
        % Populate Storm Data
        for lc=1:number_of_life_cycles
            % Create LCs
            project_forcing.Peaks.Default.('TC'){lc, 1} = reference_lc_peaks(sampled_tc{lc}, storm_data, config.storm_duration/24, C); % Life-Cycle Peaks Layout (lcs_columns.m)
            fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
        end
    end
end
if ~hot_start
    disp('     Sampling Tropical Events .....');
    fprintf(1,'      Completion Progress: %3d%%\n',0);
    if ~settings.use_peaks
        % Timeseries Only: Storm IDs Drawn From The Timeseries Storms
        tc_storm_ids = cell2mat(storm.TC.Timeseries.Default(:, 1));
    end
    for lc=1:number_of_life_cycles
        if settings.use_peaks
            [sampled_tc{lc, 1},...
                project_forcing.Peaks.Default.('TC'){lc, 1}] = ...
                sample_tc_storm(cell2mat(storm.TC.Peaks.Default), settings.simulation_years, prob_mass, lcs_mode, config.storm_duration/24);
        else
            sampled_tc{lc, 1} = sample_tc_storm(tc_storm_ids, settings.simulation_years, prob_mass, lcs_mode, config.storm_duration/24);
        end
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
    end
end
% Replicate Storm Sampling With Storm Timeseries
if config.use_timeseries == 1
    ts_dur = sampled_storm_durations(sampled_tc, storm.('TC').('Timeseries').('Default'), config.storm_duration, settings.compute_storm_duration);
end
for lc=1:number_of_life_cycles
    if config.use_timeseries == 1
        % Build LCS Timeseries Dataset
        project_forcing.Timeseries.Default.('TC'){lc, 1} = timeseries_lc_creation(sampled_tc{lc, 1},...
            storm.('TC').('Timeseries').('Default'), ts_dur, C, C_ts);
    end
    % Create Alternate Datasets
    if config.create_wlp == 1
        project_forcing.Peaks.WLP.('TC'){lc, 1} = ...
            sample_alternate_dataset(cell2mat(storm.TC.Peaks.WLP),...
            sampled_tc{lc, 1}, project_forcing.Peaks.Default.('TC'){lc, 1}, C);
    end
    if config.create_whp == 1
        project_forcing.Peaks.WHP.('TC'){lc, 1} = ...
            sample_alternate_dataset(cell2mat(storm.TC.Peaks.WHP),...
            sampled_tc{lc, 1}, project_forcing.Peaks.Default.('TC'){lc, 1}, C);
    end
end
end

%% AUX FUNCTION: COMBINE TROPICAL AND EXTRATROPICAL LIFE CYCLES (CC)
function project_forcing = combine_storm_type_life_cycles(project_forcing, config, settings, C)
for lc=1:settings.number_of_life_cycles
    if settings.use_peaks
        % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
        project_forcing.Peaks.Default.('CC'){lc, 1} = sortrows([project_forcing.Peaks.Default.('TC'){lc, 1};...
            project_forcing.Peaks.Default.('XC'){lc, 1}],[C.year, C.order, C.bin]);
    end

    if settings.whp_switch
        % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
        project_forcing.Peaks.WHP.('CC'){lc, 1} = sortrows([project_forcing.Peaks.WHP.('TC'){lc, 1};...
            project_forcing.Peaks.WHP.('XC'){lc, 1}],[C.year, C.order, C.bin]);
    end
    if settings.wlp_switch
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

%% AUX FUNCTION: REMOVE ALTERNATE DATASETS THAT WERE NOT REQUESTED
function project_forcing = remove_unrequested_alternate_datasets(project_forcing, settings)
if ~settings.use_peaks
    return
end
% Wave Height Priority
if settings.whp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WHP');
end
% Water Level Priority
if settings.wlp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WLP');
end
end

%% AUX FUNCTION: SAVE SAMPLING SEED FILE (SAMPLING MODE, SAMPLED LIFE CYCLES & RAW XC PEAKS)
% Sampling Mode Used (Effective Mode When Storms Were Reused): Cases Reusing This One As Reference Inherit It.
% Sampled Life Cycles (Identity Columns Per Storm Type, Empty Life Cycles Included): Hotstart Level 'reuse_sampling'
% Rebuilds This Case's Forcing From Them Without Reading The Adjusted project_forcing.mat.
% XC Peak Values Are Copula Samples (Not Database Values). Keep Them As Sampled (Before Uncertainty And
% Adjustment) So Cases Reusing This One As Reference (load_project_forcing = 1) Get The Exact Same Values.
% Default Only (xc_peaks.Default): XC WLP/WHP Life Cycles Are Copies Of It. use_peaks = 0: No xc_peaks (No Peaks Life
% Cycles); A use_peaks = 1 Case Reusing Such A Seed Gets Storm Database Peaks For The Sampled XC Storms.
% Stored Outside project_forcing: The Uncertainty/Adjustment Drivers Treat Every project_forcing Field As A Data Type.
function save_sampling_seed(config, lcs_mode, sampled_xc, sampled_tc, project_forcing)
storm_sampling = config.storm_sampling;
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
    if contains(storm_sampling, {'XC','CC'}) && config.use_peaks == 1
        xc_peaks = struct('Default', {project_forcing.Peaks.Default.('XC')});
        seed_vars{end+1} = 'xc_peaks';
    end
    seed_file = lcs_sampling_seed_file(config.out_files.project_forcing);
    if ~isfolder(fileparts(seed_file))
        mkdir(fileparts(seed_file));
    end
    save(seed_file, seed_vars{:}, '-v7.3');
end
end

%% AUX FUNCTION: EXPECTED STORMS PER LIFE CYCLE CHECK
% A Rate <= 0 Can Never Produce Storms: Stop Before Sampling (Both Modes).
% Rate Matched (mode 1): Life Cycles Are Matched To rate x mcs_nYears +/- 1 Storm (sample_tc_storm / sample_xc_storm;
% ERDC/CHL TR-20-5 Sec. 3.2-3.3), Which Is Meaningless For rate x mcs_nYears <= 1: Stop Before Sampling.
% Full Poisson (mode 0): Life Cycles Without Storms Are Valid Outcomes, No Further Restriction.
function check_storms_per_life_cycle(stm_type, storm_rate, n_years, mode)
if ~(storm_rate > 0)
    error('chess_lcs:rateTooLow', 'chess_lcs: the %s storm rate is %g storms/yr; no %s storms can be sampled.', stm_type, storm_rate, stm_type);
elseif mode == 1 && ~(storm_rate*n_years > 1)
    error('chess_lcs:rateTooLow', ['chess_lcs: expected %s storms per life cycle = %.2f (%.3f storms/yr x %d yr). ',...
        'Rate-matched life-cycle sampling needs more than 1; increase mcs_nYears to at least %d.'],...
        stm_type, storm_rate*n_years, storm_rate, n_years, floor(1/storm_rate) + 1);
end
end

%% AUX FUNCTION: STORM DURATION PER STORM DATABASE ROW (TIMESERIES)
function dur = sampled_storm_durations(sampled, storm_ts, storm_duration, compute_storm_duration)
% Storm Duration [days] Of Every Sampled Storm (timeseries_storm_durations.m), Computed Once Per Storm ID And
% Reused In Every Life Cycle The Storm Appears In. NaN For Database Storms Not Sampled
dur = NaN(size(storm_ts, 1), 1);
ids = unique(cell2mat(cellfun(@(x) x(:, 1), sampled(:), 'un', false)));
rows = find(ismember(cell2mat(storm_ts(:, 1)), ids));
dur(rows) = timeseries_storm_durations(storm_ts(rows, 2), storm_duration, compute_storm_duration);
end

%% AUX FUNCTION: TIMESERIES LC CREATOR
function lc_out = timeseries_lc_creation(sample_indx, storm, ts_dur, C, C_ts)
% Life Cycle Without Storms
if isempty(sample_indx)
    lc_out = zeros(0, C.n_timeseries);
    return
end
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
lc_out(:, C_ts.storm_duration) = repelem(ts_dur(pull_indx), cellfun(@(x) size(x, 1), storm(pull_indx, 2)));
end

%% AUX FUNCTION: REFERENCE CASE XC PEAK VALUES (SAMPLING SEED FILE)
function seed = load_reference_xc_seed(ref_pf_file, sampled, ref_label, C)
% Returns The Reference's Raw XC Default Peaks (Life Cycles) When They Match The Loaded Sampling Seed, Else []
seed = [];
seed_file = lcs_sampling_seed_file(ref_pf_file);
if ~ismember('xc_peaks', who('-file', seed_file))
    disp(['     Warning: sampling seed file of ' ref_label ' holds no XC sampled peak values (sampled with use_peaks = 0); XC peak values are rebuilt from the storm database.']);
    return
end
S = load(seed_file, 'xc_peaks');
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
function lc_peaks = reference_lc_peaks(sampled, storm_data, duration_days, C)
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
lc_peaks(:, C.storm_duration) = duration_days;
end

%% AUX FUNCTION: COPY COLUMNS OF ONE LIFE-CYCLE MATRIX INTO ANOTHER
function d = copy_columns(d, s, cols)
d(:, cols) = s(:, cols);
end

%% AUX FUNCTION: NOT CONVERGED LIFE CYCLE COUNT (PROMPT OR WARN)
function confirm_not_converged(conv, stm_type, prompt)
msg = sprintf('%s: mcs_nLC = %d is below the %d life cycles required for convergence.', stm_type, conv.nLC, conv.nLC_req);
if prompt ~= 1
    warning('chess_lcs:notConverged', '%s Continuing (lcs_convergence_prompt = 0).', msg);
    return
end
while true
    reply = lower(strtrim(input(sprintf('   %s Proceed or cancel? [p/c]: ', msg), 's')));
    if any(strcmp(reply, {'p', 'proceed'}))
        return
    elseif any(strcmp(reply, {'c', 'cancel'}))
        error('chess_lcs:notConverged', ['chess_lcs: LCS cancelled. %s Set mcs_nLC >= %d in the input file ',...
            '(or relax lcs_convergence_tol / lcs_convergence_confidence).'], msg, conv.nLC_req);
    end
end
end

%% AUX FUNCTION: SAMPLE ALTERNATE DATASETS (TC: WLP/WHP Database Values Of The Sampled Storms)
function lcs_default = sample_alternate_dataset(storm_data, sampled_indx, lcs_default, C)
% Get Row Index (Database Row Of Each Sampled Storm)
[~, bi] = ismember(sampled_indx(:, 1), storm_data(:, 1));
% Pull WLP/WHP Dataset For Sampled Storms (Life-Cycle Rows Keep Their Order; Was lcs_default(bi, ...),
% Which Used Database Rows As Life-Cycle Rows And Padded The Life Cycle With Zero Rows).
% storm_data Columns: ID SWL Hm0 Tp wDir datenum; C.storm_duration Stays From lcs_default (config.storm_duration)
lcs_default(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir]) = storm_data(bi, [2 3 3 4 5]);
end
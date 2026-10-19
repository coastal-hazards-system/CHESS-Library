function [project_forcing, config]  = call_project_forcing_formater(config, storm, prob_mass)
%CALL_PROJECT_FORCING_FORMATER Loads/builds project_forcing, applying hotstart coverage checks.
% IMPORTANT: Callers MUST capture BOTH outputs:
%   [project_forcing, config] = call_project_forcing_formater(config, storm, prob_mass);
% The coverage check below can reset config.u_engine/config.f_adjust to 0
% when a cached project_forcing.mat does not cover the current request --
% later pipeline stages only see that reset if the second output is
% captured. No caller inside CHESS_Library currently enforces this.
%% GRAB INPUT FROM "config"
% Define Requested Workflow (1 -> RB1 Approach, other-> Life-Cycle Base)
workflow = config.workflow;
% Define Storm Type ('XC' or 'TC')
storm_sampling = config.storm_sampling;
% Initialize Load Flag As False
load_pass = false;
% Grab Sim File Paths
existing_file = config.out_files.project_forcing;

%% FORMAT FORCING DATA ACCORDING TO WORKFLOW
% Check If Project Forcing Exist
if exist(existing_file, 'file') == 2
    % Load Project Forcing And Check If Existing Data Complies With Request (Shared With The GUI)
    [covers, project_forcing, missing_desc] = project_forcing_cache_hit(config);
    if ~covers % Requested Data Is Not Present
        disp_toggle(config.print_progress, sprintf('Hotstart: cached project forcing does not cover requested permutation (missing: %s) -- deleting, will be regenerated....', missing_desc));
        delete(config.out_files.project_forcing);
        load_pass = false;
        config.u_engine = 0;
        config.f_adjust = 0;
    else
        disp('A project_forcing already exist for this alternative. Trying to load....');
        disp(['Successfully loaded:' existing_file]);
        load_pass = true;
        % LCS: Mode The Cached Life Cycles Were Sampled With (Sampling Seed File, Written By chess_lcs)
        if workflow == 3
            seed_file = lcs_sampling_seed_file(existing_file);
            if isfile(seed_file)
                S = load(seed_file, 'lcs_restrict_sampling_rate');
                config.lcs_effective_sampling_rate = S.lcs_restrict_sampling_rate;
                % Saved Config Carries It Too (Plots Read The Saved Config)
                save(config.out_files.config, 'config', '-append');
            end
        end
    end
else
    % RESET DATA MOD FLAGS
    config.u_engine = 0;
    config.f_adjust = 0;
end

%% FORMAT STORM SUITE ACCORDING TO WORKFLOW
if ~load_pass
    % Prompt User
    disp('Preping project forcing data....');
    % Peaks Storm Duration From config (In Memory Only; Peaks Only, Timeseries Time Steps Untouched): The Storm DB
    % Column Holds The Duration The DB Was Built With, While Dn50 Always Uses config.storm_duration
    storm = restamp_peaks_storm_duration(storm, config.storm_duration);
    % Define Events Per Case
    switch workflow
        case {1,4} % CHESS: PROS (RB1, RB3, FB)
            check_peaks_timeseries_ids(storm, storm_sampling);
            % Reshape Forcing Parameters For RB Analysis (nStorms * normal_discretizations)
            project_forcing = chess_pros_formater(storm_sampling, storm, prob_mass, config.print_progress);
            % Save Peaks Life Cycle Structures
            save(existing_file,'project_forcing','-v7.3');
        case 2 % CHESS: Deterministic (No Replicates)
            check_peaks_timeseries_ids(storm, storm_sampling);
            project_forcing = chess_det_formater(storm_sampling, storm, config.print_progress);
            % Save Project Forcing
            save(existing_file,'project_forcing','-v7.3');
        case 3 % CHESS: LCS
            % Call CHESS: Monte Carlo Storm Sampler (config: Adds lcs_effective_sampling_rate)
            [project_forcing, config] = chess_lcs(config, storm, prob_mass);
            % Save Peaks Life Cycle Structures
            save(existing_file,'project_forcing','-v7.3');
    end
    % Save Config
    save(config.out_files.config, 'config', '-append');
end
end

%% AUX FUNCTION: PEAKS AND TIMESERIES MUST HOLD THE SAME STORM IDS IN THE SAME ORDER
% PROS/DET Pair Them By Row (One Tide Start Hour Per Storm Shared By Both: draw_tide_indices.m).
% LCS Is Not Checked: It Pulls Hydrographs By Storm ID (chess_lcs.m timeseries_lc_creation)
function check_peaks_timeseries_ids(storm, storm_sampling)
if strcmp(storm_sampling, 'CC')
    storm_types = {'TC', 'XC'};
else
    storm_types = {storm_sampling};
end
for st = storm_types
    if ~all(isfield(storm.(st{1}), {'Peaks', 'Timeseries'}))
        continue
    end
    ts_id = cell2mat(storm.(st{1}).Timeseries.Default(:, 1));
    for mt = fieldnames(storm.(st{1}).Peaks)'
        pk_id = cell2mat(storm.(st{1}).Peaks.(mt{1})(:, 1));
        n = min(numel(pk_id), numel(ts_id));
        k = find(pk_id(1:n) ~= ts_id(1:n), 1);
        if ~isempty(k)
            error('chess:peaksTimeseriesIdMismatch',...
                '%s storm IDs of Peaks (%s) and Timeseries differ: first mismatch at row %d (Peaks ID %d, Timeseries ID %d).',...
                st{1}, mt{1}, k, pk_id(k), ts_id(k));
        elseif numel(pk_id) ~= numel(ts_id)
            error('chess:peaksTimeseriesIdMismatch',...
                '%s storm counts of Peaks (%s) and Timeseries differ: %d vs %d storms.',...
                st{1}, mt{1}, numel(pk_id), numel(ts_id));
        end
    end
end
end

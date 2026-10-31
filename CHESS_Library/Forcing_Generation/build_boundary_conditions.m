function [project_forcing, config] = build_boundary_conditions(config, storm, prob_mass)
%{
    %% DESCRIPTION
        Step 1 of call_chess_boundary_conditions.m: builds the project
        forcing of the whole storm request, per workflow. Nothing is saved
        here except the LCS sampling seed file (chess_lcs.m).
            - PROS (RB/FB, workflows 1, 4): chess_pros_formater.m
              (replicates per storm).
            - DET (workflow 2): chess_det_formater.m (storms as recorded).
            - LCS (workflow 3): chess_lcs.m (samples the life cycles; adds
              config.lcs_effective_sampling_rate).
            - Multi-line stage 2 (config.multiline, multiline_stage2_config.m):
              apply_stage1_transmission.m (stage 1's complete forcing,
              transmitted behind stage 1, depth limited at the stage 2 toe).
        Peaks storm duration is restamped from config.storm_duration (in
        memory only). Every dataset carries storm_duration (event length);
        Timeseries also carry dt (row time step); with
        compute_storm_duration = 1 (missing = 0) the Timeseries
        storm_duration is the SWL duration of each storm
        (timeseries_storm_durations.m). PROS/DET check that Peaks and
        Timeseries hold the same storm IDs in the same order.

    %% INPUTS
        config: Run configuration. | struct
        storm: Storm database request (call_chs_data_formater.m). | struct
        prob_mass: Storm probability masses. | struct

    %% OUTPUTS
        project_forcing: Project forcing before uncertainty and
            adjustments. | struct
        config: Run configuration (LCS: lcs_effective_sampling_rate). | struct

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if isfield(config, 'multiline') && ~isempty(config.multiline)
    % Multi-Line Stage 2: Stage 1's Storms/Life Cycles, Uncertainty, Tides And SLR Are Kept
    project_forcing = apply_stage1_transmission(config);
    return
end
% Peaks Storm Duration From config (In Memory Only; Peaks Only, Timeseries Time Steps Untouched): The Storm DB
% Column Holds The Duration The DB Was Built With; The Restamped Column Becomes The Peaks storm_duration (Dn50, LCS Peaks Reliability)
storm = restamp_peaks_storm_duration(storm, config.storm_duration);
% Timeseries storm_duration: config.storm_duration, Or Per Storm From Its SWL (compute_storm_duration = 1; Missing = 0)
if ~isfield(config, 'compute_storm_duration') || isempty(config.compute_storm_duration)
    config.compute_storm_duration = 0;
end
switch config.workflow
    case {1,4} % CHESS: PROS (RB1, RB3, FB)
        check_peaks_timeseries_ids(storm, config.storm_sampling);
        % Reshape Forcing Parameters For RB Analysis (nStorms * normal_discretizations)
        project_forcing = chess_pros_formater(config.storm_sampling, storm, prob_mass, config.print_progress,...
            config.storm_duration, config.compute_storm_duration);
    case 2 % CHESS: Deterministic (No Replicates)
        check_peaks_timeseries_ids(storm, config.storm_sampling);
        project_forcing = chess_det_formater(config.storm_sampling, storm, config.print_progress,...
            config.storm_duration, config.compute_storm_duration);
    case 3 % CHESS: LCS
        % Monte Carlo Storm Sampler (config: Adds lcs_effective_sampling_rate)
        [project_forcing, config] = chess_lcs(config, storm, prob_mass);
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

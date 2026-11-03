function [project_forcing, config] = build_boundary_conditions(config, storm, prob_mass)
% build_boundary_conditions  Build the project forcing of the storm request.
%   [project_forcing, config] = build_boundary_conditions(config, storm,
%       prob_mass)
%
%   Step 1 of call_chess_boundary_conditions: builds the project forcing of
%   the whole storm request, per workflow. Nothing is saved here except the
%   LCS sampling seed file (chess_lcs).
%     - PROS (RB/FB, workflows 1, 4) and DET (workflow 2):
%       chess_forcing_formatter (PROS: replicates per storm; DET: storms as
%       recorded). Peaks and Timeseries of a storm type must hold the same
%       storm IDs in the same order (else error
%       chess:peaksTimeseriesIdMismatch).
%     - LCS (workflow 3): chess_lcs (samples the life cycles; adds
%       lcs_effective_sampling_rate to config).
%     - Multi-line stage 2 (multiline, multiline_stage2_config):
%       apply_stage1_transmission (stage 1's complete forcing, transmitted
%       behind stage 1, depth limited at the stage 2 toe); config is
%       returned unchanged.
%   The storm database holds no storm duration: every dataset gets
%   storm_duration (event length; Peaks: the config storm_duration).
%   Timeseries also carry dt (row time step); with compute_storm_duration
%   = 1 (missing = 0) the Timeseries storm_duration is the SWL duration of
%   each storm (timeseries_storm_durations).
%
%   Inputs:
%     config    - CHESS configuration, 1x1 struct; reads workflow,
%                 storm_sampling, print_progress, storm_duration [hours],
%                 compute_storm_duration, multiline (and the chess_lcs
%                 fields for LCS)
%     storm     - storm database request (call_chs_data_formatter), struct
%     prob_mass - storm probability masses (PROS TC: TC_Freq), struct
%   Outputs:
%     project_forcing - project forcing before uncertainty and adjustments,
%                       project_forcing.<data type>.<match type>.<storm
%                       type>, struct
%     config          - input config with compute_storm_duration (0 when
%                       missing) and, LCS, lcs_effective_sampling_rate,
%                       struct
%
%   Tier: internal
%
%   See also call_chess_boundary_conditions, chess_forcing_formatter,
%   chess_lcs, apply_stage1_transmission, timeseries_storm_durations.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if isfield(config, 'multiline') && ~isempty(config.multiline)
    % Multi-Line Stage 2: Stage 1's Storms/Life Cycles, Uncertainty, Tides And SLR Are Kept
    project_forcing = apply_stage1_transmission(config);
    return
end
% Timeseries storm_duration: config.storm_duration, Or Per Storm From Its SWL (compute_storm_duration = 1; Missing = 0)
if ~isfield(config, 'compute_storm_duration') || isempty(config.compute_storm_duration)
    config.compute_storm_duration = 0;
end
switch config.workflow
    case {1,2,4} % CHESS: PROS (RB1, RB3, FB; Replicates Per Storm) And Deterministic (No Replicates)
        check_peaks_timeseries_ids(storm, config.storm_sampling);
        project_forcing = chess_forcing_formatter(config.storm_sampling, storm, prob_mass, config.print_progress,...
            config.storm_duration, config.compute_storm_duration, config.workflow ~= 2);
    case 3 % CHESS: LCS
        % Monte Carlo Storm Sampler (config: Adds lcs_effective_sampling_rate)
        [project_forcing, config] = chess_lcs(config, storm, prob_mass);
end
end

%% AUX FUNCTION: PEAKS AND TIMESERIES MUST HOLD THE SAME STORM IDS IN THE SAME ORDER
% PROS/DET Pair Them By Row (One Tide Start Hour Per Storm Shared By Both: draw_tide_indices.m).
% LCS Is Not Checked: It Pulls Hydrographs By Storm ID (chess_lcs.m timeseries_lc_creation)
function check_peaks_timeseries_ids(storm, storm_sampling)
storm_types = storm_types_for_sampling(storm_sampling, {'TC', 'XC'});
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

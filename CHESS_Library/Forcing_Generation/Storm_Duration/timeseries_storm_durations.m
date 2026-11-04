function dur = timeseries_storm_durations(storm_data, storm_duration, compute_storm_duration, storm_ids)
% timeseries_storm_durations  Event length of each Timeseries storm.
%   dur = timeseries_storm_durations(storm_data, storm_duration,
%       compute_storm_duration, storm_ids)
%
%   Event length (storm_duration) of each Timeseries storm of the storm
%   database, set when the project forcing is built (chess_forcing_formatter,
%   chess_lcs):
%     compute_storm_duration ~= 1: storm_duration for every storm.
%     compute_storm_duration == 1: SWL hydrograph duration of the storm
%       (estimate_storm_durations: 98% of the amplitude, shifted threshold,
%       1 h minimum) from its own database record (before SLR, tides and
%       uncertainty), so a storm has the same duration in every replicate
%       and every life cycle. The IDs of the storms with a flagged
%       duration are always printed, one line per flag (edge_start,
%       edge_end, threshold_shifted, min_applied, flat_signal; see
%       storm_duration_event), after a line with the flagged count.
%
%   Inputs:
%     storm_data             - storm database Timeseries records, one per
%                              storm (M x 6 [SWL Hm0 Tp wDir datenum dt]),
%                              cell
%     storm_duration         - storm duration (config storm_duration)
%                              [hours], scalar double
%     compute_storm_duration - 1 = per-storm SWL duration (config
%                              compute_storm_duration), double
%     storm_ids              - storm ID of each storm_data record (for the
%                              flag report), numel(storm_data) x 1 double
%   Outputs:
%     dur - storm duration per storm [days], numel(storm_data) x 1 double
%
%   Tier: internal
%
%   See also estimate_storm_durations, storm_duration_event,
%   chess_forcing_formatter, chess_lcs.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

dur = repmat(storm_duration/24, numel(storm_data), 1);
if compute_storm_duration == 1 && ~isempty(storm_data)
    T = estimate_storm_durations(cellfun(@(x) x(:, 1), storm_data(:), 'un', false),...
        cellfun(@(x) x(:, 5), storm_data(:), 'un', false), 0.98, true, 1);
    dur = T.duration_hr/24;
    report_flagged_storms(T, storm_ids(:));
end
end

function report_flagged_storms(T, storm_ids)
flags = {
    'edge_start',        'no up-crossing before the peak, record start used'
    'edge_end',          'no down-crossing after the peak, record end used'
    'threshold_shifted', 'record starts or ends above the threshold, threshold raised'
    'min_applied',       'duration below the 1 h minimum, minimum used'
    'flat_signal',       'flat SWL, whole record used'};
flagged = false(height(T), 1);
for k = 1:size(flags, 1)
    flagged = flagged | T.(flags{k, 1});
end
fprintf('               Storm durations (compute_storm_duration = 1): %d of %d storms flagged\n', nnz(flagged), height(T));
for k = 1:size(flags, 1)
    ids = storm_ids(T.(flags{k, 1}));
    if ~isempty(ids)
        fprintf('                  %s (%s), %d storms: %s\n', flags{k, 1}, flags{k, 2}, numel(ids), strjoin(compose('%d', ids), ', '));
    end
end
end

function dur = timeseries_storm_durations(storm_data, storm_duration, compute_storm_duration)
% timeseries_storm_durations  Event length of each Timeseries storm.
%   dur = timeseries_storm_durations(storm_data, storm_duration,
%       compute_storm_duration)
%
%   Event length (storm_duration) of each Timeseries storm of the storm
%   database, set when the project forcing is built (chess_forcing_formatter,
%   chess_lcs):
%     compute_storm_duration ~= 1: storm_duration for every storm.
%     compute_storm_duration == 1: SWL hydrograph duration of the storm
%       (estimate_storm_durations: 98% of the amplitude, shifted threshold,
%       1 h minimum) from its own database record (before SLR, tides and
%       uncertainty), so a storm has the same duration in every replicate
%       and every life cycle.
%
%   Inputs:
%     storm_data             - storm database Timeseries records, one per
%                              storm (M x 6 [SWL Hm0 Tp wDir datenum dt]),
%                              cell
%     storm_duration         - storm duration (config storm_duration)
%                              [hours], scalar double
%     compute_storm_duration - 1 = per-storm SWL duration (config
%                              compute_storm_duration), double
%   Outputs:
%     dur - storm duration per storm [days], numel(storm_data) x 1 double
%
%   Tier: internal
%
%   See also estimate_storm_durations, chess_forcing_formatter, chess_lcs.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

dur = repmat(storm_duration/24, numel(storm_data), 1);
if compute_storm_duration == 1 && ~isempty(storm_data)
    T = estimate_storm_durations(cellfun(@(x) x(:, 1), storm_data(:), 'un', false),...
        cellfun(@(x) x(:, 5), storm_data(:), 'un', false), 0.98, true, 1);
    dur = T.duration_hr/24;
end
end

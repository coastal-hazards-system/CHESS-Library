function dur = timeseries_storm_durations(storm_data, storm_duration, compute_storm_duration)
%{
    %% DESCRIPTION
        Event length (storm_duration) of each Timeseries storm of the storm
        database, set when the project forcing is built (chess_pros_formater.m,
        chess_det_formater.m, chess_lcs.m):
            compute_storm_duration ~= 1: storm_duration (config) for every storm.
            compute_storm_duration == 1: SWL hydrograph duration of the storm
                (estimate_storm_durations.m: 98% of the amplitude, shifted
                threshold, 1 h minimum) from its own database record (before
                SLR, tides and uncertainty), so a storm has the same duration
                in every replicate and every life cycle.

    %% INPUTS
        storm_data: Storm database Timeseries records, one per storm
            ([SWL Hm0 Tp wDir datenum dt]). | cell
        storm_duration: Storm duration [hrs] (config.storm_duration). | double
        compute_storm_duration: 1 = per-storm SWL duration (config). | double

    %% OUTPUTS
        dur: Storm duration per storm [days] (one row per storm). | double

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
dur = repmat(storm_duration/24, numel(storm_data), 1);
if compute_storm_duration == 1 && ~isempty(storm_data)
    T = estimate_storm_durations(cellfun(@(x) x(:, 1), storm_data(:), 'un', false),...
        cellfun(@(x) x(:, 5), storm_data(:), 'un', false), 0.98, true, 1);
    dur = T.duration_hr/24;
end
end

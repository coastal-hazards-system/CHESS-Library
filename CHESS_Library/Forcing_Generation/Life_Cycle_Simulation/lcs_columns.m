function C = lcs_columns(data_type)
%{
    %% DESCRIPTION
        Column map of the CHESS: LCS life-cycle matrices (project_forcing
        .Peaks/.Timeseries.<mt>.<st>{lc}). Every read/write of a life-cycle
        column goes through these names.
            Peaks      [nEvents x 10]: id | bin | year | order | SWL | Hm0_toe |
                                       Hm0_offshore | Tp | wDir | storm_duration
            Timeseries [nHours x 12]:  same 1-9 | dt (time step) | step (0:n-1 per storm) |
                                       storm_duration (per storm, on every row of the storm)
        dt [days]: time step of a Timeseries row (Q, DPA). Peaks have no dt.
        storm_duration [days]: event length (Dn50 number of waves, peaks
        reliability): config.storm_duration, or with compute_storm_duration = 1
        the SWL duration of each Timeseries storm (timeseries_storm_durations.m).
        Hm0_offshore: wave height before depth limitation (after uncertainty).
        Hm0_toe: depth limited at the toe (adjust_project_forcing.m).

    %% INPUTS
        data_type: Optional, 'Peaks' (default) or 'Timeseries'. Sets
           storm_duration (column 10 or 12); every other index is shared
           (dt and step are Timeseries columns). | char

    %% OUTPUTS
        C: Struct of column indices (id, bin, year, order, SWL, Hm0_toe,
           Hm0_offshore, Tp, wDir, dt, step, storm_duration) and the column
           counts n_peaks (10) and n_timeseries (12). | struct

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
C = struct('id', 1, 'bin', 2, 'year', 3, 'order', 4, 'SWL', 5, 'Hm0_toe', 6, 'Hm0_offshore', 7,...
    'Tp', 8, 'wDir', 9, 'dt', 10, 'step', 11, 'storm_duration', 10, 'n_peaks', 10, 'n_timeseries', 12);
if nargin > 0 && strcmpi(data_type, 'Timeseries')
    C.storm_duration = 12;
end
end

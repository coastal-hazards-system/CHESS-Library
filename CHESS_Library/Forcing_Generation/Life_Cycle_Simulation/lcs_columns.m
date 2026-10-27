function C = lcs_columns()
%{
    %% DESCRIPTION
        Column map of the CHESS: LCS life-cycle matrices (project_forcing
        .Peaks/.Timeseries.<mt>.<st>{lc}). Every read/write of a life-cycle
        column goes through these names.
            Peaks      [nEvents x 10]: id | bin | year | order | SWL | Hm0_toe |
                                       Hm0_offshore | Tp | wDir | dt (storm duration)
            Timeseries [nHours x 11]:  same 1-9 | dt (time step) | step (0:n-1 per storm)
        Hm0_offshore: wave height before depth limitation (after uncertainty).
        Hm0_toe: depth limited at the toe (adjust_project_forcing.m).

    %% OUTPUTS
        C: Struct of column indices (id, bin, year, order, SWL, Hm0_toe,
           Hm0_offshore, Tp, wDir, dt, step) and the column counts
           n_peaks (10) and n_timeseries (11). | struct

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
C = struct('id', 1, 'bin', 2, 'year', 3, 'order', 4, 'SWL', 5, 'Hm0_toe', 6, 'Hm0_offshore', 7,...
    'Tp', 8, 'wDir', 9, 'dt', 10, 'step', 11, 'n_peaks', 10, 'n_timeseries', 11);
end

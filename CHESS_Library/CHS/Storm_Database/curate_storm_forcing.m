function dataset = curate_storm_forcing(dataset)
% curate_storm_forcing  Forcing curation of one storm dataset (the one place of these rules).
%   dataset = curate_storm_forcing(dataset)
%
%   Applied to every dataset of a storm database when it is built from
%   CHS files (build_storm_database) and when a storm .mat is imported
%   (call_input_parser, CHSStormDBImportUI), through
%   curate_storm_database; works on any dataset of that layout. Rules,
%   row by row:
%     Hm0 <= 0.01 m: Hm0 = 0.01 m and Tp = 1.1*3.3*Hm0^0.63 (Wilson
%                    wind-sea period of that height, about 0.199 s;
%                    floor_wave_height)
%     SWL <= -100 m: SWL = NaN (no forcing)
%   NaN values are kept. The other columns are not changed.
%
%   Inputs:
%     dataset - N x 2 cell: column 1 storm ID, column 2 storm data with
%               SWL [m, study datum] in column 1, Hm0 [m] in column 2 and
%               Tp [s] in column 3 (Peaks 1 x 5 [SWL Hm0 Tp wDir datenum],
%               Timeseries M x 6 [SWL Hm0 Tp wDir datenum dt])
%   Outputs:
%     dataset - curated dataset, N x 2 cell
%
%   Tier: internal
%
%   See also curate_storm_database, floor_wave_height,
%   remove_storms_without_water_level, build_storm_database.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

dataset(:, 2) = cellfun(@curate_storm_rows, dataset(:, 2), 'UniformOutput', false);
end

%% LOCAL FUNCTIONS
function data = curate_storm_rows(data)
[data(:, 2), data(:, 3)] = floor_wave_height(data(:, 2), data(:, 3));
data(data(:, 1) <= -100, 1) = NaN;
end

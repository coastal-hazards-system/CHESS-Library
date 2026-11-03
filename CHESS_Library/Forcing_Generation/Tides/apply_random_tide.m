function [SWL, tide_indx] = apply_random_tide(tide_file, SWL, t_size, tide_indx)
% apply_random_tide  Add a random tide to the SWL of each storm.
%   [SWL, tide_indx] = apply_random_tide(tide_file, SWL, t_size, tide_indx)
%
%   Adds the tide record of tide_file (read_tide_series) to the SWL of each
%   storm: a storm of L time steps starting at tide hour idx gets tide
%   values idx : idx + L - 1 (Peaks: the value at idx). Start hours are
%   drawn when tide_indx is empty; supplied ones are kept except for storms
%   that do not fit the tide record (tide_start_hours). The same tide is
%   added to every replicate column.
%
%   Inputs:
%     tide_file - tide file (create_tide_file layout), char or string
%     SWL       - still water level [m, study datum, positive up], cell: one
%                 cell per storm (PROS/DET, nSteps x n_replicates) or per
%                 life cycle (LCS, column)
%     t_size    - time steps per storm (forcing_storm_lengths), cell (one
%                 cell per SWL row)
%     tide_indx - tide start hours to keep ([] = draw all), cell (same
%                 shape as t_size)
%   Outputs:
%     SWL       - SWL with the tide added [m, study datum, positive up],
%                 cell (same shape as the input)
%     tide_indx - tide start hours used (rows of the tide record), cell
%
%   Tier: internal
%
%   See also adjust_project_forcing, tide_start_hours, read_tide_series,
%   draw_tide_indices, create_tide_file.

%% IMPORT TIDAL DATA
tidal_data = read_tide_series(tide_file);

%% ADD RANDOM TIDE ACCORDINGLY
% Start Hours: Drawn If None Were Given; Each Storm Hydrograph Fits The Tide Record
tide_indx = tide_start_hours(length(tidal_data), t_size, tide_indx);
rand_tide = {};
% For Each Event
for stm = 1:length(tide_indx)
    % Add Tide To Storm Data
    rand_tide{stm, 1} = cell2mat(arrayfun(@(x, y) tidal_data(x:x+y-1), tide_indx{stm}, t_size{stm},'un',false));
    % Life Cycle Without Storms: cell2mat Gives 0x0, Keep A Column (0x0 Assigned To A Column Deletes It Downstream)
    if isempty(rand_tide{stm, 1})
        rand_tide{stm, 1} = zeros(0, 1);
    end
end
% Add To Surge
for gg = 1:size(SWL, 2)
    % Add Tidal Signal To Storm Data
    SWL(:, gg) = cellfun(@(x,y) x + y, SWL(:, gg), rand_tide, 'un', false);
end
end
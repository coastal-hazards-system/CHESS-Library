function SWL = random_tide(tide, SWL, start_hours, storm_lengths)
% random_tide  Add the tide record to the SWL of one storm or one life cycle.
%   SWL = chess.BoundaryConditions.tides.random_tide(tide, SWL,
%       start_hours, storm_lengths)
%
%   A storm of L time steps starting at tide hour idx gets the tide values
%   idx : idx + L - 1 (Peaks: the value at idx). The same tide is added to
%   every column (replicate) of SWL. The start hours come from
%   chess.BoundaryConditions.tides.start_hours.
%
%   Inputs:
%     tide          - hourly tide record (chess.BoundaryConditions.tides.read_series)
%                     [m], column
%     SWL           - still water level [m, study datum, positive up]: the
%                     rows of one storm (PROS/DET, nSteps x n_replicates) or
%                     of one life cycle (LCS, all its storms stacked), double
%     start_hours   - tide start hour of each storm in SWL (rows of the tide
%                     record), column
%     storm_lengths - time steps of each storm in SWL, same size as
%                     start_hours
%   Outputs:
%     SWL - SWL with the tide added [m, study datum, positive up], same
%           size as the input
%
%   See also chess.BoundaryConditions.tides.start_hours,
%   chess.BoundaryConditions.tides.read_series.

tide_rows = cell2mat(arrayfun(@(first, n) tide(first:first + n - 1), start_hours, storm_lengths, 'un', false));
% Life Cycle Without Storms: cell2mat Gives 0x0, Keep A Column
if isempty(tide_rows)
    tide_rows = zeros(0, 1);
end
SWL = SWL + tide_rows;
end

function SWL = sea_level_change(SWL, sea_level_change)
% sea_level_change  Add a sea level change to the still water level.
%   SWL = chess.BoundaryConditions.water_levels.sea_level_change(SWL,
%       sea_level_change)
%
%   Inputs:
%     SWL              - still water level [m, study datum, positive up],
%                        double array
%     sea_level_change - sea level change added to SWL (config swl_slr) [m],
%                        scalar double
%   Outputs:
%     SWL - adjusted still water level [m, study datum, positive up], same
%           size as the input
%
%   See also chess.BoundaryConditions.tides.random_tide.

SWL = SWL + sea_level_change;
end

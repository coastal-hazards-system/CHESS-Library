function c = physical_constants()
% chess.Common.physical_constants  Physical constants used by CHESS (single source).
%   c = chess.Common.physical_constants() returns the physical constants of
%   every CHESS computation, in SI units.
%
%   Inputs:
%     none
%   Outputs:
%     c - struct with fields
%           gravity - standard gravity, 9.80665 [m/s^2] (CGPM 1901, exact),
%                     scalar double
%
%   See also chess.Common.chess_units.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

persistent constants
if isempty(constants)
    constants = struct();
    constants.gravity = 9.80665; % [m/s^2] standard gravity (CGPM 1901, exact)
end
c = constants;
end

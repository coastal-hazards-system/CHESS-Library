function gravity_constant = standard_gravity()
% standard_gravity  Standard gravitational acceleration used by CHESS.
%   gravity_constant = standard_gravity() returns 9.80665 m/s^2, the value
%   used by every CHESS run (config.gravity_constant, set in
%   call_input_parser, and the GUI chessController.GRAVITY constant).
%
%   Inputs:
%     none
%   Outputs:
%     gravity_constant - standard gravity, 9.80665 [m/s^2], scalar double
%
%   Tier: internal
%
%   See also call_input_parser.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

gravity_constant = 9.80665;
end

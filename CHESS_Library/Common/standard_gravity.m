function gravity_constant = standard_gravity()
%{
    %% DESCRIPTION
        Standard gravitational acceleration used by every CHESS run
        (config.gravity_constant, set in call_input_parser.m, and the GUI
        chessController.GRAVITY constant).

    %% INPUTS
        None.

    %% OUTPUTS
        gravity_constant: 9.80665 [m/s^2]. | double

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
gravity_constant = 9.80665;
end

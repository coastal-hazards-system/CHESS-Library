function msg = chs_dependencies_message(storm_sampling, region)
%{
    %% DESCRIPTION
        Error message of a TC/CC request without CHS_Dependencies covering
        the region (chs_dependencies_available.m). Shared by
        call_input_parser.m (early check) and call_chs_data_formater.m
        (storm database build).

    %% INPUTS
        storm_sampling: Requested storm sampling ('TC' | 'CC'). | char
        region: CHS region (config.region). | char

    %% OUTPUTS
        msg: Error message. | char

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
msg = sprintf(['Error: %s storm sampling needs the CHS_Dependencies folder covering region %s (TC probability masses, ',...
    'bias & uncertainty). Without it StormSim runs XC only. Download from: https://chs.erdc.dren.mil/Home/Library'],...
    storm_sampling, region);
end

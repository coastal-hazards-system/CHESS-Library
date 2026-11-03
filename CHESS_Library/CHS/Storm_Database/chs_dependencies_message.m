function msg = chs_dependencies_message(storm_sampling, region)
% chs_dependencies_message  Error message: TC/CC without CHS_Dependencies.
%   msg = chs_dependencies_message(storm_sampling, region)
%
%   Error message of a TC/CC request without CHS_Dependencies covering
%   the region (chs_dependency_files tropical_statistics_available).
%   Shared by call_input_parser (early check), call_chs_data_formatter
%   (storm database build) and the GUI storm database wizard.
%
%   Inputs:
%     storm_sampling - requested storm sampling, 'TC' or 'CC', char
%     region         - CHS region (config.region), char
%   Outputs:
%     msg            - error message, char
%
%   Tier: internal
%
%   See also chs_dependency_files, call_input_parser,
%   call_chs_data_formatter.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
msg = sprintf(['Error: %s storm sampling needs the CHS_Dependencies folder covering region %s (TC probability masses, ',...
    'bias & uncertainty). Without it CHESS runs XC only. Download from: https://chs.erdc.dren.mil/Home/Library'],...
    storm_sampling, region);
end

function tf = chs_dependencies_available(chs_dependencies, region)
%{
    %% DESCRIPTION
        True when the CHS_Dependencies folder exists and covers the CHS
        region (TC probability masses, study grid, bias & uncertainty).
        Without it CHESS runs XC only: a CHS input builds its storm
        database with XC only and a TC/CC request stops with an error.

    %% INPUTS
        chs_dependencies: CHS_Dependencies folder (config.chs_dependencies). | char
        region: CHS region (config.region). | char

    %% OUTPUTS
        tf: CHS_Dependencies available for the region. | logical

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
region_list = {'CHS-TX','CHS-SA','CHS-PR','CHS-NA','CHS-GoM','CHS-LA','CHS-GLM', 'CHS-GLH','CHS-S2G'}; % Regions With TC Files
tf = ~isempty(chs_dependencies) && exist(chs_dependencies, 'dir') == 7 && ismember(region, region_list);
end

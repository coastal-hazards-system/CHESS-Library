function check_offshore_elevation(config)
%{
    %% DESCRIPTION
        Stops every run early when no usable offshore elevation is available
        (always required: offshore end of the PSE transect conceptual model,
        used by the damaging depth and the transect): the storm database has no study grid value (config is
        only overwritten when it has one, storm_db_info.m 'apply') and the
        PSE geometry gives none (input file row / GUI PSE table; field missing,
        empty or NaN). Shared by the
        library (call_chs_data_formater.m, after the storm database's
        db_info is applied) and the GUI (create_resp_config, Run).

    %% INPUTS
        config.
            offshore_elevation: Optional. Offshore elevation [m, study    | double | 1 x 1
                                datum, positive up].
            region, sp_ID: CHS region and savepoint (error message).
            storm_db, out_files.storm_and_prob_mass: Optional. Storm
                                database name / file (error message).
            chs_dependencies: Optional. CHS_Dependencies folder (error message).

    %% OUTPUTS
        None. Error check_offshore_elevation:missing when the value is
        missing.

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if isfield(config, 'offshore_elevation') && isnumeric(config.offshore_elevation) &&...
        isscalar(config.offshore_elevation) && isfinite(config.offshore_elevation)
    return
end
% Why The Storm Database Has No Study Grid Value
region = char(config.region);
chs_dependencies = '';
if isfield(config, 'chs_dependencies')
    chs_dependencies = config.chs_dependencies;
end
if ~startsWith(region, 'CHS-')
    reason = 'Custom Modeling storm data, no CHS study grid';
elseif ismember(region, {'CHS-TX', 'CHS-PR'})
    reason = sprintf('the %s study grid has no value column', region);
elseif ~isempty(chs_dependencies) && ~chs_dependencies_available(chs_dependencies, region)
    reason = sprintf('no CHS_Dependencies for %s', region);
else
    reason = 'grid fill value at the savepoint, no CHS_Dependencies, or a storm database built before offshore elevations were stored';
end
sp_str = '';
if isnumeric(config.sp_ID) && isscalar(config.sp_ID)
    sp_str = sprintf(' for SP%d', config.sp_ID);
end
% Storm Database Name: storm_db, Else The Database File Name (chess_paths.m Default <region>_SP<sp_ID>)
db_name = '';
if isfield(config, 'storm_db')
    db_name = char(string(config.storm_db));
end
if isempty(db_name) && isfield(config, 'out_files') && isfield(config.out_files, 'storm_and_prob_mass')
    [~, db_name] = fileparts(config.out_files.storm_and_prob_mass);
end
error('check_offshore_elevation:missing',...
    ['CHESS needs offshore_elevation (offshore end of the PSE transect; elevation, positive up, study datum): the storm database %s has no study grid value%s (%s) and the PSE geometry gives none.\n'...
    'Enter offshore_elevation in the PSE geometry (GUI: PSE creation; input file: row offshore_elevation).'], db_name, sp_str, reason);
end

function check_offshore_elevation(config)
% check_offshore_elevation  Stop a run that has no usable offshore elevation.
%   check_offshore_elevation(config) returns when offshore_elevation is a
%   finite numeric scalar and errors otherwise. offshore_elevation is always
%   required (offshore end of the PSE transect conceptual model, used by
%   the damaging depth and the transect): it comes from the storm database's
%   study grid value (config is only overwritten when the grid has one,
%   storm_db_info 'apply'), else from the PSE geometry (input file row / GUI
%   PSE table). Shared by the library (call_chs_data_formatter, after the
%   storm database's db_info is applied) and the GUI (create_resp_config,
%   Run).
%
%   Inputs:
%     config - CHESS configuration, 1x1 struct; reads:
%                offshore_elevation - offshore elevation [m, study datum,
%                                     positive up], scalar double (optional;
%                                     missing, empty or NaN fails)
%                region, sp_ID      - CHS region and savepoint (error
%                                     message)
%                storm_db, out_files.storm_and_prob_mass - storm database
%                                     name / file (optional, error message)
%                chs_dependencies   - CHS_Dependencies folder (optional,
%                                     error message)
%   Outputs:
%     none; error check_offshore_elevation:missing when the value is
%     missing, naming the reason the storm database has no grid value
%
%   Tier: internal
%
%   See also call_chs_data_formatter, damaging_depth, chs_dependency_files,
%   storm_db_info.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
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
chs_files = chs_dependency_files(chs_dependencies, region);
if ~startsWith(region, 'CHS-')
    reason = 'Custom Modeling storm data, no CHS study grid';
elseif chs_files.region_supported && ~chs_files.study_grid_has_elevation
    reason = sprintf('the %s study grid has no value column', region);
elseif ~isempty(chs_dependencies) && ~chs_files.study_grid_available
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

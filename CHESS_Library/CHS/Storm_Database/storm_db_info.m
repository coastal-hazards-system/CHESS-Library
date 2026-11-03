function out = storm_db_info(action, varargin)
% storm_db_info  Create, apply or validate the storm database details (db_info).
%   db_info = storm_db_info('create', bnu, tc_bias_corrected, Nyrs_XC,
%       Nstm_XC, source_file)
%   config = storm_db_info('apply', db_info, config)
%   tf = storm_db_info('valid', db_info)
%
%   Storm database details (db_info), saved as the third variable of
%   <db>.mat (save(..., 'storm', 'prob_mass', 'db_info')). Shared by the
%   library and the GUI storm database wizard, so both write and read
%   the same plain struct. Determined once, when the database is built.
%   'create' builds db_info. 'apply' copies tc_bias_corrected, the
%   chs_swl_* / chs_hm0_* fields and Nyrs_XC/Nstm_XC (when not empty)
%   into config, and build_date as config.storm_db_build_date (hotstart
%   dependency: a database rebuilt since the cached run gives
%   'resample'). The study grid wins: a non-empty offshore_elevation sets
%   config.offshore_elevation (config.offshore_elevation_source =
%   'Storm DB grid'); otherwise config keeps its own offshore_elevation
%   (the fallback, source 'config'), as for a db_info without these
%   fields. 'valid' is true for a db_info holding every bias/uncertainty,
%   XC and provenance field (older databases have none); the offshore/
%   savepoint location fields are not required.
%   Sources: 'chs_dependencies' (CHS_Dependencies Bias_and_Uncertainty
%   files), 'manual' (entered when the database was built), 'provided'
%   (entered with the storm data in the GUI wizard, Custom_Modeling).
%
%   Inputs:
%     action            - 'create', 'apply' or 'valid', char
%     'create' form:
%     bnu               - bias & uncertainty and savepoint location
%                         (storm_db_bias_uncertainty output: chs_swl_*,
%                         chs_hm0_*, offshore_elevation,
%                         offshore_elevation_source, grid_distance_m,
%                         sp_lat, sp_lon), struct
%     tc_bias_corrected - 1 if the TC SWL bias correction was applied,
%                         else 0, scalar double
%     Nyrs_XC           - XC record length [years] ([] without XC),
%                         double
%     Nstm_XC           - XC storm count ([] without XC), double
%     source_file       - input the database was built from (name +
%                         extension), char or string
%     'apply' and 'valid' forms:
%     db_info           - storm database details, struct
%     config            - 'apply' form: CHESS configuration, 1x1 struct
%   Outputs:
%     db_info - 'create' form: storm database details, struct; fields:
%                 tc_bias_corrected - 1 if the TC SWL bias correction was
%                     applied, else 0, double
%                 chs_swl_b_a, chs_swl_b_r - SWL bias, absolute [m] /
%                     relative [-], double
%                 chs_swl_u_a, chs_swl_u_r - SWL uncertainty, absolute [m]
%                     / relative [-], double
%                 chs_swl_bu_source - source of the SWL values, char
%                 chs_hm0_b_a, chs_hm0_b_r - Hm0 bias (stored only, not
%                     applied; [] if not available), double
%                 chs_hm0_u_a, chs_hm0_u_r - Hm0 uncertainty, absolute
%                     [m] / relative [-], double
%                 chs_hm0_bu_source - source of the Hm0 values, char
%                 offshore_elevation - offshore (savepoint) elevation [m,
%                     study datum, positive up]: minus the depth
%                     (positive down) of the savepoint's CHS_Dependencies
%                     study grid point (savepoint_grid_row; [] when the
%                     grid has no value, no grid), double
%                 offshore_elevation_source - 'chs_dependencies' or '',
%                     char
%                 grid_distance_m - distance from the savepoint
%                     coordinates to that grid point [m] ([] without
%                     coordinates, no grid), double
%                 sp_lat, sp_lon - savepoint coordinates [deg] ([] when
%                     not available), double
%                 Nyrs_XC, Nstm_XC - XC record length [years] and XC
%                     storm count ([] without XC), double
%                 source_file - input the database was built from (name +
%                     extension), char
%                 build_date - build date ('yyyy-mm-dd HH:MM:SS'), char
%     config  - 'apply' form: config with the db_info fields, struct
%     tf      - 'valid' form: db_info holds every required field, logical
%
%   Tier: internal
%
%   See also storm_db_bias_uncertainty, build_storm_database,
%   storm_db_check, call_chs_data_formatter.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
bnu_fields = {'chs_swl_b_a', 'chs_swl_b_r', 'chs_swl_u_a', 'chs_swl_u_r', 'chs_swl_bu_source',...
    'chs_hm0_b_a', 'chs_hm0_b_r', 'chs_hm0_u_a', 'chs_hm0_u_r', 'chs_hm0_bu_source'};
loc_fields = {'offshore_elevation', 'offshore_elevation_source', 'grid_distance_m', 'sp_lat', 'sp_lon'};
all_fields = [{'tc_bias_corrected'}, bnu_fields, {'Nyrs_XC', 'Nstm_XC', 'source_file', 'build_date'}];
switch action
    case 'create'
        [bnu, tc_bias_corrected, Nyrs_XC, Nstm_XC, source_file] = varargin{:};
        out = struct('tc_bias_corrected', double(tc_bias_corrected));
        for ff = [bnu_fields, loc_fields]
            out.(ff{1}) = bnu.(ff{1});
        end
        out.Nyrs_XC = Nyrs_XC;
        out.Nstm_XC = Nstm_XC;
        out.source_file = char(source_file);
        out.build_date = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    case 'apply'
        [db_info, out] = varargin{:};
        for ff = [{'tc_bias_corrected'}, bnu_fields]
            out.(ff{1}) = db_info.(ff{1});
        end
        for ff = {'Nyrs_XC', 'Nstm_XC'}
            if ~isempty(db_info.(ff{1}))
                out.(ff{1}) = db_info.(ff{1});
            end
        end
        out.storm_db_build_date = db_info.build_date;
        if isfield(db_info, 'offshore_elevation') && ~isempty(db_info.offshore_elevation)
            out.offshore_elevation = db_info.offshore_elevation;
            out.offshore_elevation_source = 'Storm DB grid';
        else
            out.offshore_elevation_source = 'config';
        end
    case 'valid'
        out = isstruct(varargin{1}) && isscalar(varargin{1}) && all(isfield(varargin{1}, all_fields));
end
end

function bnu = storm_db_bias_uncertainty(chs_dependencies, region, sp_ID, sp_coords, prev_info, prompt)
% storm_db_bias_uncertainty  Storm database bias, uncertainty, offshore elevation.
%   bnu = storm_db_bias_uncertainty(chs_dependencies, region, sp_ID, sp_coords)
%   bnu = storm_db_bias_uncertainty(..., prev_info, prompt)
%
%   CHS modeling bias & uncertainty and offshore elevation of a storm
%   database, determined once when the database is built (stored in
%   db_info, storm_db_info). Shared by the library and the GUI storm
%   database wizard.
%   CHS_Dependencies files come from chs_dependency_files (read when the
%   folder exists and the region is supported).
%   Study grid row (savepoint_grid_row, shared with the TC probability
%   masses): one lookup gives the grid row and the offshore elevation
%   (value column of that row). The savepoint ID is matched when the
%   match is unique (CHS-LA: savepoint -> ADCIRC node through the
%   savepoint node map file), else the grid point nearest to the
%   savepoint coordinates is used (CHS-NA: nearest only, the grid holds
%   mesh nodes). Printed: a grid point more than 0.5 m from the
%   coordinates, an ID matched without coordinates. Lookup errors
%   (savepoint_grid_row:gridNotFound | noCoordinates | spNotFound) are
%   raised there.
%   Offshore elevation: the grid stores depth, positive down (study
%   datum); it is negated to an elevation, positive up. None for grids
%   without a value column (CHS-TX, CHS-PR), NaN or fill values
%   (<= -99999, e.g. CHS-GLH -999999).
%   SWL values come from the water level bias & uncertainty file (Comb:
%   PBL + ADCIRC, else WL: ADCIRC only) at the grid row; a row beyond
%   that file is an error (storm_db_bias_uncertainty:spNotFound, naming
%   the row and both files). Hm0 values come from the wave height bias &
%   uncertainty file (STWAVE/SWAN): global values, the regional average
%   (_avg) when given per savepoint. Values not available there (no
%   CHS_Dependencies for the region, no file) are entered once in the
%   command window (source 'manual'); a database being rebuilt keeps its
%   earlier 'manual'/'provided' values instead (prev_info). Hm0 bias is
%   stored only when the wave file has it (not prompted, not applied).
%
%   Inputs:
%     chs_dependencies - CHS_Dependencies folder (config.chs_dependencies),
%                        char
%     region           - CHS region (config.region), char
%     sp_ID            - CHS ADCIRC savepoint ID (config.sp_ID), scalar
%                        double
%     sp_coords        - savepoint [latitude longitude] [deg] ([] or NaN:
%                        not available), 1x2 double
%     prev_info        - db_info of the database being rebuilt (optional,
%                        default []: none), struct
%     prompt           - false: never prompts, values not available stay
%                        empty with an empty source (GUI wizard)
%                        (optional, default true), logical
%   Outputs:
%     bnu - bias & uncertainty and savepoint location, struct; fields:
%             chs_swl_b_a, chs_swl_b_r - SWL bias, absolute [m] /
%                 relative [-], double
%             chs_swl_u_a, chs_swl_u_r - SWL uncertainty, absolute [m] /
%                 relative [-], double
%             chs_hm0_b_a, chs_hm0_b_r - Hm0 bias, absolute [m] /
%                 relative [-] ([] when the wave file has none), double
%             chs_hm0_u_a, chs_hm0_u_r - Hm0 uncertainty, absolute [m] /
%                 relative [-], double
%             chs_swl_bu_source, chs_hm0_bu_source - 'chs_dependencies',
%                 'manual', prev_info's 'manual'/'provided', or '' when
%                 not prompted, char
%             offshore_elevation - minus the grid depth [m, study datum,
%                 positive up] ([] when none), double
%             offshore_elevation_source - 'chs_dependencies' or '', char
%             grid_distance_m - distance from the savepoint coordinates
%                 to the grid point [m] ([] without coordinates or grid),
%                 double
%             sp_lat, sp_lon - savepoint coordinates [deg] ([] when not
%                 available), double
%
%   Tier: internal
%
%   See also storm_db_info, savepoint_grid_row, chs_dependency_files,
%   build_storm_database.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin < 5
    prev_info = [];
end
if nargin < 6
    prompt = true;
end
bnu = struct('chs_swl_b_a', [], 'chs_swl_b_r', [], 'chs_swl_u_a', [], 'chs_swl_u_r', [], 'chs_swl_bu_source', '',...
    'chs_hm0_b_a', [], 'chs_hm0_b_r', [], 'chs_hm0_u_a', [], 'chs_hm0_u_r', [], 'chs_hm0_bu_source', '',...
    'offshore_elevation', [], 'offshore_elevation_source', '', 'grid_distance_m', [], 'sp_lat', [], 'sp_lon', []);
if numel(sp_coords) == 2 && all(isfinite(sp_coords))
    bnu.sp_lat = sp_coords(1);
    bnu.sp_lon = sp_coords(2);
else
    sp_coords = [];
end

%% CHS_DEPENDENCIES STUDY GRID, BIAS & UNCERTAINTY FILES
files = chs_dependency_files(chs_dependencies, region);
if files.folder_exists && files.region_supported
    % Study Grid Row (savepoint_grid_row.m) And Offshore Elevation (Grid Depth, Positive Down, Negated)
    loc = savepoint_grid_row(files, sp_ID, sp_coords);
    grid_row = loc.row;
    bnu.grid_distance_m = loc.distance_m;
    report_grid_point(loc, sp_ID, region);
    if ~isempty(loc.value) && ~isnan(loc.value) && loc.value > -99999
        bnu.offshore_elevation = -loc.value;
        bnu.offshore_elevation_source = 'chs_dependencies';
    end
    % SWL: Study Grid Row
    if files.exists.water_level_bias_uncertainty_file
        circ_file = files.water_level_bias_uncertainty_file;
        [~, circ_name, circ_ext] = fileparts(circ_file);
        circ_name = [circ_name circ_ext];
        if any(strcmp(who('-file', circ_file), 'Comb'))
            u_data = load(circ_file, 'Comb'); % PBL + ADCIRC
            u_data = u_data.Comb;
        else
            u_data = load(circ_file, 'WL'); % ADCIRC Only
            u_data = u_data.WL;
        end
        if grid_row > numel(u_data.U_a)
            error('storm_db_bias_uncertainty:spNotFound', 'Save point SP%d (row %d of the %s study grid file %s) not found in the %s bias/uncertainty file %s.',...
                sp_ID, grid_row, region, loc.grid_name, region, circ_name);
        end
        bnu.chs_swl_b_a = u_data.B_a(grid_row);
        bnu.chs_swl_b_r = u_data.B_r(grid_row);
        bnu.chs_swl_u_a = u_data.U_a(grid_row); % SWL absolute uncertainty
        bnu.chs_swl_u_r = u_data.U_r(grid_row); % SWL Proportional uncertainty
        bnu.chs_swl_bu_source = 'chs_dependencies';
    end
    % Hm0: Global Values (Region Average When Given Per Savepoint)
    if files.exists.wave_height_bias_uncertainty_file
        u_hm0 = load(files.wave_height_bias_uncertainty_file, 'Hm0');
        u_hm0 = u_hm0.Hm0;
        bnu.chs_hm0_u_a = global_value(u_hm0, 'U_a');
        bnu.chs_hm0_u_r = global_value(u_hm0, 'U_r');
        bnu.chs_hm0_b_a = global_value(u_hm0, 'B_a');
        bnu.chs_hm0_b_r = global_value(u_hm0, 'B_r');
        bnu.chs_hm0_bu_source = 'chs_dependencies';
    end
end

%% VALUES ENTERED FOR THE DATABASE BEING REBUILT
groups = {'chs_swl_', {'b_a','b_r','u_a','u_r'}; 'chs_hm0_', {'b_a','b_r','u_a','u_r'}};
if ~isempty(prev_info)
    for gg = 1:size(groups, 1)
        src = [groups{gg, 1} 'bu_source'];
        if isempty(bnu.(src)) && any(strcmp(prev_info.(src), {'manual', 'provided'}))
            for ff = groups{gg, 2}
                bnu.([groups{gg, 1} ff{1}]) = prev_info.([groups{gg, 1} ff{1}]);
            end
            bnu.(src) = prev_info.(src);
        end
    end
end

%% MANUAL ENTRY (ONCE, WHEN THE STORM DATABASE IS BUILT)
if ~prompt
    return
end
if isempty(bnu.chs_swl_bu_source) || isempty(bnu.chs_hm0_bu_source)
    disp('Storm database: bias/uncertainty values not available from CHS_Dependencies. Please provide values manually:');
end
if isempty(bnu.chs_swl_bu_source)
    bnu.chs_swl_b_a = input('  SWL Absolute Bias [m]:         ');
    bnu.chs_swl_b_r = input('  SWL Relative Bias [-]:         ');
    bnu.chs_swl_u_a = input('  SWL Absolute Uncertainty [m]:  ');
    bnu.chs_swl_u_r = input('  SWL Relative Uncertainty [-]:  ');
    bnu.chs_swl_bu_source = 'manual';
end
if isempty(bnu.chs_hm0_bu_source)
    bnu.chs_hm0_u_a = input('  Hm0 Absolute Uncertainty [m]:  ');
    bnu.chs_hm0_u_r = input('  Hm0 Relative Uncertainty [-]:  ');
    bnu.chs_hm0_bu_source = 'manual';
end
end

%% AUX FUNCTION: PRINT A GRID POINT FAR FROM THE SAVEPOINT COORDINATES, OR AN ID MATCHED WITHOUT COORDINATES
function report_grid_point(loc, sp_ID, region)
if isempty(loc.distance_m)
    fprintf('Warning: Savepoint coordinates not found. Savepoint ID SP%d matched in the %s study grid instead.\n', sp_ID, region);
elseif loc.distance_m > 0.5
    switch loc.method
        case 'nearest'
            fprintf('Warning: Nearest grid point found was %.1f m away. This is caused by using SP data.\n', loc.distance_m);
        case 'id'
            fprintf('Warning: Savepoint SP%d grid point (ID match) is %.1f m from the savepoint coordinates.\n', sp_ID, loc.distance_m);
    end
end
end

%% AUX FUNCTION: GLOBAL WAVE VALUE (Average Field When Values Are Given Per Savepoint; [] If Absent)
function val = global_value(u_hm0, fld)
val = [];
if ~isfield(u_hm0, fld)
    return
end
val = u_hm0.(fld);
if ~isscalar(val)
    if isfield(u_hm0, [fld '_avg'])
        val = u_hm0.([fld '_avg']);
    else
        val = [];
    end
end
end

function bnu = storm_db_bias_uncertainty(chs_dependencies, region, sp_ID, sp_coords, prev_info, prompt)
%{
    %% DESCRIPTION
        CHS modeling bias & uncertainty and offshore elevation of a storm
        database, determined once when the database is built (stored in
        db_info, storm_db_info.m). Shared by the library and the GUI storm
        database wizard.
        Study grid (CHS_Dependencies Grid_Files/<region>: *nodeID* file if
        present, else *staID*): one lookup gives the grid row and the
        offshore elevation (value column of that row). The row is the grid
        point nearest to the savepoint coordinates (great-circle distance,
        no threshold; a distance above 0.5 m is printed: the CHS-NA grid
        holds mesh nodes while the data are at savepoints). Without
        coordinates (e.g. storm + prob_mass .mat input) the savepoint ID is
        matched instead (CHS-LA: savepoint -> ADCIRC node through the
        *ADCIRC_SPs* file), with a printed warning; an ID missing from the
        grid is then an error when the SWL values need the row
        (storm_db_bias_uncertainty:spNotFound, naming the file searched).
        A missing or empty Grid_Files/<region> folder is an error
        (storm_db_bias_uncertainty:gridNotFound).
        Offshore elevation: the grid stores depth, positive down (study
        datum); it is negated to an elevation, positive up. None for grids
        without a value column (CHS-TX, CHS-PR), NaN or fill values
        (<= -99999, e.g. CHS-GLH -999999).
        SWL values come from the Bias_and_Uncertainty circulation file
        (Comb: PBL + ADCIRC, else WL: ADCIRC only) at the grid row; a row
        beyond that file is an error (storm_db_bias_uncertainty:spNotFound,
        naming the row and both files). Hm0 values come from the wave file
        (STWAVE/SWAN): global values, the regional average (_avg) when
        given per savepoint. Values not available there (no
        CHS_Dependencies for the region, no file) are entered once in the
        command window (source 'manual'); a database being rebuilt keeps
        its earlier 'manual'/'provided' values instead (prev_info). Hm0 bias
        is stored only when the wave file has it (not prompted, not
        applied).

    %% INPUTS
        chs_dependencies: CHS_Dependencies folder (config.chs_dependencies). | char
        region: CHS region (config.region). | char
        sp_ID: CHS ADCIRC savepoint ID (config.sp_ID). | double
        sp_coords: Savepoint [latitude longitude] in degrees ([] or NaN: | double | 1 x 2
                   not available, the savepoint ID is matched instead).
        prev_info: Optional. db_info of the database being rebuilt ([]: none). | struct
        prompt: Optional (default true). false: never prompts; values not | logical
                available stay empty with an empty source (GUI wizard).

    %% OUTPUTS
        bnu: chs_swl_b_a, chs_swl_b_r, chs_swl_u_a, chs_swl_u_r, | struct
             chs_swl_bu_source, chs_hm0_b_a, chs_hm0_b_r, chs_hm0_u_a,
             chs_hm0_u_r, chs_hm0_bu_source ('chs_dependencies' | 'manual'
             | prev_info's 'manual'/'provided' | '' when not prompted),
             offshore_elevation (minus the grid depth, positive up; [] when none),
             offshore_elevation_source ('chs_dependencies' | ''),
             grid_distance_m (distance to the nearest grid point [m]; []
             when the ID was matched or no grid was read), sp_lat, sp_lon
             (savepoint coordinates; [] when not available).

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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
if chs_dependencies_available(chs_dependencies, region)
    w_state = warning('off');
    w_cleanup = onCleanup(@() warning(w_state));
    % Study Grid Row (Nearest Point, Else Savepoint ID) And Offshore Elevation
    [grid_row, grid_name, bnu.offshore_elevation, bnu.grid_distance_m] = savepoint_row(chs_dependencies, region, sp_ID, sp_coords);
    if ~isempty(bnu.offshore_elevation)
        bnu.offshore_elevation_source = 'chs_dependencies';
    end
    bnu_dir = dir(fullfile(chs_dependencies, 'Bias_and_Uncertainty', region, '*.mat'));
    circ_file = bnu_dir(contains({bnu_dir.name}, {'Comb','WL'}));
    wave_file = bnu_dir(contains({bnu_dir.name}, {'STWAVE','SWAN'}));
    % SWL: Study Grid Row
    if ~isempty(circ_file)
        if ~isscalar(grid_row)
            error('storm_db_bias_uncertainty:spNotFound', 'Save point SP%d not found in the %s study grid file %s.',...
                sp_ID, region, grid_name);
        end
        circ_name = circ_file(1).name;
        circ_file = fullfile(circ_file(1).folder, circ_name);
        if any(strcmp(who('-file', circ_file), 'Comb'))
            u_data = load(circ_file, 'Comb'); % PBL + ADCIRC
            u_data = u_data.Comb;
        else
            u_data = load(circ_file, 'WL'); % ADCIRC Only
            u_data = u_data.WL;
        end
        if grid_row > numel(u_data.U_a)
            error('storm_db_bias_uncertainty:spNotFound', 'Save point SP%d (row %d of the %s study grid file %s) not found in the %s bias/uncertainty file %s.',...
                sp_ID, grid_row, region, grid_name, region, circ_name);
        end
        bnu.chs_swl_b_a = u_data.B_a(grid_row);
        bnu.chs_swl_b_r = u_data.B_r(grid_row);
        bnu.chs_swl_u_a = u_data.U_a(grid_row); % SWL absolute uncertainty
        bnu.chs_swl_u_r = u_data.U_r(grid_row); % SWL Proportional uncertainty
        bnu.chs_swl_bu_source = 'chs_dependencies';
    end
    % Hm0: Global Values (Region Average When Given Per Savepoint)
    if ~isempty(wave_file)
        u_hm0 = load(fullfile(wave_file(1).folder, wave_file(1).name), 'Hm0');
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

%% AUX FUNCTION: STUDY GRID ROW OF THE SAVEPOINT AND ITS OFFSHORE ELEVATION
% Grid Columns: [ID Node Lat Lon Value] (5), [ID Lat Lon Value] (4) Or [ID Lat Lon] (3, No Value); Longitudes In -180..180.
% grid_row: Row Of The Grid Point Nearest To sp_coords, Else Of The Savepoint ID ([] If Not Found).
% grid_name: Study Grid File Where The Lookup Ended. elevation: Minus The Depth Of grid_row ([] If None).
% distance_m: Distance To The Nearest Grid Point ([] When The ID Was Matched).
function [grid_row, grid_name, elevation, distance_m] = savepoint_row(chs_dependencies, region, sp_ID, sp_coords)
grid_folder = fullfile(chs_dependencies, 'Grid_Files', region);
grid_dir = dir(fullfile(grid_folder, '*.mat'));
if isempty(grid_dir)
    error('storm_db_bias_uncertainty:gridNotFound', 'No %s study grid files (.mat) found in %s.', region, grid_folder);
end
grid_row = [];
elevation = [];
distance_m = [];
if any(contains({grid_dir.name}, 'nodeID'))
    grid_name = grid_file(grid_dir, 'nodeID', region, grid_folder);
    grid_data = load(fullfile(grid_folder, grid_name), 'nodeID'); grid_data = grid_data.nodeID;
else
    grid_name = grid_file(grid_dir, 'staID', region, grid_folder);
    grid_data = load(fullfile(grid_folder, grid_name), 'staID'); grid_data = grid_data.staID;
end
lat_col = 2 + (size(grid_data, 2) == 5);
if ~isempty(sp_coords)
    [distance_m, grid_row] = min(haversine_m(sp_coords(1), sp_coords(2), grid_data(:, lat_col), grid_data(:, lat_col + 1)));
    if distance_m > 0.5
        fprintf('Warning: Nearest grid point found was %.1f m away. This is caused by using SP data.\n', distance_m);
    end
else
    fprintf('Warning: Savepoint coordinates not found. Savepoint ID SP%d matched in the %s study grid instead.\n', sp_ID, region);
    if strcmp(region, 'CHS-LA') % Statistics Use Nodal Indexing: Savepoint -> ADCIRC Node
        sp_name = grid_file(grid_dir, 'SPs', region, grid_folder);
        load(fullfile(grid_folder, sp_name), 'SPs');  % SPs
        adcirc_node_id = SPs(SPs(:,1) == sp_ID, 2);
        if isscalar(adcirc_node_id)
            grid_row = find(grid_data(:,2) == adcirc_node_id);
        else
            grid_name = sp_name;
        end
    else
        grid_row = find(grid_data(:,1) == sp_ID);
    end
end
% Grid Stores Depth, Positive Down (Study Datum); Negated To An Elevation, Positive Up
if isscalar(grid_row) && size(grid_data, 2) >= lat_col + 2
    value = grid_data(grid_row, lat_col + 2);
    if ~isnan(value) && value > -99999
        elevation = -value;
    end
end
end

%% AUX FUNCTION: GREAT-CIRCLE (HAVERSINE) DISTANCE [m] BETWEEN POINTS GIVEN IN DEGREES
function d = haversine_m(lat1, lon1, lat2, lon2)
r_earth = 6371008.8; % Mean Earth Radius [m]
a = sind((lat2 - lat1)/2).^2 + cosd(lat1).*cosd(lat2).*sind((lon2 - lon1)/2).^2;
d = 2*r_earth*asin(min(1, sqrt(a)));
end

%% AUX FUNCTION: STUDY GRID FILE HOLDING key IN ITS NAME
function name = grid_file(grid_dir, key, region, grid_folder)
hit = find(contains({grid_dir.name}, key), 1);
if isempty(hit)
    error('storm_db_bias_uncertainty:gridNotFound', 'No %s study grid file (*%s*.mat) found in %s.', region, key, grid_folder);
end
name = grid_dir(hit).name;
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

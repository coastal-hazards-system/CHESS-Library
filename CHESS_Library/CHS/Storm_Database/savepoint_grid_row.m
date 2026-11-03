function loc = savepoint_grid_row(files, sp_ID, sp_coords)
% savepoint_grid_row  Study grid row of a CHS savepoint (ID match, else nearest).
%   loc = savepoint_grid_row(files, sp_ID, sp_coords)
%
%   Study grid row of a savepoint: the one lookup shared by the TC
%   probability masses (chs_probability_mass_loader) and the storm
%   database bias & uncertainty / offshore elevation
%   (storm_db_bias_uncertainty). Prints nothing.
%   Study grid (chs_dependency_files): [ID Node Lat Lon Value] (5
%   columns), [ID Lat Lon Value] (4) or [ID Lat Lon] (3, no value).
%   Resolution:
%     - staID grids: savepoint ID in column 1; CHS-LA (study grid rows
%       are ADCIRC nodes): savepoint -> ADCIRC node through the savepoint
%       node map file, node in column 2. The ID match is used when it is
%       unique; otherwise (ID missing or repeated, e.g. the CHS-TX grid)
%       the grid point nearest to sp_coords.
%     - nodeID grids (CHS-NA: mesh nodes, no savepoint IDs): the grid
%       point nearest to sp_coords only.
%   Nearest: great-circle distance (haversine_km), ties to the first row.
%   Errors: no study grid file, or no CHS-LA savepoint node map when the
%   ID is needed (savepoint_grid_row:gridNotFound, naming the folder);
%   nodeID grid without coordinates (savepoint_grid_row:noCoordinates);
%   no unique ID match and no coordinates (savepoint_grid_row:spNotFound,
%   naming the file searched).
%
%   Inputs:
%     files     - chs_dependency_files output of the region, struct
%     sp_ID     - CHS ADCIRC savepoint ID, scalar double
%     sp_coords - savepoint [latitude longitude] [deg] ([] or NaN: not
%                 available), 1x2 double
%   Outputs:
%     loc - study grid point, struct; fields:
%             row        - study grid row, double
%             lat, lon   - grid point coordinates [deg], double
%             value      - grid value column of the row (depth [m,
%                          study datum, positive down]; [] for grids
%                          without a value column), double
%             method     - 'id' (savepoint ID matched) or 'nearest', char
%             distance_m - distance from sp_coords to the grid point [m]
%                          ([] without coordinates), double
%             grid_name  - study grid file name (with extension), char
%
%   Tier: internal
%
%   See also chs_dependency_files, haversine_km, storm_db_bias_uncertainty,
%   chs_probability_mass_loader.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
region = files.region;
if ~files.study_grid_available
    error('savepoint_grid_row:gridNotFound', 'No %s study grid file (%s_nodeID*.mat or %s_staID*.mat) found in %s.',...
        region, region, region, files.folders.study_grid);
end
has_coords = numel(sp_coords) == 2 && all(isfinite(sp_coords));
grid_name = file_name(files.study_grid_file);
grid_data = load(files.study_grid_file, files.study_grid_variable); grid_data = grid_data.(files.study_grid_variable);
lat_col = 2 + (size(grid_data, 2) == 5);
grid_holds_mesh_nodes_only = strcmp(files.study_grid_variable, 'nodeID');

%% SAVEPOINT ID MATCH (staID Grids, CHS-LA Through The Savepoint Node Map)
id_rows = [];
searched_name = grid_name;
if grid_holds_mesh_nodes_only
    if ~has_coords
        error('savepoint_grid_row:noCoordinates', ['The %s study grid file %s holds mesh nodes, not savepoint IDs: ',...
            'the savepoint SP%d latitude/longitude are needed to find its grid point.'], region, grid_name, sp_ID);
    end
elseif files.uses_savepoint_node_map
    if files.exists.savepoint_node_map_file
        node_map = load(files.savepoint_node_map_file, 'SPs'); node_map = node_map.SPs; % [SP_ID Node Lon Lat Depth]
        adcirc_node_id = node_map(node_map(:,1) == sp_ID, 2);
        if isscalar(adcirc_node_id)
            id_rows = find(grid_data(:,2) == adcirc_node_id);
        else
            searched_name = file_name(files.savepoint_node_map_file);
        end
    elseif ~has_coords
        error('savepoint_grid_row:gridNotFound', 'No %s savepoint node map file (%s_ADCIRC_SPs.mat) found in %s.',...
            region, region, files.folders.study_grid);
    end
else
    id_rows = find(grid_data(:,1) == sp_ID);
end

%% ROW: UNIQUE ID MATCH, ELSE NEAREST GRID POINT
if isscalar(id_rows)
    row = id_rows;
    method = 'id';
elseif has_coords
    [~, row] = min(haversine_km(sp_coords(1), sp_coords(2), grid_data(:, lat_col), grid_data(:, lat_col + 1)));
    method = 'nearest';
else
    error('savepoint_grid_row:spNotFound', 'Save point SP%d not found (or not unique) in the %s study grid file %s.',...
        sp_ID, region, searched_name);
end
loc.row = row;
loc.lat = grid_data(row, lat_col);
loc.lon = grid_data(row, lat_col + 1);
loc.value = [];
if size(grid_data, 2) >= lat_col + 2
    loc.value = grid_data(row, lat_col + 2);
end
loc.method = method;
loc.distance_m = [];
if has_coords
    loc.distance_m = 1000*haversine_km(sp_coords(1), sp_coords(2), loc.lat, loc.lon);
end
loc.grid_name = grid_name;
end

%% AUX FUNCTION: FILE NAME (WITH EXTENSION) OF A FULL PATH
function name = file_name(file)
[~, name, ext] = fileparts(file);
name = [name ext];
end

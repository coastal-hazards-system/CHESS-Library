function [selected, selected_rows] = select_noaa_stations(catalog, selection)
%{
    %% DESCRIPTION
        Selects stations of a NOAA station catalog (noaa_station_catalog.m).
        Every filter given in selection is applied (logical AND); an empty
        selection keeps every station. Ids and states are matched exactly
        (ismember); polygons use inpolygon on (lon, lat).

    %% INPUTS
        catalog: Station catalog (noaa_station_catalog.m). | table
        selection: (Optional) Struct with any of the fields | struct
            ids: Station ids. | cell/string
            states: State codes (e.g. {'NY', 'NJ'}). | cell/string
            polygon_csv: CSV file with the polygon vertices, longitude in
                column 1 and latitude in column 2. | char
            polygon_lon, polygon_lat: Polygon vertices [deg]. | double
            active_only: Keep active stations only. | logical

    %% OUTPUTS
        selected: Catalog rows selected. | table
        selected_rows: Selected rows of the catalog. | logical

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin < 2 || isempty(selection)
    selection = struct();
end
selected_rows = true(height(catalog), 1);
if isfield(selection, 'ids') && ~isempty(selection.ids)
    selected_rows = selected_rows & ismember(catalog.id, string(selection.ids));
end
if isfield(selection, 'states') && ~isempty(selection.states)
    selected_rows = selected_rows & ismember(catalog.state, string(selection.states));
end
if isfield(selection, 'polygon_csv') && ~isempty(selection.polygon_csv)
    polygon_vertices = readmatrix(selection.polygon_csv);
    selected_rows = selected_rows & inpolygon(catalog.lon, catalog.lat,...
        polygon_vertices(:, 1), polygon_vertices(:, 2));
end
if isfield(selection, 'polygon_lon') && isfield(selection, 'polygon_lat') && ~isempty(selection.polygon_lon)
    selected_rows = selected_rows & inpolygon(catalog.lon, catalog.lat,...
        selection.polygon_lon(:), selection.polygon_lat(:));
end
if isfield(selection, 'active_only') && isequal(logical(selection.active_only), true)
    selected_rows = selected_rows & catalog.active;
end
selected = catalog(selected_rows, :);
end

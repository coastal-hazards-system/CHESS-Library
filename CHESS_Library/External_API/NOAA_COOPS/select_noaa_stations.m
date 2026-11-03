function [selected, selected_rows] = select_noaa_stations(catalog, selection)
% select_noaa_stations  Select stations of a NOAA station catalog.
%   [selected, selected_rows] = select_noaa_stations(catalog)
%   [selected, selected_rows] = select_noaa_stations(catalog, selection)
%
%   Selects stations of a NOAA station catalog (noaa_station_catalog).
%   Every filter given in selection is applied (logical AND); an empty
%   selection keeps every station. Ids and states are matched exactly
%   (ismember); polygons use inpolygon on (lon, lat).
%
%   Inputs:
%     catalog   - station catalog (noaa_station_catalog), table
%     selection - struct (optional; [] = default); fields (all optional):
%                   .ids - station ids, cell or string
%                   .states - state codes (e.g. {'NY', 'NJ'}), cell or
%                       string
%                   .polygon_csv - file with the polygon vertices
%                       (readmatrix), longitude in column 1 and latitude in
%                       column 2 [deg], char
%                   .polygon_lon, .polygon_lat - polygon vertices [deg]
%                       (both needed), double
%                   .active_only - keep active stations only, logical,
%                       default false
%   Outputs:
%     selected      - catalog rows selected, table
%     selected_rows - selected rows of the catalog, logical column
%
%   Tier: public
%
%   See also create_tide_file, download_noaa_tide_predictions,
%   download_noaa_water_levels, noaa_station_catalog,
%   noaa_station_details, plot_noaa_stations.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
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

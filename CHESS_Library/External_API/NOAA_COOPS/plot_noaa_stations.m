function map_axes = plot_noaa_stations(catalog, polygon, parent)
%{
    %% DESCRIPTION
        Map of NOAA CO-OPS stations (noaa_station_catalog.m or
        select_noaa_stations.m rows) on geographic axes: active water level
        stations, historical water level stations and predictions-only
        harmonic stations in separate colors, plus the selection polygon
        when one is given.

    %% INPUTS
        catalog: Station catalog rows to plot. | table
        polygon: (Optional) Selection polygon: struct with fields lon and
            lat [deg], or an N x 2 matrix [lon lat]; [] for none. | struct/double
        parent: (Optional) Parent figure or panel (default a new
            figure). | handle

    %% OUTPUTS
        map_axes: Geographic axes. | geoaxes

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin < 3 || isempty(parent)
    parent = figure();
end
map_axes = geoaxes(parent, 'Basemap', 'satellite');
hold(map_axes, 'on');

station_groups = {catalog.has_water_levels & catalog.active, 'Active water levels', [0 0.8 0];...
    catalog.has_water_levels & ~catalog.active, 'Historical water levels', [1 0.6 0];...
    ~catalog.has_water_levels & catalog.harmonic_predictions, 'Harmonic predictions only', [0 0.7 1]};
for group_index = 1:size(station_groups, 1)
    in_group = station_groups{group_index, 1};
    if any(in_group)
        geoscatter(map_axes, catalog.lat(in_group), catalog.lon(in_group), 20,...
            station_groups{group_index, 3}, 'filled', 'DisplayName', station_groups{group_index, 2});
    end
end

if nargin >= 2 && ~isempty(polygon)
    if isstruct(polygon)
        polygon_lon = polygon.lon(:);
        polygon_lat = polygon.lat(:);
    else
        polygon_lon = polygon(:, 1);
        polygon_lat = polygon(:, 2);
    end
    geoplot(map_axes, [polygon_lat; polygon_lat(1)], [polygon_lon; polygon_lon(1)], '-r',...
        'LineWidth', 2, 'DisplayName', 'Selection polygon');
end
legend(map_axes, 'Location', 'best');
hold(map_axes, 'off');
end

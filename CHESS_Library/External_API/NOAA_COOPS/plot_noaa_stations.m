function map_axes = plot_noaa_stations(catalog, polygon, parent)
% plot_noaa_stations  Map NOAA CO-OPS stations on geographic axes.
%   map_axes = plot_noaa_stations(catalog)
%   map_axes = plot_noaa_stations(catalog, polygon, parent)
%
%   Map of NOAA CO-OPS stations (noaa_station_catalog or
%   select_noaa_stations rows) on geographic axes (satellite basemap):
%   active water level stations, historical water level stations and
%   predictions-only harmonic stations in separate colors, plus the
%   selection polygon when one is given.
%
%   Inputs:
%     catalog - station catalog rows to plot (noaa_station_catalog
%               layout), table
%     polygon - selection polygon (optional, default none; [] = none):
%               struct with fields lon and lat [deg], or an N x 2 matrix
%               [lon lat] [deg], struct or double
%     parent  - parent figure or panel (optional, default a new figure;
%               [] = default), graphics handle
%   Outputs:
%     map_axes - geographic axes, geoaxes
%
%   Tier: public
%
%   See also create_tide_file, download_noaa_tide_predictions,
%   download_noaa_water_levels, noaa_station_catalog,
%   noaa_station_details, select_noaa_stations.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
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

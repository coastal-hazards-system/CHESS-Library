function d_km = haversine_km(lat1, lon1, lat2, lon2)
% haversine_km  Great-circle distance between points given in degrees.
%   d_km = haversine_km(lat1, lon1, lat2, lon2) returns the great-circle
%   (haversine) distance between the first point and each point of the
%   second input, using a mean Earth radius of 6371 km. The second point may
%   be a vector (one distance per point).
%
%   Inputs:
%     lat1, lon1 - latitude and longitude of the first point [deg], scalar
%                  double
%     lat2, lon2 - latitude and longitude of the second point(s) [deg],
%                  [N x 1] double
%   Outputs:
%     d_km - distance from the first point to each second point [km],
%            [N x 1] double
%
%   Tier: internal
%
%   See also savepoint_grid_row.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

lat1 = deg2rad(lat1);
lon1 = deg2rad(lon1);
lat2 = deg2rad(lat2);
lon2 = deg2rad(lon2);
dlat = lat2 - lat1;
dlon = lon2 - lon1;
a = sin(dlat/2).^2 + cos(lat1) * cos(lat2) .* sin(dlon/2).^2;
d_km = 6371 * (2 * atan2(sqrt(a), sqrt(1-a)));
end

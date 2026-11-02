function d_km = haversine_km(lat1, lon1, lat2, lon2)
%{
    %% DESCRIPTION
        Great-circle (haversine) distance between points given in degrees,
        mean Earth radius 6371 km. The second point may be a vector (one
        distance per point).

    %% INPUTS
        lat1, lon1: First point latitude and longitude [deg]. | double | 1 x 1
        lat2, lon2: Second point(s) latitude and longitude [deg]. | double | N x 1

    %% OUTPUTS
        d_km: Distance [km]. | double | N x 1

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
lat1 = deg2rad(lat1);
lon1 = deg2rad(lon1);
lat2 = deg2rad(lat2);
lon2 = deg2rad(lon2);
dlat = lat2 - lat1;
dlon = lon2 - lon1;
a = sin(dlat/2).^2 + cos(lat1) * cos(lat2) .* sin(dlon/2).^2;
d_km = 6371 * (2 * atan2(sqrt(a), sqrt(1-a)));
end

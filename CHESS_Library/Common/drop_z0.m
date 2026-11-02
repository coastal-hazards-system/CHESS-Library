function data = drop_z0(data)
%{
    %% DESCRIPTION
        Removes the z = 0 replicate column (replicate_z0_col.m) from PROS
        replicate data, leaving the replicates used by the statistics
        (hazard curve fits, JPM discretization, run sample overlays).
        Single-column data has no replicates and is returned unchanged.

    %% INPUTS
        data: [nRows x nReps] array, nReps odd (z = 0 in the middle). | double

    %% OUTPUTS
        data: [nRows x nReps-1] array (or the input when nReps == 1). | double

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
n_cols = size(data, 2);
if n_cols > 1
    data(:, replicate_z0_col(n_cols)) = [];
end
end

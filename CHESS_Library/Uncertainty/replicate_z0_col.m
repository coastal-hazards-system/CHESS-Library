function z0 = replicate_z0_col(n_cols)
%{
    %% DESCRIPTION
        Column of the z = 0 replicate in PROS forcing/response arrays. The
        discrete normal files (discrete_norm_20.txt, discrete_norm_444.txt)
        hold 21 and 445 sorted z-scores with z = 0 in the middle (columns 11
        and 223), so the z = 0 replicate is the middle column. Single-column
        data (CHESS: Deterministic, forcing hazard curve inputs) is its own
        z = 0 column. The only place that knows where z = 0 is: statistics
        consumers drop it through drop_z0.m, deterministic values read it here.

    %% INPUTS
        n_cols: Number of columns (replicates) of the data. | double

    %% OUTPUTS
        z0: Column index of the z = 0 replicate. | double

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if mod(n_cols, 2) ~= 1
    error('replicate_z0_col:evenReplicates', ['Data with %d replicate columns has no z = 0 replicate ',...
        '(expected an odd count, e.g. 21 XC / 445 TC). Re-run the case to rebuild its forcing.'], n_cols);
end
z0 = (n_cols + 1)/2;
end

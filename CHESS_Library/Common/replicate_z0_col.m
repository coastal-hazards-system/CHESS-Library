function z0 = replicate_z0_col(n_cols)
% replicate_z0_col  Column of the z = 0 replicate in PROS arrays.
%   z0 = replicate_z0_col(n_cols) returns the column of the z = 0 replicate
%   in PROS forcing/response arrays with n_cols columns.
%
%   The discrete normal z-scores (discrete_standard_normal_scores: XC, TC)
%   are 21 and 445 sorted z-scores with z = 0 in the middle (columns 11 and
%   223), so the z = 0 replicate is the middle column. Single-column data
%   (CHESS: Deterministic, forcing hazard curve inputs) is its own z = 0
%   column. The only place that knows where z = 0 is: statistics consumers
%   drop it through drop_z0, deterministic values read it here. An even
%   number of columns raises replicate_z0_col:evenReplicates.
%
%   Inputs:
%     n_cols - number of columns (replicates) of the data [-], scalar double,
%              odd
%   Outputs:
%     z0 - column index of the z = 0 replicate [-], scalar double
%
%   Tier: internal
%
%   See also drop_z0, discrete_standard_normal_scores.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if mod(n_cols, 2) ~= 1
    error('replicate_z0_col:evenReplicates', ['Data with %d replicate columns has no z = 0 replicate ',...
        '(expected an odd count, e.g. 21 XC / 445 TC). Re-run the case to rebuild its forcing.'], n_cols);
end
z0 = (n_cols + 1)/2;
end

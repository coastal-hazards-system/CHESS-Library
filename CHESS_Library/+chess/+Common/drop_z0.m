function data = drop_z0(data)
% chess.Common.drop_z0  Remove the z = 0 replicate column from PROS replicate data.
%   data = chess.Common.drop_z0(data) removes the z = 0 replicate column
%   (chess.Common.replicate_z0_col) from PROS replicate data, leaving the replicates used
%   by the statistics (hazard curve fits, JPM discretization, run sample
%   overlays). Single-column data has no replicates and is returned
%   unchanged.
%
%   Inputs:
%     data - replicate data, [nRows x nReps] double, nReps odd (z = 0 in the
%            middle)
%   Outputs:
%     data - data without the z = 0 column, [nRows x nReps-1] double (the
%            input itself when nReps == 1)
%
%   See also chess.Common.replicate_z0_col, chess.Common.discrete_standard_normal_scores.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

n_cols = size(data, 2);
if n_cols > 1
    data(:, chess.Common.replicate_z0_col(n_cols)) = [];
end
end

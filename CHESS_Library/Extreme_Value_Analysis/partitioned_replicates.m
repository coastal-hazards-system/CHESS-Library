function replicates = partitioned_replicates(value, z_scores)
% partitioned_replicates  Replicates carrying the first uncertainty partition (PCHA ITCS).
%   replicates = partitioned_replicates(value, z_scores)
%
%   The uncertainty of a TC forcing curve or JPM response is split in two:
%   the first partition is carried by replicates, the rest by the
%   confidence limits (uncertainty_after_partition). With p_a = 0.1
%   (units of the value) and p_r = 0.1 [-]:
%     replicates = value + z_scores.*(p_a + value.*p_r)/2
%   independent of the uncertainty of the value (z = 0 gives value).
%   Used by CHESS_JPM_integration (integration_method 2) and chess_pros
%   (TC forcing curves).
%
%   Inputs:
%     value    - forcing or response value, double array
%     z_scores - standard normal scores [-], double array (broadcast with
%                value, e.g. one column per replicate)
%   Outputs:
%     replicates - value with the first partition (units of value), size
%                  of value + z_scores
%
%   Tier: internal
%
%   See also uncertainty_after_partition, combined_uncertainty,
%   CHESS_JPM_integration, chess_pros.

p_a = 0.1;
p_r = 0.1;
replicates = value + z_scores.*(p_a + value.*p_r)/2;
end

function [U_a, U_r] = uncertainty_after_partition(U_a, U_r)
% uncertainty_after_partition  Uncertainty left for the confidence limits after the first uncertainty partition.
%   [U_a, U_r] = uncertainty_after_partition(U_a, U_r)
%
%   U_left = sqrt(U^2 - p^2) when U^2 >= p^2, else U unchanged, with
%   p = 0.1 (units of the value) for U_a and p = 0.1 [-] for U_r: the
%   partition carried by the replicates of partitioned_replicates. Used
%   by CHESS_JPM_integration (integration_method 2),
%   call_hazard_curve_builder (TC forcing curves) and
%   chess_pros_frequency_base (EB2 sampling of TC and CC forcing curves).
%
%   Inputs:
%     U_a - absolute uncertainty (units of the value), scalar double
%     U_r - relative uncertainty [-], scalar double
%   Outputs:
%     U_a - absolute uncertainty left (units of the value), scalar double
%     U_r - relative uncertainty left [-], scalar double
%
%   Tier: internal
%
%   See also partitioned_replicates, combined_uncertainty,
%   CHESS_JPM_integration, call_hazard_curve_builder,
%   chess_pros_frequency_base.

p_a = 0.1;
p_r = 0.1;
if U_a^2 >= p_a^2
    U_a = sqrt(U_a^2-p_a^2);
end
if U_r^2 >= p_r^2
    U_r = sqrt(U_r^2-p_r^2);
end
end

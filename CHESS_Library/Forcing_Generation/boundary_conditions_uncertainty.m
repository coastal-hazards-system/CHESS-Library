function data = boundary_conditions_uncertainty(config, data, st)
% boundary_conditions_uncertainty  Apply forcing uncertainty to one dataset.
%   data = boundary_conditions_uncertainty(config, data, st)
%
%   Step 2 of call_chess_boundary_conditions: forcing uncertainty of one
%   dataset (data type x match type x storm type), per workflow.
%     - PROS (RB/FB, workflows 1, 4): discrete standard normal z-scores
%       (discrete_standard_normal_scores: TC 445, XC 21) applied by
%       apply_uncertainty, one z-score per replicate column.
%     - LCS (workflow 3): none yet (placeholder hook, data returned
%       untouched).
%     - DET (workflow 2) and multi-line stage 2: none (stage 2 keeps stage
%       1's uncertainty).
%
%   Inputs:
%     config - CHESS configuration, 1x1 struct; reads workflow, multiline
%              (and the apply_uncertainty fields for PROS)
%     data   - one dataset of the project forcing (build_boundary_conditions):
%              PROS/DET struct, LCS cell
%     st     - storm type, 'XC', 'TC' or 'CC' (PROS: 'XC' or 'TC'), char
%   Outputs:
%     data - dataset with uncertainty applied, struct or cell
%
%   Tier: internal
%
%   See also call_chess_boundary_conditions, apply_uncertainty,
%   discrete_standard_normal_scores, boundary_conditions_adjust.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if isfield(config, 'multiline') && ~isempty(config.multiline)
    return
end
switch config.workflow
    case {1,4} % CHESS: PROS
        data = apply_uncertainty(config, data, discrete_standard_normal_scores(st)');
    case 3 % CHESS: LCS
        % No LCS Uncertainty Scheme Yet (Open Team Item): Hook For One, Life Cycles Returned Untouched
    case 2 % CHESS: Deterministic -> Forcing Used As Recorded
end
end

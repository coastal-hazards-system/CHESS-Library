function data = boundary_conditions_uncertainty(config, data, st)
%{
    %% DESCRIPTION
        Step 2 of call_chess_boundary_conditions.m: forcing uncertainty of
        one dataset (data type x match type x storm type), per workflow.
            - PROS (RB/FB, workflows 1, 4): pre-computed discrete normal
              z-scores (TC: discrete_norm_444.txt, XC: discrete_norm_20.txt)
              applied by Uncertainty/apply_uncertainty.m.
            - LCS (workflow 3): none yet (placeholder hook, data returned
              untouched).
            - DET (workflow 2) and multi-line stage 2: none (stage 2 keeps
              stage 1's uncertainty).

    %% INPUTS
        config: Run configuration. | struct
        data: One dataset of the project forcing (build_boundary_conditions.m). | struct/cell
        st: Storm type ('XC' | 'TC' | 'CC'). | char

    %% OUTPUTS
        data: Dataset with uncertainty applied. | struct/cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if isfield(config, 'multiline') && ~isempty(config.multiline)
    return
end
switch config.workflow
    case {1,4} % CHESS: PROS
        switch st
            case 'TC'
                RandNorm = readmatrix('discrete_norm_444.txt')'; % z-scores
            case 'XC'
                RandNorm = readmatrix('discrete_norm_20.txt')';
        end
        data = apply_uncertainty(config, data, RandNorm);
    case 3 % CHESS: LCS
        % No LCS Uncertainty Scheme Yet (Open Team Item): Hook For One, Life Cycles Returned Untouched
    case 2 % CHESS: Deterministic -> Forcing Used As Recorded
end
end

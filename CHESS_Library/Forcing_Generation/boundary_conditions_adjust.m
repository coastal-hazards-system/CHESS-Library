function [data, config] = boundary_conditions_adjust(config, structure, data, st)
%{
    %% DESCRIPTION
        Step 3 of call_chess_boundary_conditions.m: forcing adjustments of
        one dataset (data type x match type x storm type), per workflow.
            - PROS, DET, LCS: Forcing_Adjustments/adjust_project_forcing.m
              (random tides, SLR, depth limitation -> Hm0_toe). Tide start
              hours shared across datasets are drawn before the dataset
              loop (call_chess_boundary_conditions.m).
            - Multi-line stage 2: none (stage 1's tides and SLR are kept,
              depth limitation already applied at the stage 2 toe by
              apply_stage1_transmission.m).

    %% INPUTS
        config: Run configuration. | struct
        structure: CHESS structure geometry. | struct
        data: One dataset of the project forcing. | struct/cell
        st: Storm type ('XC' | 'TC' | 'CC'). | char

    %% OUTPUTS
        data: Adjusted dataset. | struct/cell
        config: Run configuration (tide start hours drawn by
            adjust_project_forcing.m). | struct

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if isfield(config, 'multiline') && ~isempty(config.multiline)
    return
end
switch config.workflow
    case {1,2,3,4} % CHESS: PROS, DET, LCS
        [data, config] = adjust_project_forcing(config, structure, data, st);
end
end

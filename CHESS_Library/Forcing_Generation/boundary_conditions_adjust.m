function [data, config] = boundary_conditions_adjust(config, structure, data, st)
% boundary_conditions_adjust  Apply the forcing adjustments to one dataset.
%   [data, config] = boundary_conditions_adjust(config, structure, data, st)
%
%   Step 3 of call_chess_boundary_conditions: forcing adjustments of one
%   dataset (data type x match type x storm type), per workflow.
%     - PROS, DET, LCS: adjust_project_forcing (random tides, SLR, depth
%       limitation -> Hm0_toe). Tide start hours shared across datasets are
%       drawn before the dataset loop (call_chess_boundary_conditions).
%     - Multi-line stage 2: none (stage 1's tides and SLR are kept, depth
%       limitation already applied at the stage 2 toe by
%       apply_stage1_transmission).
%
%   Inputs:
%     config    - CHESS configuration, 1x1 struct; reads multiline (and the
%                 adjust_project_forcing fields)
%     structure - CHESS structure geometry, 1x1 struct
%     data      - one dataset of the project forcing: PROS/DET struct, LCS
%                 cell
%     st        - storm type, 'XC', 'TC' or 'CC', char
%   Outputs:
%     data   - adjusted dataset, struct or cell
%     config - input config with tide_indx_<st> when random tide start
%              hours are drawn here (storm types without Timeseries),
%              struct
%
%   Tier: internal
%
%   See also call_chess_boundary_conditions, adjust_project_forcing,
%   boundary_conditions_uncertainty, draw_tide_indices.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if isfield(config, 'multiline') && ~isempty(config.multiline)
    return
end
[data, config] = adjust_project_forcing(config, structure, data, st);
end

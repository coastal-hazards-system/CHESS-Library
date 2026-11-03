function mode = lcs_sampling_mode(config)
% lcs_sampling_mode  Effective LCS sampling mode of a run.
%   mode = lcs_sampling_mode(config)
%
%   LCS sampling mode the life cycles were actually sampled with
%   (0 = Full Poisson, 1 = Rate Matched): lcs_effective_sampling_rate,
%   set by chess_lcs (it differs from the configured mode when the storms
%   are reused from a reference case sampled under the other mode), when
%   present and not empty; else the configured lcs_restrict_sampling_rate.
%
%   Inputs:
%     config - CHESS configuration, 1x1 struct
%   Outputs:
%     mode - effective sampling mode (0 or 1), double
%
%   Tier: internal
%
%   See also chess_lcs, lcs_reference_reuse.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if isfield(config, 'lcs_effective_sampling_rate') && ~isempty(config.lcs_effective_sampling_rate)
    mode = config.lcs_effective_sampling_rate;
else
    mode = config.lcs_restrict_sampling_rate;
end
end

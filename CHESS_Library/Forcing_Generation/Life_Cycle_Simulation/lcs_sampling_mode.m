function mode = lcs_sampling_mode(config)
%{
    %% DESCRIPTION
        LCS sampling mode the life cycles were actually sampled with
        (0 = Full Poisson, 1 = Rate Matched): config.lcs_effective_sampling_rate,
        set by chess_lcs (it differs from the configured mode when the storms
        are reused from a reference case sampled under the other mode), else the
        configured config.lcs_restrict_sampling_rate.

    %% INPUTS
        config: Run configuration. | struct

    %% OUTPUTS
        mode: Effective sampling mode (0 or 1). | double

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if isfield(config, 'lcs_effective_sampling_rate') && ~isempty(config.lcs_effective_sampling_rate)
    mode = config.lcs_effective_sampling_rate;
else
    mode = config.lcs_restrict_sampling_rate;
end
end

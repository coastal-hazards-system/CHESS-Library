function checks = lcs_convergence_checks(config, prob_mass, stm_types, quiet)
%{
    %% DESCRIPTION
        Runs lcs_convergence_check for each storm type to be sampled with full
        Poisson LCS sampling, using the run configuration. Shared by chess_lcs
        (before sampling) and the GUI (convergence dialog before an LCS run).
        Storm rates: XC -> config.Nstm_XC/config.Nyrs_XC, TC -> prob_mass.TC_SRR(end).
        Storm types with a rate <= 0 are skipped (chess_lcs stops on them).

    %% INPUTS
        config: Run configuration (mcs_nYears, mcs_nLC, lcs_convergence_tol,
            lcs_convergence_confidence, project_CLs, storm_sampling, Nstm_XC, Nyrs_XC). | struct
        prob_mass: CHS probability masses (TC_SRR); unused for XC. | struct or []
        stm_types: Optional storm types to check (default: from config.storm_sampling,
            'CC' -> {'XC','TC'}). | cell
        quiet: Optional, true -> no printed reports (default false). | logical

    %% OUTPUTS
        checks: One element per checked storm type: lcs_convergence_check outputs
            plus stm_type and rate [storms/yr]. Empty when nothing is checked. | struct

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin < 3 || isempty(stm_types)
    if strcmp(config.storm_sampling, 'CC')
        stm_types = {'XC','TC'};
    else
        stm_types = {config.storm_sampling};
    end
end
if nargin < 4
    quiet = false;
end
prc = cellfun(@str2double, strsplit(config.project_CLs(2:end-1), {' '}));
checks = struct([]);
for kk = 1:numel(stm_types)
    switch stm_types{kk}
        case 'XC'
            rate = config.Nstm_XC/config.Nyrs_XC;
        case 'TC'
            rate = prob_mass.TC_SRR(end);
    end
    if ~(rate > 0)
        continue
    end
    res = lcs_convergence_check(rate, config.mcs_nYears, config.mcs_nLC, config.lcs_convergence_tol,...
        config.lcs_convergence_confidence, prc, stm_types{kk}, quiet);
    res.stm_type = stm_types{kk};
    res.rate = rate;
    if isempty(checks)
        checks = res;
    else
        checks(end+1) = res; %#ok<AGROW>
    end
end
end

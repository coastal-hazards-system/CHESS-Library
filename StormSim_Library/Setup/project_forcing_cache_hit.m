function [hit, project_forcing, missing_desc] = project_forcing_cache_hit(config)
%PROJECT_FORCING_CACHE_HIT True if the cached project_forcing.mat will be reused as is.
%{
%% DESCRIPTION
The reuse rule of call_project_forcing_formater.m: the cached
config.out_files.project_forcing exists and covers the current request
(project_forcing_coverage.m). No side effects (a non-covering cache is
not deleted here). Hotstart resolution runs first and deletes the cache
when a dependency changed (apply_hotstart_level.m, used by the library's
resolve_hotstart_state.m and by the GUI), so call this after it, or
after the equivalent side-effect-free decision (hotstart_plan.m level
'full'). On a hit no project forcing is generated, e.g. no LCS sampling
and no convergence check.

%% INPUTS
config: Current run's parsed config struct (out_files.project_forcing
        plus the fields read by project_forcing_coverage.m).

%% OUTPUTS
hit: true if the cached project forcing exists and covers the request.
project_forcing: Loaded cached project forcing ([] if no file).
missing_desc: Missing items (project_forcing_coverage.m); '' on a hit
              or when there is no file.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
hit = false;
project_forcing = [];
missing_desc = '';
if exist(config.out_files.project_forcing, 'file') ~= 2
    return
end
S = load(config.out_files.project_forcing, 'project_forcing');
project_forcing = S.project_forcing;
[hit, missing_desc] = project_forcing_coverage(config, project_forcing);
end

function [hit, project_forcing, missing_desc] = project_forcing_cache_hit(config)
% project_forcing_cache_hit  True if the cached project forcing is reused as is.
%   [hit, project_forcing, missing_desc] = project_forcing_cache_hit(config)
%   loads the cached out_files.project_forcing and checks that it covers the
%   current request in the current layout.
%
%   The coverage rule of call_chess_boundary_conditions (step 0, which also
%   needs the forcing_stamp field): the cached project forcing file exists
%   and covers the current request (project_forcing_coverage) in the
%   current layout (every PROS/DET dataset carries storm_duration, LCS
%   Timeseries life cycles have lcs_columns().n_timeseries columns; an
%   older forcing is rebuilt, never converted). No side effects (a
%   non-covering cache is not deleted here). Hotstart resolution runs first
%   and deletes the cache when a dependency changed (apply_hotstart_level,
%   used by the library's resolve_hotstart_state and by the GUI), so call
%   this after it, or after the equivalent side-effect-free decision
%   (hotstart_plan level 'full'). On a hit no project forcing is generated,
%   e.g. no LCS sampling and no convergence check.
%
%   Inputs:
%     config - current run's parsed configuration, 1x1 struct; reads
%              out_files.project_forcing, workflow and the fields read by
%              project_forcing_coverage
%   Outputs:
%     hit             - true if the cached project forcing exists and covers
%                       the request in the current layout, logical
%     project_forcing - loaded cached project forcing ([] if no file),
%                       struct
%     missing_desc    - missing items (project_forcing_coverage, or
%                       'storm_duration (forcing layout)' for an older
%                       layout); '' on a hit or when there is no file, char
%
%   Tier: internal
%
%   See also project_forcing_coverage, call_chess_boundary_conditions,
%   apply_hotstart_level, hotstart_plan.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
hit = false;
project_forcing = [];
missing_desc = '';
if exist(config.out_files.project_forcing, 'file') ~= 2
    return
end
S = load(config.out_files.project_forcing, 'project_forcing');
project_forcing = S.project_forcing;
[hit, missing_desc] = project_forcing_coverage(config, project_forcing);
if hit && ~current_layout(config.workflow, project_forcing)
    hit = false;
    missing_desc = 'storm_duration (forcing layout)';
end
end

%% AUX FUNCTION: FORCING IN THE CURRENT LAYOUT (PROS/DET: storm_duration Per Dataset; LCS: Timeseries Column Count)
function ok = current_layout(workflow, project_forcing)
if workflow == 3
    ok = true;
    if isfield(project_forcing, 'Timeseries')
        lcs = struct2cell(project_forcing.Timeseries.Default);
        ok = all(cellfun(@(d) all(cellfun(@(x) size(x, 2) == lcs_columns().n_timeseries, d(:))), lcs));
    end
    return
end
ok = has_storm_duration(project_forcing);
end

function ok = has_storm_duration(data)
% Every Dataset Struct (Holding SWL) Below data Carries storm_duration
if isfield(data, 'SWL')
    ok = isfield(data, 'storm_duration');
    return
end
ok = true;
for fn = fieldnames(data)'
    if isstruct(data.(fn{1})) && ~has_storm_duration(data.(fn{1}))
        ok = false;
        return
    end
end
end

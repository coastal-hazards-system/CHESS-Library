function deps = hotstart_cache_dependencies()
%HOTSTART_CACHE_DEPENDENCIES Declares which config fields set which hotstart level.
%{
%% DESCRIPTION
Single source of truth for "which config fields, if changed between
reruns of the same project/struc_id/case_name, mean the cached
project_forcing.mat (or the cached LCS sampling) can no longer be
trusted." Read by hotstart_level.m (used by resolve_hotstart_state.m)
and by the unit test suite (unit_test/HotstartDependencyDriftTest.m), so
the declared lists and what the pipeline actually checks can never
silently drift apart.

The lists map onto the three hotstart levels of hotstart_level.m:
    'resample'       -> deps.sampling, deps.data_shape
    'reuse_sampling' -> deps.forcing_build, deps.f_adjust, deps.u_engine
    'full'           -> none of the above changed

deps.sampling: Fields that decide WHICH storms the LCS life cycles hold
    (chess_lcs.m and the samplers it calls): life cycle count and
    length, and the sampling mode. A change draws new life cycles.
    storm_db_build_date (storm_db_info.m 'apply', the storm database's
    db_info.build_date): the storm database is shared by every
    PSE/alternative, so another case may rebuild it (e.g. with other
    bias/uncertainty values); a forcing cached before that rebuild is not
    reused.

deps.data_shape: Fields consumed by project_forcing_coverage.m (via
    call_chess_boundary_conditions.m) and by hotstart_level.m. Unlike the
    other lists, this one is NOT equality-diffed: it is an asymmetric
    "does the cached data/sampling cover the request" check, where a
    cache having MORE than requested (e.g. cached CC data satisfying an
    XC-only request) is valid and must not be invalidated. A request the
    cache does not cover draws new life cycles. use_peaks is deliberately
    NOT in this list: it only matters for PROS, and project_forcing_coverage.m
    / hotstart_level.m branch on config.workflow to decide whether to
    check it at all.

deps.forcing_build: Fields baked into the generated forcing that do not
    change which storms are sampled (storm_duration of every dataset:
    config.storm_duration, or with compute_storm_duration = 1 the SWL
    duration of each Timeseries storm). A change rebuilds the forcing from the
    storm database; LCS keeps its sampled life cycles. multiline
    (multiline_stage2_config.m: stage 1 alternative, its forcing build
    stamp and geometry): a multi-line stage 2 forcing is rebuilt from
    stage 1's forcing (apply_stage1_transmission.m) when stage 1 was re-run
    or its geometry changed.

deps.f_adjust (named after the adjustment step,
    boundary_conditions_adjust.m): Fields consumed by
    Forcing_Generation/Forcing_Adjustments/adjust_project_forcing.m
    (and its callees adjust_wave_height.m / apply_depth_limitation.m /
    apply_random_tide.m; adjust_wave_height.m takes its switches as
    arguments, so every config read stays in adjust_project_forcing.m).
    A change rebuilds the forcing from the storm database and re-applies
    the adjustments; LCS keeps its sampled life cycles.

deps.u_engine (named after the uncertainty step,
    boundary_conditions_uncertainty.m): Fields consumed by
    Uncertainty/apply_uncertainty.m and not declared in deps.sampling.
    Same effect as deps.f_adjust.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
deps.sampling = {'mcs_nYears','mcs_nLC','lcs_restrict_sampling_rate','storm_db_build_date'};
deps.data_shape = {'create_wlp','create_whp','use_timeseries','storm_sampling'};
deps.forcing_build = {'storm_duration', 'compute_storm_duration', 'multiline'};
deps.f_adjust = {'apply_depth_limitation','apply_random_tides','tide_file','swl_slr', ...
    'toe_elevation','wall_bottom_elevation','berm_crest_elevation','berm_seaward_slope','berm_crest_width', ...
    'add_toe_berm','struc_type'};
deps.u_engine = {};
end

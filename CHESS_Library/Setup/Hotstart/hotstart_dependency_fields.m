function dependency_fields = hotstart_dependency_fields()
% hotstart_dependency_fields  Config fields that set each hotstart level.
%   dependency_fields = hotstart_dependency_fields() returns the lists of
%   config fields that, if changed between reruns of the same
%   project/struc_id/case_name, mean the cached project_forcing.mat (or the
%   cached LCS sampling) can no longer be trusted.
%
%   Single source of truth, read by hotstart_level (used through
%   hotstart_plan by resolve_hotstart_state and the GUI) and by the unit
%   test suite (HotstartDependencyDriftTest), so the declared lists and what
%   the pipeline actually checks can never silently drift apart.
%
%   The lists map onto the hotstart levels of hotstart_level:
%       'resample'       -> lcs_sampling_fields, dataset_coverage_fields
%       'reuse_sampling' -> forcing_build_fields, forcing_adjustment_fields,
%                           forcing_uncertainty_fields
%       'full'           -> none of the above changed
%
%   Inputs:
%     none
%   Outputs:
%     dependency_fields - 1x1 struct of cellstr field-name lists:
%       lcs_sampling_fields        - fields that decide WHICH storms the LCS
%                                    life cycles hold (chess_lcs and the
%                                    samplers it calls): life cycle count
%                                    and length, and the sampling rate
%                                    restriction. A change draws new life
%                                    cycles. storm_db_build_date
%                                    (storm_db_info 'apply', the storm
%                                    database's db_info.build_date): the
%                                    storm database is shared by every
%                                    PSE/alternative, so another case may
%                                    rebuild it (e.g. with other
%                                    bias/uncertainty values); a forcing
%                                    cached before that rebuild is not
%                                    reused.
%       dataset_coverage_fields    - fields consumed by
%                                    project_forcing_coverage (via
%                                    call_chess_boundary_conditions) and by
%                                    hotstart_level. Unlike the other lists
%                                    this one is NOT equality-diffed: it is
%                                    an asymmetric "does the cached
%                                    data/sampling cover the request" check,
%                                    where a cache having MORE than
%                                    requested (e.g. cached CC data
%                                    satisfying an XC-only request) is valid
%                                    and must not be invalidated. A request
%                                    the cache does not cover draws new life
%                                    cycles. use_peaks applies to every
%                                    workflow: LCS builds Peaks life cycles
%                                    only with use_peaks = 1 (chess_lcs), so
%                                    use_peaks 0 -> 1 draws new life cycles,
%                                    while 1 -> 0 is covered (the cached
%                                    Peaks are ignored).
%       forcing_build_fields       - fields baked into the generated forcing
%                                    that do not change which storms are
%                                    sampled (storm_duration of every
%                                    dataset: the storm_duration field, or
%                                    with compute_storm_duration = 1 the SWL
%                                    duration of each Timeseries storm). A
%                                    change rebuilds the forcing from the
%                                    storm database; LCS keeps its sampled
%                                    life cycles. multiline
%                                    (multiline_stage2_config: stage 1
%                                    alternative, its forcing build stamp
%                                    and geometry): a multi-line stage 2
%                                    forcing is rebuilt from stage 1's
%                                    forcing (apply_stage1_transmission)
%                                    when stage 1 was re-run or its
%                                    geometry changed.
%       forcing_adjustment_fields  - fields consumed by the adjustment step
%                                    (boundary_conditions_adjust):
%                                    adjust_project_forcing and its callees
%                                    adjust_wave_height /
%                                    apply_depth_limitation /
%                                    apply_random_tide (adjust_wave_height
%                                    takes its switches as arguments, so
%                                    every config read stays in
%                                    adjust_project_forcing). A change
%                                    rebuilds the forcing from the storm
%                                    database and re-applies the
%                                    adjustments; LCS keeps its sampled life
%                                    cycles.
%       forcing_uncertainty_fields - fields consumed by the uncertainty step
%                                    (boundary_conditions_uncertainty):
%                                    apply_uncertainty, not declared in
%                                    lcs_sampling_fields. Same effect as
%                                    forcing_adjustment_fields.
%
%   Tier: internal
%
%   See also hotstart_level, hotstart_plan, project_forcing_coverage,
%   any_field_changed.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
dependency_fields.lcs_sampling_fields = {'mcs_nYears','mcs_nLC','lcs_restrict_sampling_rate','storm_db_build_date'};
dependency_fields.dataset_coverage_fields = {'use_peaks','create_wlp','create_whp','use_timeseries','storm_sampling'};
dependency_fields.forcing_build_fields = {'storm_duration', 'compute_storm_duration', 'multiline'};
dependency_fields.forcing_adjustment_fields = {'apply_depth_limitation','apply_random_tides','tide_file','swl_slr', ...
    'toe_elevation','wall_bottom_elevation','berm_crest_elevation','berm_seaward_slope','berm_crest_width', ...
    'add_toe_berm','struc_type'};
dependency_fields.forcing_uncertainty_fields = {};
end

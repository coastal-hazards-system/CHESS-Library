function [level, reason_field] = hotstart_level(config, config_old)
% hotstart_level  How much of a cached run of the same case can be reused.
%   [level, reason_field] = hotstart_level(config, config_old) compares the
%   current run's config with the cached run's config using the lists of
%   hotstart_dependency_fields. No side effects: shared by hotstart_plan
%   (library resolve_hotstart_state and the GUI).
%
%   Levels (first match wins):
%       'resample'       A lcs_sampling_fields field changed, or the request
%                        is not covered by the cached data shape
%                        (dataset_coverage_fields, every workflow;
%                        asymmetric check: a cache holding MORE than
%                        requested still covers it). LCS draws new life
%                        cycles.
%       'reuse_sampling' A forcing_build_fields, forcing_adjustment_fields
%                        or forcing_uncertainty_fields field changed. The
%                        forcing is rebuilt from the storm database and
%                        adjusted/perturbed once; LCS keeps its sampled
%                        life cycles (sampling seed file).
%       'full'           Nothing forcing-relevant changed: the cached
%                        (adjusted/perturbed) project forcing is reused.
%   PROS (workflows 1, 4) and DET (2) have no random sampling: 'resample'
%   and 'reuse_sampling' both rebuild their forcing from the storm database.
%   Fields missing from either struct count as unchanged
%   (any_field_changed).
%
%   Inputs:
%     config     - current run's configuration, 1x1 struct
%     config_old - cached run's configuration (same case), 1x1 struct
%   Outputs:
%     level        - 'full', 'reuse_sampling' or 'resample', char
%     reason_field - config field that set the level ('' for 'full'), char
%
%   Tier: internal
%
%   See also hotstart_plan, hotstart_dependency_fields, any_field_changed,
%   apply_hotstart_level.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
dependency_fields = hotstart_dependency_fields();
[changed, reason_field] = any_field_changed(config, config_old, dependency_fields.lcs_sampling_fields);
if changed
    level = 'resample';
    return
end
reason_field = uncovered_data_shape(config, config_old, dependency_fields.dataset_coverage_fields);
if ~isempty(reason_field)
    level = 'resample';
    return
end
[changed, reason_field] = any_field_changed(config, config_old, [dependency_fields.forcing_build_fields, dependency_fields.forcing_adjustment_fields, dependency_fields.forcing_uncertainty_fields]);
if changed
    level = 'reuse_sampling';
    return
end
level = 'full';
reason_field = '';
end

%% AUX FUNCTION: FIRST DATA SHAPE FIELD THE CACHED RUN DOES NOT COVER ('' If Covered)
function fld = uncovered_data_shape(config, config_old, shape_fields)
fld = '';
flags = setdiff(shape_fields, {'storm_sampling'}, 'stable');
for kk = 1:numel(flags)
    f = flags{kk};
    if isfield(config, f) && isfield(config_old, f) && logical(config.(f)) && ~logical(config_old.(f))
        fld = f;
        return
    end
end
if isfield(config, 'storm_sampling') && isfield(config_old, 'storm_sampling') &&...
        ~all(ismember(storm_types(config.storm_sampling), storm_types(config_old.storm_sampling)))
    fld = 'storm_sampling';
end
end

function types = storm_types(storm_sampling)
types = storm_types_for_sampling(storm_sampling, {'XC', 'TC'});
end

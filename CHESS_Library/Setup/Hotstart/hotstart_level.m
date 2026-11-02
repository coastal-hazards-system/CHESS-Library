function [level, reason_field] = hotstart_level(config, config_old)
%HOTSTART_LEVEL How much of a cached run of the same case can be reused.
%{
%% DESCRIPTION
Compares the current run's config against the cached run's config with
the lists of hotstart_dependency_fields.m. No side effects: shared by
hotstart_plan.m (library resolve_hotstart_state.m and the GUI).

Levels (first match wins):
    'resample'       A lcs_sampling_fields field changed, or the request is not
                     covered by the cached data shape (dataset_coverage_fields,
                     plus use_peaks outside LCS; asymmetric check: a
                     cache holding MORE than requested still covers it).
                     LCS draws new life cycles.
    'reuse_sampling' A forcing_build_fields, forcing_adjustment_fields or forcing_uncertainty_fields
                     field changed. The forcing is rebuilt from the storm
                     database and adjusted/perturbed once; LCS keeps its
                     sampled life cycles (sampling seed file).
    'full'           Nothing forcing-relevant changed: the cached
                     (adjusted/perturbed) project forcing is reused.
PROS (workflow 1, 4) and DET (2) have no random sampling: 'resample' and
'reuse_sampling' both rebuild their forcing from the storm database.

Fields missing from either struct count as unchanged (any_field_changed.m).

%% INPUTS
config: Current run's config. | struct
config_old: Cached run's config (same case). | struct

%% OUTPUTS
level: 'full', 'reuse_sampling' or 'resample'. | char
reason_field: Config field that set the level ('' for 'full'). | char

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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
if isfield(config, 'workflow') && config.workflow ~= 3
    flags = [{'use_peaks'}, flags];
end
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
if strcmpi(storm_sampling, 'CC')
    types = {'XC', 'TC'};
else
    types = {upper(char(storm_sampling))};
end
end

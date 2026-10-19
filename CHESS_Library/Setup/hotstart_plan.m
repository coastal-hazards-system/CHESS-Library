function [level, reason_field, why_not] = hotstart_plan(config, config_old, is_lcs)
%HOTSTART_PLAN Hotstart level a rerun of the same case will actually get.
%{
%% DESCRIPTION
hotstart_level.m plus the one cache check it cannot make from the two
configs: LCS level 'reuse_sampling' needs this case's own sampling seed
file (lcs_sampling_seed_file.m, next to config.out_files.project_forcing)
to hold the requested life cycles. When it does not, the level falls back
to 'resample' and why_not says why. No side effects: shared by
resolve_hotstart_state.m (library) and the GUI (Run dialog), which then
act on the level with apply_hotstart_level.m.

%% INPUTS
config: Current run's config. | struct
config_old: Cached run's config (same case). | struct
is_lcs: LCS workflow (life cycles are sampled). | logical

%% OUTPUTS
level: 'full', 'reuse_sampling' or 'resample'. | char
reason_field: Config field that set the level ('' for 'full'). | char
why_not: Why LCS sampling reuse fell back to 'resample' ('' otherwise). | char

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
[level, reason_field] = hotstart_level(config, config_old);
why_not = '';
if strcmp(level, 'reuse_sampling') && is_lcs
    why_not = own_sampling_gap(config, lcs_sampling_seed_file(config.out_files.project_forcing));
    if ~isempty(why_not)
        level = 'resample';
    end
end
end

%% AUX FUNCTION: WHY THIS CASE'S OWN LCS SAMPLING SEED CANNOT BE REUSED ('' If It Can)
function why_not = own_sampling_gap(config, seed_file)
why_not = '';
if ~isfile(seed_file)
    why_not = 'no sampling seed file was found';
    return
end
S = load(seed_file);
if strcmp(config.storm_sampling, 'CC')
    types = {'XC', 'TC'};
else
    types = {config.storm_sampling};
end
for kk = 1:numel(types)
    if ~isfield(S.sampled_ids, types{kk}) || numel(S.sampled_ids.(types{kk})) ~= config.mcs_nLC
        why_not = sprintf('the sampling seed file has no %s life cycles to reuse', types{kk});
        return
    end
end
% XC WLP/WHP Life Cycles Are Copies Of The Default Ones (stormsim_lcs.m): Only xc_peaks.Default Is Needed
if ismember('XC', types) && (~isfield(S, 'xc_peaks') || ~isfield(S.xc_peaks, 'Default'))
    why_not = 'the sampling seed file lacks the sampled XC peak values';
end
end

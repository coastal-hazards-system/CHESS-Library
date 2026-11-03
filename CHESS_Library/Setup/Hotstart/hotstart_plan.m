function [level, reason_field, why_not] = hotstart_plan(config, config_old, is_lcs)
% hotstart_plan  Hotstart level a rerun of the same case will actually get.
%   [level, reason_field, why_not] = hotstart_plan(config, config_old,
%       is_lcs) returns hotstart_level plus the one cache check it cannot
%       make from the two configs.
%
%   LCS level 'reuse_sampling' needs this case's own sampling seed file
%   (lcs_sampling_seed_file, next to out_files.project_forcing) to hold the
%   requested life cycles (and the XC peak values when use_peaks = 1). When
%   it does not, the level falls back to 'resample' and why_not says why.
%   No side effects: shared by resolve_hotstart_state (library) and the GUI
%   (Run dialog), which then act on the level with apply_hotstart_level.
%
%   Inputs:
%     config     - current run's configuration, 1x1 struct; for LCS reads
%                  out_files.project_forcing, storm_sampling, mcs_nLC and
%                  use_peaks
%     config_old - cached run's configuration (same case), 1x1 struct
%     is_lcs     - LCS workflow (life cycles are sampled), logical
%   Outputs:
%     level        - 'full', 'reuse_sampling' or 'resample', char
%     reason_field - config field that set the level ('' for 'full'), char
%     why_not      - why LCS sampling reuse fell back to 'resample' (''
%                    otherwise), char
%
%   Tier: internal
%
%   See also hotstart_level, apply_hotstart_level, resolve_hotstart_state,
%   lcs_sampling_seed_file.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
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
types = storm_types_for_sampling(config.storm_sampling, {'XC', 'TC'});
for kk = 1:numel(types)
    if ~isfield(S.sampled_ids, types{kk}) || numel(S.sampled_ids.(types{kk})) ~= config.mcs_nLC
        why_not = sprintf('the sampling seed file has no %s life cycles to reuse', types{kk});
        return
    end
end
% XC WLP/WHP Life Cycles Are Copies Of The Default Ones (chess_lcs.m): Only xc_peaks.Default Is Needed.
% use_peaks = 0 Builds No Peaks Life Cycles (Its Seed Holds No xc_peaks)
if config.use_peaks == 1 && ismember('XC', types) && (~isfield(S, 'xc_peaks') || ~isfield(S.xc_peaks, 'Default'))
    why_not = 'the sampling seed file lacks the sampled XC peak values';
end
end

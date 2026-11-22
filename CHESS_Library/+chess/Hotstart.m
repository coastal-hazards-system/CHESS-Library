classdef Hotstart < handle
    % Hotstart  Decide how much of a saved run can be reused.
    %   hotstart = chess.Hotstart(config) compares the configuration of this
    %   run with the one saved by the last run of the same alternative,
    %   workflow and storm database (config.out_files.config).
    %   hotstart = chess.Hotstart(config, saved_config) compares with a given
    %   saved configuration.
    %
    %   Levels:
    %     'full'           - nothing the forcing depends on changed: the saved
    %                        project forcing is reused
    %     'reuse_sampling' - the forcing is rebuilt; LCS keeps its sampled life
    %                        cycles (sampling seed file)
    %     'resample'       - the forcing is rebuilt; LCS draws new life cycles
    %     'cold'           - no saved run (or it could not be read)
    %
    %   Typical use:
    %     hotstart = chess.Hotstart(config);
    %     [level, reason, why] = hotstart.plan();   % no disk writes
    %     config = hotstart.apply(level);           % deletes stale files, carries tides and stamps
    %
    %   See also chess.Model.

    properties (SetAccess = private)
        config              % configuration of this run
        saved_config = []   % configuration saved by the last run ([] = none)
        load_error = ''     % why the saved configuration could not be read
    end

    methods
        function obj = Hotstart(config, saved_config)
            % Hotstart  Compare the configuration of a run with its saved run (see the class help).
            %   obj = chess.Hotstart(config, saved_config)
            obj.config = config;
            if nargin > 1
                obj.saved_config = saved_config;
                return
            end
            % This Run's Own File, So Its Stored Paths Are Not Compared (A Moved Project Stores Other Paths)
            if isfile(config.out_files.config)
                try
                    S = load(config.out_files.config, 'config');
                    obj.saved_config = S.config;
                catch failure
                    obj.load_error = failure.message;
                end
            end
        end

        function [level, reason, why] = plan(obj, is_life_cycle)
            % plan  Hotstart level of this run (no disk writes).
            %   [level, reason, why] = hotstart.plan()
            %   [level, reason, why] = hotstart.plan(is_life_cycle)
            %   level  - 'full', 'reuse_sampling', 'resample' or 'cold'
            %   reason - config field that changed since the saved run ('' = none)
            %   why    - why the sampled life cycles cannot be reused although
            %            only forcing settings changed ('' = not applicable)
            %   is_life_cycle - LCS sampling rules apply (default: workflow 3)
            if nargin < 2
                is_life_cycle = obj.config.workflow == 3;
            end
            reason = '';
            why = '';
            if isempty(obj.saved_config)
                level = 'cold';
                return
            end
            [level, reason] = hotstart_level(obj.config, obj.saved_config);
            % LCS Sampling Reuse Needs This Case's Own Sampling Seed File To Cover The Request
            if strcmp(level, 'reuse_sampling') && is_life_cycle
                why = own_sampling_gap(obj.config, chess.ProjectPaths.sampling_seed_file(obj.config.out_files.project_forcing));
                if ~isempty(why)
                    level = 'resample';
                end
            end
        end

        function config = apply(obj, level, is_life_cycle)
            % apply  Act on a hotstart level and return the updated config.
            %   config = hotstart.apply(level)
            %   config = hotstart.apply(level, is_life_cycle)
            %   'full': keeps the forcing stamp and the LCS tide start hours of
            %   the saved run. 'reuse_sampling': LCS carries the tide start
            %   hours when the tide settings did not change. 'resample': the
            %   LCS sampling seed file is deleted. Every level but 'full'
            %   deletes the saved project forcing ('cold' also the sampling
            %   seed). config.hotstart_level is set.
            if nargin < 3
                is_life_cycle = obj.config.workflow == 3;
            end
            if strcmp(level, 'cold')
                config = obj.config;
                for ff = {config.out_files.project_forcing, chess.ProjectPaths.sampling_seed_file(config.out_files.project_forcing)}
                    if isfile(ff{1})
                        delete(ff{1});
                    end
                end
                config.hotstart_level = 'cold';
            else
                config = apply_hotstart_level(obj.config, obj.saved_config, level, is_life_cycle);
            end
            obj.config = config;
        end

        function config = resolve(obj)
            % resolve  Plan, report and apply the hotstart level of this run.
            %   config = hotstart.resolve()
            config = obj.config;
            is_lcs = config.workflow == 3;
            if ~isempty(obj.load_error)
                warning('chess:Hotstart:cacheLoadFailed', 'Hotstart cache failed to load (%s): running a cold start.', obj.load_error);
                config = obj.apply('cold');
                return
            end
            [level, reason, why_not] = obj.plan();
            if ~isempty(why_not)
                chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache, but %s -- drawing new life cycles....', reason, why_not));
            end
            switch level
                case 'cold'
                    paths = chess.ProjectPaths.build(config);
                    chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: no cache found for storm database ''%s'', running cold start....', paths.db));
                    config.hotstart_level = 'cold';
                    obj.config = config;
                    return
                case 'full'
                    chess.Common.disp_toggle(config.print_progress, 'Hotstart cache is valid (no forcing-relevant config field changed), reusing project forcing....');
                case 'reuse_sampling'
                    if is_lcs
                        chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- reusing the sampled life cycles, rebuilding project forcing from the storm database....', reason));
                    else
                        chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- rebuilding project forcing from the storm database....', reason));
                    end
                case 'resample'
                    if is_lcs
                        chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- drawing new life cycles and rebuilding project forcing....', reason));
                    else
                        chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- rebuilding project forcing from the storm database....', reason));
                    end
            end
            try
                config = obj.apply(level);
            catch failure
                warning('chess:Hotstart:cacheLoadFailed', 'Hotstart cache failed to load (%s): running a cold start.', failure.message);
                config = obj.apply('cold');
            end
        end

        function [covers, project_forcing, missing] = forcing_covers(obj)
            % forcing_covers  True when the saved project forcing holds what this run requests.
            %   [covers, project_forcing, missing] = hotstart.forcing_covers()
            %   covers          - the saved forcing has every requested data
            %                     type, Peaks dataset and storm type, in the
            %                     current layout
            %   project_forcing - the saved forcing ([] when there is no file)
            %   missing         - what is missing, e.g. 'WLP, TC' ('' = nothing)
            [covers, project_forcing, missing] = project_forcing_cache_hit(obj.config);
        end
    end

    methods (Static)
        function [changed, changed_field] = any_field_changed(a, b, field_names)
        % chess.Hotstart.any_field_changed  True if any named field differs between two structs.
        %   [changed, changed_field] = chess.Hotstart.any_field_changed(a, b, field_names) compares
        %   the named fields of two structs with isequaln and returns the first
        %   one that differs.
        %
        %   Generic struct-field comparator with no domain knowledge of what the
        %   fields mean. A field present in only one of the two structs counts as
        %   not changed (not an error), so a freshly parsed config can be compared
        %   with an older cached config that predates the field. NaN values compare
        %   equal (isequaln): a NaN field (e.g. sp_lat/sp_lon when the CHS file has
        %   no savepoint coordinates, blank input table cells) that is NaN in both
        %   structs counts as unchanged.
        %
        %   Inputs:
        %     a, b        - structs to compare, 1x1 struct
        %     field_names - field names to check, in order, cellstr
        %   Outputs:
        %     changed       - true if a named field is present in both structs and
        %                     its value differs (isequaln), false otherwise, logical
        %     changed_field - name of the first field found to differ ('' when
        %                     changed is false), char
        %
        %   See also hotstart_level, chess.Hotstart.dependency_fields.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        changed = false;
        changed_field = '';
        for kk = 1:numel(field_names)
            fld = field_names{kk};
            if isfield(a, fld) && isfield(b, fld) && ~isequaln(a.(fld), b.(fld))
                changed = true;
                changed_field = fld;
                return
            end
        end
        end

        function [covers, missing] = forcing_coverage(config, project_forcing)
            % forcing_coverage  Check a project forcing against a run request.
            %   [covers, missing] = chess.Hotstart.forcing_coverage(config, project_forcing)
            [covers, missing] = project_forcing_coverage(config, project_forcing);
        end

        function dependency_fields = dependency_fields()
            % dependency_fields  Config fields each hotstart level depends on.
            dependency_fields = dependency_field_lists();
        end
    end
end

%% LOCAL FUNCTIONS
function [level, reason_field] = hotstart_level(config, config_old)
dependency_fields = dependency_field_lists();
[changed, reason_field] = chess.Hotstart.any_field_changed(config, config_old, dependency_fields.lcs_sampling_fields);
if changed
    level = 'resample';
    return
end
reason_field = uncovered_data_shape(config, config_old, dependency_fields.dataset_coverage_fields);
if ~isempty(reason_field)
    level = 'resample';
    return
end
[changed, reason_field] = chess.Hotstart.any_field_changed(config, config_old, [dependency_fields.forcing_build_fields, dependency_fields.forcing_adjustment_fields, dependency_fields.forcing_uncertainty_fields]);
if changed
    level = 'reuse_sampling';
    return
end
level = 'full';
reason_field = '';
end

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
types = chess.Common.storm_types_for_sampling(storm_sampling, {'XC', 'TC'});
end

function why_not = own_sampling_gap(config, seed_file)
why_not = '';
if ~isfile(seed_file)
    why_not = 'no sampling seed file was found';
    return
end
S = load(seed_file);
types = chess.Common.storm_types_for_sampling(config.storm_sampling, {'XC', 'TC'});
for kk = 1:numel(types)
    if ~isfield(S.sampled_ids, types{kk}) || numel(S.sampled_ids.(types{kk})) ~= config.mcs_nLC
        why_not = sprintf('the sampling seed file has no %s life cycles to reuse', types{kk});
        return
    end
end
% XC WLP/WHP Life Cycles Are Copies Of The Default Ones (chess.Model.LifeCycle): Only xc_peaks.Default Is Needed.
% use_peaks = 0 Builds No Peaks Life Cycles (Its Seed Holds No xc_peaks)
if config.use_peaks == 1 && ismember('XC', types) && (~isfield(S, 'xc_peaks') || ~isfield(S.xc_peaks, 'Default'))
    why_not = 'the sampling seed file lacks the sampled XC peak values';
end
end

function config = apply_hotstart_level(config, config_old, level, is_lcs)
switch level
    case 'full'
        % The Reused Forcing Keeps Its Build Stamp: Marks It Complete (chess.Model.build_forcing Step 0),
        % Multi-Line Stage 2 Runs Coupled To It Stay Current
        if isfield(config_old, 'forcing_stamp')
            config.forcing_stamp = config_old.forcing_stamp;
        end
        % LCS: The Reused Forcing Holds These Tides, Keep Them In The Saved Config (Later
        % 'reuse_sampling' Reruns And Reference Cases Read Them). chess.Model.LifeCycle Drops Them If It Resamples.
        if is_lcs
            for fld = {'tide_indx_tc', 'tide_indx_xc', 'tide_indx_cc'}
                if isfield(config_old, fld{1})
                    config.(fld{1}) = config_old.(fld{1});
                end
            end
        end
    case 'reuse_sampling'
        if is_lcs
            config = carry_tide_indices(config, config_old);
        end
    case 'resample'
        % A Stale Seed Must Not Outlive A Run That Crashes Before Resampling
        seed_file = chess.ProjectPaths.sampling_seed_file(config.out_files.project_forcing);
        if is_lcs && isfile(seed_file)
            delete(seed_file);
        end
end
% Cached Project Forcing Is Adjusted/Perturbed: Never A Value Source Once Anything Changed
if ~strcmp(level, 'full')
    if exist(config.out_files.project_forcing, 'file')
        delete(config.out_files.project_forcing);
    end
end
config.hotstart_level = level;
end

function config = carry_tide_indices(config, config_old)
if config.apply_random_tides ~= 1 || config_old.apply_random_tides ~= 1 ||...
        ~strcmp(char(config.tide_file), char(config_old.tide_file))
    return
end
for st = {'tc', 'xc'}
    fld = ['tide_indx_' st{1}];
    if isfield(config_old, fld) && ~isempty(config_old.(fld))
        config.(fld) = config_old.(fld);
        chess.Common.disp_toggle(config.print_progress, sprintf('Hotstart: reusing the cached run''s %s tide start hours....', upper(st{1})));
    end
end
end

function [hit, project_forcing, missing_desc] = project_forcing_cache_hit(config)
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

function ok = current_layout(workflow, project_forcing)
if workflow == 3
    ok = true;
    if isfield(project_forcing, 'Timeseries')
        lcs = struct2cell(project_forcing.Timeseries.Default);
        ok = all(cellfun(@(d) all(cellfun(@(x) size(x, 2) == chess.Common.lcs_columns().n_timeseries, d(:))), lcs));
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

function [covers, missing_desc] = project_forcing_coverage(config, project_forcing)
has_peaks = isfield(project_forcing, 'Peaks');
has_wlp = has_peaks && isfield(project_forcing.Peaks, 'WLP');
has_whp = has_peaks && isfield(project_forcing.Peaks, 'WHP');
has_timeseries = isfield(project_forcing, 'Timeseries');
if has_peaks
    storm_types = project_forcing.Peaks.Default;
else
    storm_types = project_forcing.Timeseries.Default;
end
has_xc = isfield(storm_types, 'XC');
has_tc = isfield(storm_types, 'TC');
sampled_types = chess.Common.storm_types_for_sampling(config.storm_sampling, {'TC', 'XC'});
tc_conf = ismember('TC', sampled_types);
xc_conf = ismember('XC', sampled_types);
have = [has_peaks;has_wlp;has_whp;has_timeseries;has_tc;has_xc];
need = [cellfun(@(x) logical(config.(x)), {'use_peaks','create_wlp','create_whp','use_timeseries'}, 'un', true)';tc_conf;xc_conf];
labels = {'Peaks';'WLP';'WHP';'Timeseries';'TC';'XC'};
missing_mask = need & ~have;
covers = ~any(missing_mask);
missing_desc = strjoin(labels(missing_mask), ', ');
end

function dependency_fields = dependency_field_lists()
% dependency_field_lists  Config fields that set each hotstart level.
%   dependency_fields = dependency_field_lists() returns the lists of
%   config fields that, if changed between reruns of the same
%   project/struc_id/case_name, mean the cached project_forcing.mat (or the
%   cached LCS sampling) can no longer be trusted.
%
%   Single source of truth, read by hotstart_level (used through
%   chess.Hotstart.plan by chess.Hotstart.resolve and the GUI) and by the unit
%   test suite (HotstartDependencyDriftTest), so the declared lists and what
%   the pipeline actually checks can never silently drift apart.
%
%   The lists map onto the hotstart levels of hotstart_level:
%       'resample'       -> lcs_sampling_fields, dataset_coverage_fields
%       'reuse_sampling' -> forcing_build_fields, forcing_adjustment_fields,
%                           forcing_uncertainty_fields
%       'full'           -> none of the above changed
%   Response settings are NOT dependencies (the cached forcing is reused
%   and the responses are recomputed at every level): the compute_*
%   switches, dn50_use_legacy_model and dn50_legacy_submerged_correction.
%
%   Inputs:
%     none
%   Outputs:
%     dependency_fields - 1x1 struct of cellstr field-name lists:
%       lcs_sampling_fields        - fields that decide WHICH storms the LCS
%                                    life cycles hold (chess.Model.LifeCycle and the
%                                    samplers it calls): life cycle count
%                                    and length, and the sampling rate
%                                    restriction. A change draws new life
%                                    cycles. storm_db_build_date
%                                    (chess.CoastalHazardSystem.create_db_info 'apply', the storm
%                                    database's db_info.build_date): the
%                                    storm database is shared by every
%                                    PSE/alternative, so another case may
%                                    rebuild it (e.g. with other
%                                    bias/uncertainty values); a forcing
%                                    cached before that rebuild is not
%                                    reused.
%       dataset_coverage_fields    - fields consumed by
%                                    chess.Hotstart.forcing_coverage (via
%                                    chess.Model.build_forcing) and by
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
%                                    only with use_peaks = 1 (chess.Model.LifeCycle), so
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
%                                    (chess.Model.couple_to_stage1: stage 1
%                                    alternative, its forcing build stamp
%                                    and geometry): a multi-line stage 2
%                                    forcing is rebuilt from stage 1's
%                                    forcing (stage1_forcing)
%                                    when stage 1 was re-run or its
%                                    geometry changed.
%       forcing_adjustment_fields  - fields consumed by the adjustment step
%                                    (chess.Model.build_forcing (adjustment step)):
%                                    chess.Model.build_forcing (adjustment step) and its callees
%                                    toe_wave_height /
%                                    apply_depth_limitation /
%                                    chess.BoundaryConditions.tides.random_tide. A change
%                                    rebuilds the forcing from the storm
%                                    database and re-applies the
%                                    adjustments; LCS keeps its sampled life
%                                    cycles.
%       forcing_uncertainty_fields - fields consumed by the uncertainty step
%                                    (chess.Model.build_forcing (uncertainty step)):
%                                    apply_uncertainty, not declared in
%                                    lcs_sampling_fields. Same effect as
%                                    forcing_adjustment_fields.
%
%   See also hotstart_level, chess.Hotstart.plan, chess.Hotstart.forcing_coverage,
%   chess.Hotstart.any_field_changed.
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

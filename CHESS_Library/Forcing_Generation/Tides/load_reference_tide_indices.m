function config = load_reference_tide_indices(config, project_forcing)
% load_reference_tide_indices  Reuse the tide start hours of an LCS reference.
%   config = load_reference_tide_indices(config, project_forcing)
%
%   When an LCS run reuses the storm sampling of a reference case
%   (load_project_forcing = 1, ref_case_name), the alternatives share the
%   same storm sequences. This function also gives them the same random
%   tides: it copies tide_indx_tc / tide_indx_xc from the reference case's
%   config file into config, so draw_tide_indices and apply_random_tide
%   keep them instead of drawing new start hours.
%
%   The reference indices of a storm type are used only when:
%     - random tides are applied in this run (apply_random_tides = 1),
%     - config holds no start hours of that type yet,
%     - that storm type's life cycles were actually reused from the
%       reference (lcs_reference_reuse: src = 'Reference', i.e. the
%       reference has a usable sampling seed file holding that storm type);
%       otherwise the life cycles were sampled fresh and their storms have
%       nothing to do with the reference's tides,
%     - the reference case used the same tide file,
%     - they match this run's life cycles: same number of life cycles and
%       the same number of storms of that type in each life cycle.
%   Otherwise new start hours are drawn as usual (a message says why).
%
%   Inputs:
%     config          - CHESS configuration (workflow 3), 1x1 struct; reads
%                       workflow, load_project_forcing, ref_case_name,
%                       apply_random_tides, tide_file, storm_sampling,
%                       tide_indx_tc / _xc, outfolder, project_name,
%                       struc_id, case_name, storm_db or region/sp_ID
%                       (chess_paths), plus the fields lcs_reference_reuse
%                       reads
%     project_forcing - LCS project forcing of this run (before adjustment),
%                       struct
%   Outputs:
%     config - input config with tide_indx_tc / tide_indx_xc from the
%              reference case when they apply, struct
%
%   Tier: internal
%
%   See also draw_tide_indices, lcs_reference_reuse, chess_lcs,
%   chess_paths.

if ~isfield(config, 'workflow') || config.workflow ~= 3 ||...
        ~isfield(config, 'load_project_forcing') || config.load_project_forcing ~= 1 ||...
        ~isfield(config, 'apply_random_tides') || config.apply_random_tides ~= 1
    return
end
% Reference Case Config: Same Project/PSE, Alternative ref_case_name, LCS, Same Storm DB (chess_paths.m)
paths = chess_paths(config);
ref_paths = chess_paths(config.outfolder, config.project_name, config.struc_id, config.ref_case_name, 3, paths.db);
ref_cfg = ref_paths.out_files.config;
if ~isfile(ref_cfg)
    return
end
ref = load(ref_cfg, 'config');
ref = ref.config;
% Same Tide File Only (Start Hours Point Into That File)
if ~isfield(ref, 'tide_file') || ~strcmp(char(ref.tide_file), char(config.tide_file))
    disp(['     Tides: reference case ' config.ref_case_name ' used a different tide file; drawing new tide start hours.']);
    return
end
% Storm Types Whose Life Cycles Were Reused From The Reference (Same Rule As chess_lcs.m)
reuse = lcs_reference_reuse(config);
for st = storm_types_for_sampling(config.storm_sampling, {'TC', 'XC'})
    fld = ['tide_indx_' lower(st{1})];
    if ~isfield(ref, fld) || isempty(ref.(fld)) || (isfield(config, fld) && ~isempty(config.(fld)))
        continue
    end
    storms_per_lc = lc_storm_counts(project_forcing, st{1});
    if isempty(storms_per_lc)
        continue
    end
    if ~strcmp(reuse.src.(st{1}), 'Reference')
        disp(['     Tides: ' st{1} ' life cycles were not reused from reference case ' config.ref_case_name '; drawing new tide start hours.']);
        continue
    end
    ref_idx = ref.(fld)(:);
    if numel(ref_idx) == numel(storms_per_lc) && isequal(cellfun(@numel, ref_idx), storms_per_lc)
        config.(fld) = ref.(fld);
        disp(['     Tides: reusing ' st{1} ' tide start hours from reference case ' config.ref_case_name '.']);
    else
        disp(['     Tides: ' st{1} ' life cycles differ from reference case ' config.ref_case_name '; drawing new tide start hours.']);
    end
end
end

%% AUX FUNCTION: STORMS PER LIFE CYCLE (PEAKS ROWS; WITHOUT PEAKS (use_peaks = 0) TIMESERIES FIRST-STEP ROWS, step == 0)
function counts = lc_storm_counts(project_forcing, st_type)
counts = [];
if isfield(project_forcing, 'Peaks') && isfield(project_forcing.Peaks, 'Default') && isfield(project_forcing.Peaks.Default, st_type)
    counts = cellfun(@(x) size(x, 1), project_forcing.Peaks.Default.(st_type)(:));
elseif isfield(project_forcing, 'Timeseries') && isfield(project_forcing.Timeseries.Default, st_type)
    step = lcs_columns().step;
    counts = cellfun(@(x) sum(x(:, step) == 0), project_forcing.Timeseries.Default.(st_type)(:));
end
end

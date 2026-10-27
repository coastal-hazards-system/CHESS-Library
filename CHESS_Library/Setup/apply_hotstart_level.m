function config = apply_hotstart_level(config, config_old, level, is_lcs)
%APPLY_HOTSTART_LEVEL Cache actions of a hotstart level (from hotstart_plan.m).
%{
%% DESCRIPTION
Acts on the hotstart level of a rerun of the same case. Shared by
resolve_hotstart_state.m (library) and the GUI (Run dialog "Hotstart").
Never removes folders (neither does resolve_hotstart_state.m: another
sp_ID/region is another storm DB, so other run files; chess_paths.m).
    'full'           forcing_stamp carried from the cached run, so the
                     cached (complete) project forcing is reused as is
                     (call_chess_boundary_conditions.m step 0). LCS: the
                     cached run's tide start hours (tide_indx_tc/_xc/_cc)
                     are carried too: the reused forcing holds these tides.
    'reuse_sampling' LCS: the cached run's TC/XC tide start hours are
                     carried when random tides are on in both runs with
                     the same tide file (tide_indx_cc is re-derived by
                     draw_tide_indices.m).
    'resample'       LCS: this case's sampling seed file is deleted, so
                     new life cycles are drawn.
Any level but 'full': the cached project_forcing.mat is deleted (it
holds adjusted/perturbed values).
config.hotstart_level is set to the level (lcs_reference_reuse.m reads
'reuse_sampling' to rebuild the life cycles from the sampling seed file).

%% INPUTS
config: Current run's config (out_files.project_forcing). | struct
config_old: Cached run's config (same case). | struct
level: 'full', 'reuse_sampling' or 'resample' (hotstart_plan.m). | char
is_lcs: LCS workflow. | logical

%% OUTPUTS
config: config with hotstart_level (plus forcing_stamp at 'full' and
        LCS tide start hours) resolved.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
switch level
    case 'full'
        % The Reused Forcing Keeps Its Build Stamp: Marks It Complete (call_chess_boundary_conditions.m Step 0),
        % Multi-Line Stage 2 Runs Coupled To It Stay Current
        if isfield(config_old, 'forcing_stamp')
            config.forcing_stamp = config_old.forcing_stamp;
        end
        % LCS: The Reused Forcing Holds These Tides, Keep Them In The Saved Config (Later
        % 'reuse_sampling' Reruns And Reference Cases Read Them). chess_lcs Drops Them If It Resamples.
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
        seed_file = lcs_sampling_seed_file(config.out_files.project_forcing);
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

%% AUX FUNCTION: KEEP THE CACHED RUN'S TIDE START HOURS FOR THE REUSED LCS LIFE CYCLES
% Same Rule As load_reference_tide_indices.m (Random Tides On In Both Runs, Same Tide File). chess_lcs
% Clears Them Again For Any Storm Type Whose Life Cycles Are Not Rebuilt From This Case's Own Sampling.
% tide_indx_cc Is Not Carried: draw_tide_indices.m Derives It From The TC/XC Start Hours.
function config = carry_tide_indices(config, config_old)
if config.apply_random_tides ~= 1 || config_old.apply_random_tides ~= 1 ||...
        ~strcmp(char(config.tide_file), char(config_old.tide_file))
    return
end
for st = {'tc', 'xc'}
    fld = ['tide_indx_' st{1}];
    if isfield(config_old, fld) && ~isempty(config_old.(fld))
        config.(fld) = config_old.(fld);
        disp_toggle(config.print_progress, sprintf('Hotstart: reusing the cached run''s %s tide start hours....', upper(st{1})));
    end
end
end

function config = resolve_hotstart_state(config, wflow2)
%{
%% DESCRIPTION
Compares the current run's config against a previously cached
"_config_file.mat" (if one exists) and decides which hotstart state
carries over: whether call_chess_boundary_conditions.m reuses the
cached project forcing (forcing_stamp, carried at level 'full'). The cache is this run's own file
(chess_paths.m): its name holds the storm database (<region>_SP<sp_ID>
by default), so a different savepoint or region never finds it and runs
cold; nothing is deleted. The hotstart level (hotstart_plan.m, acted on
by apply_hotstart_level.m; both shared with the GUI) decides:
    'full'           Cached project forcing is reused (forcing_stamp carried).
    'reuse_sampling' The cached project_forcing.mat is deleted (it holds
                     adjusted/perturbed values) and rebuilt from the storm
                     database, then adjusted/perturbed once. LCS keeps its
                     sampled life cycles: chess_lcs rebuilds them from
                     this case's own sampling seed file, and the cached
                     run's tide start hours are kept (random tides on in
                     both runs, same tide file). Without a seed file that
                     covers the request it falls back to 'resample'.
    'resample'       As 'reuse_sampling', but LCS draws new life cycles
                     (the case's sampling seed file is deleted).
The level is stored in config.hotstart_level ('cold' when there is no
usable cache). A cache that fails to load runs cold: this run's cached
project forcing and LCS sampling seed are deleted.

Bias/uncertainty values are not carried from the cache: every run takes
them from the storm database's db_info (storm_db_info.m), set when the
database was built. A database rebuilt since the cached run (by this or
another case: config.storm_db_build_date) gives 'resample'.

%% INPUTS
config: Current run's parsed config struct (pre-hotstart-resolution).
wflow2: Workflow subfolder name ('PROS', 'DET' or 'LCS'); 'LCS'
        enables the LCS sampling reuse rules.

%% OUTPUTS
config: config struct with hotstart_level (and forcing_stamp at
        'full') resolved (plus tide_indx_tc/_xc carried over at LCS level
        'reuse_sampling'; tide_indx_cc is derived from them by
        draw_tide_indices.m).

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if exist(config.out_files.config, 'file')
    try
        % Load Config (This Run's Own File, So Its Stored Paths Are Not Compared: A Moved Project Stores Other Paths)
        config_load = load(config.out_files.config, 'config');
        config_load = config_load.config;
        % Hotstart Level (Shared With The GUI): 'full' | 'reuse_sampling' | 'resample'
        % (chs_swl_u_a/u_r/chs_hm0_u_a/u_r Are Not Hotstart Dependencies: They Come From The Storm Database's
        % db_info And Change Only When It Is Rebuilt, Which Changes storm_db_build_date: 'resample')
        is_lcs = strcmp(wflow2, 'LCS');
        % LCS Sampling Reuse Needs This Case's Own Sampling Seed File To Cover The Request (hotstart_plan.m)
        [level, reason, why_not] = hotstart_plan(config, config_load, is_lcs);
        if ~isempty(why_not)
            disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache, but %s -- drawing new life cycles....', reason, why_not));
        end
        switch level
            case 'full'
                disp_toggle(config.print_progress, 'Hotstart cache is valid (no forcing-relevant config field changed), reusing project forcing....');
            case 'reuse_sampling'
                if is_lcs
                    disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- reusing the sampled life cycles, rebuilding project forcing from the storm database....', reason));
                else
                    disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- rebuilding project forcing from the storm database....', reason));
                end
            case 'resample'
                if is_lcs
                    disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- drawing new life cycles and rebuilding project forcing....', reason));
                else
                    disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- rebuilding project forcing from the storm database....', reason));
                end
        end
        % Level Actions (apply_hotstart_level.m, Shared With The GUI): Forcing Stamp, LCS Tides, Cache/Seed Deletion
        config = apply_hotstart_level(config, config_load, level, is_lcs);
    catch ME
        warning('Hotstart cache failed to load: %s -- running cold start....', ME.message);
        % Delete This Run's Cached Forcing And LCS Sampling Seed (The Workflow Folder Is Shared With Other Storm DBs: Kept)
        for ff = {config.out_files.project_forcing, lcs_sampling_seed_file(config.out_files.project_forcing)}
            if isfile(ff{1})
                delete(ff{1});
            end
        end
        config.hotstart_level = 'cold';
    end
else
    paths = chess_paths(config);
    disp_toggle(config.print_progress, sprintf('Hotstart: no cache found for storm database ''%s'', running cold start....', paths.db));
    config.hotstart_level = 'cold';
end
end

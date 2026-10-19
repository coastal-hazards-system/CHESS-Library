function reuse = lcs_reference_reuse(config)
%{
    %% DESCRIPTION
        Decides, before LCS sampling, which storm types are reused from the reference
        case (load_project_forcing = 1, ref_case_name), the sampling mode the life cycles
        end up with, and the storm types that get the convergence check. Shared by
        stormsim_lcs and the GUI (convergence dialog) so both apply the same rule:
            - A storm type is reused only when the reference project forcing file exists
              AND the reference's sampling seed file holds the sampling mode
              (lcs_restrict_sampling_rate) and that storm type's sampled life cycles
              (sampled_ids). A reference without a usable seed file reuses nothing: its
              storm types are sampled fresh, as if load_project_forcing = 0 (seed_found
              = false; stormsim_lcs warns).
            - Reused storms were sampled under the mode stored in the seed file, which
              then becomes the effective mode. Otherwise the configured
              lcs_restrict_sampling_rate is the effective mode.
            - The convergence check runs only in effective mode 0, for the storm types
              that are sampled fresh.
            - Hotstart level 'reuse_sampling' (config.hotstart_level, set by
              resolve_hotstart_state.m): when no reference is used, this case's own
              cached sampling is reused instead (its sampling seed file: sampled_ids,
              mode and raw XC peaks), the same way as a reference.
        Prints nothing: stormsim_lcs reports the outcome.

    %% INPUTS
        config: Run configuration (load_project_forcing, ref_case_name, outfolder,
            project_name, struc_id, case_name, workflow, storm_db or region/sp_ID
            (stormsim_paths.m), storm_sampling, lcs_restrict_sampling_rate; optional
            hotstart_level, out_files.project_forcing). | struct

    %% OUTPUTS
        reuse: | struct
            file: Reference project forcing file. | char
            found: load_project_forcing = 1 and the reference file exists. | logical
            seed_found: found and the reference's sampling seed file holds
                lcs_restrict_sampling_rate and sampled_ids. | logical
            types: Storm types to sample, in sampling order ('CC' -> {'XC','TC'}). | cell
            src: Seed source per storm type (fields XC, TC): 'Reference' (reference's
                sampling seed file), 'Seed' (own sampling seed file) or '' (not reused,
                sampled fresh). | struct
            ids: Reused life-cycle identity columns per storm type (fields XC, TC):
                nLC x 1 cell of [storm_ID, intensity_bin, Sim_Year, order]. | struct
            own: The reused storms are this case's own cached sampling. | logical
            seed_pf: Project forcing file whose sampling seed file holds the reused
                mode and raw XC peaks (reference or own). | char
            label: Source description for messages. | char
            reused: Reused flag per element of types. | logical
            mode: Effective sampling mode (0 = Full Poisson, 1 = Rate Matched). | double
            check_types: Storm types that get the convergence check. | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
% Reference Case: Same Project/PSE, Alternative ref_case_name, LCS, Same Storm DB As This Run (stormsim_paths.m)
paths = stormsim_paths(config);
ref_paths = stormsim_paths(config.outfolder, config.project_name, config.struc_id, config.ref_case_name, 3, paths.db);
reuse.file = ref_paths.out_files.project_forcing;
switch config.storm_sampling
    case 'CC'
        reuse.types = {'XC','TC'};
    otherwise
        reuse.types = {config.storm_sampling};
end
reuse.found = config.load_project_forcing == 1 && isfile(reuse.file);
reuse.seed_found = false;
reuse.src = struct('XC', '', 'TC', '');
reuse.ids = struct('XC', {{}}, 'TC', {{}});
reuse.own = false;
reuse.seed_pf = reuse.file;
reuse.label = ['ref_case_name (' config.ref_case_name ')'];
if reuse.found
    [reuse.seed_found, sampled_ids] = read_seed(reuse.file);
    for kk = 1:numel(reuse.types)
        if reuse.seed_found && isfield(sampled_ids, reuse.types{kk})
            reuse.src.(reuse.types{kk}) = 'Reference';
            reuse.ids.(reuse.types{kk}) = sampled_ids.(reuse.types{kk});
        end
    end
elseif isfield(config, 'hotstart_level') && strcmp(config.hotstart_level, 'reuse_sampling')
    [own_found, sampled_ids] = read_seed(config.out_files.project_forcing);
    if own_found
        for kk = 1:numel(reuse.types)
            if isfield(sampled_ids, reuse.types{kk})
                reuse.src.(reuse.types{kk}) = 'Seed';
                reuse.ids.(reuse.types{kk}) = sampled_ids.(reuse.types{kk});
            end
        end
        reuse.seed_pf = config.out_files.project_forcing;
        reuse.label = 'this case''s cached sampling (hotstart)';
    end
end
reuse.reused = cellfun(@(x) ~isempty(reuse.src.(x)), reuse.types);
reuse.own = any(reuse.reused) && ~reuse.found;
reuse.mode = config.lcs_restrict_sampling_rate;
if any(reuse.reused)
    S = load(lcs_sampling_seed_file(reuse.seed_pf), 'lcs_restrict_sampling_rate');
    reuse.mode = S.lcs_restrict_sampling_rate;
end
if reuse.mode == 0
    reuse.check_types = reuse.types(~reuse.reused);
else
    reuse.check_types = {};
end
end

%% AUX FUNCTION: SAMPLING SEED FILE OF A PROJECT FORCING FILE (ok: Holds The Mode And The Sampled Life Cycles)
function [ok, sampled_ids] = read_seed(pf_file)
sampled_ids = struct();
seed_file = lcs_sampling_seed_file(pf_file);
ok = isfile(seed_file) && all(ismember({'lcs_restrict_sampling_rate', 'sampled_ids'}, who('-file', seed_file)));
if ok
    S = load(seed_file, 'sampled_ids');
    sampled_ids = S.sampled_ids;
end
end

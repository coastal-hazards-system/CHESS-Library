classdef LifeCycle < chess.Model
    % LifeCycle  Life-cycle simulation and coastal structure reliability (LCS, workflow 3).
    %   model = chess.Model.create(inputs) returns this class for workflow 3.
    %
    %   The forcing is a set of life cycles: for each one the storms of
    %   mcs_nYears years are sampled from the storm database (XC by record
    %   rate, TC by their probability masses). The responses are computed
    %   over every life cycle. For a rubble mound:
    %     armor_reliability  - Peaks: share of storms the armor withstands
    %     damage_progression - Timeseries: armor damage accumulated row by row,
    %                          with and without repairs
    %
    %   Tools shared with the GUI: reference_reuse, sampling_mode,
    %   convergence_checks, convergence_check, yearly_curve.
    %
    %   See also chess.Model, chess.ProtectionSystem.RubbleMound.

    properties (Constant, Access = protected)
        run_label = 'Coastal Structure Reliability'
    end

    methods
        function obj = LifeCycle(varargin)
            % LifeCycle  Life-cycle model of a ready configuration (see chess.Model.create).
            %   obj = chess.Model.LifeCycle(config, protection_system, storm_database)
            obj@chess.Model(varargin{:});
        end

        function [PF_Summary, Reliab_Summary] = armor_reliability(obj, life_cycles)
            % armor_reliability  Armor reliability of a rubble mound over Peaks life cycles.
            %   [PF_Summary, Reliab_Summary] = model.armor_reliability(life_cycles)
            %   life_cycles: Peaks life cycles of one storm type, nLC x 1 cell
            %   of matrices (chess.Common.lcs_columns; reads SWL, Hm0_toe, Tp
            %   and storm_duration). For every storm the seaside and leeside
            %   stability margins come from the rubble mound
            %   (seaside_stability_margin, leeside_stability_margin); a storm
            %   fails when its margin is negative; a dry toe (depth SWL - toe
            %   elevation <= 0) gives a NaN margin, not a failure. The reliability of a life
            %   cycle is the share of its storms without failure (1 for a life
            %   cycle without storms).
            %   Reliab_Summary / PF_Summary: mean, the project confidence
            %   limits and the standard deviation over the life cycles of the
            %   reliability / probability of failure (Overall, Seaside,
            %   Leeside), tables.
            pse = obj.protection_system;
            % Requested Confidence Limits
            prc = [cellfun(@str2double,strsplit(obj.config.project_CLs(2:end-1),{' '}))];
            Reliab_all = zeros(length(life_cycles),1);
            Reliab_ss = zeros(length(life_cycles),1);
            Reliab_ls = zeros(length(life_cycles),1);
            C = chess.Common.lcs_columns();
            for lcS = 1:length(life_cycles)
                WL = life_cycles{lcS}(:, C.SWL);
                Hm0 = life_cycles{lcS}(:, C.Hm0_toe);
                Tp = life_cycles{lcS}(:, C.Tp);
                storm_duration = life_cycles{lcS}(:, C.storm_duration); % [days]
                % Number Of Storms
                nSim = size(life_cycles{lcS},1);
                % Life Cycle Without Storms: No Failure (Reliability 1)
                if nSim == 0
                    Reliab_ss(lcS,1) = 1;
                    Reliab_ls(lcS,1) = 1;
                    Reliab_all(lcS,1) = 1;
                    continue
                end
                % Seaside Stability Limit State
                G_ss = pse.seaside_stability_margin(Hm0, Tp, WL, storm_duration);
                Reliab_ss(lcS,1) = 1-sum(G_ss<0)/nSim;
                % Leeside Stability Limit State
                G_ls = pse.leeside_stability_margin(Hm0, Tp, WL, storm_duration);
                Reliab_ls(lcS,1) = 1-sum(G_ls<0)/nSim;
                % Overall Stability Limit State
                G_all = min(G_ss,G_ls);
                Reliab_all(lcS,1) = 1-sum(G_all<0)/nSim;
            end
            %% RELIABILITY AVERAGES AND PERCENTILES
            % Define Row Names
            row_names = [{'Mean'}; cellstr([num2str(prc') repmat('%',size(prc',1),1)]); {'Std'}];
            % Compute Overall Mean, Percentiles, Std Reliability
            col1 = num2cell([mean(Reliab_all,1,"omitnan");...
                prctile(Reliab_all,prc)';...
                std(Reliab_all,1,"omitnan")]);
            % Compute Seaside Mean, Percentiles, Std Reliability
            col2 = num2cell([mean(Reliab_ss,1,"omitnan");...
                prctile(Reliab_ss,prc)';...
                std(Reliab_ss,1,"omitnan")]);
            % Compute Leeside Mean, Percentiles, Std Reliability
            col3 = num2cell([mean(Reliab_ls,1,"omitnan");...
                prctile(Reliab_ls,prc)';...
                std(Reliab_ls,1,"omitnan")]);
            % Create Reliability Summary Table
            Reliab_Summary = cell2table([row_names,col1,col2,col3],"VariableNames",{'Row_Name','Overall','Seaside','Leeside'});

            %% PROBABILITY OF FAILURE AVERAGES AND PERCENTILES
            % Seaside Probability Of Failure
            PF_ss = 1-Reliab_ss;
            % Leeside Probability Of Failure
            PF_ls = 1-Reliab_ls;
            % Overall Probability Of Failure
            PF_all = 1- Reliab_all;
            % Compute Overall Mean, Percentiles, Std Reliability
            col1 = num2cell([mean(PF_all,1,"omitnan");...
                prctile(PF_all,prc)';...
                std(PF_all,1,"omitnan")]);
            % Compute Seaside Mean, Percentiles, Std Reliability
            col2 = num2cell([mean(PF_ss,1,"omitnan");...
                prctile(PF_ss,prc)';...
                std(PF_ss,1,"omitnan")]);
            % Compute Leeside Mean, Percentiles, Std Reliability
            col3 = num2cell([mean(PF_ls,1,"omitnan");...
                prctile(PF_ls,prc)';...
                std(PF_ls,1,"omitnan")]);
            % Create Reliability Summary Table
            PF_Summary = cell2table([row_names,col1,col2,col3],"VariableNames",{'Row_Name','Overall','Seaside','Leeside'});
        end

        function results = damage_progression(obj, life_cycles)
            % damage_progression  Armor damage progression of a rubble mound over Timeseries life cycles.
            %   results = model.damage_progression(life_cycles)
            %   life_cycles: Timeseries life cycles of one storm type, nLC x 1
            %   cell of matrices (chess.Common.lcs_columns; reads year, SWL,
            %   Hm0_toe, Tp, dt and step). The seaside and leeside damage are
            %   accumulated row by row with the rubble mound
            %   (seaside_armor_damage, leeside_armor_damage), without and with
            %   repairs. Repairs (config csr_apply_structure_repair: 0 none,
            %   1 above the service limit, 2 above the ultimate limit, 3
            %   either): when the damage of the previous row exceeds the
            %   limit, the rest of that storm is NaN and the damage restarts
            %   at 0 at the next storm. csr_apply_cutoff_correction /
            %   csr_cutoff_offset raise the crest used by the submergence
            %   check of the damage equations.
            %   results: struct with the damage series (S_seaside_no_repairs,
            %   S_leeside_no_repairs, S_seaside_with_repairs,
            %   S_leeside_with_repairs), Seaside_Repair_Indexes,
            %   Leeside_Repair_Indexes, stats (final damage), Repairs_Stats or
            %   the repair counts, Reliability_Seaside, Reliability_Leeside,
            %   the yearly curves (Smax, LSmax, SPcurves, LSPcurves) and
            %   diagnostics (one table per life cycle). The percentiles of
            %   stats, Repairs_Stats and the yearly curves are those of
            %   config.project_CLs (as given, e.g. '[16 84]').
            disp('   Running CHESS: Coastal Structure Reliability - Damage Progression Analysis....');
            fprintf(1,'      Completion Progress: %3d%%\n',0);
            config = obj.config;
            pse = obj.protection_system;
            % Limits And Run Settings
            settings = struct('repair_switch', config.csr_apply_structure_repair, 'nYears', config.mcs_nYears,...
                'seaside_S_SLS', pse.seaside_design_S, 'leeside_S_SLS', pse.leeside_design_S,...
                'seaside_S_ULS', pse.seaside_S_uls, 'leeside_S_ULS', pse.leeside_S_uls,...
                'percentiles', cellfun(@str2double, strsplit(config.project_CLs(2:end-1), {' '})));
            % Cutoff Correction: [] = Off, Else The Offset [m]
            cutoff_offset = [];
            if config.csr_apply_cutoff_correction ~= 0
                cutoff_offset = config.csr_cutoff_offset;
            end
            nLC = length(life_cycles);

            %% FORCING PER LIFE CYCLE (ONE CELL PER LIFE CYCLE)
            C = chess.Common.lcs_columns();
            forcing.WL = cellfun(@(x) x(:, C.SWL), life_cycles, 'un', false);
            forcing.Hm0 = cellfun(@(x) x(:, C.Hm0_toe), life_cycles, 'un', false);
            forcing.Tp = cellfun(@(x) x(:, C.Tp), life_cycles, 'un', false);
            forcing.dt = cellfun(@(x) x(:, C.dt), life_cycles, 'un', false); % Row Time Step [days]
            forcing.step = cellfun(@(x) x(:, C.step), life_cycles, 'un', false); % 0 At The First Row Of Each Storm
            % Reported In The Diagnostics
            forcing.h = cellfun(@(x) x - pse.toe_elevation, forcing.WL, 'un', false);
            forcing.Rc = cellfun(@(x) pse.crest_elevation - x, forcing.WL, 'un', false);
            forcing.Nz = cellfun(@(dt, tp) chess.Common.chess_units('convert', dt, 'day', 's')./chess.BoundaryConditions.waves.period_from_peak(tp, 'mean'), forcing.dt, forcing.Tp, 'un', false);
            [forcing.z1p, forcing.u1p] = cellfun(@(hm0, tp, swl) pse.leeside_crest_velocity(hm0, tp, swl),...
                forcing.Hm0, forcing.Tp, forcing.WL, 'un', false);

            %% DAMAGE PROGRESSION OVER EACH LIFE CYCLE
            damage = struct('Szero_no_repairs', {cell(nLC, 1)}, 'seaside_no_repairs', {cell(nLC, 1)},...
                'Szero_with_repairs', {cell(nLC, 1)}, 'seaside_with_repairs', {cell(nLC, 1)},...
                'leeside_with_repairs', {cell(nLC, 1)}, 'leeside_no_repairs', {cell(nLC, 1)});
            Seaside_Repair_Indexes = {};
            Leeside_Repair_Indexes = {};
            for life_cycle_index = 1:nLC
                rows = structfun(@(x) x{life_cycle_index}, forcing, 'UniformOutput', false);
                % Seaside, With And Without Repairs
                [damage.seaside_with_repairs{life_cycle_index}, damage.Szero_with_repairs{life_cycle_index}, repair_seaside] = ...
                    obj.seaside_damage_series(rows, true, settings, cutoff_offset);
                [damage.seaside_no_repairs{life_cycle_index}, damage.Szero_no_repairs{life_cycle_index}] = ...
                    obj.seaside_damage_series(rows, false, settings, cutoff_offset);
                % Run-up Reported In The Diagnostics (The Damage Series Do Not Read It)
                forcing.z1p{life_cycle_index}(rows.Hm0<0.1 | rows.Tp<0 | rows.Rc<0) = 0; % [m] 0.1 m
                % Leeside, With And Without Repairs
                [damage.leeside_with_repairs{life_cycle_index}, damage.leeside_no_repairs{life_cycle_index},...
                    forcing.u1p{life_cycle_index}, repair_leeside] = obj.leeside_damage_series(rows, settings, cutoff_offset);
                % Store Repair Indexes (If Any)
                if ~isempty(repair_leeside)
                    Leeside_Repair_Indexes = [Leeside_Repair_Indexes;[{repair_leeside}, {life_cycle_index}]]; %#ok<AGROW>
                end
                if ~isempty(repair_seaside)
                    Seaside_Repair_Indexes = [Seaside_Repair_Indexes;[{repair_seaside}, {life_cycle_index}]]; %#ok<AGROW>
                end
                fprintf(1,'\b\b\b\b%3.0f%%',(100*(life_cycle_index/nLC)));
            end
            disp([newline '      Computing Post Damage Statistics....']);

            %% POST DAMAGE STATISTICS
            statistics = final_damage_statistics(life_cycles, damage, settings.nYears, settings.percentiles);
            diagnostics = diagnostics_tables(forcing, damage, nLC);
            repairs = repair_statistics(settings, damage, Seaside_Repair_Indexes, Leeside_Repair_Indexes);
            reliability = structure_reliability(settings.repair_switch, repairs, Seaside_Repair_Indexes, Leeside_Repair_Indexes, nLC);
            results = damage_progression_output(settings.repair_switch, damage, Seaside_Repair_Indexes,...
                Leeside_Repair_Indexes, statistics, repairs, reliability, diagnostics);
        end
    end

    methods (Static)
        function reuse = reference_reuse(config)
        % reference_reuse  Decide which LCS storm types reuse a sampling seed.
        %   reuse = chess.Model.LifeCycle.reference_reuse(config)
        %
        %   Decides, before LCS sampling, which storm types are reused from the
        %   reference case (load_project_forcing = 1, ref_case_name), the sampling
        %   mode the life cycles end up with, and the storm types that get the
        %   convergence check. Shared by chess.Model.LifeCycle and the GUI (convergence
        %   dialog) so both apply the same rule:
        %     - A storm type is reused only when the reference project forcing
        %       file exists AND the reference's sampling seed file holds the
        %       sampling mode (lcs_restrict_sampling_rate) and that storm type's
        %       sampled life cycles (sampled_ids). A reference without a usable
        %       seed file reuses nothing: its storm types are sampled fresh, as if
        %       load_project_forcing = 0 (seed_found = false; chess.Model.LifeCycle warns).
        %     - Reused storms were sampled under the mode stored in the seed file,
        %       which then becomes the effective mode. Otherwise the configured
        %       lcs_restrict_sampling_rate is the effective mode.
        %     - The convergence check runs only in effective mode 0, for the storm
        %       types that are sampled fresh.
        %     - Hotstart level 'reuse_sampling' (config.hotstart_level, set by
        %       chess.Hotstart.resolve): when no reference is used, this case's
        %       own cached sampling is reused instead (its sampling seed file:
        %       sampled_ids, mode and, with use_peaks = 1, raw XC peaks), the same
        %       way as a reference.
        %   Prints nothing: chess.Model.LifeCycle reports the outcome.
        %
        %   Inputs:
        %     config - CHESS configuration (load_project_forcing, ref_case_name,
        %              outfolder, project_name, struc_id, case_name, workflow,
        %              storm_db or region/sp_ID (chess.ProjectPaths.build), storm_sampling,
        %              lcs_restrict_sampling_rate; optional hotstart_level,
        %              out_files.project_forcing), 1x1 struct
        %   Outputs:
        %     reuse - 1x1 struct with fields:
        %       file        - reference project forcing file, char
        %       found       - load_project_forcing = 1 and the reference file
        %                     exists, logical
        %       seed_found  - found and the reference's sampling seed file holds
        %                     lcs_restrict_sampling_rate and sampled_ids, logical
        %       types       - storm types to sample, in sampling order ('CC' ->
        %                     {'XC','TC'}), cell
        %       src         - seed source per storm type (fields XC, TC):
        %                     'Reference' (reference's sampling seed file), 'Seed'
        %                     (own sampling seed file) or '' (not reused, sampled
        %                     fresh), struct
        %       ids         - reused life-cycle identity columns per storm type
        %                     (fields XC, TC): nLC x 1 cell of [storm_ID,
        %                     intensity_bin, Sim_Year, order], struct
        %       own         - the reused storms are this case's own cached
        %                     sampling, logical
        %       seed_pf     - project forcing file whose sampling seed file holds
        %                     the reused mode and raw XC peaks (reference or own),
        %                     char
        %       label       - source description for messages, char
        %       reused      - reused flag per element of types, logical
        %       mode        - effective sampling mode (0 = Full Poisson, 1 = Rate
        %                     Matched), double
        %       check_types - storm types that get the convergence check, cell
        %
        %   See also chess.Model.LifeCycle, chess.ProjectPaths.sampling_seed_file, chess.Model.LifeCycle.convergence_checks,
        %   chess.ProjectPaths.build, chess.Hotstart.resolve.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        % Reference Case: Same Project/PSE, Alternative ref_case_name, LCS, Same Storm DB As This Run (chess.ProjectPaths.build)
        paths = chess.ProjectPaths.build(config);
        ref_paths = chess.ProjectPaths.build(config.outfolder, config.project_name, config.struc_id, config.ref_case_name, 3, paths.db);
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
            S = load(chess.ProjectPaths.sampling_seed_file(reuse.seed_pf), 'lcs_restrict_sampling_rate');
            reuse.mode = S.lcs_restrict_sampling_rate;
        end
        if reuse.mode == 0
            reuse.check_types = reuse.types(~reuse.reused);
        else
            reuse.check_types = {};
        end
        end

        function mode = sampling_mode(config)
        % sampling_mode  Effective LCS sampling mode of a run.
        %   mode = chess.Model.LifeCycle.sampling_mode(config)
        %
        %   LCS sampling mode the life cycles were actually sampled with
        %   (0 = Full Poisson, 1 = Rate Matched): lcs_effective_sampling_rate,
        %   set by chess.Model.LifeCycle (it differs from the configured mode when the storms
        %   are reused from a reference case sampled under the other mode), when
        %   present and not empty; else the configured lcs_restrict_sampling_rate.
        %
        %   Inputs:
        %     config - CHESS configuration, 1x1 struct
        %   Outputs:
        %     mode - effective sampling mode (0 or 1), double
        %
        %   See also chess.Model.LifeCycle, chess.Model.LifeCycle.reference_reuse.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        if isfield(config, 'lcs_effective_sampling_rate') && ~isempty(config.lcs_effective_sampling_rate)
            mode = config.lcs_effective_sampling_rate;
        else
            mode = config.lcs_restrict_sampling_rate;
        end
        end

        function checks = convergence_checks(config, prob_mass, stm_types, quiet)
        % convergence_checks  Run the LCS convergence check per storm type.
        %   checks = chess.Model.LifeCycle.convergence_checks(config, prob_mass)
        %   checks = chess.Model.LifeCycle.convergence_checks(config, prob_mass, stm_types)
        %   checks = chess.Model.LifeCycle.convergence_checks(..., quiet)
        %
        %   Runs chess.Model.LifeCycle.convergence_check for each storm type to be sampled with full
        %   Poisson LCS sampling, using the run configuration. Shared by chess.Model.LifeCycle
        %   (before sampling) and the GUI (convergence dialog before an LCS run).
        %   Storm rates: XC -> Nstm_XC/Nyrs_XC, TC -> prob_mass.TC_SRR(end).
        %   Storm types with a rate <= 0 are skipped (chess.Model.LifeCycle stops on them).
        %
        %   Inputs:
        %     config    - CHESS configuration (mcs_nYears, mcs_nLC,
        %                 lcs_convergence_tol, lcs_convergence_confidence,
        %                 project_CLs (char, e.g. '[16 84]'), storm_sampling,
        %                 Nstm_XC, Nyrs_XC), 1x1 struct
        %     prob_mass - CHS probability masses (TC_SRR [storms/yr]); unused for
        %                 XC, struct or []
        %     stm_types - (optional, default from storm_sampling, 'CC' ->
        %                 {'XC','TC'}; [] = default) storm types to check, cell
        %     quiet     - (optional, default false) true: no printed reports,
        %                 logical
        %   Outputs:
        %     checks - one element per checked storm type: the
        %              chess.Model.LifeCycle.convergence_check outputs plus stm_type and rate
        %              [storms/yr]; struct([]) when nothing is checked, 1 x n
        %              struct
        %
        %   See also chess.Model.LifeCycle.convergence_check, chess.Model.LifeCycle.reference_reuse, chess.Model.LifeCycle.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        if nargin < 3 || isempty(stm_types)
            if strcmp(config.storm_sampling, 'CC')
                stm_types = {'XC','TC'};
            else
                stm_types = {config.storm_sampling};
            end
        end
        if nargin < 4
            quiet = false;
        end
        prc = cellfun(@str2double, strsplit(config.project_CLs(2:end-1), {' '}));
        checks = struct([]);
        for kk = 1:numel(stm_types)
            switch stm_types{kk}
                case 'XC'
                    rate = config.Nstm_XC/config.Nyrs_XC;
                case 'TC'
                    rate = prob_mass.TC_SRR(end);
            end
            if ~(rate > 0)
                continue
            end
            res = chess.Model.LifeCycle.convergence_check(rate, config.mcs_nYears, config.mcs_nLC, config.lcs_convergence_tol,...
                config.lcs_convergence_confidence, prc, stm_types{kk}, quiet);
            res.stm_type = stm_types{kk};
            res.rate = rate;
            if isempty(checks)
                checks = res;
            else
                checks(end+1) = res; %#ok<AGROW>
            end
        end
        end

        function res = convergence_check(lambda, N, nLC, tol, c, p, stm_type, quiet)
        % convergence_check  Life cycles needed for converged LCS storm counts.
        %   res = chess.Model.LifeCycle.convergence_check(lambda, N, nLC, tol, c, p, stm_type)
        %   res = chess.Model.LifeCycle.convergence_check(..., quiet)
        %
        %   Estimates how many life cycles a full Poisson LCS
        %   (lcs_restrict_sampling_rate = 0) needs so the life-cycle storm count
        %   statistics are converged, and prints a short report. The storm count
        %   of a life cycle is Poisson(lambda*N). Two requirements, the largest
        %   governs:
        %     - Mean: relative half-width of the c-confidence interval of the mean
        %       storm count <= tol -> nLC_mean = ceil((z/tol)^2 / (lambda*N)),
        %       z = norminv((1+c)/2).
        %     - Percentiles: smallest candidate nLC (25*2^k, up to 102400) whose
        %       sample percentiles (prctile, MATLAB default) are within
        %       max(1, tol*x_p) storms of the exact Poisson percentile x_p in a
        %       fraction c of 1000 repeats.
        %   Percentiles below the storm-free share exp(-lambda*N) are 0 storms
        %   (reported only). The random draws of this check do not affect the
        %   LCS: the global random number generator state is restored on exit
        %   (also on error).
        %
        %   Inputs:
        %     lambda   - storm rate [storms/yr], scalar double
        %     N        - life-cycle length, mcs_nYears [years], scalar double
        %     nLC      - number of life cycles, mcs_nLC, scalar double
        %     tol      - relative tolerance, lcs_convergence_tol [-], scalar double
        %     c        - confidence level, lcs_convergence_confidence [-], scalar
        %                double
        %     p        - percentile levels [%], from project_CLs (e.g. [16 84]),
        %                double vector
        %     stm_type - storm type label for the report ('XC', 'TC'), char
        %     quiet    - (optional, default false) true: no printed report (e.g.
        %                plots and the GUI dialog), logical
        %   Outputs:
        %     res - lamN (lambda*N), cv (1/sqrt(lamN)), p0 (storm-free share
        %           exp(-lamN)), zero_pct (levels of p below p0, as fractions),
        %           nLC_mean, nLC_pct (Inf above the cap), nLC_req (largest of
        %           both), nLC, converged (nLC >= nLC_req) and nLC_cap (102400),
        %           1x1 struct
        %
        %   See also chess.Model.LifeCycle.convergence_checks, chess.Model.LifeCycle.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        if nargin < 8
            quiet = false;
        end
        s = rng;
        restore_rng = onCleanup(@() rng(s));

        R = 1000;           % Repeats Per Candidate
        nLC_cap = 102400;   % Largest Candidate
        max_draws = 1e7;    % Poisson Draws Per Chunk (Memory)

        p = p(:)/100;
        lamN = lambda*N;
        res.lamN = lamN;
        res.cv = 1/sqrt(lamN);
        res.p0 = exp(-lamN);
        res.zero_pct = p(res.p0 > p)';

        %% MEAN STORM COUNT
        z = norminv((1 + c)/2);
        res.nLC_mean = ceil((z/tol)^2/lamN);

        %% PERCENTILES OF THE STORM COUNT
        x_p = poissinv(p, lamN);
        allowed = max(1, tol*x_p);
        res.nLC_pct = Inf;
        for n = 25*2.^(0:floor(log2(nLC_cap/25)))
            est = zeros(numel(p), R);
            chunk = max(1, min(R, floor(max_draws/n)));
            for r0 = 1:chunk:R
                r = r0:min(R, r0 + chunk - 1);
                est(:, r) = prctile(poissrnd(lamN, n, numel(r)), 100*p, 1);
            end
            e = sort(abs(est - x_p), 2);
            if all(e(:, ceil(c*R)) <= allowed)
                res.nLC_pct = n;
                break
            end
        end
        res.nLC_req = max(res.nLC_mean, res.nLC_pct);
        res.nLC = nLC;
        res.converged = nLC >= res.nLC_req;
        res.nLC_cap = nLC_cap;

        %% REPORT
        if quiet
            return
        end
        fprintf('   LCS convergence check (%s, full Poisson sampling):\n', stm_type);
        fprintf('      Expected storms per life cycle (lambda x mcs_nYears): %.3f (CV %.3f)\n', lamN, res.cv);
        fprintf('      Storm-free life cycles: %.1f%%\n', 100*res.p0);
        if ~isempty(res.zero_pct)
            fprintf('      Percentile(s) %s are 0 storms (below the storm-free share)\n', mat2str(100*res.zero_pct));
        end
        if isinf(res.nLC_pct)
            pct_txt = sprintf('> %d', nLC_cap);
        else
            pct_txt = sprintf('%d', res.nLC_pct);
        end
        fprintf('      Life cycles needed: mean %d, percentiles %s -> required %s (tol %g, confidence %g)\n',...
            res.nLC_mean, pct_txt, num2str(res.nLC_req), tol, c);
        if res.converged
            fprintf('      mcs_nLC = %d: converged\n', nLC);
        else
            fprintf('      mcs_nLC = %d: NOT converged\n', nLC);
        end
        end

        function [Smax,SPcurves,yBox] = yearly_curve(data, resp_vec, nYears, p)
        % yearly_curve  Yearly mean and percentiles of LCS storm maxima.
        %   [Smax, SPcurves, yBox] = chess.Model.LifeCycle.yearly_curve(data, resp_vec,
        %       nYears)
        %   [Smax, SPcurves, yBox] = chess.Model.LifeCycle.yearly_curve(data, resp_vec,
        %       nYears, p)
        %
        %   Takes the maximum of the response over each storm of every life cycle
        %   (Timeseries: from a row with step 0 to the row before the next storm;
        %   Peaks: one row per storm) and the storm's year. For each year
        %   1..nYears the storm maxima of that year are pooled over all life
        %   cycles: Smax is their mean (NaN omitted) and SPcurves their
        %   percentiles p (prctile); a year without storms in any life
        %   cycle gives NaN. Smax is the mean of the storm maxima of the year, not
        %   of the yearly maxima of each life cycle.
        %
        %   Inputs:
        %     data     - life cycles, nLC x 1 cell of Peaks (nStorms x 10) or
        %                Timeseries (nRows x 12) matrices (chess.Common.lcs_columns; reads year
        %                and, for Timeseries, step)
        %     resp_vec - response per row, nLC x 1 cell of column vectors (rows of
        %                data)
        %     nYears   - number of years per life cycle (mcs_nYears), scalar
        %     p        - percentiles [%], vector (optional, default [] = no
        %                percentile curves)
        %   Outputs:
        %     Smax     - yearly mean of the storm maxima, nYears x 1 double
        %     SPcurves - yearly percentiles p, nYears x numel(p) double (one
        %                column per percentile)
        %     yBox     - storm maxima of each year, nYears x 1 cell of column
        %                vectors
        %
        %   See also chess.Model.LifeCycle.damage_progression, lcs_methods, chess.Common.lcs_columns.

        if nargin < 4
            p = [];
        end
        p = reshape(p, 1, []);
        num_LCs = length(data);
        % Life-Cycle Column Map
        C = chess.Common.lcs_columns();

        % Preallocate cells to hold the year and max response for EVERY storm
        all_storm_years = cell(num_LCs, 1);
        all_storm_max = cell(num_LCs, 1);

        %% STEP 1: Process all Life Cycles (LCs) once
        for ii = 1:num_LCs
            lc_data = data{ii};
            lc_resp = resp_vec{ii};

            % 1. Get Storm Hydrograph Boundaries (Start and End indices)
            if size(lc_data, 2) == C.n_timeseries
                % Find where the step counter is 0 (Start of a storm)
                stm_beg = find(lc_data(:, C.step) == 0);

                % Calculate the end index of each storm
                % (The step before the next storm begins, and the final array index)
                stm_end = [stm_beg(2:end) - 1; size(lc_data, 1)];
            else
                % Peaks Layout: Treat Every Row As A 1-Step Event
                stm_beg = (1:size(lc_data, 1)).';
                stm_end = stm_beg;
            end

            % 2. Extract the occurrence year for each storm
            storm_years = lc_data(stm_beg, C.year);

            % 3. Calculate the maximum response for each individual storm
            num_storms = length(stm_beg);
            storm_max = zeros(num_storms, 1); % Preallocate for speed

            for k = 1:num_storms
                % Extract the data slice for this specific storm and find the peak
                storm_max(k) = max(lc_resp(stm_beg(k) : stm_end(k)));
            end

            % Store the years and max responses for this LC
            all_storm_years{ii} = storm_years;
            all_storm_max{ii} = storm_max;
        end

        %% STEP 2: Flatten data across all LCs
        % Combine all LCs into two large column vectors for rapid filtering
        all_storm_years = vertcat(all_storm_years{:});
        all_storm_max = vertcat(all_storm_max{:});

        %% STEP 3: Group by Year and Calculate Statistics
        years = 1:nYears;
        yBox = cell(nYears, 1);
        Smax = zeros(nYears, 1);
        SPcurves = zeros(nYears, numel(p));

        for jj = 1:nYears
            % Find all storms that occurred in this specific year across ALL life cycles
            yr_mask = (all_storm_years == years(jj));

            % Extract their maximum responses
            yr_data = all_storm_max(yr_mask);

            % Store in the output bin
            yBox{jj} = yr_data;

            % Calculate statistical curves (handle empty years to prevent errors)
            if ~isempty(yr_data)
                Smax(jj) = mean(yr_data, 'omitnan');
                if ~isempty(p)
                    SPcurves(jj, :) = prctile(yr_data, p);
                end
            else
                % Fallback if a year had absolutely zero storms across all LCs
                Smax(jj) = NaN;
                SPcurves(jj, :) = NaN(1, numel(p));
            end
        end
        end
    end

    methods (Static)
        function rules = workflow_input_rules()
            % workflow_input_rules  Inputs only LCS needs (chess.Model.input_rules).
            %   The damage progression inputs (csr_*) are required only when
            %   csr_call_dpa is 1; the hidden sampling settings (lcs_*) are
            %   optional (defaults in chess.Config.apply_rules).
            rules = [...
                chess.Config.input_rule('mcs_nLC', 'integer', 'minimum', 1),...
                chess.Config.input_rule('mcs_nYears', 'integer', 'minimum', 1),...
                chess.Config.input_rule('load_project_forcing', 'switch'),...
                chess.Config.input_rule('ref_case_name', 'text', 'required_if', 'load_project_forcing'),...
                chess.Config.input_rule('csr_call_dpa', 'switch', 'optional', true),...
                chess.Config.input_rule('csr_apply_structure_repair', 'choice', 'choices', [0 1 2 3], 'required_if', 'csr_call_dpa'),...
                chess.Config.input_rule('csr_apply_cutoff_correction', 'switch', 'required_if', 'csr_call_dpa'),...
                chess.Config.input_rule('csr_cutoff_offset', 'number', 'minimum', 0, 'required_if', 'csr_call_dpa', 'unit_kind', 'length'),...
                chess.Config.input_rule('lcs_restrict_sampling_rate', 'switch', 'optional', true),...
                chess.Config.input_rule('lcs_convergence_tol', 'number', 'exclusive_minimum', 0, 'optional', true),...
                chess.Config.input_rule('lcs_convergence_confidence', 'number', 'exclusive_minimum', 0, 'maximum', 1, 'optional', true),...
                chess.Config.input_rule('lcs_convergence_prompt', 'switch', 'optional', true)];
        end
    end

    methods (Access = protected)
        function project_forcing = build_storm_forcing(obj, storm, prob_mass)
            % Monte Carlo storm sampling: one matrix of sampled storms per life cycle
            %   The sampling of a reference case (load_project_forcing = 1) or
            %   of this case's saved run (hotstart 'reuse_sampling') is reused
            %   when available. The sampled life cycles are written to the
            %   sampling seed file. config gets lcs_effective_sampling_rate
            %   and lcs_convergence_results.
            config = obj.config;
            %% GRAB INPUT FROM "config"
            settings = read_life_cycle_settings(config);
            storm_sampling = settings.storm_sampling;

            % Command Prompts
            disp('   Running CHESS: Monte Carlo Simulation (Storm Sampling)....');

            %% REFERENCE CASE SAMPLING SEED (load_project_forcing = 1) OR OWN CACHED SAMPLING (hotstart_level 'reuse_sampling')
            % Storm Types Reused, Effective Sampling Mode And Convergence-Check Storm Types (Shared With The GUI)
            reuse = chess.Model.LifeCycle.reference_reuse(config);
            [config, lcs_mode] = report_reuse_and_clear_tides(config, reuse);

            %% SAMPLING MODE CHECKS (BEFORE SAMPLING)
            config = check_life_cycle_sampling(config, prob_mass, reuse, settings, lcs_mode);

            %% LIFE-CYCLE COLUMN MAP
            C = chess.Common.lcs_columns();
            C_ts = chess.Common.lcs_columns('Timeseries');

            %% DEFINE ADDITIONAL VARIABLES
            % Initialize Life Cycle Storage Vars (Peaks Only With use_peaks = 1)
            project_forcing = empty_life_cycle_storage(storm_sampling, settings.number_of_life_cycles, settings.use_peaks);
            % Sampled Storms Per Storm Type (Sampling Seed File)
            sampled_xc = [];
            sampled_tc = [];

            %% CYCLE THROUGH LIFE CYCLES
            %% SAMPLE EXTRATROPICAL STORMS
            if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'XC')==1
                [project_forcing, sampled_xc] = sample_extratropical_life_cycles(project_forcing, storm, config, reuse, settings, lcs_mode, C, C_ts);
            end

            %% SAMPLE TROPICAL CYCLONES
            if strcmp(storm_sampling,'CC')==1 || strcmp(storm_sampling,'TC')==1
                [project_forcing, sampled_tc] = sample_tropical_life_cycles(project_forcing, storm, prob_mass, config, reuse, settings, lcs_mode, C, C_ts);
            end

            %% COMBINE TROPICAL AND EXTRATROPICAL SAMPLED STORMS
            if strcmp(storm_sampling,'CC')==1
                project_forcing = combine_storm_type_life_cycles(project_forcing, config, settings, C);
            end
            disp(newline);

            %% REMOVE ADDITIONAL FIELDS (IF NEEDED)
            project_forcing = remove_unrequested_alternate_datasets(project_forcing, settings);

            %% SAVE SAMPLING SEED FILE (SAMPLING MODE, SAMPLED LIFE CYCLES & RAW XC PEAKS WITH use_peaks = 1)
            save_sampling_seed(config, lcs_mode, sampled_xc, sampled_tc, project_forcing);
            obj.config = config;
        end

        function Resp = dataset_responses(obj, project_forcing, data_type, dataset_name) %#ok<INUSD>
            % Responses of one life-cycle dataset; rubble mound: armor reliability (Peaks) or damage progression (Timeseries)
            config = obj.config;
            % Overtopping Volume (Q_vol) Is Timeseries Only
            if strcmp(data_type, 'Peaks')
                config.compute_q_vol = 0;
            end
            storm_type = fieldnames(project_forcing);
            for ii = 1:length(storm_type)
                Resp.(storm_type{ii}) = obj.hydraulic_responses(config, project_forcing.(storm_type{ii}), 0);
                % Rubblemound Only
                if obj.protection_system.structure_type == 3
                    switch data_type
                        case 'Peaks'
                            [Resp.(storm_type{ii}).('PF_Summary'), Resp.(storm_type{ii}).('Reliab_Summary')] = ...
                                obj.armor_reliability(project_forcing.(storm_type{ii}));
                        case 'Timeseries'
                            % Limited To One Storm Type
                            if config.csr_call_dpa == 1 && strcmp(storm_type{ii}, config.storm_sampling)
                                Resp.(storm_type{ii}).S = obj.damage_progression(project_forcing.(storm_type{ii}));
                            end
                    end
                end
            end
        end

        function announce_run(obj)
            if chess.Model.LifeCycle.sampling_mode(obj.config) == 1
                disp(['Notice: LCS sampling is rate restricted (lcs_restrict_sampling_rate = 1): each life cycle holds lambda x mcs_nYears +/- 1 storms ',...
                    'and no convergence check is run. Life-cycle percentiles are conditional on rate-matched storm counts: they include storm ',...
                    'selection, intensity and timing variability, but not storm-count variability.']);
            end
        end

        function config = note_saved_forcing(obj, config, forcing_file) %#ok<INUSL>
            % Sampling mode the saved life cycles were sampled with (sampling seed file)
            seed_file = chess.ProjectPaths.sampling_seed_file(forcing_file);
            if isfile(seed_file)
                S = load(seed_file, 'lcs_restrict_sampling_rate');
                config.lcs_effective_sampling_rate = S.lcs_restrict_sampling_rate;
                % Saved Config Carries It Too (Plots Read The Saved Config)
                save(config.out_files.config, 'config', '-append');
            end
        end
    end

    methods (Access = private)
        function [seaside_damage, Szero, repair_rows] = seaside_damage_series(obj, rows, apply_repairs, settings, cutoff_offset)
            % Seaside damage over the rows of one life cycle, with or without repairs
            %   The damage initiation coefficient is used until the end of the
            %   first damaging storm, the progression coefficient afterwards.
            pse = obj.protection_system;
            n_steps = numel(rows.step);
            seaside_damage = zeros(n_steps,1);
            Szero = zeros(n_steps,1);
            damage_last = 0;
            storm_end = 0;
            repair_rows = [];
            on_first_damaging_storm = 0; % The First Damaging Storm Has Not Been Triggered Yet
            has_damage = 0;
            for time_step = 1:n_steps
                [damage_initiation, on_first_damaging_storm] = in_first_damaging_storm(has_damage, on_first_damaging_storm, rows.step, time_step);
                repair_now = apply_repairs && repair_condition(settings.repair_switch, settings.seaside_S_SLS, settings.seaside_S_ULS, damage_last);
                if repair_now && settings.repair_switch > 0
                    % Store The Row Where The Limit Was Exceeded
                    if storm_end == 0
                        storm_end = find_storm_end(rows.step, time_step);
                        repair_rows = [repair_rows;time_step-1]; %#ok<AGROW>
                    end
                    % The Rest Of The Storm Is NaN
                    Szero(time_step) = NaN(1,1);
                    seaside_damage(time_step) = NaN(1,1);
                    % End Of The Storm: The Damage Restarts At 0
                    if time_step == storm_end
                        damage_last = 0;
                        storm_end = 0;
                        has_damage = 0;
                    end
                else
                    [damage_value, Szero_value] = pse.seaside_armor_damage(rows.Hm0(time_step), rows.Tp(time_step), rows.WL(time_step),...
                        rows.dt(time_step), damage_last, damage_initiation, cutoff_offset);
                    seaside_damage(time_step) = damage_value;
                    Szero(time_step) = Szero_value;
                    % Initial Damage
                    if damage_last == 0 && damage_value > 0
                        has_damage = 1;
                        on_first_damaging_storm = 1;
                    end
                    damage_last = damage_value;
                end
            end
        end

        function [leeside_with_repairs, leeside_no_repairs, u1p, repair_rows] = leeside_damage_series(obj, rows, settings, cutoff_offset)
            % Leeside damage over the rows of one life cycle, with and without repairs
            %   Both tracks use the crest velocity of the no-repairs track at
            %   the previous row, so they share one loop.
            pse = obj.protection_system;
            n_steps = numel(rows.step);
            leeside_with_repairs = zeros(n_steps,1);
            leeside_no_repairs = zeros(n_steps,1);
            u1p = rows.u1p;
            with_repairs_last = 0;
            no_repairs_last = 0;
            u1p_last = 0;
            storm_end = 0;
            repair_rows = [];
            for time_step = 1:n_steps
                %% WITH REPAIRS
                repair_now = repair_condition(settings.repair_switch, settings.leeside_S_SLS, settings.leeside_S_ULS, with_repairs_last);
                if repair_now && settings.repair_switch > 0
                    if storm_end == 0
                        storm_end = find_storm_end(rows.step, time_step);
                        repair_rows = [repair_rows;time_step-1]; %#ok<AGROW>
                    end
                    leeside_with_repairs(time_step) = NaN(1,1);
                    if time_step == storm_end
                        with_repairs_last = 0;
                        storm_end = 0;
                    end
                else
                    damage_value = pse.leeside_armor_damage(rows.Hm0(time_step), rows.Tp(time_step), rows.WL(time_step),...
                        rows.dt(time_step), with_repairs_last, u1p_last, cutoff_offset);
                    leeside_with_repairs(time_step) = damage_value;
                    with_repairs_last = damage_value;
                end
                %% NO REPAIRS
                [damage_value, u1p_value] = pse.leeside_armor_damage(rows.Hm0(time_step), rows.Tp(time_step), rows.WL(time_step),...
                    rows.dt(time_step), no_repairs_last, u1p_last, cutoff_offset);
                leeside_no_repairs(time_step) = damage_value;
                u1p(time_step) = u1p_value;
                u1p_last = u1p_value;
                no_repairs_last = damage_value;
            end
        end
    end

    methods (Static, Access = ?matlab.unittest.TestCase) % Internal Steps: Private To The Class, Open To Unit Tests
        function [sample_storms, lcs_data] = sample_tropical_storms(storm_peaks, simulation_years, prob_mass, restrict_rate, storm_duration_days)
        % sample_tropical_storms  Sample one LCS life cycle of tropical cyclones (TC).
        %   sample_storms = chess.Model.LifeCycle.sample_tropical_storms(storm_peaks, simulation_years,
        %       prob_mass, restrict_rate, storm_duration_days)
        %   [sample_storms, lcs_data] = chess.Model.LifeCycle.sample_tropical_storms(storm_peaks,
        %       simulation_years, prob_mass, restrict_rate, storm_duration_days)
        %
        %   Draws the number of TC storms of each simulation year from a Poisson
        %   distribution with the total TC recurrence rate prob_mass.TC_SRR(end).
        %   restrict_rate = 1 redraws the yearly counts until the life-cycle storm
        %   rate is within 1/simulation_years of that rate (1e-4 for 1e5 years),
        %   i.e. +/- 1 storm per life cycle, up to 1e6 draws (then a warning, the
        %   last draw is kept); restrict_rate = 0 keeps the first draw (a life
        %   cycle can hold no storms). For each storm an intensity bin (1 low,
        %   2 mid, 3 high) is drawn with probability
        %   TC_SRR(1:3)/sum(TC_SRR(1:3)), redrawn when the bin has no storm in
        %   storm_peaks, then a storm ID of that bin (smpl1, smpl2 or smpl3,
        %   restricted to the IDs in storm_peaks(:, 1)) weighted by TC_Freq.
        %   With two outputs the peak values are the database values of the
        %   sampled storms (storm_peaks rows). With one output only the storm IDs
        %   are drawn (chess.Model.LifeCycle with use_peaks = 0 passes the Timeseries storm
        %   IDs as storm_peaks). Errors when TC_SRR(end) is not a finite,
        %   non-negative scalar, or when no bin with a positive rate has storms.
        %
        %   Inputs:
        %     storm_peaks         - TC Peaks storm database rows [ID, SWL, Hm0, Tp,
        %                           wDir, datenum] (cell2mat of
        %                           storm.TC.Peaks.Default): SWL [m, study datum],
        %                           Hm0 [m], Tp [s], wDir [deg], datenum [days],
        %                           nStorms x 6 double; with one output only
        %                           column 1 (storm ID) is read
        %     simulation_years    - life-cycle length, mcs_nYears [years], positive
        %                           integer scalar
        %     prob_mass           - TC probability masses
        %                           (chess.CoastalHazardSystem.load_probability_masses), struct with
        %                           TC_SRR (recurrence rates [storms/yr] of the low,
        %                           mid and high bins and of all storms, 1 x 4),
        %                           TC_Freq (storm weights, indexed by the storm's
        %                           row in storm_peaks) and smpl1, smpl2, smpl3
        %                           (storm IDs of each bin, columns)
        %     restrict_rate       - sampling mode (effective
        %                           lcs_restrict_sampling_rate): 0 full Poisson, 1
        %                           rate matched, scalar double
        %     storm_duration_days - storm duration written to every row of lcs_data
        %                           [days] (storm_duration/24; storm_duration is in
        %                           hours), scalar double
        %   Outputs:
        %     sample_storms - sampled storm identity [storm ID, bin (1, 2, 3),
        %                     year (1 to simulation_years), order (storm number
        %                     within the year)], one row per storm in year order,
        %                     nEvents x 4 double (0 x 4 when no storm is drawn)
        %     lcs_data      - life-cycle Peaks matrix (chess.Common.lcs_columns Peaks map): id,
        %                     bin, year, order, SWL [m, study datum], Hm0_toe [m]
        %                     (= Hm0_offshore; depth limited later by
        %                     chess.Model.build_forcing (adjustment step)), Hm0_offshore [m], Tp [s],
        %                     wDir [deg], storm_duration [days]; nEvents x 10
        %                     double (0 x 10 when no storm is drawn)
        %
        %   See also chess.Model.LifeCycle.sample_extratropical_storms, chess.Model.LifeCycle, chess.Common.lcs_columns,
        %   chess.CoastalHazardSystem.load_probability_masses.
        %
        %   Developed by: Norberto C. Nadal-Caraballo, PhD; Victor M. Gonzalez, PE;
        %   Fabian A. Garcia-Moreno

        %{
        LICENSING:
            This code is part of CHESS software suite developed by the U.S. Army
            Engineer Research and Development Center Coastal and Hydraulics Laboratory
            (hereinafter â€œERDC-CHLâ€?). This material is distributed in accordance with DoD
            Instruction 5230.24. Recipient agrees to abide by all notices, and distribution
            and license markings. The controlling DOD office is the U.S. Army Engineer
            Research and Development Center (hereinafter, "ERDC"). This material shall be
            handled and maintained in accordance with For Official Use Only, Export Control,
            and AR 380-19 requirements. ERDC-CHL retains all right, title and interest in
            CHESS and any portion thereof and in all copies, modifications and derivative
            works of CHESS and any portions thereof including, without limitation, all
            rights to patent, copyright, trade secret, trademark and other proprietary or
            intellectual property rights. Recipient has no rights, by license or otherwise, to
            use, disclose or disseminate CHESS, in whole or in part.

        DISCLAIMER:
            CHESS IS PROVIDED â€œAS ISâ€? BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
            ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
            TO CHESS OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
            OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
            MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
            CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
            USE, AND THAT THE ASSOCIATED SOFTWAREâ€™S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
            WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN CHESS, AND
            DISTRIBUTES IT â€œAS IS.â€? RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
            UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
            HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
            LIABILITIES, DEMANDS, DAMAGES.

        MODIFICATIONS:
            |   DATE (yyyy-mm-dd)   |      EDITOR      |         SUMMARY               |
            |-----------------------|------------------|-------------------------------|
            |      2021-03-02       |   Abigail Stehno |  Created function for storm   |
            |                       |                  |  sampling - xtrops            |
            |-----------------------|------------------|-------------------------------|
        RELEVANT PUBLICATIONS:
            Source Material:
                TBD
            Application Of Methodology:
                (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
                        structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
                        and Development Center.
        %}


        %% DEFINE INPUTS
        smpl1 = prob_mass.smpl1;
        smpl2 = prob_mass.smpl2;
        smpl3 = prob_mass.smpl3;
        % Storm Probability Masses
        TC_SRR = prob_mass.TC_SRR;
        % Storm Frequency
        TC_Freq = prob_mass.TC_Freq;
        % Simulation flag, internal. Stops two 'while' loops below to ensure sampled
        % storms match sampling rate.
        % Rate-matched tolerance, used only with the hidden option lcs_restrict_sampling_rate:
        % the sampled storm rate must match the storm rate within 1/simulation_years
        % (+/- 1 storm per life cycle); the 1e5-year case uses 1e-4 (+/- 10 storms).
        if simulation_years == 1e5
            SIM_Flag = 1e-4;
        else
            SIM_Flag = 1/simulation_years; % Force at least 1 event/yr
        end

        %% POISSON PROCESS
        % Assing SRR for all intensities as lambda
        TC_lambda = TC_SRR(1,end);  % Events/ Yr
        if ~isscalar(TC_lambda) || ~isfinite(TC_lambda) || TC_lambda < 0
            error('chess:Model:LifeCycle:invalidStormRate', 'Tropical storm sampling: the TC storm recurrence rate (prob_mass.TC_SRR(end)) must be a finite, non-negative number.');
        end
        % Make Distribuition Object
        TC_pd = makedist('Poisson','lambda',TC_lambda);
        % Sample Number Of TCs Sampled For The Simulation Year.
        TC_MCS = random(TC_pd,[simulation_years,1]);
        % restrict_rate = 0: Full Poisson Process, The First Draw Is Kept (A Life Cycle Can Have No Storms).
        % restrict_rate = 1: Rate-Matched Life Cycle (ERDC/CHL TR-20-5 Sec. 3.2-3.3; USGS OFR 2020-1001 p. 17-18): Yearly
        % Storm Counts Are Redrawn Until The Life-Cycle Storm Rate Is Within SIM_Flag Of The SRR (+/- 1 Storm Per Life Cycle).
        if restrict_rate == 1
            max_draws = 1e6; % Safeguard Against An Endless Loop
            % Recomputes The Storm Rate Of The Simulation Period To Check Against SRR.
            TC_EPY = sum(TC_MCS)/simulation_years;
            n_draws = 1;
            while abs(TC_EPY-TC_lambda)>SIM_Flag && n_draws < max_draws %cannot be higher than NSIMyrs
                % Sample Number Of TCs Sampled For The Simulation Year.
                TC_MCS = random(TC_pd,[simulation_years,1]);
                % Recomputes The Storm Rate Of The Simulation Period To Check Against SRR.
                TC_EPY = sum(TC_MCS)/simulation_years;
                n_draws = n_draws + 1;
            end
            if abs(TC_EPY-TC_lambda)>SIM_Flag
                warning('chess:Model:LifeCycle:rateNotMatched', 'Tropical storm sampling: life-cycle storm rate %.4f not within %.4f of SRR %.4f after %d draws; using the last draw.',...
                    TC_EPY, SIM_Flag, TC_lambda, n_draws);
            end
        end
        % No Storms Sampled In This Life Cycle: Empty Outputs
        C = chess.Common.lcs_columns();
        if sum(TC_MCS) == 0
            lcs_data = zeros(0, C.n_peaks); % Life-Cycle Peaks Layout (chess.Common.lcs_columns)
            sample_storms = zeros(0, 4); % [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order ]
            return
        end

        %% SAMPLE TROPICAL STORMS
        % Initialize Storm Counter
        n=1;
        lcs_data = zeros(sum(TC_MCS), C.n_peaks);
        % Grab Valid Storm Id List
        valid_storms = storm_peaks(:, 1);
        % Intensity Bin Populations (1-Low, 2-Mid, 3-High), Keeping Storms Present In storm_peaks
        smpl_bins = {smpl1, smpl2, smpl3};
        smpl_bins = cellfun(@(x) x(ismember(x, valid_storms)), smpl_bins, 'un', false);
        % Intensity Bins That Can Be Drawn: Must Have Storms. A Draw Landing In An Empty Bin Is Re-Drawn (As Before),
        % Which Always Ends Because At Least One Bin With A Positive Rate Has Storms (Checked Here).
        has_storms = ~cellfun(@isempty, smpl_bins);
        if ~any(has_storms & TC_SRR(1:3) > 0)
            error('chess:Model:LifeCycle:noBinStorms', 'Tropical storm sampling: no TC storms in any intensity bin (prob_mass.smpl1-3 matched against the storm peaks).');
        end
        cumulativeProb = cumsum(TC_SRR(1:3))./sum(TC_SRR(1:3));
        % cumulativeProb = cumsum(TC_SRR(1:3)./TC_SRR(end)); % Original (Team Discussion): Normalized By Total SRR. Identical
        % When sum(TC_SRR(1:3)) == TC_SRR(end); Otherwise cumulativeProb(3) < 1 And Draws Above It Matched No Intensity Bin.
        % Loop Through Simulation Length
        for j = 1:simulation_years
            %
            if (TC_MCS(j,1)>0)
                m=1;
                for k = 1:TC_MCS(j,1)
                    % Storm Year
                    lcs_data(n, C.year) = j;
                    % Number of Storm In Storm Year
                    lcs_data(n, C.order) = m;
                    % Random Number from 0 - 1
                    smpl_flag = rand;
                    % Determine Random Intensity To Sample (First Bin Whose Cumulative Probability Exceeds The Draw)
                    IIdx = find(smpl_flag < cumulativeProb, 1);
                    % Make Sure Resulting Intensity Has A Population (Re-Draw Otherwise)
                    while isempty(IIdx) || ~has_storms(IIdx)
                        % Random Number from 0 - 1
                        smpl_flag = rand;
                        % Try New Intensity
                        IIdx = find(smpl_flag < cumulativeProb, 1);
                    end
                    % Stomr Intensity
                    lcs_data(n, C.bin) = IIdx; % 1-Low, 2-Mid, 3-High
                    % Grab Sampling Population From Intensity Bin (Storms Present In storm_peaks)
                    smpl = smpl_bins{IIdx};
                    % Find Correnponding Frequency
                    [~, bi] = ismember(smpl, valid_storms);
                    % Sample Random Storm From Instensity Bin (randsample Treats A Scalar As 1:n, So A Single Storm Is Taken Directly)
                    if isscalar(smpl)
                        lcs_data(n, C.id) = smpl;
                    else
                        lcs_data(n, C.id) = randsample(smpl, 1, true, TC_Freq(bi));
                    end
                    % Increment Storm
                    n=n+1;
                    % Increment Number of Storm In Storm Year
                    m=m+1;
                end% for 
            end% if
        end% for j
        % Sampled Storm Indexes
        sample_storms = lcs_data(:, [C.id, C.bin, C.year, C.order]); % (Headers in script header)
        % Storm IDs Only (use_peaks = 0: storm_peaks Holds The Storm ID Column)
        if nargout < 2
            return
        end
        [~, bi] = ismember(lcs_data(:, C.id), storm_peaks(:, 1));
        % Pull Storm Responses For Sampled Storms (Storm Database Columns: ID SWL Hm0 Tp wDir datenum)
        lcs_data(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir]) =  storm_peaks(bi, [2 3 3 4 5]);
        lcs_data(:, C.storm_duration) = storm_duration_days;
        end

        function [sampled_storms, lcs_data] = sample_extratropical_storms(storm_peaks, simulation_years, yearly_rate, restrict_rate, storm_duration_days)
        % sample_extratropical_storms  Sample one LCS life cycle of extratropical (XC) storms.
        %   sampled_storms = chess.Model.LifeCycle.sample_extratropical_storms(storm_peaks, simulation_years,
        %       yearly_rate, restrict_rate, storm_duration_days)
        %   [sampled_storms, lcs_data] = chess.Model.LifeCycle.sample_extratropical_storms(storm_peaks,
        %       simulation_years, yearly_rate, restrict_rate, storm_duration_days)
        %
        %   Draws the number of XC storms of each simulation year from a Poisson
        %   distribution with rate yearly_rate. restrict_rate = 1 redraws the
        %   yearly counts until the life-cycle storm rate is within
        %   1/simulation_years of yearly_rate (1e-4 for 1e5 years), i.e. +/- 1
        %   storm per life cycle, up to 1e6 draws (then a warning, the last draw
        %   is kept); restrict_rate = 0 keeps the first draw (a life cycle can
        %   hold no storms). Each storm is drawn uniformly, with replacement, from
        %   the storm IDs in storm_peaks(:, 1).
        %   With two outputs the peak values are drawn from a Gaussian copula
        %   fitted to the SWL, Hm0, Tp and wDir columns of storm_peaks
        %   (chess.Model.LifeCycle.copula_sampler), not taken from the database values of the sampled
        %   storms. With one output only the storm IDs are drawn and the copula is
        %   not run (chess.Model.LifeCycle with use_peaks = 0 passes the Timeseries storm IDs
        %   as storm_peaks). Errors when yearly_rate is not a finite, non-negative
        %   scalar.
        %
        %   Inputs:
        %     storm_peaks         - XC Peaks storm database rows [ID, SWL, Hm0, Tp,
        %                           wDir, datenum] (cell2mat of
        %                           storm.XC.Peaks.Default): SWL [m, study datum],
        %                           Hm0 [m], Tp [s], wDir [deg], datenum [days],
        %                           nStorms x 6 double; with one output only
        %                           column 1 (storm ID) is read
        %     simulation_years    - life-cycle length, mcs_nYears [years], positive
        %                           integer scalar
        %     yearly_rate         - XC storm rate, Nstm_XC/Nyrs_XC [storms/yr],
        %                           finite non-negative scalar double
        %     restrict_rate       - sampling mode (effective
        %                           lcs_restrict_sampling_rate): 0 full Poisson, 1
        %                           rate matched, scalar double
        %     storm_duration_days - storm duration written to every row of lcs_data
        %                           [days] (storm_duration/24; storm_duration is in
        %                           hours), scalar double
        %   Outputs:
        %     sampled_storms - sampled storm identity [storm ID, bin (0 = XC), year
        %                      (1 to simulation_years), order (storm number within
        %                      the year)], one row per storm in year order,
        %                      nEvents x 4 double (0 x 4 when no storm is drawn)
        %     lcs_data       - life-cycle Peaks matrix (chess.Common.lcs_columns Peaks map): id,
        %                      bin, year, order, SWL [m, study datum], Hm0_toe [m]
        %                      (= Hm0_offshore; depth limited later by
        %                      chess.Model.build_forcing (adjustment step)), Hm0_offshore [m], Tp [s],
        %                      wDir [deg], storm_duration [days]; nEvents x 10
        %                      double (0 x 10 when no storm is drawn)
        %
        %   See also chess.Model.LifeCycle.sample_tropical_storms, chess.Model.LifeCycle, chess.Common.lcs_columns, chess.Model.LifeCycle.copula_sampler.
        %
        %   Developed by: Norberto C. Nadal-Caraballo, PhD; Victor M. Gonzalez, PE;
        %   Fabian A. Garcia-Moreno

        %{
        LICENSING:
            This code is part of CHESS software suite developed by the U.S. Army
            Engineer Research and Development Center Coastal and Hydraulics Laboratory
            (hereinafter â€œERDC-CHLâ€?). This material is distributed in accordance with DoD
            Instruction 5230.24. Recipient agrees to abide by all notices, and distribution
            and license markings. The controlling DOD office is the U.S. Army Engineer
            Research and Development Center (hereinafter, "ERDC"). This material shall be
            handled and maintained in accordance with For Official Use Only, Export Control,
            and AR 380-19 requirements. ERDC-CHL retains all right, title and interest in
            CHESS and any portion thereof and in all copies, modifications and derivative
            works of CHESS and any portions thereof including, without limitation, all
            rights to patent, copyright, trade secret, trademark and other proprietary or
            intellectual property rights. Recipient has no rights, by license or otherwise, to
            use, disclose or disseminate CHESS, in whole or in part.

        DISCLAIMER:
            CHESS IS PROVIDED â€œAS ISâ€? BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
            ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
            TO CHESS OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
            OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
            MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
            CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
            USE, AND THAT THE ASSOCIATED SOFTWAREâ€™S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
            WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN CHESS, AND
            DISTRIBUTES IT â€œAS IS.â€? RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
            UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
            HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
            LIABILITIES, DEMANDS, DAMAGES.

        MODIFICATIONS:
            |   DATE (yyyy-mm-dd)   |      EDITOR      |         SUMMARY               |
            |-----------------------|------------------|-------------------------------|
            |      2021-03-02       |   Abigail Stehno |  Created function for storm   |
            |                       |                  |  sampling - xtrops            |
            |-----------------------|------------------|-------------------------------| 
        RELEVANT PUBLICATIONS:
            Source Material:
                TBD
            Application Of Methodology:
                (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
                        structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
                        and Development Center.
        %}

        %% DEFINE INPUTS
        % Simulation flag, internal. Stops two 'while' loops below to ensure sampled
        % storms match sampling rate.
        % Rate-matched tolerance, used only with the hidden option lcs_restrict_sampling_rate:
        % the sampled storm rate must match the storm rate within 1/simulation_years
        % (+/- 1 storm per life cycle); the 1e5-year case uses 1e-4 (+/- 10 storms).
        if simulation_years == 1e5
            SIM_Flag = 1e-4;
        else
            SIM_Flag = 10^-(log10(simulation_years));
        end

        %% POISSON PROCESS
        % Rate of extratropical cyclones (storms/year)
        XC_lambda = yearly_rate;
        if ~isscalar(XC_lambda) || ~isfinite(XC_lambda) || XC_lambda < 0
            error('chess:Model:LifeCycle:invalidStormRate', 'Extratropical storm sampling: the XC yearly rate (Nstm_XC / Nyrs_XC) must be a finite, non-negative number.');
        end
        % Make Distribuition Object
        XC_pd = makedist('Poisson','lambda',XC_lambda);
        XC_MCS = random(XC_pd,[simulation_years,1]);%sampled number of storms based on Poisson distribution
        % restrict_rate = 0: Full Poisson Process, The First Draw Is Kept (A Life Cycle Can Have No Storms).
        % restrict_rate = 1: Rate-Matched Life Cycle (ERDC/CHL TR-20-5 Sec. 3.2-3.3; USGS OFR 2020-1001 p. 17-18): Yearly
        % Storm Counts Are Redrawn Until The Life-Cycle Storm Rate Is Within SIM_Flag Of The Rate (+/- 1 Storm Per Life Cycle).
        if restrict_rate == 1
            max_draws = 1e6; % Safeguard Against An Endless Loop
            XC_EPY = sum(XC_MCS)/simulation_years;
            n_draws = 1;
            while abs(XC_EPY-XC_lambda)>SIM_Flag && n_draws < max_draws %cannot be higher than Nsimulation_years
                XC_MCS = random(XC_pd,[simulation_years,1]);%sampled number of storms based on Poisson distribution
                XC_EPY = sum(XC_MCS)/simulation_years;
                n_draws = n_draws + 1;
            end
            if abs(XC_EPY-XC_lambda)>SIM_Flag
                warning('chess:Model:LifeCycle:rateNotMatched', 'Extratropical storm sampling: life-cycle storm rate %.4f not within %.4f of rate %.4f after %d draws; using the last draw.',...
                    XC_EPY, SIM_Flag, XC_lambda, n_draws);
            end
        end
        % No Storms Sampled In This Life Cycle: Empty Outputs
        C = chess.Common.lcs_columns();
        if sum(XC_MCS) == 0
            lcs_data = zeros(0, C.n_peaks); % Life-Cycle Peaks Layout (chess.Common.lcs_columns)
            sampled_storms = zeros(0, 4); % [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order ]
            return
        end

        %% SAMPLE XC STORM IDs
        n=1; clear SimOUT_XC
        for j = 1:simulation_years
            if (XC_MCS(j,1)>0)
                m=1;
                for k = 1:XC_MCS(j,1)
                    % Storm Year
                    SimOUT_XC(n,2) = j;
                    % Storm intensity (0 = Extratropical, 1,2,3 = tropical cyclones (low, mid, high))
                    SimOUT_XC(n,1) = 0;
                    % Number of Storm In Storm Year
                    SimOUT_XC(n,3) = m;
                    % Sample Random Storm (randsample Treats A Scalar As 1:n, So A Single Storm Is Taken Directly)
                    if isscalar(storm_peaks(:,1))
                        XC_INDEX(n,1) = storm_peaks(1,1);
                    else
                        XC_INDEX(n,1) = randsample(storm_peaks(:,1), 1);
                    end
                    % Increment Storm
                    n=n+1;
                    % Increment Number Of Storm In Storm Year
                    m=m+1;
                end%for k
            end%if
        end%for j
        % Sampled Storm Indexes (For Timeseries LC Creation)
        sampled_storms = [XC_INDEX, SimOUT_XC]; % [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order ]
        % Storm IDs Only (use_peaks = 0: storm_peaks Holds The Storm ID Column): No Copula Draw
        if nargout < 2
            return
        end
        % Call Copula Sampler [ SWL, Hm0, Tp, wDir, storm_IDs ]
        [Y] = chess.Model.LifeCycle.copula_sampler(storm_peaks(:, 2:5), XC_INDEX);
        % Monte Carlo Simulation Outputs (Sample Extratropical Storms Peaks)
        lcs_data = zeros(numel(XC_INDEX), C.n_peaks); % Life-Cycle Peaks Layout (chess.Common.lcs_columns)
        lcs_data(:, [C.id, C.bin, C.year, C.order]) = [XC_INDEX, SimOUT_XC];
        lcs_data(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir]) = Y(:, [1 2 2 3 4]);
        lcs_data(:, C.storm_duration) = storm_duration_days;

        end

        function Y = copula_sampler(storm_peaks, storm_indexes)  
        % chess.Model.LifeCycle.copula_sampler  Draw XC peak values from a Gaussian copula of the peaks.
        %   Y = chess.Model.LifeCycle.copula_sampler(storm_peaks, storm_indexes)
        %
        %   Fits a Gaussian copula to the four peak columns (marginals: kernel
        %   density CDFs, ksdensity; correlation from Kendall's tau, copulaparam)
        %   and draws one row per element of storm_indexes (copularnd), mapped
        %   back to values with the kernel inverse CDFs. The drawn values are not
        %   tied to the sampled storm IDs: storm_indexes only sets the number of
        %   draws. Each column is then scaled so its mean equals the storm_peaks
        %   column mean (NaN omitted); the scale factors come from the first
        %   draw and are kept. Rows whose scaled Hm0 is below 0.1 m are drawn
        %   again (copula, kernel inverse CDFs, the same scale factors) until
        %   none remain; errors (chess:Model:LifeCycle:copulaResampleLimit)
        %   when rows are still below 0.1 m after 100 redraw rounds. Uses the
        %   global random number stream.
        %
        %   Inputs:
        %     storm_peaks   - XC peak values [SWL, Hm0, Tp, wDir]: SWL [m, study
        %                     datum], Hm0 [m], Tp [s], wDir [deg], nStorms x 4
        %                     double
        %     storm_indexes - sampled storm IDs (only the row count is used),
        %                     nEvents x 1 double
        %   Outputs:
        %     Y - sampled peak values [SWL, Hm0, Tp, wDir] (units as storm_peaks),
        %         nEvents x 4 double
        %
        %   See also chess.Model.LifeCycle.sample_extratropical_storms.

        %% COMPUTE GAUSSIAN COPULA STATISTICAL PARAMETERS & SAMPLE STORMS
            minimum_wave_height = 0.1; % [m]
            maximum_redraw_rounds = 100;
            % Returns a probability density estimate, f, for each sample data column
            for k = 1:4
                X(:,k) = ksdensity(storm_peaks(:,k),storm_peaks(:,k),'function','cdf');
            end
            % Compute Tau
            Tau = corr(X,'type','Kendall'); % Maximums
            % Compute matrix of linear correlations (Rho)
            Rho = copulaparam('Gaussian',Tau,'type','Kendall'); % Maximums
            Y = copula_draw(storm_peaks, Rho, size(storm_indexes,1));

            %% SCALE SAMPLED STORM RESPONSES
            % Scale Responses By Individual Means (Factors Of The First Draw, Kept For The Redraws)
            scale_factors = mean(storm_peaks, 1, "omitnan")./mean(Y, 1, "omitnan");
            Y = Y.*scale_factors;

            %% REDRAW STORMS WITH TOO SMALL WAVES
            redraw = Y(:,2) < minimum_wave_height;
            redraw_round = 0;
            while any(redraw)
                if redraw_round == maximum_redraw_rounds
                    error('chess:Model:LifeCycle:copulaResampleLimit',...
                        ['%d copula sampled XC storms still have Hm0 below %g m after %d redraw rounds: the XC peak ',...
                        'wave heights are too small for the copula sampler.'], nnz(redraw), minimum_wave_height,...
                        maximum_redraw_rounds);
                end
                redraw_round = redraw_round + 1;
                Y(redraw,:) = copula_draw(storm_peaks, Rho, nnz(redraw)).*scale_factors;
                redraw = Y(:,2) < minimum_wave_height;
            end
        end
    end
end

%% LOCAL FUNCTIONS: DAMAGE PROGRESSION
function [damage_initiation, on_first_storm] = in_first_damaging_storm(got_damage, on_first_storm, step_column, time_step)
% True while the damage initiation coefficient applies: no damage yet, or before the end of the first damaging storm
if got_damage && on_first_storm
    storm_end_row = find_storm_end(step_column, time_step);
    if time_step<storm_end_row
        damage_initiation = true;
        on_first_storm = 1;
    else
        damage_initiation = false;
        on_first_storm = 0;
    end
elseif got_damage
    damage_initiation = false;
else
    damage_initiation = true;
end
end

function statistics = final_damage_statistics(LC_SimOUT_hyd, damage, nYears, p)
%% STORE LAST COMPUTED DAMAGE FOR EACH LC
% This will turn into a mean sigular value once percentiles are computed
% Seaside
% (Life Cycles Without Storms Keep The Initial Damage, 0)
S_final = lc_values(damage.seaside_no_repairs, @(x) x(end));
LS_final = lc_values(damage.leeside_no_repairs, @(x) x(end));

%% COMPUTE MEAN DAMAGE CURVE
[LSmax,LSPcurves,~] = chess.Model.LifeCycle.yearly_curve(LC_SimOUT_hyd, damage.leeside_no_repairs, nYears, p);
[Smax,SPcurves,~] = chess.Model.LifeCycle.yearly_curve(LC_SimOUT_hyd, damage.seaside_no_repairs, nYears, p);
% Fill values for year 0
Smax = [0;Smax];
LSmax = [0;LSmax];
SPcurves = [zeros(size(SPcurves(1,:)));SPcurves];
LSPcurves = [zeros(size(SPcurves(1,:)));LSPcurves];

%% COMPUTE STATISTICS - TABLE
% Percentiles Of config.project_CLs
p = p(:);
Sp = reshape(prctile(S_final,p), [], 1);
LSp = reshape(prctile(LS_final,p), [], 1);
% Compute Mean Accumulated Damage For Bin
Smean = repmat(mean(S_final,'omitnan'),size(p));
LSmean = repmat(mean(LS_final,'omitnan'),size(p));
% Build Stats Table
statistics.stats = table(p,Smean,Sp,LSmean,LSp);
statistics.Smax = Smax;
statistics.LSmax = LSmax;
statistics.SPcurves = SPcurves;
statistics.LSPcurves = LSPcurves;
end

function diagnostics = diagnostics_tables(forcing, damage, nLC)
WL = forcing.WL; Hm0 = forcing.Hm0; Tp = forcing.Tp; h = forcing.h; Nz = forcing.Nz; Rc = forcing.Rc;
z1p = forcing.z1p; u1p = forcing.u1p;
Szero_no_repairs = damage.Szero_no_repairs; seaside_no_repairs = damage.seaside_no_repairs;
Szero_with_repairs = damage.Szero_with_repairs; seaside_with_repairs = damage.seaside_with_repairs;
leeside_no_repairs = damage.leeside_no_repairs; leeside_with_repairs = damage.leeside_with_repairs;
diagnostics(1,:) = cellfun(@(a) table(WL{a},Hm0{a},...
    Tp{a},h{a},Nz{a},Rc{a},z1p{a},u1p{a},Szero_no_repairs{a},seaside_no_repairs{a},Szero_with_repairs{a},...
    seaside_with_repairs{a}, leeside_no_repairs{a}, leeside_with_repairs{a}, 'VariableNames',...
    {'WL','Hm0_toe','Tp','h','Nz','Rc','z1p','u1p',...
    'Szero_no_repairs','Ssea_no_repairs','Szero_with_repairs','Ssea_with_repairs',...
    'SLee_no_repairs','SLee_with_repairs'}),...
    num2cell(1:nLC),'un',false)';
end

function repairs = repair_statistics(settings, damage, Seaside_Repair_Indexes, Leeside_Repair_Indexes)
if settings.repair_switch > 0
    % Seaside N Repairs
    if ~isempty(Seaside_Repair_Indexes)
        sea_repairs = cellfun(@(x) length(x), Seaside_Repair_Indexes(:, 1),'UniformOutput',true);
    else
        sea_repairs = 0;
    end
    % Leeside N Repairs
    if ~isempty(Leeside_Repair_Indexes)
        lee_repairs = cellfun(@(x) length(x), Leeside_Repair_Indexes(:, 1),'UniformOutput',true);
    else
        lee_repairs = 0;
    end
    % Compute Seaside Mean Repairs
    sea_repairs_mean = mean(sea_repairs);
    % Compute Leeside Mean Repairs
    lee_repairs_mean = mean(lee_repairs);
    p = settings.percentiles(:)';
    pct_names = @(side) arrayfun(@(x) sprintf('%s_Repair_%s_Percentile', side, strrep(sprintf('%g', x), '.', 'p')), p, 'un', 0);
    sea_repairs_percentiles = reshape(prctile(sea_repairs, p), 1, []);
    lee_repairs_percentiles = reshape(prctile(lee_repairs, p), 1, []);
    repairs.Repairs_Stats = array2table([sum(sea_repairs), sea_repairs_mean, sea_repairs_percentiles,...
        sum(lee_repairs), lee_repairs_mean, lee_repairs_percentiles], 'VariableNames',...
        [{'Total_Seaside_Repairs', 'Mean_Seaside_Repairs'}, pct_names('Seaside'),...
        {'Total_Leeside_Repairs', 'Mean_Leeside_Repairs'}, pct_names('Leeside')]);
else
    % Seaside N Repairs
    sea_repairs = sum(lc_values(damage.seaside_no_repairs, @max)>=settings.seaside_S_ULS);
    % Leeside N Repairs
    lee_repairs = sum(lc_values(damage.leeside_no_repairs, @max)>=settings.leeside_S_ULS);
end
repairs.sea_repairs = sea_repairs;
repairs.lee_repairs = lee_repairs;
end

function reliability = structure_reliability(repair_switch, repairs, Seaside_Repair_Indexes, Leeside_Repair_Indexes, nLC)
if repair_switch > 0
    % One Repair_Indexes Row Per Life Cycle With At Least One Repair (sea_repairs/lee_repairs Are 0 When None Was Needed)
    % Seaside Reliability
    reliability.Seaside = 1 - size(Seaside_Repair_Indexes, 1)/nLC;
    % Leeside Reliability
    reliability.Leeside = 1 - size(Leeside_Repair_Indexes, 1)/nLC;
else
    % Seaside Reliability
    reliability.Seaside = 1 - repairs.sea_repairs/nLC;
    % Leeside Reliability
    reliability.Leeside = 1 - repairs.lee_repairs/nLC;
end
end

function CSR_Timeseries_DPA = damage_progression_output(repair_switch, damage, Seaside_Repair_Indexes,...
    Leeside_Repair_Indexes, statistics, repairs, reliability, diagnostics)
% Damage with no breaching
CSR_Timeseries_DPA.S_seaside_no_repairs = damage.seaside_no_repairs;
CSR_Timeseries_DPA.S_leeside_no_repairs = damage.leeside_no_repairs;
% Damage with breaching
CSR_Timeseries_DPA.S_seaside_with_repairs = damage.seaside_with_repairs;
CSR_Timeseries_DPA.S_leeside_with_repairs = damage.leeside_with_repairs;
% Stores Timestep Where Breaching Occoured For Each Strom At Each LC
CSR_Timeseries_DPA.Seaside_Repair_Indexes = Seaside_Repair_Indexes;
CSR_Timeseries_DPA.Leeside_Repair_Indexes = Leeside_Repair_Indexes;
% Mean & Percentiles For THe Final Accumulated Damage Of All LC's
CSR_Timeseries_DPA.stats = statistics.stats;
% Repairs Stats
if repair_switch > 0
    CSR_Timeseries_DPA.Repairs_Stats = repairs.Repairs_Stats;
else
    CSR_Timeseries_DPA.seaside_repair_count = repairs.sea_repairs;
    CSR_Timeseries_DPA.leeside_repair_count = repairs.lee_repairs;
end
% Overall Structure Seaside Reliability
CSR_Timeseries_DPA.Reliability_Seaside = reliability.Seaside;
% Overall Structure Seaside Reliability
CSR_Timeseries_DPA.Reliability_Leeside = reliability.Leeside;
% Yearly Mean Maximum Cumulative Damages
CSR_Timeseries_DPA.Smax = statistics.Smax;
CSR_Timeseries_DPA.LSmax = statistics.LSmax;
% Yearly Mean Maximum Cumulative Damages Percentiles
CSR_Timeseries_DPA.LSPcurves = statistics.LSPcurves;
CSR_Timeseries_DPA.SPcurves = statistics.SPcurves;
% Diagnostics Data Structure
CSR_Timeseries_DPA.diagnostics = diagnostics;
end

function v = lc_values(S, fun)
v = zeros(size(S));
has_storms = ~cellfun(@isempty, S);
v(has_storms) = cellfun(fun, S(has_storms));
end

function  storm_end_row = find_storm_end(step_column, time_step)
storm_tstps = step_column(time_step:end); % 0:73 or 0:96 repeated for 70ish storms except missing first time_step values
% Find Row Index Of 1st TimeStep of Storms In LC
storm_end_row = find(storm_tstps==0);
% Find End Row Of present Storm
if isempty(storm_end_row)==0 % if true, then all storms but last storm
    storm_end_row = time_step+storm_end_row(1)-2; % all storms but last storm
else
    storm_end_row = time_step+length(storm_tstps)-1; % last storm because no zeros
end
end

function repair_flag = repair_condition(repair_switch, SLS, ULS, S_last)
% Determine Repair Conditions
switch repair_switch
    case 1 % Include Service Limit State Repairs (SLS)
        if S_last>SLS
            repair_flag = true;
        else
            repair_flag = false;
        end
    case 2 % Repair for Ultimate Limit State (ULS)
        if S_last>ULS
            repair_flag = true;
        else
            repair_flag = false;
        end
    case 3 % Repair for Service & Ultimate Limit State
        if S_last>ULS || S_last>SLS
            repair_flag = true;
        else
            repair_flag = false;
        end
    case 0  % No Repairs
        repair_flag = false;
    otherwise
        error('chess:Model:LifeCycle:unknownRepairScenario', 'csr_apply_structure_repair must be 0 (no repairs), 1 (repair above SLS), 2 (repair above ULS) or 3 (repair above SLS or ULS).');
end
end

%% LOCAL FUNCTIONS: STORM SAMPLING
function Y = copula_draw(storm_peaks, Rho, number_of_draws)
% Gaussian copula draws mapped back to peak values with the kernel inverse CDFs of the storm_peaks columns
r = copularnd('Gaussian',Rho,number_of_draws);
Y = zeros(number_of_draws, 4);
for k = 1:4
    Y(:,k) = ksdensity(storm_peaks(:,k),r(:,k),'function','icdf');
end
end

function settings = read_life_cycle_settings(config)
% Storm Sampling Scheme
settings.storm_sampling = config.storm_sampling;
% Peaks Life Cycles (use_peaks = 0: Timeseries Only, Storm IDs Drawn From The Timeseries Storms)
settings.use_peaks = config.use_peaks == 1;
% Number Of Life Cycles
settings.number_of_life_cycles = config.mcs_nLC;
% Simulation Length
settings.simulation_years = config.mcs_nYears;
% Create Water Level Priority Switch
settings.wlp_switch = config.create_wlp;
% Timeseries Storm Duration From Each Storm's SWL (Missing = 0: config.storm_duration)
settings.compute_storm_duration = isfield(config, 'compute_storm_duration') && isequal(config.compute_storm_duration, 1);
% Create Wave Height Priority Switch
settings.whp_switch = config.create_whp;
switch settings.storm_sampling
    case 'TC'
        settings.xc_storm_count = [];
        settings.xc_record_years = [];
    otherwise
        % Define Number Of Extratropical Storms In Data
        settings.xc_storm_count = config.Nstm_XC;
        % Define Number of Years In Extratropical Data
        settings.xc_record_years = config.Nyrs_XC;
end
end

function [config, lcs_mode] = report_reuse_and_clear_tides(config, reuse)
mcs_ref_pth = reuse.file;
% Storm Types To Sample (In Sampling Order)
storm_types_to_sample = reuse.types;
reused = reuse.reused;
if config.load_project_forcing == 1
    if reuse.found && ~reuse.seed_found
        warning('chess:Model:LifeCycle:referenceSeedNotFound', ['Reference case ''%s'' has no sampling seed file; its sampling cannot be ',...
            'reused. Life cycles will be sampled fresh (as if load_project_forcing = 0).\n   %s'],...
            config.ref_case_name, chess.ProjectPaths.sampling_seed_file(mcs_ref_pth));
    elseif reuse.found
        for kk = find(~reused)
            disp(['     Warning: ref_case_name ('  config.ref_case_name ') does not have ' storm_types_to_sample{kk} ' sampling information...']);
        end
    else
        if reuse.own
            fallback = 'The cached sampling of this case is reused instead.';
        else
            fallback = 'Storms are sampled fresh instead.';
        end
        warning('chess:Model:LifeCycle:referenceNotFound', ['load_project_forcing = 1, but the project forcing of ref_case_name (%s) ',...
            'was not found at:\n   %s\n%s'], config.ref_case_name, mcs_ref_pth, fallback);
    end
end
if reuse.own
    disp(['     Hotstart: reusing ' strjoin(storm_types_to_sample(reused), ' and ') ' life cycles from ' reuse.label ', storm values from the storm database.']);
end
% Tide Start Hours Carried From The Cached Run (chess.Hotstart.resolve) Belong To Its Own Life Cycles Only
for kk = 1:numel(storm_types_to_sample)
    fld = ['tide_indx_' lower(storm_types_to_sample{kk})];
    if isfield(config, fld) && ~(reuse.own && reused(kk))
        config.(fld) = [];
    end
end
% Life-Cycle Sampling Mode (0 = Full Poisson, 1 = Rate Matched)
% Reused Storms Were Sampled Under The Reference's Mode, So That Mode Drives Everything Downstream.
% Stored As lcs_effective_sampling_rate: lcs_restrict_sampling_rate Keeps The Configured Value (Hotstart Dependency).
lcs_mode = reuse.mode;
if lcs_mode ~= config.lcs_restrict_sampling_rate
    fprintf(['   Notice: lcs_restrict_sampling_rate = %d is used instead of the configured %d: the storms are reused from ',...
        '%s, which was sampled with lcs_restrict_sampling_rate = %d.\n'], lcs_mode, config.lcs_restrict_sampling_rate, reuse.label, lcs_mode);
end
config.lcs_effective_sampling_rate = lcs_mode;
end

function config = check_life_cycle_sampling(config, prob_mass, reuse, settings, lcs_mode)
% Storm Types To Sample (In Sampling Order)
storm_types_to_sample = reuse.types;
reused = reuse.reused;
if lcs_mode == 1
    disp(['   Notice: LCS sampling is rate restricted (lcs_restrict_sampling_rate = 1): each life cycle holds lambda x mcs_nYears +/- 1 storms ',...
        'and no convergence check is run. Life-cycle percentiles are conditional on rate-matched storm counts: they include storm ',...
        'selection, intensity and timing variability, but not storm-count variability.']);
end
for kk = 1:length(storm_types_to_sample)
    if reused(kk)
        disp(['     ' storm_types_to_sample{kk} ' storms are reused from ' reuse.label ': convergence check skipped (sampled storms are fixed).']);
        continue
    end
    switch storm_types_to_sample{kk}
        case 'XC'
            storm_rate = settings.xc_storm_count/settings.xc_record_years;
        case 'TC'
            storm_rate = prob_mass.TC_SRR(end);
    end
    check_storms_per_life_cycle(storm_types_to_sample{kk}, storm_rate, settings.simulation_years, lcs_mode);
end
% Results Kept Per Storm Type (Sampling Dashboard Reuses Them Instead Of Re-Running The Check)
config.lcs_convergence_results = struct();
if ~isempty(reuse.check_types)
    checks = chess.Model.LifeCycle.convergence_checks(config, prob_mass, reuse.check_types);
    for conv = checks
        config.lcs_convergence_results.(conv.stm_type) = conv;
    end
    for conv = checks(~[checks.converged])
        confirm_not_converged(conv, conv.stm_type, config.lcs_convergence_prompt);
    end
end
end

function project_forcing = empty_life_cycle_storage(storm_sampling, number_of_life_cycles, use_peaks)
project_forcing = struct();
if ~use_peaks
    return
end
if contains(storm_sampling,{'XC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('XC') = repmat({},number_of_life_cycles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('XC') = repmat({},number_of_life_cycles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('XC') = repmat({},number_of_life_cycles,1);
end
if contains(storm_sampling,{'TC','CC'})
    % Initialize Default Dataset MC Storage Variable
    project_forcing.Peaks.Default.('TC') = repmat({},number_of_life_cycles,1);
    % Initialize WLP Dataset MC Storage Variable
    project_forcing.Peaks.WLP.('TC') = repmat({},number_of_life_cycles,1);
    % Initialize WHP Dataset MC Storage Variable
    project_forcing.Peaks.WHP.('TC') = repmat({},number_of_life_cycles,1);
end
end

function [project_forcing, sampled_xc] = sample_extratropical_life_cycles(project_forcing, storm, config, reuse, settings, lcs_mode, C, C_ts)
number_of_life_cycles = settings.number_of_life_cycles;
storm_duration_days = chess.Common.chess_units('convert', config.storm_duration, 'h', 'day');
% Sample XC Storms According To Peak Responses
hot_start = ~isempty(reuse.src.XC);
if hot_start
    disp(['     Loading XC sampling seed from ' reuse.label]);
    % Pull Sampling Seed
    sampled_xc = reuse.ids.XC;
    if settings.use_peaks
        fprintf(1,'      Completion Progress: %3d%%\n',0);
        storm_data = storm.XC.Peaks.Default;
        % Populate Storm Data
        for lc=1:number_of_life_cycles
            % Create LCs
            project_forcing.Peaks.Default.('XC'){lc, 1} = reference_lc_peaks(sampled_xc{lc}, storm_data, storm_duration_days, C); % Life-Cycle Peaks Layout (chess.Common.lcs_columns)
            fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
        end
        % XC Peaks Are Copula Samples: Use The Reference's Sampled Values (Sampling Seed File) Instead Of Database Peaks
        xc_seed = load_reference_xc_seed(reuse.seed_pf, sampled_xc, reuse.label, C);
        % Only The Copula Values (SWL, Hm0, Tp, wDir) Are Kept: Identity And Storm Duration Come From This Run (As For TC)
        if ~isempty(xc_seed)
            copula_cols = [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir];
            project_forcing.Peaks.Default.('XC') = cellfun(@(s, d) copy_columns(d, s, copula_cols), xc_seed,...
                project_forcing.Peaks.Default.('XC'), 'un', false);
        end
    end
end
if ~hot_start
    disp('     Sampling Extratropical Events .....');
    fprintf(1,'      Completion Progress: %3d%%\n',0);
    if ~settings.use_peaks
        % Timeseries Only: Storm IDs Drawn From The Timeseries Storms, No Copula Peaks
        xc_storm_ids = cell2mat(storm.XC.Timeseries.Default(:, 1));
    end
    for lc=1:number_of_life_cycles
        if settings.use_peaks
            [sampled_xc{lc, 1},...
                project_forcing.Peaks.Default.('XC'){lc, 1}] = ...
                chess.Model.LifeCycle.sample_extratropical_storms(cell2mat(storm.XC.Peaks.Default), settings.simulation_years, settings.xc_storm_count/settings.xc_record_years, lcs_mode, storm_duration_days);
        else
            sampled_xc{lc, 1} = chess.Model.LifeCycle.sample_extratropical_storms(xc_storm_ids, settings.simulation_years, settings.xc_storm_count/settings.xc_record_years, lcs_mode, storm_duration_days);
        end
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
    end
end
% Replicate Storm Sampling With Storm Timeseries
if config.use_timeseries == 1
    ts_dur = sampled_storm_durations(sampled_xc, storm.('XC').('Timeseries').('Default'), config.storm_duration, settings.compute_storm_duration, 'XC');
    for lc=1:number_of_life_cycles
        % Build LCS Timeseries Dataset
        project_forcing.Timeseries.Default.('XC'){lc, 1} = timeseries_lc_creation(sampled_xc{lc, 1},...
            storm.('XC').('Timeseries').('Default'), ts_dur, C, C_ts);
    end
end
% Alternate Datasets: XC Peaks Are Copula Draws Fitted To The Default Peaks, Not Database Values Of The Sampled Storms.
% WLP/WHP Are An Exact Copy Of The Default Life Cycles (The Copula Is Never Re-Sampled), So The Matching Methods
% Compare On The Same XC Storms And Values; storm.XC.Peaks.WLP/WHP Are Not Read Here
if config.create_wlp == 1
    project_forcing.Peaks.WLP.('XC') = project_forcing.Peaks.Default.('XC');
end
if config.create_whp == 1
    project_forcing.Peaks.WHP.('XC') = project_forcing.Peaks.Default.('XC');
end
end

function [project_forcing, sampled_tc] = sample_tropical_life_cycles(project_forcing, storm, prob_mass, config, reuse, settings, lcs_mode, C, C_ts)
number_of_life_cycles = settings.number_of_life_cycles;
storm_duration_days = chess.Common.chess_units('convert', config.storm_duration, 'h', 'day');
% Sample TC Storms According To Their Probability Masses
hot_start = ~isempty(reuse.src.TC);
if hot_start
    disp(['     Loading TC sampling seed from ' reuse.label]);
    % Pull Sampling Seed
    sampled_tc = reuse.ids.TC;
    if settings.use_peaks
        fprintf(1,'      Completion Progress: %3d%%\n',0);
        storm_data = storm.TC.Peaks.Default;
        % Populate Storm Data
        for lc=1:number_of_life_cycles
            % Create LCs
            project_forcing.Peaks.Default.('TC'){lc, 1} = reference_lc_peaks(sampled_tc{lc}, storm_data, storm_duration_days, C); % Life-Cycle Peaks Layout (chess.Common.lcs_columns)
            fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
        end
    end
end
if ~hot_start
    disp('     Sampling Tropical Events .....');
    fprintf(1,'      Completion Progress: %3d%%\n',0);
    if ~settings.use_peaks
        % Timeseries Only: Storm IDs Drawn From The Timeseries Storms
        tc_storm_ids = cell2mat(storm.TC.Timeseries.Default(:, 1));
    end
    for lc=1:number_of_life_cycles
        if settings.use_peaks
            [sampled_tc{lc, 1},...
                project_forcing.Peaks.Default.('TC'){lc, 1}] = ...
                chess.Model.LifeCycle.sample_tropical_storms(cell2mat(storm.TC.Peaks.Default), settings.simulation_years, prob_mass, lcs_mode, storm_duration_days);
        else
            sampled_tc{lc, 1} = chess.Model.LifeCycle.sample_tropical_storms(tc_storm_ids, settings.simulation_years, prob_mass, lcs_mode, storm_duration_days);
        end
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(lc/number_of_life_cycles)));
    end
end
% Replicate Storm Sampling With Storm Timeseries
if config.use_timeseries == 1
    ts_dur = sampled_storm_durations(sampled_tc, storm.('TC').('Timeseries').('Default'), config.storm_duration, settings.compute_storm_duration, 'TC');
end
for lc=1:number_of_life_cycles
    if config.use_timeseries == 1
        % Build LCS Timeseries Dataset
        project_forcing.Timeseries.Default.('TC'){lc, 1} = timeseries_lc_creation(sampled_tc{lc, 1},...
            storm.('TC').('Timeseries').('Default'), ts_dur, C, C_ts);
    end
    % Create Alternate Datasets
    if config.create_wlp == 1
        project_forcing.Peaks.WLP.('TC'){lc, 1} = ...
            sample_alternate_dataset(cell2mat(storm.TC.Peaks.WLP),...
            sampled_tc{lc, 1}, project_forcing.Peaks.Default.('TC'){lc, 1}, C);
    end
    if config.create_whp == 1
        project_forcing.Peaks.WHP.('TC'){lc, 1} = ...
            sample_alternate_dataset(cell2mat(storm.TC.Peaks.WHP),...
            sampled_tc{lc, 1}, project_forcing.Peaks.Default.('TC'){lc, 1}, C);
    end
end
end

function project_forcing = combine_storm_type_life_cycles(project_forcing, config, settings, C)
for lc=1:settings.number_of_life_cycles
    if settings.use_peaks
        % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
        project_forcing.Peaks.Default.('CC'){lc, 1} = sortrows([project_forcing.Peaks.Default.('TC'){lc, 1};...
            project_forcing.Peaks.Default.('XC'){lc, 1}],[C.year, C.order, C.bin]);
    end

    if settings.whp_switch
        % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
        project_forcing.Peaks.WHP.('CC'){lc, 1} = sortrows([project_forcing.Peaks.WHP.('TC'){lc, 1};...
            project_forcing.Peaks.WHP.('XC'){lc, 1}],[C.year, C.order, C.bin]);
    end
    if settings.wlp_switch
        % Combined Suite Of XC and TC for Simulation Period Per Each Modeled Life-Cycle
        project_forcing.Peaks.WLP.('CC'){lc, 1} = sortrows([project_forcing.Peaks.WLP.('TC'){lc, 1};...
            project_forcing.Peaks.WLP.('XC'){lc, 1}],[C.year, C.order, C.bin]);
    end
    % Combine Timseries Data
    if config.use_timeseries == 1
        project_forcing.Timeseries.Default.('CC'){lc, 1} = sortrows([project_forcing.Timeseries.Default.('TC'){lc, 1};...
            project_forcing.Timeseries.Default.('XC'){lc, 1}],[C.year, C.order, C.bin]);
    end
end
end

function project_forcing = remove_unrequested_alternate_datasets(project_forcing, settings)
if ~settings.use_peaks
    return
end
% Wave Height Priority
if settings.whp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WHP');
end
% Water Level Priority
if settings.wlp_switch == 0
    % Remove Empty Field (Tropicals)
    project_forcing.Peaks = rmfield(project_forcing.Peaks,'WLP');
end
end

function save_sampling_seed(config, lcs_mode, sampled_xc, sampled_tc, project_forcing)
storm_sampling = config.storm_sampling;
if isfield(config, 'out_files') && isfield(config.out_files, 'project_forcing')
    lcs_restrict_sampling_rate = lcs_mode;
    sampled_ids = struct();
    if contains(storm_sampling, {'XC','CC'})
        sampled_ids.XC = sampled_xc;
    end
    if contains(storm_sampling, {'TC','CC'})
        sampled_ids.TC = sampled_tc;
    end
    seed_vars = {'lcs_restrict_sampling_rate', 'sampled_ids'};
    if contains(storm_sampling, {'XC','CC'}) && config.use_peaks == 1
        xc_peaks = struct('Default', {project_forcing.Peaks.Default.('XC')});
        seed_vars{end+1} = 'xc_peaks';
    end
    seed_file = chess.ProjectPaths.sampling_seed_file(config.out_files.project_forcing);
    if ~isfolder(fileparts(seed_file))
        mkdir(fileparts(seed_file));
    end
    save(seed_file, seed_vars{:}, '-v7.3');
end
end

function check_storms_per_life_cycle(stm_type, storm_rate, n_years, mode)
if ~(storm_rate > 0)
    error('chess:Model:LifeCycle:rateTooLow', 'LCS sampling: the %s storm rate is %g storms/yr; no %s storms can be sampled.', stm_type, storm_rate, stm_type);
elseif mode == 1 && ~(storm_rate*n_years > 1)
    error('chess:Model:LifeCycle:rateTooLow', ['LCS sampling: expected %s storms per life cycle = %.2f (%.3f storms/yr x %d yr). ',...
        'Rate-matched life-cycle sampling needs more than 1; increase mcs_nYears to at least %d.'],...
        stm_type, storm_rate*n_years, storm_rate, n_years, floor(1/storm_rate) + 1);
end
end

function dur = sampled_storm_durations(sampled, storm_ts, storm_duration, compute_storm_duration, storm_type)
% Storm Duration [days] Of Every Sampled Storm (storm_durations), Computed Once Per Storm ID And
% Reused In Every Life Cycle The Storm Appears In. NaN For Database Storms Not Sampled
dur = NaN(size(storm_ts, 1), 1);
ids = unique(cell2mat(cellfun(@(x) x(:, 1), sampled(:), 'un', false)));
rows = find(ismember(cell2mat(storm_ts(:, 1)), ids));
dur(rows) = chess.Model.storm_durations(storm_ts(rows, 2), storm_duration, compute_storm_duration, cell2mat(storm_ts(rows, 1)), storm_type);
end

function lc_out = timeseries_lc_creation(sample_indx, storm, ts_dur, C, C_ts)
% Life Cycle Without Storms
if isempty(sample_indx)
    lc_out = zeros(0, C.n_timeseries);
    return
end
% Indentify Storm IDs To Pull Hydrographs For
[~, pull_indx] = arrayfun(@(x) ismember(x,...
    cell2mat(storm(:, 1))),...
    sample_indx(:, 1), 'un', true);
% Pull Hydrographs
stm_mat = cell2mat(storm(pull_indx, 2));
% Pull And Reshape Sampling Index Information
% (Row Count, Not length(): length Returns The Largest Dimension, So A Hydrograph With
%  Fewer Time Steps Than Data Columns Would Get The Column Count)
sample_indx_hyd = cell2mat(arrayfun(@(y, z) repmat(sample_indx(z, :), y, 1),...
    cellfun(@(x) size(x, 1), storm(pull_indx, 2)),...
    [1:size(sample_indx, 1)]', 'un', false));
% Create Timestep Arrays To Append
stm_tstp = arrayfun(@(x) [0:x-1]',...
    cellfun(@(x) size(x, 1), storm(pull_indx, 2)),'un', false);
% Build LCS Timeseries Dataset (Storm Database Columns: SWL Hm0 Tp wDir datenum dt)
lc_out = zeros(size(stm_mat, 1), C.n_timeseries);
lc_out(:, [C.id, C.bin, C.year, C.order]) = sample_indx_hyd;
lc_out(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir, C.dt]) = stm_mat(:, [1 2 2 3 4 6]);
lc_out(:, C.step) = cell2mat(stm_tstp);
lc_out(:, C_ts.storm_duration) = repelem(ts_dur(pull_indx), cellfun(@(x) size(x, 1), storm(pull_indx, 2)));
end

function seed = load_reference_xc_seed(ref_pf_file, sampled, ref_label, C)
% Returns The Reference's Raw XC Default Peaks (Life Cycles) When They Match The Loaded Sampling Seed, Else []
seed = [];
seed_file = chess.ProjectPaths.sampling_seed_file(ref_pf_file);
if ~ismember('xc_peaks', who('-file', seed_file))
    disp(['     Warning: sampling seed file of ' ref_label ' holds no XC sampled peak values (sampled with use_peaks = 0); XC peak values are rebuilt from the storm database.']);
    return
end
S = load(seed_file, 'xc_peaks');
ok = isfield(S, 'xc_peaks') && isfield(S.xc_peaks, 'Default') && numel(S.xc_peaks.Default) == numel(sampled) &&...
    all(cellfun(@(a, b) isequal(a(:, [C.id, C.bin, C.year, C.order]), b), S.xc_peaks.Default(:), sampled(:)));
if ok
    seed = S.xc_peaks.Default;
    disp(['     Loading XC sampled peak values (copula) from ' ref_label]);
else
    disp(['     Warning: sampling seed file of ' ref_label ' does not match its sampled storms; XC peak values are rebuilt from the storm database.']);
end
end

function lc_peaks = reference_lc_peaks(sampled, storm_data, duration_days, C)
% Life-Cycle Peaks Layout (chess.Common.lcs_columns)
% Find Sampled Event On Storm Suite
stm_indx = arrayfun(@(x) find(cell2mat(storm_data(:, 1)) == x), sampled(:, 1), 'un', true);
% Pull Storm Data (Explicit Size: A Life Cycle Without Storms Must Still Have All Columns)
lc_peaks = zeros(numel(stm_indx), C.n_peaks);
lc_peaks(:, [C.id, C.bin, C.year, C.order]) = sampled;
for ss = 1:numel(stm_indx)
    % Storm Database Columns: SWL Hm0 Tp wDir
    lc_peaks(ss, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir]) = storm_data{stm_indx(ss), 2}(:, [1 2 2 3 4]);
end
lc_peaks(:, C.storm_duration) = duration_days;
end

function d = copy_columns(d, s, cols)
d(:, cols) = s(:, cols);
end

function confirm_not_converged(conv, stm_type, prompt)
msg = sprintf('%s: mcs_nLC = %d is below the %d life cycles required for convergence.', stm_type, conv.nLC, conv.nLC_req);
if prompt ~= 1
    warning('chess:Model:LifeCycle:notConverged', '%s Continuing (lcs_convergence_prompt = 0).', msg);
    return
end
while true
    reply = lower(strtrim(input(sprintf('   %s Proceed or cancel? [p/c]: ', msg), 's')));
    if any(strcmp(reply, {'p', 'proceed'}))
        return
    elseif any(strcmp(reply, {'c', 'cancel'}))
        error('chess:Model:LifeCycle:cancelled', ['Life-cycle simulation cancelled. %s Set mcs_nLC >= %d in the input file ',...
            '(or relax lcs_convergence_tol / lcs_convergence_confidence).'], msg, conv.nLC_req);
    end
end
end

function lcs_default = sample_alternate_dataset(storm_data, sampled_indx, lcs_default, C)
% Get Row Index (Database Row Of Each Sampled Storm)
[~, bi] = ismember(sampled_indx(:, 1), storm_data(:, 1));
% Pull WLP/WHP Dataset For Sampled Storms (Life-Cycle Rows Keep Their Order; Was lcs_default(bi, ...),
% Which Used Database Rows As Life-Cycle Rows And Padded The Life Cycle With Zero Rows).
% storm_data Columns: ID SWL Hm0 Tp wDir datenum; C.storm_duration Stays From lcs_default (config.storm_duration)
lcs_default(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir]) = storm_data(bi, [2 3 3 4 5]);
end

function [ok, sampled_ids] = read_seed(pf_file)
sampled_ids = struct();
seed_file = chess.ProjectPaths.sampling_seed_file(pf_file);
ok = isfile(seed_file) && all(ismember({'lcs_restrict_sampling_rate', 'sampled_ids'}, who('-file', seed_file)));
if ok
    S = load(seed_file, 'sampled_ids');
    sampled_ids = S.sampled_ids;
end
end

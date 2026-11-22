classdef Pros < chess.Model
    % Pros  Probabilistic response of structures (PROS).
    %   model = chess.Model.create(inputs) returns this class for workflow 1
    %   (response based) and workflow 4 (frequency based).
    %
    %   Response based: the forcing of every storm carries one column per
    %   replicate of the forcing uncertainty; the responses of every
    %   replicate are computed and their per-storm maxima are fitted
    %   (XC: peaks over threshold, TC: joint probability method; CC: both
    %   combined). Frequency based: the hazard curves of the forcing are
    %   built first and the responses are computed from them; this is also
    %   how the secondary responses (wall pressures p2/p3, nappe) are
    %   obtained in a response based run.
    %
    %   Standalone tools (work on saved results):
    %     response_based_hazard_curves - fit the hazard curves of responses,
    %                                    response by response (XC, TC, CC)
    %     combine_hazard_curves        - combine TC and XC curves of a shared
    %                                    response grid
    %     frequency_based_hazard_curves - one response from saved forcing curves
    %
    %   See also chess.Model, chess.ExtremeValueAnalysis.

    properties (Constant, Access = protected)
        run_label = 'Probabilistic Response Of Structures (PROS)'
    end

    methods
        function obj = Pros(varargin)
            % Pros  PROS model of a ready configuration (see chess.Model.create).
            %   obj = chess.Model.Pros(config, protection_system, storm_database)
            obj@chess.Model(varargin{:});
        end

        function hazard_curves = response_based_hazard_curves(obj, responses, probability_mass, outPath)
            % response_based_hazard_curves  Fit the hazard curves of every response, response by response (XC, TC and CC).
            %   hazard_curves = model.response_based_hazard_curves(responses)
            %   hazard_curves = model.response_based_hazard_curves(responses, probability_mass, out_path)
            %   responses: struct with one field per storm type ('XC' and/or
            %   'TC'), each a struct with one field per response (and forcing
            %   curve input), storms x replicates of per-storm maxima. The
            %   z = 0 replicate is dropped before fitting. TC forcing curves
            %   (registry rows with partition_uncertainty: SWL, Hm0_offshore,
            %   Hm0_toe, Tp) hold the replicates of the first uncertainty
            %   partition (forcing_curve_values) and their confidence limits
            %   use the uncertainty left
            %   (chess.ExtremeValueAnalysis.uncertainty_after_partition); XC
            %   forcing curves are one column of z = 0 values.
            %   probability_mass: probability mass of each TC storm ([] without
            %   TC). XC: peaks-over-threshold fit
            %   (chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique;
            %   record length Nyrs_XC times the number of replicates). TC: joint
            %   probability method
            %   (chess.ExtremeValueAnalysis.JointProbabilityMethod, integration
            %   method 1) with the probability mass of each storm shared by its
            %   replicates.
            %   Great Lakes water levels are fitted as surge (mean lake level
            %   removed and added back).
            %   For each response: every storm type is fitted, one fixed
            %   response grid is used for all of them
            %   (chess.Common.response_hazard_grid: the registry / unit_kind
            %   range; it warns when fitted curve values of any confidence
            %   limit fall outside that range), each fit gives its exceedance
            %   on that grid (x_grid),
            %   and, when both storm types are given, the TC and XC curves are
            %   combined (CC, combine_hazard_curves). The fits live only within
            %   the iteration of their response.
            %   hazard_curves: struct with the fields XC and TC of the given
            %   storm types, and CC when both are given and both have curves;
            %   each a struct array, one entry per fitted response ([] when
            %   none; fields of set_hazard_curve_entry: var, CL, x_plot,
            %   y_plot, x_table, y_table, x_table_ARI, POT, y_label, title,
            %   y_log_scale, save_name, n_events, n_dropped, lake_offset,
            %   x_grid, y_grid). Entries follow the response order of each
            %   storm type (CC: TC order).
            if nargin < 3
                probability_mass = [];
            end
            if nargin < 4
                outPath = '';
            end
            use_aep = obj.config.pros_use_aep;
            disp('            Building hazard curves....');

            %% RESPONSES OF EACH STORM TYPE (XC FIRST)
            storm_types = reshape(intersect({'XC', 'TC'}, fieldnames(responses), 'stable'), 1, []);
            names_of = struct();
            all_names = {};
            for st = storm_types
                if ~isstruct(responses.(st{1}))
                    error('chess:Model:Pros:invalidResponses', 'responses.%s must be a struct of computed responses (one per storm type).', st{1});
                end
                names = fieldnames(responses.(st{1}));
                % TC Probability Masses Are No Response
                names_of.(st{1}) = reshape(names(~contains(names, {'TC_Prob'})), 1, []);
                all_names = [all_names, names_of.(st{1})]; %#ok<AGROW>
            end
            all_names = unique(all_names, 'stable');
            combine = numel(storm_types) == 2;

            %% RESPONSE LOOP: FIT, SHARED GRID, EXCEEDANCE ON THE GRID, COMBINATION
            entries = struct('XC', {cell(1, numel(all_names))}, 'TC', {cell(1, numel(all_names))}, 'CC', {cell(1, numel(all_names))});
            for ii = 1:numel(all_names)
                resp_var = all_names{ii};
                % 1. Fit Each Storm Type
                fits = struct();
                for st = storm_types
                    if ismember(resp_var, names_of.(st{1}))
                        fit = obj.fit_hazard_curve(responses.(st{1}).(resp_var), st{1}, resp_var, probability_mass, outPath, ii, numel(all_names));
                        if ~isempty(fit)
                            fits.(st{1}) = fit;
                        end
                    end
                end
                fitted_types = reshape(fieldnames(fits), 1, []);
                if isempty(fitted_types)
                    continue;
                end
                % 2. Fixed Response Grid; The Fitted Curves (All CL Columns, Untrimmed, No Lake Level) Only Checked Against Its Range
                curve_values = cellfun(@(st) fits.(st).hazard.HC_plt(:), fitted_types, 'un', false);
                grid = chess.Common.response_hazard_grid(resp_var, vertcat(curve_values{:}));
                % 3. Exceedance Of Each Fit On The Grid; Hazard Curve Entries (Mean Lake Level Added Back To Response Values)
                for st = fitted_types
                    fit = fits.(st{1});
                    entry = chess.Model.Pros.set_hazard_curve_entry([], 1, resp_var, fit.y_label, fit.title_str,...
                        fit.hazard.HC_plt_x, fit.hazard.HC_plt + fit.lake_offset,...
                        fit.hazard.HC_tbl_x, fit.hazard.HC_tbl + fit.lake_offset, fit.POT,...
                        fit.y_log_scale, fit.CL, fit.save_name, fit.n_events, fit.n_dropped, fit.lake_offset,...
                        fit.method.exceedance_at_grid(grid), grid + fit.lake_offset);
                    entry.x_table_ARI = table_return_periods(entry.x_table_ARI, use_aep);
                    entries.(st{1}){ii} = entry;
                end
                % 4. Combined Curve (CC)
                if combine && all(isfield(fits, {'XC', 'TC'}))
                    entries.CC{ii} = obj.combine_hazard_curves(entries.TC{ii}, entries.XC{ii});
                end
            end

            %% OUTPUT PER STORM TYPE
            hazard_curves = struct();
            for st = storm_types
                hazard_curves.(st{1}) = ordered_entries(entries.(st{1}), all_names, names_of.(st{1}));
            end
            if combine && ~isempty(hazard_curves.XC) && ~isempty(hazard_curves.TC)
                hazard_curves.CC = ordered_entries(entries.CC, all_names, names_of.TC);
                if isempty(hazard_curves.CC)
                    hazard_curves.CC = hazard_curves.TC([]);
                end
            end
        end

        function cc_curves = combine_hazard_curves(obj, tc_curves, xc_curves)
            % combine_hazard_curves  Combine the TC and XC hazard curves of each response (CC).
            %   cc_curves = model.combine_hazard_curves(tc_curves, xc_curves)
            %   tc_curves, xc_curves: hazard curve entries
            %   (response_based_hazard_curves TC and XC) paired by name (TC
            %   order); responses without a pair, skipped by the registry
            %   (cc_rule 'skip') or without x_grid (frequency based) are left
            %   out. A pair must share its response grid (y_grid), as the
            %   entries of one response_based_hazard_curves call do
            %   ('chess:Model:Pros:responseGridMismatch' otherwise).
            %   Everything is combined in AEP from the untrimmed curves
            %   (chess.ExtremeValueAnalysis.combine_storm_hazards): the best
            %   estimate adds the XC and TC best-estimate AEPs of each grid
            %   level (x_grid) and is read at the untrimmed table and plot AEPs
            %   (chess.ExtremeValueAnalysis.hazard_table_probabilities,
            %   hazard_plot_frequencies); the confidence limits follow the rule
            %   of the response (chess.Common.response_registry). CC x_grid:
            %   the summed AEP (best estimate) and the CC confidence-limit plot
            %   curves inverted at y_grid
            %   (chess.ExtremeValueAnalysis.exceedance_at_response), converted
            %   to AEF when pros_use_aep = 0; an AEP >= 1 is NaN in both modes.
            %   cc_curves: one entry per combined response with the TC entry
            %   labels (title and figure name with CC, POT a note, n_events and
            %   n_dropped [XC, TC], x_table_ARI of the kept table rows).
            config = obj.config;
            use_aep = config.pros_use_aep;
            %% UNTRIMMED TABLE AND PLOT FREQUENCIES (AS STORED) AND THEIR AEPs
            table_x = chess.ExtremeValueAnalysis.hazard_table_probabilities(use_aep);
            plot_aef = chess.ExtremeValueAnalysis.hazard_plot_frequencies();
            if use_aep == 1
                plot_x = chess.ExtremeValueAnalysis.aef_to_aep(plot_aef);
                table_aep = table_x;
                plot_aep = plot_x;
                to_aep = @(x) x;
            else
                plot_x = plot_aef;
                table_aep = chess.ExtremeValueAnalysis.aef_to_aep(table_x);
                plot_aep = chess.ExtremeValueAnalysis.aef_to_aep(plot_aef);
                to_aep = @chess.ExtremeValueAnalysis.aef_to_aep;
            end
            % Pair TC & XC Responses By Name (TC Order; Responses Without A Pair Are Dropped)
            xc_vars = {xc_curves.var};
            cc_curves = tc_curves([]);
            for j = find(ismember({tc_curves.var}, xc_vars))
                tc_j = tc_curves(j);
                % Registry Rules (chess.Common.response_registry): Skipped Responses; U_r Only Feeds The ALS Confidence Limits
                row = chess.Common.response_registry('name', tc_j.var);
                if ~isempty(row) && strcmp(row.cc_rule, 'skip')
                    continue;
                end
                xc_j = xc_curves(find(strcmp(xc_vars, tc_j.var), 1));
                % Frequency-Based Entries Have No Grid
                if isempty(tc_j.x_grid) || isempty(xc_j.x_grid)
                    continue;
                end
                if ~isequal(tc_j.y_grid, xc_j.y_grid)
                    error('chess:Model:Pros:responseGridMismatch',...
                        'The TC and XC hazard curves of %s have different response grids (y_grid): fit them together with response_based_hazard_curves.', tc_j.var);
                end
                u_field = [];
                if ~isempty(row) && strcmp(row.cc_confidence_limit_method, 'als_relative')
                    u_field = config.(row.relative_uncertainty);
                end
                disp(['               Combining ' tc_j.var ' hazard curves....']);
                tc_grid_aep = to_aep(tc_j.x_grid);
                xc_grid_aep = to_aep(xc_j.x_grid);
                % Combine HCs To Create Table
                y_table = chess.ExtremeValueAnalysis.combine_storm_hazards(tc_grid_aep, xc_grid_aep,...
                    tc_j.y_grid, table_aep, tc_j.y_log_scale, tc_j.CL, u_field, tc_j.var);
                % Combine HCs To Create Plot
                [y_plot, combined_aep] = chess.ExtremeValueAnalysis.combine_storm_hazards(tc_grid_aep, xc_grid_aep,...
                    tc_j.y_grid, plot_aep, tc_j.y_log_scale, tc_j.CL, u_field, tc_j.var);
                % Exceedance On The Grid: Summed AEP (BE), Inverted CC Confidence-Limit Curves
                x_grid = [combined_aep, chess.ExtremeValueAnalysis.exceedance_at_response(plot_aep, y_plot(:, 2:end), tc_j.y_grid)];
                x_grid(x_grid >= 1) = NaN;
                if use_aep ~= 1
                    x_grid = chess.ExtremeValueAnalysis.aep_to_aef(x_grid);
                end
                % Figure Title: CC, Events Not Fitted [XC, TC]
                title_str = tc_j.title;
                title_str(2) = {strrep(title_str{2},'TC','CC')};
                n_events = [xc_j.n_events, tc_j.n_events];
                n_dropped = [xc_j.n_dropped, tc_j.n_dropped];
                title_str(2) = {regexprep(title_str{2}, ' \| \d+ of \d+ events not fitted$', '')};
                if any(n_dropped > 0)
                    title_str(2) = {sprintf('%s | XC %d/%d, TC %d/%d not fitted', title_str{2},...
                        n_dropped(1), n_events(1), n_dropped(2), n_events(2))};
                end
                entry = chess.Model.Pros.set_hazard_curve_entry([], 1, tc_j.var, tc_j.y_label, title_str,...
                    plot_x, y_plot, table_x, y_table, {'Hazard curve computed by combining TC & XC primary responses'},...
                    tc_j.y_log_scale, tc_j.CL, strrep(tc_j.save_name,'TC','CC'), n_events, n_dropped, tc_j.lake_offset,...
                    x_grid, tc_j.y_grid);
                % CC Return Periods: Kept Table Rows Only
                entry.x_table_ARI = table_return_periods(entry.x_table_ARI(table_x >= 0.001), use_aep);
                cc_curves(end+1) = entry; %#ok<AGROW>
            end
        end

        function fb_curve = frequency_based_hazard_curves(obj, hazard_curves, storm_type, response_name)
            % frequency_based_hazard_curves  Frequency-based hazard curve of one response from saved forcing curves.
            %   fb_curve = model.frequency_based_hazard_curves(hazard_curves, storm_type, response_name)
            %   hazard_curves: saved hazard curves of one storm type holding the
            %   forcing curves (SWL, Hm0_offshore, Hm0_toe, Tp). The forcing
            %   curves are sampled with their uncertainty (10000 samples per
            %   exceedance level; SWL on the surge, Hm0_offshore and Hm0_toe
            %   with the absolute and relative uncertainty of the same draw, Tp
            %   relative from that draw; TC / CC curves with the uncertainty
            %   left after the first partition,
            %   chess.ExtremeValueAnalysis.uncertainty_after_partition) and
            %   the response is computed for every sample; the curve is the
            %   requested confidence limits of those responses. [] when the
            %   response gives no curve.
            config = obj.config;
            forcing_names = chess.Common.pros_forcing_curves();
            missing = setdiff(forcing_names, {hazard_curves.var}, 'stable');
            if ~isempty(missing)
                error('chess:Model:Pros:missingForcingCurves',...
                    'The %s hazard curves have no forcing curve for %s: run PROS with the forcing hazard curves on.',...
                    storm_type, strjoin(missing, ', '));
            end
            row = chess.Common.response_registry('name', response_name, 'fitted_by_pros_rb', true, 'data_type', 'Peaks', 'structure_type', config.struc_type);
            if isempty(row)
                error('chess:Model:Pros:notEligible',...
                    '%s has no frequency-based hazard curve for this structure type (PROS-RB fitted responses computed for Peaks only).', response_name);
            end

            config_fb = config;
            for switch_name = chess.Common.response_registry('output', 'switches')
                config_fb.(switch_name{1}) = 0;
            end
            config_fb.(row.compute_switch) = 1;
            config_fb.compute_q_vol = 0;

            forcing_entries = hazard_curves(ismember({hazard_curves.var}, forcing_names));
            fb_curves = obj.frequency_based(config_fb, struct(storm_type, forcing_entries), '', 4);
            fb_curves = fb_curves.(storm_type);
            fb_curve = fb_curves(strcmp({fb_curves.var}, response_name));
            if isempty(fb_curve)
                fb_curve = [];
            end
        end
    end

    methods (Static)
        function rules = workflow_input_rules()
            % workflow_input_rules  Inputs only PROS needs (chess.Model.input_rules).
            rules = [...
                chess.Config.input_rule('pros_use_aep', 'switch'),...
                chess.Config.input_rule('pros_compute_forcing_HC', 'switch')];
        end
    end

    methods (Access = protected)
        function forcing = build_storm_forcing(obj, storm, prob_mass)
            % One column per replicate (XC 21, TC 445; z = 0 in the middle column)
            forcing = obj.format_storm_forcing(storm, prob_mass, true);
        end

        function data = apply_forcing_uncertainty(obj, data, storm_type)
            % Forcing uncertainty of one dataset: every replicate column is the storm value shifted by its z-score
            %   SWL: absolute and relative uncertainty on the surge (mean lake
            %   level removed and added back). Hm0_offshore: same on the wave
            %   height of the curated storm data
            %   (chess.CoastalHazardSystem.curate_storm_forcing). Tp:
            %   relative, sqrt(1 + chs_hm0_u_r) - 1. Then the Hm0 floor
            %   (chess.CoastalHazardSystem.floor_wave_height): Hm0_offshore
            %   <= 0.01 m -> 0.01 m with the Wilson Tp (about 0.199 s) on those
            %   entries; NaN kept. At Hm0 <= 0.1 m only the stone sizes and
            %   the seaside damage are NaN (q and R2p are still computed).
            config = obj.config;
            %% GRAB INFORMATION FROM "config"
            swl_u_a = config.chs_swl_u_a;
            hm0_u_a = config.chs_hm0_u_a;
            swl_u_r = config.chs_swl_u_r;
            hm0_u_r = config.chs_hm0_u_r;
            % PROS Dataset (chess.Model.build_forcing (uncertainty step))
            % Water Level
            SWL = data.('SWL');
            % Wave Height (Offshore: Hm0_toe Is Derived From It By chess.Model.build_forcing (adjustment step))
            Hm0 = data.('Hm0_offshore');
            % Wave Peak Period
            Tp = data.('Tp');
            % Copy Normal Distribution Accross All Events 
            z_scores = chess.Common.discrete_standard_normal_scores(storm_type)';
            z_scores_per_storm = repmat({z_scores}, size(SWL));
            % Lake Specific Level (Uncertainty Needs To Be Computed For Surge Not TWL)
            lake_level = chess.Common.mean_lake_level(config);

            %% APPLY SWL UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
            % Apply uncertainty using the discrete standard normal scores (z_scores)
            % ------------------ SWL ------------------
            SWL = cellfun(@(x, y) x - lake_level, SWL ,'un',false);
            SWL = cellfun(@(x, y) chess.ExtremeValueAnalysis.apply_uncertainty(x, swl_u_a, swl_u_r, y),SWL, z_scores_per_storm,'un',false);
            SWL = cellfun(@(x, y) x + lake_level, SWL ,'un',false);

            %% APPLY Hm0 & Tp UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
            Hm0 = cellfun(@(x, y) chess.ExtremeValueAnalysis.apply_uncertainty(x, hm0_u_a, hm0_u_r, y), Hm0, z_scores_per_storm, 'un', false);
            % Tp
            Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
            Tp = cellfun(@(x, y) x.*(1+Tp_U.*y), Tp, z_scores_per_storm, 'un', false);
            [Hm0, Tp] = cellfun(@chess.CoastalHazardSystem.floor_wave_height, Hm0, Tp, 'un', false);

            %% Store Results
            data.SWL = SWL;
            data.Hm0_offshore = Hm0;
            data.Tp = Tp;

            %% Define internal Aux Function
        end

        function curves = forcing_curve_values(obj, forcing, storm_type)
            % Per-storm values of the forcing hazard curves (chess.Common.pros_forcing_curves) of one dataset and storm type
            %   Built from the z = 0 replicate of forcing (no forcing
            %   uncertainty; tides, swl_slr and the Hm0 floor included);
            %   the replicates of the hydraulics are not used.
            %   XC (one column, fitted by PST): SWL and Hm0_offshore are the
            %   per-storm peaks, Tp the value at the Hm0_offshore peak and
            %   Hm0_toe the per-storm peak of the z = 0 toe series.
            %   TC (storms x 445, z = 0 in the middle column; the registry rows
            %   with partition_uncertainty, fitted with the uncertainty left,
            %   chess.ExtremeValueAnalysis.uncertainty_after_partition): the
            %   replicates of the first uncertainty partition
            %   (chess.ExtremeValueAnalysis.apply_uncertainty 'partition', U of
            %   the registry row), one z-score per column shared by SWL,
            %   Hm0_offshore and Tp; SWL on the surge (mean lake level removed
            %   and added back). SWL, Hm0_offshore and Tp: the XC values
            %   partitioned. Hm0_toe: the z = 0 SWL, Hm0_offshore and Tp series
            %   partitioned, toe_wave_height of each replicate, then the
            %   per-storm peak (no Hm0 floor). A storm whose z = 0 value is NaN,
            %   Inf or <= 0 (SWL: surge) has NaN replicates (its z = 0 column is
            %   kept), as JPM integration method 2 drops such storms.
            %   curves: struct with SWL, Hm0_offshore, Tp, Hm0_toe, storms x
            %   1 (XC) or storms x 445 (TC) double.
            z0_of = @(name) cellfun(@(x) x(:, chess.Common.replicate_z0_col(size(x, 2))), forcing.(name)(:), 'un', false);
            SWL = z0_of('SWL');
            Hm0_off = z0_of('Hm0_offshore');
            Tp = z0_of('Tp');
            curves.SWL = cellfun(@(x) max(x, [], 1), SWL);
            [curves.Hm0_offshore, peak_row] = cellfun(@(x) max(x, [], 1), Hm0_off);
            curves.Tp = cellfun(@(x, row) x(row), Tp, num2cell(peak_row));
            switch storm_type
                case 'XC'
                    curves.Hm0_toe = cellfun(@(x) max(x, [], 1), z0_of('Hm0_toe'));
                case 'TC'
                    config = obj.config;
                    z_scores = chess.Common.discrete_standard_normal_scores('TC')';
                    lake_level = chess.Common.mean_lake_level(config);
                    partition = struct();
                    for name = {'SWL', 'Hm0_offshore', 'Tp'}
                        [U_a, U_r] = chess.Common.response_library_headers(config, name{1});
                        partition.(name{1}) = @(values) chess.ExtremeValueAnalysis.apply_uncertainty(values, U_a, U_r, z_scores, 'partition', true);
                    end
                    surge = curves.SWL - lake_level;
                    curves.SWL = keep_fittable_storms(partition.SWL(surge), surge, z_scores) + lake_level;
                    curves.Hm0_offshore = keep_fittable_storms(partition.Hm0_offshore(curves.Hm0_offshore), curves.Hm0_offshore, z_scores);
                    curves.Tp = keep_fittable_storms(partition.Tp(curves.Tp), curves.Tp, z_scores);
                    toe_peaks = @(swl, hm0, tp) max(obj.toe_wave_height(partition.Hm0_offshore(hm0), partition.Tp(tp),...
                        partition.SWL(swl - lake_level) + lake_level), [], 1);
                    Hm0_toe = cell2mat(cellfun(toe_peaks, SWL, Hm0_off, Tp, 'un', false));
                    curves.Hm0_toe = keep_fittable_storms(Hm0_toe, Hm0_toe(:, z_scores == 0), z_scores);
            end
        end

        function HC_out = dataset_responses(obj, project_forcing, data_type, dataset_name)
            % Responses and hazard curves of one forcing dataset (XC, TC and CC)
            config = obj.config;
            % Overtopping Volume (Q_vol) Is Timeseries Only
            if strcmp(data_type, 'Peaks')
                config.compute_q_vol = 0;
            end
            % Run File Tag: RB / FB (PROS-RB / PROS-FB)
            tag = extractAfter(chess.Model.workflows(config.workflow).wflow_name, 'PROS-');
            if strcmp(data_type, 'Peaks')
                outPath = fullfile(obj.paths.wf_dir, sprintf('%s1_%s', tag, dataset_name));
            else
                outPath = fullfile(obj.paths.wf_dir, [tag '3']);
            end
            %% INITIALIZE FIELDS AND PROMT USER
            % Get AEP vs AEF Flag
            use_aep = config.pros_use_aep;
            % Display PROS Message
            disp(['      Running CHESS: PROS....']);
            % Get Secondary Responses Switch
            varnames = chess.Common.response_registry('output', 'switches', 'pros_secondary_eb1', true);
            % Get Responses To Compute Usign PROS-FB
            fb_responses = cellfun(@(x) config.(x), varnames, 'un', true);
            % Turn Off Responses For RB Section
            config = config_editor(config, varnames, 0);
            % PROS-FB For All Responses
            if config.workflow == 4 % PROS-FB
                % Force Forcing Hazard Curve Creation
                config.pros_compute_forcing_HC = 1;
                % Force Overtopping Dischar Volume To Off
                config.compute_q_vol = 0; % Can't Integrate q Hazard Curve
                % Get Responses To Compute
                varnames = chess.Common.response_registry('output', 'switches');
                % Get Responses To Compute Usign PROS-FB
                fb_responses = cellfun(@(x) config.(x), varnames, 'un', true);
                varnames = varnames(logical(fb_responses));
                % Turn Off Responses For RB Section
                config = config_editor(config, varnames, 0);
            end

            %% CHESS: PROS - STRUCTURE RESPONSES OF EACH STORM TYPE (Forcing Hazard Curve Inputs Added: chess.Common.pros_forcing_curves)
            responses = struct();
            probability_mass = [];
            for storm_type = chess.Common.storm_types_for_sampling(config.storm_sampling, {'XC', 'TC'})
                responses.(storm_type{1}) = obj.hydraulic_responses(config, project_forcing.(storm_type{1}), 1);
                if config.pros_compute_forcing_HC == 1
                    curve_values = obj.forcing_curve_values(project_forcing.(storm_type{1}), storm_type{1});
                    for name = fieldnames(curve_values)'
                        responses.(storm_type{1}).(name{1}) = curve_values.(name{1});
                    end
                end
            end
            if isfield(responses, 'TC')
                probability_mass = project_forcing.TC.TC_Prob;
            end

            %% CHESS: PROS - HAZARD CURVES, RESPONSE BY RESPONSE (XC, TC; CC When Both Are Sampled)
            HC_out = obj.response_based_hazard_curves(responses, probability_mass, outPath);

            %% COMPUTE SECONDARY RESPONSES
            % Compute Secondary Response Hazard Curves Using PROS-FB
            if any(fb_responses) || config.workflow == 4
                %
                disp('         Computing Frequency Base Responses Hazard Curves...');
                % Turn On Responses For FB Section
                config = config_editor(config, varnames, 1);
                % Run CHESS PROS-FB
                HC_out = obj.frequency_based(config, HC_out, outPath, config.workflow);
            end
        end

        function tf = uses_peaks_dataset(obj, name)
            tf = ~((strcmp(name, 'WLP') && ~obj.config.create_wlp) || (strcmp(name, 'WHP') && ~obj.config.create_whp));
        end

        function data_out = frequency_based(obj, config, data_in, outPath, workflow)
            % Frequency-based hazard curves from the forcing curves of data_in
            %   workflow 1: secondary responses only (p2/p3 from the p1 curve,
            %   nappe from the q curve). workflow 4: every response switched
            %   on in config, from sampled forcing curves.
            pse = obj.protection_system;
            % ==========================================
            % 1. INITIALIZE CONFIG & STRUCTURE DETAILS
            % ==========================================
            proj_name = config.project_name;
            struc_id  = strrep(config.struc_id, '_', ' ');
            case_name = strrep(config.case_name, '_', ' ');
            save_name = fullfile(outPath, [proj_name, '_', struc_id]);
            config.compute_q_vol = 0; % Force Q vol to 0
            p2_p3_names = chess.Common.response_registry('output', 'names', 'compute_switch', 'compute_p2_p3');

            % Mean Lake Level (EB2 SWL Uncertainty Is Computed On Surge, Not TWL)
            lake_level = chess.Common.mean_lake_level(config);

            storm_types = fieldnames(data_in);
            data_out = struct();

            % ==========================================
            % 2. PROCESS EACH STORM TYPE
            % ==========================================
            for st = 1:length(storm_types)
                storm_name = storm_types{st};
                hc_data = data_in.(storm_name);
        
                % Pre-allocate/Clear loop variables to prevent cross-contamination
                Output = [];
                Resp = []; 
        
                x_plt = hc_data(1).x_plot;
                x_tbl = hc_data(1).x_table;
                cl    = hc_data(1).CL;
        
                % Clarified Logic: Can we compute secondary responses directly?
                req_p2_p3 = config.compute_p2_p3 == 1;
                req_nappe = config.compute_nappe == 1;
                has_p1    = any(strcmp({hc_data.var}, 'p1'));
                has_q     = any(strcmp({hc_data.var}, 'q'));
        
        
                % Process both 'y_table' and 'y_plot' seamlessly
                for field_str = ["y_table", "y_plot"]
                    field = char(field_str);

                    % Forcing Curves (chess.Common.pros_forcing_curves): Hm0_offshore For Goda/Damaging Depth, Hm0_toe For Toe Responses
                    [SWL, pass_swl] = get_hc_data(hc_data, 'SWL', field);
                    [Hm0_off, pass_hm0_off] = get_hc_data(hc_data, 'Hm0_offshore', field);
                    [Hm0_toe, pass_hm0_toe] = get_hc_data(hc_data, 'Hm0_toe', field);
                    [Tp,  pass_tp]  = get_hc_data(hc_data, 'Tp', field);
            
                    % Abort if minimum hazard curves do not exist
                    if ~(pass_swl && pass_hm0_off && pass_hm0_toe && pass_tp)
                        Resp = [];
                        continue; 
                    end
            
                    % Compute Intermediate Variables
                    Ts = Tp; % assuming narrow spectra
            
                    % Compute Responses
                   switch workflow
                       case 1 % PROS-RB (Only Compute Secondary Responses As EB1 
                           % Check For Compute Specs
                           can_do_secondary = (~req_p2_p3 || has_p1) && (~req_nappe || has_q);
                           if can_do_secondary
                               if req_p2_p3
                                   p1 = get_hc_data(hc_data, 'p1', field);
                                   P = cellfun(@(a, b, s, f) pse.wall_pressures(a, b, s, f), Hm0_off, Ts, SWL, p1, 'UniformOutput', false);
                                   for pp = 1:length(p2_p3_names)
                                       Resp.(field).(p2_p3_names{pp}) = cellfun(@(s) s.(p2_p3_names{pp}), P, 'UniformOutput', false);
                                   end
                               end

                               if req_nappe
                                   q = get_hc_data(hc_data, 'q', field);
                                   nappe = cellfun(@(a, b, c) pse.nappe_jet(b, a, c), SWL, Hm0_toe, q, 'UniformOutput', false);
                                   for nappe_name = fieldnames(nappe{1})'
                                       Resp.(field).(nappe_name{1}) = cellfun(@(s) s.(nappe_name{1}), nappe, 'UniformOutput', false);
                                   end
                               end
                                eb1_fields = fieldnames(Resp.(field));
                                for gg = 1:length(eb1_fields)
                                    Resp.(field).(eb1_fields{gg}) = cell2mat(Resp.(field).(eb1_fields{gg})); 
                                end
                           end
                       case 4 % PROS-EB2 (Compute All PSE Responses As EB2)
                           % Grab Uncertainty                    
                           tp_u = sqrt(1+config.chs_hm0_u_r)-1; %0.0724
                           swl_u = [config.chs_swl_u_a, config.chs_swl_u_r];
                           hm0_u = [config.chs_hm0_u_a, config.chs_hm0_u_r];
                           % Define MC Samples
                           MCsim = 10000; % For EB2
                           % Sample
                           normU_swl = randn(length(SWL{1}),MCsim);
                           normU_hm0 = randn(length(SWL{1}),MCsim);
                           normU_tp = (1+tp_u.*normU_hm0);
                           % SWL
                           project_forcing.SWL = {pcha_forcing_uncertainty_EB2(SWL{1} - lake_level,...
                               swl_u(1), swl_u(2),...
                               normU_swl, storm_name) + lake_level};
                           % Hm0 Offshore (Absolute + Relative Uncertainty)
                           project_forcing.Hm0_offshore = {pcha_forcing_uncertainty_EB2(Hm0_off{1},...
                               hm0_u(1), hm0_u(2),...
                               normU_hm0, storm_name)};
                           % Hm0 At The Toe (Absolute + Relative Uncertainty, Same Draw As Offshore; Samples Are Not Capped By The Breaker Limit)
                           project_forcing.Hm0_toe = {pcha_forcing_uncertainty_EB2(Hm0_toe{1},...
                               hm0_u(1), hm0_u(2),...
                               normU_hm0, storm_name)};
                           % Tp
                           project_forcing.Tp = {Tp{1}.*normU_tp};
                           % Hm0 Floor (chess.CoastalHazardSystem.floor_wave_height): Wilson Tp Where Hm0_offshore Is Floored; A Floored Hm0_toe Keeps The Sampled Tp (Tp Is Shared)
                           [project_forcing.Hm0_offshore{1}, project_forcing.Tp{1}] = chess.CoastalHazardSystem.floor_wave_height(project_forcing.Hm0_offshore{1}, project_forcing.Tp{1});
                           project_forcing.Hm0_toe{1} = chess.CoastalHazardSystem.floor_wave_height(project_forcing.Hm0_toe{1}, project_forcing.Tp{1});
                           % Storm Duration [days] (Peaks Samples: No dt)
                           project_forcing.storm_duration  = {repmat(chess.Common.chess_units('convert', config.storm_duration, 'h', 'day'), size(SWL{1}))};
                           % Per-Sample MC Forcing (Single Column, No z = 0 Replicate): Tag As PROS-FB Even When Called From A PROS-RB Run (chess.Model.Pros.frequency_based_hazard_curves)
                           config_fb = config;
                           config_fb.workflow = 4;
                           Resp.(field) = obj.hydraulic_responses(config_fb, project_forcing, 0);
                           %
                           if ~isempty(Resp.(field))
                               fnames = fieldnames(Resp.(field));
                               for ii = 1:length(fnames)
                                   % Sort AEF Vector Across All MC Sims
                                   resp_sort = sort(Resp.(field).(fnames{ii}){:}, 2);
                                   % Pick Out CL Of Interest
                                   Resp.(field).(fnames{ii}) = resp_sort(:, ceil(MCsim.*hc_data(1).CL./100));
                               end
                               % Make Sure To Overwrite R2p+SWL
                               if any(contains(fnames, {'R2p_SWL'}))
                                   Resp.(field).('R2p_SWL') = cell2mat(SWL) + Resp.(field).('R2p');
                               end
                           end
                   end
                end
        
                % ==========================================
                % 3. APPEND RESULTS TO HAZARD TABLE
                % ==========================================
                if ~isempty(Resp)
                    resp_vars = fieldnames(Resp.y_table);
            
                    for vv = 1:length(resp_vars)
                        v_name = resp_vars{vv};
                        [~, ~, ~, unit_label, lbl_name, y_label, y_scale_log] = chess.Common.response_library_headers(config, v_name);
                
                        % Formatted Strings
                        title_str = {sprintf('CHESS: PROS-FB | %s | %s', case_name, struc_id), ...
                                     sprintf('%s | %s [%s]', storm_name, lbl_name, unit_label)};
                        out_name  = sprintf('%s_%s_%s_Hazard_Curve.png', save_name, v_name, storm_name);
                
                        % Append (No PST/JPM Fit: Count And Grid Fields Kept For Concatenation With The RB Entries)
                        Output = chess.Model.Pros.set_hazard_curve_entry(Output, vv, v_name, y_label, title_str, ...
                            x_plt, [Resp.y_plot.(v_name)], x_tbl, [Resp.y_table.(v_name)], ...
                            {'Computed using frequency base approach.'}, y_scale_log, cl, out_name, [], 0, 0, [], []);
                    end
            
                    % Prioritize existing RB calculations using exact matching
                    rm_indx = ismember({Output.var}, {hc_data.var});
                    data_out.(storm_name) = [hc_data, Output(~rm_indx)];
                else 
                    data_out.(storm_name) = hc_data;
                end
            end
        end
    end

    methods (Access = private)
        function fit = fit_hazard_curve(obj, values, storm_type, resp_var, probability_mass, outPath, response_number, number_of_responses)
            % Fit of one response and storm type (PST for XC, JPM for TC); [] when the response is skipped
            %   fit: hazard (PST/JPM output, no lake level), method (the fitted
            %   object, exceedance_at_grid), the entry labels and event counts.
            config = obj.config;
            fit = [];
            %% GRAB DETAILS FROM "config"
            case_name = strrep(config.case_name,'_',' ');
            struc_id = strrep(config.struc_id,'_',' ');
            % Grab Percentiles
            try
                prc = [cellfun(@str2double,strsplit(config.project_CLs(2:end-1),{' '}))];
            catch
                prc = [];
            end
            % Save Name
            save_name = fullfile(outPath, [config.project_name,'_', config.struc_id]);

            %% PREP RESPONSE FOR PST/JPM
            % Search Response Library For Uncertainty Values & Associated Labels
            [U_a, U_r, uncert_treatment,...
                unit_label,...
                var_name, y_label, y_scale_log] = chess.Common.response_library_headers(config, resp_var);
            % Replicates Fitted By PST/JPM (z = 0 Replicate Dropped)
            fit_data = chess.Common.drop_z0(values);
            % Get Data Size
            [drows, dcols] = size(fit_data);
            % Great Lakes Water Levels Are Fitted As Surge (Mean Lake Level Removed, Added Back To The Hazard Curve)
            switch resp_var
                case chess.Common.response_registry('output', 'names', 'datum_elevation', true)
                    lake_offset = chess.Common.mean_lake_level(config);
                otherwise
                    lake_offset = 0;
            end
            % Response Information
            % SLC = 0: The Forcing SWL Already Includes swl_slr (chess.Model.build_forcing (adjustment step))
            response = fit_data(:) - lake_offset;
            record_years = config.Nyrs_XC*dcols;
            % TC Forcing Curves Hold The Replicates Of The First Uncertainty Partition (forcing_curve_values): The Confidence Limits Take The Uncertainty Left
            row = chess.Common.response_registry('name', resp_var);
            if strcmp(storm_type, 'TC') && ~isempty(row) && row.partition_uncertainty
                [U_a, U_r] = chess.ExtremeValueAnalysis.uncertainty_after_partition(U_a, U_r);
            end
            % Check For Full NaN Vector (On Absolute Values)
            if all(isnan(fit_data(:))) || all(fit_data(:)==0)
                % Response Variable Has NaNs For All Entries
                disp(['               No valid responses for ' resp_var ', Skipping response var....']);
                return;
            end
            % Count Events PST/JPM Discard (NaN, Inf, <= 0 After The Lake Level Shift)
            n_events = drows*dcols;
            n_dropped = sum(isnan(response) | isinf(response) | response <= 0);
            if n_dropped > 0
                if lake_offset ~= 0
                    drop_reason = [' (<= 0 after removing mean lake level ' num2str(lake_offset) ' ' chess.Common.chess_units('length') ')'];
                else
                    drop_reason = '';
                end
                disp(['               ' resp_var ': ' num2str(n_dropped) ' of ' num2str(n_events) ' events dropped' drop_reason]);
            end

            %% PREP NAMING STRINGS
            % Define Workflow String
            wstr = chess.Model.workflows(config.workflow).wflow_name;
            % PROS-RB Naming Overwrite When Calling PROS-FB: The Forcing Curves Are Built Response Based
            if config.workflow == 4 && ismember(resp_var, chess.Common.pros_forcing_curves())
                wstr = 'PROS-RB';
            end
            % Define Figure Title
            title_str = {['CHESS: ' wstr ' | '  case_name ' | ' struc_id],...
                ['' storm_type ' | ' var_name ' [' unit_label ']']};
            % Report Events Not Fitted On The Figure Title
            if n_dropped > 0
                title_str{2} = [title_str{2} ' | ' num2str(n_dropped) ' of ' num2str(n_events) ' events not fitted'];
            end

            %% CALL PST/JPM TO BUILD HAZARD CURVES
            switch storm_type
                case 'XC' % PST
                    disp(['               Performing Stochastic Simulation Technique (SST) for station (',num2str(response_number),'/',num2str(number_of_responses),'): ', resp_var]);
                    try
                        method = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique('use_aep', config.pros_use_aep,...
                            'confidence_limits', prc, 'record_years', record_years, 'y_log_scale', y_scale_log);
                        [hazard, method] = method.compute_hazard(response, [], [], resp_var);
                    catch
                        disp(['               Stochastic Simulation Technique (SST) returned error, skipping: ', resp_var]);
                        return;
                    end
                case 'TC' % JPM
                    disp(['               Performing Joint Probability Method (JPM) for station (',num2str(response_number),'/',num2str(number_of_responses),'): ', resp_var]);
                    % Scale Prob Mass If Needed
                    if dcols ~= 1 % Need To Scale DSW For Replicates
                        tc_dsw = repmat(probability_mass./dcols, 1, dcols);
                    else
                        tc_dsw = probability_mass;
                    end
                    % Integration Method 1 For Every Response: With tide_application 0 (Never Set By PROS) Method 1 On The Partitioned
                    % Replicates Equals Method 2 On The z = 0 Values
                    try
                        method = chess.ExtremeValueAnalysis.JointProbabilityMethod('integration_method', 1,...
                            'uncertainty_treatment', uncert_treatment, 'use_aep', config.pros_use_aep,...
                            'confidence_limits', prc, 'y_log_scale', y_scale_log);
                        [hazard, method] = method.compute_hazard(response, tc_dsw(:), U_a, U_r, [], resp_var);
                    catch
                        disp(['               Joint Probability Method (JPM) returned error, skipping: ', resp_var]);
                        return;
                    end
            end
            % chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique Returns Fit Errors In ME Instead Of Raising Them
            if (isfield(hazard, 'ME') && ~isempty(hazard.ME)) || ~isfield(hazard, 'HC_plt') || isempty(hazard.HC_plt) || all(isnan(hazard.HC_plt(:)))
                if isfield(hazard, 'ME') && ~isempty(hazard.ME)
                    fail_msg = hazard.ME.message;
                else
                    fail_msg = 'empty or all-NaN curve';
                end
                switch storm_type
                    case 'XC'
                        tool_name = 'PST (chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique)';
                    case 'TC'
                        tool_name = 'JPM (chess.ExtremeValueAnalysis.JointProbabilityMethod)';
                end
                disp(['               ' resp_var ': ' tool_name ' returned no valid curve (' fail_msg '), skipping']);
                return;
            end
            fit = struct('hazard', hazard, 'method', method, 'title_str', {title_str}, 'y_label', y_label,...
                'y_log_scale', y_scale_log, 'CL', [50, prc], 'save_name', [save_name '_' resp_var '_' storm_type '_Hazard_Curve.png'],...
                'n_events', n_events, 'n_dropped', n_dropped, 'lake_offset', lake_offset, 'POT', values);
        end
    end

    methods (Static, Access = private)
        function hazard_curves = set_hazard_curve_entry(hazard_curves, entry_index, var_name, y_label, title_str,...
            x_plot, y_plot, x_table, y_table, POT, y_log_scale, CL, save_name, n_events, n_dropped, lake_offset, x_grid, y_grid)
        % chess.Model.Pros.set_hazard_curve_entry  Write one PROS hazard curve entry.
        %   hazard_curves = chess.Model.Pros.set_hazard_curve_entry(hazard_curves, entry_index,
        %       var_name, y_label, title_str, x_plot, y_plot, x_table, y_table,
        %       POT, y_log_scale, CL, save_name, n_events, n_dropped, lake_offset,
        %       x_grid, y_grid)
        %
        %   Writes one hazard curve entry (one response, one storm type) of the
        %   PROS hazard curve output, with the same fields in the same order for
        %   response-based curves (chess.Model.Pros.response_based_hazard_curves: PST/JPM fit) and
        %   frequency-based curves (chess.Model.Pros (frequency based): no fit), so both
        %   concatenate into one struct array. Plot and table rows keep AEF/AEP
        %   >= 0.001; plot rows are also bounded by the largest table value.
        %   x_table_ARI keeps the full table vector (callers convert it).
        %   x_grid / y_grid (exceedance at the response grid) are stored
        %   untrimmed.
        %
        %   Inputs:
        %     hazard_curves  - hazard curve entries ([] when empty),
        %                      1 x number_of_entries struct
        %     entry_index    - entry to write (created if past the end), scalar
        %                      double
        %     var_name       - response / forcing variable name, char
        %     y_label        - y axis label, char
        %     title_str      - figure title lines, cell
        %     x_plot, y_plot - hazard curve (AEF/AEP, response per CL),
        %                      number_of_rows x 1 and number_of_rows x
        %                      number_of_CLs double
        %     x_table, y_table - hazard table (AEF/AEP, response per CL),
        %                      number_of_rows x 1 and number_of_rows x
        %                      number_of_CLs double
        %     POT            - fitted responses (RB) or a note (FB), double or
        %                      cell
        %     y_log_scale    - y axis log scale flag, scalar double
        %     CL             - percentiles of the curve columns, 1 x
        %                      number_of_CLs double
        %     save_name      - hazard curve figure file, char
        %     n_events       - events handed to PST/JPM ([] without a fit), double
        %     n_dropped      - events PST/JPM discarded (NaN, Inf, <= 0 after
        %                      shift), scalar double
        %     lake_offset    - mean lake level removed before fitting [m], scalar
        %                      double
        %     x_grid         - AEF/AEP (as x_plot) at each level of y_grid,
        %                      untrimmed, number_of_levels x number_of_CLs
        %                      double ([] for frequency-based curves)
        %     y_grid         - response grid, mean lake level included
        %                      [response units], number_of_levels x 1 double
        %                      ([] for frequency-based curves)
        %   Outputs:
        %     hazard_curves - hazard curve entries with entry_index written
        %                     (fields var, CL, x_plot, y_plot, x_table, y_table,
        %                     x_table_ARI, POT, y_label, title, y_log_scale,
        %                     save_name, n_events, n_dropped, lake_offset,
        %                     x_grid, y_grid),
        %                     1 x number_of_entries struct
        %
        %   See also chess.Model.Pros.response_based_hazard_curves, chess.Model.Pros (frequency based).
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        table_rows = x_table >= 0.001;
        plot_rows = x_plot >= 0.001 & x_plot <= max(x_table);
        hazard_curves(entry_index).var = var_name;
        hazard_curves(entry_index).CL = CL;
        hazard_curves(entry_index).x_plot = x_plot(plot_rows, :);
        hazard_curves(entry_index).y_plot = y_plot(plot_rows, :);
        hazard_curves(entry_index).x_table = x_table(table_rows, :);
        hazard_curves(entry_index).y_table = y_table(table_rows, :);
        hazard_curves(entry_index).x_table_ARI = x_table;
        hazard_curves(entry_index).POT = POT;
        hazard_curves(entry_index).y_label = y_label;
        hazard_curves(entry_index).title = title_str;
        hazard_curves(entry_index).y_log_scale = y_log_scale;
        hazard_curves(entry_index).save_name = save_name;
        hazard_curves(entry_index).n_events = n_events;
        hazard_curves(entry_index).n_dropped = n_dropped;
        hazard_curves(entry_index).lake_offset = lake_offset;
        hazard_curves(entry_index).x_grid = x_grid;
        hazard_curves(entry_index).y_grid = y_grid;
        end
    end
end

%% LOCAL FUNCTIONS
function config_out = config_editor(config_out, var_to_look, value)
    % Turn Off Responses For RB Section
    for ii = 1:length(var_to_look)
        config_out.(var_to_look{ii}) = value;
    end
end

function replicates = keep_fittable_storms(replicates, z0_values, z_scores)
    % Storms Whose z = 0 Value Is Not Fittable (NaN, Inf, <= 0) Get NaN Replicates, As JPM Integration Method 2 Drops Them Before Replicating (z = 0 Column Kept For The Overlays)
    replicates(~(isfinite(z0_values) & z0_values > 0), z_scores ~= 0) = NaN;
end

function hazard_curves = ordered_entries(entries, all_names, names)
    % Entries Of One Storm Type In Its Own Response Order (entries Indexed Like all_names; [] When None)
    entries = entries(cellfun(@(name) find(strcmp(all_names, name), 1), names));
    entries = entries(~cellfun(@isempty, entries));
    if isempty(entries)
        hazard_curves = [];
    else
        hazard_curves = [entries{:}];
    end
end

function return_periods = table_return_periods(table_x, use_aep)
    % Return Periods [years] Of The Hazard Table Frequencies (x_table_ARI)
    if use_aep == 1
        return_periods = ceil(1./chess.ExtremeValueAnalysis.aep_to_aef(table_x));
    else
        return_periods = 1./table_x;
    end
end

function [var_out, pass_indx] = get_hc_data(data, varname, field_get)
    var_indx = strcmp(varname, {data.var});
    if any(var_indx)
        pass_indx = true;
        var_out = num2cell(data(var_indx).(field_get), 1);
    else
        pass_indx = false;
        var_out = {NaN};
    end
end

function iVar_w_u = pcha_forcing_uncertainty_EB2(iVar, u_a, u_r, normU, stm_type)
    % TC / CC Forcing Curves Already Hold The First Uncertainty Partition: Sample The Uncertainty Left
    switch stm_type
        case {'TC', 'CC'}
            [u_a, u_r] = chess.ExtremeValueAnalysis.uncertainty_after_partition(u_a, u_r);
    end
    iVar_w_u = chess.ExtremeValueAnalysis.apply_uncertainty(iVar, u_a, u_r, normU);
end


classdef lcs_methods < CHESSPlotsBase
    % lcs_methods  Plots of the life-cycle simulation (LCS) workflow results (workflow 3).
    %   sp = CHESSPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
    %       with config.workflow = 3 returns an lcs_methods object; the
    %       constructor lcs_methods(...) takes the same inputs (documented
    %       in CHESSPlots).
    %
    %   Data: the saved life-cycle matrices project_forcing.<data_type>.
    %   <match_type>.<storm_type>{lc} (columns: lcs_columns) and the
    %   responses aligned row for row (Resp...<storm_type>.<field>{lc});
    %   armor damage under Resp...S (S_* series only when the run saved
    %   them, DPA on). ds_query (every method): struct with storm_type,
    %   data_type ('Peaks' or 'Timeseries') and match_type, see
    %   aux_methods.pull_data.
    %
    %   Methods (in addition to the CHESSPlotsBase methods):
    %     lcs_methods                   - constructor (create through CHESSPlots)
    %     slope_armor_damage_plot       - cumulative armor damage S per life cycle or mean
    %     event_sampling_distribution   - event type mix and mean recurrence rates
    %     mound_damage_dashboard        - 5-panel rubble mound damage dashboard
    %     sampling_scheme_dashboard     - 6-panel storm sampling diagnostics
    %     split_into_events             - split life-cycle vectors into storm events
    %     get_damaging_instances        - time steps where the armor damage grows
    %     plot_mound_damaging_instances_distribution - share of damaging steps per life cycle
    %     plot_pse_submergance_distribution - submergence time distribution by year
    %     plot_mound_final_damage_state - final damage per life cycle and its mean
    %     annual_response_distribution  - storm maxima of a response binned by year
    %     generate_bin_guess            - bin edges spanning a response
    %     compute_annual_distribution   - yearly bin counts or percentages
    %     plot_annual_distribution      - pcolor of a yearly binned distribution
    %     event_choices                 - storm event viewer / response table choices
    %     refine_selection              - life cycle and year of a selection
    %     event_controls                - control row: life cycle, year, peaks view
    %     event_series                  - storm event viewer series
    %     event_table                   - response table rows
    %
    %   Tier: public
    %
    %   See also CHESSPlots, CHESSPlotsBase, pros_methods, det_methods,
    %   chess_lcs, chess_csr.

    methods (Access=public)
        function self = lcs_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
            % lcs_methods  Create the LCS plotting object (use CHESSPlots).
            %   self = lcs_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
            %       passes every input to the CHESSPlotsBase constructor;
            %       the inputs are documented in CHESSPlots.

            self = self@CHESSPlotsBase(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
        end
    end

    methods (Access=public)
        function ax = slope_armor_damage_plot(self, ax, ds_query, field_to_plot, lc_index)
            % slope_armor_damage_plot  Plot the cumulative armor damage S of the life cycles.
            %   ax = slope_armor_damage_plot(self, ax, ds_query, field_to_plot)
            %   ax = slope_armor_damage_plot(self, ax, ds_query, field_to_plot, lc_index)
            %       plots the S_* damage series of each life cycle over
            %       cumulative storm hours, or the Smax / LSmax yearly mean
            %       curve over simulation years. Rubble mound only
            %       (structure.struc_type 3, else an error); Timeseries
            %       results (data_type is set to Timeseries).
            %
            %   Inputs:
            %     ax            - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query      - dataset query (storm_type, match_type)
            %     field_to_plot - armor damage measure (response_registry kind
            %                     'armor_damage': S_seaside_no_repairs, ...,
            %                     Smax, LSmax)
            %     lc_index      - (optional) life cycle(s) for S_* fields
            %                     ([] = all); Smax / LSmax are means across
            %                     life cycles (all only)
            %   Outputs:
            %     ax - the plot axes

            arguments
                self
                ax
                ds_query struct
                field_to_plot string
                lc_index double {mustBeInteger, mustBePositive} = []
            end
            % Registry Lists Cannot Be Called In Validators (R2022b)
            mustBeMember(field_to_plot, response_registry('output', 'names', 'kind', 'armor_damage'));


            if self.structure.struc_type~=3
                error('PSE type on loaded simulation does not support slope armor damage.');
            else
                % GRAB DETAILS FROM "config"
                % Define Project CHS Region
                loc = self.config.region;
                % Define Savepoint ID
                spoint = self.config.sp_ID;
                % Define Percentiles
                prc = strsplit(self.config.project_CLs(2:end-1),{' '});
                % Define Simulation Length
                nyears = [0:self.config.mcs_nYears];
                ds_query.data_type = 'Timeseries'; % Force Timeseries
                sim_data = aux_methods.pull_data(ds_query, self.Resp);
                S = sim_data.S.(field_to_plot);
                % Life Cycle Selection (S_* Fields Only: Cell Array, 1 Damage Series Per LC)
                if ~isempty(lc_index)
                    if ~iscell(S)
                        error('Life cycle selection only applies to S_* fields (Smax/LSmax are means across all life cycles).');
                    elseif any(lc_index > numel(S))
                        error('Requested life cycle exceeds the number of simulated life cycles (%d).', numel(S));
                    end
                    S = S(lc_index);
                end
                % Get Variable Labels
                [~, ~, ~,...
                    ~,...
                    vname, y_label, ~] = response_library_headers(self.config, char(field_to_plot));
                % Define Axes Fields
                if ismember(field_to_plot, response_registry('output', 'names', 'damage_summary', 'yearly_mean_max'))
                    x_label = 'Simulation Year'; % Yearly Mean Curves
                else
                    x_label = 'Cumulative Storm Hours'; % S_* Series: 1 Value Per Storm Time Step (Calm Time Excluded)
                end
                if isempty(lc_index)
                    title_label = ['CHESS: LCS Slope Armor Damage | ' vname];
                else
                    title_label = {['CHESS: LCS Slope Armor Damage | ' vname],...
                        ['Life Cycle ' strjoin(arrayfun(@num2str, lc_index, 'un', false), ', ')]};
                end
                % Initialize Axes
                ax = aux_methods.initiate_axes(ax, x_label, y_label, title_label, self.base_fnt);
                grid(ax,'minor');
                % Plot Damage Field
                switch field_to_plot
                    case 'LSmax'
                        % Plot Mean Curve
                        plot(ax,nyears, S,'--k','LineWidth',2,'DisplayName','$\bar{S}$');% Plot Damage
                        % Plot Percentiles
                        %                         cellfun(@(x,y) plot(ax, nyears, sim_data.LSPcurves(:,x),...
                        %                             'LineWidth',2,'DisplayName',['Percentile: ',y,' \%']),...
                        %                             num2cell(1:length(prc)),prc,'un',false);
                        %                         legend(ax,'Location','Best','Interpreter','Latex');
                    case 'Smax'
                        % Plot Mean Curve
                        plot(ax,nyears, S,'--k','LineWidth',2,'DisplayName','$\bar{S}$');% Plot Damage
                        %                         % Plot Percentiles
                        %                         cellfun(@(x,y) plot(ax, nyears, sim_data.SPcurves(:,x),...
                        %                             'LineWidth',2,'DisplayName',['Percentile: ',y,' \%']),...
                        %                             num2cell(1:length(prc)),prc,'un',false);
                        %                         legend(ax,'Location','Best','Interpreter','Latex');
                    otherwise
                        cellfun(@(x) plot(ax,[1:size(x,1)],x,'LineWidth',1.5),S,'UniformOutput',false);% Plot Damage
                end
            end
        end
        function ax = event_sampling_distribution(self, ax, ds_query, lc_index)
            % event_sampling_distribution  Bar chart of the sampled event type mix.
            %   ax = event_sampling_distribution(self, ax, ds_query)
            %   ax = event_sampling_distribution(self, ax, ds_query, lc_index)
            %       plots the share [%] of XC, TC low, TC mid and TC high
            %       events in the sampled life cycles, with the mean storm
            %       recurrence rate [events/yr] of each type in the legend.
            %
            %   Inputs:
            %     ax       - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query - dataset query (storm_type, data_type, match_type)
            %     lc_index - (optional) life cycle(s) to count ([] or omitted
            %                = all life cycles)
            %   Outputs:
            %     ax - the plot axes

            if nargin < 4
                lc_index = [];
            end
            % Pull Requested Data Out Of SS Data Structure
            data = aux_methods.pull_data(ds_query, self.project_forcing);
            % Life Cycle Selection (1 Cell Per LC)
            if ~isempty(lc_index)
                if any(lc_index > numel(data)) || any(lc_index < 1) || any(lc_index ~= round(lc_index))
                    error('Requested life cycle must be an integer between 1 and %d.', numel(data));
                end
                data = data(lc_index);
            end
            %
            switch ds_query.data_type
                case 'Timeseries'
                    % Event Start Rows (Single Datapoint Per Event)
                    pull_indx = cellfun(@(x) x(:, lcs_columns().step) == 0, data, 'un', false);
                    % Pull Actual Event Sampling Information
                    lc_data = cellfun(@(x, y) x(y, :), data, pull_indx, 'un', false);
                otherwise
                    lc_data = data;
            end
            %
            stms_per_lc = mean(cellfun(@(x) length(x(:, 1)), lc_data, 'un', true));
            % Create Event Distributions
            % Storm Type Flag: 0-XC, 1-TC_Low, 2-TC_Mid, 3-TC_High
            bin = lcs_columns().bin;
            n_xc = cellfun(@(x) sum(x(:, bin) == 0), lc_data, 'un', true);
            n_low = cellfun(@(x) sum(x(:, bin) == 1), lc_data, 'un', true);
            n_mid = cellfun(@(x) sum(x(:, bin) == 2), lc_data, 'un', true);
            n_high = cellfun(@(x) sum(x(:, bin) == 3), lc_data, 'un', true);
            % Compute Totals
            total_xc = sum(n_xc);
            total_low = sum(n_low);
            total_mid = sum(n_mid);
            total_high  = sum(n_high);
            total_events = sum([total_xc, total_low, total_mid, total_high], 'all');
            % Compute Recurrance Rates [stm/yr]
            srr_xc = mean(n_xc./self.config.mcs_nYears);
            srr_low = mean(n_low./self.config.mcs_nYears);
            srr_mid = mean(n_mid./self.config.mcs_nYears);
            srr_high = mean(n_high./self.config.mcs_nYears);
            srr_array = round([srr_xc, srr_low, srr_mid, srr_high], 4);
            % Create Plot Variables
            y_data = 100.*[total_xc, total_low, total_mid, total_high]./total_events;
            x_names = {'XC', 'TC Low','TC Mid','TC High'};
            x_data = categorical(x_names, x_names); % Category Order = Legend Order (Default Is Alphabetical)

            % Define Axes Fields
            y_label     = 'Event Type Distribution [\%]'; % LaTeX Labels (initiate_axes): % Must Be Escaped
            x_label     = 'Event Type';
            if isempty(lc_index)
                title_label = {'CHESS: LCS Event Sampling Distribution Over Entire Simulation',...
                    ['Total Number of Events (N): ' num2str(total_events) ' ($N_{mean}$ per LC: ' num2str(round(stms_per_lc,1)) ')']};
            else
                title_label = {['CHESS: LCS Event Sampling Distribution For Life Cycle ' strjoin(arrayfun(@num2str, lc_index, 'un', false), ', ')],...
                    ['Total Number of Events (N): ' num2str(total_events)]};
            end
            % Initialize Axes
            ax = aux_methods.initiate_axes(ax, x_label, y_label, title_label, self.base_fnt);

            % Add Each Bar Individually to leverage Legend
            lg_lbl = ["XC", "TC_{low}", "TC_{mid}", "TC_{high}"];
            for ii = 1:4
                bar(ax, x_data(ii), y_data(ii), 'FaceColor', 'b',...
                    'DisplayName', lg_lbl(ii) + " = " + string(srr_array(ii)));
            end
            % Add Text On Top
            for gg = 1:length(x_data)
                text(ax, x_data(gg),...
                    y_data(gg),...
                    [num2str(y_data(gg) ,'%0.2f') ' %'],...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom','FontWeight','bold','FontSize',self.base_fnt);
            end
            % Headroom For The Bar Labels (A 100 % Bar Label Would Otherwise Overlap The Title)
            ax.YLim = [0, 1.15*max([y_data, 1])];
            % Legend
            lg = legend(ax, 'Location', 'northeast', 'FontSize', ax.FontSize); % XC Bar Is First (Left), Keep Legend Clear Of It
            title(lg, 'Mean SRR [event/yr]', 'FontSize', ax.FontSize, 'FontWeight', 'bold');
        end
        function mound_damage_dashboard(self, ax, ds_query, field_to_plot, s_bin_edges, s_cb_lim)
            % mound_damage_dashboard  Five-panel rubble mound armor damage dashboard.
            %   mound_damage_dashboard(self, ax, ds_query, field_to_plot, s_bin_edges, s_cb_lim)
            %       draws (1) the share of damaging time steps per life
            %       cycle (plot_mound_damaging_instances_distribution), (2)
            %       the submergence time distribution by year
            %       (plot_pse_submergance_distribution), (3) the yearly mean
            %       maximum cumulative damage and (4) the final damage per
            %       life cycle of the same armor side
            %       (slope_armor_damage_plot, plot_mound_final_damage_state)
            %       and (5) the damage distribution by year
            %       (annual_response_distribution, percent).
            %
            %   Inputs:
            %     ax            - figure, grid layout or axes (subplot_manager)
            %     ds_query      - dataset query (storm_type, data_type, match_type)
            %     field_to_plot - armor damage series (response_registry
            %                     damage_summary 'series', e.g.
            %                     S_seaside_no_repairs)
            %     s_bin_edges   - bin edges of panel 5 ([] = automatic)
            %     s_cb_lim      - colorbar limits of panel 5 ([] = automatic)

            % Initialize Figure
            [gl, subplot_flag] = subplot_manager(self, ax, 2, 6);
            % Define Axes Objects
            if subplot_flag
                % subplot_manager Fills All 12 Tiles: Drop The Unused Axes, Then Move The Rest To Their Tiles Before Spanning
                % (Moved Last-To-First So No Axes Lands On A Tile Still Held By Another)
                delete(gl(6:end));
                gl = gl(1:5);
                tile_start = [1 4 7 9 11];
                tile_span = {[1 3], [1 3], [1 2], [1 2], [1 2]};
                for kk = 5:-1:1
                    gl(kk).Layout.Tile = tile_start(kk);
                end
                for kk = 1:5
                    gl(kk).Layout.TileSpan = tile_span{kk};
                end
                % Top Figures Span 1x3 Gridcells, Bottom Figures 1x2
                ax1 = aux_methods.initiate_axes(gl(1), '',  '', '', self.base_fnt);
                ax2 = aux_methods.initiate_axes(gl(2), '',  '', '', self.base_fnt);
                ax3 = aux_methods.initiate_axes(gl(3), '',  '', '', self.base_fnt);
                ax4 = aux_methods.initiate_axes(gl(4), '',  '', '', self.base_fnt);
                ax5 = aux_methods.initiate_axes(gl(5), '',  '', '', self.base_fnt);
            else
                ax1 = aux_methods.initiate_axes(gl, '',  '', '', self.base_fnt, 1, [1 3]);
                ax2 = aux_methods.initiate_axes(gl, '', '', '', self.base_fnt, 1, [4 6]);
                % Bottom Figures , Each Will Span 1x2 gridcells
                ax3 = aux_methods.initiate_axes(gl, '',  '', '', self.base_fnt, 2, [1 2]);
                ax4 = aux_methods.initiate_axes(gl, '',  '', '', self.base_fnt, 2, [3 4]);
                ax5 = aux_methods.initiate_axes(gl, '',  '', '', self.base_fnt, 2, [5 6]);
            end
            % Plot Damaging Instances Distirbutions
            ax1 = plot_mound_damaging_instances_distribution(self, ax1, ds_query, field_to_plot);
            % Plot Yearly Mean Maximum Submergence Percentage Distribution
            ax2 = plot_pse_submergance_distribution(self, ax2, ds_query, false, false, false, []);
            % Yearly Mean Maximum Cumulative Mean Damage (S)
            armor_side = response_registry('name', char(field_to_plot)).armor_side;
            ax3 = slope_armor_damage_plot(self, ax3, ds_query, char(response_registry('output', 'names', 'armor_side', armor_side, 'damage_summary', 'yearly_mean_max')));
            ax4 = plot_mound_final_damage_state(self, ax4, ds_query, char(response_registry('output', 'names', 'armor_side', armor_side, 'with_repairs', false, 'damage_summary', 'series')));
            side = [upper(armor_side(1)) armor_side(2:end)];
            % Short Y Labels (The Standalone Labels Get Clipped In The Dashboard Tiles): The Titles Name The Quantity
            ylabel(ax3, 'Damage $\bar{\bar{S}}_{max}$', 'FontSize', self.base_fnt, 'FontWeight', 'bold', 'Interpreter', 'latex');
            title(ax3, ['Yearly Mean Maximum Cumulative Damage (' side ')'], 'FontSize', self.base_fnt + 2, 'FontWeight', 'bold', 'Interpreter', 'latex');
            ylabel(ax4, 'Final Damage $\bar{S}$', 'FontSize', self.base_fnt, 'FontWeight', 'bold', 'Interpreter', 'latex');
            title(ax4, ['Final Damage Per Life Cycle (' side ')'], 'FontSize', self.base_fnt + 2, 'FontWeight', 'bold', 'Interpreter', 'latex');

            [ax5, ~] = annual_response_distribution(self, ax5, ds_query, field_to_plot, s_bin_edges, 'percent', s_cb_lim, false, false);
        end
        function sampling_scheme_dashboard(self, ax, ds_query)
            % sampling_scheme_dashboard  Six-panel diagnostics of the LCS storm sampling.
            %   sampling_scheme_dashboard(self, ax, ds_query)
            %
            % Diagnostics Of The LCS Storm Sampling For One Storm Type (ds_query.storm_type):
            %   (1) Storms Per Life Cycle Vs Poisson(lambda*N); Rate-Matched Sampling Only: Window lambda*N +/- 1
            %       (sample_tc_storm / sample_xc_storm; ERDC/CHL TR-20-5 Sec. 3.2-3.3)
            %   (2) Storms Per Simulation Year (All Life Cycles Pooled) Vs Poisson(lambda)
            %   (3) Event Type Mix And Mean Recurrence Rates (event_sampling_distribution)
            %   (4) Mean Storms By Simulation Year (Timing Within The Life Cycle)
            %   (5) Storm Selection: Sampled Vs Expected Share Per Storm
            %       (XC: Uniform Over The Screened XC Storms Of storm, Else Nstm_XC | TC: Intensity Bin Rates x TC_Freq Within Bin; Needs storm & dsw)
            %   (6) Convergence Over mcs_nLC (Targets Of lcs_convergence_check): Running Mean Vs lambda*N*(1 +/- tol),
            %       Running Percentiles (project_CLs) Vs Exact Poisson Percentiles +/- max(1, tol*x_p);
            %       Full Poisson Sampling: nLC_req And Verdict (config.lcs_convergence_results From chess_lcs When Present,
            %       Else Computed) | Rate Matched: Running Mean And Percentiles Only, No Targets Or Convergence Check
            % Inputs: ax -> Figure, Grid Layout Or Axes (subplot_manager) | ds_query -> storm_type, data_type, match_type
            % Uses: self.project_forcing (LCS), self.config (mcs_nYears, Nstm_XC, Nyrs_XC, project_CLs, lcs_* Sampling Settings),
            %       self.dsw (TC), self.storm (Panel 5)

            sampling = self.sampling_scheme_inputs(ds_query);

            %% Axes (2 x 3)
            [gl, subplot_flag] = subplot_manager(self, ax, 2, 3);
            axs = gobjects(1, 6);
            for kk = 1:6
                if subplot_flag
                    axs(kk) = aux_methods.initiate_axes(gl(kk), '', '', '', self.base_fnt);
                else
                    axs(kk) = aux_methods.initiate_axes(gl, '', '', '', self.base_fnt, ceil(kk/3), mod(kk - 1, 3) + 1);
                end
            end

            self.plot_storms_per_life_cycle(axs(1), sampling, ds_query.storm_type);
            self.plot_storms_per_simulation_year(axs(2), sampling);
            %% (3) Event Type Mix
            event_sampling_distribution(self, axs(3), ds_query);
            self.plot_mean_storms_by_year(axs(4), sampling);
            self.plot_storm_selection(axs(5), sampling, ds_query.storm_type);
            self.plot_life_cycle_convergence(axs(6), sampling, ds_query.storm_type);
        end
    end

    %% SAMPLING SCHEME DASHBOARD PANELS (Drawn By sampling_scheme_dashboard)
    properties (Constant, Access=protected)
        % Panel Colors: Sampled Bars/Lines, Poisson Reference, Rate-Matched / Tolerance Window
        sampling_colors = struct('bar', [0.17 0.43 0.61], 'reference', [0.77 0.48 0.13], 'window', [0.95 0.75 0.45])
    end

    methods (Access=protected)
        function sampling = sampling_scheme_inputs(self, ds_query)
            % Sampled Life Cycles Of One Storm Type: data (Event Start Rows Per Life Cycle), cols, n_lc, n_years, lc_counts,
            % lambda (Storm Rate [storms/yr]), m (Expected Storms Per Life Cycle), lcs_mode, yr_counts (n_years x n_lc)
            %% Sampled Life Cycles (Timeseries Rows Repeat Per Timestep: Keep Event Start Rows, Step Counter == 0)
            sampling.cols = lcs_columns();
            data = aux_methods.pull_data(ds_query, self.project_forcing);
            if strcmp(ds_query.data_type, 'Timeseries')
                data = cellfun(@(x) x(x(:, sampling.cols.step) == 0, :), data, 'un', false);
            end
            sampling.data = data(:);
            sampling.n_lc = numel(sampling.data);
            sampling.n_years = self.config.mcs_nYears;
            sampling.lc_counts = cellfun(@(x) size(x, 1), sampling.data);
            % Storm Rate [storms/yr]: XC From The Storm Record, TC From The Probability Masses (Else Estimated From The Samples)
            switch ds_query.storm_type
                case 'XC'
                    sampling.lambda = self.config.Nstm_XC/self.config.Nyrs_XC;
                otherwise
                    if isstruct(self.dsw) && isfield(self.dsw, 'TC_SRR')
                        sampling.lambda = self.dsw.TC_SRR(end);
                    else
                        sampling.lambda = mean(sampling.lc_counts)/sampling.n_years;
                    end
            end
            sampling.m = sampling.lambda*sampling.n_years; % Expected Storms Per Life Cycle
            sampling.lcs_mode = lcs_sampling_mode(self.config); % Mode The Life Cycles Were Sampled With (0 = Full Poisson, 1 = Rate Matched)
            % Storms Per Simulation Year, One Column Per Life Cycle
            sampling.yr_counts = cell2mat(cellfun(@(x) accumarray(x(:, sampling.cols.year), 1, [sampling.n_years 1]), sampling.data', 'un', false));
        end

        function plot_storms_per_life_cycle(self, ax, sampling, storm_type)
            %% (1) Storms Per Life Cycle
            m = sampling.m;
            k = 0:max([sampling.lc_counts; ceil(m + 4*sqrt(m) + 2)]);
            share = histcounts(sampling.lc_counts, [k - 0.5, k(end) + 0.5])/sampling.n_lc;
            y_top = 1.1*max([share, poisspdf(k, m)]);
            if sampling.lcs_mode == 1
                fill(ax, [m - 1, m + 1, m + 1, m - 1], [0 0 y_top y_top], self.sampling_colors.window, 'EdgeColor', 'none', 'FaceAlpha', 0.35,...
                    'DisplayName', 'Rate-matched window ($\lambda N \pm 1$)');
                mode_txt = 'Rate Matched';
            else
                mode_txt = 'Full Poisson';
            end
            bar(ax, k, share, 0.8, 'FaceColor', self.sampling_colors.bar, 'EdgeColor', 'none', 'DisplayName', 'Sampled life cycles');
            plot(ax, k, poisspdf(k, m), 'o-', 'Color', self.sampling_colors.reference, 'LineWidth', 1.2, 'MarkerFaceColor', self.sampling_colors.reference, 'DisplayName', 'Poisson($\lambda N$)');
            xline(ax, m, '--k', 'LineWidth', 1.2, 'DisplayName', sprintf('$\\lambda N$ = %.2f', m));
            ax.YLim = [0 y_top];
            title(ax, aux_methods.latex_escape({sprintf('Storms Per Life Cycle (%s, %s Sampling)', storm_type, mode_txt),...
                sprintf('$\\lambda$ = %.3f storms/yr, N = %d yr, %d life cycles', sampling.lambda, sampling.n_years, sampling.n_lc)}));
            xlabel(ax, 'Storms per life cycle', 'FontSize', self.base_fnt); ylabel(ax, 'Share of life cycles', 'FontSize', self.base_fnt);
            legend(ax, 'Interpreter', 'latex', 'Location', 'northeast');
        end

        function plot_storms_per_simulation_year(self, ax, sampling)
            %% (2) Storms Per Simulation Year
            lambda = sampling.lambda;
            k2 = 0:max([sampling.yr_counts(:); ceil(lambda + 4*sqrt(lambda) + 1)]);
            share2 = histcounts(sampling.yr_counts(:), [k2 - 0.5, k2(end) + 0.5])/numel(sampling.yr_counts);
            bar(ax, k2, share2, 0.8, 'FaceColor', self.sampling_colors.bar, 'EdgeColor', 'none', 'DisplayName', 'Sampled years');
            plot(ax, k2, poisspdf(k2, lambda), 'o-', 'Color', self.sampling_colors.reference, 'LineWidth', 1.2, 'MarkerFaceColor', self.sampling_colors.reference, 'DisplayName', 'Poisson($\lambda$)');
            title(ax, 'Storms Per Simulation Year (All Life Cycles)');
            xlabel(ax, 'Storms in a year', 'FontSize', self.base_fnt); ylabel(ax, 'Share of years', 'FontSize', self.base_fnt);
            legend(ax, 'Interpreter', 'latex', 'Location', 'northeast');
        end

        function plot_mean_storms_by_year(self, ax, sampling)
            %% (4) Mean Storms By Simulation Year
            plot(ax, 1:sampling.n_years, mean(sampling.yr_counts, 2), '-o', 'Color', self.sampling_colors.bar, 'LineWidth', 1.2, 'MarkerFaceColor', self.sampling_colors.bar, 'DisplayName', 'Mean over life cycles');
            yline(ax, sampling.lambda, '--', 'Color', self.sampling_colors.reference, 'LineWidth', 1.2, 'DisplayName', '$\lambda$');
            ax.XLim = [0.5, sampling.n_years + 0.5];
            title(ax, 'Mean Storms By Simulation Year');
            xlabel(ax, 'Simulation year', 'FontSize', self.base_fnt); ylabel(ax, 'Storms per year', 'FontSize', self.base_fnt);
            legend(ax, 'Interpreter', 'latex', 'Location', 'best');
        end

        function plot_storm_selection(self, ax, sampling, storm_type)
            %% (5) Storm Selection: Sampled Vs Expected Share Per Storm
            ids = cell2mat(cellfun(@(x) x(:, sampling.cols.id), sampling.data, 'un', false));
            [u_ids, ~, ic] = unique(ids);
            sampled = accumarray(ic, 1)/numel(ids);
            expected = self.expected_storm_shares(u_ids, storm_type);
            if all(isnan(expected))
                aux_methods.display_no_data(ax, self.base_fnt);
            else
                lim = [0, 1.05*max([sampled; expected])];
                plot(ax, lim, lim, '--k', 'LineWidth', 1, 'DisplayName', '1:1');
                scatter(ax, expected, sampled, 18, self.sampling_colors.bar, 'filled', 'MarkerFaceAlpha', 0.6, 'DisplayName', 'Storm');
                ax.XLim = lim; ax.YLim = lim;
                % No x10^n Exponent Label (The Y One Collides With The 2-Line Title); Decimals Follow The Share Magnitude
                fmt = sprintf('%%.%df', max(1, ceil(-log10(lim(2))) + 1));
                ax.XAxis.Exponent = 0; ax.XAxis.TickLabelFormat = fmt;
                ax.YAxis.Exponent = 0; ax.YAxis.TickLabelFormat = fmt;
                legend(ax, 'Interpreter', 'latex', 'Location', 'northwest');
            end
            title(ax, {'Storm Selection', sprintf('%d sampled events, %d distinct storms', numel(ids), numel(u_ids))});
            xlabel(ax, 'Expected share', 'FontSize', self.base_fnt); ylabel(ax, 'Sampled share', 'FontSize', self.base_fnt);
        end

        function expected = expected_storm_shares(self, u_ids, storm_type)
            % Expected Sampling Share Per Sampled Storm ID (NaN Where The Storm Record / Probability Masses Are Missing)
            expected = nan(size(u_ids));
            switch storm_type
                case 'XC' % Storm IDs Are Drawn Uniformly From The Screened Pool (Nstm_XC Counts Storms Before Bad-Storm Removal)
                    n_pool = self.config.Nstm_XC;
                    if isstruct(self.storm) && isfield(self.storm, 'XC')
                        if isfield(self.storm.XC, 'Peaks')
                            pool_ids = cell2mat(self.storm.XC.Peaks.Default(:, 1));
                        else
                            pool_ids = cell2mat(self.storm.XC.Timeseries.Default(:, 1));
                        end
                        n_pool = numel(unique(pool_ids));
                    end
                    expected(:) = 1/n_pool;
                otherwise % Intensity Bin (Rate Share, Empty Bins Re-Drawn) x Storm Frequency Within The Bin
                    if isstruct(self.dsw) && isfield(self.dsw, 'smpl1') && isstruct(self.storm) && isfield(self.storm, 'TC')
                        if isfield(self.storm.TC, 'Peaks')
                            all_ids = cell2mat(self.storm.TC.Peaks.Default(:, 1));
                        else
                            all_ids = cell2mat(self.storm.TC.Timeseries.Default(:, 1));
                        end
                        bins = {self.dsw.smpl1, self.dsw.smpl2, self.dsw.smpl3};
                        bins = cellfun(@(b) b(ismember(b, all_ids)), bins, 'un', false);
                        p_bin = self.dsw.TC_SRR(1:3).*~cellfun(@isempty, bins);
                        p_bin = p_bin/sum(p_bin);
                        p_storm = zeros(size(all_ids));
                        for bb = find(p_bin > 0)
                            [~, bi] = ismember(bins{bb}, all_ids);
                            w = self.dsw.TC_Freq(bi);
                            p_storm(bi) = p_storm(bi) + p_bin(bb)*w(:)/sum(w);
                        end
                        [~, si] = ismember(u_ids, all_ids);
                        expected(si > 0) = p_storm(si(si > 0));
                    end
            end
        end

        function plot_life_cycle_convergence(self, ax, sampling, storm_type)
            %% (6) Convergence Of Storms Per Life Cycle (Same Targets As lcs_convergence_check)
            % Rate Matched: Running Statistics Only (Rate-Matched Counts Do Not Follow The Poisson Targets By Design)
            n_lc = sampling.n_lc;
            m = sampling.m;
            lc_counts = sampling.lc_counts;
            prc = cellfun(@str2double, strsplit(self.config.project_CLs(2:end-1), {' '}));
            n = (1:n_lc)';
            run_mean = cumsum(lc_counts)./n;
            half_ci = 1.96*std(lc_counts)./sqrt(n);
            % Running Percentiles (prctile) On The First n Life Cycles, Log-Subsampled n For Speed
            n_pct = unique(round(logspace(0, log10(n_lc), min(n_lc, 100))))';
            run_pct = zeros(numel(n_pct), numel(prc));
            for jj = 1:numel(n_pct)
                run_pct(jj, :) = prctile(lc_counts(1:n_pct(jj)), prc);
            end
            conv = [];
            if sampling.lcs_mode == 0
                tol = self.config.lcs_convergence_tol;
                x_p = poissinv(prc/100, m);
                pct_tol = max(1, tol*x_p);
                % Result Of The Check Run By chess_lcs When Available, Else Computed Here
                if isfield(self.config, 'lcs_convergence_results') && isfield(self.config.lcs_convergence_results, storm_type)
                    conv = self.config.lcs_convergence_results.(storm_type);
                else
                    conv = lcs_convergence_check(sampling.lambda, sampling.n_years, n_lc, tol, self.config.lcs_convergence_confidence, prc, storm_type, true);
                end
            end
            x_max = max(n_lc, 2);
            if ~isempty(conv) && isfinite(conv.nLC_req)
                x_max = max(x_max, ceil(1.1*conv.nLC_req));
            end
            x_band = [1, x_max, x_max, 1];
            c_pct = lines(7);
            c_pct = c_pct(mod(0:numel(prc) - 1, 4) + 4, :); % Colors 4-7: Distinct From The Bar / Reference Colors
            fill(ax, [n; flipud(n)], [run_mean - half_ci; flipud(run_mean + half_ci)], [0.6 0.6 0.6], 'EdgeColor', 'none',...
                'FaceAlpha', 0.15, 'DisplayName', '95\% CI of the mean');
            if sampling.lcs_mode == 0
                fill(ax, x_band, m*[1 - tol, 1 - tol, 1 + tol, 1 + tol], self.sampling_colors.window, 'EdgeColor', 'none', 'FaceAlpha', 0.45,...
                    'DisplayName', sprintf('Tolerance: $\\lambda N (1 \\pm %g)$', tol));
            end
            for jj = 1:numel(prc)
                if sampling.lcs_mode == 0
                    fill(ax, x_band, x_p(jj) + pct_tol(jj)*[-1, -1, 1, 1], c_pct(jj, :), 'EdgeColor', 'none', 'FaceAlpha', 0.12,...
                        'HandleVisibility', 'off');
                    yline(ax, x_p(jj), '--', 'Color', c_pct(jj, :), 'LineWidth', 1, 'HandleVisibility', 'off');
                    pct_name = sprintf('P%g (Poisson: %g)', prc(jj), x_p(jj));
                else
                    pct_name = sprintf('P%g', prc(jj));
                end
                plot(ax, n_pct, run_pct(:, jj), '-', 'Color', c_pct(jj, :), 'LineWidth', 1.2, 'DisplayName', pct_name);
            end
            plot(ax, n, run_mean, '-', 'Color', self.sampling_colors.bar, 'LineWidth', 1.5, 'DisplayName', 'Running mean');
            yline(ax, m, '--', 'Color', self.sampling_colors.reference, 'LineWidth', 1.2, 'DisplayName', '$\lambda N$');
            % Rate Matched: No Convergence Check | Full Poisson: Verdict Of lcs_convergence_check
            k0 = min(n_lc, 10);
            if isempty(conv)
                verdict = 'Rate matched: no convergence check';
                y_vals = m;
            else
                if isinf(conv.nLC_req)
                    req_txt = ['$>$ ' regexprep(num2str(conv.nLC_cap), '(\d)(?=(\d{3})+$)', '$1,')];
                else
                    req_txt = sprintf('%d', conv.nLC_req);
                    xline(ax, conv.nLC_req, '-.k', 'LineWidth', 1.2, 'DisplayName', 'nLC\_req');
                end
                if conv.converged
                    verdict = sprintf('Converged: mcs\\_nLC = %d $\\geq$ nLC\\_req = %s', n_lc, req_txt);
                else
                    verdict = sprintf('Not converged: mcs\\_nLC = %d $<$ nLC\\_req = %s', n_lc, req_txt);
                end
                y_vals = [m*(1 + [-tol, tol]), x_p - pct_tol, x_p + pct_tol];
            end
            % Y Limits From The Targets (Mode 0) And The Running Statistics (The Early CI Is Left Clipped)
            y_vals = [y_vals, run_mean(k0:end)', reshape(run_pct(n_pct >= k0, :), 1, [])];
            y_pad = 0.08*max(max(y_vals) - min(y_vals), 1);
            ax.YLim = [max(0, min(y_vals) - y_pad), max(y_vals) + y_pad];
            ax.XScale = 'log';
            ax.XLim = [1, x_max];
            title(ax, aux_methods.latex_escape({'Convergence Of Storms Per Life Cycle', verdict}));
            xlabel(ax, 'Number of life cycles', 'FontSize', self.base_fnt); ylabel(ax, 'Storms per life cycle', 'FontSize', self.base_fnt);
            legend(ax, 'Interpreter', 'latex', 'Location', 'best', 'FontSize', max(ax.FontSize - 2, 6));
        end
    end

    %%
    methods (Access=public)
        function chunked_events = split_into_events(self, ds_query, value_in)
            % split_into_events  Split life-cycle vectors into storm events.
            %   chunked_events = split_into_events(self, ds_query, value_in)
            %       splits each life-cycle array of value_in at the storm
            %       boundaries of the saved project forcing (Timeseries:
            %       rows with step 0 start a storm; Peaks: one row per
            %       storm).
            %
            %   Inputs:
            %     ds_query - dataset query (storm_type, data_type, match_type)
            %     value_in - cell, one array per life cycle, rows aligned
            %                with the project forcing rows
            %   Outputs:
            %     chunked_events - cell per life cycle;
            %                      chunked_events{lc}{event} holds the rows
            %                      of one storm event

            % 1. Load Simulation Forcing Data to find boundaries
            stm_data = aux_methods.pull_data(ds_query, self.project_forcing);

            % 2. Calculate Event Start/End Indices Across All LCs
            switch char(ds_query.data_type)
                case 'Timeseries'
                    stm_beg = cellfun(@(x) find(x(:, lcs_columns().step) == 0), stm_data, 'un', false);
                    stm_end = cellfun(@(x) x(2:end)-1, stm_beg, 'un', false);

                    % Append End For Last Storm
                    stm_end = cellfun(@(x,y) [x; size(y, 1)], stm_end, stm_data, 'un', false);
                case 'Peaks'
                    stm_beg = cellfun(@(x) [1:length(x)]', stm_data, 'un', false);
                    stm_end = stm_beg;
            end
            % 3. Initialize Output Cell Array
            num_LC = length(value_in);
            chunked_events = cell(num_LC, 1);

            % 4. Split value_in into chunks
            for nLC = 1:num_LC
                % Calculate the exact length of each chunk/event
                chunk_lengths = stm_end{nLC} - stm_beg{nLC} + 1;

                % Vectorized split: Instantly breaks the array into chunks
                % (size(value_in{nLC}, 2) ensures this works for both 1D and 2D arrays)
                chunked_events{nLC} = mat2cell(value_in{nLC}, chunk_lengths, size(value_in{nLC}, 2));
            end
        end
        function [C, damage_indx] = get_damaging_instances(self, ds_query, field_to_plot)
            % get_damaging_instances  Time steps where the armor damage grows.
            %   [C, damage_indx] = get_damaging_instances(self, ds_query, field_to_plot)
            %       No repairs: the first step of each new damage value.
            %       With repairs: evaluated storm by storm, a value counts
            %       when it differs from the last value of the previous
            %       storm. S = 0 steps are never damaging.
            %
            %   Inputs:
            %     ds_query      - dataset query (storm_type, data_type, match_type)
            %     field_to_plot - armor damage series (response_registry
            %                     damage_summary 'series')
            %   Outputs:
            %     C           - cell per life cycle: damage values at the
            %                   damaging steps (no repairs: every unique value,
            %                   0 included)
            %     damage_indx - cell per life cycle: row indices of the
            %                   damaging steps

            arguments
                self
                ds_query struct
                field_to_plot string
            end
            % Registry Lists Cannot Be Called In Validators (R2022b)
            mustBeMember(field_to_plot, response_registry('output', 'names', 'damage_summary', 'series'));
            % Load Simulation Data
            sim_data = aux_methods.pull_data(ds_query, self.Resp);
            stm_data = aux_methods.pull_data(ds_query, self.project_forcing);

            % Pull Damage Vector (No Repairs)
            s_vector = sim_data.S.(field_to_plot);

            % Get Event Start/End Across All LCs
            stm_beg = cellfun(@(x) find(x(:, lcs_columns().step) == 0), stm_data, 'un', false);
            stm_end = cellfun(@(x) x(2:end)-1, stm_beg, 'un', false);
            % Append End For Last Storm
            stm_end = cellfun(@(x,y) [x;length(y(:,1))], stm_end, stm_data, 'un', false);

            % Find Unique Damagin Instances
            switch char(field_to_plot)
                case response_registry('output', 'names', 'damage_summary', 'series', 'with_repairs', true)
                    % Repair Vectors Require Unique Damages To Be Analyzed
                    % on the storm by storm basis for each LC
                    num_LC = length(stm_data);
                    damage_indx = cell(num_LC, 1); % Initialize Damage Index

                    % Loop through LCs
                    for nLC = 1:num_LC
                        % Extract arrays once per load case to minimize overhead
                        b_idx = stm_beg{nLC};
                        e_idx = stm_end{nLC};
                        s_vec = s_vector{nLC};

                        num_chunks = length(b_idx);
                        chunk_indices = cell(num_chunks, 1); % Preallocate memory for speed

                        prev_end = 0; % Initialize for the first iteration

                        % Loop Thorugh Each Event In The LC
                        for lc = 1:num_chunks
                            % 1. Extract the current chunk and its global row indices
                            g_rows = (b_idx(lc) : e_idx(lc)).';
                            chunk_vals = s_vec(g_rows);
                            % 2. Get unique values (stable) and their local indices
                            [u_vals, local_idx] = unique(chunk_vals, 'stable');
                            % 3. Define Logical Test To Flag Unique Damage Values
                            if lc == 1
                                pass_test = (u_vals ~= 0); % First Event Just Checks For 0 S
                            else
                                % Compare Against Previous Event (diff ~= 0 means damage changed)
                                pass_test = (prev_end - u_vals ~= 0);
                            end
                            % 4. Evaluate Storm unique S Entries
                            if any(pass_test)
                                % Check For 0 S Values
                                keep_mask = (u_vals ~= 0); % Only Keep Non-Zero Entries
                                % If Any Non-Zero Value Is Leftover, Store indexes
                                if any(keep_mask)
                                    chunk_indices{lc} = g_rows(local_idx(keep_mask));
                                end
                            end
                            % Update previous event's last value for the next iteration
                            prev_end = u_vals(end);
                        end
                        % Append Non-Zero Entries (concatenate all chunks at once)
                        damage_indx{nLC} = vertcat(chunk_indices{:});
                    end

                    % Pull Unique S Values
                    C = cellfun(@(x, y) x(y), s_vector, damage_indx, 'un', false);
                otherwise
                    % No Repairs == Will grow to infinity, hence we can do
                    % a unique on the full damage vector
                    % Find Damaging And Submergence Instances
                    [C,damage_indx,ic] = cellfun(@(x) unique(x,'stable'), s_vector, 'un', false);
                    % C -> Unique Damage Vector | ia-> damaging timesteps | ic-> Non-damaging timesteps
                    % Remove Timestep Where S==0 From Unique Array
                    damage_indx = cellfun(@(x,y) x(y),damage_indx,cellfun(@(x) x~=0,C,'un',false),'un',false);
            end
        end
        function ax = plot_mound_damaging_instances_distribution(self, ax, ds_query, field_to_plot)
            % plot_mound_damaging_instances_distribution  Share of damaging time steps per life cycle.
            %   ax = plot_mound_damaging_instances_distribution(self, ax, ds_query, field_to_plot)
            %       bars: percentage of the life-cycle time steps that
            %       caused damage with the structure emergent; red line:
            %       the same while submerged (SWL above the crest).
            %
            %   Inputs:
            %     ax            - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query      - dataset query (storm_type, data_type, match_type)
            %     field_to_plot - armor damage series (response_registry
            %                     damage_summary 'series')
            %   Outputs:
            %     ax - the plot axes

            arguments
                self
                ax
                ds_query struct
                field_to_plot string
            end
            % Registry Lists Cannot Be Called In Validators (R2022b)
            mustBeMember(field_to_plot, response_registry('output', 'names', 'damage_summary', 'series'));
            % Load Simulation Data
            sim_data = aux_methods.pull_data(ds_query, self.Resp);
            stm_data = aux_methods.pull_data(ds_query, self.project_forcing);

            % Pull Damage Vector (No Repairs)
            s_vector = sim_data.S.(field_to_plot);
            % Find Damaging Instances
            [C, damage_indx] = get_damaging_instances(self, ds_query, field_to_plot);
            % Compute Freeboard For Damaging Timesteps To Determine State
            Rc = cellfun(@(x,y) self.structure.crest_elevation-x(y, lcs_columns().SWL), stm_data, damage_indx, 'un', false);
            % Define Structure Submergence State
            sumergance_state = cellfun(@(x) x<0, Rc, 'un', false);
            % Compute LC percentages
            data_sub = cellfun(@(x, y, z) 100.*length(x(y))./length(z), damage_indx, sumergance_state,s_vector);
            data = cellfun(@(x, y, z) 100.*length(x(~y))./length(z), damage_indx, sumergance_state,s_vector);
            % Get Mean Metrics
            avg_len = mean(cellfun(@length, s_vector)); % Mean LC Length
            avg_dmg_len = mean(cellfun(@length, damage_indx)); % Mean Damaging Timesteps
            % Define Axes Fields
            y_label     = 'Timestep Percentage That Caused Damage';
            x_label     = 'Life Cycles';
            % Title
            title_label ='';
            % Initialize Axes
            ax = aux_methods.initiate_axes(ax, x_label, y_label, title_label, self.base_fnt);
            % 5. Calculate bin centers for plotting
            centers = 1:length(data);
            % 6. Plot as a stacked bar chart
            b = bar(ax, centers, data, 'BarWidth', 1,'DisplayName','Emergent','EdgeColor','none');
            X=zeros(length(data_sub)*3, 1);Y=zeros(length(data_sub)*3, 1);
            for kk = 1:length(centers)
                if kk==1
                    indx = 1:3;
                else
                    indx = kk*3-2:kk*3;
                end
                X(indx) = [kk - b.BarWidth/2;kk;kk + b.BarWidth/2];
                Y(indx) = [data_sub(kk); data_sub(kk); data_sub(kk)];
            end
            plot(ax, X(:), Y(:), 'r-', 'LineWidth', 2, 'DisplayName', 'Submerged');
            xlim(ax, [min(X), max(X)]);
            legend(ax);
        end
        function ax = plot_pse_submergance_distribution(self, ax, ds_query, use_log_x, is_count, cb_log, cb_lim)
            % plot_pse_submergance_distribution  Submergence time per storm binned by simulation year.
            %   ax = plot_pse_submergance_distribution(self, ax, ds_query, use_log_x, is_count, cb_log, cb_lim)
            %       sums the hours with SWL above the crest of each storm
            %       (Timeseries dt column) and plots their distribution by
            %       simulation year (compute_annual_distribution with
            %       automatic edges, plot_annual_distribution). No
            %       submergence: a no-data note.
            %
            %   Inputs:
            %     ax        - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query  - dataset query (storm_type, data_type, match_type)
            %     use_log_x - true: log X axis
            %     is_count  - true: colorbar label reads counts (the bins hold
            %                 percentages)
            %     cb_log    - true: log colorbar
            %     cb_lim    - colorbar limits ([] = data range)
            %   Outputs:
            %     ax - the plot axes

            arguments
                self
                ax
                ds_query struct
                use_log_x
                is_count
                cb_log
                cb_lim
            end
            % Load Simulation Data
            stm_data = aux_methods.pull_data(ds_query, self.project_forcing);

            % Compute Freeboard For Damaging Timesteps To Determine State
            cols = lcs_columns();
            Rc = cellfun(@(x) self.structure.crest_elevation-x(:, cols.SWL), stm_data, 'un', false);
            % Define Structure Submergence State
            sumergance_state = cellfun(@(x) x<0, Rc, 'un', false);
            % SWL Never Above The Crest: Nothing To Bin
            if ~any(cellfun(@any, sumergance_state))
                ax = aux_methods.initiate_axes(ax, 'Submergence Time [hrs] Bins', 'Simulation Year', '', self.base_fnt);
                aux_methods.display_no_data(ax, self.base_fnt, 'No submergence in simulation');
                return
            end
            % Split Rc entries Per Event Across All LCs
            sumergance_state_per_event = split_into_events(self, ds_query, sumergance_state);
            % Do The Same For The dt Column
            submerged_time_per_event = split_into_events(self, ds_query, cellfun(@(x) x(:, cols.dt), stm_data, 'un', false));
            % Define Helper Function To Deal With Nested Cells ( First
            % Cell-> LC Second Cell -> Event Chunks In LC
            f_x = @(a, b) cellfun(@(x, y) sum(x(y)).*24, a, b, 'un',true);
            % Find And Sum Total Submergence Time For Each Event Across All LC
            submerged_time_per_event = cellfun(@(x,y) f_x(x, y), submerged_time_per_event, sumergance_state_per_event,'un',false);
            % Create Dummy LC Sampling Var To Perform Yearly Binnin
            dummy_stm_data = cellfun(@(x, y) x(y, 1:cols.n_peaks),...
                stm_data, cellfun(@(x) x(:, cols.step) == 0, stm_data, 'un', false),...
                'un', false);
            % Bin Duration Values
            [bin_data, bin_edges] = compute_annual_distribution(self, dummy_stm_data, submerged_time_per_event,self.config.mcs_nYears,...
                false, is_count, []);

            [ax, pp, hb] = plot_annual_distribution(self, ax, bin_data, bin_edges, use_log_x, is_count, cb_log, cb_lim);
            pp.LineWidth = 0.2;

            % Define Axes Fields
            ax.YLabel.String      =  'Simulation Year';
            ax.XLabel.String = 'Submergence Time [hrs] Bins';
            title(ax, '');%Submergence Time Distribution By Sim Year';


        end
        function ax = plot_mound_final_damage_state(self, ax, ds_query, field_to_plot)
            % plot_mound_final_damage_state  Final armor damage of each life cycle and its mean.
            %   ax = plot_mound_final_damage_state(self, ax, ds_query, field_to_plot)
            %       Timeseries only (Peaks errors). Life cycles without
            %       storms keep the initial damage 0.
            %
            %   Inputs:
            %     ax            - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query      - dataset query (storm_type, data_type, match_type)
            %     field_to_plot - no-repairs armor damage series (response_registry
            %                     damage_summary 'series', with_repairs false)
            %   Outputs:
            %     ax - the plot axes

            arguments
                self
                ax
                ds_query struct
                field_to_plot string
            end
            % Registry Lists Cannot Be Called In Validators (R2022b)
            mustBeMember(field_to_plot, response_registry('output', 'names', 'damage_summary', 'series', 'with_repairs', false));
            %
            switch ds_query.data_type
                case 'Peaks'
                    error('This plot only supports timeseries data_types.');
            end
            % Pull Simulation Outputs
            sim_data = aux_methods.pull_data(ds_query, self.Resp);
            S = sim_data.S.(field_to_plot);
            % Find Final Damage At Each LC  (Using no repairs, hence max ==
            % last step). Life Cycles Without Storms Keep The Initial Damage (0)
            s_max = zeros(size(S));
            has_storms = ~cellfun(@isempty, S);
            s_max(has_storms) = cellfun(@(x) x(end), S(has_storms));
            % Get Variable Labels
            [~, ~, ~,...
                ~,...
                vname, y_label, ~] = response_library_headers(self.config, field_to_plot);
            % Define Axes Fields
            y_label     = ['Final Cumulative Damage ' vname];
            x_label     = 'Life Cycle';
            title_label = '';
            % Initialize Axes
            ax = aux_methods.initiate_axes(ax, x_label, y_label, title_label, self.base_fnt);
            % Plot
            plot(ax, 1:length(s_max), s_max, '-r', 'LineWidth', 1.5, 'DisplayName', '$\bar{S}_{final}$ per LC');
            plot(ax, [1, length(s_max)], [mean(s_max), mean(s_max)], '--k', 'LineWidth', 2, 'DisplayName', ['Mean $\bar{S}_{final}$ = ' num2str(round(mean(s_max), 3))]);
            xlim(ax, [1 length(s_max)]);
            % Legend
            legend(ax, 'Interpreter', 'latex');
        end
    end
    %% ANNUAL BINNING METHOD
    methods (Access=public)
        function [ax, bin_data] = annual_response_distribution(self, ax, ds_query, field_to_plot,...
                bin_edges, norm_type, cb_lim, grid_on, cb_log)
            % annual_response_distribution  Storm maxima of a response binned by simulation year.
            %   [ax, bin_data] = annual_response_distribution(self, ax, ds_query, field_to_plot, bin_edges, norm_type, cb_lim, grid_on, cb_log)
            %       takes the maximum of the response over each storm of
            %       every life cycle, pools the maxima by the storm's year
            %       and bins them (compute_annual_distribution, with
            %       overflow bins below
            %       and above the edges) and plots the year x bin pcolor
            %       (plot_annual_distribution). All-NaN response: a no-data
            %       note and bin_data = [].
            %
            %   Inputs:
            %     ax            - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query      - dataset query (storm_type, data_type, match_type)
            %     field_to_plot - per-event response (response_registry
            %                     per_event); armor damage is read from Resp...S
            %     bin_edges     - inner bin edges ([] = generate_bin_guess,
            %                     5 edges)
            %     norm_type     - "count" or "percent"
            %     cb_lim        - colorbar limits [min max] ([] = data range)
            %     grid_on       - logical (not used by the plot)
            %     cb_log        - logical, log colorbar
            %   Outputs:
            %     ax       - the plot axes
            %     bin_data - nYears x bins array of counts or percentages
            %                (empty bins NaN)

            arguments
                self
                ax
                ds_query struct
                field_to_plot string
                bin_edges double
                norm_type string {mustBeMember(norm_type, ["count","percent"])}
                cb_lim double
                grid_on logical
                cb_log logical
            end
            % Registry Lists Cannot Be Called In Validators (R2022b)
            mustBeMember(field_to_plot, response_registry('output', 'names', 'per_event', true));
            %%%%


            % Get Response Labels
            [~, ~, ~,...
                ~,...
                vname, vlabel, x_scale_log] = response_library_headers(self.config, field_to_plot);

            % Pull Requested Data Out Of SS Data Structure
            stm_data = aux_methods.pull_data(ds_query, self.project_forcing); % LCS Storm Data
            resp_data = aux_methods.pull_data(ds_query, self.Resp);

            % Handle Nested Structure Case (S Parameters)
            if ismember(field_to_plot, response_registry('output', 'names', 'kind', 'armor_damage'))
                resp_fields = fieldnames(resp_data.S);
                if ~any(contains(field_to_plot, resp_fields))
                    error('Requested field is not present on simulation outputs (Resp)');
                end
                resp_vector = resp_data.S.(field_to_plot);
            else
                resp_fields = fieldnames(resp_data);
                if ~any(contains(field_to_plot, resp_fields))
                    error('Requested field is not present on simulation outputs (Resp)');
                end
                resp_vector = resp_data.(field_to_plot);
            end

            % All-NaN Response (e.g. No Wave Attack): Nothing To Bin
            if ~any(cellfun(@(x) any(isfinite(x(:))), resp_vector))
                ax = aux_methods.initiate_axes(ax, 'Response Bins', 'Simulation Year', [vname ' Distribution By Sim Year'], self.base_fnt);
                aux_methods.display_no_data(ax, self.base_fnt, 'No finite response values to plot');
                bin_data = [];
                return
            end

            % 1. Configuration
            is_count = strcmpi(norm_type, 'count'); % Use Count Or Percentage For bin_data
            % Compute Yearly Max Mean Responses
            % Max: Max is computed for each event across all LCs
            % Event Max responses are binned according to the assigned year
            % Mean is taken for each bin
            [bin_data, bin_edges] = compute_annual_distribution(self, stm_data, resp_vector,self.config.mcs_nYears,...
                x_scale_log, is_count, bin_edges);
            %
            [ax, pp, hb] = plot_annual_distribution(self, ax, bin_data, bin_edges, x_scale_log, is_count, cb_log, cb_lim);
            % Define Axes Fields
            ax.YLabel.String =  'Simulation Year';
            ax.XLabel.String     = aux_methods.latex_escape([vlabel ' Bins']);
            title(ax, aux_methods.latex_escape({[vname ' Distribution By Sim Year']}));


        end
        function bin_edges = generate_bin_guess(self, resp_vector, n_bins, use_log)
            % generate_bin_guess  Bin edges spanning the values of a response.
            %   bin_edges = generate_bin_guess(self, resp_vector)
            %   bin_edges = generate_bin_guess(self, resp_vector, n_bins, use_log)
            %       spaces n_bins edges from the minimum to the maximum of
            %       all cells (log: from the smallest positive value); a
            %       constant response is padded so at least two edges
            %       increase.
            %
            %   Inputs:
            %     resp_vector - N x 1 cell of M x 1 arrays
            %     n_bins      - (optional) number of edges (default 20)
            %     use_log     - (optional) true: log-spaced edges (default false)
            %   Outputs:
            %     bin_edges - unique, sorted edges (row vector)

            if nargin < 2 || isempty(n_bins), n_bins = 20; end
            if nargin < 3 || isempty(use_log), use_log = false; end

            % 1. Extract global min and max across all cells
            % We use @(x) min(x(:)) to handle potential empty cells safely
            all_mins = cellfun(@(x) min(x(:)), resp_vector(~cellfun(@isempty, resp_vector)));
            all_maxs = cellfun(@(x) max(x(:)), resp_vector(~cellfun(@isempty, resp_vector)));

            global_min = min(all_mins);
            global_max = max(all_maxs);

            % 2. Generate edges
            if use_log
                % Ensure we don't take log of 0
                if global_min <= 0
                    global_min = min(all_mins(all_mins > 0));
                    if isempty(global_min), global_min = 1e-3; end
                end
                % Constant Response: Pad Multiplicatively So There Are At Least Two Increasing Edges
                if global_max <= global_min
                    v = global_min;
                    global_min = v / 2;
                    global_max = v * 2;
                end
                bin_edges = logspace(log10(global_min), log10(global_max), n_bins);
            else
                % Constant Response: Pad Around The Value So There Are At Least Two Increasing Edges
                if global_max <= global_min
                    v = global_min;
                    pad = 0.5 * max(abs(v), 1);
                    global_min = v - pad;
                    global_max = v + pad;
                end
                bin_edges = linspace(global_min, global_max, n_bins);
            end

            % 3. Clean up: ensure edges are unique and sorted
            bin_edges = unique(bin_edges);
        end
        function [bin_data, plot_edges] = compute_annual_distribution(self, stm_data, resp_vector, nYears, x_scale_log, is_count, bin_edges)
            % compute_annual_distribution  Yearly bin counts or percentages of storm maxima.
            %   [bin_data, plot_edges] = compute_annual_distribution(self, stm_data, resp_vector, nYears, x_scale_log, is_count, bin_edges)
            %       takes the storm maxima per year (compute_lcs_yearly_curve)
            %       and counts them in bin_edges plus overflow bins below and
            %       above; the overflow bins are mapped to finite plot edges.
            %
            %   Inputs:
            %     stm_data    - cell per life cycle of the LCS forcing matrices
            %     resp_vector - cell per life cycle of the response, rows
            %                   aligned with stm_data
            %     nYears      - number of simulation years
            %     x_scale_log - 1: log X axis (sets the overflow plot edges and
            %                   the automatic edges)
            %     is_count    - 1: counts, else percentages per year
            %     bin_edges   - inner bin edges ([] = generate_bin_guess, 5
            %                   edges)
            %   Outputs:
            %     bin_data   - nYears x bins array (0 shown as NaN)
            %     plot_edges - finite edges for the pcolor plot

            if isempty(bin_edges)
                bin_edges = generate_bin_guess(self, resp_vector, 5, x_scale_log);
            end
            use_log_x = x_scale_log == 1;
            % 2. Dual-Overflow Binning Logic
            min_val = min(bin_edges);
            max_val = max(bin_edges);

            % Create edges that include -Inf and Inf for catch-all behavior
            final_edges = [-Inf, bin_edges, bin_edges(end)+1, Inf]; % Need To Ensure Bin Edge Count Is Isolated


            % Get raw data via your custom curve function
            [~, ~, yBox] = compute_lcs_yearly_curve(stm_data, resp_vector, nYears);

            % Vectorized histogram calculation using cellfun
            % The value X(i) is in the kth bin if edges(k) ≤ X(i) < edges(k+1).
            % The last bin also includes the right bin edge, so that it contains X(i) if edges(end-1) ≤ X(i) ≤ edges(end).
            [bin_count] = cell2mat(cellfun(@(y) histcounts(y, final_edges), yBox, 'UniformOutput', false));

            % Calculate percentages or counts
            if is_count == 1
                bin_data = bin_count;
            else
                bin_data = 100 * (bin_count ./ sum(bin_count, 2));
            end
            bin_data(bin_data == 0) = NaN;

            % 3. Coordinate Prep for Mapping
            % Map the infinite bins to finite visual space for pcolor
            if use_log_x
                lower_buffer = min_val * 0.8;
                upper_buffer = max_val * 1.2;
            else
                if length(bin_edges) == 1
                    buffer_amt = 0;
                else
                    buffer_amt = bin_edges(2)-bin_edges(1);
                end
                if buffer_amt == 0, buffer_amt = 1; end % Safety
                lower_buffer = min_val - buffer_amt;
                upper_buffer = max_val + buffer_amt;
            end

            plot_edges = [lower_buffer, bin_edges, upper_buffer];
                plot_edges(end+1) = plot_edges(end)+(plot_edges(end-1)-plot_edges(end-2));
                bin_data(:, end+1) = bin_data(:, end);
            
        end
        function [ax, pp, hb] = plot_annual_distribution(self, ax, bin_data, bin_edges, use_log_x, is_count, cb_log, cb_lim)
            % plot_annual_distribution  pcolor of a distribution binned by simulation year.
            %   [ax, pp, hb] = plot_annual_distribution(self, ax, bin_data, bin_edges, use_log_x, is_count, cb_log, cb_lim)
            %
            %   Inputs:
            %     ax        - axes, figure or grid layout (aux_methods.initiate_axes)
            %     bin_data  - nYears x bins array (compute_annual_distribution)
            %     bin_edges - plot edges (compute_annual_distribution
            %                 plot_edges); the first and last bins are
            %                 labelled as overflow bins
            %     use_log_x - 1: log X axis
            %     is_count  - 1: colorbar label "Count", else "Percentage"
            %     cb_log    - true: log colorbar
            %     cb_lim    - colorbar limits ([] = data range, [0 100] when
            %                 constant)
            %   Outputs:
            %     ax - the plot axes
            %     pp - the pcolor surface
            %     hb - the colorbar

            % Define Axes Fields
            y_label_cb = aux_methods.tern(is_count == 1, 'Count of Total Events', 'Percentage of Total Events');
            y_label     =  'Simulation Year';
            x_label     = 'Response Bins';
            title_label = '';
            % Initialize Axes
            ax = aux_methods.initiate_axes(ax, x_label, y_label, title_label, self.base_fnt);

            num_bins = length(bin_edges);

            labels = cell(1, num_bins);
            for i = 1:(num_bins)
                switch i
                    case 1
                        labels{i} = sprintf('x <= %.2f', bin_edges(i+1));
                    case num_bins
                        labels{i} = sprintf('x >= %.2f', bin_edges(i-1));
                    otherwise
                        labels{i} = sprintf('%.2f', bin_edges(i));
                end
            end

            % 3. Apply to your pcolor plot
            xticks(ax,bin_edges);
            xticklabels(ax,labels);
            %
            [xx, yy] = meshgrid(bin_edges, 1:self.config.mcs_nYears);

            % PLot Actual 2D distirbution
            pp=pcolor(ax, xx, yy, bin_data);
            pp.EdgeColor = 'k';
            % 5. Axis Formatting
            set(ax, 'XScale', aux_methods.tern(use_log_x==1, 'log', 'linear'));



            xlim(ax, [min(xx,[],'all') max(xx,[],'all')]);
            ylim(ax, [1, self.config.mcs_nYears]);


            % 6. Colorbar & Styling
            chess_colormap(ax);
            %
            hb = colorbar(ax);
            ylabel(hb, y_label_cb, 'FontSize', self.base_fnt);
            %
            if cb_log
                set(ax, 'ColorScale', 'log');
            end
            %
            if ~isempty(cb_lim)
                clim(ax, cb_lim);
            else
                min_val = min(bin_data,[], 'all','omitnan');
                max_val = max(bin_data,[], 'all','omitnan');
                if min_val == max_val
                    clim(ax, [0 100]);
                else
                    clim(ax, [min_val max_val]);
                end
            end
        end
    end

    %% STORM EVENT VIEWER / RESPONSE TABLE (WORKFLOW 3)
    % Saved life-cycle matrices (project_forcing.<dt>.<mt>.<st>{lc}, columns: lcs_columns.m) and the responses aligned
    % row for row (Resp...<st>.<field>{lc}); S_* damage series only when the run saved them (DPA on). Nothing is computed.
    methods (Access=public)
        function ch = event_choices(self, ds_query)
            % event_choices  Storm event viewer / response table choices of an LCS dataset.
            %   ch = event_choices(self, ds_query)
            %
            %   Inputs:
            %     ds_query - dataset query (storm_type, data_type, match_type)
            %   Outputs:
            %     ch - struct: storm_ids ([]), is_ts (Timeseries data),
            %          peaks_toggle (= is_ts), n_lc (number of life cycles),
            %          years (cell per life cycle: simulation years with
            %          storms)

            C = lcs_columns();
            pf = self.event_matrices(ds_query);
            ch.storm_ids = [];
            ch.is_ts = strcmp(ds_query.data_type, 'Timeseries');
            ch.peaks_toggle = ch.is_ts;
            ch.n_lc = numel(pf);
            ch.years = cellfun(@(x) unique(x(:, C.year))', pf, 'un', false);
        end

        function sel = refine_selection(~, sel, choices)
            % refine_selection  Validate the life cycle and year of a selection.
            %   sel = refine_selection(self, sel, choices) sets sel.lc to 1
            %       when it is not a valid life cycle and sel.year to 'All'
            %       when it is not a year with storms in that life cycle.
            %
            %   Inputs:
            %     sel     - selection struct (CHESSPlotsBase.event_selection)
            %     choices - event_choices output (n_lc, years)
            %   Outputs:
            %     sel - the selection struct

            if ~isnumeric(sel.lc) || ~isscalar(sel.lc) || sel.lc < 1 || sel.lc > choices.n_lc
                sel.lc = 1;
            end
            sel.lc = round(sel.lc);
            if ~(ischar(sel.year) && strcmp(sel.year, 'All')) && (isempty(sel.year) || ~ismember(sel.year, choices.years{sel.lc}))
                sel.year = 'All';
            end
        end

        function ctrl = event_controls(~, parent, row, sel, choices, emit)
            % event_controls  Control row: life cycle, simulation year and peaks view.
            %   ctrl = event_controls(self, parent, row, sel, choices, emit)
            %       builds the life cycle and year ('All' or one) dropdowns
            %       and, for Timeseries data, the peaks-view checkbox.
            %
            %   Inputs:
            %     parent  - uigridlayout holding the row
            %     row     - grid row of the control row
            %     sel     - selection struct (lc, year, peaks_view)
            %     choices - event_choices output
            %     emit    - function handle emit(field_name, value)
            %   Outputs:
            %     ctrl - uigridlayout of the control row

            ctrl = uigridlayout(parent, [1 6], 'ColumnWidth', {'fit', 90, 'fit', 90, 'fit', '1x'}, 'RowHeight', {'1x'}, 'Padding', [5 2 5 2]);
            ctrl.Layout.Row = row;
            years = choices.years{sel.lc};
            uilabel(ctrl, 'Text', 'Life cycle:', 'HorizontalAlignment', 'right');
            uidropdown(ctrl, 'Items', arrayfun(@num2str, 1:choices.n_lc, 'un', false), 'ItemsData', 1:choices.n_lc, 'Value', sel.lc, ...
                'ValueChangedFcn', @(src, ~) emit('lc', src.Value));
            uilabel(ctrl, 'Text', 'Year:', 'HorizontalAlignment', 'right');
            uidropdown(ctrl, 'Items', [{'All'}, arrayfun(@num2str, years, 'un', false)], 'ItemsData', [{'All'}, num2cell(years)], ...
                'Value', sel.year, 'ValueChangedFcn', @(src, ~) emit('year', src.Value));
            if choices.peaks_toggle
                uicheckbox(ctrl, 'Text', aux_methods.tern(sel.peaks_view, 'Swap to timeseries view', 'Swap to peaks view'), ...
                    'Value', sel.peaks_view, 'ValueChangedFcn', @(src, ~) emit('peaks_view', logical(src.Value)));
            end
        end

        function ser = event_series(self, ds_query, response_to_view, sel)
            % event_series  Storm event viewer series of the LCS results.
            %   ser = event_series(self, ds_query, response_to_view, sel)
            %       Timeseries view: the storm hours of the chosen year (one
            %       color per storm) or of the whole life cycle (one style,
            %       storm start/end lines, years on the axis). Peaks view /
            %       Peaks data: one marker per storm. Nothing is computed.
            %
            %   Inputs:
            %     ds_query         - dataset query (storm_type, data_type, match_type)
            %     response_to_view - response name (char or string)
            %     sel              - selection struct (lc, year, peaks_view)
            %   Outputs:
            %     ser - struct of the storm event viewer series (x, x_kind,
            %           storm_ids, swl, hm0_off, hm0_toe, h, rc, hb, resp
            %           ([] when not saved), event_str and the optional
            %           fields of CHESSPlotsBase.event_series_defaults)

            d = self.event_data(ds_query, sel);
            ser = rmfield(d, {'cols', 'mode', 'time_table', 'view_label', 'plot_title', 'extra', 'ids'});
            ser.storm_ids = d.ids;
            ser.swl = d.cols.SWL;
            ser.hm0_off = d.cols.Hm0_offshore;
            ser.hm0_toe = d.cols.Hm0_toe;
            ser.h = d.cols.h;
            ser.rc = d.cols.Rc;
            ser.hb = self.berm_depth(ser.swl);
            ser.resp = [];
            resp_name = char(response_to_view);
            if isfield(d.cols, resp_name)
                ser.resp = d.cols.(resp_name);
            end
        end

        function [T, info] = event_table(self, ds_query, sel)
            % event_table  Response table rows of the LCS results.
            %   [T, info] = event_table(self, ds_query, sel)
            %
            %   Inputs:
            %     ds_query - dataset query (storm_type, data_type, match_type)
            %     sel      - selection struct (lc, year, peaks_view)
            %   Outputs:
            %     T    - table of the viewer rows (storm hours: Time, StormID,
            %            Year, Order; or one row per storm: StormID, Year,
            %            Order) with every forcing and response column
            %     info - struct: mode ('ts' or 'peaks'), view_label,
            %            plot_title, x_label

            d = self.event_data(ds_query, sel);
            if strcmp(d.mode, 'ts')
                T = table(d.time_table(:), d.ids(:), d.extra.Year(:), d.extra.Order(:), 'VariableNames', {'Time', 'StormID', 'Year', 'Order'});
            else
                T = table(d.ids(:), d.extra.Year(:), d.extra.Order(:), 'VariableNames', {'StormID', 'Year', 'Order'});
            end
            for f = fieldnames(d.cols)'
                T.(f{1}) = d.cols.(f{1})(:);
            end
            info = struct('mode', d.mode, 'view_label', d.view_label, 'plot_title', d.plot_title, 'x_label', 'Storm Duration [hrs]');
        end
    end

    methods (Access=private)
        function pf = event_matrices(self, ds_query)
            % Saved Life-Cycle Matrices Of The Queried Dataset (Cell Per Life Cycle)
            if isempty(self.project_forcing)
                error('lcs_methods:noForcing', 'The saved project forcing is not available for this run.');
            end
            pf = aux_methods.pull_data(ds_query, self.project_forcing);
        end

        function d = event_data(self, ds_query, sel)
            % Rows Of The Chosen Life Cycle (And Year): mode 'ts' (One Row Per Time Step, Storms In Order) Or 'peaks' (One Row Per Storm,
            % [year, order, bin] Groups: Maxima, Rc Minimum). cols: SWL, Hm0_offshore, Hm0_toe, Tp, h, Rc, Saved Responses
            C = lcs_columns();
            pf = self.event_matrices(ds_query);
            M = pf{sel.lc};
            R = aux_methods.pull_data(ds_query, self.Resp);
            all_years = ischar(sel.year);
            if all_years
                rows = (1:size(M, 1))';
            else
                rows = find(M(:, C.year) == sel.year);
            end
            Mk = M(rows, :);
            n = size(Mk, 1);
            if n > 0
                [~, ~, g] = unique(Mk(:, [C.year C.order C.bin]), 'rows', 'stable'); % Storms (Rows Of A Storm Are Contiguous; Order Restarts In Each Bin)
                segs = accumarray(g, (1:n)', [], @(r) {r});
            else
                g = zeros(0, 1);
                segs = {};
            end
            firsts = cellfun(@(r) r(1), segs);
            lasts = cellfun(@(r) r(end), segs);
            % Per-Row Series: Forcing From The Matrix, Responses (And S_*) Aligned Row For Row With It
            row_cols.SWL = Mk(:, C.SWL);
            row_cols.Hm0_offshore = Mk(:, C.Hm0_offshore);
            row_cols.Hm0_toe = Mk(:, C.Hm0_toe);
            row_cols.Tp = Mk(:, C.Tp);
            for f = fieldnames(R)'
                add_response(f{1}, R.(f{1}));
            end
            if isfield(R, 'S') && isstruct(R.S)
                for f = fieldnames(R.S)'
                    if ismember(f{1}, response_registry('output', 'names', 'damage_summary', 'series'))
                        add_response(f{1}, R.S.(f{1}));
                    end
                end
            end
            toe = self.structure.toe_elevation;
            crest = self.structure.crest_elevation;
            is_ts = size(M, 2) == C.n_timeseries && ~sel.peaks_view;
            d.extra.Year = Mk(firsts, C.year);
            d.extra.Order = Mk(firsts, C.order);
            if all_years
                year_str = 'All years';
            else
                year_str = sprintf('Year %d', sel.year);
            end
            d.x_label = '';
            d.segments = [];
            d.color_segments = false;
            d.bounds = [];
            d.xticks = [];
            if is_ts
                d.mode = 'ts';
                d.cols = row_cols;
                d.cols.h = d.cols.SWL - toe;
                d.cols.Rc = crest - d.cols.SWL;
                step_h = Mk(:, C.dt)*24;
                hours = cumsum([0; step_h(1:max(n - 1, 0))]);
                hours = hours(1:n);
                d.x = hours;
                d.x_kind = 'hours';
                d.time_table = hours;
                d.ids = Mk(:, C.id);
                d.extra.Year = Mk(:, C.year);
                d.extra.Order = Mk(:, C.order);
                d.segments = segs;
                if all_years % One Style, Storm Start/End Lines, Years On The X Axis (First Storm Of Each Year)
                    d.bounds = [hours(firsts); hours(lasts)];
                    [yrs, iy] = unique(Mk(:, C.year), 'stable');
                    keep = 1:max(1, ceil(numel(yrs)/15)):numel(yrs);
                    if ~isempty(keep)
                        d.xticks = struct('pos', hours(iy(keep))', 'labels', {arrayfun(@num2str, yrs(keep)', 'un', false)});
                    end
                    d.x_label = 'Simulation Year';
                else % One Color Per Storm
                    d.color_segments = true;
                    d.x_label = sprintf('Storm Duration In Year %d [hrs]', sel.year);
                end
                d.event_str = sprintf('Life cycle %d | %s | %d storms', sel.lc, year_str, numel(segs));
                d.view_label = sprintf('%s Timeseries (life cycle %d, %s, %d storms)', ds_query.storm_type, sel.lc, year_str, numel(segs));
                d.plot_title = sprintf('Life cycle %d | %s', sel.lc, year_str);
            else
                d.mode = 'peaks';
                reduce = @(v) accumarray(g, v(:), [], @(a) max(a, [], 'omitnan'));
                if n == 0
                    reduce = @(v) zeros(0, 1);
                end
                d.cols.SWL = reduce(row_cols.SWL);
                d.cols.Hm0_offshore = reduce(row_cols.Hm0_offshore);
                d.cols.Hm0_toe = reduce(row_cols.Hm0_toe);
                d.cols.Tp = reduce(row_cols.Tp);
                d.cols.h = d.cols.SWL - toe;
                d.cols.Rc = crest - d.cols.SWL;
                for f = setdiff(fieldnames(row_cols), fieldnames(d.cols), 'stable')'
                    d.cols.(f{1}) = reduce(row_cols.(f{1}));
                end
                d.x = (1:numel(segs))';
                d.x_kind = 'event';
                d.time_table = [];
                d.ids = Mk(firsts, C.id);
                d.event_str = sprintf('Life cycle %d | %s | %d storms (peaks)', sel.lc, year_str, numel(segs));
                d.view_label = sprintf('%s Peaks (life cycle %d, %s, %d storms)', ds_query.storm_type, sel.lc, year_str, numel(segs));
                d.plot_title = '';
            end

            function add_response(name, v)
                % Adds A Response Cell With One Value Per Row Of This Life Cycle To row_cols
                if iscell(v) && numel(v) >= sel.lc && isnumeric(v{sel.lc}) && size(v{sel.lc}, 1) == size(M, 1) && size(v{sel.lc}, 2) == 1
                    row_cols.(name) = v{sel.lc}(rows);
                end
            end
        end
    end
end

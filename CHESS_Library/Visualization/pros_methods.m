classdef pros_methods < CHESSPlotsBase
    % PROS_METHODS PROS/frequency-domain workflow plots (workflow = 1 or 4).
    % Instantiated via CHESSPlots(...).
 %% PUBLIC METHODS
    methods (Access=public)
        % Method: Response Hazard Curve Plot 
        function ax = hc_plot(self, ax, ds_names, field_to_plot, add_events)
            % Plots CHESS: PROS Hazard Curve for specified field on Resp data structure.

            % Pull Requested Data Out Of SS Data Structure
            sim_data = aux_methods.pull_data(ds_names, self.Resp);
            % Define Plot Field
            plt_fld = 'y_plot';
            plt_fld_x = 'x_plot';
            % Define Color Pallet ( Mean + <=4 additional CLs )
            colorstr = {'k-','b--','r--','m--','c--'};%{'k-','b-.','r-.','r--','b--'};
            % Grab response Data To Plot
            plt = sim_data(strcmp({sim_data.var}, field_to_plot));
            % Requested Field Not In Results: No Data (plt Labels Below Would Fail On An Empty Struct)
            if isempty(plt)
                ax = aux_methods.initiate_axes(ax, '', '', '', self.base_fnt);
                aux_methods.display_no_data(ax, self.base_fnt);
                return
            end

            % Define XTick Labels And XTicks
            if self.config.pros_use_aep == 1
                x_label = 'Annual Exceedance Probability, AEP';
                xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3]);
                xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}'});
                x_lim = [10^-3, 1];
            else
                x_label = 'Annual Exceedance Frequency, AEF [1/yr]';
                xticks_data = fliplr([10^0, 10^-1, 10^-2, 10^-3, 10^-4]);
                xticks_data_lbl = fliplr({'10^0', '10^{-1}', '10^{-2}', '10^{-3}', '10^{-4}'});
                x_lim = [10^-4 1];
            end
            % Initialize Axes
            ax = aux_methods.initiate_axes(ax, x_label, plt.y_label, plt.title, self.base_fnt);
            % Adjust Axes According To Data specs
            if plt.y_log_scale ==0
                set(ax,'XScale','log','YScale','linear','XDir','reverse');
            else
                set(ax,'XScale','log','YScale','log','XDir','reverse');
            end
            % Check If Field Is Available (Was isempty(plt_pass): Always False, So Missing Data Never Showed The No-Data Note)
            no_data = isempty(plt) || isempty(plt.(plt_fld));
            % Plot If Data Available
            if no_data
                % Clear Axes
                cla(ax);
                aux_methods.display_no_data(ax, self.base_fnt);
            else
                % Limit AEF Vector
                s_lim_indx = plt.(plt_fld_x)>=x_lim(1);
                % Set X Ticks
                ax.XTick = xticks_data;
                ax.XTickLabel = xticks_data_lbl;
                % Set X Lim
                ax.XLim = x_lim;
                % Set Y Lim
                if numel(plt.(plt_fld)(s_lim_indx, :))~=sum(isnan(plt.(plt_fld)(s_lim_indx, :)),'all')
                    try
                        ax.YLim = [min(plt.(plt_fld)(s_lim_indx, :),[],'all','omitnan'),max(plt.(plt_fld)(s_lim_indx, :),[],'all','omitnan')];
                    end
                end
                % Grab CLs
                prc = plt.CL;
                p_cl = gobjects(1, length(plt(1).(plt_fld)(1,:)));
                % For Each CL
                for i = 1:length(plt(1).(plt_fld)(1,:))
                    % Define Curve Name
                    if prc(i) == 50
                        DataName = 'Best Estimate';
                    else
                        DataName = [num2str(prc(i)) '%'];
                    end
                    % PLot CL into Axes
                    p_cl(i) = plot(ax,plt.(plt_fld_x)(s_lim_indx,1),...
                        plt.(plt_fld)(s_lim_indx,i),...
                        colorstr{i},'LineWidth',2,'DisplayName',DataName);
                    % Update Data Tip
                    row = dataTipTextRow('RowID', 1:length(plt.(plt_fld_x)(s_lim_indx,1)));
                    % Append Neew Data Tip
                    p_cl(i).DataTipTemplate.DataTipRows(end+1) = row;
                end
                % Events Overlay: 0 Off, 1 Run Sample (POT Replicates), 2 Storm Values (POT z = 0 Replicate)
                p_ev = gobjects(0);
                % CC Has No Overlays (POT Is A Note, No CC Storm Set); FB POT Is A Note Too
                if strcmp(ds_names.storm_type, 'CC') || ~isnumeric(plt.POT)
                    add_events = 0;
                end
                switch double(add_events)
                    case 1
                        p_ev = self.add_run_sample(ax, plt.POT, ds_names.storm_type, plt.n_dropped);
                    case 2
                        p_ev = self.add_storm_values(ax, plt.POT,...
                            plt.(plt_fld_x)(s_lim_indx,1), plt.(plt_fld)(s_lim_indx,1));
                end
                % Add Legend (CLs First; Overlay Entry Wraps To Its Own Row)
                legend2 = legend(ax, [p_cl, p_ev]);
                % Get Legend Title Handle
                htitle = get(legend2,'Title');
                % Define Legend Location
                set(legend2,'Location','Best','FontSize',ax.FontSize,'Orientation','horizontal','NumColumns',length(prc));
                % Define Legened Title
                set(htitle,'String','Confidence Levels');
            end
        end
        % Method: CHESS: PROS-RB vs CHESS: PROS-FB
        function [ax, fb_data] = frequency_base_comparison_plot(self, ax, ds_names, field_to_plot)
            % Define Plot Field
            plt_fld = 'y_plot';
            plt_fld_x = 'x_plot';
            % Define Color Pallet ( Mean + <=4 additional CLs )
            colorstr = {'k:','b:','r:','m:','c:'};
            if self.config.pros_use_aep == 1
                x_lim = [10^-3, 1];
            else
                x_lim = [10^-4 1];
            end
            % Plot RB Hazard Curve
            ax = self.hc_plot(ax, ds_names, field_to_plot, false);
            % Compute FB responses
            fb_data = call_pros_fb(self, ds_names);
            % Pull Out Requested response
            var_indx = strcmp(field_to_plot, {fb_data.var});
            plt = fb_data(var_indx);
            % Check If Field Is Available (Was isempty(plt_pass): Always False, So Missing Data Never Showed The No-Data Note)
            no_data = isempty(plt) || isempty(plt.(plt_fld));
            % Plot If Data Available (FB Curve Missing: Keep RB Plot, Skip FB Lines)
            if ~no_data
                % Limit AEF Vector
                s_lim_indx = plt.(plt_fld_x)>=x_lim(1);
                % Grab CLs
                prc = plt.CL;
                % For Each CL
                for i = 1:length(plt(1).(plt_fld)(1,:))
                    % Define Curve Name
                    if prc(i) == 50
                        DataName = 'Best Estimate (FB)';
                    else
                        DataName = [num2str(prc(i)) '% (FB)'];
                    end
                    % PLot CL into Axes
                    p = plot(ax,plt.(plt_fld_x)(s_lim_indx,1),...
                        plt.(plt_fld)(s_lim_indx,i),...
                        colorstr{i},'LineWidth',2,'DisplayName',DataName);
                    % Update Data Tip
                    row = dataTipTextRow('RowID', 1:length(plt.(plt_fld_x)(s_lim_indx,1)));
                    % Append New Data Tip
                    p.DataTipTemplate.DataTipRows(end+1) = row;
                end
                % Expand Y Lim To Include FB Curves (hc_plot Sets It From RB Only)
                fb_y = plt.(plt_fld)(s_lim_indx, :);
                fb_y = fb_y(isfinite(fb_y)); % Finite Values Only (Inf Would Break YLim)
                if strcmp(ax.YScale, 'log')
                    fb_y = fb_y(fb_y > 0); % Log Axes: Positive Values Only
                end
                if ~isempty(fb_y)
                    ax.YLim = [min([ax.YLim(1); fb_y(:)]), max([ax.YLim(2); fb_y(:)])];
                end
            end
        end
        % Method: Estimate AEF Associated To Event Responses
        function [data_out, idx] = get_aef(self, response_vector, benchmark_aef, benchmark_hc, dsw, resp_indx)
            % GET_AEF Find associated AEF value to provided event responses.
            %
            % Inputs:
            %   storm_id        - Array of integers
            %   response_vector - Array of floats
            %   benchmark_aef   - Array of floats
            %   benchmark_hc    - Array of floats
            %   dsw             - (Optional) Array of floats
            %
            % Output:
            %   data_out        - Struct containing storm_id, aef, and response

            % Handle optional 'dsw' argument (Treat empty or missing as None)
            if nargin < 5 || isempty(dsw)
                dsw = [];
                resp_indx = [];
            end

            % Validate shape if dsw is provided
            if ~isempty(dsw)
                if ~isequal(size(dsw), size(response_vector))
                    error('dsw must have shape [%s], but got [%s]', ...
                        num2str(size(response_vector)), num2str(size(dsw)));
                end
            end

            % Sort response Vector in descending order
            [~, idx] = sort(response_vector, 'descend');

            % Execute AEF Estimation According To Storm Type
            if isempty(dsw)
                % Apply Sorting
                resp_sorted = response_vector(idx);
                if ~isempty(resp_indx)
                    resp_indx = resp_indx(idx);
                end

                % Interpolate log(AEF) at sorted responses
                x = benchmark_hc(:);
                y = log(benchmark_aef(:));
                % JPM Sets Negative Curve Values To NaN: Keep Finite, Distinct Curve Points Only
                keep = isfinite(x) & isfinite(y);
                x = x(keep);
                y = y(keep);
                [x, ia_x] = unique(x, 'stable');
                y = y(ia_x);

                if numel(x) < 2
                    aef_out = NaN(size(resp_sorted));
                else
                    % Note: np.interp clamps out-of-bounds values to the edges.
                    % MATLAB returns NaN by default. We clamp the inputs here to mimic Python.
                    resp_clamped = max(min(resp_sorted, max(x)), min(x));
                    vq = interp1(x, y, resp_clamped, 'linear');

                    % Report AEF Out With Original Sorting
                    aef_out = exp(vq);
                end

            else
                % Process TC Storm Suite

                % Apply Sorting
                y_val = response_vector(idx);
                %storm_id_sorted = storm_id(idx);
                if ~isempty(resp_indx)
                    resp_indx = resp_indx(idx);
                end
                % Compute AEF From DSWs (Cumulative Sum)
                x_aef = cumsum(dsw(idx));

                % Remove infinities from the log
                mask = isfinite(log(x_aef));
                y_val = y_val(mask);
                x_aef = x_aef(mask);
                if ~isempty(resp_indx)
                    resp_indx(mask) = resp_indx(mask);
                end
                % Get Log Of AEF
                lx = log(x_aef);

                % Unique values (Use 'first' to match Python's np.unique behavior)
                [~, ia_x] = unique(lx, 'stable');

                % Apply Mask And Revert To AEF
                resp_sorted = y_val(ia_x);
                %storm_id_sorted = storm_id_sorted(ia_x);
                aef_out = exp(lx(ia_x));
                if ~isempty(resp_indx)
                    resp_indx = resp_indx(ia_x);
                end

            end

            % Build AEF Output Structure (Equivalent to Python Dictionary)
            % 'storm_id', storm_id_sorted, ...
            data_out = struct(...
                'aef', aef_out, ...
                'response', resp_sorted,...
                'resp_indx', resp_indx);
        end

    end
    %% METHOD: PSE OVERLAY PLOT (TO BE DEPRECATED)
    methods (Access=private)
        % DEPRECATED: kept only until callers migrate off this method. Do not extend.
        function tbl_out = pse_and_response_overlay_plot(self, ax_geom, ds_query, field_to_plot, field_to_plot2, cl_to_plot, overlay_pot)
            % ==========================================
            % 1. DATA EXTRACTION & PREP
            % ==========================================
            sim_data = aux_methods.pull_data(ds_query, self.Resp);
            d_left  = sim_data(strcmp({sim_data.var}, field_to_plot));
            d_right = sim_data(strcmp({sim_data.var}, field_to_plot2));

            dsw_mod = aux_methods.tern(strcmp(ds_query.storm_type, 'TC'), self.dsw, []);

            if self.config.pros_use_aep == 1
                v_freq = ceil(1 ./ aep2aef(sim_data(1).x_table));
            else
                v_freq = 1 ./ sim_data(1).x_table;
            end

            s_years = [20, 50, 100, 500];
            cb_ticks = [1, 5, 10, 20, 50, 100, 500]';
            f_indx = arrayfun(@(x) find(v_freq == x, 1), s_years);
            cl_indx = ismember(d_left.CL, cl_to_plot);

            resp_left = d_left.y_table(f_indx, cl_indx);
            resp_right = d_right.y_table(f_indx, cl_indx);

            % ==========================================
            % 2. GRID CLEANUP & PADDING (Fix 4: Cutoffs)
            % ==========================================
            if isempty(ax_geom) || ~isvalid(ax_geom)
                fig = uifigure('Name', 'CHESS Overlay Debugger', 'Position', [100 100 1000 600]);
                % Create the nested-style 1x2 grid we've been using
                plotGrid = uigridlayout(fig, [1 2]);
                plotGrid.ColumnWidth = {'1x', 100}; % Dedicated Colorbar Column
                plotGrid.Padding = [30 20 0 20];
                plotGrid.ColumnSpacing = 15;

                ax_geom = uiaxes(plotGrid);
                ax_geom.Layout.Row = 1;
                ax_geom.Layout.Column = 1;
            else
                plotGrid = ax_geom.Parent;
                % Provide a safety margin for labels: [Left, Bottom, Right, Top]
                plotGrid.ColumnWidth{2} = 100; % Fix Col Width For this Plot Only
                plotGrid.Padding = [30 20 0 20];
                plotGrid.ColumnSpacing = 15;
            end

            % Hard sweep of old artifacts
            delete(findall(plotGrid, 'Tag', 'clone'));
            delete(findall(plotGrid, 'Tag', 'cb_anchor'));
            delete(findall(plotGrid, 'Type', 'ColorBar'));

            % ==========================================
            % 3. UNDERLAY (Geometry)
            % ==========================================
            [ax_geom, ~] = self.pse_transect_plot(ax_geom);
            ax_geom.Color = [0.8 0.8 0.8];
            ax_geom.PositionConstraint = 'innerposition';
            ax_geom.Layout.Row = 1; ax_geom.Layout.Column = 1;
            % Geometry Shifting
            x_shift = 3; x_new = 0;
            for tag = ["pse", "sand"]
                geo_obj = findall(ax_geom, 'Tag', char(tag));
                if ~isempty(geo_obj)
                    geo_obj.Shape.Vertices(:, 1) = geo_obj.Shape.Vertices(:, 1) + x_shift;
                    if tag == "sand"
                        geo_obj.Shape.Vertices(:, 1) = geo_obj.Shape.Vertices(:, 1) + [2; -2; -2; 2];
                    end
                    x_new = max(x_new, max(geo_obj.Shape.Vertices(:, 1)));
                end
            end
            ax_geom.XLim = [0, x_new+x_shift];
            ylim_new = max([self.structure.crest_elevation, max([resp_left, resp_right], [], 'all')]);
            ax_geom.YLim = [min(ax_geom.YLim)-0.5, ylim_new + 0.2];

            % Intersection math
            geo_poly = findall(ax_geom, 'Tag', 'pse').Shape;
            switch self.structure.struc_type
                case 2 % Floodwall
                    left_x = repmat(geo_poly.Vertices(1,1), size(resp_left));
                    right_x = repmat(max(geo_poly.Vertices(1,1)), size(resp_right));
                otherwise
                    crest_idx = find(geo_poly.Vertices(:,2) == self.structure.crest_elevation);
                    left_x = repmat(min(geo_poly.Vertices(crest_idx, 1)), size(resp_left)) - 4;
                    right_x = repmat(max(geo_poly.Vertices(crest_idx, 1)), size(resp_right)) + 4;
            end

            % ==========================================
            % 4. OVERLAY & ANCHOR (Resize-Proof Lock)
            % ==========================================
            ax_clone = uiaxes(plotGrid, 'Color', 'none', 'Tag', 'clone');
            ax_clone.Layout.Row = 1; ax_clone.Layout.Column = 1;
            ax_clone.PositionConstraint = 'innerposition';
            set(ax_clone, 'FontSize', self.base_fnt - 2, 'FontWeight', 'bold');
            ax_clone.XLabel.String = ax_geom.XLabel.String;
            ax_clone.XLabel.FontSize = self.base_fnt;

            % Invisible Anchor for Colorbar (trapped in Col 2)
            ax_anchor = uiaxes(plotGrid, 'Visible', 'off', 'Tag', 'cb_anchor', 'HandleVisibility', 'off');
            ax_anchor.Layout.Row = 1; ax_anchor.Layout.Column = 2;

            % Force Grid Math Refresh
            drawnow;
            hLink = linkprop([ax_geom, ax_clone], 'InnerPosition');
            setappdata(ax_clone, 'PositionLink', hLink);
            hold(ax_clone, 'on');

            % ==========================================
            % 5. PLOTTING & COLORBAR (Fix 1 & 2)
            % ==========================================
            % Setup Left Axis
            yyaxis(ax_clone, 'left');
            ax_clone.YAxis(1).Scale = aux_methods.tern(d_left.y_log_scale == 1, 'log', 'linear');
            ylabel(ax_clone, d_left.y_label, 'Color', 'b', 'FontWeight', 'bold', 'FontSize', self.base_fnt);

            % Prepare color scales
            set(ax_clone, 'ColorScale', 'log');
            ax_clone.CLim = [1, 500];

            % Fix 1: Generate color map logic without creating a colorbar handle yet
            [~, c_line] = generate_custom_colorbar(cb_ticks, build_custom_cmap(), ax_clone);
            delete(findall(ax_clone.Parent, 'Type', 'ColorBar')); % Safety sweep

            if overlay_pot
                ax_anchor.ColorScale = 'log';
                ax_anchor.CLim = [1, 500];
                colormap(ax_anchor, build_custom_cmap());
                hc = colorbar(ax_anchor, 'Location','west');
                hc.Ticks = cb_ticks;
                hc.TickLabels = string(cb_ticks);
                hc.FontSize = self.base_fnt - 2;
                ylabel(hc, 'ARI [yrs]', 'FontWeight', 'bold', 'FontSize', self.base_fnt);

                % Left Side Scatter
                [~, ~, ss_left] = add_events(ax_clone, d_left.POT, 0, max(left_x, [], "omitnan"),...
                    d_left.x_plot, d_left.y_plot(:, 1), dsw_mod, s_years, [], []);

                % FIX 1: Capture the colors immediately for the left side
                ss_left.CData = extract_rgb_from_cdata(ax_clone, ss_left.CData);
            end

            % Setup Right Axis
            yyaxis(ax_clone, 'right');
            ax_clone.YAxis(2).Scale = aux_methods.tern(d_right.y_log_scale == 1, 'log', 'linear');
            ylabel(ax_clone, d_right.y_label, 'FontWeight', 'bold', 'FontSize', self.base_fnt);

            % RE-LOCK COLOR SCALE FOR RIGHT SIDE
            set(ax_clone, 'ColorScale', 'log');
            ax_clone.CLim = [1, 500];

            if overlay_pot
                [~, ~, ss_right] = add_events(ax_clone, d_right.POT, min(right_x, [], "omitnan"), ...
                    max(ax_geom.XLim), d_right.x_plot, d_right.y_plot(:, 1), dsw_mod, s_years, [], []);

                % FIX 1: Capture the colors immediately for the right side
                ss_right.CData = extract_rgb_from_cdata(ax_clone, ss_right.CData);
            end

            p_dummy = gobjects(1, length(f_indx));
            for kk = 1:length(f_indx)
                c_rgb = c_line(cb_ticks == v_freq(f_indx(kk)), :);
                lbl_str = string(s_years(kk)) + " yrs";

                yyaxis(ax_clone, 'left');
                plot(ax_clone, [0, left_x(kk)], [resp_left(kk), resp_left(kk)], 'Color', c_rgb, 'LineWidth', 1.5);
                text(ax_clone, 0, resp_left(kk), " " + lbl_str, 'Color', c_rgb, 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');

                yyaxis(ax_clone, 'right');
                plot(ax_clone, [right_x(kk), max(ax_geom.XLim)], [resp_right(kk), resp_right(kk)], 'Color', c_rgb, 'LineWidth', 1.5);
                text(ax_clone, right_x(kk), resp_right(kk), " " + lbl_str, 'Color', c_rgb, 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');

                p_dummy(kk) = plot(ax_geom, NaN, NaN, 'Color', c_rgb, 'DisplayName', lbl_str);
            end

            yyaxis(ax_clone, 'left');
            ax_clone.YLim = calculate_bounds(resp_left, field_to_plot, ax_geom);

            yyaxis(ax_clone, 'right');
            ax_clone.YLim = calculate_bounds(resp_right, field_to_plot2, ax_geom);


            % ==========================================
            % 6. DEPTH RULER (Fix 3: Centering)
            % ==========================================
            vtx_pse = geo_poly.Vertices;
            % Find exact top crest horizontal center
            max_y = max(vtx_pse(:,2));
            xo_ruler = mean(vtx_pse(vtx_pse(:,2) == max_y, 1));

            add_floating_y_axis(ax_geom, xo_ruler, 2, 'Elevation [m, NAVD88]');

            % ==========================================
            % 7. FINAL STACK & SYNC
            % ==========================================
            if overlay_pot && exist('ss_left', 'var')
                %                 ss_left.CData = extract_rgb_from_cdata(ax_clone, ss_left.CData);
                %                 ss_right.CData = extract_rgb_from_cdata(ax_clone, ss_right.CData);
            else
                lg = legend(ax_geom, p_dummy, 'Location', 'northoutside', 'Orientation', 'horizontal');
                title(lg, 'ARI');
            end

            ax_clone.XLim = ax_geom.XLim;
            linkaxes([ax_geom, ax_clone], 'x');

            % Hide geometry visuals
            ax_geom.YAxis.Visible = 'off';
            ax_geom.XAxis.Visible = 'off';
            ax_geom.YLabel.Visible = 'off';
            ax_geom.Toolbar.Visible = 'off';
            ax_clone.Toolbar.Visible = 'off';

            %             uistack(ax_clone, 'top'); % Data on top
            drawnow;

            % Output
            tbl_out.tbl_data = [v_freq(f_indx), resp_left, resp_right];
            tbl_out.tbl_headers = ["ARI", field_to_plot, field_to_plot2];
            % ---------------------------------------------------------
            % HELPER FUNCTIONS
            % ---------------------------------------------------------
            function [aef_out, idx, ss] = add_events(ax, pot, xi, xf, aef_hc, ssl_hc, dsw, ari_range, aef_in, idx)
                if self.config.pros_use_aep == 1; aef_hc = aep2aef(aef_hc); end

                pot = drop_z0(pot); % Replicates Fitted By PST/JPM
                if size(pot, 2) > 1
                    rep_indx = repmat(1:size(pot, 2), size(pot, 1), 1);
                    mrk_sz = 2;
                    tgt_rep = 222;
                else
                    rep_indx = ones(size(pot, 1), 1);
                    mrk_sz = 12;
                    tgt_rep = 1;
                end

                dcols = size(pot, 2);
                dsw_in = repmat(dsw./dcols, 1, dcols);

                if isempty(aef_in)
                    [aef_out, idx] = self.get_aef(pot(:), aef_hc, ssl_hc, dsw_in(:), rep_indx(:));
                else
                    aef_out = aef_in;
                end



                aef_indx = aef_out.aef >= min(1./ari_range) & aef_out.aef <= max(1./ari_range);
                cvec = aef_out.aef(aef_indx);
                y = aef_out.response(aef_indx);
                rep_cols = aef_out.resp_indx(aef_indx);


                npoints = sum(aef_indx);

                dx_adj = ((xf - xi) * 0.35); %/ 2;
                x = linspace(xi + dx_adj, xf, npoints);
                p_indx = randperm(length(x));

                ss = scatter(ax, x, y(p_indx), mrk_sz, 1./cvec(p_indx), 'filled', ...
                    'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none');
            end

            function bounds = calculate_bounds(data, field_name, ax_geom)
                y_mn = min(data, [], 'all', 'omitnan');
                y_mx = max(data, [], 'all', 'omitnan');

                switch field_name
                    case {'SWL','R2p_SWL'}
                        bounds = ax_geom.YLim;
                    case {'q_wave_ot','q'}
                        bounds = [10^floor(log10(y_mn)), 10^ceil(log10(y_mx))];
                    otherwise
                        % Standard data-driven bounds for independent zooming
                        bounds = [y_mn * 0.9, y_mx * 1.1];
                end
            end

            function [hc, c_line] = generate_custom_colorbar(x, cm, ax)
                x = x(:); x_min = min(x); x_max = max(x);
                colormap(ax, cm);
                if x_max > x_min; ax.CLim = [x_min, x_max]; end
                cmap = colormap(ax);
                hc = colorbar(ax); hc.Ticks = x;

                if x_max > x_min
                    if strcmp(ax.ColorScale, 'log')
                        c_scale = logspace(log10(x_min), log10(x_max), size(cmap, 1));
                    else
                        c_scale = linspace(x_min, x_max, size(cmap, 1));
                    end
                    c_line = max(min(interp1(c_scale, cmap, x, 'linear', 'extrap'), 1), 0);
                else
                    c_line = repmat(cmap(1, :), length(x), 1);
                end
            end

            function cmap = build_custom_cmap()
                anchors = [1, 5, 10, 20, 50, 100, 500];
                c_anchors = [0 0 0.6; 0.6 0 0.8; 0 0.8 1; 0 0.8 0; 1 1 0; 1 0.5 0; 0.7 0 0];
                log_query = linspace(min(log10(anchors)), max(log10(anchors)), 256);
                cmap = max(min(interp1(log10(anchors), c_anchors, log_query, 'pchip'), 1), 0);
            end

            function rgb_matrix = extract_rgb_from_cdata(ax, cData)
                cmap = colormap(ax); c_limits = ax.CLim; c_vals = cData(:);
                if strcmp(ax.ColorScale, 'log')
                    c_vals(c_vals <= 0) = realmin; c_limits(c_limits <= 0) = realmin;
                    c_vals = log10(c_vals); c_limits = log10(c_limits);
                end
                c_vals = max(min(c_vals, c_limits(2)), c_limits(1));
                ref_scale = linspace(c_limits(1), c_limits(2), size(cmap, 1));
                rgb_matrix = max(min(interp1(ref_scale, cmap, c_vals, 'linear'), 1), 0);
            end

            function add_floating_y_axis(ax, xo, major_stride, y_lbl)
                % ADD_FLOATING_Y_AXIS Creates an internal depth ruler.

                % 1. Get current limits to bound the ruler
                ylims = ax.YLim;
                xlims = ax.XLim;

                % 2. Calculate dynamic tick widths (1.5% and 0.7% of X-span)
                x_span = xlims(2) - xlims(1);
                dx_major = x_span * 0.015;
                dx_minor = x_span * 0.007;

                % 3. Draw the vertical spine
                plot(ax, [xo, xo], ylims, 'k-', 'LineWidth', 1, 'Tag','float_axes');

                % 4. Generate ticks
                minor_stride = major_stride / 5; % Standard 5 subdivisions

                min_y = ceil(ylims(1) / minor_stride) * minor_stride;
                max_y = floor(ylims(2) / minor_stride) * minor_stride;
                all_ticks = min_y : minor_stride : max_y;

                for el = all_ticks
                    % Check if this is a major tick (using tolerance for floating-point math)
                    is_major = abs(round(el/major_stride) - el/major_stride) < 1e-4;

                    if is_major
                        % Draw longer, thicker Major Tick
                        plot(ax, [xo - dx_major, xo + dx_major], [el, el], 'k-', ...
                            'LineWidth', 1, 'Tag','float_axes');

                        % Add numeric label to the right of the major tick
                        text(ax, xo + dx_major * 1.5, el, sprintf('%.1f', el), ...
                            'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', ...
                            'FontSize',  self.base_fnt-2, 'Color', 'k', 'Tag','float_axes');
                    else
                        % Draw shorter, thinner Minor Tick
                        plot(ax, [xo - dx_minor, xo + dx_minor], [el, el], 'k-', ...
                            'LineWidth', 0.5, 'Tag','float_axes');
                    end
                end

                % 5. Add the Parallel Label (Rotated and Centered)
                y_center = mean(ylims); % Find the exact vertical middle
                x_offset = dx_major * 3; % Shift it to the left of the major ticks

                text(ax, xo - x_offset, y_center, y_lbl, ...
                    'Rotation', 90, ...                           % <--- Rotates the text parallel to the line
                    'HorizontalAlignment', 'center', ...          % <--- Centers it vertically along the line
                    'VerticalAlignment', 'bottom', ...
                    'FontWeight', 'bold', 'FontSize', self.base_fnt, 'Color', 'k', 'Tag','float_axes');
            end
        end
    end

    %% PRIVATE METHODS
    methods (Access=private)
        % -----------------------------------------
        % Run Sample: The POT The Hazard Curve Was Built From, All Replicates Pooled Except z = 0 (n_dropped: Events PST/JPM Did Not Fit)
        function p = add_run_sample(self, ax, pot, storm_type, n_dropped)
            pot = drop_z0(pot);
            n_cols = size(pot, 2);
            switch storm_type
                case 'XC'
                    [aef, resp] = self.empirical_hazard(pot, [], self.config.Nyrs_XC*n_cols);
                case 'TC'
                    [aef, resp] = self.empirical_hazard(pot, repmat(self.dsw.TC_Freq(:)./n_cols, 1, n_cols), []);
            end
            if n_dropped > 0
                legend_str = sprintf('Run sample (n=%d, %d not fitted)', numel(resp), n_dropped);
            else
                legend_str = sprintf('Run sample (n=%d)', numel(resp));
            end
            p = plot(ax, aef, resp, 'o', 'MarkerSize', 5,...
                'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'g', 'DisplayName', legend_str);
        end
        % -----------------------------------------
        % Storm Values: One Value Per Storm, The z = 0 Replicate Of The POT (Forcing Curves: Their Single Column), Placed On The Best Estimate Curve
        function p = add_storm_values(self, ax, pot, hc_aef, hc_resp)
            vals = pot(:, replicate_z0_col(size(pot, 2)));
            vals = vals(isfinite(vals) & vals > 0);
            [aef_out, ~] = self.get_aef(vals(:), hc_aef, hc_resp, [], []);
            % get_aef Clamps To The Curve Ends: Drop Values Outside The Curve's Response Range Instead
            on_curve = isfinite(hc_resp) & isfinite(log(hc_aef));
            inside = aef_out.response >= min(hc_resp(on_curve)) & aef_out.response <= max(hc_resp(on_curve)) &...
                isfinite(aef_out.aef);
            p = plot(ax, aef_out.aef(inside), aef_out.response(inside), 'o', 'MarkerSize', 5,...
                'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'g',...
                'DisplayName', sprintf('CHESS: DET (n=%d, %d outside curve)', sum(inside), sum(~inside)));
        end
        % -----------------------------------------
        % Empirical Hazard Of A POT Sample: Finite Positive Values, Descending (PST Weibull Positions Or JPM Cumulative Masses)
        function [aef, resp] = empirical_hazard(self, pot, dsw, nyrs)
            keep = isfinite(pot) & pot > 0;
            [resp, idx] = sort(pot(keep), 'descend');
            if isempty(dsw)
                n = numel(resp);
                aef = (1:n)'./(n + 1).*n./nyrs;
            else
                w = dsw(keep);
                aef = cumsum(w(idx));
            end
            if self.config.pros_use_aep == 1
                aef = aef2aep(aef);
            end
        end
        % -----------------------------------------
        function fb_data = call_pros_fb(self, ds_names)
            % Determine Subfolder Name
            switch ds_names.data_type
                case 'Peaks'
                    wName = 'FB1';
                case 'Timeseries'
                    wName = 'FB3';
            end
            % Build Out Path (Workflow Folder Of The Alternative, chess_paths.m)
            paths = chess_paths(self.config);
            outPath = fullfile(paths.wf_dir, wName);
            % Pull Out response Data
            resp_data = self.Resp.(ds_names.data_type).(ds_names.match_type);
            %
            resp_names = fieldnames(resp_data);
            % Remove Non-Active Storm Types
            resp_data = rmfield(resp_data, resp_names(~strcmp(ds_names.storm_type, resp_names)));
            % Only Keep Forcing HC
            v_indx = ~ismember({resp_data.(ds_names.storm_type).var}', pros_forcing_curves());
            resp_data.(ds_names.storm_type)(v_indx) = [];
            % Run CHESS PROS-FB
            fb_data = chess_pros_frequency_base(self.config, self.structure, resp_data, outPath, 4);
            fb_data = fb_data.(ds_names.storm_type);
        end
        % -----------------------------------------
    end
end

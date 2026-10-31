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

    %% STORM EVENT VIEWER / RESPONSE TABLE (WORKFLOWS 1 AND 4)
    % Forcing: the saved, already adjusted project_forcing (cells per storm [nSteps x replicates]; storm_id, time:
    % chess_pros_formater.m). Workflow 1 draws one replicate column (z selector) and recomputes its responses with
    % compute_structure_response on that column only (Resp holds hazard curves, not per-step responses). Workflow 4 draws
    % the z = 0 column and, instead of responses, the hazard curve values at the chosen AEF/AEP and CLs (overlay lines).
    methods (Access=public)
        function ch = event_choices(self, ds_query)
            % Choices: Storm IDs Of The Saved Forcing, Timeseries Flag, Peaks-View Toggle (Workflow 1), z Values (1) / AEF-CL List (4)
            pf = self.event_forcing(ds_query);
            ch.storm_ids = pf.storm_id(:);
            ch.is_ts = strcmp(ds_query.data_type, 'Timeseries');
            ch.peaks_toggle = ch.is_ts && self.config.workflow == 1;
            ch.z_values = [];
            ch.aefs = [];
            ch.cls = [];
            switch self.config.workflow
                case 1
                    ch.z_values = self.replicate_z(ds_query.storm_type);
                case 4
                    data = aux_methods.pull_data(ds_query, self.Resp);
                    if ~isempty(data)
                        ch.aefs = data(1).x_table(:);
                        ch.cls = data(1).CL(:)';
                    end
            end
        end

        function sel = refine_selection(self, sel, choices)
            switch self.config.workflow
                case 1 % Replicate Column (Default: z = 0)
                    n = numel(choices.z_values);
                    if ~isnumeric(sel.z_col) || ~isscalar(sel.z_col) || sel.z_col < 1 || sel.z_col > n
                        sel.z_col = replicate_z0_col(n);
                    end
                    sel.z_col = round(sel.z_col);
                case 4 % AEF/AEP (Default: Closest To 0.01), CL ('All' Or One)
                    if ~isempty(choices.aefs) && (isempty(sel.aef) || ~ismember(sel.aef, choices.aefs))
                        [~, r] = min(abs(log(choices.aefs) - log(0.01)));
                        sel.aef = choices.aefs(r);
                    end
                    if ~ischar(sel.cl) && (isempty(sel.cl) || ~ismember(sel.cl, choices.cls))
                        sel.cl = 'All';
                    end
            end
        end

        function ctrl = event_controls(self, parent, row, sel, choices, emit)
            % Control Row: Storm ID (+ Peaks View, Workflow 1) | Workflow 1: z Slider Snapping To The Replicates |
            % Workflow 4: AEF/AEP And CL Dropdowns
            ctrl = uigridlayout(parent, [1 8], 'ColumnWidth', {'fit', 100, 'fit', 'fit', 110, 'fit', 130, '1x'}, ...
                'RowHeight', {'1x'}, 'Padding', [5 2 5 2]);
            ctrl.Layout.Row = row;
            if choices.is_ts
                put(uilabel(ctrl, 'Text', 'Storm ID:', 'HorizontalAlignment', 'right'), 1);
                put(uidropdown(ctrl, 'Items', string(choices.storm_ids), 'ItemsData', choices.storm_ids, 'Value', sel.storm_id, ...
                    'Enable', ~sel.peaks_view, 'ValueChangedFcn', @(src, ~) emit('storm_id', src.Value)), 2);
                if choices.peaks_toggle
                    put(uicheckbox(ctrl, 'Text', aux_methods.tern(sel.peaks_view, 'Swap to timeseries view', 'Swap to peaks view'), ...
                        'Value', sel.peaks_view, 'ValueChangedFcn', @(src, ~) emit('peaks_view', logical(src.Value))), 3);
                end
            else
                put(uilabel(ctrl, 'Text', 'All events (Peaks)'), 1);
            end
            switch self.config.workflow
                case 1
                    ctrl.ColumnWidth = {'fit', 100, 'fit', 'fit', '1x', 270};
                    z_text = @(col) sprintf('z = %.4f  (replicate %d of %d)', choices.z_values(col), col, numel(choices.z_values));
                    put(uilabel(ctrl, 'Text', 'z-score:', 'HorizontalAlignment', 'right'), 4);
                    value_label = uilabel(ctrl, 'Text', z_text(sel.z_col));
                    put(value_label, 6);
                    put(uislider(ctrl, 'Limits', [1 numel(choices.z_values)], 'Value', sel.z_col, 'MajorTicks', [], 'MinorTicks', [], ...
                        'ValueChangingFcn', @(~, evt) set(value_label, 'Text', z_text(round(evt.Value))), ...
                        'ValueChangedFcn', @(src, ~) emit('z_col', round(src.Value))), 5);
                case 4
                    if self.config.pros_use_aep == 1
                        aef_label = 'AEP:';
                    else
                        aef_label = 'AEF [1/yr]:';
                    end
                    put(uilabel(ctrl, 'Text', aef_label, 'HorizontalAlignment', 'right'), 4);
                    put(uidropdown(ctrl, 'Items', arrayfun(@(v) sprintf('%g', v), choices.aefs, 'un', false), 'ItemsData', choices.aefs, ...
                        'Value', sel.aef, 'ValueChangedFcn', @(src, ~) emit('aef', src.Value)), 5);
                    put(uilabel(ctrl, 'Text', 'CL:', 'HorizontalAlignment', 'right'), 6);
                    cl_items = [{'All'}, arrayfun(@(v) self.cl_name(v), choices.cls, 'un', false)];
                    put(uidropdown(ctrl, 'Items', cl_items, 'ItemsData', [{'All'}, num2cell(choices.cls)], 'Value', sel.cl, ...
                        'ValueChangedFcn', @(src, ~) emit('cl', src.Value)), 7);
            end

            function w = put(w, col)
                w.Layout.Column = col;
            end
        end

        function ser = event_series(self, ds_query, response_to_view, sel)
            % Storm Event Viewer Data: One Storm (Timeseries View) Or The Per-Storm Maxima (Peaks View / Peaks Data, Rc Minimum)
            % At The Selected Replicate. Workflow 4: No Response Line, Overlay Lines From The Hazard Curve Instead.
            d = self.event_data(ds_query, sel);
            ser.x = d.x;
            ser.x_kind = d.x_kind;
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
            ser.event_str = d.event_str;
            if self.config.workflow == 4
                [ser.overlay, aef_str] = self.event_overlay(ds_query, resp_name, sel);
                ser.event_str = [ser.event_str ' | ' aef_str];
            end
        end

        function [T, info] = event_table(self, ds_query, sel)
            % Response Table Rows: Same Data As The Viewer, All Forcing And Response Columns. Workflow 4 Adds The Hazard Curve
            % Values At The Chosen AEF/AEP (<response>_BE, <response>_CL<n>, Constant Down The Rows)
            d = self.event_data(ds_query, sel);
            if strcmp(d.mode, 'ts')
                T = table(d.time_table(:), 'VariableNames', {'Time'});
            else
                T = table(d.ids(:), d.time_table(:), 'VariableNames', {'StormID', 'Time'});
            end
            for f = fieldnames(d.cols)'
                T.(f{1}) = d.cols.(f{1})(:);
            end
            if self.config.workflow == 4
                data = aux_methods.pull_data(ds_query, self.Resp);
                [~, r] = min(abs(data(1).x_table(:) - sel.aef));
                cls = aux_methods.tern(ischar(sel.cl), data(1).CL, sel.cl);
                for v = 1:numel(data)
                    for cl = cls(:)'
                        j = find(data(v).CL == cl, 1);
                        tag = aux_methods.tern(cl == 50, 'BE', sprintf('CL%d', cl));
                        T.([data(v).var '_' tag]) = repmat(data(v).y_table(r, j), height(T), 1);
                    end
                end
            end
            info = struct('mode', d.mode, 'view_label', d.view_label, 'plot_title', d.plot_title, 'x_label', 'Storm Duration [hrs]');
        end
    end

    methods (Access=private)
        function pf = event_forcing(self, ds_query)
            % Saved Project Forcing Of The Queried Dataset (Storm IDs And Time Stamps Come With It)
            if strcmp(ds_query.storm_type, 'CC')
                error('pros_methods:noCC', 'PROS CC results are derived from TC and XC: pick TC or XC.');
            end
            if isempty(self.project_forcing)
                error('pros_methods:noForcing', 'The saved project forcing is not available for this run.');
            end
            pf = aux_methods.pull_data(ds_query, self.project_forcing);
            if ~isfield(pf, 'storm_id')
                error('pros_methods:noStormIds', 'The saved project forcing has no storm IDs. Re-run the case to rebuild its forcing.');
            end
        end

        function z = replicate_z(~, storm_type)
            % z-Scores Of The Replicate Columns (Sorted, z = 0 In The Middle: XC 21, TC 445)
            switch storm_type
                case 'XC'
                    z = readmatrix('discrete_norm_20.txt');
                case 'TC'
                    z = readmatrix('discrete_norm_444.txt');
            end
            z = z(:);
        end

        function name = cl_name(~, cl)
            name = aux_methods.tern(cl == 50, 'Best Estimate', sprintf('%g%%', cl));
        end

        function d = event_data(self, ds_query, sel)
            % Columns Of The Selected Storm (mode 'ts') Or One Row Per Storm (mode 'peaks') At The Selected Replicate Column
            % (Workflow 4: z = 0). cols: SWL, Hm0_offshore, Hm0_toe, Tp, h, Rc, Responses (Workflow 1)
            pf = self.event_forcing(ds_query);
            n_col = size(pf.SWL{1}, 2);
            if self.config.workflow == 1
                z_col = sel.z_col;
                z_val = self.replicate_z(ds_query.storm_type);
                z_str = sprintf('z = %.4f (replicate %d)', z_val(z_col), z_col);
            else
                z_col = replicate_z0_col(n_col);
                z_str = '';
            end
            is_ts = strcmp(ds_query.data_type, 'Timeseries') && ~sel.peaks_view;
            if is_ts
                rows = find(pf.storm_id == sel.storm_id, 1);
                if isempty(rows)
                    error('pros_methods:unknownStorm', 'Storm ID %g is not in this dataset.', sel.storm_id);
                end
            else
                rows = (1:numel(pf.storm_id))';
            end
            column = @(c) cellfun(@(v) v(:, z_col), c(rows), 'un', false);
            one.SWL = column(pf.SWL);
            one.Hm0_offshore = column(pf.Hm0_offshore);
            one.Hm0_toe = column(pf.Hm0_toe);
            one.Tp = column(pf.Tp);
            one.storm_duration = pf.storm_duration(rows);
            if isfield(pf, 'dt') % Timeseries Only
                one.dt = pf.dt(rows);
            end
            R = [];
            if self.config.workflow == 1 % Responses Of This Replicate Only (Forcing Is Already Adjusted)
                cfg = self.config;
                if ~strcmp(ds_query.data_type, 'Timeseries') % Q_vol Is Timeseries Only (As In The Run, call_project_response)
                    cfg.compute_q_vol = 0;
                end
                R = compute_structure_response(cfg, self.structure, one, load_empirical_coefficients(), 0);
            end
            toe = self.structure.toe_elevation;
            crest = self.structure.crest_elevation;
            st = ds_query.storm_type;
            if is_ts
                d.mode = 'ts';
                t = pf.time{rows}(:);
                d.x = datetime(t, 'ConvertFrom', 'datenum');
                d.x_kind = 'datetime';
                d.ids = sel.storm_id;
                d.time_table = (t - t(1))*24;
                d.cols.SWL = one.SWL{1}(:);
                d.cols.Hm0_offshore = one.Hm0_offshore{1}(:);
                d.cols.Hm0_toe = one.Hm0_toe{1}(:);
                d.cols.Tp = one.Tp{1}(:);
                d.cols.h = d.cols.SWL - toe;
                d.cols.Rc = crest - d.cols.SWL;
                d.event_str = num2str(sel.storm_id);
                d.view_label = sprintf('%s Timeseries (hourly, 1 storm)', st);
                reduce = @(v) v{1}(:);
            else
                d.mode = 'peaks';
                d.ids = pf.storm_id(rows);
                d.x = (1:numel(rows))';
                d.x_kind = 'event';
                [swl_max, ix] = cellfun(@(v) max(v, [], 1), one.SWL);
                d.time_table = datetime(cellfun(@(t, i) t(i), pf.time(rows), num2cell(ix)), 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm');
                reduce = @(v) cellfun(@(x) max(x, [], 1), v);
                d.cols.SWL = swl_max;
                d.cols.Hm0_offshore = reduce(one.Hm0_offshore);
                d.cols.Hm0_toe = reduce(one.Hm0_toe);
                d.cols.Tp = reduce(one.Tp);
                d.cols.h = swl_max - toe;
                d.cols.Rc = crest - swl_max;
                if strcmp(ds_query.data_type, 'Timeseries')
                    d.event_str = 'All (Timeseries peaks)';
                    d.view_label = sprintf('%s Timeseries (storm maxima)', st);
                else
                    d.event_str = 'All (Peaks)';
                    d.view_label = sprintf('%s Peaks (%s)', st, ds_query.match_type);
                end
            end
            if ~isempty(R)
                for f = fieldnames(R)'
                    v = R.(f{1});
                    if iscell(v) && all(cellfun(@(x) isnumeric(x) && size(x, 2) == 1, v))
                        d.cols.(f{1}) = reduce(v);
                    end
                end
            end
            if ~isempty(z_str)
                d.event_str = [d.event_str ' | ' z_str];
                d.view_label = [d.view_label ' | ' z_str];
            end
            d.plot_title = sprintf('Storm %g', sel.storm_id);
        end

        function [overlay, aef_str] = event_overlay(self, ds_query, resp_name, sel)
            % Workflow 4: Hazard Curve Values Of The Response At The Chosen AEF/AEP, One Horizontal Line Per Chosen CL
            data = aux_methods.pull_data(ds_query, self.Resp);
            aef_str = sprintf('%s %g', aux_methods.tern(self.config.pros_use_aep == 1, 'AEP', 'AEF'), sel.aef);
            overlay = struct('y', {}, 'label', {}, 'color', {});
            hc = data(strcmp({data.var}, resp_name));
            if isempty(hc)
                return
            end
            [~, r] = min(abs(hc.x_table(:) - sel.aef));
            palette = [0 0 0; 0 0 1; 1 0 0; 1 0 1; 0 1 1];
            cols = 1:numel(hc.CL);
            if ~ischar(sel.cl)
                cols = find(hc.CL == sel.cl);
            end
            for j = cols
                y = hc.y_table(r, j);
                if ~isfinite(y)
                    continue
                end
                overlay(end+1) = struct('y', y, 'label', sprintf('%s: %.4g', self.cl_name(hc.CL(j)), y), ...
                    'color', palette(mod(j - 1, size(palette, 1)) + 1, :)); %#ok<AGROW>
            end
        end
    end
end

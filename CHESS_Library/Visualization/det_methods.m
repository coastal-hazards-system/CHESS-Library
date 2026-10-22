classdef det_methods < CHESSPlotsBase
    % DET_METHODS CHESS: Deterministic workflow plots (workflow = 2).
    % Instantiated via CHESSPlots(...). Resp layout (chess_det.m):
    %   Resp.(Peaks|Timeseries).(Default|WLP|WHP).(XC|TC) -> full histories + .Max (one value per storm)
    % Every field (forcing: SWL, Hm0, Hm0_DL, Tp, h, Rc; and responses) can be used on any axis.
    % Labels, units and log scaling come from response_library_headers.m.

    properties (Constant, Access=private)
        % Plotted Before The Responses, In This Order
        forcing_fields = {'SWL', 'Hm0', 'Hm0_DL', 'Tp', 'h', 'Rc'}
        % Datum-Referenced Elevations (Left yyaxis On Hydrographs)
        elevation_fields = {'SWL', 'R2p_SWL', 'DamDepthElev'}
    end

    methods (Access=public)
        function self = det_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
            self = self@CHESSPlotsBase(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
        end

        function fields = available_fields(self, ds_query)
            % Fields That Can Be Plotted For The Queried Dataset (Forcing First, Then Responses)
            mx = self.det_data(ds_query).Max;
            names = setdiff(fieldnames(mx), {'storm_id', 'time'}, 'stable');
            fields = [self.forcing_fields(ismember(self.forcing_fields, names)), ...
                setdiff(names, self.forcing_fields, 'stable')'];
            fields = fields(:)';
        end

        % Method: Response vs Forcing (X, Y, Color)
        function ax = response_vs_forcing_plot(self, ax, ds_query, x_field, y_field, c_field)
            % Peaks: One Point Per Storm. Timeseries: Storm Maxima (Non-Concurrent; Rc Uses The Minimum).
            T = self.max_table(ds_query);
            self.check_fields(T, {x_field, y_field, c_field});
            [x_lbl, ~, x_log] = self.field_info(x_field);
            [y_lbl, ~, y_log] = self.field_info(y_field);
            c_lbl = self.field_info(c_field);
            ax = aux_methods.initiate_axes(ax, x_lbl, y_lbl, self.title_str(ds_query), self.base_fnt);
            ok = ~isnan(T.(x_field)) & ~isnan(T.(y_field)) & ~isnan(T.(c_field));
            if ~any(ok)
                aux_methods.display_no_data(ax, self.base_fnt);
                return
            end
            scatter(ax, T.(x_field)(ok), T.(y_field)(ok), 40, T.(c_field)(ok), 'filled', 'MarkerEdgeColor', [.3 .3 .3]);
            colormap(ax, parula);
            cb = colorbar(ax);
            cb.Label.String = c_lbl; cb.Label.Interpreter = 'latex'; cb.Label.FontSize = self.base_fnt;
            ax.XScale = aux_methods.tern(x_log == 1, 'log', 'linear');
            ax.YScale = aux_methods.tern(y_log == 1, 'log', 'linear');
            aux_methods.pad_limits(ax, 'X', T.(x_field)(ok));
            aux_methods.pad_limits(ax, 'Y', T.(y_field)(ok));
            text(ax, 0.02, 0.97, sprintf('%d of %d storms', sum(ok), height(T)), 'Units', 'normalized', ...
                'VerticalAlignment', 'top', 'FontSize', self.base_fnt - 2);
        end

        % Method: Peaks Value vs Timeseries Computed Peak
        function ax = peaks_vs_timeseries_plot(self, ax, ds_query, field)
            % Needs Both Datasets. Peaks Uses ds_query.match_type; Storms Matched By ID; Dashed 1:1 Line.
            q_pk = ds_query; q_pk.data_type = 'Peaks';
            q_ts = ds_query; q_ts.data_type = 'Timeseries';
            if ~self.has_data(q_pk) || ~self.has_data(q_ts)
                error('det_methods:missingDataset', 'Peaks vs Timeseries needs both Peaks and Timeseries outputs.');
            end
            TP = self.max_table(q_pk); TS = self.max_table(q_ts);
            self.check_fields(TP, {field}); self.check_fields(TS, {field});
            [~, ia, ib] = intersect(TP.StormID, TS.StormID);
            x = TP.(field)(ia); y = TS.(field)(ib);
            ok = ~isnan(x) & ~isnan(y);
            [lbl, ~, is_log] = self.field_info(field);
            ax = aux_methods.initiate_axes(ax, ['Peaks: ' lbl], ['Timeseries Peak: ' lbl], ...
                strrep(sprintf('%s Peaks (%s) vs Timeseries', ds_query.storm_type, ds_query.match_type), '_', ' '), self.base_fnt);
            if ~any(ok)
                aux_methods.display_no_data(ax, self.base_fnt);
                return
            end
            scatter(ax, x(ok), y(ok), 36, [0 0.447 0.741], 'filled', 'MarkerEdgeColor', [.2 .2 .2]);
            lim = [min([x(ok); y(ok)]) max([x(ok); y(ok)])];
            plot(ax, lim, lim, '--k', 'LineWidth', 1);
            if is_log == 1, set(ax, 'XScale', 'log', 'YScale', 'log'); end
            aux_methods.pad_limits(ax, 'X', [x(ok); y(ok)]);
            aux_methods.pad_limits(ax, 'Y', [x(ok); y(ok)]);
            axis(ax, 'square');
            text(ax, 0.03, 0.97, sprintf('%d matched storms', sum(ok)), 'Units', 'normalized', ...
                'VerticalAlignment', 'top', 'FontSize', self.base_fnt - 2);
        end

        % Method: Response Table Pop-Out (Axes On Top, Table Below)
        function fig = response_table(self, ds_query, storm_id)
            % Peaks: One Row Per Storm; Select 2 Columns (1st Click = X, 2nd = Y) For A Scatter.
            % Timeseries: Pick A Storm ID; Its Hourly Rows Are Shown And Selected Columns Plot As Hydrographs
            %   (Elevations On The Left yyaxis, Everything Else On The Right; Max 2 Unit Groups).
            if nargin < 3, storm_id = []; end
            is_ts = strcmp(ds_query.data_type, 'Timeseries');
            d = self.det_data(ds_query);
            lbl = aux_methods.tern(is_ts, sprintf('%s Timeseries (hourly, 1 storm)', ds_query.storm_type), self.title_str(ds_query));
            fig = uifigure('Name', ['Response Table | ' lbl], 'Position', [60 60 1250 820]);
            gl = uigridlayout(fig, [3 1], 'RowHeight', {30, 440, '1x'});
            top = uigridlayout(gl, [1 3], 'ColumnWidth', {'1x', 80, 120}, 'Padding', 0);
            uilabel(top, 'Text', ['<b>Response Table</b> | ' lbl], 'Interpreter', 'html');
            axp = uipanel(gl, 'BorderType', 'none');
            ax = uiaxes(axp, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            ut = uitable(gl, 'RowName', {}, 'FontSize', self.base_fnt - 1, 'SelectionType', 'column', 'Multiselect', 'on');
            st.order = {}; st.T = table(); st.id = [];
            if is_ts
                uilabel(top, 'Text', 'Storm ID:', 'HorizontalAlignment', 'right');
                dd = uidropdown(top, 'Items', string(d.storm_id), 'ItemsData', d.storm_id, ...
                    'ValueChangedFcn', @(s, ~) set_storm(s.Value));
                if isempty(storm_id), storm_id = d.storm_id(1); end
                set_storm(storm_id);
            else
                uilabel(top, 'Text', ''); uilabel(top, 'Text', '');
                set_table(self.max_table(ds_query));
            end
            ut.CellSelectionCallback = @on_select;
            % Programmatic Access (Scripts / Tests)
            fig.UserData = struct('select', @select, 'set_storm', @set_storm, 'axes', ax, 'table', ut);

            function set_table(T)
                st.T = T; st.order = {};
                vn = T.Properties.VariableNames;
                Tf = T;
                for k = 1:numel(vn)
                    if ~isfloat(Tf.(vn{k})), continue, end
                    [~, ~, is_log] = self.field_info(vn{k});
                    if is_log == 1 % Log-Scaled Fields (e.g. q): Scientific Notation So Small Values Do Not Show As 0
                        Tf.(vn{k}) = arrayfun(@(x) sprintf('%.2e', x), Tf.(vn{k}), 'un', false);
                    else
                        Tf.(vn{k}) = round(Tf.(vn{k}), 4);
                    end
                end
                ut.Data = Tf;
                ut.ColumnName = cellfun(@(v) self.column_name(v), vn, 'un', false);
                if isnumeric(T.Time), ut.ColumnName{strcmp(vn, 'Time')} = 'Time [hrs]'; end % Timeseries: Storm Hours
                ut.Selection = [];
                redraw();
            end
            function set_storm(id)
                if ~ismember(id, d.storm_id)
                    error('det_methods:unknownStorm', 'Storm ID %g is not in this dataset.', id);
                end
                st.id = id; dd.Value = id;
                set_table(self.storm_table(ds_query, id));
            end
            function on_select(~, evt)
                cols = unique(evt.Indices(:, 2))';
                names = st.T.Properties.VariableNames(cols);
                keep = st.order(ismember(st.order, names)); % Click Order Preserved
                st.order = [keep, setdiff(names, keep, 'stable')];
                redraw();
            end
            function select(names)
                st.order = names;
                ut.Selection = find(ismember(st.T.Properties.VariableNames, names));
                redraw();
            end
            function show_msg(lines_in)
                cla(ax, 'reset'); ax.XTick = []; ax.YTick = []; box(ax, 'on');
                text(ax, 0.5, 0.5, lines_in, 'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                    'FontSize', self.base_fnt, 'Color', [.35 .35 .35]);
            end
            function redraw()
                sel = st.order(~ismember(st.order, {'StormID', 'Time'}));
                if ~is_ts
                    if numel(sel) ~= 2
                        show_msg({'Select 2 table columns to plot', '1st click = X axis, 2nd click = Y axis'});
                        return
                    end
                    [xl, ~, xlog] = self.field_info(sel{1}); [yl, ~, ylog] = self.field_info(sel{2});
                    cla(ax, 'reset');
                    aux_methods.initiate_axes(ax, xl, yl, '', self.base_fnt);
                    ok = ~isnan(st.T.(sel{1})) & ~isnan(st.T.(sel{2}));
                    scatter(ax, st.T.(sel{1})(ok), st.T.(sel{2})(ok), 30, [0 0.447 0.741], 'filled', 'MarkerEdgeColor', [.2 .2 .2]);
                    ax.XScale = aux_methods.tern(xlog == 1, 'log', 'linear');
                    ax.YScale = aux_methods.tern(ylog == 1, 'log', 'linear');
                    aux_methods.pad_limits(ax, 'X', st.T.(sel{1})(ok));
                    aux_methods.pad_limits(ax, 'Y', st.T.(sel{2})(ok));
                else
                    if isempty(sel)
                        show_msg({'Select one or more table columns', 'to plot their hydrographs'});
                        return
                    end
                    % Group By (Datum Elevation?, Unit): Max 2 Groups -> Left / Right yyaxis
                    key = cellfun(@(v) sprintf('%d|%s', ismember(v, self.elevation_fields), self.field_unit(v)), sel, 'un', false);
                    [grp, ~, gi] = unique(key, 'stable');
                    if numel(grp) > 2
                        show_msg({'Selected columns span more than 2 unit groups', 'Deselect columns until 2 or fewer remain'});
                        return
                    end
                    cla(ax, 'reset'); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
                    set(ax, 'FontSize', self.base_fnt - 2, 'FontWeight', 'bold');
                    cols = lines(numel(sel)); side = {'left', 'right'};
                    for g = 1:numel(grp)
                        yyaxis(ax, side{g});
                        members = find(gi' == g); labs = cell(1, numel(members)); any_log = false;
                        for m = 1:numel(members)
                            k = members(m);
                            [labs{m}, ~, lg] = self.field_info(sel{k}); any_log = any_log || lg == 1;
                            plot(ax, st.T.Time, st.T.(sel{k}), '-', 'Color', cols(k, :), 'LineWidth', 1.4, 'DisplayName', labs{m});
                        end
                        ylabel(ax, aux_methods.latex_escape(strjoin(labs, ', ')), 'Interpreter', 'latex', 'FontSize', self.base_fnt, 'FontWeight', 'bold');
                        ax.YColor = [.15 .15 .15];
                        ax.YScale = aux_methods.tern(any_log, 'log', 'linear');
                        vals = cellfun(@(v) st.T.(v), sel(members), 'un', false);
                        aux_methods.pad_limits(ax, 'Y', vertcat(vals{:}));
                    end
                    % Single Unit Group: Hide The Empty Right Axis
                    ax.YAxis(2).Visible = aux_methods.tern(numel(grp) == 1, 'off', 'on');
                    legend(ax, 'Interpreter', 'latex', 'Location', 'northoutside', 'Orientation', 'horizontal', 'FontSize', self.base_fnt - 1);
                    xlabel(ax, 'Storm Duration [hrs]', 'Interpreter', 'latex', 'FontSize', self.base_fnt, 'FontWeight', 'bold');
                    title(ax, sprintf('Storm %g', st.id), 'Interpreter', 'latex', 'FontSize', self.base_fnt + 2, 'FontWeight', 'bold');
                    ax.XLim = [0 max(st.T.Time(end), 1)];
                end
            end
        end
    end

    methods (Access=private)
        function d = det_data(self, ds_query)
            if ~self.has_data(ds_query)
                error('det_methods:noData', 'No deterministic outputs for %s %s %s.', ...
                    ds_query.storm_type, ds_query.data_type, ds_query.match_type);
            end
            d = aux_methods.pull_data(ds_query, self.Resp);
        end

        function tf = has_data(self, ds_query)
            tf = false;
            try
                d = aux_methods.pull_data(ds_query, self.Resp);
                tf = isstruct(d) && isfield(d, 'Max');
            catch
            end
        end

        function T = max_table(self, ds_query)
            % One Row Per Storm (Peaks: The Record; Timeseries: Storm Maxima, Rc Minimum)
            mx = self.det_data(ds_query).Max;
            T = table(mx.storm_id(:), datetime(mx.time(:), 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm'), ...
                'VariableNames', {'StormID', 'Time'});
            for f = self.available_fields(ds_query)
                T.(f{1}) = mx.(f{1})(:);
            end
        end

        function T = storm_table(self, ds_query, id)
            % One Row Per Time Step Of One Storm; Time = Elapsed Storm Hours (Hourly Records)
            d = self.det_data(ds_query);
            k = find(d.storm_id == id, 1);
            n = numel(d.time{k});
            T = table((0:n - 1)', 'VariableNames', {'Time'});
            for f = self.available_fields(ds_query)
                v = d.(f{1});
                if iscell(v) && numel(v{k}) == n
                    T.(f{1}) = double(v{k}(:));
                end
            end
        end

        function [lbl, unit, is_log] = field_info(self, field)
            [~, ~, ~, unit, ~, lbl, is_log] = response_library_headers(self.config, field);
            if strcmp(lbl, 'nan'), lbl = strrep(field, '_', ' '); unit = ''; end
        end

        function unit = field_unit(self, field)
            [~, unit] = self.field_info(field);
        end

        function name = column_name(self, field)
            if any(strcmp(field, {'StormID', 'Time'})), name = field; return, end
            unit = strrep(strrep(self.field_unit(field), '$', ''), '^3', char(179));
            name = aux_methods.tern(isempty(unit), field, [field ' [' unit ']']);
        end

        function check_fields(~, T, fields)
            missing = fields(~ismember(fields, T.Properties.VariableNames));
            if ~isempty(missing)
                error('det_methods:unknownField', 'Field(s) %s not available. Available: %s', ...
                    strjoin(missing, ', '), strjoin(setdiff(T.Properties.VariableNames, {'StormID', 'Time'}, 'stable'), ', '));
            end
        end

        function str = title_str(~, ds_query)
            if strcmp(ds_query.data_type, 'Timeseries')
                str = sprintf('%s Timeseries (storm maxima)', ds_query.storm_type);
            else
                str = sprintf('%s Peaks (%s)', ds_query.storm_type, ds_query.match_type);
            end
        end
    end
end

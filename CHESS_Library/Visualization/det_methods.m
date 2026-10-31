classdef det_methods < CHESSPlotsBase
    % DET_METHODS CHESS: Deterministic workflow plots (workflow = 2).
    % Instantiated via CHESSPlots(...). Resp layout (chess_det.m):
    %   Resp.(Peaks|Timeseries).(Default|WLP|WHP).(XC|TC) -> storm_id, h, Rc, response histories + .Max (one value per storm,
    %   forcing maxima included). Forcing histories (time, SWL, Hm0_offshore, Hm0_toe, Tp) come from project_forcing (same
    %   dataset, same row order), needed by the Timeseries response table only.
    % Every field (forcing: SWL, Hm0_offshore, Hm0_toe, Tp, h, Rc; and responses) can be used on any axis.
    % Labels, units and log scaling come from response_library_headers.m.

    properties (Constant, Access=private)
        % Plotted Before The Responses, In This Order
        forcing_fields = {'SWL', 'Hm0_offshore', 'Hm0_toe', 'Tp', 'h', 'Rc'}
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
            [c_lbl, ~, c_log] = self.field_info(c_field);
            ax = aux_methods.initiate_axes(ax, x_lbl, y_lbl, self.title_str(ds_query), self.base_fnt);
            valid = ~isnan(T.(x_field)) & ~isnan(T.(y_field)) & ~isnan(T.(c_field));
            % Log-Scaled Fields (e.g. q): Non-Positive Values Cannot Be Drawn; Still Counted As Valid, Reported As Hidden
            flds = {x_field, y_field, c_field};
            f_log = unique(flds([x_log y_log c_log] == 1), 'stable');
            ok = valid;
            for k = 1:numel(f_log), ok = ok & T.(f_log{k}) > 0; end
            f_hid = f_log(cellfun(@(f) any(valid & T.(f) <= 0), f_log));
            cnt = sprintf('%d of %d storms', sum(valid), height(T));
            if any(valid & ~ok)
                cnt = sprintf('%s (%d hidden, %s %s 0)', cnt, sum(valid & ~ok), strjoin(f_hid, ', '), char(8804));
            end
            if ~any(ok)
                aux_methods.display_no_data(ax, self.base_fnt);
                return
            end
            scatter(ax, T.(x_field)(ok), T.(y_field)(ok), 40, T.(c_field)(ok), 'filled', 'MarkerEdgeColor', [.3 .3 .3]);
            colormap(ax, parula);
            ax.ColorScale = aux_methods.tern(c_log == 1, 'log', 'linear');
            colorbar(ax);
            % Color Field Named In A Subtitle, Not The Colorbar Label: UIAxes Layout Lets Labels Longer Than The Bar Spill Out
            subtitle(ax, ['Color: ' aux_methods.latex_escape(c_lbl)], 'Interpreter', 'latex', 'FontSize', self.base_fnt);
            ax.XScale = aux_methods.tern(x_log == 1, 'log', 'linear');
            ax.YScale = aux_methods.tern(y_log == 1, 'log', 'linear');
            aux_methods.pad_limits(ax, 'X', T.(x_field)(ok));
            aux_methods.pad_limits(ax, 'Y', T.(y_field)(ok));
            text(ax, 0.02, 0.97, cnt, 'Units', 'normalized', 'Interpreter', 'none', ...
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

        function ch = event_choices(self, ds_query)
            % Storm Event Viewer / Response Table Choices: Storm IDs Of The Saved Results, Timeseries Flag
            ch.storm_ids = self.det_data(ds_query).storm_id(:);
            ch.is_ts = strcmp(ds_query.data_type, 'Timeseries');
            ch.peaks_toggle = ch.is_ts;
        end

        function [T, info] = event_table(self, ds_query, sel)
            % Response Table Rows (DET): The Selected Storm's Hourly Rows (Timeseries View), Else One Row Per Storm (Max).
            % info: mode ('ts'|'peaks'), view_label, plot_title, x_label
            if strcmp(ds_query.data_type, 'Timeseries') && ~sel.peaks_view
                T = self.storm_table(ds_query, sel.storm_id);
                info.mode = 'ts';
                info.view_label = sprintf('%s Timeseries (hourly, 1 storm)', ds_query.storm_type);
            else
                T = self.max_table(ds_query);
                info.mode = 'peaks';
                info.view_label = self.title_str(ds_query);
            end
            info.plot_title = sprintf('Storm %g', sel.storm_id);
            info.x_label = 'Storm Duration [hrs]';
        end

        function ser = event_series(self, ds_query, response_to_view, sel)
            % Storm Event Viewer Data (DET): Straight From The Saved Results, Nothing Recomputed.
            %   Timeseries View: One Storm's Histories (project_forcing + Resp, Matched By Storm ID).
            %   Peaks View / Peaks Data: The Saved Max Struct, One Value Per Storm (Rc Is The Minimum).
            % ser: x, x_kind ('datetime'|'event'), storm_ids, swl, hm0_off, hm0_toe, h, hb ([] w/o berm), rc, resp, event_str
            d = self.det_data(ds_query);
            resp_name = char(response_to_view);
            if strcmp(ds_query.data_type, 'Timeseries') && ~sel.peaks_view
                pf = aux_methods.pull_data(ds_query, self.project_forcing);
                kf = find(pf.storm_id == sel.storm_id, 1);
                kr = find(d.storm_id == sel.storm_id, 1);
                if isempty(kf) || isempty(kr)
                    error('det_methods:unknownStorm', 'Storm ID %g is not in this dataset.', sel.storm_id);
                end
                ser.x = datetime(pf.time{kf}(:), 'ConvertFrom', 'datenum');
                ser.x_kind = 'datetime';
                ser.storm_ids = sel.storm_id;
                ser.swl = pf.SWL{kf}(:);
                ser.hm0_off = pf.Hm0_offshore{kf}(:);
                ser.hm0_toe = pf.Hm0_toe{kf}(:);
                ser.h = d.h{kr}(:);
                ser.rc = d.Rc{kr}(:);
                ser.resp = [];
                if isfield(d, resp_name)
                    ser.resp = d.(resp_name){kr}(:);
                end
                ser.event_str = num2str(sel.storm_id);
            else
                mx = d.Max;
                ser.x = (1:numel(mx.storm_id))';
                ser.x_kind = 'event';
                ser.storm_ids = mx.storm_id(:);
                ser.swl = mx.SWL(:);
                ser.hm0_off = mx.Hm0_offshore(:);
                ser.hm0_toe = mx.Hm0_toe(:);
                ser.h = mx.h(:);
                ser.rc = mx.Rc(:);
                ser.resp = [];
                if isfield(mx, resp_name)
                    ser.resp = mx.(resp_name)(:);
                end
                ser.event_str = aux_methods.tern(strcmp(ds_query.data_type, 'Timeseries'), 'All (Timeseries peaks)', 'All (Peaks)');
            end
            ser.hb = [];
            if self.config.add_toe_berm == 1
                ser.hb = ser.swl - self.structure.berm_crest_elevation;
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
            % One Row Per Time Step Of One Storm; Time = Elapsed Storm Hours (Hourly Records). Forcing From project_forcing
            % (Not Copied Into Resp, chess_det.m), Same Row k
            d = self.det_data(ds_query);
            pf = aux_methods.pull_data(ds_query, self.project_forcing);
            k = find(d.storm_id == id, 1);
            n = numel(pf.time{k});
            T = table((0:n - 1)', 'VariableNames', {'Time'});
            for f = self.available_fields(ds_query)
                if isfield(d, f{1})
                    v = d.(f{1});
                else
                    v = pf.(f{1});
                end
                if iscell(v) && numel(v{k}) == n
                    T.(f{1}) = double(v{k}(:));
                end
            end
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

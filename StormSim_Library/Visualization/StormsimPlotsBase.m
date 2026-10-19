classdef StormsimPlotsBase
    % STORMSIMPLOTSBASE Base class for StormSim plotting.
    % Holds shared data and input-screening methods available to all workflows.
    % Do not instantiate directly — use StormsimPlots(...) instead.

    properties
        base_fnt
        config
        Resp
        storm
        project_forcing
        dsw
        structure
        unitLib
    end

    methods (Access=public)
        function self = StormsimPlotsBase(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
            self.base_fnt        = base_fnt;
            self.Resp            = Resp;
            self.storm           = storm;
            self.project_forcing = project_forcing;
            self.dsw             = dsw;
            self.config          = config;
            self.structure       = structure;
            self.unitLib         = aux_methods.build_unit_library(unit_system);
        end
    end

    %% INPUT SCREENING METHODS
    methods (Access=public)
        function [ax, Geo] = pse_transect_plot(self, ax, ~)
            % Third Input (Former datum) Is Kept For Call Compatibility And Ignored:
            % Elevations Are Plotted Signed, So No Tick Relabeling Is Needed.
            warning('off');
            pse_geo     = self.structure;
            % Horizontal Space Before The First Toe And After The Leeside Toe
            x_shift     = 8;
            % Sand Thickness & Space Above Crest As Fractions Of Structure Height
            sand_ratio  = 0.2;
            top_ratio   = 0.1;
            y_label     = ['Elevation [' self.unitLib.unitSymbols.length ', ' self.config.project_datum ']'];
            x_label     = ['X Distance [' self.unitLib.unitSymbols.length ']'];
            title_label = ['PSE ID: ' self.config.struc_id ' | Alternative ID: ' self.config.case_name];
            title_label = strrep(title_label, '_', ' ');
            add_berm = self.config.add_toe_berm;
            % Get Values For Profile
            % Offshore Slope
            offshore_slope_cota = pse_geo.offshore_slope;
            % Berm Parameters
            if add_berm == 1
                berm_seaside_slope_cota = pse_geo.berm_seaward_slope;
                berm_crest_width =  abs(pse_geo.berm_crest_width);
                berm_crest_elevation =  pse_geo.berm_crest_elevation;
            else
                x_ini = x_shift;
            end
            % Main PSE Parameters (Signed Elevations, Negative Below Datum Zero)
            toe_elevation = pse_geo.toe_elevation;
            crest_elevation = pse_geo.crest_elevation;
            crest_width = pse_geo.crest_width;
            % Vertical Scales Follow Structure Height (Fallback To 1 For Degenerate Input)
            struc_height = crest_elevation - toe_elevation;
            if ~(struc_height > 0)
                struc_height = 1;
            end
            y_shift = sand_ratio*struc_height;
            y_top = top_ratio*struc_height;
            switch self.config.struc_type
                case {1, 3, 4}
                    mound_seaside_slope_cota = pse_geo.seaside_slope;
                    mound_leeside_slope_cota = pse_geo.leeside_slope;
                case 2
                    mound_seaside_slope_cota = 0;
                    mound_leeside_slope_cota = 0;
            end

            % Build Polys (solvePointSlope Returns Absolute X Positions)
            % Berm Poly (Berm Toe At x_shift)
            if add_berm == 1
                % X Coordinates
                xBerm = repmat(x_shift, 4, 1);
                xBerm(2:end) = solvePointSlope(berm_crest_elevation, toe_elevation,...
                    1/berm_seaside_slope_cota, [], x_shift);
                xBerm(3:end) = xBerm(2)+berm_crest_width;
                % Y Coordinates
                yBerm = repmat(toe_elevation, 4, 1);
                yBerm(2:3) = berm_crest_elevation;
                x_ini = xBerm(3);
            end
            % PSE Poly (Seaside Toe At x_ini)
            xGeo = repmat(x_ini, 4, 1);
            switch  self.config.struc_type
                case {1, 3, 4}
                    % Seaside Slope
                    xGeo(2) = solvePointSlope(crest_elevation, toe_elevation,...
                        1/mound_seaside_slope_cota, [], x_ini);
                    % Crest
                    xGeo(3) = xGeo(2)+crest_width;
                    % Leeside Slope
                    xGeo(4) = solvePointSlope(crest_elevation, toe_elevation,...
                        1/mound_leeside_slope_cota, [], xGeo(3));
                case 2
                    % Crest
                    xGeo(3:4) = xGeo(2)+crest_width;
            end
            yGeo  = [toe_elevation, crest_elevation, crest_elevation, toe_elevation]';
            % Sea Bottom (x_shift Beyond Leeside Toe, y_shift Thick)
            x_f =  xGeo(end) + x_shift;
            xOffshore = [linspace(0,x_f,3)';flipud(linspace(0,x_f,3)')];
            yOffshore = [repmat(toe_elevation, 3, 1); repmat(toe_elevation-y_shift, 3, 1)];
            ax = aux_methods.initiate_axes(ax, x_label, y_label, title_label, self.base_fnt);
            ax.Title.Interpreter = 'none';
            ax.Title.String = title_label; % Plain Title (initiate_axes Set The LaTeX-Escaped Form)
            % Create Polyshapes
            Geo        = polyshape(xGeo, yGeo);
            Sand       = polyshape(xOffshore, yOffshore);
            plot(ax, Sand, 'FaceColor', [0.92,0.82,0.08], 'EdgeColor', 'none', 'FaceAlpha', 1, 'Tag', 'sand');
            plot(ax, Geo, 'FaceColor', [0.65,0.65,0.65], 'EdgeColor', [0,0,0], 'FaceAlpha', 1, 'Tag', 'pse');
            if add_berm == 1
                plot(ax, polyshape(xBerm,yBerm), 'FaceColor', [0.65,0.65,0.65], 'EdgeColor', [0,0,0], 'FaceAlpha', 1, 'Tag', 'Berm');
            end

            % Add the anchored text box
            % Offshore Elevation (Storm DB Study Grid, Else Inputs) From The Structure (Copied At Run Time,
            % call_project_response.m), Else From config (Structures Built Outside A Run): 'n/a' When None Is Given;
            % Optional Source Label (offshore_elevation_source, e.g. 'Storm DB grid')
            elev_src = self.config;
            if isfield(pse_geo, 'offshore_elevation') && ~isempty(pse_geo.offshore_elevation)
                elev_src = pse_geo;
            end
            elev_str = 'n/a';
            if isfield(elev_src, 'offshore_elevation') && isscalar(elev_src.offshore_elevation) && isfinite(elev_src.offshore_elevation)
                elev_str = sprintf('%.2f', elev_src.offshore_elevation);
                if isfield(elev_src, 'offshore_elevation_source') && ~isempty(elev_src.offshore_elevation_source)
                    elev_str = [elev_str ' (' char(elev_src.offshore_elevation_source) ')'];
                end
            end
            textContent = { ...
                sprintf('Offshore Slope (tan(a) | deg): %.2f | %.2f', 1/offshore_slope_cota, rad2deg(atan(1/offshore_slope_cota))), ...
                ['Offshore Elev. [m]: ' elev_str] ...
                };

            text(ax, 0.02, 0.98, textContent, ...
                'Units', 'normalized', ...
                'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', 'white', ...
                'EdgeColor', 'black', ...
                'Interpreter', 'none'); % Plain Text (Storm DB Names May Contain Underscores)

            ax.Children = ax.Children([end, 1:end-1]);
            xlim(ax, [0, x_f]);
            ylim(ax, [toe_elevation-y_shift, crest_elevation+y_top]);
            warning('on');

            function result = solvePointSlope(y2, y1, m, x2, x1)
                % Pass the known variables as numbers, and the unknown as []
                % Example: solvePointSlope(10, [], 2, 5, 1) solves for y1

                if isempty(y2)
                    result = y1 + m * (x2 - x1);
                elseif isempty(y1)
                    result = y2 - m * (x2 - x1);
                elseif isempty(m)
                    result = (y2 - y1) / (x2 - x1);
                elseif isempty(x2)
                    result = (y2 - y1) / m + x1;
                elseif isempty(x1)
                    result = x2 - (y2 - y1) / m;
                else
                    error('You must pass exactly one variable as empty ([]).');
                end
            end
        end

        function [ax] = storm_data_space_plot(self, ax, ds_query, var_left, var_right)
            arguments
                self
                ax
                ds_query  struct
                var_left  string {mustBeMember(var_left, ["SWL", "Hm0", "Tp"])}
                var_right  string {mustBeMember(var_right, ["SWL", "Hm0", "Tp"])}
            end
            %
            stm_data = aux_methods.pull_data(ds_query, self.storm);
            % Find Col Index For Requested Field
            col_indx_right = find(var_right== ["SWL", "Hm0", "Tp"]);
            col_indx_left = find(var_left== ["SWL", "Hm0", "Tp"]);
            % Pull Peaks
            peaks_left = cellfun(@(x) max(x(:, col_indx_left), [], "omitnan"), stm_data(:,2), 'un', true);
            peaks_right = cellfun(@(x) max(x(:, col_indx_right), [], "omitnan"), stm_data(:,2), 'un', true);
            % Get Labels
            [~, ~, ~,...
                ~,...
                ~, y_label_left, ~] = response_library_headers(self.config, char(var_left));
            [~, ~, ~,...
                ~,...
                ~, y_label_right, ~] = response_library_headers(self.config, char(var_right));

            y_label_left = strrep(y_label_left, 'SSL','SWL');
            y_label_right = strrep(y_label_right, 'SSL','SWL');
            % Define Title (PSE Line Only When A PSE Is Provided, e.g. Not For Storm Database Viewing)
            title_label = {['CHS Region: ' self.config.region ' | Savepoint: ' num2str(self.config.sp_ID) ' ']};
            if isfield(self.config, 'struc_id') && ~isempty(self.config.struc_id)
                title_label = [{['PSE ID: ' self.config.struc_id ' | Alternative ID: ' self.config.case_name]}; title_label];
            end
            title_label = strrep(title_label, '_', ' ');
            % Initialize Figure
            ax = aux_methods.initiate_axes(ax, y_label_right, y_label_left, title_label, self.base_fnt);
            plot(ax, peaks_right, peaks_left, 'bo','MarkerSize', 8);
        end

        function [ax] = event_hydrograph_plot(self, ax, ds_query, event_id, field_to_plot, chs_data)
            % Plots One Event Hydrograph: storm (Interpolated, Red) And Optionally
            % The Raw CHS Signal It Was Built From (CHS_Data, Black).
            %   ds_query: storm_type / match_type (data_type Forced To Timeseries)
            %   event_id: Storm ID
            %   field_to_plot: "SWL", "Hm0" or "Tp"
            %   chs_data: CHS_Data From The Storm Database "_raw_files.mat" (Optional)
            %   config (Optional Fields): tc_bias_corrected, chs_swl_b_a, chs_swl_b_r -> TC Raw SWL Bias Correction
            arguments
                self
                ax
                ds_query  struct
                event_id double
                field_to_plot string {mustBeMember(field_to_plot, ["SWL", "Hm0", "Tp"])}
                chs_data = []
            end
            % Interpolated Hydrograph, storm Timeseries Columns: [SWL Hm0 Tp wDir datenum dt]
            ds_query.data_type = 'Timeseries';
            stm_data = aux_methods.pull_data(ds_query, self.storm);
            stm_indx = cell2mat(stm_data(:, 1)) == event_id;
            if ~any(stm_indx)
                error('Requested event ID does not exist');
            end
            hydrograph = stm_data{stm_indx, 2};
            col_indx = find(field_to_plot == ["SWL", "Hm0", "Tp"]);
            t_storm = datetime(hydrograph(:, 5), 'ConvertFrom', 'datenum');
            t_start = t_storm(1);
            % Get Labels
            [~, ~, ~,...
                ~,...
                ~, y_label, ~] = response_library_headers(self.config, char(field_to_plot));
            y_label = strrep(y_label, 'SSL','SWL');
            % Define Title
            title_label = [{['Storm ID: ' num2str(event_id) ' | Storm Type: ' ds_query.storm_type]};...
                {['CHS Region: ' self.config.region ' | Savepoint: ' num2str(self.config.sp_ID) ' ']}];
            title_label = strrep(title_label, '_', ' ');
            % Initialize Figure
            ax = aux_methods.initiate_axes(ax, 'Event Duration [hrs]', y_label, title_label, self.base_fnt);
            % Raw CHS Signal (Black), Clipped To The Interpolated Event Window
            if ~isempty(chs_data)
                [t_raw, y_raw] = pull_raw_signal(chs_data, ds_query.storm_type, event_id, field_to_plot);
                raw_name = 'CHS Data (raw)';
                % TC SWL Bias Correction (Same As call_chs_storm_quality_check; Never Applied To XC)
                if field_to_plot == "SWL" && strcmp(ds_query.storm_type, 'TC') &&...
                        isfield(self.config, 'tc_bias_corrected') && isequal(self.config.tc_bias_corrected, 1)
                    b_a = self.config.chs_swl_b_a;
                    b_r = self.config.chs_swl_b_r;
                    y_raw = y_raw - b_a./abs(b_a)./sqrt(1./b_a.^2 + 1./(b_r .* y_raw).^2);
                    raw_name = 'CHS Data (raw, bias corrected)';
                end
                keep = t_raw >= t_start & t_raw <= t_storm(end);
                plot(ax, t_raw(keep) - t_start, y_raw(keep), '-k', 'LineWidth', 1.2, 'DisplayName', raw_name);
            end
            % Interpolated storm Signal (Red)
            plot(ax, t_storm - t_start, hydrograph(:, col_indx), '-or', 'LineWidth', 1.5, 'MarkerSize', 3,...
                'DisplayName', 'storm (interpolated)');
            % Elapsed Time Axis (0:dt:t_final) In Hours
            ax.XAxis.TickLabelFormat = 'h';
            xlim(ax, [hours(0), t_storm(end) - t_start]);
            legend(ax, 'Location', 'best');

            function [t_raw, y_raw] = pull_raw_signal(chs_data, storm_type, event_id, field_to_plot)
                % Raw Timeseries From CHS_Data: ADCIRC For SWL, Wave Model For Hm0/Tp
                t_raw = datetime.empty(0, 1);
                y_raw = zeros(0, 1);
                switch storm_type
                    case 'TC'
                        type_tokens = {'_TS_', '_TC_'};
                    case 'XC'
                        type_tokens = {'_XC_', '_XH_'};
                    otherwise
                        return
                end
                file_names = {chs_data.Filename};
                is_ts = contains(file_names, 'Timeseries') & contains(file_names, type_tokens);
                is_adcirc = contains(file_names, 'ADCIRC');
                if field_to_plot == "SWL"
                    file_indx = find(is_ts & is_adcirc, 1);
                    col_name = 'Water Elevation';
                    flag_value = -90; % ADCIRC No-Data Flag (chs_timeseries_formater)
                else
                    file_indx = find(is_ts & ~is_adcirc, 1);
                    if isempty(file_indx)
                        return
                    end
                    wave_headers = chs_wave_model_header_locator(chs_data(file_indx));
                    col_name = wave_headers.(char(field_to_plot));
                    flag_value = -400; % Wave Model No-Data Flag (chs_timeseries_formater)
                end
                if isempty(file_indx)
                    return
                end
                raw_table = chs_data(file_indx).Conv_Data.Table_StormData;
                row_indx = find(str2double(raw_table.('Storm ID')) == event_id, 1);
                if isempty(row_indx)
                    return
                end
                t_raw = datetime(raw_table.('yyyymmddHHMM'){row_indx}, 'InputFormat', 'yyyyMMddHHmm');
                y_raw = raw_table.(col_name){row_indx};
                y_raw(y_raw < flag_value) = NaN;
            end
        end

        function [] = storm_event_viewer(self, parent, ds_query, event_id, response_to_view, datum_offset)
            arguments
                self
                parent
                ds_query struct
                event_id double
                response_to_view string  {mustBeMember(response_to_view, [ ...
                    "Hm0t", ...
                    "R2p", "R2p_SWL", ...
                    "Dn50", "Dn50_LCBW", "Dn50_Lee", ...
                    "p1", ...
                    "q", "q_overflow", "q_wave_ot", ...
                    "Q_vol", "Q_vol_overflow", "Q_vol_wave_ot", ...
                    "DamDepthElev", "DamDepth", ...
                    "p2dyn", "p2sta", "p2total", ...
                    "p3dyn", "p3sta", "p3total", ...
                    "pu", ...
                    "X_low", "X_up", "X_c_surge", "Bx", ...
                    "theta_low", "theta_up", "theta_center", ...
                    "Bjet", "Vjet", "Fjet" ...
                    ])}
                datum_offset double
            end
            % Create figure with 2 subplots stacked vertically.
            % The top plot must include: SWL, Hm0_no_DL, h, Rc, Hm0_with_DL
            % For the SWL subplot, also include h (SWL - toe_elevation).
            if isempty(datum_offset)
                datum_offset = 0;
            end

            stm_data = aux_methods.pull_data(ds_query, self.storm);

            if strcmp(ds_query.data_type,'Timeseries')
                stm_to_plot = cell2mat(stm_data(:,1)) == event_id;
                event_str = num2str(event_id);
                x_str = 'Date';
                time_signal = datetime(stm_data{stm_to_plot,2}(:,5),'ConvertFrom','datenum');
            else
                stm_to_plot = true(size(stm_data,1), 1);
                event_str = 'All (Peaks)';
                x_str = 'Event #';
                time_signal = 1:length(stm_data);
            end
            dummy = cell2mat(stm_data(stm_to_plot,2));
            swl_signal = dummy(:,1);
            hm0_signal = dummy(:,2);
            if ~any(stm_to_plot)
                error("Requested event ID does not exist");
            end

            switch self.structure.struc_type
                case 1
                    supported_resp = ["Hm0t", ...
                        "R2p", "R2p_SWL", ...
                        "q", "q_overflow", "q_wave_ot", ...
                        "Q_vol", "Q_vol_overflow", "Q_vol_wave_ot", ...
                        "DamDepthElev", "DamDepth"];
                case 2
                    supported_resp = ["p1",...
                        "q", "q_overflow", "q_wave_ot", ...
                        "Q_vol", "Q_vol_overflow", "Q_vol_wave_ot", ...
                        "DamDepthElev", "DamDepth", ...
                        "p2dyn", "p2sta", "p2total", ...
                        "p3dyn", "p3sta", "p3total", ...
                        "pu", ...
                        "X_low", "X_up", "X_c_surge", "Bx", ...
                        "theta_low", "theta_up", "theta_center", ...
                        "Bjet", "Vjet", "Fjet" ...
                        ];
                case 3
                    supported_resp = ["Hm0t", ...
                        "R2p", "R2p_SWL", ...
                        "Dn50", "Dn50_LCBW", "Dn50_Lee", ...
                        "q", "q_overflow", "q_wave_ot", ...
                        "Q_vol", "Q_vol_overflow", "Q_vol_wave_ot", ...
                        "DamDepthElev", "DamDepth"];
                case 4
                    supported_resp = ["Hm0t", ...
                        "R2p", "R2p_SWL", ...
                        "Dn50_LCBW",...
                        "q", "q_overflow", "q_wave_ot", ...
                        "Q_vol", "Q_vol_overflow", "Q_vol_wave_ot", ...
                        "DamDepthElev", "DamDepth"];
            end
            if ~any(ismember(response_to_view, supported_resp))
                error(['Requested response is not supported by pse type. Please call: ' supported_resp]);
            end
            [~, ~, ~,...
                ~,...
                ~, y_label, y_scale_log] = response_library_headers(self.config, char(response_to_view));
            %
            config_mod  = self.config; % This is just to ensure I get the correct label
            config_mod.apply_random_tides = 0; % This will be overwritten in later lines
            [~, ~, ~,...
                ~,...
                ~, y_label2, ~] = response_library_headers(config_mod, 'SWL');
            y_label2 = strrep(y_label2, 'SSL','Elevation');
            % Define Title
            title_label = [{['PSE ID: ' self.config.struc_id ' | Alternative ID: ' self.config.case_name]};...
                {['CHS Region: ' self.config.region ' | Savepoint: ' num2str(self.config.sp_ID) ' | Event: ' event_str]}];
            title_label = strrep(title_label, '_', ' ');
            % Initialize Figure
            [gl, subplot_flag] = subplot_manager(self, parent, 2, 1);
            % Define Axes Objects
            if subplot_flag
                ax = aux_methods.initiate_axes(gl(1), x_str, y_label2, title_label, self.base_fnt);
                ax2 = aux_methods.initiate_axes(gl(2), x_str, y_label, ['Response Variable: ' y_label], self.base_fnt);
            else
                ax = aux_methods.initiate_axes(gl, x_str, y_label2, title_label, self.base_fnt, 1, 1);
                ax2 = aux_methods.initiate_axes(gl, x_str, y_label, ['Response Variable: ' y_label], self.base_fnt , 2, 1);
            end

            %
            if y_scale_log == 1
                ax2.YScale = 'log';
            end

            % Mimic PROS Forcing Adjustment (No reps), Peaks Duration From The Run's config (call_project_forcing_formater Rule)
            pf = stormsim_pros_formater(ds_query.storm_type, restamp_peaks_storm_duration(self.storm, self.config.storm_duration), struct('TC_Freq', []), 0);
            % Keep Only Requested Data Product
            pf = pf.(ds_query.data_type).(ds_query.match_type).(ds_query.storm_type);
            % Remove Replicates
            pf.SWL = pf.SWL_no_rep;
            pf.Hm0 = pf.Hm0_no_rep;
            pf.Tp = pf.Tp_no_rep;
            % Apply Adjustments
            config_mod  = self.config;
            config_mod.apply_depth_limitation = 1; % Force DL
            % LCS Tide Indices Are Per Life Cycle, Not Per Storm: Draw Fresh Tides For This Event
            if self.config.workflow == 3 && isfield(config_mod, ['tide_indx_' lower(ds_query.storm_type)])
                config_mod = rmfield(config_mod, ['tide_indx_' lower(ds_query.storm_type)]);
            end
            config_mod.workflow = 1;
            config_names = fieldnames(config_mod);
            [pf, config_mod] = adjust_project_forcing(config_mod, self.structure, pf, ds_query.storm_type);
            % Turn On Computes
            config_mod = config_editor(config_mod, config_names(contains(fieldnames(config_mod),{'compute'})), 1);
            % Compute Structure Responses
            emp_coeff = load_empirical_coefficients();
            resp_signal = compute_structure_response(config_mod, self.structure,pf,emp_coeff, 0);
            % Pick Out requested Response
            if ~isfield(resp_signal, response_to_view)
                resp_signal = [];
            else
                resp_signal = resp_signal.(response_to_view);
            end
            % Pick Storm
            if strcmp(ds_query.data_type,'Timeseries')
                if ~any(response_to_view == ["Q_vol", "Q_vol_overflow", "Q_vol_wave_ot"])
                    resp_signal = resp_signal(cell2mat(stm_data(:,1)) == event_id);
                    resp_time = time_signal;
                    resp_style = 'o';
                else
                    resp_time = 1:length(resp_signal);
                    resp_style = '-';
                end
                hm0_dl_signal = pf.Hm0{cell2mat(stm_data(:,1)) == event_id};
            else
                resp_time = time_signal;
                hm0_dl_signal = cell2mat(pf.Hm0);
                resp_style = 'o';
            end
            
            if any(iscell(resp_signal))
                resp_signal = cell2mat(resp_signal);
            end

            % Compute Derived Signals
            h = swl_signal - self.structure.toe_elevation;
            if config_mod.add_toe_berm == 1
                hb = swl_signal - self.structure.berm_crest_elevation;
            end
            rc_signal = self.structure.crest_elevation-swl_signal;
            swl_signal = swl_signal-datum_offset; % Makes SWL To Be  Y value from datum_offset.

            %Plots
            plot(ax, time_signal, swl_signal, '-r','LineWidth', 1.2,'DisplayName','SWL');
            yline(ax, self.structure.crest_elevation-datum_offset, '--c','LineWidth', 1.2,'DisplayName','PSE Crest');
            plot(ax, time_signal, hm0_signal, '--k','LineWidth', 1.2,'DisplayName','Hm0 (raw)');
            plot(ax, time_signal, hm0_dl_signal, '-k','LineWidth', 1.2,'DisplayName','Hm0 (DL)');
            plot(ax, time_signal, h, '--b','LineWidth', 1.2,'DisplayName','h');
            if config_mod.add_toe_berm == 1
                plot(ax, time_signal, hb, '--m','LineWidth', 1.2,'DisplayName','h (berm)');
            end
            plot(ax, time_signal, rc_signal, '-g','LineWidth', 1.2,'DisplayName','Freeboard (Rc)');
            lg = legend(ax, 'Location', 'northoutside','Orientation','horizontal','NumColumns',7);
            lg.ItemHitFcn = @toggleLine;
            %
            if isempty(resp_signal)
                aux_methods.display_no_data(ax2, self.base_fnt);
            else
                plot(ax2, resp_time, resp_signal, [resp_style 'k'],'LineWidth', 1.2);
            end

            ax.XLim = [min(time_signal) max(time_signal)];
            ax2.XLim =  [min(resp_time) max(resp_time)];

            if (any(response_to_view == ["Q_vol", "Q_vol_overflow", "Q_vol_wave_ot"]) && ~isempty(resp_signal))
                plot(ax2, resp_time(cell2mat(stm_data(:,1)) == event_id), resp_signal(cell2mat(stm_data(:,1)) == event_id), 'or','LineWidth', 1.2);
            else
                linkaxes([ax,ax2],'x');
            end
            
            if isa(ax.Parent.Parent, 'matlab.ui.Figure') % Not A Panel/Tab Holding The Grid (e.g. GUI Results Tab Mirror)
                ax.Parent.Parent.Position = [100 100 992 699];
            end
            function config_out = config_editor(config_out, var_to_look, value)
                % Turn Off Responses For RB Section
                for ii = 1:length(var_to_look)
                    config_out.(var_to_look{ii}) = value;
                end
            end
            % --- Callback Function ---
            function toggleLine(~, event)
                % event.Peer is the specific line object associated with the clicked legend text
                if strcmp(event.Peer.Visible, 'on')
                    event.Peer.Visible = 'off'; % Hide the line
                else
                    event.Peer.Visible = 'on';  % Show the line
                end
            end
        end
    end

    methods (Access=public)
        function [gl, subplot_flag] = subplot_manager(self, parent, nRows, nCols)
            % Initialize Figure
            subplot_flag = false;

            if ~isempty(parent)
                switch class(parent)
                    case 'matlab.ui.control.UIAxes'
                        % Create the 2-row, 1-column grid layout
                        gl = uigridlayout(parent.parent,[nRows, nCols]);
                        gl.RowHeight = repmat({'1x'},1, nRows); % Both rows get equal flexible space
                        gl.ColumnWidth = repmat({'1x'},1, nCols);     % The single column takes up the full width
                        parent.Parent = gl;
                        parent.Layout.Row = 1;
                        parent.Layout.Column = 1;

                    case 'matlab.ui.Figure'
                        try
                            gl = uigridlayout(parent,[nRows, nCols]);
                            uifig_check = true;
                            delete(gl);
                        catch
                            uifig_check = false;
                        end

                        if uifig_check % UIFigure
                            % Create the grid layout
                            gl = uigridlayout(parent,[nRows, nCols]);
                            gl.RowHeight = repmat({'1x'},1, nRows);
                            gl.ColumnWidth = repmat({'1x'},1, nCols);

                        else % Classic Figure
                            % Initialize the tiled layout on the figure
                            t = tiledlayout(parent, nRows, nCols);

                            % Preallocate graphics object array (good practice)
                            gl = gobjects(nRows * nCols, 1);

                            ctr = 0;
                            for gg = 1:nRows % Fixed: replaced length(nRows) with nRows
                                for kk = 1:nCols
                                    ctr = ctr + 1;
                                    % Create the axes in the next tile and store its handle
                                    gl(ctr) = nexttile(t);
                                    gl(ctr).Tag = [num2str(gg) '_' num2str(kk)];
                                end
                            end
                            subplot_flag = true;
                        end

                    case 'matlab.ui.container.GridLayout'
                        gl = parent;
                        gl.RowHeight = repmat({'1x'},1, nRows);
                        gl.ColumnWidth = repmat({'1x'},1, nCols);
                    case 'matlab.graphics.axis.Axes'    
                        % Initialize the tiled layout on the figure
                        t = tiledlayout(parent.Parent, nRows, nCols);

                        % Preallocate graphics object array (good practice)
                        gl = gobjects(nRows * nCols, 1);

                        ctr = 0;
                        for gg = 1:nRows % Fixed: replaced length(nRows) with nRows
                            for kk = 1:nCols
                                ctr = ctr + 1;
                                % Create the axes in the next tile and store its handle
                                gl(ctr) = nexttile(t);
                                gl(ctr).Tag = [num2str(gg) '_' num2str(kk)];
                            end
                        end
                        subplot_flag = true;
                end
            else
                % Create the 2-row, 1-column grid layout in a new UIFigure
                gl = uigridlayout(uifigure, [2, 1]);
                gl.RowHeight = repmat({'1x'},1, nRows);
                gl.ColumnWidth = repmat({'1x'},1, nCols);
            end
        end
    end
end

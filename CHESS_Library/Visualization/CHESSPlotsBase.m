classdef CHESSPlotsBase
    % CHESSPlotsBase  Base class of the CHESS plotting objects (shared plots).
    %   sp = CHESSPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
    %       returns the workflow subclass (pros_methods, det_methods or
    %       lcs_methods), which inherits every method below.
    %   sp = CHESSPlotsBase(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
    %       creates the base object directly, for the workflow-independent
    %       plots (the GUI does so for pse_transect_plot and
    %       storm_data_space_plot, with [] for the unused inputs).
    %
    %   Inputs (stored as properties of the same names; unit_system is
    %   stored as unitLib):
    %     config          - run configuration struct
    %     Resp            - saved structure responses of the run, or []
    %     storm           - storm database variable "storm", or []
    %     project_forcing - project forcing of the run, or []
    %     dsw             - storm probability masses of the storm database
    %                       ("prob_mass": TC_Freq, TC_SRR, smpl1-smpl3), or []
    %     structure       - PSE structure struct, or []
    %     base_fnt        - base font size [pt] (titles +2, ticks -2)
    %     unit_system     - 'SI' or 'Imperial': unit symbols of the axis
    %                       labels (aux_methods.build_unit_library); the
    %                       data are not converted
    %   See CHESSPlots for the details of each input.
    %   ds_query (dataset query, most methods): struct with storm_type
    %   ('XC', 'TC' or 'CC'), data_type ('Peaks' or 'Timeseries') and
    %   match_type ('Default', 'WLP' or 'WHP'), see aux_methods.pull_data.
    %
    %   Methods:
    %     CHESSPlotsBase        - constructor
    %     pse_transect_plot     - PSE cross-section with sand and toe berm
    %     storm_data_space_plot - storm peaks of one variable against another
    %     event_hydrograph_plot - one storm hydrograph, optional raw CHS signal
    %     storm_event_viewer    - forcing and one response of the saved results
    %     event_selection       - viewer / table selection with defaults
    %     refine_selection      - workflow-specific selection defaults
    %     event_controls        - in-figure control row of the viewer and table
    %     event_series_defaults - optional storm event viewer series fields
    %     response_table        - response table pop-out (table and plot)
    %     subplot_manager       - grid or tiled layout for multi-panel plots
    %
    %   Tier: public
    %
    %   See also CHESSPlots, pros_methods, det_methods, lcs_methods.

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
        function self = CHESSPlotsBase(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
            % CHESSPlotsBase  Create the base plotting object (workflow plots: use CHESSPlots).
            %   self = CHESSPlotsBase(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
            %       stores the inputs as properties and unit_system as
            %       unitLib (aux_methods.build_unit_library). The inputs
            %       are documented in CHESSPlots.

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
        function [ax, Geo] = pse_transect_plot(self, ax)
            % pse_transect_plot  Draw the PSE cross-section (structure, sand, toe berm).
            %   [ax, Geo] = pse_transect_plot(self, ax) draws the structure
            %       of config.struc_type (levee or rubble mound trapezoid,
            %       floodwall rectangle) on the offshore sand profile, with
            %       the toe berm when config.add_toe_berm == 1. Elevations
            %       are signed (study datum, negative below zero); axis
            %       labels use the unit symbols of unit_system.
            %
            %   Inputs:
            %     ax - axes, figure or grid layout (aux_methods.initiate_axes)
            %   Outputs:
            %     ax  - the plot axes
            %     Geo - polyshape of the structure body

            % polyshape Repairs The Transect Polygons On Creation And Warns Each Time
            w_state = warning;
            warning('off', 'MATLAB:polyshape:repairedBySimplify');
            w_cleanup = onCleanup(@() warning(w_state));
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
                case {1, 3}
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
                case {1, 3}
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
            % storm_data_space_plot  Storm peaks of one variable against another.
            %   ax = storm_data_space_plot(self, ax, ds_query, var_left, var_right)
            %       plots the per-storm maximum of var_left (Y) against that
            %       of var_right (X) for the storm database dataset of
            %       ds_query (self.storm; Hm0 is the offshore wave height).
            %
            %   Inputs:
            %     ax        - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query  - dataset query (storm_type, data_type, match_type)
            %     var_left  - Y variable: "SWL", "Hm0" or "Tp"
            %     var_right - X variable: "SWL", "Hm0" or "Tp"
            %   Outputs:
            %     ax - the plot axes

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
            % Get Labels (Storm Database Hm0 Is Offshore)
            [~, ~, ~,...
                ~,...
                ~, y_label_left, ~] = response_library_headers(self.config, char(replace(var_left, "Hm0", "Hm0_offshore")));
            [~, ~, ~,...
                ~,...
                ~, y_label_right, ~] = response_library_headers(self.config, char(replace(var_right, "Hm0", "Hm0_offshore")));
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
            % event_hydrograph_plot  Draw one storm hydrograph, optionally with its raw CHS signal.
            %   ax = event_hydrograph_plot(self, ax, ds_query, event_id, field_to_plot)
            %   ax = event_hydrograph_plot(self, ax, ds_query, event_id, field_to_plot, chs_data)
            %       draws the interpolated storm database hydrograph (red)
            %       over elapsed hours and, with chs_data, the raw CHS
            %       signal it was built from (black, clipped to the event
            %       window). TC raw SWL is bias corrected when
            %       config.tc_bias_corrected == 1 (chs_swl_b_a, chs_swl_b_r).
            %
            %   Inputs:
            %     ax            - axes, figure or grid layout (aux_methods.initiate_axes)
            %     ds_query      - dataset query (storm_type, match_type;
            %                     data_type is set to Timeseries)
            %     event_id      - storm ID (an unknown ID errors)
            %     field_to_plot - "SWL", "Hm0" or "Tp"
            %     chs_data      - (optional) CHS_Data from the storm database
            %                     "_raw_files.mat" (default [] = no raw signal)
            %   Outputs:
            %     ax - the plot axes

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
            % Get Labels (Storm Database Hm0 Is Offshore)
            [~, ~, ~,...
                ~,...
                ~, y_label, ~] = response_library_headers(self.config, char(replace(field_to_plot, "Hm0", "Hm0_offshore")));
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
                if ~ismember(storm_type, {'TC', 'XC'})
                    return
                end
                file_parts = chs_file_name_parts({chs_data.Filename});
                is_ts = strcmp({file_parts.data_type}, 'Timeseries') & strcmp({file_parts.storm_type}, storm_type);
                is_adcirc = [file_parts.is_adcirc];
                if field_to_plot == "SWL"
                    file_indx = find(is_ts & is_adcirc, 1);
                    col_name = 'Water Elevation';
                    flag_value = -90; % ADCIRC No-Data Flag (chs_timeseries_formatter)
                else
                    file_indx = find(is_ts & ~is_adcirc, 1);
                    if isempty(file_indx)
                        return
                    end
                    wave_headers = chs_wave_model_header_locator(chs_data(file_indx));
                    col_name = wave_headers.(char(field_to_plot));
                    flag_value = -400; % Wave Model No-Data Flag (chs_timeseries_formatter)
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

        function fig = storm_event_viewer(self, parent, ds_query, response_to_view, sel, datum_offset, on_change)
            % storm_event_viewer  Show the forcing and one response of the saved results.
            %   fig = storm_event_viewer(self, parent, ds_query, response_to_view)
            %   fig = storm_event_viewer(self, parent, ds_query, response_to_view, sel, datum_offset, on_change)
            %       draws the forcing (top) and one response (bottom) of the
            %       workflow's saved results, with the selectors in a
            %       control row above the axes. Nothing is recomputed except
            %       the workflow 1 (PROS-RB) responses of the selected
            %       replicate (pros_methods.event_series). The response
            %       must be a per-event response supported by
            %       structure.struc_type (response_registry).
            %
            %   Inputs:
            %     parent           - [] (own uifigure), or a uifigure, uipanel
            %                        or uigridlayout to build in (classic
            %                        figures are not supported)
            %     ds_query         - dataset query (storm_type, data_type, match_type)
            %     response_to_view - response name (string)
            %     sel              - (optional) selection struct; [] or missing
            %                        fields take defaults from the data
            %                        (event_selection):
            %                          storm_id     storm shown (Timeseries view)
            %                          peaks_view   true: per-storm maxima of all
            %                                       storms, markers only
            %                                       (Timeseries data only)
            %                          lake_removed true: mean lake level removed
            %                                       from SWL and crest (Great
            %                                       Lakes only, right-click)
            %                          z_col        workflow 1: replicate column
            %                          lc, year     workflow 3: life cycle, year
            %                                       ('All' or a year)
            %                          aef, cl      workflow 4: AEF/AEP, CL ('All'
            %                                       or a CL)
            %     datum_offset     - (optional) elevation subtracted from SWL and
            %                        crest (default 0)
            %     on_change        - (optional) function handle called with the
            %                        new sel when a control changes (the caller
            %                        redraws); [] (default): the viewer redraws
            %                        itself in place
            %   Outputs:
            %     fig - the figure holding the viewer

            arguments
                self
                parent
                ds_query struct
                response_to_view string
                sel = []
                datum_offset double = 0
                on_change = []
            end
            % Registry Lists Cannot Be Called In Validators (R2022b)
            mustBeMember(response_to_view, response_registry('output', 'names', 'per_event', true));
            if isempty(datum_offset)
                datum_offset = 0;
            end
            % Each Workflow Provides Its Choices And Its Series (Common Struct, Drawn By The Shared Core Below)
            choices = self.event_choices(ds_query);
            sel = self.event_selection(sel, choices);
            ser = self.event_series_defaults(self.event_series(ds_query, response_to_view, sel));

            supported_resp = response_registry('output', 'names', 'per_event', true, 'structure_type', self.structure.struc_type);
            if ~any(ismember(response_to_view, supported_resp))
                error(['Requested response is not supported by pse type. Please call: ' strjoin(supported_resp, ', ')]);
            end
            labels = self.event_viewer_labels(response_to_view, sel, ser, datum_offset);
            % Container: Own uifigure, Else Built Inside The Caller's Figure, Panel Or Grid
            if isempty(parent) || ~isvalid(parent)
                parent = uifigure('Name', 'CHESS Figure', 'Position', [100 100 1000 600]);
            end
            container = parent;
            gl = uigridlayout(container, [3 1], 'RowHeight', {32, '1x', '1x'}, 'ColumnWidth', {'1x'}, 'Padding', [0 0 0 0]);
            fig = ancestor(container, 'figure');
            % Control Row (Per Workflow)
            self.event_controls(gl, 1, sel, choices, @emit);
            % Axes
            ax = aux_methods.initiate_axes(gl, labels.x_label, labels.elevation_label, labels.title, self.base_fnt, 2, 1);
            ax2 = aux_methods.initiate_axes(gl, labels.x_label, labels.response_label, ['Response Variable: ' labels.response_label], self.base_fnt, 3, 1);
            if labels.response_log == 1
                ax2.YScale = 'log';
            end

            event_view = self.event_viewer_view(ser, labels.response_log);
            self.plot_event_forcing(ax, fig, ser, event_view, sel, labels, @emit);
            self.plot_event_response(ax2, ser, event_view);
            self.finish_event_axes(ax, ax2, ser, event_view);

            % --- New Selection: Caller Redraws (on_change), Else This Viewer Rebuilds In Place ---
            function emit(field_name, value)
                new_sel = sel;
                new_sel.(field_name) = value;
                if isa(on_change, 'function_handle')
                    on_change(new_sel);
                else
                    kids = container.Children;
                    delete(kids(~isa(kids, 'matlab.ui.container.ContextMenu')));
                    self.storm_event_viewer(container, ds_query, response_to_view, new_sel, datum_offset, on_change);
                end
            end
        end

        function sel = event_selection(self, sel, choices)
            % event_selection  Complete a viewer / response table selection with defaults.
            %   sel = event_selection(self, sel, choices) fills missing
            %       fields with the defaults from the data: first storm,
            %       Timeseries view, lake level kept; the workflow fields
            %       (z_col, lc, year, aef, cl) are completed by
            %       refine_selection.
            %
            %   Inputs:
            %     sel     - selection struct or [] (fields: storm_id,
            %               peaks_view, lake_removed, z_col, lc, year, aef, cl)
            %     choices - event_choices output (storm_ids, peaks_toggle, ...)
            %   Outputs:
            %     sel - the complete, validated selection struct

            defaults = struct('storm_id', NaN, 'peaks_view', false, 'lake_removed', false, ...
                'z_col', [], 'lc', [], 'year', 'All', 'aef', [], 'cl', []);
            if ~isstruct(sel)
                sel = struct();
            end
            for fn = fieldnames(defaults)'
                if ~isfield(sel, fn{1})
                    sel.(fn{1}) = defaults.(fn{1});
                end
            end
            if ~isempty(choices.storm_ids) && ~ismember(sel.storm_id, choices.storm_ids)
                sel.storm_id = choices.storm_ids(1);
            end
            sel.peaks_view = logical(sel.peaks_view) && choices.peaks_toggle;
            sel.lake_removed = logical(sel.lake_removed);
            sel = self.refine_selection(sel, choices);
        end

        function sel = refine_selection(~, sel, ~)
            % refine_selection  Workflow-specific defaults and validation of a selection.
            %   sel = refine_selection(self, sel, choices) returns sel
            %       unchanged here; pros_methods (z_col, aef, cl) and
            %       lcs_methods (lc, year) override it.
            %
            %   Inputs:
            %     sel     - selection struct (event_selection)
            %     choices - event_choices output
            %   Outputs:
            %     sel - the selection struct
        end

        function ctrl = event_controls(~, parent, row, sel, choices, emit)
            % event_controls  Build the in-figure control row of the viewer and response table.
            %   ctrl = event_controls(self, parent, row, sel, choices, emit)
            %       builds a storm ID dropdown and a peaks-view checkbox
            %       (Timeseries data), else an "All events (Peaks)" label;
            %       pros_methods and lcs_methods override it.
            %
            %   Inputs:
            %     parent  - uigridlayout holding the row
            %     row     - grid row of the control row
            %     sel     - selection struct (event_selection)
            %     choices - event_choices output
            %     emit    - function handle emit(field_name, value), called
            %               when a control changes the selection
            %   Outputs:
            %     ctrl - uigridlayout of the control row

            ctrl = uigridlayout(parent, [1 4], 'ColumnWidth', {'fit', 120, 'fit', '1x'}, 'RowHeight', {'1x'}, 'Padding', [5 2 5 2]);
            ctrl.Layout.Row = row;
            if choices.is_ts
                uilabel(ctrl, 'Text', 'Storm ID:', 'HorizontalAlignment', 'right');
                uidropdown(ctrl, 'Items', string(choices.storm_ids), 'ItemsData', choices.storm_ids, 'Value', sel.storm_id, ...
                    'Enable', ~sel.peaks_view, 'ValueChangedFcn', @(src, ~) emit('storm_id', src.Value));
                if choices.peaks_toggle
                    uicheckbox(ctrl, 'Text', aux_methods.tern(sel.peaks_view, 'Swap to timeseries view', 'Swap to peaks view'), ...
                        'Value', sel.peaks_view, 'ValueChangedFcn', @(src, ~) emit('peaks_view', logical(src.Value)));
                end
            else
                uilabel(ctrl, 'Text', 'All events (Peaks)');
            end
        end

        function ser = event_series_defaults(~, ser)
            % event_series_defaults  Fill the optional storm event viewer series fields.
            %   ser = event_series_defaults(self, ser) adds the missing
            %       optional fields of the shared drawing core:
            %         x_label        X label ('' -> by x_kind: 'datetime' date,
            %                        'event' event #, 'hours' storm duration [hrs])
            %         segments       cell of row-index vectors, one per storm:
            %                        lines break between storms ([] -> one storm)
            %         color_segments true -> the response line has one color
            %                        per segment (default false)
            %         bounds         X positions of thin vertical lines (storm
            %                        start/end) ([] -> none)
            %         xticks         struct(pos, labels) replacing the X ticks
            %                        ([] -> automatic)
            %         overlay        struct array (y, label, color): horizontal
            %                        lines on the response axes ([] -> none)
            %
            %   Inputs:
            %     ser - event_series output of the workflow
            %   Outputs:
            %     ser - ser with every optional field present

            defaults = struct('x_label', '', 'segments', [], 'color_segments', false, 'bounds', [], 'xticks', [], 'overlay', []);
            for fn = fieldnames(defaults)'
                if ~isfield(ser, fn{1})
                    ser.(fn{1}) = defaults.(fn{1});
                end
            end
            if isempty(ser.overlay)
                ser.overlay = [];
            end
        end

        function fig = response_table(self, ds_query, sel, on_change)
            % response_table  Open the response table pop-out (plot on top, table below).
            %   fig = response_table(self, ds_query)
            %   fig = response_table(self, ds_query, sel, on_change) is the
            %       tabular twin of storm_event_viewer, with the same
            %       selection struct and in-figure controls (event_choices,
            %       event_selection, event_controls); the workflow provides
            %       the rows (event_table).
            %       Timeseries view: rows of the selected storm (or life
            %       cycle / year); the selected columns plot as hydrographs
            %       (elevations on the left yyaxis, everything else on the
            %       right; at most 2 unit groups).
            %       Peaks (data type Peaks, or the peaks view of
            %       Timeseries): one row per storm; select 2 columns (1st
            %       click = X, 2nd = Y) for a scatter.
            %
            %   Inputs:
            %     ds_query  - dataset query (storm_type, data_type, match_type)
            %     sel       - (optional) selection struct (event_selection;
            %                 [] = defaults)
            %     on_change - (optional) function handle called with the new
            %                 sel when a control changes (the caller redraws);
            %                 [] (default): the figure updates in place
            %   Outputs:
            %     fig - the uifigure; fig.UserData holds select, set_storm,
            %           set_peaks_view, set_selection, axes and table for
            %           scripts and tests

            if nargin < 3, sel = []; end
            if nargin < 4, on_change = []; end
            choices = self.event_choices(ds_query);
            sel = self.event_selection(sel, choices);
            fig = uifigure('Position', [60 60 1250 820]);
            gl = uigridlayout(fig, [4 1], 'RowHeight', {30, 34, 440, '1x'});
            lt = uilabel(gl, 'Interpreter', 'html');
            lt.Layout.Row = 1;
            ctrl = [];
            axp = uipanel(gl, 'BorderType', 'none');
            axp.Layout.Row = 3;
            ax = uiaxes(axp, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
            ut = uitable(gl, 'RowName', {}, 'FontSize', self.base_fnt - 1, 'SelectionType', 'column', 'Multiselect', 'on');
            ut.Layout.Row = 4;
            st.order = {}; st.T = table(); st.info = struct(); st.ts = false;
            ut.CellSelectionCallback = @on_select;
            apply_view();
            % Programmatic Access (Scripts / Tests)
            fig.UserData = struct('select', @select, 'set_storm', @set_storm, 'set_peaks_view', @set_peaks_view, ...
                'set_selection', @control_changed, 'axes', ax, 'table', ut);

            function control_changed(field_name, value)
                new_sel = sel;
                new_sel.(field_name) = value;
                if isa(on_change, 'function_handle')
                    on_change(new_sel);
                else
                    sel = self.event_selection(new_sel, choices);
                    apply_view();
                end
            end
            function apply_view()
                [T, info] = self.event_table(ds_query, sel);
                st.info = info;
                st.ts = strcmp(info.mode, 'ts');
                fig.Name = ['Response Table | ' info.view_label];
                lt.Text = ['<b>Response Table</b> | ' info.view_label];
                if ~isempty(ctrl) && isvalid(ctrl)
                    delete(ctrl);
                end
                ctrl = self.event_controls(gl, 2, sel, choices, @control_changed);
                set_table(T);
            end
            function set_peaks_view(flag)
                control_changed('peaks_view', logical(flag));
            end
            function set_storm(id)
                if ~ismember(id, choices.storm_ids)
                    error('CHESSPlotsBase:unknownStorm', 'Storm ID %g is not in this dataset.', id);
                end
                control_changed('storm_id', id);
            end
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
                if ismember('Time', vn) && isnumeric(T.Time), ut.ColumnName{strcmp(vn, 'Time')} = 'Time [hrs]'; end % Timeseries: Storm Hours
                ut.Selection = [];
                redraw();
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
                pick = st.order(~ismember(st.order, self.table_id_cols));
                if ~st.ts
                    if numel(pick) ~= 2
                        show_msg({'Select 2 table columns to plot', '1st click = X axis, 2nd click = Y axis'});
                        return
                    end
                    [xl, ~, xlog] = self.field_info(pick{1}); [yl, ~, ylog] = self.field_info(pick{2});
                    cla(ax, 'reset');
                    aux_methods.initiate_axes(ax, xl, yl, '', self.base_fnt);
                    ok = ~isnan(st.T.(pick{1})) & ~isnan(st.T.(pick{2}));
                    scatter(ax, st.T.(pick{1})(ok), st.T.(pick{2})(ok), 30, [0 0.447 0.741], 'filled', 'MarkerEdgeColor', [.2 .2 .2]);
                    ax.XScale = aux_methods.tern(xlog == 1, 'log', 'linear');
                    ax.YScale = aux_methods.tern(ylog == 1, 'log', 'linear');
                    aux_methods.pad_limits(ax, 'X', st.T.(pick{1})(ok));
                    aux_methods.pad_limits(ax, 'Y', st.T.(pick{2})(ok));
                else
                    if isempty(pick)
                        show_msg({'Select one or more table columns', 'to plot their hydrographs'});
                        return
                    end
                    % Group By (Datum Elevation?, Unit): Max 2 Groups -> Left / Right yyaxis
                    key = cellfun(@(v) sprintf('%d|%s', ismember(self.base_field(v), self.elevation_fields), self.field_unit(v)), pick, 'un', false);
                    [grp, ~, gi] = unique(key, 'stable');
                    if numel(grp) > 2
                        show_msg({'Selected columns span more than 2 unit groups', 'Deselect columns until 2 or fewer remain'});
                        return
                    end
                    cla(ax, 'reset'); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
                    set(ax, 'FontSize', self.base_fnt - 2, 'FontWeight', 'bold');
                    cols = lines(numel(pick)); side = {'left', 'right'};
                    for g = 1:numel(grp)
                        yyaxis(ax, side{g});
                        members = find(gi' == g); labs = cell(1, numel(members)); any_log = false;
                        for m = 1:numel(members)
                            k = members(m);
                            [labs{m}, ~, lg] = self.field_info(pick{k}); any_log = any_log || lg == 1;
                            plot(ax, st.T.Time, st.T.(pick{k}), '-', 'Color', cols(k, :), 'LineWidth', 1.4, 'DisplayName', labs{m});
                        end
                        ylabel(ax, aux_methods.latex_escape(strjoin(labs, ', ')), 'Interpreter', 'latex', 'FontSize', self.base_fnt, 'FontWeight', 'bold');
                        ax.YColor = [.15 .15 .15];
                        ax.YScale = aux_methods.tern(any_log, 'log', 'linear');
                        vals = cellfun(@(v) st.T.(v), pick(members), 'un', false);
                        aux_methods.pad_limits(ax, 'Y', vertcat(vals{:}));
                    end
                    % Single Unit Group: Hide The Empty Right Axis
                    ax.YAxis(2).Visible = aux_methods.tern(numel(grp) == 1, 'off', 'on');
                    legend(ax, 'Interpreter', 'latex', 'Location', 'northoutside', 'Orientation', 'horizontal', 'FontSize', self.base_fnt - 1);
                    xlabel(ax, aux_methods.latex_escape(st.info.x_label), 'Interpreter', 'latex', 'FontSize', self.base_fnt, 'FontWeight', 'bold');
                    title(ax, aux_methods.latex_escape(st.info.plot_title), 'Interpreter', 'latex', 'FontSize', self.base_fnt + 2, 'FontWeight', 'bold');
                    if st.T.Time(end) > st.T.Time(1)
                        ax.XLim = [st.T.Time(1) st.T.Time(end)];
                    end
                end
            end
        end
    end

    %% STORM EVENT VIEWER PARTS (Drawn By storm_event_viewer)
    methods (Access=protected)
        function labels = event_viewer_labels(self, response_to_view, sel, ser, datum_offset)
            % Axis Labels, Title And Elevation Offset Of The Storm Event Viewer:
            %   title, x_label, elevation_label (Top Axes), response_label, response_log (Bottom Axes),
            %   lake_level (Mean Lake Level, 0 Outside The Great Lakes), elevation_offset (Subtracted From SWL And Crest)
            [~, ~, ~,...
                ~,...
                ~, labels.response_label, labels.response_log] = response_library_headers(self.config, char(response_to_view));
            %
            [~, ~, ~,...
                ~,...
                ~, elevation_base_label, ~] = response_library_headers(self.config, 'SWL');
            elevation_base_label = strrep(elevation_base_label, 'SWL','Elevation');
            % Datum Offset Is Subtracted From SWL And Crest Below: Reflect It In The Label
            labels.lake_level = mean_lake_level(self.config);
            labels.elevation_offset = datum_offset;
            if sel.lake_removed
                labels.elevation_offset = datum_offset + labels.lake_level;
            end
            labels.elevation_label = self.offset_elevation_label(elevation_base_label, labels.elevation_offset);
            labels.x_label = ser.x_label;
            if isempty(labels.x_label)
                switch ser.x_kind
                    case 'event'
                        labels.x_label = 'Event #';
                    case 'hours'
                        labels.x_label = 'Storm Duration [hrs]';
                    otherwise
                        labels.x_label = 'Date';
                end
            end
            % Define Title
            title_label = [{['PSE ID: ' self.config.struc_id ' | Alternative ID: ' self.config.case_name]};...
                {['CHS Region: ' self.config.region ' | Savepoint: ' num2str(self.config.sp_ID) ' | Event: ' ser.event_str]}];
            labels.title = strrep(title_label, '_', ' ');
        end

        function label_out = offset_elevation_label(self, base_label, offset)
            % Elevation Label With The Offset Next To The Project Datum (e.g. [IGLD85 - 176.45])
            label_out = base_label;
            if offset ~= 0
                offset_sign = '-';
                if offset < 0
                    offset_sign = '+';
                end
                label_out = strrep(label_out, [self.config.project_datum ']'],...
                    sprintf('%s %s %g]', self.config.project_datum, offset_sign, abs(offset)));
            end
        end

        function event_view = event_viewer_view(~, ser, response_log)
            % What The Viewer Draws: segs, xg (Gapped X), tip_ids, is_peaks, has_resp_line, has_overlay, has_resp_data
            % Storm Segments (Rows Of One Storm Each): Lines Break Between Storms (NaN Gap), Storm ID Data Tips Per Row
            event_view.is_peaks = strcmp(ser.x_kind, 'event');
            event_view.segs = ser.segments;
            event_view.xg = CHESSPlotsBase.gapped(ser.x, event_view.segs);
            event_view.tip_ids = [];
            if numel(ser.storm_ids) == numel(ser.x) && (event_view.is_peaks || numel(ser.x) > 1)
                event_view.tip_ids = CHESSPlotsBase.gapped(ser.storm_ids, event_view.segs);
            end

            % No Data: Empty, Or No Finite Non-Zero (Positive On A Log Axis) Values; Overlay Lines Count As Data
            resp_signal = ser.resp;
            if response_log == 1
                event_view.has_resp_line = any(isfinite(resp_signal(:)) & resp_signal(:) > 0);
            else
                event_view.has_resp_line = any(isfinite(resp_signal(:)) & resp_signal(:) ~= 0);
            end
            event_view.has_overlay = ~isempty(ser.overlay);
            event_view.has_resp_data = event_view.has_resp_line || event_view.has_overlay;
        end

        function plot_event_forcing(self, ax, fig, ser, event_view, sel, labels, emit)
            % Plots: Top Axes (Elevations Shifted By The Datum Offset, Mean Lake Level When Removed)
            %   emit(field, value): The Viewer's Selection Callback (Lake Level Context Menu)
            hm0_off_label = 'Hm0 (offshore)';
            if isfield(self.config, 'multiline') && isstruct(self.config.multiline) % Multi-Line Stage 2: Saved Forcing Is Already Transmitted
                hm0_off_label = ['Hm0 (offshore, behind ' strrep(self.config.multiline.stage1_alt, '_', '\_') ')']; % Legend: TeX
            end
            CHESSPlotsBase.add_series(ax, ser.swl - labels.elevation_offset, [1 0 0], false, true, 'SWL', event_view);
            yline(ax, self.structure.crest_elevation - labels.elevation_offset, '--c','LineWidth', 1.2,'DisplayName','PSE Crest');
            CHESSPlotsBase.add_series(ax, ser.hm0_off, [0 0 0], true, false, hm0_off_label, event_view);
            CHESSPlotsBase.add_series(ax, ser.hm0_toe, [0 0 0], false, true, 'Hm0 (at toe)', event_view);
            CHESSPlotsBase.add_series(ax, ser.h, [0 0 1], true, false, 'h', event_view);
            if ~isempty(ser.hb)
                CHESSPlotsBase.add_series(ax, ser.hb, [1 0 1], true, false, 'h (berm)', event_view);
            end
            CHESSPlotsBase.add_series(ax, ser.rc, [0 1 0], false, true, 'Freeboard (Rc)', event_view);
            lg = legend(ax, 'Location', 'northoutside','Orientation','horizontal','NumColumns',7);
            lg.ItemHitFcn = @CHESSPlotsBase.toggle_legend_line;
            % Mean Lake Level Option (Regions With A Mean Lake Level Only)
            if labels.lake_level ~= 0
                lake_menu = uicontextmenu(fig);
                uimenu(lake_menu, 'Text', 'Remove mean lake level from SWL & Crest', ...
                    'Checked', aux_methods.tern(sel.lake_removed, 'on', 'off'), 'MenuSelectedFcn', @(~, ~) emit('lake_removed', ~sel.lake_removed));
                ax.ContextMenu = lake_menu;
                ax.DeleteFcn = @(~, ~) delete(lake_menu);
                set(ax.Children, 'ContextMenu', lake_menu);
            end
        end

        function plot_event_response(self, ax2, ser, event_view)
            % Bottom Axes: Response (Markers, One Line, Or One Color Per Storm) And Overlay Lines (Horizontal)
            x = ser.x;
            segs = event_view.segs;
            resp_signal = ser.resp;
            if ~event_view.has_resp_data
                aux_methods.display_no_data(ax2, self.base_fnt);
            else
                if event_view.is_peaks && event_view.has_resp_line
                    resp_line = plot(ax2, event_view.xg, resp_signal, 'ok', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
                    CHESSPlotsBase.add_tips(resp_line, event_view.tip_ids, event_view.is_peaks);
                elseif ser.color_segments && ~isempty(segs) && event_view.has_resp_line
                    palette = lines(7);
                    for ss = 1:numel(segs)
                        rows = segs{ss};
                        resp_line = plot(ax2, x(rows), resp_signal(rows), '-', 'LineWidth', 1.2, 'Color', palette(mod(ss - 1, 7) + 1, :));
                        if ~isempty(event_view.tip_ids)
                            CHESSPlotsBase.add_tips(resp_line, ser.storm_ids(rows), event_view.is_peaks);
                        end
                    end
                elseif event_view.has_resp_line
                    resp_line = plot(ax2, event_view.xg, CHESSPlotsBase.gapped(resp_signal, segs), '-k','LineWidth', 1.2);
                    CHESSPlotsBase.add_tips(resp_line, event_view.tip_ids, event_view.is_peaks);
                end
                if event_view.has_overlay
                    if ~event_view.has_resp_line % Empty Line Gives This Axes The Type Of The Forcing X Axis (Link)
                        plot(ax2, event_view.xg, NaN(size(event_view.xg)), 'HandleVisibility', 'off');
                    end
                    for ss = 1:numel(ser.overlay)
                        yline(ax2, ser.overlay(ss).y, '-', ser.overlay(ss).label, 'Color', ser.overlay(ss).color, 'LineWidth', 1.5, ...
                            'LabelHorizontalAlignment', 'left', 'FontWeight', 'bold');
                    end
                    if ~event_view.has_resp_line
                        aux_methods.pad_limits(ax2, 'Y', [ser.overlay.y]);
                    end
                end
            end
        end

        function finish_event_axes(~, ax, ax2, ser, event_view)
            % Shared X Limits And Link, Storm Start/End Lines And Custom X Ticks (e.g. Simulation Years)
            x = ser.x;
            if numel(x) > 1 && max(x) > min(x)
                ax.XLim = [min(x) max(x)];
                if event_view.has_resp_data
                    ax2.XLim = [min(x) max(x)];
                end
            end
            if event_view.has_resp_data % No Data: ax2 Keeps Numeric Limits, Cannot Link To A Datetime Axis
                linkaxes([ax,ax2],'x');
            end
            axes_drawn = ax;
            if event_view.has_resp_data
                axes_drawn = [ax, ax2];
            end
            for a = axes_drawn
                if ~isempty(ser.bounds)
                    xline(a, ser.bounds(:), '-', 'Color', [0.65 0.65 0.65], 'LineWidth', 0.5, 'HandleVisibility', 'off');
                end
                if ~isempty(ser.xticks)
                    a.XTick = ser.xticks.pos;
                    a.XTickLabel = ser.xticks.labels;
                end
            end
        end
    end

    methods (Static, Access=protected)
        function v = gapped(v, segs)
            % Segments Joined With A NaN Between Them (One Line Object, Broken Between Storms)
            if isempty(segs)
                return
            end
            v = v(:);
            parts = cellfun(@(r) [v(r); NaN], segs(:), 'un', false);
            v = vertcat(parts{:});
        end

        function ln = add_series(a, y, color, dashed, filled, name, event_view)
            y = CHESSPlotsBase.gapped(y, event_view.segs);
            if event_view.is_peaks % Markers Only, Storm ID In The Data Tip (Open Markers = Dashed Lines Of The Timeseries View)
                ln = plot(a, event_view.xg, y, 'o', 'Color', color, 'MarkerSize', 5, 'DisplayName', name);
                if filled
                    ln.MarkerFaceColor = color;
                end
            else
                ln = plot(a, event_view.xg, y, 'Color', color, 'LineStyle', aux_methods.tern(dashed, '--', '-'), 'LineWidth', 1.2, 'DisplayName', name);
            end
            CHESSPlotsBase.add_tips(ln, event_view.tip_ids, event_view.is_peaks);
        end

        function add_tips(ln, ids, is_peaks)
            % Storm ID Data Tip: Replaces The X Row Of Event Markers, Added After The Others On Lines
            if isempty(ids)
                return
            end
            tip_row = dataTipTextRow('Storm ID', ids);
            if is_peaks
                ln.DataTipTemplate.DataTipRows(1) = tip_row;
            else
                ln.DataTipTemplate.DataTipRows(end+1) = tip_row;
            end
        end

        % --- Callback Function ---
        function toggle_legend_line(~, event)
            % event.Peer is the specific line object associated with the clicked legend text
            if strcmp(event.Peer.Visible, 'on')
                event.Peer.Visible = 'off'; % Hide the line
            else
                event.Peer.Visible = 'on';  % Show the line
            end
        end
    end

    %% EVENT TABLE HELPERS (STORM EVENT VIEWER / RESPONSE TABLE)
    properties (Constant, Access=protected)
        % Datum-Referenced Elevations (Left yyaxis On Hydrographs)
        elevation_fields = response_registry('output', 'names', 'datum_elevation', true)
        % Table Columns That Identify Rows (Never Plotted)
        table_id_cols = {'StormID', 'Time', 'Year', 'Order'}
    end

    methods (Access=protected)
        function hb = berm_depth(self, swl)
            % Water Depth At The Toe Berm ([] Without A Berm)
            hb = [];
            if self.config.add_toe_berm == 1
                hb = swl - self.structure.berm_crest_elevation;
            end
        end

        function [lbl, unit, is_log] = field_info(self, field)
            [~, ~, ~, unit, ~, lbl, is_log] = response_library_headers(self.config, self.base_field(field));
            if strcmp(lbl, 'nan'), lbl = strrep(field, '_', ' '); unit = ''; end
        end

        function unit = field_unit(self, field)
            [~, unit] = self.field_info(field);
        end

        function name = column_name(self, field)
            if any(strcmp(field, self.table_id_cols)), name = field; return, end
            unit = strrep(strrep(self.field_unit(field), '$', ''), '^3', char(179));
            name = aux_methods.tern(isempty(unit), field, [field ' [' unit ']']);
        end

        function name = base_field(~, field)
            % Hazard Curve Value Columns Of The PROS-FB Table (<response>_BE, <response>_CL90): The Response They Belong To
            name = regexprep(field, '_(BE|CL\d+)$', '');
        end
    end

    methods (Access=public)
        function [gl, subplot_flag] = subplot_manager(self, parent, nRows, nCols)
            % subplot_manager  Grid or tiled layout for a multi-panel plot.
            %   [gl, subplot_flag] = subplot_manager(self, parent, nRows, nCols)
            %
            %   Inputs:
            %     parent - uiaxes (replaced by a grid in its parent, the
            %              axes moved to cell 1, 1), uifigure (new grid),
            %              uigridlayout (resized and reused), classic figure
            %              or axes (tiled layout), or [] (new uifigure with
            %              a grid)
            %     nRows  - number of rows
            %     nCols  - number of columns
            %   Outputs:
            %     gl           - uigridlayout, or for classic figures / axes
            %                    an nRows*nCols x 1 array of the tile axes
            %                    (Tag 'row_col')
            %     subplot_flag - true when gl holds tile axes

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

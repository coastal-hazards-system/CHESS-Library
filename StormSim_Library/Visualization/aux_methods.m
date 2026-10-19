classdef aux_methods
    % AUX_METHODS Shared plotting utilities.
    % All methods are Static — you never create an aux_methods object.
    % Call them directly: aux_methods.initiate_axes(...)
    %
    % These are called by pros_methods (and future lcs_methods, etc.)
    % NOT by StormsimPlots directly.

    methods (Static)

        function data_out = pull_data(query_names, ds)
            % ds: Can be StormSim variable: Resp, storm, project_forcing
            % query_names: structure containing the following fields
            %   - storm_type: 'XC', 'TC' or 'CC'
            %   - data_type: 'Peaks' or 'Timeseries'
            %   - match_type: 'Default', 'WLP' or 'WHP'
            storm_type=query_names.storm_type;
            data_type=query_names.data_type;
            % Exception cases
            switch query_names.data_type
                case 'Timeseries'
                    % No WLP, WHP Datasets For Timeseries
                    match_type = 'Default';
                otherwise
                    match_type = query_names.match_type;
            end
            % Determine Data Architecture
            lvl_0 = fieldnames(ds);
            try
                % Pull Data From Nested Layers
                if any(ismember(lvl_0, {'XC','TC','CC'})) % storm Storing Method
                    data_out = ds.(storm_type).(data_type).(match_type);
                else % Resp, Project_forcing
                    data_out = ds.(data_type).(match_type).(storm_type);
                end
            catch ME
                error(ME.message)
            end
        end

        function ax = initiate_axes(parent, x_label, y_label, title_str, base_fnt, varargin)
            % initiate_axes Initializes and formats a uiaxes object for StormSim plots.
            %
            % Inputs:
            %   parent    - Parent container (uifigure or uigridlayout) or an existing uiaxes handle.
            %   x_label   - String or cell array for the X-axis label.
            %   y_label   - String or cell array for the Y-axis label.
            %   title_str - String or cell array for the plot title.
            %   base_fnt  - Base font size for the title (labels and ticks are scaled relative to this).
            %   row       - (Optional) Grid row for the axes layout.
            %   col       - (Optional) Grid column for the axes layout.

            % Parse Optional Inputs 
            if length(varargin)==2
                row = varargin{1};
                col = varargin{2};
            else
                row = [];
                col = [];
            end

            % Initialize Parent Container If Needed 
            if isempty(parent) || ~isvalid(parent)
                % Default TO GridLayout
                fig = uifigure('Name', 'StormSim Figure', 'Position', [100 100 1000 600]);
                % Create the nested-style 1x2 grid we've been using
                parent = uigridlayout(fig, [1 1]);
                parent.ColumnWidth = {'1x'}; % Dedicated Colorbar Column
                parent.Padding = [10 10 10 10];
            end

            % Define Fonts
            ax_label_fnt = base_fnt;
            ax_tick_fnt = ax_label_fnt - 2;

            % Initialize Axes Handle
            switch class(parent)
                case {'matlab.ui.control.UIAxes', 'matlab.graphics.axis.Axes'}
                    ax = parent;
                    parent = ax.Parent;
                case 'matlab.ui.Figure'
                    if strcmp(parent.HandleVisibility,'off') % UIFigure
                        ax = uiaxes(parent);
                    else % Classic FIgure
                        ax = axes(parent);
                    end
                case 'matlab.ui.container.GridLayout'
                    ax = uiaxes(parent);
                    if ~isempty(row) && ~isempty(col)
                        ax.Layout.Row = row;
                        ax.Layout.Column = col;
                    else
                        ax.Layout.Row = 1;
                        ax.Layout.Column = 1;
                    end
            end
            
            % Clear Axes
            cla(ax);

            % Define Axis Properties
            set(ax, 'XScale', 'linear', 'YScale', 'linear', 'XGrid', 'on', 'XMinorTick', 'on', ...
                'YGrid', 'on', 'YMinorTick', 'on', 'FontSize', ax_tick_fnt, 'FontWeight', 'bold');

            % Hold Axis Properties
            hold(ax, 'on');

            % Enable Box
            box(ax, 'on');

            % Define Figure Title
            title(ax, aux_methods.latex_escape(title_str), 'FontSize', base_fnt + 2, 'FontWeight', 'bold', 'Interpreter', 'latex');

            % Define X Label
            xlabel(ax, aux_methods.latex_escape(x_label), 'FontSize', ax_label_fnt, 'FontWeight', 'bold', 'Interpreter', 'latex');

            % Define Y Label
            ylabel(ax, aux_methods.latex_escape(y_label), 'FontSize', ax_label_fnt, 'FontWeight', 'bold', 'Interpreter', 'latex');
            
            ax.Tag = 'stormsim_fig';
        end

        function out = latex_escape(str)
            % LATEX_ESCAPE Display String Valid For The LaTeX Interpreter (Titles / Axis Labels Only; Never Field Names).
            %   Outside $...$ math segments: # % & _ escaped, ^ -> \^{}, a lone \ -> \textbackslash{}; an unpaired $ is
            %   escaped. Math segments, \-commands and already escaped characters (\%, \_) are kept, so mixed labels
            %   (e.g. response_library_headers.m: '$R_{2\%}$ [m]') pass unchanged and escaping twice changes nothing.
            %   Accepts char, string or cell arrays of them (same shape out); other types are returned as given.
            if iscell(str)
                out = cellfun(@aux_methods.latex_escape, str, 'un', false);
                return
            end
            if isstring(str)
                out = str;
                for kk = 1:numel(str)
                    out(kk) = string(aux_methods.latex_escape(char(str(kk))));
                end
                return
            end
            if ~ischar(str) || isempty(str)
                out = str;
                return
            end
            n = numel(str);
            prev = [' ', str(1:end-1)];
            dollars = find(str == '$' & prev ~= '\');
            is_math = false(1, n);
            if mod(numel(dollars), 2) == 0
                for dd = 1:2:numel(dollars)
                    is_math(dollars(dd):dollars(dd+1)) = true;
                end
            end
            out = '';
            kk = 1;
            while kk <= n
                c = str(kk);
                if is_math(kk)
                    out = [out c]; %#ok<AGROW>
                elseif c == '\' && kk < n
                    out = [out str(kk:kk+1)]; %#ok<AGROW>
                    kk = kk + 1;
                elseif c == '\'
                    out = [out '\textbackslash{}']; %#ok<AGROW>
                elseif any(c == '#%&_$')
                    out = [out '\' c]; %#ok<AGROW>
                elseif c == '^'
                    out = [out '\^{}']; %#ok<AGROW>
                else
                    out = [out c]; %#ok<AGROW>
                end
                kk = kk + 1;
            end
        end

        function display_no_data(ax, base_fnt, msg)
            % Puts a red "No data available" (or msg) label at the centre of ax.
            if nargin < 3, msg = 'No data available'; end
            text(ax, 0.5, 0.5, msg, ...
                'Units',               'normalized', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment',   'middle', ...
                'Color',               'red', ...
                'FontSize',            base_fnt, ...
                'BackgroundColor',     'white', ...
                'EdgeColor',           'red');
        end

        function pad_limits(ax, which, data, frac)
            % PAD_LIMITS Sets ax X/Y limits to the data range plus a buffer, so points never sit on the axis edge.
            %   which: 'X' or 'Y'. data: values plotted on that axis. frac: buffer per side (default 0.05).
            %   Log axes are padded in decades; a flat signal gets +/-5% of its magnitude (or +/-0.05 if zero).
            if nargin < 4, frac = 0.05; end
            data = data(isfinite(data));
            is_log = strcmp(ax.([which 'Scale']), 'log');
            if is_log, data = log10(data(data > 0)); end
            if isempty(data), return, end
            lo = min(data); hi = max(data); rng = hi - lo;
            if rng == 0
                rng = max(abs(lo), 1) * 0.1;
                lo = lo - rng/2; hi = hi + rng/2;
            end
            lim = [lo - frac*rng, hi + frac*rng];
            if is_log, lim = 10.^lim; end
            ax.([which 'Lim']) = lim;
        end

        function out = tern(cond, a, b)
            % TERN Ternary helper: returns a if cond is true, else b.
            if cond
                out = a;
            else
                out = b;
            end
        end

        function unitLib = build_unit_library(unit_system)
            switch unit_system
                case 'SI'
                    % Define Conversion Factors For Fundamental Units
                    unitLib.conversionCoeffs.length = 3.2808399;% m to ft
                    unitLib.conversionCoeffs.mass = 2.20462262;% kg to lbm
                    unitLib.conversionCoeffs.density = unitLib.conversionCoeffs.mass/(unitLib.conversionCoeffs.length^3);% kg/m^3 to lbm/ft^3
                    unitLib.conversionCoeffs.force = 0.22480894;% N to lbf
                    unitLib.conversionCoeffs.pressure = 0.00014504;% Pa to Psi
                    % Define Symmbols For Fundamental Units
                    unitLib.unitSymbols.length = 'm';% m to ft
                    unitLib.unitSymbols.mass = 'Kg';% kg to lbm
                    unitLib.unitSymbols.density = 'Kg/m^3';% kg/m^3 to lbm/ft^3
                    unitLib.unitSymbols.force = 'N';% N to lbf
                    unitLib.unitSymbols.pressure = 'Pa';% Pa to Psi
                case 'Imperial'
                    % Initialize Unit Conversion Factors
                    unitLib.conversionCoeffs.length = 1/3.2808399;% ft to m
                    unitLib.conversionCoeffs.mass = 1/2.20462262;% lbm to Kg
                    unitLib.conversionCoeffs.density = unitLib.conversionCoeffs.mass/(unitLib.conversionCoeffs.length^3);% lbm/ft^3 to kg/m^3
                    unitLib.conversionCoeffs.force = 1/0.22480894;% lbf to N
                    unitLib.conversionCoeffs.pressure = 1/0.00014504;% Psi to Pa
                    % Define Symmbols For Fundamental Units
                    unitLib.unitSymbols.length = 'ft';% m to ft
                    unitLib.unitSymbols.mass = 'lb';% kg to lbm
                    unitLib.unitSymbols.density = 'lb/m^3';% kg/m^3 to lbm/ft^3
                    unitLib.unitSymbols.force = 'lb_f';% N to lbf
                    unitLib.unitSymbols.pressure = 'Psi';% Pa to Psi
                otherwise 
                    error('Unsupported unit system. Please use ''SI'' or ''Imperial''');
            end
        end
    
    end
end

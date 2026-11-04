classdef aux_methods
    % aux_methods  Static plotting helpers shared by the CHESS plot classes.
    %   aux_methods holds Static methods only; no object is created. Call
    %   them on the class name, e.g.
    %     ax = aux_methods.initiate_axes(parent, x_label, y_label, title_str, base_fnt)
    %   Used by CHESSPlotsBase, det_methods, lcs_methods, pros_methods and
    %   the GUI (chessResults, chessRunPlanner, the app); CHESSPlots does
    %   not call them.
    %
    %   Methods:
    %     pull_data          - one dataset of a storm, Resp or project_forcing struct
    %     initiate_axes      - create or reset axes formatted for a CHESS plot
    %     latex_escape       - escape text for the LaTeX interpreter
    %     display_no_data    - red "No data available" note centred on axes
    %     pad_limits         - axis limits = data range plus a buffer
    %     tern               - ternary helper (a if cond, else b)
    %
    %   Tier: internal
    %
    %   See also CHESSPlots, CHESSPlotsBase, det_methods, lcs_methods,
    %   pros_methods.

    methods (Static)

        function data_out = pull_data(query_names, ds)
            % pull_data  Return one dataset of a storm, Resp or project_forcing struct.
            %   data_out = aux_methods.pull_data(query_names, ds)
            %
            %   Inputs:
            %     query_names - struct with fields storm_type ('XC', 'TC' or
            %                   'CC'), data_type ('Peaks' or 'Timeseries') and
            %                   match_type ('Default', 'WLP' or 'WHP';
            %                   Timeseries always uses 'Default')
            %     ds          - storm database "storm"
            %                   (ds.<storm_type>.<data_type>.<match_type>), or
            %                   Resp / project_forcing
            %                   (ds.<data_type>.<match_type>.<storm_type>)
            %   Outputs:
            %     data_out - the requested dataset; a missing level errors
            %                with the original message

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
            % initiate_axes  Create or reset axes formatted for a CHESS plot.
            %   ax = aux_methods.initiate_axes(parent, x_label, y_label, title_str, base_fnt)
            %   ax = aux_methods.initiate_axes(parent, x_label, y_label, title_str, base_fnt, row, col)
            %       clears the axes, turns grids, minor ticks, box and hold
            %       on, and writes the title and labels with the LaTeX
            %       interpreter (latex_escape). ax.Tag is 'chess_fig'.
            %
            %   Inputs:
            %     parent    - existing axes or uiaxes (reused), uifigure or
            %                 classic figure (new axes), uigridlayout (new
            %                 uiaxes at row, col), or [] / deleted handle (new
            %                 uifigure with a 1 x 1 grid)
            %     x_label   - X-axis label, char, string or cell array
            %     y_label   - Y-axis label, char, string or cell array
            %     title_str - plot title, char, string or cell array
            %     base_fnt  - base font size [pt]: labels base_fnt, title
            %                 base_fnt + 2, ticks base_fnt - 2
            %     row, col  - (optional, both or neither) grid row and column
            %                 when parent is a uigridlayout (default 1, 1)
            %   Outputs:
            %     ax - the formatted axes

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
                fig = uifigure('Name', 'CHESS Figure', 'Position', [100 100 1000 600]);
                % 1 x 1 Grid Holding The New Axes
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
            
            ax.Tag = 'chess_fig';
        end

        function out = latex_escape(str)
            % latex_escape  Escape text for the LaTeX interpreter (titles and axis labels).
            %   out = aux_methods.latex_escape(str)
            %
            %   For titles and axis labels only, never for field names.
            %   Outside $...$ math segments: # % & _ are escaped, ^ ->
            %   \^{}, a lone \ -> \textbackslash{}, | -> $|$ (text-mode |
            %   renders as an em dash in the LaTeX OT1 font); an unpaired $
            %   is escaped. Math segments, \-commands and already escaped
            %   characters (\%, \_) are kept, so mixed labels (e.g.
            %   response_library_headers: '$R_{2\%}$ [m]') pass unchanged
            %   and escaping twice changes nothing.
            %
            %   Inputs:
            %     str - char, string or cell array of them; other types
            %           are returned as given
            %   Outputs:
            %     out - escaped text, same class and shape as str

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
                elseif c == '|'
                    out = [out '$|$']; %#ok<AGROW>
                else
                    out = [out c]; %#ok<AGROW>
                end
                kk = kk + 1;
            end
        end

        function display_no_data(ax, base_fnt, msg)
            % display_no_data  Write a red "No data available" note at the centre of axes.
            %   aux_methods.display_no_data(ax, base_fnt)
            %   aux_methods.display_no_data(ax, base_fnt, msg)
            %
            %   Inputs:
            %     ax       - target axes
            %     base_fnt - font size of the note [pt]
            %     msg      - (optional) note text (default 'No data available')


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
            % pad_limits  Set axis limits to the data range plus a buffer.
            %   aux_methods.pad_limits(ax, which, data)
            %   aux_methods.pad_limits(ax, which, data, frac) sets the X or
            %       Y limits of ax so plotted points never sit on the axis
            %       edge. Log axes are padded in decades; a flat signal
            %       gets +/-5% of its magnitude (or +/-0.05 if zero). No
            %       finite data (positive on log axes): limits unchanged.
            %
            %   Inputs:
            %     ax    - target axes
            %     which - 'X' or 'Y'
            %     data  - values plotted on that axis
            %     frac  - (optional) buffer per side as a fraction of the
            %             range (default 0.05)

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
            % tern  Ternary helper: return a if cond is true, else b.
            %   out = aux_methods.tern(cond, a, b)
            %
            %   Inputs:
            %     cond - logical scalar
            %     a, b - values returned when cond is true or false
            %   Outputs:
            %     out - a or b

            if cond
                out = a;
            else
                out = b;
            end
        end
    end
end

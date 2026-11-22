classdef chessProjectView
    % CHESS GUI Views Of A Project (chess.Project): What The GUI Shows Of An Alternative That The Library Record Does Not Hold.
    %   The Record Keeps The Inputs Of An Alternative (Struct) And Its Structure Type; Here:
    %     PSE Table      {Symbol, Description, Units, Value} Rows Of The Inputs, From The Library Template (input_table,
    %                    table_inputs, template_rows)
    %     Geometry       The Structure Of An Alternative Or Of A PSE Table As A Struct With The GUI Fields pse_type And
    %                    add_toe_berm (geometry, table_geometry)
    %     Transect Plots Library Transect Plot Of An Alternative, A Structure Or A Multi-Line Transect (plot_geometry,
    %                    plot_structure, plot_multiline)
    %     Units          Unit Labels And Values Of The PSE Table In The Project Unit System (convert_rows)
    %   Static Helpers, No State. proj: chess.Project

    properties (Constant)
        PSE_TYPES = {'Levee', 'Floodwall', 'Rubble Mound'} % PSE Type Names By Library Structure Type (1, 2, 3)
    end

    %% PSE TYPE, TEMPLATE, PSE TABLE, GEOMETRY
    methods (Static)
        function structure_type = structure_type(pse_type)
            % Library Structure Type (1 Levee, 2 Floodwall, 3 Rubble Mound) Of A PSE Type Name (A Number Is Returned As Is)
            if isnumeric(pse_type)
                structure_type = pse_type;
                return
            end
            switch pse_type
                case 'Levee'
                    structure_type = 1;
                case {'Floodwall', 'Vertical Wall'}
                    structure_type = 2;
                case 'Rubble Mound'
                    structure_type = 3;
                otherwise
                    error('Unsupported PSE type "%s".', pse_type);
            end
        end

        function pse_type = pse_type(structure_type)
            % PSE Type Name Of A Library Structure Type
            pse_type = chessProjectView.PSE_TYPES{structure_type};
        end

        function tpl = template(pse_type)
            % Library Input Template Of A PSE Type (Name Or Structure Type Number): chess.Project.structure_template
            tpl = chess.Project.structure_template(chessProjectView.structure_type(pse_type));
        end

        function [rows, berm_rows, berm_allowed, berm_default] = template_rows(pse_type, unit_system)
            % PSE Table Rows Of A New Alternative: Template Geometry + Properties, Without The add_toe_berm Row And The Berm
            % Rows (berm_rows: Added When A Berm Is Requested; berm_allowed: The Template Has The Switch And The Type Takes
            % A Berm; berm_default: Template Switch Value). Template Values Are SI: Dimensional Inputs Converted For An
            % Imperial Project (convert_rows)
            tpl = chessProjectView.template(pse_type);
            rows = [tpl.geometry; tpl.properties];
            berm_indx = strcmp(rows(:, 1), 'add_toe_berm');
            berm_allowed = any(berm_indx) && chessProjectView.structure_type(pse_type) ~= 2;
            berm_default = berm_allowed && isequal(rows{berm_indx, 4}, 1);
            rows(berm_indx, :) = [];
            is_berm = startsWith(rows(:, 1), 'berm_');
            berm_rows = rows(is_berm & berm_allowed, :);
            rows(is_berm, :) = [];
            if strcmp(unit_system, 'Imperial')
                rows = chessProjectView.convert_rows(rows, unit_system);
                berm_rows = chessProjectView.convert_rows(berm_rows, unit_system);
            end
        end

        function tbl = input_table(proj, pse_name, alt_name)
            % PSE Table Of An Alternative: Its Inputs As {Symbol, Description, Units, Value} Rows In Template Order
            % (Description And Units From The Template; Inputs The Template Does Not List Go Last, Without Them). Template
            % Rows The Alternative Has No Input For Are Left Out. Unknown Names: 0 x 4
            tbl = cell(0, 4);
            if ~proj.has_alternative(pse_name, alt_name)
                return
            end
            record = proj.alternative(pse_name, alt_name);
            tpl = chessProjectView.template(record.structure_type);
            rows = [tpl.geometry; tpl.properties];
            if strcmp(proj.unit_system, 'Imperial')
                rows = chessProjectView.convert_rows(rows, proj.unit_system, false);
            end
            names = fieldnames(record.inputs);
            [listed, at] = ismember(names, rows(:, 1));
            [~, order] = sort(at(listed));
            listed_names = names(listed);
            listed_names = listed_names(order);
            tbl = rows(sort(at(listed)), :);
            tbl(:, 4) = cellfun(@(name) record.inputs.(name), listed_names, 'un', false);
            for name = names(~listed)'
                tbl(end+1, :) = {name{1}, '', '', record.inputs.(name{1})}; %#ok<AGROW>
            end
        end

        function inputs = table_inputs(tbl)
            % Inputs Of An Alternative (Struct, One Field Per Row) Of A PSE Table
            inputs = cell2struct(tbl(:, 4), tbl(:, 1), 1);
        end

        function geo = geometry(proj, pse_name, alt_name)
            % Structure Of An Alternative (chess.Project.structure, SI) With The GUI Fields pse_type And add_toe_berm.
            % Unknown Names: []
            geo = [];
            if ~proj.has_alternative(pse_name, alt_name)
                return
            end
            geo = proj.structure(pse_name, alt_name);
            geo.add_toe_berm = 0; % Berms Are Not Available (Library Structure Rules)
            geo.pse_type = chessProjectView.pse_type(geo.struc_type);
        end

        function geo = table_geometry(pse_type, tbl, unit_system)
            % Structure (SI) Of A PSE Table In unit_system (Library chess.ProtectionSystem.create; Errors When The Table Does
            % Not Build It), With The GUI Fields pse_type And add_toe_berm
            inputs = chess.Config.to_SI(chessProjectView.table_inputs(tbl), unit_system);
            inputs.struc_type = chessProjectView.structure_type(pse_type);
            inputs.add_toe_berm = 0; % Berms Are Not Available (Library Structure Rules)
            geo = chess.ProtectionSystem.create(inputs).to_struct();
            geo.add_toe_berm = 0;
            geo.pse_type = chessProjectView.pse_type(geo.struc_type);
        end
    end

    %% TRANSECT PLOTS
    methods (Static)
        function ax = plot_geometry(proj, pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source, stage1)
            % Library Transect Plot Of A PSE/Alternative Into ax.
            %   base_fnt: Base Font Size (Default 12, The GUI Plot Font)
            %   keep_text_box: Keep Library Offshore Slope/Elevation Text Box (Default false)
            %   offshore_elevation: Offshore Elevation For The Text Box ([] -> PSE Geometry Value, Else 'n/a')
            %   elevation_source: Label Shown Next To The Elevation (e.g. 'Storm DB: SP123')
            %   stage1: Multi-Line Stage 2 Only. struct: The Stage 1 Structure Drawn In Line Before It (The Saved structure Of
            %       Stage 1's Run Its Forcing Comes From; Never Stage 1's Current Inputs). char: Stage 2 Alone With This Note
            %       (No Text Box). Default []: Stage 2 Alone
            if nargin < 5 || isempty(base_fnt)
                base_fnt = 12;
            end
            if nargin < 6 || isempty(keep_text_box)
                keep_text_box = false;
            end
            if nargin < 7
                offshore_elevation = [];
            end
            if nargin < 8
                elevation_source = '';
            end
            if nargin < 9
                stage1 = [];
            end
            structure = chessProjectView.geometry(proj, pse_name, alt_name);
            if ~isempty(structure) && proj.stage(pse_name, alt_name) == 2
                if isstruct(stage1)
                    ax = chessProjectView.plot_multiline(proj, pse_name, proj.stage1_alternative(pse_name), stage1, alt_name,...
                        structure, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source);
                    return
                end
                % Stage 2 Alone: Its Offshore End Is Stage 1's Toe, Unknown Here (No Text Box)
                ax = chessProjectView.plot_structure(proj, structure, pse_name, alt_name, ax, base_fnt, false, [], '');
                if ischar(stage1) && ~isempty(stage1)
                    text(ax, 0.02, 0.98, stage1, 'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left',...
                        'BackgroundColor', 'white', 'EdgeColor', 'black', 'Interpreter', 'none', 'FontSize', base_fnt - 2,...
                        'Tag', 'stage_note');
                end
                return
            end
            ax = chessProjectView.plot_structure(proj, structure, pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source);
        end

        function ax = plot_multiline(proj, pse_name, stage1_alt, stage1_structure, stage2_alt, stage2_structure, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source)
            % Multi-Line Transect Into ax: Stage 1 (stage1_structure; Text Box = Its Offshore End, plot_geometry Inputs), Then
            % Stage 2 (stage2_structure) To Its Right After A Display Gap (The Stages Have No Distance Between Them In The
            % Analysis), Joined By A Sand Strip Between The Drawn Sand Tops (Library pse_transect_plot: Every Profile Starts On
            % Its Sand Top, At toe_elevation; A Floodwall Without A Toe Berm Has toe_elevation = wall_bottom_elevation).
            % Also Used By PSECreationUI For A Stage 2 Being Created (stage2_alt = Its Placeholder Name)
            if nargin < 8 || isempty(base_fnt)
                base_fnt = 12;
            end
            if nargin < 9 || isempty(keep_text_box)
                keep_text_box = false;
            end
            if nargin < 10
                offshore_elevation = [];
            end
            if nargin < 11
                elevation_source = '';
            end
            ax = chessProjectView.plot_structure(proj, stage1_structure, pse_name, stage1_alt, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source);
            s2 = stage2_structure;
            sand1 = findobj(ax.Children, 'flat', 'Tag', 'sand');
            if isempty(s2) || ~isfield(s2, 'struc_type') || isempty(sand1)
                return
            end
            fig = figure('Visible', 'off');
            closer = onCleanup(@() delete(fig));
            ax2 = chessProjectView.plot_structure(proj, s2, pse_name, stage2_alt, axes(fig), base_fnt, false, [], '');
            sand2 = findobj(ax2.Children, 'flat', 'Tag', 'sand');
            [x1, x2] = deal(ax.XLim(2), ax2.XLim(2));
            dx = x1 + 0.25*max(x1, x2); % Display Gap Only
            [b1, b2] = deal(min(sand1.Shape.Vertices(:, 2)), min(sand2.Shape.Vertices(:, 2)));
            [t1, t2] = deal(max(sand1.Shape.Vertices(:, 2)), max(sand2.Shape.Vertices(:, 2)));
            plot(ax, polyshape([x1 dx dx x1], [t1 t2 b2 b1]), 'FaceColor', [0.92,0.82,0.08],...
                'EdgeColor', 'none', 'FaceAlpha', 1, 'Tag', 'sand');
            for h = flipud(findobj(ax2.Children, 'flat', 'Type', 'polygon'))'
                hn = copyobj(h, ax);
                hn.Shape = translate(hn.Shape, dx, 0);
            end
            for lbl = {x1/2, stage1_alt, b1; dx + x2/2, stage2_alt, b2}'
                text(ax, lbl{1}, lbl{3}, lbl{2}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom',...
                    'Interpreter', 'none', 'FontSize', base_fnt - 2, 'Tag', 'stage_label');
            end
            text_box = findobj(ax.Children, 'flat', 'Type', 'text', '-not', 'Tag', 'stage_label');
            if ~isempty(text_box)
                uistack(text_box, 'top');
            end
            xlim(ax, [0, dx + x2]);
            ylim(ax, [min(ax.YLim(1), ax2.YLim(1)), max(ax.YLim(2), ax2.YLim(2))]);
            ax.Title.String = ['PSE ID: ' pse_name ' | Multi-Line: ' stage1_alt ' -> ' stage2_alt];
        end

        function ax = plot_structure(proj, structure, pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source)
            % One Transect (structure: A geometry / table_geometry Struct Or A Saved Run structure, SI) Into ax; Names For The
            % Title (plot_geometry Inputs; offshore_elevation SI). The Plot Shows The Project Unit System
            if nargin < 6 || isempty(base_fnt)
                base_fnt = 12;
            end
            if nargin < 7 || isempty(keep_text_box)
                keep_text_box = false;
            end
            if nargin < 8
                offshore_elevation = [];
            end
            if nargin < 9
                elevation_source = '';
            end
            cla(ax);
            % Nothing To Plot
            if isempty(structure) || ~isfield(structure, 'struc_type')
                return
            end
            % Minimal Plot Config (Structure Step, No Workflow); Offshore Elevation Goes With The Structure, As In A Run:
            % The Given Value, Else The PSE Geometry Value. Berms Are Not Available (Library Structure Rules)
            config = struct('project_datum', proj.vertical_datum,...
                'struc_id', pse_name,...
                'case_name', alt_name,...
                'struc_type', structure.struc_type,...
                'add_toe_berm', 0);
            if ~isempty(offshore_elevation)
                structure.offshore_elevation = offshore_elevation;
                structure.offshore_elevation_source = elevation_source;
            end
            % Library Transect Plot (Base Class: No Workflow Needed)
            chessPlot = chess.Visualization.CHESSPlotsBase(config, [], [], [], [], structure, base_fnt, proj.unit_system);
            ax = chessPlot.pse_transect_plot(ax);
            % Remove Library Annotation Text Box (Offshore Slope/Elevation) Unless Requested
            if ~keep_text_box
                delete(findobj(ax.Children, 'flat', 'Type', 'text'));
            end
        end
    end

    %% UNITS
    methods (Static)
        function rows = convert_rows(rows, unit_system, convert_values)
            % PSE Table Rows In SI -> Project Unit System: The Rows Of Inputs With A Unit (chess.Config.unit_fields) Get The
            % Unit Symbol Of unit_system (chess.Common.chess_units) And, Unless convert_values Is false, Their Value
            % (chess.Config.from_SI)
            if nargin < 3
                convert_values = true;
            end
            sys = chess.Common.chess_units('system', unit_system);
            [names, kinds] = chess.Config.unit_fields();
            [has_unit, at] = ismember(rows(:, 1), names);
            for rr = find(has_unit)'
                rows{rr, 3} = ['[' sys.symbol.(kinds{at(rr)}) ']'];
                if convert_values
                    value = chess.Config.from_SI(struct(rows{rr, 1}, rows{rr, 4}), unit_system);
                    rows{rr, 4} = value.(rows{rr, 1});
                end
            end
        end
    end
end

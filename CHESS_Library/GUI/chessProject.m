classdef chessProject < handle
    %% PROPERTIES
    properties (Access=public)
        name char
        path char
        vdatum char
        CLs double
        unitsys char
        pse_list cell
        alternative_list cell
        % Storm DB Records (Struct Array, CHSStormDBImportUI.to_record): Names, Paths, db_info, Savepoint, layout. Projects Saved
        % With Wizard Objects Are Converted By The Import Sync (sync_sims 'project')
        stormDB_list
        tide_files_list cell
        pse_tables cell
        pse_geometry cell
        % Simulation Registry sims{pse}{alt} (Same Shape As alternative_list): Struct Array, One Row Per (Storm DB, Workflow)
        % Bundle With A Responses File (sim_row_from_config). Names Only, Never Paths (chess_paths)
        sims cell = {}
        sim_record table
        chs_dependencies char = '' % CHS_Dependencies Folder Of The Project Region (project_region), Set By The First CHS Storm DB
        % Multi-Line Transect PSEs (Name Based), One Entry Each: pse, stage1 (Its '<name>_stage_1' Rubble Mound Alternative),
        % stage2 (Column Cell Of Its '<name>_stage_2' Alternatives). A Multi-Line PSE Holds Only These Alternatives
        multiline struct = struct('pse', {}, 'stage1', {}, 'stage2', {})
    end

    properties (Access=public)
        pse_indx
        alt_indx
        db_indx
    end

    %% CONSTRUCTOR
    methods (Access=public)
        function obj = chessProject(name, path, vdatum, CLs, unitsys)
            arguments
                name (1, :) {mustBeText}
                path (1, :) {mustBeText}
                vdatum (1, :) {mustBeText}
                CLs (1, 4) {mustBeNumeric}
                unitsys (1, :) {mustBeText}
            end
            obj.name = name;
            obj.path = path;
            obj.vdatum = vdatum;
            obj.CLs = CLs;
            obj.unitsys = unitsys;
            obj.pse_list = {};
            obj.alternative_list = {};
            obj.pse_tables = {};
            obj.pse_geometry = {};
            obj.stormDB_list = CHSStormDBImportUI.empty_records();
        end
    end

    %% PLOT METHODS
    methods (Access=public)
        function ax = plot_geometry(obj, pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source, stage1)
            % Library Transect Plot Of A PSE/Alternative Into ax.
            %   base_fnt: Base Font Size (Default 12, The GUI Plot Font)
            %   keep_text_box: Keep Library Offshore Slope/Elevation Text Box (Default false)
            %   offshore_elevation: Offshore Elevation For The Text Box ([] -> PSE Geometry Value, Else 'n/a')
            %   elevation_source: Label Shown Next To The Elevation (e.g. 'Storm DB: SP123')
            %   stage1: Multi-Line Stage 2 Only. struct: The Stage 1 Structure Drawn In Line Before It (The Saved structure Of
            %       Stage 1's Run Its Forcing Comes From; Never Stage 1's Current PSE Table). char: Stage 2 Alone With This Note
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
            structure = obj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
            if obj.alt_stage(pse_name, alt_name) == 2
                if isstruct(stage1)
                    ax = obj.plot_multiline(pse_name, obj.stage1_alt(pse_name), stage1, alt_name, ax, base_fnt, keep_text_box,...
                        offshore_elevation, elevation_source);
                    return
                end
                % Stage 2 Alone: Its Offshore End Is Stage 1's Toe, Unknown Here (No Text Box)
                ax = obj.plot_single(structure, pse_name, alt_name, ax, base_fnt, false, [], '');
                if ischar(stage1) && ~isempty(stage1)
                    text(ax, 0.02, 0.98, stage1, 'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left',...
                        'BackgroundColor', 'white', 'EdgeColor', 'black', 'Interpreter', 'none', 'FontSize', base_fnt - 2,...
                        'Tag', 'stage_note');
                end
                return
            end
            ax = obj.plot_single(structure, pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source);
        end

        function ax = plot_multiline(obj, pse_name, stage1_alt, stage1_structure, stage2_alt, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source)
            % Multi-Line Transect Into ax: Stage 1 (stage1_structure; Text Box = Its Offshore End, plot_geometry Inputs), Then
            % Stage 2 (Its Current pse_geometry) To Its Right After A Display Gap (The Stages Have No Distance Between Them In The
            % Analysis), Joined By A Sand Strip Between The Drawn Sand Tops (Library pse_transect_plot: Every Profile Starts On
            % Its Sand Top, At toe_elevation; A Floodwall Without A Toe Berm Has toe_elevation = wall_bottom_elevation,
            % finalize_structure_config). Also Used By PSECreationUI For A Stage 2 Not Yet Linked (stage2_alt = Its Placeholder)
            if nargin < 7 || isempty(base_fnt)
                base_fnt = 12;
            end
            if nargin < 8 || isempty(keep_text_box)
                keep_text_box = false;
            end
            if nargin < 9
                offshore_elevation = [];
            end
            if nargin < 10
                elevation_source = '';
            end
            ax = obj.plot_single(stage1_structure, pse_name, stage1_alt, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source);
            s2 = obj.get_project_field('pse_geometry', pse_name, stage2_alt, 'alt');
            sand1 = findobj(ax.Children, 'flat', 'Tag', 'sand');
            if isempty(s2) || ~isfield(s2, 'struc_type') || isempty(sand1)
                return
            end
            fig = figure('Visible', 'off');
            closer = onCleanup(@() delete(fig));
            ax2 = obj.plot_single(s2, pse_name, stage2_alt, axes(fig), base_fnt, false, [], '');
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
    end

    methods (Access=private)
        function ax = plot_single(obj, structure, pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source)
            % One Transect (structure: A pse_geometry Entry Or A Saved Run structure) Into ax; Names For The Title
            % (plot_geometry Inputs)
            % Clear Axes
            cla(ax);
            % Nothing To Plot
            if isempty(structure)
                return
            end
            % Geometry Created Before Library Schema (No struc_type)
            if ~isfield(structure, 'struc_type')
                title(ax, 'Geometry created with an older GUI version. Recreate this alternative.');
                return
            end
            % Minimal Plot Config (Structure Step, No Workflow); Offshore Elevation Goes With The Structure, As In A Run
            % (Library call_project_response): The Given Value, Else The PSE Geometry Value
            config = struct('project_datum', obj.vdatum,...
                'struc_id', pse_name,...
                'case_name', alt_name,...
                'struc_type', structure.struc_type,...
                'add_toe_berm', structure.add_toe_berm);
            if ~isempty(offshore_elevation)
                structure.offshore_elevation = offshore_elevation;
                structure.offshore_elevation_source = elevation_source;
            end
            % Library Transect Plot (Base Class: No Workflow Needed)
            chessPlot = CHESSPlotsBase(config, [], [], [], [], structure, base_fnt, obj.unitsys);
            ax = chessPlot.pse_transect_plot(ax, []);
            % Remove Library Annotation Text Box (Offshore Slope/Elevation) Unless Requested
            if ~keep_text_box
                delete(findobj(ax.Children, 'flat', 'Type', 'text'));
            end
        end
    end

    %% DATA ACCESS/MANAGEMENT METHODS
    methods (Access=public)
        function set_working_pse(obj, pse_name)
            if isempty(obj.pse_list)
                obj.pse_indx = 1;
            else
                obj.pse_indx = find(strcmp(pse_name, obj.pse_list), 1);
            end
        end

        function set_working_alt(obj, pse_name, alt_name)
            if isempty(alt_name) || isempty(obj.pse_indx) || obj.pse_indx > numel(obj.alternative_list)
                obj.alt_indx = [];
            elseif isempty(obj.alternative_list{obj.pse_indx})
                obj.alt_indx = [];
            else
                list = obj.alternative_list{obj.pse_indx};
                obj.alt_indx = find(strcmp(alt_name, list), 1);
            end
        end

        function set_working_db(obj, db_name)
            list = {obj.stormDB_list.db_name};
            obj.db_indx = find(strcmp(db_name, list), 1);
        end
    end

    methods (Access=public)
        function add_project_field(obj, field, item, pse_name, alt_name, dtype)
            switch dtype
                case 'pse'
                    obj.(field) =  [obj.(field); item];
                case 'alt'
                    set_working_pse(obj, pse_name);
                    set_working_alt(obj, pse_name, alt_name);
                    if isempty(obj.(field))
                        obj.(field) =  {{item}};
                    elseif obj.pse_indx > length(obj.(field)) % Ensures No Indexing Errors
                        obj.(field) = [obj.(field);{{item}}];
                    else
                        obj.(field){obj.pse_indx} =  [obj.(field){obj.pse_indx};item];
                    end
            end
        end

        function set_project_field(obj, field, item, pse_name, alt_name, dtype)
            switch dtype
                case 'db'
                    obj.set_working_db(pse_name);
                    obj.(field)(obj.db_indx) =  item;
                case 'proj'
                    obj.(field) =  item;
                otherwise
                    set_working_pse(obj, pse_name);
                    switch dtype
                        case 'pse'
                            if isempty(obj.(field))
                                obj.(field) = {item};
                            else
                                obj.(field){obj.pse_indx, 1} =  item;
                            end
                        case 'alt'
                                                set_working_alt(obj, pse_name, alt_name);
                            if isempty(obj.(field))
                                obj.(field) = {{item}};
                            elseif obj.pse_indx > length(obj.(field)) % Ensures No Indexing Errors
                                obj.(field) = [obj.(field);{{item}}];
                            elseif obj.alt_indx > length(obj.(field){obj.pse_indx, 1})
                                obj.(field){obj.pse_indx, 1} = [obj.(field){obj.pse_indx, 1}; {item}];
                            elseif isempty(obj.(field){obj.pse_indx, 1})
                                obj.(field){obj.pse_indx, 1} = {item};
                            else
                                obj.(field){obj.pse_indx, 1}{obj.alt_indx, 1} = item;
                            end
                    end
            end
        end

        function delete_project_field(obj, field, pse_name, alt_name, dtype)
            switch dtype
                case 'proj'
                    % Empty Field (Keeps Field Class)
                    obj.(field) = obj.(field)([]);
                otherwise
                    set_working_pse(obj, pse_name);
                    switch dtype
                        case 'alt'
                            set_working_alt(obj, pse_name, alt_name);
                            obj.(field){obj.pse_indx}(obj.alt_indx) = [];
                        case 'pse'
                            obj.(field)(obj.pse_indx) = [];
                    end
            end
        end

        function val = get_project_field(obj, field, pse_name, alt_name, dtype)
            % Returns [] When PSE/Alternative/DB Is Not Found
            val = [];
            switch dtype
                case 'db'
                    obj.set_working_db(pse_name);
                    val = obj.(field)(obj.db_indx);
                case 'proj'
                    val =  obj.(field);
                otherwise
                    set_working_pse(obj, pse_name);
                    if isempty(obj.pse_indx) || obj.pse_indx > numel(obj.(field))
                        return
                    end
                    switch dtype
                        case 'alt'
                            set_working_alt(obj, pse_name, alt_name);
                            if isempty(obj.alt_indx) || obj.alt_indx > numel(obj.(field){obj.pse_indx})
                                return
                            end
                            if iscell(obj.(field){obj.pse_indx})
                                val = obj.(field){obj.pse_indx}{obj.alt_indx};
                            else
                                val = obj.(field){obj.pse_indx}(obj.alt_indx);
                            end
                        case 'pse'
                            val = obj.(field){obj.pse_indx};
                    end
            end
        end

        function reset_project(obj)
            obj.pse_list = {};
            obj.alternative_list = {};
            obj.pse_tables = {};
            obj.pse_geometry = {};
            obj.sims = {};
            obj.multiline = obj.multiline([]);
        end

        function leftover = remove_pse(obj, pse_name, delete_files)
            % Removes PSE From Every Per-PSE Field (Keeps Fields Aligned). delete_files (Default false): Its Folder
            % <path>\<name>\PSE\<pse> Is Deleted First (delete_folder; An Error Leaves The Project Unchanged).
            % leftover: Path delete_folder Could Not Fully Remove ('' If None)
            if nargin < 3
                delete_files = false;
            end
            leftover = '';
            indx = find(strcmp(pse_name, obj.pse_list), 1);
            if isempty(indx)
                return
            end
            if delete_files
                leftover = chessProject.delete_folder(fullfile(obj.path, obj.name, 'PSE', pse_name));
            end
            fields = {'pse_list', 'alternative_list', 'pse_tables', 'pse_geometry', 'sims'};
            for kk = 1:length(fields)
                if numel(obj.(fields{kk})) >= indx
                    obj.(fields{kk})(indx) = [];
                end
            end
            obj.multiline(strcmp(pse_name, {obj.multiline.pse})) = [];
            obj.pse_indx = [];
            obj.alt_indx = [];
        end

        function leftover = remove_alternative(obj, pse_name, alt_name, delete_files)
            % Removes Alternative From Every Per-Alternative Field (Removes PSE If Last Alternative, Or If It Is The Stage 1 Of A
            % Multi-Line PSE: The Whole Multi-Line PSE Goes). delete_files (Default false): Its Folder <path>\<name>\PSE\<pse>\<alt>
            % (The PSE Folder When The PSE Goes) Is Deleted First (delete_folder; An Error Leaves The Project Unchanged).
            % leftover: Path Not Fully Removed ('' If None)
            if nargin < 4
                delete_files = false;
            end
            leftover = '';
            p_indx = find(strcmp(pse_name, obj.pse_list), 1);
            if isempty(p_indx) || p_indx > numel(obj.alternative_list)
                return
            end
            a_indx = find(strcmp(alt_name, obj.alternative_list{p_indx}), 1);
            if isempty(a_indx)
                return
            end
            if numel(obj.alternative_list{p_indx}) == 1 || obj.alt_stage(pse_name, alt_name) == 1
                leftover = obj.remove_pse(pse_name, delete_files);
                return
            end
            if delete_files
                leftover = chessProject.delete_folder(fullfile(obj.path, obj.name, 'PSE', pse_name, alt_name));
            end
            fields = {'alternative_list', 'pse_tables', 'pse_geometry', 'sims'};
            for kk = 1:length(fields)
                if numel(obj.(fields{kk})) >= p_indx && iscell(obj.(fields{kk}){p_indx})...
                        && numel(obj.(fields{kk}){p_indx}) >= a_indx
                    obj.(fields{kk}){p_indx}(a_indx) = [];
                end
            end
            mm = find(strcmp(pse_name, {obj.multiline.pse}), 1);
            if ~isempty(mm)
                obj.multiline(mm).stage2(strcmp(alt_name, obj.multiline(mm).stage2)) = [];
            end
            obj.alt_indx = [];
        end

        function copy_pse(obj, pse_name, new_name)
            % Copy Of PSE pse_name Appended As new_name (End Of The PSE List): Its Alternatives (Same Names), PSE Tables,
            % Geometry And Multi-Line Link. Simulation Bundles Are Not Copied: Empty Registry Rows, Nothing On Disk Until A Run.
            % The Caller Checks new_name (name_problem)
            p = find(strcmp(pse_name, obj.pse_list), 1);
            if isempty(p)
                error('CHESS:copyPseMissing', 'PSE "%s" is not in project %s.', pse_name, obj.name);
            end
            n = numel(obj.pse_list) + 1;
            fields = {'alternative_list', 'pse_tables', 'pse_geometry'};
            for kk = 1:length(fields)
                if numel(obj.(fields{kk})) >= p
                    obj.(fields{kk}){n, 1} = obj.(fields{kk}){p};
                end
            end
            obj.pse_list{n, 1} = new_name;
            obj.sync_alt_fields();
            mm = find(strcmp(pse_name, {obj.multiline.pse}), 1);
            if ~isempty(mm)
                obj.multiline(end+1) = obj.multiline(mm);
                obj.multiline(end).pse = new_name;
            end
            obj.pse_indx = [];
            obj.alt_indx = [];
        end

        function n_alt = stormdb_usage(obj, db_name)
            % Number Of Alternatives With A Registry Row (sims) Of Storm Database db_name (Case-Insensitive)
            n_alt = 0;
            for pp = 1:numel(obj.sims)
                for aa = 1:numel(obj.sims{pp})
                    n_alt = n_alt + any(strcmpi(db_name, {obj.sims{pp}{aa}.db}));
                end
            end
        end

        function remove_stormdb(obj, db_name)
            % Removes A Storm Database And Its Registry Rows (drop_db_sims). Its Run Files Are Not Touched (stormdb_run_files)
            indx = find(strcmp(db_name, {obj.stormDB_list.db_name}), 1);
            if isempty(indx)
                return
            end
            obj.drop_db_sims(db_name);
            obj.stormDB_list(indx) = [];
            obj.db_indx = [];
        end

        function drop_db_sims(obj, db_name)
            % Registry Rows Of Storm Database db_name Dropped In Every Alternative (Case-Insensitive; Storm DB Entry Kept)
            for pp = 1:numel(obj.sims)
                for aa = 1:numel(obj.sims{pp})
                    rows = obj.sims{pp}{aa};
                    obj.sims{pp}{aa} = rows(~strcmpi(db_name, {rows.db}));
                end
            end
        end

        function files = stormdb_run_files(obj, db_name)
            % Run Files Of Storm Database db_name In Every Alternative, Read From Disk For Every Workflow (bundle_files: Every
            % <db>_<WF>_* Run File, Run Backups *_prev.mat Included), So Bundles Without A Registry Row (Not Yet Synced, Or
            % Without A Responses File) Are Included Too: A Storm DB Imported Again Under This Name Never Inherits Old Runs.
            % Case-Insensitive DB Name
            files = cell(0, 1);
            for pp = 1:numel(obj.pse_list)
                for aa = 1:numel(obj.alternative_list{pp})
                    for wf = {'PROS-RB', 'DET', 'LCS', 'PROS-FB'}
                        files = [files; obj.bundle_files(obj.pse_list{pp}, obj.alternative_list{pp}{aa}, db_name, wf{1})]; %#ok<AGROW>
                    end
                end
            end
        end

        function lines = stormdb_tied_sims(obj, db_name)
            % Simulations Tied To Storm Database db_name: One Line Per Alternative With Registry Rows Of It Or Run Files Of It
            % On Disk (bundle_files: Bundles Not Yet Synced Count Too, So Removing The DB Always Prompts),
            % '<pse> / <alt>  (<workflows>)' (Case-Insensitive DB Name)
            lines = cell(0, 1);
            for pp = 1:numel(obj.pse_list)
                for aa = 1:numel(obj.alternative_list{pp})
                    wfs = {};
                    if pp <= numel(obj.sims) && aa <= numel(obj.sims{pp})
                        rows = obj.sims{pp}{aa};
                        wfs = {rows(strcmpi(db_name, {rows.db})).workflow};
                    end
                    for wf = {'PROS-RB', 'DET', 'LCS', 'PROS-FB'}
                        if ~any(strcmpi(wf{1}, wfs)) && ~isempty(obj.bundle_files(obj.pse_list{pp}, obj.alternative_list{pp}{aa}, db_name, wf{1}))
                            wfs{end+1} = wf{1}; %#ok<AGROW>
                        end
                    end
                    if ~isempty(wfs)
                        lines{end+1, 1} = sprintf('%s / %s  (%s)', obj.pse_list{pp}, obj.alternative_list{pp}{aa},...
                            strjoin(wfs, ', ')); %#ok<AGROW>
                    end
                end
            end
        end

        function [rows, dropped, changed] = sim_rows(obj, pse_name, alt_name, repair)
            % Registry Rows Of An Alternative Whose Responses File Exists (One isfile Each, sim_file), Sorted By Label
            % (sim_label). repair (Default true): Rows Whose Responses File Is Missing Are Dropped (dropped) And Only That
            % Alternative Is Re-Synced (sync_sims 'sync'; changed: Its stage1_changed Rows {pse, alt, db, workflow}); false:
            % They Are Only Left Out. Unknown Names: No Rows
            if nargin < 4
                repair = true;
            end
            rows = chessProject.empty_sim_rows();
            dropped = rows;
            changed = cell(0, 4);
            [p, a] = obj.alt_position(pse_name, alt_name);
            if isempty(a) || p > numel(obj.sims) || a > numel(obj.sims{p})
                return
            end
            rows = obj.sims{p}{a};
            ok = false(size(rows));
            for rr = 1:numel(rows)
                ok(rr) = isfile(obj.sim_file(pse_name, alt_name, rows(rr)));
            end
            dropped = rows(~ok);
            rows = rows(ok);
            if repair && ~isempty(dropped)
                obj.sims{p}{a} = rows;
                info = obj.sync_sims({pse_name, alt_name}, 'sync');
                changed = info.stage1_changed;
                rows = obj.sims{p}{a};
            end
            [~, order] = sort(lower(arrayfun(@chessProject.sim_label, rows, 'un', false)));
            rows = rows(order);
        end

        function upsert_sim(obj, pse_name, alt_name, row)
            % Registry Row Of A Bundle (sim_row_from_config) Added, Or Replacing The Row Of The Same Storm DB + Workflow
            % (Case-Insensitive)
            obj.sync_alt_fields();
            [p, a] = obj.alt_position(pse_name, alt_name);
            rows = obj.sims{p}{a};
            k = find(strcmpi(row.db, {rows.db}) & strcmpi(row.workflow, {rows.workflow}), 1);
            if isempty(k)
                k = numel(rows) + 1;
            end
            rows(k, 1) = row;
            obj.sims{p}{a} = rows;
        end

        function drop_sim(obj, pse_name, alt_name, db_name, workflow)
            % Registry Row Of One Bundle (Storm DB + Workflow, Case-Insensitive) Dropped; Its Files Are Not Touched (delete_sim)
            [p, a] = obj.alt_position(pse_name, alt_name);
            if isempty(a) || p > numel(obj.sims) || a > numel(obj.sims{p})
                return
            end
            rows = obj.sims{p}{a};
            obj.sims{p}{a} = rows(~(strcmpi(db_name, {rows.db}) & strcmpi(workflow, {rows.workflow})));
        end

        function db_name = default_db(obj, pse_name, alt_name)
            % Storm DB Of The Alternative's Newest Registry Row (resp_file_date) Still In The Project, As Named In stormDB_list
            % ('' If None)
            db_name = '';
            [p, a] = obj.alt_position(pse_name, alt_name);
            if isempty(a) || p > numel(obj.sims) || a > numel(obj.sims{p})
                return
            end
            names = {obj.stormDB_list.db_name};
            rows = obj.sims{p}{a};
            rows = rows(ismember(lower({rows.db}), lower(names)));
            if ~isempty(rows)
                [~, k] = max([rows.resp_file_date]);
                db_name = names{find(strcmpi(rows(k).db, names), 1)};
            end
        end

        function info = sync_sims(obj, scope, mode)
            % Registry Rebuilt From Disk. scope: 'project' Or {pse, alt} (One Alternative). mode:
            %   'sync': Rows Whose Bundle Is Gone Dropped, Rows Whose Responses File Date Changed Reloaded, Bundles Without A
            %       Row Added (Only Changed Or New Bundles Load Their Config File)
            %   'full': Existing Rows Ignored, Every Bundle Reloaded
            % A Bundle = <db>_<WF>_project_responses.mat In PSE\<pse>\<alt>\<PROS|DET|LCS> (disk_bundles); Its Row Comes From
            % Its Config File (sim_row_from_config; A Config File That Fails To Load Is Skipped). scope 'project' Also Converts
            % The Storm DB Wizard Objects Of An Older Project File To Records (convert_stormdb_records) And Retries A Missing
            % Storm DB layout (fill_stormdb_layouts; Both Modes).
            % info: added, refreshed, dropped, skipped, converted (Counts); stage1_changed / stage1_dropped: Rows
            %   {pse, alt, db, workflow} Of Multi-Line Stage 1 Bundles Reloaded With Another forcing_stamp Or structure_kt / Dropped
            info = struct('added', 0, 'refreshed', 0, 'dropped', 0, 'skipped', 0, 'converted', 0,...
                'stage1_changed', {cell(0, 4)}, 'stage1_dropped', {cell(0, 4)});
            obj.sync_alt_fields();
            if ischar(scope)
                info.converted = obj.convert_stormdb_records();
                obj.fill_stormdb_layouts();
                for pp = 1:numel(obj.pse_list)
                    for aa = 1:numel(obj.alternative_list{pp})
                        info = obj.sync_alt(pp, aa, mode, info);
                    end
                end
            else
                [p, a] = obj.alt_position(scope{1}, scope{2});
                if ~isempty(a)
                    info = obj.sync_alt(p, a, mode, info);
                end
            end
        end

        function failed = delete_sim(obj, pse_name, alt_name, db_name, workflow)
            % Deletes The Run Files Of One Bundle (bundle_files: Responses File First, So A Partial Delete Never Leaves A Saved
            % Simulation Behind), Then Its Registry Row (drop_sim) Once The Responses File Is Gone. failed: '<file> (<reason>)'
            % Per File Not Deleted
            failed = cell(0, 1);
            for ff = obj.bundle_files(pse_name, alt_name, db_name, workflow)'
                try
                    java.nio.file.Files.delete(java.io.File(ff{1}).toPath());
                catch ME
                    failed{end+1, 1} = sprintf('%s (%s)', ff{1}, chessProject.nio_reason(ME)); %#ok<AGROW>
                end
            end
            if ~isfile(obj.sim_file(pse_name, alt_name, struct('db', db_name, 'workflow', workflow)))
                obj.drop_sim(pse_name, alt_name, db_name, workflow);
            end
        end

        function stage2 = multiline_stage2(obj, pse_name, alt_name)
            % Stage 2 Alternatives Coupled To alt_name When It Is The Stage 1 Of A Multi-Line PSE (multiline), Else {}
            stage2 = cell(0, 1);
            mm = find(strcmp(pse_name, {obj.multiline.pse}), 1);
            if ~isempty(mm) && strcmp(alt_name, obj.multiline(mm).stage1)
                stage2 = obj.multiline(mm).stage2(:);
            end
        end

        function tf = is_multiline(obj, pse_name)
            % PSE Is A Multi-Line Transect (multiline)
            tf = any(strcmp(pse_name, {obj.multiline.pse}));
        end

        function stage = alt_stage(obj, pse_name, alt_name)
            % Multi-Line Stage Of An Alternative: 1, 2, Or 0 (Not A Multi-Line Alternative)
            stage = 0;
            mm = find(strcmp(pse_name, {obj.multiline.pse}), 1);
            if isempty(mm)
                return
            elseif strcmp(alt_name, obj.multiline(mm).stage1)
                stage = 1;
            elseif any(strcmp(alt_name, obj.multiline(mm).stage2))
                stage = 2;
            end
        end

        function s1 = stage1_alt(obj, pse_name)
            % Stage 1 Alternative Of A Multi-Line PSE ('' When pse_name Is Not One)
            s1 = '';
            mm = find(strcmp(pse_name, {obj.multiline.pse}), 1);
            if ~isempty(mm)
                s1 = obj.multiline(mm).stage1;
            end
        end

        function names = multiline_pses(obj)
            % Multi-Line PSE Names (Project PSE Order)
            names = obj.pse_list(ismember(obj.pse_list, {obj.multiline.pse}));
            names = names(:)';
        end

        function link_multiline(obj, pse_name, alt_name, stage)
            % Record A Created Multi-Line Alternative: stage 1 Starts The Multi-Line PSE pse_name, stage 2 Joins It
            if stage == 1
                obj.multiline(end+1) = struct('pse', pse_name, 'stage1', alt_name, 'stage2', {cell(0, 1)});
            else
                mm = find(strcmp(pse_name, {obj.multiline.pse}), 1);
                obj.multiline(mm).stage2{end+1, 1} = alt_name;
            end
        end

        function sync_alt_fields(obj)
            % Sizes The Registry (sims) To alternative_list: Alternatives Without An Entry Get No Rows
            nPSE = numel(obj.alternative_list);
            data = obj.sims(1:min(numel(obj.sims), nPSE));
            for pp = 1:nPSE
                nAlt = numel(obj.alternative_list{pp});
                if pp > numel(data) || ~iscell(data{pp})
                    data{pp, 1} = repmat({chessProject.empty_sim_rows()}, nAlt, 1);
                elseif numel(data{pp}) < nAlt
                    data{pp}(end+1:nAlt, 1) = {chessProject.empty_sim_rows()};
                else
                    data{pp} = data{pp}(1:nAlt);
                end
            end
            obj.sims = data(:);
        end

        function relocate(obj, new_root)
            % [NEW] Project Folder Moved/Copied To new_root (Import From Another Location): Stored Paths Under
            % <path>\<name> Point Into <new_root>\<name> (remap_paths)
            obj.remap_paths(fullfile(obj.path, obj.name), fullfile(new_root, obj.name));
            obj.path = new_root;
        end

        function remap_paths(obj, old_dir, new_dir)
            % Stored Paths Under old_dir (Tide Files, Storm DB Files, chs_dependencies) -> Same Subpath Under new_dir.
            % source_paths (CHS Sources Outside The Project) Are Left As Is. Registry Rows Hold No Paths
            remap = @(p) chessProject.relocate_path(p, old_dir, new_dir);
            obj.tide_files_list = cellfun(remap, obj.tide_files_list, 'un', false);
            for kk = 1:numel(obj.stormDB_list)
                rec = obj.stormDB_list(kk);
                rec.outpath = remap(rec.outpath);
                if isstruct(rec.output_paths)
                    flds = fieldnames(rec.output_paths);
                    for ff = 1:numel(flds)
                        rec.output_paths.(flds{ff}) = remap(rec.output_paths.(flds{ff}));
                    end
                end
                obj.stormDB_list(kk) = rec;
            end
            obj.chs_dependencies = remap(obj.chs_dependencies);
        end

        function region = project_region(obj)
            % CHS Study Of The Project's Storm DBs ('' If None). Custom_Modeling Storm DBs Give No Region
            studies = {obj.stormDB_list.study};
            studies = studies(~cellfun(@isempty, studies) & ~strcmp(studies, 'Custom_Modeling'));
            region = '';
            if ~isempty(studies)
                region = studies{1};
            end
        end

        function info = rename(obj, level, new_name, pse_name, alt_name, project_names)
            % Rename The Project, A PSE Or An Alternative (level 'proj' | 'pse' | 'alt'; pse_name/alt_name Name The Item).
            % In Order: Name Check (name_problem; The Target Folder Must Not Exist Unless Only The Case Changes), Folder
            % Moved (If Any; Nothing Changed When That Fails), Names + Stored Paths Updated (remap_paths), Saved Run Configs
            % (*_config_file.mat) Under The Moved Folder Rewritten (Name Field, out_files, tide_file), Project File Renamed
            % (Project Level). project_names: The Other Loaded Projects (Project Level).
            % info: old_dir, new_dir, rewritten (Config Files), failed ('<file>: <error>', Not Rewritten)
            arguments
                obj
                level {mustBeMember(level, {'proj', 'pse', 'alt'})}
                new_name {mustBeTextScalar}
                pse_name {mustBeText} = ''
                alt_name {mustBeText} = ''
                project_names cell = {}
            end
            new_name = char(new_name);
            proj_dir = fullfile(obj.path, obj.name);
            switch level
                case 'proj'
                    current = obj.name;
                    siblings = project_names;
                    parent = obj.path;
                    name_field = 'project_name';
                case 'pse'
                    p = find(strcmp(pse_name, obj.pse_list), 1);
                    current = pse_name;
                    siblings = obj.pse_list([1:p-1, p+1:end]);
                    parent = fullfile(proj_dir, 'PSE');
                    name_field = 'struc_id';
                case 'alt'
                    p = find(strcmp(pse_name, obj.pse_list), 1);
                    alts = obj.alternative_list{p};
                    a = find(strcmp(alt_name, alts), 1);
                    current = alt_name;
                    siblings = alts([1:a-1, a+1:end]);
                    parent = fullfile(proj_dir, 'PSE', pse_name);
                    name_field = 'case_name';
            end
            msg = chessProject.name_problem(new_name, siblings, current);
            stage = 0;
            if strcmp(level, 'alt')
                stage = obj.alt_stage(pse_name, alt_name);
            end
            if isempty(msg)
                msg = chessProject.stage_name_problem(new_name, stage);
            end
            if ~isempty(msg)
                error('CHESS:renameInvalid', '%s', msg);
            end
            old_dir = fullfile(parent, current);
            new_dir = fullfile(parent, new_name);
            case_only = strcmpi(new_name, current);
            % movefile Onto An Existing Folder Would Move The Old Folder Inside It
            if ~case_only && (isfolder(new_dir) || isfile(new_dir))
                error('CHESS:renameExists', '"%s" already exists on disk. Choose another name.', new_dir);
            end
            if isfolder(old_dir)
                chessProject.move_item(old_dir, new_dir, case_only);
            end
            mm = find(strcmp(pse_name, {obj.multiline.pse}), 1);
            switch level
                case 'proj'
                    obj.name = new_name;
                case 'pse'
                    obj.pse_list{p} = new_name;
                    if ~isempty(mm)
                        obj.multiline(mm).pse = new_name;
                    end
                case 'alt'
                    obj.alternative_list{p}{a} = new_name;
                    if stage == 1
                        obj.multiline(mm).stage1 = new_name;
                    elseif stage == 2
                        obj.multiline(mm).stage2{strcmp(current, obj.multiline(mm).stage2)} = new_name;
                    end
            end
            obj.remap_paths(old_dir, new_dir);
            info = struct('old_dir', old_dir, 'new_dir', new_dir, 'rewritten', {{}}, 'failed', {{}});
            % Saved Run Configs (Run Backups *_config_file_prev.mat Do Not Match The Pattern). '-append' Keeps 'structure'
            files = dir(fullfile(new_dir, '**', '*_config_file.mat'));
            for ff = 1:numel(files)
                f = fullfile(files(ff).folder, files(ff).name);
                try
                    S = load(f, 'config');
                    config = S.config;
                    config.(name_field) = new_name;
                    for fld = fieldnames(config.out_files)'
                        config.out_files.(fld{1}) = chessProject.relocate_path(config.out_files.(fld{1}), old_dir, new_dir);
                    end
                    config.tide_file = chessProject.relocate_path(config.tide_file, old_dir, new_dir);
                    save(f, 'config', '-append');
                    info.rewritten{end+1, 1} = f;
                catch ME
                    info.failed{end+1, 1} = [f ': ' ME.message];
                end
            end
            % Renamed Multi-Line Stage 1: Its Stage 2 Run Configs Name It (config.multiline.stage1_alt, Library multiline_stage2_config), _prev Backups Included
            if stage == 1
                for s2 = obj.multiline(mm).stage2'
                    files = dir(fullfile(parent, s2{1}, '**', '*_config_file*.mat'));
                    for ff = 1:numel(files)
                        f = fullfile(files(ff).folder, files(ff).name);
                        try
                            S = load(f, 'config');
                            config = S.config;
                            if isfield(config, 'multiline') && isstruct(config.multiline)
                                config.multiline.stage1_alt = new_name;
                                save(f, 'config', '-append');
                                info.rewritten{end+1, 1} = f;
                            end
                        catch ME
                            info.failed{end+1, 1} = [f ': ' ME.message];
                        end
                    end
                end
            end
            % Project File Follows The Project Name (The Caller Then Saves The Updated Project Over It)
            old_file = fullfile(new_dir, ['CHESS_project_' current '.mat']);
            if strcmp(level, 'proj') && isfile(old_file)
                try
                    chessProject.move_item(old_file, fullfile(new_dir, ['CHESS_project_' new_name '.mat']), case_only);
                catch ME
                    info.failed{end+1, 1} = [old_file ': ' ME.message];
                end
            end
        end

        function note = export_archive(obj, zip_file)
            % Project Archive zip_file: <name>/... (The Project Folder) Plus, When The Project Has A Region (project_region) And A
            % Valid chs_dependencies Folder Elsewhere, <name>/CHS_Dependencies/ With That Region's Files Only: Grid_Files\<region>,
            % Bias_and_Uncertainty\<region>, Probability_Masses\<region> (If Any), Probability_Masses\*.mat (Shared TC Files).
            % java.util.zip (MATLAB zip Takes One Root Folder): Nothing Is Copied Into The Project Folder. note: Status Text
            proj_dir = fullfile(obj.path, obj.name);
            bundle_dir = fullfile(proj_dir, 'CHS_Dependencies');
            region = obj.project_region();
            [src, names] = chessProject.folder_entries(proj_dir, obj.name);
            keep = ~strcmp(names, [obj.name '/.chess_lock']); % Session Lock (acquire_lock), Not Project Data
            src = src(keep);
            names = names(keep);
            if isempty(region)
                note = sprintf('Project exported to %s without CHS_Dependencies: the project has no CHS region.', zip_file);
            elseif chessProject.same_path(obj.chs_dependencies, bundle_dir)
                note = sprintf('Project exported to %s with its CHS_Dependencies folder (region %s).', zip_file, region);
            elseif ~isempty(chessProject.chs_dependencies_problem(obj.chs_dependencies, region))
                note = sprintf('Project exported to %s without CHS_Dependencies: no valid %s folder found at "%s".',...
                    zip_file, region, obj.chs_dependencies);
            else
                % A CHS_Dependencies Folder Left In The Project (Imported, Then Re-Pointed) Is Replaced By The Region Subset
                keep = ~startsWith(names, [obj.name '/CHS_Dependencies/']);
                src = src(keep);
                names = names(keep);
                top = [obj.name '/CHS_Dependencies'];
                src = [src; {''; ''; ''; ''}];
                names = [names; strcat(top, {'/'; '/Grid_Files/'; '/Bias_and_Uncertainty/'; '/Probability_Masses/'})];
                for sub = {'Grid_Files', 'Bias_and_Uncertainty', 'Probability_Masses'}
                    sub_dir = fullfile(obj.chs_dependencies, sub{1}, region);
                    if isfolder(sub_dir)
                        [s, n] = chessProject.folder_entries(sub_dir, [top '/' sub{1} '/' region]);
                        src = [src; s]; %#ok<AGROW>
                        names = [names; n]; %#ok<AGROW>
                    end
                end
                pm = dir(fullfile(obj.chs_dependencies, 'Probability_Masses', '*.mat'));
                pm = pm(~[pm.isdir]);
                src = [src; fullfile({pm.folder}', {pm.name}')];
                names = [names; strcat([top '/Probability_Masses/'], {pm.name}')];
                note = sprintf('Project exported to %s with CHS_Dependencies (region %s files).', zip_file, region);
            end
            chessProject.write_zip(zip_file, src, names);
        end
    end

    methods (Access = private)
        function [p, a] = alt_position(obj, pse_name, alt_name)
            % Indices Of A PSE / Alternative In pse_list / alternative_list (a Empty When Not Found)
            a = [];
            p = find(strcmp(pse_name, obj.pse_list), 1);
            if ~isempty(p) && p <= numel(obj.alternative_list)
                a = find(strcmp(alt_name, obj.alternative_list{p}), 1);
            end
        end

        function f = sim_file(obj, pse_name, alt_name, row)
            % Responses File Of A Registry Row (Library chess_paths: <db>_<WF>_project_responses.mat)
            paths = chess_paths(obj.path, obj.name, pse_name, alt_name, chessProject.workflow_number(row.workflow), row.db);
            f = paths.out_files.resp_data;
        end

        function files = bundle_files(obj, pse_name, alt_name, db_name, workflow)
            % Run Files Of One Bundle On Disk: <wf_dir>\<db>_<WF>_<config_file|project_forcing|project_responses|sampling_seed>
            % (_prev).mat (Library chess_paths; Exact, Case-Insensitive Names), Responses File First. Column Cell
            paths = chess_paths(obj.path, obj.name, pse_name, alt_name, chessProject.workflow_number(workflow), db_name);
            d = dir(fullfile(paths.wf_dir, '*.mat'));
            pat = ['^' regexptranslate('escape', [db_name '_' workflow])...
                '_(config_file|project_forcing|project_responses|sampling_seed)(_prev)?\.mat$'];
            d = d(~cellfun(@isempty, regexpi({d.name}, pat, 'once')));
            files = cell(0, 1);
            for ff = 1:numel(d)
                files{end+1, 1} = fullfile(d(ff).folder, d(ff).name); %#ok<AGROW>
            end
            [~, order] = sort(~strcmpi(files, paths.out_files.resp_data));
            files = files(order);
        end

        function bundles = disk_bundles(obj, pse_name, alt_name)
            % Bundles On Disk With A Responses File: PSE\<pse>\<alt>\<wf_folder>\<db>_<WF>_project_responses.mat (Library
            % chess_paths; Case-Insensitive, Run Backups Not Counted). Column Struct Array: db, workflow (Upper Case), config
            % (Its Config File), datenum (Responses File Date)
            bundles = struct('db', {}, 'workflow', {}, 'config', {}, 'datenum', {});
            alt_dir = fullfile(obj.path, obj.name, 'PSE', pse_name, alt_name);
            wf = {'PROS', 'PROS-RB|PROS-FB'; 'DET', 'DET'; 'LCS', 'LCS'};
            for kk = 1:size(wf, 1)
                d = dir(fullfile(alt_dir, wf{kk, 1}, '*_project_responses.mat'));
                tok = regexpi({d.name}, ['^(.+)_(' wf{kk, 2} ')_project_responses\.mat$'], 'tokens', 'once');
                for ff = find(~cellfun(@isempty, tok))
                    wf_name = upper(tok{ff}{2});
                    bundles(end+1, 1) = struct('db', tok{ff}{1}, 'workflow', wf_name, 'datenum', d(ff).datenum,...
                        'config', fullfile(d(ff).folder, [tok{ff}{1} '_' wf_name '_config_file.mat'])); %#ok<AGROW>
                end
            end
        end

        function info = sync_alt(obj, p, a, mode, info)
            % sync_sims Of One Alternative (Indices p, a); Counts And Stage 1 Lists Added To info
            pse_name = obj.pse_list{p};
            alt_name = obj.alternative_list{p}{a};
            stage1 = obj.alt_stage(pse_name, alt_name) == 1;
            old = obj.sims{p}{a};
            matched = false(size(old));
            rows = chessProject.empty_sim_rows();
            for d = obj.disk_bundles(pse_name, alt_name)'
                k = find(strcmpi(d.db, {old.db}) & strcmpi(d.workflow, {old.workflow}), 1);
                matched(k) = true;
                if strcmp(mode, 'sync') && ~isempty(k) && isequal(old(k).resp_file_date, d.datenum)
                    rows(end+1, 1) = old(k); %#ok<AGROW>
                    continue
                end
                try
                    S = load(d.config, 'config', 'structure');
                    row = chessProject.sim_row_from_config(S.config, S.structure, d.datenum);
                catch
                    info.skipped = info.skipped + 1;
                    continue
                end
                if isempty(k)
                    info.added = info.added + 1;
                else
                    info.refreshed = info.refreshed + 1;
                    if stage1 && ~(strcmp(row.forcing_stamp, old(k).forcing_stamp) && isequaln(row.structure_kt, old(k).structure_kt))
                        info.stage1_changed(end+1, :) = {pse_name, alt_name, row.db, row.workflow};
                    end
                end
                rows(end+1, 1) = row; %#ok<AGROW>
            end
            gone = old(~matched);
            info.dropped = info.dropped + numel(gone);
            if stage1
                for gg = 1:numel(gone)
                    info.stage1_dropped(end+1, :) = {pse_name, alt_name, gone(gg).db, gone(gg).workflow};
                end
            end
            obj.sims{p}{a} = rows;
        end

        function n = convert_stormdb_records(obj)
            % Project File Saved With Storm DB Wizard Objects: stormDB_list Becomes Records (CHSStormDBImportUI.to_record; A
            % Missing layout Is Filled By fill_stormdb_layouts). n: Records Converted
            n = 0;
            if ~isa(obj.stormDB_list, 'CHSStormDBImportUI')
                return
            end
            recs = CHSStormDBImportUI.empty_records();
            for kk = 1:numel(obj.stormDB_list)
                recs(end+1, 1) = obj.stormDB_list(kk).to_record(); %#ok<AGROW>
            end
            obj.stormDB_list = recs;
            n = numel(recs);
        end

        function fill_stormdb_layouts(obj)
            % Storm DB Records Without A layout (Storm DB File Missing Or Unreadable When Last Tried): Computed From The Storm
            % DB File When It Exists And Loads (One Load Each), Else Left Empty (The GUI Asks For A Re-Import)
            for kk = 1:numel(obj.stormDB_list)
                rec = obj.stormDB_list(kk);
                if ~isempty(rec.layout) || ~isstruct(rec.output_paths) || ~isfield(rec.output_paths, 'storm_db')...
                        || ~isfile(rec.output_paths.storm_db)
                    continue
                end
                try
                    S = load(rec.output_paths.storm_db, 'storm');
                    obj.stormDB_list(kk).layout = CHSStormDBImportUI.storm_layout(S.storm);
                catch
                end
            end
        end
    end

    %%
    methods (Access = public)
        function chess_structure = create_geometry(obj, pse_name, alt_name, pse_type)
            % Structure Step: Build Structure-Only Config From PSE Table
            pse_table = obj.get_project_field('pse_tables', pse_name, alt_name, 'alt');
            config = cell2struct(pse_table(:, 4), pse_table(:, 1), 1);
            config.struc_type = obj.get_struc_type(pse_type);
            config.add_toe_berm = +any(startsWith(pse_table(:, 1), 'berm_'));
            % Library Structure Rules (Berms, Floodwall Toe)
            config = finalize_structure_config(config);
            % Library Geometry (Suppress Status Print)
            [~, chess_structure] = evalc('create_structure_geometry(config)');
            % GUI Fields. offshore_elevation: Fallback Offshore Elevation (PSE Table Row, Template Geometry Section), Used By
            % Runs When The Storm DB Has No Study Grid Value (create_resp_config); PSEs Created Before The Row Have None
            chess_structure.add_toe_berm = config.add_toe_berm;
            if isfield(config, 'offshore_elevation')
                chess_structure.offshore_elevation = config.offshore_elevation;
            end
            chess_structure.pse_type = pse_type;
            % Set Geometry
            obj.set_project_field('pse_geometry', chess_structure, pse_name, alt_name, 'alt');
        end
    end

    %% STATIC METHODS
    methods (Static)
        function row = sim_row_from_config(config, structure, resp_file_date)
            % Registry Row Of A Completed Run (Run Success And sync_sims). Names Only, Never Paths:
            %   db, workflow: Library chess_paths db / wflow_name (e.g. 'PROS-RB')
            %   data_types: Run Tab Data Type Symbols ('peaks_default', 'create_wlp', 'create_whp', 'use_timeseries')
            %   storm_type: config.storm_sampling
            %   run_date: 'yyyy-MM-dd HH:mm' Of resp_file_date (datenum Of <db>_<WF>_project_responses.mat)
            %   forcing_stamp: config.forcing_stamp ('' If None)
            %   structure_kt: crest_elevation, crest_width, seaside_slope, offshore_slope, toe_elevation Of The Run's
            %       structure (NaN If Absent); Read For Multi-Line Stage 1 Rows (Stage 2 Kt And Offshore End)
            %   inherited: multiline_inherited_fields Values Of The Run (Without Its Tide Indices And LCS Convergence Results;
            %       tide_file As A File Name); Read For Multi-Line Stage 1 Rows
            %   stage1_stamp: Multi-Line Stage 2 Rows: config.multiline.stage1_stamp (The Stage 1 forcing_stamp Its Forcing
            %       Came From), Else ''
            paths = chess_paths(config);
            row = chessProject.empty_sim_rows();
            row(1).db = paths.db;
            row.workflow = paths.wflow_name;
            dt = {'peaks_default', 'create_wlp', 'create_whp', 'use_timeseries'};
            row.data_types = dt([config.use_peaks, config.create_wlp, config.create_whp, config.use_timeseries] == 1);
            row.storm_type = config.storm_sampling;
            row.run_date = char(datetime(resp_file_date, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm'));
            row.resp_file_date = resp_file_date;
            row.forcing_stamp = '';
            if isfield(config, 'forcing_stamp')
                row.forcing_stamp = config.forcing_stamp;
            end
            row.structure_kt = struct();
            for fld = {'crest_elevation', 'crest_width', 'seaside_slope', 'offshore_slope', 'toe_elevation'}
                row.structure_kt.(fld{1}) = NaN;
                if isfield(structure, fld{1})
                    row.structure_kt.(fld{1}) = structure.(fld{1});
                end
            end
            row.inherited = struct();
            run_outputs = {'tide_indx_xc', 'tide_indx_tc', 'tide_indx_cc', 'lcs_convergence_results'};
            for fld = setdiff(multiline_inherited_fields(), run_outputs, 'stable')
                if isfield(config, fld{1})
                    row.inherited.(fld{1}) = config.(fld{1});
                end
            end
            if isfield(row.inherited, 'tide_file')
                [~, tide_name, tide_ext] = fileparts(row.inherited.tide_file);
                row.inherited.tide_file = [tide_name tide_ext];
            end
            row.stage1_stamp = '';
            if isfield(config, 'multiline') && isstruct(config.multiline) && isfield(config.multiline, 'stage1_stamp')
                row.stage1_stamp = config.multiline.stage1_stamp;
            end
        end

        function rows = empty_sim_rows()
            % Registry Rows Of An Alternative Without Bundles (0x1, Every Row Field; sim_row_from_config)
            rows = struct('db', {}, 'workflow', {}, 'data_types', {}, 'storm_type', {}, 'run_date', {}, 'resp_file_date', {},...
                'forcing_stamp', {}, 'structure_kt', {}, 'inherited', {}, 'stage1_stamp', {});
            rows = reshape(rows, 0, 1);
        end

        function label = sim_label(row)
            % Display Label Of A Registry Row: '<db> | <workflow>'
            label = [row.db ' | ' row.workflow];
        end

        function wf = workflow_number(wflow_name)
            % Library Workflow Number Of A chess_paths wflow_name (PROS-RB 1, DET 2, LCS 3, PROS-FB 4; Case-Insensitive)
            wf = find(strcmpi(wflow_name, {'PROS-RB', 'DET', 'LCS', 'PROS-FB'}), 1);
        end

        function [lock, holder, problem] = acquire_lock(proj_dir)
            % Exclusive OS Lock Of A Project Folder (One GUI Session Per Project): java.nio FileChannel.tryLock On
            % <proj_dir>\.chess_lock, Released By The OS When The Holding MATLAB Ends (Crash Included). Locked: lock =
            % struct(file, raf, lock) (release_lock), The File Then Holds '<user>, <open time>'. Held Elsewhere (Another MATLAB,
            % Or Another Channel In This One): lock = [], holder = That Text. The Locked Byte Lies Past The Text, So Other
            % Sessions Can Still Read It (Windows Locks Are Mandatory). A Leftover File Without A Held Lock Blocks Nothing.
            % Lock File Not Usable (Project Folder Missing, Read-Only, Access Denied): lock = [], holder = '', problem = Reason
            holder = '';
            problem = '';
            f = fullfile(proj_dir, '.chess_lock');
            try
                raf = java.io.RandomAccessFile(f, 'rw');
            catch ME
                lock = [];
                if ~isfolder(proj_dir)
                    problem = sprintf('project folder "%s" not found', proj_dir);
                else
                    problem = sprintf('lock file "%s" cannot be written (%s)', f, chessProject.nio_reason(ME));
                end
                return
            end
            try
                lk = raf.getChannel().tryLock(int64(2^31), int64(1), false);
            catch % OverlappingFileLockException: Held In This MATLAB
                lk = [];
            end
            if isempty(lk)
                raf.close();
                lock = [];
                holder = strtrim(fileread(f));
                if isempty(holder)
                    holder = 'unknown user';
                end
                return
            end
            holder = sprintf('%s, %s', char(java.lang.System.getProperty('user.name')),...
                char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
            try
                raf.setLength(0);
                raf.write(typecast(unicode2native(holder, 'UTF-8'), 'int8'));
            catch ME
                lk.release();
                raf.close();
                lock = [];
                holder = '';
                problem = sprintf('lock file "%s" cannot be written (%s)', f, chessProject.nio_reason(ME));
                return
            end
            lock = struct('file', f, 'raf', raf, 'lock', lk);
        end

        function release_lock(lock)
            % Releases An acquire_lock Lock ([] Or Already Released: Nothing). The File Stays (Harmless Without A Held Lock)
            if isempty(lock) || ~lock.lock.isValid()
                return
            end
            lock.lock.release();
            lock.raf.close();
        end

        function struc_type = get_struc_type(pse_type)
            % GUI PSE Type -> Library Structure Type (Single Place For GUI Labels).
            % Former Labels 'Vertical Wall' / 'Low Crested Mound' Accepted For Previously Saved Projects
            switch pse_type
                case 'Levee'
                    struc_type = 1;
                case {'Floodwall', 'Vertical Wall'}
                    struc_type = 2;
                case 'Rubble Mound'
                    struc_type = 3;
                case {'Low Crested Breakwater', 'Low Crested Mound'}
                    struc_type = 4;
                otherwise
                    error('Unsupported PSE type "%s".', pse_type);
            end
        end

        function tpl = get_library_template(pse_type)
            % Reads CHESS-Library Input Template For PSE Type.
            % Output: struct with one field per template section (general,
            % forcing, geometry, properties, responses, mcs, csr, pros),
            % each an N x 4 cell {symbol, description, units, value}.
            persistent cache
            if isempty(cache)
                cache = containers.Map();
            end
            % Internal Template Per Library Structure Type: <name>.csv (Primary, No Excel Needed), Else <name>.xlsx
            fnames = {'levee_pse', 'floodwall_pse', 'rubble_mound_pse', 'low_crested_breakwater_pse'};
            fname = fnames{chessProject.get_struc_type(pse_type)};
            % Templates Live In CHESS_Library\PSE_Templates (Setup's Sibling Folder)
            setup_dir = fileparts(which('create_structure_geometry'));
            if isempty(setup_dir)
                error('CHESS-Library is not on the MATLAB path.');
            end
            fpath = fullfile(fileparts(setup_dir), 'PSE_Templates', [fname '.csv']);
            if ~isfile(fpath)
                fpath = fullfile(fileparts(setup_dir), 'PSE_Templates', [fname '.xlsx']);
            end
            finfo = dir(fpath);
            if isempty(finfo)
                error('Library template not found: %s (.csv or .xlsx)', fpath(1:end-5));
            end
            % Reuse Cached Template Unless File Changed
            if isKey(cache, fpath)
                cached = cache(fpath);
                if cached.datenum == finfo.datenum
                    tpl = cached.tpl;
                    return
                end
            end
            % Parse Template (Library read_chess_input, Same Reader As call_input_parser)
            tpl = read_chess_input(fpath);
            cache(fpath) = struct('datenum', finfo.datenum, 'tpl', tpl);
        end

        function [val_c, unitlbl, convunitlbl] = convert_units(val, dim, src_unitsys, trg_unitsys)
            arguments
                val {mustBeNumeric}
                dim {mustBeMember(dim, {'length','mass','density','force','pressure'})}
                src_unitsys {mustBeMember(src_unitsys, {'SI', 'Imperial'})}
                trg_unitsys {mustBeMember(trg_unitsys, {'SI', 'Imperial'})}
            end
            switch src_unitsys
                case 'SI'
                    % Define Symmbols For Fundamental Units
                    unitSymbols.length = 'm';% m to ft
                    unitSymbols.mass = 'Kg';% kg to lbm
                    unitSymbols.density = 'Kg/m^3';% kg/m^3 to lbm/ft^3
                    unitSymbols.force = 'N';% N to lbf
                    unitSymbols.pressure = 'Pa';% Pa to Psi
                case 'Imperial'
                    unitSymbols.length = 'ft';% m to ft
                    unitSymbols.mass = 'lb';% kg to lbm
                    unitSymbols.density = 'lb/m^3';% kg/m^3 to lbm/ft^3
                    unitSymbols.force = 'lb_f';% N to lbf
                    unitSymbols.pressure = 'Psi';% Pa to Psi
            end

            % Load Conversion Factors And Symbols
            if strcmp(src_unitsys, 'SI') && strcmp(trg_unitsys, 'Imperial')
                % Define Conversion Factors For Fundamental Units
                conversionCoeffs.length = 3.2808399;% m to ft
                conversionCoeffs.mass = 2.20462262;% kg to lbm
                conversionCoeffs.density =conversionCoeffs.mass/(conversionCoeffs.length^3);% kg/m^3 to lbm/ft^3
                conversionCoeffs.force = 0.22480894;% N to lbf
                conversionCoeffs.pressure = 0.00014504;% Pa to Psi

                % Define Conversion Symbols
                convUnitSymbols.length = 'ft';% m to ft
                convUnitSymbols.mass = 'lb';% kg to lbm
                convUnitSymbols.density = 'lb/m^3';% kg/m^3 to lbm/ft^3
                convUnitSymbols.force = 'lb_f';% N to lbf
                convUnitSymbols.pressure = 'Psi';% Pa to Psi
            elseif strcmp(src_unitsys, 'Imperial') && strcmp(trg_unitsys, 'SI')
                % Initialize Unit Conversion Factors
                conversionCoeffs.length = 1/3.2808399;% ft to m
                conversionCoeffs.mass = 1/2.20462262;% lbm to Kg
                conversionCoeffs.density = conversionCoeffs.mass/(conversionCoeffs.length^3);% lbm/ft^3 to kg/m^3
                conversionCoeffs.force = 1/0.22480894;% lbf to N
                conversionCoeffs.pressure = 1/0.00014504;% Psi to Pa

                % Define Conversion Symbols
                convUnitSymbols.length = 'm';% m to ft
                convUnitSymbols.mass = 'Kg';% kg to lbm
                convUnitSymbols.density = 'Kg/m^3';% kg/m^3 to lbm/ft^3
                convUnitSymbols.force = 'N';% N to lbf
                convUnitSymbols.pressure = 'Pa';% Pa to Psi
            elseif strcmp(src_unitsys, trg_unitsys)
                % Initialize Unit Conversion Factors
                conversionCoeffs.length = 1;% ft to m
                conversionCoeffs.mass = 1;% lbm to Kg
                conversionCoeffs.density = 1;% lbm/ft^3 to kg/m^3
                conversionCoeffs.force = 1;% lbf to N
                conversionCoeffs.pressure = 1;% Psi to Pa

                % Define Conversion Symbols
                convUnitSymbols.length = unitSymbols.length;% m to ft
                convUnitSymbols.mass = unitSymbols.mass;% kg to lbm
                convUnitSymbols.density = unitSymbols.density;% kg/m^3 to lbm/ft^3
                convUnitSymbols.force = unitSymbols.force;% N to lbf
                convUnitSymbols.pressure = unitSymbols.pressure;% Pa to Psi
            end
            % Convert Value
            val_c = val.*conversionCoeffs.(dim);
            unitlbl = unitSymbols.(dim);
            convunitlbl = convUnitSymbols.(dim);
        end

        function p = relocate_path(p, old_dir, new_dir)
            % [NEW] Path Under old_dir (Path-Segment Boundary, '\' Or '/', Case-Insensitive On Windows) -> Same Subpath Under
            % new_dir. Any Other Value (Elsewhere, Empty, Not char, e.g. 'None') Is Returned Unchanged
            if ~ischar(p) || isempty(p)
                return
            end
            p_n = chessProject.norm_path(p);
            old_n = chessProject.norm_path(old_dir);
            n = numel(old_n);
            if strncmp(p_n, old_n, n) && (numel(p_n) == n || p_n(n+1) == '/')
                p = fullfile(new_dir, p(n+1:end));
            end
        end

        function tf = same_path(a, b)
            % [NEW] Same Folder/File ('\' Or '/', Trailing Separators Ignored, Case-Insensitive On Windows)
            tf = strcmp(chessProject.norm_path(a), chessProject.norm_path(b));
        end

        function msg = name_problem(new_name, sibling_names, current_name, parent_dir)
            % '' When new_name Can Rename current_name (Project, PSE Or Alternative: A Folder Name), Else A Short Message.
            % sibling_names Exclude The Current Item; Clashes Are Case-Insensitive (Windows Folders), A Case-Only Change Is Allowed.
            % Wizards Pass current_name ''. parent_dir (Optional): Folder The Item Lives In; A Folder Or File Of That Name There
            % Is A Clash Too (Not For A Case-Only Change)
            if nargin < 4
                parent_dir = '';
            end
            new_name = char(new_name);
            reserved = [{'CON', 'PRN', 'AUX', 'NUL'}, compose('COM%d', 1:9), compose('LPT%d', 1:9)];
            if isempty(new_name)
                msg = 'Enter a name.';
            elseif any(isspace(new_name))
                msg = 'Spaces are not allowed.';
            elseif any(ismember(new_name, '\/:*?"<>|')) || any(new_name < 32)
                msg = 'These characters are not allowed: \ / : * ? " < > |';
            elseif new_name(end) == '.'
                msg = 'The name cannot end with a dot.';
            elseif any(strcmpi(extractBefore([new_name '.'], '.'), reserved)) % Windows Also Reserves "CON.txt"
                msg = sprintf('"%s" is a reserved Windows name.', new_name);
            elseif strcmp(new_name, current_name)
                msg = 'Enter a different name.';
            elseif any(strcmpi(new_name, sibling_names))
                msg = sprintf('"%s" already exists.', new_name);
            elseif ~isempty(parent_dir) && ~strcmpi(new_name, current_name) && isfile(fullfile(parent_dir, new_name))
                msg = sprintf('A file named "%s" already exists on disk (folder %s).', new_name, chessProject.folder_name(parent_dir));
            elseif ~isempty(parent_dir) && ~strcmpi(new_name, current_name) && isfolder(fullfile(parent_dir, new_name))
                msg = sprintf('A folder named "%s" already exists on disk (folder %s).', new_name, chessProject.folder_name(parent_dir));
            else
                msg = '';
            end
        end

        function suffix = stage_suffix(stage)
            % Name Suffix Of A Multi-Line Alternative: '_stage_1' | '_stage_2' ('' For stage 0)
            suffix = '';
            if stage > 0
                suffix = sprintf('_stage_%d', stage);
            end
        end

        function msg = stage_name_problem(new_name, stage)
            % '' When new_name Keeps The Multi-Line Suffix Of Its Stage (stage_suffix; Any Name For stage 0), Else A Short Message
            msg = '';
            suffix = chessProject.stage_suffix(stage);
            if ~endsWith(char(new_name), suffix) || strcmp(char(new_name), suffix)
                msg = sprintf('A multi-line stage %d alternative name must end with "%s".', stage, suffix);
            end
        end

        function msg = db_name_problem(name)
            % '' When name Is A Valid Storm DB Name (name_problem Rules), Else A Short Message. A Name Ending With "_raw_files"
            % Would Collide With <db>_raw_files.mat (Library chess_paths). Clashes With Existing Storm DBs Are Not Problems Here
            % (Overwrite, Confirmed At Import)
            msg = chessProject.name_problem(name, {}, '');
            if isempty(msg) && endsWith(char(name), '_raw_files', 'IgnoreCase', true)
                msg = 'The name cannot end with "_raw_files".';
            end
        end

        function leftover = delete_folder(folder)
            % Delete folder: One Atomic Move To A Temporary Name Next To It First (Fails With The Reason, e.g. A File Inside
            % Open Elsewhere, And Changes Nothing), Then rmdir Best Effort. leftover: Temporary Folder Not Fully Removed ('' If None)
            leftover = '';
            if ~isfolder(folder)
                return
            end
            tmp = tempname(fileparts(folder));
            try
                chessProject.nio_move(folder, tmp);
            catch ME
                error('CHESS:deleteFailed', ['Could not delete "%s" (%s). A file inside may be open in another program ',...
                    '(File Explorer, MATLAB): close it and try again.'], folder, chessProject.nio_reason(ME));
            end
            try
                rmdir(tmp, 's');
            catch
            end
            if isfolder(tmp)
                leftover = tmp;
            end
        end

        function move_item(src, dst, case_only)
            % Rename src -> dst (Folder Or File) As One File System Move (java.nio ATOMIC_MOVE): It Works Or Changes Nothing.
            % Not movefile: With A File Inside Locked It Copies What It Can And Leaves A Partial Copy. A Case-Only Rename Goes
            % Through A Temporary Name (Windows Is Case-Insensitive). case_only: Default false
            if nargin < 3
                case_only = false;
            end
            try
                if case_only
                    tmp = tempname(fileparts(src));
                    chessProject.nio_move(src, tmp);
                    try
                        chessProject.nio_move(tmp, dst);
                    catch ME
                        chessProject.nio_move(tmp, src);
                        rethrow(ME);
                    end
                else
                    chessProject.nio_move(src, dst);
                end
            catch ME
                error('CHESS:renameMoveFailed', ['Could not rename "%s" to "%s" (%s). A file inside may be open in another ',...
                    'program (File Explorer, MATLAB): close it and try again.'], src, dst, chessProject.nio_reason(ME));
            end
        end

        function msg = chs_dependencies_problem(chs_dir, region)
            % '' When chs_dir Is A CHS_Dependencies Folder (Bias_and_Uncertainty, Grid_Files, Probability_Masses) That, For A
            % Non-Empty region, Holds Grid_Files\<region> And Bias_and_Uncertainty\<region> (Great Lakes Studies Have No
            % Probability_Masses\<region>). Else The Message Shown To The User
            msg = '';
            if isempty(chs_dir) || ~all(isfolder(fullfile(chs_dir, {'Bias_and_Uncertainty', 'Grid_Files', 'Probability_Masses'})))
                msg = 'Selected CHS_Dependencies folder does not meet required folder structure.';
            elseif ~isempty(region) && ~all(isfolder(fullfile(chs_dir, {'Grid_Files', 'Bias_and_Uncertainty'}, region)))
                msg = sprintf('This CHS_Dependencies folder has no %s files. Select a folder containing region %s.', region, region);
            end
        end
    end

    methods (Static, Access = private)
        function nio_move(src, dst)
            % One java.nio ATOMIC_MOVE (move_item, delete_folder)
            opts = javaArray('java.nio.file.CopyOption', 1);
            opts(1) = java.nio.file.StandardCopyOption.ATOMIC_MOVE;
            java.nio.file.Files.move(java.io.File(src).toPath(), java.io.File(dst).toPath(), opts);
        end

        function name = folder_name(folder)
            % Last Folder Of A Path (Trailing Separators Ignored), For Short Messages
            [~, name, ext] = fileparts(regexprep(char(folder), '[\\/]+$', ''));
            name = [name ext];
        end

        function reason = nio_reason(ME)
            % Short Reason Of A Failed nio_move, e.g. 'access denied'
            reason = regexp(ME.message, 'java\.nio\.file\.(\w+)Exception', 'tokens', 'once');
            if isempty(reason)
                reason = strtrim(ME.message);
            else
                reason = lower(regexprep(reason{1}, '(?<=[a-z])([A-Z])', ' $1'));
            end
        end

        function [src, names] = folder_entries(root, prefix)
            % Zip Entries Of Every File And Folder Under root, Named prefix/<subpath> ('/' Separators, Folders End With '/').
            % src: File Path ('' For A Folder Entry)
            d = dir(fullfile(root, '**'));
            d = d(~ismember({d.name}, {'.', '..'}));
            rel = strrep(extractAfter(fullfile({d.folder}', {d.name}'), numel(root)), '\', '/');
            names = [{[prefix '/']}; strcat(prefix, rel)];
            src = [{''}; fullfile({d.folder}', {d.name}')];
            is_dir = [true; [d.isdir]'];
            names(is_dir & ~endsWith(names, '/')) = strcat(names(is_dir & ~endsWith(names, '/')), '/');
            src(is_dir) = {''};
        end

        function write_zip(zip_file, src, names)
            % Zip Archive Of src (Files; '' = Folder Entry) Under names, File Dates Kept. A Failed Write Leaves No Archive
            zos = java.util.zip.ZipOutputStream(java.io.FileOutputStream(zip_file));
            try
                for kk = 1:numel(names)
                    entry = java.util.zip.ZipEntry(names{kk});
                    if ~isempty(src{kk})
                        entry.setTime(java.io.File(src{kk}).lastModified());
                    end
                    zos.putNextEntry(entry);
                    if ~isempty(src{kk})
                        java.nio.file.Files.copy(java.io.File(src{kk}).toPath(), zos);
                    end
                    zos.closeEntry();
                end
                zos.close();
            catch ME
                try
                    zos.close();
                catch
                end
                delete(zip_file);
                rethrow(ME);
            end
        end

        function p = norm_path(p)
            % [NEW] Comparison Form: '/' Separators, No Trailing Separator, Lower Case On Windows. Length Matches The Input
            % (Up To Trailing Separators), So relocate_path Can Index The Original Path With It
            p = strrep(char(p), '\', '/');
            while numel(p) > 1 && p(end) == '/'
                p(end) = [];
            end
            if ispc
                p = lower(p);
            end
        end
    end
end
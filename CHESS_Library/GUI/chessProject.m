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
        stormDB_list CHSStormDBImportUI
        tide_files_list cell
        pse_tables cell
        pse_geometry cell
        stormDB_assignment cell
        project_response_files cell
        sim_record table
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
        end
    end

    %% PLOT METHODS
    methods (Access=public)
        function ax = plot_geometry(obj, pse_name, alt_name, ax, base_fnt, keep_text_box, offshore_elevation, elevation_source)
            % Library Transect Plot Of A PSE/Alternative Into ax.
            %   base_fnt: Base Font Size (Default 12, The GUI Plot Font)
            %   keep_text_box: Keep Library Offshore Slope/Elevation Text Box (Default false)
            %   offshore_elevation: Offshore Elevation For The Text Box ([] -> PSE Geometry Value, Else 'n/a')
            %   elevation_source: Label Shown Next To The Elevation (e.g. 'Storm DB: SP123')
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
            % Get Structure For PSE/Alternative
            structure = obj.get_project_field('pse_geometry', pse_name, alt_name, 'alt');
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
            obj.stormDB_assignment = {};
            obj.project_response_files = {};
        end

        function remove_pse(obj, pse_name)
            % Removes PSE From Every Per-PSE Field (Keeps Fields Aligned)
            indx = find(strcmp(pse_name, obj.pse_list), 1);
            if isempty(indx)
                return
            end
            fields = {'pse_list', 'alternative_list', 'pse_tables', 'pse_geometry',...
                'stormDB_assignment', 'project_response_files'};
            for kk = 1:length(fields)
                if numel(obj.(fields{kk})) >= indx
                    obj.(fields{kk})(indx) = [];
                end
            end
            obj.pse_indx = [];
            obj.alt_indx = [];
        end

        function remove_alternative(obj, pse_name, alt_name)
            % Removes Alternative From Every Per-Alternative Field (Removes PSE If Last Alternative)
            p_indx = find(strcmp(pse_name, obj.pse_list), 1);
            if isempty(p_indx) || p_indx > numel(obj.alternative_list)
                return
            end
            a_indx = find(strcmp(alt_name, obj.alternative_list{p_indx}), 1);
            if isempty(a_indx)
                return
            end
            if numel(obj.alternative_list{p_indx}) == 1
                obj.remove_pse(pse_name);
                return
            end
            fields = {'alternative_list', 'pse_tables', 'pse_geometry',...
                'stormDB_assignment', 'project_response_files'};
            for kk = 1:length(fields)
                if numel(obj.(fields{kk})) >= p_indx && iscell(obj.(fields{kk}){p_indx})...
                        && numel(obj.(fields{kk}){p_indx}) >= a_indx
                    obj.(fields{kk}){p_indx}(a_indx) = [];
                end
            end
            obj.alt_indx = [];
        end

        function n_alt = stormdb_usage(obj, db_name)
            % Number Of Alternatives Whose Last Run Used Storm Database db_name
            n_alt = 0;
            indx = find(strcmp(db_name, {obj.stormDB_list.db_name}), 1);
            if isempty(indx) || ~iscell(obj.stormDB_assignment)
                return
            end
            for pp = 1:numel(obj.stormDB_assignment)
                if iscell(obj.stormDB_assignment{pp})
                    n_alt = n_alt + sum(cellfun(@(x) isequal(x, indx), obj.stormDB_assignment{pp}));
                end
            end
        end

        function remove_stormdb(obj, db_name)
            % Removes A Storm Database. stormDB_assignment Holds Indices Into stormDB_list:
            % Alternatives Assigned To It Lose Their Assignment & Results Pointer, Later Indices Shift Down By One.
            indx = find(strcmp(db_name, {obj.stormDB_list.db_name}), 1);
            if isempty(indx)
                return
            end
            obj.stormDB_list(indx) = [];
            if iscell(obj.stormDB_assignment)
                for pp = 1:numel(obj.stormDB_assignment)
                    if ~iscell(obj.stormDB_assignment{pp})
                        continue
                    end
                    for aa = 1:numel(obj.stormDB_assignment{pp})
                        db_a = obj.stormDB_assignment{pp}{aa};
                        if isequal(db_a, indx)
                            obj.stormDB_assignment{pp}{aa} = [];
                            if numel(obj.project_response_files) >= pp && iscell(obj.project_response_files{pp})...
                                    && numel(obj.project_response_files{pp}) >= aa
                                obj.project_response_files{pp}{aa} = [];
                            end
                        elseif isnumeric(db_a) && isscalar(db_a) && db_a > indx
                            obj.stormDB_assignment{pp}{aa} = db_a - 1;
                        end
                    end
                end
            end
            obj.db_indx = [];
        end

        function sync_alt_fields(obj)
            % Sizes Per-Alternative Fields To Match alternative_list
            fields = {'stormDB_assignment', 'project_response_files'};
            nPSE = numel(obj.alternative_list);
            for kk = 1:length(fields)
                data = obj.(fields{kk});
                if ~iscell(data)
                    data = {};
                end
                data = data(1:min(numel(data), nPSE));
                for pp = 1:nPSE
                    nAlt = numel(obj.alternative_list{pp});
                    if pp > numel(data) || ~iscell(data{pp})
                        data{pp, 1} = cell(nAlt, 1);
                    elseif numel(data{pp}) < nAlt
                        data{pp}(end+1:nAlt, 1) = {[]};
                    else
                        data{pp} = data{pp}(1:nAlt);
                    end
                end
                obj.(fields{kk}) = data(:);
            end
        end

        function relocate(obj, new_root)
            % [NEW] Project Folder Moved/Copied To new_root (Import From Another Location): Stored Paths Under
            % <path>\<name> (Tide Files, Response Files, Storm DB Files) Point Into <new_root>\<name>, Subpaths Unchanged.
            % source_paths (CHS Sources Outside The Project) And outpath_dirlist (Rebuilt On Use) Are Left As Is
            old_dir = fullfile(obj.path, obj.name);
            new_dir = fullfile(new_root, obj.name);
            remap = @(p) chessProject.relocate_path(p, old_dir, new_dir);
            obj.tide_files_list = cellfun(remap, obj.tide_files_list, 'un', false);
            for pp = 1:numel(obj.project_response_files)
                if ~iscell(obj.project_response_files{pp})
                    continue
                end
                for aa = 1:numel(obj.project_response_files{pp})
                    f = obj.project_response_files{pp}{aa};
                    if ischar(f) && ~isempty(f)
                        obj.project_response_files{pp}{aa} = remap(f);
                    end
                end
            end
            for kk = 1:numel(obj.stormDB_list)
                dbObj = obj.stormDB_list(kk);
                dbObj.outpath = remap(dbObj.outpath);
                if isstruct(dbObj.output_paths)
                    flds = fieldnames(dbObj.output_paths);
                    for ff = 1:numel(flds)
                        dbObj.output_paths.(flds{ff}) = remap(dbObj.output_paths.(flds{ff}));
                    end
                end
            end
            obj.path = new_root;
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
    end

    methods (Static, Access = private)
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
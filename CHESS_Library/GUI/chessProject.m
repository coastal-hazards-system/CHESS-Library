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
        chs_dependencies char = '' % CHS_Dependencies Folder Of The Project Region (project_region), Set By The First CHS Storm DB
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

        function leftover = remove_alternative(obj, pse_name, alt_name, delete_files)
            % Removes Alternative From Every Per-Alternative Field (Removes PSE If Last Alternative). delete_files (Default
            % false): Its Folder <path>\<name>\PSE\<pse>\<alt> (The PSE Folder For The Last Alternative) Is Deleted First
            % (delete_folder; An Error Leaves The Project Unchanged). leftover: Path Not Fully Removed ('' If None)
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
            if numel(obj.alternative_list{p_indx}) == 1
                leftover = obj.remove_pse(pse_name, delete_files);
                return
            end
            if delete_files
                leftover = chessProject.delete_folder(fullfile(obj.path, obj.name, 'PSE', pse_name, alt_name));
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
            % Alternatives Assigned To It Lose Their Assignment & Results Pointer (clear_stormdb_links), Later Indices Shift Down By One.
            indx = find(strcmp(db_name, {obj.stormDB_list.db_name}), 1);
            if isempty(indx)
                return
            end
            obj.clear_stormdb_links(db_name);
            obj.stormDB_list(indx) = [];
            if iscell(obj.stormDB_assignment)
                for pp = 1:numel(obj.stormDB_assignment)
                    if ~iscell(obj.stormDB_assignment{pp})
                        continue
                    end
                    for aa = 1:numel(obj.stormDB_assignment{pp})
                        db_a = obj.stormDB_assignment{pp}{aa};
                        if isnumeric(db_a) && isscalar(db_a) && db_a > indx
                            obj.stormDB_assignment{pp}{aa} = db_a - 1;
                        end
                    end
                end
            end
            obj.db_indx = [];
        end

        function clear_stormdb_links(obj, db_name)
            % Alternatives Assigned To Storm Database db_name Lose Their Assignment & Results Pointer (Entry Itself Kept)
            indx = find(strcmp(db_name, {obj.stormDB_list.db_name}), 1);
            if isempty(indx) || ~iscell(obj.stormDB_assignment)
                return
            end
            for pp = 1:numel(obj.stormDB_assignment)
                if ~iscell(obj.stormDB_assignment{pp})
                    continue
                end
                for aa = 1:numel(obj.stormDB_assignment{pp})
                    if isequal(obj.stormDB_assignment{pp}{aa}, indx)
                        obj.stormDB_assignment{pp}{aa} = [];
                        if numel(obj.project_response_files) >= pp && iscell(obj.project_response_files{pp})...
                                && numel(obj.project_response_files{pp}) >= aa
                            obj.project_response_files{pp}{aa} = [];
                        end
                    end
                end
            end
        end

        function files = stormdb_run_files(obj, db_name)
            % Run Files Of Storm Database db_name In Every Alternative (Library chess_paths:
            % PSE\<pse>\<alt>\<wf_folder>\<db>_<wflow_name>_<config_file|project_forcing|project_responses|sampling_seed>.mat,
            % Run Backups *_prev.mat Included). Exact Name Match (Case-Insensitive, Windows): A Storm DB Whose Name Only
            % Starts With db_name Is Not Picked Up
            files = cell(0, 1);
            pse_dir = fullfile(obj.path, obj.name, 'PSE');
            wf = {'PROS', 'PROS-(RB|FB)'; 'DET', 'DET'; 'LCS', 'LCS'};
            for kk = 1:size(wf, 1)
                d = dir(fullfile(pse_dir, '*', '*', wf{kk, 1}, '*.mat'));
                pat = ['^' regexptranslate('escape', db_name) '_' wf{kk, 2}...
                    '_(config_file|project_forcing|project_responses|sampling_seed)(_prev)?\.mat$'];
                keep = ~cellfun(@isempty, regexpi({d.name}, pat, 'once'));
                files = [files; fullfile({d(keep).folder}', {d(keep).name}')]; %#ok<AGROW>
            end
        end

        function lines = stormdb_tied_sims(obj, db_name)
            % Simulations Tied To Storm Database db_name, One Line Per Alternative: '<pse> / <alt>  (<workflows>)' From Its
            % Run Files (stormdb_run_files; Workflow = File Name Token After '<db>_', e.g. PROS-RB), Or
            % '<pse> / <alt>  (linked, no saved results)' For An Alternative Assigned To It Without Run Files
            keys = cell(0, 1);
            wfs = cell(0, 1);
            files = obj.stormdb_run_files(db_name);
            for ff = 1:numel(files)
                parts = strsplit(files{ff}, filesep); % ...\PSE\<pse>\<alt>\<wf_folder>\<file> (Folder Names May Contain Dots)
                key = [parts{end-3} ' / ' parts{end-2}];
                [~, fname] = fileparts(files{ff});
                wf = regexp(fname(numel(db_name)+2:end), '^[^_]+', 'match', 'once');
                kk = find(strcmpi(key, keys), 1);
                if isempty(kk)
                    keys{end+1, 1} = key; %#ok<AGROW>
                    wfs{end+1, 1} = {wf}; %#ok<AGROW>
                elseif ~any(strcmpi(wf, wfs{kk}))
                    wfs{kk}{end+1} = wf;
                end
            end
            indx = find(strcmp(db_name, {obj.stormDB_list.db_name}), 1);
            if ~isempty(indx) && iscell(obj.stormDB_assignment)
                for pp = 1:min(numel(obj.stormDB_assignment), numel(obj.pse_list))
                    if ~iscell(obj.stormDB_assignment{pp})
                        continue
                    end
                    for aa = 1:min(numel(obj.stormDB_assignment{pp}), numel(obj.alternative_list{pp}))
                        key = [obj.pse_list{pp} ' / ' obj.alternative_list{pp}{aa}];
                        if isequal(obj.stormDB_assignment{pp}{aa}, indx) && ~any(strcmpi(key, keys))
                            keys{end+1, 1} = key; %#ok<AGROW>
                            wfs{end+1, 1} = {'linked, no saved results'}; %#ok<AGROW>
                        end
                    end
                end
            end
            lines = cellfun(@(k, w) [k '  (' strjoin(w, ', ') ')'], keys, wfs, 'un', false);
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
            % <path>\<name> Point Into <new_root>\<name> (remap_paths)
            obj.remap_paths(fullfile(obj.path, obj.name), fullfile(new_root, obj.name));
            obj.path = new_root;
        end

        function remap_paths(obj, old_dir, new_dir)
            % Stored Paths Under old_dir (Tide Files, Response Files, Storm DB Files, chs_dependencies) -> Same Subpath Under
            % new_dir. source_paths (CHS Sources Outside The Project) And outpath_dirlist (Rebuilt On Use) Are Left As Is
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
            switch level
                case 'proj'
                    obj.name = new_name;
                case 'pse'
                    obj.pse_list{p} = new_name;
                case 'alt'
                    obj.alternative_list{p}{a} = new_name;
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
classdef Project < handle
    % Project  A CHESS project: its PSEs, alternatives, storm databases and runs.
    %   project = chess.Project.create(name, root_folder, vertical_datum, confidence_limits)
    %   project = chess.Project.open(project_folder)
    %
    %   One record of a project for script runs and for the GUI. The project
    %   folder is <root_folder>\<name>, laid out by chess.ProjectPaths.build:
    %       <root_folder>\<name>\
    %           CHESS_project_<name>.mat        project file (save, open)
    %           Event_Database\                 storm databases
    %           PSE\<pse>\<alternative>\<PROS|DET|LCS>\   run files
    %
    %   A project holds PSEs; a PSE holds alternatives; an alternative holds
    %   its structure type, its inputs and its runs (one per storm database
    %   and workflow with a responses file). A multi-line PSE holds one
    %   stage 1 alternative (offshore line) and its stage 2 alternatives
    %   (lines behind it), and nothing else.
    %
    %   The project file holds a plain struct (variable project). Paths
    %   inside the project folder are saved relative to it, so a project
    %   folder can be moved or copied and opened where it is.
    %
    %   See also chess.Model, chess.ProtectionSystem, chess.CoastalHazardSystem,
    %   chess.ProjectPaths.build.
    %
    %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

    properties
        name char                       % project name (also its folder name)
        root_folder char                % folder that contains the project folder
        vertical_datum char             % vertical datum label of the project
        confidence_limits double        % percentiles of the confidence limits (0 = not used), 1 x 4
        chs_dependencies char = ''      % CHS_Dependencies folder of the project region
        pses                            % PSEs, n x 1 struct: name, alternatives (n x 1 struct: name, structure_type, inputs, stage, runs)
        storm_databases                 % storm database records, n x 1 struct (chess.Project.storm_database_fields)
        tide_files cell = cell(0, 1)    % tide files of the project, n x 1 cell of char
    end

    properties (SetAccess = private)
        unit_system char = 'SI'         % 'SI' or 'Imperial': unit system of the alternative inputs and run settings as entered, and of displayed/exported results
    end

    properties (Dependent)
        folder                          % project folder, <root_folder>\<name>
        project_file                    % project file, <folder>\CHESS_project_<name>.mat
    end

    properties (Constant, Access = private)
        format_version = 1              % version of the saved project struct
        folder_token = '<project>'      % stands for the project folder in saved paths
    end

    %% CREATE, OPEN, SAVE
    methods (Static)
        function project = create(name, root_folder, vertical_datum, confidence_limits, unit_system)
            % create  New, empty project (nothing is written until save).
            %   project = chess.Project.create(name, root_folder, vertical_datum, confidence_limits)
            %   project = chess.Project.create(..., unit_system)
            %   confidence_limits: up to 4 percentiles (missing ones are 0).
            %   unit_system: 'SI' (default) or 'Imperial'.
            if nargin < 5
                unit_system = 'SI';
            end
            problem = chess.Project.name_problem(name);
            if ~isempty(problem)
                error('chess:Project:invalidName', '%s', problem);
            end
            project = chess.Project();
            project.name = char(name);
            project.root_folder = char(root_folder);
            project.vertical_datum = char(vertical_datum);
            limits = zeros(1, 4);
            limits(1:numel(confidence_limits)) = confidence_limits(:)';
            project.confidence_limits = limits;
            project.unit_system = char(unit_system);
        end

        function project = open(source)
            % open  Open a project from its folder or its project file.
            %   project = chess.Project.open(project_folder)
            %   project = chess.Project.open(project_file)
            %   The project is opened where it is: root_folder is the folder
            %   that holds the project folder, and saved paths inside the
            %   project folder point into it. A CHS_Dependencies folder
            %   inside the project folder is used as chs_dependencies.
            %   A project file of the v2.0.0 CHESS GUI errors
            %   (chess:Project:oldProjectFormat): convert it once with
            %   CHESS_Library/Tools/convert_v2_project.
            %   Nothing is locked and the runs are not synced with the
            %   disk (sync_runs).
            source = char(source);
            if isfolder(source)
                project_folder = source;
                [~, folder_name] = fileparts(project_folder);
                file = fullfile(project_folder, ['CHESS_project_' folder_name '.mat']);
            else
                file = source;
                project_folder = fileparts(file);
            end
            if ~isfile(file)
                error('chess:Project:noProjectFile', 'Project file not found: %s', file);
            end
            project_folder = chess.Project.full_path(project_folder);
            [root_folder, folder_name] = fileparts(project_folder);
            variables = who('-file', file);
            if ismember('project', variables)
                saved = load(file, 'project');
                project = chess.Project.from_saved_struct(saved.project, project_folder);
            elseif ismember('chess_project', variables)
                error('chess:Project:oldProjectFormat', ['This project file was written by the v2.0.0 CHESS GUI: %s\n',...
                    'Convert it once with CHESS_Library/Tools/convert_v2_project (see its README.md), then open it again.'], file);
            else
                error('chess:Project:notAProjectFile', 'Not a CHESS project file: %s', file);
            end
            if ~strcmp(project.name, folder_name)
                error('chess:Project:folderName', 'The project file must be inside its project folder "%s" (found in "%s").',...
                    project.name, folder_name);
            end
            project.root_folder = root_folder;
            bundled_dependencies = fullfile(project_folder, 'CHS_Dependencies');
            if isfolder(bundled_dependencies)
                project.chs_dependencies = bundled_dependencies;
            end
        end
    end

    methods
        function save(obj)
            % save  Write the project file (plain struct, variable project).
            %   project.save()
            %   Paths inside the project folder are saved relative to it.
            project = struct('format_version', obj.format_version, 'name', obj.name,...
                'vertical_datum', obj.vertical_datum, 'confidence_limits', obj.confidence_limits,...
                'unit_system', obj.unit_system, 'chs_dependencies', obj.chs_dependencies);
            project.pses = obj.pses;
            project.storm_databases = chess.Project.replace_path_start(obj.storm_databases, obj.folder, obj.folder_token);
            project.tide_files = chess.Project.replace_path_start(obj.tide_files, obj.folder, obj.folder_token);
            if ~isfolder(obj.folder)
                mkdir(obj.folder);
            end
            save(obj.project_file, 'project', '-v7.3');
        end

        function value = get.folder(obj)
            value = fullfile(obj.root_folder, obj.name);
        end

        function value = get.project_file(obj)
            value = fullfile(obj.folder, ['CHESS_project_' obj.name '.mat']);
        end
    end

    %% PSES AND ALTERNATIVES
    methods
        function names = pse_names(obj)
            % pse_names  Names of the PSEs of the project, n x 1 cell of char.
            names = reshape({obj.pses.name}, [], 1);
        end

        function names = alternative_names(obj, pse)
            % alternative_names  Names of the alternatives of a PSE, n x 1 cell of char.
            %   names = project.alternative_names(pse)
            p = obj.pse_position(pse);
            names = reshape({obj.pses(p).alternatives.name}, [], 1);
        end

        function tf = has_alternative(obj, pse, alternative)
            % has_alternative  True when the project holds that alternative of that PSE.
            %   tf = project.has_alternative(pse, alternative)
            p = find(strcmp(pse, {obj.pses.name}), 1);
            tf = ~isempty(p) && any(strcmp(alternative, {obj.pses(p).alternatives.name}));
        end

        function record = alternative(obj, pse, alternative)
            % alternative  Record of one alternative.
            %   record = project.alternative(pse, alternative)
            %   record: struct with name, structure_type (1 levee, 2
            %   floodwall, 3 rubble mound), inputs (PSE inputs, struct),
            %   stage (0 single line, 1 offshore line, 2 line behind) and
            %   runs (chess.Project.empty_runs rows).
            [p, a] = obj.alternative_position(pse, alternative);
            record = obj.pses(p).alternatives(a);
        end

        function add_pse(obj, pse)
            % add_pse  Add a PSE without alternatives.
            %   project.add_pse(pse)
            problem = chess.Project.name_problem(pse, obj.pse_names());
            if ~isempty(problem)
                error('chess:Project:invalidName', '%s', problem);
            end
            obj.pses(end+1, 1) = struct('name', char(pse), 'alternatives', chess.Project.empty_alternatives());
        end

        function add_alternative(obj, pse, alternative, structure_type, inputs, stage, check_inputs)
            % add_alternative  Add an alternative to a PSE (the PSE is added when new).
            %   project.add_alternative(pse, alternative, structure_type, inputs)
            %   project.add_alternative(pse, alternative, structure_type, inputs, stage)
            %   project.add_alternative(..., stage, check_inputs)
            %   structure_type: 1 levee, 2 floodwall, 3 rubble mound.
            %   inputs: PSE inputs, struct with one field per geometry and
            %   property input of that structure (project unit system); they must build the
            %   protection system (chess.ProtectionSystem.create) unless check_inputs is false.
            %   stage: 0 single line (default), 1 offshore line of a
            %   multi-line PSE, 2 line behind it. A multi-line PSE holds one
            %   stage 1 alternative, added first, and stage 2 alternatives
            %   only.
            %   check_inputs: true (default) or false: the inputs are kept
            %   as given without building the protection system (inputs
            %   saved by an earlier CHESS version, e.g. by
            %   Tools/convert_v2_project; complete them with set_inputs).
            if nargin < 6
                stage = 0;
            end
            if nargin < 7
                check_inputs = true;
            end
            if ~any(strcmp(pse, {obj.pses.name}))
                obj.add_pse(pse);
            end
            p = obj.pse_position(pse);
            problem = chess.Project.name_problem(alternative, obj.alternative_names(pse));
            if isempty(problem) && ismember(stage, [1 2])
                problem = chess.Project.stage_name_problem(alternative, stage);
            end
            if ~isempty(problem)
                error('chess:Project:invalidName', '%s', problem);
            end
            stages = [obj.pses(p).alternatives.stage];
            if ~ismember(stage, [0 1 2])
                error('chess:Project:invalidStage', 'stage must be 0 (single line), 1 (offshore line) or 2 (line behind).');
            elseif stage == 0 && any(stages ~= 0)
                error('chess:Project:invalidStage', 'PSE "%s" is a multi-line PSE: its alternatives are stage 1 or stage 2.', pse);
            elseif stage ~= 0 && any(stages == 0)
                error('chess:Project:invalidStage', 'PSE "%s" holds single-line alternatives: it cannot take a stage %d alternative.', pse, stage);
            elseif stage == 1 && any(stages == 1)
                error('chess:Project:invalidStage', 'PSE "%s" already has a stage 1 alternative.', pse);
            elseif stage == 2 && ~any(stages == 1)
                error('chess:Project:invalidStage', 'PSE "%s" needs its stage 1 alternative before a stage 2 alternative.', pse);
            end
            if check_inputs
                chess.Project.build_protection_system(structure_type, inputs, obj.unit_system); % Errors When The Inputs Do Not Build The Structure
            end
            obj.pses(p).alternatives(end+1, 1) = struct('name', char(alternative), 'structure_type', structure_type,...
                'inputs', inputs, 'stage', stage, 'runs', chess.Project.empty_runs());
        end

        function set_inputs(obj, pse, alternative, inputs)
            % set_inputs  Replace the PSE inputs of an alternative.
            %   project.set_inputs(pse, alternative, inputs)
            %   inputs: PSE inputs in the project unit system. The inputs
            %   must build the protection system. Saved runs are not touched.
            [p, a] = obj.alternative_position(pse, alternative);
            chess.Project.build_protection_system(obj.pses(p).alternatives(a).structure_type, inputs, obj.unit_system);
            obj.pses(p).alternatives(a).inputs = inputs;
        end

        function protection_system = protection_system(obj, pse, alternative)
            % protection_system  Protection system of an alternative.
            %   protection_system = project.protection_system(pse, alternative)
            %   chess.ProtectionSystem.Levee, .Floodwall or .RubbleMound built
            %   from the inputs of the alternative (converted to SI,
            %   chess.Config.to_SI); multiline_stage is set from its stage.
            record = obj.alternative(pse, alternative);
            protection_system = chess.Project.build_protection_system(record.structure_type, record.inputs, obj.unit_system);
            protection_system.multiline_stage = record.stage;
        end

        function structure = structure(obj, pse, alternative)
            % structure  Structure of an alternative as a plain struct (protection_system(...).to_struct(), SI).
            %   structure = project.structure(pse, alternative)
            structure = obj.protection_system(pse, alternative).to_struct();
        end

        function stage = stage(obj, pse, alternative)
            % stage  Multi-line stage of an alternative: 0 single line, 1 offshore line, 2 line behind.
            %   stage = project.stage(pse, alternative)
            stage = obj.alternative(pse, alternative).stage;
        end

        function tf = is_multiline(obj, pse)
            % is_multiline  True when the PSE is a multi-line transect (has a stage 1 alternative).
            %   tf = project.is_multiline(pse)
            p = obj.pse_position(pse);
            tf = any([obj.pses(p).alternatives.stage] == 1);
        end

        function name = stage1_alternative(obj, pse)
            % stage1_alternative  Stage 1 alternative of a multi-line PSE ('' when it is not one).
            %   name = project.stage1_alternative(pse)
            p = obj.pse_position(pse);
            name = '';
            a = find([obj.pses(p).alternatives.stage] == 1, 1);
            if ~isempty(a)
                name = obj.pses(p).alternatives(a).name;
            end
        end

        function names = multiline_pse_names(obj)
            % multiline_pse_names  Names of the multi-line PSEs of the project, n x 1 cell of char.
            names = obj.pse_names();
            names = names(cellfun(@(pse) obj.is_multiline(pse), names));
        end

        function names = stage2_alternatives(obj, pse)
            % stage2_alternatives  Stage 2 alternatives of a multi-line PSE, n x 1 cell of char.
            %   names = project.stage2_alternatives(pse)
            p = obj.pse_position(pse);
            names = reshape({obj.pses(p).alternatives([obj.pses(p).alternatives.stage] == 2).name}, [], 1);
        end
    end

    %% STORM DATABASES AND TIDE FILES
    methods
        function names = storm_database_names(obj)
            % storm_database_names  Names of the storm databases of the project, n x 1 cell of char.
            names = reshape({obj.storm_databases.db_name}, [], 1);
        end

        function record = storm_database(obj, name)
            % storm_database  Record of one storm database (chess.Project.storm_database_fields).
            %   record = project.storm_database(name)
            k = find(strcmp(name, {obj.storm_databases.db_name}), 1);
            if isempty(k)
                error('chess:Project:unknownStormDatabase', 'Project "%s" has no storm database "%s".', obj.name, char(name));
            end
            record = obj.storm_databases(k);
        end

        function add_storm_database(obj, record)
            % add_storm_database  Add a storm database record, or replace the record of the same name.
            %   project.add_storm_database(record)
            %   record: struct with the fields of
            %   chess.Project.storm_database_fields.
            fields = chess.Project.storm_database_fields();
            missing = setdiff(fields, fieldnames(record));
            if ~isempty(missing)
                error('chess:Project:invalidStormDatabase', 'The storm database record needs the field(s): %s.', strjoin(missing, ', '));
            end
            record = orderfields(rmfield(record, setdiff(fieldnames(record), fields)), obj.storm_databases);
            k = find(strcmp(record.db_name, {obj.storm_databases.db_name}), 1);
            if isempty(k)
                k = numel(obj.storm_databases) + 1;
            end
            obj.storm_databases(k, 1) = record;
        end

        function record = import_storm_database(obj, name, source, create_wlp, create_whp, datum_offset, replace)
            % import_storm_database  Build a storm database from storm data and add it to the project.
            %   record = project.import_storm_database(name, source)
            %   record = project.import_storm_database(name, source, create_wlp, create_whp, datum_offset, replace)
            %   name: storm database name (the file is
            %   <project folder>\Event_Database\<name>.mat).
            %   source: CHS .zip, CHS_Data .mat or storm .mat (storm +
            %   prob_mass), see chess.CoastalHazardSystem.
            %   create_wlp, create_whp: also build the water level priority
            %   and wave height priority Peaks (0/1, default 0; CHS input
            %   with Peaks and Timeseries only).
            %   datum_offset: added to every water level [m], study datum
            %   to project datum (default 0).
            %   replace (default false): what happens when the name is in
            %   use (storm_database_clash).
            %     false: the existing storm database is kept as is and
            %     nothing is built. One of the project is returned; a
            %     database file in Event_Database that is not in the
            %     project is added to it (built again when it does not
            %     hold what the source and the request give). The source
            %     is not compared with the existing storm data, and
            %     datum_offset is not applied to it. Asking for WLP / WHP
            %     that a storm database of the project does not hold is
            %     an error.
            %     true: the storm database is built again from the source
            %     and replaces the existing one, files and runs
            %     (add_built_storm_database).
            %   The three steps in a row: inspect_storm_data,
            %   build_storm_database, add_built_storm_database (the GUI
            %   wizard runs them one by one). A storm .mat is taken as the
            %   study its file name gives (<region>_SP<id>), else as
            %   Custom_Modeling; use the three steps with
            %   chess.CoastalHazardSystem.set_study to state another.
            %   The project is not saved (save).
            %   record: the storm database record added to the project.
            if nargin < 4
                create_wlp = 0;
            end
            if nargin < 5
                create_whp = 0;
            end
            if nargin < 6
                datum_offset = 0;
            end
            if nargin < 7
                replace = false;
            end
            name = char(name);
            problem = chess.Project.storm_database_name_problem(name);
            if ~isempty(problem)
                error('chess:Project:invalidName', '%s', problem);
            end
            if ~replace
                % Name In Use: The Existing Storm Database Is Kept (Hotstart)
                [in_project, on_disk, existing_name] = obj.storm_database_clash(name);
                if in_project && isfile(fullfile(obj.folder, 'Event_Database', [existing_name '.mat']))
                    record = obj.storm_database(existing_name);
                    labels = {'WLP', 'WHP'};
                    missing = labels([create_wlp == 1 && record.create_wlp ~= 1, create_whp == 1 && record.create_whp ~= 1]);
                    if ~isempty(missing)
                        error('chess:Project:notCovered', ['Storm database "%s" of project "%s" has no %s Peaks ',...
                            '(replace = true builds it again and deletes its runs).'], existing_name, obj.name, strjoin(missing, ' and '));
                    end
                    return
                elseif ~in_project && on_disk
                    record = obj.add_existing_storm_database(name, source, create_wlp, create_whp);
                    if ~isempty(record)
                        return
                    end
                    replace = true; % The Files Do Not Hold The Request And No Run Belongs To Them: Built Again
                end
            end
            obj.check_storm_database_name(name, replace);
            database = obj.inspect_storm_data(source);
            try
                obj.build_storm_database(database, create_wlp, create_whp, datum_offset);
                record = obj.add_built_storm_database(name, database, replace);
            catch failure
                obj.discard_built_storm_database();
                rethrow(failure);
            end
        end

        function database = inspect_storm_data(obj, source, chs_dependencies)
            % inspect_storm_data  Describe storm data to import into the project (nothing is converted or built).
            %   database = project.inspect_storm_data(source)
            %   database = project.inspect_storm_data(source, chs_dependencies)
            %   source: CHS .zip, CHS_Data .mat or storm .mat.
            %   chs_dependencies: CHS_Dependencies folder to build with
            %   (default: the folder of the project).
            %   database: chess.CoastalHazardSystem of the source (region,
            %   savepoint, vertical datum, source_contents). Its database
            %   file is in the holding folder of the project
            %   (Event_Database\_import_staging), where build_storm_database
            %   builds it; a database left there by an earlier import is
            %   discarded. Storm data of another region than the storm
            %   databases of the project is an error.
            if nargin < 3
                chs_dependencies = obj.chs_dependencies;
            end
            source = char(source);
            if ~isfile(source)
                error('chess:Project:noStormData', 'Storm data not found: %s', source);
            end
            obj.discard_built_storm_database();
            database = chess.CoastalHazardSystem(source, char(chs_dependencies), fullfile(obj.storm_database_holding_folder(), 'staged.mat'));
            problem = obj.storm_data_region_problem(database);
            if ~isempty(problem)
                error('chess:Project:otherRegion', '%s', problem);
            end
        end

        function build_storm_database(obj, database, create_wlp, create_whp, datum_offset, progress_function)
            % build_storm_database  Build the storm database of inspected storm data in the holding folder of the project.
            %   project.build_storm_database(database)
            %   project.build_storm_database(database, create_wlp, create_whp, datum_offset, progress_function)
            %   database: from inspect_storm_data.
            %   create_wlp, create_whp: also build the water level priority
            %   and wave height priority Peaks (0/1, default 0; CHS input
            %   with Peaks and Timeseries only). A storm .mat brings its
            %   own datasets.
            %   datum_offset: added to every water level [m] (default 0).
            %   progress_function: progress_function(fraction, message),
            %   see chess.CoastalHazardSystem.build (default []: none).
            %   Every complete storm type and data type of the source is
            %   built. The database is not part of the project until
            %   add_built_storm_database; building again replaces it (the
            %   converted CHS storm files are kept).
            if nargin < 3
                create_wlp = 0;
            end
            if nargin < 4
                create_whp = 0;
            end
            if nargin < 5
                datum_offset = 0;
            end
            if nargin < 6
                progress_function = [];
            end
            problem = obj.storm_data_region_problem(database);
            if ~isempty(problem)
                error('chess:Project:otherRegion', '%s', problem);
            end
            contents = database.source_contents();
            holding_folder = obj.storm_database_holding_folder();
            if ~isfolder(holding_folder)
                mkdir(holding_folder);
            end
            database.delete_database();
            if strcmp(database.source_kind, 'storm_mat')
                database.import_user_storm(contents.storm_sampling, double(contents.has_peaks), double(contents.has_timeseries),...
                    double(contents.has_wlp), double(contents.has_whp));
            else
                database.build(contents.storm_sampling, double(contents.has_peaks), double(contents.has_timeseries),...
                    double(create_wlp == 1), double(create_whp == 1), true, progress_function);
            end
            database.apply_datum_offset(datum_offset);
        end

        function [record, replaced, not_deleted] = add_built_storm_database(obj, name, database, replace)
            % add_built_storm_database  Add the storm database built in the holding folder to the project under a name.
            %   record = project.add_built_storm_database(name, database)
            %   [record, replaced, not_deleted] = project.add_built_storm_database(name, database, replace)
            %   database: from inspect_storm_data, built with
            %   build_storm_database.
            %   replace (default false): true replaces a storm database of
            %   that name (storm_database_clash); a name in use is an
            %   error otherwise.
            %   The built files take the names <name>.mat and
            %   <name>_raw_files.mat in Event_Database in one step each:
            %   when a move fails, the earlier files are put back. A
            %   replaced storm database of the project loses its runs: the
            %   run files are deleted and their rows dropped (the results
            %   belong to the old storm data). The CHS_Dependencies folder
            %   the database was built with becomes the folder of the
            %   project when the project has no usable one. The project is
            %   not saved (save).
            %   record: the storm database record added to the project.
            %   replaced: record of the replaced storm database ([] when none).
            %   not_deleted: run files of the replaced storm database that
            %   could not be deleted, n x 1 cell of char.
            if nargin < 4
                replace = false;
            end
            name = char(name);
            holding_folder = obj.storm_database_holding_folder();
            if ~strcmpi(fileparts(database.database_file), holding_folder) || ~isfile(database.database_file)
                error('chess:Project:notBuilt', 'No storm database is built for project "%s": use inspect_storm_data and build_storm_database first.', obj.name);
            end
            [in_project, ~, existing_name] = obj.check_storm_database_name(name, replace);
            problem = obj.storm_data_region_problem(database);
            if ~isempty(problem)
                error('chess:Project:otherRegion', '%s', problem);
            end
            % Built Files Take Their Names (An Earlier Raw File Goes When The New Database Has None)
            database_folder = fullfile(obj.folder, 'Event_Database');
            database_file = fullfile(database_folder, [name '.mat']);
            raw_file = fullfile(database_folder, [name '_raw_files.mat']);
            chess.Project.place_built_files({database.database_file, database.raw_file}, {database_file, raw_file}, holding_folder);
            % Replaced Storm Database Of The Project: Its Runs Go, Its Place In The List Is Kept
            replaced = [];
            not_deleted = cell(0, 1);
            if in_project
                replaced = obj.storm_database(existing_name);
                for file = obj.storm_database_run_files(existing_name)'
                    delete(file{1});
                    if isfile(file{1})
                        not_deleted{end+1, 1} = file{1}; %#ok<AGROW>
                    end
                end
                obj.drop_storm_database_runs(existing_name);
                obj.storm_databases(strcmp(existing_name, {obj.storm_databases.db_name})).db_name = name;
            end
            record = obj.add_storm_database_record(name, database);
            obj.discard_built_storm_database();
        end

        function discard_built_storm_database(obj)
            % discard_built_storm_database  Delete the holding folder of the project (a storm database built but not added).
            holding_folder = obj.storm_database_holding_folder();
            if isfolder(holding_folder)
                try
                    rmdir(holding_folder, 's');
                catch
                    % A File Open Elsewhere: Left For The Next Import
                end
            end
        end

        function [in_project, on_disk, existing_name] = storm_database_clash(obj, name)
            % storm_database_clash  Whether a storm database name is in use in the project or on disk.
            %   [in_project, on_disk, existing_name] = project.storm_database_clash(name)
            %   in_project: a storm database of the project has the name
            %   (in any case; existing_name: the name as the project has it).
            %   on_disk: <name>.mat or <name>_raw_files.mat is in
            %   Event_Database.
            name = char(name);
            names = obj.storm_database_names();
            k = find(strcmpi(name, names), 1);
            in_project = ~isempty(k);
            existing_name = name;
            if in_project
                existing_name = names{k};
            end
            database_folder = fullfile(obj.folder, 'Event_Database');
            on_disk = isfile(fullfile(database_folder, [name '.mat'])) || isfile(fullfile(database_folder, [name '_raw_files.mat']));
        end

        function problem = storm_data_region_problem(obj, database)
            % storm_data_region_problem  '' when storm data can join the storm databases of the project, else why not.
            %   problem = project.storm_data_region_problem(database)
            %   database: chess.CoastalHazardSystem (inspect_storm_data).
            %   The storm databases of a project are of one CHS region;
            %   Custom_Modeling storm data has none and always fits.
            problem = '';
            project_region = obj.region();
            if ~isempty(project_region) && ~any(strcmp(database.region, {'Custom_Modeling', project_region}))
                problem = sprintf('The storm data is of region %s; the storm databases of project "%s" are of region %s.',...
                    database.region, obj.name, project_region);
            end
        end

        function file = download_tide_file(obj, station, datum, start_date, file_name, progress_function)
            % download_tide_file  Download one year of NOAA tide predictions into the project and add the tide file.
            %   file = project.download_tide_file(station, datum, start_date, file_name)
            %   file = project.download_tide_file(..., progress_function)
            %   station, datum, start_date ('yyyyMMdd'), progress_function:
            %   as chess.NOAA.create_tide_file (harmonic stations only).
            %   file_name: name of the tide file, with or without .csv.
            %   The file is written to tide_file_path(file_name) (a file
            %   of that name is replaced) and added to the tide files of
            %   the project. The project is not saved (save).
            if nargin < 6
                progress_function = [];
            end
            file = obj.tide_file_path(file_name);
            if ~isfolder(fileparts(file))
                mkdir(fileparts(file));
            end
            chess.NOAA.create_tide_file(station, datum, start_date, file, progress_function, struct('harmonic_predictions', true));
            obj.add_tide_file(file);
        end

        function file = tide_file_path(obj, file_name)
            % tide_file_path  Where a tide file of a given name is kept in the project: <project folder>\Tides\<name>.csv.
            %   file = project.tide_file_path(file_name)
            [~, name] = fileparts(char(file_name));
            file = fullfile(obj.folder, 'Tides', [name '.csv']);
        end

        function remove_tide_file(obj, file_name)
            % remove_tide_file  Remove a tide file from the project by file name (the file stays on disk).
            %   project.remove_tide_file(file_name)
            [~, names, extensions] = cellfun(@fileparts, obj.tide_files, 'un', false);
            obj.tide_files(strcmp(strcat(names, extensions), file_name)) = [];
        end

        function name = default_storm_database(obj, pse, alternative)
            % default_storm_database  Storm database of the newest run of an alternative ('' when it has no run).
            %   name = project.default_storm_database(pse, alternative)
            %   Only storm databases the project still holds count.
            name = '';
            names = obj.storm_database_names();
            rows = obj.alternative(pse, alternative).runs;
            rows = rows(ismember(lower({rows.db}), lower(names)));
            if ~isempty(rows)
                [~, newest] = max([rows.resp_file_date]);
                name = names{find(strcmpi(rows(newest).db, names), 1)};
            end
        end

        function add_tide_file(obj, file)
            % add_tide_file  Add a tide file to the project (once).
            file = char(file);
            if ~any(strcmp(file, obj.tide_files))
                obj.tide_files{end+1, 1} = file;
            end
        end
    end

    %% RUNS
    methods
        function rows = runs(obj, pse, alternative)
            % runs  Runs of an alternative whose responses file exists, sorted by label.
            %   rows = project.runs(pse, alternative)
            %   rows: chess.Project.empty_runs rows. The record of the
            %   project is not changed; sync_runs brings it in line with
            %   the disk.
            [p, a] = obj.alternative_position(pse, alternative);
            rows = obj.pses(p).alternatives(a).runs;
            on_disk = false(size(rows));
            for rr = 1:numel(rows)
                on_disk(rr) = isfile(obj.responses_file(pse, alternative, rows(rr)));
            end
            rows = rows(on_disk);
            [~, order] = sort(lower(arrayfun(@chess.Project.run_label, rows, 'un', false)));
            rows = rows(order);
        end

        function record_run(obj, pse, alternative, row)
            % record_run  Add the row of a run, or replace the row of the same storm database and workflow.
            %   project.record_run(pse, alternative, row)
            %   row: chess.Project.run_from_config row.
            [p, a] = obj.alternative_position(pse, alternative);
            rows = obj.pses(p).alternatives(a).runs;
            k = find(strcmpi(row.db, {rows.db}) & strcmpi(row.workflow, {rows.workflow}), 1);
            if isempty(k)
                k = numel(rows) + 1;
            end
            rows(k, 1) = row;
            obj.pses(p).alternatives(a).runs = rows;
        end

        function info = sync_runs(obj, scope, mode)
            % sync_runs  Bring the runs of the project in line with the run files on disk.
            %   info = project.sync_runs()                     whole project, 'sync'
            %   info = project.sync_runs(scope, mode)
            %   scope: 'project' or {pse, alternative}.
            %   mode:  'sync' - rows whose responses file is gone are
            %                   dropped, rows whose responses file date
            %                   changed are reloaded, run files without a
            %                   row get one
            %          'full' - every row is rebuilt from the run files
            %   A run on disk is <db>_<workflow>_project_responses.mat in
            %   PSE\<pse>\<alternative>\<PROS|DET|LCS>; its row comes from
            %   its config file (a config file that fails to load is
            %   skipped).
            %   The whole-project sync also computes the layout of storm
            %   database records that have none (database file missing or
            %   unreadable when last tried).
            %   info: counts added, refreshed, dropped, skipped;
            %   stage1_changed / stage1_dropped: {pse, alternative, db,
            %   workflow} of stage 1 runs reloaded with another forcing
            %   stamp or transmission geometry / dropped.
            if nargin < 2
                scope = 'project';
            end
            if nargin < 3
                mode = 'sync';
            end
            info = struct('added', 0, 'refreshed', 0, 'dropped', 0, 'skipped', 0,...
                'stage1_changed', {cell(0, 4)}, 'stage1_dropped', {cell(0, 4)});
            if ischar(scope) || isstring(scope)
                obj.fill_storm_database_layouts();
                for p = 1:numel(obj.pses)
                    for a = 1:numel(obj.pses(p).alternatives)
                        info = obj.sync_alternative(p, a, mode, info);
                    end
                end
            else
                [p, a] = obj.alternative_position(scope{1}, scope{2});
                info = obj.sync_alternative(p, a, mode, info);
            end
        end
    end

    %% RUNS FROM THE PROJECT
    methods
        function settings = run_settings(obj, pse, alternative, workflow, storm_database)
            % run_settings  Default settings of a run of an alternative.
            %   settings = project.run_settings(pse, alternative, workflow, storm_database)
            %   workflow: 1 PROS-RB, 2 DET, 3 LCS, 4 PROS-FB.
            %   storm_database: name of a storm database of the project.
            %   settings: struct with the names of the CHESS input file.
            %   Change the fields the run needs and pass it to run_config,
            %   model or run:
            %     workflow, storm_database
            %     storm_sampling          'XC', 'TC' or 'CC' (a type the
            %                             storm database holds)
            %     use_peaks, use_timeseries, create_wlp, create_whp
            %     swl_slr                 sea level change [project length unit]
            %     tide_file               tide file, 'None' = no random tide
            %     apply_depth_limitation
            %     storm_duration, compute_storm_duration
            %     lcs_convergence_prompt  0 (default): an LCS run does not
            %                             stop to ask when mcs_nLC is below
            %                             the life cycles needed
            %     the workflow inputs (MCS, CSR and PROS sections) and the
            %     response switches and parameters of the structure type
            %   Defaults: the input template of the structure type
            %   (chess.Project.structure_template). A stage 1 alternative
            %   always computes the wave transmission. The dimensional
            %   settings (swl_slr, csr_cutoff_offset) are in the project unit
            %   system (chess.Config.from_SI of the SI template defaults).
            record = obj.alternative(pse, alternative);
            database = obj.storm_database(storm_database);
            chess.Model.workflows(workflow); % Errors When The Workflow Is Unknown
            template = chess.Project.structure_template(record.structure_type);
            settings = struct('workflow', workflow, 'storm_database', database.db_name);
            run_rows = [template.general; template.forcing];
            for name = {'storm_sampling', 'use_peaks', 'use_timeseries', 'create_wlp', 'create_whp', 'swl_slr',...
                    'apply_depth_limitation', 'storm_duration', 'compute_storm_duration'}
                settings.(name{1}) = run_rows{find(strcmp(name{1}, run_rows(:, 1)), 1), 4};
            end
            settings.tide_file = 'None';
            settings.lcs_convergence_prompt = 0; % A Project Run Does Not Stop To Ask (1: LCS Asks In The Command Window)
            % Storm Type And Data Types The Storm Database Holds
            layout = database.layout;
            if isstruct(layout) && isfield(layout, 'storm_types') && ~isempty(layout.storm_types)
                wanted = {settings.storm_sampling};
                if strcmp(settings.storm_sampling, 'CC')
                    wanted = {'XC', 'TC'};
                end
                if ~all(ismember(wanted, layout.storm_types))
                    settings.storm_sampling = layout.storm_types{1};
                    wanted = layout.storm_types(1);
                end
                has_peaks = all(cellfun(@(type) ismember('Peaks', layout.data_types.(type)), wanted));
                has_timeseries = all(cellfun(@(type) ismember('Timeseries', layout.data_types.(type)), wanted));
                settings.use_peaks = double(settings.use_peaks == 1 && has_peaks);
                settings.use_timeseries = double(settings.use_timeseries == 1 && has_timeseries);
                if ~settings.use_peaks && ~settings.use_timeseries
                    settings.use_timeseries = double(has_timeseries);
                    settings.use_peaks = double(~has_timeseries);
                end
                if ~(has_peaks && has_timeseries)
                    settings.create_wlp = 0;
                    settings.create_whp = 0;
                end
            end
            % Workflow Inputs And Responses Of The Structure Type
            input_rows = [template.mcs; template.csr; template.pros; template.responses];
            for rr = 1:size(input_rows, 1)
                settings.(input_rows{rr, 1}) = input_rows{rr, 4};
            end
            if record.stage == 1
                settings.compute_wave_transmission = 1;
            end
            settings = chess.Config.from_SI(settings, obj.unit_system);
        end

        function [config, structure] = run_config(obj, pse, alternative, settings)
            % run_config  Configuration of a run of an alternative (nothing is written).
            %   [config, structure] = project.run_config(pse, alternative, settings)
            %   settings: run_settings struct (project unit system); fields
            %   left out take their default, unknown fields are an error.
            %   config: the settings, the project (output folder, names,
            %   confidence limits, datum), the inputs of the alternative
            %   and the details of the storm database, with the
            %   configuration rules applied (chess.Config.apply_rules).
            %   A stage 2 alternative records its stage 1 alternative
            %   (config.multiline.stage1_alt) and, once stage 1 has a run
            %   of the same storm database and workflow, is coupled to it
            %   (chess.Model.couple_to_stage1).
            %   structure: the structure of the run (protection system
            %   as a struct).
            %   Units: config and structure are SI (the settings and the
            %   alternative inputs are converted, chess.Config.to_SI);
            %   config.unit_system is the project unit system, the unit
            %   system of the exported results.
            record = obj.alternative(pse, alternative);
            defaults = obj.run_settings(pse, alternative, settings.workflow, settings.storm_database);
            unknown = setdiff(fieldnames(settings), fieldnames(defaults));
            if ~isempty(unknown)
                error('chess:Project:unknownSetting', 'Unknown run setting(s) for %s / %s: %s.', pse, alternative, strjoin(unknown, ', '));
            end
            for name = setdiff(fieldnames(defaults), fieldnames(settings))'
                settings.(name{1}) = defaults.(name{1});
            end
            settings = chess.Config.to_SI(settings, obj.unit_system);
            database = obj.storm_database(settings.storm_database);
            if ~chess.CoastalHazardSystem.is_valid_db_info(database.db_info)
                error('chess:Project:stormDatabaseInfo', ['Storm database "%s" has no db_info (built with an older CHESS ',...
                    'version): build the storm database again.'], database.db_name);
            end
            % Every Response Switch And Parameter Of Every Structure Type Starts At 0
            config = struct();
            for structure_type = 1:3
                template = chess.Project.structure_template(structure_type);
                for rr = 1:size(template.responses, 1)
                    config.(template.responses{rr, 1}) = 0;
                end
            end
            % Run Settings
            for name = setdiff(fieldnames(settings), {'storm_database'})'
                config.(name{1}) = settings.(name{1});
            end
            config.apply_random_tides = double(~strcmpi(config.tide_file, 'None'));
            config.load_project_forcing = 0;
            config.ref_case_name = 'none';
            % Storm Database
            config.region = database.study;
            config.sp_ID = '';
            config.sp_ID_wave = '';
            config.storm_db = database.db_name;
            % Project
            config.outfolder = obj.root_folder;
            config.project_name = obj.name;
            config.struc_id = char(pse);
            config.case_name = char(alternative);
            limits = obj.confidence_limits(obj.confidence_limits ~= 0);
            config.project_CLs = ['[' strjoin(arrayfun(@num2str, limits, 'un', false), ' ') ']'];
            config.project_datum = obj.vertical_datum;
            config.unit_system = obj.unit_system;
            config.gravity_constant = chess.Common.physical_constants().gravity;
            % Structure
            structure = obj.protection_system(pse, alternative).to_struct();
            for name = setdiff(fieldnames(structure), {'multiline_stage', 'offshore_elevation_source'})'
                config.(name{1}) = structure.(name{1});
            end
            % Storm Database Details After The Structure: The Study Grid Offshore Elevation Wins Over The Structure Value
            config = chess.Model.apply_storm_database_info(database.db_info, config);
            config = chess.Config.apply_rules(config);
            % Multi-Line Transect
            if record.stage == 1
                config.compute_wave_transmission = 1;
            elseif record.stage == 2
                stage1 = obj.stage1_alternative(pse);
                config.multiline = struct('stage1_alt', stage1);
                workflow_name = chess.Model.workflows(config.workflow).wflow_name;
                stage1_runs = obj.runs(pse, stage1);
                if any(strcmpi(database.db_name, {stage1_runs.db}) & strcmpi(workflow_name, {stage1_runs.workflow}))
                    [config, structure] = chess.Model.couple_to_stage1(config, structure);
                end
            end
            paths = chess.ProjectPaths.build(obj.root_folder, obj.name, pse, alternative, config.workflow, database.db_name);
            config.out_files = paths.out_files;
        end

        function [model, plan] = model(obj, pse, alternative, settings, hotstart)
            % model  Model of a run of an alternative, ready for build_forcing.
            %   model = project.model(pse, alternative, settings)
            %   [model, plan] = project.model(pse, alternative, settings, hotstart)
            %   The run configuration (run_config) is checked
            %   (chess.Config.validate, offshore elevation, the storm
            %   database holds the request, stage 2 has its stage 1 run),
            %   the hotstart level is resolved and applied, and the
            %   configuration and structure are saved in the run folder.
            %   hotstart: 'auto' (default) reuses what the saved run of
            %   this storm database and workflow still covers; 'cold'
            %   builds everything again.
            %   model: chess.Model with the storm database of the project.
            %       [storm, prob_mass] = model.storm_database.read();
            %       forcing = model.build_forcing(storm, prob_mass);
            %       responses = model.compute_responses(forcing);
            %   plan: hotstart level ('cold', 'reuse_sampling' or 'full')
            %   and reason (the input that changed).
            %   The files of the previous run are replaced without a
            %   backup and the project is not updated: run does both.
            if nargin < 5
                hotstart = 'auto';
            end
            [config, structure, plan] = obj.planned_run(pse, alternative, settings, hotstart);
            model = obj.ready_model(config, structure, plan);
        end

        function [responses, info] = run(obj, pse, alternative, settings, hotstart, progress_function)
            % run  Run an alternative and record the run in the project.
            %   responses = project.run(pse, alternative, settings)
            %   [responses, info] = project.run(pse, alternative, settings, hotstart)
            %   [responses, info] = project.run(pse, alternative, settings, hotstart, progress_function)
            %   settings: run_settings struct. hotstart: 'auto' (default)
            %   or 'cold' (see model). progress_function(step, message):
            %   steps 0-4 of chess.Model.build_forcing, then 5 (responses)
            %   and 6 (run recorded); default prints the message.
            %   The configuration, forcing and sampling seed of the
            %   previous run of this storm database and workflow are
            %   backed up first (<file>_prev.mat). A run that fails puts
            %   them back and the error is rethrown; a run that succeeds
            %   removes the backups, records the run (record_run) and
            %   saves the project.
            %   info: struct
            %     hotstart_level, hotstart_reason   how the forcing was
            %                                       obtained
            %     run                the row of the run
            %     config             the configuration of the run
            %     project_saved      false when the results are saved but
            %                        the project file could not be written
            %                        (warning chess:Project:notSaved)
            %     stale_stage2_runs  stage 1 run: {alternative, storm
            %                        database, workflow} of the stage 2
            %                        runs that took their forcing from the
            %                        replaced stage 1 run. Nothing is
            %                        deleted: run them again, or remove
            %                        them with delete_run.
            if nargin < 5 || isempty(hotstart)
                hotstart = 'auto';
            end
            if nargin < 6 || isempty(progress_function)
                progress_function = @(~, message) disp(message);
            end
            [config, structure, plan] = obj.planned_run(pse, alternative, settings, hotstart);
            previous_rows = obj.alternative(pse, alternative).runs;
            workflow_name = chess.Model.workflows(config.workflow).wflow_name;
            previous_row = previous_rows(strcmpi(config.storm_db, {previous_rows.db}) & strcmpi(workflow_name, {previous_rows.workflow}));
            backed_up = chess.Project.back_up_run_files(chess.Project.run_file_backups(config.out_files), plan.level);
            try
                model = obj.ready_model(config, structure, plan);
                [storm, prob_mass] = model.storm_database.read();
                forcing = model.build_forcing(storm, prob_mass, progress_function);
                progress_function(5, 'Computing project responses....');
                responses = model.compute_responses(forcing);
            catch failure
                not_restored = chess.Project.restore_run_files(backed_up);
                if ~isempty(not_restored)
                    error('chess:Project:runFailed', '%s\n\nFiles of the previous run not restored: %s', failure.message,...
                        strjoin(not_restored, '; '));
                end
                rethrow(failure);
            end
            % Results Saved: The Files Of The Previous Run Are No Longer Needed
            for kk = 1:numel(backed_up)
                if backed_up(kk).existed && isfile(backed_up(kk).previous)
                    delete(backed_up(kk).previous);
                end
            end
            row = chess.Project.run_from_config(model.config, model.protection_system.to_struct(),...
                dir(model.config.out_files.resp_data).datenum);
            obj.record_run(pse, alternative, row);
            info = struct('hotstart_level', plan.level, 'hotstart_reason', plan.reason, 'run', row,...
                'config', model.config, 'project_saved', true, 'stale_stage2_runs', {cell(0, 3)});
            try
                obj.save();
            catch failure
                info.project_saved = false;
                warning('chess:Project:notSaved', 'The results are saved, but the project file could not be written: %s', failure.message);
            end
            progress_function(6, 'Run recorded in the project.');
            if obj.stage(pse, alternative) == 1
                stale = obj.stale_stage2_runs(pse);
                same_run = strcmpi(row.db, stale(:, 2)) & strcmpi(row.workflow, stale(:, 3));
                info.stale_stage2_runs = stale(same_run, :);
                % Same Forcing (Full Hotstart) But Another Transmission Geometry: Every Stage 2 Run Of It Is Stale
                if ~isempty(previous_row) && ~isequaln(previous_row(1).structure_kt, row.structure_kt)
                    info.stale_stage2_runs = obj.stage2_runs_of(pse, row.db, row.workflow);
                end
            end
        end

        function restore_interrupted_run(obj, pse, alternative, workflow, storm_database)
            % restore_interrupted_run  Put back the files of the previous run when the last run never finished.
            %   project.restore_interrupted_run(pse, alternative, workflow, storm_database)
            %   A run keeps the configuration, forcing and sampling seed it
            %   replaces as <file>_prev.mat until its results are saved.
            %   Backups still there (e.g. MATLAB was closed during the run)
            %   are moved back. model and run do this first.
            paths = chess.ProjectPaths.build(obj.root_folder, obj.name, pse, alternative, workflow, storm_database);
            backups = chess.Project.run_file_backups(paths.out_files);
            for kk = 1:numel(backups)
                if isfile(backups(kk).previous)
                    movefile(backups(kk).previous, backups(kk).file, 'f');
                end
            end
        end

        function stale = stale_stage2_runs(obj, pse)
            % stale_stage2_runs  Stage 2 runs whose forcing is not from the current stage 1 run.
            %   stale = project.stale_stage2_runs(pse)
            %   stale: {alternative, storm database, workflow}, n x 3 cell.
            %   A stage 2 run is stale when stage 1 has no run of its
            %   storm database and workflow, or that run has another
            %   forcing stamp than the one the stage 2 run recorded.
            stale = cell(0, 3);
            stage1 = obj.stage1_alternative(pse);
            if isempty(stage1)
                return
            end
            stage1_rows = obj.alternative(pse, stage1).runs;
            for stage2 = obj.stage2_alternatives(pse)'
                rows = obj.alternative(pse, stage2{1}).runs;
                for rr = 1:numel(rows)
                    k = find(strcmpi(rows(rr).db, {stage1_rows.db}) & strcmpi(rows(rr).workflow, {stage1_rows.workflow}), 1);
                    if isempty(k) || ~strcmp(rows(rr).stage1_stamp, stage1_rows(k).forcing_stamp)
                        stale(end+1, :) = {stage2{1}, rows(rr).db, rows(rr).workflow}; %#ok<AGROW>
                    end
                end
            end
        end

        function not_deleted = delete_run(obj, pse, alternative, storm_database, workflow)
            % delete_run  Delete the files of a run and its row, then save the project.
            %   not_deleted = project.delete_run(pse, alternative, storm_database, workflow)
            %   workflow: workflow name of the run ('PROS-RB', 'DET', 'LCS',
            %   'PROS-FB') or its number.
            %   Deleted: the run files <storm database>_<workflow>_*.mat of
            %   the workflow folder (responses file first) and the files
            %   of the run in its Export folder. The row is dropped once
            %   the responses file is gone.
            %   not_deleted: files that could not be deleted (e.g. open in
            %   another program), n x 1 cell of char.
            if isnumeric(workflow)
                workflow = chess.Model.workflows(workflow).wflow_name;
            end
            [p, a] = obj.alternative_position(pse, alternative);
            paths = chess.ProjectPaths.build(obj.root_folder, obj.name, pse, alternative,...
                chess.Project.workflow_number(workflow), storm_database);
            files = obj.run_files(pse, alternative, storm_database, workflow);
            exported = dir(fullfile(paths.wf_dir, 'Export', [char(storm_database) '_' workflow '_*']));
            files = [files; reshape(fullfile({exported.folder}, {exported.name}), [], 1)];
            not_deleted = cell(0, 1);
            warning_state = warning('off', 'MATLAB:DELETE:Permission');
            restore_warning = onCleanup(@() warning(warning_state));
            for ff = 1:numel(files)
                delete(files{ff});
                if isfile(files{ff})
                    not_deleted{end+1, 1} = files{ff}; %#ok<AGROW>
                end
            end
            if ~isfile(paths.out_files.resp_data)
                rows = obj.pses(p).alternatives(a).runs;
                obj.pses(p).alternatives(a).runs = rows(~(strcmpi(storm_database, {rows.db}) & strcmpi(workflow, {rows.workflow})));
                obj.save();
            end
        end
    end

    %% MAINTENANCE
    methods
        function info = rename(obj, level, new_name, pse, alternative)
            % rename  Rename the project, a PSE or an alternative, on disk and in the record.
            %   info = project.rename('project', new_name)
            %   info = project.rename('pse', new_name, pse)
            %   info = project.rename('alternative', new_name, pse, alternative)
            %   In order: the name is checked (chess.Project.name_problem;
            %   a multi-line alternative keeps its _stage_1 / _stage_2
            %   ending), the folder is moved in one step (nothing changes
            %   when that fails, e.g. a file inside is open elsewhere), the
            %   record and its saved paths are updated, the saved run
            %   configurations under the moved folder are rewritten (name,
            %   file paths, tide file; a renamed stage 1 also in the
            %   configurations of its stage 2 runs), the project file
            %   follows a new project name, and the project is saved.
            %   info: old_folder, new_folder, rewritten (configuration
            %   files), failed ('<file>: <error>', not rewritten).
            if nargin < 4
                pse = '';
            end
            if nargin < 5
                alternative = '';
            end
            new_name = char(new_name);
            stage = 0;
            switch level
                case 'project'
                    current = obj.name;
                    siblings = {};
                    parent = obj.root_folder;
                    name_field = 'project_name';
                case 'pse'
                    p = obj.pse_position(pse);
                    current = obj.pses(p).name;
                    siblings = setdiff(obj.pse_names(), {current});
                    parent = chess.ProjectPaths.build(obj.root_folder, obj.name).pse_root_dir;
                    name_field = 'struc_id';
                case 'alternative'
                    [p, a] = obj.alternative_position(pse, alternative);
                    current = obj.pses(p).alternatives(a).name;
                    siblings = setdiff(obj.alternative_names(pse), {current});
                    parent = chess.ProjectPaths.build(obj.root_folder, obj.name, pse).pse_dir;
                    name_field = 'case_name';
                    stage = obj.pses(p).alternatives(a).stage;
                otherwise
                    error('chess:Project:invalidLevel', 'level must be ''project'', ''pse'' or ''alternative''.');
            end
            problem = chess.Project.name_problem(new_name, siblings, current);
            if isempty(problem)
                problem = chess.Project.stage_name_problem(new_name, stage);
            end
            if ~isempty(problem)
                error('chess:Project:invalidName', '%s', problem);
            end
            old_folder = fullfile(parent, current);
            new_folder = fullfile(parent, new_name);
            case_only = strcmpi(new_name, current);
            if ~case_only && (isfolder(new_folder) || isfile(new_folder))
                error('chess:Project:nameOnDisk', '"%s" already exists on disk. Choose another name.', new_folder);
            end
            if isfolder(old_folder)
                chess.Project.move_item(old_folder, new_folder, case_only);
            end
            switch level
                case 'project'
                    obj.name = new_name;
                case 'pse'
                    obj.pses(p).name = new_name;
                case 'alternative'
                    obj.pses(p).alternatives(a).name = new_name;
            end
            obj.storm_databases = chess.Project.replace_path_start(obj.storm_databases, old_folder, new_folder);
            obj.tide_files = chess.Project.replace_path_start(obj.tide_files, old_folder, new_folder);
            obj.chs_dependencies = chess.Project.replace_path_start(obj.chs_dependencies, old_folder, new_folder);
            info = struct('old_folder', old_folder, 'new_folder', new_folder, 'rewritten', {cell(0, 1)}, 'failed', {cell(0, 1)});
            % Saved Run Configurations Under The Moved Folder (Run Backups Do Not Match The Pattern); '-append' Keeps structure
            files = dir(fullfile(new_folder, '**', '*_config_file.mat'));
            for ff = 1:numel(files)
                file = fullfile(files(ff).folder, files(ff).name);
                try
                    saved = load(file, 'config');
                    config = saved.config;
                    config.(name_field) = new_name;
                    config.out_files = chess.Project.replace_path_start(config.out_files, old_folder, new_folder);
                    config.tide_file = chess.Project.replace_path_start(config.tide_file, old_folder, new_folder);
                    save(file, 'config', '-append');
                    info.rewritten{end+1, 1} = file;
                catch failure
                    info.failed{end+1, 1} = [file ': ' failure.message];
                end
            end
            % Renamed Stage 1: The Run Configurations Of Its Stage 2 Alternatives Name It (Run Backups Included)
            if stage == 1
                for stage2 = obj.stage2_alternatives(obj.pses(p).name)'
                    files = dir(fullfile(parent, stage2{1}, '**', '*_config_file*.mat'));
                    for ff = 1:numel(files)
                        file = fullfile(files(ff).folder, files(ff).name);
                        try
                            saved = load(file, 'config');
                            config = saved.config;
                            if isfield(config, 'multiline') && isstruct(config.multiline)
                                config.multiline.stage1_alt = new_name;
                                save(file, 'config', '-append');
                                info.rewritten{end+1, 1} = file;
                            end
                        catch failure
                            info.failed{end+1, 1} = [file ': ' failure.message];
                        end
                    end
                end
            end
            % Project File Follows The Project Name
            old_file = fullfile(new_folder, ['CHESS_project_' current '.mat']);
            if strcmp(level, 'project') && isfile(old_file)
                try
                    chess.Project.move_item(old_file, obj.project_file, case_only);
                catch failure
                    info.failed{end+1, 1} = [old_file ': ' failure.message];
                end
            end
            obj.save();
        end

        function copy_pse(obj, pse, new_name)
            % copy_pse  Copy a PSE under a new name: its alternatives, inputs and stages.
            %   project.copy_pse(pse, new_name)
            %   Runs are not copied: the copy has none, and nothing is
            %   written in its folder until a run. The project is not saved.
            p = obj.pse_position(pse);
            problem = chess.Project.name_problem(new_name, obj.pse_names());
            if ~isempty(problem)
                error('chess:Project:invalidName', '%s', problem);
            end
            copy = obj.pses(p);
            copy.name = char(new_name);
            for a = 1:numel(copy.alternatives)
                copy.alternatives(a).runs = chess.Project.empty_runs();
            end
            obj.pses(end+1, 1) = copy;
        end

        function leftover = remove_pse(obj, pse, delete_files)
            % remove_pse  Remove a PSE from the project.
            %   leftover = project.remove_pse(pse)
            %   leftover = project.remove_pse(pse, delete_files)
            %   delete_files (default false): the PSE folder with its runs
            %   is deleted first; when it cannot be (a file inside is open
            %   elsewhere) the error leaves the project unchanged.
            %   leftover: folder that could not be fully removed ('' if
            %   none). The project is not saved.
            if nargin < 3
                delete_files = false;
            end
            p = obj.pse_position(pse);
            leftover = '';
            if delete_files
                leftover = chess.Project.delete_folder(chess.ProjectPaths.build(obj.root_folder, obj.name, pse).pse_dir);
            end
            obj.pses(p) = [];
        end

        function leftover = remove_alternative(obj, pse, alternative, delete_files)
            % remove_alternative  Remove an alternative from a PSE.
            %   leftover = project.remove_alternative(pse, alternative)
            %   leftover = project.remove_alternative(pse, alternative, delete_files)
            %   The PSE is removed with it when it is its last alternative
            %   or its stage 1 alternative (a multi-line PSE cannot stay
            %   without its offshore line). delete_files, leftover: see
            %   remove_pse. The project is not saved.
            if nargin < 4
                delete_files = false;
            end
            [p, a] = obj.alternative_position(pse, alternative);
            if numel(obj.pses(p).alternatives) == 1 || obj.pses(p).alternatives(a).stage == 1
                leftover = obj.remove_pse(pse, delete_files);
                return
            end
            leftover = '';
            if delete_files
                leftover = chess.Project.delete_folder(chess.ProjectPaths.build(obj.root_folder, obj.name, pse, alternative).alt_dir);
            end
            obj.pses(p).alternatives(a) = [];
        end

        function tied = storm_database_runs(obj, name)
            % storm_database_runs  Runs made with a storm database, in the record or on disk.
            %   tied = project.storm_database_runs(name)
            %   tied: {pse, alternative, workflow}, n x 3 cell. Runs on
            %   disk without a row (not synced, or without a responses
            %   file) count too.
            tied = cell(0, 3);
            for p = 1:numel(obj.pses)
                for a = 1:numel(obj.pses(p).alternatives)
                    rows = obj.pses(p).alternatives(a).runs;
                    workflows = {rows(strcmpi(name, {rows.db})).workflow};
                    for workflow = {chess.Model.workflows().wflow_name}
                        if ~any(strcmpi(workflow{1}, workflows)) && ...
                                ~isempty(obj.run_files(obj.pses(p).name, obj.pses(p).alternatives(a).name, name, workflow{1}))
                            workflows{end+1} = workflow{1}; %#ok<AGROW>
                        end
                    end
                    for workflow = workflows
                        tied(end+1, :) = {obj.pses(p).name, obj.pses(p).alternatives(a).name, workflow{1}}; %#ok<AGROW>
                    end
                end
            end
        end

        function count = storm_database_usage(obj, name)
            % storm_database_usage  Number of alternatives with runs of a storm database (storm_database_runs).
            %   count = project.storm_database_usage(name)
            tied = obj.storm_database_runs(name);
            count = numel(unique(strcat(tied(:, 1), '|', tied(:, 2))));
        end

        function files = storm_database_run_files(obj, name)
            % storm_database_run_files  Run files of a storm database in every alternative, n x 1 cell of char.
            %   files = project.storm_database_run_files(name)
            %   Every <storm database>_<workflow>_* run file on disk, run
            %   backups included.
            files = cell(0, 1);
            for p = 1:numel(obj.pses)
                for a = 1:numel(obj.pses(p).alternatives)
                    for workflow = {chess.Model.workflows().wflow_name}
                        files = [files; obj.run_files(obj.pses(p).name, obj.pses(p).alternatives(a).name, name, workflow{1})]; %#ok<AGROW>
                    end
                end
            end
        end

        function remove_storm_database(obj, name)
            % remove_storm_database  Remove a storm database record and the rows of its runs.
            %   project.remove_storm_database(name)
            %   No file is deleted: the database file and the run files
            %   (storm_database_run_files) stay on disk. The project is
            %   not saved.
            k = find(strcmp(name, {obj.storm_databases.db_name}), 1);
            if isempty(k)
                error('chess:Project:unknownStormDatabase', 'Project "%s" has no storm database "%s".', obj.name, char(name));
            end
            obj.drop_storm_database_runs(name);
            obj.storm_databases(k) = [];
        end

        function drop_storm_database_runs(obj, name)
            % drop_storm_database_runs  Drop the rows of the runs made with a storm database (no file is deleted).
            %   project.drop_storm_database_runs(name)
            for p = 1:numel(obj.pses)
                for a = 1:numel(obj.pses(p).alternatives)
                    rows = obj.pses(p).alternatives(a).runs;
                    obj.pses(p).alternatives(a).runs = rows(~strcmpi(name, {rows.db}));
                end
            end
        end

        function region = region(obj)
            % region  CHS study of the storm databases of the project ('' when none; Custom_Modeling gives none).
            studies = {obj.storm_databases.study};
            studies = studies(~cellfun(@isempty, studies) & ~strcmp(studies, 'Custom_Modeling'));
            region = '';
            if ~isempty(studies)
                region = studies{1};
            end
        end

        function note = export_archive(obj, zip_file)
            % export_archive  Write the project folder to a zip file, with the CHS_Dependencies of its region.
            %   note = project.export_archive(zip_file)
            %   The archive holds <name>/... (the project folder). When the
            %   project has a region and a valid CHS_Dependencies folder
            %   outside the project folder, the files of that region are
            %   added as <name>/CHS_Dependencies/ (nothing is copied into
            %   the project folder). An extracted archive opens with
            %   chess.Project.open. note: what was exported.
            project_folder = obj.folder;
            bundled_folder = fullfile(project_folder, 'CHS_Dependencies');
            project_region = obj.region();
            [sources, names] = chess.Project.folder_entries(project_folder, obj.name);
            keep = ~strcmp(names, [obj.name '/.chess_lock']); % Session Lock, Not Project Data
            sources = sources(keep);
            names = names(keep);
            if isempty(project_region)
                note = sprintf('Project exported to %s without CHS_Dependencies: the project has no CHS region.', zip_file);
            elseif chess.Project.same_path(obj.chs_dependencies, bundled_folder)
                note = sprintf('Project exported to %s with its CHS_Dependencies folder (region %s).', zip_file, project_region);
            elseif ~isempty(chess.Project.chs_dependencies_problem(obj.chs_dependencies, project_region))
                note = sprintf('Project exported to %s without CHS_Dependencies: no valid %s folder found at "%s".',...
                    zip_file, project_region, obj.chs_dependencies);
            else
                % A CHS_Dependencies Folder Left In The Project Is Replaced By The Region Files
                keep = ~startsWith(names, [obj.name '/CHS_Dependencies/']);
                sources = sources(keep);
                names = names(keep);
                top = [obj.name '/CHS_Dependencies'];
                chs_files = chess.CoastalHazardSystem.dependency_files(obj.chs_dependencies, project_region);
                % Archive Names Keep The Last Path Parts: <subfolder>/<region>/<file> (Region), Probability_Masses/<file> (Shared)
                last_parts = @(parts, n) strjoin(parts(end-n+1:end), '/');
                region_names = cellfun(@(file) last_parts(strsplit(file, filesep), 3), chs_files.region_files, 'un', false);
                shared_names = cellfun(@(file) last_parts(strsplit(file, filesep), 2), chs_files.shared_files, 'un', false);
                region_folders = unique(cellfun(@(name) name(1:find(name == '/', 1, 'last')), region_names, 'un', false));
                folder_names = [{'/'; '/Grid_Files/'; '/Bias_and_Uncertainty/'; '/Probability_Masses/'}; strcat('/', region_folders)];
                sources = [sources; repmat({''}, numel(folder_names), 1); chs_files.region_files; chs_files.shared_files];
                names = [names; strcat(top, folder_names); strcat([top '/'], [region_names; shared_names])];
                note = sprintf('Project exported to %s with CHS_Dependencies (region %s files).', zip_file, project_region);
            end
            chess.Project.write_zip(zip_file, sources, names);
        end
    end

    %% RECORD LAYOUTS AND SHARED HELPERS
    methods (Static)
        function template = structure_template(structure_type)
            % structure_template  Input template of a structure type.
            %   template = chess.Project.structure_template(structure_type)
            %   structure_type: 1 levee, 2 floodwall, 3 rubble mound.
            %   template: sections general, forcing, geometry, properties,
            %   responses, mcs, csr, pros of CHESS_Library\PSE_Templates\
            %   <levee|floodwall|rubble_mound>_pse.csv (.xlsx when there
            %   is no .csv), each an n x 4 cell {symbol, description,
            %   units, value} (chess.Config.read_sections).
            persistent cache
            if isempty(cache)
                cache = containers.Map();
            end
            names = {'levee_pse', 'floodwall_pse', 'rubble_mound_pse'};
            if ~(isnumeric(structure_type) && isscalar(structure_type) && ismember(structure_type, 1:3))
                error('chess:Project:unknownStructureType', 'structure_type must be 1 (levee), 2 (floodwall) or 3 (rubble mound).');
            end
            library_folder = fileparts(fileparts(which('chess.Project')));
            file = fullfile(library_folder, 'PSE_Templates', [names{structure_type} '.csv']);
            if ~isfile(file)
                file = fullfile(library_folder, 'PSE_Templates', [names{structure_type} '.xlsx']);
            end
            file_details = dir(file);
            if isempty(file_details)
                error('chess:Project:noTemplate', 'Input template not found: %s (.csv or .xlsx).', file(1:end-5));
            end
            if isKey(cache, file)
                cached = cache(file);
                if cached.datenum == file_details.datenum
                    template = cached.template;
                    return
                end
            end
            template = chess.Config.read_sections(file);
            cache(file) = struct('datenum', file_details.datenum, 'template', template);
        end

        function fields = storm_database_fields()
            % storm_database_fields  Fields of a storm database record, in order, 1 x n cell of char.
            %   db_name        storm database name
            %   output_paths   files of the database (storm_db, chs_data), struct
            %   outpath        folder of the database
            %   source_paths   storm data it was built from
            %   study          CHS study (region)
            %   study_datum    datum of the study
            %   db_info        database details (chess.CoastalHazardSystem.create_db_info)
            %   sp_coords      savepoint coordinates
            %   sp_ids         savepoint ids
            %   create_wlp, create_whp   priority datasets built (0/1)
            %   gravity_constant         gravity used [m/s^2]
            %   db_created     true once the database file is built
            %   layout         storm types, data types and counts (chess.Project.storm_layout)
            fields = {'db_name', 'output_paths', 'outpath', 'source_paths', 'study', 'study_datum', 'db_info', 'sp_coords',...
                'sp_ids', 'create_wlp', 'create_whp', 'gravity_constant', 'db_created', 'layout'};
        end

        function records = empty_storm_databases()
            % empty_storm_databases  No storm database records, 0 x 1 struct with every record field.
            fields = chess.Project.storm_database_fields();
            records = cell2struct(cell(numel(fields), 0), fields, 1);
        end

        function rows = empty_runs()
            % empty_runs  No runs, 0 x 1 struct with every run field (run_from_config).
            rows = struct('db', {}, 'workflow', {}, 'data_types', {}, 'storm_type', {}, 'run_date', {}, 'resp_file_date', {},...
                'forcing_stamp', {}, 'structure_kt', {}, 'inherited', {}, 'stage1_stamp', {});
            rows = reshape(rows, 0, 1);
        end

        function row = run_from_config(config, structure, resp_file_date)
            % run_from_config  Row of a completed run, from its saved config and structure.
            %   row = chess.Project.run_from_config(config, structure, resp_file_date)
            %   Names only, never paths:
            %     db, workflow   storm database and workflow name of the
            %                    run files (chess.ProjectPaths.build)
            %     data_types     'peaks_default', 'create_wlp', 'create_whp',
            %                    'use_timeseries' that were on
            %     storm_type     config.storm_sampling
            %     run_date       'yyyy-MM-dd HH:mm' of resp_file_date
            %     resp_file_date date of the responses file, datenum
            %     forcing_stamp  config.forcing_stamp ('' if none)
            %     structure_kt   crest_elevation, crest_width, seaside_slope,
            %                    offshore_slope, toe_elevation of the run's
            %                    structure (NaN if absent); read for stage 1
            %     inherited      chess.Model.multiline_inherited_fields values
            %                    of the run (without tide indices and LCS
            %                    convergence results; tide_file as a file
            %                    name); read for stage 1
            %     stage1_stamp   stage 2 runs: forcing stamp of the stage 1
            %                    run its forcing came from, else ''
            %   The values (structure_kt, inherited) are SI, as the saved
            %   config and structure.
            paths = chess.ProjectPaths.build(config);
            row = chess.Project.empty_runs();
            row(1).db = paths.db;
            row.workflow = paths.wflow_name;
            data_types = {'peaks_default', 'create_wlp', 'create_whp', 'use_timeseries'};
            row.data_types = data_types([config.use_peaks, config.create_wlp, config.create_whp, config.use_timeseries] == 1);
            row.storm_type = config.storm_sampling;
            row.run_date = char(datetime(resp_file_date, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm'));
            row.resp_file_date = resp_file_date;
            row.forcing_stamp = '';
            if isfield(config, 'forcing_stamp')
                row.forcing_stamp = config.forcing_stamp;
            end
            row.structure_kt = struct();
            for field = {'crest_elevation', 'crest_width', 'seaside_slope', 'offshore_slope', 'toe_elevation'}
                row.structure_kt.(field{1}) = NaN;
                if isfield(structure, field{1})
                    row.structure_kt.(field{1}) = structure.(field{1});
                end
            end
            row.inherited = struct();
            run_outputs = {'tide_indx_xc', 'tide_indx_tc', 'tide_indx_cc', 'lcs_convergence_results'};
            for field = setdiff(chess.Model.multiline_inherited_fields(), run_outputs, 'stable')
                if isfield(config, field{1})
                    row.inherited.(field{1}) = config.(field{1});
                end
            end
            if isfield(row.inherited, 'tide_file')
                [~, tide_name, tide_extension] = fileparts(row.inherited.tide_file);
                row.inherited.tide_file = [tide_name tide_extension];
            end
            row.stage1_stamp = '';
            if isfield(config, 'multiline') && isstruct(config.multiline) && isfield(config.multiline, 'stage1_stamp')
                row.stage1_stamp = config.multiline.stage1_stamp;
            end
        end

        function label = run_label(row)
            % run_label  Label of a run: '<storm database> | <workflow>'.
            %   label = chess.Project.run_label(row)
            label = [row.db ' | ' row.workflow];
        end

        function number = workflow_number(workflow_name)
            % workflow_number  Workflow number of a workflow name of the run files ([] when unknown).
            %   number = chess.Project.workflow_number(workflow_name)
            %   chess.Model.workflows: PROS-RB 1, DET 2, LCS 3, PROS-FB 4 (case-insensitive).
            workflows = chess.Model.workflows();
            number = [workflows(find(strcmpi(workflow_name, {workflows.wflow_name}), 1)).number];
        end

        function layout = storm_layout(storm)
            % storm_layout  Storm types, data types and storm counts of a storm database.
            %   layout = chess.Project.storm_layout(storm)
            %   storm: storm data of a storm database (chess.CoastalHazardSystem.read).
            %   layout: struct
            %     storm_types            XC / TC in database order, row cell
            %     data_types.(storm type)   Peaks / Timeseries, row cell
            %     match_types.(storm type).(data type)   Default / WLP / WHP, row cell
            %     counts.(storm type).(data type).(match type)   number of storms
            %     qc_removed.(storm type)   storms removed by the quality
            %                               check (0 if not recorded)
            storm_types = fieldnames(storm);
            storm_types = storm_types(ismember(storm_types, {'XC', 'TC'}));
            layout = struct('storm_types', {storm_types(:)'}, 'data_types', struct(), 'match_types', struct(),...
                'counts', struct(), 'qc_removed', struct());
            for tt = 1:numel(storm_types)
                storm_type = storm_types{tt};
                data_types = intersect(fieldnames(storm.(storm_type)), {'Peaks', 'Timeseries'}, 'stable');
                layout.data_types.(storm_type) = data_types(:)';
                for dd = 1:numel(data_types)
                    match_types = fieldnames(storm.(storm_type).(data_types{dd}));
                    layout.match_types.(storm_type).(data_types{dd}) = match_types(:)';
                    for mm = 1:numel(match_types)
                        layout.counts.(storm_type).(data_types{dd}).(match_types{mm}) = ...
                            size(storm.(storm_type).(data_types{dd}).(match_types{mm}), 1);
                    end
                end
                removed = 0;
                if isfield(storm.(storm_type), 'removed_storms') && isfield(storm.(storm_type).removed_storms, 'Default')
                    removed = numel(storm.(storm_type).removed_storms.Default);
                end
                layout.qc_removed.(storm_type) = removed;
            end
        end

        function problem = name_problem(name, sibling_names, current_name, parent_folder)
            % name_problem  Why a project, PSE, alternative or storm database name cannot be used ('' when it can).
            %   problem = chess.Project.name_problem(name)
            %   problem = chess.Project.name_problem(name, sibling_names)
            %   problem = chess.Project.name_problem(name, sibling_names, current_name)
            %   problem = chess.Project.name_problem(name, sibling_names, current_name, parent_folder)
            %   A name is a folder name: not blank, no spaces, none of
            %   \ / : * ? " < > |, no trailing dot, not a reserved Windows
            %   name, and not one of sibling_names (case-insensitive).
            %   current_name (rename): the name must differ from it; a
            %   change of case only is allowed. parent_folder: a file or
            %   folder of that name there is a clash too.
            if nargin < 2
                sibling_names = {};
            end
            if nargin < 3
                current_name = '';
            end
            if nargin < 4
                parent_folder = '';
            end
            problem = '';
            if ~(ischar(name) || (isstring(name) && isscalar(name))) || isempty(char(name))
                problem = 'Enter a name.';
                return
            end
            name = char(name);
            reserved = [{'CON', 'PRN', 'AUX', 'NUL'}, compose('COM%d', 1:9), compose('LPT%d', 1:9)];
            if any(isspace(name))
                problem = 'Spaces are not allowed.';
            elseif any(ismember(name, '\/:*?"<>|')) || any(name < 32)
                problem = 'These characters are not allowed: \ / : * ? " < > |';
            elseif name(end) == '.'
                problem = 'The name cannot end with a dot.';
            elseif any(strcmpi(extractBefore([name '.'], '.'), reserved)) % Windows Also Reserves "CON.txt"
                problem = sprintf('"%s" is a reserved Windows name.', name);
            elseif ~isempty(current_name) && strcmp(name, current_name)
                problem = 'Enter a different name.';
            elseif any(strcmpi(name, sibling_names))
                problem = sprintf('"%s" already exists.', name);
            elseif ~isempty(parent_folder) && ~strcmpi(name, current_name) && isfile(fullfile(parent_folder, name))
                problem = sprintf('A file named "%s" already exists on disk (folder %s).', name, parent_folder);
            elseif ~isempty(parent_folder) && ~strcmpi(name, current_name) && isfolder(fullfile(parent_folder, name))
                problem = sprintf('A folder named "%s" already exists on disk (folder %s).', name, parent_folder);
            end
        end

        function leftover = delete_folder(folder)
            % delete_folder  Delete a folder, or change nothing when a file inside is open elsewhere.
            %   leftover = chess.Project.delete_folder(folder)
            %   The folder is first moved to a temporary name next to it in
            %   one step (an error with the reason when that fails), then
            %   removed. leftover: temporary folder that could not be fully
            %   removed ('' if none).
            leftover = '';
            if ~isfolder(folder)
                return
            end
            temporary = tempname(fileparts(folder));
            try
                chess.Project.move_in_one_step(folder, temporary);
            catch failure
                error('chess:Project:deleteFailed', ['Could not delete "%s" (%s). A file inside may be open in another program ',...
                    '(File Explorer, MATLAB): close it and try again.'], folder, chess.Project.move_failure_reason(failure));
            end
            try
                rmdir(temporary, 's');
            catch
            end
            if isfolder(temporary)
                leftover = temporary;
            end
        end

        function move_item(source, target, case_only)
            % move_item  Rename a folder or file in one file system move: it works or changes nothing.
            %   chess.Project.move_item(source, target)
            %   chess.Project.move_item(source, target, case_only)
            %   case_only (default false): the names differ in case only
            %   (the move goes through a temporary name).
            if nargin < 3
                case_only = false;
            end
            try
                if case_only
                    temporary = tempname(fileparts(source));
                    chess.Project.move_in_one_step(source, temporary);
                    try
                        chess.Project.move_in_one_step(temporary, target);
                    catch failure
                        chess.Project.move_in_one_step(temporary, source);
                        rethrow(failure);
                    end
                else
                    chess.Project.move_in_one_step(source, target);
                end
            catch failure
                error('chess:Project:renameFailed', ['Could not rename "%s" to "%s" (%s). A file inside may be open in another ',...
                    'program (File Explorer, MATLAB): close it and try again.'], source, target, chess.Project.move_failure_reason(failure));
            end
        end

        function value = replace_path_start(value, old_start, new_start)
            % replace_path_start  Point paths under one folder into another folder.
            %   value = chess.Project.replace_path_start(value, old_start, new_start)
            %   Every text in value (char, cell or struct, nested) that is
            %   old_start or a path under it gets new_start instead
            %   (case-insensitive, either slash). Other values are returned
            %   unchanged.
            if ischar(value)
                comparable = strrep(value, '/', '\');
                old_comparable = strrep(old_start, '/', '\');
                n = numel(old_comparable);
                if size(value, 1) == 1 && n > 0 && strncmpi(comparable, old_comparable, n) && ...
                        (numel(comparable) == n || comparable(n+1) == '\')
                    value = [new_start value(n+1:end)];
                end
            elseif iscell(value)
                for ii = 1:numel(value)
                    value{ii} = chess.Project.replace_path_start(value{ii}, old_start, new_start);
                end
            elseif isstruct(value)
                fields = fieldnames(value);
                for ii = 1:numel(value)
                    for ff = 1:numel(fields)
                        value(ii).(fields{ff}) = chess.Project.replace_path_start(value(ii).(fields{ff}), old_start, new_start);
                    end
                end
            end
        end

        function suffix = stage_suffix(stage)
            % stage_suffix  Ending of a multi-line alternative name: '_stage_1', '_stage_2' ('' for stage 0).
            suffix = '';
            if stage > 0
                suffix = sprintf('_stage_%d', stage);
            end
        end

        function problem = stage_name_problem(name, stage)
            % stage_name_problem  '' when an alternative name carries the ending of its stage (any name for stage 0).
            problem = '';
            suffix = chess.Project.stage_suffix(stage);
            if ~endsWith(char(name), suffix) || strcmp(char(name), suffix)
                problem = sprintf('A multi-line stage %d alternative name must end with "%s".', stage, suffix);
            end
        end

        function problem = storm_database_name_problem(name)
            % storm_database_name_problem  '' when name can name a storm database, else why not.
            %   name_problem rules; a name ending with "_raw_files" would
            %   collide with <storm database>_raw_files.mat.
            problem = chess.Project.name_problem(name);
            if isempty(problem) && endsWith(char(name), '_raw_files', 'IgnoreCase', true)
                problem = 'The name cannot end with "_raw_files".';
            end
        end

        function problem = chs_dependencies_problem(chs_dependencies, region)
            % chs_dependencies_problem  '' when a folder is a usable CHS_Dependencies folder, else why not.
            %   problem = chess.Project.chs_dependencies_problem(chs_dependencies, region)
            %   The folder needs Bias_and_Uncertainty, Grid_Files and
            %   Probability_Masses and, for a non-empty region, the study
            %   grid and the bias and uncertainty files of that region
            %   (chess.CoastalHazardSystem.dependency_files).
            problem = '';
            chs_files = chess.CoastalHazardSystem.dependency_files(chs_dependencies, region);
            if ~chs_files.folder_layout_ok
                problem = 'Selected CHS_Dependencies folder does not meet required folder structure.';
            elseif ~isempty(region) && ~(chs_files.study_grid_available && chs_files.bias_uncertainty_available)
                problem = sprintf('This CHS_Dependencies folder has no %s files. Select a folder containing region %s.', region, region);
            end
        end

        function [lock, holder, problem] = acquire_lock(project_folder)
            % acquire_lock  Take the session lock of a project folder (one session works on a project at a time).
            %   [lock, holder, problem] = chess.Project.acquire_lock(project_folder)
            %   An operating system lock on <project_folder>\.chess_lock,
            %   released when the holding MATLAB ends (a crash included).
            %   Taken: lock is a struct for release_lock and the file holds
            %   '<user>, <time>'. Held by another session: lock = [] and
            %   holder is that text. Lock file not usable (folder missing,
            %   read-only): lock = [], holder = '', problem is the reason.
            %   A lock is a courtesy between sessions: open, save and run
            %   do not check it.
            holder = '';
            problem = '';
            file = fullfile(project_folder, '.chess_lock');
            try
                lock_file = java.io.RandomAccessFile(file, 'rw');
            catch failure
                lock = [];
                if ~isfolder(project_folder)
                    problem = sprintf('project folder "%s" not found', project_folder);
                else
                    problem = sprintf('lock file "%s" cannot be written (%s)', file, chess.Project.move_failure_reason(failure));
                end
                return
            end
            try
                % The Locked Byte Lies Past The Text, So Other Sessions Can Still Read It
                file_lock = lock_file.getChannel().tryLock(int64(2^31), int64(1), false);
            catch % Held In This MATLAB
                file_lock = [];
            end
            if isempty(file_lock)
                lock_file.close();
                lock = [];
                holder = strtrim(fileread(file));
                if isempty(holder)
                    holder = 'unknown user';
                end
                return
            end
            holder = sprintf('%s, %s', char(java.lang.System.getProperty('user.name')),...
                char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
            try
                lock_file.setLength(0);
                lock_file.write(typecast(unicode2native(holder, 'UTF-8'), 'int8'));
            catch failure
                file_lock.release();
                lock_file.close();
                lock = [];
                holder = '';
                problem = sprintf('lock file "%s" cannot be written (%s)', file, chess.Project.move_failure_reason(failure));
                return
            end
            lock = struct('file', file, 'raf', lock_file, 'lock', file_lock);
        end

        function release_lock(lock)
            % release_lock  Release an acquire_lock lock ([] or already released: nothing). The file stays.
            if isempty(lock) || ~lock.lock.isValid()
                return
            end
            lock.lock.release();
            lock.raf.close();
        end
    end

    %% INTERNAL
    methods (Access = private)
        function folder = storm_database_holding_folder(obj)
            % Where a storm database is built before it is added to the project (inspect_storm_data, build_storm_database)
            folder = fullfile(obj.folder, 'Event_Database', '_import_staging');
        end

        function record = add_existing_storm_database(obj, name, source, create_wlp, create_whp)
            % Add the storm database file already in Event_Database under a name (not in the project) when it holds what the
            % source and the request give; [] when it does not (import_storm_database builds it again)
            record = [];
            source = char(source);
            if ~isfile(source)
                error('chess:Project:noStormData', 'Storm data not found: %s', source);
            end
            database_file = fullfile(obj.folder, 'Event_Database', [name '.mat']);
            if ~isfile(database_file)
                return
            end
            try
                database = chess.CoastalHazardSystem(source, char(obj.chs_dependencies), database_file);
                contents = database.source_contents();
                if strcmp(database.source_kind, 'storm_mat')
                    request = double([contents.has_wlp contents.has_whp]);
                else
                    request = double([create_wlp == 1, create_whp == 1]);
                end
                covered = database.covers(contents.storm_sampling, double(contents.has_peaks), double(contents.has_timeseries), request(1), request(2));
            catch
                return % Source Or File Not Readable: The Build Reports It
            end
            problem = obj.storm_data_region_problem(database);
            if ~isempty(problem)
                error('chess:Project:otherRegion', '%s', problem);
            end
            if covered
                record = obj.add_storm_database_record(name, database);
            end
        end

        function record = add_storm_database_record(obj, name, database)
            % Record of the storm database files <name>.mat / <name>_raw_files.mat of Event_Database, added to the project;
            % database: chess.CoastalHazardSystem of its source
            database_folder = fullfile(obj.folder, 'Event_Database');
            database_file = fullfile(database_folder, [name '.mat']);
            raw_file = fullfile(database_folder, [name '_raw_files.mat']);
            saved = load(database_file, 'storm', 'db_info');
            layout = chess.Project.storm_layout(saved.storm);
            has_dataset = @(dataset) any(cellfun(@(type) isfield(layout.match_types.(type), 'Peaks')...
                && ismember(dataset, layout.match_types.(type).Peaks), layout.storm_types));
            if ~isfile(raw_file)
                raw_file = '';
            end
            record = struct('db_name', name,...
                'output_paths', struct('chs_data', raw_file, 'storm_db', database_file),...
                'outpath', database_folder,...
                'source_paths', struct('chs_dependencies_path', database.chs_dependencies, 'chs_zip', database.source),...
                'study', database.region, 'study_datum', database.vertical_datum, 'db_info', saved.db_info,...
                'sp_coords', [database.savepoint_latitude database.savepoint_longitude],...
                'sp_ids', struct('adcirc', database.savepoint_id, 'wave', database.wave_savepoint_id),...
                'create_wlp', double(has_dataset('WLP')), 'create_whp', double(has_dataset('WHP')),...
                'gravity_constant', chess.Common.physical_constants().gravity, 'db_created', true, 'layout', layout);
            obj.add_storm_database(record);
            record = obj.storm_database(name);
            if ~strcmp(record.study, 'Custom_Modeling') && ~isempty(chess.Project.chs_dependencies_problem(obj.chs_dependencies, obj.region()))
                obj.chs_dependencies = database.chs_dependencies;
            end
        end

        function [in_project, on_disk, existing_name] = check_storm_database_name(obj, name, replace)
            % Error when a name cannot name a new storm database: not a valid name, or in use (storm_database_clash) without replace
            problem = chess.Project.storm_database_name_problem(name);
            if ~isempty(problem)
                error('chess:Project:invalidName', '%s', problem);
            end
            [in_project, on_disk, existing_name] = obj.storm_database_clash(name);
            if in_project && ~replace
                error('chess:Project:invalidName', 'Project "%s" already has a storm database "%s" (replace = true replaces it and deletes its runs).',...
                    obj.name, existing_name);
            elseif on_disk && ~replace
                error('chess:Project:invalidName', ['Storm database files "%s" are in the Event_Database folder of project "%s" but not in the ',...
                    'project (replace = true replaces them).'], char(name), obj.name);
            end
        end

        function obj = Project()
            obj.pses = chess.Project.empty_pses();
            obj.storm_databases = chess.Project.empty_storm_databases();
        end

        function p = pse_position(obj, pse)
            % Index Of A PSE (Error When The Project Has None Of That Name)
            p = find(strcmp(pse, {obj.pses.name}), 1);
            if isempty(p)
                error('chess:Project:unknownPSE', 'Project "%s" has no PSE "%s".', obj.name, char(pse));
            end
        end

        function [p, a] = alternative_position(obj, pse, alternative)
            % Indices Of A PSE And One Of Its Alternatives (Error When Unknown)
            p = obj.pse_position(pse);
            a = find(strcmp(alternative, {obj.pses(p).alternatives.name}), 1);
            if isempty(a)
                error('chess:Project:unknownAlternative', 'PSE "%s" of project "%s" has no alternative "%s".',...
                    char(pse), obj.name, char(alternative));
            end
        end

        function file = responses_file(obj, pse, alternative, row)
            % Responses File Of A Run Row (chess.ProjectPaths.build)
            paths = chess.ProjectPaths.build(obj.root_folder, obj.name, pse, alternative,...
                chess.Project.workflow_number(row.workflow), row.db);
            file = paths.out_files.resp_data;
        end

        function found = runs_on_disk(obj, pse, alternative)
            % Runs On Disk With A Responses File (Backups Not Counted): db, workflow, config (Its Config File), datenum
            found = struct('db', {}, 'workflow', {}, 'config', {}, 'datenum', {});
            alternative_folder = chess.ProjectPaths.build(obj.root_folder, obj.name, pse, alternative).alt_dir;
            for workflow_folder = unique({chess.Model.workflows().folder}, 'stable')
                files = dir(fullfile(alternative_folder, workflow_folder{1}, '*_project_responses.mat'));
                for ff = 1:numel(files)
                    run_file = chess.ProjectPaths.parse_run_file(files(ff).name);
                    if isempty(run_file) || ~strcmp(run_file.file_type, 'project_responses') || run_file.is_backup...
                            || ~strcmp(run_file.wf_folder, workflow_folder{1})
                        continue
                    end
                    found(end+1, 1) = struct('db', run_file.db, 'workflow', run_file.wflow_name, 'datenum', files(ff).datenum,...
                        'config', fullfile(files(ff).folder, [run_file.db '_' run_file.wflow_name '_config_file.mat'])); %#ok<AGROW>
                end
            end
        end

        function files = run_files(obj, pse, alternative, storm_database, workflow_name)
            % Run Files Of One Run On Disk (<db>_<workflow>_*.mat, Run Backups Included), Responses File First, n x 1 Cell
            paths = chess.ProjectPaths.build(obj.root_folder, obj.name, pse, alternative,...
                chess.Project.workflow_number(workflow_name), storm_database);
            listing = dir(fullfile(paths.wf_dir, '*.mat'));
            files = cell(0, 1);
            for ff = 1:numel(listing)
                run_file = chess.ProjectPaths.parse_run_file(listing(ff).name);
                if ~isempty(run_file) && strcmpi(run_file.db, storm_database) && strcmpi(run_file.wflow_name, workflow_name)
                    files{end+1, 1} = fullfile(listing(ff).folder, listing(ff).name); %#ok<AGROW>
                end
            end
            [~, order] = sort(~strcmpi(files, paths.out_files.resp_data));
            files = files(order);
        end

        function fill_storm_database_layouts(obj)
            % Storm Database Records Without A layout: Computed From The Database File When It Exists And Loads
            for kk = 1:numel(obj.storm_databases)
                record = obj.storm_databases(kk);
                if ~isempty(record.layout) || ~isstruct(record.output_paths) || ~isfield(record.output_paths, 'storm_db')...
                        || ~isfile(record.output_paths.storm_db)
                    continue
                end
                try
                    saved = load(record.output_paths.storm_db, 'storm');
                    obj.storm_databases(kk).layout = chess.Project.storm_layout(saved.storm);
                catch
                end
            end
        end

        function rows = stage2_runs_of(obj, pse, storm_database, workflow_name)
            % Stage 2 Runs Of A Storm Database And Workflow: {alternative, db, workflow}
            rows = cell(0, 3);
            for stage2 = obj.stage2_alternatives(pse)'
                runs = obj.alternative(pse, stage2{1}).runs;
                if any(strcmpi(storm_database, {runs.db}) & strcmpi(workflow_name, {runs.workflow}))
                    rows(end+1, :) = {stage2{1}, storm_database, workflow_name}; %#ok<AGROW>
                end
            end
        end

        function [config, structure, plan] = planned_run(obj, pse, alternative, settings, hotstart)
            % Checked Configuration Of A Run And Its Hotstart Plan (Nothing Of The Run Is Written).
            % Backups Left By A Run That Never Finished Are Put Back First.
            %   plan: level ('cold' | 'reuse_sampling' | 'full'), reason (Input That Changed), saved_config (Saved Run, [] If None)
            if ~ismember(hotstart, {'auto', 'cold'})
                error('chess:Project:invalidHotstart', 'hotstart must be ''auto'' or ''cold''.');
            end
            obj.restore_interrupted_run(pse, alternative, settings.workflow, settings.storm_database);
            [config, structure] = obj.run_config(pse, alternative, settings);
            chess.Config.validate(config);
            is_stage2 = ~isempty(config.multiline);
            if is_stage2 && ~isfield(config.multiline, 'stage1_stamp')
                error('chess:Project:noStage1Run', ['Stage 2 alternative "%s" needs a run of its stage 1 alternative "%s" with ',...
                    'storm database %s and workflow %s: run stage 1 first.'], alternative, config.multiline.stage1_alt,...
                    config.storm_db, chess.Model.workflows(config.workflow).wflow_name);
            end
            chess.Model.check_offshore_elevation(config);
            % Hotstart Level Against The Saved Run Of This Storm Database And Workflow
            plan = struct('level', 'cold', 'reason', '', 'saved_config', []);
            if strcmp(hotstart, 'cold') || ~isfile(config.out_files.config) || ~isfile(config.out_files.resp_data)
                return
            end
            saved = load(config.out_files.config, 'config');
            saved = saved.config;
            % A Tide File Inside The Project Folder Of A Moved Project Is Not A Change
            saved.tide_file = chess.Project.replace_path_start(saved.tide_file, fullfile(saved.outfolder, saved.project_name), obj.folder);
            plan.saved_config = saved;
            if ~isfield(saved, 'forcing_stamp') % The Saved Run Has No Complete Forcing
                return
            end
            database_inputs = {'region', 'chs_swl_u_a', 'chs_swl_u_r', 'chs_hm0_u_a', 'chs_hm0_u_r'};
            [changed, plan.reason] = chess.Hotstart.any_field_changed(config, saved, database_inputs);
            if changed
                return
            end
            saved_run = chess.Hotstart(config, saved);
            [level, plan.reason] = saved_run.plan(config.workflow == 3 && ~is_stage2);
            if strcmp(level, 'reuse_sampling') || (strcmp(level, 'full') && isfile(config.out_files.project_forcing))
                plan.level = level;
            end
        end

        function model = ready_model(obj, config, structure, plan)
            % Model Of A Planned Run: Storm Database Checked, Hotstart Level Applied, Configuration And Structure Saved
            record = obj.storm_database(config.storm_db);
            database = chess.CoastalHazardSystem.load(record.output_paths.storm_db, obj.chs_dependencies);
            if ~database.covers(config.storm_sampling, config.use_peaks, config.use_timeseries, config.create_wlp, config.create_whp)
                error('chess:Project:stormDatabaseRequest', ['Storm database "%s" does not hold the storm data of the run ',...
                    '(storm_sampling %s, use_peaks %d, use_timeseries %d, create_wlp %d, create_whp %d).'], config.storm_db,...
                    config.storm_sampling, config.use_peaks, config.use_timeseries, config.create_wlp, config.create_whp);
            end
            hotstart = chess.Hotstart(config, plan.saved_config);
            config = hotstart.apply(plan.level, config.workflow == 3 && isempty(config.multiline));
            switch plan.level
                case 'full'
                    disp('Hotstart: the saved project forcing is reused.');
                case 'reuse_sampling'
                    fprintf('Hotstart: ''%s'' changed, the project forcing is rebuilt.\n', plan.reason);
                otherwise
                    disp('Coldstart: the project forcing is built again.');
            end
            run_folder = fileparts(config.out_files.config);
            if ~isfolder(run_folder)
                mkdir(run_folder);
            end
            save(config.out_files.config, 'config', 'structure', '-v7.3');
            protection_system = chess.ProtectionSystem.create(chess.Model.stone_size_inputs(structure, config));
            protection_system.multiline_stage = obj.stage(config.struc_id, config.case_name);
            model = chess.Model.for_workflow(config, protection_system, database);
            model.hotstart = hotstart;
        end

        function info = sync_alternative(obj, p, a, mode, info)
            % sync_runs Of One Alternative (Indices p, a); Counts And Stage 1 Lists Added To info
            pse = obj.pses(p).name;
            alternative = obj.pses(p).alternatives(a).name;
            is_stage1 = obj.pses(p).alternatives(a).stage == 1;
            old = obj.pses(p).alternatives(a).runs;
            matched = false(size(old));
            rows = chess.Project.empty_runs();
            for found = obj.runs_on_disk(pse, alternative)'
                k = find(strcmpi(found.db, {old.db}) & strcmpi(found.workflow, {old.workflow}), 1);
                matched(k) = true;
                if strcmp(mode, 'sync') && ~isempty(k) && isequal(old(k).resp_file_date, found.datenum)
                    rows(end+1, 1) = old(k); %#ok<AGROW>
                    continue
                end
                try
                    saved = load(found.config, 'config', 'structure');
                    row = chess.Project.run_from_config(saved.config, saved.structure, found.datenum);
                catch
                    info.skipped = info.skipped + 1;
                    continue
                end
                if isempty(k)
                    info.added = info.added + 1;
                else
                    info.refreshed = info.refreshed + 1;
                    if is_stage1 && ~(strcmp(row.forcing_stamp, old(k).forcing_stamp) && isequaln(row.structure_kt, old(k).structure_kt))
                        info.stage1_changed(end+1, :) = {pse, alternative, row.db, row.workflow};
                    end
                end
                rows(end+1, 1) = row; %#ok<AGROW>
            end
            gone = old(~matched);
            info.dropped = info.dropped + numel(gone);
            if is_stage1
                for gg = 1:numel(gone)
                    info.stage1_dropped(end+1, :) = {pse, alternative, gone(gg).db, gone(gg).workflow};
                end
            end
            obj.pses(p).alternatives(a).runs = rows;
        end
    end

    methods (Static, Access = private)
        function place_built_files(built, final, holding_folder)
            % Give built files their final names, or change nothing.
            %   built, final: file names, 1 x n cell. Files at the final
            %   names are first moved aside into holding_folder, then the
            %   built files are moved in (a built file that does not exist
            %   leaves its final name empty). A move that fails puts
            %   everything back and the error is rethrown. The files moved
            %   aside are deleted with the holding folder.
            is_built = cellfun(@isfile, built);
            aside = cellfun(@(file) fullfile(holding_folder, ['previous_' chess.Project.file_name(file)]), final, 'un', false);
            moved_aside = false(size(final));
            placed = false(size(final));
            try
                for kk = find(cellfun(@isfile, final))
                    chess.Project.move_item(final{kk}, aside{kk});
                    moved_aside(kk) = true;
                end
                for kk = find(is_built)
                    chess.Project.move_item(built{kk}, final{kk});
                    placed(kk) = true;
                end
            catch failure
                for kk = find(placed)
                    try
                        chess.Project.move_item(final{kk}, built{kk});
                    catch
                    end
                end
                for kk = find(moved_aside)
                    try
                        chess.Project.move_item(aside{kk}, final{kk});
                    catch
                    end
                end
                rethrow(failure);
            end
        end

        function name = file_name(file)
            % File name with its extension
            [~, name, extension] = fileparts(file);
            name = [name extension];
        end

        function pses = empty_pses()
            pses = reshape(struct('name', {}, 'alternatives', {}), 0, 1);
        end

        function alternatives = empty_alternatives()
            alternatives = reshape(struct('name', {}, 'structure_type', {}, 'inputs', {}, 'stage', {}, 'runs', {}), 0, 1);
        end

        function backups = run_file_backups(out_files)
            % Files A Run Replaces (Configuration, Project Forcing, Sampling Seed) And Their Backups While The Run Lasts
            % (<file>_prev.mat In The Same Folder). backups(k).name: 'config' | 'forcing' | 'seed'
            files = {out_files.config, out_files.project_forcing, chess.ProjectPaths.sampling_seed_file(out_files.project_forcing)};
            previous = cellfun(@(file) [file(1:end-4) '_prev.mat'], files, 'un', false);
            backups = struct('name', {'config', 'forcing', 'seed'}, 'file', files, 'previous', previous);
        end

        function backed_up = back_up_run_files(backups, level)
            % Back Up The Run Files Before The Run Touches Them, By Hotstart Level:
            %   Configuration: Copied. Forcing: Moved ('cold', 'reuse_sampling': Rebuilt By The Run); 'full' Reuses It, No Backup.
            %   Seed: Moved ('cold': Sampled Again), Copied ('reuse_sampling': Read, Then Saved Again); 'full': No Backup.
            % backed_up: What This Run Backed Up (existed = false: Not There Before The Run, Deleted If The Run Fails).
            % A Failure While Backing Up Restores What Was Done And Rethrows
            action = struct('config', 'copy', 'forcing', 'move', 'seed', 'move');
            switch level
                case 'full'
                    action.forcing = '';
                    action.seed = '';
                case 'reuse_sampling'
                    action.seed = 'copy';
            end
            backed_up = struct('name', {}, 'file', {}, 'previous', {}, 'existed', {});
            try
                for kk = 1:numel(backups)
                    entry = backups(kk);
                    if isempty(action.(entry.name))
                        continue
                    end
                    entry.existed = isfile(entry.file);
                    if entry.existed && strcmp(action.(entry.name), 'copy')
                        copyfile(entry.file, entry.previous, 'f');
                    elseif entry.existed
                        movefile(entry.file, entry.previous, 'f');
                    end
                    backed_up(end+1) = entry; %#ok<AGROW>
                end
            catch failure
                chess.Project.restore_run_files(backed_up);
                rethrow(failure);
            end
        end

        function not_restored = restore_run_files(backed_up)
            % Failed Run: Put Back What The Run Backed Up And Delete The Files It Created Where There Were None.
            % not_restored: '<file> (<reason>)' Of What Could Not Be Put Back
            not_restored = {};
            for kk = 1:numel(backed_up)
                try
                    if backed_up(kk).existed
                        if isfile(backed_up(kk).previous)
                            movefile(backed_up(kk).previous, backed_up(kk).file, 'f');
                        end
                    elseif isfile(backed_up(kk).file)
                        delete(backed_up(kk).file);
                    end
                catch failure
                    not_restored{end+1} = sprintf('%s (%s)', backed_up(kk).file, failure.message); %#ok<AGROW>
                end
            end
        end

        function move_in_one_step(source, target)
            % One java.nio ATOMIC_MOVE
            options = javaArray('java.nio.file.CopyOption', 1);
            options(1) = java.nio.file.StandardCopyOption.ATOMIC_MOVE;
            java.nio.file.Files.move(java.io.File(source).toPath(), java.io.File(target).toPath(), options);
        end

        function reason = move_failure_reason(failure)
            % Short Reason Of A Failed java.nio Call, e.g. 'access denied'
            reason = regexp(failure.message, 'java\.nio\.file\.(\w+)Exception', 'tokens', 'once');
            if isempty(reason)
                reason = strtrim(failure.message);
            else
                reason = lower(regexprep(reason{1}, '(?<=[a-z])([A-Z])', ' $1'));
            end
        end

        function tf = same_path(a, b)
            % Same Folder Or File (Either Slash, Trailing Separators Ignored, Case-Insensitive On Windows)
            tf = strcmp(chess.Project.comparable_path(a), chess.Project.comparable_path(b));
        end

        function path = comparable_path(path)
            path = regexprep(strrep(char(path), '\', '/'), '(?<=.)/+$', '');
            if ispc
                path = lower(path);
            end
        end

        function [sources, names] = folder_entries(root, prefix)
            % Zip Entries Of Every File And Folder Under root, Named prefix/<subpath> ('/' Separators, Folders End With '/').
            % sources: File Path ('' For A Folder Entry)
            listing = dir(fullfile(root, '**'));
            listing = listing(~ismember({listing.name}, {'.', '..'}));
            relative = strrep(extractAfter(fullfile({listing.folder}', {listing.name}'), numel(root)), '\', '/');
            names = [{[prefix '/']}; strcat(prefix, relative)];
            sources = [{''}; fullfile({listing.folder}', {listing.name}')];
            is_folder = [true; [listing.isdir]'];
            names(is_folder & ~endsWith(names, '/')) = strcat(names(is_folder & ~endsWith(names, '/')), '/');
            sources(is_folder) = {''};
        end

        function write_zip(zip_file, sources, names)
            % Zip Archive Of sources (Files; '' = Folder Entry) Under names, File Dates Kept. A Failed Write Leaves No Archive
            stream = java.util.zip.ZipOutputStream(java.io.FileOutputStream(zip_file));
            try
                for kk = 1:numel(names)
                    entry = java.util.zip.ZipEntry(names{kk});
                    if ~isempty(sources{kk})
                        entry.setTime(java.io.File(sources{kk}).lastModified());
                    end
                    stream.putNextEntry(entry);
                    if ~isempty(sources{kk})
                        java.nio.file.Files.copy(java.io.File(sources{kk}).toPath(), stream);
                    end
                    stream.closeEntry();
                end
                stream.close();
            catch failure
                try
                    stream.close();
                catch
                end
                delete(zip_file);
                rethrow(failure);
            end
        end

        function protection_system = build_protection_system(structure_type, inputs, unit_system)
            % Protection System Of PSE Inputs In unit_system (chess.ProtectionSystem.create Errors When They Do Not Build It)
            inputs = chess.Config.to_SI(inputs, unit_system);
            inputs.struc_type = structure_type;
            protection_system = chess.ProtectionSystem.create(inputs);
        end

        function project = from_saved_struct(saved, project_folder)
            % Project Of A Saved Project Struct, Opened In project_folder
            if ~isfield(saved, 'format_version') || saved.format_version > chess.Project.format_version
                error('chess:Project:unknownFormat', 'The project file was written by a newer CHESS version.');
            end
            project = chess.Project();
            for field = {'name', 'vertical_datum', 'confidence_limits', 'unit_system', 'chs_dependencies', 'pses'}
                project.(field{1}) = saved.(field{1});
            end
            token = chess.Project.folder_token;
            project.storm_databases = chess.Project.replace_path_start(saved.storm_databases, token, project_folder);
            project.tide_files = chess.Project.replace_path_start(saved.tide_files, token, project_folder);
        end

        function folder = full_path(folder)
            % Absolute Path Of An Existing Folder
            listing = dir(folder);
            folder = listing(1).folder;
        end
    end
end

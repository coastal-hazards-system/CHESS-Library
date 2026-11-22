function project = convert_v2_project(source)
% convert_v2_project  Convert a project file of the v2.0.0 CHESS GUI to the chess.Project format (one-time tool).
%   project = convert_v2_project(project_folder)
%   project = convert_v2_project(project_file)
%
%   Reads CHESS_project_<name>.mat written by the v2.0.0 GUI (a chessProject
%   object, variable chess_project), builds the same project with the
%   chess.Project API (PSEs, alternatives with their inputs and multi-line
%   stages, runs, storm database records, tide files, CHS_Dependencies
%   folder) and saves it in the chess.Project format. Paths saved under
%   the old project folder are pointed into the folder the file is in, so
%   a moved or copied project folder converts where it is.
%
%   On disk:
%     - the original file is copied, unchanged, to
%       CHESS_project_<name>_before_conversion.mat in the same folder
%       (the tool errors, and writes nothing, when that file exists);
%     - CHESS_project_<name>.mat is overwritten with the converted project.
%   Nothing else in the project folder is touched. The converted file
%   cannot be opened by the v2.0.0 GUI (keep the backup for that).
%
%   Usage (CHESS_Library and its path set up first):
%       addpath('CHESS_Library'); chess_setup_path;
%       addpath('CHESS_Library/Tools/convert_v2_project');
%       convert_v2_project('D:\Projects\My_Project');
%       project = chess.Project.open('D:\Projects\My_Project');
%   The tool puts its own folder on the path only while it runs (for the
%   class chessProject the old file needs); chess_setup_path never adds it.
%
%   Inputs:
%     source - project folder <root>\<name> or its project file
%              <root>\<name>\CHESS_project_<name>.mat, char or string
%   Outputs:
%     project - converted project, chess.Project (already saved)
%
%   The alternative inputs are kept as saved, without building the
%   structure. Alternatives whose inputs do not build it with this CHESS
%   version (e.g. an input added after v2.0.0) are listed in the warning
%   convert_v2_project:incompleteInputs; complete them in the GUI or with
%   chess.Project.set_inputs before running them. The stage 1 alternative
%   of a multi-line PSE is placed first.
%   A file that holds its storm databases as import window objects (older
%   than storm database records) is not converted.
%
%   Errors: convert_v2_project:noProjectFile, :alreadyConverted,
%   :notV2ProjectFile, :backupExists, :folderName, :unsupportedFormat.
%
%   See also chess.Project.open, chess.Project.create, chessProject.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

source = char(source);
if isfolder(source)
    project_folder = full_path(source);
    [~, folder_name] = fileparts(project_folder);
    file = fullfile(project_folder, ['CHESS_project_' folder_name '.mat']);
else
    file = source;
    project_folder = fileparts(file);
end
if ~isfile(file)
    error('convert_v2_project:noProjectFile', 'Project file not found: %s', file);
end
project_folder = full_path(project_folder);
[~, name, extension] = fileparts(file);
file = fullfile(project_folder, [name extension]);
variables = who('-file', file);
if ismember('project', variables)
    error('convert_v2_project:alreadyConverted', 'This project file is already in the chess.Project format: %s', file);
elseif ~ismember('chess_project', variables)
    error('convert_v2_project:notV2ProjectFile', 'Not a project file of the v2.0.0 CHESS GUI (no variable chess_project): %s', file);
end
backup_file = [file(1:end-4) '_before_conversion.mat'];
if isfile(backup_file)
    error('convert_v2_project:backupExists', ['The backup file already exists: %s\nMove or delete it first ',...
        '(the tool never overwrites it).'], backup_file);
end

tool_folder = fileparts(mfilename('fullpath'));
if ~any(strcmpi(tool_folder, strsplit(path, pathsep)))
    addpath(tool_folder);
    remove_tool_folder = onCleanup(@() rmpath(tool_folder));
end
saved = load(file, 'chess_project');
old = saved.chess_project;
if ~isa(old, 'chessProject')
    error('convert_v2_project:notV2ProjectFile', 'Not a project file of the v2.0.0 CHESS GUI: %s', file);
end
[root_folder, folder_name] = fileparts(project_folder);
if ~strcmp(old.name, folder_name)
    error('convert_v2_project:folderName', 'The project file must be inside its project folder "%s" (found in "%s").',...
        old.name, folder_name);
end
if isobject(old.stormDB_list)
    error('convert_v2_project:unsupportedFormat', ['This project file holds its storm databases as import window ',...
        'objects (written before storm database records). Its format is not converted.']);
end

project = chess.Project.create(old.name, root_folder, old.vdatum, old.CLs, old.unitsys);
project.chs_dependencies = old.chs_dependencies;
add_pses(project, old);
warn_incomplete_inputs(project);
old_folder = fullfile(old.path, old.name);
records = chess.Project.replace_path_start(old.stormDB_list, old_folder, project_folder);
for r = 1:numel(records)
    project.add_storm_database(records(r));
end
tide_files = chess.Project.replace_path_start(old.tide_files_list, old_folder, project_folder);
for t = 1:numel(tide_files)
    project.add_tide_file(tide_files{t});
end

clear saved old % No chessProject Object Left When The Tool Folder Leaves The Path
copyfile(file, backup_file);
project.save();
end

function add_pses(project, old)
% PSEs And Alternatives Of The Old Parallel Lists (By Position), Stage 1 First In A Multi-Line PSE
for p = 1:numel(old.pse_list)
    pse = old.pse_list{p};
    project.add_pse(pse);
    multiline = old.multiline(strcmp(pse, {old.multiline.pse}));
    names = {};
    if p <= numel(old.alternative_list)
        names = old.alternative_list{p};
    end
    stages = zeros(numel(names), 1);
    for a = 1:numel(names)
        if ~isempty(multiline) && strcmp(names{a}, multiline(1).stage1)
            stages(a) = 1;
        elseif ~isempty(multiline) && any(strcmp(names{a}, multiline(1).stage2))
            stages(a) = 2;
        end
    end
    [~, order] = sort(stages ~= 1);
    for a = reshape(order, 1, [])
        geometry = list_item(old.pse_geometry, p, a);
        table = list_item(old.pse_tables, p, a);
        if iscell(table) && size(table, 2) >= 4
            inputs = cell2struct(table(:, 4), table(:, 1), 1);
        else % No Table Kept: The Saved Geometry Holds The Inputs
            inputs = rmfield(geometry, intersect(fieldnames(geometry), {'struc_type', 'pse_type', 'add_toe_berm'}));
        end
        project.add_alternative(pse, names{a}, geometry.struc_type, inputs, stages(a), false);
        rows = list_item(old.sims, p, a);
        if isstruct(rows)
            for r = 1:numel(rows)
                project.record_run(pse, names{a}, rows(r));
            end
        end
    end
end
end

function warn_incomplete_inputs(project)
% Warning Listing The Alternatives Whose Inputs Do Not Build Their Structure
problems = {};
pses = project.pse_names();
for p = 1:numel(pses)
    alternatives = project.alternative_names(pses{p});
    for a = 1:numel(alternatives)
        try
            project.protection_system(pses{p}, alternatives{a});
        catch failure
            problems{end+1, 1} = sprintf('  %s / %s: %s', pses{p}, alternatives{a}, failure.message); %#ok<AGROW>
        end
    end
end
if ~isempty(problems)
    warning('convert_v2_project:incompleteInputs', ['%d alternative(s) have inputs that do not build their ',...
        'structure; complete them before running them:\n%s'],numel(problems), strjoin(problems, newline));
end
end

function item = list_item(list, p, a)
% Item (p, a) Of A Per-PSE, Per-Alternative List Of The Old Class ([] When It Has None)
item = [];
if p > numel(list) || a > numel(list{p})
    return
end
if iscell(list{p})
    item = list{p}{a};
else
    item = list{p}(a);
end
end

function folder = full_path(folder)
% Absolute Path Of An Existing Folder ('' Is The Current Folder)
listing = dir(folder);
folder = listing(1).folder;
end

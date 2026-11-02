function paths = chess_paths(varargin)
%{
    %% DESCRIPTION
        Single source of CHESS output folders and file names, shared by
        the library and the GUI:
            <outfolder>\<project>\
                Event_Database\<db>.mat, <db>_raw_files.mat
                PSE\<pse>\<alt>\<wf_folder>\<db>_<wflow_name>_*.mat
        <db> is the storm database name. Every run file of an alternative
        starts with <db>_<wflow_name>, so runs with different storm
        databases (or CHS savepoints/regions) never share a file.
        wf_folder and wflow_name come from the workflow table
        (chess_workflows.m: 1 PROS/PROS-RB, 2 DET/DET, 3 LCS/LCS,
        4 PROS/PROS-FB). The 'parse' form reads a run file name back into
        its storm database, workflow and file type.

    %% INPUTS
        Call forms:
            paths = chess_paths(config)
            paths = chess_paths(outfolder, project_name, pse, alt, workflow, db)
            paths = chess_paths(outfolder, project_name)   (project level only)
            paths = chess_paths(outfolder, project_name, pse)   (+ PSE folder)
            paths = chess_paths(outfolder, project_name, pse, alt)   (+ alternative folder)
            run_file = chess_paths('parse', file_name)
        config: CHESS configuration. Uses outfolder, project_name,
            struc_id (PSE), case_name (alternative), workflow, and
            storm_db when non-empty; otherwise <db> = <region>_SP<sp_ID>. | struc
        outfolder: Root output folder. | char
        project_name: Project name. | char
        pse: PSE name (config.struc_id). | char
        alt: Alternative name (config.case_name). | char
        workflow: 1 (PROS), 2 (DET), 3 (LCS) or 4 (PROS-FB). | double
        db: Storm database name (a number is used as its digits). | char, string or double
        file_name: Run file name, with or without its folder. | char

    %% OUTPUTS
        paths: | struc
            project_dir: <outfolder>\<project>. | char
            event_db_dir: <project_dir>\Event_Database. | char
            pse_root_dir: <project_dir>\PSE (folder of every PSE). | char
            Three-input and longer forms also return:
            pse_dir: <pse_root_dir>\<pse>. | char
            Four-input and longer forms also return:
            alt_dir: <pse_dir>\<alt>. | char
            Six-input and config forms also return:
            db: Storm database name. | char
            storm_db: <event_db_dir>\<db>.mat (storm, prob_mass). | char
            chs_data: <event_db_dir>\<db>_raw_files.mat (CHS_Data). | char
            wf_folder: Workflow folder name. | char
            wflow_name: Workflow name used in file names. | char
            wf_dir: <alt_dir>\<wf_folder>. | char
            prefix: <wf_dir>\<db>_<wflow_name>. | char
            out_files: config, resp_data, project_forcing (<prefix>_config_file.mat,
                _project_responses.mat, _project_forcing.mat). | struc
        run_file ('parse' form): [] when file_name is not a run file
            <db>_<wflow_name>_<file_type>(_prev).mat (case-insensitive), else: | struc
            db: Storm database name, as in the file name. | char
            workflow: Workflow number. | double
            wflow_name: Workflow name (chess_workflows.m spelling). | char
            wf_folder: Workflow folder name. | char
            file_type: 'config_file', 'project_forcing', 'project_responses'
                or 'sampling_seed'. | char
            is_backup: true for a run backup (_prev.mat). | logical

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin == 2 && strcmp(varargin{1}, 'parse')
    paths = parse_run_file_name(varargin{2});
    return
end
if nargin == 1
    config = varargin{1};
    if isfield(config, 'storm_db') && ~isempty(config.storm_db)
        db = char(string(config.storm_db)); % string(): A Numeric Excel Cell Becomes Its Digits, Not A Character Code
    else
        db = [char(config.region) '_SP' num2str(config.sp_ID)];
    end
    paths = chess_paths(config.outfolder, config.project_name, config.struc_id,...
        config.case_name, config.workflow, db);
    return
end
% Project Level
paths.project_dir = fullfile(varargin{1}, varargin{2});
paths.event_db_dir = fullfile(paths.project_dir, 'Event_Database');
paths.pse_root_dir = fullfile(paths.project_dir, 'PSE');
if nargin == 2
    return
end
paths.pse_dir = fullfile(paths.pse_root_dir, varargin{3});
if nargin == 3
    return
end
paths.alt_dir = fullfile(paths.pse_dir, varargin{4});
if nargin == 4
    return
end
[workflow, db] = varargin{5:6};
% Storm Database Files (Project Level, Shared By Every PSE/Alternative)
paths.db = char(string(db));
paths.storm_db = fullfile(paths.event_db_dir, [paths.db '.mat']);
paths.chs_data = fullfile(paths.event_db_dir, [paths.db '_raw_files.mat']);
% Alternative Run Files
workflow_row = chess_workflows(workflow);
paths.wf_folder = workflow_row.folder;
paths.wflow_name = workflow_row.wflow_name;
paths.wf_dir = fullfile(paths.alt_dir, paths.wf_folder);
paths.prefix = fullfile(paths.wf_dir, [paths.db '_' paths.wflow_name]);
paths.out_files.config = [paths.prefix '_config_file.mat'];
paths.out_files.resp_data = [paths.prefix '_project_responses.mat'];
paths.out_files.project_forcing = [paths.prefix '_project_forcing.mat'];
end

%% AUX FUNCTIONS
function run_file = parse_run_file_name(file_name)
% Run File Name -> Storm Database, Workflow And File Type ([] When Not A Run File). The Greedy <db> Takes Everything Before
% The Last _<wflow_name>_<file_type>, So A Storm Database Name Holding A Workflow Name Still Reads Back Whole
[~, name, ext] = fileparts(char(file_name));
workflows = chess_workflows();
wflow_names = strjoin(cellfun(@(x) regexptranslate('escape', x), {workflows.wflow_name}, 'un', false), '|');
tok = regexpi([name ext], ['^(.+)_(' wflow_names ')_(config_file|project_forcing|project_responses|sampling_seed)'...
    '(?:_prev)?\.mat$'], 'tokens', 'once');
if isempty(tok)
    run_file = [];
    return
end
workflow_row = workflows(strcmpi(tok{2}, {workflows.wflow_name}));
run_file = struct('db', tok{1}, 'workflow', workflow_row.number, 'wflow_name', workflow_row.wflow_name,...
    'wf_folder', workflow_row.folder, 'file_type', lower(tok{3}), 'is_backup', endsWith(name, '_prev', 'IgnoreCase', true));
end

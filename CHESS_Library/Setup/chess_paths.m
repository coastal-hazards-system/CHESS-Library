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
            Workflow | wf_folder | wflow_name
                1    |   PROS    |  PROS-RB
                2    |   DET     |  DET
                3    |   LCS     |  LCS
                4    |   PROS    |  PROS-FB

    %% INPUTS
        Call forms:
            paths = chess_paths(config)
            paths = chess_paths(outfolder, project_name, pse, alt, workflow, db)
            paths = chess_paths(outfolder, project_name)   (project level only)
        config: CHESS configuration. Uses outfolder, project_name,
            struc_id (PSE), case_name (alternative), workflow, and
            storm_db when non-empty; otherwise <db> = <region>_SP<sp_ID>. | struc
        outfolder: Root output folder. | char
        project_name: Project name. | char
        pse: PSE name (config.struc_id). | char
        alt: Alternative name (config.case_name). | char
        workflow: 1 (PROS), 2 (DET), 3 (LCS) or 4 (PROS-FB). | double
        db: Storm database name (a number is used as its digits). | char, string or double

    %% OUTPUTS
        paths: | struc
            project_dir: <outfolder>\<project>. | char
            event_db_dir: <project_dir>\Event_Database. | char
            Six-input and config forms also return:
            db: Storm database name. | char
            storm_db: <event_db_dir>\<db>.mat (storm, prob_mass). | char
            chs_data: <event_db_dir>\<db>_raw_files.mat (CHS_Data). | char
            alt_dir: <project_dir>\PSE\<pse>\<alt>. | char
            wf_folder: Workflow folder name. | char
            wflow_name: Workflow name used in file names. | char
            wf_dir: <alt_dir>\<wf_folder>. | char
            prefix: <wf_dir>\<db>_<wflow_name>. | char
            out_files: config, resp_data, project_forcing (<prefix>_config_file.mat,
                _project_responses.mat, _project_forcing.mat). | struc

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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
if nargin == 2
    return
end
[pse, alt, workflow, db] = varargin{3:6};
% Storm Database Files (Project Level, Shared By Every PSE/Alternative)
paths.db = char(string(db));
paths.storm_db = fullfile(paths.event_db_dir, [paths.db '.mat']);
paths.chs_data = fullfile(paths.event_db_dir, [paths.db '_raw_files.mat']);
% Alternative Run Files
switch workflow
    case 1
        paths.wf_folder = 'PROS';
        paths.wflow_name = 'PROS-RB';
    case 2
        paths.wf_folder = 'DET';
        paths.wflow_name = 'DET';
    case 3
        paths.wf_folder = 'LCS';
        paths.wflow_name = 'LCS';
    case 4
        paths.wf_folder = 'PROS';
        paths.wflow_name = 'PROS-FB';
    otherwise
        error('Error: workflow must be 1 (PROS), 2 (DET), 3 (LCS), or 4 (PROS-FB).');
end
paths.alt_dir = fullfile(paths.project_dir, 'PSE', pse, alt);
paths.wf_dir = fullfile(paths.alt_dir, paths.wf_folder);
paths.prefix = fullfile(paths.wf_dir, [paths.db '_' paths.wflow_name]);
paths.out_files.config = [paths.prefix '_config_file.mat'];
paths.out_files.resp_data = [paths.prefix '_project_responses.mat'];
paths.out_files.project_forcing = [paths.prefix '_project_forcing.mat'];
end

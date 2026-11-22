function paths = build(varargin)
% build  CHESS output folders and run file names.
%   paths = chess.ProjectPaths.build(config)
%   paths = chess.ProjectPaths.build(outfolder, project_name, pse, alt, workflow, db)
%   paths = chess.ProjectPaths.build(outfolder, project_name)
%   paths = chess.ProjectPaths.build(outfolder, project_name, pse)
%   paths = chess.ProjectPaths.build(outfolder, project_name, pse, alt)
%
%   Single source of CHESS output folders and file names, shared by the
%   library and the GUI:
%       <outfolder>\<project>\
%           Event_Database\<db>.mat, <db>_raw_files.mat
%           PSE\<pse>\<alt>\<wf_folder>\<db>_<wflow_name>_*.mat
%   <db> is the storm database name. Every run file of an alternative
%   starts with <db>_<wflow_name>, so runs with different storm databases
%   (or CHS savepoints/regions) never share a file. wf_folder and
%   wflow_name come from the workflow table (chess.Model.workflows: 1 PROS/PROS-RB,
%   2 DET/DET, 3 LCS/LCS, 4 PROS/PROS-FB). The config and six-input forms
%   give every path; the two-input form the project level only, the
%   three-input form adds the PSE folder and the four-input form the
%   alternative folder. chess.ProjectPaths.parse_run_file reads a run file
%   name back into its storm database, workflow and file type.
%
%   Inputs:
%     config       - CHESS configuration, 1x1 struct; reads outfolder,
%                    project_name, struc_id (PSE), case_name (alternative),
%                    workflow, and storm_db when non-empty, otherwise
%                    <db> = <region>_SP<sp_ID>
%     outfolder    - root output folder, char
%     project_name - project name, char
%     pse          - PSE name (config.struc_id), char
%     alt          - alternative name (config.case_name), char
%     workflow     - workflow number, 1 (PROS-RB), 2 (DET), 3 (LCS) or
%                    4 (PROS-FB), double
%     db           - storm database name (a number is used as its digits),
%                    char, string or double
%   Outputs:
%     paths    - output folders and files, struct:
%                  project_dir  - <outfolder>\<project>, char
%                  event_db_dir - <project_dir>\Event_Database, char
%                  pse_root_dir - <project_dir>\PSE (folder of every PSE),
%                                 char
%                Three-input and longer forms also return:
%                  pse_dir      - <pse_root_dir>\<pse>, char
%                Four-input and longer forms also return:
%                  alt_dir      - <pse_dir>\<alt>, char
%                Six-input and config forms also return:
%                  db           - storm database name, char
%                  storm_db     - <event_db_dir>\<db>.mat (storm, prob_mass),
%                                 char
%                  chs_data     - <event_db_dir>\<db>_raw_files.mat
%                                 (CHS_Data), char
%                  wf_folder    - workflow folder name, char
%                  wflow_name   - workflow name used in file names, char
%                  wf_dir       - <alt_dir>\<wf_folder>, char
%                  prefix       - <wf_dir>\<db>_<wflow_name>, char
%                  out_files    - config, resp_data, project_forcing
%                                 (<prefix>_config_file.mat,
%                                 _project_responses.mat,
%                                 _project_forcing.mat), struct
%                  sampling_seed - <prefix>_sampling_seed.mat (LCS
%                                 sampling seed), char
%                  backup_files - the _prev.mat backup name of each
%                                 out_files entry and of sampling_seed,
%                                 struct
%
%   See also chess.Model.workflows, chess.Model.create, chess.Config.read_sections.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
if nargin == 1
    config = varargin{1};
    if isfield(config, 'storm_db') && ~isempty(config.storm_db)
        db = char(string(config.storm_db)); % string(): A Numeric Excel Cell Becomes Its Digits, Not A Character Code
    else
        db = [char(config.region) '_SP' num2str(config.sp_ID)];
    end
    paths = chess.ProjectPaths.build(config.outfolder, config.project_name, config.struc_id,...
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
workflow_row = chess.Model.workflows(workflow);
paths.wf_folder = workflow_row.folder;
paths.wflow_name = workflow_row.wflow_name;
paths.wf_dir = fullfile(paths.alt_dir, paths.wf_folder);
paths.prefix = fullfile(paths.wf_dir, [paths.db '_' paths.wflow_name]);
paths.out_files.config = [paths.prefix '_config_file.mat'];
paths.out_files.resp_data = [paths.prefix '_project_responses.mat'];
paths.out_files.project_forcing = [paths.prefix '_project_forcing.mat'];
% LCS Sampling Seed (Written Next To The Project Forcing File)
paths.sampling_seed = [paths.prefix '_sampling_seed.mat'];
% Backups Of A Previous Run (_prev.mat)
for name = {'config', 'resp_data', 'project_forcing'}
    paths.backup_files.(name{1}) = strrep(paths.out_files.(name{1}), '.mat', '_prev.mat');
end
paths.backup_files.sampling_seed = strrep(paths.sampling_seed, '.mat', '_prev.mat');
end

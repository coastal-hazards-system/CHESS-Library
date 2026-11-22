function run_file = parse_run_file(file_name)
% parse_run_file  Storm database, workflow and file type of a run file name.
%   run_file = chess.ProjectPaths.parse_run_file(file_name)
%
%   Inputs:
%     file_name - run file name, with or without its folder, char
%   Outputs:
%     run_file - [] when file_name is not a run file
%                <db>_<wflow_name>_<file_type>(_prev).mat (case-insensitive),
%                else a struct:
%                  db         - storm database name, as in the file name,
%                               char
%                  workflow   - workflow number, double
%                  wflow_name - workflow name (chess.Model.workflows
%                               spelling), char
%                  wf_folder  - workflow folder name, char
%                  file_type  - 'config_file', 'project_forcing',
%                               'project_responses' or 'sampling_seed', char
%                  is_backup  - true for a run backup (_prev.mat), logical
%
%   See also chess.ProjectPaths.build, chess.Model.workflows.
% Run File Name -> Storm Database, Workflow And File Type ([] When Not A Run File). The Greedy <db> Takes Everything Before
% The Last _<wflow_name>_<file_type>, So A Storm Database Name Holding A Workflow Name Still Reads Back Whole
[~, name, ext] = fileparts(char(file_name));
workflows = chess.Model.workflows();
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

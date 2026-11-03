function workflows = chess_workflows(workflow_number)
% chess_workflows  Table of the CHESS workflows (number, folder, name).
%   workflows = chess_workflows() returns the whole table.
%   workflows = chess_workflows(workflow_number) returns the row of that
%   workflow.
%
%   Table of the CHESS workflows: the workflow number (config.workflow), the
%   output folder of its runs and the workflow name used in its run file
%   names (chess_paths). Single source of these names for the library and
%   the GUI.
%       number | folder | wflow_name
%          1   |  PROS  |  PROS-RB   (PROS, response based)
%          2   |  DET   |  DET       (deterministic)
%          3   |  LCS   |  LCS       (life cycle simulation)
%          4   |  PROS  |  PROS-FB   (PROS, frequency based)
%
%   An unknown workflow number raises chess_workflows:unknownWorkflow.
%
%   Inputs:
%     workflow_number - (optional) workflow number (config.workflow) [-],
%                       scalar double; without it the whole table is returned
%   Outputs:
%     workflows - table rows ordered by number (4x1 without input, 1x1 with
%                 workflow_number), struct array with fields:
%                   number     - workflow number [-], double
%                   folder     - run folder name under the alternative folder,
%                                char
%                   wflow_name - workflow name in the run file names (upper
%                                case), char
%
%   Tier: internal
%
%   See also chess_paths, call_input_parser.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

workflows = struct('number', {1; 2; 3; 4},...
    'folder', {'PROS'; 'DET'; 'LCS'; 'PROS'},...
    'wflow_name', {'PROS-RB'; 'DET'; 'LCS'; 'PROS-FB'});
if nargin == 0
    return
end
row = [];
if isnumeric(workflow_number) && isscalar(workflow_number)
    row = find([workflows.number] == workflow_number, 1);
end
if isempty(row)
    error('chess_workflows:unknownWorkflow', 'Error: workflow must be 1 (PROS), 2 (DET), 3 (LCS), or 4 (PROS-FB).');
end
workflows = workflows(row);
end

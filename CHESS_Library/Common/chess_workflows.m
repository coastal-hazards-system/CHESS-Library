function workflows = chess_workflows(workflow_number)
%{
    %% DESCRIPTION
        Table of the CHESS workflows: the workflow number (config.workflow),
        the output folder of its runs and the workflow name used in its run
        file names (chess_paths.m). Single source of these names for the
        library and the GUI.
            number | folder | wflow_name
               1   |  PROS  |  PROS-RB   (PROS, response based)
               2   |  DET   |  DET       (deterministic)
               3   |  LCS   |  LCS       (life cycle simulation)
               4   |  PROS  |  PROS-FB   (PROS, frequency based)

    %% INPUTS
        workflow_number (optional): Workflow number (config.workflow).
            Without it the whole table is returned. | double

    %% OUTPUTS
        workflows: [4x1] struct array ordered by number (or the row of
            workflow_number), fields: | struct
            number: Workflow number. | double
            folder: Run folder name under the alternative folder. | char
            wflow_name: Workflow name in the run file names (upper case). | char

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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

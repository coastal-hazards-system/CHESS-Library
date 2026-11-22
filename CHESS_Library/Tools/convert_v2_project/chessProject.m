classdef chessProject < handle
    % chessProject  Project object of the v2.0.0 CHESS GUI, kept only for convert_v2_project.
    %   Project files written by the v2.0.0 GUI hold a chessProject object
    %   (variable chess_project in CHESS_project_<name>.mat); MATLAB needs
    %   this class definition to load that object. It exists only for the
    %   one-time conversion tool convert_v2_project, which puts this folder
    %   on the path while it runs. The library and the GUI do not use it.
    %   It has no methods. Keep the class name: the project files store it.
    %
    %   See also convert_v2_project, chess.Project.

    properties
        name char
        path char
        vdatum char
        CLs double
        unitsys char
        pse_list cell
        alternative_list cell
        stormDB_list % Storm DB Records (Struct Array)
        tide_files_list cell
        pse_tables cell
        pse_geometry cell
        sims cell = {}
        sim_record table
        chs_dependencies char = ''
        multiline struct = struct('pse', {}, 'stage1', {}, 'stage2', {})
        pse_indx
        alt_indx
        db_indx
    end
end

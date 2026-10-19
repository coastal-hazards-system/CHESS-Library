function sp = CHESSPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
% CHESSPLOTS Factory function — returns a workflow-specific plotting object.
%   sp = CHESSPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
%
%   config.workflow = 1 or 4  →  pros_methods instance
%   config.workflow = 2       →  det_methods instance
%   config.workflow = 3       →  lcs_methods instance
switch config.workflow
    case {1, 4}
        sp = pros_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    case 2
        sp = det_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    case 3
        sp = lcs_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    otherwise
        error('CHESSPlots:unsupportedWorkflow', 'Workflow %d is not supported.', config.workflow);
end
end

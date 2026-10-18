function sp = StormsimPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
% STORMSIMPLOTS Factory function — returns a workflow-specific plotting object.
%   sp = StormsimPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
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
        error('StormsimPlots:unsupportedWorkflow', 'Workflow %d is not supported.', config.workflow);
end
end

function config = finalize_structure_config(config)
% finalize_structure_config  Apply the structure-level rules to config.
%   config = finalize_structure_config(config) applies the structure-level
%   rules before the structure geometry is created. Needs only the
%   structure type and geometry fields (no workflow, forcing or response
%   inputs), so it can run as soon as a structure is defined. No file I/O;
%   idempotent.
%
%   Toe berms are hidden until their conceptual models are set: for every
%   structure type add_toe_berm = 0, berm_seaward_slope = 1,
%   berm_crest_width = 0 and berm_crest_elevation = 0. A floodwall without
%   a toe berm sits on its wall bottom: toe_elevation =
%   wall_bottom_elevation.
%
%   Inputs:
%     config - CHESS configuration, 1x1 struct; reads:
%                struc_type            - structure type (1 Levee,
%                                        2 Floodwall, 3 Rubblemound),
%                                        double
%                add_toe_berm          - toe berm switch (optional, default
%                                        0), 0/1
%                wall_bottom_elevation - wall bottom elevation [m, study
%                                        datum, positive up] (required for
%                                        floodwalls), double
%   Outputs:
%     config - configuration with add_toe_berm, the berm fields and (for
%              floodwalls) toe_elevation set, 1x1 struct
%
%   Tier: internal
%
%   See also finalize_config, create_structure_geometry, call_input_parser.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

% Toe Berm Switch Not Provided
if ~isfield(config, 'add_toe_berm') || isempty(config.add_toe_berm)
    config.add_toe_berm = 0;
end

%% BERM RULES
% Hide Berms Until Conceptual Models Are Set (Floodwalls Included 2026-10-05)
switch config.struc_type
    case {1,2,3} % Levee, Floodwall, Rubblemounds
        config.add_toe_berm = 0;
        config.berm_seaward_slope = 1;
        config.berm_crest_width = 0;
        config.berm_crest_elevation = 0;
end
% Floodwall Without Berm Sits On Wall Bottom
if config.add_toe_berm == 0 && config.struc_type == 2
    config.toe_elevation = config.wall_bottom_elevation;
end
end

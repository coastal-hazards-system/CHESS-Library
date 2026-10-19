function config = finalize_structure_config(config)
%{
    %% DESCRIPTION
        Applies structure-level rules to "config" before the structure
        geometry is created. Only requires structure type and geometry
        fields (no workflow, forcing or response inputs), so it can be
        called as soon as a structure is defined.
        No file I/O. Safe to call more than once (idempotent).

    %% INPUTS
        config: StormSim configuration. | struc
            Required fields:
                struc_type: Structure type (1 - Levee, 2 - Floodwall,
                            3 - Rubblemound, 4 - Low Crested Breakwater)
            Optional fields:
                add_toe_berm: Toe berm switch (0/1). Defaults to 0.
                wall_bottom_elevation: Required for floodwalls without berm.

    %% OUTPUTS
        config: Updated StormSim configuration. | struc

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% DEFAULTS
% Toe Berm Switch Not Provided (e.g. Low Crested Breakwater Template)
if ~isfield(config, 'add_toe_berm') || isempty(config.add_toe_berm)
    config.add_toe_berm = 0;
end
% Deprecated Or Hidden Features
config.structure_dir = 0; % Assume Shore Normal Waves

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

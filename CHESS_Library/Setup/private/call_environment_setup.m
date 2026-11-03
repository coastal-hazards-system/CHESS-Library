function [config, structure] = call_environment_setup(config, run_flag)
% call_environment_setup  Set up the run environment of a parsed config.
%   [config, structure] = call_environment_setup(config, run_flag) prints
%   the workflow welcome banner (run_flag 1), reports whether the
%   CHS_Dependencies folder covers the region (chs_dependency_files; without
%   it CHESS runs XC only), sets the storm database files in out_files,
%   resolves the hotstart state (resolve_hotstart_state), zero-fills the
%   forcing uncertainty fields for DET (workflow 2), builds the structure
%   geometry (create_structure_geometry) and saves config and structure to
%   out_files.config. Last step of call_input_parser.
%
%   Inputs:
%     config    - parsed CHESS configuration (after finalize_config), 1x1
%                 struct; reads workflow, region (optional, 'NoRegion' when
%                 absent), chs_dependencies, out_files.config and the fields
%                 read by chess_paths, resolve_hotstart_state and
%                 create_structure_geometry
%     run_flag  - 1 to print the welcome banner (no storm database file
%                 yet), 0 otherwise, logical or 0/1
%   Outputs:
%     config    - configuration with out_files.storm_and_prob_mass,
%                 out_files.chs_data and hotstart_level set (DET:
%                 chs_swl_u_a, chs_swl_u_r, chs_hm0_u_a, chs_hm0_u_r = 0
%                 when missing or empty), 1x1 struct
%     structure - structure geometry, 1x1 struct
%
%   Tier: internal
%
%   See also call_input_parser, resolve_hotstart_state,
%   create_structure_geometry, chess_paths.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% CREATE DIRECTORIES
% Define Workflow (chess_workflows.m)
workflow = config.workflow;
if ~isfield(config, 'region')
    chs_region = 'NoRegion';
else
    chs_region = config.region;
end
%% CONFIGURATION RULES
% Structure & Run Rules Are Applied In finalize_structure_config.m & finalize_config.m

%% DISPLAY WELCOME MESSAGE
% Determine What TO Print
if run_flag == 1
    switch workflow
        case {1,4} % CHESS: PROS
            welcome_message = ['************************************************************************' newline...
                '***    Coastal Hazards, Engineering and Structures System (CHESS)    ***' newline...
                '***       CHESS: Probabilistic Responses of Structures (PROS)        ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 2 % CHESS: Deterministic
            welcome_message = ['************************************************************************' newline...
                '***    Coastal Hazards, Engineering and Structures System (CHESS)    ***' newline...
                '***          CHESS: Deterministic Structure Responses (DET)          ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 3 % CHESS: MCS/CSR
            welcome_message = ['************************************************************************' newline...
                '***    Coastal Hazards, Engineering and Structures System (CHESS)    ***' newline...
                '***                CHESS: Life Cycle Simulation (LCS)                ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
    end
    % Display Welcome Banner
    disp(welcome_message);
end

%% CHECK FOR CHS DEPENDENCIES FOLDER
% Without It (Or For A Region It Does Not Cover) CHESS Runs XC Only: A TC/CC Request Already Stopped In call_input_parser.m.
% File Paths Are Looked Up Where They Are Read (chs_dependency_files.m); config Keeps Only chs_dependencies & region
chs_files = chs_dependency_files(config.chs_dependencies, chs_region);
if chs_files.tropical_statistics_available
    disp('External CHS_Dependencies folder found...');
elseif chs_files.folder_exists && chs_files.region_supported
    disp(['External CHS_Dependencies folder found (no TC statistics for ' chs_region ': XC only)...']);
else
    disp('CHS_Dependencies not found. Running in XC-only mode...');
end

%% BUILD FILENAMES FOR SIMULATION
% Project Level Storm Database Files (Event_Database, Shared By Every PSE/Alternative; chess_paths.m)
paths = chess_paths(config);
config.out_files.storm_and_prob_mass = paths.storm_db;
config.out_files.chs_data = paths.chs_data;
% Alternative Specific Files (config, resp_data, project_forcing) Are Built In finalize_config.m

%% HOTSTART STATE
% Bias & Uncertainty, TC Bias Correction And Nyrs_XC/Nstm_XC Come From The Storm Database's db_info (storm_db_info.m),
% Applied In call_input_parser.m Or, When The Database Is Built, In call_chs_data_formatter.m
config = resolve_hotstart_state(config);

%% DET: NO FORCING UNCERTAINTY
% Unused By The Deterministic Workflow; Zero-Filled So Downstream Label/Header Lookups Still Work
if workflow == 2
    u_fields = {'chs_swl_u_a','chs_swl_u_r','chs_hm0_u_a','chs_hm0_u_r'};
    for kk = 1:length(u_fields)
        if ~isfield(config, u_fields{kk}) || isempty(config.(u_fields{kk}))
            config.(u_fields{kk}) = 0;
        end
    end
end

%% INITIALIZE GEOMETRY
% Create Structure Variable
[structure] = create_structure_geometry(config);% Second input argument: 1 - show plot 0 - hide plot
% Save Out Configuration & Structure File
save(config.out_files.config, 'config','structure','-v7.3');
end
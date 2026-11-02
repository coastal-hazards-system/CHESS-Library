function [config, structure] = call_environment_setup(config, run_flag)
%{
%% DESCRIPTION
This function initializes the CHESS library.


%% INPUTS
config: Parsed CHESS project input file. MATLAB structure.

%% OUTPUTS
config: MATLAB data structure containing input file data parsed out as
individual strucutre fields.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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
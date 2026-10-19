function [config, structure] = call_environment_setup(config, run_flag)
%{
%% DESCRIPTION
This function initializes the StormSim library.


%% INPUTS
config: Parsed StormSim project input file. MATLAB structure.

%% OUTPUTS
config: MATLAB data structure containing input file data parsed out as
individual strucutre fields.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% CREATE DIRECTORIES
% Define Workflow
workflow = config.workflow;
%
switch workflow
    case 1
        wflow2 = 'PROS';
    case 2
        wflow2 = 'DET';
    case 3
        wflow2 = 'LCS';
    case 4
        wflow2 = 'PROS';
end
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
        case {1,4} % StormSim: PROS
            welcome_message = ['************************************************************************' newline...
                '***           Stochastic Storm Simulation System (StormSim)          ***' newline...
                '***        StormSim: Probabilistic Responses of Structures (PROS)    ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 2 % StormSim: Deterministic
            welcome_message = ['************************************************************************' newline...
                '***           Stochastic Storm Simulation System (StormSim)          ***' newline...
                '***       StormSim: Deterministic Structure Responses (DET)          ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
        case 3 % StormSim: MCS/CSR
            welcome_message = ['************************************************************************' newline...
                '***           Stochastic Storm Simulation System (StormSim)          ***' newline...
                '***               StormSim: Life Cycle Simulation (LCS)              ***' newline...
                '***                          Version 1.0.0                           ***' newline...
                '***                        FOR  TESTING  ONLY                        ***' newline...
                '************************************************************************'];
    end
    % Display Welcome Banner
    disp(welcome_message);
end

%% CHECK FOR CHS DEPENDENCIES FOLDER
% Without It (Or For A Region It Does Not Cover) StormSim Runs XC Only: A TC/CC Request Already Stopped In call_input_parser.m
if chs_dependencies_available(config.chs_dependencies, chs_region)
    disp('External CHS_Dependencies folder found...');
    % Revised function: Returns a cell array of full paths for 0, 1, or N matches
    f_x = @(x, y) fullfile({y(contains({y.name}, x)).folder}, {y(contains({y.name}, x)).name});

    % 1. Get ADCIRC & Wave Model Bias And Uncertainty
    dummy = dir(fullfile(config.chs_dependencies, 'Probability_Masses', config.region, '*.mat'));
    config.in_files.tc_dsw = cell2mat(f_x('DSW', dummy));
    config.in_files.tc_master_table = cell2mat(f_x('Param', dummy));

    % 2. Atlantic Basin TC Statistics
    dummy = dir(fullfile(config.chs_dependencies, 'Probability_Masses', '*.mat'));
    config.in_files.crl = cell2mat(f_x('CRLs', dummy)); % Coastal Reference Locations
    config.in_files.tc_srr = f_x('SRR', dummy); % Storm Recurrance Rates [stm/yr*Km] at CRLs

    % 3. Study Grid
    dummy = dir(fullfile(config.chs_dependencies, 'Grid_Files', config.region, '*.mat'));
    config.in_files.grid = cell2mat(f_x(config.region, dummy));

    % 4. Model Bias & Epistemic Uncertainty
    dummy = dir(fullfile(config.chs_dependencies, 'Bias_and_Uncertainty', config.region, '*.mat'));
    config.in_files.BnU_circulation = cell2mat(f_x({'Comb','WL'}, dummy));
    config.in_files.BnU_waves = cell2mat(f_x({'STWAVE', 'SWAN'}, dummy));
else
    disp('CHS_Dependencies not found. Running in XC-only mode...');
    config.in_files.BnU_circulation = [];
    config.in_files.BnU_waves = [];
    config.in_files.grid = [];
    config.in_files.tc_srr = [];
    config.in_files.crl = [];
    config.in_files.tc_master_table = [];
    config.in_files.tc_dsw = [];
end

%% BUILD FILENAMES FOR SIMULATION
% Project Level Storm Database Files (Event_Database, Shared By Every PSE/Alternative; stormsim_paths.m)
paths = stormsim_paths(config);
config.out_files.storm_and_prob_mass = paths.storm_db;
config.out_files.chs_data = paths.chs_data;
% Alternative Specific Files (config, resp_data, project_forcing) Are Built In finalize_config.m

%% HOTSTART STATE
% Bias & Uncertainty, TC Bias Correction And Nyrs_XC/Nstm_XC Come From The Storm Database's db_info (storm_db_info.m),
% Applied In call_input_parser.m Or, When The Database Is Built, In call_chs_data_formater.m
config = resolve_hotstart_state(config, wflow2);

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
save(config.out_files.config, 'config','structure');
end
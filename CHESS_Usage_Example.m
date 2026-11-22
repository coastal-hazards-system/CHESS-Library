clc;clear all;close all;
addpath('CHESS_Library'); chess_setup_path; % Library On The Path (chess.* Classes And Functions), Tools/ And Retired/ Kept Off
% diary 'Log.txt';
%% USER INPUTS
% Define CHESS Input File Name
chess_input_file = 'CHESS_rubble_mound_inputs.xlsx'; % Include relative path if not in parent directory

%% STEP 1: SET-UP PROJECT ENVIRONMENT
%{
 Description:
   chess.Model.create reads the input file (copy and fill out the provided
   "CHESS_rubble_mound_inputs.xlsx" template; do not change the values
   written under "Model Variable Symbol"), checks every input against the
   rules of the workflow and of the structure (chess.Config.validate: a
   missing or invalid input stops here, with the full list), checks the
   storm data given in chs_zip, prepares the project folders, applies the
   configuration rules, resolves the hotstart level and builds the
   protection system. It returns the model of the requested workflow:
        1 -> chess.Model.Pros           Probabilistic Response Of Structures (PROS, response based)
        2 -> chess.Model.Deterministic  Deterministic structure responses (DET)
        3 -> chess.Model.LifeCycle      Life Cycle Simulation & Coastal Structure Reliability (LCS)
        4 -> chess.Model.Pros           PROS, frequency based
  The model holds:
   model.config             parsed inputs plus the derived fields | 1 x 1 struct
   model.protection_system  chess.ProtectionSystem.Levee, .Floodwall or .RubbleMound
   model.storm_database     chess.CoastalHazardSystem (storm data description)
   model.hotstart           chess.Hotstart (reuse of a saved run)
   model.paths              output folders and files
%}
t1 = tic;
model = chess.Model.create(chess_input_file);
t1 = toc(t1);

%% STEP 2: IMPORT, PROCESS & FORMAT COASTAL HAZARD SYSTEM (CHS) DATA (h5 -> storm database)
%{
 Description:
   Makes sure the storm database holds what the run requests. The CHS zip
   folder (or files) is converted, screened and formatted once and saved to
     <outfolder>\<project>\Event_Database\<db>.mat           (storm, prob_mass, db_info)
     <outfolder>\<project>\Event_Database\<db>_raw_files.mat (converted CHS files)
   An existing database that covers the request is kept as is.
   The storm data itself can be read with
     [storm, prob_mass] = model.storm_database.read();
%}
t2 = tic;
model.prepare_storm_database();
t2 = toc(t2);

%% STEP 3: CREATE PROJECT FORCING (BOUNDARY CONDITIONS)
%{
 Description:
   Builds the project forcing in one call: build (the storm data is laid
   out for the workflow), uncertainty (PROS) and forcing adjustments (sea
   level change, random tides, depth limitation), then saves it once to
   <db>_<workflow>_project_forcing.mat. A complete saved project forcing
   (hotstart) is loaded instead.
   forcing.<Peaks|Timeseries>.<Default|WLP|WHP>.<XC|TC|CC>
%}
t3 = tic;
forcing = model.build_forcing();
t3 = toc(t3);

%% STEP 4: COMPUTE PROJECT RESPONSES
%{
 Description:
   Computes the responses of every requested forcing dataset with the
   workflow of the model and saves them to
     <db>_<workflow>_project_responses.mat                   (Resp)
   The result tables are also written as CSV files (and the config as
   JSON) to the Export folder next to it:
     PROS: one hazard curve file per response, one summary file per
           confidence limit (..._summary_CL50.csv, ...)
     DET:  one row per storm, every maximum with its own date
     LCS:  reliability and damage summaries
   A saved run is exported again with model.export_results().
%}
t4 = tic;
responses = model.compute_responses(forcing);
t4 = toc(t4);

%% PRINT TIME
disp(['Simulation Completed. Total run time: ' num2str(round(sum([t1,t2,t3,t4])/60,2)) ' mins...']);
% diary 'off';

%% ALL STEPS IN ONE CALL
% model = chess.Model.create(chess_input_file);
% [responses, forcing] = model.run();

%% RUNS FROM A PROJECT (chess.Project)
%{
 Description:
   A project keeps PSEs, alternatives, storm databases and runs in one
   record, the same one the GUI opens (CHESS_UI_Call): a project built
   here opens in the GUI, and a GUI project runs from a script.
     <root_folder>\<project>\CHESS_project_<project>.mat     project file
     <root_folder>\<project>\Event_Database\                 storm databases
     <root_folder>\<project>\PSE\<pse>\<alternative>\<PROS|DET|LCS>\   run files
   Uncomment the lines below to use it (help chess.Project lists every
   method).

 % New project (nothing is written until save)
 project = chess.Project.create('My_Project', 'CHESS_Outputs', 'NAVD88', [5 50 95]); % name, root folder, vertical datum, confidence limits
 project.chs_dependencies = 'CHS_Dependencies';                                      % CHS_Dependencies folder of the region

 % Storm database: built from a CHS .zip (or CHS_Data .mat, or storm .mat)
 % and added to the project. Further inputs: create_wlp, create_whp (0/1),
 % datum_offset [m] and replace. A storm database of that name already in
 % the project or its Event_Database folder is kept as is (nothing is
 % built); replace = true builds it again and deletes its runs.
 % Tide file: project.download_tide_file
 project.import_storm_database('SP01234', 'CHS_files.zip');

 % PSE and alternative: structure type (1 levee, 2 floodwall, 3 rubble mound)
 % and its inputs, one field per geometry and property input (SI). The
 % template of the structure type lists them with their default values
 template = chess.Project.structure_template(3);
 rows = [template.geometry; template.properties];        % {symbol, description, units, value}
 inputs = cell2struct(rows(:, 4), rows(:, 1), 1);
 inputs.crest_elevation = 4.5;
 project.add_alternative('Breakwater', 'Existing', 3, inputs);
 inputs.crest_elevation = 5.5;
 project.add_alternative('Breakwater', 'Raised_Crest', 3, inputs);
 project.save();

 % Run: default settings of the workflow (1 PROS-RB, 2 DET, 3 LCS, 4 PROS-FB),
 % changed where needed. The run is recorded in the project and the
 % project is saved
 settings = project.run_settings('Breakwater', 'Existing', 1, 'SP01234');
 settings.swl_slr = 0.3;
 [responses, info] = project.run('Breakwater', 'Existing', settings);
 disp(info.hotstart_level);                              % 'cold', 'reuse_sampling' or 'full' (saved forcing reused)

 % Same settings for every alternative of the PSE
 for alternative = project.alternative_names('Breakwater')'
     settings = project.run_settings('Breakwater', alternative{1}, 1, 'SP01234');
     settings.swl_slr = 0.3;
     project.run('Breakwater', alternative{1}, settings);
 end

 % Existing project (also one made with the GUI): open, look, run again
 project = chess.Project.open('CHESS_Outputs\My_Project');
 project.sync_runs();                                    % runs in line with the run files on disk
 disp(project.pse_names());
 rows = project.runs('Breakwater', 'Existing');          % one row per storm database and workflow
 disp(arrayfun(@chess.Project.run_label, rows, 'un', false));

 % Step by step, as STEPS 3 and 4 above (the project is not updated: run does that)
 model = project.model('Breakwater', 'Existing', settings);
 [storm, prob_mass] = model.storm_database.read();
 forcing = model.build_forcing(storm, prob_mass);
 responses = model.compute_responses(forcing);
%}

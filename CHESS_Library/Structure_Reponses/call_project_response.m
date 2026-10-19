function [Resp] = call_project_response(config, project_forcing, structure, create_plots)
% CALL_PROJECT_RESPONSE Computes structure response based on a workflow config.

    %% ================= CONFIGURATION & VARIABLE MAPPING =================
    % Modify these variables to change how fields are read from 'config'
    workflow       = config.workflow;
    storm_sampling = config.storm_sampling;
    use_peaks      = config.use_peaks;
    use_timeseries = config.use_timeseries;
    use_whp        = config.create_whp;
    use_wlp        = config.create_wlp;
    
    % Core Output File Target
    save_target    = config.out_files.resp_data;
    % =====================================================================

    % Resolved Offshore Elevation Into The Structure (Full PSE Transect In One Place): config Value After
    % storm_db_info('apply') (Storm DB Study Grid, Else Inputs) And check_offshore_elevation.m. Shared By Library And GUI
    % Runs; Appended To The Run Config File With The Structure. Not A Hotstart Dependency (Responses Are Always Recomputed)
    structure.offshore_elevation = [];
    structure.offshore_elevation_source = '';
    if isfield(config, 'offshore_elevation')
        structure.offshore_elevation = config.offshore_elevation;
    end
    if isfield(config, 'offshore_elevation_source')
        structure.offshore_elevation_source = config.offshore_elevation_source;
    end
    save(config.out_files.config, 'structure', '-append');

    % Load Empirical Coefficients & Initialize Output Struct
    [emp_coeff] = load_empirical_coefficients();
    Resp        = struct();
    
    % Establish Output Directory (Workflow Folder Of The Alternative, chess_paths.m)
    paths  = chess_paths(config);
    subDir = paths.wf_dir;

    %% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
    switch workflow
        
        case {1, 4} % ================= PROS WORKFLOW =================
            % Define workflow parameters
            wName  = ifthen(workflow == 4, 'FB', 'RB');
            ensure_directory(subDir);

            % Process Peaks Datasets (PROS)
            if use_peaks && isfield(project_forcing, 'Peaks')
                disp('Running CHESS: Probabilistic Response Of Structures (PROS) - Peaks....');
                
                peak_fields = fieldnames(project_forcing.Peaks);
                for i = 1:numel(peak_fields)
                    fName = peak_fields{i};
                    
                    % Filter based on water level/height configurations
                    if (strcmp(fName, 'WLP') && ~use_wlp) || (strcmp(fName, 'WHP') && ~use_whp)
                        continue; 
                    end
                    
                    fprintf('   Processing %s dataset....\n', fName);
                    save_path = fullfile(subDir, sprintf('%s1_%s', wName, fName));
                    
                    Resp.Peaks.(fName) = chess_pros(config, ...
                        project_forcing.Peaks.(fName), structure, emp_coeff, save_path);
                end
            end

            % Process Timeseries Datasets (PROS)
            if use_timeseries && isfield(project_forcing, 'Timeseries')
                disp('Running CHESS: Probabilistic Response Of Structures (PROS) - Timeseries....');
                save_path = fullfile(subDir, [wName, '3']);
                
                Resp.Timeseries.Default = chess_pros(config, ...
                    project_forcing.Timeseries.Default, structure, emp_coeff, save_path);
            end
        case 2 % ============== DETERMINISTIC WORKFLOW ==============
            ensure_directory(subDir);

            % Process Peaks Datasets (DET)
            if use_peaks && isfield(project_forcing, 'Peaks')
                disp('Running CHESS: Deterministic - Peaks....');

                peak_fields = fieldnames(project_forcing.Peaks);
                for i = 1:numel(peak_fields)
                    fName = peak_fields{i};

                    % Filter based on water level/height configurations
                    if (strcmp(fName, 'WLP') && ~use_wlp) || (strcmp(fName, 'WHP') && ~use_whp)
                        continue;
                    end

                    fprintf('   Processing %s dataset....\n', fName);
                    Resp.Peaks.(fName) = chess_det(config, ...
                        project_forcing.Peaks.(fName), structure, emp_coeff);
                end
            end

            % Process Timeseries Datasets (DET)
            if use_timeseries && isfield(project_forcing, 'Timeseries')
                disp('Running CHESS: Deterministic - Timeseries....');

                Resp.Timeseries.Default = chess_det(config, ...
                    project_forcing.Timeseries.Default, structure, emp_coeff);
            end
        case 3 % ================== CSR WORKFLOW ==================
            % Define workflow parameters
            ensure_directory(subDir);
            if lcs_sampling_mode(config) == 1
                disp(['Notice: LCS sampling is rate restricted (lcs_restrict_sampling_rate = 1): each life cycle holds lambda x mcs_nYears +/- 1 storms ',...
                    'and no convergence check is run. Life-cycle percentiles are conditional on rate-matched storm counts: they include storm ',...
                    'selection, intensity and timing variability, but not storm-count variability.']);
            end

            % Process Peaks Datasets (CSR)
            if use_peaks && isfield(project_forcing, 'Peaks')
                disp('Running CHESS: Coastal Structure Reliability - Peaks....');
                
                peak_fields = fieldnames(project_forcing.Peaks);
                for i = 1:numel(peak_fields)
                    fName = peak_fields{i};
                    fprintf('   Processing %s dataset....\n', fName);
                    
                    Resp.Peaks.(fName) = chess_csr(config, ...
                        project_forcing.Peaks.(fName), structure, emp_coeff, 'peaks', subDir);
                end
            end

            % Process Timeseries Datasets (CSR)
            if use_timeseries && isfield(project_forcing, 'Timeseries')
                disp('Running CHESS: Coastal Structure Reliability - Timeseries....');
                
                Resp.Timeseries.Default = chess_csr(config, ...
                    project_forcing.Timeseries.Default, structure, emp_coeff, 'timeseries', subDir);
            end
    end

    %% EXPORT OUTPUTS
    disp('Saving project responses....');
    save(save_target, 'Resp', '-v7.3');
end

%% ================= HELPER FUNCTIONS =================
function ensure_directory(dir_path)
    % Verifies and creates directory if it doesn't exist
    if ~exist(dir_path, 'dir')
        mkdir(dir_path);
    end
end

function out = ifthen(cond, true_val, false_val)
    % Fast inline ternary condition
    if cond, out = true_val; else, out = false_val; end
end

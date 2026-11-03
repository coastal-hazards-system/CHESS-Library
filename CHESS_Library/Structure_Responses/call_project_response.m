function [Resp] = call_project_response(config, project_forcing, structure)
% call_project_response  Compute the structure responses of a CHESS run.
%   Resp = call_project_response(config, project_forcing, structure)
%
%   Pipeline step after call_chess_boundary_conditions. Copies the
%   resolved offshore elevation (config offshore_elevation and
%   offshore_elevation_source) into the structure and appends the
%   structure to the run config file, creates the workflow folder of the
%   alternative (chess_paths wf_dir) and runs every dataset of the
%   request:
%     workflows 1 and 4 (PROS-RB, PROS-FB) - chess_pros: hazard curves
%         per storm type;
%     workflow 2 (DET)                     - chess_det: responses per
%         storm, no replicates or uncertainty;
%     workflow 3 (LCS)                     - chess_csr with the empirical
%         coefficients of load_empirical_coefficients: responses per life
%         cycle and, for rubble mounds, reliability (Peaks) or damage
%         progression (Timeseries, csr_call_dpa = 1); prints a notice when
%         the life cycles are rate restricted (lcs_sampling_mode 1).
%   Datasets: every Peaks match type of project_forcing when use_peaks = 1
%   (PROS and DET skip WLP and WHP unless create_wlp / create_whp is 1)
%   and Timeseries Default when use_timeseries = 1. Peaks datasets run
%   with compute_q_vol = 0 (the overtopping volume is Timeseries only).
%   PROS hazard curve figure names (save_name) start with
%   <wf_dir>\<RB or FB>1_<match type> (Peaks) or <wf_dir>\<RB or FB>3
%   (Timeseries).
%
%   Files written:
%     out_files.config    - structure appended (with offshore_elevation
%                           and offshore_elevation_source)
%     out_files.resp_data - Resp (-v7.3)
%
%   Inputs:
%     config          - CHESS configuration (call_input_parser,
%                       call_chs_data_formatter,
%                       call_chess_boundary_conditions), 1x1 struct;
%                       reads workflow (1 PROS-RB, 2 DET, 3 LCS, 4
%                       PROS-FB), use_peaks, use_timeseries, create_wlp,
%                       create_whp (0/1), out_files (config, resp_data),
%                       offshore_elevation and offshore_elevation_source
%                       (when present), plus the fields read by the
%                       workflow functions
%     project_forcing - forcing of the run (call_chess_boundary_conditions),
%                       project_forcing.<data type>.<match type>.<storm
%                       type>, struct; PROS and DET: per-storm forcing
%                       (chess_forcing_formatter, adjust_project_forcing);
%                       LCS: nLC x 1 cell of life-cycle matrices
%                       (lcs_columns)
%     structure       - structure geometry of the run (call_input_parser),
%                       1x1 struct
%   Outputs:
%     Resp - responses, struct: Resp.Peaks.<match type> (Default, WLP,
%            WHP) and Resp.Timeseries.Default, each:
%              PROS - hazard curve entries per storm type (XC, TC, CC),
%                     chess_pros
%              DET  - per storm type: storm_id, h, Rc, the responses
%                     (full histories) and Max, chess_det
%              LCS  - per storm type: the responses per life cycle plus
%                     PF_Summary and Reliab_Summary (Peaks) or S
%                     (Timeseries) for rubble mounds, chess_csr
%
%   Tier: public
%
%   See also call_chess_boundary_conditions, compute_structure_response,
%   call_input_parser, call_chs_data_formatter, chess_paths.

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

    % Initialize Output Struct
    Resp = struct();

    % Overtopping Volume (Q_vol) Is Timeseries Only: Peaks Datasets Run Without It
    config_peaks = config;
    config_peaks.compute_q_vol = 0;
    
    % Establish Output Directory (Workflow Folder Of The Alternative, chess_paths.m)
    paths  = chess_paths(config);
    subDir = paths.wf_dir;

    %% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
    switch workflow
        
        case {1, 2, 4} % ============ PROS AND DETERMINISTIC WORKFLOWS ============
            ensure_directory(subDir);
            if workflow == 2
                run_label = 'Deterministic';
                run_dataset = @(cfg, data, file_name) chess_det(cfg, data, structure);
            else
                run_label = 'Probabilistic Response Of Structures (PROS)';
                run_dataset = @(cfg, data, file_name) chess_pros(cfg, data, structure, fullfile(subDir, file_name));
            end
            % Run File Tag: RB / FB (PROS-RB / PROS-FB, chess_workflows.m); Not Used By DET
            tag = extractAfter(chess_workflows(workflow).wflow_name, 'PROS-');

            % Process Peaks Datasets
            if use_peaks && isfield(project_forcing, 'Peaks')
                disp(['Running CHESS: ' run_label ' - Peaks....']);

                peak_fields = fieldnames(project_forcing.Peaks);
                for i = 1:numel(peak_fields)
                    fName = peak_fields{i};

                    % Filter based on water level/height configurations
                    if (strcmp(fName, 'WLP') && ~use_wlp) || (strcmp(fName, 'WHP') && ~use_whp)
                        continue;
                    end

                    fprintf('   Processing %s dataset....\n', fName);
                    Resp.Peaks.(fName) = run_dataset(config_peaks, ...
                        project_forcing.Peaks.(fName), sprintf('%s1_%s', tag, fName));
                end
            end

            % Process Timeseries Datasets
            if use_timeseries && isfield(project_forcing, 'Timeseries')
                disp(['Running CHESS: ' run_label ' - Timeseries....']);

                Resp.Timeseries.Default = run_dataset(config, ...
                    project_forcing.Timeseries.Default, [tag '3']);
            end
        case 3 % ================== CSR WORKFLOW ==================
            % Define workflow parameters
            ensure_directory(subDir);
            emp_coeff = load_empirical_coefficients(); % Damage Coefficients, Read Only By CSR (chess_csr_peaks, chess_csr_dpa)
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


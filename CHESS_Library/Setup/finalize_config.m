function config = finalize_config(config)
%{
    %% DESCRIPTION
        Applies run-level rules to "config": response restrictions per
        structure type, workflow and response dependencies, defaults,
        confidence limit formatting, response uncertainties and output
        file paths.
        No folder creation, loading of CHS data or user prompts. Safe to
        call more than once (idempotent). Fields already set by the
        caller for response uncertainties are kept.

    %% INPUTS
        config: CHESS configuration. | struc
            Required fields:
                struc_type, workflow, use_peaks, use_timeseries,
                create_wlp, create_whp, project_CLs, outfolder,
                project_name, struc_id, case_name, compute_* switches,
                storm_db (or region and sp_ID when storm_db is empty)

    %% OUTPUTS
        config: Updated CHESS configuration. | struc

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
%% APPLY STRUCTURE TYPE RESPONSES RESTRICTIONS
% Grab Structure Response Switches
switch config.struc_type
    case 1 % Levee
        config.compute_dn50_seaside = 0;
        config.compute_dn50_leeside = 0;
        config.compute_p1 = 0;
        config.compute_p2_p3 = 0;
        config.compute_nappe = 0;
    case 2 % Floodwall
        config.compute_wave_transmission = 0;
        config.compute_dn50_seaside = 0;
        config.compute_dn50_leeside = 0;
        config.compute_r2p = 0;
        % Enforce Dependencies For P2/P3 Computations
        if config.compute_p2_p3 == 1
            config.compute_p1 = 1;
            % Secondary Responses Require Forcing HCs
            config.pros_compute_forcing_HC = 1;
        end
        % Enforce Dependencies For Nappe Discharge Computations
        if config.compute_nappe == 1
            config.compute_q = 1;
            config.pros_compute_forcing_HC = 1;
        end
    case 3 % Rubble Mound
        config.compute_p1 = 0;
        config.compute_p2_p3 = 0;
        config.compute_nappe = 0;
end
% Per-Storm Timeseries Durations From SWL (Forcing Setting, Every Structure Type): Off Unless Requested
if ~isfield(config, 'compute_storm_duration') || isempty(config.compute_storm_duration)
    config.compute_storm_duration = 0;
end

%% WORKFLOW & RESPONSE DEPENDENCIES
% Workflow Restrictions
switch config.workflow
    case 4
        config.pros_compute_forcing_HC = 1;
end
% P2, P3 Are Secondary Responses. Need to process FB
if config.compute_p2_p3 == 1 || config.compute_nappe == 1
    % Ensure P1 Hazard Curve Is Computed
    config.compute_p1 = 1;
    % Ensure Surge & Waves Hazards Are Computed
    config.pros_compute_forcing_HC = 1;
end
% DET Computes Every Response (Incl. P2/P3, Nappe) Straight From The Equations: No Hazard Curves
if config.workflow == 2
    config.pros_compute_forcing_HC = 0;
end
% WLP, WHP Require Peaks & Timeseries Files
if sum([config.use_peaks,config.use_timeseries])~=2
    % Set WLP, WHP To Off
    config.create_wlp = 0;
    config.create_whp = 0;
end
% Overtopping Volume (Q_vol) Integrates Hourly Timeseries Only: Off Without Timeseries Data
if config.use_timeseries ~= 1
    config.compute_q_vol = 0;
end

%% APPEND ADDITIONAL SIMULATION DETAILS TO CONFIG
if ~isfield(config, 'Nyrs_XC')
    config.Nyrs_XC = 0;
end
% Make Sure Confidence Limits Are In The Expected Format
try
    % Split Sring
    dummy = strsplit(config.project_CLs,{' ','[',']'});
    dummy = dummy(2:end-1);
    % Sort CLs
    dummy = sort(cellfun(@str2double, dummy), "ascend");
    % Store Back On Config
    config.project_CLs = ['[',strtrim(sprintf('%d ', dummy)),']'];
catch % In Case Of Unexpected Format , Default To
    config.project_CLs = '[16 84]';
end
% Hidden LCS Sampling Settings: Not In The Input Templates, Parsed Only When Their Row Is Added To The Input File
lcs_defaults = struct('lcs_restrict_sampling_rate', 0, 'lcs_convergence_tol', 0.05,...
    'lcs_convergence_confidence', 0.95, 'lcs_convergence_prompt', 1);
for fn = fieldnames(lcs_defaults)'
    if ~isfield(config, fn{1}) || isempty(config.(fn{1}))
        config.(fn{1}) = lcs_defaults.(fn{1});
    end
end
% LCS Damage Progression Analysis (Rubble Mound Timeseries) Is Off Unless Requested
if ~isfield(config, 'csr_call_dpa') || isempty(config.csr_call_dpa)
    config.csr_call_dpa = 0;
end
% Multi-Line Transect: A Single-Line Run Unless The Caller Couples It To A Stage 1 Run (multiline_stage2_config.m)
if ~isfield(config, 'multiline')
    config.multiline = [];
end
% Deprecated Or Hidden Features
config.chs_wDir_u_a = 0; % Assume Shore Normal Waves
config.tide_std = 0; % Tidal std , not implemented
% This helps toggle print outs
config.print_progress = true;

%% RESPONSES UNCERTAINTIES
u_fields = {'dn50_u','p1_u','q_u','r2p_u'};
if ~all(isfield(config, u_fields))
    uData = readcell('primary_responses_epistemic_uncertainties.txt');
    uData(1, :) = []; % Remove Headers
    uData = cell2struct(uData(:,3), uData(:,1));
    for kk = 1:length(u_fields)
        if ~isfield(config, u_fields{kk})
            config.(u_fields{kk}) = uData.(u_fields{kk});
        end
    end
end

%% OUTPUT FILES
% Alternative Run Files (<db>_<workflow>_*, chess_paths.m)
paths = chess_paths(config);
config.out_files.config = paths.out_files.config;
config.out_files.resp_data = paths.out_files.resp_data;
config.out_files.project_forcing = paths.out_files.project_forcing;
end

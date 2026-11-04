function config = finalize_config(config)
% finalize_config  Apply the run-level rules to config.
%   config = finalize_config(config) applies the run-level rules: response
%   restrictions per structure type, workflow and response dependencies,
%   defaults, confidence limit formatting, response uncertainties and
%   output file paths. No folder creation, CHS data loading or user
%   prompts; idempotent. Response uncertainty fields already set by the
%   caller are kept.
%
%   Rules, in order:
%     - compute switches of responses that do not apply to struc_type are
%       set to 0 (response_registry)
%     - compute_p2_p3 or compute_nappe turns compute_p1 on, compute_nappe
%       turns compute_q on, and both turn pros_compute_forcing_HC on;
%       workflow 4 (PROS-FB) turns pros_compute_forcing_HC on, workflow 2
%       (DET) turns it off
%     - create_wlp and create_whp are 0 unless use_peaks and use_timeseries
%       are both 1; compute_q_vol is 0 without Timeseries data, and
%       compute_q_vol = 1 turns compute_q on
%     - dn50_use_legacy_model and dn50_legacy_submerged_correction: 0
%       when missing or empty, must be 0 or 1 (errors
%       finalize_config:invalidDn50UseLegacyModel,
%       finalize_config:invalidDn50LegacySubmergedCorrection), set to 0
%       unless struc_type is 3 (rubble mound)
%     - defaults when missing: compute_storm_duration 0, Nyrs_XC 0,
%       csr_call_dpa 0, multiline [], lcs_restrict_sampling_rate 0,
%       lcs_convergence_tol 0.05, lcs_convergence_confidence 0.95,
%       lcs_convergence_prompt 1; print_progress is set to true
%     - project_CLs is rewritten sorted as '[a b]' ('[16 84]' when it
%       cannot be read)
%     - dn50_u, p1_u, q_u, r2p_u not set by the caller come from
%       primary_responses_epistemic_uncertainties.txt
%     - out_files.config, out_files.resp_data and out_files.project_forcing
%       come from chess_paths
%
%   Inputs:
%     config - CHESS configuration, 1x1 struct; required fields:
%              struc_type, workflow, use_peaks, use_timeseries, create_wlp,
%              create_whp, compute_q_vol, project_CLs, outfolder,
%              project_name, struc_id, case_name, the compute_* switches,
%              storm_db (or region and sp_ID when storm_db is empty)
%   Outputs:
%     config - configuration with the rules applied, 1x1 struct
%
%   Tier: internal
%
%   See also finalize_structure_config, response_registry, chess_paths,
%   call_input_parser.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% APPLY STRUCTURE TYPE RESPONSES RESTRICTIONS
% Switch Off The Compute Switches Of Responses Not Applicable To The Structure Type (response_registry.m)
switches_off = setdiff(response_registry('output', 'switches'),...
    response_registry('output', 'switches', 'structure_type', config.struc_type), 'stable');
for switch_name = switches_off
    config.(switch_name{1}) = 0;
end
% Enforce Dependencies For P2/P3 Computations (Floodwall Only After The Zeroing)
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
% Per-Storm Timeseries Durations From SWL (Forcing Setting, Every Structure Type): Off Unless Requested
if ~isfield(config, 'compute_storm_duration') || isempty(config.compute_storm_duration)
    config.compute_storm_duration = 0;
end
% Legacy Dn50 Equations (Melby Seaside / Van Gent Leeside) And Their Submerged Correction: Rubble Mound Only, Off Unless Requested
legacy_dn50_fields = {'dn50_use_legacy_model', 'invalidDn50UseLegacyModel';...
    'dn50_legacy_submerged_correction', 'invalidDn50LegacySubmergedCorrection'};
for ff = 1:size(legacy_dn50_fields, 1)
    field_name = legacy_dn50_fields{ff, 1};
    if ~isfield(config, field_name) || isempty(config.(field_name))
        config.(field_name) = 0;
    end
    value = config.(field_name);
    if ~((isnumeric(value) || islogical(value)) && isscalar(value) && ismember(double(value), [0, 1]))
        error(['finalize_config:' legacy_dn50_fields{ff, 2}], '%s must be 0 or 1.', field_name);
    end
    config.(field_name) = double(value);
    if config.struc_type ~= 3
        config.(field_name) = 0;
    end
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
% Overtopping Volume Integrates The Overtopping Discharge: Q_vol Needs q
if config.compute_q_vol == 1
    config.compute_q = 1;
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

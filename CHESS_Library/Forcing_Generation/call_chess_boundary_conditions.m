function [project_forcing, config] = call_chess_boundary_conditions(config, storm, prob_mass, structure, progress_fcn)
% call_chess_boundary_conditions  Build, perturb and adjust the project forcing.
%   [project_forcing, config] = call_chess_boundary_conditions(config, storm,
%       prob_mass, structure)
%   [project_forcing, config] = call_chess_boundary_conditions(...,
%       progress_fcn)
%
%   Pipeline step after call_chs_data_formatter. Builds the project forcing
%   (boundary conditions) of a run: build, uncertainty and adjustments, each
%   a self-contained step with its own workflow switch, and a single save of
%   the complete forcing.
%     Step 0  Cache: a complete cached forcing (forcing_stamp, carried by a
%             'full' hotstart: apply_hotstart_level) that covers the request
%             (project_forcing_cache_hit) is loaded and returned (no
%             rebuild, no save of the forcing). LCS: the sampling mode of the
%             cached life cycles is read from the sampling seed file into
%             lcs_effective_sampling_rate and the config file is updated.
%             Any other cached forcing file is deleted.
%     Step 1  Build (whole request): build_boundary_conditions.
%             Tide start hours shared across datasets
%             (load_reference_tide_indices, draw_tide_indices) are drawn
%             next, before the dataset loop (multi-line stage 2: none).
%     Then one loop over data type x match type x storm type:
%     Step 2  Uncertainty: boundary_conditions_uncertainty.
%     Step 3  Adjustments: boundary_conditions_adjust.
%     Step 4  forcing_stamp, the only save of project_forcing (-v7.3) and
%             the config appended to the config file.
%   Callers must capture both outputs: later stages read the config fields
%   added here (forcing_stamp, tide start hours,
%   lcs_effective_sampling_rate).
%
%   Files written (chess_paths): out_files.project_forcing (project_forcing,
%   -v7.3) and out_files.config (config appended); LCS also writes its
%   sampling seed file (chess_lcs).
%
%   Inputs:
%     config       - CHESS configuration after hotstart resolution
%                    (resolve_hotstart_state or the GUI), 1x1 struct; reads
%                    out_files, workflow, multiline, forcing_stamp,
%                    print_progress and the fields of each step
%     storm        - storm database request (call_chs_data_formatter),
%                    struct
%     prob_mass    - storm probability masses (call_chs_data_formatter),
%                    struct
%     structure    - CHESS structure geometry (call_input_parser), 1x1
%                    struct
%     progress_fcn - progress callback progress_fcn(step, message), step 0
%                    to 4 as above (optional, default: message printed with
%                    disp; [] = default), function_handle
%   Outputs:
%     project_forcing - complete project forcing,
%                       project_forcing.<data type>.<match type>.<storm
%                       type> (Peaks/Timeseries, Default/WLP/WHP,
%                       XC/TC/CC): PROS/DET one struct per dataset
%                       (chess_forcing_formatter fields plus Hm0_toe), LCS
%                       one life-cycle matrix per cell (lcs_columns), struct
%     config          - input config with forcing_stamp, the tide start
%                       hours tide_indx_<type> (random tides),
%                       compute_storm_duration (0 when missing) and, LCS,
%                       lcs_effective_sampling_rate, struct
%
%   Tier: public
%
%   See also call_input_parser, call_chs_data_formatter,
%   call_project_response, chess_setup_path, build_boundary_conditions,
%   boundary_conditions_uncertainty, boundary_conditions_adjust,
%   chess_paths.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if nargin < 5 || isempty(progress_fcn)
    progress_fcn = @(~, message) disp(message);
end
existing_file = config.out_files.project_forcing;
is_stage2 = isfield(config, 'multiline') && ~isempty(config.multiline);

%% STEP 0: CACHED COMPLETE PROJECT FORCING
if exist(existing_file, 'file') == 2
    if isfield(config, 'forcing_stamp')
        % Load Project Forcing And Check If Existing Data Complies With Request (Shared With The GUI)
        [covers, project_forcing, missing_desc] = project_forcing_cache_hit(config);
        if covers
            progress_fcn(0, ['Successfully loaded the complete cached project forcing: ' existing_file]);
            % LCS: Mode The Cached Life Cycles Were Sampled With (Sampling Seed File, Written By chess_lcs)
            if config.workflow == 3
                seed_file = lcs_sampling_seed_file(existing_file);
                if isfile(seed_file)
                    S = load(seed_file, 'lcs_restrict_sampling_rate');
                    config.lcs_effective_sampling_rate = S.lcs_restrict_sampling_rate;
                    % Saved Config Carries It Too (Plots Read The Saved Config)
                    save(config.out_files.config, 'config', '-append');
                end
            end
            return
        end
        disp_toggle(config.print_progress, sprintf('Hotstart: cached project forcing does not cover requested permutation (missing: %s) -- deleting, will be regenerated....', missing_desc));
    else
        disp_toggle(config.print_progress, 'Hotstart: cached project forcing is not from a completed run -- deleting, will be regenerated....');
    end
    delete(existing_file);
end

%% STEP 1: BUILD
if is_stage2
    progress_fcn(1, ['Multi-line stage 2: transmitting the waves of stage 1 (' config.multiline.stage1_alt ')....']);
else
    progress_fcn(1, 'Preping project forcing data....');
end
[project_forcing, config] = build_boundary_conditions(config, storm, prob_mass);

%% STEP 3 SET-UP: TIDE START HOURS SHARED ACROSS DATASETS
if ~is_stage2
    % LCS Reference Case: Reuse Its Tide Start Hours Too (Same Storms -> Same Tides Across Alternatives)
    config = load_reference_tide_indices(config, project_forcing);
    % Storm Types With Timeseries: One Tide Start Hour Per Storm, Shared By Peaks And Timeseries.
    % LCS CC: TC/XC Start Hours First, CC Derived From Them (Same Storm -> Same Tide), All Before Any Dataset
    config = draw_tide_indices(config, project_forcing);
end

%% STEPS 2-3: UNCERTAINTY AND ADJUSTMENTS PER DATASET
data_types = fieldnames(project_forcing);
for dt = 1:length(data_types) % Peaks, Timeseries
    match_types = fieldnames(project_forcing.(data_types{dt}));
    for mt = 1:length(match_types) % Default, WLP, WHP
        storm_types = fieldnames(project_forcing.(data_types{dt}).(match_types{mt}));
        for st = 1:length(storm_types) % XC, TC, CC
            ds_str = [data_types{dt} ' ' match_types{mt} ' ' storm_types{st}];
            data = project_forcing.(data_types{dt}).(match_types{mt}).(storm_types{st});
            progress_fcn(2, ['Uncertainty step: ' ds_str '....']);
            data = boundary_conditions_uncertainty(config, data, storm_types{st});
            progress_fcn(3, ['Adjustment step: ' ds_str '....']);
            [data, config] = boundary_conditions_adjust(config, structure, data, storm_types{st});
            project_forcing.(data_types{dt}).(match_types{mt}).(storm_types{st}) = data;
        end
    end
end

%% STEP 4: STAMP AND SAVE
% Forcing Build Stamp: Marks The Forcing On Disk As Complete (Step 0); A Multi-Line Stage 2 Run Records It
% (multiline_stage2_config.m), So A Rebuilt Stage 1 Forcing Marks Stage 2 Inputs As Changed
config.forcing_stamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
progress_fcn(4, 'Saving project forcing....');
save(existing_file, 'project_forcing', '-v7.3');
save(config.out_files.config, 'config', '-append');
end

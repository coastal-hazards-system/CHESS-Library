function HC_out = chess_pros(config, project_forcing, structure, outPath)
% chess_pros  PROS hazard curves of one dataset.
%   HC_out = chess_pros(config, project_forcing, structure, outPath)
%
%   CHESS: PROS, workflows 1 (PROS-RB) and 4 (PROS-FB). For every sampled
%   storm type (XC for XC and CC sampling, TC for TC and CC):
%     1. responses per storm: maxima of the responses fitted by PROS-RB
%        (compute_structure_response, get_max = 1);
%     2. with pros_compute_forcing_HC = 1, the per-storm values of the
%        forcing curves (pros_forcing_curves), built from the z = 0
%        replicate only (no forcing uncertainty; tides, swl_slr and the
%        Hm0 floor included; the hydraulic replicates are not used):
%        XC, one column: the SWL and Hm0_offshore peaks, the Tp at the
%        Hm0_offshore peak and the peak of the z = 0 Hm0_toe series.
%        TC, storms x 445 (z = 0 in the middle column; registry rows with
%        partition_uncertainty): the replicates of the first uncertainty
%        partition (partitioned_replicates, one z-score per
%        column shared by SWL, Hm0_offshore and Tp; SWL on the surge, mean
%        lake level removed and added back) of the XC values; Hm0_toe =
%        the z = 0 SWL, Hm0_offshore and Tp series partitioned, the toe
%        wave height of each replicate (adjust_project_forcing without
%        tides and swl_slr: depth limitation, toe rule), then the per-storm
%        peak (no Hm0 floor). A storm whose z = 0 value is NaN, Inf or <= 0
%        (SWL: surge) gets NaN replicates (z = 0 column kept), as JPM
%        integration method 2 drops such storms;
%     3. hazard curves (call_hazard_curve_builder; TC with TC_Prob, the
%        TC forcing curves fitted with the uncertainty left after the
%        partition).
%   CC sampling combines the TC and XC curves (call_hazard_curve_combiner).
%   tbl_rsp_x and tbl_rsp_y are removed from the XC and TC entries.
%   The secondary responses (response_registry pros_secondary_eb1: P2/P3
%   and nappe) are left out of the RB fits and computed by
%   chess_pros_frequency_base (EB1) when requested.
%   PROS-FB (workflow 4) forces pros_compute_forcing_HC = 1 and
%   compute_q_vol = 0, fits only the forcing curves and computes every
%   requested response with chess_pros_frequency_base (EB2).
%
%   Inputs:
%     config          - CHESS configuration, 1x1 struct; reads workflow,
%                       storm_sampling, pros_use_aep (0/1),
%                       pros_compute_forcing_HC (0/1), the response_registry
%                       compute switches and the fields read by the
%                       functions above
%     project_forcing - one PROS dataset, struct with fields XC and/or TC:
%                       per-storm forcing with replicates (SWL,
%                       Hm0_offshore, Hm0_toe, Tp, storm_duration, dt for
%                       Timeseries; TC also TC_Prob), chess_forcing_formatter
%                       and adjust_project_forcing
%     structure       - structure geometry, 1x1 struct
%     outPath         - folder and prefix of the hazard curve figure names
%                       (save_name of each entry; nothing is written), char
%   Outputs:
%     HC_out - hazard curves, struct with fields XC, TC and CC (as
%              sampled), each a struct array of hazard curve entries
%              (set_hazard_curve_entry: var, CL, x_plot, y_plot, x_table,
%              y_table, ...), frequency-based entries appended
%
%   Tier: internal
%
%   See also call_project_response, compute_structure_response,
%   call_hazard_curve_builder, call_hazard_curve_combiner,
%   chess_pros_frequency_base, pros_forcing_curves, partitioned_replicates,
%   adjust_project_forcing.

%% INITIALIZE FIELDS AND PROMT USER
% Get AEP vs AEF Flag
use_aep = config.pros_use_aep;
% Display PROS Message
disp(['      Running CHESS: PROS....']);
% Get Secondary Responses Switch
varnames = response_registry('output', 'switches', 'pros_secondary_eb1', true);
% Get Responses To Compute Usign PROS-FB
fb_responses = cellfun(@(x) config.(x), varnames, 'un', true);
% Turn Off Responses For RB Section
config = config_editor(config, varnames, 0);
% PROS-FB For All Responses
if config.workflow == 4 % PROS-FB
    % Force Forcing Hazard Curve Creation
    config.pros_compute_forcing_HC = 1;
    % Force Overtopping Dischar Volume To Off
    config.compute_q_vol = 0; % Can't Integrate q Hazard Curve
    % Get Responses To Compute
    varnames = response_registry('output', 'switches');
    % Get Responses To Compute Usign PROS-FB
    fb_responses = cellfun(@(x) config.(x), varnames, 'un', true);
    varnames = varnames(logical(fb_responses));
    % Turn Off Responses For RB Section
    config = config_editor(config, varnames, 0);
end

%% CHESS: PROS - XC
if contains(config.storm_sampling, {'XC','CC'})
    % 1. Compute Structure Responses
    [Resp] = compute_structure_response(config, structure, project_forcing.('XC'), 1);
    % 1.1 Add Forcing Hazard Curve Inputs (pros_forcing_curves.m)
    Resp = add_forcing(config, structure, project_forcing.('XC'), 'XC', Resp);
    % 2. Compute Extremal Distribution Curves
    HC_out.XC = call_hazard_curve_builder(config, [], Resp, 'XC', use_aep, outPath);
end

%% CHESS: PROS - TC
if contains(config.storm_sampling, {'TC','CC'})
    % 1. Compute Structure Responses
    [Resp] = compute_structure_response(config, structure, project_forcing.('TC'), 1);
    % 1.1 Add Forcing Hazard Curve Inputs (pros_forcing_curves.m)
    Resp = add_forcing(config, structure, project_forcing.('TC'), 'TC', Resp);
    % 2. Compute Extremal Distribution Curves
    HC_out.TC = call_hazard_curve_builder(config, project_forcing.TC.TC_Prob, Resp, 'TC', use_aep, outPath);
end

%% CHESS: PROS - COMBINE HAZARDS
if contains(config.storm_sampling, {'CC'})
    if isfield(HC_out, 'TC') & isfield(HC_out, 'XC')
        if ~isempty(HC_out.('TC')) & ~isempty(HC_out.('XC'))
            disp('         Combining project primary responses hazard curves...');
            [HC_out.('CC')] = call_hazard_curve_combiner(config, HC_out.('TC'), HC_out.('XC'), use_aep);
        end
    end
end

%% REMOVE UNWANTED FIELDS FROM OUTPUT VAR
if isfield(HC_out, 'XC')
    HC_out.XC = rmfield(HC_out.XC, {'tbl_rsp_x','tbl_rsp_y'});
end
if isfield(HC_out, 'TC')
    HC_out.TC = rmfield(HC_out.TC, {'tbl_rsp_x','tbl_rsp_y'});
end

%% COMPUTE SECONDARY RESPONSES
% Compute Secondary Response Hazard Curves Using PROS-FB
if any(fb_responses) || config.workflow == 4
    %
    disp('         Computing Frequency Base Responses Hazard Curves...');
    % Turn On Responses For FB Section
    config = config_editor(config, varnames, 1);
    % Run CHESS PROS-FB
    HC_out = chess_pros_frequency_base(config, structure, HC_out, outPath, config.workflow);
end

%% AUX FUNCTION
    function config_out = config_editor(config_out, var_to_look, value)
        % Turn Off Responses For RB Section
        for ii = 1:length(var_to_look)
            config_out.(var_to_look{ii}) = value;
        end
    end
end

function Resp = add_forcing(config, structure, forcing, storm_type, Resp)
% Forcing Hazard Curve Inputs (pros_forcing_curves) Added To The Responses Of One Storm Type
if config.pros_compute_forcing_HC == 1
    curves = forcing_curve_values(config, structure, forcing, storm_type);
    for name = fieldnames(curves)'
        Resp.(name{1}) = curves.(name{1});
    end
end
end

function curves = forcing_curve_values(config, structure, forcing, storm_type)
% Per-Storm Forcing Curve Values Of One Dataset From Its z = 0 Replicate (See The Header, Step 2)
z0_of = @(name) cellfun(@(x) x(:, replicate_z0_col(size(x, 2))), forcing.(name)(:), 'un', false);
SWL = z0_of('SWL');
Hm0_off = z0_of('Hm0_offshore');
Tp = z0_of('Tp');
curves.SWL = cellfun(@(x) max(x, [], 1), SWL);
[curves.Hm0_offshore, peak_row] = cellfun(@(x) max(x, [], 1), Hm0_off);
curves.Tp = cellfun(@(x, row) x(row), Tp, num2cell(peak_row));
switch storm_type
    case 'XC'
        curves.Hm0_toe = cellfun(@(x) max(x, [], 1), z0_of('Hm0_toe'));
    case 'TC'
        z_scores = discrete_standard_normal_scores('TC')';
        lake_level = mean_lake_level(config);
        partition = @(values) partitioned_replicates(values, z_scores);
        surge = curves.SWL - lake_level;
        curves.SWL = keep_fittable_storms(partition(surge), surge, z_scores) + lake_level;
        curves.Hm0_offshore = keep_fittable_storms(partition(curves.Hm0_offshore), curves.Hm0_offshore, z_scores);
        curves.Tp = keep_fittable_storms(partition(curves.Tp), curves.Tp, z_scores);
        % The z = 0 SWL Already Holds The Tides And swl_slr: Only The Toe Wave Height Step Of adjust_project_forcing Is Wanted
        replicates = struct('SWL', {cellfun(@(x) partition(x - lake_level) + lake_level, SWL, 'un', false)},...
            'Hm0_offshore', {cellfun(partition, Hm0_off, 'un', false)}, 'Tp', {cellfun(partition, Tp, 'un', false)});
        config_toe = config;
        config_toe.apply_random_tides = 0;
        config_toe.swl_slr = 0;
        replicates = adjust_project_forcing(config_toe, structure, replicates, storm_type);
        Hm0_toe = cell2mat(cellfun(@(x) max(x, [], 1), replicates.Hm0_toe, 'un', false));
        curves.Hm0_toe = keep_fittable_storms(Hm0_toe, Hm0_toe(:, z_scores == 0), z_scores);
end
end

function replicates = keep_fittable_storms(replicates, z0_values, z_scores)
% JPM Integration Method 2 Drops A Storm Whose z = 0 Value Is NaN, Inf Or <= 0 Before Replicating: Same Here (z = 0 Column Kept For The Overlays)
replicates(~(isfinite(z0_values) & z0_values > 0), z_scores ~= 0) = NaN;
end
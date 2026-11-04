function [Resp] = compute_structure_response(config, structure, project_forcing, get_max)
% compute_structure_response  Structure responses of one dataset's forcing.
%   Resp = compute_structure_response(config, structure, project_forcing,
%       get_max)
%
%   Computes every response whose response_registry compute switch is on
%   in config and that applies to the structure type (switches of other
%   structure types are set to 0). compute_p2_p3 turns compute_p1 on;
%   compute_nappe and compute_q_vol turn compute_q on.
%     Levee and rubble mound: R2p, R2p_SWL, q, q_wave_ot
%       (Eurotop_r2p_q_Final; with compute_r2p, compute_q or
%       compute_q_vol); rubble mound Dn50 and Dn50_Lee
%       (ann_rubblemound_stability; with dn50_use_legacy_model = 1
%       melby_Dn50_seaside_stability and van_gent_Dn50_leeside_stability,
%       empirical coefficients from load_empirical_coefficients, and with
%       dn50_legacy_submerged_correction = 1 also
%       submerged_stone_armor_stability; number of waves from
%       storm_duration, never dt).
%     Floodwall: q, q_wave_ot (Eurotop_r2p_q_Final); p1
%       (goda_forces_on_vertical_p1); p2dyn, p2sta, p2total, p3dyn,
%       p3sta, p3total, pu (goda_forces_on_vertical_p2p3; NaN where p1 is
%       NaN); X_low, theta_low, X_up, theta_up, Bx, X_c_surge,
%       theta_center, Bjet, Vjet, Fjet (floodwall_nappe_response; NaN
%       where q is NaN).
%     Every type: Hm0t (Hm0_toe times the eurotop_wave_transmission Kt;
%       PROS-RB uses the z = 0 replicate Hm0_toe with the Kt of every
%       replicate); DamDepthElev, DamDepth (damaging_depth; offshore
%       elevation from structure.offshore_elevation, else
%       config.offshore_elevation); Q_vol, Q_vol_wave_ot (Timeseries only:
%       running sum of q.*dt over each storm [m^3/m], a storm's total is
%       its last value; off for Peaks).
%   Hm0_toe drives every toe response, Hm0_offshore the Goda pressures and
%   the damaging depth. Influence factors come from call_eurotop_ifactors.
%   Periods: Tm = Tp/1.2, T_m-1,0 = Tp/1.1, Ts = Tp. Depths: h = SWL - toe
%   elevation (floodwall without a toe berm: wall bottom elevation), hb =
%   SWL - berm crest elevation (toe elevation without a toe berm), Rc =
%   crest elevation - SWL; elevations are signed.
%   Errors: compute_structure_response:unsupportedStructureType,
%   compute_structure_response:unsupportedWorkflow (Hm0t).
%
%   Inputs:
%     config          - CHESS configuration, 1x1 struct; reads struc_type
%                       (1 levee, 2 floodwall, 3 rubble mound), workflow
%                       (1 PROS-RB, 2 DET, 3 LCS, 4 PROS-FB),
%                       gravity_constant [m/s^2], water_density [kg/m^3],
%                       add_toe_berm, every response_registry compute
%                       switch, compute_damaging_depth_Ks, when the
%                       structure has none, offshore_elevation and
%                       (rubble mound, 0 when missing)
%                       dn50_use_legacy_model,
%                       dn50_legacy_submerged_correction
%     structure       - structure geometry, 1x1 struct; reads
%                       crest_elevation, crest_width, toe_elevation,
%                       offshore_slope, roughness_ifactor, berm_* (toe
%                       berm), seaside_slope and leeside_slope (types 1,
%                       3), armor_delta, seaside_design_S,
%                       leeside_design_S, cem_P (type 3),
%                       wall_bottom_elevation (type 2), offshore_elevation
%                       (optional); elevations [m, study datum, positive
%                       up]
%     project_forcing - forcing of one dataset and storm type:
%                       workflows 1, 2, 4: struct with SWL, Hm0_toe,
%                       Hm0_offshore, Tp, storm_duration [days] and,
%                       Timeseries only, dt [days], each nStorms x 1 cell
%                       of nSteps x n_replicates (chess_forcing_formatter,
%                       adjust_project_forcing);
%                       workflow 3: life cycles, nLC x 1 cell of Peaks
%                       (10 columns) or Timeseries (12 columns) matrices
%                       (lcs_columns)
%     get_max         - 1 = keep only the responses fitted by PROS-RB
%                       (response_registry fitted_by_pros_rb) and take
%                       their maximum over each storm (workflows 1, 2, 4;
%                       no effect for workflow 3); 0 = full histories
%   Outputs:
%     Resp - responses, struct with one field per computed response
%            (units in response_registry), each a cell the size of the
%            forcing cell array holding arrays the size of the forcing;
%            with get_max = 1 each field is a double with one row per
%            storm; [] when no response is requested
%
%   Tier: internal
%
%   See also call_project_response, response_registry,
%   call_eurotop_ifactors, Eurotop_r2p_q_Final, ann_rubblemound_stability,
%   melby_Dn50_seaside_stability, van_gent_Dn50_leeside_stability,
%   submerged_stone_armor_stability, damaging_depth, lcs_columns.

%% GRAB DETAILS FROM "config"
% Strucutre Type
struc_type = config.struc_type;
% Define Requested Workflow
workflow = config.workflow;
% Gravity
g = config.gravity_constant;
% Water Density kg/m^3
rho_w = config.water_density;
% Structure Response Switches
response_switch = resolve_response_switches(config);

%% GRAB DETAILS FROM "structure"
geometry = structure_fields_for_responses(config, structure);

%% GET FORCING FIELDS
[forcing, response_switch] = unpack_forcing(project_forcing, workflow, geometry, response_switch);
% Any Primary (Non-Secondary) Structure Response Requested
primary_switches = response_registry('output', 'switches', 'kind', 'response', 'pros_secondary_eb1', false);
any_primary_response = any(cellfun(@(name) response_switch.(name), primary_switches) ~= 0);

%% COMPUTE STRUCTURE RESPONSE
if any_primary_response
    % Call Eurotop Influence Factors
    gammas = cellfun(@(x,y) call_eurotop_ifactors(config, structure, x, y),forcing.SWL,forcing.Hm0,'un',false);
    % Compute Structure Type Dependant Responses
    switch struc_type
        case 2 % Floodwall
            type_responses = floodwall_responses(response_switch, forcing, gammas, geometry, rho_w, g, struc_type);
        case {1,3} % Levees & Rubblemound
            type_responses = embankment_responses(response_switch, forcing, gammas, geometry, g, struc_type, legacy_dn50_settings(config));
        otherwise
            error('compute_structure_response:unsupportedStructureType', 'Unsupported structure type %d (1 = Levee, 2 = Floodwall, 3 = Rubblemound).', struc_type);
    end
    % Resp Is Created By Its First Response Field (Left Unassigned When None Is Computed)
    for name = fieldnames(type_responses)'
        Resp.(name{1}) = type_responses.(name{1});
    end
    if response_switch.compute_wave_transmission == 1
        Resp.Hm0t = transmitted_wave_height(forcing, geometry, workflow, struc_type, g);
    end
    % Damaging Depth Response: Offshore Elevation From The Structure (Copied At Run Time By call_project_response.m;
    % Storm DB Study Grid, Else Inputs, Checked By check_offshore_elevation.m), Else From config (Structures Built Outside
    % A Run, e.g. Plots Of A Loaded Result)
    if response_switch.compute_damaging_depth == 1
        [Resp.DamDepthElev, Resp.DamDepth] = damaging_depth_responses(config, structure, forcing, geometry, g);
    end
    % Compute Overtopping Volume
    % Timeseries Only, Progressive Per Storm [m^3/m] (Running Sum Of q.*dt, dt From The Forcing), A Storm's Total Is Its Last Value
    if response_switch.compute_q_vol == 1 && isfield(Resp, 'q') && isfield(Resp, 'q_wave_ot')
        [Resp.Q_vol, Resp.Q_vol_wave_ot] = overtopping_volumes(Resp.q, Resp.q_wave_ot, forcing.dt, forcing.q_step);
    end
else % No Responses Computed
    Resp = [];
end

%% FLATTEN DATA & STORE RESPONSES
if get_max == 1
    Resp = per_storm_peak_responses(Resp, response_switch, workflow);
end
end

%% AUX FUNCTION: STRUCTURE RESPONSE SWITCHES FROM "config" (REGISTRY SWITCHES, STRUCTURE TYPE FILTER, DEPENDENCIES)
function response_switch = resolve_response_switches(config)
% Grab Structure Response Switches (Registry Compute Switches; compute_q_vol Is 0 For Peaks Calls And FB)
response_switch = struct();
for switch_name = response_registry('output', 'switches')
    response_switch.(switch_name{1}) = config.(switch_name{1});
end
% Remove Responses Not Applicable To The Structure Type
switches_off = setdiff(response_registry('output', 'switches'),...
    response_registry('output', 'switches', 'structure_type', config.struc_type), 'stable');
for switch_name = switches_off
    response_switch.(switch_name{1}) = 0;
end
% Dependencies: P2/P3 Need P1 (Floodwall); Nappe And Overtopping Volume Need q
if response_switch.compute_p2_p3 == 1
    response_switch.compute_p1 = 1;
end
% compute_q_vol turns compute_q on for the run (finalize_config applies the same rule), even on calls
% where unpack_forcing later switches Q_vol off (Peaks)
if response_switch.compute_nappe == 1 || response_switch.compute_q_vol == 1
    response_switch.compute_q = 1;
end
end

%% AUX FUNCTION: STRUCTURE GEOMETRY FROM "structure" (ELEVATIONS SIGNED, <0 BELOW DATUM ZERO)
function geometry = structure_fields_for_responses(config, structure)
% Define Structure Crest Elevation
crest_elev = structure.crest_elevation;
% Define Structure Crest Width
crest_width = structure.crest_width;
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation;
if config.add_toe_berm
    % Berm Elevation (<0 Below Datum Zero)
    berm_elev = structure.berm_crest_elevation;
    % Berm Width
    berm_width = structure.berm_crest_width;
    % Berm Slope
    berm_slope_tana = 1./structure.berm_seaward_slope;
else
    % Berm Elevation (<0 Below Datum Zero)
    berm_elev = toe_elev; % This Translates to h == hb
    % Berm Width
    berm_width = 0;
    % Berm Slope
    berm_slope_tana= 1;% Can't set to 0, Will cause 1/0 in Goda Pressure Calcs
end
offshore_slope_tana = 1./structure.offshore_slope;
% Rubblemound Fields
switch config.struc_type
    case 3
        % Delta
        geometry.armor_delta = structure.armor_delta;
        % Seaside Limit State
        geometry.seaside_design_S = structure.seaside_design_S;
        geometry.leeside_design_S = structure.leeside_design_S;
        % CEM P
        cem_P = structure.cem_P;
    case  2
        wall_bottom_elev = structure.wall_bottom_elevation;
        hw = crest_elev - wall_bottom_elev;
        % Toe: Berm Toe When A Toe Berm Is Included (Same Rule As adjust_project_forcing), Else The Wall Bottom
        if ~config.add_toe_berm
            toe_elev = wall_bottom_elev;
        end
        geometry.wall_bottom_elev = wall_bottom_elev;
        geometry.wall_height = hw;
        cem_P = 0;
    case 1
        cem_P = 0;
end
% Get Slopes
if ismember(config.struc_type, [1, 3])
    % Seaside Slope (cot(alpha))
    geometry.mound_seaside_slope_cota = structure.seaside_slope;
    % Leeside Slope
    geometry.mound_leeside_slope_cota = structure.leeside_slope;
end
geometry.crest_elev = crest_elev;
geometry.crest_width = crest_width;
geometry.toe_elev = toe_elev;
geometry.berm_elev = berm_elev;
geometry.berm_width = berm_width;
geometry.berm_slope_tana = berm_slope_tana;
geometry.offshore_slope_tana = offshore_slope_tana;
geometry.cem_P = cem_P;
end

%% AUX FUNCTION: FORCING FIELDS PER WORKFLOW (PROS/DET DATASETS OR LCS LIFE CYCLES), DEPTHS AND PERIODS
function [forcing, response_switch] = unpack_forcing(project_forcing, workflow, geometry, response_switch)
toe_elev = geometry.toe_elev;
crest_elev = geometry.crest_elev;
% Hm0 (Toe): Depth Limited At The Toe, Used By Every Toe Response. Hm0_off (Offshore): Before Depth Limitation, Used By
% The Goda Pressures And The Damaging Depth
switch workflow
    case {1,2,4} % RB, DET
        % Create Forcing Variables For Simplicity
        SWL = project_forcing.SWL; % SWL
        Hm0 = project_forcing.Hm0_toe; % Hm0 At The Toe
        Hm0_off = project_forcing.Hm0_offshore; % Hm0 Offshore
        Tp = project_forcing.Tp; % Tp
        h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
        Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
        storm_dur = cellfun(@(x) x*24*3600, project_forcing.storm_duration, 'un', false); % Event Length [days -> s]
        % Row Time Step [days -> s]: Timeseries Only (Peaks Have No dt, So No Overtopping Volume)
        if isfield(project_forcing, 'dt')
            dt = cellfun(@(x) x*24*3600, project_forcing.dt, 'un', false);
        else
            dt = [];
            response_switch.compute_q_vol = 0;
        end
        q_step = cell(size(SWL));
    case 3 % LCS
        C = lcs_columns();
        SWL = cellfun(@(x) x(:, C.SWL),project_forcing,'un',false); % SWL
        Hm0 = cellfun(@(x) x(:, C.Hm0_toe),project_forcing,'un',false); % Hm0 At The Toe
        Hm0_off = cellfun(@(x) x(:, C.Hm0_offshore),project_forcing,'un',false); % Hm0 Offshore
        Tp = cellfun(@(x) x(:, C.Tp),project_forcing,'un',false); % Tp
        h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
        Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
        % Timeseries Life Cycles (Storms Start At step == 0); Peaks Life Cycles Have One Row Per Storm
        is_ts = cellfun(@(x) size(x, 2) == C.n_timeseries, project_forcing);
        % Event Length [days -> s]: Last Column Of Either Layout (Peaks 10, Timeseries 12)
        sd_col = [C.storm_duration, lcs_columns('Timeseries').storm_duration];
        storm_dur = cellfun(@(x, a) x(:, sd_col(1 + a))*24*3600, project_forcing, num2cell(is_ts), 'un', false);
        % Row Time Step [days -> s] And Storm Step: Timeseries Life Cycles Only (Empty For Peaks)
        dt = cellfun(@(x, a) ts_column(x, C.dt, a)*24*3600, project_forcing, num2cell(is_ts), 'un', false);
        q_step = cellfun(@(x, a) ts_column(x, C.step, a), project_forcing, num2cell(is_ts), 'un', false);
        % Overtopping Volume Is Timeseries Only, Even If The Switch Arrives On For Peaks Life Cycles
        if ~any(is_ts)
            response_switch.compute_q_vol = 0;
        end
end
forcing.SWL = SWL;
forcing.Hm0 = Hm0;
forcing.Hm0_off = Hm0_off;
forcing.Tp = Tp;
forcing.h = h;
forcing.Rc = Rc;
forcing.storm_dur = storm_dur;
forcing.dt = dt;
forcing.q_step = q_step;
% Compute Water Depth @ Berm
forcing.hb = cellfun(@(x) x - geometry.berm_elev, SWL,'un',false);
% Compute Mean Period
forcing.Tm = cellfun(@(x) x./1.2,Tp,'un',false); %
% Compute Zeroth Moment Spectral Wave Period
forcing.Tm10 = cellfun(@(x) x./1.1,Tp,'un',false); %
% Compute Ts
forcing.Ts = Tp; % Assuming narrow spectrat Ts~Tp
end

%% AUX FUNCTION: FLOODWALL RESPONSES (OVERTOPPING, GODA WALL PRESSURES, NAPPE)
function Resp = floodwall_responses(response_switch, forcing, gammas, geometry, rho_w, g, struc_type)
SWL = forcing.SWL; Hm0 = forcing.Hm0; Hm0_off = forcing.Hm0_off; Tm10 = forcing.Tm10; Ts = forcing.Ts;
h = forcing.h; hb = forcing.hb; Rc = forcing.Rc;
crest_elev = geometry.crest_elev; wall_bottom_elev = geometry.wall_bottom_elev; hw = geometry.wall_height; cem_P = geometry.cem_P;
berm_width = geometry.berm_width; berm_slope_tana = geometry.berm_slope_tana; offshore_slope_tana = geometry.offshore_slope_tana;
Resp = struct();
% Reformat Slope If Needed
slope_aux = cellfun(@(y) zeros(size(y)), SWL, 'un', false);
% Compute runup & Overtopping
if response_switch.compute_q == 1 || response_switch.compute_nappe == 1
    [~,~, Resp.q, ~, Resp.q_wave_ot]=cellfun(@(a, b, c, d, e, f) Eurotop_r2p_q_Final(a, b, c, d,...
        f, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
        wall_bottom_elev, cem_P, g, struc_type),...
        Hm0, Tm10, SWL, Rc, gammas, slope_aux,'un',false);
end
% Compute Wall Pressures
if response_switch.compute_p1 == 1 || response_switch.compute_p2_p3 == 1
    % P1
    Resp.p1 = cellfun(@(a, b, c, d) goda_forces_on_vertical_p1(a, b, 1.8,...
        0, c, d, berm_width, rho_w, g, offshore_slope_tana, berm_slope_tana), Hm0_off, Ts, h, hb, 'un', false);
end
%
if response_switch.compute_p2_p3 == 1
    % Compute P2 & P3 Wall Pressures (Plots)
    [Resp.p2dyn, Resp.p2sta, Resp.p2total,...
        Resp.p3dyn, Resp.p3sta, Resp.p3total, Resp.pu] = cellfun(@(a, b, c, d, e, f) goda_forces_on_vertical_p2p3(a, b, 1.8,...
        0, c, d, e, hw, f, rho_w, g), Hm0_off, Ts, h, hb, Rc, Resp.p1, 'un', false);
    % No Wave Attack (P1 NaN, e.g. Dry Toe): Secondary Pressures Are Undefined, Not Zero
    p_names = response_registry('output', 'names', 'compute_switch', 'compute_p2_p3');
    for pp = 1:length(p_names)
        Resp.(p_names{pp}) = cellfun(@nan_where, Resp.(p_names{pp}), Resp.p1, 'un', false);
    end
end
%
if response_switch.compute_nappe == 1
    [Resp.X_low, Resp.theta_low, Resp.X_up,...
        Resp.theta_up, Resp.Bx, Resp.X_c_surge,...
        Resp.theta_center, Resp.Bjet, Resp.Vjet,...
        Resp.Fjet] = cellfun(@(a, b, c) floodwall_nappe_response(a, b,...
        c, hw, rho_w, crest_elev), SWL, Hm0, Resp.q, 'un', false);
    % No Overtopping Estimate (q NaN, e.g. Dry Toe): Nappe Is Undefined
    n_names = response_registry('output', 'names', 'compute_switch', 'compute_nappe');
    for nn = 1:length(n_names)
        Resp.(n_names{nn}) = cellfun(@nan_where, Resp.(n_names{nn}), Resp.q, 'un', false);
    end
end
end

%% AUX FUNCTION: LEVEE & RUBBLEMOUND RESPONSES (EUROTOP RUNUP/OVERTOPPING, RUBBLEMOUND STONE SIZE ANN OR LEGACY EQUATIONS)
function Resp = embankment_responses(response_switch, forcing, gammas, geometry, g, struc_type, legacy_dn50)
SWL = forcing.SWL; Hm0 = forcing.Hm0; Tm = forcing.Tm; Tm10 = forcing.Tm10;
h = forcing.h; Rc = forcing.Rc; storm_dur = forcing.storm_dur;
crest_elev = geometry.crest_elev; crest_width = geometry.crest_width; toe_elev = geometry.toe_elev; cem_P = geometry.cem_P;
offshore_slope_tana = geometry.offshore_slope_tana;
mound_seaside_slope_cota = geometry.mound_seaside_slope_cota;
mound_leeside_slope_cota = geometry.mound_leeside_slope_cota;
Resp = struct();
% Reformat Slope If Needed
slope_aux = cellfun(@(y) repmat(mound_seaside_slope_cota, size(y)), SWL, 'un', false);
% Compute runup & Overtopping
if response_switch.compute_r2p == 1 || response_switch.compute_q == 1 || response_switch.compute_q_vol == 1
    [Resp.R2p, Resp.R2p_SWL, Resp.q, ~, Resp.q_wave_ot]=cellfun(@(a, b, c, d, e,f) Eurotop_r2p_q_Final(a, b, c, d,...
        f, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
        toe_elev, cem_P, g, struc_type),...
        Hm0, Tm10, SWL, Rc, gammas, slope_aux,'un',false);
end
% Rubblemound Stone Size (Seaside & Leeside Component Stability ANN, ann_rubblemound_stability.m, Or The Legacy Equations)
if struc_type == 3 && (response_switch.compute_dn50_seaside == 1 || response_switch.compute_dn50_leeside == 1)
    if legacy_dn50.use_legacy_model == 1
        [Dn50_ss, Dn50_ls] = legacy_dn50_responses(response_switch, forcing, gammas, geometry, g, legacy_dn50.submerged_correction);
    else
        seaside_design_S = geometry.seaside_design_S; leeside_design_S = geometry.leeside_design_S; armor_delta = geometry.armor_delta;
        % Number Of Waves Duration [s]: The Storm Duration (Event Length, Set With The Forcing), Never dt
        [Dn50_ss, Dn50_ls] = cellfun(@(a, b, c, d, e, f, k) ann_rubblemound_stability(a, b, c, d, e, f,...
            crest_elev - toe_elev, crest_width, mound_seaside_slope_cota, mound_leeside_slope_cota,...
            offshore_slope_tana, cem_P, k.gamma_f, seaside_design_S, leeside_design_S, armor_delta, g),...
            Hm0, Tm, Tm10, h, Rc, storm_dur, gammas, 'un', false);
    end
    if response_switch.compute_dn50_seaside == 1
        Resp.Dn50 = Dn50_ss;
    end
    if response_switch.compute_dn50_leeside == 1
        Resp.Dn50_Lee = Dn50_ls;
    end
end
end

%% AUX FUNCTION: LEGACY DN50 SWITCHES FROM "config" (MISSING = 0: CONFIGS BUILT WITHOUT finalize_config)
function legacy_dn50 = legacy_dn50_settings(config)
legacy_dn50.use_legacy_model = config_flag(config, 'dn50_use_legacy_model');
legacy_dn50.submerged_correction = config_flag(config, 'dn50_legacy_submerged_correction');
end

%% AUX FUNCTION: CONFIG 0/1 FIELD, 0 WHEN MISSING OR EMPTY
function value = config_flag(config, field_name)
value = 0;
if isfield(config, field_name) && ~isempty(config.(field_name))
    value = config.(field_name);
end
end

%% AUX FUNCTION: LEGACY RUBBLEMOUND STONE SIZE (MELBY SEASIDE, VAN GENT LEESIDE, OPTIONAL SUBMERGED CORRECTION)
function [Dn50_ss, Dn50_ls] = legacy_dn50_responses(response_switch, forcing, gammas, geometry, g, submerged_correction)
emp_coeff = load_empirical_coefficients();
Hm0 = forcing.Hm0; Tp = forcing.Tp; Tm = forcing.Tm; Tm10 = forcing.Tm10; h = forcing.h; Rc = forcing.Rc;
crest_elev = geometry.crest_elev; crest_width = geometry.crest_width; cem_P = geometry.cem_P; armor_delta = geometry.armor_delta;
seaside_design_S = geometry.seaside_design_S; leeside_design_S = geometry.leeside_design_S;
mound_seaside_slope_cota = geometry.mound_seaside_slope_cota; mound_leeside_slope_cota = geometry.mound_leeside_slope_cota;
% The Equations Flatten Hm0 But Not The Duration (Nz = duration./Tm(:)): One Duration [s] Per Hm0 Element, As A Column
duration = cellfun(@(d, a) reshape(d + zeros(size(a)), [], 1), forcing.storm_dur, Hm0, 'un', false);
Dn50_ss = [];
Dn50_ls = [];
if response_switch.compute_dn50_seaside == 1
    Dn50_ss = cellfun(@(a, b, c, d, e) melby_Dn50_seaside_stability(a, b, c, e, mound_seaside_slope_cota,...
        armor_delta, cem_P, seaside_design_S, g, emp_coeff.km1, emp_coeff.km2, d), Hm0, Tm, h, Rc, duration, 'un', false);
    % Submerged Crest (Rc < 0): hc Is The Crest Elevation, As In The Pre-ANN Code
    if submerged_correction == 1
        Dn50_ss = cellfun(@(a, b, c, d, e) submerged_stone_armor_stability(a, b, c, d, e, crest_elev,...
            seaside_design_S, armor_delta, g), Hm0, Tp, h, Rc, Dn50_ss, 'un', false);
    end
end
if response_switch.compute_dn50_leeside == 1
    Dn50_ls = cellfun(@(a, b, c, d, e, k) van_gent_Dn50_leeside_stability(leeside_design_S, a, b, c, d, crest_width,...
        mound_seaside_slope_cota, mound_leeside_slope_cota, e, armor_delta, g, emp_coeff.k_ls1, emp_coeff.k_ls2, k.gamma_f),...
        Hm0, Tm10, Tm, Rc, duration, gammas, 'un', false);
    if submerged_correction == 1
        Dn50_ls = cellfun(@(a, b, c, d, e) submerged_stone_armor_stability(a, b, c, d, e, crest_elev,...
            leeside_design_S, armor_delta, g), Hm0, Tp, h, Rc, Dn50_ls, 'un', false);
    end
end
end

%% AUX FUNCTION: TRANSMITTED WAVE HEIGHT Hm0t (INCIDENT Hm0 AT THE TOE x EUROTOP Kt)
function Hm0t = transmitted_wave_height(forcing, geometry, workflow, struc_type, g)
Hm0 = forcing.Hm0;
% Seaward Slope: Levee/Rubblemound Seaside Slope, Else The Berm Slope
if ismember(struc_type, [1, 3])
    seaward_slope_tana=1/geometry.mound_seaside_slope_cota;
else
    seaward_slope_tana=geometry.berm_slope_tana;
end
crest_width = geometry.crest_width;
[Kt] = cellfun(@(a,b,c) eurotop_wave_transmission(a,b,c,crest_width,seaward_slope_tana,g),Hm0,forcing.Tp,forcing.Rc,'un',false);
% Compute Transmitted Wave (Incident Hm0 At The Toe)
switch workflow
    case 1 % PROS-RB: Best-Estimate (z = 0) Incident Hm0 x Kt Replicates (Same As Forcing HCs)
        Hm0t = cellfun(@(x, y) x(:, replicate_z0_col(size(x, 2))).*y, Hm0, Kt, 'un', false);
    case {2, 3, 4} % DET, LCS, PROS-FB (Hm0 Is The Per-Sample MC Forcing)
        Hm0t = cellfun(@(x, y) x.*y, Hm0, Kt, 'un', false);
    otherwise
        error('compute_structure_response:unsupportedWorkflow', 'Unsupported workflow %d (1 = PROS, 2 = DET, 3 = LCS, 4 = PROS-FB).', workflow);
end
end

%% AUX FUNCTION: DAMAGING DEPTH RESPONSES (DamDepthElev, DamDepth)
function [DamDepthElev, DamDepth] = damaging_depth_responses(config, structure, forcing, geometry, g)
damaging_depth_ks = config.compute_damaging_depth_Ks;
if isfield(structure, 'offshore_elevation') && ~isempty(structure.offshore_elevation)
    offshore_elevation = structure.offshore_elevation;
else
    offshore_elevation = config.offshore_elevation;
end
berm_width = geometry.berm_width; berm_slope_tana = geometry.berm_slope_tana; offshore_slope_tana = geometry.offshore_slope_tana;
[DamDepthElev, DamDepth]= cellfun(@(x, y, z, a, b) damaging_depth(x, y, z, offshore_elevation,...
    damaging_depth_ks, a, b, berm_width, berm_slope_tana, offshore_slope_tana, g),...
    forcing.SWL, forcing.Hm0_off, forcing.Tp, forcing.h, forcing.hb, 'un', false);
end

%% AUX FUNCTION: PROGRESSIVE OVERTOPPING VOLUMES PER STORM (Q_vol, Q_vol_wave_ot)
function [Q_vol, Q_vol_wave_ot] = overtopping_volumes(q, q_wave_ot, dt, q_step)
Q_vol = cellfun(@progressive_volume, q, dt, q_step, 'un', false);
Q_vol_wave_ot = cellfun(@progressive_volume, q_wave_ot, dt, q_step, 'un', false);
end

%% AUX FUNCTION: KEEP THE FITTED RESPONSES AND TAKE THEIR PER-STORM MAXIMA (PROS/DET TIMESERIES, RB3)
function Resp = per_storm_peak_responses(Resp, response_switch, workflow)
% No Responses Computed (Every Switch Off): Nothing To Reduce
if isempty(Resp)
    return
end
% Responses Fitted By PROS-RB Whose Compute Switch Is On (Q_vol* Only When compute_q_vol Is On)
fitted_rows = response_registry('fitted_by_pros_rb', true);
fitted_on = arrayfun(@(row) response_switch.(row.compute_switch) == 1, fitted_rows);
vars_to_find = {fitted_rows(fitted_on).name};
% Evaluate According To Workflow
switch workflow
    case {1, 2, 4} % Find Max Responses For Timeseries (RB3)
        % Remove Unwanted Fields
        rm_indx = sum(cell2mat(cellfun(@(x) strcmp(fieldnames(Resp), x), vars_to_find, 'un', false)), 2) == 0;
        if any(rm_indx)
            rm_names = fieldnames(Resp);
            Resp = rmfield(Resp, rm_names(rm_indx));
        end
        % Loop Through Each Response
        vars_to_find = vars_to_find(isfield(Resp, vars_to_find)); % Q_vol* Only When The Overtopping Fields Exist
        for vv = 1:length(vars_to_find)
            Resp.(vars_to_find{vv}) = cell2mat(cellfun(@(x) max(x,[],1), Resp.(vars_to_find{vv}), 'un', false));
        end
end
end

%% AUX FUNCTION: RUNNING TOTAL OF q.*dt PER STORM
function Q = progressive_volume(q, dt, step)
% Running Total Of q.*dt Down Dim 1 (NaN Counts As 0): The Whole Cell (One Storm), Or Restarting At Each Storm Start
% (step == 0, LCS Timeseries Life Cycles)
Q = q.*dt;
Q(isnan(Q)) = 0;
if isempty(step)
    Q = cumsum(Q, 1);
    return
end
starts = [find(step == 0); size(Q, 1) + 1];
for ss = 1:length(starts)-1
    rows = starts(ss):starts(ss+1)-1;
    Q(rows, :) = cumsum(Q(rows, :), 1);
end
end

%% AUX FUNCTION: TIMESERIES LIFE-CYCLE COLUMN (EMPTY FOR PEAKS)
function v = ts_column(x, col, is_timeseries)
% Column Of A Timeseries Life Cycle (dt, step), Empty For Peaks
if is_timeseries
    v = x(:, col);
else
    v = [];
end
end

%% AUX FUNCTION: NaN WHERE THE REFERENCE RESPONSE IS NaN
function x = nan_where(x, ref)
% Sets x To NaN Where ref Is NaN (Same Size), Or Entirely When ref Is All NaN
if isequal(size(x), size(ref))
    x(isnan(ref)) = NaN;
elseif all(isnan(ref(:)))
    x(:) = NaN;
end
end

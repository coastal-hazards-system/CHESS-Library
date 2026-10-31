function HC_out = chess_pros(config, project_forcing, structure, emp_coeff, outPath)
%% INITIALIZE FIELDS AND PROMT USER
% Turn Off Warnings
warning('off');
% Get AEP vs AEF Flag
use_aep = config.pros_use_aep;
% Display PROS Message
disp(['      Running CHESS: PROS....']);
% Get Secondary Responses Switch
varnames = fieldnames(config);
varnames = varnames(contains(varnames, {'compute_p2_p3', 'compute_nappe'}));
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
    varnames = fieldnames(config);
    varnames = varnames(contains(varnames, {'compute_'}));  % Keep compute_*
    varnames = varnames(~contains(varnames, {'pros_', '_Ks','_slope'})); % Remove unwanted
    % Get Responses To Compute Usign PROS-FB
    fb_responses = cellfun(@(x) config.(x), varnames, 'un', true);
    varnames = varnames(logical(fb_responses));
    % Turn Off Responses For RB Section
    config = config_editor(config, varnames, 0);
end

%% CHESS: PROS - XC
if contains(config.storm_sampling, {'XC','CC'})
    % 1. Compute Structure Responses
    [Resp] = compute_structure_response(config, structure, project_forcing.('XC'), emp_coeff, 1);
    % 1.1 Add Forcing Hazard Curve Inputs (pros_forcing_curves.m)
    Resp = add_forcing(project_forcing, 'XC', Resp);
    % 2. Compute Extremal Distribution Curves
    HC_out.XC = call_hazard_curve_builder(config, [], Resp, 'XC', use_aep, outPath);
end

%% CHESS: PROS - TC
if contains(config.storm_sampling, {'TC','CC'})
    % 1. Compute Structure Responses
    [Resp] = compute_structure_response(config, structure, project_forcing.('TC'), emp_coeff, 1);
    % 1.1 Add Forcing Hazard Curve Inputs (pros_forcing_curves.m)
    Resp = add_forcing(project_forcing, 'TC', Resp);
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

% Enable Warnings Again
warning('on');

%% AUX FUNCTION
    function config_out = config_editor(config_out, var_to_look, value)
        % Turn Off Responses For RB Section
        for ii = 1:length(var_to_look)
            config_out.(var_to_look{ii}) = value;
        end
    end

    function Resp = add_forcing(project_forcing, st_type, Resp)
        if  config.pros_compute_forcing_HC == 1
            % SWL, Tp, Hm0_offshore: Values Without Uncertainty (z = 0 Replicate) For HC Calculations (pros_forcing_curves.m)
            z0_of = @(f) cellfun(@(x) x(:, replicate_z0_col(size(x, 2))), project_forcing.(st_type).(f), 'un', false);
            SWL = z0_of('SWL');
            Hm0_off = z0_of('Hm0_offshore');
            Tp = z0_of('Tp');
            % This Max Is Mostly Meant To Handle Hm0/Tp Max Relationship
            Resp.('SWL') = cellfun(@(x) max(x,[],1),SWL,'un',true);
            % Find Hm0 Max For Each Storm (Tp At The Offshore Hm0 Peak)
            [Resp.('Hm0_offshore'), Hm0_indx] = cellfun(@(x) max(x,[],1),Hm0_off,'un',true);
            %
            Resp.('Tp') = cellfun(@(x,y) x(y), Tp, num2cell(Hm0_indx), 'un', true);
            % Hm0_toe Is A Toe Response Like Hm0t: Per-Storm Max Of Every Replicate (Storms x Replicates)
            Resp.('Hm0_toe') = cell2mat(cellfun(@(x) max(x,[],1), project_forcing.(st_type).Hm0_toe(:), 'un', false));
        end
    end
end
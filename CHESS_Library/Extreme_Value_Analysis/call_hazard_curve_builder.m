function  [Output]= call_hazard_curve_builder(config, TC_Prob, Resp, storm_type, use_aep, outPath)
% call_hazard_curve_builder  Fit PROS response-based hazard curves.
%   Output = call_hazard_curve_builder(config, TC_Prob, Resp, storm_type,
%       use_aep, outPath)
%
%   PROS-RB step of chess_pros: fits one hazard curve per field of Resp
%   (structure responses and the forcing curves of pros_forcing_curves)
%   for one storm type: XC with peaks-over-threshold statistics
%   (CHESS_PST, DataType 'POT', record length Nyrs_XC times the number of
%   fitted replicates, GPD threshold by minimum WMSE, GPD always fitted,
%   100 bootstrap simulations) and TC with the joint probability method
%   (CHESS_JPM, the discrete storm weights TC_Prob split evenly over the
%   replicates). This is the response-based caller of PST/JPM for CHESS,
%   not a general PST/JPM front end.
%   Responses hold one column per replicate: the z = 0 replicate is
%   dropped (drop_z0) before fitting and kept in POT (overlays). The
%   forcing curves SWL, Tp and Hm0_offshore come in as the z = 0 column
%   only and use JPM integration method 2 (PCHA ITCS: JPM adds the
%   replicates); Hm0_toe comes in with every replicate and uses method 1
%   (PCHA ATCS), like a response. Uncertainties, uncertainty treatment,
%   labels and y scale come from response_library_headers. Great Lakes
%   water levels (registry datum_elevation rows) are fitted as surge: the
%   mean lake level (mean_lake_level) is removed before the fit and added
%   back to the curves. SLC = 0 (the forcing SWL already holds swl_slr).
%   Events PST/JPM discard (NaN, Inf, <= 0 after the lake level shift)
%   are counted and reported in the figure title. Variables with no valid
%   value (all NaN or all 0) and variables whose PST/JPM call errors are
%   skipped. In PROS-FB (workflow 4) the forcing curves are titled PROS-RB.
%
%   Inputs:
%     config     - CHESS configuration, 1x1 struct; reads case_name,
%                  struc_id, project_name, project_CLs (CL percentiles,
%                  e.g. '[84 90]'), Nyrs_XC, pros_use_aep, workflow, the
%                  uncertainty fields read by response_library_headers
%                  and the mean lake level (mean_lake_level)
%     TC_Prob    - TC discrete storm weights (probability masses) [1/yr],
%                  number_of_storms x 1 double (project_forcing.TC.TC_Prob);
%                  [] for XC
%     Resp       - variables to fit, struct; one field per response or
%                  forcing curve, number_of_storms x number_of_replicates
%                  double (z = 0 column included); a field named TC_Prob
%                  is ignored
%     storm_type - 'XC' (PST) or 'TC' (JPM), char
%     use_aep    - hazard curve frequencies as AEP (1) or AEF (0), scalar
%                  double (chess_pros passes config.pros_use_aep)
%     outPath    - folder of the hazard curve figure names (save_name),
%                  char
%   Outputs:
%     Output - hazard curve entries, 1 x number_of_fitted_variables struct
%              ([] when none); the set_hazard_curve_entry fields (var, CL
%              = [50 project_CLs], x_plot/y_plot, x_table/y_table, POT =
%              the Resp field with every replicate, y_label, title,
%              y_log_scale, save_name, n_events, n_dropped, lake_offset)
%              plus:
%                .x_table_ARI - average recurrence interval of every table
%                               row [years]
%                .tbl_rsp_x   - AEP of each tbl_rsp_y response level, one
%                               column per CL (always AEP; used by
%                               call_hazard_curve_combiner)
%                .tbl_rsp_y   - response levels 0.01:0.01:20 plus the lake
%                               offset [response units], 2000 x 1
%
%   Tier: internal
%
%   See also CHESS_PST, CHESS_JPM, set_hazard_curve_entry,
%   call_hazard_curve_combiner, chess_pros, drop_z0.


disp('            Building hazard curves....');

%% QUICK ABORT COMMANDS
if ~isstruct(Resp)
    error('Error: Variables "Resp" needs to be populated or empty MATLAB structures....');
end

%% GRAB DETAILS FROM "config"
case_name = strrep(config.case_name,'_',' ');
struc_id = strrep(config.struc_id,'_',' ');
% Grab Percentiles
try
    prc = [cellfun(@str2double,strsplit(config.project_CLs(2:end-1),{' '}))];
catch
    prc = [];
end
% Save Name
save_name = fullfile(outPath, [config.project_name,'_', config.struc_id]);

%% DEFINE RESPONSE VARIABLES TO PROCESS
% Grab Strucutre Response Fields If Provided
vars_to_process = fieldnames(Resp);
% Append Data Structure
data_to_process = Resp;
% Remove Tc Prob From Filenames
vars_to_process = vars_to_process(~contains(vars_to_process,{'TC_Prob'}));

%% INITIALIZE FIELDS && RESPONSE LOOP
% Initialize Counter
ctr = 1;Output = [];
% Loop Through All Responses
for ii = 1:length(vars_to_process)
    %% PREP RESPONSE FOR PST/JPM
    % Define Station ID
    resp_var = vars_to_process{ii};
    % Search Response Library For Uncertainty Values & Associated Labels
    [U_a, U_r, uncert_treatment,...
        unit_label,...
        var_name, y_label, y_scale_log] = response_library_headers(config, resp_var);
    % Replicates Fitted By PST/JPM (z = 0 Replicate Dropped)
    fit_data = drop_z0(data_to_process.(resp_var));
    % Get Data Size
    [drows, dcols] = size(fit_data);
    % Great Lakes Water Levels Are Fitted As Surge (Mean Lake Level Removed, Added Back To The Hazard Curve)
    switch resp_var
        case response_registry('output', 'names', 'datum_elevation', true)
            lake_offset = mean_lake_level(config);
        otherwise
            lake_offset = 0;
    end
    % Response Information
    % SLC = 0: The Forcing SWL Already Includes swl_slr (adjust_project_forcing.m)
    response_data = struct('data', [zeros(drows*dcols, 1) fit_data(:)-lake_offset zeros(drows*dcols, 1)],...
        'flag_value', [],'Ua', U_a,'Ur', U_r, 'SLC', 0, 'tide_std', 0,...
        'lambda', [],'Nyrs', config.Nyrs_XC*dcols, 'gprMdl', [], 'DataType', 'POT');
    % PST/JPM Options
    eva_options = struct('integration_method', 1,...
        'uncertainty_treatment', uncert_treatment,...
        'tide_application', 0, 'ind_Skew', 0, 'use_AEP', config.pros_use_aep,...
        'prc', prc, 'stat_print', 0, 'tLag', 0, 'GPD_TH_crit', 2,...
        'apply_GPD_to_SS', 1, 'bootstrap_sims', 100);
    % Plot Options
    plot_options = struct('create_plots', 0,'staID', resp_var,'yaxis_Label', [],...
        'yaxis_Limits', [], 'y_log', y_scale_log,'path_out', '');
    % Check For Full NaN Vector (On Absolute Values)
    if all(isnan(fit_data(:))) || all(fit_data(:)==0)
        % Response Variable Has NaNs For All Entries
        disp(['               No valid responses for ' resp_var ', Skipping response var....']);
        % Skip Iteration
        continue;
    end
    % Count Events PST/JPM Discard (NaN, Inf, <= 0 After The Lake Level Shift)
    n_events = drows*dcols;
    n_dropped = sum(isnan(response_data.data(:, 2)) | isinf(response_data.data(:, 2)) | response_data.data(:, 2) <= 0);
    if n_dropped > 0
        if lake_offset ~= 0
            drop_reason = [' (<= 0 after removing mean lake level ' num2str(lake_offset) ' m)'];
        else
            drop_reason = '';
        end
        disp(['               ' resp_var ': ' num2str(n_dropped) ' of ' num2str(n_events) ' events dropped' drop_reason]);
    end

    %% PREP NAMING STRINGS
    % Define Workflow String
    wstr = chess_workflows(config.workflow).wflow_name;
    % PROS-RB Naming Overwrite When Calling PROS-FB
    if ismember(resp_var, pros_forcing_curves())
        % For FB Analysis The Forcing HC Are Created Using RB
        if config.workflow == 4
            wstr = 'PROS-RB'; % Forcing Fields Are Computed With Response Base
        end
        % Redifine Integration Method For JPM (Hm0_toe Holds Replicates Like Any Response: ATCS)
        if ~strcmp(resp_var, 'Hm0_toe')
            eva_options.integration_method = 2; % Let JPM Manage Replicates
        end
    end
    % Define Figure Title
    title_str = {['CHESS: ' wstr ' | '  case_name ' | ' struc_id],...
        ['' storm_type ' | ' var_name ' [' unit_label ']']};
    % Report Events Not Fitted On The Figure Title
    if n_dropped > 0
        title_str{2} = [title_str{2} ' | ' num2str(n_dropped) ' of ' num2str(n_events) ' events not fitted'];
    end

    %% CALL PST/JPM TO BUILD HAZARD CURVES
    switch storm_type
        case 'XC' % PST
            % Disp Progress
            disp(['               Performing Stochastic Simulation Technique (SST) for station (',num2str(ii),'/',num2str(length(vars_to_process)),'): ', resp_var]);
            % Call SST
            try
                [dummy] = CHESS_PST(response_data, eva_options, plot_options);
            catch
                disp(['               Stochastic Simulation Technique (SST) returned error, skipping: ', resp_var]);
                ctr = ctr+1;
                continue;
            end
        case 'TC' % JPM
            disp(['               Performing Joint Probability Method (JPM) for station (',num2str(ii),'/',num2str(length(vars_to_process)),'): ', resp_var]);
            % Scale Prob Mass If Needed
            if dcols ~= 1 % Need To Scale DSW For Replicates
                tc_dsw = repmat(TC_Prob./dcols, 1, dcols);
            else
                tc_dsw = TC_Prob;
            end
            % Append DSWs
            response_data.data = [response_data.data, tc_dsw(:)];
            % Call JPM
            try
                [dummy] = CHESS_JPM(response_data, eva_options, plot_options);
            catch
                disp(['               Joint Probability Method (JPM) returned error, skipping: ', resp_var]);
                ctr = ctr+1;
                continue;
            end
    end

    % Add Mean Lake Level Back To Response Valued Outputs (HC_tbl_rsp_x Holds AEF/AEP)
    dummy.HC_plt = dummy.HC_plt + lake_offset;
    dummy.HC_tbl = dummy.HC_tbl + lake_offset;
    dummy.HC_tbl_rsp_y = dummy.HC_tbl_rsp_y + lake_offset;

    %% STORE OUTPUTS
    % Append Results To Output Data Structure
    Output = set_hazard_curve_entry(Output, ctr, resp_var, y_label, title_str,...
        dummy.HC_plt_x, dummy.HC_plt,...
        dummy.HC_tbl_x, dummy.HC_tbl, data_to_process.(resp_var),...
        y_scale_log, [50,prc], [save_name '_' resp_var '_' storm_type '_Hazard_Curve.png'],...
        n_events, n_dropped, lake_offset);
    % Add "_rsp" Fields For Hazard Combinations
    if use_aep == 1
        Output(ctr).tbl_rsp_x = dummy.HC_tbl_rsp_x; % x here implies Responses, AEP/AEF -> Responses
        Output(ctr).x_table_ARI = ceil(1./aep2aef(Output(ctr).x_table_ARI));
    else
        Output(ctr).tbl_rsp_x = aef2aep(dummy.HC_tbl_rsp_x);
        Output(ctr).x_table_ARI = 1./Output(ctr).x_table_ARI;
    end
    Output(ctr).tbl_rsp_y = dummy.HC_tbl_rsp_y; % y here implies AEF/AEp, Response -> AEP/AEF

    % Increase Counter
    ctr = ctr + 1;
end

%% REMOVE EMPTY RESPONSES
% Remove Empty Entries (If Any)
if ~isempty(Output)
    rm_indx = cell2mat(cellfun(@(x) isempty(x), {Output.y_table}, 'un', false));% Get Logical Index
    Output = Output(~rm_indx);% Keep Valid Fields
else
    return;
end
end
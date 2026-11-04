function [SST_output] = CHESS_PST(response_data, pst_options, plot_options)
% CHESS_PST  Response hazard curves by peaks-over-threshold statistics.
%   SST_output = CHESS_PST(response_data, pst_options, plot_options)
%
%   Peaks-over-threshold statistics (PST; SST was the former name) of the
%   CHS probabilistic coastal hazard analysis, used for extratropical (XC)
%   responses: a peaks-over-threshold (POT) sample, given (DataType 'POT')
%   or extracted from a time series (DataType 'Timeseries', CHESS_POT),
%   is bootstrapped and fitted with a generalized Pareto distribution
%   (GPD) above a mean residual life (MRL) threshold, giving the mean
%   hazard curve and its confidence limits (CL) (CHESS_PST_Fit).
%   The inputs are checked first (errors for invalid fields). POT rows
%   with the flag value or with NaN, Inf or <= 0 (response, and response
%   with tides when ind_Skew = 1) are removed; Timeseries rows with the
%   flag value, NaN or Inf are removed and Nyrs is the number of days with
%   data / 365.25. An error is raised when no valid data is left (POT: 3
%   or fewer unique values). Duplicate POT values get 1e-6 added. Errors
%   of the fit or the plots are not raised: they are returned in
%   SST_output.ME. The known gpfit and table warnings are silenced by ID
%   until the function returns.
%
%   Inputs:
%     response_data - response sample, struct; fields:
%       .data       - [time, response, response_with_tides], N x 3
%                     double: column 1 event time (MATLAB datenum; used
%                     for Timeseries only), column 2 response without
%                     tides, column 3 response with tides (POT with
%                     ind_Skew = 1 only; ignored for Timeseries)
%       .DataType   - 'POT' or 'Timeseries', char
%       .flag_value - response value to remove ([] = none)
%       .Nyrs       - record length [years], scalar > 0 (POT; computed
%                     for Timeseries)
%       .lambda     - mean annual rate of events [1/yr], scalar > 0
%                     (Timeseries; ignored for POT)
%       .SLC        - sea level change implicit in the response [response
%                     units], scalar >= 0 (POT; 0 for Timeseries)
%       .gprMdl     - skew tide Gaussian process regression model
%                     (RegressionGP, predicts the skew tide mean and
%                     standard deviation from the surge), required when
%                     ind_Skew = 1; the field must exist ([] otherwise)
%     pst_options - PST settings, struct; fields:
%       .GPD_TH_crit     - MRL threshold criterion: 1 sample intensity
%                          (about 2 events/yr), 2 minimum weighted mean
%                          square error (WMSE)
%       .apply_GPD_to_SS - 1 always fit the GPD; 0 use the empirical curve
%                          when the POT sample has < 20 events or Nyrs <
%                          20 years
%       .bootstrap_sims  - bootstrap simulations, >= 100 (non-numeric or
%                          < 100 = 100)
%       .ind_Skew        - add skew tides from gprMdl (0/1; POT only,
%                          forced to 0 for Timeseries)
%       .tLag            - inter-event time [hours], scalar > 0
%                          (Timeseries; ignored for POT)
%       .use_AEP         - frequencies as AEP (1) or AEF (0)
%       .prc             - CL percentiles [%], up to 4 values
%                          ([] = [2.28 15.87 84.13 97.72])
%       .stat_print      - clear the command window and print the
%                          progress (0/1)
%     plot_options - plot settings, struct; fields:
%       .create_plots - write the figures and output .mat (0/1)
%       .staID        - variable name for titles and file names, char
%                       ([] = 'resp')
%       .yaxis_Label  - y axis label, char ([] = '')
%       .yaxis_Limits - y axis limits ([] = automatic)
%       .y_log        - y axis log scale of the bootstrap figure (0/1)
%       .path_out     - output folder, char ([] = current folder); files
%                       go in <path_out>/PST_outputs
%   Outputs:
%     SST_output - hazard curves, struct; fields:
%       .staID        - plot_options.staID
%       .RL           - record length Nyrs [years]
%       .MRL_output   - MRL threshold selection (CHESS_MRL Summary and
%                       Selection tables, when the GPD is fitted) with the
%                       bootstrap GPD parameters pd_TH_wOut, pd_k_wOut,
%                       pd_sigma, pd_k_mod (shape limited to [-0.5 0.3])
%                       and Status ('' or the reason the GPD was not fit)
%       .HC_plt_x     - plot grid AEF (AEP when use_AEP = 1) from 1e-6 to
%                       10, 631 x 1
%       .HC_plt       - response at HC_plt_x, columns [bootstrap mean,
%                       prc CLs], 631 x (1 + numel(prc))
%       .HC_tbl_x     - table AEP 1/[2 5 10 ... 1e6] (18 values) or AEF
%                       1/[0.1 0.2 0.5 ... 1e4] (16 values)
%       .HC_tbl       - response at HC_tbl_x (same columns), negatives NaN
%       .HC_tbl_rsp_y - response levels 0.01:0.01:20, 2000 x 1
%       .HC_tbl_rsp_x - AEF/AEP of each HC_tbl_rsp_y level (same columns),
%                       < 1e-4 set to NaN
%       .HC_emp       - empirical curve, table (Response, Rank, CCDF,
%                       Hazard = AEF or AEP, ARI)
%       .POT          - POT sample without tides, sorted in descending
%                       order
%       .Warning      - '' or the warning that the best estimate at 0.1
%                       AEF/AEP exceeds 1.75 times the empirical curve
%       .ME           - [] on success, else the MException of a failed fit
%                       or plot (after a failed fit only staID is set;
%                       HC_plt_x, HC_tbl_x and HC_tbl_rsp_y are then
%                       missing)
%   With create_plots = 1 the figures (CHESS_PST_plot, bootstrap check)
%   and CHESS_<staID>_SST_output.mat are written in <path_out>/PST_outputs.
%
%   Tier: public
%
%   See also CHESS_JPM, aef2aep, aep2aef.

%% Other settings
if pst_options.stat_print == 1
    clc;
    disp(['***********************************************************' newline...
        '***         CHESS-SST Tool Alpha Version 0.5         ***' newline...
        '***                Release 1 - 20210809                 ***' newline...
        '***                 FOR  TESTING  ONLY                  ***' newline...
        '***********************************************************']);
    disp([newline '*** Step 1: Processing input arguments ']);
end

% Silence The Known Fit Warnings (GPD Fit Boundary/Evaluation Limit, MRL Table Rows) Until The Function Exits
w_state = warning;
warning('off', 'stats:gpfit:ConvergedToBoundary1');
warning('off', 'stats:gpfit:ConvergedToBoundary2');
warning('off', 'stats:gpfit:EvalLimit');
warning('off', 'MATLAB:table:RowsAddedExistingVars');
w_cleanup = onCleanup(@() warning(w_state));

%% PARAMETER INITIALIZATION
% Error Handeling For Inputs
[response_data, pst_options, plot_options] = error_handling(response_data, pst_options, plot_options);
% Define Output Path For PST
plot_options.('path_out') = fullfile(plot_options.('path_out'), 'PST_outputs');
% Check path to output folder
if ~exist(plot_options.('path_out'), 'dir') && plot_options.create_plots == 1
    mkdir(plot_options.('path_out'));
end
% Define Col Index To Include For Invalid Response Identification
if pst_options.ind_Skew == 1
    % include POT with Tides As Part Of QC
    col_indx = 3;
else
    % Ignore POT WIth Tides Col
    col_indx = 2;
end
% Pre-allocate output structure array
SST_output = struct('staID','','RL',double.empty,'POT',double.empty,'MRL_output',double.empty,...
    'HC_plt',double.empty,'HC_tbl',double.empty,'HC_tbl_rsp_x',double.empty,'HC_emp',double.empty,'Warning','','ME',cell(1));
if pst_options.stat_print == 1
    disp('*** Step 2: Verifying input datasets')
end

%% Data preprocessing: remove NaN, inf values; compute record length
% Grab Event Response Data
procData = response_data.data;

% Prep Processing Data
switch response_data.DataType
    case 'Timeseries'  %Timeseries
        % Remove Flag Values
        if ~isempty(response_data.('flag_value'))
            % Remove Flag Values
            procData(procData(:, 2) == response_data.('flag_value'), :) = [];
        end
        % Merge data and remove NaN, Inf values
        procData(isinf(procData(:,2)) | isnan(procData(:,2)), :) = [];
        % Compute record length: Effective duration method
        [dt(:,1),dt(:,2),dt(:,3)] = ymd(datetime(procData(:,1), 'ConvertFrom', 'datenum'));
        % Get Unique Rows
        dt = unique(dt,'rows');
        % Compute Number Of Years From Timeseries Data
        response_data.('Nyrs') = size(dt,1)/365.25; % number_timesteps/year_in_days
        % Ensure Timeseries Is Valid
        if isempty(procData(:, 2)) % This already covers isempty condition (length == 0)
            fail_flag = true;
        else
            fail_flag = false;
        end
    case 'POT' %POT
        % Remove Flag Values
        if ~isempty(response_data.('flag_value'))
            % Remove Flag Values
            procData(any(procData(:, 2:end) == response_data.('flag_value'), 2), :) = [];
        end
        % Merge data and remove NaN, Inf values
        procData(any(isinf(procData(:, 2:col_indx)) | isnan(procData(:, 2:col_indx)) | procData(:, 2:col_indx) <= 0, 2), :) = [];
        % Ensure POT Is Valid
        if length(unique(procData(:, 2), 'stable'))<=3 % This already covers isempty condition (length == 0)
            fail_flag = true;
        else
            fail_flag = false;
        end
end
% Abort PST Based On Data
if fail_flag
    % Abort PST Processing
    error('Error: Could not process dataset because invalid response removal yielded empty data structure.');
end

%% Perform SST
if pst_options.stat_print == 1
    disp(['*** Step 3: Performing SST for station ', plot_options.staID]);
end

try
    % Defien POT Dataset
    switch response_data.DataType
        case 'Timeseries' %Timeseries
            % Execute CHESS-POT
            [POT_samp,~] = CHESS_POT(procData(:,1), procData(:,2), pst_options.tLag, response_data.lambda, response_data.Nyrs); % [ timestamp, event_peak, lower_bound, upper_bound ]
        case 'POT'
            POT_samp = procData; % [ timestamp, event_peak, event_peak_with_tide ]
    end
    %%% Add noise to duplicates in POT sample - LAA 2023/12/07
    [~, w]=unique(POT_samp(:,2),'stable');
    duplicate_indices=setdiff(1:numel(POT_samp(:,2)), w);
    POT_samp(duplicate_indices, 2) = POT_samp(duplicate_indices, 2) + 1e-6;
    %%%
    % Execute CHESS-SST-Fit
    [SST_output] = CHESS_PST_Fit(POT_samp(:, 2), POT_samp(:, 3), response_data.SLC, response_data.Nyrs, response_data.gprMdl, pst_options, plot_options);
    SST_output.ME = [];
    % Plot results
    if plot_options.create_plots == 1
        CHESS_PST_plot(SST_output, pst_options, plot_options);
    end
catch ME
    SST_output.staID = plot_options.staID;
    SST_output.ME = ME;
end

%% Save the output
if pst_options.stat_print == 1
    disp(['*** Step 4: Saving results here: ',plot_options.path_out]);
end
% Save Output
if plot_options.create_plots == 1
    save(fullfile(plot_options.('path_out'), ['CHESS_' SST_output.staID '_SST_output.mat']), 'SST_output', '-v7.3');
end
if pst_options.stat_print == 1
    disp('*** Evaluation finished.' )
    disp(['****** Remember to check outputs Check_datasets and Removed_datasets.' newline])
    disp('*** CHESS-SST Tool terminated.')
end

%% ERROR HANDELING FUNCTION
    function [response_data, pst_options, plot_options] = error_handling(response_data, pst_options, plot_options)
        % Define Boolean Fields To Inspect
        field_to_check = ["pst_options.use_AEP","plot_options.create_plots",...
            "plot_options.y_log", "pst_options.apply_GPD_to_SS",...
            "pst_options.stat_print", "pst_options.GPD_TH_crit"];
        % Define Error Message To Append
        error_msg = ["0 (AEF) or 1 (AEP)", "0 (no plots) or 1 (all plots)",...
            "0 (linear y-scale) or 1 (log y-scale)", "0 (use empirical for small sample) or 1 (force GPD fit)"...
            "0 (no code progress print) or 1 (print code progress)",...
            "1 (lambda sample intensity criterion) or  2 (WMSE criterion) for GPD threshold selection"];
        % Define Member List To Check Per Field
        member_list = [repmat([0, 1], 5, 1);[1, 2]];
        % Loop Across Fields To Check
        for kk = 1:length(field_to_check)
            % Build Error String
            error_str = "Error: " + field_to_check(kk) + " must be " + error_msg(kk) + ".";
            % Call Bool Check Function
            bool_check(eval(field_to_check(kk)), error_str, member_list(kk, :));
        end
        % Datatype Specific Errors
        switch response_data.DataType
            case 'POT'
                % Force Timeseries Fields To Empty
                pst_options.tLag = [];
                response_data.lambda = [];
                % Number Of Years
                if response_data.Nyrs<=0 || isempty(response_data.Nyrs)
                    error('When DataType is set to ''POT'': Input "Nyrs" cannot be empty and must have positive values only')
                end
                % Implicit SLC
                if isempty(response_data.('SLC'))
                    response_data.('SLC') = 0;
                elseif length(response_data.SLC)~=1 || response_data.SLC < 0 || isnan(response_data.SLC) || isinf(response_data.SLC)
                    error('Input SLC must be a positive scalar')
                end
                % Skew Tides
                if ~ismember(pst_options.ind_Skew, [0 1]) || isempty(pst_options.ind_Skew) || isnan(pst_options.ind_Skew) || isinf(pst_options.ind_Skew)
                    error('Input ind_Skew must be 0 or 1')
                end
                % Skew Tides Model
                if pst_options.ind_Skew==1
                    if isempty(response_data.gprMdl) || ~isobject(response_data.gprMdl)
                        error('When ind_Skew = 1: Input gprMdl cannot be an empty')
                    end
                end
            case 'Timeseries'
                % Force POT Fields To Empty
                response_data.data(:, 3) = zeros(size(response_data.data(:, 2)));
                response_data.Nyrs = [];
                response_data.SLC = 0;
                response_data.gprMdl = [];
                pst_options.ind_Skew = 0;
                % Inter-event Time Lag (hours)
                if pst_options.tLag<=0 || isempty(pst_options.tLag)
                    error('When DataType = ''Timeseries'': Input tLag cannot be an empty array and must have positive values only')
                end
                % Event Rate
                if response_data.lambda<=0 || isempty(response_data.lambda)
                    error('When DataType is set to ''Timeseries'': Input lambda cannot be an empty array and must have positive values only')
                end
            otherwise % Unrecognized Datatype
                error('Unrecognized value for DataType. Available options are ''Timeseries'' or ''POT'' ')
        end

        % ---- pst_options Fields -------
        % Bootstrap Simulations
        if ~isnumeric(pst_options.bootstrap_sims)
            pst_options.bootstrap_sims = 100;
        elseif pst_options.bootstrap_sims<100
            pst_options.bootstrap_sims = 100;
        end
        % Percentiles
        if length(pst_options.prc)>4 || all(isnan(pst_options.prc)) || all(isinf(pst_options.prc)) || any(pst_options.prc<0)
            error('Input prc can have 1 to 4 percentages in the interval [0,100].');
        elseif isempty(pst_options.('prc'))
            pst_options.('prc')=[2.28 15.87 84.13 97.72]';
        else
            pst_options.('prc') = sort(pst_options.('prc'),'ascend');
        end
        % ---- response_data Fields -------
        if isempty(response_data.data)|| size(response_data.data, 2) < 2
            error('Error: response_data.data cannot be empty. Must be a M x 2 or M x 3 data matrix.');
        end

        % ---- plot_options Fields -------
        % Response Label
        if isempty(plot_options.staID)
            plot_options.staID = 'resp';
        elseif ~ischar(plot_options.staID)
            error('Error: plot_options.staID must be a character array.')
        end
        % Y Axis Label
        if isempty(plot_options.yaxis_Label)
            plot_options.yaxis_Label = '';
        elseif ~ischar(plot_options.yaxis_Label)
            plot_options.yaxis_Label = '';
        end
        % Y Axis Limit
        if ~isnumeric(plot_options.yaxis_Limits)
            plot_options.yaxis_Limits = [];
        end
        % Output Path
        if isempty(plot_options.path_out)
            plot_options.path_out = '';
        elseif ~ischar(plot_options.path_out)
            plot_options.path_out = '';
        end
    end
    function bool_check(data_field, error_msg, member_list)
        if isempty(data_field) || ~isscalar(data_field)
            error(error_msg);
        elseif ~isnumeric(data_field) || ~ismember(data_field, member_list)
            error(error_msg);
        end
    end
end
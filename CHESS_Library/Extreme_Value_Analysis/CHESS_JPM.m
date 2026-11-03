function [JPM_output] = CHESS_JPM(response_data, jpm_options, plot_options)
% CHESS_JPM  Response hazard curves by the joint probability method.
%   JPM_output = CHESS_JPM(response_data, jpm_options, plot_options)
%
%   Joint probability method (JPM) of the CHS probabilistic coastal hazard
%   analysis (PCHA) for synthetic tropical cyclone (TC) responses: the
%   responses are sorted in descending order and the cumulative sum of
%   their discrete storm weights (DSW) gives the annual exceedance
%   frequency (AEF) of each response; the best-estimate curve and its
%   confidence limits (CL) are interpolated in log(AEF) on a plot grid, a
%   frequency table and a response table (CHESS_JPM_integration).
%   The inputs are checked first (errors for invalid fields); rows with
%   the flag value, NaN, Inf or response <= 0 are removed (error when none
%   is left). Integration methods:
%     1 PCHA ATCS (augmented TC suite, e.g. SACS, LACPR, CTXS revision):
%       the responses are used as given; with tide_application 2 and
%       ind_Skew 0 the tide uncertainty is drawn at random (rng default).
%     2 PCHA ITCS (storm suite as is, e.g. NACCS, CTXS initial): each
%       response is replicated over the 444 discrete standard normal
%       scores of the TC set (z = 0 dropped, DSW / 444), a first partition
%       of the uncertainties (0.1 absolute, 0.1 relative) is applied to
%       the response and Ua and Ur are reduced to sqrt(U^2 - 0.1^2).
%   CL curves, z = norminv(prc/100), Ut = tide_std when tide_application
%   = 1 (else 0):
%     'absolute': y + z*sqrt(Ua^2 + Ut^2)
%     'relative': y + z*y*sqrt((y*Ur)^2 + Ut^2)
%     'combined': y + z/sqrt(1/Ua^2 + 1/(y*Ur)^2 + 1/Ut^2) (the Ut term
%                 only when Ut ~= 0)
%
%   Inputs:
%     response_data - response and uncertainties, struct; fields:
%       .data       - [time, response, skew_tide, dsw], N x 4 double:
%                     column 1 event time (MATLAB datenum; not used),
%                     column 2 response without tides, column 3 skew tide
%                     (used when tide_application = 2 and ind_Skew = 1;
%                     else set to 0), column 4 discrete storm weight
%                     (probability mass) [1/yr]
%       .flag_value - response value to remove ([] = none)
%       .Ua         - absolute uncertainty [response units], scalar >= 0
%                     (set to 0 for 'relative')
%       .Ur         - relative uncertainty [-], scalar >= 0 (set to 0 for
%                     'absolute')
%       .SLC        - sea level change implicit in the response [response
%                     units], scalar >= 0 ([] = 0)
%       .tide_std   - tide standard deviation [response units], scalar > 0
%                     when tide_application = 1, or 2 with ind_Skew = 0
%                     (set to 0 otherwise)
%     jpm_options - JPM settings, struct; fields:
%       .integration_method    - 1 (PCHA ATCS) or 2 (PCHA ITCS)
%       .uncertainty_treatment - 'absolute', 'relative' or 'combined'
%       .tide_application      - 0 no tide uncertainty, 1 tide_std
%                                combined with the CL uncertainty, 2 tides
%                                added to the response (skew tides when
%                                ind_Skew = 1, else tide_std times a
%                                normal score)
%       .ind_Skew              - add the skew tides of data column 3 (0/1;
%                                forced to 0 unless tide_application = 2)
%       .use_AEP               - frequencies as AEP (1) or AEF (0)
%       .prc                   - CL percentiles [%], up to 4 values
%                                ([] = [2.28 15.87 84.13 97.72])
%       .stat_print            - clear the command window and print the
%                                progress (0/1)
%     plot_options - plot settings, struct; fields:
%       .create_plots - write the hazard curve figure and output .mat (0/1)
%       .staID        - variable name for titles and file names, char
%                       ([] = 'resp')
%       .yaxis_Label  - y axis label, char ([] = '')
%       .yaxis_Limits - y axis limits ([] = automatic)
%       .y_log        - y axis log scale flag (0/1; checked, not used by
%                       the JPM figure)
%       .path_out     - output folder, char ([] = current folder); files
%                       go in <path_out>/JPM_outputs
%   Outputs:
%     JPM_output - hazard curves, struct; fields:
%       .staID        - plot_options.staID
%       .HC_plt_x     - plot grid AEF from 1e-6 to 10 (log spaced), 631 x 1
%       .HC_plt       - response at HC_plt_x, columns [best estimate,
%                       prc CLs], 631 x (1 + numel(prc))
%       .HC_tbl_x     - table AEP 1/[2 5 10 ... 1e6] (18 values) or AEF
%                       1/[0.1 0.2 0.5 ... 1e6] (22 values)
%       .HC_tbl       - response at HC_tbl_x (same columns), negatives NaN
%       .HC_tbl_rsp_y - response levels 0.01:0.01:20, 2000 x 1
%       .HC_tbl_rsp_x - AEF (AEP when use_AEP = 1) of each HC_tbl_rsp_y
%                       level (same columns)
%   With create_plots = 1 the figure JPM_HC_<staID>_<PCHA_ATCS or
%   PCHA_ITCS>.png (CHESS_JPM_plot) is written in <path_out>/JPM_outputs.
%
%   Tier: public
%
%   See also CHESS_PST, aef2aep, aep2aef.

%% General settings
if jpm_options.stat_print == 1
    clc;
    disp(['***********************************************************' newline...
        '***         CHESS-JPM Tool Alpha Version 0.3         ***' newline...
        '***                Release 1 - 20210831                 ***' newline...
        '***                 FOR  TESTING  ONLY                  ***' newline...
        '***********************************************************']);

    disp([newline '*** Step 1: Processing input arguments ']);
end
%% PARAMETER INITIALIZATION
% Error Handeling For Inputs
[response_data, jpm_options, plot_options] = error_handling(response_data, jpm_options, plot_options);
% Define Output Path For PST
plot_options.('path_out') = fullfile(plot_options.('path_out'), 'JPM_outputs');
% Check path to output folder
if ~exist(plot_options.('path_out'), 'dir') && plot_options.create_plots == 1
    mkdir(plot_options.('path_out'));
end

%% Data preprocessing: remove NaN, inf values; compute record length
if jpm_options.stat_print == 1
    disp('*** Step 2: Verifying input datasets')
end
% Remove Flag Values
if ~isempty(response_data.('flag_value'))
    % Remove Flag Values
    response_data.data(any(response_data.data(:, 2) == response_data.('flag_value'), 2), :) = [];
end
% Merge data and remove NaN, Inf values
response_data.data(any(isinf(response_data.data(:, 2)) | isnan(response_data.data(:, 2)) | response_data.data(:, 2) <= 0, 2), :) = [];
% Ensure Timeseries Is Valid
if isempty(response_data.data) % This already covers isempty condition (length == 0)
    fail_flag = true;
else
    fail_flag = false;
end
% Abort PST Based On Data
if fail_flag
    % Abort PST Processing
    error('Error: Could not process dataset because invalid response removal yielded empty data structure.');
end

%% Check number of virtual gauges and partition the inputs if necessary
if jpm_options.stat_print == 1
    % Perform integration
    disp('*** Step 3: Performing integration')
end
%
JPM_output = CHESS_JPM_integration(response_data, jpm_options, plot_options);
% Plot hazard curves
if plot_options.create_plots == 1
    if jpm_options.stat_print == 1
        disp('*** Step 3: Plotting hazard curves');
    end
    CHESS_JPM_plot(JPM_output, jpm_options, plot_options);
    % Store output
    if jpm_options.stat_print == 1
        disp(['*** Step 4: Saving results here: ',path_out]);
    end
    save([plot_options.('path_out'), 'CHESS_JPM_' plot_options.staID 'output.mat'],'JPM_output','-v7.3');
end


if jpm_options.stat_print == 1
    disp('*** Evaluation finished.');
    disp('*** CHESS-JPM Tool terminated.');
end

%% AUXIALIARY FUNCTIONS (ERROR HANDELING)
    function [response_data, jpm_options, plot_options] = error_handling(response_data, jpm_options, plot_options)
        % Response Data Matrix
        if ~isnumeric(response_data.data) || size(response_data.data, 2) ~= 4 % [ time, response, skew_tides, dsw ]
            error('Error: response_data.data must be a N x 4 numerical matrix where columns represent: [ time, response, skew_tides, dsw ]')
        end
        % Implicit SLC
        if isempty(response_data.('SLC'))
            response_data.('SLC') = 0;
        elseif length(response_data.SLC)~=1 || response_data.SLC < 0 || isnan(response_data.SLC) || isinf(response_data.SLC)
            error('Error: response_data.SLC must be a positive scalar');
        end
        % Define Boolean Fields To Inspect
        field_to_check = ["jpm_options.use_AEP","plot_options.create_plots",...
            "plot_options.y_log", "jpm_options.stat_print",...
            "jpm_options.ind_Skew", "jpm_options.integration_method"];
        % Define Error Message To Append
        error_msg = ["0 (AEF) or 1 (AEP)", "0 (no plots) or 1 (all plots)",...
            "0 (linear y-scale) or 1 (log y-scale)", "0 (no code progress print) or 1 (print code progress)",...
            "0 (use tide std) or 1 (use skew tides)", "1 (PCHA ATCS) or 2 (PCHA ITCS)"];
        % Define Member List To Check Per Field
        member_list = [repmat([0, 1], 5, 1);[1, 2]];
        % Loop Across Fields To Check
        for kk = 1:length(field_to_check)
            % Build Error String
            error_str = "Error: " + field_to_check(kk) + " must be " + error_msg(kk) + ".";
            % Call Bool Check Function
            bool_check(eval(field_to_check(kk)), error_str, member_list(kk, :));
        end
        % Verify Tidal Application Case And Inputs
        switch jpm_options.tide_application
            case 0 % No tides
                % Force Tidal STD To Zero
                response_data.tide_std = 0;
                % Force Skew Tide Column To Zero
                response_data.data(:, 3) = 0;
                % Set Skew Tides Switch To 0
                jpm_options.ind_Skew = 0;
            case 1 % Tides Added as Uncertainty To Confidence Limits
                % Check Standard Deviation Value
                if ~isnumeric(response_data.tide_std) ||  ~isscalar(response_data.tide_std) || any(response_data.tide_std<=0)
                    error('Error: Tides standard deviation must be a positive scalar value.');
                end
                % Force Skew Tide Column To Zero
                response_data.data(:, 3) = 0;
                % Set Skew Tides Switch To 0
                jpm_options.ind_Skew = 0;
            case 2 % Tides Added To Response
                if jpm_options.ind_Skew == 1
                    % Check Skew Tides
                    if any(isinf(response_data.data(:, 3))) || any(isnan(response_data.data(:, 3)))
                        error('Error: response_data.data(:, 3) (Skew tides) must be non-inf or non-nan values.');
                    end
                    % Force Tidal STD To Zero
                    response_data.tide_std = 0;
                else
                    % Check Standard Deviation Value
                    if ~isnumeric(response_data.tide_std) ||  ~isscalar(response_data.tide_std) || any(response_data.tide_std<=0)
                        error('Error: response_data.tide_std must be a positive scalar value.');
                    end
                    % Force Skew Tide Column To Zero
                    response_data.data(:, 3) = 0;
                end
        end
        % Verify Uncertainty Treatment Method
        switch jpm_options.uncertainty_treatment
            case 'combined'
                % Pass
            case 'relative'
                % Set Absolute Component To Zero
                response_data.Ua = 0;
            case 'absolute'
                % Set Relative Component To Zero
                response_data.Ur = 0;
            otherwise
                error('Error: response_data.uncertainty_treatment must be: ''combined'', ''relative'', ''absolute''');
        end
        % Verify Uncertainty Values
        if ~isnumeric(response_data.Ur) || any(response_data.Ur<0) || ~isscalar(response_data.Ur)
            error('Error: response_data.Ur must be a positive scalar.');
        end
        if ~isnumeric(response_data.Ua) || any(response_data.Ua<0) || ~isscalar(response_data.Ua)
            error('Error: response_data.Ua must be a positive scalar.');
        end
        % Percentiles
        if length(jpm_options.prc)>4 || any(isnan(jpm_options.prc)) || any(isinf(jpm_options.prc)) || any(jpm_options.prc<0)
            error('Error: jpm_options.prc can have 1 to 4 percentages in the interval [0, 100].');
        elseif isempty(jpm_options.('prc'))
            jpm_options.('prc')=[2.28 15.87 84.13 97.72]';
        else
            jpm_options.('prc') = reshape(sort(jpm_options.('prc'),'ascend'), 1, []);
        end
        % ---- plot_options Fields -------
        % Response Label
        if isempty(plot_options.staID)
            plot_options.staID = 'resp';
        elseif ~ischar(plot_options.staID)
            error('Error: plot_options.staID be a character array.')
        end
        % Y Axis Label
        if isempty(plot_options.yaxis_Label)
            plot_options.yaxis_Label = '';
        elseif ~ischar(plot_options.yaxis_Label)
            plot_options.yaxis_Limits = '';
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
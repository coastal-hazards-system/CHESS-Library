classdef ProbabilisticSimulationTechnique < chess.ExtremeValueAnalysis
    % ProbabilisticSimulationTechnique  Response hazard curves by peaks-over-threshold statistics (PST).
    %   pst = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique(name, value, ...)
    %   [hazard, pst] = pst.compute_hazard(response)
    %   x_grid = pst.exceedance_at_grid(levels)
    %
    %   A generalized Pareto distribution is fitted above a threshold chosen
    %   on the mean residual life table and the fit is bootstrapped; below
    %   the threshold the curve is empirical. The fitted object keeps the
    %   untrimmed plot curve (HC_plt at its AEFs), from which
    %   exceedance_at_grid inverts the curve at any response levels.
    %
    %   See also chess.ExtremeValueAnalysis,
    %   chess.ExtremeValueAnalysis.JointProbabilityMethod.

    properties
        data_type = 'POT'               % 'POT' (response = peaks over threshold) or 'Timeseries'
        record_years = []               % record length [years] (data_type 'POT')
        event_rate = []                 % target events per year (data_type 'Timeseries')
        time_lag_hours = 0              % inter-event time [hours] (data_type 'Timeseries')
        threshold_criterion = 2         % GPD threshold selection: 1 = sample intensity, 2 = weighted mean square error
        apply_gpd_to_small_sample = 1   % 1 = force the GPD fit, 0 = empirical curve for small samples
        bootstrap_simulations = 100     % number of bootstrap simulations (at least 100)
        use_skew_tides = 0              % 1 = skew tides through skew_tide_model
        skew_tide_model = []            % regression model of the skew tide (use_skew_tides = 1)
    end

    methods
        function obj = ProbabilisticSimulationTechnique(varargin)
            % ProbabilisticSimulationTechnique  Create the method with its settings as name-value pairs (property names).
            %   obj = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique(name, value, ...)
            obj@chess.ExtremeValueAnalysis(varargin{:});
        end

        function [hazard, obj] = compute_hazard(obj, response, time, response_with_tides, label)
            % compute_hazard  Hazard curve of a response by the PST fit.
            %   [hazard, pst] = pst.compute_hazard(response)
            %   [hazard, pst] = pst.compute_hazard(response, time, response_with_tides, label)
            %   Inputs:
            %     response            - peaks over threshold (data_type 'POT') or
            %                           the response series ('Timeseries'), vector
            %     time                - times of response (datenum [days]);
            %                           needed for 'Timeseries' (optional for
            %                           'POT', default zeros)
            %     response_with_tides - peaks with tides (use_skew_tides = 1;
            %                           optional, default zeros)
            %     label               - response name used in titles and file
            %                           names (optional, default 'resp')
            %   Outputs:
            %     hazard - struct: staID, RL (record length), POT, MRL_output,
            %              HC_plt (best estimate and confidence limits at
            %              HC_plt_x), HC_tbl (at HC_tbl_x), HC_emp (empirical
            %              curve), Warning, ME (fit error, [] when the fit
            %              worked); HC_plt_x from
            %              chess.ExtremeValueAnalysis.hazard_plot_frequencies,
            %              HC_tbl_x from
            %              chess.ExtremeValueAnalysis.hazard_table_probabilities
            %     pst    - the method with the fitted plot curve
            %              (exceedance_at_grid; not fitted when ME is set)
            if nargin < 3 || isempty(time)
                time = zeros(numel(response), 1);
            end
            if nargin < 4 || isempty(response_with_tides)
                response_with_tides = zeros(numel(response), 1);
            end
            if nargin < 5
                label = '';
            end
            response_data = struct('data', [time(:), response(:), response_with_tides(:)], 'flag_value', obj.flag_value,...
                'SLC', obj.sea_level_change, 'lambda', obj.event_rate, 'Nyrs', obj.record_years,...
                'gprMdl', obj.skew_tide_model, 'DataType', obj.data_type);
            pst_options = obj.fit_settings();
            plot_options = obj.plot_settings(label);

        %% Other settings
        if pst_options.stat_print == 1
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
        [response_data, pst_options, plot_options] = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.validate_inputs(response_data, pst_options, plot_options);
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
        hazard = struct('staID','','RL',double.empty,'POT',double.empty,'MRL_output',double.empty,...
            'HC_plt',double.empty,'HC_tbl',double.empty,'HC_emp',double.empty,'Warning','','ME',cell(1));
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
            error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:emptyResponseData', 'Could not process dataset because invalid response removal yielded empty data structure.');
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
                    [POT_samp,~] = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.peaks_over_threshold(procData(:,1), procData(:,2), pst_options.tLag, response_data.lambda, response_data.Nyrs); % [ timestamp, event_peak, lower_bound, upper_bound ]
                case 'POT'
                    POT_samp = procData; % [ timestamp, event_peak, event_peak_with_tide ]
            end
            %%% Add noise to duplicates in POT sample - LAA 2023/12/07
            [~, w]=unique(POT_samp(:,2),'stable');
            duplicate_indices=setdiff(1:numel(POT_samp(:,2)), w);
            POT_samp(duplicate_indices, 2) = POT_samp(duplicate_indices, 2) + 1e-6;
            %%%
            % Execute CHESS-SST-Fit
            [hazard] = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.bootstrap_fit(POT_samp(:, 2), POT_samp(:, 3), response_data.SLC, response_data.Nyrs, response_data.gprMdl, pst_options, plot_options);
            hazard.ME = [];
            % Untrimmed Plot Curve (AEF) Of The Response Inversion (exceedance_at_grid)
            obj.fitted_aef = chess.ExtremeValueAnalysis.hazard_plot_frequencies();
            obj.fitted_response = hazard.HC_plt;
            % Plot results
            if plot_options.create_plots == 1
                obj.plot_hazard_curve(hazard);
            end
        catch ME
            hazard.staID = plot_options.staID;
            hazard.ME = ME;
        end

        %% Save the output
        if pst_options.stat_print == 1
            disp(['*** Step 4: Saving results here: ',plot_options.path_out]);
        end
        % Save Output
        if plot_options.create_plots == 1
            save(fullfile(plot_options.('path_out'), ['CHESS_' hazard.staID '_SST_output.mat']), 'hazard', '-v7.3');
        end
        if pst_options.stat_print == 1
            disp('*** Evaluation finished.' )
            disp(['****** Remember to check outputs Check_datasets and Removed_datasets.' newline])
            disp('*** CHESS-SST Tool terminated.')
        end
        end

        function plot_hazard_curve(obj, hazard)
            % plot_hazard_curve  Save the figures of a PST hazard curve.
            %   pst.plot_hazard_curve(hazard) writes the figures under
            %   <output_folder>/PST_outputs.
            pst_options = obj.fit_settings();
            if isempty(pst_options.prc)
                pst_options.prc = obj.DEFAULT_CONFIDENCE_LIMITS';
            end
            pst_options.prc = sort(pst_options.prc, 'ascend');
            plot_options = obj.plot_settings(hazard.staID);
            plot_options.path_out = fullfile(plot_options.path_out, 'PST_outputs');
            if ~exist(plot_options.path_out, 'dir')
                mkdir(plot_options.path_out);
            end
        % Colors for percentiles plots
        cs={'r-.','b--','b--','r-.'};
        prc=round(pst_options.prc);

        %% PLOT MEAN RESIDUAL LIFE RESULTS
        % plot these only when the GPD fit occurred
        if ~strcmp(hazard.MRL_output.Selection.Criterion{:},'None')
            % Define Inputs
            MRL_output = hazard.MRL_output; % Grab MRL Data Structure
            mrl = MRL_output.Summary; % MRL Results Summary
            TH = MRL_output.Selection.Threshold; % Threshold Selected
            crit = MRL_output.Selection.Criterion; % Specified Criterion
            % Define Subplot Properties
            line_colors = {'-g','-m','-k','-b','-r'}; % Line Colors
            field_to_plot = {'Rate', 'WMSE', 'MeanExcess', 'GPD_Shape', 'GPD_Scale'}; % MRL Fields
            y_labels = [{'Events';'per year'}, {'Weighted';'MSE'}, {'Mean';'Excess'}, ...
                {'Shape';'Parameter'}, {'Scale';'Parameter'}]; % Subplot Y Labels
            % Plot MRL Parameters If Available
            if strcmp(MRL_output.Status,'')
                % Intialize Figure
                fig=figure('units','inches','Position',[1 1 6 6],'Color',[1 1 1],'visible','off');
                % Title
                title({'CHESS-SST - Mean Residual Life';['Station: ',hazard.staID]},'FontSize',12);
                % Set Base Axes Properties
                axes('XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12);
                % Plot Each Axis
                for ii = 1:5
                    % Define Subplot Axis (Threshold)
                    ax1 = subplot(5,1,ii);
                    % Hold Properties
                    hold(ax1, 'on');
                    % Format Y Axis
                    ylim(ax1, [round(min(mrl.(field_to_plot{ii}))-0.01,2) round(max(mrl.(field_to_plot{ii}))+0.01,2)]);
                    ylabel(ax1, y_labels(ii), 'FontSize', 12);
                    % Plot MRL Rate Curve
                    plot(mrl.Threshold, mrl.(field_to_plot{ii}), line_colors{ii}, 'LineWidth', 2);
                    % Plot Resulting Threshold
                    if ~isempty(TH)
                        h = xline(ax1, TH, 'k:', 'LineWidth', 2);
                        if ii == 1
                            legend(h, crit, 'Location', 'NorthEast');
                        end
                    end
                    % Turn Off Hold On Properties
                    hold(ax1, "off");
                end
                % Save Out Figure
                fname = fullfile(plot_options.path_out, ['SST_','MRL_',hazard.staID,'.png']);
                saveas(gcf, fname);
                close(fig);
            end

            %% PLOT GPD PARAMETERS FOR BOOTSTRAPING
            % Get Mean GPD Parameters
            mn_k = mean(MRL_output.pd_k_wOut,1,'omitnan');
            mn_k2 = mean(MRL_output.pd_k_mod,1,'omitnan');
            % Define Threshold Criterion String
            switch hazard.MRL_output.Selection.Criterion{:}
                case 'CritWMSE'
                    str = 'WMSE Criterion';
                case 'CritSI'
                    str = 'Sample Intensity Criterion';
                case 'Default'
                    str = 'Default';
                otherwise
                    str = 'None';
            end
            % Intialize Figure
            fig=figure('Color','w','visible','off');
            % Initialize & Format Axes
            ax = gca;
            xlabel(ax, ['GPD Shape Parameter - MRL Threshold - ' str], 'FontSize', 12);
            ylabel(ax, 'Count', 'FontSize', 12);
            % Hold Properties
            hold(ax, "on");
            % Plot Distirbution
            h1 = histogram(ax, MRL_output.pd_k_wOut,'BinWidth',.05,'FaceColor','b'); %original
            h2 = histogram(ax, MRL_output.pd_k_mod,'BinWidth',.05,'FaceColor','r'); %w/outliers filled
            % Plot Mean
            m1 = xline(ax, mn_k, 'b-', 'LineWidth', 2);
            m2 = xline(ax, mn_k2, 'r-', 'LineWidth', 2);
            % Add Legend
            legend([h1, h2, m1, m2],{'hist w/outliers','hist w/o outliers','mean w/outliers',...
                'mean w/o outliers'}, 'Location', 'northwest', 'FontSize', 8);
            % Save Out Figure
            fname = fullfile(plot_options.path_out, ['SST_CompareGPDShape_',hazard.staID,'.png']);
            saveas(gcf, fname)
            close(fig);
        end

        %% PLOT HAZARD CURVES
        % Initialize Figures
        fig=figure('Color',[1 1 1],'visible','off');
        % Intialize Axes
        ax = axes('xscale','log','XGrid','on','XMinorTick','on',...
            'YGrid','on','YMinorTick','on',...
            'XDir', 'reverse', 'FontSize', 12);
        % Hold Properties
        hold(ax, 'on');
        % Title
        title({'CHESS-SST '; ['Station: ',hazard.staID]}, 'FontSize',12);
        % Format X Axis
        if pst_options.use_AEP == 1
            xlim(ax, [1e-6 1]);
            XTick=[1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1];
            xlabel('Annual Exceedance Probability','FontSize',12);
        else
            xlim(ax, [1e-6 10]);
            XTick=[1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10];
            xlabel('Annual Exceedance Frequency (yr^{-1})','FontSize',12);
        end
        set(ax, 'XTick', XTick);
        % Format Y Axis
        if ~isempty(plot_options.yaxis_Limits)
            ylim(plot_options.yaxis_Limits);
        end
        ylabel(plot_options.yaxis_Label, 'FontSize', 12);
        % Process the percentiles
        pObj=struct('o',[],'n',[],'L','');
        for i=2:length(prc)+1 % First Row Is Mean
            pObj(i-1).o = plot(ax, hazard.HC_plt_x, hazard.HC_plt(:, i), cs{i-1}, 'LineWidth', 2);
            pObj(i-1).n = prc(i-1);
            pObj(i-1).L = {['CL',int2str(prc(i-1)),'%']};
        end
        pObj_t = struct2table(pObj);
        pObj_t = sortrows(pObj_t,'n','descend'); % sort the table by 'n'

        % Take percentiles
        t1 = pObj_t(pObj_t.n>50,:); t1 = table2struct(t1); %above the mean
        t2 = pObj_t(pObj_t.n<50,:); t2 = table2struct(t2); %below the mean

        % Mean and Empirical
        h1 = plot(ax, hazard.HC_plt_x, hazard.HC_plt(:, 1), 'k-', 'LineWidth', 2); % Mean
        h2 = scatter(ax, hazard.HC_emp.Hazard, hazard.HC_emp.Response, 10, 'g','filled','MarkerEdgeColor','k'); % Historical
        % Legend
        legend([[t1.o],h1,[t2.o],h2],{t1.L,'Mean',t2.L,'Empirical'},...
            'Location','southoutside','Orientation','horizontal','NumColumns',5,'FontSize',10);
        % Filename
        fname = fullfile(plot_options.path_out,...
            ['SST_','HC_',hazard.staID,'_TH_' hazard.MRL_output.Selection.Criterion{:} '.png']);
        % Save figure
        saveas(fig,fname)
        close(fig);
        end
    end

    methods (Static)
        function [POTout,Threshold] = peaks_over_threshold(dt,Resp,tLag,lambda,Nyrs)
            % peaks_over_threshold  Peaks over threshold of a response time series.
            %   [peaks, threshold] = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.peaks_over_threshold(
            %       time, response, time_lag_hours, event_rate, record_years)
            %   The threshold (mean + multiplier*std) is raised until the number
            %   of events is at most record_years*event_rate; events closer than
            %   time_lag_hours belong to the same storm.
            %   Inputs:
            %     time           - times of the series (datenum [days]), vector
            %     response       - response series, same size as time
            %     time_lag_hours - inter-event time [hours]
            %     event_rate     - target number of events per year
            %     record_years   - record length [years]
            %   Outputs:
            %     peaks     - [time of the peak, peak, first time, last time]
            %                 per event
            %     threshold - threshold used

        % LICENSING:
        %     This code is part of CHESS software suite developed by the U.S. Army
        %     Engineer Research and Development Center Coastal and Hydraulics
        %     Laboratory (hereinafter “ERDC-CHL”). This material is distributed in
        %     accordance with DoD Instruction 5230.24. Recipient agrees to abide by
        %     all notices, and distribution and license markings. The controlling DOD
        %     office is the U.S. Army Engineer Research and Development Center
        %     (hereinafter, "ERDC"). This material shall be handled and maintained in
        %     accordance with For Official Use Only, Export Control, and AR 380-19
        %     requirements. ERDC-CHL retains all right, title and interest in
        %     CHESS and any portion thereof and in all copies, modifications and
        %     derivative works of CHESS and any portions thereof including,
        %     without limitation, all rights to patent, copyright, trade secret,
        %     trademark and other proprietary or intellectual property rights.
        %     Recipient has no rights, by license or otherwise, to use, disclose or
        %     disseminate CHESS, in whole or in part.
        %
        % DISCLAIMER:
        %     CHESS IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT
        %     HOLDERS. ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS
        %     OR IMPLIED WITH RESPECT TO CHESS OR ANYTHING PROVIDED BY ERDC-CHL,
        %     AND EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, EITHER EXPRESSED OR
        %     IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF MERCHANTABILITY,
        %     NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
        %     CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE
        %     AND RESULTS OF THE USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE
        %     UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL WARRANTIES AND LIABILITIES
        %     REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN CHESS, AND DISTRIBUTES
        %     IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST
        %     ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND
        %     SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD HARMLESS ERDC-CHL, THE
        %     UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
        %     LIABILITIES, DEMANDS, DAMAGES.
        %
        % SOFTWARE NAME:
        %     CHESS-POT (Statistics)
        %
        % CONTRIBUTORS:
        %     ERDC-CHL Coastal Hazards Group
        %
        % HISTORY OF REVISIONS:
        % 20200903-ERS: revised.
        % 20200914-ERS: revised.
        % 20231207-LAA: Revised to add noice to duplicate values in POT sample.
        %
        % ***************  ALPHA  VERSION  ***************  FOR TESTING  ************
        %% A few check points

        % Required input
        if nargin<5
            error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:wrongInputCount', 'Missing input arguments: Received less than 5 input arguments.');
        elseif nargin>5
            error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:wrongInputCount', 'Too many input arguments: Function only requires 5 input arguments.');
        end

        % Reformat some inputs
        if isrow(dt),dt=dt';end
        if isrow(Resp),Resp=Resp';end

        %% Set default and compute additional parameters
        thMult = 1; %Default = 1; If threshold multiplier is set too low (e.g., ~0)
        % an almost continuous time series will be created in Resp(index), with
        % dLag <=48 hr and very few peaks will be identified

        Nstm = 100000;
        Resp_avg = mean(Resp); %arithmetic mean of response
        Resp_std = std(Resp); %standard deviation of response
        tLag = chess.Common.chess_units('convert', tLag, 'h', 'day');  %Convert inter-event time from hours to days

        %% Determine the threshold that yields a required amount of peak response events
        while Nstm > (Nyrs*lambda)
    
            % Compute threshold and identify response values above it
            Threshold = Resp_avg + Resp_std*thMult;
            index = find(Resp >= Threshold);
    
            % Take corresponding time values
            dt2 = dt(index);
    
            % Compute sample inter-event times
            dt2 = [1;diff(dt2)<=tLag;0];
    
            % Identify inter-event times longer than tLag
            id = find(dt2==0);
    
            % Compute amount of resulting events and increase the multiplier
            Nstm = length(id);
            thMult = thMult + 0.01;
        end

        %% Classify the response values

        % NOTE:
        %   stm_col has data indices; Resp_peak has response values; each column
        %   has response events inside a time segment defined by the inter-event
        %   time

        stm_col = NaN(length(dt2),length(id));
        stm_col(1:id(1)-1,1) = index(1:id(1)-1);
        Resp_peak = NaN(length(dt2),length(id));
        Resp_peak(1:id(1)-1,1) = Resp(index(1:id(1)-1));

        for k = 2:length(id)
            id2 = id(k-1):id(k)-1;
            stm_col(id2-(id(k-1)-1),k) = index(id2);
            Resp_peak(id2-(id(k-1)-1),k) = Resp(index(id2));
        end

        %% Extract peak response value for each event
        [Pk_val,I] = max(Resp_peak,[],1,'omitnan');

        %% Locate events inside arrays
        ParINDEX = NaN(length(I),3);
        for i=1:Nstm
            ParINDEX(i,1) = stm_col(I(i),i);
        end
        ParINDEX(:,2) = min(stm_col,[],1,'omitnan')';
        ParINDEX(:,3) = max(stm_col,[],1,'omitnan')';

        %% Extract timestamps of peak events and store results for output
        POTout = dt(ParINDEX(:,1),1); %timestamp of peak event
        POTout(:,2) = Pk_val'; %peak event

        % Data time range used for selection of POT value:
        POTout(:,3) = dt(ParINDEX(:,2),1); %lower bound
        POTout(:,4) = dt(ParINDEX(:,3),1); %upper bound

        %% Remove NaN / Inf / negative values
        POTout(isnan(POTout(:,2))|isinf(POTout(:,2))|POTout(:,2)<=0,:)=[];

        %% Add noise to duplicates in POT sample - LAA 2023/12/07
        [~,w]=unique(POTout,'stable');
        duplicate_indices=setdiff(1:numel(POTout),w);
        POTout(duplicate_indices)=POTout(duplicate_indices)+1e-6;
        %%

        end
    end

    methods (Access = private)
        function pst_options = fit_settings(obj)
            % Settings in the layout used by the fit code
            pst_options = struct('ind_Skew', obj.use_skew_tides, 'use_AEP', obj.use_aep, 'prc', obj.confidence_limits,...
                'stat_print', obj.print_progress, 'tLag', obj.time_lag_hours, 'GPD_TH_crit', obj.threshold_criterion,...
                'apply_GPD_to_SS', obj.apply_gpd_to_small_sample, 'bootstrap_sims', obj.bootstrap_simulations);
        end
    end

    methods (Static, Access = private)
        function [response_data, pst_options, plot_options] = validate_inputs(response_data, pst_options, plot_options)
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
                error_str = field_to_check(kk) + " must be " + error_msg(kk) + ".";
                % Call Bool Check Function
                chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.check_choice(eval(field_to_check(kk)), error_str, member_list(kk, :));
            end
            % Datatype Specific Errors
            switch response_data.DataType
                case 'POT'
                    % Force Timeseries Fields To Empty
                    pst_options.tLag = [];
                    response_data.lambda = [];
                    % Number Of Years
                    if response_data.Nyrs<=0 || isempty(response_data.Nyrs)
                        error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidNyrs', 'When DataType is set to ''POT'': Input "Nyrs" cannot be empty and must have positive values only.');
                    end
                    % Implicit SLC
                    if isempty(response_data.('SLC'))
                        response_data.('SLC') = 0;
                    elseif length(response_data.SLC)~=1 || response_data.SLC < 0 || isnan(response_data.SLC) || isinf(response_data.SLC)
                        error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidSlc', 'Input SLC must be a positive scalar.');
                    end
                    % Skew Tides
                    if ~ismember(pst_options.ind_Skew, [0 1]) || isempty(pst_options.ind_Skew) || isnan(pst_options.ind_Skew) || isinf(pst_options.ind_Skew)
                        error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidChoice', 'Input ind_Skew must be 0 or 1.');
                    end
                    % Skew Tides Model
                    if pst_options.ind_Skew==1
                        if isempty(response_data.gprMdl) || ~isobject(response_data.gprMdl)
                            error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:missingGprModel', 'When ind_Skew = 1: Input gprMdl cannot be empty.');
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
                        error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidTimeLag', 'When DataType = ''Timeseries'': Input tLag cannot be an empty array and must have positive values only.');
                    end
                    % Event Rate
                    if response_data.lambda<=0 || isempty(response_data.lambda)
                        error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidLambda', 'When DataType is set to ''Timeseries'': Input lambda cannot be an empty array and must have positive values only.');
                    end
                otherwise % Unrecognized Datatype
                    error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:unknownDataType', 'Unrecognized value for DataType. Available options are ''Timeseries'' or ''POT''.');
            end

            % ---- pst_options Fields -------
            % Bootstrap Simulations
            if ~isnumeric(pst_options.bootstrap_sims)
                pst_options.bootstrap_sims = 100;
            elseif pst_options.bootstrap_sims<100
                pst_options.bootstrap_sims = 100;
            end
            % Percentiles
            if isempty(pst_options.('prc'))
                pst_options.('prc')=chess.ExtremeValueAnalysis.DEFAULT_CONFIDENCE_LIMITS';
            elseif length(pst_options.prc)>4 || all(isnan(pst_options.prc)) || all(isinf(pst_options.prc)) || any(pst_options.prc<0)
                error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidPercentiles', 'Input prc can have 1 to 4 percentages in the interval [0,100].');
            else
                pst_options.('prc') = sort(pst_options.('prc'),'ascend');
            end
            % ---- response_data Fields -------
            if isempty(response_data.data)|| size(response_data.data, 2) < 2
                error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidResponseData', 'response_data.data cannot be empty. Must be a M x 2 or M x 3 data matrix.');
            end

            % ---- plot_options Fields -------
            % Response Label
            if isempty(plot_options.staID)
                plot_options.staID = 'resp';
            elseif ~ischar(plot_options.staID)
                error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidStationId', 'plot_options.staID must be a character array.');
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

        function check_choice(data_field, error_msg, member_list)
            if isempty(data_field) || ~isscalar(data_field)
                error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidChoice', '%s', error_msg);
            elseif ~isnumeric(data_field) || ~ismember(data_field, member_list)
                error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:invalidChoice', '%s', error_msg);
            end
        end

        function [SST_output] = bootstrap_fit(POT_no_tides, POT_with_tides, SLC, Nyrs, gprMdl, pst_options, plot_options)
        % bootstrap_fit  Bootstrap GPD fit of a POT sample into hazard curves.
        %   SST_output = bootstrap_fit(POT_no_tides, POT_with_tides, SLC, Nyrs,
        %       gprMdl, pst_options, plot_options)
        %
        %   Fit step of chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique (inputs already checked there).
        %   Empirical curve: Weibull plotting position m/(n+1) times the sample
        %   intensity n/Nyrs (AEF). Bootstrap
        %   (ecdf_boot, bootstrap_sims samples); with ind_Skew = 1 and a gprMdl
        %   object, skew tides predicted by gprMdl (mean plus a random normal
        %   times the standard deviation) are added to each sample of the surge
        %   minus SLC, SLC is added back and the empirical curve uses
        %   POT_with_tides. Values < 0 are set to NaN.
        %   GPD (when the sample has >= 20 events and Nyrs >= 20 years, or
        %   apply_GPD_to_SS = 1): threshold from gpd_threshold_selection (GPD_TH_crit); without
        %   one, 0.99 times the minimum of each bootstrap sample ('Default'). The
        %   GPD is fitted to each bootstrap sample above the threshold with the
        %   shape limited to [-0.5 0.3], and each simulated curve joins the GPD
        %   above the threshold and the empirical values below. Otherwise each
        %   bootstrap sample gives an empirical curve.
        %   The mean and the prc percentiles of the simulated curves are made
        %   monotonic (monotonic_adjustment) and interpolated into the tables.
        %   Everything is computed in AEF; with use_AEP = 1 the AEP table is read
        %   at its AEF (chess.ExtremeValueAnalysis.aep_to_aef) and HC_plt_x and the HC_emp Hazard
        %   column are converted to AEP (chess.ExtremeValueAnalysis.aef_to_aep) at the end.
        %   Errors when ind_Skew = 1 and the mean curve reaches 1e3. With
        %   create_plots = 1 and a GPD fit, the bootstrap check figure
        %   SST_HC_bootCheck_<staID>_TH_<criterion>.png is written in path_out.
        %
        %   Inputs:
        %     POT_no_tides   - POT sample without tides, vector
        %     POT_with_tides - POT sample with tides (used with ind_Skew = 1),
        %                      vector
        %     SLC            - sea level change implicit in the sample [response
        %                      units], scalar
        %     Nyrs           - record length [years], scalar
        %     gprMdl         - skew tide Gaussian process regression model ([]
        %                      without skew tides)
        %     pst_options    - PST settings (use_AEP, bootstrap_sims, ind_Skew,
        %                      GPD_TH_crit, apply_GPD_to_SS, prc; see chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique),
        %                      struct
        %     plot_options   - plot settings (create_plots, y_log, staID,
        %                      yaxis_Limits, yaxis_Label, path_out), struct
        %   Outputs:
        %     SST_output - hazard curves (staID, RL, MRL_output, HC_plt, HC_tbl,
        %                  HC_emp, HC_plt_x, HC_tbl_x; HC_plt_x from
        %                  chess.ExtremeValueAnalysis.hazard_plot_frequencies, HC_tbl_x from
        %                  chess.ExtremeValueAnalysis.hazard_table_probabilities;
        %                  see chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique), struct; also:
        %                    .POT     - POT sample without tides, sorted in
        %                               descending order
        %                    .Warning - '' or the warning that the best estimate
        %                               at 0.1 AEF/AEP exceeds 1.75 times the
        %                               empirical curve, char
        %                  MRL_output.Status keeps the reason of a default
        %                  threshold or of a GPD not fitted ('' otherwise).
        %
        %   See also chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique, chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.plot_hazard_curve, gpd_threshold_selection, ecdf_boot,
        %   monotonic_adjustment.

        %% INITIALIZE FIELDS
        % Set up probabilities and responses for HC summary
        HC_tbl_x = chess.ExtremeValueAnalysis.hazard_table_probabilities(pst_options.use_AEP);
        % The Curves Are Computed In AEF; AEP Tables Are Read At Their AEF And The x Outputs Converted At The End
        if pst_options.use_AEP
            to_aef = @chess.ExtremeValueAnalysis.aep_to_aef;
        else
            to_aef = @(x) x;
        end
        % Set up AEFs for full HC; in log10 scale (for plotting), from 10^1 to 10^-6
        HC_plt_x = chess.ExtremeValueAnalysis.hazard_plot_frequencies();
        % Sort POT sample in descending order
        POT_no_tides = sort(POT_no_tides, 'descend');
        HC_emp = POT_no_tides; % Response vector sorted in descending order; positive values only
        % Pre-Allocate Output Fields
        Resp_boot_plt = NaN(pst_options.bootstrap_sims, length(HC_plt_x)); % Nsims x Events
        pd_k_wOut = NaN(pst_options.bootstrap_sims, 1); % Nsims x 1
        pd_sigma = pd_k_wOut; % Nsims x 1
        pd_TH_wOut = pd_k_wOut; % Nsims x 1
        pd_k_mod = pd_k_wOut; % Nsims x 1


        %% Develop empirical CDF (using output of POT function)
        % Weibull Plotting Position, P = m/(n+1)
        % where P = Exceedance probability
        %       m = rank of descending response values, with largest equal to 1
        %       n = number of response values
        Nstrm_hist = length(HC_emp); % Weibull's "n"
        HC_emp(:, 2) = (1:Nstrm_hist)'; %Rank of descending response values
        HC_emp(:, 3) = HC_emp(:,2)/(Nstrm_hist+1); %Webull's "P"; NEEDS Lambda Correction

        % Lambda Correction - Required for Partial Duration Series (PDS)
        Lambda_hist = Nstrm_hist/Nyrs; % Lambda = sample intensity = events/year
        HC_emp(:, 4) = HC_emp(:, 3)*Lambda_hist;

        % Compute Annual Recurrence Interval (ARI)
        HC_emp(:, 5) = 1./HC_emp(:, 4);
        ecdf_y = HC_emp(:, 1);

        %% Perform bootstrap
        % Skew Tides Bootstrap
        if  pst_options.ind_Skew && ~isempty(POT_with_tides) && isobject(gprMdl)
            % Substract Implicit SLC From Empirical Sample
            ecdf_y = ecdf_y - SLC;
            % Perform Bootstraping
            boot = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.ecdf_boot(ecdf_y, pst_options.bootstrap_sims)'; % N events x N sims
            % Compute and add skew tides to bootstrap sample or surge
            for i = 1:pst_options.bootstrap_sims
                % Predict Skew Tide With Provided Metamodel For Each Sim
                [skew_tide_mean, skew_tide_sd] = predict(gprMdl, boot(:, i));
                % Add Tide Uncertainty To Predicted Value
                skew_tide_pred = skew_tide_mean + randn(length(skew_tide_mean), 1).*skew_tide_sd;
                % Add Skew Tide To Surge
                boot(:, i) = boot(:, i) + skew_tide_pred; %this is water level
                % Rank Response
                boot(:, i) = sort(boot(:, i), 'descend');
            end
            % Add the SLC amount
            boot = boot + SLC;
            %Substitute the empirical dist with user supplied surge + tides + SLC (WL)
            ecdf_y = sort(POT_with_tides, 'descend'); %Sort POT sample in descending order
            % Reshape , Why ?
            szH = size(HC_emp, 1); szy = length(ecdf_y);
            if szH>szy
                HC_emp = HC_emp(1:szy, :);
            elseif szH<szy
                ecdf_y = ecdf_y(1:szH);
            end
            HC_emp(:, 1) = ecdf_y;
            boot = boot(1:length(ecdf_y), :);
        else
            % Response Bootstrap
            boot = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.ecdf_boot(ecdf_y, pst_options.bootstrap_sims)';
        end
        % Dealing With Extreme Values, Remove <0 Values
        boot(boot<0) = NaN;
        % Verify For Applicability Of GPD Fitting
        gpd_pass = (length(ecdf_y)>=20 && Nyrs>=20) || pst_options.apply_GPD_to_SS;

        %% Apply the GPD when empirical POT sample size is >20 and RL >20 yrs. Otherwise, compute HC using empirical.
        if gpd_pass %apply GPD
            %% Apply "Mean Residual Life" Automated Threshold Detection
            MRL_output = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.gpd_threshold_selection(pst_options.GPD_TH_crit, ecdf_y, Nyrs);

            %% MRL GPD Threshold condition
            mrl_th = MRL_output.Selection.Threshold;

            %% Take parameters and preallocate
            ecdf_x_adj=HC_emp(:,4);

            %% Perform SST
            % If the MRL didn't returned a threshold value, compute it from the
            % bootstrap samples. Then identify the peaks.
            if isnan(mrl_th)
                sz = size(boot,1); %total events above threshold per simulation
                idx = ones(sz, pst_options.bootstrap_sims)==1; %index of events above threshold per simulation
                idx2 = zeros(sz, pst_options.bootstrap_sims)==1; %index of events below threshold per simulation
                sz = repmat(sz,1, pst_options.bootstrap_sims);
                mrl_th = 0.99*min(boot,[],1,'omitnan');
                MRL_output.Selection.Threshold = mean(mrl_th,'omitnan');
                MRL_output.Selection.Criterion = {'Default'};
                eMsg = 'No threshold found by MRL method. Default criterion applied: GPD threshold set to 0.99 times the minimum value of the bootstrap sample.';
            else
                idx = boot>mrl_th; %index of events above threshold per simulation
                sz = sum(idx,1); %total events above threshold per simulation
                idx2 = boot<=mrl_th; %index of events below threshold per simulation
                mrl_th = repmat(mrl_th,1,pst_options.bootstrap_sims);
                eMsg ='';
            end
            Lambda_mrl = sz/Nyrs; %annual rate of events

            % GPD fitting
            for k = 1:pst_options.bootstrap_sims
                try
                    PEAKS_rnd = boot(:,k);

                    % Fit the GPD to a bootrap data sample
                    u = PEAKS_rnd(idx(:,k));
                    pd = fitdist(u,'GeneralizedPareto','theta',mrl_th(k));
                    pd_TH_wOut(k,1) = pd.theta;
                    pd_k_wOut(k,1) = pd.k;
                    pd_sigma(k,1) = pd.sigma;
                catch
                end
            end

            % Correction of GPD shape parameter values. Limits determined by NCNC.
            pd_k_mod=pd_k_wOut;
            k_min=-0.5; k_max=0.3;
            pd_k_mod(pd_k_mod<k_min) = k_min;
            pd_k_mod(pd_k_mod>k_max) = k_max;
        else
            eMsg = 'GPD not fit: POT sample size <20 and RL <20 years.';
        end

        %% COMPUTE HC
        for k = 1:pst_options.bootstrap_sims
            % Build HC With GPD If Conditions Met
            if gpd_pass
                try
                    % Get POT Smaple From Bootsrap Simulations
                    PEAKS_rnd = boot(:, k);
                    % Compute the AEF from the GPD fit
                    Resp_gpd = icdf('Generalized Pareto', 1-HC_plt_x/Lambda_mrl(k), pd_k_mod(k,1), pd_sigma(k,1), pd_TH_wOut(k,1));
                    AEF_gpd = HC_plt_x(~isnan(Resp_gpd));
                    Resp_gpd(isnan(Resp_gpd)) = [];
                    % Compute the empirical AEF
                    Resp_ecdf = PEAKS_rnd(idx2(:, k));
                    AEF_ecdf = ecdf_x_adj(idx2(:, k));
                    % Merge the AEFs (empirical + fitted GPD)
                    y_comb = [Resp_gpd;Resp_ecdf];
                    x_comb = [AEF_gpd;AEF_ecdf];
                catch
                    % Skip bootstrap Sim
                    continue;
                end
            else % Using Empirical Only
                y_comb = boot(:,k);
                x_comb = HC_emp(:,4);
            end
            % Delete duplicates
            [~, ia, ~] = unique(x_comb, 'stable');
            x_comb = x_comb(ia, :);
            y_comb = y_comb(ia, :);

            [~, ia, ~] = unique(y_comb, 'stable');
            y_comb = y_comb(ia, :);
            x_comb = x_comb(ia, :);

            % Interpolate AEF curve for table and plot
            Resp_boot_plt(k, :) = interp1(log(x_comb), y_comb, log(HC_plt_x));
        end

        %% PLOT BOOTSTRAPING
        if gpd_pass && plot_options.create_plots
            % Initialize Figure
            fig=figure('Color',[1 1 1],'visible','off', 'Units', 'normalized','Position', [1 1 1 1]);
            %
            if plot_options.y_log == 1
                y_scale = 'log';
            else
                y_scale = 'linear';
            end
            % Initialize Axes
            ax = axes('xscale','log','YScale',y_scale,'XGrid','on','XMinorTick','on',...
                'YGrid','on','YMinorTick','on','XDir','reverse','FontSize',12);
            % hold Axes Properties
            hold(ax,'on');
            % Title
            title(ax, {'CHESS-SST '; [plot_options.staID ' Bootstrap Sample Plot']},'FontSize',12);
            % Define X Axis
            if pst_options.use_AEP == 1
                to_axis = @chess.ExtremeValueAnalysis.aef_to_aep;
                xlim(ax, [1e-6 1]);
                set(ax, 'XTick', [1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1])
                xlabel(ax, 'Annual Exceedance Probability','FontSize',12);
            else
                to_axis = @(x) x;
                xlim([1e-6 10]);
                set(ax, 'XTick', [1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10]);
                xlabel(ax, 'Annual Exceedance Frequency (yr^{-1})', 'FontSize',12);
            end
            % Define Y Axis
            if ~isempty(plot_options.yaxis_Limits)
                ylim(plot_options.yaxis_Limits);
            end
            ylabel(plot_options.yaxis_Label,'FontSize',12);
            % Historical
            scatter(to_axis(HC_emp(:,4)), ecdf_y, 15, 'g', 'filled', 'MarkerEdgeColor', 'k');
            % Resampling (last bootstrap sample)
            scatter(to_axis(HC_emp(:,4)), PEAKS_rnd, 15, 'r', 'filled', 'MarkerEdgeColor', 'k');
            % Empirical
            plot(to_axis(AEF_ecdf), Resp_ecdf, 'y-', 'LineWidth', 2);
            % MRL threshold
            th_x = to_axis(interp1(y_comb, x_comb, pd_TH_wOut(k)));
            scatter(th_x, pd_TH_wOut(k), 15, 'w', 'filled', 'MarkerEdgeColor', 'b');
            % GPD with MRL
            plot(to_axis(AEF_gpd), Resp_gpd, 'b-', 'LineWidth', 2)
            % Legend
            legend({'Historical', 'Resampling', 'Empirical', 'MRL threshold', 'GPD'},...
                'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 4, 'FontSize', 10);
            % Save Out Name
            fname = fullfile(plot_options.path_out, ['SST_HC_bootCheck_', plot_options.staID,'_TH_', MRL_output.Selection.Criterion{:},'.png']);
            % Save Figure
            saveas(fig, fname, 'png');
            % Close Figure
            close(fig);
        end

        %% Compute mean and percentiles
        Boot_mean_plt = mean(Resp_boot_plt, 1, 'includenan');
        Boot_plt = prctile(Resp_boot_plt, pst_options.prc, 1);

        %For this application only: delete results if WL >= 1e3 meters
        if pst_options.ind_Skew && max(Boot_mean_plt, [], 'omitnan')>=1e3
            error('chess:ExtremeValueAnalysis:ProbabilisticSimulationTechnique:curveAboveLimit', 'Mean hazard curve exceeds 1e3 (skew-tide fit); fit rejected.');
        end

        HC_plt = [Boot_mean_plt;Boot_plt]';

        % Monotonic adjustment
        for kk = 1:size(HC_plt,2)
            HC_plt(:, kk) = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.monotonic_adjustment(HC_plt_x, HC_plt(:, kk));
        end


        %% Interpolation to create the hazard table
        % preallocate
        HC_tbl_y = NaN(length(HC_tbl_x), size(HC_plt, 2));
        HCmn = NaN(1, size(HC_plt, 2));
        for kk = 1:size(HC_plt, 2)

            % Delete duplicates
            [~,ia,~] = unique(HC_plt(:, kk),'stable');
            dm1 = HC_plt(ia, kk); dm2 = log(HC_plt_x(ia));

            % Delete NaN/Inf
            ia = isnan(dm1) | isinf(dm1); dm1(ia) = []; dm2(ia) = [];

            % Interpolate
            HC_tbl_y(:, kk) = interp1(dm2, dm1, log(to_aef(HC_tbl_x)), 'linear', 'extrap');

            %interpol for 0.1 aep/aef
            HCmn(1, kk) = interp1(dm2, dm1, log(to_aef(0.1)), 'linear', 'extrap');
        end
        % Ensure No Duplicate Values
        [~, ia, ~] = unique(log(HC_emp(:, 4)), 'stable');
        % Compare if mean HC > 1.75* emp HC at 0.1 AEP/AEF,
        HCep = interp1(log(HC_emp(ia, 4)), HC_emp(ia, 1), log(to_aef(0.1)), 'linear', 'extrap');
        str1 = '';
        if HCmn(1) > 1.75*HCep
            str1 = 'Warning: At 0.1 AEP/AEF, best estimate HC value is greater than 1.75 times the empirical HC value. Manual verification is recommended.';
        end

        % Convert The x Outputs To AEP
        if pst_options.use_AEP
            HC_plt_x = chess.ExtremeValueAnalysis.aef_to_aep(HC_plt_x);
            HC_emp(:, 4) = chess.ExtremeValueAnalysis.aef_to_aep(HC_emp(:, 4));
        end
        % Change negatives to NaN
        HC_tbl_y(HC_tbl_y<0) = NaN;

        %% Store parameters needed for manual GPD Shape parameter evaluation
        MRL_output.pd_TH_wOut = pd_TH_wOut;
        MRL_output.pd_k_wOut = pd_k_wOut;
        MRL_output.pd_sigma = pd_sigma;
        MRL_output.pd_k_mod = pd_k_mod;
        MRL_output.Status = eMsg;
        HC_emp = array2table(HC_emp,'VariableNames',{'Response','Rank','CCDF','Hazard','ARI'});
        % Gather the output
        SST_output.staID = plot_options.staID;
        SST_output.RL = Nyrs;
        SST_output.POT = POT_no_tides;
        SST_output.MRL_output = MRL_output;
        SST_output.HC_plt = HC_plt;
        SST_output.HC_tbl = HC_tbl_y;
        SST_output.HC_emp = HC_emp;
        SST_output.HC_plt_x = HC_plt_x;
        SST_output.HC_tbl_x = HC_tbl_x;
        SST_output.Warning = str1;
        end

        function [MRL_output] = gpd_threshold_selection(GPD_TH_crit, PEAKS, Nyrs)
        % gpd_threshold_selection  GPD threshold by the mean residual life (MRL) method.
        %   MRL_output = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.gpd_threshold_selection(GPD_TH_crit, PEAKS, Nyrs)
        %
        %   Every sorted sample value (up to the 10th largest) is a candidate
        %   threshold u. For each u: mean excess e(u) and weight (number above u
        %   over the variance of the excesses); a weighted linear fit of e(u)
        %   against u over the thresholds >= u gives the weighted mean square
        %   error (WMSE) and a GPD fit above u gives the shape and scale
        %   (thresholds up to the 20th largest value). The WMSE is smoothed by a
        %   kernel local mean (kernel_regression, bandwidth = ksdensity bandwidth
        %   / 7) and its local minima are the candidates: 'CritWMSE' takes the
        %   lowest threshold, 'CritSI' the one whose rate is closest to 2
        %   events/yr (rates < 1 excluded; else the highest rate). Needs more
        %   than 20 values; with 20 or fewer, or without a local WMSE minimum,
        %   MRL_output keeps a NaN Summary row and an empty Selection criterion.
        %
        %   Inputs:
        %     GPD_TH_crit - criterion kept: 1 sample intensity ('CritSI'), 2
        %                   minimum WMSE ('CritWMSE'), scalar
        %     PEAKS       - POT sample (bootstrapped empirical responses), column
        %                   vector
        %     Nyrs        - record length [years], scalar > 0
        %   Outputs:
        %     MRL_output - threshold selection, struct; fields:
        %       .Summary   - one row per candidate threshold, table (Threshold,
        %                    MeanExcess, Weight, WMSE, GPD_Shape, GPD_Scale,
        %                    Events, Rate [1/yr])
        %       .Selection - selected threshold, 1-row table (Criterion,
        %                    Threshold, id_Summary, Events, Rate)
        %
        %   See also bootstrap_fit, kernel_regression.
        %
        %   Developed by: Norberto C. Nadal-Caraballo, PhD (NCNC); Efrain
        %   Ramos-Santiago (ERS)

        % SOFTWARE NAME:
        %     CHESS-SST-Fit (Statistics)
        %
        % HISTORY OF REVISIONS:
        % 20200903-ERS: revised.
        % 20201015-ERS: revised. Updated documentation.
        % 20201215-ERS: added break in for loop to avoid evaluating thresholds
        %     returning excesses of same magnitude.
        % 20210325-ERS: organized the threshold computation; the 3rd threshold not included
        %     in the output anymore; output organized into table arrays stored in a structure array.
        % 20210406-ERS: identified error when input sample size <10. When this
        %     happens, an empty array is returned and the Default GPD threshold computed
        %     in the three fit scripts.
        % 20210412-ERS: now selecting a minima when no inflexion point exists; avoiding the script to crash.
        % 20210429-ERS: now removing noise from the min WMSE through kernel
        %     regression. Also corrected the minimum WMSE criterion based on Langousis. Removed patch
        %     applied on 20210412.
        % 20210430-ERS: script will stop and return empty arrays when no minima is
        %     found by WRMS criterion.
        %
        % ***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************

        %% Step 1: Use sorted POT dataset as initial values of threshold parameter.
        th = sort(PEAKS, 'ascend'); %threshold parameter; sorted in ascending order
        N = size(th,1);

        % preallocate output
        MRL_output.Summary=array2table(NaN(1,8),'VariableNames',...
            {'Threshold','MeanExcess','Weight','WMSE','GPD_Shape','GPD_Scale','Events','Rate'});

        MRL_output.Selection = table({''}, NaN, NaN, NaN, NaN,...
            'VariableNames',...
            {'Criterion', 'Threshold', 'id_Summary', 'Events', 'Rate'});

        TH_selected = table;

        if N>20

            %% Step 2: Estimate mean values of excesses
            mrl=NaN(N-10,8); %pre-allocation for speed
            % col(01): thresholds, u
            % col(02): mean excesses, e(u)
            % col(03): weights
            % col(04): weighted mean square errors
            % col(05): GPD shape parameter
            % col(06): GPD scale parameter
            % col(07): Number of events above threshold
            % col(08): Sample intensity or annual rate of events

            % Note: Looping up to N-10 as max threshold ensures a min of 10 excesses
            %   e(u) to calculate the conditional mean e(u).

            for i = 1:N-10 %threshold loop
                mrl(i,1) = th(i);                %Store threshold
                u = PEAKS(PEAKS(:,1)>th(i),1);   %Take sample of values above threshold
                mrl(i,2) = mean(u-th(i),'omitnan');     %Compute mean excess: difference between sample and threshold
                mrl(i,3) = (N-i)/var(u-th(i),'omitnan');%Compute weights: difference in rank normalized by variance of e(u)
            end

            % Note: Weights are used to acount for the increase in the estimation
            %   variance of e(u) with increasing threshold u. Under the assumption of
            %   independence of e(u).

            id = isinf(mrl(:,3))|isnan(mrl(:,3));%|(mrl(:,3)<=0);
            %     mrl(id,:) = [];

            x = mrl(:,1); %threshold, u
            y = mrl(:,2); %mean excess, e(u)
            w = mrl(:,3); %weights

            %% Step 3: Fit a linear model to (u,e(u)) using the weighted least squares
            % method and compute parameters of interest

            % Note: Looping up to N-20 as max threshold ensures a min of 10 conditional
            %   means e(u) for the linear regression.

            for j = 1:N-20

                %Fit GPD and take shape/scale parameters
                u = PEAKS(PEAKS(:,1)>th(j),1);

                try
                    %Do linear regression
                    mdl = fitlm(x(j:end),y(j:end),'Weights',w(j:end),'Exclude',id(j:end));
                    %Note: if an error arises with the lack of data, enable the 'Exclude' option.

                    %Compute weighted mean square error (WMSR) using fit residuals
                    mrl(j,4) = mean(w(j:end).*(mdl.Residuals.Raw).^2,'omitnan');

                    %Fit GPD and take parameters
                    pd = fitdist(u,'gp','theta',th(j));
                    mrl(j,5) = pd.k; %shape
                    mrl(j,6) = pd.sigma;%scale
                catch
                end
            end

            %Estimate sample intensity for each threshold considered
            for k = 1:size(mrl,1)
                mrl(k,7) = sum(mrl(:,1)>mrl(k,1)); %no. of events
            end
            mrl(:,8)=mrl(:,7)./Nyrs; %lambda


            %% Step 4: Threshold selection: Minimum weighted MSE criterion
            mrl(isinf(mrl(:,4))|isnan(mrl(:,4))|mrl(:,4)==0,:)=[]; %delete values with WMSR=0

            % remove noise
            [~,~,H] = ksdensity(mrl(:,1)); H=H/7; %no difference found for values < 6
            [~,mrl(:,4)] = chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.kernel_regression(mrl(:,1),mrl(:,4),H);

            %Identify local minima
            TH_id = islocalmin(mrl(:,4),'FlatSelection','first');

            % If no min found, return empty arrays
            if sum(TH_id)==0
                %Check: When no inflexion point exists, select the minimum available value
                % [~,TH_id] = min(mrl(:,4),[],'omitnan');
                return;
            end
            TH_id = find(TH_id);
            mrl2=mrl(TH_id,:); %take data of minima

            [~,I]=min(mrl2(:,1),[],'omitnan'); %select minimum threshold

            % Take results
            TH_selected = table;
            TH_selected.Criterion = {'CritWMSE'};
            TH_selected.Threshold = mrl2(I,1);
            TH_selected.id_Summary = TH_id(I);
            TH_selected.Events = mrl2(I,7);
            TH_selected.Rate = mrl2(I,8);


            %% Step 5: Threshold selection: Sample intensity (lambda) criterion

            % Select the minimum with nearly 2 events/year
            aux = mrl2(:,8)-2;
            aux(aux<-1) = NaN;
            [C,I] = min(abs(aux),[],'omitnan');

            if isempty(I)||isnan(C)||isempty(C)
                [~,I] = max(mrl2(:,8),[],'omitnan');
            end

            % Take results
            TH_selected.Criterion(2) = {'CritSI'};
            TH_selected.Threshold(2) = mrl2(I,1);
            TH_selected.id_Summary(2) = TH_id(I);
            TH_selected.Events(2) = mrl2(I,7);
            TH_selected.Rate(2) = mrl2(I,8);

            %% Step 6: Keep Requested Method
            switch GPD_TH_crit
                case 1 % Sample Intensity
                    TH_selected = TH_selected(2, :);
                case 2 % WMSE Method
                    TH_selected = TH_selected(1, :);
            end

            %% Store MRL output
            mrl = array2table(mrl,'VariableNames',{'Threshold','MeanExcess','Weight',...
                'WMSE','GPD_Shape','GPD_Scale','Events','Rate'});

            MRL_output.Summary=mrl;
            MRL_output.Selection=TH_selected;
        end
        end

        function boot = ecdf_boot(empHC,Nsim)
        % ecdf_boot  Bootstrap samples of an empirical response sample.
        %   boot = ecdf_boot(empHC, Nsim)
        %
        %   Each simulation draws numel(empHC) values with replacement
        %   (datasample), adds normal noise scaled by the gap between the drawn
        %   value and the next one of the input (the last gap repeated), and sorts
        %   the result in descending order. The random generator is reset
        %   (rng('default')) on every call, so the samples are reproducible.
        %
        %   Inputs:
        %     empHC - response sample sorted in descending order, column vector
        %     Nsim  - number of bootstrap simulations, scalar
        %   Outputs:
        %     boot - bootstrap samples, one row per simulation sorted in
        %            descending order, Nsim x numel(empHC) double
        %
        %   See also bootstrap_fit.
        %
        %   Developed by: Norberto C. Nadal-Caraballo, PhD (NCNC)

        % CONTRIBUTORS:
        %     Efrain Ramos-Santiago (ERS)
        %
        % HISTORY OF REVISIONS:
        % 20201015-ERS: revised. Updated documentation.
        %
        % ***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
        rng('default');
        Nstrm = size(empHC,1);
        dlt = abs(diff(empHC)); dlt = [dlt;dlt(end)];
        boot=zeros(Nsim,Nstrm);
        for i = 1:Nsim
            [x,idx] = datasample(empHC,Nstrm);
            y = x + randn(Nstrm,1).*dlt(idx);
            boot(i,:) = sort(y,'descend')';
        end
        end

        function [X,Y] = kernel_regression(x,y,H)
        % kernel_regression  Local mean (Nadaraya-Watson) kernel regression.
        %   [X, Y] = kernel_regression(x, y, H)
        %
        %   Non-parametric local mean (order 0) regression with a normal kernel,
        %   following Wand & Jones (1994, Ch. 5, Sec. 2): Y(i) is the kernel
        %   weighted mean of y around X(i,:). Uni- or multivariate predictors,
        %   with the same kernel and bandwidth for every predictor; the prediction
        %   grid is the predictors themselves. Adapted from a local polynomial
        %   (order 0 or 1) script; only the local mean is kept. gpd_threshold_selection uses it
        %   to remove the noise of the WMSE curve.
        %   Reference: Wand, M. P., and Jones, M. C. (1994). Kernel smoothing.
        %   Chapman & Hall/CRC Monographs on Statistics & Applied Probability.
        %
        %   Inputs:
        %     x - predictor matrix, one predictor per column, n x k double
        %     y - response, n x 1 double
        %     H - kernel bandwidth [x units], scalar > 0 (gpd_threshold_selection passes the
        %         ksdensity bandwidth of x divided by 7)
        %   Outputs:
        %     X - prediction grid (= x), n x k double
        %     Y - local mean prediction at X, n x 1 double
        %
        %   See also gpd_threshold_selection.
        %
        %   Developed by: E. Ramos-Santiago

        % History of revisions:
        % 20171206-ERS: developed first draft of function.
        % 20180228-ERS: made revision.
        % 20190109-ERS: expanded algorithm to incorporate multivariate regression using p=0/p=1, only.
        % 20210505-ERS: adapted.
        [n,k] = size(x); %sample size and dimensionality
        X = x;

        % setup regression parameters
        NN=size(X,1);Y=zeros(NN,1);
        Kh =@(H,t,k)H^(-k)*(2*pi)^(k/2)*exp(-0.5*t); %d-variate Normal kernel

        %do regression
        for i = 1:NN %grid point loop
            t = sum(bsxfun(@minus, X(i,:), x).^2,2)./(H^2);
            Xx = ones(n,1);
            Wx = diag(Kh(H,t,k));
            Y(i) = (Xx'*Wx*Xx)\(Xx'*Wx)*y;
        end
        end

        function [y_in] = monotonic_adjustment(x_in,y_in)
        % monotonic_adjustment  Remove jumps from a hazard curve.
        %   y_out = monotonic_adjustment(x_in, y_in)
        %
        %   PST can give non-monotonic curves when the MRL threshold is too low
        %   (incomplete random samples, jumps in the mean curve and CLs). On
        %   log(x_in), every segment with a positive slope (response increasing
        %   with the exceedance frequency) is replaced: its end value becomes the
        %   start value plus the mean of the two preceding slopes times the
        %   segment length. NaN values are kept in place.
        %
        %   Inputs:
        %     x_in - AEF or AEP of the curve, vector > 0
        %     y_in - hazard curve response at x_in, vector (numel(x_in))
        %   Outputs:
        %     y_out - adjusted response, 1 x numel(y_in) double (row vector; the
        %             output variable is named y_in in the code)
        %
        %   See also bootstrap_fit.
        %
        %   Developed by: E. Ramos-Santiago

        % History of revisions:
        % 20210310-ERS: created function to patch the SST tool.

        % Change inputs to column vector
        y_in=y_in(:);x_in=log(x_in(:));

        % Take numbers
        idx3=~isnan(y_in);y=y_in(idx3);x=x_in(idx3);

        % Compute slope
        dx=diff(x);dy=diff(y);s=dy./dx;

        % Identify positive slopes
        id_pos=find(s>0);

        % Adjust y values with positive slopes
        if ~isempty(id_pos)
            for i=1:length(id_pos)
                y(id_pos(i)+1)=mean(s(id_pos(i)-2:id_pos(i)-1))*dx(id_pos(i))+y(id_pos(i));
            end
    
            % Return values to original position
            y_in(idx3)=y;
        end
        y_in=y_in';
        end
    end
end

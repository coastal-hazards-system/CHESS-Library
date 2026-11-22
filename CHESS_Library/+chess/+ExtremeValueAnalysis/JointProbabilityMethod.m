classdef JointProbabilityMethod < chess.ExtremeValueAnalysis
    % JointProbabilityMethod  Response hazard curves by the joint probability method (JPM).
    %   jpm = chess.ExtremeValueAnalysis.JointProbabilityMethod(name, value, ...)
    %   [hazard, jpm] = jpm.compute_hazard(response, probability_mass,
    %       absolute_uncertainty, relative_uncertainty)
    %   x_grid = jpm.exceedance_at_grid(levels)
    %
    %   The hazard curve is the cumulative sum of the storm probability
    %   masses over the responses sorted from largest to smallest;
    %   confidence limits are y + z*sigma, with sigma from
    %   chess.ExtremeValueAnalysis.combined_uncertainty (uncertainty_treatment;
    %   the tide standard deviation is included with tide_application 1;
    %   integration_method 2 adds the replicates of the first uncertainty
    %   partition, chess.ExtremeValueAnalysis.apply_uncertainty 'partition',
    %   and uses the uncertainty left after it,
    %   chess.ExtremeValueAnalysis.uncertainty_after_partition). The fitted object keeps the integrated storm points
    %   (AEF, best estimate and confidence limits), from which
    %   exceedance_at_grid inverts the curve at any response levels.
    %
    %   See also chess.ExtremeValueAnalysis,
    %   chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.

    properties
        integration_method = 1              % 1 = responses as given (PCHA ATCS), 2 = replicates added here (PCHA ITCS)
        uncertainty_treatment = 'combined'  % 'combined', 'relative' or 'absolute'
        tide_application = 0                % 0 = no tides, 1 = tide in the confidence limits, 2 = tide added to the response
        use_skew_tides = 0                  % 1 = skew tides per storm (tide_application 2), 0 = tide standard deviation
        tide_std = 0                        % tide standard deviation [m]
    end

    methods
        function obj = JointProbabilityMethod(varargin)
            % JointProbabilityMethod  Create the method with its settings as name-value pairs (property names).
            %   obj = chess.ExtremeValueAnalysis.JointProbabilityMethod(name, value, ...)
            obj@chess.ExtremeValueAnalysis(varargin{:});
        end

        function [hazard, obj] = compute_hazard(obj, response, probability_mass, absolute_uncertainty, relative_uncertainty, skew_tides, label)
            % compute_hazard  Hazard curve of a response by JPM integration.
            %   [hazard, jpm] = jpm.compute_hazard(response, probability_mass,
            %       absolute_uncertainty, relative_uncertainty)
            %   [hazard, jpm] = jpm.compute_hazard(..., skew_tides, label)
            %   Inputs:
            %     response             - response of each storm, vector
            %     probability_mass     - probability mass (discrete storm weight)
            %                            of each storm, same size as response
            %     absolute_uncertainty - absolute uncertainty of the response
            %                            (units of the response), scalar
            %     relative_uncertainty - relative uncertainty [-], scalar
            %     skew_tides           - skew tide of each storm [m] (optional,
            %                            default zeros)
            %     label                - response name used in titles and file
            %                            names (optional, default 'resp')
            %   Outputs:
            %     hazard - struct: staID, HC_plt (best estimate and confidence
            %              limits at HC_plt_x), HC_tbl (at HC_tbl_x), HC_plt_x
            %              (chess.ExtremeValueAnalysis.hazard_plot_frequencies),
            %              HC_tbl_x
            %              (chess.ExtremeValueAnalysis.hazard_table_probabilities)
            %     jpm    - the method with the integrated storm points
            %              (exceedance_at_grid)
            if nargin < 6 || isempty(skew_tides)
                skew_tides = zeros(numel(response), 1);
            end
            if nargin < 7
                label = '';
            end
            response_data = struct('data', [zeros(numel(response), 1), response(:), skew_tides(:), probability_mass(:)],...
                'flag_value', obj.flag_value, 'Ua', absolute_uncertainty, 'Ur', relative_uncertainty,...
                'SLC', obj.sea_level_change, 'tide_std', obj.tide_std);
            jpm_options = obj.integration_settings();
            plot_options = obj.plot_settings(label);

        %% General settings
        if jpm_options.stat_print == 1
            disp(['***********************************************************' newline...
                '***         CHESS-JPM Tool Alpha Version 0.3         ***' newline...
                '***                Release 1 - 20210831                 ***' newline...
                '***                 FOR  TESTING  ONLY                  ***' newline...
                '***********************************************************']);

            disp([newline '*** Step 1: Processing input arguments ']);
        end
        %% PARAMETER INITIALIZATION
        % Error Handeling For Inputs
        [response_data, jpm_options, plot_options] = chess.ExtremeValueAnalysis.JointProbabilityMethod.validate_inputs(response_data, jpm_options, plot_options);
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
            error('chess:ExtremeValueAnalysis:JointProbabilityMethod:emptyResponseData', 'Could not process dataset because invalid response removal yielded empty data structure.');
        end

        %% Check number of virtual gauges and partition the inputs if necessary
        if jpm_options.stat_print == 1
            % Perform integration
            disp('*** Step 3: Performing integration')
        end
        %
        [hazard, obj.fitted_aef, obj.fitted_response] = chess.ExtremeValueAnalysis.JointProbabilityMethod.integrate(response_data, jpm_options, plot_options);
        % Plot hazard curves
        if plot_options.create_plots == 1
            if jpm_options.stat_print == 1
                disp('*** Step 3: Plotting hazard curves');
            end
            obj.plot_hazard_curve(hazard);
            % Store output
            if jpm_options.stat_print == 1
                disp(['*** Step 4: Saving results here: ',plot_options.path_out]);
            end
            save(fullfile(plot_options.('path_out'), ['CHESS_JPM_' plot_options.staID '_output.mat']),'hazard','-v7.3');
        end


        if jpm_options.stat_print == 1
            disp('*** Evaluation finished.');
            disp('*** CHESS-JPM Tool terminated.');
        end
        end

        function plot_hazard_curve(obj, hazard)
            % plot_hazard_curve  Save the figure of a hazard curve (best estimate and confidence limits).
            %   jpm.plot_hazard_curve(hazard) writes JPM_HC_<label>_<method>.png
            %   under <output_folder>/JPM_outputs.
            jpm_options = obj.integration_settings();
            if isempty(jpm_options.prc)
                jpm_options.prc = obj.DEFAULT_CONFIDENCE_LIMITS;
            end
            jpm_options.prc = reshape(sort(jpm_options.prc, 'ascend'), 1, []);
            plot_options = obj.plot_settings(hazard.staID);
            plot_options.path_out = fullfile(plot_options.path_out, 'JPM_outputs');
            if ~exist(plot_options.path_out, 'dir')
                mkdir(plot_options.path_out);
            end
        %
        % Colors for percentiles plots
        cs={'r-.','b--','b--','r-.'};
        prc=round(jpm_options.prc);

        % Initialize Figures
        fig=figure('Color',[1 1 1],'visible','off');
        % Intialize Axes
        ax = axes('xscale','log','XGrid','on','XMinorTick','on',...
            'YGrid','on','YMinorTick','on',...
            'XDir', 'reverse', 'FontSize', 12);
        % Hold Properties
        hold(ax, 'on');
        % Title
        title({'CHESS-JPM '; ['Station: ',hazard.staID]}, 'FontSize',12);
        % Format X Axis
        if jpm_options.use_AEP == 1
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
        % Legend
        legend([[t1.o],h1,[t2.o]],{t1.L,'Mean',t2.L},...
            'Location','southoutside','Orientation','horizontal','NumColumns',5,'FontSize',10);
        %
        switch jpm_options.integration_method
            case 1
                int_str = 'PCHA_ATCS';
            case 2
                int_str = 'PCHA_ITCS';
        end
        % Filename
        fname = fullfile(plot_options.path_out,...
            ['JPM_','HC_',hazard.staID,'_' int_str '.png']);
        % Save figure
        saveas(fig,fname);
        close(fig);
        end
    end

    methods (Access = private)
        function jpm_options = integration_settings(obj)
            % Settings in the layout used by the integration code
            jpm_options = struct('integration_method', obj.integration_method, 'uncertainty_treatment', obj.uncertainty_treatment,...
                'tide_application', obj.tide_application, 'ind_Skew', obj.use_skew_tides, 'use_AEP', obj.use_aep,...
                'prc', obj.confidence_limits, 'stat_print', obj.print_progress);
        end
    end

    methods (Static, Access = private)
        function [response_data, jpm_options, plot_options] = validate_inputs(response_data, jpm_options, plot_options)
            % Response Data Matrix
            if ~isnumeric(response_data.data) || size(response_data.data, 2) ~= 4 % [ time, response, skew_tides, dsw ]
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidResponseData', 'response_data.data must be a N x 4 numerical matrix where columns represent: [ time, response, skew_tides, dsw ]');
            end
            % Implicit SLC
            if isempty(response_data.('SLC'))
                response_data.('SLC') = 0;
            elseif length(response_data.SLC)~=1 || response_data.SLC < 0 || isnan(response_data.SLC) || isinf(response_data.SLC)
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidSlc', 'response_data.SLC must be a positive scalar.');
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
                error_str = field_to_check(kk) + " must be " + error_msg(kk) + ".";
                % Call Bool Check Function
                chess.ExtremeValueAnalysis.JointProbabilityMethod.check_choice(eval(field_to_check(kk)), error_str, member_list(kk, :));
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
                        error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidTideStd', 'Tides standard deviation must be a positive scalar value.');
                    end
                    % Force Skew Tide Column To Zero
                    response_data.data(:, 3) = 0;
                    % Set Skew Tides Switch To 0
                    jpm_options.ind_Skew = 0;
                case 2 % Tides Added To Response
                    if jpm_options.ind_Skew == 1
                        % Check Skew Tides
                        if any(isinf(response_data.data(:, 3))) || any(isnan(response_data.data(:, 3)))
                            error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidSkewTides', 'response_data.data(:, 3) (Skew tides) must be non-inf or non-nan values.');
                        end
                        % Force Tidal STD To Zero
                        response_data.tide_std = 0;
                    else
                        % Check Standard Deviation Value
                        if ~isnumeric(response_data.tide_std) ||  ~isscalar(response_data.tide_std) || any(response_data.tide_std<=0)
                            error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidTideStd', 'response_data.tide_std must be a positive scalar value.');
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
                    error('chess:ExtremeValueAnalysis:JointProbabilityMethod:unknownUncertaintyTreatment', 'jpm_options.uncertainty_treatment must be: ''combined'', ''relative'', ''absolute''.');
            end
            % Verify Uncertainty Values
            if ~isnumeric(response_data.Ur) || any(response_data.Ur<0) || ~isscalar(response_data.Ur)
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidUncertainty', 'response_data.Ur must be a positive scalar.');
            end
            if ~isnumeric(response_data.Ua) || any(response_data.Ua<0) || ~isscalar(response_data.Ua)
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidUncertainty', 'response_data.Ua must be a positive scalar.');
            end
            % Percentiles
            if length(jpm_options.prc)>4 || any(isnan(jpm_options.prc)) || any(isinf(jpm_options.prc)) || any(jpm_options.prc<0)
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidPercentiles', 'jpm_options.prc can have 1 to 4 percentages in the interval [0, 100].');
            elseif isempty(jpm_options.('prc'))
                jpm_options.('prc')=chess.ExtremeValueAnalysis.DEFAULT_CONFIDENCE_LIMITS';
            else
                jpm_options.('prc') = reshape(sort(jpm_options.('prc'),'ascend'), 1, []);
            end
            % ---- plot_options Fields -------
            % Response Label
            if isempty(plot_options.staID)
                plot_options.staID = 'resp';
            elseif ~ischar(plot_options.staID)
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidStationId', 'plot_options.staID must be a character array.');
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
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidChoice', '%s', error_msg);
            elseif ~isnumeric(data_field) || ~ismember(data_field, member_list)
                error('chess:ExtremeValueAnalysis:JointProbabilityMethod:invalidChoice', '%s', error_msg);
            end
        end

        function [hazard, storm_aef, storm_response] = integrate(response_data, jpm_options, plot_options)
        % Hazard curve and the integrated storm points: storm_aef [1/yr] (column) and storm_response (best estimate, CLs)

        %% INITIALIZE RESPONSE FIELDS
        % Get Input Dataset
        Resp = response_data.data(:, 2); % Response Data
        ProbMass = response_data.data(:, 4); % DSWs
        U_tide = response_data.data(:, 3);
        U_a = response_data.Ua;
        U_r = response_data.Ur;
        % Intialize Random Norm Variable
        randomNorm = 0;
        % Remove sea level change (without steric adjustment) from response data
        Resp = Resp - response_data.SLC;

        %% INTIALIZE HAZARD FREQUENCIES
        % Set up probabilities and responses for HC summary
        HC_tbl_x = chess.ExtremeValueAnalysis.hazard_table_probabilities(jpm_options.use_AEP);
        % The Curves Are Computed In AEF; AEP Tables Are Read At Their AEF And The x Outputs Converted At The End
        if jpm_options.use_AEP
            HC_tbl_x_aef = chess.ExtremeValueAnalysis.aep_to_aef(HC_tbl_x);
        else
            HC_tbl_x_aef = HC_tbl_x;
        end
        % Set up AEFs for full HC; in log10 scale (for plotting), from 10^1 to 10^-6
        HC_plt_x = chess.ExtremeValueAnalysis.hazard_plot_frequencies();

        %% PCHA STANDARD ONLY FIELDS
        if jpm_options.integration_method == 2
            % Define Normal Distribution Discretization Z-Scores
        %     dscrtGauss = [1.9982;1.5632;1.3064;1.1147;0.957;0.8202;0.6973;0.5841;0.478;0.377;0.2798;0.1852;0.0922;0;-0.0922;-0.1852;-0.2798;-0.377;-0.478;-0.5841;-0.6973;-0.8202;-0.957;-1.1147;-1.3064;-1.5632;-1.9982];
            % 444 Z-Scores: The z = 0 Replicate Of The File Is Dropped (chess.Common.drop_z0)
            dscrtGauss = chess.Common.drop_z0(chess.Common.discrete_standard_normal_scores('TC')')';
            % Define Number Of Replicates
            nReps = length(dscrtGauss);
            % Repeat Normal Replicates Per Number Of Storms
            dscrt = sort(repmat(dscrtGauss,  length(Resp), 1));
            % Scale DSW By Number Of Replicates
            ProbMass = repmat(ProbMass./length(dscrtGauss), nReps, 1);
            % Apply Normaly Distributed Replicates To Response
            Resp = repmat(Resp, nReps, 1);
            % Apply Normaly Distributed Replicates To Tides
            U_tide = repmat(U_tide, nReps, 1);
            % First Uncertainty Partition On The Replicates; The Confidence Limits Take The Rest
            [U_a, U_r] = chess.ExtremeValueAnalysis.uncertainty_after_partition(U_a, U_r);
            Resp = chess.ExtremeValueAnalysis.apply_uncertainty(Resp, U_a, U_r, dscrt, 'partition', true);
        end

        %% Tides
        % Get Response Vector Size
        resp_sz = length(Resp);
        % Prep Skew Tides and Tides Uncertainty for Integration
        switch jpm_options.tide_application
            case 0 % No Tides
                tide_cl = 0;%zeros(resp_sz, 1);
            case 1 % Apply Tides Through Confidence Limits
                tide_cl = response_data.tide_std;%.*ones(resp_sz, 1); % Define Tide Std
            case 2 % Add Tides To Response
                % No Tides On CLs
                tide_cl = 0;%zeros(resp_sz, 1);
                % Create Normal Random Numbers
                if jpm_options.ind_Skew == 0 % SD
                    rng('default');
                    % Define RandNorm According to Integration Method
                    switch jpm_options.integration_method
                        case 1 % PCHA ATCS
                            randomNorm = randn(resp_sz, 1);
                        case 2 % PCHA ITCS
                            randomNorm = dscrt;
                    end
                    % Replace Skw Tide Vector With tide_std
                    U_tide = response_data.tide_std;
                else
                    randomNorm = 1;
                end
        end
        % Add uncertainty (or skews) and sea level change to responses
        Resp = Resp + randomNorm.*U_tide + response_data.SLC;

        %% DEFINE CONFIDENCE LIMITS FUNCTION
        % compute Normal Z-scores
        z=reshape(norminv(jpm_options.prc/100), 1, []);
        % Define CL Function Handle (U_a, U_r After The integration_method 2 Partition)
        CL_unc = @(y,U_t) y + z.*chess.ExtremeValueAnalysis.combined_uncertainty(y, U_a, U_r, jpm_options.uncertainty_treatment, U_t);

        %% PERFORM INTEGRATION
        % Find Valid Entries
        pass_indx = ~isnan(Resp) & Resp>0;
        % Keep Valid
        Resp = Resp(pass_indx, 1);
        ProbMass = ProbMass(pass_indx, 1);
        % Sort Response
        [y, I] = sort(Resp, 'descend');%sort response for non-dry storms;
        % y: Response, thresholds for defining hazard curve
        x = cumsum(ProbMass(I, 1)); %HC_Prob: exceedance of threshold rates
        x(x==0)=1e-16;
        % Sort in ascending order
        dm = sortrows([x y], 1, 'ascend');
        storm_aef=dm(:,1);x=log(storm_aef);y=dm(:,2);
        % remove duplicates from x values
        [~,ia,~]=unique(x,'stable');y=y(ia);x=x(ia);storm_aef=storm_aef(ia);
        % remove duplicates from y values - LAA 2023/12/07
        [~,iy,~]=unique(y,'stable');y=y(iy);x=x(iy);storm_aef=storm_aef(iy);
        % Compute percentiles
        resp_perc = CL_unc(y, tide_cl);
        % merge best estimate with percentiles
        y = [y resp_perc];
        % Interpolate AEF curve for plot
        Lx=x;
        y_plt = interp1(Lx,y,log(HC_plt_x));
        % Interpolation to create hazard tables
        HC_tbl_y = interp1(Lx, y, log(HC_tbl_x_aef), 'linear', 'extrap');
        % Storm Points Of The Response Inversion (exceedance_at_grid)
        storm_response = y;
        %Change negatives to NaN
        HC_tbl_y(HC_tbl_y<0)=NaN;
        y_plt(y_plt<0)=NaN;
        % Convert to AEP
        if jpm_options.use_AEP
            HC_plt_x=chess.ExtremeValueAnalysis.aef_to_aep(HC_plt_x);
        end

        %% STORE OUTPUTS
        % Gather the output
        hazard.staID = plot_options.staID;
        hazard.HC_plt = y_plt;
        hazard.HC_tbl = HC_tbl_y;
        hazard.HC_plt_x = HC_plt_x;
        hazard.HC_tbl_x = HC_tbl_x;
        end
    end
end

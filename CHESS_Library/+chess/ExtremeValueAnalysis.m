classdef (Abstract) ExtremeValueAnalysis
    % ExtremeValueAnalysis  Hazard curves of a response from storm data.
    %   Parent class of chess.ExtremeValueAnalysis.JointProbabilityMethod
    %   (tropical storms: responses and their probability masses) and
    %   chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique
    %   (extratropical storms: peaks over threshold and a record length).
    %   The object holds the settings; compute_hazard takes plain arrays
    %   and returns, as its second output, the fitted object, whose
    %   exceedance_at_grid gives the exceedance of any response levels.
    %
    %   Settings are given to the constructor as name-value pairs, e.g.
    %     jpm = chess.ExtremeValueAnalysis.JointProbabilityMethod('use_aep', 1, 'confidence_limits', [16 84]);
    %     [hazard, jpm] = jpm.compute_hazard(response, probability_mass, 0.1, 0.1);
    %     x_grid = jpm.exceedance_at_grid((0:0.01:5)');
    %
    %   Static tools: combine_storm_hazards, exceedance_at_response,
    %   combined_uncertainty, apply_uncertainty, uncertainty_after_partition,
    %   aep_to_aef, aef_to_aep,
    %   hazard_table_probabilities, hazard_plot_frequencies.
    %
    %   See also chess.ExtremeValueAnalysis.JointProbabilityMethod,
    %   chess.ExtremeValueAnalysis.ProbabilisticSimulationTechnique.

    properties
        use_aep = 0             % 1 = annual exceedance probability, 0 = annual exceedance frequency
        confidence_limits = []  % confidence limits [percent], 1 to 4 values ([] = DEFAULT_CONFIDENCE_LIMITS)
        sea_level_change = 0    % sea level change already inside the response [m]
        flag_value = []         % response value marking invalid records ([] = none)
        print_progress = 0      % 1 = print the steps
        create_plots = 0        % 1 = save the hazard curve figure and the output .mat when computing
        output_folder = ''      % folder of the figures and output .mat
        y_axis_label = ''       % y axis label of the figures
        y_axis_limits = []      % y axis limits of the figures ([] = automatic)
        y_log_scale = 0         % 1 = logarithmic y axis in the figures
    end

    properties (Access = protected)
        fitted_aef = []         % AEF [1/yr] of the fitted curve points (set by compute_hazard), column
        fitted_response = []    % response of the fitted curve points, best estimate and confidence limits (set by compute_hazard), one column each
    end

    properties (Constant)
        DEFAULT_CONFIDENCE_LIMITS = [2.28 15.87 84.13 97.72]  % [percent] standard-normal -2, -1, +1, +2 sigma percentiles
        PARTITION_ABSOLUTE_UNCERTAINTY = 0.1  % [response units] absolute part of the first uncertainty partition (PCHA ITCS replicates)
        PARTITION_RELATIVE_UNCERTAINTY = 0.1  % [-] relative part of the first uncertainty partition (PCHA ITCS replicates)
    end

    methods
        function obj = ExtremeValueAnalysis(varargin)
            % ExtremeValueAnalysis  Hold the settings given as name-value pairs (property names).
            %   obj = chess.ExtremeValueAnalysis(name, value, ...)
            % Settings as name-value pairs (property names)
            for kk = 1:2:numel(varargin)
                if ~isprop(obj, varargin{kk})
                    error('chess:ExtremeValueAnalysis:unknownSetting', 'Unknown setting ''%s''.', varargin{kk});
                end
                obj.(varargin{kk}) = varargin{kk + 1};
            end
        end

        function x_grid = exceedance_at_grid(obj, levels)
            % exceedance_at_grid  Exceedance of response levels on the fitted hazard curve.
            %   x_grid = fitted.exceedance_at_grid(levels)
            %   fitted is the second output of compute_hazard. JPM: from the
            %   integrated storm points; PST: from the untrimmed plot curve
            %   (HC_plt at the plot frequencies), each through
            %   chess.ExtremeValueAnalysis.exceedance_at_response.
            %   Inputs:
            %     levels - response levels in the fitted response space (no
            %              lake level added) [response units], vector
            %   Outputs:
            %     x_grid - AEF [1/yr] (AEP [-] when use_aep = 1) of each level,
            %              numel(levels) x number_of_CLs double (best estimate
            %              first, then the confidence limits)
            if isempty(obj.fitted_response)
                error('chess:ExtremeValueAnalysis:notFitted',...
                    'No fitted hazard curve: use the second output of compute_hazard.');
            end
            x_grid = chess.ExtremeValueAnalysis.exceedance_at_response(obj.fitted_aef, obj.fitted_response, levels);
            if obj.use_aep
                x_grid = chess.ExtremeValueAnalysis.aef_to_aep(x_grid);
            end
        end
    end

    methods (Abstract)
        % Hazard curve of a response; fitted: the object holding the fitted curve (exceedance_at_grid)
        [hazard, fitted] = compute_hazard(obj, response, varargin)
        % Figure of a hazard curve returned by compute_hazard
        plot_hazard_curve(obj, hazard)
    end

    methods (Access = protected)
        function plot_options = plot_settings(obj, label)
            % Figure settings in the layout used by the fit and plot code
            plot_options = struct('create_plots', obj.create_plots, 'staID', label, 'yaxis_Label', obj.y_axis_label,...
                'yaxis_Limits', obj.y_axis_limits, 'y_log', obj.y_log_scale, 'path_out', obj.output_folder);
        end
    end

    methods (Static)
        function [aep_out, combined_aep] = combine_storm_hazards(tc_prob, xc_prob, xc_resp_vector, aep_list, log_scale, prc, u_a, resp_var)
        % combine_storm_hazards  Combined (CC) response at given AEPs from TC and XC.
        %   [aep_out, combined_aep] = combine_storm_hazards(tc_prob, xc_prob,
        %       xc_resp_vector, aep_list, log_scale, prc, u_a, resp_var)
        %
        %   Best estimate (column 1): at every response level of xc_resp_vector
        %   the XC and TC best-estimate AEPs are added (zero/NaN taken as 0); the
        %   response is interpolated linearly in log(AEP) at aep_list (with
        %   extrapolation; values <= 0 set to NaN). CL columns: for registry rows
        %   with cc_confidence_limit_method 'als_relative', BE*(1 + z*u_a) with z
        %   the standard normal score of prc; otherwise the TC curves alone give
        %   the offset of each CL from the TC best estimate, applied to the
        %   combined best estimate (a difference when log_scale = 0, a log10
        %   ratio when log_scale = 1).
        %
        %   Inputs:
        %     tc_prob        - TC AEP at each response level of the shared
        %                      response grid (the untrimmed x_grid of the TC
        %                      entry, as AEP), one column per CL,
        %                      number_of_levels x number_of_CLs double
        %     xc_prob        - XC AEP at the same levels (XC x_grid as AEP),
        %                      same size as tc_prob
        %     xc_resp_vector - shared response grid of both (y_grid)
        %                      [response units], number_of_levels x 1 double
        %     aep_list       - AEPs to evaluate [-], vector
        %     log_scale      - y axis log scale flag of the variable (0/1), scalar
        %     prc            - CL percentiles of the columns, [50 project_CLs]
        %                      [%], 1 x number_of_CLs double
        %     u_a            - relative uncertainty for the 'als_relative' CLs
        %                      [-], scalar ([] otherwise)
        %     resp_var       - variable name (registry name), char
        %   Outputs:
        %     aep_out      - combined response at aep_list [response units],
        %                    numel(aep_list) x number_of_CLs double
        %     combined_aep - combined best-estimate AEP (XC + TC) at each
        %                    response level [-] (NaN where the sum is 0 or not
        %                    finite), number_of_levels x 1 double
        %
        %   See also chess.Model.Pros.combine_hazard_curves, chess.Model.Pros.response_based_hazard_curves,
        %   chess.Common.response_registry.

        % Initialize Out Var
        aep_out = NaN(length(aep_list), size(xc_prob, 2));
        % Loop Through Each CL

        % JAM mod 8/23/23 as per NNC
        % combine for mean curves but only use tropical curves for CL
        % first column is BE, second is lower CL, third is upper
        % Define BE Probability Vectors
        FREQ_mean_1 = xc_prob(:,1);
        FREQ_mean_2 = tc_prob(:,1);
        % Make Zero Entries NaN's
        FREQ_mean_1(FREQ_mean_1 == 0) = NaN;
        FREQ_mean_2(FREQ_mean_2 == 0) = NaN;
        FREQ_mean_1(isnan(FREQ_mean_1)) = 0;
        FREQ_mean_2(isnan(FREQ_mean_2)) = 0;
        % Add Probabilities
        % screen for cases when there are few or no values.  This happens with,
        % for example, the crest elevation is high enough to prevent OT.
        % Often, XC storms will produce no OT.
        FREQ_mean_3 = (FREQ_mean_1 + FREQ_mean_2);
        FREQ_mean_3(FREQ_mean_3==0) = NaN;
        combined_aep = FREQ_mean_3;
        combined_aep(~isfinite(combined_aep)) = NaN;

        %% Process data for interpolation (remove NaN, inf, and repeats)
        x1 = FREQ_mean_3;
        y1 = xc_resp_vector;

        % Remove NaN & Inf Values
        rIndx = isnan(x1) | isinf(x1);
        x1(rIndx) = []; y1(rIndx) = [];
        % Compute Log
        x1 = log(x1);
        % Do Unique, Keep Order
        [C, ia, ~] = unique(x1,'stable');
        x1 = C;y1 = y1(ia,1);

        try
            % Interpolate Response For Specified ARI's
            dummy = interp1(x1,y1,log(aep_list),'linear','extrap');
            % Set Negative Iynterp Values To NaN
            dummy(dummy<=0) = NaN;
            % Store Results
            aep_out(:,1) = dummy;
        catch
            % dummy = [];
            %  aep_out(:,ii) = dummy;
        end

        % At this point we have a final combined BE HC

        %% Interpolate to compute ARI for each y-value for tropical storms
        switch resp_var
            case chess.Common.response_registry('output', 'names', 'cc_confidence_limit_method', 'als_relative')
                % ALS CL Method
                for ii = 2:size(tc_prob,2)
                    z = norminv(prc(ii)/100); % Compute Normal Z Scores
                    aep_out(:,ii) = aep_out(:,1)*(1+z*u_a);
                end
            otherwise
                for ii=1:size(tc_prob,2)
                    x1 = tc_prob(:,ii); % CLs use tropical only
                    y1 = xc_resp_vector;

                    % Remove NaN & Inf Values
                    rIndx = isnan(x1) | isinf(x1);
                    x1(rIndx) = []; y1(rIndx) = [];
                    % Compute Log
                    x1 = log(x1);

                    rIndx = isnan(x1) | isinf(x1);
                    x1(rIndx) = []; y1(rIndx) = [];
                    % Do Unique, Keep Order
                    [C, ia, ~] = unique(x1,'stable');
                    x1 = C;y1 = y1(ia,1);
                    try
                        % Interpolate Response For Specified ARI's
                        dummy = interp1(x1,y1,log(aep_list),'linear','extrap');
                        % Set Negative Interp Values To NaN
                        dummy(dummy<=0) = NaN;
                        % Store Results
                        TC_aep(:,ii) = dummy;
                    catch
                    end
                end
                for ii=2:size(TC_aep,2)
                    if log_scale == 0
                        CL_BE_TC_diff = TC_aep(:,1) - TC_aep(:,ii); % TC BE - CL
                        aep_out(:,ii) = aep_out(:,1) - CL_BE_TC_diff; % CC BE/(TC BE + CL)
                    else
                        CL_BE_TC_diff2 = log10(TC_aep(:,ii)) - log10(TC_aep(:,1));
                        aep_out(:,ii) = 10.^(log10(aep_out(:,1)).*CL_BE_TC_diff2);
                    end
                    if size(aep_out,1)>100
                        nan_index = find(isnan(aep_out(:,ii)),1,'first');
                        % aep_out(nan_index-1,ii)=nan; % WHY -1
                        % aep_out(nan_index-2,ii)=nan; % wHY -2
                    end
                end
        end
        end

        function sigma = combined_uncertainty(value, absolute_uncertainty, relative_uncertainty, treatment, tide_uncertainty)
            % combined_uncertainty  Standard deviation of a value from its absolute, relative and tide uncertainty.
            %   sigma = chess.ExtremeValueAnalysis.combined_uncertainty(value,
            %       absolute_uncertainty, relative_uncertainty, treatment, tide_uncertainty)
            %   With U_a = absolute_uncertainty, U_r = relative_uncertainty and
            %   U_t = tide_uncertainty:
            %     'absolute': sigma = sqrt(U_a^2 + U_t^2)
            %     'relative': sigma = sqrt((value*U_r)^2 + U_t^2)
            %     'combined': sigma = 1/sqrt(1/U_a^2 + 1/(value*U_r)^2 [+ 1/U_t^2
            %                 when U_t ~= 0]); with U_r = 0 it is treated as
            %                 'absolute', else with U_a = 0 as 'relative'.
            %   sigma is never negative (also for negative values).
            %   Inputs:
            %     value                - forcing or response value, double array
            %     absolute_uncertainty - absolute uncertainty (units of value), scalar
            %     relative_uncertainty - relative uncertainty [-], scalar
            %     treatment            - 'absolute', 'relative' or 'combined'
            %                            (default 'combined'), char; any other
            %                            value is an error
            %                            ('chess:ExtremeValueAnalysis:unknownUncertaintyTreatment')
            %     tide_uncertainty     - tide uncertainty (units of value),
            %                            scalar (default 0)
            %   Outputs:
            %     sigma - standard deviation (units of value), size of value
            if nargin < 4 || isempty(treatment), treatment = 'combined'; end
            if nargin < 5 || isempty(tide_uncertainty), tide_uncertainty = 0; end
            U_a = absolute_uncertainty; U_r = relative_uncertainty; U_t = tide_uncertainty;
            if strcmp(treatment, 'combined')
                if U_r == 0
                    treatment = 'absolute';
                elseif U_a == 0
                    treatment = 'relative';
                end
            end
            switch treatment
                case 'absolute'
                    sigma = sqrt(U_a.^2 + U_t.^2) + zeros(size(value));
                case 'relative'
                    sigma = sqrt((value.*U_r).^2 + U_t.^2);
                case 'combined'
                    w = 1./U_a.^2 + 1./(value.*U_r).^2;
                    if U_t ~= 0
                        w = w + 1./U_t.^2;
                    end
                    sigma = 1./sqrt(w);
                otherwise
                    error('chess:ExtremeValueAnalysis:unknownUncertaintyTreatment', ...
                        'Unknown uncertainty treatment ''%s'' (use ''absolute'', ''relative'' or ''combined'').', treatment);
            end
        end

        function value = apply_uncertainty(value, absolute_uncertainty, relative_uncertainty, z_scores, option_name, partition)
            % apply_uncertainty  Add the combined uncertainty to a value, scaled by z-scores.
            %   value = chess.ExtremeValueAnalysis.apply_uncertainty(value,
            %       absolute_uncertainty, relative_uncertainty, z_scores)
            %   value = chess.ExtremeValueAnalysis.apply_uncertainty(...,
            %       'partition', true)
            %   value + combined_uncertainty(value, ...).*z_scores with the
            %   'combined' treatment and no tide uncertainty (z_scores: standard
            %   normal scores, e.g. one column per replicate).
            %   With 'partition', true: the replicates of the first uncertainty
            %   partition (PCHA ITCS, JointProbabilityMethod integration_method
            %   2), value + z_scores.*(p_a + value.*p_r)/2 with p_a =
            %   PARTITION_ABSOLUTE_UNCERTAINTY and p_r =
            %   PARTITION_RELATIVE_UNCERTAINTY; absolute_uncertainty and
            %   relative_uncertainty are not used (the confidence limits take
            %   the rest, uncertainty_after_partition).
            %   Inputs:
            %     value                - forcing or response value, double array
            %     absolute_uncertainty - absolute uncertainty (units of value), scalar
            %     relative_uncertainty - relative uncertainty [-], scalar
            %     z_scores             - standard normal scores, double array
            %                            (broadcast with value)
            %     option_name          - 'partition', char (optional; any other
            %                            name is an error,
            %                            'chess:ExtremeValueAnalysis:unknownOption')
            %     partition            - true = first uncertainty partition,
            %                            false = combined uncertainty (default),
            %                            logical
            %   Outputs:
            %     value - value with the uncertainty (units of value), size of
            %             value + z_scores
            use_partition = false;
            if nargin > 4
                if ~strcmp(option_name, 'partition')
                    error('chess:ExtremeValueAnalysis:unknownOption', 'Unknown option ''%s'' (use ''partition'').', option_name);
                end
                use_partition = logical(partition);
            end
            if use_partition
                p_a = chess.ExtremeValueAnalysis.PARTITION_ABSOLUTE_UNCERTAINTY;
                p_r = chess.ExtremeValueAnalysis.PARTITION_RELATIVE_UNCERTAINTY;
                value = value + z_scores.*(p_a + value.*p_r)/2;
            else
                value = value + chess.ExtremeValueAnalysis.combined_uncertainty(value, absolute_uncertainty, relative_uncertainty).*z_scores;
            end
        end

        function [absolute_uncertainty, relative_uncertainty] = uncertainty_after_partition(absolute_uncertainty, relative_uncertainty)
            % uncertainty_after_partition  Uncertainty left for the confidence limits after the first uncertainty partition.
            %   [U_a_left, U_r_left] = chess.ExtremeValueAnalysis.uncertainty_after_partition(U_a, U_r)
            %   U_left = sqrt(U^2 - p^2) when U^2 >= p^2, else U unchanged,
            %   with p = PARTITION_ABSOLUTE_UNCERTAINTY for U_a and
            %   PARTITION_RELATIVE_UNCERTAINTY for U_r (the partition of
            %   apply_uncertainty(..., 'partition', true)).
            %   Inputs:
            %     absolute_uncertainty - absolute uncertainty (response units), scalar
            %     relative_uncertainty - relative uncertainty [-], scalar
            %   Outputs:
            %     absolute_uncertainty - absolute uncertainty left (response units), scalar
            %     relative_uncertainty - relative uncertainty left [-], scalar
            p_a = chess.ExtremeValueAnalysis.PARTITION_ABSOLUTE_UNCERTAINTY;
            p_r = chess.ExtremeValueAnalysis.PARTITION_RELATIVE_UNCERTAINTY;
            if absolute_uncertainty^2 >= p_a^2
                absolute_uncertainty = sqrt(absolute_uncertainty^2-p_a^2);
            end
            if relative_uncertainty^2 >= p_r^2
                relative_uncertainty = sqrt(relative_uncertainty^2-p_r^2);
            end
        end

        function aef = aep_to_aef(aep)
            % aep_to_aef  Annual exceedance frequency of an annual exceedance probability.
            %   aef = chess.ExtremeValueAnalysis.aep_to_aef(aep)
            aef = -log(1-aep);
        end

        function aep = aef_to_aep(aef)
            % aef_to_aep  Annual exceedance probability of an annual exceedance frequency.
            %   aep = chess.ExtremeValueAnalysis.aef_to_aep(aef)
            aep = (exp(aef)-1)./exp(aef);
        end

        function table_x = hazard_table_probabilities(use_aep)
            % hazard_table_probabilities  Probability list of the hazard tables.
            %   table_x = chess.ExtremeValueAnalysis.hazard_table_probabilities(use_aep)
            %   Inputs:
            %     use_aep - 1 = AEP list, 0 = AEF list (default 0), scalar
            %   Outputs:
            %     table_x - AEP [-] (18 x 1, 1/2 to 1/1e6) or AEF [1/yr]
            %               (22 x 1, 1/0.1 to 1/1e6), double column
            if nargin < 1 || isempty(use_aep), use_aep = 0; end
            if use_aep
                table_x = 1./[2 5 10 20 50 100 200 500 1000 2000 5000 1e4 2e4 5e4 1e5 2e5 5e5 1e6]';
            else
                table_x = 1./[0.1 0.2 0.5 1 2 5 10 20 50 100 200 500 1e3 2e3 5e3 1e4 2e4 5e4 1e5 2e5 5e5 1e6]';
            end
        end

        function aef = hazard_plot_frequencies()
            % hazard_plot_frequencies  AEFs of the plotted hazard curves (HC_plt_x before any AEP conversion).
            %   aef = chess.ExtremeValueAnalysis.hazard_plot_frequencies()
            %   Outputs:
            %     aef - AEF [1/yr], 90 points per decade from 1e-6 to 10, ascending
            %           double column (631 x 1)
            d=1/90; v=10.^(1:-d:0)'; aef=v; x=10;
            for i=1:6
                aef=[aef; v(2:end)/x]; %#ok<AGROW>
                x=x*10;
            end
            aef=flipud(aef);
        end

        function aef = exceedance_at_response(curve_aef, curve_response, levels)
            % exceedance_at_response  Exceedance of response levels on hazard curves (curve inversion).
            %   aef = chess.ExtremeValueAnalysis.exceedance_at_response(curve_aef, curve_response, levels)
            %   For each column of curve_response: the pairs with a non-finite
            %   response or log(curve_aef) are dropped, the first occurrence of
            %   each response value is kept (unique, 'stable'), and
            %   log(curve_aef) is interpolated linearly at levels with
            %   extrapolation; the output is exp of it.
            %   A column with fewer than two points gives NaN. The same rule
            %   inverts AEF or AEP curves (the output is in the unit of
            %   curve_aef).
            %   Inputs:
            %     curve_aef      - exceedance of the curve points (AEF [1/yr] or
            %                      AEP [-]), column shared by every column of
            %                      curve_response or a matrix of its size
            %     curve_response - response of the curve points, one column per
            %                      curve (best estimate, CLs) [response units]
            %     levels         - response levels to evaluate [response units],
            %                      vector
            %   Outputs:
            %     aef - exceedance at each level, numel(levels) x
            %           size(curve_response, 2) double
            levels = levels(:);
            n_columns = size(curve_response, 2);
            if size(curve_aef, 2) == 1
                curve_aef = repmat(curve_aef(:), 1, n_columns);
            end
            aef = NaN(numel(levels), n_columns);
            for column = 1:n_columns
                response = curve_response(:, column);
                log_aef = log(curve_aef(:, column));
                keep = isfinite(response) & isfinite(log_aef);
                response = response(keep);
                log_aef = log_aef(keep);
                [response, first] = unique(response, 'stable');
                log_aef = log_aef(first);
                if numel(response) < 2
                    continue
                end
                aef(:, column) = exp(interp1(response, log_aef, levels, 'linear', 'extrap'));
            end
        end
    end
end

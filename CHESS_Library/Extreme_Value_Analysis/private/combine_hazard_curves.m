function [aep_out] = combine_hazard_curves(tc_prob, xc_prob, xc_resp_vector, aep_list, log_scale, prc, u_a, resp_var)
% combine_hazard_curves  Combined (CC) response at given AEPs from TC and XC.
%   aep_out = combine_hazard_curves(tc_prob, xc_prob, xc_resp_vector,
%       aep_list, log_scale, prc, u_a, resp_var)
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
%     tc_prob        - TC AEP per response level, one column per CL
%                      (call_hazard_curve_builder tbl_rsp_x),
%                      number_of_levels x number_of_CLs double
%     xc_prob        - XC AEP per response level (tbl_rsp_x), same size
%                      as tc_prob
%     xc_resp_vector - response levels of both tables (tbl_rsp_y)
%                      [response units], number_of_levels x 1 double
%     aep_list       - AEPs to evaluate [-], vector
%     log_scale      - y axis log scale flag of the variable (0/1), scalar
%     prc            - CL percentiles of the columns, [50 project_CLs]
%                      [%], 1 x number_of_CLs double
%     u_a            - relative uncertainty for the 'als_relative' CLs
%                      [-], scalar ([] otherwise)
%     resp_var       - variable name (registry name), char
%   Outputs:
%     aep_out - combined response at aep_list [response units],
%               numel(aep_list) x number_of_CLs double
%
%   Tier: internal
%
%   See also call_hazard_curve_combiner, call_hazard_curve_builder,
%   response_registry.

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
    case response_registry('output', 'names', 'cc_confidence_limit_method', 'als_relative')
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
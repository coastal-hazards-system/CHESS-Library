function JPM_outputs = CHESS_JPM_integration(response_data, jpm_options, plot_options)
% CHESS_JPM_integration  JPM integration of a checked response sample.
%   JPM_outputs = CHESS_JPM_integration(response_data, jpm_options,
%       plot_options)
%
%   Integration step of CHESS_JPM (inputs already checked and cleaned
%   there). Applies the integration method (2: replication over the 444
%   TC discrete standard normal scores without z = 0 carrying the first
%   uncertainty partition, partitioned_replicates; Ua and Ur reduced to
%   what is left, uncertainty_after_partition), the tide treatment and
%   the SLC, sorts the
%   responses in descending order, accumulates the discrete storm weights
%   into AEF, builds the CL curves y + z*sigma(y) from the uncertainty
%   treatment (combined_uncertainty with Ua, Ur and the tide_std of
%   tide_application 1; a zero Ua or Ur means not given) and
%   interpolates in log(AEF) on the plot grid (hazard_plot_frequencies)
%   and the frequency table
%   (hazard_table_probabilities). The response table inverts the
%   integrated storm points (best estimate and CLs) at the levels of
%   jpm_options.response_grid (exceedance_at_response, with
%   extrapolation). Responses <= 0 or NaN after these steps are dropped.
%   With use_AEP = 1 the AEP table is read at its AEF (aep2aef) and
%   HC_plt_x and HC_tbl_rsp_x are converted to AEP (aef2aep) at the end.
%
%   Inputs:
%     response_data - checked response sample (CHESS_JPM response_data:
%                     data N x 4, Ua, Ur, SLC, tide_std), struct
%     jpm_options   - JPM settings (CHESS_JPM jpm_options: use_AEP,
%                     integration_method, tide_application, ind_Skew,
%                     uncertainty_treatment, prc, response_grid), struct
%     plot_options  - plot settings (staID used), struct
%   Outputs:
%     JPM_outputs - hazard curves (staID, HC_plt, HC_tbl, HC_tbl_rsp_x,
%                   HC_tbl_rsp_y, HC_plt_x, HC_tbl_x; see CHESS_JPM),
%                   struct
%
%   Tier: internal
%
%   See also CHESS_JPM, CHESS_JPM_plot, discrete_standard_normal_scores,
%   drop_z0, combined_uncertainty, partitioned_replicates,
%   uncertainty_after_partition, hazard_table_probabilities,
%   hazard_plot_frequencies, exceedance_at_response.

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
% Set up probabilities for HC summary
HC_tbl_x = hazard_table_probabilities(jpm_options.use_AEP);
% The Curves Are Computed In AEF; AEP Tables Are Read At Their AEF And The x Outputs Converted At The End
if jpm_options.use_AEP
    HC_tbl_x_aef = aep2aef(HC_tbl_x);
else
    HC_tbl_x_aef = HC_tbl_x;
end
% Set up responses for HC summary
HC_tbl_rsp_y = jpm_options.response_grid(:);
% Set up AEFs for full HC; in log10 scale (for plotting), from 10^1 to 10^-6
HC_plt_x = hazard_plot_frequencies();

%% PCHA STANDARD ONLY FIELDS
if jpm_options.integration_method == 2
    % Define Normal Distribution Discretization Z-Scores
%     dscrtGauss = [1.9982;1.5632;1.3064;1.1147;0.957;0.8202;0.6973;0.5841;0.478;0.377;0.2798;0.1852;0.0922;0;-0.0922;-0.1852;-0.2798;-0.377;-0.478;-0.5841;-0.6973;-0.8202;-0.957;-1.1147;-1.3064;-1.5632;-1.9982];
    % 444 Z-Scores: The z = 0 Replicate Of The File Is Dropped (drop_z0.m)
    dscrtGauss = drop_z0(discrete_standard_normal_scores('TC')')';
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
    [U_a, U_r] = uncertainty_after_partition(U_a, U_r);
    Resp = partitioned_replicates(Resp, dscrt);
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
% Define CL Function Handle
CL_unc = @(y,U_t) y + z.*combined_uncertainty(y, U_a, U_r, jpm_options.uncertainty_treatment, U_t);

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
HC_tbl_rsp_x = exceedance_at_response(storm_aef, y, HC_tbl_rsp_y);
%Change negatives to NaN
HC_tbl_y(HC_tbl_y<0)=NaN;
y_plt(y_plt<0)=NaN;
% Convert to AEP
if jpm_options.use_AEP
    HC_tbl_rsp_x=aef2aep(HC_tbl_rsp_x);
    HC_plt_x=aef2aep(HC_plt_x);
end

%% STORE OUTPUTS
% Gather the output
JPM_outputs.staID = plot_options.staID;
JPM_outputs.HC_plt = y_plt;
JPM_outputs.HC_tbl = HC_tbl_y;
JPM_outputs.HC_tbl_rsp_x = HC_tbl_rsp_x;
JPM_outputs.HC_tbl_rsp_y = HC_tbl_rsp_y;
JPM_outputs.HC_plt_x = HC_plt_x;
JPM_outputs.HC_tbl_x = HC_tbl_x;
end


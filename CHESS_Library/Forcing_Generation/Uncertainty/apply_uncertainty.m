function [project_forcing] = apply_uncertainty(config, project_forcing, z_scores)
% apply_uncertainty  Apply the PROS forcing uncertainty to one dataset.
%   project_forcing = apply_uncertainty(config, project_forcing, z_scores)
%
%   Perturbs SWL, Hm0_offshore and Tp of a PROS dataset with the discrete
%   standard normal z-scores, one z-score per replicate column
%   (pcha_forcing_uncertainty):
%     - SWL: perturbed as surge (mean_lake_level removed first and added
%       back; 0 outside the Great Lakes) with the SWL absolute and relative
%       uncertainties.
%     - Hm0_offshore: perturbed with the Hm0 uncertainties; values that are
%       0 in the database stay 0 (wave responses NaN, surge responses such as
%       the damaging depth still computed) and negative perturbed values are
%       set to 0.01.
%     - Tp: Tp .* (1 + (sqrt(1 + u_r) - 1) .* z), u_r = Hm0 relative
%       uncertainty.
%   Hm0_toe is derived later from Hm0_offshore (adjust_project_forcing).
%
%   Inputs:
%     config          - CHESS configuration, 1x1 struct; reads chs_swl_u_a
%                       [m], chs_swl_u_r [-], chs_hm0_u_a [m], chs_hm0_u_r
%                       [-] (storm database db_info) and region
%                       (mean_lake_level)
%     project_forcing - one PROS dataset (chess_forcing_formatter), struct;
%                       SWL [m, study datum, positive up], Hm0_offshore [m]
%                       and Tp [s], each nStorms x 1 cell of nSteps x
%                       n_replicates
%     z_scores        - discrete standard normal z-scores
%                       (discrete_standard_normal_scores, transposed) [-],
%                       1 x n_replicates double
%   Outputs:
%     project_forcing - input dataset with SWL, Hm0_offshore and Tp
%                       perturbed, struct
%
%   Tier: internal
%
%   See also boundary_conditions_uncertainty, pcha_forcing_uncertainty,
%   discrete_standard_normal_scores, mean_lake_level.

%% GRAB INFORMATION FROM "config"
swl_u_a = config.chs_swl_u_a;
hm0_u_a = config.chs_hm0_u_a;
swl_u_r = config.chs_swl_u_r;
hm0_u_r = config.chs_hm0_u_r;
% PROS Dataset (boundary_conditions_uncertainty.m)
% Water Level
SWL = project_forcing.('SWL');
% Wave Height (Offshore: Hm0_toe Is Derived From It By adjust_project_forcing)
Hm0 = project_forcing.('Hm0_offshore');
% Wave Peak Period
Tp = project_forcing.('Tp');
% Copy Normal Distirbution Accross All Events 
z_scores_per_storm = repmat({z_scores}, size(SWL));
% Lake Specific Level (Uncertainty Needs To Be Computed For Surge Not TWL)
lake_level = mean_lake_level(config);

%% APPLY SWL UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
% Apply uncertainty using a random normal distribution
% ------------------ SWL ------------------
SWL = cellfun(@(x, y) x - lake_level, SWL ,'un',false);
SWL = cellfun(@(x, y) pcha_forcing_uncertainty(x, swl_u_a, swl_u_r, y),SWL, z_scores_per_storm,'un',false);
SWL = cellfun(@(x, y) x + lake_level, SWL ,'un',false);

%% APPLY Hm0 & Tp UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
% Check For Hm0 == 0 (No Waves In The Database: Excluded From Uncertainty, Restored To 0 Below)
no_waves = cellfun(@(x) x == 0, Hm0, 'un', false);
Hm0_w_Uncert = cellfun(@(x) Hm0_replace(1,x), Hm0, 'un', false);
% Apply Uncertainty
Hm0_w_Uncert = cellfun(@(x, y) pcha_forcing_uncertainty(x, hm0_u_a, hm0_u_r, y), Hm0_w_Uncert, z_scores_per_storm, 'un', false);
% Check For Hm0 < 0.01
Hm0  = cellfun(@(x) Hm0_replace(2,x), Hm0_w_Uncert, 'un', false);
% Storms Without Waves Stay At Hm0 = 0: Wave Responses NaN, Surge Responses (e.g. Damaging Depth) Still Computed
Hm0  = cellfun(@zero_where, Hm0, no_waves, 'un', false);
% Tp
Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
Tp = cellfun(@(x, y) x.*(1+Tp_U.*y), Tp, z_scores_per_storm, 'un', false);

%% Store Results
project_forcing.SWL = SWL;
project_forcing.Hm0_offshore = Hm0;
project_forcing.Tp = Tp;

%% Define internal Aux Function
    function x = zero_where(x, m)
        x(m) = 0;
    end
    function Hm0 = Hm0_replace(cond,Hm0)
        switch cond
            case 1 % Hm0 == 0
                Hm0(Hm0 == 0) =  NaN;
            case 2 % Hm0 < 0.1
                Hm0(Hm0 < 0) =  0.01;
        end
    end
end
function [project_forcing] = apply_uncertainty(config, project_forcing, RandNorm)
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
RandNorm = repmat({RandNorm}, size(SWL));
% Lake Specific Level (Uncertainty Needs To Be Computed For Surge Not TWL)
lake_level = mean_lake_level(config);

%% APPLY SWL UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
% Apply uncertainty using a random normal distribution
% ------------------ SWL ------------------
SWL = cellfun(@(x, y) x - lake_level, SWL ,'un',false);
SWL = cellfun(@(x, y) pcha_forcing_uncertainty(x, swl_u_a, swl_u_r, y),SWL, RandNorm,'un',false);
SWL = cellfun(@(x, y) x + lake_level, SWL ,'un',false);

%% APPLY Hm0 & Tp UNCERTAINTY FOR STRUCTURE RESPONSE COMPUTATIONS
% Check For Hm0 == 0 (No Waves In The Database: Excluded From Uncertainty, Restored To 0 Below)
no_waves = cellfun(@(x) x == 0, Hm0, 'un', false);
Hm0_w_Uncert = cellfun(@(x) Hm0_replace(1,x), Hm0, 'un', false);
% Apply Uncertainty
Hm0_w_Uncert = cellfun(@(x, y) pcha_forcing_uncertainty(x, hm0_u_a, hm0_u_r, y), Hm0_w_Uncert, RandNorm, 'un', false);
% Check For Hm0 < 0.01
Hm0  = cellfun(@(x) Hm0_replace(2,x), Hm0_w_Uncert, 'un', false);
% Storms Without Waves Stay At Hm0 = 0: Wave Responses NaN, Surge Responses (e.g. Damaging Depth) Still Computed
Hm0  = cellfun(@zero_where, Hm0, no_waves, 'un', false);
% Tp
Tp_U = sqrt(1+hm0_u_r)-1; %0.0724
Tp = cellfun(@(x, y) x.*(1+Tp_U.*y), Tp, RandNorm, 'un', false);

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
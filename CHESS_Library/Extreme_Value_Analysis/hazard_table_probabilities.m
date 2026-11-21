function table_x = hazard_table_probabilities(use_aep)
% hazard_table_probabilities  Probability list of the hazard tables.
%   table_x = hazard_table_probabilities(use_aep)
%
%   One list for the JPM (CHESS_JPM_integration) and PST (CHESS_PST_Fit)
%   tables, both down to 1e-6.
%
%   Inputs:
%     use_aep - 1 = AEP list, 0 = AEF list, scalar double
%   Outputs:
%     table_x - AEP [-] (18 x 1, 1/2 to 1/1e6) or AEF [1/yr] (22 x 1,
%               1/0.1 to 1/1e6), descending double column
%
%   Tier: internal
%
%   See also CHESS_JPM, CHESS_PST, call_hazard_curve_combiner.

if use_aep
    table_x = 1./[2 5 10 20 50 100 200 500 1000 2000 5000 1e4 2e4 5e4 1e5 2e5 5e5 1e6]';
else
    table_x = 1./[0.1 0.2 0.5 1 2 5 10 20 50 100 200 500 1e3 2e3 5e3 1e4 2e4 5e4 1e5 2e5 5e5 1e6]';
end
end

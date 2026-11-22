function names = pros_forcing_curves()
% chess.Common.pros_forcing_curves  Names of the PROS forcing hazard curves.
%   names = chess.Common.pros_forcing_curves() returns the names (Output.var) of the PROS
%   forcing hazard curves sampled by PROS-FB (chess.Model.Pros (frequency based)): the
%   pros_forcing_curve rows of chess.Common.response_registry, in registry order.
%
%   SWL, Tp and Hm0_offshore are built from the z = 0 replicate (chess.Model.Pros)
%   with JPM integration method 2 / PST; Hm0_toe is built from every
%   replicate like a toe response (JPM integration method 1,
%   chess.Model.Pros.response_based_hazard_curves).
%
%   Inputs:
%     none
%   Outputs:
%     names - forcing curve names, {'SWL', 'Hm0_offshore', 'Hm0_toe', 'Tp'},
%             1x4 cell of char
%
%   See also chess.Common.response_registry, chess.Model.Pros (frequency based),
%   chess.Model.Pros.response_based_hazard_curves.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

names = chess.Common.response_registry('output', 'names', 'pros_forcing_curve', true);
end

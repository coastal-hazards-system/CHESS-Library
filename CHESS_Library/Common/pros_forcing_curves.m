function names = pros_forcing_curves()
% pros_forcing_curves  Names of the PROS forcing hazard curves.
%   names = pros_forcing_curves() returns the names (Output.var) of the PROS
%   forcing hazard curves sampled by PROS-FB (chess_pros_frequency_base): the
%   pros_forcing_curve rows of response_registry, in registry order.
%
%   SWL, Tp and Hm0_offshore are built from the z = 0 replicate (chess_pros)
%   with JPM integration method 2 / PST; Hm0_toe is built from every
%   replicate like a toe response (JPM integration method 1,
%   call_hazard_curve_builder).
%
%   Inputs:
%     none
%   Outputs:
%     names - forcing curve names, {'SWL', 'Hm0_offshore', 'Hm0_toe', 'Tp'},
%             1x4 cell of char
%
%   Tier: internal
%
%   See also response_registry, chess_pros_frequency_base,
%   call_hazard_curve_builder.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

names = response_registry('output', 'names', 'pros_forcing_curve', true);
end

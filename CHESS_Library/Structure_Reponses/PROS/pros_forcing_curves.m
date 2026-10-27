function names = pros_forcing_curves()
%{
    %% DESCRIPTION
        Names (Output.var) of the PROS forcing hazard curves sampled by
        PROS-FB (chess_pros_frequency_base.m). SWL, Tp and Hm0_offshore are
        built from the z = 0 replicate (chess_pros.m) with JPM integration
        method 2 / PST; Hm0_toe is built from every replicate like a toe
        response (JPM integration method 1, call_hazard_curve_builder.m).

    %% OUTPUTS
        names: {'SWL', 'Tp', 'Hm0_offshore', 'Hm0_toe'}. | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
names = {'SWL', 'Tp', 'Hm0_offshore', 'Hm0_toe'};
end

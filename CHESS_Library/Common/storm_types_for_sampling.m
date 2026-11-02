function storm_types = storm_types_for_sampling(storm_sampling, order)
%{
    %% DESCRIPTION
        Storm types a storm_sampling value stands for: 'CC' is both storm
        types, 'TC' / 'XC' is that type only. The caller states the order
        it needs for 'CC' (it drives the random number sequence of the
        samplers), so every use keeps its own order.

    %% INPUTS
        storm_sampling: 'TC', 'XC' or 'CC' (config.storm_sampling). | char
        order: Order of the types for 'CC', {'TC','XC'} or {'XC','TC'}. | cell | 1 x 2

    %% OUTPUTS
        storm_types: Storm types, in order for 'CC'. | cell | 1 x number_of_types

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
storm_sampling = upper(char(storm_sampling));
if strcmp(storm_sampling, 'CC')
    storm_types = reshape(order, 1, []);
else
    storm_types = {storm_sampling};
end
end

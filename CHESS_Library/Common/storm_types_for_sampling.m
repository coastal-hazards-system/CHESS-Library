function storm_types = storm_types_for_sampling(storm_sampling, order)
% storm_types_for_sampling  Storm types a storm_sampling value stands for.
%   storm_types = storm_types_for_sampling(storm_sampling, order) returns
%   the storm types of a storm_sampling value: 'CC' is both storm types,
%   'TC' / 'XC' is that type only.
%
%   The caller states the order it needs for 'CC' (it drives the random
%   number sequence of the samplers), so every use keeps its own order.
%
%   Inputs:
%     storm_sampling - 'TC', 'XC' or 'CC' (config.storm_sampling), char or
%                      string; converted to upper case, so lower case is
%                      accepted
%     order          - order of the types for 'CC', {'TC','XC'} or
%                      {'XC','TC'}, 1x2 cell of char; ignored for 'TC' / 'XC'
%   Outputs:
%     storm_types - storm types, in order for 'CC', 1 x number_of_types cell
%                   of char
%
%   Tier: internal
%
%   See also discrete_standard_normal_scores, chess_workflows.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

storm_sampling = upper(char(storm_sampling));
if strcmp(storm_sampling, 'CC')
    storm_types = reshape(order, 1, []);
else
    storm_types = {storm_sampling};
end
end

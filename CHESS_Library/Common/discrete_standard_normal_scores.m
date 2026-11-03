function z_scores = discrete_standard_normal_scores(storm_type)
% discrete_standard_normal_scores  Discrete standard normal z-scores of the PROS replicates.
%   z_scores = discrete_standard_normal_scores(storm_type) returns the sorted
%   z-scores of the PROS forcing replicates, with z = 0 in the middle
%   (replicate_z0_col).
%
%   One z-score per replicate column of the PROS forcing and responses:
%       TC: 445 z-scores (444 covering the (-3, 3) range + z = 0),
%           read from discrete_norm_444.txt.
%       XC: 21 z-scores (20 because the SST code draws 1000 bootstrap
%           samples + z = 0), read from discrete_norm_20.txt.
%   Single source of the replicate count and z-scores for the forcing
%   builder, the forcing uncertainty, JPM integration and the event viewer.
%   Statistics consumers drop the z = 0 score with drop_z0. Any other storm
%   type raises discrete_standard_normal_scores:unknownStormType.
%
%   Inputs:
%     storm_type - storm type, 'TC' or 'XC' (case sensitive), char
%   Outputs:
%     z_scores - sorted z-scores [-], [nReplicates x 1] double (TC 445, XC 21)
%
%   Tier: internal
%
%   See also replicate_z0_col, drop_z0, storm_types_for_sampling.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

switch storm_type
    case 'TC'
        z_scores = readmatrix('discrete_norm_444.txt');
    case 'XC'
        z_scores = readmatrix('discrete_norm_20.txt');
    otherwise
        error('discrete_standard_normal_scores:unknownStormType',...
            'Storm type "%s" has no discrete normal z-scores (expected TC or XC).', storm_type);
end
z_scores = z_scores(:);
end

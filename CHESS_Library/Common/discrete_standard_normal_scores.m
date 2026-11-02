function z_scores = discrete_standard_normal_scores(storm_type)
%{
    %% DESCRIPTION
        Discrete standard normal z-scores of the PROS forcing replicates,
        sorted, with z = 0 in the middle (replicate_z0_col.m). One z-score
        per replicate column of the PROS forcing and responses:
            TC: 445 z-scores (444 covering the (-3, 3) range + z = 0),
                read from discrete_norm_444.txt.
            XC: 21 z-scores (20 because the SST code draws 1000 bootstrap
                samples + z = 0), read from discrete_norm_20.txt.
        Single source of the replicate count and z-scores for the forcing
        builder, the forcing uncertainty, JPM integration and the event
        viewer. Statistics consumers drop the z = 0 score with drop_z0.m.

    %% INPUTS
        storm_type: Storm type ('TC' | 'XC'). | char

    %% OUTPUTS
        z_scores: [nReplicates x 1] sorted z-scores (TC 445, XC 21). | double

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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

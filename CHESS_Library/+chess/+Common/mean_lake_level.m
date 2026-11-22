function lake_level = mean_lake_level(config)
% chess.Common.mean_lake_level  Mean lake level of the Great Lakes regions.
%   lake_level = chess.Common.mean_lake_level(config) returns the mean lake level used to
%   convert Great Lakes water levels to surge (SWL uncertainty and hazard
%   curve fitting): 176.45 m for the CHS-GLM and CHS-GLH regions, 0 for all
%   other (non Great Lakes) regions.
%
%   Inputs:
%     config - CHESS configuration struct, 1x1 struct; only its region field
%              (char, e.g. 'CHS-GLM') is read
%   Outputs:
%     lake_level - mean lake level [m, study datum], scalar double
%
%   See also chess.Model.Pros.response_based_hazard_curves, apply_uncertainty.

switch config.region
    case {'CHS-GLM','CHS-GLH'}
        lake_level = 176.45;
    otherwise
        lake_level = 0;
end
end

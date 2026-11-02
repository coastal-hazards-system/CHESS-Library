function lake_level = mean_lake_level(config)
% MEAN_LAKE_LEVEL Returns the mean lake level used to convert Great Lakes
% water levels to surge (SWL uncertainty and hazard curve fitting). Returns
% 0 for non Great Lakes regions.
switch config.region
    case {'CHS-GLM','CHS-GLH'}
        lake_level = 176.45;
    otherwise
        lake_level = 0;
end
end

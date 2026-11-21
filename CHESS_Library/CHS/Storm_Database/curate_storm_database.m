function storm = curate_storm_database(storm)
% curate_storm_database  Forcing curation of every dataset of a storm database.
%   storm = curate_storm_database(storm)
%
%   curate_storm_forcing on every Peaks and Timeseries dataset (Default,
%   WLP, WHP) of every storm type (TC, XC). The other fields of storm
%   (removed_storms, Nyrs_XC, Nstm_XC) are not changed. Called at the end
%   of build_storm_database and on a storm .mat import (call_input_parser,
%   CHSStormDBImportUI).
%
%   Inputs:
%     storm - storm database (storm.TC / storm.XC: Peaks, Timeseries),
%             struct
%   Outputs:
%     storm - storm database with every dataset curated, struct
%
%   Tier: internal
%
%   See also curate_storm_forcing, remove_storms_without_water_level,
%   build_storm_database.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

for st = reshape(intersect({'TC', 'XC'}, fieldnames(storm), 'stable'), 1, [])
    for dtype = reshape(intersect({'Peaks', 'Timeseries'}, fieldnames(storm.(st{1})), 'stable'), 1, [])
        for mtype = reshape(fieldnames(storm.(st{1}).(dtype{1})), 1, [])
            storm.(st{1}).(dtype{1}).(mtype{1}) = curate_storm_forcing(storm.(st{1}).(dtype{1}).(mtype{1}));
        end
    end
end
end

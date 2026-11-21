function [storm, prob_mass] = remove_storms_without_water_level(storm, prob_mass)
% remove_storms_without_water_level  Remove the storms whose curated Peaks SWL is NaN (storm .mat import).
%   [storm, prob_mass] = remove_storms_without_water_level(storm, prob_mass)
%
%   Storm .mat import step after the curation (curate_storm_database) and
%   the validation (storm_validation, prob_mass_validation): every storm
%   whose curated SWL is NaN in a Peaks dataset (Default, WLP, WHP) leaves
%   every dataset of its storm type (Peaks and Timeseries, by storm ID)
%   and, TC, the probability masses (TC_Freq and Param rows of its
%   Default row, TC_Freq rescaled to TotalFreq; smpl1, smpl2, smpl3 by
%   ID); its ID is added to storm.<type>.removed_storms.Default. Warning
%   remove_storms_without_water_level:removedStorms lists the removed IDs;
%   error remove_storms_without_water_level:noStormsWithWaterLevel when a
%   storm type keeps no storm.
%
%   Inputs:
%     storm     - curated storm database (storm.TC / storm.XC: Peaks,
%                 Timeseries, removed_storms), struct
%     prob_mass - TC probability masses (Param, TC_SRR, TC_Freq,
%                 TotalFreq, smpl1, smpl2, smpl3; [] without TC), struct
%   Outputs:
%     storm     - storm database without the storms lacking a water
%                 level, struct
%     prob_mass - TC probability masses of the kept storms, struct
%
%   Tier: internal
%
%   See also curate_storm_database, curate_storm_forcing,
%   storm_validation, prob_mass_validation.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

for st = reshape(intersect({'TC', 'XC'}, fieldnames(storm), 'stable'), 1, [])
    if ~isfield(storm.(st{1}), 'Peaks')
        continue
    end
    removed_ids = [];
    for mtype = reshape(fieldnames(storm.(st{1}).Peaks), 1, [])
        dataset = storm.(st{1}).Peaks.(mtype{1});
        no_water_level = cellfun(@(peak) isnan(peak(1)), dataset(:, 2));
        removed_ids = union(removed_ids, cell2mat(dataset(no_water_level, 1)));
    end
    if isempty(removed_ids)
        continue
    end
    removed_ids = removed_ids(:);
    if strcmp(st{1}, 'TC') && isfield(prob_mass, 'TC_Freq') && ~isempty(prob_mass.TC_Freq)
        % TC_Freq And Param Rows Follow The Rows Of The Default Datasets (prob_mass_validation)
        removed_rows = ismember(cell2mat(storm.TC.Peaks.Default(:, 1)), removed_ids);
        prob_mass.TC_Freq(removed_rows, :) = [];
        prob_mass.TC_Freq = prob_mass.TC_Freq*prob_mass.TotalFreq/sum(prob_mass.TC_Freq);
        if isfield(prob_mass, 'Param')
            prob_mass.Param(removed_rows, :) = [];
        end
        for bin = {'smpl1', 'smpl2', 'smpl3'}
            kept = prob_mass.(bin{1})(~ismember(prob_mass.(bin{1}), removed_ids));
            prob_mass.(bin{1}) = kept(:);
        end
    end
    for dtype = reshape(intersect({'Peaks', 'Timeseries'}, fieldnames(storm.(st{1})), 'stable'), 1, [])
        for mtype = reshape(fieldnames(storm.(st{1}).(dtype{1})), 1, [])
            dataset = storm.(st{1}).(dtype{1}).(mtype{1});
            storm.(st{1}).(dtype{1}).(mtype{1}) = dataset(~ismember(cell2mat(dataset(:, 1)), removed_ids), :);
        end
    end
    previously_removed = [];
    if isfield(storm.(st{1}), 'removed_storms') && isfield(storm.(st{1}).removed_storms, 'Default')
        previously_removed = storm.(st{1}).removed_storms.Default(:);
    end
    storm.(st{1}).removed_storms.Default = union(previously_removed, removed_ids);
    warning('remove_storms_without_water_level:removedStorms',...
        '%d %s storms have no water level (curated Peaks SWL NaN) and are removed from the storm database: storm IDs %s.',...
        numel(removed_ids), st{1}, mat2str(removed_ids'));
    if isempty(storm.(st{1}).Peaks.Default)
        error('remove_storms_without_water_level:noStormsWithWaterLevel',...
            'No %s storm of the storm data has a water level (every curated Peaks SWL is NaN).', st{1});
    end
end
end

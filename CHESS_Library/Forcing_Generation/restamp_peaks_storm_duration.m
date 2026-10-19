function storm = restamp_peaks_storm_duration(storm, storm_duration)
%{
    %% DESCRIPTION
        Sets the last column (storm duration, datenum days) of every Peaks
        storm-data matrix to storm_duration/24. The storm DB column holds the
        duration the DB was built with, while runs always use
        config.storm_duration. Timeseries data are left untouched.

    %% INPUTS
        storm: Storm database structure (storm.<st>.Peaks.<mt>{:, 2}). | struct
        storm_duration: Storm duration [hrs] (config.storm_duration). | double

    %% OUTPUTS
        storm: Same structure with the Peaks duration column restamped. | struct

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
for st = fieldnames(storm)'
    if isstruct(storm.(st{1})) && isfield(storm.(st{1}), 'Peaks')
        for mt = fieldnames(storm.(st{1}).Peaks)'
            storm.(st{1}).Peaks.(mt{1})(:, 2) = cellfun(@(x) [x(:, 1:end-1), repmat(storm_duration/24, size(x, 1), 1)],...
                storm.(st{1}).Peaks.(mt{1})(:, 2), 'un', false);
        end
    end
end
end

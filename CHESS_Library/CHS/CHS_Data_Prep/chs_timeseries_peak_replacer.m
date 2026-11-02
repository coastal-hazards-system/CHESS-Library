function storm_type_data = chs_timeseries_peak_replacer(storm_type_data)
% Replaces The Maximum Of Each Hydrograph Column (SWL, Hm0, Tp, wDir) With The Value Of The Peaks Dataset
% storm_type_data: storm.<TC or XC> (Peaks.Default [SWL Hm0 Tp wDir peak_datenum] and Timeseries.Default)
dPeaks = storm_type_data.('Peaks').('Default');
timeseries_ids = cell2mat(storm_type_data.('Timeseries').('Default')(:,1));
% For Each Storm ID
for kk = 1:length(dPeaks(:,1))
    % Find Storm ID Entry Row, Skip Storm If Not Found
    rowID = timeseries_ids == dPeaks{kk,1};
    if ~any(rowID)
        continue;
    end
    for jj = 1:4 % For Each Column SWL, Hm0, Tp, wDir
        % Find Max On Hydrograph
        [~, tsIndx] = max(storm_type_data.('Timeseries').('Default'){rowID, 2}(:, jj));
        % Replace Timestep With Value In Peaks File
        storm_type_data.('Timeseries').('Default'){rowID, 2}(tsIndx, jj) = dPeaks{kk, 2}(1, jj);
    end
end
end

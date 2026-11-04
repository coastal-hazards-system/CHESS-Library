function [storm_data, ts_storm2rm] = create_priority_dataset(peaks_table, timeseries_table_surge, timeseries_table_wave, storms2rm, wave_headers, Tp_special, priority_type, print_progress)
% create_priority_dataset  Build the WLP or WHP Peaks dataset of a storm type.
%   [storm_data, ts_storm2rm] = create_priority_dataset(peaks_table,
%       timeseries_table_surge, timeseries_table_wave, storms2rm,
%       wave_headers, Tp_special, priority_type, print_progress)
%
%   Pairs the Peaks values of one model with the Timeseries values of the
%   other. All tables are sorted by numeric Storm ID and paired by row;
%   they must hold the same storm IDs (error
%   sort_tables_by_storm_id:stormIdMismatch).
%   'wlp' (Water Level Priority): peaks_table is the ADCIRC Peaks table;
%   its SWL is paired with the wave Timeseries Hm0, Tp and wave dir at the
%   time step nearest the SWL peak time, within +/- 3 hours. When no wave
%   time step is that close, the peak time becomes the time of the ADCIRC
%   Timeseries maximum within the wave Timeseries time range (the SWL
%   stays the Peaks value).
%   'whp' (Wave Height Priority): peaks_table is the wave model Peaks
%   table; its Hm0, Tp and wave dir are paired with the ADCIRC Timeseries
%   SWL at the time step nearest the wave peak time, within +/- 3 hours.
%   Tp_special = 1 gives Tp = 1.2 * Tm. A storm in storms2rm, with a
%   single value in the paired Timeseries or with no match gets NaN data
%   and is added to ts_storm2rm.
%
%   Inputs:
%     peaks_table            - converted Peaks table, ADCIRC for 'wlp' or
%                              wave model for 'whp' (Storm ID,
%                              yyyymmddHHMM, data columns), table
%     timeseries_table_surge - converted ADCIRC Timeseries table (Storm ID,
%                              yyyymmddHHMM, Water Elevation), table
%     timeseries_table_wave  - converted wave model Timeseries table,
%                              table
%     storms2rm              - IDs of storms already removed, double
%     wave_headers           - wave model column names (fields Hm0, Tp,
%                              wDir; chs_wave_model_header_locator),
%                              struct
%     Tp_special             - 1 when the wave file gives the mean period
%                              Tm instead of Tp, else 0, double
%     priority_type          - 'wlp' or 'whp', char
%     print_progress         - print progress (0/1), double
%   Outputs:
%     storm_data  - WLP or WHP dataset, number_of_storms x 2 cell
%                   {storm ID, 1x5 [SWL Hm0 Tp wave_dir peak_datenum]}
%     ts_storm2rm - unique IDs of storms2rm and of the storms removed
%                   here, double
%
%   Tier: internal
%
%   See also call_chs_storm_quality_check, chs_peaks_formatter,
%   chs_timeseries_formatter, chs_wave_model_header_locator.

%% DEFINE INPUTS
ts_storm2rm = storms2rm;
% Define Time Window Around Peak To Pull Response From Timeseries
tdelta = datenum(0, 0, 0, 3, 0, 0); %  +/- 3 hours
% Sort By Numeric Storm ID; All Tables Must Hold The Same Storms (Paired By Row)
[peaks_table, timeseries_table_surge, timeseries_table_wave] = sort_tables_by_storm_id(peaks_table,...
    timeseries_table_surge, timeseries_table_wave);
% Grab Storm IDs
stmID = num2cell(str2double(peaks_table.("Storm ID")));
% Initialize Storage Matrix
storm_data = [stmID ,cell(length(stmID(:,1)),1)];

%% PROMT USER
% Display Progress Step
switch priority_type
    case 'wlp'
        disp_toggle(print_progress,'Building water level priority (WLP) dataset....');
        timeseries_table = timeseries_table_wave;
        chk_field = wave_headers.Hm0;
    case 'whp'
        disp_toggle(print_progress,'Building wave height priority (WHP) dataset....');
        timeseries_table = timeseries_table_surge;
        chk_field = "Water Elevation";
end
% Display Completion Progress Initial Print
if print_progress
    fprintf(1,'   Completion Progress: %3d%%\n',0);
end
%%
% Find Table Row To Extract
for stm = 1:length(stmID)
    % Print Status
    if print_progress
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(stm/length(stmID))));
    end
    % Skip Bad Storm
    if ismember(stmID{stm}, storms2rm) || length(timeseries_table.(chk_field){stm,1}) == 1
        % Assign NaN
        storm_data(stm, 2) = {nan(1,1)};
        % Store Bad Storm ID
        ts_storm2rm = [ts_storm2rm;stmID{stm}];
        % Move To Next Storm
        continue;
    end
    % Get Storm Timeseries Timestamp
    ts_date =  datenum(timeseries_table.('yyyymmddHHMM'){stm,1});
    % Get Priority Response Peak Timestamp
    peak_date = datenum(peaks_table.('yyyymmddHHMM')(stm,1));
    % Find Timeseries Data Points Withing The +/- Time Window (tdelta)
    wIndx = find(abs(ts_date-peak_date)<=tdelta);
    % Remove Storm For Failed Peak Match
    if isempty(wIndx)
        % Water Level Priority Failsafe
        if strcmp(priority_type, 'wlp') % Find Surge Timeseries Within Wave Timeseries
            % Get Wave Timestamp
            ts_date_surge = datenum(timeseries_table_surge.('yyyymmddHHMM'){stm,1});
            % Find Surge Timseries Rows Within Wave Timeseries
            wl_indx = ts_date_surge >= min(ts_date) & ts_date_surge <= max(ts_date);
            % Execute Data Assignment
            if ~any(wl_indx) % Bad Storm
                % Assign NaN
                storm_data(stm, 2) = {nan(1,1)};
                % Store Bad Storm ID
                ts_storm2rm = [ts_storm2rm;stmID{stm}];
                % Move To Next Storm
                continue;
            else % Find Corresponding Peak Wave Response
                % Find New Peak Surge
                [~, peak_indx] = max(timeseries_table_surge.('Water Elevation'){stm,1}(wl_indx, 1));
                % Grab Surge Timeseries Timestamp Within Wave Temporal Range
                ts_date_surge = ts_date_surge(wl_indx);
                % Find Peak Response Date
                peak_date = ts_date_surge(peak_indx);
                % Find Timeseries Data Points Withing The +/- Time Window (tdelta)
                wIndx = find(abs(ts_date-peak_date)<=tdelta);
            end
        else
            % Assign NaN
            storm_data(stm, 2) = {nan(1,1)};
            % Store Bad Storm ID
            ts_storm2rm = [ts_storm2rm;stmID{stm}];
            % Move To Next Storm
            continue;
        end
    end
    % Determine The CLoses Timestamp
    [~, wIndx2] = min(abs(ts_date(wIndx)-peak_date));
    % Redefine Index To Final Selection
    wIndx = wIndx(wIndx2);
    % Assign Storm Data
    switch priority_type
        case 'wlp'
            storm_data{stm, 2} = [peaks_table.('Water Elevation')(stm,1),...
                timeseries_table.(wave_headers.Hm0){stm,1}(wIndx),...
                timeseries_table.(wave_headers.Tp){stm,1}(wIndx),...
                timeseries_table.(wave_headers.wDir){stm,1}(wIndx),...
                peak_date];
        case 'whp'
            storm_data{stm, 2} = [timeseries_table.('Water Elevation'){stm,1}(wIndx),...
                peaks_table.(wave_headers.Hm0)(stm,1),...
                peaks_table.(wave_headers.Tp)(stm,1),...
                peaks_table.(wave_headers.wDir)(stm,1),...
                peak_date];
    end
    % Check For Special Tp Case
    if Tp_special == 1
        storm_data{stm, 2}(:, 3) = storm_data{stm, 2}(:, 3).*1.2;
    end
end
% Do Unique
ts_storm2rm = unique(ts_storm2rm);
% Print Status
if print_progress
    fprintf(1,['\b\b\b\b%3.0f%%' newline],(100*(stm/length(stmID))));
end
end

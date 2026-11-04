function [storm_data, ts_storm2rm] = chs_timeseries_formatter(swl_timeseries, hm0_timeseries, storms2rm,...
    STWAVE_headers_location, Tp_special, print_progress)
% chs_timeseries_formatter  Match ADCIRC and wave model Timeseries per storm.
%   [storm_data, ts_storm2rm] = chs_timeseries_formatter(swl_timeseries,
%       hm0_timeseries, storms2rm, STWAVE_headers_location, Tp_special,
%       print_progress)
%
%   Builds the Timeseries.Default dataset of one storm type. Both tables
%   are sorted by numeric Storm ID and paired by row; they must hold the
%   same storm IDs (error sort_tables_by_storm_id:stormIdMismatch). For
%   each storm the ADCIRC
%   water level is kept within the wave model time range, then both are
%   linearly interpolated to an hourly time step over their common time
%   range. A raw peak (SWL, Hm0, Tp, wave dir) missed by the interpolation
%   is written at the hourly time step nearest its time, so each
%   hydrograph keeps its raw peak. Rows with flagged values (SWL < -90;
%   Hm0, Tp or wave dir < -400) or NaN are dropped. Tp_special = 1 gives
%   Tp = 1.2 * Tm. A storm in storms2rm or with a single water level value
%   gets NaN data, a storm left with no rows gets empty data; both are
%   added to ts_storm2rm.
%
%   Inputs:
%     swl_timeseries          - converted ADCIRC Timeseries table
%                               (Table_StormData: Storm ID, yyyymmddHHMM,
%                               Water Elevation; one row per storm, cells
%                               hold the series), table
%     hm0_timeseries          - converted wave model Timeseries table
%                               (Storm ID, yyyymmddHHMM and the columns
%                               named in STWAVE_headers_location), table
%     storms2rm               - IDs of storms already removed (Peaks
%                               screening; [] without Peaks), double
%     STWAVE_headers_location - wave model column names (fields Hm0, Tp,
%                               wDir; chs_wave_model_header_locator),
%                               struct
%     Tp_special              - 1 when the wave file gives the mean period
%                               Tm instead of Tp, else 0, double
%     print_progress          - print the completion percentage (0/1),
%                               double
%   Outputs:
%     storm_data  - Timeseries dataset, number_of_storms x 2 cell
%                   {storm ID, M x 6 [SWL Hm0 Tp wave_dir datenum dt]};
%                   dt is the time step (1 hour) as a datenum span [days]
%     ts_storm2rm - unique IDs of storms2rm and of the storms removed
%                   here, column double
%
%   Tier: internal
%
%   See also call_chs_storm_quality_check, chs_wave_model_header_locator,
%   chs_timeseries_peak_replacer, chs_peaks_formatter.

%% DEFINE INPUTS AND PRE-ALLOCATE
if print_progress
    fprintf(1,'   Completion Progress:  0%%\n');
end

% Sort By Numeric Storm ID; Both Tables Must Hold The Same Storms (Paired By Row)
[swl_timeseries, hm0_timeseries] = sort_tables_by_storm_id(swl_timeseries, hm0_timeseries);

% Extract Storm IDs quickly as a numeric matrix
stmID_vec = cellfun(@str2double, swl_timeseries.('Storm ID'));
num_storms = length(stmID_vec);

% Initialize Storage Cell Matrix 
storm_data = [num2cell(stmID_vec), cell(num_storms, 1)];

% Pre-allocate space for bad storms to prevent dynamic array resizing
bad_storms_buffer = nan(num_storms, 1);
bad_count = 0;

%% PROACTIVE VECTORIZED DATETIME PARSING (MASSIVE SPEEDUP)
% Determine date formats and convert entire columns outside the loop
dformat = 'yyyyMMddHHmmss';
% yyyymmddHHMM columns are already datetime — pass through directly
all_ad_dtime = swl_timeseries.("yyyymmddHHMM");
all_wv_dtime = hm0_timeseries.("yyyymmddHHMM");
dt_final = hours(1);
dt_final_datenum = datenum(dt_final);

%% ADCIRC-STWAVE TIMESERIES MATCHING PROCESS
for stm = 1:num_storms
    % Print Status
    if print_progress % Only print every 10 iterations to minimize I/O overhead
        fprintf(1,'\b\b\b\b%3.0f%%',(100*(stm/num_storms)));
        drawnow;
    end
    
    current_stmID = stmID_vec(stm);
    
    % Skip Bad Storm
    if ismember(current_stmID, storms2rm) || length(swl_timeseries.("Water Elevation"){stm,1}) == 1
        storm_data{stm, 2} = nan(1,1);
        bad_count = bad_count + 1;
        bad_storms_buffer(bad_count) = current_stmID;
        continue;
    end
    
    %% EXTRACT STORM DATA (Direct Indexing via 'stm' replaces 'pull_indx')
    WL = swl_timeseries.("Water Elevation"){stm, 1};
    
    waves = [hm0_timeseries.(STWAVE_headers_location.Hm0){stm, 1},...
             hm0_timeseries.(STWAVE_headers_location.Tp){stm, 1},...
             hm0_timeseries.(STWAVE_headers_location.wDir){stm, 1}];
         
    wv_dtime = all_wv_dtime{stm};
    ad_dtime = all_ad_dtime{stm};
    
    % Lake Ontario Special Case: Wave Model Provides Tm, Convert To Tp (waves = [Hm0, Tp, wDir])
    if Tp_special == 1
        waves(:,2) = waves(:,2) .* 1.2;
    end
    
    %% EXTRACT ADCIRC DATA RESIDING INSIDE STWAVE TEMPORAL RANGE
    min_wv = wv_dtime(1);    % Optimization: avoid min/max function overhead over sorted arrays
    max_wv = wv_dtime(end);
    
    ad_mask = (ad_dtime >= min_wv) & (ad_dtime <= max_wv);
    WL = WL(ad_mask, :);
    ad_dtime = ad_dtime(ad_mask, :);
    
    %% ADJUST MODEL OUTPUTS VIA INTERPOLATION
    min_bound = max(min_wv, ad_dtime(1));
    max_bound = min(max_wv, ad_dtime(end));
    
    date_final = (min_bound:dt_final:max_bound)';
    len_final = length(date_final);
    
    % Perform Interpolation
    WL_interp = interp1(ad_dtime, WL, date_final, 'linear');
    waves_interp = interp1(wv_dtime, waves, date_final, 'linear'); % Interpolates all 3 columns simultaneously
    %% PRESERVE RAW PEAKS (SWL, Hm0, Tp, wDir)
    % Hourly Interpolation Can Miss A Raw Peak Between Grid Points: Keep It At The Nearest Grid Point
    WL_interp = preserve_raw_peak(WL_interp, date_final, WL, ad_dtime);
    for cc = 1:size(waves, 2)
        waves_interp(:, cc) = preserve_raw_peak(waves_interp(:, cc), date_final, waves(:, cc), wv_dtime);
    end
    
    % Build Storm Data Matrix [ SWL, Hm0, Tp, wDir, date, dt ]
    storm_mat = [WL_interp, waves_interp, datenum(date_final), repmat(dt_final_datenum, len_final, 1)];
    
    %% REMOVE BAD ENTRIES
    % ADCIRC Flag Check
    storm_mat(storm_mat(:, 1) < -90, :) = NaN;
    % STWAVE Flag Check
    storm_mat(any(storm_mat(:, 2:4) < -400, 2), 2:4) = NaN;
    % Remove NaNs
    storm_mat(any(isnan(storm_mat), 2), :) = [];
    % Empty Matrix Handling
    if isempty(storm_mat)
        bad_count = bad_count + 1;
        bad_storms_buffer(bad_count) = current_stmID;
        continue;
    end
    
    % Store Final Results
    storm_data{stm, 2} = storm_mat;
end

%% POST-PROCESSING CONSOLIDATION
% Prune unused pre-allocated elements and combine with input array
bad_storms_buffer = bad_storms_buffer(1:bad_count);
ts_storm2rm = unique([storms2rm(:); bad_storms_buffer]);

% Print Final Status Completion
if print_progress
    fprintf(1, '\b\b\b\b100%%\n');
end
end

%% AUX FUNCTION: RAW PEAK PRESERVATION
function interp_vals = preserve_raw_peak(interp_vals, t_grid, raw_vals, t_raw)
% If The Raw Peak (Within The Interpolation Window) Exceeds The Interpolated Peak,
% Write It At The Grid Point Nearest The Raw Peak Time. Only Applied When Higher, So
% The Resulting Peak Always Equals The Raw Peak And Is Never Lower Than Before.
in_window = t_raw >= t_grid(1) & t_raw <= t_grid(end);
raw_vals = raw_vals(in_window);
t_raw = t_raw(in_window);
[raw_max, i_raw] = max(raw_vals, [], 'omitnan');
if isempty(raw_max) || isnan(raw_max) || ~(raw_max > max(interp_vals, [], 'omitnan'))
    return
end
[~, i_grid] = min(abs(t_grid - t_raw(i_raw)));
interp_vals(i_grid) = raw_max;
end
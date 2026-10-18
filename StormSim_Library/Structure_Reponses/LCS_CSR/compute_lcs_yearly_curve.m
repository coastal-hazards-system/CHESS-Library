


function [Smax,SPcurves,yBox] = compute_lcs_yearly_curve(data, resp_vec, nYears)
% COMPUTE_LCS_YEARLY_CURVE Calculates the expected yearly peak structural
% response and statistical bounds across multiple simulated life cycles.

num_LCs = length(data);

% Preallocate cells to hold the year and max response for EVERY storm
all_storm_years = cell(num_LCs, 1);
all_storm_max = cell(num_LCs, 1);

%% STEP 1: Process all Life Cycles (LCs) once
for ii = 1:num_LCs
    lc_data = data{ii};
    lc_resp = resp_vec{ii};

    % 1. Get Storm Hydrograph Boundaries (Start and End indices)
    if size(lc_data, 2) >= 10
        % Find where column 10 is 0 (Start of a storm)
        stm_beg = find(lc_data(:, 10) == 0);

        % Calculate the end index of each storm
        % (The step before the next storm begins, and the final array index)
        stm_end = [stm_beg(2:end) - 1; size(lc_data, 1)];
    else
        % If not 10 columns, treat every row as a 1-step event
        stm_beg = (1:size(lc_data, 1)).';
        stm_end = stm_beg;
    end

    % 2. Extract the occurrence year for each storm (from column 3)
    storm_years = lc_data(stm_beg, 3);

    % 3. Calculate the maximum response for each individual storm
    num_storms = length(stm_beg);
    storm_max = zeros(num_storms, 1); % Preallocate for speed

    for k = 1:num_storms
        % Extract the data slice for this specific storm and find the peak
        storm_max(k) = max(lc_resp(stm_beg(k) : stm_end(k)));
    end

    % Store the years and max responses for this LC
    all_storm_years{ii} = storm_years;
    all_storm_max{ii} = storm_max;
end

%% STEP 2: Flatten data across all LCs
% Combine all LCs into two large column vectors for rapid filtering
all_storm_years = vertcat(all_storm_years{:});
all_storm_max = vertcat(all_storm_max{:});

%% STEP 3: Group by Year and Calculate Statistics
years = 1:nYears;
yBox = cell(nYears, 1);
Smax = zeros(nYears, 1);
SPcurves = zeros(nYears, 4);

for jj = 1:nYears
    % Find all storms that occurred in this specific year across ALL life cycles
    yr_mask = (all_storm_years == years(jj));

    % Extract their maximum responses
    yr_data = all_storm_max(yr_mask);

    % Store in the output bin
    yBox{jj} = yr_data;

    % Calculate statistical curves (handle empty years to prevent errors)
    if ~isempty(yr_data)
        Smax(jj) = mean(yr_data, 'omitnan');
        SPcurves(jj, :) = prctile(yr_data, [10, 16, 84, 90]);
    else
        % Fallback if a year had absolutely zero storms across all LCs
        Smax(jj) = NaN;
        SPcurves(jj, :) = NaN(1, 4);
    end
end
end


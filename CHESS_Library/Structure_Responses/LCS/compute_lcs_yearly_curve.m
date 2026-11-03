


function [Smax,SPcurves,yBox] = compute_lcs_yearly_curve(data, resp_vec, nYears)
% compute_lcs_yearly_curve  Yearly mean and percentiles of LCS storm maxima.
%   [Smax, SPcurves, yBox] = compute_lcs_yearly_curve(data, resp_vec,
%       nYears)
%
%   Takes the maximum of the response over each storm of every life cycle
%   (Timeseries: from a row with step 0 to the row before the next storm;
%   Peaks: one row per storm) and the storm's year. For each year
%   1..nYears the storm maxima of that year are pooled over all life
%   cycles: Smax is their mean (NaN omitted) and SPcurves their 10th,
%   16th, 84th and 90th percentiles; a year without storms in any life
%   cycle gives NaN. Smax is the mean of the storm maxima of the year, not
%   of the yearly maxima of each life cycle.
%
%   Inputs:
%     data     - life cycles, nLC x 1 cell of Peaks (nStorms x 10) or
%                Timeseries (nRows x 12) matrices (lcs_columns; reads year
%                and, for Timeseries, step)
%     resp_vec - response per row, nLC x 1 cell of column vectors (rows of
%                data)
%     nYears   - number of years per life cycle (mcs_nYears), scalar
%   Outputs:
%     Smax     - yearly mean of the storm maxima, nYears x 1 double
%     SPcurves - yearly 10/16/84/90th percentiles, nYears x 4 double
%     yBox     - storm maxima of each year, nYears x 1 cell of column
%                vectors
%
%   Tier: internal
%
%   See also chess_csr_dpa, lcs_methods, lcs_columns.

num_LCs = length(data);
% Life-Cycle Column Map
C = lcs_columns();

% Preallocate cells to hold the year and max response for EVERY storm
all_storm_years = cell(num_LCs, 1);
all_storm_max = cell(num_LCs, 1);

%% STEP 1: Process all Life Cycles (LCs) once
for ii = 1:num_LCs
    lc_data = data{ii};
    lc_resp = resp_vec{ii};

    % 1. Get Storm Hydrograph Boundaries (Start and End indices)
    if size(lc_data, 2) == C.n_timeseries
        % Find where the step counter is 0 (Start of a storm)
        stm_beg = find(lc_data(:, C.step) == 0);

        % Calculate the end index of each storm
        % (The step before the next storm begins, and the final array index)
        stm_end = [stm_beg(2:end) - 1; size(lc_data, 1)];
    else
        % Peaks Layout: Treat Every Row As A 1-Step Event
        stm_beg = (1:size(lc_data, 1)).';
        stm_end = stm_beg;
    end

    % 2. Extract the occurrence year for each storm
    storm_years = lc_data(stm_beg, C.year);

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


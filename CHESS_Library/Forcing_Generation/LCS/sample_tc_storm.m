function [sample_storms, lcs_data] = sample_tc_storm(storm_peaks, simulation_years, prob_mass, restrict_rate, storm_duration_days)
% sample_tc_storm  Sample one LCS life cycle of tropical cyclones (TC).
%   sample_storms = sample_tc_storm(storm_peaks, simulation_years,
%       prob_mass, restrict_rate, storm_duration_days)
%   [sample_storms, lcs_data] = sample_tc_storm(storm_peaks,
%       simulation_years, prob_mass, restrict_rate, storm_duration_days)
%
%   Draws the number of TC storms of each simulation year from a Poisson
%   distribution with the total TC recurrence rate prob_mass.TC_SRR(end).
%   restrict_rate = 1 redraws the yearly counts until the life-cycle storm
%   rate is within 1/simulation_years of that rate (1e-4 for 1e5 years),
%   i.e. +/- 1 storm per life cycle, up to 1e6 draws (then a warning, the
%   last draw is kept); restrict_rate = 0 keeps the first draw (a life
%   cycle can hold no storms). For each storm an intensity bin (1 low,
%   2 mid, 3 high) is drawn with probability
%   TC_SRR(1:3)/sum(TC_SRR(1:3)), redrawn when the bin has no storm in
%   storm_peaks, then a storm ID of that bin (smpl1, smpl2 or smpl3,
%   restricted to the IDs in storm_peaks(:, 1)) weighted by TC_Freq.
%   With two outputs the peak values are the database values of the
%   sampled storms (storm_peaks rows). With one output only the storm IDs
%   are drawn (chess_lcs with use_peaks = 0 passes the Timeseries storm
%   IDs as storm_peaks). Errors when TC_SRR(end) is not a finite,
%   non-negative scalar, or when no bin with a positive rate has storms.
%
%   Inputs:
%     storm_peaks         - TC Peaks storm database rows [ID, SWL, Hm0, Tp,
%                           wDir, datenum] (cell2mat of
%                           storm.TC.Peaks.Default): SWL [m, study datum],
%                           Hm0 [m], Tp [s], wDir [deg], datenum [days],
%                           nStorms x 6 double; with one output only
%                           column 1 (storm ID) is read
%     simulation_years    - life-cycle length, mcs_nYears [years], positive
%                           integer scalar
%     prob_mass           - TC probability masses
%                           (chs_probability_mass_loader), struct with
%                           TC_SRR (recurrence rates [storms/yr] of the low,
%                           mid and high bins and of all storms, 1 x 4),
%                           TC_Freq (storm weights, indexed by the storm's
%                           row in storm_peaks) and smpl1, smpl2, smpl3
%                           (storm IDs of each bin, columns)
%     restrict_rate       - sampling mode (effective
%                           lcs_restrict_sampling_rate): 0 full Poisson, 1
%                           rate matched, scalar double
%     storm_duration_days - storm duration written to every row of lcs_data
%                           [days] (storm_duration/24; storm_duration is in
%                           hours), scalar double
%   Outputs:
%     sample_storms - sampled storm identity [storm ID, bin (1, 2, 3),
%                     year (1 to simulation_years), order (storm number
%                     within the year)], one row per storm in year order,
%                     nEvents x 4 double (0 x 4 when no storm is drawn)
%     lcs_data      - life-cycle Peaks matrix (lcs_columns Peaks map): id,
%                     bin, year, order, SWL [m, study datum], Hm0_toe [m]
%                     (= Hm0_offshore; depth limited later by
%                     adjust_project_forcing), Hm0_offshore [m], Tp [s],
%                     wDir [deg], storm_duration [days]; nEvents x 10
%                     double (0 x 10 when no storm is drawn)
%
%   Tier: internal
%
%   See also sample_xc_storm, chess_lcs, lcs_columns,
%   chs_probability_mass_loader.
%
%   Developed by: Norberto C. Nadal-Caraballo, PhD; Victor M. Gonzalez, PE;
%   Fabian A. Garcia-Moreno

%{
LICENSING:
    This code is part of CHESS software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics Laboratory
    (hereinafter â€œERDC-CHLâ€?). This material is distributed in accordance with DoD
    Instruction 5230.24. Recipient agrees to abide by all notices, and distribution
    and license markings. The controlling DOD office is the U.S. Army Engineer
    Research and Development Center (hereinafter, "ERDC"). This material shall be
    handled and maintained in accordance with For Official Use Only, Export Control,
    and AR 380-19 requirements. ERDC-CHL retains all right, title and interest in
    CHESS and any portion thereof and in all copies, modifications and derivative
    works of CHESS and any portions thereof including, without limitation, all
    rights to patent, copyright, trade secret, trademark and other proprietary or
    intellectual property rights. Recipient has no rights, by license or otherwise, to
    use, disclose or disseminate CHESS, in whole or in part.

DISCLAIMER:
    CHESS IS PROVIDED â€œAS ISâ€? BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
    ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
    TO CHESS OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
    OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
    MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
    USE, AND THAT THE ASSOCIATED SOFTWAREâ€™S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
    WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN CHESS, AND
    DISTRIBUTES IT â€œAS IS.â€? RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
    HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.

MODIFICATIONS:
    |   DATE (yyyy-mm-dd)   |      EDITOR      |         SUMMARY               |
    |-----------------------|------------------|-------------------------------|
    |      2021-03-02       |   Abigail Stehno |  Created function for storm   |
    |                       |                  |  sampling - xtrops            |
    |-----------------------|------------------|-------------------------------|
RELEVANT PUBLICATIONS:
    Source Material:
        TBD
    Application Of Methodology:
        (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
                structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
                and Development Center.
%}


%% DEFINE INPUTS
smpl1 = prob_mass.smpl1;
smpl2 = prob_mass.smpl2;
smpl3 = prob_mass.smpl3;
% Storm Probability Masses
TC_SRR = prob_mass.TC_SRR;
% Storm Frequency
TC_Freq = prob_mass.TC_Freq;
% Simulation flag, internal. Stops two 'while' loops below to ensure sampled
% storms match sampling rate.
% Rate-matched tolerance, used only with the hidden option lcs_restrict_sampling_rate:
% the sampled storm rate must match the storm rate within 1/simulation_years
% (+/- 1 storm per life cycle); the 1e5-year case uses 1e-4 (+/- 10 storms).
if simulation_years == 1e5
    SIM_Flag = 1e-4;
else
    SIM_Flag = 1/simulation_years; % Force at least 1 event/yr
end

%% POISSON PROCESS
% Assing SRR for all intensities as lambda
TC_lambda = TC_SRR(1,end);  % Events/ Yr
if ~isscalar(TC_lambda) || ~isfinite(TC_lambda) || TC_lambda < 0
    error('sample_tc_storm: TC storm recurrence rate (prob_mass.TC_SRR(end)) must be a finite, non-negative number.');
end
% Make Distribuition Object
TC_pd = makedist('Poisson','lambda',TC_lambda);
% Sample Number Of TCs Sampled For The Simulation Year.
TC_MCS = random(TC_pd,[simulation_years,1]);
% restrict_rate = 0: Full Poisson Process, The First Draw Is Kept (A Life Cycle Can Have No Storms).
% restrict_rate = 1: Rate-Matched Life Cycle (ERDC/CHL TR-20-5 Sec. 3.2-3.3; USGS OFR 2020-1001 p. 17-18): Yearly
% Storm Counts Are Redrawn Until The Life-Cycle Storm Rate Is Within SIM_Flag Of The SRR (+/- 1 Storm Per Life Cycle).
if restrict_rate == 1
    max_draws = 1e6; % Safeguard Against An Endless Loop
    % Recomputes The Storm Rate Of The Simulation Period To Check Against SRR.
    TC_EPY = sum(TC_MCS)/simulation_years;
    n_draws = 1;
    while abs(TC_EPY-TC_lambda)>SIM_Flag && n_draws < max_draws %cannot be higher than NSIMyrs
        % Sample Number Of TCs Sampled For The Simulation Year.
        TC_MCS = random(TC_pd,[simulation_years,1]);
        % Recomputes The Storm Rate Of The Simulation Period To Check Against SRR.
        TC_EPY = sum(TC_MCS)/simulation_years;
        n_draws = n_draws + 1;
    end
    if abs(TC_EPY-TC_lambda)>SIM_Flag
        warning('sample_tc_storm: life-cycle storm rate %.4f not within %.4f of SRR %.4f after %d draws; using last draw.',...
            TC_EPY, SIM_Flag, TC_lambda, n_draws);
    end
end
% No Storms Sampled In This Life Cycle: Empty Outputs
C = lcs_columns();
if sum(TC_MCS) == 0
    lcs_data = zeros(0, C.n_peaks); % Life-Cycle Peaks Layout (lcs_columns.m)
    sample_storms = zeros(0, 4); % [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order ]
    return
end

%% SAMPLE TROPICAL STORMS
% Initialize Storm Counter
n=1;
lcs_data = zeros(sum(TC_MCS), C.n_peaks);
% Grab Valid Storm Id List
valid_storms = storm_peaks(:, 1);
% Intensity Bin Populations (1-Low, 2-Mid, 3-High), Keeping Storms Present In storm_peaks
smpl_bins = {smpl1, smpl2, smpl3};
smpl_bins = cellfun(@(x) x(ismember(x, valid_storms)), smpl_bins, 'un', false);
% Intensity Bins That Can Be Drawn: Must Have Storms. A Draw Landing In An Empty Bin Is Re-Drawn (As Before),
% Which Always Ends Because At Least One Bin With A Positive Rate Has Storms (Checked Here).
has_storms = ~cellfun(@isempty, smpl_bins);
if ~any(has_storms & TC_SRR(1:3) > 0)
    error('sample_tc_storm: no TC storms available in any intensity bin (prob_mass.smpl1-3 matched against storm_peaks).');
end
cumulativeProb = cumsum(TC_SRR(1:3))./sum(TC_SRR(1:3));
% cumulativeProb = cumsum(TC_SRR(1:3)./TC_SRR(end)); % Original (Team Discussion): Normalized By Total SRR. Identical
% When sum(TC_SRR(1:3)) == TC_SRR(end); Otherwise cumulativeProb(3) < 1 And Draws Above It Matched No Intensity Bin.
% Loop Through Simulation Length
for j = 1:simulation_years
    %
    if (TC_MCS(j,1)>0)
        m=1;
        for k = 1:TC_MCS(j,1)
            % Storm Year
            lcs_data(n, C.year) = j;
            % Number of Storm In Storm Year
            lcs_data(n, C.order) = m;
            % Random Number from 0 - 1
            smpl_flag = rand;
            % Determine Random Intensity To Sample (First Bin Whose Cumulative Probability Exceeds The Draw)
            IIdx = find(smpl_flag < cumulativeProb, 1);
            % Make Sure Resulting Intensity Has A Population (Re-Draw Otherwise)
            while isempty(IIdx) || ~has_storms(IIdx)
                % Random Number from 0 - 1
                smpl_flag = rand;
                % Try New Intensity
                IIdx = find(smpl_flag < cumulativeProb, 1);
            end
            % Stomr Intensity
            lcs_data(n, C.bin) = IIdx; % 1-Low, 2-Mid, 3-High
            % Grab Sampling Population From Intensity Bin (Storms Present In storm_peaks)
            smpl = smpl_bins{IIdx};
            % Find Correnponding Frequency
            [~, bi] = ismember(smpl, valid_storms);
            % Sample Random Storm From Instensity Bin (randsample Treats A Scalar As 1:n, So A Single Storm Is Taken Directly)
            if isscalar(smpl)
                lcs_data(n, C.id) = smpl;
            else
                lcs_data(n, C.id) = randsample(smpl, 1, true, TC_Freq(bi));
            end
            % Increment Storm
            n=n+1;
            % Increment Number of Storm In Storm Year
            m=m+1;
        end% for 
    end% if
end% for j
% Sampled Storm Indexes
sample_storms = lcs_data(:, [C.id, C.bin, C.year, C.order]); % (Headers in script header)
% Storm IDs Only (use_peaks = 0: storm_peaks Holds The Storm ID Column)
if nargout < 2
    return
end
[~, bi] = ismember(lcs_data(:, C.id), storm_peaks(:, 1));
% Pull Storm Responses For Sampled Storms (Storm Database Columns: ID SWL Hm0 Tp wDir datenum)
lcs_data(:, [C.SWL, C.Hm0_toe, C.Hm0_offshore, C.Tp, C.wDir]) =  storm_peaks(bi, [2 3 3 4 5]);
lcs_data(:, C.storm_duration) = storm_duration_days;
end
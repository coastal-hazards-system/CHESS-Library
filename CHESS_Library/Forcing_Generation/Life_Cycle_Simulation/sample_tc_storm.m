function [sample_storms, lcs_data] = sample_tc_storm(storm_peaks, simulation_years, prob_mass, restrict_rate)
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

SCRIPT NAME:
    Sample_XC.m.

CALLED BY:
    MCS_DLL1.m

PURPOSE:
    This script reads and pre-processes CHS tropical storm data.

INPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    |       lc      |   double    |  Number of life cycles                   |
    |---------------|-------------|------------------------------------------|
    |    TC_B1RT    |   Double    |  Extra tropical storm response variable  |
    |---------------|-------------|------------------------------------------|
    |  storm_whp_peaks  |   Double    |  Extra tropical storm response variable  |
    |               |             |  - water level priority                  |
    |---------------|-------------|------------------------------------------|
    |  storm_wlp_peaks  |   Double    |  Extra tropical storm response variable  |
    |               |             |  - wave height priority                  |
    |---------------|-------------|------------------------------------------|
    |    SIMyrs     |   Double    |  Extra tropical storm response variable  |
    |---------------|-------------|------------------------------------------|
    |    SIM_Flag   |   Double    |  Simulation flag to ensure sampled storms|
    |               |             |  match sampling rate                     |
    |---------------|-------------|------------------------------------------|
    |     TC_SRR    |   Double    |  Tropical storm recurrance rate          |
    |---------------|-------------|------------------------------------------|
       
OUTPUTS:
    |   Vars Name      |  Vars Type  |               Description                |
    |------------------|-------------|------------------------------------------|
    |    INDEX_TC_TS   |   Double    |  Sampled Storm Indexes                   |
    |------------------|-------------|------------------------------------------|
    | LC_MCSimOUT_TC   |   Double    |  Life Cycle Data Structure - Maximums    |
    |------------------|-------------|------------------------------------------|
    |LC_MCSimOUT_TC_WHP|   Double    |  Life Cycle Data Structure               |
    |                  |             |  - wave height priority                  |
    |------------------|-------------|------------------------------------------|
    |LC_MCSimOUT_TC_WLP|   Double    |  Life Cycle Data Structure               |
    |                  |             |  - water level priority                  |
    |------------------|-------------|------------------------------------------|
    |     TC_iclass    |   Double    |  Sampled Storms Intensity Index          |
    |------------------|-------------|------------------------------------------|

OUTPUTS HEADERS:
    LC_MCSimOUT_TC, LC_MCSimOUT_TC_WHP, LC_MCSimOUT_TC_WLP :
        Size (# of LC's, 8) -> (Rows,Col)
            (01) Storm ID                       [-]
            (02) Storm type                     [0 = extratropical]
            (03) Storm Year                     [-]
            (04) Number of storm in storm year  [-]
            (05) Water Level                    [meters, MSL]
            (06) Wave Height                    [meters]
            (07) Peak Wave Period               [seconds]
            (08) Wave Direction                 [degrees; N=0, E=+90, S=+/-180, W=-90]


EXTERNAL FUNCTIONS:
    storm type flag => (0 - tropicals, 1 - extratropicals)

AUTHORS:
    By: Norberto C. Nadal-Caraballo, PhD,
    Victor M. Gonzalez,PE, Fabian A. Garcia-Moreno

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
if sum(TC_MCS) == 0
    lcs_data = zeros(0, 9);      % [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order, SSL, Hm0, Tp, wDir, storm_duration ]
    sample_storms = zeros(0, 4); % [ storm_IDs, intensity_bin, Sim_Year, yearly_ocurrance_order ]
    return
end

%% SAMPLE TROPICAL STORMS
% Initialize Storm Counter
n=1;
lcs_data = zeros(sum(TC_MCS),9);
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
            lcs_data(n,3) = j;
            % Number of Storm In Storm Year
            lcs_data(n,4) = m;
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
            lcs_data(n,2) = IIdx; % 1-Low, 2-Mid, 3-High
            % Grab Sampling Population From Intensity Bin (Storms Present In storm_peaks)
            smpl = smpl_bins{IIdx};
            % Find Correnponding Frequency
            [~, bi] = ismember(smpl, valid_storms);
            % Sample Random Storm From Instensity Bin (randsample Treats A Scalar As 1:n, So A Single Storm Is Taken Directly)
            if isscalar(smpl)
                lcs_data(n, 1) = smpl;
            else
                lcs_data(n, 1) = randsample(smpl, 1, true, TC_Freq(bi));
            end
            % Increment Storm
            n=n+1;
            % Increment Number of Storm In Storm Year
            m=m+1;
        end% for 
    end% if
end% for j
[~, bi] = ismember(lcs_data(:, 1), storm_peaks(:, 1));
% Pull Storm Responses For Sampled Storms 
lcs_data(:, 5:end) =  storm_peaks(bi, [2:5,7]);

%% STORE SAMPLED TROPICAL STORMS
% Sampled Storm Indexes
sample_storms = lcs_data(:,1:4); % (Headers in script header)
end
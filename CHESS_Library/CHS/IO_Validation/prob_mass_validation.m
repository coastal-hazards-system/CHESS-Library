function prob_mass_validation(config, prob_mass, storm)
% prob_mass_validation  Check the TC probability masses of a user storm .mat.
%   prob_mass_validation(config, prob_mass, storm)
%
%   Checks the prob_mass variable of a user storm .mat (storm_data
%   input); called by call_input_parser and the GUI storm database wizard
%   when the storm data has TC storms. Errors (message only, no error ID)
%   when prob_mass does not hold the six fields below, when TC_SRR has
%   neither 1 row nor 4 columns, or when smpl1, smpl2 and smpl3 are all
%   empty. Prints a warning when TotalFreq differs from sum(TC_Freq) or
%   the TC_SRR total from the sum of the three bin rates. The TC_Freq
%   length is not checked against the TC storm count of storm.
%
%   Inputs:
%     config    - CHESS configuration, 1x1 struct; not read
%     prob_mass - TC probability masses, struct; fields:
%                   TC_SRR    - TC storm recurrence rates per intensity
%                               bin [storms/yr], 1x4 double [low, mid,
%                               high, total]; bins by central pressure
%                               deficit dP [hPa]: low dP < 28, mid
%                               28 <= dP < 48, high dP >= 48
%                   TC_Freq   - TC discrete storm weights (probability
%                               masses) [storms/yr], N x 1 double
%                   TotalFreq - total TC storm suite frequency,
%                               sum(TC_Freq) [storms/yr], scalar double
%                   smpl1, smpl2, smpl3 - storm IDs of the low, mid and
%                               high intensity bins (IDs of the storm
%                               variable), N x 1 double
%     storm     - user storm database, struct; not read
%   Outputs:
%     none (errors or prints a warning)
%
%   Tier: internal
%
%   See also storm_validation, storm_db_check, call_input_parser.

    % Define Intensity Bins
    intensity_bins = {'smpl1','smpl2','smpl3'}; % low, mid, high
% Scan Provided PM File Fields
pm_fields = fieldnames(prob_mass);
% Verify How Many Fields Are Found
if sum(contains(pm_fields, {'TC_SRR', 'TC_Freq', 'TotalFreq', 'smpl1', 'smpl2', 'smpl3'})) ~= 6
    error('Error: Provided "prob_mass" variable does not comply with the expected fields. Aborting...');
end
% Determine Number Of TC Storms In Storm Suite
% if config.use_peaks == 1
%     number_of_storms = length(storm.TC.Peaks.Default(:,1));
% else
%     number_of_storms = length(storm.TC.Timeseries.Default(:,1));
% end
% Ensure Each TC Storm Has An Associated Likelihood of Occurrence
% if number_of_storms~=length(prob_mass.('TC_Freq'))
%     error('Error: Provided "prob_mass.TC_Freq" field must match the number of TC storms on storm suite. Aborting...');
% else
if prob_mass.TotalFreq~=sum(prob_mass.TC_Freq) % Make Sure Total Frequency Matches
    % Throw Warning
    disp('Warning: Field "prob_mass.TotalFreq" field does not match sum(prob_mass.TC_Freq)...');
end
% Verify Storm Recurrence Rates
if size(prob_mass.TC_SRR, 1) ~= 1 && size(prob_mass.TC_SRR, 2) ~= 4
    error('Error: Field "prob_mass.TC_SRR" does not match expected dimensions 1 x 4 double. Each column represents yearly recurrance rate for each intensity bin [ low, mid, high, total ]...');
elseif sum(prob_mass.TC_SRR(1,1:end-1)) ~= prob_mass.TC_SRR(1, end)
    disp('Warning: Provided total SRR does not match sum(SRR_low, SRR_mid, SRR_high)....');
end
% Make Sure At Least 1 smpl Field Is Populated
if isempty(prob_mass.smpl1) && isempty(prob_mass.smpl2) && isempty(prob_mass.smpl3)
    error('Error: No storm IDs found assigned to intensity bins (smpl1, smpl2, smpl3)....');
elseif any(cell2mat(cellfun(@(x) strcmp(x, fieldnames(prob_mass)), intensity_bins, 'un', false)), 'all')
    % Check What Intensity Bins Exist
    found_bins = any(cell2mat(cellfun(@(x) strcmp(x, fieldnames(prob_mass)), intensity_bins, 'un', false)),1);
    % Populate Missing Intensity Bins With Empty Fields
    for ll = intensity_bins(~found_bins)
        prob_mass.({ll}) = [];
    end
end
end

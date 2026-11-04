function prob_mass = prob_mass_validation(config, prob_mass, storm)
% prob_mass_validation  Check the TC probability masses of a user storm .mat.
%   prob_mass = prob_mass_validation(config, prob_mass, storm)
%
%   Checks the prob_mass variable of a user storm .mat (storm_data
%   input) against the TC storms of storm and returns it with the missing
%   intensity bins added and TotalFreq set to sum(TC_Freq); called by call_input_parser and the GUI storm
%   database wizard when the storm data has TC storms, after
%   storm_validation. Errors when:
%     - TC_SRR or TC_Freq is missing
%       (prob_mass_validation:missingField);
%     - TC_SRR is not 1 x 4 (prob_mass_validation:tcSrrSize);
%     - TC_Freq is not N x 1, N = rows of every TC Default dataset of
%       storm (prob_mass_validation:tcFreqSize);
%     - Param is present and its row count differs from numel(TC_Freq)
%       (prob_mass_validation:paramRows);
%     - smpl1, smpl2 or smpl3 is not a column vector
%       (prob_mass_validation:smplShape) or holds IDs that are not TC
%       storm IDs of storm (prob_mass_validation:smplIds);
%     - smpl1, smpl2 and smpl3 are all empty
%       (prob_mass_validation:noBinStorms).
%   A missing smpl1, smpl2 or smpl3 is added as zeros(0,1) and an empty
%   bin is returned as zeros(0,1). Warnings: an empty bin with a TC_SRR
%   rate > 0 (prob_mass_validation:emptyBin; sample_tc_storm redraws an
%   empty bin, so its share of the rate goes to the other bins) and the
%   TC_SRR total differing from the sum of the three bin rates by more than
%   a relative 1e-9 (prob_mass_validation:srrTotalMismatch).
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
%                   TotalFreq - optional; ignored and set to sum(TC_Freq)
%                               [storms/yr] (total TC storm suite frequency)
%                   Param     - optional; TC storm parameters, one row per
%                               storm, N x number_of_parameters double
%                   smpl1, smpl2, smpl3 - optional; storm IDs of the low,
%                               mid and high intensity bins (TC storm IDs
%                               of storm), column double
%     storm     - user storm database (storm_validation output), struct;
%                 storm.TC.Peaks.Default and storm.TC.Timeseries.Default
%                 are read (row counts, storm IDs)
%   Outputs:
%     prob_mass - prob_mass with smpl1, smpl2 and smpl3 as column vectors
%                 (missing or empty bins as zeros(0,1)), struct
%
%   Tier: internal
%
%   See also storm_validation, storm_db_check, call_input_parser,
%   sample_tc_storm.

intensity_bins = {'smpl1', 'smpl2', 'smpl3'};
required = {'TC_SRR', 'TC_Freq'};
missing = required(~isfield(prob_mass, required));
if ~isempty(missing)
    error('prob_mass_validation:missingField', 'Provided "prob_mass" variable lacks the field(s) %s.', strjoin(missing, ', '));
end
if ~isequal(size(prob_mass.TC_SRR), [1 4])
    error('prob_mass_validation:tcSrrSize', ['Field "prob_mass.TC_SRR" must be 1 x 4 double (yearly recurrence rate ',...
        'per intensity bin [low, mid, high, total]); found %s.'], mat2str(size(prob_mass.TC_SRR)));
end
tc_ids = [];
for dtype = intersect({'Peaks', 'Timeseries'}, fieldnames(storm.TC), 'stable')
    tc_ids = cell2mat(storm.TC.(dtype{1}).Default(:, 1));
    if ~iscolumn(prob_mass.TC_Freq) || numel(prob_mass.TC_Freq) ~= numel(tc_ids)
        error('prob_mass_validation:tcFreqSize', ['Field "prob_mass.TC_Freq" must be N x 1 with N = %d TC storms ',...
            '(storm.TC.%s.Default); found %s.'], numel(tc_ids), dtype{1}, mat2str(size(prob_mass.TC_Freq)));
    end
end
prob_mass.TotalFreq = sum(prob_mass.TC_Freq);
if isfield(prob_mass, 'Param') && size(prob_mass.Param, 1) ~= numel(prob_mass.TC_Freq)
    error('prob_mass_validation:paramRows', 'Field "prob_mass.Param" has %d rows; expected one per TC storm (%d).',...
        size(prob_mass.Param, 1), numel(prob_mass.TC_Freq));
end
for bb = 1:numel(intensity_bins)
    bin = intensity_bins{bb};
    if ~isfield(prob_mass, bin) || isempty(prob_mass.(bin))
        prob_mass.(bin) = zeros(0, 1);
        if prob_mass.TC_SRR(bb) > 0
            warning('prob_mass_validation:emptyBin', ['Intensity bin "%s" has no storms but a TC_SRR rate of %g storms/yr; ',...
                'the sampler moves that share to the other bins.'], bin, prob_mass.TC_SRR(bb));
        end
    elseif ~iscolumn(prob_mass.(bin))
        error('prob_mass_validation:smplShape', 'Field "prob_mass.%s" must be a column vector of TC storm IDs.', bin);
    elseif ~all(ismember(prob_mass.(bin), tc_ids))
        error('prob_mass_validation:smplIds', 'Field "prob_mass.%s" holds IDs that are not TC storm IDs of the storm data.', bin);
    end
end
if all(cellfun(@(bin) isempty(prob_mass.(bin)), intensity_bins))
    error('prob_mass_validation:noBinStorms', 'No storm IDs assigned to the intensity bins (smpl1, smpl2, smpl3).');
end
if ~totals_match(sum(prob_mass.TC_SRR(1:3)), prob_mass.TC_SRR(4))
    warning('prob_mass_validation:srrTotalMismatch', 'Provided total SRR does not match sum(SRR_low, SRR_mid, SRR_high).');
end
end

function tf = totals_match(a, b)
% Totals agree within a relative tolerance of 1e-9 (floating-point sums).
tf = abs(a - b) <= 1e-9 * max(abs(a), abs(b));
end

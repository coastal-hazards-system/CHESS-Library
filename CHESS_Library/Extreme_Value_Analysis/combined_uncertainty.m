function sigma = combined_uncertainty(value, absolute_uncertainty, relative_uncertainty, treatment, tide_uncertainty)
% combined_uncertainty  Standard deviation of a value from its absolute, relative and tide uncertainty.
%   sigma = combined_uncertainty(value, absolute_uncertainty, relative_uncertainty)
%   sigma = combined_uncertainty(value, absolute_uncertainty,
%       relative_uncertainty, treatment, tide_uncertainty)
%
%   With U_a = absolute_uncertainty, U_r = relative_uncertainty and
%   U_t = tide_uncertainty:
%     'absolute': sigma = sqrt(U_a^2 + U_t^2)
%     'relative': sigma = sqrt((value*U_r)^2 + U_t^2)
%     'combined': sigma = 1/sqrt(1/U_a^2 + 1/(value*U_r)^2 [+ 1/U_t^2
%                 when U_t ~= 0]); with U_r = 0 it is treated as
%                 'absolute', else with U_a = 0 as 'relative' (a zero
%                 uncertainty means "not given", it does not collapse the
%                 band).
%   sigma is never negative (also for negative values). Used for the PROS
%   forcing replicates (apply_uncertainty, chess_pros_frequency_base EB2)
%   and the JPM confidence limits (CHESS_JPM_integration).
%
%   Inputs:
%     value                - forcing or response value, double array
%     absolute_uncertainty - absolute uncertainty (units of value), scalar
%                            double
%     relative_uncertainty - relative uncertainty [-], scalar double
%     treatment            - 'absolute', 'relative' or 'combined' (default
%                            'combined'), char; any other value is an error
%                            ('combined_uncertainty:unknownUncertaintyTreatment')
%     tide_uncertainty     - tide uncertainty (units of value), scalar
%                            double (default 0)
%   Outputs:
%     sigma - standard deviation (units of value), size of value
%
%   Tier: public
%
%   See also apply_uncertainty, CHESS_JPM_integration,
%   chess_pros_frequency_base.

if nargin < 4 || isempty(treatment), treatment = 'combined'; end
if nargin < 5 || isempty(tide_uncertainty), tide_uncertainty = 0; end
U_a = absolute_uncertainty; U_r = relative_uncertainty; U_t = tide_uncertainty;
if strcmp(treatment, 'combined')
    if U_r == 0
        treatment = 'absolute';
    elseif U_a == 0
        treatment = 'relative';
    end
end
switch treatment
    case 'absolute'
        sigma = sqrt(U_a.^2 + U_t.^2) + zeros(size(value));
    case 'relative'
        sigma = sqrt((value.*U_r).^2 + U_t.^2);
    case 'combined'
        w = 1./U_a.^2 + 1./(value.*U_r).^2;
        if U_t ~= 0
            w = w + 1./U_t.^2;
        end
        sigma = 1./sqrt(w);
    otherwise
        error('combined_uncertainty:unknownUncertaintyTreatment', ...
            'Unknown uncertainty treatment ''%s'' (use ''absolute'', ''relative'' or ''combined'').', treatment);
end
end

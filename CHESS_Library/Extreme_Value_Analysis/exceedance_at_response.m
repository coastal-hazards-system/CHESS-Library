function aef = exceedance_at_response(curve_aef, curve_response, levels)
% exceedance_at_response  Exceedance of response levels on hazard curves (curve inversion).
%   aef = exceedance_at_response(curve_aef, curve_response, levels)
%
%   For each column of curve_response: the pairs with a non-finite
%   response or log(curve_aef) are dropped, the first occurrence of each
%   response value is kept (unique, 'stable'), and log(curve_aef) is
%   interpolated linearly at levels with extrapolation; the output is exp
%   of it. A column with fewer than two points gives NaN. The same rule
%   inverts AEF or AEP curves (the output is in the unit of curve_aef).
%   Used for the response tables (HC_tbl_rsp_x) of CHESS_JPM_integration
%   (integrated storm points) and CHESS_PST_Fit (plot curve).
%
%   Inputs:
%     curve_aef      - exceedance of the curve points (AEF [1/yr] or AEP
%                      [-]), column shared by every column of
%                      curve_response or a matrix of its size
%     curve_response - response of the curve points, one column per curve
%                      (best estimate, CLs) [response units]
%     levels         - response levels to evaluate [response units],
%                      vector
%   Outputs:
%     aef - exceedance at each level, numel(levels) x
%           size(curve_response, 2) double
%
%   Tier: internal
%
%   See also response_hazard_grid, CHESS_JPM, CHESS_PST.

levels = levels(:);
n_columns = size(curve_response, 2);
if size(curve_aef, 2) == 1
    curve_aef = repmat(curve_aef(:), 1, n_columns);
end
aef = NaN(numel(levels), n_columns);
for column = 1:n_columns
    response = curve_response(:, column);
    log_aef = log(curve_aef(:, column));
    keep = isfinite(response) & isfinite(log_aef);
    response = response(keep);
    log_aef = log_aef(keep);
    [response, first] = unique(response, 'stable');
    log_aef = log_aef(first);
    if numel(response) < 2
        continue
    end
    aef(:, column) = exp(interp1(response, log_aef, levels, 'linear', 'extrap'));
end
end

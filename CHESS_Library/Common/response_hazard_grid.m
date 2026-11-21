function grid = response_hazard_grid(name, response_values)
% response_hazard_grid  Response grid of the PROS hazard curves of one response.
%   grid = response_hazard_grid(name)
%   grid = response_hazard_grid(name, response_values)
%
%   The grid is fixed: exactly the range of the response at its spacing,
%   linear grids from the lower end of the range in steps of step (the
%   upper end rounded up to the next step), log grids the points 10^(k/n)
%   (n points per decade, k integer) from the decade point at or below the
%   lower end to the one at or above the upper end. The range and spacing
%   come from the registry row of the response (response_registry
%   hazard_grid) or, when it has none, from its unit_kind (names outside
%   the registry: dimensionless):
%       length                     0 to 30, step 0.01 (surge space: the
%                                  mean lake level is added afterwards)
%       discharge_per_length (q)   1e-7 to 10, log, 20 per decade
%       volume_per_length (Q)      1e-3 to 1e5, log, 20 per decade
%       pressure [Pa]              10 to 1e6, log, 20 per decade
%       force_per_length [N/m]     10 to 1e7, log, 20 per decade
%       velocity                   0 to 30, step 0.01
%       angle [deg]                0 to 90, step 0.1
%       time [s]                   0 to 40, step 0.01
%       dimensionless, other       0.01 to 20, step 0.01
%   The same grid serves the TC and XC curves of a response, so the
%   combined (CC) curve reads both on it (call_hazard_curve_combiner).
%   response_values only checks the coverage: finite values (log grids:
%   values > 0) outside the range give the warning
%   response_hazard_grid:outsideRange (how many, their minimum and
%   maximum); the registry hazard_grid override can widen the range. The
%   grid is not extended.
%
%   Inputs:
%     name            - registry name of the response, char
%     response_values - fitted curve values checked against the range (no
%                       lake level added) [response units], array
%                       (optional, default [])
%   Outputs:
%     grid - response levels [response units], ascending double column
%
%   Tier: internal
%
%   See also response_registry, exceedance_at_response,
%   call_hazard_curve_builder, call_hazard_curve_combiner.

if nargin < 2
    response_values = [];
end
settings = grid_settings(name);
low = settings.range(1);
high = settings.range(2);
% A Range End On A Grid Point Is Not Pushed One Step Out By The Rounding
tolerance = 1e-9;
values = response_values(isfinite(response_values));
switch settings.spacing
    case 'linear'
        last = ceil((high - low)/settings.step - tolerance);
        grid = low + (0:last)'*settings.step;
    case 'log'
        values = values(values > 0);
        n = settings.points_per_decade;
        first = floor(n*log10(low) + tolerance);
        last = ceil(n*log10(high) - tolerance);
        grid = 10.^((first:last)'/n);
end
outside = values(values < low | values > high);
if ~isempty(outside)
    warning('response_hazard_grid:outsideRange',...
        ['%s: %d hazard curve values fall outside the hazard grid range [%g, %g] (min %g, max %g) and are not ',...
        'covered by the grid. The hazard_grid override of its response_registry row can widen the range.'],...
        name, numel(outside), low, high, min(outside), max(outside));
end
end

%% LOCAL FUNCTIONS
function settings = grid_settings(name)
row = response_registry('name', name);
unit_kind = '';
if ~isempty(row)
    if ~isempty(row.hazard_grid)
        settings = row.hazard_grid;
        return
    end
    unit_kind = row.unit_kind;
end
linear = @(range, step) struct('range', range, 'spacing', 'linear', 'step', step);
logarithmic = @(range) struct('range', range, 'spacing', 'log', 'points_per_decade', 20);
switch unit_kind
    case 'length'
        settings = linear([0 30], 0.01);
    case 'discharge_per_length'
        settings = logarithmic([1e-7 10]);
    case 'volume_per_length'
        settings = logarithmic([1e-3 1e5]);
    case 'pressure'
        settings = logarithmic([10 1e6]);
    case 'force_per_length'
        settings = logarithmic([10 1e7]);
    case 'velocity'
        settings = linear([0 30], 0.01);
    case 'angle'
        settings = linear([0 90], 0.1);
    case 'time'
        settings = linear([0 40], 0.01);
    otherwise
        settings = linear([0.01 20], 0.01);
end
end

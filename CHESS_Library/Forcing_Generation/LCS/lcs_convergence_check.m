function res = lcs_convergence_check(lambda, N, nLC, tol, c, p, stm_type, quiet)
% lcs_convergence_check  Life cycles needed for converged LCS storm counts.
%   res = lcs_convergence_check(lambda, N, nLC, tol, c, p, stm_type)
%   res = lcs_convergence_check(..., quiet)
%
%   Estimates how many life cycles a full Poisson LCS
%   (lcs_restrict_sampling_rate = 0) needs so the life-cycle storm count
%   statistics are converged, and prints a short report. The storm count
%   of a life cycle is Poisson(lambda*N). Two requirements, the largest
%   governs:
%     - Mean: relative half-width of the c-confidence interval of the mean
%       storm count <= tol -> nLC_mean = ceil((z/tol)^2 / (lambda*N)),
%       z = norminv((1+c)/2).
%     - Percentiles: smallest candidate nLC (25*2^k, up to 102400) whose
%       sample percentiles (prctile, MATLAB default) are within
%       max(1, tol*x_p) storms of the exact Poisson percentile x_p in a
%       fraction c of 1000 repeats.
%   Percentiles below the storm-free share exp(-lambda*N) are 0 storms
%   (reported only). The random draws of this check do not affect the
%   LCS: the global random number generator state is restored on exit
%   (also on error).
%
%   Inputs:
%     lambda   - storm rate [storms/yr], scalar double
%     N        - life-cycle length, mcs_nYears [years], scalar double
%     nLC      - number of life cycles, mcs_nLC, scalar double
%     tol      - relative tolerance, lcs_convergence_tol [-], scalar double
%     c        - confidence level, lcs_convergence_confidence [-], scalar
%                double
%     p        - percentile levels [%], from project_CLs (e.g. [16 84]),
%                double vector
%     stm_type - storm type label for the report ('XC', 'TC'), char
%     quiet    - (optional, default false) true: no printed report (e.g.
%                plots and the GUI dialog), logical
%   Outputs:
%     res - lamN (lambda*N), cv (1/sqrt(lamN)), p0 (storm-free share
%           exp(-lamN)), zero_pct (levels of p below p0, as fractions),
%           nLC_mean, nLC_pct (Inf above the cap), nLC_req (largest of
%           both), nLC, converged (nLC >= nLC_req) and nLC_cap (102400),
%           1x1 struct
%
%   Tier: internal
%
%   See also lcs_convergence_checks, chess_lcs.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if nargin < 8
    quiet = false;
end
s = rng;
restore_rng = onCleanup(@() rng(s));

R = 1000;           % Repeats Per Candidate
nLC_cap = 102400;   % Largest Candidate
max_draws = 1e7;    % Poisson Draws Per Chunk (Memory)

p = p(:)/100;
lamN = lambda*N;
res.lamN = lamN;
res.cv = 1/sqrt(lamN);
res.p0 = exp(-lamN);
res.zero_pct = p(res.p0 > p)';

%% MEAN STORM COUNT
z = norminv((1 + c)/2);
res.nLC_mean = ceil((z/tol)^2/lamN);

%% PERCENTILES OF THE STORM COUNT
x_p = poissinv(p, lamN);
allowed = max(1, tol*x_p);
res.nLC_pct = Inf;
for n = 25*2.^(0:floor(log2(nLC_cap/25)))
    est = zeros(numel(p), R);
    chunk = max(1, min(R, floor(max_draws/n)));
    for r0 = 1:chunk:R
        r = r0:min(R, r0 + chunk - 1);
        est(:, r) = prctile(poissrnd(lamN, n, numel(r)), 100*p, 1);
    end
    e = sort(abs(est - x_p), 2);
    if all(e(:, ceil(c*R)) <= allowed)
        res.nLC_pct = n;
        break
    end
end
res.nLC_req = max(res.nLC_mean, res.nLC_pct);
res.nLC = nLC;
res.converged = nLC >= res.nLC_req;
res.nLC_cap = nLC_cap;

%% REPORT
if quiet
    return
end
fprintf('   LCS convergence check (%s, full Poisson sampling):\n', stm_type);
fprintf('      Expected storms per life cycle (lambda x mcs_nYears): %.3f (CV %.3f)\n', lamN, res.cv);
fprintf('      Storm-free life cycles: %.1f%%\n', 100*res.p0);
if ~isempty(res.zero_pct)
    fprintf('      Percentile(s) %s are 0 storms (below the storm-free share)\n', mat2str(100*res.zero_pct));
end
if isinf(res.nLC_pct)
    pct_txt = sprintf('> %d', nLC_cap);
else
    pct_txt = sprintf('%d', res.nLC_pct);
end
fprintf('      Life cycles needed: mean %d, percentiles %s -> required %s (tol %g, confidence %g)\n',...
    res.nLC_mean, pct_txt, num2str(res.nLC_req), tol, c);
if res.converged
    fprintf('      mcs_nLC = %d: converged\n', nLC);
else
    fprintf('      mcs_nLC = %d: NOT converged\n', nLC);
end
end

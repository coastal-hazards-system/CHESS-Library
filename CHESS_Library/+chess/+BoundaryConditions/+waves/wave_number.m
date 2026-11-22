function[km,kmest,ERROR] = wave_number(T,depth,grav)
% wave_number  Wave number from the linear wave theory dispersion relation.
%   [km, kmest, ERROR] = wave_number(T, depth, grav) solves the linear wave
%   theory dispersion relation for the wave number, k = 2*pi/L, by Newton
%   iteration. It also returns an empirical estimate using the relation from
%   Guo, J. (2002), "Simple and explicit solution of wave dispersion
%   equation", Coastal Engineering, Vol 45, No. 2, pp 71-74.
%
%   The operations are element-wise, so T and depth may be arrays (same
%   size, or compatible sizes for implicit expansion). Each element takes its
%   own branch and converges on its own: the initial guess is WHSQ where
%   WHSQ > 1 (deep water) and sqrt(WHSQ) elsewhere, and an element leaves
%   the Newton loop once its correction is no larger than TOL = 1e-5 (or
%   at once when the deep- or shallow-water limit already holds). The loop
%   stops after 50 iterations: elements still not converged are set to NaN
%   with warning 'chess:BoundaryConditions:waves:wave_number:notConverged'. NaN inputs give NaN, and
%   a negative depth (WHSQ < 0) gives NaN without a warning. A scalar call
%   follows the same steps as the original scalar routine.
%
%   Inputs:
%     T     - wave period [s], double scalar or array
%     depth - water depth [m or ft], double scalar or array (same size as T,
%             or compatible)
%     grav  - acceleration of gravity [m/s^2 or ft/s^2], scalar double (use
%             the same length unit as depth)
%   Outputs:
%     km    - wave number from the dispersion relation [1/m or 1/ft], double,
%             size of T and depth combined
%     kmest - wave number empirical estimate (Guo 2002) [1/m or 1/ft],
%             double, same size as km
%     ERROR - 1 when the iteration converged, 0 when the slope check failed
%             for any element (that element keeps its last iterate) [-],
%             scalar double (one flag for the whole array)
%
%   Developed by: Jeff Melby

% HISTORY: Jeff Melby 4/27/09 (wavenum).

TOL = 1.0E-5;
MAX_ITER = 50;
ERROR = 1;
fq = 1./T;
WHSQ = (depth./grav).*(2*pi*fq).^2;
X1 = WHSQ;
X1(WHSQ < 0) = NaN;  % set before sqrt so the array never turns complex
X1 = sqrt(X1);
deep = WHSQ > 1.0;
X1(deep) = WHSQ(deep);
done = (deep & tanh(X1) > 1-TOL) | (~deep & abs(X1-tanh(X1)) < TOL) | isnan(WHSQ) | WHSQ < 0;
active = ~done;
for iter = 1:MAX_ITER
    idx = find(active);
    if isempty(idx), break, end
    x = X1(idx);
    numer = x.*tanh(x) - WHSQ(idx);
    denom = tanh(x) + x./cosh(x).^2;
    slope_fail = abs(denom) < TOL;
    corr = numer./denom;
    corr(slope_fail) = 0;
    X1(idx) = x - corr;
    if any(slope_fail), ERROR = 0; end
    active(idx(slope_fail | ~(abs(corr) > TOL))) = false;
end
if any(active(:))
    X1(active) = NaN;
    warning('chess:BoundaryConditions:waves:wave_number:notConverged', ...
        'wave_number: %d of %d element(s) did not converge in %d iterations; set to NaN.', ...
        nnz(active), numel(active), MAX_ITER);
end
km = X1./depth;
% check against the empirical estimate
arg=2*pi./T.*sqrt(depth./grav);
A = grav.*T.^2/2/pi;
wavelen = A.*(1-exp(-(arg.^2.5))).^(0.4);
kmest = (2*pi)./wavelen;
return
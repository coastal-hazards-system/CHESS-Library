function[km,kmest,ERROR] = wavnum1_VG(T,depth,grav)
% wavnum1_VG  Wave number from the linear wave theory dispersion relation.
%   [km, kmest, ERROR] = wavnum1_VG(T, depth, grav) solves the linear wave
%   theory dispersion relation for the wave number, k = 2*pi/L, by Newton
%   iteration. It also returns an empirical estimate using the relation from
%   Guo, J. (2002), "Simple and explicit solution of wave dispersion
%   equation", Coastal Engineering, Vol 45, No. 2, pp 71-74.
%
%   The operations are element-wise, so T and depth may be arrays (same
%   size, or compatible sizes for implicit expansion). With arrays the
%   branch tests act on the whole array: the shallow-water initial guess
%   sqrt(WHSQ) is used unless every element has WHSQ > 1, the Newton loop
%   runs until every element has converged, and ERROR is a single flag.
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
%             (in case slope causes error) [-], scalar double (one flag for
%             the whole array)
%
%   Tier: internal
%
%   Developed by: Jeff Melby

% HISTORY: Jeff Melby 4/27/09 (wavenum).

TOL = 1.0E-5;
CORR = 2 * TOL;
ERROR = 1;
fq = 1./T;
% solve for kh(x1) using iterative method
% initial guess for X1 based on WHSQ
WHSQ = (depth./grav).* (2*pi*fq).^2;
if WHSQ > 1.0
   X1 = WHSQ;
   if tanh(X1) > 1.-TOL  % deep water limits
     CORR = TOL - 1e-6;  % done, return to calling program
   end
else  
   X1 = sqrt(WHSQ);
   if abs(X1-tanh(X1)) < TOL % shallow water limits
     CORR = TOL - 1e-6;  % done, return to calling program
   end
end

%
% iterative loop
while abs(CORR) > TOL
%   while ERROR >0
      numer = X1 .* tanh(X1) - WHSQ;
      denom = tanh(X1) + X1./(cosh(X1)).^2;
% Check slope to avoid divide by zero
      if abs(denom) < TOL
         ERROR = 0; %ERROR IN SLOPE CHECK IN WAVNUM SUBROUTINE
         CORR = TOL - 1e-6;
      else
         CORR = numer./denom;
         X1 = X1 - CORR;
      end
%   end
end
km = X1 ./ depth;
% check against the empirical estimate
arg=2*pi./T.*sqrt(depth./grav);
A = grav.*T.^2/2/pi;
wavelen = A.*(1-exp(-(arg.^2.5))).^(0.4);
kmest = (2*pi)./wavelen;
return
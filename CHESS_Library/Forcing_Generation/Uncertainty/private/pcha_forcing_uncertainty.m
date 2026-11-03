function iVar_w_u = pcha_forcing_uncertainty(iVar, u_a, u_r, normU)
% pcha_forcing_uncertainty  Perturb a forcing variable with PCHA uncertainty.
%   iVar_w_u = pcha_forcing_uncertainty(iVar, u_a, u_r, normU)
%
%   iVar_w_u = iVar + u .* normU, with the uncertainty u from the absolute
%   and relative terms a = u_a + iVar and r = u_r .* iVar:
%     u_a == 0: u = abs(r)
%     u_r == 0: u = a
%     otherwise: u = sign(a) ./ sqrt(1./a.^2 + 1./r.^2)
%   With symmetric z-scores, the mean of iVar_w_u over the replicate
%   columns is iVar and its standard deviation is about u.
%
%   Inputs:
%     iVar  - forcing variable (SWL as surge [m] or Hm0 [m]), nSteps x
%             n_replicates double
%     u_a   - absolute uncertainty (units of iVar), scalar double
%     u_r   - relative uncertainty [-], scalar double
%     normU - standard normal z-scores [-], 1 x n_replicates double
%   Outputs:
%     iVar_w_u - perturbed variable (units of iVar), same size as iVar
%
%   Tier: internal
%
%   See also apply_uncertainty.

a = u_a+iVar; r = u_r.*iVar;
if u_a == 0
    u_iVar = 1./sqrt(1./(r).^2);
elseif u_r == 0
    u_iVar = 1./sqrt(1./(a).^2);
    u_iVar = u_iVar .* (a./abs(a));
else
    u_iVar = 1./sqrt(1./(a).^2 + 1./(r).^2);
    u_iVar = u_iVar .* (a./abs(a));
end
iVar_w_u = iVar + u_iVar.*normU;
end
function iVar_w_u = pcha_forcing_uncertainty(iVar, u_a, u_r, normU)
% pcha_forcing_uncertainty  Perturb a forcing variable with PCHA uncertainty.
%   iVar_w_u = pcha_forcing_uncertainty(iVar, u_a, u_r, normU)
%
%   iVar_w_u = iVar + u .* normU, with u the 'combined' standard deviation
%   of combined_uncertainty (absolute term u_a, relative term u_r .* iVar):
%     u_r == 0: u = u_a
%     u_a == 0: u = abs(u_r .* iVar)
%     otherwise: u = 1 ./ sqrt(1/u_a^2 + 1./(u_r .* iVar).^2)
%   u is never negative. With symmetric z-scores, the mean of iVar_w_u over
%   the replicate columns is iVar and its standard deviation is about u.
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
%   See also apply_uncertainty, combined_uncertainty.

iVar_w_u = iVar + combined_uncertainty(iVar, u_a, u_r).*normU;
end

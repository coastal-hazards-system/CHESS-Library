function [gamma_beta_r2p,gamma_beta_q] = oblique_waves_influence_factor(Nstrm)
% oblique_waves_influence_factor  EurOtop oblique wave factors (ones).
%   [gamma_beta_r2p, gamma_beta_q] = oblique_waves_influence_factor(Nstrm)
%       returns ones for both factors: oblique wave attack is not
%       implemented in CHESS (normal incidence). EurOtop (2018) Eq. 6.9
%       (rubble mounds) and Eqs. 5.28-5.31 (levees) are the planned forms.
%
%   Inputs:
%     Nstrm          - size vector of the output, e.g. size(Hm0) (passed
%                      to ones)
%   Outputs:
%     gamma_beta_r2p - oblique wave factor for run-up [-], ones(Nstrm)
%     gamma_beta_q   - oblique wave factor for overtopping [-], ones(Nstrm)
%
%   Tier: public
%
%   See also Eurotop_r2p_q_Final, berm_influence_factor,
%   surface_roughness_influence_factor, wall_influence_factor.

    % Oblique wave coefficients - Not implemented in CHESS as of 9/03/20
    % will use Eurotop eq 6.9 for RM ; eq. 5.28-5.31 for levees
    gamma_beta_r2p = ones(Nstrm);
    gamma_beta_q   = ones(Nstrm);
end
function[z1p] = z1p_calc(H,Tmm1,Rc,Sslp,grav)
% z1p_calc  Wave run-up exceeded by 1 percent of the incident waves.
%   z1p = z1p_calc(H, Tmm1, Rc, Sslp, grav) returns the run-up height z1%
%       on a rough (rubble mound) slope for every forcing row.
%
%   van Gent run-up formulation with c0 = 1.45, c1 = 5.1,
%   c2 = 0.25*c1^2/c0 and p = 0.5*c1/c0:
%     z1p = gamma*H*c0*xi            for xi <= p
%     z1p = gamma*H*(c1 - c2/xi)     for xi > p
%   with xi = 1/(Sslp*sqrt(H/Lmm1)), Lmm1 = grav*Tmm1^2/(2*pi) and
%   gamma = gamma_f*gamma_beta, gamma_beta = 1 (normal incidence) and the
%   rubble mound roughness gamma_f = 0.55 for xi <= 2,
%   0.05625*(xi - 2) + 0.55 for 2 < xi < 10 and 1.0 for xi >= 10.
%   Freeboard restriction: z1p = 0 where Rc < 0.6 (in the units of Rc,
%   i.e. 0.6 m in CHESS).
%
%   Inputs (H, Tmm1 and Rc of the same size):
%     H    - spectral significant wave height at the toe [m]
%     Tmm1 - spectral wave period T_m-1,0 [s] (CHESS: Tp/1.1)
%     Rc   - freeboard, crest elevation - SWL [m]
%     Sslp - seaward slope cot(alpha) [-], scalar
%     grav - gravitational acceleration [m/s^2], scalar
%   Outputs:
%     z1p  - run-up height above SWL exceeded by 1 percent of the incident
%            waves [m], size of H
%
%   Tier: public
%
%   See also u1p_calc, leeside_armor_stone_damage,
%   ann_rubblemound_stability, Eurotop_r2p_q_Final.
%
%   Developed by: Jeffrey A. Melby (JAM)

% HISTORY OF REVISIONS:
%     Written by Jeff Melby April 2009
%     updated by JAM on 2-10-12 to use van Gent equations

%============================================================


%============================================================
  % preliminary calculations
  Lmm1=grav.*Tmm1.^2./2./pi;
  som  = H./Lmm1;
  SSPm = 1./Sslp./sqrt(som);  % Iribarren param
  c0 = 1.45;
  c1 = 5.1;
  c2 = 0.25.*c1.^2./c0;
  pR = 0.5.*c1./c0;

  % roughness coefficient for rubble mound
  gamf = 0.05625.*(SSPm-2)+0.55;
  gamf(SSPm <= 2) = 0.55;
  gamf(SSPm >= 10) = 1.0;


  gam_beta = 1.0;   % reduction factor for wave obliquity
  gamma = gamf.*gam_beta;
  %============================================================

  %============================================================
  % Runup
  z1p = gamma .* H .* (c1 - c2./SSPm);
  z1p(SSPm <= pR) = gamma(SSPm <= pR) .* H(SSPm <= pR) .* c0 .* SSPm(SSPm <= pR);
  % Freeboard Restriciton
  z1p(Rc<0.6) = 0;
  %============================================================

return
function[S,u1p] = leeside_armor_stone_damage(SLast,...
    H, Tmm1, u1p_last, LDn, Lslp, Sslp, WL, Rc, Nz, Delta, K_ls1, K_ls2, crest_width, crest_elevation, grav, compute_S_submerged, cutoff_switch, cutoff)
% leeside_armor_stone_damage  Leeside armor damage after one forcing row.
%   [S, u1p] = leeside_armor_stone_damage(SLast, H, Tmm1, u1p_last, LDn,
%       Lslp, Sslp, WL, Rc, Nz, Delta, K_ls1, K_ls2, crest_width,
%       crest_elevation, grav, compute_S_submerged, cutoff_switch, cutoff)
%       returns the leeside (rear-side) armor damage S after one forcing
%       row, starting from the damage SLast of the previous row, and the
%       crest velocity u1p of the row.
%
%   Melby revision of the van Gent and Pozueta (2004) rear-side stability
%   formula (coefficients after Melby 2009). The run-up z1p (z1p_calc) and
%   the crest velocity u1p (u1p_calc) are computed with Rc, or with the
%   freeboard of the raised crest crest_elevation + cutoff - WL when
%   cutoff_switch = 1. When the run-up exceeds the crest (z1p - Rc > 0)
%   and u1p > 0:
%     als = Lslp^(-2.5/r)*(1 + 10*exp(-Rc/H))^(1/r)
%     Nls = u1p*Tmm1/(sqrt(Delta)*LDn*K_ls1)
%     Nze = (SLast/(K_ls2*(als*Nls)^r))^2
%     S   = K_ls2*sqrt(Nze + Nz)*(als*Nls)^r
%   with r = 6 for an undamaged armor (SLast = 0) and r = 1 with
%   K_ls2 = 0.04 (the input K_ls2 is replaced) once SLast > 0. Otherwise
%   S = SLast; when the run-up stays below the crest u1p = u1p_last.
%   compute_S_submerged = 1 with Rc < 0 keeps S = SLast (submerged damage
%   is not implemented).
%
%   Inputs (scalars, one forcing row):
%     SLast               - leeside damage after the previous row [-]
%     H                   - spectral significant wave height at the toe [m]
%     Tmm1                - spectral wave period T_m-1,0 [s] (CHESS:
%                           Tp/1.1, converted by chess_csr_dpa)
%     u1p_last            - crest velocity of the previous row [m/s]
%     LDn                 - leeside armor nominal diameter Dn50 [m]
%     Lslp                - leeside slope cot(beta) [-]
%     Sslp                - seaward slope cot(alpha) [-]
%     WL                  - still water level [m, study datum, positive up]
%                           (used only when cutoff_switch = 1)
%     Rc                  - freeboard, crest elevation - SWL [m]
%     Nz                  - number of waves in the row, dt/Tm [-]
%     Delta               - armor relative buoyant density [-]
%     K_ls1, K_ls2        - leeside damage coefficients [-]
%                           (CHESS_empirical_coefficients.txt)
%     crest_width         - crest width [m]
%     crest_elevation     - crest elevation [m, study datum, positive up]
%                           (used only when cutoff_switch = 1)
%     grav                - gravitational acceleration [m/s^2]
%     compute_S_submerged - 0 or 1 (CHESS: 0)
%     cutoff_switch       - 0 actual crest, 1 crest raised by cutoff
%     cutoff              - crest elevation offset [m]
%   Outputs:
%     S                   - accumulated leeside damage [-]
%     u1p                 - crest velocity exceeded by 1 percent of the
%                           waves [m/s]
%
%   Tier: public
%
%   See also seaside_armor_stone_damage, z1p_calc, u1p_calc,
%   load_empirical_coefficients.
%
%   Developed by: Jeffrey A. Melby (JAM)

% HISTORY OF REVISIONS:
%     Written by Jeff Melby April 2009
%============================================================
% Inside CHESS the input for period is already converted with parent code chess_csr_dpa.m /1.1;     % spectral mean wave period in sec
%============================================================
% Coeffs from Melby 2009
if SLast>0
    K_ls2=0.04;
    r=1;
else
    r=6;
end

%============================================================
% Check to see if runup exceeds the crest elevation.
% If not, then no leeside calculation is required.
% If there is velocity on crest, compute damage

% Restrictions Taken Care Of By u1p & z1p (Ru)
% Rc >= 0.6 else z1p = 0
% Rc/Hs >= 0.3 else u1p = 0
% z1p-Rc > 0 else u1p = 0
% z1p = 0 then u1p = 0


if cutoff_switch == 0 % Evaluate Actual Design
    % Compute Run-up Exceeded By 1% Of The Incident Waves
    [z1p] = z1p_calc(H, Tmm1, Rc, Sslp, grav);
    % Compute Crest Velocity Exceeded By 1% Of The Incident Waves
    u1p = u1p_calc(crest_width, Rc, z1p, Tmm1, H, Sslp, grav);
else % Artificially Increase Freeboard (Raise Structure)
    % Compute "New" Crest Elevation
    cutoff_elevation = crest_elevation + cutoff;
    % Compute Artificial Freeboard
    Rc_artificial = cutoff_elevation - WL;
    % Recompute u1p, z1p
    % Compute Run-up Exceeded By 1% Of The Incident Waves
    [z1p] = z1p_calc(H, Tmm1, Rc_artificial, Sslp, grav);
    % Compute Crest Velocity Exceeded By 1% Of The Incident Waves
    u1p = u1p_calc(crest_width, Rc_artificial, z1p, Tmm1, H, Sslp, grav);
end
%
if Rc<0 && compute_S_submerged == 1
    % Call Submerged Equation Here
    % The "Potential" Damage (S_pot): This calculates how much damage the current wave conditions would cause if they persisted for exactly N_ref waves.
    % Formula is typically are  calibrated to N_ref = 3000 waves. 
    % By using this as a reference, we can calculate the "potential damage" for the current hour and then scale it based on
    % the square-root-of-time rule (S proportional sqrt{N}) to maintain consistency with your Melby seaside functions.
    %     Nref = 3000;
    % [S, S_pot] = submerged_armor_stone_damage(h, SLast, H, Tp, crest_elevation, LDn, Delta, grav, Nref, Nz);
    S= SLast;
elseif (z1p-Rc)>0 % In case of Rc<0 this will be true
    if u1p > 0 % u1p already accounts for Rc<0 restriction
        als = (Lslp^(-2.5/r))*(1 + 10*exp(-Rc/H))^(1/r);
        Nls = u1p*Tmm1/sqrt(Delta)/LDn/K_ls1;
        Nze = (SLast/K_ls2/(als*Nls)^r)^2;
        S= K_ls2*sqrt(Nze+Nz)*(als*Nls)^r;
    else
        S= SLast;
    end
else
    S = SLast;
    u1p=u1p_last;
end
% Equation Validity Range
% Eq_invalid_range = any([Nz>=4000,...
% Rc./H<0.3 | Rc./H>6,...
% crest_width./H<1.3 | crest_width./H>1.6,...
% H./(Delta.*LDn)<5.5 | H./(Delta.*LDn)<8.5,...
% (Ru-Rc)./(gamma_f.*H)<0 | (Ru-Rc)./(gamma_f.*H)>1.4]);
% % If Any Of The Conditions Yields True , Neglect Damage
% if Eq_invalid_range
%     S = SLast;
%     u1p = u1p_last;
% end
%============================================================
return

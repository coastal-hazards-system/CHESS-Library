
function u1p = u1p_calc(wdth,Rc,z1p,Tmm1,H,Sslp,grav)
% u1p_calc  Crest flow velocity exceeded by 1 percent of the incident waves.
%   u1p = u1p_calc(wdth, Rc, z1p, Tmm1, H, Sslp, grav) returns the
%       overtopping flow velocity u1% on the crest for every forcing row.
%
%   u1p = 1.7*sqrt(grav*H)*sqrt(gamma_c)*sqrt((z1p - Rc)/(gamma_f*H))
%         /(1 + 0.1*wdth/H)
%   with the crest roughness gamma_c = gamma_f and the rubble mound
%   roughness gamma_f = 0.55 for xi <= 2, 0.05625*(xi - 2) + 0.55 for
%   2 < xi < 10 and 1 for xi >= 10, xi = 1/(Sslp*sqrt(H/Lmm1)) and
%   Lmm1 = grav*Tmm1^2/(2*pi). u1p = 0 where there is no run-up
%   (z1p = 0), where the run-up stays below the crest (z1p - Rc < 0) and
%   where Rc/H < 0.3 (van Gent and Pozueta validity limit).
%
%   Inputs (Rc, z1p, Tmm1 and H of the same size):
%     wdth - crest width [m], scalar
%     Rc   - freeboard, crest elevation - SWL [m]
%     z1p  - run-up height exceeded by 1 percent of the waves [m]
%            (z1p_calc)
%     Tmm1 - spectral wave period T_m-1,0 [s] (CHESS: Tp/1.1)
%     H    - spectral significant wave height at the toe [m]
%     Sslp - seaward slope cot(alpha) [-], scalar
%     grav - gravitational acceleration [m/s^2], scalar
%   Outputs:
%     u1p  - crest flow velocity exceeded by 1 percent of the incident
%            waves [m/s], size of Tmm1
%
%   Tier: public
%
%   See also z1p_calc, leeside_armor_stone_damage.

    % Spectral Mean Wave Length
    Lmm1=grav*Tmm1.^2./2./pi;
    % Spectral Mean Wave Slope
    som = H./Lmm1;
    % Surf Similarity Parameter
    SSPm=1./Sslp./sqrt(som);
    % Friction Factor
    gamf = zeros(size(Tmm1));
    gamf(SSPm<=2) = 0.55;
    gamf(SSPm>2 & SSPm<10) = 0.05625.*(SSPm(SSPm>2 & SSPm<10)-2)+0.55;
        gamf(SSPm>=10) = 1;
    % friction factor for crest
    gam_crest =gamf;
    % Compute u1%
    u1pNum=sqrt((z1p-Rc)./gamf./H); % What To Do When z1p-Rc
    u1pNum(z1p == 0) = 0; % If there is no overtopping, there can't be flow velocity.
    u1pDenom=1+0.1.*wdth./H;
    u1p=sqrt(grav.*H).*1.7.*sqrt(gam_crest).*u1pNum./u1pDenom;
    u1p((z1p-Rc)<0) = 0;
    u1p(Rc./H<0.3)=0; %JAM added on 2/23/26 from v&P paper.
end
function [S,Szero] = seaside_armor_stone_damage(depth,SLast,...
    Hsig,Tm,crest_elevation,Sslp,SDn,SG,grav,P,Nz,Rc,Szerolim,cutoff,WL,cutoff_switch,km1,km2,Ks,dS,compute_S_submerged)
% seaside_armor_stone_damage  Seaside armor damage after one forcing row.
%   [S, Szero] = seaside_armor_stone_damage(depth, SLast, Hsig, Tm,
%       crest_elevation, Sslp, SDn, SG, grav, P, Nz, Rc, Szerolim, cutoff,
%       WL, cutoff_switch, km1, km2, Ks, dS, compute_S_submerged) returns
%       the seaside armor damage S after one forcing row, starting from the
%       damage SLast of the previous row (Melby damage progression).
%
%   With the water depth h = depth, the wave number at h from wavnum1_VG
%   (Lm = 2*pi/km, sm = Hsig/Lm) and the momentum flux parameter
%     Mf = A0*(h/(grav*Tm^2))^(-A1), A0 = 0.639*(Hsig/h)^2.026,
%     A1 = 0.180*(Hsig/h)^(-0.391),
%   the stability number Nm = sqrt(Mf/(SG - 1))*h/SDn and
%     am = 1/(km1*P^0.18*sqrt(Sslp))                   if sm >= Sslp^(-3)
%                                                      (plunging)
%     am = 1/(km2*P^0.18*Sslp^(0.5 - P)*sm^(-P/3))     otherwise (surging)
%   the damage of this row alone is Szero = Ks*sqrt(Nz)*(am*Nm)^5 and the
%   accumulated damage, with the equivalent number of waves of the
%   previous damage Nze = (SLast/(Ks*(am*Nm)^5))^2, is
%     S = dS + Ks*sqrt(Nze + Nz)*(am*Nm)^5.
%   S grows only when Szero > Szerolim and Rc/SDn >= 1 (cutoff_switch = 1:
%   (crest_elevation + cutoff - WL)/SDn >= 1); otherwise S = SLast. No
%   wave attack (Hsig <= 0.1 or depth <= 0): S = SLast and Szero = 0.
%   compute_S_submerged = 1 with Rc < 0 keeps S = SLast (submerged damage
%   is not implemented).
%
%   Inputs (scalars, one forcing row):
%     depth               - water depth at the toe, SWL - toe elevation [m]
%     SLast               - seaside damage after the previous row [-]
%     Hsig                - spectral significant wave height at the toe [m]
%     Tm                  - mean wave period [s] (CHESS: Tp/1.2)
%     crest_elevation     - crest elevation [m, study datum, positive up]
%                           (used only when cutoff_switch = 1)
%     Sslp                - seaward slope cot(alpha) [-]
%     SDn                 - seaside armor nominal diameter Dn50 [m]
%     SG                  - armor specific gravity, 1 + Delta [-]
%     grav                - gravitational acceleration [m/s^2]
%     P                   - notional permeability [-]
%     Nz                  - number of waves in the row, dt/Tm [-]
%     Rc                  - freeboard, crest elevation - SWL [m]
%     Szerolim            - minimum row damage Szero that accumulates [-]
%                           (CHESS: 0.2)
%     cutoff              - crest elevation offset for the cutoff check [m]
%     WL                  - still water level [m, study datum, positive up]
%                           (used only when cutoff_switch = 1)
%     cutoff_switch       - 0 actual crest, 1 crest raised by cutoff in the
%                           validity check
%     km1, km2            - plunging and surging damage coefficients [-]
%                           (CHESS_empirical_coefficients.txt)
%     Ks                  - damage coefficient [-] (CHESS: k_si before and
%                           during the first damaging storm, k_sp after)
%     dS                  - damage offset added when S grows [-] (CHESS:
%                           0.5 before and during the first damaging storm,
%                           0 after)
%     compute_S_submerged - 0 or 1 (CHESS: 0)
%   Outputs:
%     S                   - accumulated seaside damage [-]
%     Szero               - damage of this row starting from zero [-]
%
%   Tier: public
%
%   See also leeside_armor_stone_damage, load_empirical_coefficients,
%   wavnum1_VG.

%% DAMAGE (S) COMPUTATION
if (Hsig>0.1) && (depth>0)
    %% DEFINE WATER COLUM AND WAVE PARAMETERS
    % Define Water Column
    h = depth;
    % Estimate Wave Number
    [km,~,~] = wavnum1_VG(Tm,h,grav);
    % Compute Wave Length
    Lm = 2*pi/km;
    % Compute Wave Steepness
    sm = Hsig/Lm;
    % Determine Critical Wave Steepness Continous
    smc = Sslp^-3;

    %% MOMENTUM FLUX COMPUTATIONS
    A0 = 0.639*(Hsig/h)^2.026;
    A1 = 0.180*(Hsig/h)^-0.391;
    Mf = A0*(h/grav/Tm^2)^-A1;

    %% DETERMINE am RELATIONSHIP TO USE BASED ON WAVE STEEPNESS
    if sm>=smc
        am = 1/(km1*P^0.18*sqrt(Sslp)); %plunging
    else
        am = 1/(km2*P^0.18*Sslp^(0.5-P)*sm^(-P/3)); %surging
    end

    %% COMPUTE Nm & Nze
    Nm = sqrt(Mf/(SG-1)) * h/SDn;
    Nze = (SLast/Ks/(am*Nm)^5)^2;

    %% COMPUTE Szero
    Szero = Ks*sqrt(Nz)*(am*Nm)^5;

    %% CUTOFF ANALYSIS FOR STRUCTURE SUBMERGENCE
    if Szero > Szerolim
        % Verify Validity Range
        if cutoff_switch == 0 % Evaluate Actual Design 
            Eq_range = Rc/SDn>=1 & Rc/SDn<=Inf;
        else % Artificially Increase Freeboard (Raise Structure)
            % Compute "New" Crest Elevation
            cutoff_elevation = crest_elevation + cutoff;
            % Compute Artificial Freeboard
            Rc_artificial = cutoff_elevation - WL;
            % Define New 
            Eq_range = Rc_artificial/SDn>=1 & Rc_artificial/SDn<=Inf;
        end
        % Compute Damage If Within Equation Bounds
        if Eq_range % This is a scalar bool
            % Compute Damage Accumulation
            S=dS + Ks*sqrt(Nze+Nz)*(am*Nm)^5;
        elseif Rc<0 && compute_S_submerged == 1
            % Call Submerged Equation Here
            % The "Potential" Damage (S_pot): This calculates how much damage the current wave conditions would cause if they persisted for exactly N_ref waves.
            % Formula is typically are  calibrated to N_ref = 3000 waves.
            % By using this as a reference, we can calculate the "potential damage" for the current hour and then scale it based on
            % the square-root-of-time rule (S proportional sqrt{N}) to maintain consistency with your Melby seaside functions.
            %     Nref = 3000;
            % [S, S_pot] = submerged_armor_stone_damage(h, SLast, Hsig, Tm*1.1, crest_elevation, SDn, Delta, grav, Nref, Nz);     
            S=SLast;
        else
            S=SLast;
        end
    else
        S=SLast;
    end
else
    % If No New Damage Carry Previous Damage Level
    S= SLast;
    Szero = 0;
end
end
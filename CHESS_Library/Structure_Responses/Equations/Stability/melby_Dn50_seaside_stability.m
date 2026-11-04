function [Dn50_Melby] = melby_Dn50_seaside_stability(Hsig,Tm,h,duration,Sslp,delta,P,S,grav,km1,km2,Rc)
% melby_Dn50_seaside_stability  Seaside armor stone size from the momentum flux.
%   Dn50_Melby = melby_Dn50_seaside_stability(Hsig, Tm, h, duration, Sslp,
%       delta, P, S, grav, km1, km2, Rc) returns the seaside median nominal
%       armor stone diameter of a rubble mound that reaches the damage
%       level S (Melby and Kobayashi momentum-flux stability).
%
%   Mf = A0*(h/(grav*Tm^2))^(-A1), A0 = 0.639*(Hsig/h)^2.026,
%   A1 = 0.180*(Hsig/h)^(-0.391); sm = Hsig/Lm with Lm from wavnum1_VG
%   (Tm, h); critical steepness smc = Sslp^-3; plunging (sm >= smc)
%   am = 1/(km1*P^0.18*sqrt(Sslp)), surging (sm < smc)
%   am = 1/(km2*P^0.18*Sslp^(0.5 - P)*sm^(-P/3));
%   Dn50 = sqrt(Mf/delta)*h*am*(sqrt(Nz)/S)^0.2 with Nz = duration/Tm.
%   NaN where Hsig <= 0.1, h < 0 or Rc/Dn50 < 1. Used by
%   compute_structure_response when dn50_use_legacy_model = 1.
%
%   Inputs (Hsig, Tm, h and Rc of the same size; duration is not flattened,
%   so it must be a scalar or a column with one element per element of
%   Hsig):
%     Hsig     - spectral significant wave height at the toe (Hm0) [m]
%     Tm       - mean wave period [s] (CHESS: Tp/1.2)
%     h        - water depth at the toe, SWL - toe elevation [m]
%     duration - storm duration for the number of waves [s] (CHESS: the
%                event length storm_duration, never dt)
%     Sslp     - seaside slope cot(alpha) [-], scalar
%     delta    - armor relative buoyant density [-], scalar
%     P        - notional permeability [-], scalar
%     S        - seaside design damage level [-], scalar
%     grav     - gravitational acceleration [m/s^2], scalar
%     km1      - plunging empirical coefficient [-] (emp_coeff.km1)
%     km2      - surging empirical coefficient [-] (emp_coeff.km2)
%     Rc       - freeboard, crest elevation - SWL [m]
%   Outputs:
%     Dn50_Melby - seaside median nominal stone diameter [m], size of Hsig
%
%   Tier: public
%
%   See also van_gent_Dn50_leeside_stability,
%   submerged_stone_armor_stability, ann_rubblemound_stability,
%   compute_structure_response, wavnum1_VG.
%
%   Developed by: Jeffrey A. Melby (JAM)

% LICENSING:
%     This code is part of CHESS software suite developed by the U.S. Army
%     Engineer Research and Development Center Coastal and Hydraulics
%     Laboratory (hereinafter “ERDC-CHL”). This material is distributed in
%     accordance with DoD Instruction 5230.24. Recipient agrees to abide by
%     all notices, and distribution and license markings. The controlling DOD
%     office is the U.S. Army Engineer Research and Development Center
%     (hereinafter, "ERDC"). This material shall be handled and maintained in
%     accordance with For Official Use Only, Export Control, and AR 380-19
%     requirements. ERDC-CHL retains all right, title and interest in
%     CHESS and any portion thereof and in all copies, modifications and
%     derivative works of CHESS and any portions thereof including,
%     without limitation, all rights to patent, copyright, trade secret,
%     trademark and other proprietary or intellectual property rights.
%     Recipient has no rights, by license or otherwise, to use, disclose or
%     disseminate CHESS, in whole or in part.
%
% DISCLAIMER:
%     CHESS IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT
%     HOLDERS. ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS
%     OR IMPLIED WITH RESPECT TO CHESS OR ANYTHING PROVIDED BY ERDC-CHL,
%     AND EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, EITHER EXPRESSED OR
%     IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF MERCHANTABILITY,
%     NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
%     CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE
%     AND RESULTS OF THE USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE
%     UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL WARRANTIES AND LIABILITIES
%     REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN CHESS, AND DISTRIBUTES
%     IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST
%     ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND
%     SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD HARMLESS ERDC-CHL, THE
%     UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
%     LIABILITIES, DEMANDS, DAMAGES.
%
% HISTORY OF REVISIONS:
% Program to
%     compute cross-section incremental damage
% Written by Jeff Melby May 2012
%
% Modified Dec 2020 Abigail Stehno to compare Melby eqs with low-crested
% breakwater and Van Gent LC-BW equations
%       - added CrestEle to inputs for low-crested eqs
%       - changed function output to include Low Crested Eqs and Burcharth RoT
% Modified Nov 2021 Abigail Stehno - change Crest elevation input to Rc
%
% Input:
%     Tm............Mean Wave Period (sec)
%     Hsig..........Hm0 Significant Wave height(m or ft)
%     Sslp..........cot of Structure Slope
%     grav..........Acceleration of Gravity (m./s.^2 or ft./s.^2)
%     Nz............Number of Waves = duration./Tm
%     depth.........Water Depth near Toe (m or ft)
%     P.............Structure Notional Permeability
%     S.............Damage Limit State
%     delta.........Armor Immersed Relative Denstity
%
%       CrestEel .... Crest elevation (depth + freeboard)
%
% Output:
%     Dn50..........Armor Stone Nominal Size (m or ft)
%
%
%
%============================================================



%% Melby
% Hard Coded Coeff
ks = 1;

%% VECTORIZE INPUTS
data_dims = size(Hsig);
Hsig = Hsig(:);
Tm = Tm(:);
h = h(:);
Rc = Rc(:);
Nz = duration./Tm;

%% COMPUTE Dn50
% Momentum Flux Computations
A0 = 0.639.*(Hsig./h).^2.026;
A1 = 0.180.*(Hsig./h).^-0.391;
Mf = A0.*(h./grav./Tm.^2).^-A1;
% Estimate Wave Number
[km,~,~] = wavnum1_VG(Tm,h,grav);
% Compute Wave length Based On Mean Period
Lm = 2.*pi./km;
% Compute Wave Steepness Based On Mean Period
sm = Hsig./Lm;
% Compute Critical Wave Steepness (Melby & Kobayashi 2011)
smc = Sslp.^-3; % JAM change 11./18./22 for continuous equation
% Initialize am
am = zeros(size(Hsig));
% Compute Plunging
am(sm>=smc) = 1./(km1.*P.^0.18.*sqrt(Sslp));
% Compute Surging
am(sm<smc) = 1./(km2.*P.^0.18.*Sslp.^(0.5-P).*sm(sm<smc).^(-P./3));
% COmpute Median Stone Size For Given S
Dn50_Melby = sqrt(Mf./delta).*h.*am.*((ks.*sqrt(Nz))./S).^0.2;
% Assign NaNs
Dn50_Melby(Hsig<=0.1 | h<0) = NaN;
% Compute Relative Freeboard 
Rc_r =  Rc./Dn50_Melby;
% Remove Response Entries Outside of Equation Bounds 
Dn50_Melby(Rc_r<1) = NaN;
Dn50_Melby = reshape(Dn50_Melby, data_dims);

%% Low Crested
%{
% From Burcharth et al 2006 - stability of low crested structures. 
% Equation 5.
% Assume same armor layer size for the whole structure and is valid for -3
% <= Rc/Dn_50 < 2 and slope 1:1.5 exposed to non-depth limited waves, and
% slopes 1:2 exposed to depth limited short-crested waves. 
% Hard coded Coeff
a = 1.36; 
% Remove Negative Freeboards
Rc(Rc<0) = 0;   
% Compute Dn50_LCBW
    Dn50_LCBW=Hsig/delta/1.75; 
% COmpute m
m=Rc./Dn50_LCBW;
% Assign NaNs
Dn50_LCBW(m<-3 | m>=2) = NaN;
Dn50_LCBW(Hsig<=0.1 | h<0) = NaN;
% Reshape
Dn50_LCBW = reshape(Dn50_LCBW, data_dims);
%}
end



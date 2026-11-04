function [Dn50_Lee] = van_gent_Dn50_leeside_stability(S_ls, Hsig, Tm10, Tm, Rc, crest_width, Sslp, Lslp, duration, delta, grav, K_ls1, K_ls2, gamma_f)
% van_gent_Dn50_leeside_stability  Leeside armor stone size of an overtopped crest.
%   Dn50_Lee = van_gent_Dn50_leeside_stability(S_ls, Hsig, Tm10, Tm, Rc,
%       crest_width, Sslp, Lslp, duration, delta, grav, K_ls1, K_ls2,
%       gamma_f) returns the leeside median nominal armor stone diameter of
%       a rubble mound that reaches the leeside damage level S_ls (van Gent
%       leeside stability).
%
%   Dn50_Lee = Lslp^(-2.5/r)*(1 + 10*exp(-Rc/Hsig))^(1/r)
%              *(S_ls/(K_ls2*sqrt(Nz)))^(-1/r)*u1p*Tm10/(K_ls1*sqrt(delta))
%   with r = 6, Nz = duration/Tm, the run-up z1p from z1p_calc and the
%   crest velocity u1p from u1p_calc. NaN where z1p - Rc < 0, u1p <= 0 or
%   Rc <= 0. Used by compute_structure_response when
%   dn50_use_legacy_model = 1.
%
%   Inputs (Hsig, Tm10, Tm, Rc and gamma_f of the same size; duration is
%   not flattened, so it must be a scalar or a column with one element per
%   element of Hsig):
%     S_ls        - leeside design damage level [-], scalar
%     Hsig        - spectral significant wave height at the toe (Hm0) [m]
%     Tm10        - spectral wave period T_m-1,0 [s] (CHESS: Tp/1.1)
%     Tm          - mean wave period [s] (CHESS: Tp/1.2)
%     Rc          - freeboard, crest elevation - SWL [m]
%     crest_width - crest width [m], scalar
%     Sslp        - seaside slope cot(alpha) [-], scalar
%     Lslp        - leeside slope cot(beta) [-], scalar
%     duration    - storm duration for the number of waves [s] (CHESS:
%                   the event length storm_duration, never dt)
%     delta       - armor relative buoyant density [-], scalar
%     grav        - gravitational acceleration [m/s^2], scalar
%     K_ls1       - leeside empirical coefficient 1 [-] (emp_coeff.k_ls1)
%     K_ls2       - leeside empirical coefficient 2 [-] (emp_coeff.k_ls2)
%     gamma_f     - roughness influence factor [-]
%   Outputs:
%     Dn50_Lee - leeside median nominal stone diameter [m], size of Hsig
%
%   Tier: public
%
%   See also melby_Dn50_seaside_stability, submerged_stone_armor_stability,
%   z1p_calc, u1p_calc, ann_rubblemound_stability,
%   compute_structure_response.
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


%% VECTORIZE INPUTS
data_dims = size(Hsig);
Hsig = Hsig(:);
Tm10 = Tm10(:);
Tm = Tm(:);
Rc = Rc(:);
Nz = duration./Tm;
gamma_f = gamma_f(:);

%% DEFINE CONSTANTS
% Define
r = 6; % Constant Wave Conditions

% Compute Run-up Exceeded By 1% Of The Incident Waves
[z1p] = z1p_calc(Hsig, Tm10, Rc, Sslp, grav);
% Compute Crest Velocity Exceeded By 1% Of The Incident Waves
u1p = u1p_calc(crest_width, Rc, z1p, Tm10, Hsig, Sslp, grav);
% Compute First Term
a_ls = Lslp.^(-2.5/r) .* (1 + 10*exp(-1 * Rc./Hsig)).^(1/r);
% Compute Second Term
aux1 = (S_ls./(K_ls2 .* sqrt(Nz))).^(-1/r);
% compute Third Term
aux2 = (u1p .* Tm10)./(K_ls1 .* sqrt(delta));
% Compute Leeside Stone Size
Dn50_Lee = a_ls .* aux1 .* aux2;
% Remove Invalid Entries
Dn50_Lee(z1p-Rc<0) = NaN;
Dn50_Lee(u1p<=0) = NaN;
Dn50_Lee(Rc<=0) = NaN;
% Equation Validity Range 
% Dn50_Lee(Nz>=4000) = NaN;
% Dn50_Lee(Rc./Hsig<0.3 | Rc./Hsig>6) = NaN; 
% Dn50_Lee(crest_width./Hsig<1.3 | crest_width./Hsig>1.6) = NaN; 
% Dn50_Lee(Hsig./(delta.*Dn50_Lee)<5.5 | Hsig./(delta.*Dn50_Lee)<8.5) = NaN; Stability Number
% Dn50_Lee((z1p-Rc)./(gamma_f.*Hsig)<0 | (z1p-Rc)./(gamma_f.*Hsig)>1.4) = NaN; Relative Run-up
% Reshape
Dn50_Lee = reshape(Dn50_Lee, data_dims);
end



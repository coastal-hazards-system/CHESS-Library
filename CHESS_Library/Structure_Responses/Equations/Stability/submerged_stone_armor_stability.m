function [Dn50, Dn50_tag] = submerged_stone_armor_stability(Hs,Tp,h,Rc,Dn50,hc,S,delta,g)
% submerged_stone_armor_stability  Armor stone size where the crest is submerged.
%   [Dn50, Dn50_tag] = submerged_stone_armor_stability(Hs, Tp, h, Rc, Dn50,
%       hc, S, delta, g) replaces the input stone size by the submerged
%       structure stone size (van der Meer and Daemen 1994, CEM Table
%       VI-5-25) wherever the crest is below the SWL (Rc < 0).
%
%   Dn50_sub = -0.14*Hs/delta/sp^(1/3)/log(min(hc/h/(2.1 + 0.1*S), 1)),
%   sp = Hs/Lp with Lp from wavnum1_VG (Tp, h). Hs < 0.1 is set to NaN
%   before the computation. Used by compute_structure_response when
%   dn50_use_legacy_model = 1 and dn50_legacy_submerged_correction = 1.
%
%   Inputs (Hs, Tp, h, Rc and Dn50 of the same size; hc of that size or
%   scalar):
%     Hs    - spectral significant wave height at the toe (Hm0) [m]
%     Tp    - peak wave period [s]
%     h     - water depth at the toe, SWL - toe elevation [m]
%     Rc    - freeboard, crest elevation - SWL [m]
%     Dn50  - stone size of the emergent-crest equation [m]
%     hc    - structure height from the sea bottom [m] (CHESS passes
%             crest elevation - toe elevation)
%     S     - design damage level [-], scalar
%     delta - armor relative buoyant density [-], scalar
%     g     - gravitational acceleration [m/s^2], scalar
%   Outputs:
%     Dn50     - stone size [m], size of Hs: the input Dn50 where Rc >= 0,
%                the submerged stone size where Rc < 0
%     Dn50_tag - logical, size of Hs: true where Rc < 0
%
%   Tier: public
%
%   See also melby_Dn50_seaside_stability, van_gent_Dn50_leeside_stability,
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
% JAM Updated on 2/11/26
% New approach in this routine follows the vdM and Daemen 1994 paper and 
% intends a spatially continuous computational approach for leeside and 
% low-crested-submerged armor.
% 1. Fully emergent crest: seaside and leeside separately using present version of SS
% 3. Submerged Rc<0: this is for entire structure
%
% JAM revision on 2/18/26 and updated 4/9/26
% removed vdM low crested equation that is in CEM Table VI-5-24 because it
% produced large discontinuity at SWL because submerged armor are much
% larger.

%% VECTORIZE INPUTS
data_dims = size(Hs);
Hs = Hs(:);
Tp = Tp(:);
h = h(:); %depth
hc = hc(:); %crest height
delta = delta(:); %why do this, should be constant
Rc = Rc(:);
% hc is structure height from sea bottom
Dn50 = Dn50(:);
Hs(Hs<0.1)=nan; % had to do this on 8/3/23 to avoid errant Dn50 spikes for very small Hs
%sop=g*Hs.*Tp.^2/2/pi; %deep water wave steepness based on Tp
[kp,kpest,ERROR] = wavnum1_VG(Tp,h,g);
Lp=2*pi./kp; %local wavelength based on Tp
sp=Hs./Lp; %local wave steepness based on Tp

%% Emergent but low-crested adjustment 
% This didn't work well so it is not implemented
%Rp_star=Rc./Hs.*sqrt(sop/2/pi); %Equation 8 in v&D paper
% Rp_star varies from 0.52 at transition to 0 when crest is at SWL
%fi=1./(1.25-4.8.*Rp_star); % Equation 10 in v&D paper
%fi(fi<0.8) = 0.8; % crest at SWL
%fi(fi>1.0) = 1.0; % crest at transition where Dn50 is unaltered
%Dn50 = fi.*Dn50; % reduce if low-crested

%% Submerged
% The following computes armor size based on rearranged Equation 11 in paper
% and CEM Table VI-5-25 Dn50 comes from the so-called spectral stability number (Ahrens)
% Ns_star = Hs^2/3*Lp^1/3/Delta/Dn50 = H/Delta/Dn50/(sp^1/3)=Ns/(sp^1/3)
aux1 = hc./h./(2.1 + 0.1*S);
aux1 = min(aux1,1); % if aux1>1 then ln(aux1)>0 and Dn50 will be negative
Dn50_sub = -0.14.*Hs/delta./sp.^(1/3)./log(aux1);
Dn50(Rc<0) = Dn50_sub(Rc<0);
Dn50_tag = Rc<0;

%% Output
Dn50 = reshape(Dn50, data_dims);
Dn50_tag = reshape(Dn50_tag, data_dims);
end
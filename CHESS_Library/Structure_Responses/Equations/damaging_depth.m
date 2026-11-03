function [DamDepthElev,DamDepth]= damaging_depth(SWL,Hm0,Ts,offshore_elevation,Ks,hs,d,Bm,berm_slope_tana,offshore_slope_tana, g)
% damaging_depth  Damaging depth from the water level and the controlling wave.
%   [DamDepthElev, DamDepth] = damaging_depth(SWL, Hm0, Ts,
%       offshore_elevation, Ks, hs, d, Bm, berm_slope_tana,
%       offshore_slope_tana, g) returns the elevation of the controlling
%       wave crest and the water column height above the offshore bed.
%
%   The damaging depth is the total water column height from the
%   topographic surface to the crest of the controlling wave:
%   DamDepthElev = SWL + 0.7*Ks*Hc. The controlling wave height Hc is the
%   average height of the highest 1 percent of waves during storm
%   conditions, taken as 1.6*Hm0 and limited to the breaker height of
%   Goda's breaker equation (goda_Hmax, Goda 2000 p. 105) at 5*Hm0 from
%   the structure (on the toe berm or the offshore slope). 70 percent of
%   Hc is assumed to lie above the SWL, so SWL must include every storm
%   water level component (surge, tide and wave setup).
%   DamDepth = DamDepthElev - offshore_elevation, clipped to 0 when
%   negative (no water column above an offshore bed that is above the
%   wave crest); NaN is kept. CHESS passes Ts = Tp (narrow spectrum,
%   conservative; Ts = 0.93*Tp for JONSWAP with gamma = 3.3).
%
%   Inputs (lengths in m and g in m/s^2 in CHESS; any consistent units):
%     SWL                 - still water level (surge, tide, setup) [m,
%                           study datum, positive up]; any shape, same
%                           number of elements as Ts
%     Hm0                 - offshore spectral significant wave height
%                           (before depth limitation) [m], same size as Ts
%     Ts                  - significant wave period [s]; the outputs take
%                           the shape of Ts
%     offshore_elevation  - offshore (savepoint) bed elevation [m, study
%                           datum, positive up], scalar
%     Ks                  - sheltering (shielding) coefficient [-]: 1 for
%                           0-1 rows of buildings, 0.7 for 2-3 rows, 0.5
%                           for 4-5 rows, 0.3 for 6 or more rows
%     hs                  - water depth at the structure toe, SWL - toe
%                           elevation [m], same size as Ts
%     d                   - water depth over the toe berm crest, SWL - berm
%                           crest elevation [m] (= hs without a berm), same
%                           size as Ts
%     Bm                  - toe berm crest width [m], scalar (0 = no berm)
%     berm_slope_tana     - seaward slope of the toe berm, tan(alpha) [-],
%                           scalar
%     offshore_slope_tana - offshore (seabed) slope, tan(beta) [-], scalar
%     g                   - gravitational acceleration [m/s^2] (required;
%                           CHESS passes config.gravity_constant, from
%                           standard_gravity)
%   Outputs:
%     DamDepthElev - elevation of the controlling wave crest [m, study
%                    datum, positive up], size of Ts
%     DamDepth     - damaging depth, DamDepthElev - offshore_elevation,
%                    clipped to 0 when negative, NaN kept [m], size of Ts
%
%   Tier: public
%
%   See also goda_Hmax, compute_structure_response, check_offshore_elevation,
%   standard_gravity.
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
% SOFTWARE NAME:
%     Damaging_Depth_11_27_24.m
%
% HISTORY OF REVISIONS:
%
% ***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
var_shape = size(Ts);
Ts = Ts(:); %note that Ts=0.93*Tp for Jonswap with gamma=3.3 but approaches Tp as gamma 
Hm0 = Hm0(:);
SWL = SWL(:);
% increases (spectrum becomes narrower).  So here we assume narrow spectra to be conservative.
[Hb, ~]=goda_Hmax(Hm0,Ts,1.6,hs,d,Bm,berm_slope_tana,offshore_slope_tana, g);

DamDepthElev = SWL + 0.7 * Ks * Hb;
DamDepth = DamDepthElev - offshore_elevation;
% No Water Column Above The Offshore Bed (Storm Below An Offshore Elevation Above Datum): Clip To 0 (NaN Kept)
DamDepth(DamDepth < 0) = 0;
% Resahpe Variables 
DamDepth = reshape(DamDepth, var_shape);
DamDepthElev = reshape(DamDepthElev, var_shape);
end
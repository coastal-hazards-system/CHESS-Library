function [Hmax, hb]=goda_Hmax(Hm0,Ts,Rayleigh_H250,hs,d,Bm,berm_slope_tana,offshore_slope_tana,g)
% goda_Hmax  Depth-limited design wave height 5*Hm0 seaward of a structure.
%   [Hmax, hb] = goda_Hmax(Hm0, Ts, Rayleigh_H250, hs, d, Bm,
%       berm_slope_tana, offshore_slope_tana, g) returns the design wave
%       height Rayleigh_H250*Hm0 limited by the breaker height at 5*Hm0
%       from the structure, and the water depth at that point.
%
%   Breaker point at b_dist = 5*Hm0 from the structure, on the toe berm or
%   on the offshore slope:
%     Bm > 0 and b_dist <= Bm:           hb = d (on the berm crest)
%     Bm > 0 and Bm < b_dist < toe_dist: hb = d + berm_slope_tana*
%                                             (b_dist - Bm)
%     otherwise:                         hb = hs + offshore_slope_tana*
%                                             (b_dist - toe_dist)
%   with toe_dist = (hs - d)/berm_slope_tana + Bm (0 without a berm); hb
%   is clipped at 0. The berm tests are element-wise (one branch per row).
%   Breaker height (Goda 2000, p. 105; Kamphuis irregular wave form,
%   Eq. 3.34, confirmed by Li et al.):
%     Hb = 0.12*Lo*(1 - exp(-1.5*pi*hb/Lo*(1 + 11*tanb^(4/3)))),
%     Lo = g*Ts^2/(2*pi),
%   tanb being the slope at the breaker point (berm or offshore), and
%   Hmax = min(Hb, Rayleigh_H250*Hm0) (NaN omitted). Goda uses Ts = T1/3
%   (about T_m-1,0); Ts = 0.93*Tp for JONSWAP with gamma = 3.3 and
%   approaches Tp for narrower spectra.
%
%   Inputs (any consistent length unit: m from damaging_depth, ft from
%   goda_forces_on_vertical_p1; Hm0, Ts, hs and d of the same size):
%     Hm0                 - offshore spectral significant wave height
%     Ts                  - significant wave period [s]
%     Rayleigh_H250       - ratio of the design height to Hm0 [-], scalar
%                           (damaging_depth passes 1.6,
%                           goda_forces_on_vertical_p1 its design_scale,
%                           1.8 in CHESS)
%     hs                  - water depth at the structure (berm) toe
%     d                   - water depth over the toe berm crest (= hs
%                           without a berm)
%     Bm                  - toe berm crest width, scalar or one per element
%                           of Hm0 (0 = no berm)
%     berm_slope_tana     - seaward slope of the toe berm, tan(alpha) [-],
%                           scalar
%     offshore_slope_tana - offshore (seabed) slope, tan(beta) [-], scalar
%     g                   - gravitational acceleration (length unit/s^2),
%                           scalar
%   Outputs (column vectors, one row per element of Hm0):
%     Hmax                - design wave height, min(Hb, Rayleigh_H250*Hm0)
%     hb                  - water depth at the breaker point 5*Hm0 from
%                           the structure (>= 0)
%
%   Tier: public
%
%   See also damaging_depth, goda_forces_on_vertical_p1,
%   goda_forces_on_vertical_p2p3.

Hm0 = Hm0(:);
Ts = Ts(:);
hs = hs(:);
d = d(:);
Bm = Bm(:) + zeros(size(hs));

%%  PREPROCESSING
% Location Of 5Hm0 From The Wall: On The Berm (Crest Or Seaward Slope), Else Offshore Of The Berm Toe
b_dist = 5*Hm0;
has_berm = Bm > 0;
toe_dist = zeros(size(hs));
toe_dist(has_berm) = (hs(has_berm) - d(has_berm))./berm_slope_tana + Bm(has_berm);
on_berm = has_berm & b_dist < toe_dist;
on_berm_slope = on_berm & b_dist > Bm;
hb = hs + offshore_slope_tana*(b_dist - toe_dist);
hb(on_berm) = d(on_berm);
hb(on_berm_slope) = d(on_berm_slope) + berm_slope_tana*(b_dist(on_berm_slope) - Bm(on_berm_slope));
tan_b_slope = repmat(offshore_slope_tana, size(hs));
tan_b_slope(on_berm) = berm_slope_tana;
% Negative Water Col Failsafe
hb(hb<0) = 0;

%% DEPTH LIMITATION 
% Goda says to use Ts = T1/3.  He says use Ts = Tm-1,0.  Ts=0.93*Tp for Jonswap with gamma=3.3 but approaches Tp as gamma 
% increases (spectrum becomes narrower).  
% Deep Water Wave Length 
Lo = g*Ts.^2/2/pi;
% Compute maximum significant wave height in the surf zone (Depth Limitation)
%HbonLo(:, 1) = 0.17*(1-exp(-1.5*pi*SPdepth/Lo*(1+15*tanbeta^(4/3)))); %Goda, 1995
HbonLo(:, 1) = 0.12.*(1-exp(-1.5.*pi.*hb./Lo.*(1+11.*tan_b_slope.^(4/3)))); %Goda, 1995
Hb = HbonLo.*Lo;
% Keep Smallest 
Hmax = min(Hb, Hm0.*Rayleigh_H250, "omitnan");
end

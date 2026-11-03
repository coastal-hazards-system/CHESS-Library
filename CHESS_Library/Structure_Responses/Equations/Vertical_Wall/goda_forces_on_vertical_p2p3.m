function [p2dyn, p2sta, p2total, p3dyn, p3sta, p3total, pu]=goda_forces_on_vertical_p2p3(Hm0,Tp,design_scale,beta,hs,d,Rc,hw,p1dyn,rho_w,g)
% goda_forces_on_vertical_p2p3  Goda wall pressures p2, p3 and uplift pu.
%   [p2dyn, p2sta, p2total, p3dyn, p3sta, p3total, pu] =
%       goda_forces_on_vertical_p2p3(Hm0, Tp, design_scale, beta, hs, d,
%       Rc, hw, p1dyn, rho_w, g) returns the Goda pressures at the top and
%       the base of a vertical wall and the uplift pressure at its seaward
%       heel, from the pressure p1dyn at SWL (goda_forces_on_vertical_p1).
%
%   Goda method of the CEM, Tables VI-5-53 and VI-5-55 (full-height wall,
%   irregular non-breaking waves; hydrostatic pressure on the seaward face
%   only; uplift assumes a permeable base), with H_design =
%   design_scale*Hm0 (no breaker limit, unlike p1), lambda1 = lambda3 = 1
%   and k the wave number of Tp at depth d (wavnum1_VG):
%     eta* = 0.75*(1 + cos(beta))*lambda1*H_design
%     p2dyn = (1 - Rc/eta*)*p1dyn where eta* > Rc, else 0
%     p2sta = max(gamma_w*(d - hw), 0)
%     p3dyn = alpha3*p1dyn, alpha3 = 1 - (hw - Rc)/hs*(1 - 1/cosh(k*hs))
%     p3sta = max(gamma_w*d, 0)
%     p2total = p2dyn + p2sta, p3total = p3dyn + p3sta
%     pu = 0.5*(1 + cos(beta))*lambda3*alpha1*alpha3*gamma_w*H_design,
%          alpha1 = 0.6 + 0.5*(2*k*hs/sinh(2*k*hs))^2
%   Negative depths are clipped to 0. The inputs are metric; the function
%   works in ft, lbm/ft^3 and ft/s^2 and converts the pressures back with
%   the psf-to-Pa factor. Note: here gamma_w = rho_w*g (lbm/ft^3 times
%   ft/s^2) lacks the 1/32.174 lbm-to-lbf factor that
%   goda_forces_on_vertical_p1 applies, so as coded p2sta, p3sta and pu
%   (and the hydrostatic part of p2total and p3total) come out 32.174
%   times larger than Pa.
%
%   Inputs (Hm0, Tp, hs, d, Rc and p1dyn of the same size):
%     Hm0          - offshore spectral significant wave height [m]
%     Tp           - wave period [s] (CHESS passes Ts = Tp)
%     design_scale - ratio of the design wave height to Hm0 [-], scalar
%                    (CHESS: 1.8)
%     beta         - wave obliquity [rad], scalar (CHESS: 0)
%     hs           - water depth at the toe, SWL - toe elevation [m]
%     d            - water depth over the toe berm crest [m] (= hs without
%                    a berm)
%     Rc           - freeboard, crest elevation - SWL [m]
%     hw           - wall height, crest - wall bottom elevation [m], scalar
%     p1dyn        - dynamic pressure at SWL [Pa]
%                    (goda_forces_on_vertical_p1)
%     rho_w        - water density [kg/m^3], scalar
%     g            - gravitational acceleration [m/s^2], scalar
%   Outputs (size of Hm0; see the Note on the hydrostatic terms):
%     p2dyn   - dynamic pressure at the top of the wall [Pa]
%     p2sta   - hydrostatic pressure at the top of the wall
%     p2total - total pressure at the top of the wall, p2dyn + p2sta
%     p3dyn   - dynamic pressure at the base of the wall (ground or top of
%               fill) [Pa]
%     p3sta   - hydrostatic pressure at the base of the wall
%     p3total - total pressure at the base of the wall, p3dyn + p3sta
%     pu      - uplift pressure at the seaward heel
%
%   Tier: public
%
%   See also goda_forces_on_vertical_p1, goda_Hmax, wavnum1_VG,
%   compute_structure_response.
%
%   Developed by: Abigail L. Stehno

% HISTORY OF REVISIONS:
%     Written by Abigail L. Stehno (abigail.l.stehno@erdc.dren.mil) 11/17/21
%
% Note: goda_ForcesOnVertical below no longer exists (old p, F, M interface).
% Validation test: 
% [p2dyn, p2sta, p2total, p3dyn, p3sta, p3total, pu]=goda_forces_on_vertical_p2p3(1.9507, 7.7, 1.8, 2, 5.7607, 5.1511, 0.7926,5.9437,p1dyn,1025.502, 9.81)
% ^ Must run goda_forces_on_vertical_p1.m validation test first
%
% [p,F,M]=goda_ForcesOnVertical(6.4,7.7,2,18.9,16.9,19.5,2,155,1,10)
% p = 
%          p1: 187.7356
%          p2: 90.9741
%          p3: 1.4018e+03 but I was getting 1.2354e+03, which matches S2G outputs
% F = 
%     F_horiz: 2.9205e+03
%        F_up: 117.7368
%          FG: 3.8811e+03
% M = 
%     M_horiz: 2.5689e+04
%        M_up: 146.7887
%          MG: 3.8811e+03
%
%
% Comments from Jeff
% - Include a code that calls this function set up with one of the examples. 
% - Looks like this is for a wall with no water on back side because it has 
%   hydro static.  That needs a clear comment up front.  Ideally it is not 
%   assumed but there should be a user-defined logical for hydrostatic/no hydrostatic.
% - put all user modifiable things in a section at front of code after header 
%   comments and have a statement that says "Do not change anything below here"
% - Specific weight of water should be a user input (fresh or salt)
% - H_design_factor (1.8) should be a user input
% - Breaker index (0.6) should be a user input
% - Lambdas should be user inputs
% - The period in Goda equation is not Tp, it is "significant wave period" or 
%   Tm-1,0 or 1.1Tm or Tp/1.1 
% - Need to describe units.  You have input units described but not output.  
%   Ideally, acceleration of gravity is a user input that defines the units.  
%   So if it is 32.1719 then it is english standard, if it is 9.8066, then it is SI.  
%   Then the output units are stated in the output structure 
% - Uplift force assumes caisson is sitting on a gravel base.  What if structure 
%   is not on a gravel base?  What if it is a pile-founded I-wall or T-wall?  
%   This could be a logical (uplift pressures are possible or not). 
% - For moments, add to comments that they are computed about heel of caisson. 
%   The actual rotation point is fairly complex and there is a method to compute
%   it for caissons.  But if it is a floodwall, it is very different and depends
%   on the geometry and the geotechnical failure location.   

%% VECTORIZE INPUTS
data_dims = size(Hm0);
Hm0 = Hm0(:)*3.2808;
Tp = Tp(:);
hs = hs(:)*3.2808;
d = d(:)*3.2808;
p1dyn = p1dyn(:)/47.8803;
Rc = Rc(:)*3.2808;
rho_w = rho_w*0.062428;
g=g(:)*3.28084; 
hw = hw(:)*3.2808;

%% PREPROCESSING 
% Compute Design Hm0
H_design = Hm0*design_scale;
% Negative Water Col Failsafe
hs(hs<0) = 0; d(d<0)=0;
% lambda coefficients - Vertical Wall
lambda1 = 1; % More Cases Will Be Added In The Future
lambda3 = 1; % More Cases Will Be Added In The Future
% Define Constants
gamma_w = rho_w.*g; % Specific weight of water, pcf

%% COMPUTE WAVE NUMBER
% Wave length
[kp,~,~]=wavnum1_VG(Tp,d,g); % 1./ft
kp_hs = kp.*hs; % k_p .* h_s, unitless

%% COMPUTE ALPHA'S & ETA*
    % Alpha coefficients
alpha1 = 0.6+0.5.*(2.*kp_hs./sinh(2.*kp_hs)).^2;
alpha3 = 1-(hw-Rc)./hs.*(1-1./cosh(kp_hs)); 

% Eta*
etaStar = 0.75*(1+cos(beta)).*H_design*lambda1; 

%% COMPUTE P2 & P3 (Table VI-5-53 in CEM)
% Initialize P2 & P3
p2dyn = zeros(size(p1dyn));
% Compute P2
p2dyn(etaStar>Rc) = (1-Rc(etaStar>Rc)./etaStar(etaStar>Rc)).*p1dyn(etaStar>Rc); % Dynamic p2 at top of wall
% p2sta=max(gamma_w*-1*(hw-d),0); % hydrostatic p2 at top of wall
p2sta=gamma_w*-1*(hw-d); % hydrostatic p2 at top of wall
p2sta(~isnan(p2sta)) = max(p2sta(~isnan(p2sta)),0);
p2total = p2dyn+p2sta; % total p2 at top of wall
% Compute P3
p3dyn = alpha3.*p1dyn; % Dynamic p3 at ground/top of fill
p3sta = gamma_w*d; % hydrostatic p3 at ground/top of fill
p3sta(~isnan(p3sta)) = max(p3sta(~isnan(p3sta)) ,0);
p3total = p3dyn+p3sta; % total p3 at ground/top of fill
% Compute uplift pressure at seaward edge
pu = 0.5*(1+cos(beta)).*lambda3.*alpha1.*alpha3*gamma_w.*H_design;

%% RESHAPE OUTPUT VARS 
p2dyn = reshape(p2dyn,data_dims)*47.8803;
p3dyn = reshape(p3dyn,data_dims)*47.8803;
p2sta = reshape(p2sta,data_dims)*47.8803;
p3sta = reshape(p3sta,data_dims)*47.8803;
p2total = reshape(p2total,data_dims)*47.8803;
p3total = reshape(p3total,data_dims)*47.8803;

pu = reshape(pu,data_dims)*47.8803;
end



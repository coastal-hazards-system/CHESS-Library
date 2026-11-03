function [X_low, theta_low, X_up, theta_up, Bx, X_c_surge, theta_center, Bjet, Vjet, Fjet] = floodwall_nappe_response(SWL, Hm0, q, h_wall, rho_w, crest_elev)
% floodwall_nappe_response  Floodwall overtopping nappe geometry and jet force.
%   [X_low, theta_low, X_up, theta_up, Bx, X_c_surge, theta_center, Bjet,
%       Vjet, Fjet] = floodwall_nappe_response(SWL, Hm0, q, h_wall, rho_w,
%       crest_elev) returns the landing range, angle, width, velocity and
%       force of the overtopping jet behind a floodwall.
%
%   Sharp-crested weir nappe of ERDC/CHL TR-21-15 Report 1, Appendix F,
%   Eqs. F.29-F.36 (Figure F-8), with the head over the crest
%   h1 = SWL + Hm0 - crest_elev. Hm0 is added on purpose (conservative):
%   HSDRRS Design Guidelines (2010), Ch. 4 "Wave and Surge Overtopping"
%   (pp. 4-18/4-19) note that combined overtopping pulsates and the jet
%   lands farther from the wall when the wave crest overtops; the surge
%   only nappe (HSDRRS Eqs. 4.12-4.15 = TR-21-15 F.29-F.30) is applied
%   with the wave crest added to the head (HSDRRS uses 0.7*H above SWL,
%   Eq. 4.25; the full Hm0 is more conservative). No head (h1 <= 0): no
%   nappe, every output NaN. With A = -0.425, B = 0.055, C = 0.150 and
%   D = 0.559:
%     X_low = h1*(-B - sqrt(B^2 - 4*A*(C + h_wall/h1)))/(2*A)      (F.29)
%     X_up  = h1*(-B - sqrt(B^2 - 4*A*(C + D + h_wall/h1)))/(2*A)  (F.30)
%     X_c_surge = (X_up + X_low)/2                                 (F.31)
%     theta = -atand(2*A*X/h1 + B) at X_low and X_up          (F.32, F.33)
%     Bjet = Bx*sind(theta_center), Bx = X_up - X_low              (F.34)
%     Vjet = q/Bjet                                                (F.35)
%     Fjet = rho_w*Bjet*Vjet^2                                     (F.36)
%   Coordinates (Report 1, Sec. 5.6 and Fig. 53): x = 0 at the flood face
%   of the wall, positive landward. Angles are positive below the leeside
%   horizontal (theta = -theta_report), so F.34 uses sin(theta).
%
%   Inputs (SWL, Hm0 and q with the same number of elements; outputs take
%   the shape of SWL):
%     SWL        - still water level [m, study datum, positive up]
%     Hm0        - spectral significant wave height at the toe [m]
%     q          - mean overtopping discharge [m^3/s per m]
%                  (Eurotop_r2p_q_Final)
%     h_wall     - wall height Hw, crest - wall bottom elevation [m], scalar
%     rho_w      - water density [kg/m^3], scalar
%     crest_elev - wall crest elevation [m, study datum, positive up],
%                  scalar
%   Outputs (size of SWL, all >= 0 or NaN):
%     X_low        - distance to the lower nappe impact point [m] (F.29)
%     theta_low    - jet angle at X_low [deg] (F.32)
%     X_up         - distance to the upper nappe impact point [m] (F.30)
%     theta_up     - jet angle at X_up [deg] (F.33)
%     Bx           - horizontal impact width, X_up - X_low [m]
%     X_c_surge    - distance to the jet center [m] (F.31)
%     theta_center - mean jet angle, (theta_low + theta_up)/2 [deg]
%     Bjet         - impinging jet width [m] (F.34)
%     Vjet         - jet entry velocity [m/s] (F.35)
%     Fjet         - jet force per unit wall length [N/m] (F.36)
%
%   Tier: public
%
%   See also Eurotop_r2p_q_Final, compute_structure_response.

%% VECTORIZE INPUTS
data_dims = size(SWL);
SWL = SWL(:);
Hm0 = Hm0(:);
q = q(:);

%% COMPUTE WALL NAPPE RESPONSE (AS PER TR-21-15)
% Head Over The Crest: h1 = h - Hw = (SWL + Hm0 - wall_bottom) - (crest - wall_bottom)
h1 = SWL+Hm0-crest_elev;
% No Water Head Over The Crest: No Nappe (NaN Propagates To Every Output)
h1(h1 <= 0) = NaN;
% Define Equation Empirical Coefficients
A = -0.425; B = 0.055; C = 0.150; D = 0.559;
% Compute Nappe Lower Wave Impact Region (F.29)
Nappe.X_low = h1.*((-B-sqrt(B.^(2)-4*A*(C+(h_wall./h1))))./(2*A)); % m
% Compute Overtopping Jet Angle Lower Geometry Angle (F.32, Positive Below Leeside Horizontal)
Nappe.theta_low= -atand((2*A.*Nappe.X_low./h1)+B); % deg
% Compute Nappe Upper Wave Impact Region (F.30)
Nappe.X_up = h1.*((-B-sqrt(B.^(2)-4*A*(C+D+(h_wall./h1))))./(2*A)); % m
% Compute Overtopping Jet Angle Upper Geometry Angle (F.33, Positive Below Leeside Horizontal)
Nappe.theta_up = -atand((2*A.*Nappe.X_up./h1)+B); % deg
% Compute Impact Range Difference
Nappe.Bx = Nappe.X_up  - Nappe.X_low; % m
% Compute Distance From Floodside Of Wall To Jet Center (F.31)
Nappe.X_c_surge = (Nappe.X_up+Nappe.X_low)./2; % m
% Jet Angle: Average Of Lower & Upper (Text Above F.32)
Nappe.theta_center = (Nappe.theta_low + Nappe.theta_up)./2; % deg
% Compute The Width Of Impinging Jet (F.34; Angle Already Positive)
Nappe.Bjet  = Nappe.Bx.*sind(Nappe.theta_center); % m
% Compute Jet Entry Velocity (F.35)
Nappe.Vjet  = q./Nappe.Bjet; % m/s
% Compute Total Force Excerted (F.36)
Nappe.Fjet  = rho_w.*Nappe.Bjet.*(Nappe.Vjet).^2; % N/m
% Get Fieldnames 
fnames = fieldnames(Nappe);
% Reshape Fields 
for ii = 1:length(fnames)
    eval([fnames{ii} ' = reshape(Nappe.(fnames{ii}), data_dims);']);
end

%% PARAMETERS NOT FOUND IN TR-21-15 Appendix F
%     v1 = 3*sqrt(9.81*toe); % v1 is 2-4 times cg - split the difference as 3?
%     H = h1 + (v1^2 / (2*9.81));
%     Nappe.X_c_wave = sqrt(2*(toe+SWL.*(h_wall+0.7.*Hm0+h1)));
%         Nappe.X_low = abs(h1)./2/A.*(-B-4*B*(C+h_wall./abs(h1))); Where did this come from
%         Nappe.X_up = abs(h1)./2/A.*(-B-4*B.*(C+D+h_wall./abs(h1)));
end

function [X_low, theta_low, X_up, theta_up, Bx, X_c_surge, theta_center, Bjet, Vjet, Fjet] = floodwall_nappe_response(SWL, Hm0, q, h_wall, rho_w, crest_elev)
%{
    Floodwall overtopping nappe geometry, ERDC/CHL TR-21-15 Report 1, Appendix F, Eqs. F.29-F.36
    (flow over a sharp-crested weir, Figure F-8).
    SWL, crest_elev: elevations [m, datum]. Hm0: [m]. q: overtopping rate [m^3/s per m] (library units).
    h_wall: wall height Hw = crest - wall bottom [m]. rho_w: [kg/m^3].
    h1 = h - Hw, h = total water depth at the wall (from the wall bottom) -> h1 = SWL + Hm0 - crest_elev
    (head over the crest). Hm0 is added ON PURPOSE (conservative): HSDRRS Design Guidelines (2010), Ch. 4
    "Wave and Surge Overtopping" (pp. 4-18/4-19): combined overtopping pulsates and the jet lands farther from
    the wall when the wave crest overtops, so protection must extend farther than for surge alone. The surge-only
    sharp-crested weir nappe (HSDRRS Eqs. 4.12-4.15 = TR-21-15 F.29-F.30) is applied with the wave crest added to
    the head (HSDRRS uses a crest 0.7*H above SWL, Eq. 4.25; using the full Hm0 is more conservative).
    No water head (h1 <= 0): no nappe, all outputs NaN.
    Coordinates (Report 1, Sec. 5.6 & Fig. 53): x = 0 at the flood face of the wall, positive landward.
    Angles are reported POSITIVE, as the angle below the leeside horizontal (the report's F.32-F.33 slope
    angles are negative; theta here = -theta_report), so F.34 becomes BJ = Bx*sin(theta).
    Outputs (all >= 0): distances [m], angles [deg], Vjet [m/s], Fjet [N/m].
%}
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

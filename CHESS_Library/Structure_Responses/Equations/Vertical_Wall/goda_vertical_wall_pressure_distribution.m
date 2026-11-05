function P = goda_vertical_wall_pressure_distribution(Hm0, Ts, hs, d, hc, wall, units, options)
% goda_vertical_wall_pressure_distribution  Goda pressure distribution on a vertical wall.
%   P = goda_vertical_wall_pressure_distribution(Hm0, Ts, hs, d, hc, wall,
%       units) returns the Goda wave pressure p1 at SWL, the pressures at
%       the top (p2) and the base (p3) of the wall and the uplift pressure
%       pu at its seaward heel, for every forcing element.
%   P = goda_vertical_wall_pressure_distribution(..., p1 = p1) uses the
%       given p1 (e.g. a p1 hazard curve) instead of computing it; the
%       design wave, hb, k, the alphas and eta_star still come from the
%       forcing inputs.
%   P = goda_vertical_wall_pressure_distribution(..., distribution = false)
%       returns p1 only.
%
%   Goda method of the CEM, Tables VI-5-53 and VI-5-55 (full-height wall,
%   irregular waves), with the CEM variable names and lambda1 = lambda2 =
%   lambda3 = 1:
%     [H_design, hb] = goda_Hmax(Hm0, Ts, design_scale, hs, d, Bm, ...):
%       design wave design_scale*Hm0 limited by the breaker height at
%       5*Hm0 seaward of the wall, hb the water depth there. This
%       breaker-limited H_design drives every wave term (p1, eta_star,
%       p2dyn, pu).
%     k = wave number of Ts at depth d (wavnum1_VG)
%     alpha1 = 0.6 + 0.5*(2*k*hs/sinh(2*k*hs))^2
%     alpha2 = min((hb - d)/(3*hb)*(H_design/d)^2, 2*d/H_design)
%     alpha3 = 1 - h_prime/hs*(1 - 1/cosh(k*hs)), h_prime = hw - hc
%     eta_star = 0.75*(1 + cos(beta))*lambda1*H_design
%     p1 = 0.5*(1 + cos(beta))*(lambda1*alpha1 + lambda2*alpha2*
%          cos(beta)^2)*gamma_w*H_design
%     p2dyn = (1 - hc/eta_star)*p1 where eta_star > hc, else 0
%     p3dyn = alpha3*p1
%     pu = 0.5*(1 + cos(beta))*lambda3*alpha1*alpha3*gamma_w*H_design
%     p2sta = gamma_w*max(-hc, 0), p3sta = gamma_w*hs
%     p2total = p2dyn + p2sta, p3total = p3dyn + p3sta
%   The inputs are converted from the unit system (units) to SI for
%   goda_Hmax and then to imperial units (ft, s, lbf/ft^3) for the Goda
%   core, which stays imperial because its empirical coefficients were
%   fitted in imperial units; the pressures (psf) are converted back to
%   the unit system. gamma_w [lbf/ft^3] = rho_w*g [N/m^3] divided by the
%   lbf/ft^3-to-N/m^3 factor (no lbm-to-lbf g_c factor).
%
%   Here hc is the crest freeboard, crest elevation - SWL (CHESS Rc); it is
%   NOT the CHESS hc = crest - toe elevation used by the ANN and Dn50
%   equations. hb is the depth at the breaker point (goda_Hmax) only.
%
%   Model rules (no depth clipping):
%     - wave (dynamic) terms p1, p2dyn, p3dyn, pu, and the totals p2total,
%       p3total, are NaN where hc < 0 (submerged crest: Goda applies up to
%       SWL at the crest, hc = 0), and NaN where p1 is undefined;
%     - static terms p2sta, p3sta are always computed (also where hc < 0)
%       and never use eta_star or H_design;
%     - dry toe (hs <= 0): every output is NaN, static terms included;
%     - k is computed only where hs > 0, d > 0 and Ts > 0 (else the wave
%       terms are NaN).
%   Assumptions: the landside is always dry (still-water pressure acts on
%   the seaward face only, no still-water uplift, pu is wave-only); the
%   wall stands on the seabed and the mound is ignored (h_prime = d = hs,
%   toe = wall bottom; CHESS hides toe berms, finalize_structure_config
%   sets add_toe_berm = 0); hs is the water depth at the toe; head-on
%   waves (CHESS beta = 0); dynamic = wave loading only, static = still-
%   water loading only. The paired wave is the project-forcing
%   Hm0_offshore, never Hm0_toe: on a single line the save-point Hm0 (not
%   changed by apply_depth_limitation), on a multiline stage 2 the stage-1
%   transmitted wave (depth-limited per the apply_depth_limitation
%   setting); goda_Hmax breaker-limits it either way. CHESS passes Ts = Tp
%   (narrow-spectrum assumption; Goda's Ts is T1/3, about T_m-1,0, open
%   team item).
%
%   Inputs (Hm0, Ts, hs, d, hc and options.p1 of the same size; lengths,
%   times, densities, accelerations and pressures in the units unit system):
%     Hm0   - wave height paired with the wall [length] (CHESS:
%             project-forcing Hm0_offshore)
%     Ts    - significant wave period [time] (CHESS: Tp)
%     hs    - water depth at the toe, SWL - toe elevation [length]
%     d     - water depth over the toe berm crest [length] (= hs without a
%             berm)
%     hc    - crest freeboard, crest elevation - SWL [length] (CHESS Rc)
%     wall  - wall settings, 1x1 struct with fields
%               hw                  - wall height, crest - wall bottom
%                                     elevation [length]
%               Bm                  - toe berm crest width [length] (0 =
%                                     no berm)
%               berm_slope_tana     - seaward slope of the toe berm,
%                                     tan(alpha) [-]
%               offshore_slope_tana - offshore (seabed) slope, tan(beta)
%                                     [-]
%               rho_w               - water density [density]
%               g                   - gravitational acceleration
%                                     [acceleration]
%               design_scale        - ratio of the design wave height to
%                                     Hm0 [-] (CHESS: 1.8)
%               beta                - wave obliquity [rad] (CHESS: 0)
%     units - unit system of the inputs and outputs,
%             chess_units('system', 'SI' | 'Imperial')
%     options.p1           - given p1 [pressure] (default [] = compute it)
%     options.distribution - true (default) = every pressure; false = p1
%                            only
%   Outputs:
%     P - pressures [pressure], 1x1 struct of arrays the size of Hm0, field
%         names of the response_registry rows: p1 (dynamic pressure at
%         SWL; the given p1 with the NaN rules in given-p1 mode), p2dyn,
%         p2sta, p2total (top of the wall), p3dyn, p3sta, p3total (base of
%         the wall), pu (uplift at the seaward heel); p1 only with
%         distribution = false
%
%   Errors: goda_vertical_wall_pressure_distribution:missingWallField when
%   wall lacks a field.
%
%   Tier: public
%
%   See also goda_Hmax, wavnum1_VG, chess_units, compute_structure_response,
%   chess_pros_frequency_base.
%
%   Developed by: Abigail L. Stehno; restructured by Fabian A. Garcia
%   Moreno ERDC-CHL

arguments
    Hm0 double
    Ts double
    hs double
    d double
    hc double
    wall (1,1) struct
    units (1,1) struct
    options.p1 double = []
    options.distribution (1,1) logical = true
end

required_fields = {'hw', 'Bm', 'berm_slope_tana', 'offshore_slope_tana', 'rho_w', 'g', 'design_scale', 'beta'};
missing_fields = setdiff(required_fields, fieldnames(wall), 'stable');
if ~isempty(missing_fields)
    error('goda_vertical_wall_pressure_distribution:missingWallField', ...
        'The wall struct lacks the field(s): %s.', strjoin(missing_fields, ', '));
end
data_dims = size(Hm0);
given_p1 = ~isempty(options.p1);

%% PROJECT UNITS -> SI
length_SI = units.to_SI.length;
Hm0_SI = Hm0(:)*length_SI;
Ts_SI = Ts(:)*units.to_SI.time;
hs_SI = hs(:)*length_SI;
d_SI = d(:)*length_SI;
hc_SI = hc(:)*length_SI;
hw_SI = wall.hw*length_SI;
Bm_SI = wall.Bm*length_SI;
rho_w_SI = wall.rho_w*units.to_SI.density;
g_SI = wall.g*units.to_SI.acceleration;

%% BREAKER-LIMITED DESIGN WAVE (SI)
[H_design_SI, hb_SI] = goda_Hmax(Hm0_SI, Ts_SI, wall.design_scale, hs_SI, d_SI, Bm_SI, ...
    wall.berm_slope_tana, wall.offshore_slope_tana, g_SI);

%% SI -> IMPERIAL GODA CORE (ft, s, lbf/ft^3, psf)
imp = chess_units('system', 'Imperial');
foot = imp.to_SI.length;
hs = hs_SI/foot;
d = d_SI/foot;
hc = hc_SI/foot;
hw = hw_SI/foot;
H_design = H_design_SI/foot;
hb = hb_SI/foot;
Ts = Ts_SI;
g = g_SI/imp.to_SI.acceleration;
gamma_w = (rho_w_SI*g_SI)/(imp.to_SI.force/foot^3);
beta = wall.beta;
lambda1 = 1;
lambda2 = 1;
lambda3 = 1;

%% COEFFICIENTS (CEM TABLE VI-5-53)
k = NaN(size(hs));
has_depth = hs > 0 & d > 0 & Ts > 0;
if any(has_depth)
    k(has_depth) = wavnum1_VG(Ts(has_depth), d(has_depth), g);
end
alpha1 = 0.6 + 0.5*(2*k.*hs./sinh(2*k.*hs)).^2;
alpha2 = min([(hb - d)./(3*hb).*(H_design./d).^2, 2*d./H_design], [], 2, 'omitnan');
h_prime = hw - hc;
alpha3 = 1 - h_prime./hs.*(1 - 1./cosh(k.*hs));
eta_star = 0.75*(1 + cos(beta))*lambda1*H_design;

%% PRESSURES [psf]
if given_p1
    p1 = options.p1(:)*units.to_SI.pressure/imp.to_SI.pressure;
else
    p1 = 0.5*(1 + cos(beta))*(lambda1*alpha1 + lambda2*alpha2*cos(beta)^2)*gamma_w.*H_design;
end
submerged_crest = hc < 0;
dry_toe = hs <= 0;
p1(submerged_crest | dry_toe) = NaN;
if ~options.distribution
    P.p1 = to_project_units(p1, imp, units, data_dims);
    return
end
p2dyn = (1 - hc./eta_star).*p1;
p2dyn(eta_star <= hc) = 0;
p2dyn(isnan(p1)) = NaN;
p3dyn = alpha3.*p1;
pu = 0.5*(1 + cos(beta))*lambda3*alpha1.*alpha3*gamma_w.*H_design;
pu(isnan(p1)) = NaN;
p2sta = gamma_w*max(-hc, 0);
p2sta(isnan(hc)) = NaN;
p3sta = gamma_w*hs;
p2sta(dry_toe) = NaN;
p3sta(dry_toe) = NaN;
p2total = p2dyn + p2sta;
p3total = p3dyn + p3sta;

%% PSF -> PROJECT UNITS
P.p1 = to_project_units(p1, imp, units, data_dims);
P.p2dyn = to_project_units(p2dyn, imp, units, data_dims);
P.p2sta = to_project_units(p2sta, imp, units, data_dims);
P.p2total = to_project_units(p2total, imp, units, data_dims);
P.p3dyn = to_project_units(p3dyn, imp, units, data_dims);
P.p3sta = to_project_units(p3sta, imp, units, data_dims);
P.p3total = to_project_units(p3total, imp, units, data_dims);
P.pu = to_project_units(pu, imp, units, data_dims);
end

function p = to_project_units(p_psf, imp, units, data_dims)
p = reshape(p_psf*imp.to_SI.pressure/units.to_SI.pressure, data_dims);
end

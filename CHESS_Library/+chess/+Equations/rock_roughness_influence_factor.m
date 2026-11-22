function [gamma_f, xi_m10] = rock_roughness_influence_factor(H, Tmm1, slope, grav)
% chess.Equations.rock_roughness_influence_factor  Rubble mound roughness factor of the Van Gent run-up (single source).
%   [gamma_f, xi_m10] = chess.Equations.rock_roughness_influence_factor(H, Tmm1, slope, grav)
%   returns the rock slope roughness factor used by the run-up z1% and
%   crest velocity u1% equations, element-wise:
%     Lmm1   = grav*Tmm1^2/(2*pi)
%     xi_m10 = 1/(slope*sqrt(H/Lmm1))
%     gamma_f = 0.55                        for xi_m10 <= 2
%     gamma_f = 0.05625*(xi_m10 - 2) + 0.55 for 2 < xi_m10 < 10
%     gamma_f = 1.0                         for xi_m10 >= 10
%   gamma_f is 0 where xi_m10 is NaN; H < 0 gives NaN xi_m10 (real output).
%
%   Inputs:
%     H     - spectral significant wave height at the toe [m], double
%             scalar or array
%     Tmm1  - spectral wave period T_m-1,0 [s], same size as H
%     slope - seaward slope cot(alpha) [-], scalar double
%     grav  - acceleration of gravity [m/s^2], scalar double
%   Outputs:
%     gamma_f - roughness influence factor [-], size of xi_m10
%     xi_m10  - surf similarity parameter on T_m-1,0 [-], size of H and
%               Tmm1 combined
%
%   See also chess.Equations.z1p_calc, chess.Equations.u1p_calc.
%
%   Developed by: Jeffrey A. Melby (JAM)

Lmm1 = grav.*Tmm1.^2./2./pi;
som = H./Lmm1;
som(H < 0) = NaN;
xi_m10 = 1./slope./sqrt(som);
gamma_f = zeros(size(xi_m10));
gamma_f(xi_m10<=2) = 0.55;
gamma_f(xi_m10>2 & xi_m10<10) = 0.05625.*(xi_m10(xi_m10>2 & xi_m10<10)-2)+0.55;
gamma_f(xi_m10>=10) = 1.0;
end

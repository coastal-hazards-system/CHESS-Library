function [gamma_b] = berm_influence_factor(berm_width,berm_elevation,Hm0,SWL,berm_slope_tana)
% berm_influence_factor  EurOtop berm influence factor gamma_b.
%   gamma_b = berm_influence_factor(berm_width, berm_elevation, Hm0, SWL,
%       berm_slope_tana) returns the berm reduction factor for run-up and
%       overtopping for every forcing row.
%
%   EurOtop (2018) Eq. 5.40: gamma_b = 1 - rB*(1 - rDB), limited to
%   0.6 <= gamma_b <= 1, with rB = B/Lberm, Lberm = B + 2*Hm0/berm_slope_tana
%   (berm plus the slope from Hm0 below to Hm0 above it) and the berm
%   depth dBerm = SWL - berm_elevation:
%     rDB = 0.5 - 0.5*cos(pi*dBerm/(2*Hm0))  for -2*Hm0 <= dBerm <= 2*Hm0
%     rDB = 1                                  beyond +/- 2*Hm0
%   (dBerm > 0: berm below SWL; for it the code labels 2*Hm0 as the
%   estimated run-up). berm_width = 0 (no berm) returns ones.
%
%   Inputs (Hm0 and SWL of the same size):
%     berm_width      - berm crest width B [m], scalar
%     berm_elevation  - berm crest elevation [m, study datum, positive up],
%                       scalar
%     Hm0             - spectral significant wave height at the toe [m]
%     SWL             - still water level [m, study datum, positive up]
%     berm_slope_tana - seaward slope of the berm, tan(alpha) [-], scalar
%   Outputs:
%     gamma_b         - berm influence factor [-], size of Hm0
%
%   Tier: public
%
%   See also Eurotop_r2p_q_Final, wall_influence_factor,
%   surface_roughness_influence_factor, oblique_waves_influence_factor,
%   compute_structure_response.

% berm influence
if berm_width~=0
    B = berm_width; % Berm width
    Lberm = B + 2*Hm0./berm_slope_tana;
    dBerm = SWL-berm_elevation;

    rB = B ./ Lberm;
    R2p_Est = 2*Hm0; % Esimated per EurOtop for runup - could be refined more using r2p eq

    rDB = zeros(size(dBerm));
    rDB(dBerm>0)=0.5-0.5*cos(pi.*dBerm(dBerm>0)./R2p_Est(dBerm>0));
    rDB(dBerm<0)=0.5-0.5*cos(pi.*dBerm(dBerm<0)./(2*Hm0(dBerm<0)));
    rDB(dBerm>R2p_Est | dBerm<(-2*Hm0))=1;

    gamma_b = 1-rB.*(1-rDB); % EurOtop eq 5.40
    gamma_b(gamma_b<0.6)=0.6;
    gamma_b(gamma_b>1)=1;

else
    gamma_b = ones(size(Hm0));
end
end
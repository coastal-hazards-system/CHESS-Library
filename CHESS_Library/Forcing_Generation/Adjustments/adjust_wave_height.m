function Hm0 = adjust_wave_height(Hm0, Tp, SWL, toe_elev, apply_DL, g)
% adjust_wave_height  Wave height at the structure toe per storm.
%   Hm0 = adjust_wave_height(Hm0, Tp, SWL, toe_elev, apply_DL, g)
%
%   Depth limits Hm0 (apply_depth_limitation, when apply_DL == 1) using the
%   water depth at the toe (h = SWL - toe_elev): the wave height is limited
%   to the depth-limited height and is NaN where the toe is dry (h <= 0).
%   With apply_DL = 0 Hm0 is returned unchanged; a dry toe is then caught
%   by the depth rules of the responses (h <= 0: wave responses NaN,
%   compute_structure_response). Surge-only responses are still computed.
%   Called by adjust_project_forcing (Hm0_offshore in, Hm0_toe out) and
%   apply_stage1_transmission.
%
%   Inputs:
%     Hm0      - offshore significant wave height [m], cell (one cell per
%                storm or life cycle)
%     Tp       - peak wave period [s], cell (same sizes as Hm0)
%     SWL      - still water level [m, study datum, positive up], cell
%                (same sizes as Hm0)
%     toe_elev - toe elevation [m, study datum, positive up] (signed, < 0
%                below datum zero), scalar double
%     apply_DL - apply depth limitation (0/1; config apply_depth_limitation),
%                double
%     g        - gravity (config gravity_constant) [m/s^2], scalar double
%   Outputs:
%     Hm0 - wave height at the toe [m], cell (same sizes as the input;
%           NaN where h <= 0 when apply_DL == 1)
%
%   Tier: internal
%
%   See also adjust_project_forcing, apply_depth_limitation,
%   apply_stage1_transmission.

% Compute Water Depth @ Toe
h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
% Apply Depth Limitation
if apply_DL == 1
    Hm0 = cellfun(@(x, y, z) apply_depth_limitation(x, y, z, g), Hm0, Tp, h, 'un', false);
end
end

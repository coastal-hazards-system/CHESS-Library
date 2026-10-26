function Hm0 = adjust_wave_height(Hm0, Tp, SWL, toe_elev, apply_DL, g)
% ADJUST_WAVE_HEIGHT Wave height at the structure toe for per-storm forcing cells.
%   Hm0 = adjust_wave_height(Hm0, Tp, SWL, toe_elev, apply_DL, g)
%
%   Depth limits Hm0 (apply_depth_limitation.m, when apply_DL == 1) using the
%   water depth at the toe (SWL - toe_elev), then sets Hm0 = 0 where the toe is
%   emergent (h < 0) regardless of depth limitation. Hm0 = 0 makes wave responses
%   NaN while surge-only responses (e.g. damaging depth) are still computed.
%   Shared by adjust_project_forcing.m and the PROS hazard curve storm overlay.
%
%   Hm0, Tp, SWL: Cell arrays, one cell per storm/life cycle (same sizes).
%   toe_elev: Toe elevation (signed, <0 below datum zero).
%   apply_DL: config.apply_depth_limitation.
%   g: config.gravity_constant.

% Compute Water Depth @ Toe
h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
% Apply Depth Limitation
if apply_DL == 1
    Hm0 = cellfun(@(x, y, z) apply_depth_limitation(x, y, z, g), Hm0, Tp, h, 'un', false);
end
% Emergent Toe (h < 0): No Wave Attack
Hm0 = cellfun(@(x, z) x .* ~(z < 0), Hm0, h, 'un', false);
end

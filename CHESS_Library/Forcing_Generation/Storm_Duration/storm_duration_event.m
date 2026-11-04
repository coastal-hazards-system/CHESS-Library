function r = storm_duration_event(x, t, frac, shift_threshold, min_duration_hr)
% storm_duration_event  Storm duration of one storm from one signal.
%   r = storm_duration_event(x, t)
%   r = storm_duration_event(x, t, frac, shift_threshold, min_duration_hr)
%
%   Threshold crossings around the peak of one signal (SWL, Hm0, ...):
%   A = max(x) - min(x), Z_th = min(x) + frac*A. Crossings of Z_th use
%   linear interpolation between samples. t1 = nearest up-crossing before
%   the peak, t2 = nearest down-crossing after it, duration = t2 - t1
%   [hours]. A side with no crossing uses the record edge and is flagged
%   (edge_start/edge_end). With shift_threshold, a record that starts or
%   ends above Z_th raises Z_th just above the lowest point on that side of
%   the peak (threshold_shifted); a peak on the record's first/last sample
%   has no point on that side, so that side keeps the record edge. The
%   duration is floored at min_duration_hr (t1/t2 stay the computed
%   crossings, no further search; duration_raw_hr keeps the crossing
%   duration, min_applied flags the floor). A flat signal (max(x) ==
%   min(x)) has no crossing: both record edges are used and flat_signal
%   flags it.
%
%   Inputs:
%     x               - signal of one storm, double vector
%     t               - times of x (datenum [days] or datetime), vector
%                       (same length as x)
%     frac            - fraction of the amplitude [-] (optional, default
%                       0.95; [] = default), scalar double
%     shift_threshold - shift Z_th when the record starts/ends above it
%                       (optional, default false; [] = default), logical
%     min_duration_hr - minimum duration [hours] (optional, default 1;
%                       [] = default), scalar double
%   Outputs:
%     r - 1x1 struct with fields:
%           sig_min, sig_max        - signal minimum and maximum (units of x)
%           threshold_base          - Z_th before any shift (units of x)
%           threshold               - Z_th used (units of x)
%           threshold_shifted       - Z_th was shifted, logical
%           peak_time, t1, t2       - peak and crossing times, datetime
%           duration_hr             - duration with the floor [hours]
%           duration_raw_hr         - crossing duration t2 - t1 [hours]
%           min_applied             - floor applied, logical
%           record_hr               - record length [hours]
%           n_crossings             - number of Z_th crossings, double
%           edge_start, edge_end    - no crossing on that side (record
%                                     edge used), logical
%           flat_signal             - max(x) == min(x), logical
%
%   Tier: internal
%
%   See also estimate_storm_durations, timeseries_storm_durations.

if nargin < 5 || isempty(min_duration_hr)
    min_duration_hr = 1;
end
if nargin < 4 || isempty(shift_threshold)
    shift_threshold = false;
end
if nargin < 3 || isempty(frac)
    frac = 0.95;
end
if isdatetime(t)
    t = datenum(t);
end
x = x(:);
t = t(:);
z_min = min(x);
[z_max, i_pk] = max(x);
z_th = z_min + frac*(z_max - z_min);
z_base = z_th;
% Record Starts/Ends Above Z_th: Raise Z_th Just Above The Lowest Point On That Side Of The Peak
if shift_threshold && (x(1) >= z_th || x(end) >= z_th)
    side_min = [min(x(1:i_pk-1)), min(x(i_pk+1:end))];
    z_th = max([z_th, side_min(side_min < z_max) + 1e-6]);
end
s = x - z_th;
% Crossings Between Consecutive Points (Sign Change, Or Exactly On The Threshold)
i_x = find((s(1:end-1) < 0 & s(2:end) >= 0) | (s(1:end-1) >= 0 & s(2:end) < 0));
t_x = t(i_x) + (t(i_x+1) - t(i_x)).*(-s(i_x))./(s(i_x+1) - s(i_x));
% Nearest Crossings To The Peak (The Peak Is Above Z_th, So These Are The Up- And Down-Crossings Bracketing It)
t_pk = t(i_pk);
t_before = t_x(t_x <= t_pk);
t_after = t_x(t_x >= t_pk);
edge_start = isempty(t_before);
edge_end = isempty(t_after);
if edge_start
    t1 = t(1);
else
    t1 = max(t_before);
end
if edge_end
    t2 = t(end);
else
    t2 = min(t_after);
end
r = struct('sig_min', z_min, 'sig_max', z_max, 'threshold_base', z_base, 'threshold', z_th, 'threshold_shifted', z_th ~= z_base,...
    'peak_time', datetime(t_pk, 'ConvertFrom', 'datenum'),...
    't1', datetime(t1, 'ConvertFrom', 'datenum'), 't2', datetime(t2, 'ConvertFrom', 'datenum'),...
    'duration_hr', max((t2 - t1)*24, min_duration_hr), 'duration_raw_hr', (t2 - t1)*24,...
    'min_applied', (t2 - t1)*24 < min_duration_hr, 'record_hr', (t(end) - t(1))*24, 'n_crossings', numel(t_x),...
    'edge_start', edge_start, 'edge_end', edge_end, 'flat_signal', z_max == z_min);
end

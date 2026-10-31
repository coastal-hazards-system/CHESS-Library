function r = storm_duration_event(x, t, frac, shift_threshold, min_duration_hr)
% Storm Duration Of One Storm From One Signal (SWL, Hm0, ...): Threshold Crossings Around The Peak
%   A = max(x) - min(x), Z_th = min(x) + frac*A. Crossings Of Z_th Use Linear Interpolation Between Samples.
%   t1 = Nearest Up-Crossing Before The Peak, t2 = Nearest Down-Crossing After It, Duration = t2 - t1 [hr].
%   A Side With No Crossing Uses The Record Edge And Is Flagged (edge_start/edge_end). With shift_threshold, A Record
%   That Starts Or Ends Above Z_th Raises Z_th Just Above The Lowest Point On That Side Of The Peak (threshold_shifted);
%   A Peak On The Record's First/Last Sample Has No Point On That Side, So That Side Keeps The Record Edge.
%   The Duration Is Floored At min_duration_hr (t1/t2 Stay The Computed Crossings, No Further Search; duration_raw_hr
%   Keeps The Crossing Duration, min_applied Flags The Floor).
%
%   r = storm_duration_event(x, t, frac, shift_threshold, min_duration_hr)
%       x: Signal Of One Storm (Vector)
%       t: Times Of x (datenum Days Or datetime)
%       frac: Fraction Of The Amplitude (Default 0.95)
%       shift_threshold: true = Shift Z_th When The Record Starts/Ends Above It (Default false)
%       min_duration_hr: Minimum Duration [hr] (Default 1)
%       r: struct With sig_min, sig_max, threshold_base, threshold, threshold_shifted, peak_time, t1, t2, duration_hr,
%          duration_raw_hr, min_applied, record_hr, n_crossings, edge_start, edge_end
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
    'edge_start', edge_start, 'edge_end', edge_end);
end

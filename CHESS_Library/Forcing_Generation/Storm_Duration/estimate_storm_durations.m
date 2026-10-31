function T = estimate_storm_durations(x, t, frac, shift_threshold, min_duration_hr)
% Storm Durations For A Set Of Storms From Any Signal (SWL, Hm0, R2p, q, ...): Threshold Crossings Around The Peak
%   Calls storm_duration_event Per Storm (See It For The Method: Z_th = min + frac*(max - min), Nearest Up/Down-Crossings
%   Around The Peak, Optional Threshold Shift, Minimum Duration Floor).
%
%   T = estimate_storm_durations(x, t, frac, shift_threshold, min_duration_hr)
%       x: M x 1 Cell, One Signal Vector Per Storm
%       t: M x 1 Cell Of The Matching Times (datenum Days Or datetime), Or A Scalar Time Step [hr] Shared By All Storms
%          (Times Then Start At 0, And peak_time/t1/t2 Are Returned As Hours From The Record Start)
%       frac: Fraction Of The Amplitude (Default 0.95)
%       shift_threshold: true = Shift The Threshold Per Storm When The Record Starts/Ends Above It (Default false)
%       min_duration_hr: Minimum Duration [hr], A Floor Only (Default 1)
%       T: M x N Table, One Row Per Storm (storm = Row Index In x), Columns As In storm_duration_event
%
%   Example (Processed SP, SWL):
%       s = load('SP02984.mat', 'storm'); D = s.storm.XC.Timeseries.Default; % {id, [SWL Hm0 Tp wDir date dt]}
%       T = estimate_storm_durations(cellfun(@(m) m(:, 1), D(:, 2), 'un', 0), cellfun(@(m) m(:, 5), D(:, 2), 'un', 0), 0.95);
%       T.storm_id = cell2mat(D(:, 1));
if nargin < 5 || isempty(min_duration_hr)
    min_duration_hr = 1;
end
if nargin < 4 || isempty(shift_threshold)
    shift_threshold = false;
end
if nargin < 3 || isempty(frac)
    frac = 0.95;
end
x = x(:);
rel_time = ~iscell(t);
if rel_time
    % Shared Time Step [hr] -> Times In datenum Days From 0
    t = cellfun(@(v) (0:numel(v)-1)'*t/24, x, 'un', false);
end
t = t(:);
if numel(t) ~= numel(x)
    error('x and t must have one cell per storm (%d vs %d).', numel(x), numel(t));
end
rows = cell(numel(x), 1);
for kk = 1:numel(x)
    rows{kk} = storm_duration_event(x{kk}, t{kk}, frac, shift_threshold, min_duration_hr);
end
T = struct2table(vertcat(rows{:}), 'AsArray', true);
T = [table((1:numel(x))', 'VariableNames', {'storm'}), T];
% Shared Time Step: peak_time/t1/t2 As Hours From The Record Start
if rel_time
    t0 = datetime(0, 'ConvertFrom', 'datenum');
    T.peak_time = hours(T.peak_time - t0);
    T.t1 = hours(T.t1 - t0);
    T.t2 = hours(T.t2 - t0);
end
end

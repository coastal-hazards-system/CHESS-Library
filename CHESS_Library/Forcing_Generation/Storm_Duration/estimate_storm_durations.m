function T = estimate_storm_durations(x, t, frac, shift_threshold, min_duration_hr)
% estimate_storm_durations  Storm durations of a set of storms from any signal.
%   T = estimate_storm_durations(x, t)
%   T = estimate_storm_durations(x, t, frac, shift_threshold, min_duration_hr)
%
%   Storm duration of each storm from any signal (SWL, Hm0, R2p, q, ...):
%   threshold crossings around the peak. Calls storm_duration_event per
%   storm (see it for the method: Z_th = min + frac*(max - min), nearest
%   up/down-crossings around the peak, optional threshold shift, minimum
%   duration floor).
%
%   Example (processed storm database, SWL):
%     s = load('SP02984.mat', 'storm'); D = s.storm.XC.Timeseries.Default;
%     T = estimate_storm_durations(cellfun(@(m) m(:, 1), D(:, 2), 'un', 0),
%         cellfun(@(m) m(:, 5), D(:, 2), 'un', 0), 0.95);
%     T.storm_id = cell2mat(D(:, 1));
%   (D rows: {id, [SWL Hm0 Tp wDir datenum dt]}.)
%
%   Inputs:
%     x               - one signal vector per storm, M x 1 cell
%     t               - matching times per storm (datenum [days] or
%                       datetime), M x 1 cell; or a time step shared by all
%                       storms [hours], scalar double (times then start at
%                       0 and peak_time, t1, t2 are returned as hours from
%                       the record start)
%     frac            - fraction of the amplitude [-] (optional, default
%                       0.95; [] = default), scalar double
%     shift_threshold - shift the threshold per storm when the record
%                       starts/ends above it (optional, default false;
%                       [] = default), logical
%     min_duration_hr - minimum duration, a floor only [hours] (optional,
%                       default 1; [] = default), scalar double
%   Outputs:
%     T - one row per storm, table: storm (row index in x) and the
%         storm_duration_event fields (duration_hr [hours], ...); error
%         when x and t have different numbers of cells
%
%   Tier: internal
%
%   See also storm_duration_event, timeseries_storm_durations.

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

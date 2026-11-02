%% MAIN: STORM DURATION FROM THRESHOLD CROSSINGS AROUND THE PEAK
% Example driver for estimate_storm_durations (a set of storms, any signal), storm_duration_event (one storm) and
% plot_storm_duration (plot one storm). Run from the CHESS-Library repo root.
clear; clc; close all

%% SETTINGS
db_file = 'CHESS_Outputs/Chicago_GRR/Event_Database/SP02984.mat'; % One Processed SP (SP*.mat)
frac = 0.98; % Threshold = min + frac*(max - min)
signal = 'SWL'; % 'SWL' Or 'Hm0' (Processed SP Columns: [SWL Hm0 Tp wDir date dt])
shift_threshold = true; % Shift The Threshold Per Storm When The Record Starts/Ends Above It
min_duration_hr = 1; % Minimum Storm Duration [hr] (Floor Only, t1/t2 Stay The Crossings)
storm_type = 'XC'; % this applies only to Timeseries

%% 1. ALL STORMS OF THE SP (Signal + Times As M x 1 Cells)
col = find(strcmpi(signal, {'SWL', 'Hm0'}));
[~, sp] = fileparts(db_file);
load(db_file, 'storm');
D = storm.(storm_type).Timeseries.Default; % {storm_id, [SWL Hm0 Tp wDir date dt]}
% Pull Requested Storm Signal
X = cellfun(@(m) m(:, col), D(:, 2), 'un', false); % SWL, Hm0
% Get Timeseries Timestamp Col
Tm = cellfun(@(m) m(:, 5), D(:, 2), 'un', false); %datenum
% Run Zero up/down-crossing Analysis Centered Around Peak
T = estimate_storm_durations(X, Tm, frac, shift_threshold, min_duration_hr);
% Append Storm ID To Output Table
T = [table(cell2mat(D(:, 1)),...
    'VariableNames', {'storm_id'}), T];

disp('Computed duration for full storm suite....');
fprintf('\n%d storms | duration [hr]: p10 %.2f | median %.2f | p90 %.2f | max %.2f\n', height(T),...
    prctile(T.duration_hr, 10), median(T.duration_hr), prctile(T.duration_hr, 90), max(T.duration_hr));

fprintf('Edge-flagged: %d | Threshold-shifted: %d | At the %g h minimum: %d\n', sum(T.edge_start | T.edge_end),...
    sum(T.threshold_shifted), min_duration_hr, sum(T.min_applied));

%% 2. ONE STORM DIRECTLY (Any Signal + Times)
storm_id = 4102;
m = D{cell2mat(D(:, 1)) == storm_id, 2};
r = storm_duration_event(m(:, col), m(:, 5), frac, shift_threshold, min_duration_hr);
disp(['Computed duration for storm ID ' num2str(storm_id) '....']);
fprintf('\n%s storm %d: t1 %s | t2 %s | duration %.2f hr\n', sp, storm_id, string(r.t1), string(r.t2), r.duration_hr);

%% 3. PLOT ONE STORM (Row Of T For The Requested Storm ID)
row = find(T.storm_id == storm_id, 1);
y_label = [signal ' (m)'];
title_str = sprintf('%s %s storm %d:', sp, storm_type, storm_id);
% Plot Requested Event Storm Duration Figure
plot_storm_duration(T, X, Tm, row, y_label, title_str);


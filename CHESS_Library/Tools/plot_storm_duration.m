function f = plot_storm_duration(T, X, Tm, row, y_label, title_str)
% Plots One Storm Of An estimate_storm_durations Result: The Signal, Its Threshold(s), t1/t2 And The Peak
%   Nothing Is Recomputed: Every Marker Comes From The Table Row. Top: Full Record. Bottom: Zoom On t1..t2 (+/- 12 hr).
%   Threshold (Red), Unshifted Threshold (Grey, Only When Shifted), t1/t2 (Blue), Peak (Red Circle).
%
%   f = plot_storm_duration(T, X, Tm, row, y_label, title_str)
%       T: Output Table Of estimate_storm_durations (Extra Columns Such As storm_id Are Fine)
%       X: The M x 1 Signal Cell Passed To estimate_storm_durations (Row i Of X Matches Row i Of T)
%       Tm: The M x 1 Time Cell (datenum Or datetime), Or The Scalar Time Step [hr] Passed To estimate_storm_durations
%       row: Row Of T To Plot (Default 1)
%       y_label: y-Axis Label (Default 'Signal')
%       title_str: Title Prefix (Default 'storm <storm_id>' When T Has A storm_id Column, Else 'row <row>')
%       f: Figure Handle
%
%   Example:
%       T = estimate_storm_durations(X, Tm, 0.95, true, 1);
%       plot_storm_duration(T, X, Tm, find(T.storm_id == 4102), 'SWL (m)');
if nargin < 4 || isempty(row)
    row = 1;
end
if nargin < 5 || isempty(y_label)
    y_label = 'Signal';
end
if nargin < 6 || isempty(title_str)
    if ismember('storm_id', T.Properties.VariableNames)
        title_str = sprintf('storm %d:', T.storm_id(row));
    else
        title_str = sprintf('row %d:', row);
    end
end
r = table2struct(T(row, :));
x = X{row}(:);
% Times: Scalar Time Step -> Hours From The Start (As In The Table), Else Dates
rel_time = ~iscell(Tm);
if rel_time
    t_plot = (0:numel(x)-1)'*Tm;
    pad = 12;
    t_txt = @(v) sprintf('%.2f h', v);
else
    t_plot = Tm{row}(:);
    if ~isdatetime(t_plot)
        t_plot = datetime(t_plot, 'ConvertFrom', 'datenum');
    end
    pad = hours(12);
    t_txt = @(v) datestr(v, 'dd-mmm-yyyy HH:MM');
end
% Settings Recovered From The Row
frac = (r.threshold_base - r.sig_min)/(r.sig_max - r.sig_min);
% Plot
f = figure('Position', [100 100 1200 700]);
tl = tiledlayout(f, 2, 1, 'TileSpacing', 'compact');
title(tl, sprintf('%s %.0f%% of amplitude, duration %.2f h', title_str, 100*frac, r.duration_hr), 'FontWeight', 'bold');
for k = 1:2
    ax = nexttile(tl);
    hold(ax, 'on');
    box(ax, 'on');
    plot(ax, t_plot, x, 'k.-');
    if r.threshold_shifted
        yline(ax, r.threshold_base, ':', 'Color', [0.5 0.5 0.5], 'Label', sprintf('%.0f%% threshold', 100*frac));
        yline(ax, r.threshold, 'r--', 'Label', 'shifted threshold');
    else
        yline(ax, r.threshold, 'r--', 'Label', sprintf('%.0f%% threshold', 100*frac));
    end
    xline(ax, [r.t1, r.t2], 'b', {'t1', 't2'}, 'LineWidth', 1.5);
    plot(ax, r.peak_time, r.sig_max, 'ro', 'MarkerSize', 8);
    ylabel(ax, y_label);
    if rel_time
        xlabel(ax, 'hours from record start');
    end
    if k == 2
        xlim(ax, [max(t_plot(1), r.t1 - pad), min(t_plot(end), r.t2 + pad)]);
        flags = {};
        if r.edge_start, flags{end+1} = 't1 = record start'; end %#ok<AGROW>
        if r.edge_end, flags{end+1} = 't2 = record end'; end %#ok<AGROW>
        if r.threshold_shifted, flags{end+1} = 'threshold shifted'; end %#ok<AGROW>
        if r.min_applied, flags{end+1} = sprintf('crossings %.2f h -> minimum %.2f h', r.duration_raw_hr, r.duration_hr); end %#ok<AGROW>
        title(ax, sprintf('Zoom (t1 %s, t2 %s)  %s', t_txt(r.t1), t_txt(r.t2), strjoin(flags, ', ')));
    end
end
end

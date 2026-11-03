function hazard_curves = set_hazard_curve_entry(hazard_curves, entry_index, var_name, y_label, title_str,...
    x_plot, y_plot, x_table, y_table, POT, y_log_scale, CL, save_name, n_events, n_dropped, lake_offset)
% set_hazard_curve_entry  Write one PROS hazard curve entry.
%   hazard_curves = set_hazard_curve_entry(hazard_curves, entry_index,
%       var_name, y_label, title_str, x_plot, y_plot, x_table, y_table,
%       POT, y_log_scale, CL, save_name, n_events, n_dropped, lake_offset)
%
%   Writes one hazard curve entry (one response, one storm type) of the
%   PROS hazard curve output, with the same fields in the same order for
%   response-based curves (call_hazard_curve_builder: PST/JPM fit) and
%   frequency-based curves (chess_pros_frequency_base: no fit), so both
%   concatenate into one struct array. Plot and table rows keep AEF/AEP
%   >= 0.001; plot rows are also bounded by the largest table value.
%   x_table_ARI keeps the full table vector (callers convert it).
%
%   Inputs:
%     hazard_curves  - hazard curve entries ([] when empty),
%                      1 x number_of_entries struct
%     entry_index    - entry to write (created if past the end), scalar
%                      double
%     var_name       - response / forcing variable name, char
%     y_label        - y axis label, char
%     title_str      - figure title lines, cell
%     x_plot, y_plot - hazard curve (AEF/AEP, response per CL),
%                      number_of_rows x 1 and number_of_rows x
%                      number_of_CLs double
%     x_table, y_table - hazard table (AEF/AEP, response per CL),
%                      number_of_rows x 1 and number_of_rows x
%                      number_of_CLs double
%     POT            - fitted responses (RB) or a note (FB), double or
%                      cell
%     y_log_scale    - y axis log scale flag, scalar double
%     CL             - percentiles of the curve columns, 1 x
%                      number_of_CLs double
%     save_name      - hazard curve figure file, char
%     n_events       - events handed to PST/JPM ([] without a fit), double
%     n_dropped      - events PST/JPM discarded (NaN, Inf, <= 0 after
%                      shift), scalar double
%     lake_offset    - mean lake level removed before fitting [m], scalar
%                      double
%   Outputs:
%     hazard_curves - hazard curve entries with entry_index written
%                     (fields var, CL, x_plot, y_plot, x_table, y_table,
%                     x_table_ARI, POT, y_label, title, y_log_scale,
%                     save_name, n_events, n_dropped, lake_offset),
%                     1 x number_of_entries struct
%
%   Tier: internal
%
%   See also call_hazard_curve_builder, chess_pros_frequency_base.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

table_rows = x_table >= 0.001;
plot_rows = x_plot >= 0.001 & x_plot <= max(x_table);
hazard_curves(entry_index).var = var_name;
hazard_curves(entry_index).CL = CL;
hazard_curves(entry_index).x_plot = x_plot(plot_rows, :);
hazard_curves(entry_index).y_plot = y_plot(plot_rows, :);
hazard_curves(entry_index).x_table = x_table(table_rows, :);
hazard_curves(entry_index).y_table = y_table(table_rows, :);
hazard_curves(entry_index).x_table_ARI = x_table;
hazard_curves(entry_index).POT = POT;
hazard_curves(entry_index).y_label = y_label;
hazard_curves(entry_index).title = title_str;
hazard_curves(entry_index).y_log_scale = y_log_scale;
hazard_curves(entry_index).save_name = save_name;
hazard_curves(entry_index).n_events = n_events;
hazard_curves(entry_index).n_dropped = n_dropped;
hazard_curves(entry_index).lake_offset = lake_offset;
end

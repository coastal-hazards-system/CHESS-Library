function hazard_curves = set_hazard_curve_entry(hazard_curves, entry_index, var_name, y_label, title_str,...
    x_plot, y_plot, x_table, y_table, POT, y_log_scale, CL, save_name, n_events, n_dropped, lake_offset)
%{
    %% DESCRIPTION
        Writes one hazard curve entry (one response, one storm type) of the
        PROS hazard curve output, with the same fields in the same order for
        response-based curves (call_hazard_curve_builder.m: PST/JPM fit) and
        frequency-based curves (chess_pros_frequency_base.m: no fit), so both
        concatenate into one struct array. Plot and table rows keep AEF/AEP
        >= 0.001; plot rows are also bounded by the largest table value.
        x_table_ARI keeps the full table vector (callers convert it).

    %% INPUTS
        hazard_curves: Hazard curve entries ([] when empty).            | struct | 1 x number_of_entries
        entry_index: Entry to write (created if past the end).          | double | 1 x 1
        var_name: Response / forcing variable name.                     | char
        y_label: Y axis label.                                          | char
        title_str: Figure title lines.                                  | cell
        x_plot, y_plot: Hazard curve (AEF/AEP, response per CL).        | double | number_of_rows x 1, number_of_rows x number_of_CLs
        x_table, y_table: Hazard table (AEF/AEP, response per CL).      | double | number_of_rows x 1, number_of_rows x number_of_CLs
        POT: Fitted responses (RB) or a note (FB).                      | double or cell
        y_log_scale: Y axis log scale flag.                             | double | 1 x 1
        CL: Percentiles of the curve columns.                           | double | 1 x number_of_CLs
        save_name: Hazard curve figure file.                            | char
        n_events: Events handed to PST/JPM ([] without a fit).          | double
        n_dropped: Events PST/JPM discarded (NaN, Inf, <= 0 after shift). | double | 1 x 1
        lake_offset: Mean lake level removed before fitting.            | double | 1 x 1

    %% OUTPUTS
        hazard_curves: Hazard curve entries with entry_index written.   | struct | 1 x number_of_entries

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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

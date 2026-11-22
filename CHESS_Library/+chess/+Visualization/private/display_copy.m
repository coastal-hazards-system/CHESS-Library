function data = display_copy(data, source, units, config)
% display_copy  Copy of saved CHESS data in a display unit system.
%   data = display_copy(data, source, units, config) divides the
%       dimensional values of SI data by the to-SI factor of their unit
%       kind (chess.Common.chess_units), for plots and GUI tables. The
%       saved data stay SI; this copy is only shown.
%
%   What is scaled, by source:
%     'responses', 'forcing' - every struct field named after a
%         chess.Common.response_registry row (numeric array, or cell of
%         numeric arrays), at any struct depth, by the unit kind of the
%         row (Max_time holds dates and is left out); PROS hazard curve
%         entries (struct array with var and y_table): y_plot, y_table,
%         y_grid, numeric POT by the unit kind of var, lake_offset by length,
%         y_label rebuilt (chess.Common.response_library_headers) and
%         '[<SI symbol>]' in the title lines replaced by the display
%         symbol
%     'forcing' with config.workflow 3 - also the LCS life-cycle matrices
%         (cell of numeric matrices): columns SWL, Hm0_toe and
%         Hm0_offshore (chess.Common.lcs_columns) by length
%     'storm'         - storm database rows (cell, storm ID and numeric
%         matrix per row): matrix columns 1-2 (SWL, Hm0) by length
%     'hazard_curves' - PROS hazard curve entries only
%   Tp (s), dt and storm_duration (days), dates, storm IDs and the
%   dimensionless values (armor damage S) are unchanged.
%
%   Inputs:
%     data   - Resp, project_forcing, storm or hazard curve entries (SI),
%              struct (or [])
%     source - 'responses', 'forcing', 'storm' or 'hazard_curves', char
%     units  - display unit system, chess.Common.chess_units('system', ...)
%              struct (name, symbol, to_SI)
%     config - run configuration (SI), 1x1 struct; workflow (forcing),
%              project_datum and the uncertainty fields of the hazard curve
%              rows (chess.Common.response_library_headers) are read
%   Outputs:
%     data - the same layout with the dimensional values in units
%
%   See also chess.Visualization.CHESSPlotsBase, chess.Common.chess_units,
%   chess.Common.response_registry, chess.Common.lcs_columns.

if isempty(data)
    return
end
rows = chess.Common.response_registry('output', 'rows');
factors = containers.Map({rows.name}, arrayfun(@(row) units.to_SI.(row.unit_kind), rows, 'un', false));
cell_rule = @(value) value;
switch source
    case 'hazard_curves'
        data = scale_hazard_curves(data, units, config);
        return
    case 'storm'
        cell_rule = @(value) scale_storm_rows(value, units.to_SI.length);
    case 'forcing'
        if isfield(config, 'workflow') && isequal(config.workflow, 3)
            cell_rule = @(value) scale_life_cycles(value, units.to_SI.length);
        end
end
data = scale_struct(data, factors, cell_rule, units, config);
end

%% LOCAL FUNCTIONS
function s = scale_struct(s, factors, cell_rule, units, config)
if ~isstruct(s)
    return
end
if isfield(s, 'var') && isfield(s, 'y_table')
    s = scale_hazard_curves(s, units, config);
    return
end
if ~isscalar(s)
    return
end
for name = fieldnames(s)'
    value = s.(name{1});
    if strcmp(name{1}, 'Max_time')
        continue
    elseif isKey(factors, name{1})
        s.(name{1}) = scale_value(value, factors(name{1}));
    elseif isstruct(value)
        s.(name{1}) = scale_struct(value, factors, cell_rule, units, config);
    elseif iscell(value)
        s.(name{1}) = cell_rule(value);
    end
end
end

function value = scale_value(value, factor)
if factor == 1
    return
end
if isnumeric(value)
    value = value ./ factor;
elseif iscell(value)
    numeric = cellfun(@isnumeric, value);
    value(numeric) = cellfun(@(x) x ./ factor, value(numeric), 'un', false);
end
end

function hc = scale_hazard_curves(hc, units, config)
si_symbols = chess.Common.chess_units('system', 'SI').symbol;
for ii = 1:numel(hc)
    row = chess.Common.response_registry('name', hc(ii).var);
    if isempty(row)
        continue
    end
    factor = units.to_SI.(row.unit_kind);
    hc(ii).y_plot = scale_value(hc(ii).y_plot, factor);
    hc(ii).y_table = scale_value(hc(ii).y_table, factor);
    hc(ii).y_grid = scale_value(hc(ii).y_grid, factor);
    if isfield(hc, 'POT') && isnumeric(hc(ii).POT)
        hc(ii).POT = scale_value(hc(ii).POT, factor);
    end
    if isfield(hc, 'lake_offset') && isnumeric(hc(ii).lake_offset)
        hc(ii).lake_offset = scale_value(hc(ii).lake_offset, units.to_SI.length);
    end
    if isfield(hc, 'y_label')
        [~, ~, ~, ~, ~, hc(ii).y_label] = chess.Common.response_library_headers(config, hc(ii).var, units.name);
    end
    if isfield(hc, 'title')
        hc(ii).title = strrep(hc(ii).title, ['[' si_symbols.(row.unit_kind) ']'], ['[' units.symbol.(row.unit_kind) ']']);
    end
end
end

function rows = scale_storm_rows(rows, length_factor)
% Storm Database Rows {Storm ID, [SWL Hm0 Tp wDir datenum (dt)]}
if size(rows, 2) ~= 2 || ~all(cellfun(@(x) isnumeric(x) && size(x, 2) >= 2, rows(:, 2)))
    return
end
for rr = 1:size(rows, 1)
    rows{rr, 2}(:, 1:2) = rows{rr, 2}(:, 1:2) ./ length_factor;
end
end

function life_cycles = scale_life_cycles(life_cycles, length_factor)
% LCS Life-Cycle Matrices (chess.Common.lcs_columns), One Per Life Cycle
C = chess.Common.lcs_columns();
if ~all(cellfun(@(x) isnumeric(x) && (isempty(x) || ismember(size(x, 2), [C.n_peaks, C.n_timeseries])), life_cycles))
    return
end
columns = [C.SWL, C.Hm0_toe, C.Hm0_offshore];
for lc = 1:numel(life_cycles)
    if ~isempty(life_cycles{lc})
        life_cycles{lc}(:, columns) = life_cycles{lc}(:, columns) ./ length_factor;
    end
end
end

function export_folder = results(responses, config, paths)
% results  Write the result tables of a run as CSV files, and its config as JSON.
%   export_folder = chess.Export.results(responses, config, paths)
%
%   Readable copy of the project responses file (the .mat files are not
%   changed). Files go to <wf_dir>\Export and start with <db>_<wflow_name>,
%   like every run file. Files of an earlier export of the same run are
%   deleted first. <dataset> is Peaks_Default, Peaks_WLP, Peaks_WHP or
%   Timeseries_Default; <storm> is XC, TC or CC.
%
%   Values are written in config.unit_system (chess.Common.chess_units;
%   'SI' when missing): the SI results are divided by the to-SI factor of
%   the unit kind of each variable (chess.Common.response_registry);
%   dates, storm IDs, dimensionless values and Tp are unchanged.
%
%   Every workflow:
%     <run>_config.json                        configuration as used, its
%                                              inputs as entered
%                                              (chess.Config.from_SI)
%   PROS (response-based and frequency-based), per dataset and storm type:
%     <run>_<dataset>_<storm>_hazard_curve_<response>.csv
%                                              one response, one column per
%                                              confidence limit
%     <run>_<dataset>_<storm>_summary_CL<p>.csv
%                                              one confidence limit, one
%                                              column per response
%     <run>_<dataset>_<storm>_exceedance_at_response_<response>.csv
%                                              one response-based response:
%                                              the response grid (y_grid,
%                                              first column) and the AEP or
%                                              AEF (pros_use_aep) of each
%                                              confidence limit at it
%                                              (x_grid, untrimmed)
%     <run>_<dataset>_<storm>_variables.csv    label (units), number of
%                                              fitted events and mean lake
%                                              level removed
%                                              (lake_offset_<length unit>)
%                                              of each response
%   DET, per dataset and storm type:
%     <run>_<dataset>_<storm>_storm_maxima.csv one row per storm; every value
%                                              is followed by its own date
%                                              (<variable>_date; Rc: date of
%                                              the minimum)
%   LCS (rubble mound), per dataset and storm type:
%     Peaks:      _reliability_summary.csv, _probability_of_failure_summary.csv
%     Timeseries: _damage_statistics.csv, _yearly_damage.csv,
%                 _repair_statistics.csv, _damage_reliability.csv
%
%   Hazard tables carry return_period_years, AEF_per_year and AEP for every
%   row, whichever of the two the run used (pros_use_aep).
%
%   Inputs:
%     responses - project responses (Resp of the project responses file),
%                 struct: <Peaks|Timeseries>.<dataset>.<storm type>
%     config    - CHESS configuration (SI), 1x1 struct; reads workflow,
%                 unit_system, pros_use_aep (PROS), mcs_nYears (LCS) and,
%                 for the PROS labels, project_datum and the uncertainty
%                 fields (chess.Common.response_library_headers)
%     paths     - run paths (chess.ProjectPaths.build), struct; reads wf_dir,
%                 db and wflow_name
%   Outputs:
%     export_folder - folder the files were written to, char
%
%   See also chess.Model, chess.ProjectPaths.build, chess.Config.from_SI,
%   chess.Common.chess_units.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

unit_system = 'SI';
if isfield(config, 'unit_system') && ~isempty(config.unit_system)
    unit_system = char(config.unit_system);
end
units = chess.Common.chess_units('system', unit_system);
export_folder = fullfile(paths.wf_dir, 'Export');
if ~exist(export_folder, 'dir')
    mkdir(export_folder);
end
run_name = [paths.db '_' paths.wflow_name];
run_prefix = fullfile(export_folder, run_name);

% Files Of An Earlier Export Of This Run (Responses Switched Off Since Then Would Stay Behind)
for extension = {'csv', 'json'}
    old_files = dir([run_prefix '_*.' extension{1}]);
    for ii = 1:numel(old_files)
        delete(fullfile(old_files(ii).folder, old_files(ii).name));
    end
end

write_config(chess.Config.from_SI(config, unit_system), [run_prefix '_config.json']);

data_types = fieldnames(responses);
for dd = 1:numel(data_types)
    datasets = fieldnames(responses.(data_types{dd}));
    for ss = 1:numel(datasets)
        dataset = responses.(data_types{dd}).(datasets{ss});
        if ~isstruct(dataset)
            continue
        end
        storm_types = fieldnames(dataset);
        for tt = 1:numel(storm_types)
            storm_results = dataset.(storm_types{tt});
            file_prefix = sprintf('%s_%s_%s_%s', run_prefix, data_types{dd}, datasets{ss}, storm_types{tt});
            switch config.workflow
                case {1, 4} % PROS-RB, PROS-FB
                    write_hazard_curves(storm_results, config, units, file_prefix);
                case 2 % DET
                    write_storm_maxima(storm_results, units, file_prefix);
                case 3 % LCS
                    write_life_cycle_summaries(storm_results, file_prefix);
            end
        end
    end
end
end

%% LOCAL FUNCTIONS
function write_config(config, file_name)
% Config As JSON; A Field jsonencode Cannot Write Is Left Out
names = fieldnames(config);
for ii = 1:numel(names)
    try
        jsonencode(config.(names{ii}));
    catch
        config = rmfield(config, names{ii});
    end
end
file_id = fopen(file_name, 'w');
close_file = onCleanup(@() fclose(file_id));
fprintf(file_id, '%s', jsonencode(config, 'PrettyPrint', true));
end

function write_hazard_curves(hazard_curves, config, units, file_prefix)
% PROS: One File Per Response (All Confidence Limits), One File Per Confidence Limit (All Responses)
if isempty(hazard_curves) || ~isstruct(hazard_curves) || ~isfield(hazard_curves, 'y_table')
    return
end
use_aep = config.pros_use_aep;
has_table = arrayfun(@(entry) isnumeric(entry.y_table) && ~isempty(entry.y_table), hazard_curves);
hazard_curves = hazard_curves(has_table);
if isempty(hazard_curves)
    return
end
frequency_headers = {'return_period_years', 'AEF_per_year', 'AEP'};
for ii = 1:numel(hazard_curves)
    hazard_curves(ii).y_table = hazard_curves(ii).y_table ./ variable_factor(hazard_curves(ii).var, units);
end

% One Response Per File
for ii = 1:numel(hazard_curves)
    entry = hazard_curves(ii);
    limit_headers = arrayfun(@(p) sprintf('CL%g', p), entry.CL(:)', 'un', false);
    write_numeric_csv(sprintf('%s_hazard_curve_%s.csv', file_prefix, entry.var),...
        [frequency_headers, limit_headers], [frequency_columns(entry.x_table, use_aep), entry.y_table]);
end

% Exceedance At The Response Grid (Untrimmed), One Response Per File (Frequency-Based Curves Have No Grid)
if use_aep
    grid_frequency = 'AEP';
else
    grid_frequency = 'AEF_per_year';
end
for ii = 1:numel(hazard_curves)
    entry = hazard_curves(ii);
    if isempty(entry.x_grid)
        continue
    end
    limit_headers = arrayfun(@(p) sprintf('%s_CL%g', grid_frequency, p), entry.CL(:)', 'un', false);
    write_numeric_csv(sprintf('%s_exceedance_at_response_%s.csv', file_prefix, entry.var),...
        [{entry.var}, limit_headers], [entry.y_grid(:) ./ variable_factor(entry.var, units), entry.x_grid]);
end

% One Confidence Limit Per File (Rows: Every Frequency Of Any Response, Most Frequent First)
all_frequencies = unique(vertcat(hazard_curves.x_table));
all_frequencies = sort(all_frequencies(~isnan(all_frequencies)), 'descend');
confidence_limits = unique([hazard_curves.CL], 'stable');
for cc = 1:numel(confidence_limits)
    values = NaN(numel(all_frequencies), numel(hazard_curves));
    for ii = 1:numel(hazard_curves)
        entry = hazard_curves(ii);
        column = find(entry.CL == confidence_limits(cc), 1);
        if isempty(column)
            continue
        end
        [found, row] = ismember(entry.x_table, all_frequencies);
        values(row(found), ii) = entry.y_table(found, column);
    end
    write_numeric_csv(sprintf('%s_summary_CL%g.csv', file_prefix, confidence_limits(cc)),...
        [frequency_headers, {hazard_curves.var}], [frequency_columns(all_frequencies, use_aep), values]);
end

% Label (Units) And Fit Details Of Each Response
variable = {hazard_curves.var}';
label = arrayfun(@(entry) strrep(variable_label(entry, config, units), '$', ''), hazard_curves(:), 'un', false);
events_fitted = arrayfun(@(entry) scalar_or_nan(entry, 'n_events'), hazard_curves(:));
events_dropped = arrayfun(@(entry) scalar_or_nan(entry, 'n_dropped'), hazard_curves(:));
lake_offset = arrayfun(@(entry) scalar_or_nan(entry, 'lake_offset'), hazard_curves(:)) ./ units.to_SI.length;
variables = table(variable, label, events_fitted, events_dropped, lake_offset);
variables.Properties.VariableNames{end} = ['lake_offset_' units.symbol.length];
writetable(variables, [file_prefix '_variables.csv']);
end

function factor = variable_factor(name, units)
% To-SI Factor Of The Unit Kind Of A Registry Variable (1 For A Name Outside chess.Common.response_registry)
factor = 1;
row = chess.Common.response_registry('name', name);
if ~isempty(row)
    factor = units.to_SI.(row.unit_kind);
end
end

function label = variable_label(entry, config, units)
% Saved Label (SI); Another Unit System: Rebuilt For A Registry Variable (chess.Common.response_library_headers)
label = char(string(entry.y_label));
if ~strcmp(units.name, 'SI') && ~isempty(chess.Common.response_registry('name', entry.var))
    [~, ~, ~, ~, ~, label] = chess.Common.response_library_headers(config, entry.var, units.name);
end
end

function columns = frequency_columns(frequency, use_aep)
% Return Period [years], AEF [1/year] And AEP Of The Hazard Table Frequencies
if use_aep
    aep = frequency(:);
    aef = chess.ExtremeValueAnalysis.aep_to_aef(aep);
else
    aef = frequency(:);
    aep = chess.ExtremeValueAnalysis.aef_to_aep(aef);
end
columns = [1./aef, aef, aep];
end

function value = scalar_or_nan(entry, field_name)
value = NaN;
if isfield(entry, field_name) && isnumeric(entry.(field_name)) && isscalar(entry.(field_name))
    value = entry.(field_name);
elseif isfield(entry, field_name) && isnumeric(entry.(field_name)) && ~isempty(entry.(field_name))
    value = numel(entry.(field_name)); % n_events: Events Handed To The Fit
end
end

function write_storm_maxima(storm_results, units, file_prefix)
% DET: One Row Per Storm (Forcing Peaks And Each Response Maximum, Each With Its Own Date)
if ~isstruct(storm_results) || ~isfield(storm_results, 'Max')
    return
end
maxima = storm_results.Max;
number_of_storms = numel(maxima.storm_id);
storm_table = table();
if iscell(maxima.storm_id) || isstring(maxima.storm_id)
    storm_table.storm_id = cellstr(string(maxima.storm_id(:)));
else
    storm_table.storm_id = maxima.storm_id(:);
end
% Date Of Each Value (Max_time, Per Variable); A Run Saved Without It Has The Date Of Peak SWL Only
has_dates = isfield(storm_results, 'Max_time') && isstruct(storm_results.Max_time);
if ~has_dates && isfield(maxima, 'time') && isnumeric(maxima.time) && all(isfinite(maxima.time(:)))
    storm_table.SWL_date = date_text(maxima.time);
end
names = setdiff(fieldnames(maxima), {'storm_id', 'time'}, 'stable');
for ii = 1:numel(names)
    values = maxima.(names{ii});
    if isnumeric(values) && numel(values) == number_of_storms
        storm_table.(names{ii}) = values(:) ./ variable_factor(names{ii}, units);
        if has_dates && isfield(storm_results.Max_time, names{ii})
            storm_table.([names{ii} '_date']) = date_text(storm_results.Max_time.(names{ii}));
        end
    end
end
writetable(storm_table, [file_prefix '_storm_maxima.csv']);
end

function text = date_text(date_numbers)
% Date And Time Of Serial Date Numbers ('' For NaN)
text = repmat({''}, numel(date_numbers), 1);
valid = isfinite(date_numbers(:));
if any(valid)
    text(valid) = cellstr(datestr(date_numbers(valid), 'yyyy-mm-dd HH:MM'));
end
end

function write_life_cycle_summaries(storm_results, file_prefix)
% LCS (Rubble Mound): Armor Reliability (Peaks) And Damage Progression (Timeseries) Summaries
if ~isstruct(storm_results)
    return
end
% Armor Reliability Over The Life Cycles
if isfield(storm_results, 'Reliab_Summary')
    writetable(storm_results.Reliab_Summary, [file_prefix '_reliability_summary.csv']);
end
if isfield(storm_results, 'PF_Summary')
    writetable(storm_results.PF_Summary, [file_prefix '_probability_of_failure_summary.csv']);
end
% Damage Progression
if ~isfield(storm_results, 'S')
    return
end
damage = storm_results.S;
% Final Accumulated Damage Of The Life Cycles (No Repairs)
statistics = damage.stats;
statistics.Properties.VariableNames = {'percentile', 'seaside_mean', 'seaside_percentile_value',...
    'leeside_mean', 'leeside_percentile_value'};
writetable(statistics, [file_prefix '_damage_statistics.csv']);
% Yearly Damage Curves (Year 0 = Start; Percentiles Of config.project_CLs, damage.stats.p, From chess.Model.LifeCycle.yearly_curve)
year = (0:numel(damage.Smax)-1)';
pct = reshape(damage.stats.p, 1, []);
write_numeric_csv([file_prefix '_yearly_damage.csv'],...
    [{'year', 'seaside_mean'}, arrayfun(@(x) sprintf('seaside_P%g', x), pct, 'un', 0),...
    {'leeside_mean'}, arrayfun(@(x) sprintf('leeside_P%g', x), pct, 'un', 0)],...
    [year, damage.Smax(:), damage.SPcurves, damage.LSmax(:), damage.LSPcurves]);
% Repairs
if isfield(damage, 'Repairs_Stats')
    writetable(damage.Repairs_Stats, [file_prefix '_repair_statistics.csv']);
end
% Reliability (Share Of Life Cycles That Never Reached The Limit State)
side = {'Seaside'; 'Leeside'};
reliability = [damage.Reliability_Seaside; damage.Reliability_Leeside];
reliability_table = table(side, reliability);
if isfield(damage, 'seaside_repair_count')
    reliability_table.life_cycles_reaching_limit_state = [damage.seaside_repair_count; damage.leeside_repair_count];
end
writetable(reliability_table, [file_prefix '_damage_reliability.csv']);
end

function write_numeric_csv(file_name, headers, values)
% Numeric Table With A Header Row (NaN Written As An Empty Cell)
file_id = fopen(file_name, 'w');
close_file = onCleanup(@() fclose(file_id));
fprintf(file_id, '%s\n', strjoin(headers, ','));
for rr = 1:size(values, 1)
    cells = arrayfun(@(v) sprintf('%.10g', v), values(rr, :), 'un', false);
    cells(isnan(values(rr, :))) = {''};
    fprintf(file_id, '%s\n', strjoin(cells, ','));
end
end

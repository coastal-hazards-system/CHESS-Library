function out = response_registry(options)
% response_registry  Registry of CHESS forcing variables, responses and armor damage.
%   rows = response_registry() returns every registry row.
%   out = response_registry('output', output, Name, Value, ...) returns the
%   rows, names or compute switches of the rows that pass the filters.
%
%   Registry of the CHESS forcing variables, structure responses and armor
%   damage measures: one row per variable stored in the project forcing /
%   Resp outputs. Single source of the response lists of the library and the
%   GUI (compute switches, structure-type applicability, labels, uncertainty
%   sources, hazard-curve rules). The registry order is the dropdown order.
%
%   Rows (kind):
%       forcing      | SWL, Hm0_offshore, Hm0_toe, Tp, h, Rc
%       response     | Hm0t, R2p, R2p_SWL, Dn50, Dn50_Lee, p1, q, q_wave_ot,
%                    | Q_vol, Q_vol_wave_ot, DamDepthElev, DamDepth,
%                    | p2dyn, p2sta, p2total, p3dyn, p3sta, p3total, pu,
%                    | X_low, X_up, X_c_surge, Bx, theta_low, theta_up,
%                    | theta_center, Bjet, Vjet, Fjet
%       armor_damage | S_seaside_no_repairs, S_seaside_with_repairs,
%                    | S_leeside_no_repairs, S_leeside_with_repairs,
%                    | Smax, LSmax
%
%   Not in the registry: storm DB columns, id columns (storm_id, time, Year,
%   Order), q_overflow and Q_vol_overflow (Eurotop intermediates),
%   compute_damaging_depth_Ks, compute_storm_duration.
%
%   Examples:
%       response_registry('output', 'names', 'per_event', true, 'structure_type', 3)
%       response_registry('output', 'switches', 'structure_type', 2)
%       row = response_registry('name', 'q');
%   In an arguments block declare only `x string`; validators cannot call
%   functions (R2022b), so check in the body:
%   mustBeMember(x, response_registry('output', 'names', 'per_event', true))
%
%   Inputs (name-value, all optional; filters are AND-combined, omitted = no
%   filter):
%     output         - what to return: "rows" (default), "names" or
%                      "switches", string
%     name           - names to keep (registry order kept, unknown names
%                      dropped), string, char or cellstr
%     kind           - "forcing", "response" and/or "armor_damage", string,
%                      char or cellstr
%     structure_type - 1 Levee, 2 Floodwall, 3 Rubblemound [-], scalar double
%     data_type      - "Peaks" or "Timeseries", string or char
%     compute_switch - config compute switch, e.g. 'compute_q', string or
%                      char
%     datum_elevation, pros_forcing_curve, fitted_by_pros_rb,
%     pros_secondary_eb1, per_event, with_repairs - row flag value, scalar
%                      logical (or 0/1)
%     cc_rule, cc_confidence_limit_method, armor_side, damage_summary - row
%                      field value, string or char
%   Outputs:
%     out - depends on output, struct or cell:
%           "rows"     - [Nx1] struct array of the filtered rows (0x1 if
%                        none)
%           "names"    - [1xN] cellstr of the row names (1x0 if none)
%           "switches" - [1xM] cellstr of the unique non-empty compute_switch
%                        values of the filtered rows, first-appearance order
%         Row fields:
%           name           - field name in the forcing / Resp outputs, char
%           kind           - 'forcing', 'response' or 'armor_damage', char
%           compute_switch - config switch that computes it ('' for forcing
%                            and armor damage; S is gated by csr_call_dpa),
%                            char
%           display_name   - plot legend / dropdown label (LaTeX), char
%           axis_label     - axis label; '{datum}' is replaced by
%                            config.project_datum, char
%           unit_label     - unit in SI ('' if dimensionless), char
%           unit_kind      - dimension (length, time, pressure,
%                            discharge_per_length, volume_per_length, angle,
%                            velocity, force_per_length, dimensionless);
%                            pairs with the unit conversion libraries, char
%           log_scale      - 1 to plot on a log axis [-], double
%           structure_types - structure types it applies to [-], double
%           data_types     - {'Peaks','Timeseries'} or {'Timeseries'}, cell
%           datum_elevation - value is an elevation referenced to the datum,
%                            logical
%           pros_forcing_curve - PROS forcing hazard curve, logical
%           fitted_by_pros_rb - hazard curve fitted by PROS-RB, logical
%           pros_secondary_eb1 - secondary floodwall response (p2/p3, nappe)
%                            computed by PROS from the EB1 forcing, logical
%           cc_rule        - 'combine' or 'skip' in the hazard curve
%                            combiner, char
%           cc_confidence_limit_method - 'tropical_only' or 'als_relative',
%                            char
%           absolute_uncertainty - config field of U_a ('' = 0), char
%           relative_uncertainty - config field of U_r ('' = 0), char
%           relative_uncertainty_rule - 'as_is' or 'tp_from_hm0'
%                            (U_r = sqrt(1 + U) - 1), char
%           jpm_uncertainty_treatment - 'combined', 'relative' or 'none',
%                            char
%           per_event      - one value per storm event, logical
%           armor_side     - 'seaside', 'leeside' or '', char
%           with_repairs   - armor damage with structure repairs, logical
%           damage_summary - 'series', 'yearly_mean_max' or '', char
%
%   Tier: internal
%
%   See also response_library_headers, pros_forcing_curves,
%   compute_structure_response, finalize_config.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

arguments
    options.output (1,1) string {mustBeMember(options.output, ["rows", "names", "switches"])} = "rows"
    options.name string
    options.kind string
    options.structure_type (1,1) double
    options.data_type (1,1) string
    options.compute_switch (1,1) string
    options.datum_elevation (1,1) {mustBeNumericOrLogical}
    options.pros_forcing_curve (1,1) {mustBeNumericOrLogical}
    options.fitted_by_pros_rb (1,1) {mustBeNumericOrLogical}
    options.pros_secondary_eb1 (1,1) {mustBeNumericOrLogical}
    options.per_event (1,1) {mustBeNumericOrLogical}
    options.with_repairs (1,1) {mustBeNumericOrLogical}
    options.cc_rule (1,1) string
    options.cc_confidence_limit_method (1,1) string
    options.armor_side (1,1) string
    options.damage_summary (1,1) string
end
persistent registry
if isempty(registry)
    registry = build_registry();
end

keep = true(numel(registry), 1);
if isfield(options, 'name')
    keep = keep & ismember({registry.name}', cellstr(options.name(:)));
end
if isfield(options, 'kind')
    keep = keep & ismember({registry.kind}', cellstr(options.kind(:)));
end
if isfield(options, 'structure_type')
    keep = keep & arrayfun(@(row) ismember(options.structure_type, row.structure_types), registry);
end
if isfield(options, 'data_type')
    keep = keep & arrayfun(@(row) ismember(char(options.data_type), row.data_types), registry);
end
for flag = {'datum_elevation', 'pros_forcing_curve', 'fitted_by_pros_rb', 'pros_secondary_eb1', 'per_event', 'with_repairs'}
    if isfield(options, flag{1})
        keep = keep & [registry.(flag{1})]' == logical(options.(flag{1}));
    end
end
for text_field = {'compute_switch', 'cc_rule', 'cc_confidence_limit_method', 'armor_side', 'damage_summary'}
    if isfield(options, text_field{1})
        keep = keep & strcmp({registry.(text_field{1})}', char(options.(text_field{1})));
    end
end
rows = registry(keep);

switch options.output
    case "rows"
        out = rows;
    case "names"
        out = reshape({rows.name}, 1, []);
    case "switches"
        switches = {rows.compute_switch};
        switches = unique(switches(~cellfun(@isempty, switches)), 'stable');
        out = reshape(switches, 1, []);
end
end

function registry = build_registry()
discharge = '$m^3$/s per m';
volume = '$m^3$ per m';
mean_damage = 'Mean Cumulative Damage $\bar{S}$';
yearly_max_damage = 'Yearly Mean Maximum Cumulative Damage ($\bar{\bar{S}}_{max}$)';
fitted = {'per_event', true, 'fitted_by_pros_rb', true};
overtopping = [fitted, {'log_scale', 1, 'relative_uncertainty', 'q_u', ...
    'jpm_uncertainty_treatment', 'relative', 'cc_confidence_limit_method', 'als_relative'}];
secondary = {'per_event', true, 'pros_secondary_eb1', true, 'cc_rule', 'skip', 'structure_types', 2};
armor = {'structure_types', 3, 'data_types', {'Timeseries'}, 'unit_kind', 'dimensionless'};

rows = {
    % Forcing
    registry_row('SWL', 'forcing', 'display_name', 'SWL', 'axis_label', 'SWL [m, {datum}]', ...
        'absolute_uncertainty', 'chs_swl_u_a', 'relative_uncertainty', 'chs_swl_u_r', ...
        'jpm_uncertainty_treatment', 'combined', 'datum_elevation', true, 'pros_forcing_curve', true)
    registry_row('Hm0_offshore', 'forcing', 'display_name', '$H_{m_{0}}$ (offshore)', ...
        'absolute_uncertainty', 'chs_hm0_u_a', 'relative_uncertainty', 'chs_hm0_u_r', ...
        'jpm_uncertainty_treatment', 'combined', 'pros_forcing_curve', true)
    registry_row('Hm0_toe', 'forcing', 'display_name', '$H_{m_{0}}$ (at toe)', ...
        'relative_uncertainty', 'chs_hm0_u_r', 'jpm_uncertainty_treatment', 'relative', 'pros_forcing_curve', true)
    registry_row('Tp', 'forcing', 'display_name', '$T_p$', 'unit_label', 's', 'unit_kind', 'time', ...
        'relative_uncertainty', 'chs_hm0_u_r', 'relative_uncertainty_rule', 'tp_from_hm0', ...
        'jpm_uncertainty_treatment', 'relative', 'pros_forcing_curve', true)
    registry_row('h', 'forcing', 'display_name', '$h$')
    registry_row('Rc', 'forcing', 'display_name', '$R_c$')
    % Responses
    registry_row('Hm0t', 'response', fitted{:}, 'compute_switch', 'compute_wave_transmission', 'structure_types', [1 3], ...
        'display_name', '$H_{m_{0t}}$', 'absolute_uncertainty', 'chs_hm0_u_a', 'relative_uncertainty', 'chs_hm0_u_r', ...
        'jpm_uncertainty_treatment', 'relative')
    registry_row('R2p', 'response', fitted{:}, 'compute_switch', 'compute_r2p', 'structure_types', [1 3], ...
        'display_name', '$R_{2\%}$', 'relative_uncertainty', 'r2p_u', 'jpm_uncertainty_treatment', 'relative')
    registry_row('R2p_SWL', 'response', fitted{:}, 'compute_switch', 'compute_r2p', 'structure_types', [1 3], ...
        'display_name', '$R_{2\%}$ + SWL', 'relative_uncertainty', 'r2p_u', 'jpm_uncertainty_treatment', 'relative', ...
        'datum_elevation', true)
    registry_row('Dn50', 'response', fitted{:}, 'compute_switch', 'compute_dn50_seaside', 'structure_types', 3, ...
        'display_name', '$D_{n_{50}}$', 'relative_uncertainty', 'dn50_u', 'jpm_uncertainty_treatment', 'relative')
    registry_row('Dn50_Lee', 'response', fitted{:}, 'compute_switch', 'compute_dn50_leeside', 'structure_types', 3, ...
        'display_name', '$D_{n_{50}}$ Lee', 'relative_uncertainty', 'dn50_u', 'jpm_uncertainty_treatment', 'relative')
    registry_row('p1', 'response', fitted{:}, 'compute_switch', 'compute_p1', 'structure_types', 2, ...
        'display_name', '$P_1$', 'unit_label', 'Pa', 'unit_kind', 'pressure', ...
        'relative_uncertainty', 'p1_u', 'jpm_uncertainty_treatment', 'relative')
    registry_row('q', 'response', overtopping{:}, 'compute_switch', 'compute_q', ...
        'display_name', 'q', 'unit_label', discharge, 'unit_kind', 'discharge_per_length')
    registry_row('q_wave_ot', 'response', overtopping{:}, 'compute_switch', 'compute_q', ...
        'display_name', '$q_{overtop}$', 'unit_label', discharge, 'unit_kind', 'discharge_per_length')
    registry_row('Q_vol', 'response', overtopping{:}, 'compute_switch', 'compute_q_vol', 'data_types', {'Timeseries'}, ...
        'display_name', 'Q', 'unit_label', volume, 'unit_kind', 'volume_per_length')
    registry_row('Q_vol_wave_ot', 'response', overtopping{:}, 'compute_switch', 'compute_q_vol', 'data_types', {'Timeseries'}, ...
        'display_name', '$Q_{overtop}$', 'unit_label', volume, 'unit_kind', 'volume_per_length')
    registry_row('DamDepthElev', 'response', fitted{:}, 'compute_switch', 'compute_damaging_depth', ...
        'display_name', 'Damaging Depth Elevation', 'relative_uncertainty', 'chs_swl_u_a', ...
        'jpm_uncertainty_treatment', 'relative', 'datum_elevation', true)
    registry_row('DamDepth', 'response', fitted{:}, 'compute_switch', 'compute_damaging_depth', ...
        'display_name', 'Damaging Depth', 'relative_uncertainty', 'chs_swl_u_a', 'jpm_uncertainty_treatment', 'relative')
    registry_row('p2dyn', 'response', secondary{:}, 'compute_switch', 'compute_p2_p3', ...
        'display_name', '$P_2$ (Dynamic)', 'unit_label', 'Pa', 'unit_kind', 'pressure')
    registry_row('p2sta', 'response', secondary{:}, 'compute_switch', 'compute_p2_p3', ...
        'display_name', '$P_2$ (Static)', 'unit_label', 'Pa', 'unit_kind', 'pressure')
    registry_row('p2total', 'response', secondary{:}, 'compute_switch', 'compute_p2_p3', ...
        'display_name', '$P_2$ (Total)', 'unit_label', 'Pa', 'unit_kind', 'pressure')
    registry_row('p3dyn', 'response', secondary{:}, 'compute_switch', 'compute_p2_p3', ...
        'display_name', '$P_3$ (Dynamic)', 'unit_label', 'Pa', 'unit_kind', 'pressure')
    registry_row('p3sta', 'response', secondary{:}, 'compute_switch', 'compute_p2_p3', ...
        'display_name', '$P_3$ (Static)', 'unit_label', 'Pa', 'unit_kind', 'pressure')
    registry_row('p3total', 'response', secondary{:}, 'compute_switch', 'compute_p2_p3', ...
        'display_name', '$P_3$ (Total)', 'unit_label', 'Pa', 'unit_kind', 'pressure')
    registry_row('pu', 'response', secondary{:}, 'compute_switch', 'compute_p2_p3', ...
        'display_name', '$P_u$', 'unit_label', 'Pa', 'unit_kind', 'pressure')
    registry_row('X_low', 'response', secondary{:}, 'compute_switch', 'compute_nappe', 'display_name', '$X_{low}$')
    registry_row('X_up', 'response', secondary{:}, 'compute_switch', 'compute_nappe', 'display_name', '$X_{up}$')
    registry_row('X_c_surge', 'response', secondary{:}, 'compute_switch', 'compute_nappe', 'display_name', '$X_c$ (surge)')
    registry_row('Bx', 'response', secondary{:}, 'compute_switch', 'compute_nappe', 'display_name', '$B_x$')
    registry_row('theta_low', 'response', secondary{:}, 'compute_switch', 'compute_nappe', ...
        'display_name', '$\theta_{low}$', 'unit_label', 'deg', 'unit_kind', 'angle')
    registry_row('theta_up', 'response', secondary{:}, 'compute_switch', 'compute_nappe', ...
        'display_name', '$\theta_{up}$', 'unit_label', 'deg', 'unit_kind', 'angle')
    registry_row('theta_center', 'response', secondary{:}, 'compute_switch', 'compute_nappe', ...
        'display_name', '$\theta_c$', 'unit_label', 'deg', 'unit_kind', 'angle')
    registry_row('Bjet', 'response', secondary{:}, 'compute_switch', 'compute_nappe', 'display_name', '$B_{jet}$')
    registry_row('Vjet', 'response', secondary{:}, 'compute_switch', 'compute_nappe', ...
        'display_name', '$V_{jet}$', 'unit_label', 'm/s', 'unit_kind', 'velocity')
    registry_row('Fjet', 'response', secondary{:}, 'compute_switch', 'compute_nappe', ...
        'display_name', '$F_{jet}$', 'unit_label', 'N/m', 'unit_kind', 'force_per_length')
    % Armor damage (seaside before leeside, no repairs before with repairs)
    registry_row('S_seaside_no_repairs', 'armor_damage', armor{:}, 'display_name', '$\bar{S}_{no\ repairs}$ (seaside)', ...
        'axis_label', mean_damage, 'per_event', true, 'armor_side', 'seaside', 'with_repairs', false, 'damage_summary', 'series')
    registry_row('S_seaside_with_repairs', 'armor_damage', armor{:}, 'display_name', '$\bar{S}_{with\ repairs}$ (seaside)', ...
        'axis_label', mean_damage, 'per_event', true, 'armor_side', 'seaside', 'with_repairs', true, 'damage_summary', 'series')
    registry_row('S_leeside_no_repairs', 'armor_damage', armor{:}, 'display_name', '$\bar{S}_{no\ repairs}$ (leeside)', ...
        'axis_label', mean_damage, 'per_event', true, 'armor_side', 'leeside', 'with_repairs', false, 'damage_summary', 'series')
    registry_row('S_leeside_with_repairs', 'armor_damage', armor{:}, 'display_name', '$\bar{S}_{with\ repairs}$ (leeside)', ...
        'axis_label', mean_damage, 'per_event', true, 'armor_side', 'leeside', 'with_repairs', true, 'damage_summary', 'series')
    registry_row('Smax', 'armor_damage', armor{:}, 'display_name', '$\bar{\bar{S}}_{max}$ (seaside)', ...
        'axis_label', yearly_max_damage, 'armor_side', 'seaside', 'damage_summary', 'yearly_mean_max')
    registry_row('LSmax', 'armor_damage', armor{:}, 'display_name', '$\bar{\bar{S}}_{max}$ (leeside)', ...
        'axis_label', yearly_max_damage, 'armor_side', 'leeside', 'damage_summary', 'yearly_mean_max')};
registry = vertcat(rows{:});
end

function row = registry_row(name, kind, varargin)
% Row defaults overridden by the field-value pairs; axis_label defaults to 'display_name [unit_label]'.
row = struct('name', name, 'kind', kind, 'compute_switch', '', 'display_name', '', 'axis_label', '', ...
    'unit_label', 'm', 'unit_kind', 'length', 'log_scale', 0, 'structure_types', [1 2 3], ...
    'data_types', {{'Peaks', 'Timeseries'}}, 'datum_elevation', false, 'pros_forcing_curve', false, ...
    'fitted_by_pros_rb', false, 'pros_secondary_eb1', false, 'cc_rule', 'combine', ...
    'cc_confidence_limit_method', 'tropical_only', 'absolute_uncertainty', '', 'relative_uncertainty', '', ...
    'relative_uncertainty_rule', 'as_is', 'jpm_uncertainty_treatment', 'none', 'per_event', false, ...
    'armor_side', '', 'with_repairs', false, 'damage_summary', '');
for k = 1:2:numel(varargin)
    row.(varargin{k}) = varargin{k + 1};
end
if strcmp(row.unit_kind, 'dimensionless')
    row.unit_label = '';
end
if isempty(row.axis_label)
    row.axis_label = [row.display_name ' [' row.unit_label ']'];
end
end

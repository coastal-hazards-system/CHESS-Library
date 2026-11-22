function [U_a, U_r, uncert_treatment_jpm,...
    unit_label,...
    var_name, y_label, y_scale_log] = response_library_headers(config, staID, unit_system)
% chess.Common.response_library_headers  Plot labels and uncertainty of a variable.
%   [U_a, U_r, uncert_treatment_jpm, unit_label, var_name, y_label,
%       y_scale_log] = chess.Common.response_library_headers(config, staID) returns the
%   ... = chess.Common.response_library_headers(config, staID, unit_system)
%   plot labels and uncertainty of a forcing / response variable, all taken
%   from its chess.Common.response_registry row (the single source).
%
%   Names outside the registry get the 'nan' defaults (U_a = U_r = 0,
%   y_scale_log = 0, uncert_treatment_jpm = 'none', labels 'nan'). U_a / U_r
%   are read from the config fields the row names (0 when none, SI);
%   y_label replaces '{datum}' with the project datum and '{unit}' with
%   unit_label. unit_label is the symbol of the unit kind of the row in
%   unit_system (chess.Common.chess_units; SI by default). For 'Hm0_offshore' of a
%   Multi-Line Stage 2 project the label names the stage 1 alternative the
%   waves are transmitted behind (stage1_forcing).
%
%   Inputs:
%     config - CHESS configuration struct, 1x1 struct; the uncertainty
%              fields named by the registry row, project_datum and
%              multiline are read
%     staID  - forcing / response name (a chess.Common.response_registry row name, e.g.
%              'SWL', 'Hm0_toe', 'q'), char
%     unit_system - optional, unit system of the labels, 'SI' (default) or
%              'Imperial', char
%   Outputs:
%     U_a                  - absolute uncertainty [SI units of the variable],
%                            scalar double (0 when none)
%     U_r                  - relative uncertainty [-], scalar double (0 when
%                            none; sqrt(1 + U) - 1 for Tp)
%     uncert_treatment_jpm - JPM uncertainty treatment, 'combined',
%                            'relative' or 'none', char
%     unit_label           - unit symbol in unit_system ('' if
%                            dimensionless), char
%     var_name             - display name for plot legends (LaTeX), char
%     y_label              - axis label with the datum and the unit
%                            filled in (LaTeX), char
%     y_scale_log          - 1 to plot on a log axis, 0 otherwise [-], scalar
%                            double
%
%   See also chess.Common.response_registry, chess.Common.chess_units,
%   stage1_forcing.

if nargin < 3
    unit_system = 'SI';
end
row = chess.Common.response_registry('name', staID);
if isempty(row)
    U_a = 0;U_r = 0;
    y_scale_log = 0;
    uncert_treatment_jpm = 'none';
    unit_label = 'nan';
    y_label = 'nan';
    var_name = 'nan';
    return
end

U_a = 0;
if ~isempty(row.absolute_uncertainty)
    U_a = config.(row.absolute_uncertainty);
end
U_r = 0;
if ~isempty(row.relative_uncertainty)
    U_r = config.(row.relative_uncertainty);
end
if strcmp(row.relative_uncertainty_rule, 'tp_from_hm0')
    U_r = sqrt(1+U_r)-1;
end
uncert_treatment_jpm = row.jpm_uncertainty_treatment;
unit_label = chess.Common.chess_units('system', unit_system).symbol.(row.unit_kind);
var_name = row.display_name;
y_label = strrep(row.axis_label, '{unit}', unit_label);
if contains(y_label, '{datum}')
    y_label = strrep(y_label, '{datum}', config.project_datum);
end
y_scale_log = row.log_scale;

% Multi-Line Stage 2: Waves Transmitted Behind Stage 1 (stage1_forcing)
if strcmp(staID, 'Hm0_offshore') && isfield(config, 'multiline') && isstruct(config.multiline)
    behind = ['(offshore, behind ' regexprep(config.multiline.stage1_alt, '([_&%#{}])', '\\$1') ')'];
    var_name = ['$H_{m_{0}}$ ' behind];
    y_label = [var_name ' [' unit_label ']'];
end
end

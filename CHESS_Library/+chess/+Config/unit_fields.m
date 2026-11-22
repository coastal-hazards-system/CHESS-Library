function [names, kinds] = unit_fields()
% unit_fields  CHESS inputs that carry a unit, with their unit kind.
%   [names, kinds] = chess.Config.unit_fields()
%
%   The union of the input rules (chess.Config.input_rule) of every
%   workflow (chess.Model.input_rules 1-4) and of every structure type
%   (chess.ProtectionSystem.input_rules 1-3) that have a unit_kind. The
%   rules are the single source of the field -> unit kind pairs;
%   chess.Config.to_SI and chess.Config.from_SI convert these fields.
%
%   Inputs:
%     none
%   Outputs:
%     names - input (config field) names, 1 x n cell of char, sorted
%     kinds - unit kind of each name (chess.Common.chess_units kind),
%             1 x n cell of char
%
%   Errors: chess:Config:unit_fields:unitKindConflict when two rules give the same
%   input different unit kinds.
%
%   See also chess.Config.input_rule, chess.Config.to_SI,
%   chess.Config.from_SI, chess.Common.chess_units.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

persistent cache
if isempty(cache)
    rules = [];
    for workflow = 1:4
        rules = [rules, chess.Model.input_rules(workflow)]; %#ok<AGROW>
    end
    for struc_type = 1:3
        rules = [rules, chess.ProtectionSystem.input_rules(struc_type)]; %#ok<AGROW>
    end
    rules = rules(~cellfun(@isempty, {rules.unit_kind}));
    [field_names, first] = unique({rules.name});
    field_kinds = {rules(first).unit_kind};
    for ii = 1:numel(rules)
        kind = field_kinds{strcmp(field_names, rules(ii).name)};
        if ~strcmp(kind, rules(ii).unit_kind)
            error('chess:Config:unit_fields:unitKindConflict', 'Input %s has two unit kinds: %s and %s.',...
                rules(ii).name, kind, rules(ii).unit_kind);
        end
    end
    cache = struct('names', {field_names}, 'kinds', {field_kinds});
end
names = cache.names;
kinds = cache.kinds;
end

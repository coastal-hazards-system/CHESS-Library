function rule = input_rule(name, kind, varargin)
% input_rule  One rule of a CHESS input: its name, kind and limits.
%   rule = chess.Config.input_rule(name, kind)
%   rule = chess.Config.input_rule(name, kind, option, value, ...)
%
%   The classes list the inputs they need with these rules
%   (chess.Model.input_rules, chess.ProtectionSystem.input_rules);
%   chess.Config.validate checks a config against them.
%
%   Inputs:
%     name - config field name, char
%     kind - kind of value, char:
%              'switch'  - 0 or 1
%              'number'  - finite real scalar
%              'integer' - finite whole scalar
%              'text'    - char row or string scalar, not blank
%              'choice'  - one of the values of the option 'choices'
%     Options (name, value pairs):
%       'optional'          - true: the input may be missing or empty
%                             (default false)
%       'required_if'       - config field name, char: the input is
%                             required only when that field is 1 (the
%                             rule is optional otherwise)
%       'allow_blank'       - true: a 'text' input may be blank (default
%                             false)
%       'minimum'           - smallest value allowed, scalar double
%       'exclusive_minimum' - the value must be larger than this, scalar
%                             double
%       'maximum'           - largest value allowed, scalar double
%       'choices'           - allowed values of a 'choice' input, double
%                             array or cell of char
%       'unit_kind'         - unit kind of a dimensional input (a
%                             chess.Common.chess_units kind, e.g.
%                             'length', 'mass', 'density'), char; '' (the
%                             default) = no unit. chess.Config.unit_fields
%                             lists the inputs that have one
%   Outputs:
%     rule - the rule, 1x1 struct (fields name, kind, owner and one field
%            per option; owner is set by the class that lists the rule)
%
%   See also chess.Config.validate, chess.Model.input_rules,
%   chess.ProtectionSystem.input_rules, chess.Config.unit_fields.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
rule = struct('name', name, 'kind', kind, 'owner', '', 'optional', false, 'required_if', '', 'allow_blank', false,...
    'minimum', [], 'exclusive_minimum', [], 'maximum', [], 'choices', [], 'unit_kind', '');
for ii = 1:2:numel(varargin)
    if ~isfield(rule, varargin{ii})
        error('chess:Config:input_rule:unknownRuleOption', 'Unknown input rule option %s.', varargin{ii});
    end
    rule.(varargin{ii}) = varargin{ii+1};
end
end

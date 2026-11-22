function s = from_SI(s, unit_system)
% from_SI  Convert the dimensional inputs of a struct from SI to a unit system.
%   s = chess.Config.from_SI(s, unit_system)
%
%   The inverse of chess.Config.to_SI: every field of s listed by
%   chess.Config.unit_fields that is numeric and not empty is divided by
%   the to-SI factor of its unit kind (chess.Common.chess_units). Other
%   fields, and listed fields that are missing, empty or not numeric, are
%   left as they are. With unit_system 'SI' s is returned unchanged (no
%   field is added or touched). The fields chess.Config.to_SI never
%   converts are not converted here either.
%
%   Inputs:
%     s           - inputs in SI, 1x1 struct
%     unit_system - unit system to convert to, 'SI' or 'Imperial', char or
%                   string
%   Outputs:
%     s - the same struct with the dimensional inputs in unit_system, 1x1
%         struct
%
%   See also chess.Config.to_SI, chess.Config.unit_fields,
%   chess.Common.chess_units.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if strcmp(char(unit_system), 'SI')
    return
end
factors = chess.Common.chess_units('system', char(unit_system)).to_SI;
[names, kinds] = chess.Config.unit_fields();
for ii = 1:numel(names)
    if isfield(s, names{ii}) && isnumeric(s.(names{ii})) && ~isempty(s.(names{ii}))
        s.(names{ii}) = s.(names{ii}) ./ factors.(kinds{ii});
    end
end
end

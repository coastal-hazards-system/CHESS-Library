function out = chess_units(unit_kind)
% chess_units  SI unit symbols of the CHESS unit kinds.
%   symbols = chess_units() returns every unit kind and its symbol.
%   symbol = chess_units(unit_kind) returns the SI symbol of one unit kind.
%
%   CHESS runs in SI only: the symbols label plots, GUI tables and the
%   response_registry rows (unit_label from unit_kind); no value is
%   converted. Kinds and symbols:
%       length 'm', mass 'kg', density 'kg/m^3', force 'N', pressure 'Pa',
%       time 's', angle 'deg', velocity 'm/s',
%       discharge_per_length '$m^3$/s per m',
%       volume_per_length '$m^3$ per m', force_per_length 'N/m',
%       dimensionless ''
%
%   Inputs:
%     unit_kind - unit kind (one of the names above), char or string
%   Outputs:
%     out - symbol of unit_kind (char, '' if dimensionless), or, with no
%           input, struct with one char field per unit kind
%
%   Errors: chess_units:unknownKind when unit_kind is not a unit kind.
%
%   Tier: internal
%
%   See also response_registry, response_library_headers.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

persistent symbols
if isempty(symbols)
    symbols = struct('length', 'm', 'mass', 'kg', 'density', 'kg/m^3', 'force', 'N', ...
        'pressure', 'Pa', 'time', 's', 'angle', 'deg', 'velocity', 'm/s', ...
        'discharge_per_length', '$m^3$/s per m', 'volume_per_length', '$m^3$ per m', ...
        'force_per_length', 'N/m', 'dimensionless', '');
end
if nargin == 0
    out = symbols;
    return
end
unit_kind = char(unit_kind);
if ~isfield(symbols, unit_kind)
    error('chess_units:unknownKind', 'Unknown unit kind "%s". Unit kinds: %s.', ...
        unit_kind, strjoin(fieldnames(symbols), ', '));
end
out = symbols.(unit_kind);
end

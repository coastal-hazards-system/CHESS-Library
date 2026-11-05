function out = chess_units(unit_kind, system_name)
% chess_units  SI unit symbols of the CHESS unit kinds and unit systems.
%   symbols = chess_units() returns every unit kind and its SI symbol.
%   symbol = chess_units(unit_kind) returns the SI symbol of one unit kind.
%   system = chess_units('system', system_name) returns the symbols and
%       the to-SI factors of a unit system ('SI' or 'Imperial').
%
%   The SI symbols label plots, GUI tables and the response_registry rows
%   (unit_label from unit_kind). Kinds and SI symbols:
%       length 'm', mass 'kg', density 'kg/m^3', force 'N', pressure 'Pa',
%       time 's', angle 'deg', velocity 'm/s',
%       discharge_per_length '$m^3$/s per m',
%       volume_per_length '$m^3$ per m', force_per_length 'N/m',
%       dimensionless ''
%   A unit system adds the kind acceleration ('m/s^2', 'ft/s^2'). A value
%   in the unit system times system.to_SI.<kind> is the SI value (every
%   SI factor is 1). Imperial fundamentals (exact): length ft = 0.3048 m,
%   mass lbm = 0.45359237 kg, time s = 1 s, force lbf = 4.4482216152605 N
%   (imperial force is lbf, not lbm*ft/s^2), pressure psf =
%   47.880258980335 Pa. Derived: density lbm/ft^3 = mass/length^3,
%   velocity ft/s = length/time, acceleration ft/s^2 = length/time^2,
%   discharge_per_length = length^2/time, volume_per_length = length^2,
%   force_per_length lbf/ft = force/length; angle (deg) and dimensionless
%   are 1.
%
%   Inputs:
%     unit_kind   - unit kind (one of the names above), or 'system', char
%                   or string
%     system_name - unit system, 'SI' or 'Imperial', char or string (only
%                   with unit_kind = 'system')
%   Outputs:
%     out - symbol of unit_kind (char, '' if dimensionless); with no
%           input, struct with one char field per unit kind; with
%           'system', struct with fields
%             name   - 'SI' or 'Imperial'
%             symbol - struct, one char symbol per unit kind (incl.
%                      acceleration)
%             to_SI  - struct, one double factor per unit kind (value in
%                      the unit system times to_SI = SI value)
%
%   Errors: chess_units:unknownKind when unit_kind is not a unit kind (or
%   a second input follows anything but 'system'); chess_units:unknownSystem
%   when system_name is not 'SI' or 'Imperial'.
%
%   Tier: internal
%
%   See also response_registry, response_library_headers,
%   goda_vertical_wall_pressure_distribution.
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
if nargin == 2
    if ~strcmp(unit_kind, 'system')
        error('chess_units:unknownKind', 'A second input needs unit_kind "system", got "%s".', unit_kind);
    end
    out = unit_system(symbols, char(system_name));
    return
end
if ~isfield(symbols, unit_kind)
    error('chess_units:unknownKind', 'Unknown unit kind "%s". Unit kinds: %s.', ...
        unit_kind, strjoin(fieldnames(symbols), ', '));
end
out = symbols.(unit_kind);
end

function system = unit_system(si_symbols, system_name)
switch system_name
    case 'SI'
        symbol = si_symbols;
        symbol.acceleration = 'm/s^2';
        kinds = fieldnames(symbol);
        to_SI = cell2struct(num2cell(ones(numel(kinds), 1)), kinds, 1);
    case 'Imperial'
        symbol = struct('length', 'ft', 'mass', 'lbm', 'density', 'lbm/ft^3', 'force', 'lbf', ...
            'pressure', 'psf', 'time', 's', 'angle', 'deg', 'velocity', 'ft/s', ...
            'discharge_per_length', '$ft^3$/s per ft', 'volume_per_length', '$ft^3$ per ft', ...
            'force_per_length', 'lbf/ft', 'dimensionless', '', 'acceleration', 'ft/s^2');
        foot = 0.3048;
        pound_mass = 0.45359237;
        second = 1;
        pound_force = 4.4482216152605;
        to_SI = struct('length', foot, 'mass', pound_mass, 'density', pound_mass/foot^3, ...
            'force', pound_force, 'pressure', 47.880258980335, 'time', second, 'angle', 1, ...
            'velocity', foot/second, 'discharge_per_length', foot^2/second, ...
            'volume_per_length', foot^2, 'force_per_length', pound_force/foot, 'dimensionless', 1, ...
            'acceleration', foot/second^2);
    otherwise
        error('chess_units:unknownSystem', 'Unknown unit system "%s". Unit systems: SI, Imperial.', system_name);
end
system = struct('name', system_name, 'symbol', symbol, 'to_SI', to_SI);
end

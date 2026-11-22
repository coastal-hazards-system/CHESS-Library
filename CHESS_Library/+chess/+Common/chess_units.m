function out = chess_units(unit_kind, varargin)
% chess.Common.chess_units  SI unit symbols of the CHESS unit kinds and unit systems, and time unit conversions.
%   symbols = chess.Common.chess_units() returns every unit kind and its SI symbol.
%   symbol = chess.Common.chess_units(unit_kind) returns the SI symbol of one unit kind.
%   system = chess.Common.chess_units('system', system_name) returns the symbols and
%       the to-SI factors of a unit system ('SI' or 'Imperial').
%   y = chess.Common.chess_units('convert', x, from_unit, to_unit) converts the time
%       values x between the time units 's', 'h' and 'day'.
%
%   The SI symbols label plots, GUI tables and the chess.Common.response_registry rows
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
%   A time conversion steps through hours, one factor per step
%   (1 h = 3600 s, 1 day = 24 h): day to s is (x.*24).*3600 and s to day
%   is (x./3600)./24, element-wise, so the result equals the two-step
%   written form bit for bit (never a single 86400 factor).
%
%   Inputs:
%     unit_kind   - unit kind (one of the names above), 'system' or
%                   'convert', char or string
%     varargin    - with 'system': system_name, unit system 'SI' or
%                   'Imperial', char or string; with 'convert': x (time
%                   values, numeric array), from_unit and to_unit ('s',
%                   'h' or 'day', char or string)
%   Outputs:
%     out - symbol of unit_kind (char, '' if dimensionless); with no
%           input, struct with one char field per unit kind; with
%           'system', struct with fields
%             name   - 'SI' or 'Imperial'
%             symbol - struct, one char symbol per unit kind (incl.
%                      acceleration)
%             to_SI  - struct, one double factor per unit kind (value in
%                      the unit system times to_SI = SI value)
%           with 'convert', x in to_unit (same size as x)
%
%   Errors: chess:Common:chess_units:unknownKind when unit_kind is not a unit kind (or
%   a second input follows anything but 'system' or 'convert');
%   chess:Common:chess_units:unknownSystem when system_name is not 'SI' or 'Imperial';
%   chess:Common:chess_units:badConvertCall when 'convert' does not get x, from_unit
%   and to_unit; chess:Common:chess_units:unknownTimeUnit when a time unit is not 's',
%   'h' or 'day' or x is not numeric.
%
%   See also chess.Common.response_registry, chess.Common.response_library_headers,
%   chess.Equations.goda_vertical_wall_pressure_distribution.
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
if strcmp(unit_kind, 'convert')
    if numel(varargin) ~= 3
        error('chess:Common:chess_units:badConvertCall', 'chess_units(''convert'', x, from_unit, to_unit) needs 3 inputs after ''convert'', got %d.', numel(varargin));
    end
    out = convert_time(varargin{:});
    return
end
if nargin >= 2
    if ~strcmp(unit_kind, 'system')
        error('chess:Common:chess_units:unknownKind', 'A second input needs unit_kind "system", got "%s".', unit_kind);
    end
    out = unit_system(symbols, char(varargin{1}));
    return
end
if ~isfield(symbols, unit_kind)
    error('chess:Common:chess_units:unknownKind', 'Unknown unit kind "%s". Unit kinds: %s.', ...
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
        error('chess:Common:chess_units:unknownSystem', 'Unknown unit system "%s". Unit systems: SI, Imperial.', system_name);
end
system = struct('name', system_name, 'symbol', symbol, 'to_SI', to_SI);
end

function y = convert_time(x, from_unit, to_unit)
ladder = {'s', 'h', 'day'};
step = [3600, 24];
i = find(strcmp(ladder, char(from_unit)));
j = find(strcmp(ladder, char(to_unit)));
if isempty(i) || isempty(j) || ~isnumeric(x)
    error('chess:Common:chess_units:unknownTimeUnit', 'Time conversion needs numeric values and the units s, h or day, got "%s" to "%s".', ...
        char(from_unit), char(to_unit));
end
y = x;
for k = i-1:-1:j
    y = y .* step(k);
end
for k = i:j-1
    y = y ./ step(k);
end
end

function s = to_SI(s, unit_system)
% to_SI  Convert the dimensional inputs of a struct from a unit system to SI.
%   s = chess.Config.to_SI(s, unit_system)
%
%   Every field of s listed by chess.Config.unit_fields (swl_slr,
%   csr_cutoff_offset, crest_elevation, crest_width, toe_elevation,
%   wall_bottom_elevation, offshore_elevation, seaside_mass, leeside_mass,
%   water_density) that is numeric and not empty is multiplied by the
%   to-SI factor of its unit kind (chess.Common.chess_units). Other
%   fields, and listed fields that are missing, empty or not numeric, are
%   left as they are (chess.Config.validate reports them). Works on any
%   struct that carries these inputs: a config, PSE inputs, run settings,
%   a structure. With unit_system 'SI' s is returned unchanged (no field
%   is added or touched).
%
%   Never converted (always SI or a fixed unit): storm_duration (hours),
%   gravity_constant (SI, set by the code), the CHS storm data, db_info,
%   the chs_* uncertainties and the grid offshore_elevation, the tide
%   files (m) and the datum_offset of an imported storm database (m).
%
%   Inputs:
%     s           - inputs in unit_system, 1x1 struct
%     unit_system - unit system of the values of s, 'SI' or 'Imperial',
%                   char or string
%   Outputs:
%     s - the same struct with the dimensional inputs in SI, 1x1 struct
%
%   See also chess.Config.from_SI, chess.Config.unit_fields,
%   chess.Common.chess_units, chess.Config.read.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

if strcmp(char(unit_system), 'SI')
    return
end
factors = chess.Common.chess_units('system', char(unit_system)).to_SI;
[names, kinds] = chess.Config.unit_fields();
for ii = 1:numel(names)
    if isfield(s, names{ii}) && isnumeric(s.(names{ii})) && ~isempty(s.(names{ii}))
        s.(names{ii}) = s.(names{ii}) .* factors.(kinds{ii});
    end
end
end

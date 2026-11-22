function config = read(input_file)
% read  Read a CHESS input file into a config struct.
%   config = chess.Config.read(input_file)
%
%   Every section row of the input file (.xlsx or .csv) becomes a config
%   field named by its 'Model Variable Symbol' (last row wins);
%   gravity_constant is set from chess.Common.physical_constants().gravity.
%   unit_system (the unit system the dimensional inputs are entered in)
%   is 'SI' when the file has no unit_system row or leaves it blank; the
%   dimensional inputs are converted to SI (chess.Config.to_SI), so the
%   returned config is SI and keeps unit_system for the exported results.
%   The rules (chess.Config.apply_rules) are not applied here.
%
%   Inputs:
%     input_file - CHESS project input file (.xlsx or .csv), char or string
%   Outputs:
%     config - CHESS configuration, dimensional inputs in SI, 1x1 struct
%
%   See also chess.Config.read_sections, chess.Config.apply_rules,
%   chess.Config.to_SI, chess.Model.create.

config.gravity_constant = chess.Common.physical_constants().gravity; % m/s^2
[~, input_rows] = chess.Config.read_sections(input_file);
for jj = 1:size(input_rows, 1)
    config.(input_rows{jj, 1}) = input_rows{jj, 4};
end
if ~isfield(config, 'unit_system') || isempty(config.unit_system)
    config.unit_system = 'SI';
end
config = chess.Config.to_SI(config, config.unit_system);
end

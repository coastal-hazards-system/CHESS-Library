classdef Levee < chess.ProtectionSystem
    % Levee  Levee protection system element.
    %   pse = chess.ProtectionSystem.Levee(pse_inputs)
    %
    %   Responses: runup_and_overtopping, overtopping_volume,
    %   transmitted_wave_height, damaging_depth (chess.ProtectionSystem).
    %
    %   See also chess.ProtectionSystem.

    properties
        seaside_slope   % seaside slope (cot) [-]
        leeside_slope   % leeside slope (cot) [-]
    end

    properties (Constant)
        structure_type = 1
        structure_name = 'levee'
    end

    methods
        function obj = Levee(varargin)
            % Levee  Build the levee from its PSE inputs (see chess.ProtectionSystem).
            %   obj = chess.ProtectionSystem.Levee(pse_inputs)
            obj@chess.ProtectionSystem(varargin{:});
        end
    end

    methods (Static)
        function rules = structure_input_rules()
            % structure_input_rules  Inputs only a levee needs (chess.ProtectionSystem.input_rules).
            rules = [...
                chess.Config.input_rule('toe_elevation', 'number', 'unit_kind', 'length'),...
                chess.Config.input_rule('seaside_slope', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('leeside_slope', 'number', 'exclusive_minimum', 0)];
        end
    end

    methods (Access = protected)
        function names = struct_field_names(~)
            names = {'crest_elevation', 'crest_width', 'toe_elevation', 'seaside_slope', 'leeside_slope',...
                'water_density', 'roughness_ifactor', 'offshore_slope'};
        end

        function [slope, wall_toe, notional_permeability] = eurotop_geometry(obj, SWL)
            slope = repmat(obj.seaside_slope, size(SWL));
            wall_toe = obj.toe_elevation;
            notional_permeability = 0;
        end

        function tangent = seaward_slope_tangent(obj)
            tangent = 1/obj.seaside_slope;
        end
    end
end

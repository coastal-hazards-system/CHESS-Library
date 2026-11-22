classdef Floodwall < chess.ProtectionSystem
    % Floodwall  Floodwall protection system element.
    %   pse = chess.ProtectionSystem.Floodwall(pse_inputs)
    %
    %   Without a toe berm the wall sits on its bottom: toe_elevation is
    %   set to wall_bottom_elevation.
    %
    %   Responses: runup_and_overtopping, overtopping_volume,
    %   transmitted_wave_height, damaging_depth (chess.ProtectionSystem),
    %   wall_pressures and nappe_jet.
    %
    %   See also chess.ProtectionSystem.

    properties
        wall_bottom_elevation   % elevation of the wall bottom [m, study datum, positive up]
    end

    properties (Constant)
        structure_type = 2
        structure_name = 'floodwall'
    end

    methods
        function obj = Floodwall(varargin)
            % Floodwall  Build the floodwall from its PSE inputs (see chess.ProtectionSystem).
            %   obj = chess.ProtectionSystem.Floodwall(pse_inputs)
            % No Toe Berm: The Wall Bottom Is The Toe (A toe_elevation Input Is Not Needed)
            if nargin > 0 && isfield(varargin{1}, 'wall_bottom_elevation')
                varargin{1}.toe_elevation = varargin{1}.wall_bottom_elevation;
            end
            obj@chess.ProtectionSystem(varargin{:});
        end

        function [pressures, eta_star] = wall_pressures(obj, Hm0_offshore, Tp, SWL, p1, distribution)
            % wall_pressures  Goda wave pressures on the wall.
            %   [pressures, eta_star] = pse.wall_pressures(Hm0_offshore, Tp, SWL)
            %   [pressures, eta_star] = pse.wall_pressures(Hm0_offshore, Tp, SWL, p1, distribution)
            %   p1           - given p1 [Pa] (e.g. a p1 hazard curve); default []
            %                  = compute it
            %   distribution - true (default): every pressure; false: p1 only
            %   pressures - struct of arrays [Pa]: p1 (at SWL), p2dyn, p2sta,
            %               p2total (top of the wall), p3dyn, p3sta, p3total
            %               (base of the wall), pu (uplift); p1 only with
            %               distribution = false
            %   eta_star  - wave run-up height on the wall [m]
            %   Design wave height 1.8*Hm0_offshore, normal incidence, Ts = Tp.
            if nargin < 5
                p1 = [];
            end
            if nargin < 6
                distribution = true;
            end
            units = chess.Common.chess_units('system', 'SI');
            wall = struct('hw', obj.crest_elevation - obj.wall_bottom_elevation, 'Bm', 0, 'berm_slope_tana', 1,...
                'offshore_slope_tana', 1./obj.offshore_slope, 'rho_w', obj.water_density, 'g', obj.gravity_constant,...
                'design_scale', 1.8, 'beta', 0);
            depth_at_toe = SWL - obj.toe_elevation;
            if isempty(p1)
                [pressures, eta_star] = chess.Equations.goda_vertical_wall_pressure_distribution(Hm0_offshore, Tp, depth_at_toe,...
                    depth_at_toe, obj.crest_elevation - SWL, wall, units, distribution = distribution);
            else
                [pressures, eta_star] = chess.Equations.goda_vertical_wall_pressure_distribution(Hm0_offshore, Tp, depth_at_toe,...
                    depth_at_toe, obj.crest_elevation - SWL, wall, units, p1 = p1, distribution = distribution);
            end
        end

        function nappe = nappe_jet(obj, Hm0_toe, SWL, q)
            % nappe_jet  Overtopping nappe geometry and jet behind the wall.
            %   nappe = pse.nappe_jet(Hm0_toe, SWL, q)
            %   q     - overtopping discharge [m^3/s/m]
            %   nappe - struct of arrays: X_low, theta_low, X_up, theta_up,
            %           Bx, X_c_surge, theta_center, Bjet, Vjet, Fjet; NaN
            %           where q is NaN (no overtopping estimate).
            [nappe.X_low, nappe.theta_low, nappe.X_up, nappe.theta_up, nappe.Bx, nappe.X_c_surge, nappe.theta_center,...
                nappe.Bjet, nappe.Vjet, nappe.Fjet] = chess.Equations.floodwall_nappe_response(SWL, Hm0_toe, q,...
                obj.crest_elevation - obj.wall_bottom_elevation, obj.water_density, obj.crest_elevation);
            for name = fieldnames(nappe)'
                value = nappe.(name{1});
                if isequal(size(value), size(q))
                    value(isnan(q)) = NaN;
                elseif all(isnan(q(:)))
                    value(:) = NaN;
                end
                nappe.(name{1}) = value;
            end
        end
    end

    methods (Static)
        function rules = structure_input_rules()
            % structure_input_rules  Inputs only a floodwall needs (chess.ProtectionSystem.input_rules).
            %   toe_elevation is not an input: a floodwall sits on
            %   wall_bottom_elevation (chess.Config.apply_rules).
            rules = chess.Config.input_rule('wall_bottom_elevation', 'number', 'unit_kind', 'length');
        end
    end

    methods (Access = protected)
        function names = struct_field_names(~)
            names = {'crest_elevation', 'crest_width', 'toe_elevation', 'water_density', 'roughness_ifactor',...
                'wall_bottom_elevation', 'offshore_slope'};
        end

        function [slope, wall_toe, notional_permeability] = eurotop_geometry(obj, SWL)
            slope = zeros(size(SWL));
            wall_toe = obj.wall_bottom_elevation;
            notional_permeability = 0;
        end

        function elevation = wall_base_elevation(obj)
            elevation = obj.wall_bottom_elevation;
        end
    end
end

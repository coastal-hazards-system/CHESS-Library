classdef ProtectionSystem
    % ProtectionSystem  Protection system element (PSE): geometry and responses.
    %   Parent class of chess.ProtectionSystem.Levee, .Floodwall and
    %   .RubbleMound. The object holds the geometry; every response method
    %   takes plain forcing arrays (same size) and returns arrays of that
    %   size. The methods call the response equations of chess.Equations.
    %
    %   pse = chess.ProtectionSystem.create(pse_inputs) builds the child of
    %   pse_inputs.struc_type (1 levee, 2 floodwall, 3 rubble mound).
    %
    %   Forcing inputs:
    %     Hm0_toe      - significant wave height at the toe [m]
    %     Hm0_offshore - significant wave height before depth limitation [m]
    %     Tp           - peak wave period [s]
    %     SWL          - still water level [m, study datum, positive up]
    %
    %   Dry toe (toe depth SWL - toe_elevation <= 0): every wave-driven
    %   response is NaN. Equations with a depth input apply the rule
    %   themselves; for the others (run-up, overtopping, transmission,
    %   crest velocity) the methods apply it.
    %
    %   See also chess.ProtectionSystem.Levee, chess.ProtectionSystem.Floodwall,
    %   chess.ProtectionSystem.RubbleMound, chess.Model.

    properties
        crest_elevation             % crest elevation [m, study datum, positive up]
        crest_width                 % crest width [m]
        toe_elevation               % toe elevation [m, study datum, positive up]
        roughness_ifactor           % surface roughness influence factor [-] (> 1 = grass)
        water_density               % water density [kg/m^3]
        gravity_constant            % gravity [m/s^2]
        offshore_slope              % offshore slope (cot) [-]: damaging depth, floodwall Goda breaking height
        offshore_elevation = []     % elevation of the offshore end of the transect [m, study datum]; set by the model
        offshore_elevation_source = '' % where offshore_elevation comes from (label)
        multiline_stage = 0         % 0 single line, 1 offshore line, 2 line behind
    end

    properties (Abstract, Constant)
        structure_type              % 1 levee, 2 floodwall, 3 rubble mound
        structure_name              % 'levee', 'floodwall' or 'rubblemound'
    end

    methods (Static)
        function rules = input_rules(struc_type)
            % input_rules  Inputs a protection system of struc_type needs.
            %   rules = chess.ProtectionSystem.input_rules(struc_type)
            %   Rules (chess.Config.input_rule) of the inputs shared by every
            %   structure, of the inputs of the child class
            %   (structure_input_rules of Levee, Floodwall or RubbleMound) and
            %   of the response switches that apply to the structure type
            %   (chess.Common.response_registry). chess.Config.validate checks
            %   a config against them. offshore_elevation is optional here:
            %   chess.Model.check_offshore_elevation requires it once the
            %   storm database value is known.
            shared = [...
                chess.Config.input_rule('crest_elevation', 'number', 'unit_kind', 'length'),...
                chess.Config.input_rule('crest_width', 'number', 'minimum', 0, 'unit_kind', 'length'),...
                chess.Config.input_rule('water_density', 'number', 'exclusive_minimum', 0, 'unit_kind', 'density'),...
                chess.Config.input_rule('roughness_ifactor', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('offshore_slope', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('offshore_elevation', 'number', 'optional', true, 'unit_kind', 'length'),...
                chess.Config.input_rule('compute_damaging_depth_Ks', 'number', 'minimum', 0, 'required_if', 'compute_damaging_depth')];
            switch struc_type
                case 1
                    own = chess.ProtectionSystem.Levee.structure_input_rules();
                    owner = chess.ProtectionSystem.Levee.structure_name;
                case 2
                    own = chess.ProtectionSystem.Floodwall.structure_input_rules();
                    owner = chess.ProtectionSystem.Floodwall.structure_name;
                case 3
                    own = chess.ProtectionSystem.RubbleMound.structure_input_rules();
                    owner = chess.ProtectionSystem.RubbleMound.structure_name;
                otherwise
                    error('chess:ProtectionSystem:unsupportedStructureType',...
                        'Unsupported structure type %d (1 = Levee, 2 = Floodwall, 3 = Rubblemound).', struc_type);
            end
            switches = cellfun(@(name) chess.Config.input_rule(name, 'switch'),...
                chess.Common.response_registry('output', 'switches', 'structure_type', struc_type));
            rules = [shared, own, switches];
            [rules.owner] = deal(owner);
        end

        function pse = create(pse_inputs)
            % create  Protection system of pse_inputs.struc_type.
            %   pse = chess.ProtectionSystem.create(pse_inputs)
            %   pse_inputs: PSE inputs (config) or a saved structure struct.
            switch pse_inputs.struc_type
                case 1
                    pse = chess.ProtectionSystem.Levee(pse_inputs);
                case 2
                    pse = chess.ProtectionSystem.Floodwall(pse_inputs);
                case 3
                    pse = chess.ProtectionSystem.RubbleMound(pse_inputs);
                otherwise
                    error('chess:ProtectionSystem:unsupportedStructureType',...
                        'Unsupported structure type %d (1 = Levee, 2 = Floodwall, 3 = Rubblemound).', pse_inputs.struc_type);
            end
        end
    end

    methods
        function obj = ProtectionSystem(pse_inputs)
            % ProtectionSystem  Build the element from its PSE inputs.
            %   pse_inputs: struct with one field per geometry property
            %   (config of a run, or the struct returned by to_struct).
            if nargin == 0
                return
            end
            if ~isfield(pse_inputs, 'gravity_constant') || isempty(pse_inputs.gravity_constant)
                pse_inputs.gravity_constant = chess.Common.physical_constants().gravity;
            end
            required = [obj.struct_field_names(), {'gravity_constant'}];
            for name = required
                if ~isfield(pse_inputs, name{1})
                    error('chess:ProtectionSystem:missingInput', 'The %s inputs need the field %s.', obj.structure_name, name{1});
                end
                obj.(name{1}) = pse_inputs.(name{1});
            end
            optional = {'offshore_elevation', 'offshore_elevation_source', 'multiline_stage'};
            for name = optional
                if isfield(pse_inputs, name{1}) && ~isempty(pse_inputs.(name{1}))
                    obj.(name{1}) = pse_inputs.(name{1});
                end
            end
        end

        function [R2p, R2p_SWL, q, q_overflow, q_wave_ot] = runup_and_overtopping(obj, Hm0_toe, Tp, SWL)
            % runup_and_overtopping  EurOtop run-up and overtopping discharge.
            %   [R2p, R2p_SWL, q, q_overflow, q_wave_ot] =
            %       pse.runup_and_overtopping(Hm0_toe, Tp, SWL)
            %   R2p        - 2 percent run-up elevation [m, study datum]
            %   R2p_SWL    - 2 percent run-up above SWL [m]
            %   q          - mean overtopping discharge (waves + overflow) [m^3/s/m]
            %   q_overflow - overflow discharge [m^3/s/m]
            %   q_wave_ot  - wave overtopping discharge [m^3/s/m]
            %   Spectral period T_m-1,0 from Tp (chess.BoundaryConditions.waves.period_from_peak);
            %   freeboard Rc = crest - SWL. Dry toe: R2p, R2p_SWL, q and
            %   q_wave_ot NaN (q_overflow kept).
            gammas = obj.influence_factors(Hm0_toe, SWL);
            [slope, wall_toe, notional_permeability] = obj.eurotop_geometry(SWL);
            [R2p, R2p_SWL, q, q_overflow, q_wave_ot] = chess.Equations.Eurotop_r2p_q_Final(Hm0_toe,...
                chess.BoundaryConditions.waves.period_from_peak(Tp, 'spectral'), SWL,...
                obj.crest_elevation - SWL, slope, gammas.gamma_f, gammas.gamma_beta_r2p, gammas.gamma_beta_q,...
                gammas.gamma_star, gammas.gamma_v, gammas.gamma_b, wall_toe, notional_permeability,...
                obj.gravity_constant, obj.structure_type);
            dry_toe = obj.dry_toe(SWL);
            R2p(dry_toe) = NaN;
            R2p_SWL(dry_toe) = NaN;
            q(dry_toe) = NaN;
            q_wave_ot(dry_toe) = NaN;
        end

        function Q_vol = overtopping_volume(obj, q, dt, step) %#ok<INUSL>
            % overtopping_volume  Running overtopping volume of a hydrograph.
            %   Q_vol = pse.overtopping_volume(q, dt)
            %   Q_vol = pse.overtopping_volume(q, dt, step)
            %   q    - overtopping discharge per row [m^3/s/m]
            %   dt   - row time step [days]
            %   step - storm step counter (0 at the first row of each storm);
            %          the total restarts at every storm. Default []: the
            %          rows are one storm.
            %   Q_vol - running sum of q.*dt down the rows [m^3/m] (NaN
            %           counts as 0); a storm's total is its last value.
            if nargin < 4
                step = [];
            end
            Q_vol = q.*chess.Common.chess_units('convert', dt, 'day', 's');
            Q_vol(isnan(Q_vol)) = 0;
            if isempty(step)
                Q_vol = cumsum(Q_vol, 1);
                return
            end
            starts = [find(step == 0); size(Q_vol, 1) + 1];
            for ss = 1:length(starts)-1
                rows = starts(ss):starts(ss+1)-1;
                Q_vol(rows, :) = cumsum(Q_vol(rows, :), 1);
            end
        end

        function [Hm0_transmitted, Kt] = transmitted_wave_height(obj, Hm0_toe, Tp, SWL)
            % transmitted_wave_height  Wave height behind the structure (EurOtop Kt).
            %   [Hm0_transmitted, Kt] = pse.transmitted_wave_height(Hm0_toe, Tp, SWL)
            %   Hm0_transmitted = Hm0_toe.*Kt [m]; Kt transmission coefficient [-].
            %   Dry toe: both NaN.
            Kt = chess.Equations.eurotop_wave_transmission(Hm0_toe, Tp, obj.crest_elevation - SWL, obj.crest_width,...
                obj.seaward_slope_tangent(), obj.gravity_constant);
            Kt(obj.dry_toe(SWL)) = NaN;
            Hm0_transmitted = Hm0_toe.*Kt;
        end

        function [damaging_depth_elevation, depth_above_offshore] = damaging_depth(obj, Hm0_offshore, Tp, SWL, Ks)
            % damaging_depth  Damaging depth elevation and depth above the offshore end.
            %   [damaging_depth_elevation, depth_above_offshore] =
            %       pse.damaging_depth(Hm0_offshore, Tp, SWL, Ks)
            %   Ks - damaging depth coefficient (config compute_damaging_depth_Ks) [-]
            %   Uses offshore_elevation and offshore_slope of the object.
            %   Dry toe (SWL - toe_elevation <= 0): both outputs NaN
            %   (chess.Equations.damaging_depth).
            if isempty(obj.offshore_elevation)
                error('chess:ProtectionSystem:missingOffshoreElevation', 'Set offshore_elevation before computing the damaging depth.');
            end
            depth_at_toe = SWL - obj.toe_elevation;
            [damaging_depth_elevation, depth_above_offshore] = chess.Equations.damaging_depth(SWL, Hm0_offshore, Tp,...
                obj.offshore_elevation, Ks, depth_at_toe, depth_at_toe, 0, 1, 1./obj.offshore_slope, obj.gravity_constant);
        end

        function ax = plot_geometry(obj, ax)
            % plot_geometry  Draw the transect of the element.
            %   ax = pse.plot_geometry()     new figure
            %   ax = pse.plot_geometry(ax)   into the given axes
            %   Drawn by the library transect plot
            %   (chess.Visualization.CHESSPlotsBase.pse_transect_plot), SI units.
            if nargin < 2
                ax = axes(figure);
            end
            structure = obj.to_struct();
            structure.add_toe_berm = 0;
            plot_config = struct('project_datum', '', 'struc_id', obj.structure_name, 'case_name', '',...
                'struc_type', obj.structure_type, 'add_toe_berm', 0);
            plots = chess.Visualization.CHESSPlotsBase(plot_config, [], [], [], [], structure, 12, 'SI');
            ax = plots.pse_transect_plot(ax);
        end

        function structure = to_struct(obj)
            % to_struct  Geometry as the plain struct saved with a run.
            %   structure = pse.to_struct()
            %   chess.ProtectionSystem.create(structure) rebuilds the object.
            for name = obj.struct_field_names()
                structure.(name{1}) = obj.(name{1});
            end
            structure.struc_type = obj.structure_type;
            structure.gravity_constant = obj.gravity_constant;
            if ~isempty(obj.offshore_elevation)
                structure.offshore_elevation = obj.offshore_elevation;
                structure.offshore_elevation_source = obj.offshore_elevation_source;
            end
            if obj.multiline_stage ~= 0
                structure.multiline_stage = obj.multiline_stage;
            end
        end
    end

    methods (Access = protected)
        function dry = dry_toe(obj, SWL)
            % True where the toe is dry: toe depth SWL - toe_elevation <= 0 (wave-driven responses NaN)
            dry = SWL - obj.toe_elevation <= 0;
        end

        function gammas = influence_factors(obj, Hm0_toe, SWL)
            % EurOtop influence factors (wall, roughness, obliquity, berm) of the forcing rows
            [gammas.gamma_v, gammas.gamma_star] = chess.Equations.wall_influence_factor(obj.crest_elevation,...
                obj.wall_base_elevation(), obj.crest_elevation - SWL, obj.structure_type);
            gammas.gamma_f = chess.Equations.surface_roughness_influence_factor(obj.roughness_ifactor, Hm0_toe);
            [gammas.gamma_beta_r2p, gammas.gamma_beta_q] = chess.Equations.oblique_waves_influence_factor(size(Hm0_toe));
            % No Berm
            gammas.gamma_b = ones(size(Hm0_toe));
        end

        function elevation = wall_base_elevation(obj)
            % Elevation the wall influence factor measures the wall height from (the toe unless there is a wall)
            elevation = obj.toe_elevation;
        end

        function tangent = seaward_slope_tangent(obj) %#ok<MANU>
            % Tangent of the seaward slope used by the wave transmission (no slope: 1)
            tangent = 1;
        end
    end

    methods (Abstract, Access = protected)
        % Fields of the saved structure struct, in order
        names = struct_field_names(obj)
        % Slope (cot, per forcing row), wall toe elevation and notional permeability of the EurOtop call
        [slope, wall_toe, notional_permeability] = eurotop_geometry(obj, SWL)
    end
end

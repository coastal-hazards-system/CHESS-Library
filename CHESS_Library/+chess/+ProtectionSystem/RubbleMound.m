classdef RubbleMound < chess.ProtectionSystem
    % RubbleMound  Rubble mound protection system element.
    %   pse = chess.ProtectionSystem.RubbleMound(pse_inputs)
    %
    %   Responses: runup_and_overtopping, overtopping_volume,
    %   transmitted_wave_height, damaging_depth (chess.ProtectionSystem),
    %   stone_sizes, seaside_stone_size, leeside_stone_size,
    %   seaside_armor_damage, leeside_armor_damage, leeside_crest_velocity,
    %   seaside_stability_margin and leeside_stability_margin.
    %
    %   Periods used by the armor methods: Tm and T_m-1,0 from Tp through
    %   chess.BoundaryConditions.waves.period_from_peak ('mean', 'spectral').
    %   The empirical armor coefficients are read from
    %   CHESS_empirical_coefficients.txt (next to this file).
    %
    %   Slopes in front of the structure: nearshore_slope (seabed right in
    %   front of the toe) is the approach slope tan_m of the stability ANN
    %   and of the stone size validity rules (stone_sizes); offshore_slope (chess.ProtectionSystem) is used only
    %   for the damaging depth.
    %
    %   See also chess.ProtectionSystem, chess.Model.LifeCycle.

    properties
        seaside_slope       % seaside slope (cot) [-]
        leeside_slope       % leeside slope (cot) [-]
        nearshore_slope     % nearshore slope in front of the toe (cot) [-]
        armor_delta         % relative buoyant density of the armor stone [-]
        seaside_mass        % seaside median armor stone mass [kg]
        leeside_mass        % leeside median armor stone mass [kg]
        cem_P               % notional permeability [-]
        seaside_design_S    % seaside design (service limit) damage [-]
        leeside_design_S    % leeside design (service limit) damage [-]
        seaside_S_uls       % seaside ultimate limit damage [-]
        leeside_S_uls       % leeside ultimate limit damage [-]
        dn50_use_legacy_model = 0            % 1 = Melby (seaside) / Van Gent (leeside) equations instead of the ANN
        dn50_legacy_submerged_correction = 0 % 1 = submerged crest correction of the legacy equations
    end

    properties (Constant)
        structure_type = 3
        structure_name = 'rubblemound'
    end

    properties (Constant, Access = private)
        damage_increment_limit = 0.2  % limits the damage accumulation to increments of roughly S > 0.8
        compute_submerged_damage = 0  % submerged damage formulation off
    end

    properties (Access = private)
        empirical_coefficients  % km1, km2, k_si, k_sp, k_ls1, k_ls2 (CHESS_empirical_coefficients.txt)
    end

    methods
        function obj = RubbleMound(varargin)
            % RubbleMound  Build the rubble mound from its PSE inputs (see chess.ProtectionSystem).
            %   obj = chess.ProtectionSystem.RubbleMound(pse_inputs)
            obj@chess.ProtectionSystem(varargin{:});
            obj.empirical_coefficients = chess.ProtectionSystem.RubbleMound.read_empirical_coefficients();
            if nargin > 0
                for name = {'dn50_use_legacy_model', 'dn50_legacy_submerged_correction'}
                    if isfield(varargin{1}, name{1}) && ~isempty(varargin{1}.(name{1}))
                        obj.(name{1}) = varargin{1}.(name{1});
                    end
                end
            end
        end

        function [Dn50_seaside, Dn50_leeside] = stone_sizes(obj, Hm0_toe, Tp, SWL, storm_duration)
            % stone_sizes  Seaside and leeside armor stone size Dn50.
            %   [Dn50_seaside, Dn50_leeside] = pse.stone_sizes(Hm0_toe, Tp, SWL, storm_duration)
            %   storm_duration - event length [days] (number of waves = storm_duration/Tm)
            %   Dn50 [m] for the design damage seaside_design_S / leeside_design_S:
            %   chess.Equations.ann_rubblemound_stability, or
            %   chess.Equations.legacy_rubblemound_stability when
            %   dn50_use_legacy_model = 1 (submerged crest correction when
            %   dn50_legacy_submerged_correction = 1). Approach slope tan_m =
            %   1/nearshore_slope. NaN outside the validity rules of
            %   chess.Equations.stone_size_validity (same rules for both models;
            %   dry toe included).
            gammas = obj.influence_factors(Hm0_toe, SWL);
            Tm = chess.BoundaryConditions.waves.period_from_peak(Tp, 'mean');
            Tm10 = chess.BoundaryConditions.waves.period_from_peak(Tp, 'spectral');
            stability_inputs = {Hm0_toe, Tm, Tm10, SWL - obj.toe_elevation, obj.crest_elevation - SWL,...
                chess.Common.chess_units('convert', storm_duration, 'day', 's'), obj.crest_elevation - obj.toe_elevation,...
                obj.crest_width, obj.seaside_slope, obj.leeside_slope, 1./obj.nearshore_slope, obj.cem_P, gammas.gamma_f,...
                obj.seaside_design_S, obj.leeside_design_S, obj.armor_delta, obj.gravity_constant};
            if obj.dn50_use_legacy_model == 1
                coefficients = obj.empirical_coefficients;
                [Dn50_seaside, Dn50_leeside] = chess.Equations.legacy_rubblemound_stability(stability_inputs{:}, Tp,...
                    coefficients.km1, coefficients.km2, coefficients.k_ls1, coefficients.k_ls2,...
                    obj.dn50_legacy_submerged_correction);
            else
                [Dn50_seaside, Dn50_leeside] = chess.Equations.ann_rubblemound_stability(stability_inputs{:});
            end
        end

        function Dn50 = seaside_stone_size(obj, Hm0_toe, Tp, SWL, storm_duration)
            % seaside_stone_size  Seaside armor stone size Dn50 [m] (see stone_sizes).
            %   Dn50 = pse.seaside_stone_size(Hm0_toe, Tp, SWL, storm_duration)
            Dn50 = obj.stone_sizes(Hm0_toe, Tp, SWL, storm_duration);
        end

        function Dn50 = leeside_stone_size(obj, Hm0_toe, Tp, SWL, storm_duration)
            % leeside_stone_size  Leeside armor stone size Dn50 [m] (see stone_sizes).
            %   Dn50 = pse.leeside_stone_size(Hm0_toe, Tp, SWL, storm_duration)
            [~, Dn50] = obj.stone_sizes(Hm0_toe, Tp, SWL, storm_duration);
        end

        function [S, S_zero] = seaside_armor_damage(obj, Hm0_toe, Tp, SWL, dt, previous_damage, first_damaging_storm, cutoff_offset)
            % seaside_armor_damage  Seaside armor damage after one forcing row (Melby).
            %   [S, S_zero] = pse.seaside_armor_damage(Hm0_toe, Tp, SWL, dt,
            %       previous_damage, first_damaging_storm, cutoff_offset)
            %   dt                   - row time step [days] (number of waves = dt/Tm)
            %   previous_damage      - damage S of the previous row [-]
            %   first_damaging_storm - true: no damage yet, or still in the first
            %                          damaging storm (damage initiation
            %                          coefficient k_si, dS = 0.5); false: damage
            %                          progression (k_sp)
            %   cutoff_offset        - [] = no cutoff correction; else the offset
            %                          [m] added to the crest for the submergence
            %                          check
            %   S      - accumulated damage after the row [-]
            %   S_zero - damage of the row started from zero [-]
            %   No wave attack (Hm0_toe <= 0.1 m or dry toe): S =
            %   previous_damage, S_zero = 0
            %   (chess.Equations.seaside_armor_stone_damage).
            coefficients = obj.empirical_coefficients;
            if first_damaging_storm
                Ks = coefficients.k_si;
                dS = 0.5;
            else
                Ks = coefficients.k_sp;
                dS = 0;
            end
            [cutoff_switch, cutoff_delta] = chess.ProtectionSystem.RubbleMound.cutoff_settings(cutoff_offset);
            Tm = chess.BoundaryConditions.waves.period_from_peak(Tp, 'mean');
            number_of_waves = chess.Common.chess_units('convert', dt, 'day', 's')./Tm;
            specific_gravity = 1 + obj.armor_delta;
            [S, S_zero] = chess.Equations.seaside_armor_stone_damage(SWL - obj.toe_elevation, previous_damage, Hm0_toe, Tm,...
                obj.crest_elevation, obj.seaside_slope, obj.nominal_diameter(obj.seaside_mass), specific_gravity,...
                obj.gravity_constant, obj.cem_P, number_of_waves, obj.crest_elevation - SWL, obj.damage_increment_limit,...
                cutoff_delta, SWL, cutoff_switch, coefficients.km1, coefficients.km2, Ks, dS, obj.compute_submerged_damage);
        end

        function [S, crest_velocity] = leeside_armor_damage(obj, Hm0_toe, Tp, SWL, dt, previous_damage, previous_crest_velocity, cutoff_offset)
            % leeside_armor_damage  Leeside armor damage after one forcing row.
            %   [S, crest_velocity] = pse.leeside_armor_damage(Hm0_toe, Tp, SWL, dt,
            %       previous_damage, previous_crest_velocity, cutoff_offset)
            %   dt                      - row time step [days]
            %   previous_damage         - damage S of the previous row [-]
            %   previous_crest_velocity - crest velocity u1% of the previous row [m/s]
            %   cutoff_offset           - [] = no cutoff correction; else the
            %                             offset [m]
            %   S              - accumulated damage after the row [-]
            %   crest_velocity - crest velocity u1% of the row [m/s]
            %   Dry toe (SWL - toe_elevation <= 0): no damage, S =
            %   previous_damage and crest_velocity = previous_crest_velocity.
            if obj.dry_toe(SWL)
                S = previous_damage;
                crest_velocity = previous_crest_velocity;
                return
            end
            coefficients = obj.empirical_coefficients;
            [cutoff_switch, cutoff_delta] = chess.ProtectionSystem.RubbleMound.cutoff_settings(cutoff_offset);
            Tm = chess.BoundaryConditions.waves.period_from_peak(Tp, 'mean');
            number_of_waves = chess.Common.chess_units('convert', dt, 'day', 's')./Tm;
            Tm10 = chess.BoundaryConditions.waves.period_from_peak(Tp, 'spectral');
            [S, crest_velocity] = chess.Equations.leeside_armor_stone_damage(previous_damage, Hm0_toe, Tm10,...
                previous_crest_velocity, obj.nominal_diameter(obj.leeside_mass), obj.leeside_slope, obj.seaside_slope, SWL,...
                obj.crest_elevation - SWL, number_of_waves, obj.armor_delta, coefficients.k_ls1, coefficients.k_ls2,...
                obj.crest_width, obj.crest_elevation, obj.gravity_constant, obj.compute_submerged_damage, cutoff_switch, cutoff_delta);
        end

        function [runup, crest_velocity] = leeside_crest_velocity(obj, Hm0_toe, Tp, SWL)
            % leeside_crest_velocity  Run-up z1% and crest velocity u1% of the forcing rows.
            %   [runup, crest_velocity] = pse.leeside_crest_velocity(Hm0_toe, Tp, SWL)
            %   runup          - run-up exceeded by 1 percent of the waves [m]
            %   crest_velocity - crest velocity exceeded by 1 percent of the waves [m/s]
            %   Dry toe: both NaN.
            freeboard = obj.crest_elevation - SWL;
            Tm10 = chess.BoundaryConditions.waves.period_from_peak(Tp, 'spectral');
            runup = chess.Equations.z1p_calc(Hm0_toe, Tm10, freeboard, obj.seaside_slope, obj.gravity_constant);
            crest_velocity = chess.Equations.u1p_calc(obj.crest_width, freeboard, runup, Tm10, Hm0_toe, obj.seaside_slope,...
                obj.gravity_constant);
            dry_toe = obj.dry_toe(SWL);
            runup(dry_toe) = NaN;
            crest_velocity(dry_toe) = NaN;
        end

        function margin = seaside_stability_margin(obj, Hm0_toe, Tp, SWL, storm_duration)
            % seaside_stability_margin  Seaside armor stability margin of each storm.
            %   margin = pse.seaside_stability_margin(Hm0_toe, Tp, SWL, storm_duration)
            %   storm_duration - event length [days]
            %   margin = resistance - loading (Melby and Kobayashi 2011) for the
            %   design damage seaside_design_S; margin < 0 is a failure; NaN
            %   on a dry toe (not a failure).
            Tm = chess.BoundaryConditions.waves.period_from_peak(Tp, 'mean');
            number_of_waves = chess.Common.chess_units('convert', storm_duration, 'day', 's')./Tm;
            margin = chess.Equations.seaside_stability_margin(Hm0_toe, Tm, SWL - obj.toe_elevation, number_of_waves,...
                obj.nominal_diameter(obj.seaside_mass), obj.armor_delta, obj.seaside_design_S, obj.cem_P, obj.seaside_slope,...
                obj.empirical_coefficients.km1, obj.empirical_coefficients.k_si, obj.gravity_constant);
        end

        function margin = leeside_stability_margin(obj, Hm0_toe, Tp, SWL, storm_duration)
            % leeside_stability_margin  Leeside armor stability margin of each storm.
            %   margin = pse.leeside_stability_margin(Hm0_toe, Tp, SWL, storm_duration)
            %   storm_duration - event length [days]
            %   margin = resistance - loading (Van Gent and Pozueta 2004; Melby
            %   2009) for the design damage leeside_design_S; margin < 0 is a
            %   failure; NaN on a dry toe (not a failure).
            Tm = chess.BoundaryConditions.waves.period_from_peak(Tp, 'mean');
            number_of_waves = chess.Common.chess_units('convert', storm_duration, 'day', 's')./Tm;
            Tm10 = chess.BoundaryConditions.waves.period_from_peak(Tp, 'spectral');
            margin = chess.Equations.leeside_stability_margin(Hm0_toe, Tm10, SWL - obj.toe_elevation, number_of_waves,...
                obj.crest_elevation - obj.toe_elevation, obj.crest_width, obj.leeside_slope, obj.seaside_slope,...
                obj.nominal_diameter(obj.leeside_mass), obj.armor_delta, obj.leeside_design_S,...
                obj.empirical_coefficients.k_ls1, obj.empirical_coefficients.k_ls2, obj.gravity_constant);
        end
    end

    methods (Static)
        function rules = structure_input_rules()
            % structure_input_rules  Inputs only a rubble mound needs (chess.ProtectionSystem.input_rules).
            rules = [...
                chess.Config.input_rule('toe_elevation', 'number', 'unit_kind', 'length'),...
                chess.Config.input_rule('seaside_slope', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('leeside_slope', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('nearshore_slope', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('armor_delta', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('seaside_mass', 'number', 'exclusive_minimum', 0, 'unit_kind', 'mass'),...
                chess.Config.input_rule('leeside_mass', 'number', 'exclusive_minimum', 0, 'unit_kind', 'mass'),...
                chess.Config.input_rule('cem_P', 'number', 'exclusive_minimum', 0, 'maximum', 1),...
                chess.Config.input_rule('seaside_design_S', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('leeside_design_S', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('seaside_S_uls', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('leeside_S_uls', 'number', 'exclusive_minimum', 0),...
                chess.Config.input_rule('dn50_use_legacy_model', 'switch', 'optional', true),...
                chess.Config.input_rule('dn50_legacy_submerged_correction', 'switch', 'optional', true)];
        end
    end

    methods (Access = protected)
        function names = struct_field_names(~)
            names = {'crest_elevation', 'crest_width', 'toe_elevation', 'seaside_slope', 'leeside_slope', 'armor_delta',...
                'seaside_mass', 'leeside_mass', 'water_density', 'cem_P', 'seaside_design_S', 'leeside_design_S',...
                'roughness_ifactor', 'seaside_S_uls', 'leeside_S_uls', 'offshore_slope', 'nearshore_slope'};
        end

        function [slope, wall_toe, notional_permeability] = eurotop_geometry(obj, SWL)
            slope = repmat(obj.seaside_slope, size(SWL));
            wall_toe = obj.toe_elevation;
            notional_permeability = obj.cem_P;
        end

        function tangent = seaward_slope_tangent(obj)
            tangent = 1/obj.seaside_slope;
        end
    end

    methods (Access = private)
        function Dn = nominal_diameter(obj, stone_mass)
            % Nominal stone diameter [m] of a median stone mass [kg]
            stone_density = (1 + obj.armor_delta).*obj.water_density;
            Dn = (stone_mass./stone_density).^(1/3);
        end
    end

    methods (Static, Access = private)
        function coefficients = read_empirical_coefficients()
            % Mean values of CHESS_empirical_coefficients.txt: [variable_name, description, units, value, std]
            persistent stored
            if isempty(stored)
                rows = readcell(fullfile(fileparts(mfilename('fullpath')), 'CHESS_empirical_coefficients.txt'));
                rows = rows(2:end, :);
                for ii = 1:size(rows, 1)
                    stored.(rows{ii, 1}) = rows{ii, 4};
                end
            end
            coefficients = stored;
        end

        function [cutoff_switch, cutoff_delta] = cutoff_settings(cutoff_offset)
            % Cutoff correction switch and offset of the damage equations ([] = off)
            cutoff_switch = double(~isempty(cutoff_offset));
            cutoff_delta = 0;
            if cutoff_switch
                cutoff_delta = cutoff_offset;
            end
        end
    end
end

function damage_table = get_overtopping_damage(q, units)
    % GET_OVERTOPPING_DAMAGE Returns a table of damage states for discharge arrays.
    % 
    % Inputs:
    %   q     - Scalar or array of overtopping discharge rates
    %   units - 'm^3/s per m' (default) or 'l/s per m'
    %
    % Output:
    %   damage_table - A MATLAB table detailing the hazard level for all 
    %                  6 structural/safety categories for each input q.

    if nargin < 2
        units = 'm^3/s per m';
    end

    % Ensure q is a column vector so it fits nicely into a table
    q = q(:);
    N = length(q);

    % Convert input to m^3/s per m if provided in liters
    if contains(lower(units), 'l') 
        q_m = q / 1000;
        display_unit = repmat({'l/s per m'}, N, 1);
    else
        q_m = q;
        display_unit = repmat({'m^3/s per m'}, N, 1);
    end

    % Preallocate cell arrays to hold the strings
    veh_str   = cell(N, 1);
    ped_str   = cell(N, 1);
    bldg_str  = cell(N, 1);
    emb_str   = cell(N, 1);
    grass_str = cell(N, 1);
    rev_str   = cell(N, 1);

    %% 1. Vehicles
    veh_str(q_m < 1e-6) = {'Safe driving at all speeds'};
    veh_str(q_m >= 1e-6 & q_m < 1e-5) = {'Unsafe driving at high speed'};
    veh_str(q_m >= 1e-5 & q_m < 3e-5) = {'Unsafe parking on vertical wall breakwaters'};
    veh_str(q_m >= 3e-5 & q_m < 1e-4) = {'Unsafe parking on horizontal composite breakwaters'};
    veh_str(q_m >= 1e-4) = {'Unsafe at any speed'};

    %% 2. Pedestrians
    ped_str(q_m < 3e-5) = {'Wet, but not uncomfortable'};
    ped_str(q_m >= 3e-5 & q_m < 1e-4) = {'Uncomfortable but not dangerous'};
    ped_str(q_m >= 1e-4 & q_m < 1e-3) = {'Dangerous on vertical wall breakwaters, grass sea dikes, and horizontal composite breakwaters'};
    ped_str(q_m >= 1e-3) = {'Very dangerous'};

    %% 3. Buildings
    bldg_str(q_m < 1e-6) = {'No damage'};
    bldg_str(q_m >= 1e-6 & q_m < 1e-3) = {'Minor damage to fittings, sign posts, etc.'};
    bldg_str(q_m >= 1e-3) = {'Structural damage'};

    %% 4. Embankment Seawalls
    emb_str(q_m < 2e-5) = {'No damage'};
    emb_str(q_m >= 2e-5 & q_m < 2e-3) = {'Damage if crest not protected'};
    emb_str(q_m >= 2e-3 & q_m < 2e-2) = {'Damage if back slope not protected'};
    emb_str(q_m >= 2e-2) = {'Damage even if fully protected'};

    %% 5. Grass Sea-Dikes
    grass_str(q_m < 1e-3) = {'No damage'};
    grass_str(q_m >= 1e-3 & q_m < 1e-2) = {'Start of damage'};
    grass_str(q_m >= 1e-2) = {'Damage'};

    %% 6. Revetments
    rev_str(q_m < 5e-2) = {'No damage'};
    rev_str(q_m >= 5e-2 & q_m < 2e-1) = {'Damage if promenade not paved'};
    rev_str(q_m >= 2e-1) = {'Damage even for paved promenade'};

    %% Build the Output Table
    damage_table = table(q, display_unit, veh_str, ped_str, bldg_str, emb_str, grass_str, rev_str, ...
        'VariableNames', {'Discharge', 'Units', 'Vehicles', 'Pedestrians', 'Buildings', 'Embankment_Seawalls', 'Grass_Sea_Dikes', 'Revetments'});
end
 function [CSR_Timeseries_DPA] = chess_csr_dpa(config, structure, emp_coeff, LC_SimOUT_hyd)
% chess_csr_dpa  Rubble mound armor damage progression over LCS life cycles.
%   CSR_Timeseries_DPA = chess_csr_dpa(config, structure, emp_coeff,
%       LC_SimOUT_hyd)
%
%   Damage progression analysis (DPA) of the seaside and leeside armor of
%   a rubble mound, row by row over the Timeseries rows of every life
%   cycle. Seaside damage: seaside_armor_stone_damage (Melby), with the
%   first-damage coefficient k_si (dS = 0.5) until the end of the first
%   damaging storm and k_sp afterwards. Leeside damage:
%   leeside_armor_stone_damage, with the run-up z1p_calc and the crest
%   velocity u1p_calc. Forcing per row: SWL, Hm0_toe, Tp (Tm = Tp/1.2,
%   T_m-1,0 = Tp/1.1) and the number of waves Nz = dt/Tm (dt, the row time
%   step). csr_apply_cutoff_correction / csr_cutoff_offset raise the
%   crest used for the submergence check of the damage functions.
%   Each side is tracked without and with repairs
%   (csr_apply_structure_repair: 0 none; 1 above the service limit
%   seaside_design_S / leeside_design_S; 2 above the ultimate limit
%   seaside_S_uls / leeside_S_uls; 3 either; any other value is an error).
%   When the damage of the previous row exceeds the limit, the rest of
%   that storm is NaN and the damage restarts at 0 at the next storm.
%   Without repairs (0) the with-repairs series equal the no-repairs
%   series.
%   Yearly curves: compute_lcs_yearly_curve on the no-repairs damage, with
%   a year 0 row of zeros. Prints the progress.
%
%   References: Melby (1999, 2009); Melby and Hughes (2004); Melby and
%   Kobayashi (2011); Van Gent and Pozueta (2005); Gonzalez et al. (2020),
%   ERDC/CHL TR-20-5.
%
%   Inputs:
%     config        - CHESS configuration, 1x1 struct; reads
%                     gravity_constant [m/s^2], water_density [kg/m^3],
%                     mcs_nYears, csr_apply_structure_repair (0-3),
%                     csr_apply_cutoff_correction (0/1) and
%                     csr_cutoff_offset [m]
%     structure     - structure geometry, 1x1 struct; reads
%                     crest_elevation, toe_elevation [m, study datum,
%                     positive up], crest_width [m], seaside_slope,
%                     leeside_slope (cot) [-], armor_delta [-],
%                     seaside_mass, leeside_mass [kg], cem_P [-],
%                     seaside_design_S, leeside_design_S (service limits)
%                     and seaside_S_uls, leeside_S_uls (ultimate limits)
%                     [-]
%     emp_coeff     - armor damage coefficients
%                     (load_empirical_coefficients), struct; reads km1,
%                     km2, k_si, k_sp, k_ls1, k_ls2
%     LC_SimOUT_hyd - life cycles of one storm type, nLC x 1 cell of
%                     Timeseries matrices (nRows x 12, lcs_columns; reads
%                     year, SWL, Hm0_toe, Tp, dt [days] and step)
%   Outputs:
%     CSR_Timeseries_DPA - damage progression results, struct with fields
%                          (in this order):
%       S_seaside_no_repairs, S_leeside_no_repairs - accumulated damage per
%           row [-], nLC x 1 cell of nRows x 1
%       S_seaside_with_repairs, S_leeside_with_repairs - same with repairs
%           (NaN over the rest of a storm that triggered a repair)
%       Seaside_Repair_Indexes, Leeside_Repair_Indexes - one row per life
%           cycle with repairs: {rows where the limit was exceeded, life
%           cycle index}, cell ({} without repairs)
%       stats - final damage (last row of each life cycle, no repairs):
%           mean and 10/16/84/90th percentiles, table (p, Smean, Sp,
%           LSmean, LSp)
%       Repairs_Stats - repairs on only: total, mean and 10/16/84/90th
%           percentiles of the repair counts, seaside and leeside, table
%       seaside_repair_count, leeside_repair_count - repairs off only:
%           life cycles whose no-repairs damage reaches the ultimate limit
%       Reliability_Seaside, Reliability_Leeside - 1 - (life cycles with a
%           repair, or reaching the ultimate limit without repairs)/nLC
%       Smax, LSmax - seaside and leeside yearly mean of the storm-maximum
%           damage (no repairs), (mcs_nYears + 1) x 1, row 1 = year 0
%       LSPcurves, SPcurves - leeside and seaside 10/16/84/90th
%           percentiles, (mcs_nYears + 1) x 4
%       diagnostics - per-row forcing and damage, 1 x nLC cell of tables
%           (WL, Hm0_toe, Tp, h, Nz, Rc, z1p, u1p, Szero_no_repairs,
%           Ssea_no_repairs, Szero_with_repairs, Ssea_with_repairs,
%           SLee_no_repairs, SLee_with_repairs)
%
%   Tier: internal
%
%   See also chess_csr, seaside_armor_stone_damage,
%   leeside_armor_stone_damage, z1p_calc, u1p_calc,
%   compute_lcs_yearly_curve, load_empirical_coefficients, lcs_columns.
%
%   Developed by: Jeffrey A. Melby, PhD; Norberto Nadal-Caraballo, PhD;
%   Victor M. Gonzalez, PE

% LICENSING:
%     This code is part of CHESS software suite developed by the U.S. Army
%     Engineer Research and Development Center Coastal and Hydraulics Laboratory
%     (hereinafter “ERDC-CHL”). This material is distributed in accordance with DoD
%     Instruction 5230.24. Recipient agrees to abide by all notices, and distribution
%     and license markings. The controlling DOD office is the U.S. Army Engineer
%     Research and Development Center (hereinafter, "ERDC"). This material shall be
%     handled and maintained in accordance with For Official Use Only, Export Control,
%     and AR 380-19 requirements. ERDC-CHL retains all right, title and interest in
%     CHESS and any portion thereof and in all copies, modifications and derivative
%     works of CHESS and any portions thereof including, without limitation, all
%     rights to patent, copyright, trade secret, trademark and other proprietary or
%     intellectual property rights. Recipient has no rights, by license or otherwise, to
%     use, disclose or disseminate CHESS, in whole or in part.
%
% DISCLAIMER:
%     CHESS IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
%     ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
%     TO CHESS OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
%     OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
%     MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
%     CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
%     USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
%     WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN CHESS, AND
%     DISTRIBUTES IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
%     UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
%     HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
%     LIABILITIES, DEMANDS, DAMAGES.
%
% SCRIPT NAME:
%     CSR_timeseries_DLL3.m.
%
% MODIFICATIONS:
%     |   DATE (mm/dd/yyyy)   |      EDITOR      |         SUMMARY               |
%     |-----------------------|------------------|-------------------------------|
%     |      06/05/2020       |   Fabian Garcia  |  Code optimization,clean-up,  |
%     |                       |                  |  and incorporation onto       |
%     |                       |                  |  streamlined workflow.        |
%     |-----------------------|------------------|-------------------------------|
%
% RELEVANT PUBLICATIONS:
%     Source Material:
%         (01) Melby, J. A. 1999. Damage Progression on Breakwaters. Dissertation in partial fulfillment of PhD.
%                 Newark, Delaware: University of Delaware.
%         (02) Melby, J. A. 2009. “Time-Dependent Life-Cycle Analysis of Coastal Structures.
%                 ”Proceedings of Coastal Structures 2007, 1842–1853. Singapore: World Scientific.
%         (03) Melby, J. A., and S. A. Hughes. 2004. “Armor Stability Based on Wave Momentum Flux.
%                 ”Proceedings of Coastal Structures 2003, 53–65. Reston, VA: ASCE.
%         (04) Melby, J. A., and N. K. Kobayashi. 2011. “Stone Armor Damage Initiation and Progression.
%                 Journal of Coastal Research 27(1): 110–119.
%         (05) Van Gent, M. R. A., and B. Pozueta. 2005. “Rear-Side Stability of Rubble Mound Structures.
%                 ”Coastal Engineering 2004, 3481–93. World Scientific Publishing Company.
%     Application Of Methodology:
%         (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
%                 structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
%                 and Development Center.

%% PRINT PROGRESS HEADER
disp(['   Running CHESS: Coastal Structure Reliability - Damage Progression Analysis....']);
fprintf(1,'      Completion Progress: %3d%%\n',0);

%% DEFINE CONSTANTS AND GRAB INPUTS
settings = read_damage_progression_settings(config, structure, emp_coeff);
% Determine Number Of Life Cycles
nLC = length(LC_SimOUT_hyd);
% Determine Number Of Timesteps Per Life Cycle
nTimes_per_LC = cellfun(@(x) length(x(:,1)),LC_SimOUT_hyd);

%% ADJUST AND COMPUTE FORCING PARAMETERS
forcing = life_cycle_forcing(LC_SimOUT_hyd, settings);

%% INITIALIZE DAMAGE VARIABLES
damage = initialize_damage_series(nTimes_per_LC);
% Repair Indexes Storage Variables
Seaside_Repair_Indexes = {};
Leeside_Repair_Indexes =  {};

%% BEGIN LC LOOP
for life_cycle_index = 1:nLC
    % Simulate Damage Progression Over The Life Cycle Timesteps
    [damage_lc, forcing_lc, repair_seaside, repair_leeside] = simulate_life_cycle_damage(...
        life_cycle_slice(forcing, life_cycle_index), life_cycle_slice(damage, life_cycle_index), settings);
    % Store Life Cycle Results (Run-up And u1% Are Updated During The Simulation)
    damage = store_life_cycle_slice(damage, damage_lc, life_cycle_index);
    forcing.z1p{life_cycle_index} = forcing_lc.z1p;
    forcing.u1p{life_cycle_index} = forcing_lc.u1p;

    %% APPEND REPAIR INDEXES
    % Store Repair Indexes (If Any)
    if ~isempty(repair_leeside)
        Leeside_Repair_Indexes = [Leeside_Repair_Indexes;[{repair_leeside}, {life_cycle_index}]];
    end
    % Store Repair Indexes (If Any)
    if ~isempty(repair_seaside)
        Seaside_Repair_Indexes = [Seaside_Repair_Indexes;[{repair_seaside}, {life_cycle_index}]];
    end
    fprintf(1,'\b\b\b\b%3.0f%%',(100*(life_cycle_index/nLC)));
end  % NLS
disp([newline '      Computing Post Damage Statistics....']);

%% POST DAMAGE STATISTICS
statistics = final_damage_statistics(LC_SimOUT_hyd, damage, settings.nYears);
diagnostics = diagnostics_tables(forcing, damage, nLC);
repairs = repair_statistics(settings, damage, Seaside_Repair_Indexes, Leeside_Repair_Indexes);
reliability = structure_reliability(settings.repair_switch, repairs, Seaside_Repair_Indexes, Leeside_Repair_Indexes, nLC);

%% GENERATE OUTPUTS DATA STRUCTURE
CSR_Timeseries_DPA = damage_progression_output(settings.repair_switch, damage, Seaside_Repair_Indexes,...
    Leeside_Repair_Indexes, statistics, repairs, reliability, diagnostics);
end

%% AUX FUNCTION: READ CONSTANTS, LIMIT STATES, SWITCHES, STRUCTURE PARAMETERS AND EMPIRICAL COEFFICIENTS
function settings = read_damage_progression_settings(config, structure, emp_coeff)
%% DEFINE CONSTANTS
% Gravitational acceleration (m/s^2)
settings.grav = config.gravity_constant;
% Limits Damage Accumulation To Increments Of Roughly S>.8
settings.Szerolim = 0.2;
% Define Number of Years
settings.nYears = config.mcs_nYears;
% Grab Submergance Switch
% Intentionally fixed at 0 (the config switch csr_compute_S_submerged was retired)
settings.compute_S_submerged = 0;
%% GRAB INPUTS FROM "config"
% ---------- PROJECT DETAILS ----------
% Water density (kg/m^3)
dw = config.water_density;
% Seaside Damage Ultimate Limit State (ULS)
settings.seaside_S_ULS = structure.seaside_S_uls;
% Leeside Damage Ultimate Limit State (ULS)
settings.leeside_S_ULS = structure.leeside_S_uls;
% Seaside Damage Serviceability Limit State (SLS)
settings.seaside_S_SLS = structure.seaside_design_S;%e.g. S=7, just before exposure of underlayer
% Leeside Damage Serviceability Limit State (SLS)
settings.leeside_S_SLS = structure.leeside_design_S; %e.g. S=7, just before exposure of underlayer
% ---------- LOGICAL SWITCHES ----------
% Structure Repair Assesment; 0 - No Repairs, 1 - Repair Above SLS, 2 - Repair Above ULS, 3 - Repair Above SLS Or ULS
settings.repair_switch = config.csr_apply_structure_repair;
% Cutoff Elevation Adjustment Flag;
% 0 - Seaside Damage is computed even if the structure is submerged
% 1 - Water Level Is Compared With Crest Height + Cutoff Elevation Delta To Determine Structure Submergence
settings.cutoff_switch = config.csr_apply_cutoff_correction;
% Cutoff Elevation Delta [m]
settings.cutoff_delta = config.csr_cutoff_offset;

%% GRAB INPUTS FROM "structure"
% Extract Strcutural Paramaters From Structure
settings.crest_elevation = structure.crest_elevation;
settings.crest_width = structure.crest_width;
settings.toe_elevation = structure.toe_elevation;
settings.seaside_slope = structure.seaside_slope;
settings.leeside_slope = structure.leeside_slope;
settings.armor_delta = structure.armor_delta;
seaside_mass = structure.seaside_mass;
leeside_mass = structure.leeside_mass;
settings.cem_P = structure.cem_P;
% Armor Stone Specific Gravity
settings.SG = 1 + settings.armor_delta;
% Armor Stone Density [kg/m^3]
dr = settings.SG*dw;
% Seaside Median Volume of Armor Stone
V_ss = seaside_mass/dr;
% Seaside Nominal Stone Diameter (m)
settings.SDn = V_ss^(1/3);
%Leeside Median Volume of Armor Stone
LV_ss = leeside_mass/dr;
% Leeside Nominal Stone Diameter (m)
settings.LDn = LV_ss^(1/3);

%% EMPIRICAL COEFFICIENTS
% Need to define wqhat K_ss is
settings.Km1 = emp_coeff.km1; % Seaside Damage Coeff
settings.Km2 = emp_coeff.km2; % Seaside Damage Coeff
settings.Ksi = emp_coeff.k_si;
settings.Ksp = emp_coeff.k_sp;
settings.K_ls1 = emp_coeff.k_ls1; % Leeside Damage Coeff
settings.K_ls2 = emp_coeff.k_ls2; % Leeside Damage Coeff
end

%% AUX FUNCTION: FORCING PER LIFE CYCLE (ONE CELL PER LIFE CYCLE) AND INITIAL STRUCTURE RESPONSES
function forcing = life_cycle_forcing(LC_SimOUT_hyd, settings)
crest_elevation = settings.crest_elevation;
toe_elevation = settings.toe_elevation;
seaside_slope = settings.seaside_slope;
crest_width = settings.crest_width;
grav = settings.grav;
% Life-Cycle Column Map
C = lcs_columns();
% Extract Water Level
forcing.WL = cellfun(@(x) x(:, C.SWL),LC_SimOUT_hyd,'un',false);
% Compute Water Column
forcing.h = cellfun(@(x) x-toe_elevation,forcing.WL,'un',false);
% Compute Freeboard
forcing.Rc = cellfun(@(x,y) crest_elevation - x,forcing.WL,'un',false);
% Extract Wave Height (At The Toe)
forcing.Hm0 = cellfun(@(x) x(:, C.Hm0_toe),LC_SimOUT_hyd,'un',false);
% Extract Wave Peak Period
forcing.Tp = cellfun(@(x) x(:, C.Tp),LC_SimOUT_hyd,'un',false);
% Spectral Wave Period (Tm_-1,0)
forcing.Tm10 = cellfun(@(x) x(:, C.Tp)/1.1,LC_SimOUT_hyd,'un',false);
% Mean wave period (sec)
forcing.Tm = cellfun(@(x) x./1.2,forcing.Tp,'un',false);
% Storm increment duration (hr)
forcing.Dstm = cellfun(@(x) x(:, C.dt).*24,LC_SimOUT_hyd,'un',false);
% Number of waves per increment
forcing.Nz = cellfun(@(x,y) (x.*3600)./y,forcing.Dstm,forcing.Tm,'un',false);
% Storm Timestep Counter (0 At The First Row Of Each Storm)
forcing.step = cellfun(@(x) x(:, C.step),LC_SimOUT_hyd,'un',false);

%% COMPUTE INITIAL STRUCTURE RESPONSES (runup & runup_vel)
% Compute Run-up
forcing.z1p = cellfun(@(w,x,y) z1p_calc(w,x,y,seaside_slope,grav),forcing.Hm0,forcing.Tm10,forcing.Rc,'un',false);
% Compute u1%
forcing.u1p = cellfun(@(v,w,x,y) u1p_calc(crest_width,v,w,x,y,seaside_slope,grav),forcing.Rc,forcing.z1p,forcing.Tm10,forcing.Hm0,'un',false);
end

%% AUX FUNCTION: ZERO DAMAGE SERIES (ONE CELL PER LIFE CYCLE)
function damage = initialize_damage_series(nTimes_per_LC)
damage.Szero_no_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
damage.seaside_no_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
damage.Szero_with_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
damage.seaside_with_repairs = cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
damage.leeside_with_repairs =  cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
damage.leeside_no_repairs =  cellfun(@(x) zeros(x,1),num2cell(nTimes_per_LC),'un',false);
end

%% AUX FUNCTION: ONE LIFE CYCLE OF A STRUCT OF PER LIFE CYCLE CELLS
function slice = life_cycle_slice(series, life_cycle_index)
slice = structfun(@(x) x{life_cycle_index}, series, 'UniformOutput', false);
end

%% AUX FUNCTION: STORE ONE LIFE CYCLE BACK INTO A STRUCT OF PER LIFE CYCLE CELLS
function series = store_life_cycle_slice(series, slice, life_cycle_index)
names = fieldnames(slice);
for k = 1:numel(names)
    series.(names{k}){life_cycle_index} = slice.(names{k});
end
end

%% AUX FUNCTION: DAMAGE PROGRESSION OVER THE TIMESTEPS OF ONE LIFE CYCLE
function [damage_lc, forcing_lc, repair_seaside, repair_leeside] = simulate_life_cycle_damage(forcing_lc, damage_lc, settings)
%% SEASIDE DAMAGE PROGRESSION - WITH REPAIRS
[damage_lc.seaside_with_repairs, damage_lc.Szero_with_repairs, repair_seaside] = seaside_damage_with_repairs_series(forcing_lc, settings);

%% SEASIDE DAMAGE PROGRESSION - NO REPAIRS
[damage_lc.seaside_no_repairs, damage_lc.Szero_no_repairs] = seaside_damage_no_repairs_series(forcing_lc, settings);

%% LEESIDE DAMAGE PROGRESSION - WITH AND WITHOUT REPAIRS
% Verify Run-up (Forcing Only; The Damage Series Do Not Read z1p)
forcing_lc.z1p(forcing_lc.Hm0<0.1 | forcing_lc.Tp<0 | forcing_lc.Rc<0) = 0;
[damage_lc.leeside_with_repairs, damage_lc.leeside_no_repairs, forcing_lc.u1p, repair_leeside] = leeside_damage_series(forcing_lc, settings);
end

%% AUX FUNCTION: SEASIDE DAMAGE (WITH REPAIRS) OVER THE TIMESTEPS OF ONE LIFE CYCLE
function [seaside_damage, Szero, repair_seaside] = seaside_damage_with_repairs_series(forcing_lc, settings)
n_steps = numel(forcing_lc.step);
seaside_damage = zeros(n_steps,1);
Szero = zeros(n_steps,1);
% Previous State
seaside_with_repairs_last = 0;
storm_end_seaside = 0;
repair_seaside = [];
first_damaging_storm_with_repairs = 0; % logical indicating first storm has not been triggered yet
has_damage_with_repairs = 0; %logical indicating damage with repairs is zero
for time_step = 1:n_steps
    % Verify Damage State (Define Ks, dS)
    [Ks_with_repairs, dS_with_repairs, first_damaging_storm_with_repairs] = damage_coefficients_for_state(has_damage_with_repairs,...
        first_damaging_storm_with_repairs, forcing_lc.step, time_step, settings.Ksi, settings.Ksp);
    % Determine Repair Conditions
    repair_sea_now = repair_condition(settings.repair_switch, settings.seaside_S_SLS, settings.seaside_S_ULS, seaside_with_repairs_last);
    % Verify For Breaching Condition
    if repair_sea_now && settings.repair_switch > 0
        % Store Breaching Timestep (Row ID)
        if storm_end_seaside == 0
            % Update Storm End Row
            storm_end_seaside = find_storm_end(forcing_lc.step, time_step);
            % Store Row Index Where Breaching Occoured
            repair_seaside = [repair_seaside;time_step-1]; %#ok<AGROW>
        end
        % Set Damage Values To NaN
        Szero(time_step) = NaN(1,1); % Szero
        seaside_damage(time_step) = NaN(1,1); % seaside damage
        % Verify If Reached End Of Breaching Storm
        if time_step == storm_end_seaside
            % Reset Seaside Damages
            seaside_with_repairs_last = 0;
            storm_end_seaside = 0;
            has_damage_with_repairs = 0; % Reset Damage Flag
        end
    else
        % Compute Seaside Armor Stone Damage Accumulation (S)
        [seaside_damage_value, Szero_value] = ...
            seaside_armor_stone_damage(forcing_lc.h(time_step), seaside_with_repairs_last,...
            forcing_lc.Hm0(time_step), forcing_lc.Tm(time_step), settings.crest_elevation, settings.seaside_slope,...
            settings.SDn, settings.SG, settings.grav, settings.cem_P, forcing_lc.Nz(time_step), forcing_lc.Rc(time_step),...
            settings.Szerolim, settings.cutoff_delta, forcing_lc.WL(time_step), settings.cutoff_switch,...
            settings.Km1, settings.Km2, Ks_with_repairs, dS_with_repairs, settings.compute_S_submerged);
        seaside_damage(time_step) = seaside_damage_value;
        Szero(time_step) = Szero_value;
        % Check For Initial Damage (Before The t-1 Update, As In The No-Repairs Series)
        if seaside_with_repairs_last == 0 && seaside_damage_value > 0
            has_damage_with_repairs  = 1; % have damage
            first_damaging_storm_with_repairs = 1; % logical indicating first storm has been triggered
        end
        % Store t-1 Damage State
        seaside_with_repairs_last = seaside_damage_value;
    end
end
end

%% AUX FUNCTION: SEASIDE DAMAGE (NO REPAIRS) OVER THE TIMESTEPS OF ONE LIFE CYCLE
function [seaside_damage, Szero] = seaside_damage_no_repairs_series(forcing_lc, settings)
n_steps = numel(forcing_lc.step);
seaside_damage = zeros(n_steps,1);
Szero = zeros(n_steps,1);
% Previous State
seaside_no_repairs_last = 0;
first_damaging_storm_no_repairs = 0; % logical indicating first storm has not been triggered yet
has_damage_no_repairs = 0; %logical indicating damage no repairs is zero
for time_step = 1:n_steps
    % Verify Damage State (Define Ks, dS)
    [Ks_no_repairs, dS_no_repairs, first_damaging_storm_no_repairs] = damage_coefficients_for_state(has_damage_no_repairs,...
        first_damaging_storm_no_repairs, forcing_lc.step, time_step, settings.Ksi, settings.Ksp);
    % Compute Seaside Armor Stone Damage Accumulation (S)
    [seaside_damage_value, Szero_value] = ...
        seaside_armor_stone_damage(forcing_lc.h(time_step), seaside_no_repairs_last,...
        forcing_lc.Hm0(time_step), forcing_lc.Tm(time_step), settings.crest_elevation, settings.seaside_slope,...
        settings.SDn, settings.SG, settings.grav, settings.cem_P, forcing_lc.Nz(time_step), forcing_lc.Rc(time_step),...
        settings.Szerolim, settings.cutoff_delta, forcing_lc.WL(time_step), settings.cutoff_switch,...
        settings.Km1, settings.Km2, Ks_no_repairs, dS_no_repairs, settings.compute_S_submerged);
    seaside_damage(time_step) = seaside_damage_value;
    Szero(time_step) = Szero_value;
    % Check For Initial Damage
    if seaside_no_repairs_last == 0 && seaside_damage_value > 0
        has_damage_no_repairs  = 1; % have damage
        first_damaging_storm_no_repairs = 1; % logical indicating first storm has been triggered
    end
    % Store t-1 Damage State
    seaside_no_repairs_last = seaside_damage_value;
end
end

%% AUX FUNCTION: LEESIDE DAMAGE (WITH AND WITHOUT REPAIRS) OVER THE TIMESTEPS OF ONE LIFE CYCLE
% Both Tracks Use The u1% Of The No-Repairs Track At t-1, So They Share One Loop (With Repairs First);
% The Returned u1p Is The No-Repairs One (It Always Overwrote The With-Repairs u1p)
function [leeside_with_repairs, leeside_no_repairs, u1p, repair_leeside] = leeside_damage_series(forcing_lc, settings)
n_steps = numel(forcing_lc.step);
leeside_with_repairs = zeros(n_steps,1);
leeside_no_repairs = zeros(n_steps,1);
u1p = forcing_lc.u1p;
% Previous State
leeside_with_repairs_last = 0;
leeside_no_repairs_last = 0;
u1p_last = 0;
storm_end_leeside = 0;
repair_leeside = [];
for time_step = 1:n_steps
    %% WITH REPAIRS
    % Determine Repair Conditions
    repair_lee_now = repair_condition(settings.repair_switch, settings.leeside_S_SLS, settings.leeside_S_ULS, leeside_with_repairs_last);
    % Verify For Breaching Condition
    if repair_lee_now && settings.repair_switch > 0 % Breach
        % Store Breaching Timestep (Row ID)
        if storm_end_leeside == 0
            % Update Storm End Row
            storm_end_leeside = find_storm_end(forcing_lc.step, time_step);
            % Store Row Index Where Breaching Occoured
            repair_leeside = [repair_leeside;time_step-1]; %#ok<AGROW>
        end
        % Set Damage Value To NaN
        leeside_with_repairs(time_step) = NaN(1,1);
        % Verify If Reached End Of Breaching Storm
        if time_step == storm_end_leeside
            % Reset Leeside Damages
            leeside_with_repairs_last = 0;
            storm_end_leeside = 0;
        end
    else
        % Compute Incremental Leeside Damage
        leeside_damage_value = ...
            leeside_armor_stone_damage(leeside_with_repairs_last,...
            forcing_lc.Hm0(time_step), forcing_lc.Tm10(time_step), u1p_last, settings.LDn,...
            settings.leeside_slope, settings.seaside_slope, forcing_lc.WL(time_step), forcing_lc.Rc(time_step), forcing_lc.Nz(time_step), ...
            settings.armor_delta, settings.K_ls1, settings.K_ls2, settings.crest_width, settings.crest_elevation,...
            settings.grav, settings.compute_S_submerged, settings.cutoff_switch, settings.cutoff_delta);
        leeside_with_repairs(time_step) = leeside_damage_value;
        % Store t-1 Damage State
        leeside_with_repairs_last = leeside_damage_value;
    end

    %% NO REPAIRS
    % Compute Incremental Leeside Damage
    [leeside_damage_value, u1p_value] = leeside_armor_stone_damage(leeside_no_repairs_last,...
        forcing_lc.Hm0(time_step), forcing_lc.Tm10(time_step), u1p_last, settings.LDn,...
        settings.leeside_slope, settings.seaside_slope, forcing_lc.WL(time_step), forcing_lc.Rc(time_step), forcing_lc.Nz(time_step),...
        settings.armor_delta, settings.K_ls1, settings.K_ls2, settings.crest_width, settings.crest_elevation,...
        settings.grav, settings.compute_S_submerged, settings.cutoff_switch, settings.cutoff_delta);
    leeside_no_repairs(time_step) = leeside_damage_value;
    u1p(time_step) = u1p_value;
    % Store t-1 Damage State
    u1p_last = u1p_value;
    leeside_no_repairs_last = leeside_damage_value;
end
end

%% AUX FUNCTION: FINAL DAMAGE PERCENTILES AND YEARLY MEAN MAXIMUM DAMAGE CURVES
function statistics = final_damage_statistics(LC_SimOUT_hyd, damage, nYears)
%% STORE LAST COMPUTED DAMAGE FOR EACH LC
% This will turn into a mean sigular value once percentiles are computed
% Seaside
% (Life Cycles Without Storms Keep The Initial Damage, 0)
S_final = lc_values(damage.seaside_no_repairs, @(x) x(end));
LS_final = lc_values(damage.leeside_no_repairs, @(x) x(end));

%% COMPUTE MEAN DAMAGE CURVE
[LSmax,LSPcurves,~] = compute_lcs_yearly_curve(LC_SimOUT_hyd, damage.leeside_no_repairs, nYears);
[Smax,SPcurves,~] = compute_lcs_yearly_curve(LC_SimOUT_hyd, damage.seaside_no_repairs, nYears);
% Fill values for year 0
Smax = [0;Smax];
LSmax = [0;LSmax];
SPcurves = [zeros(size(SPcurves(1,:)));SPcurves];
LSPcurves = [zeros(size(SPcurves(1,:)));LSPcurves];

%% COMPUTE STATISTICS - TABLE
% Define Percentiles
p = [10 16 84 90]';
% Compute Percentiles
Sp = prctile(S_final,[10 16 84 90])';
LSp = prctile(LS_final,[10 16 84 90])';
% Compute Mean Accumulated Damage For Bin
Smean = repmat(mean(S_final,'omitnan'),size(p));
LSmean = repmat(mean(LS_final,'omitnan'),size(p));
% Build Stats Table
statistics.stats = table(p,Smean,Sp,LSmean,LSp);
statistics.Smax = Smax;
statistics.LSmax = LSmax;
statistics.SPcurves = SPcurves;
statistics.LSPcurves = LSPcurves;
end

%% AUX FUNCTION: DIAGNOSTICS STRUCTURE (ONE TABLE PER LIFE CYCLE)
function diagnostics = diagnostics_tables(forcing, damage, nLC)
WL = forcing.WL; Hm0 = forcing.Hm0; Tp = forcing.Tp; h = forcing.h; Nz = forcing.Nz; Rc = forcing.Rc;
z1p = forcing.z1p; u1p = forcing.u1p;
Szero_no_repairs = damage.Szero_no_repairs; seaside_no_repairs = damage.seaside_no_repairs;
Szero_with_repairs = damage.Szero_with_repairs; seaside_with_repairs = damage.seaside_with_repairs;
leeside_no_repairs = damage.leeside_no_repairs; leeside_with_repairs = damage.leeside_with_repairs;
diagnostics(1,:) = cellfun(@(a) table(WL{a},Hm0{a},...
    Tp{a},h{a},Nz{a},Rc{a},z1p{a},u1p{a},Szero_no_repairs{a},seaside_no_repairs{a},Szero_with_repairs{a},...
    seaside_with_repairs{a}, leeside_no_repairs{a}, leeside_with_repairs{a}, 'VariableNames',...
    {'WL','Hm0_toe','Tp','h','Nz','Rc','z1p','u1p',...
    'Szero_no_repairs','Ssea_no_repairs','Szero_with_repairs','Ssea_with_repairs',...
    'SLee_no_repairs','SLee_with_repairs'}),...
    num2cell(1:nLC),'un',false)';
end

%% AUX FUNCTION: AMOUNT OF REPAIRS (REPAIRS ON) OR LIFE CYCLES REACHING THE ULS (REPAIRS OFF)
function repairs = repair_statistics(settings, damage, Seaside_Repair_Indexes, Leeside_Repair_Indexes)
if settings.repair_switch > 0
    % Seaside N Repairs
    if ~isempty(Seaside_Repair_Indexes)
        sea_repairs = cellfun(@(x) length(x), Seaside_Repair_Indexes(:, 1),'UniformOutput',true);
    else
        sea_repairs = 0;
    end
    % Leeside N Repairs
    if ~isempty(Leeside_Repair_Indexes)
        lee_repairs = cellfun(@(x) length(x), Leeside_Repair_Indexes(:, 1),'UniformOutput',true);
    else
        lee_repairs = 0;
    end
    % Compute Seaside Mean Repairs
    sea_repairs_mean = mean(sea_repairs);
    % Compute Leeside Mean Repairs
    lee_repairs_mean = mean(lee_repairs);
    % Compute Seaside Repairs Percentiles
    sea_repairs_percentiles = prctile(sea_repairs,[10 16 84 90]);
    % Compute Leeside Repairs Percentiles
    lee_repairs_percentiles = prctile(lee_repairs,[10 16 84 90]);
    % Build Table
    repairs.Repairs_Stats = table(sum(sea_repairs),sea_repairs_mean,sea_repairs_percentiles(1),sea_repairs_percentiles(2),...
        sea_repairs_percentiles(3),sea_repairs_percentiles(4),sum(lee_repairs),lee_repairs_mean,...
        lee_repairs_percentiles(1),lee_repairs_percentiles(2),lee_repairs_percentiles(3),...
        lee_repairs_percentiles(4),'VariableNames',{'Total_Seaside_Repairs','Mean_Seaside_Repairs',...
        'Seaside_Repair_10_Percentile','Seaside_Repair_16_Percentile','Seaside_Repair_84_Percentile',...
        'Seaside_Repair_90_Percentile','Total_Leeside_Repairs','Mean_Leeside_Repairs',...
        'Leeside_Repair_10_Percentile','Leeside_Repair_16_Percentile','Leeside_Repair_84_Percentile',...
        'Leeside_Repair_90_Percentile'});
else
    % Seaside N Repairs
    sea_repairs = sum(lc_values(damage.seaside_no_repairs, @max)>=settings.seaside_S_ULS);
    % Leeside N Repairs
    lee_repairs = sum(lc_values(damage.leeside_no_repairs, @max)>=settings.leeside_S_ULS);
end
repairs.sea_repairs = sea_repairs;
repairs.lee_repairs = lee_repairs;
end

%% AUX FUNCTION: SEASIDE AND LEESIDE RELIABILITY
function reliability = structure_reliability(repair_switch, repairs, Seaside_Repair_Indexes, Leeside_Repair_Indexes, nLC)
if repair_switch > 0
    % One Repair_Indexes Row Per Life Cycle With At Least One Repair (sea_repairs/lee_repairs Are 0 When None Was Needed)
    % Seaside Reliability
    reliability.Seaside = 1 - size(Seaside_Repair_Indexes, 1)/nLC;
    % Leeside Reliability
    reliability.Leeside = 1 - size(Leeside_Repair_Indexes, 1)/nLC;
else
    % Seaside Reliability
    reliability.Seaside = 1 - repairs.sea_repairs/nLC;
    % Leeside Reliability
    reliability.Leeside = 1 - repairs.lee_repairs/nLC;
end
end

%% AUX FUNCTION: OUTPUT DATA STRUCTURE (FIELD ORDER IS PART OF THE OUTPUT)
function CSR_Timeseries_DPA = damage_progression_output(repair_switch, damage, Seaside_Repair_Indexes,...
    Leeside_Repair_Indexes, statistics, repairs, reliability, diagnostics)
% Damage with no breaching
CSR_Timeseries_DPA.S_seaside_no_repairs = damage.seaside_no_repairs;
CSR_Timeseries_DPA.S_leeside_no_repairs = damage.leeside_no_repairs;
% Damage with breaching
CSR_Timeseries_DPA.S_seaside_with_repairs = damage.seaside_with_repairs;
CSR_Timeseries_DPA.S_leeside_with_repairs = damage.leeside_with_repairs;
% Stores Timestep Where Breaching Occoured For Each Strom At Each LC
CSR_Timeseries_DPA.Seaside_Repair_Indexes = Seaside_Repair_Indexes;
CSR_Timeseries_DPA.Leeside_Repair_Indexes = Leeside_Repair_Indexes;
% Mean & Percentiles For THe Final Accumulated Damage Of All LC's
CSR_Timeseries_DPA.stats = statistics.stats;
% Repairs Stats
if repair_switch > 0
    CSR_Timeseries_DPA.Repairs_Stats = repairs.Repairs_Stats;
else
    CSR_Timeseries_DPA.seaside_repair_count = repairs.sea_repairs;
    CSR_Timeseries_DPA.leeside_repair_count = repairs.lee_repairs;
end
% Overall Structure Seaside Reliability
CSR_Timeseries_DPA.Reliability_Seaside = reliability.Seaside;
% Overall Structure Seaside Reliability
CSR_Timeseries_DPA.Reliability_Leeside = reliability.Leeside;
% Yearly Mean Maximum Cumulative Damages
CSR_Timeseries_DPA.Smax = statistics.Smax;
CSR_Timeseries_DPA.LSmax = statistics.LSmax;
% Yearly Mean Maximum Cumulative Damages Percentiles
CSR_Timeseries_DPA.LSPcurves = statistics.LSPcurves;
CSR_Timeseries_DPA.SPcurves = statistics.SPcurves;
% Diagnostics Data Structure
CSR_Timeseries_DPA.diagnostics = diagnostics;
end

%% AUX FUNCTION: ONE VALUE PER LIFE CYCLE (fun(x)); LIFE CYCLES WITHOUT STORMS KEEP THE INITIAL DAMAGE (0)
function v = lc_values(S, fun)
v = zeros(size(S));
has_storms = ~cellfun(@isempty, S);
v(has_storms) = cellfun(fun, S(has_storms));
end

%% AUX FUNCTION: DETERMINE STORM END ROW
function  storm_end_row = find_storm_end(step_column, time_step)
storm_tstps = step_column(time_step:end); % 0:73 or 0:96 repeated for 70ish storms except missing first time_step values
% Find Row Index Of 1st TimeStep of Storms In LC
storm_end_row = find(storm_tstps==0);
% Find End Row Of present Storm
if isempty(storm_end_row)==0 % if true, then all storms but last storm
    storm_end_row = time_step+storm_end_row(1)-2; % all storms but last storm
else
    storm_end_row = time_step+length(storm_tstps)-1; % last storm because no zeros
end
end

%% AUX FUNCTION: DETERMINE CORRESPONDING Ks & dS
function [Ks, dS, on_first_storm] = damage_coefficients_for_state(got_damage, on_first_storm, step_column, time_step, Ksi, Ksp)
if got_damage && on_first_storm % have damage and it is still the first damaging storm
    % set coefficient Ks to Ksi (first storm damage) or Ksp (progressive damage)
    % Note that there is one for "with_repairs" and one for "no_repairs"
    storm_end_row = find_storm_end(step_column, time_step);
    if time_step<storm_end_row
        Ks = Ksi;
        dS = 0.5;
        on_first_storm = 1; % logical indicating first storm has not been triggered yet
    else
        Ks = Ksp;
        dS = 0;
        on_first_storm = 0;
    end
elseif got_damage
    Ks = Ksp;
    dS = 0;
else
    Ks = Ksi;
    dS = 0.5;
end
end

%% AUX FUNCTION: DETERMINE REPAIR CONDITION
function repair_flag = repair_condition(repair_switch, SLS, ULS, S_last)
% Determine Repair Conditions
switch repair_switch
    case 1 % Include Service Limit State Repairs (SLS)
        if S_last>SLS
            repair_flag = true;
        else
            repair_flag = false;
        end
    case 2 % Repair for Ultimate Limit State (ULS)
        if S_last>ULS
            repair_flag = true;
        else
            repair_flag = false;
        end
    case 3 % Repair for Service & Ultimate Limit State
        if S_last>ULS || S_last>SLS
            repair_flag = true;
        else
            repair_flag = false;
        end
    case 0  % No Repairs
        repair_flag = false;
    otherwise
        error(['Error: Please specify supported repair scenario: ' newline ...
            '0 - Repairs Not Included In Analysis' newline ...
            '1 - SLS Repairs Are Included In Analysis' newline ...
            '2 - repairs for ULS only' newline ...
            '3 - repairs for both ULS and SLS']);
end
end

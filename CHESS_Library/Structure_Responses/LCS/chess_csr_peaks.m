function [PF_Summary,Reliab_Summary] = chess_csr_peaks(config, structure, emp_coeff, LC_MCSimOUT)
% chess_csr_peaks  Rubble mound armor reliability from LCS Peaks storms.
%   [PF_Summary, Reliab_Summary] = chess_csr_peaks(config, structure,
%       emp_coeff, LC_MCSimOUT)
%
%   Reliability and probability of failure of the seaside and leeside
%   armor of a rubble mound for the storms sampled in every life cycle
%   (Peaks: one row per storm). For every storm:
%     seaside limit state G_ss = R_ss - F_ss (Melby and Kobayashi 2011,
%       momentum flux; damage level seaside_design_S, coefficients km1
%       and k_si);
%     leeside limit state G_ls = R_ls - F_ls (Van Gent and Pozueta 2004,
%       Melby 2009, r = 6; damage level leeside_design_S, coefficients
%       k_ls1 and k_ls2);
%     overall G = min(G_ss, G_ls).
%   Forcing: SWL, Hm0_toe, Tp (Tm = Tp/1.2, T_m-1,0 = Tp/1.1), h = SWL -
%   toe elevation (0.01 when negative) and the number of waves Nz =
%   storm_duration/Tm. Stone sizes: Dn = (mass/((1 + armor_delta)*
%   water_density))^(1/3).
%   The reliability of a life cycle is 1 - (storms with G < 0)/(storms in
%   the life cycle), 1 for a life cycle without storms; the probability of
%   failure is 1 - reliability.
%
%   Inputs:
%     config      - CHESS configuration, 1x1 struct; reads water_density
%                   [kg/m^3], gravity_constant [m/s^2] and project_CLs
%                   (percentiles, char, e.g. '[84 90]')
%     structure   - structure geometry, 1x1 struct; reads
%                   seaside_design_S, leeside_design_S [-], armor_delta
%                   [-], seaside_mass, leeside_mass [kg], seaside_slope,
%                   leeside_slope (cot) [-], cem_P [-], toe_elevation,
%                   crest_elevation [m, study datum, positive up] and
%                   crest_width [m]
%     emp_coeff   - armor damage coefficients
%                   (load_empirical_coefficients), struct; reads km1,
%                   k_si, k_ls1, k_ls2
%     LC_MCSimOUT - life cycles of one storm type, nLC x 1 cell of Peaks
%                   matrices (nStorms x 10, lcs_columns; reads SWL,
%                   Hm0_toe, Tp and storm_duration [days])
%   Outputs:
%     PF_Summary     - probability of failure over the life cycles, table
%                      with rows Mean, '<p>%' for each project_CLs
%                      percentile and Std (population) and columns
%                      Row_Name, Overall, Seaside, Leeside
%     Reliab_Summary - reliability over the life cycles, same layout
%
%   Tier: internal
%
%   See also chess_csr, chess_csr_dpa, load_empirical_coefficients,
%   lcs_columns.
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
%     CSR_Peaks_DLL2.m.
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
%         TBD
%     Application Of Methodology:
%         (01) Gonzalez, Victor M. et. al. 2020. "Alabama Barrier Island Restauration Assesment life-cycle
%                 structure response modeling." ERDC/CHL TR-20-5. Vicksburg, MS: US Army Engineer Research
%                 and Development Center.

%% GRAB INPUTS FROM "config"
% Water density (kg/m^3)
dw = config.water_density;
% Get Requested CLs
prc = [cellfun(@str2double,strsplit(config.project_CLs(2:end-1),{' '}))];

%% GRAB STRUCTURAL PARAMETERS FROM "structure"
armor_delta = structure.armor_delta;
seaside_mass = structure.seaside_mass;
leeside_mass = structure.leeside_mass;
seaside_slope = structure.seaside_slope;
leeside_slope = structure.leeside_slope;
cem_P = structure.cem_P;
toe_elevation = structure.toe_elevation;
crest_elevation = structure.crest_elevation;
crest_width = structure.crest_width;
seaside_design_S = structure.seaside_design_S;
leeside_design_S = structure.leeside_design_S;
% Deterministic value of zero damage level seaside
S_ss = seaside_design_S;
% Deterministic value of zero damage level leeside
S_ls = leeside_design_S;

%% READ EMPERICAL COEFFICIENTS
% Empirical Coefficient (Seaside) - Momentum Flux
km1 = emp_coeff.km1;%i.e. 5,0.3
% Empirical Coefficient (Seaside) - Momentum Flux
k_ss = emp_coeff.k_si;% ?
% Empirical Coefficient (Leeside) - Momentum Flux
k_ls1 = emp_coeff.k_ls1;
% Empirical Coefficient (Leeside) - Momentum Flux
k_ls2 = emp_coeff.k_ls2;

%% DETERMINE NUMBER OF SIMULATIONS IN LC's

% Initialize Output Var
Reliab_all = zeros(length(LC_MCSimOUT),1);% [ Overall, Seaside, Leeside ]
Reliab_ss = zeros(length(LC_MCSimOUT),1); % Seaside
Reliab_ls = zeros(length(LC_MCSimOUT),1); % Leeside

%% SEASIDE STRUCTURAL PARAMETERS
% Ratio of armor stone density to water density (specific gravity)
Sr = 1+armor_delta;
% Armor stone density
dr = Sr.*dw;
% Median volume of armor stone
V_ss = seaside_mass./dr;
% Seaside stone nominal diameter (m)
Dn_ss = V_ss.^(1/3);
% Tangent of the seaside stone armor slope angle
tan_ss = 1./seaside_slope;

%% LEESIDE STRUCTURAL PARAMETERS
% Ratio of armor stone density to water density
Sr = 1+armor_delta;
% Armor stone density
dr = Sr.*dw;
% Median volume of armor stone
V_ls = leeside_mass./dr;
% Seaside stone nominal diameter (m)
Dn_ls = V_ls.^(1/3);
% Tangent of the leeside stone armor slope angle
tan_ls = 1./leeside_slope;

%% READ & FORMAT ADDITIONAL DATA
% Gravitational acceleration (m/s^2)
g = config.gravity_constant;
% Life-Cycle Column Map
C = lcs_columns();
% Loop Through All Life Cycles
for lcS=1:length(LC_MCSimOUT)

    %% BUILD STORM FORCING DATA MATRIX
    % Build Forcing Parameters Matrix For Current LC
    WL = LC_MCSimOUT{lcS}(:, C.SWL); %Water Level
    Hm0 = LC_MCSimOUT{lcS}(:, C.Hm0_toe); %Wave Height (At The Toe)
    Tp = LC_MCSimOUT{lcS}(:, C.Tp); %Peak Wave Period
    % Number Of Simulations (# Of Storms)
    nSim = size(LC_MCSimOUT{lcS},1);
    % Life Cycle Without Storms: No Failure (Reliability 1)
    if nSim == 0
        Reliab_ss(lcS,1) = 1;
        Reliab_ls(lcS,1) = 1;
        Reliab_all(lcS,1) = 1;
        continue
    end

    %% APPLY UNCERTAINTY TO Tp AND COMPUTE ADDITIONAL PARAMETERS
    % Mean wave period (sec)
    Tm = Tp/1.2;
    % wave period (sec)
    Tm10 = Tp/1.1;
    % Number of waves per storm
    Nz = (LC_MCSimOUT{lcS}(:, C.storm_duration)*24*3600)./Tm; % Storm Duration Column [days] To Seconds
    % deep water wave length based on mean wave period
    Lm0 = (g*Tm.^2)/(2*pi);
    % Compute Water Col
    h = WL - toe_elevation; h(h<0) = 0.01;

    %% SEASIDE STABILITY LIMIT STATE (MELBY AND KOBAYASHI 2011)
    % Fourrier Solution Coefficient
    A0 = 0.639*(Hm0./h).^2.026;
    % Fourier Solution Exponent
    A1 = 0.180*(Hm0./h).^(-0.391);
    % Plunging Waves Coefficient
    am = 1./(km1.*(cem_P.^0.18).*sqrt(seaside_slope));
    % Compute Response Component
    R_ss = (sqrt(armor_delta).*Dn_ss.*(S_ss.^0.2))./am;
    % Momentum Flux
    A = A0.*(h./(g*Tm.^2)).^(-A1);
    % Compute Forcing Component
    F_ss = h.*(Nz.^0.1).*k_ss.*(A.^0.5);
    % Seaside Stability Performance
    G_ss = R_ss-F_ss;
    % Compute Reliability
    Reliab_ss(lcS,1) = 1-sum(G_ss<0)/nSim;

    %% LEESIDE STABILITY LIMIT STATE (VAN GENT AND POZUETA 2004; MELBY 2009)
    % for constant wave conditions
    r = 6;
    % Freeboard Leeside
    Rc_ls = crest_elevation-toe_elevation-h;
    % Empirical Coefficient
    c0 = 1.45;
    % Empirical Coefficient
    c1 = 5.1;
    % Empirical Coefficient
    c2 = 0.25*(c1^2)/c0;
    % Empirical Coefficient
    p = 0.5*c1/c0;
    % Leeside Stability Coefficient
    a_ls = leeside_slope.^(-2.5/r).*(1+10*exp(-Rc_ls./Hm0)).^(1/r);
    % Compute Response Component
    R_ls = (sqrt(armor_delta).*Dn_ls.*S_ls.^(1/6))./a_ls;
    % Wave Length
    Lm10 = (g*Tm10.^2)/(2*pi);
    % Surf Similarity Parameter
    Irs1 = tan_ls./sqrt(Hm0./Lm10);

    %% COMPUTE WAVE R1%
    % Initialize Gamma_fc Var
    Yfc = ones(size(Hm0));
    % Compute Friction Factor On Crest as f(Irs1)
    Yfc(Irs1<=2) = 0.55;
    Yfc(Irs1>2 & Irs1<10) = 0.05625*(Irs1(Irs1>2 & Irs1<10)-2)+0.55;
    Yfc(Irs1>=10) = 1.0;
    % Initialize R1% Var
    z1p = zeros(size(Hm0));
    % Compute Logical Vector
    ixIrs1 = (Irs1<=p);
    % Compute z1p
    z1p(ixIrs1) = Yfc(ixIrs1).*Hm0(ixIrs1).*(c0*Irs1(ixIrs1));% runup exceeded by % of the waves.
    % COmpute Logical Vector
    ixIrs1 = (Irs1>p);
    % Compute z1p
    z1p(ixIrs1,1) = Yfc(ixIrs1).*Hm0(ixIrs1).*(c1-c2./Irs1(ixIrs1));

    %% CONTINUE LEESIDE STABILITY COMPUTATION
    % Initialize u1p
    u1p = zeros(size(WL));
    % Negative Freeboard Failsafe
    Rc_ls(Rc_ls<0.6) = 0;
    % Compute 1% Overtopping Velocity
    u1p(~(Rc_ls<0.6)) = sqrt(g*Hm0(~(Rc_ls<0.6))).*(1.7*Yfc(~(Rc_ls<0.6)).^0.5).*...
        ((z1p(~(Rc_ls<0.6))-Rc_ls(~(Rc_ls<0.6)))./(Yfc(~(Rc_ls<0.6)).*Hm0(~(Rc_ls<0.6)))).^0.5...
        ./(1+0.1*crest_width./Hm0(~(Rc_ls<0.6)));
    % Compute Forcing Component
    F_ls = k_ls2.^(1/6).*Nz.^(1/12).*(u1p.*Tm10./k_ls1);
    % Leeside Stability Performance
    G_ls = R_ls-F_ls;
    % Compute Reliability
    Reliab_ls(lcS,1) = 1-sum(G_ls<0)/nSim;

    %% Overall Stability Limit State
    % Overall Stability Performance
    G_all = min(G_ss,G_ls);
    % Compute Overall Reliability
    Reliab_all(lcS,1) = 1-sum(G_all<0)/nSim;
end
%% RELIABILITY AVERAGES AND PERCENTILES
% Define Row Names
row_names = [{'Mean'}; cellstr([num2str(prc') repmat('%',size(prc',1),1)]); {'Std'}];
% Compute Overall Mean, Percentiles, Std Reliability
col1 = num2cell([mean(Reliab_all,1,"omitnan");...
    prctile(Reliab_all,prc)';...
    std(Reliab_all,1,"omitnan")]);
% Compute Seaside Mean, Percentiles, Std Reliability
col2 = num2cell([mean(Reliab_ss,1,"omitnan");...
    prctile(Reliab_ss,prc)';...
    std(Reliab_ss,1,"omitnan")]);
% Compute Leeside Mean, Percentiles, Std Reliability
col3 = num2cell([mean(Reliab_ls,1,"omitnan");...
    prctile(Reliab_ls,prc)';...
    std(Reliab_ls,1,"omitnan")]);
% Create Reliability Summary Table
Reliab_Summary = cell2table([row_names,col1,col2,col3],"VariableNames",{'Row_Name','Overall','Seaside','Leeside'});

%% PROBABILITY OF FAILURE AVERAGES AND PERCENTILES
% Seaside Probability Of Failure
PF_ss = 1-Reliab_ss;
% Leeside Probability Of Failure
PF_ls = 1-Reliab_ls;
% Overall Probability Of Failure
PF_all = 1- Reliab_all;
% Compute Overall Mean, Percentiles, Std Reliability
col1 = num2cell([mean(PF_all,1,"omitnan");...
    prctile(PF_all,prc)';...
    std(PF_all,1,"omitnan")]);
% Compute Seaside Mean, Percentiles, Std Reliability
col2 = num2cell([mean(PF_ss,1,"omitnan");...
    prctile(PF_ss,prc)';...
    std(PF_ss,1,"omitnan")]);
% Compute Leeside Mean, Percentiles, Std Reliability
col3 = num2cell([mean(PF_ls,1,"omitnan");...
    prctile(PF_ls,prc)';...
    std(PF_ls,1,"omitnan")]);
% Create Reliability Summary Table
PF_Summary = cell2table([row_names,col1,col2,col3],"VariableNames",{'Row_Name','Overall','Seaside','Leeside'});
end
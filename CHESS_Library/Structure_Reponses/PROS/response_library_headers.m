function [U_a, U_r, uncert_treatment_jpm,...
    unit_label,...
    var_name, y_label, y_scale_log] = response_library_headers(config, staID)

%% Grab Response Uncertainty
r2p_u = config.r2p_u; % Runup
q_u = config.q_u; % Overtopping
dn50_u = config.dn50_u; % Median Stone Size
p1_u = config.p1_u; % Goda Pressure (P1)
swl_u_a = config.chs_swl_u_a; % SWL Absolute
swl_u_r = config.chs_swl_u_r; % SWL Proportional
hm0_u_a = config.chs_hm0_u_a; % Hm0 Absolute
hm0_u_r = config.chs_hm0_u_r; % Hm0 Proportional
datum = config.project_datum;

%% Determine Response Fields
% Set Y Scale
y_scale_log = 0;
% Grab Information Accroding To Case
switch staID
    case 'SWL'
        % Define Uncertainty Parameters
        U_a = swl_u_a; % Define Absolute Uncertainty
        U_r = swl_u_r; % Define Relative Uncertainty
        uncert_treatment_jpm = 'combined';% JPM Uncertainty Treatment
        % Define Var Properties
        unit_label = 'm';
        y_label = ['SWL [' unit_label ', ' datum ']'];
        var_name = 'SWL';
    case 'Hm0_offshore' % Before Depth Limitation (Goda Pressures, Damaging Depth)
        U_a = hm0_u_a;
        U_r = hm0_u_r;
        uncert_treatment_jpm = 'combined';
        unit_label = 'm';
        y_label = ['$H_{m_{0}}$ (offshore) [' unit_label ']'];
        var_name = '$H_{m_{0}}$ (offshore)';
        % Multi-Line Stage 2: Waves Transmitted Behind Stage 1 (apply_stage1_transmission.m)
        if isfield(config, 'multiline') && isstruct(config.multiline)
            behind = ['(offshore, behind ' regexprep(config.multiline.stage1_alt, '([_&%#{}])', '\\$1') ')'];
            y_label = ['$H_{m_{0}}$ ' behind ' [' unit_label ']'];
            var_name = ['$H_{m_{0}}$ ' behind];
        end
    case 'Hm0_toe' % Depth Limited At The Toe (Toe Responses)
        U_a = 0;
        U_r = hm0_u_r;
        uncert_treatment_jpm = 'relative';
        unit_label = 'm';
        y_label = ['$H_{m_{0}}$ (at toe) [' unit_label ']'];
        var_name = '$H_{m_{0}}$ (at toe)';
    case 'Hm0t'
        U_a = hm0_u_a;
        U_r = hm0_u_r;
        uncert_treatment_jpm = 'relative';
        unit_label = 'm';
        y_label = ['$H_{m_{0t}}$ [' unit_label ']'];
        var_name = '$H_{m_{0t}}$';
    case 'h' % Water Depth At Toe: SWL - toe_elevation
        U_a = 0;U_r = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'm';
        y_label = ['$h$ [' unit_label ']'];
        var_name = '$h$';
    case 'Rc' % Freeboard: crest_elevation - SWL
        U_a = 0;U_r = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'm';
        y_label = ['$R_c$ [' unit_label ']'];
        var_name = '$R_c$';
    case 'Tp'
        U_a = 0;
        U_r = sqrt(1+hm0_u_r)-1;
        uncert_treatment_jpm = 'relative';
        unit_label = 's';
        y_label = ['$T_p$ [' unit_label ']'];
        var_name = '$T_p$';
    case {'R2p','R2p_SWL'}
        U_a=0;
        U_r = r2p_u;
        uncert_treatment_jpm = 'relative';
        unit_label = 'm';
        y_label = ['$R_{2\%}$ [' unit_label ']'];
        var_name = '$R_{2\%}$';
        if strcmp(staID,'R2p_SWL')
            y_label = ['$R_{2\%}$ + SWL [' unit_label ']'];
            var_name = '$R_{2\%}$ + SWL';
        end
    case {'Dn50','Dn50_LCBW', 'Dn50_Lee'}
        U_a=0;
        U_r = dn50_u;
        uncert_treatment_jpm = 'relative';
        unit_label = 'm';
        y_label = ['$D_{n_{50}}$ [' unit_label ']'];
        var_name = '$D_{n_{50}}$';
        if any(strcmp(staID,{'Dn50_LCBW', 'Dn50_Lee'}))
            switch staID
                case 'Dn50_LCBW'
                    str_suffix = 'LCBW';
                case 'Dn50_Lee'
                    str_suffix = 'Lee';
            end
            y_label = ['$D_{n_{50}}$ ' str_suffix ' [' unit_label ']'];
            var_name = ['$D_{n_{50}}$ ' str_suffix];
        end
    case 'p1'
        U_a=0;
        U_r = p1_u;
        uncert_treatment_jpm = 'relative';
        unit_label = 'Pa';
        y_label = ['$P_1$ [ ' unit_label ']'];
        var_name = '$P_1$';
    case {'q', 'q_overflow', 'q_wave_ot'}
        pres_lbl = {'q', '$q_{overflow}$', '$q_{overtop}$'};
        mindx = strcmp(staID, {'q', 'q_overflow', 'q_wave_ot'});
        U_a=0;U_r = [q_u swl_u_a q_u];
        y_scale_log = [1 0 1];
        uncert_treatment_jpm = 'relative';
        unit_label = '$m^3$/s per m';
        y_label = ['' pres_lbl{mindx} ' [ ' unit_label ']'];
        var_name = pres_lbl{mindx};
        y_scale_log = y_scale_log(mindx);
        U_r = U_r(mindx);
    case {'Q_vol', 'Q_vol_overflow', 'Q_vol_wave_ot'}
        pres_lbl = {'Q', '$Q_{overflow}$', '$Q_{overtop}$'};
        mindx = strcmp(staID, {'Q_vol', 'Q_vol_overflow', 'Q_vol_wave_ot'});
        U_a=0;U_r = [q_u swl_u_a q_u];
        y_scale_log = [1 0 1];
        uncert_treatment_jpm = 'relative';
        unit_label = '$m^3$ per m';
        y_label = ['' pres_lbl{mindx} ' [ ' unit_label ']'];
        var_name = pres_lbl{mindx};
        y_scale_log = y_scale_log(mindx);
        U_r = U_r(mindx);
    case 'DamDepthElev'
        U_a=0;
        U_r = swl_u_a;
        y_scale_log = 0;
        uncert_treatment_jpm = 'relative';
        unit_label = 'm';
        y_label = ['Damaging Depth Elevation [ ' unit_label ']'];
        var_name = 'Damaging Depth Elevation';
    case 'DamDepth'
        U_a=0;
        U_r = swl_u_a;
        y_scale_log = 0;
        uncert_treatment_jpm = 'relative';
        unit_label = 'm';
        y_label = ['Damaging Depth [ ' unit_label ']'];
        var_name = 'Damaging Depth';
    case {'p2dyn', 'p2sta', 'p2total'}
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'Pa';pres_lbl = {'Dynamic', 'Static', 'Total'};
        y_label = ['$P_2$ (' pres_lbl{strcmp(staID, {'p2dyn', 'p2sta', 'p2total'})} ') [ ' unit_label ']'];
        var_name = ['$P_2$ (' pres_lbl{strcmp(staID, {'p2dyn', 'p2sta', 'p2total'})} ')'];
    case {'p3dyn', 'p3sta', 'p3total'}
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'Pa';pres_lbl = {'Dynamic', 'Static', 'Total'};
        y_label = ['$P_3$ (' pres_lbl{strcmp(staID, {'p3dyn', 'p3sta', 'p3total'})} ') [ ' unit_label ']'];
        var_name = ['$P_3$ (' pres_lbl{strcmp(staID, {'p2dyn', 'p2sta', 'p2total'})} ')'];
    case 'pu'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'Pa';
        y_label = ['$P_u$ [ ' unit_label ']'];
        var_name = '$P_u$';
    case {'X_low','X_up','X_c_surge', 'Bx'}
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'm';pres_lbl = {'$X_{low}$','$X_{up}$','$X_c$ (surge)', '$B_x$'};
        y_label = [pres_lbl{strcmp(staID, {'X_low','X_up','X_c_surge', 'Bx'})} ' [ ' unit_label ']'];
        var_name = pres_lbl{strcmp(staID, {'X_low','X_up','X_c_surge', 'Bx'})};
    case {'theta_low', 'theta_up', 'theta_center'}
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'deg';pres_lbl = {'$\theta_{low}$', '$\theta_{up}$', '$\theta_c$'};
        y_label = [pres_lbl{strcmp(staID, {'theta_low', 'theta_up', 'theta_center'})} ' [ ' unit_label ']'];
        var_name = pres_lbl{strcmp(staID, {'theta_low', 'theta_up', 'theta_center'})};
    case 'Bjet'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'm';
        y_label = ['$B_{jet}$ [ ' unit_label ']'];
        var_name = '$B_{jet}$';
    case 'Vjet'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'm/s';
        y_label = ['$V_{jet}$ [ ' unit_label ']'];
        var_name = '$V_{jet}$';
    case 'Fjet'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'N/m';
        y_label = ['$F_{jet}$ [ ' unit_label ']'];
        var_name = '$F_{jet}$';
    case 'LSmax'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = '';
        var_name = '$\bar{\bar{S}}_{max}$ (leeside)';
        y_label     = 'Yearly Mean Maximum Cumulative Damage ($\bar{\bar{S}}_{max}$)';
    case 'Smax'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = '';
        var_name =  '$\bar{\bar{S}}_{max}$ (seaside)';
        y_label     = 'Yearly Mean Maximum Cumulative Damage ($\bar{\bar{S}}_{max}$)';
    case 'S_seaside_with_repairs'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = '';
        var_name = '$\bar{S}_{with\ repairs}$ (seaside)';
        y_label     = 'Mean Cumulative Damage $\bar{S}$';
    case 'S_seaside_no_repairs'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = '';
        var_name = '$\bar{S}_{no\ repairs}$ (seaside)';
        y_label     = 'Mean Cumulative Damage $\bar{S}$';
    case 'S_leeside_no_repairs'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = '';
        var_name = '$\bar{S}_{no\ repairs}$ (leeside)';
        y_label     = 'Mean Cumulative Damage $\bar{S}$';
    case 'S_leeside_with_repairs'
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = '';
        var_name = '$\bar{S}_{with\ repairs}$ (leeside)';
        y_label     = 'Mean Cumulative Damage $\bar{S}$';
    otherwise
        U_a = 0;U_r = 0;
        y_scale_log = 0;
        uncert_treatment_jpm = 'none';
        unit_label = 'nan';
        y_label = 'nan';
        var_name = 'nan';
end
end

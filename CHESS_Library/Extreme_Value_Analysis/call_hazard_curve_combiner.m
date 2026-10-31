function cc_resp = call_hazard_curve_combiner(config, tc_resp, xc_resp, use_aep)
%% GRAB DETAILS FORM "config"
% Build Uncertainty Vector
u_names = fieldnames(config);
u_vector = struct2cell(config);
% Grab Uncertainty Fields
u_vector = u_vector(contains(u_names, {'u_a','_u'}));
u_names = u_names(contains(u_names, {'u_a','_u'}));

%% COMBINE HAZARD CURVES FOR PRIMARY RESPONSES
% Define AEP's or AEF's
if use_aep == 1
    rp_out = tc_resp(1).x_table;
    x_plot_tc = tc_resp(1).x_plot;
    x_tbl_tc = tc_resp(1).x_table;
else
    rp_out = aef2aep(tc_resp(1).x_table);
    x_plot_tc = aef2aep(tc_resp(1).x_plot);
    x_tbl_tc = aef2aep(tc_resp(1).x_table);
end
plt_indx = round(x_plot_tc, 6)>=5E-04;
tbl_indx = round(x_tbl_tc, 6)>=5E-04;
x_tbl_tc = x_tbl_tc(tbl_indx);
x_plot_tc = x_plot_tc(plt_indx);
% Pair TC & XC Responses By Name (TC Order; Responses Without A Pair Are Dropped)
xc_vars = {xc_resp.var};
s_indx = find(ismember({tc_resp.var}, xc_vars));
% Initialize Storage Var (Only Combined Responses Are Stored)
cc_resp = rmfield(tc_resp([]),{'tbl_rsp_x','tbl_rsp_y'});
% Define Counter
ctr = 1;
% Loop Through Each Parameter
for j = s_indx
    % Determine Corresponding Uncertainty Field
    switch tc_resp(j).var
        case 'R2p_SWL'
            u_field = u_vector{contains(u_names, 'r2p')};
        case 'Tp'
            u_field = sqrt(1+u_vector{contains(u_names, 'chs_hm0_u_r')})-1;
        case {'q_overflow', 'Q_vol_overflow', 'DamDepthElev', 'DamDepth'}
            u_field = u_vector{contains(u_names, 'chs_swl_u_r')};
        case {'Q_vol_wave_ot','Q_vol','q_wave_ot'}
            u_field = u_vector{contains(u_names, 'q')};
        case {'Dn50', 'Dn50_Lee'}
            u_field = u_vector{contains(u_names, 'dn50')};
        case {'p2dyn','p2sta','p2total','p3dyn','p3sta','p3total','pu','X_low','theta_low','X_up','theta_up','Bx','X_c_surge','theta_center','Bjet','Vjet','Fjet'}
            % Skip Until Issues Are Sorted
            continue;
        case {'Hm0t', 'Hm0_toe'}
            % Use Values Associated To Hm0
            u_field = u_vector{contains(u_names, 'hm0_u_r')};
        case 'Hm0_offshore'
            % Same Lookup As The Former 'Hm0' Curve (First Config Field Containing 'hm0')
            u_field = u_vector{contains(u_names, 'hm0')};
        case 'SWL'
            u_field = u_vector{contains(u_names, 'chs_swl_u_r')};
        otherwise
            u_field = u_vector{contains(u_names, lower(tc_resp(j).var))};
    end
    % Matching XC Entry
    xc_j = xc_resp(find(strcmp(xc_vars, tc_resp(j).var), 1));
    % CC Entry Starts As A Copy Of The TC Entry
    cc_resp(ctr) = rmfield(tc_resp(j),{'tbl_rsp_x','tbl_rsp_y'});
    %
    disp(['               Combining ' tc_resp(j).var ' hazard curves....']);
    % Combine HCs To Create Table
    cc_resp(ctr).y_table = combine_hazard_curves(tc_resp(j).tbl_rsp_x, xc_j.tbl_rsp_x,...
        xc_j.tbl_rsp_y, x_tbl_tc, tc_resp(j).y_log_scale, tc_resp(j).CL, u_field, tc_resp(j).var);
    % Combine HCs To Create Plot
    cc_resp(ctr).y_plot = combine_hazard_curves(tc_resp(j).tbl_rsp_x, xc_j.tbl_rsp_x,...
        xc_j.tbl_rsp_y, x_plot_tc, tc_resp(j).y_log_scale, tc_resp(j).CL, u_field, tc_resp(j).var);
    % ADjust Figure Title
    %     cc_resp(ctr).title(1) = {strrep(cc_resp(ctr).title{1},'JPM','Combined')};
    cc_resp(ctr).title(2) = {strrep(cc_resp(ctr).title{2},'TC','CC')};
    % Events Not Fitted: [XC, TC]
    cc_resp(ctr).n_events = [xc_j.n_events, tc_resp(j).n_events];
    cc_resp(ctr).n_dropped = [xc_j.n_dropped, tc_resp(j).n_dropped];
    cc_resp(ctr).title(2) = {regexprep(cc_resp(ctr).title{2}, ' \| \d+ of \d+ events not fitted$', '')};
    if any(cc_resp(ctr).n_dropped > 0)
        cc_resp(ctr).title(2) = {sprintf('%s | XC %d/%d, TC %d/%d not fitted', cc_resp(ctr).title{2},...
            cc_resp(ctr).n_dropped(1), cc_resp(ctr).n_events(1), cc_resp(ctr).n_dropped(2), cc_resp(ctr).n_events(2))};
    end
    % Adjust Figure Output Names
    cc_resp(ctr).save_name = strrep(cc_resp(ctr).save_name,'TC','CC');
    % Define POT
    cc_resp(ctr).POT = {'Hazard curve computed by combining TC & XC primary responses'};
    % Increase Counter
    ctr = ctr + 1;
end
% Cut Frequency Vector
for kk = 1:length(cc_resp)
    cc_resp(kk).x_table = cc_resp(kk).x_table(tbl_indx);
    cc_resp(kk).x_plot = cc_resp(kk).x_plot(plt_indx);
    cc_resp(kk).x_table_ARI = cc_resp(kk).x_table_ARI(tbl_indx);
end
end

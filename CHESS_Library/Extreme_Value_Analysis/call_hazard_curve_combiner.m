function cc_resp = call_hazard_curve_combiner(config, tc_resp, xc_resp, use_aep)
% call_hazard_curve_combiner  Combine TC and XC hazard curves into CC curves.
%   cc_resp = call_hazard_curve_combiner(config, tc_resp, xc_resp, use_aep)
%
%   PROS-RB step of chess_pros for storm_sampling 'CC': pairs the TC and
%   XC entries of call_hazard_curve_builder by variable name (TC order;
%   variables without a pair are dropped) and builds the combined curve
%   with combine_hazard_curves at the TC table and plot frequencies
%   (converted to AEP when use_aep = 0) with AEP >= 5e-4. Variables whose
%   registry row (response_registry) has cc_rule 'skip' are not combined;
%   rows with cc_confidence_limit_method 'als_relative' build the CLs from
%   the config relative uncertainty field named in the row
%   (relative_uncertainty). Each CC entry starts as a copy of the TC entry
%   (tbl_rsp_x and tbl_rsp_y removed) with 'TC' replaced by 'CC' in the
%   title and save_name, n_events and n_dropped as [XC, TC], and POT set to
%   a note.
%
%   Inputs:
%     config  - CHESS configuration, 1x1 struct; reads the relative
%               uncertainty fields named by the registry rows
%     tc_resp - TC hazard curve entries (call_hazard_curve_builder
%               output), struct array
%     xc_resp - XC hazard curve entries (call_hazard_curve_builder
%               output), struct array
%     use_aep - TC x_table/x_plot are AEP (1) or AEF (0), scalar double
%   Outputs:
%     cc_resp - combined hazard curve entries, 1 x number_of_combined
%               struct (TC entry fields without tbl_rsp_x and tbl_rsp_y;
%               x_table, x_plot and x_table_ARI cut to AEP >= 5e-4)
%
%   Tier: internal
%
%   See also call_hazard_curve_builder, combine_hazard_curves,
%   response_registry, chess_pros.

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
    % Registry Rules (response_registry.m): Skipped Responses; U_r Only Feeds The ALS Confidence Limits
    row = response_registry('name', tc_resp(j).var);
    if ~isempty(row) && strcmp(row.cc_rule, 'skip')
        continue;
    end
    u_field = [];
    if ~isempty(row) && strcmp(row.cc_confidence_limit_method, 'als_relative')
        u_field = config.(row.relative_uncertainty);
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

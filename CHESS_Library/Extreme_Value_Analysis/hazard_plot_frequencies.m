function aef = hazard_plot_frequencies()
% hazard_plot_frequencies  AEF grid of the plotted hazard curves.
%   aef = hazard_plot_frequencies()
%
%   One plot grid (HC_plt_x before any AEP conversion) for the JPM
%   (CHESS_JPM_integration) and PST (CHESS_PST_Fit) hazard curves.
%
%   Outputs:
%     aef - AEF [1/yr], 90 points per decade from 1e-6 to 10, ascending
%           double column (631 x 1)
%
%   Tier: internal
%
%   See also hazard_table_probabilities, CHESS_JPM, CHESS_PST.

d=1/90; v=10.^(1:-d:0)'; aef=v; x=10;
for i=1:6
    aef=[aef; v(2:end)/x]; %#ok<AGROW>
    x=x*10;
end
aef=flipud(aef);
end

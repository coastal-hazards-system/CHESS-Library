function T = period_from_peak(T_in, kind)
% chess.BoundaryConditions.waves.period_from_peak  Wave period conversions from (or to) the peak period Tp (single source).
%   T = chess.BoundaryConditions.waves.period_from_peak(T_in, kind) applies
%   the CHESS period ratios element-wise:
%     'mean'           - mean period Tm = Tp/1.2
%     'spectral'       - spectral period T_m-1,0 = Tp/1.1
%     'peak_from_mean' - peak period Tp = Tm*1.2 (inverse of 'mean', used
%                        when a wave model reports Tm instead of Tp)
%
%   Inputs:
%     T_in - wave period [s], double scalar or array (Tp, or Tm for
%            'peak_from_mean')
%     kind - conversion, char or string: 'mean', 'spectral' or
%            'peak_from_mean'
%   Outputs:
%     T    - converted wave period [s], double, same size as T_in
%
%   See also chess.Equations.melby_Dn50_seaside_stability,
%   chess.Equations.van_gent_Dn50_leeside_stability,
%   chess.Equations.Eurotop_r2p_q_Final.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

switch kind
    case 'mean'
        T = T_in./1.2;
    case 'spectral'
        T = T_in./1.1;
    case 'peak_from_mean'
        T = T_in.*1.2;
    otherwise
        error('chess:BoundaryConditions:waves:period_from_peak:unknownKind', ...
            'Unknown period kind ''%s'': use ''mean'', ''spectral'' or ''peak_from_mean''.', kind);
end
end

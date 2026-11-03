function [stm_type_chk, data_type_chk, alt_chk] = storm_db_check(storm, prob_mass, storm_sampling,...
    use_peaks, use_timeseries, create_wlp, create_whp)
% storm_db_check  Check that a storm database holds the requested storm data.
%   [stm_type_chk, data_type_chk, alt_chk] = storm_db_check(storm,
%       prob_mass, storm_sampling, use_peaks, use_timeseries, create_wlp,
%       create_whp)
%
%   Storm database holds the request: storm types, data types and
%   alternate Peaks datasets (WLP/WHP). TC counts as present only with
%   its probability masses (prob_mass.TC_Freq not empty): a database
%   built without CHS_Dependencies has XC only. Each check includes the
%   previous one.
%
%   Inputs:
%     storm          - storm database content (<db>.mat), struct
%     prob_mass      - TC probability masses (<db>.mat), struct or []
%     storm_sampling - requested storm sampling, 'XC', 'TC' or 'CC', char
%     use_peaks      - Peaks requested (0/1), scalar double
%     use_timeseries - Timeseries requested (0/1), scalar double
%     create_wlp     - WLP Peaks dataset requested (0/1), scalar double
%     create_whp     - WHP Peaks dataset requested (0/1), scalar double
%   Outputs:
%     stm_type_chk   - requested storm types present, logical
%     data_type_chk  - ... and their requested data types, logical
%     alt_chk        - ... and their requested alternate Peaks datasets
%                      (the database holds the request), logical
%
%   Tier: internal
%
%   See also storm_db_info, build_storm_database, storm_validation.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
need_types = {'TC','XC'};
need_types = need_types([any(strcmp(storm_sampling, {'TC','CC'})), any(strcmp(storm_sampling, {'XC','CC'}))]);
has_tc = isfield(storm, 'TC') && isstruct(prob_mass) && isfield(prob_mass, 'TC_Freq') && ~isempty(prob_mass.TC_Freq);
stm_type_chk = all(isfield(storm, need_types)) && (has_tc || ~ismember('TC', need_types));
data_type_chk = stm_type_chk && all(cellfun(@(t) (use_peaks == 0 || isfield(storm.(t), 'Peaks')) &&...
    (use_timeseries == 0 || isfield(storm.(t), 'Timeseries')), need_types));
alt_chk = data_type_chk && all(cellfun(@(t) (create_wlp == 0 || isfield(storm.(t).Peaks, 'WLP')) &&...
    (create_whp == 0 || isfield(storm.(t).Peaks, 'WHP')), need_types));
end

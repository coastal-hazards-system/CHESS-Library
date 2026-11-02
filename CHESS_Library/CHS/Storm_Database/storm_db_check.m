function [stm_type_chk, data_type_chk, alt_chk] = storm_db_check(storm, prob_mass, storm_sampling,...
    use_peaks, use_timeseries, create_wlp, create_whp)
%{
    %% DESCRIPTION
        Storm database holds the request: storm types, data types and
        alternate Peaks datasets (WLP/WHP). TC counts as present only with
        its probability masses (prob_mass.TC_Freq not empty): a database
        built without CHS_Dependencies has XC only.

    %% INPUTS
        storm, prob_mass: Storm database content (<db>.mat). | struct
        storm_sampling: 'XC', 'TC' or 'CC'. | char
        use_peaks, use_timeseries, create_wlp, create_whp: Request switches (0/1). | double

    %% OUTPUTS
        stm_type_chk: Requested storm types present. | logical
        data_type_chk: ... and their requested data types. | logical
        alt_chk: ... and their requested alternate Peaks datasets (database holds the request). | logical

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
need_types = {'TC','XC'};
need_types = need_types([any(strcmp(storm_sampling, {'TC','CC'})), any(strcmp(storm_sampling, {'XC','CC'}))]);
has_tc = isfield(storm, 'TC') && isstruct(prob_mass) && isfield(prob_mass, 'TC_Freq') && ~isempty(prob_mass.TC_Freq);
stm_type_chk = all(isfield(storm, need_types)) && (has_tc || ~ismember('TC', need_types));
data_type_chk = stm_type_chk && all(cellfun(@(t) (use_peaks == 0 || isfield(storm.(t), 'Peaks')) &&...
    (use_timeseries == 0 || isfield(storm.(t), 'Timeseries')), need_types));
alt_chk = data_type_chk && all(cellfun(@(t) (create_wlp == 0 || isfield(storm.(t).Peaks, 'WLP')) &&...
    (create_whp == 0 || isfield(storm.(t).Peaks, 'WHP')), need_types));
end

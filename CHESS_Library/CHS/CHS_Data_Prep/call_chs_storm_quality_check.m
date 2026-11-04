function [config, storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass] = call_chs_storm_quality_check(config, CHS_Data, prob_mass, storm_type)
% call_chs_storm_quality_check  Format, match and screen CHS storm files.
%   [config, storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass] =
%       call_chs_storm_quality_check(config, CHS_Data, prob_mass, storm_type)
%
%   Builds the storm datasets of one storm type from converted CHS files;
%   build_storm_database calls it per storm type, TC first. Peaks: the
%   ADCIRC and wave model Peaks files are matched per storm ID
%   (chs_peaks_formatter, Peaks.Default). Timeseries: the ADCIRC and wave
%   model Timeseries are matched on an hourly time step
%   (chs_timeseries_formatter, Timeseries.Default). With both data types,
%   the Water Level Priority / Wave Height Priority Peaks datasets are
%   built when requested (create_priority_dataset, Peaks.WLP /
%   Peaks.WHP). The wave model columns come from
%   chs_wave_model_header_locator.
%   Timeseries wave flags: before the Timeseries and WLP datasets are
%   built, flagged raw wave steps are filled (fill_flagged_wave_steps:
%   Hm0 NaN/<= 0 -> 0.01 m, Tp NaN/<= 0 -> nearest valid Tp of the storm)
%   so the step is kept.
%   Screening: storms with NaN or flagged Peaks values, a one-value water
%   level Timeseries, no valid Tp step, no common ADCIRC/wave time range,
%   an interior gap of dropped Timeseries steps (chs_timeseries_formatter)
%   or no WLP/WHP match (create_priority_dataset) are listed in
%   removed_storms.Default and every dataset (Peaks Default / WLP / WHP,
%   Timeseries Default) drops them by its own storm IDs. TC: the removed
%   storms also leave prob_mass (Param and TC_Freq rows by the storm ID
%   in Param column 1; smpl1, smpl2, smpl3; TC_Freq rescaled to
%   TotalFreq), and the SWL is
%   bias corrected when the region's bias & uncertainty files exist
%   (chs_dependency_files bias_uncertainty_available). XC: never bias
%   corrected; XC_Nstm and XC_Nyrs come from the ADCIRC Peaks file (else
%   from the ADCIRC Timeseries file).
%
%   Inputs:
%     config     - quality check settings (build_storm_database), 1x1
%                  struct; fields:
%                    use_peaks        - storm type has complete Peaks
%                                       files (0/1), double
%                    use_timeseries   - storm type has complete
%                                       Timeseries files (0/1), double
%                    create_wlp       - build the WLP dataset (0/1), double
%                    create_whp       - build the WHP dataset (0/1), double
%                    region           - CHS region, char
%                    sp_ID            - ADCIRC savepoint ID, double
%                    chs_dependencies - CHS_Dependencies folder, char
%                    chs_swl_b_a      - SWL bias, absolute [m], double
%                    chs_swl_b_r      - SWL bias, relative [-], double
%                    print_progress   - print progress (0/1), double
%     CHS_Data   - converted CHS files (Filename, Conv_Data),
%                  1 x number_of_files struct
%     prob_mass  - TC probability masses (chs_probability_mass_loader:
%                  Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2,
%                  smpl3), struct; not read for XC
%     storm_type - storm type, 'TC' or 'XC', char
%   Outputs:
%     config         - input config; TC adds tc_bias_corrected (1 if the
%                      SWL bias correction was applied, else 0), struct
%     storm          - storm datasets of the storm type (Peaks.Default,
%                      Peaks.WLP, Peaks.WHP, Timeseries.Default; rows
%                      {storm ID, data}), struct
%     removed_storms - IDs of the removed storms (field Default), struct
%     XC_Nyrs        - XC record length [years] ([] for TC), double
%     XC_Nstm        - XC storm count, before screening ([] for TC),
%                      double
%     prob_mass      - TC probability masses without the removed storms
%                      ([] for XC), struct
%
%   Tier: internal
%
%   See also build_storm_database, chs_peaks_formatter,
%   chs_timeseries_formatter, create_priority_dataset, fill_flagged_wave_steps,
%   chs_wave_model_header_locator, chs_probability_mass_loader.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% GRAB INFORMATION FROM "config"
use_timeseries = config.use_timeseries;
use_peaks = config.use_peaks;
WLP_switch = config.create_wlp;
WHP_switch = config.create_whp;
% CHS Region
chs_region = config.region;
% Save Point ID
spID = config.sp_ID;
%
disp_on = config.print_progress;

%% DEFINE AUX VARIABLES
% No Probability Masses For Extratropical Storms
if strcmp(storm_type, 'XC')
    prob_mass = [];
end

%% PROCESS CHS PEAKS DATASET TO CREATE "storm.Peaks"
if use_peaks == 1
    % Display Progress Step
    if strcmp(storm_type,'XC')
        disp_toggle(disp_on,['Matching CHS extratropical peak waves and water levels....']);
    else
        disp_toggle(disp_on,['Matching CHS tropical peak waves and water levels....']);
    end
    % Pull Storm Data From Parsed H5 Files
    [peaks_data, adcirc_bool,  STWAVE_headers_location, Tp_special] = chs_file_selection(CHS_Data, 'Peaks', storm_type);
    % Format storm Data
    [storm.('Peaks').Default, storm2rm] = chs_peaks_formatter(peaks_data{adcirc_bool},...
        peaks_data{~adcirc_bool}, STWAVE_headers_location, Tp_special); % storm2rm is a storm ID
else
    storm2rm = [];
end

%% PROCESS CHS TIMESERIES DATASET TO CREATE "storm.Timeseries" & PRIORITY DATASETS ("storm.Peaks.WLP" and/or "storm.Peaks.WHP")
if use_timeseries == 1
    % Display Progress Step
    if strcmp(storm_type,'XC')
        disp_toggle(disp_on,['Matching CHS extratropical timeseries waves and water levels....']);
    else
        disp_toggle(disp_on,['Matching CHS tropical timeseries waves and water levels....']);
    end
    % Pull Storm Data From Parsed H5 Files
    [timeseries_data, adcirc_bool_ts,  STWAVE_headers_location_ts, Tp_special_ts] = chs_file_selection(CHS_Data, 'Timeseries', storm_type);
    % Fill Flagged Raw Wave Steps Before Any Interpolation (Timeseries.Default And WLP); No Valid Tp: Bad Storm
    [timeseries_data{~adcirc_bool_ts}, no_tp_storms] = fill_flagged_wave_steps(timeseries_data{~adcirc_bool_ts}, STWAVE_headers_location_ts);
    storm2rm = unique([storm2rm(:); no_tp_storms]);
    % Create ADCIRC-STWAVE TimeSeries Dataset
    [storm.Timeseries.Default, storm2rm] = chs_timeseries_formatter(timeseries_data{adcirc_bool_ts},...
        timeseries_data{~adcirc_bool_ts},...
        storm2rm, STWAVE_headers_location_ts, Tp_special_ts, disp_on);
    % Create Alternate Datasets
    if use_peaks == 1
        % Create Water Level Priority
        if WLP_switch == 1
            [storm.('Peaks').WLP, wlp_storm2rm] = create_priority_dataset(peaks_data{adcirc_bool},...
                timeseries_data{adcirc_bool_ts}, timeseries_data{~adcirc_bool_ts},...
                storm2rm, STWAVE_headers_location_ts, Tp_special_ts, 'wlp', disp_on);
            storm2rm = unique([storm2rm; wlp_storm2rm(:)]);
        end
        % Create Wave Height Priority
        if WHP_switch == 1
            [storm.('Peaks').WHP, whp_storm2rm] = create_priority_dataset(peaks_data{~adcirc_bool}, ...
                timeseries_data{adcirc_bool_ts}, timeseries_data{~adcirc_bool_ts},...
                storm2rm, STWAVE_headers_location, Tp_special, 'whp', disp_on);
            storm2rm = unique([storm2rm; whp_storm2rm(:)]);
        end
    end
end
% Store Invalid Storms
removed_storms.Default = storm2rm;

%% REMOVE FLAGED STORMS
% Each Dataset (Peaks Default/WLP/WHP, Timeseries Default) Drops The Removed Storms By Its Own Storm IDs
for dtype = reshape(fieldnames(storm), 1, [])
    for mtype = reshape(fieldnames(storm.(dtype{1})), 1, [])
        rm_bool = ismember(cell2mat(storm.(dtype{1}).(mtype{1})(:, 1)), removed_storms.Default);
        storm.(dtype{1}).(mtype{1})(rm_bool, :) = [];
    end
end

%% ADJUST STORM DEPENDANT PARAMETERS
% Adjust storm Type Dependant Fields
switch storm_type
    case 'TC'% Tropical Cyclones
        if isempty(prob_mass.TC_Freq)
            % Something Went Wrong In PM Load
            warning('Something went wrong loading probability masses..');
        else
            % Probability Mass Rows By Storm ID (Param Column 1)
            pm_rm = ismember(prob_mass.Param(:, 1), removed_storms.Default);
            prob_mass.TC_Freq(pm_rm, :) = [];
            % Redifine New Frequency Vector
            if ~isempty(storm2rm)
                prob_mass.TC_Freq = prob_mass.TC_Freq*prob_mass.TotalFreq/sum(prob_mass.TC_Freq);
            end
            prob_mass.Param(pm_rm, :) = [];
            %
            prob_mass.smpl1(ismember(prob_mass.smpl1,removed_storms.Default)) = [];
            prob_mass.smpl2(ismember(prob_mass.smpl2,removed_storms.Default)) = [];
            prob_mass.smpl3(ismember(prob_mass.smpl3,removed_storms.Default)) = [];
        end
        % Define Empty Var For Outputs
        XC_Nyrs = [];XC_Nstm = [];
    case 'XC' % Extratropical storms
        if use_peaks == 1
            % Determine Number Of Events
            XC_Nstm = height(peaks_data{adcirc_bool==1});
            % Get Timestamp Vector
            tVector = peaks_data{adcirc_bool==1}.yyyymmddHHMM;
            % Check For NaTs
            hIndx = ~isnat(tVector);
            % Get Event Record Years
            record_years = year(tVector(hIndx));
            % Compute Number Of Years
            XC_Nyrs=max(record_years)-min(record_years)+1;
        else
            % Determine Number Of Events
            XC_Nstm = height(timeseries_data{adcirc_bool_ts==1});
            % Get Timestamp Vector
            tVector = timeseries_data{adcirc_bool_ts==1}.yyyymmddHHMM;
            % Check For NaTs
            hIndx = cellfun(@(x) ~isnat(x), tVector, 'un', false);
            % Get Event Record Years
            for kk = 1:length(hIndx)
                if any(hIndx{kk})
                    record_years{kk} = year(tVector{kk}(hIndx{kk}));
                else
                    record_years{kk} = NaN;
                end
            end
            % Compute Number Of Years
            XC_Nyrs = max(cellfun(@max, record_years), [], "omitnan") - min(cellfun(@min, record_years), [], "omitnan")+1;
        end
end

%% APPLY BIAS CORRECTION
% Applied When The Region's Water Level And Wave Height Bias & Uncertainty Files Exist (chs_dependency_files.m)
chs_files = chs_dependency_files(config.chs_dependencies, chs_region);
bias_tgr = double(chs_files.bias_uncertainty_available);
% Enforce No Bias Correction For XCs
if strcmp(storm_type, 'XC')
    bias_tgr = 0;
end
% Record TC Bias Correction State (Plots Apply The Same Correction To Raw CHS SWL)
if strcmp(storm_type, 'TC')
    config.tc_bias_corrected = bias_tgr;
end
% Apply Bias Correction (If Applicable)
if bias_tgr == 1
    % Determine Structure Fields
    sNames = fieldnames(storm);
    % Define Function
    f_u = @(x) x - config.chs_swl_b_a./abs(config.chs_swl_b_a)./sqrt(1./config.chs_swl_b_a.^2 + 1./(config.chs_swl_b_r .* x).^2); % Bias Correction Formula
    % Adjust SWL Bias
    for ii = 1:length(sNames) % Data Types: Peaks, Timeseries
        % Get Level_2 Fieldnames
        level_2 = fieldnames(storm.(sNames{ii}));
        % Apply Bias Correction
        for kk = 1:length(level_2) % Match Type: Default, WLP, WHP
            for ss = 1:length(storm.(sNames{ii}).(level_2{kk})) % Number Of Storms
                storm.(sNames{ii}).(level_2{kk}){ss, 2}(:, 1) = f_u(storm.(sNames{ii}).(level_2{kk}){ss, 2}(:, 1)); % Apply Bias Correction To SSL (Surge)
            end
        end
    end
end

%% AUX FUNCTION
    function [storm_data, ad_indx, STWAVE_headers_location, Tp_special] = chs_file_selection(CHS_Data, data_type, selected_storm_type)
        % Pull CHS Parsed H5 Files Accordin To Data Type & Storm Type (CHS File Name Rule: chs_file_name_parts.m)
        file_parts = chs_file_name_parts({CHS_Data.Filename});
        file_indx = strcmp({file_parts.data_type}, data_type) &...
            strcmp({file_parts.storm_type}, selected_storm_type);
        % Extract Peaks Files
        storm_data = CHS_Data(file_indx);
        % Find ADCIRC Filename
        ad_indx = logical([file_parts(file_indx).is_adcirc]);
        % Get Headers For Hm0,Tp,wDir
        [STWAVE_headers_location, Tp_special] = chs_wave_model_header_locator(storm_data(~ad_indx));
        % Extract "Strom_Table" Field
        storm_data = cellfun(@(x) x.Table_StormData, {CHS_Data(file_indx).Conv_Data}, 'un', false)';
    end
end




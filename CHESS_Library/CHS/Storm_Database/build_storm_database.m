function [storm, prob_mass, db_info] = build_storm_database(CHS_Data, options)
% build_storm_database  Build the storm database (storm, prob_mass, db_info).
%   [storm, prob_mass, db_info] = build_storm_database(CHS_Data, options)
%
%   Builds the storm database from converted CHS files. The one builder
%   of the library (call_chs_data_formatter) and the GUI storm database
%   wizard (CHSStormDBImportUI.create_storm_database), so both give the
%   same database from the same input. Steps, TC first:
%       1. TC probability masses (chs_probability_mass_loader).
%       2. Per storm type: format, match and screen the CHS files
%          (call_chs_storm_quality_check; TC SWL bias correction with the
%          database bias when the region's bias & uncertainty files
%          exist).
%       3. Per storm type with Peaks and Timeseries: hydrograph peaks
%          replaced by the Peaks file values (chs_timeseries_peak_replacer).
%       4. db_info (storm_db_info 'create').
%   Data types and WLP/WHP datasets are decided per storm type from the
%   storm file slots (chs_storm_file_slots): Peaks / Timeseries when that
%   storm type's slot is complete; WLP / WHP when requested and that
%   storm type has both Peaks and Timeseries. Bias & uncertainty
%   (CHS_Dependencies or manual), the CHS_Dependencies availability
%   decision (which storm types to build), the forcing cache reset, the
%   datum adjustment and the saves stay with the callers.
%
%   Inputs:
%     CHS_Data - converted CHS files (Filename, Conv_Data; folders in
%                Filename are dropped before the file selection),
%                1 x number_of_files struct
%     options  - build settings, struct; fields (all required):
%                  .chs_dependencies - CHS_Dependencies folder, char
%                  .region           - CHS region (e.g. 'CHS-NA'), char
%                  .sp_ID            - ADCIRC savepoint ID, scalar double
%                  .storm_types      - storm types to build ('TC' and/or
%                                      'XC'), cell
%                  .storm_file_slots - storm file slots of the input
%                                      (chs_storm_file_slots slots
%                                      output), table
%                  .create_wlp       - build the Water Level Priority
%                                      dataset (0/1), scalar double
%                  .create_whp       - build the Wave Height Priority
%                                      dataset (0/1), scalar double
%                  .bias_uncertainty - bias & uncertainty and savepoint
%                                      location of the database
%                                      (storm_db_bias_uncertainty output),
%                                      struct; chs_swl_b_a/_b_r drive the
%                                      TC bias correction, sp_lat/sp_lon
%                                      locate the savepoint for the TC
%                                      probability masses
%                  .source_file      - input the database is built from
%                                      (name + extension), char
%                  .print_progress   - print progress to the command
%                                      window (0/1), scalar double
%                  .progress_fcn     - called before each step as
%                                      progress_fcn(fraction, message),
%                                      fraction in [0 1) ([]: none); an
%                                      error raised there stops the build
%                                      (GUI cancel: 'CHESS:importCancelled'),
%                                      function_handle
%   Outputs:
%     storm     - storm database (storm.TC / storm.XC: Peaks, Timeseries,
%                 removed_storms; chs_peaks_formatter row layout), struct
%     prob_mass - TC probability masses (Param, TC_SRR, TC_Freq,
%                 TotalFreq, smpl1, smpl2, smpl3; [] without TC), struct
%     db_info   - storm database details (storm_db_info), struct
%
%   Tier: internal
%
%   See also call_chs_data_formatter, storm_db_info,
%   storm_db_bias_uncertainty, chs_storm_file_slots, convert_chs_zip.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
CHS_Data = strip_chs_data_folders(CHS_Data);
storm_types = reshape(intersect({'TC', 'XC'}, options.storm_types, 'stable'), 1, []);
slots = options.storm_file_slots;
slot_complete = @(storm_type, data_type) any(slots.complete & strcmp(slots.storm_type, storm_type) & strcmp(slots.data_type, data_type));
% Quality Check Settings (call_chs_storm_quality_check.m Reads Only These Fields)
quality_check_config = struct('region', options.region, 'sp_ID', options.sp_ID,...
    'chs_dependencies', options.chs_dependencies, 'print_progress', options.print_progress,...
    'chs_swl_b_a', options.bias_uncertainty.chs_swl_b_a, 'chs_swl_b_r', options.bias_uncertainty.chs_swl_b_r);
storm = struct();
prob_mass = [];
tc_bias_corrected = 0;
Nyrs_XC = [];
Nstm_XC = [];
has_peaks_and_timeseries = false(size(storm_types));

%% FORMAT AND INSPECT CHS STORMS (TC First: Probability Masses), Data Types Per Storm Type
for tt = 1:numel(storm_types)
    storm_type = storm_types{tt};
    has_peaks = slot_complete(storm_type, 'Peaks');
    has_timeseries = slot_complete(storm_type, 'Timeseries');
    has_peaks_and_timeseries(tt) = has_peaks && has_timeseries;
    quality_check_config.use_peaks = +has_peaks;
    quality_check_config.use_timeseries = +has_timeseries;
    quality_check_config.create_wlp = +(has_peaks_and_timeseries(tt) && options.create_wlp == 1);
    quality_check_config.create_whp = +(has_peaks_and_timeseries(tt) && options.create_whp == 1);
    switch storm_type
        case 'TC'
            report_progress(options, 1/9, 'Setting-up TC modeling suite regional statistics');
            [prob_mass.Param, prob_mass.TC_SRR,...
                prob_mass.TC_Freq, prob_mass.TotalFreq,...
                prob_mass.smpl1, prob_mass.smpl2, prob_mass.smpl3] = chs_probability_mass_loader(options.chs_dependencies, options.region, options.sp_ID,...
                [options.bias_uncertainty.sp_lat options.bias_uncertainty.sp_lon]);
            report_progress(options, 2/9, 'Matching TC modeling results (surge+waves)');
            [tc_checked_config, storm.('TC'), storm.('TC').removed_storms,...
                ~, ~, prob_mass] = call_chs_storm_quality_check(quality_check_config, CHS_Data, prob_mass, 'TC');
            tc_bias_corrected = tc_checked_config.tc_bias_corrected;
        case 'XC'
            report_progress(options, 4/9, 'Matching XC modeling results (surge+waves)');
            [~, storm.('XC'), storm.('XC').removed_storms,...
                Nyrs_XC, Nstm_XC, ~] = call_chs_storm_quality_check(quality_check_config, CHS_Data, [], 'XC');
    end
end

%% TIMESERIES PEAK REPLACER: Replace Hydrograph Peak Responses With Peaks Files Responses
if any(has_peaks_and_timeseries)
    report_progress(options, 7/9, 'Adjusting hydrographs peak responses');
    for storm_type = storm_types(has_peaks_and_timeseries)
        storm.(storm_type{1}) = chs_timeseries_peak_replacer(storm.(storm_type{1}));
    end
end

%% STORM DATABASE DETAILS (Bias & Uncertainty, TC Bias Correction, XC Record)
db_info = storm_db_info('create', options.bias_uncertainty, tc_bias_corrected, Nyrs_XC, Nstm_XC, options.source_file);
end

%% LOCAL FUNCTIONS
function report_progress(options, fraction, message)
if ~isempty(options.progress_fcn)
    options.progress_fcn(fraction, message);
end
end

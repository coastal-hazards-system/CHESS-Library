function storm_validation(config, storm)
% storm_validation  Check the layout of the storm variable of a user storm .mat.
%   storm_validation(config, storm)
%
%   Checks the storm variable of a user storm .mat (storm_data input);
%   called by call_input_parser and the GUI storm database wizard. Fields
%   other than XC and TC are ignored. Errors (message only, no error ID)
%   when storm has no XC or TC field, a storm type has no Peaks or
%   Timeseries field, storm.XC lacks Nyrs_XC or Nstm_XC, a dataset is not
%   an N x 2 cell, or the data of its first storm is not 1 x 5 (Peaks) or
%   M x 6 (Timeseries).
%
%   Expected layout: storm.(st_type).(data_type).(match_type)
%     st_type    - 'XC' and/or 'TC'
%     data_type  - 'Peaks' and/or 'Timeseries'
%     match_type - storm matching of the circulation and wave models:
%                    'Default' - peak responses of the circulation (surge)
%                                and wave models (wave height, peak
%                                period, wave direction) regardless of
%                                their phase.
%                    'WLP' - Peaks only: alternate Peaks dataset (Water
%                            Level Priority) built from Peaks and
%                            Timeseries, matched on the peak circulation
%                            model response; the wave model response is
%                            the Timeseries value nearest to that peak's
%                            phase.
%                    'WHP' - Peaks only: alternate Peaks dataset (Wave
%                            Height Priority), matched on the peak wave
%                            model response; the circulation model
%                            response is the Timeseries value nearest to
%                            that peak's phase.
%                  Timeseries supports 'Default' only.
%   Each dataset is an N x 2 cell: column 1 storm ID, column 2 storm
%   data, 1 x 5 [SWL Hm0 Tp wDir datenum] for Peaks, M x 6 [SWL Hm0 Tp
%   wDir datenum dt] for Timeseries. storm.XC also holds Nyrs_XC (XC
%   record length [years]) and Nstm_XC (number of XC storms in the storm
%   suite); call_input_parser moves them to db_info.
%
%   Inputs:
%     config - CHESS configuration, 1x1 struct; use_peaks and
%              use_timeseries are read (no check depends on them)
%     storm  - user storm database (layout above), struct
%   Outputs:
%     none (errors when the layout does not comply)
%
%   Tier: internal
%
%   See also prob_mass_validation, storm_db_check, call_input_parser.

% Define Data Type Pass Flag
pass_cnt = config.use_peaks + config.use_timeseries;
% Get Storm Types On Storm Suite
st_types = fieldnames(storm); % XC, TC
% Check For storm variable contents compliance
if ~any(contains(st_types, {'XC','TC'}))
    error('Error: CHESS only supports "XC" and/or "TC" storm types. Rename fields as such....');
else % Fields Exist
    % Remove Unsupported Fields
    storm = rmfield(storm, st_types(~contains(st_types, {'XC','TC'})));
    % Define Storm Types Again
    st_types = st_types(contains(st_types, {'XC','TC'}));
end
% Loop Across Each Storm Type
for kk = 1:length(st_types)
    % Scan Data Type Fieldnames
    data_types = fieldnames(storm.(st_types{kk})); % Peaks and/or Timeseries
    % Check For Data Type Compliance
    chk = any(contains(data_types, {'Peaks','Timeseries'}));
    % throw Error If Not Met
    if ~chk
        error('Error: Could not find expected data types "Peaks" and/or "Timeseries per user request on config...')
    end
    % Evaluate Storm Type Special Cases
    switch st_types{kk}
        case 'XC'
            % Check For XC Specific Fields
            if ~all(contains({'Nyrs_XC','Nstm_XC'}, data_types))
                error('Error: Could not find expected XC storm additional fields. Make sure to include the record length (Nyrs_XC) and number of XC storms (Nstm_XC) on provided storm suite...');
            end
    end
    % Get Row Indexes
    sindx = find(contains(data_types, {'Peaks','Timeseries'}) == 1);
    % Check For Data Type Content Shapes Compliance
    for ii = min(sindx):max(sindx)
        % Scan Matching Type
        match_types = fieldnames(storm.(st_types{kk}).(data_types{ii}));
        % Loop Across Match Types
        for jj = 1:length(match_types)
            % Make Sure Cell Array Has 2 Colums
            data_shape = size(storm.(st_types{kk}).(data_types{ii}).(match_types{jj}), 2); % N x 2 | col 1: storm ID, col 2: storm data cell
            % Check For Compliance
            if data_shape ~= 2
                error(['Error: Detected wrong data shape for storm.', st_types{kk},...
                    '.', data_types{ii}, '.', match_types{jj},...
                    '. Please ensure data shape is a N x 2 cell array where col 1: storm ID, col 2: storm data cell...']);
            end
            % Verify Shape Of Storm Suite Data (Peaks: 1 x 5 [SWL Hm0 Tp wDir datenum]; Timeseries: M x 6 [SWL Hm0 Tp wDir datenum dt])
            [stm_row, stm_col] = size(storm.(st_types{kk}).(data_types{ii}).(match_types{jj}){1, 2});
            if strcmp(data_types{ii}, 'Peaks')
                if stm_row ~= 1 || stm_col ~= 5
                    error('Error: Storm suite modeling data must comply with expected data shape ( 1 x 5 ) [SWL Hm0 Tp wDir datenum] for "Peaks". ');
                end
            elseif stm_col ~= 6
                error('Error: Storm suite modeling data must comply with expected data shape ( M x 6 ) [SWL Hm0 Tp wDir datenum dt] for "Timeseries". ');
            end
        end
    end
end
end
function storm = storm_validation(config, storm)
% storm_validation  Check the layout of the storm variable of a user storm .mat.
%   storm = storm_validation(config, storm)
%
%   Checks the storm variable of a user storm .mat (storm_data input)
%   and returns it with only the supported fields; called by
%   call_input_parser and the GUI storm database wizard. Fields are kept
%   by exact name (others are dropped, then the shapes are checked):
%     storm      - XC, TC
%     storm.XC   - Peaks, Timeseries, Nyrs_XC, Nstm_XC, removed_storms
%     storm.TC   - Peaks, Timeseries, removed_storms
%     Peaks      - Default, WLP, WHP
%     Timeseries - Default
%   Errors when storm has no XC or TC field
%   (storm_validation:noStormType), a storm type has no Peaks or
%   Timeseries field (storm_validation:noDataType), storm.XC lacks
%   Nyrs_XC or Nstm_XC (storm_validation:missingXcRecord), a data type has
%   no Default dataset (storm_validation:missingDefault), a dataset is not
%   an N x 2 cell (storm_validation:datasetShape), or the data of its
%   first storm is not 1 x 5 for Peaks (storm_validation:peaksShape) or
%   M x 6 for Timeseries (storm_validation:timeseriesShape).
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
%     config - CHESS configuration, 1x1 struct; not read (kept for the
%              call shape shared with prob_mass_validation)
%     storm  - user storm database (layout above), struct
%   Outputs:
%     storm  - storm with only the supported fields above, struct
%
%   Tier: internal
%
%   See also prob_mass_validation, storm_db_check, call_input_parser.

st_types = intersect({'XC', 'TC'}, fieldnames(storm), 'stable');
if isempty(st_types)
    error('storm_validation:noStormType', 'CHESS only supports "XC" and/or "TC" storm types. Rename fields as such.');
end
storm = keep_fields(storm, st_types);
match_whitelist = struct('Peaks', {{'Default', 'WLP', 'WHP'}}, 'Timeseries', {{'Default'}});
for kk = 1:numel(st_types)
    st = st_types{kk};
    type_fields = {'Peaks', 'Timeseries', 'removed_storms'};
    if strcmp(st, 'XC')
        type_fields = [type_fields, {'Nyrs_XC', 'Nstm_XC'}]; %#ok<AGROW>
    end
    storm.(st) = keep_fields(storm.(st), type_fields);
    data_types = intersect({'Peaks', 'Timeseries'}, fieldnames(storm.(st)), 'stable');
    if isempty(data_types)
        error('storm_validation:noDataType', 'Could not find the data types "Peaks" and/or "Timeseries" in storm.%s.', st);
    end
    if strcmp(st, 'XC') && ~all(isfield(storm.XC, {'Nyrs_XC', 'Nstm_XC'}))
        error('storm_validation:missingXcRecord', ['Could not find the XC storm record fields. Include the record length ',...
            '(Nyrs_XC) and number of XC storms (Nstm_XC) in storm.XC.']);
    end
    for ii = 1:numel(data_types)
        dtype = data_types{ii};
        storm.(st).(dtype) = keep_fields(storm.(st).(dtype), match_whitelist.(dtype));
        if ~isfield(storm.(st).(dtype), 'Default')
            error('storm_validation:missingDefault', 'storm.%s.%s has no Default dataset.', st, dtype);
        end
        match_types = fieldnames(storm.(st).(dtype));
        for jj = 1:numel(match_types)
            data = storm.(st).(dtype).(match_types{jj});
            if ~iscell(data) || size(data, 2) ~= 2
                error('storm_validation:datasetShape', ['Wrong data shape for storm.%s.%s.%s. Use an N x 2 cell array ',...
                    '(col 1: storm ID, col 2: storm data).'], st, dtype, match_types{jj});
            end
            [stm_row, stm_col] = size(data{1, 2});
            if strcmp(dtype, 'Peaks')
                if stm_row ~= 1 || stm_col ~= 5
                    error('storm_validation:peaksShape', 'Storm data must be 1 x 5 [SWL Hm0 Tp wDir datenum] for "Peaks" (storm.%s.Peaks.%s).', st, match_types{jj});
                end
            elseif stm_col ~= 6
                error('storm_validation:timeseriesShape', 'Storm data must be M x 6 [SWL Hm0 Tp wDir datenum dt] for "Timeseries" (storm.%s.Timeseries.%s).', st, match_types{jj});
            end
        end
    end
end
end

%% LOCAL FUNCTIONS
function s = keep_fields(s, names)
s = rmfield(s, setdiff(fieldnames(s), names));
end

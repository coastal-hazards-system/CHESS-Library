function parts = chs_file_name_parts(file_names)
% chs_file_name_parts  Split CHS file names into their name tokens.
%   parts = chs_file_name_parts(file_names)
%
%   The one rule for reading a CHS file name. CHS file names read
%       <region>_<storm flag>_<simulation>_<post type>_SP<id>_<model>_<data type>.h5
%   e.g. CHS-NA_XH_SimB_Post0_SP05572_ADCIRC01_Peaks.h5,
%        CHS-NA_TS_SimB_Post0_SP024_STWAVE02_Timeseries.h5,
%        CHS-GLMH_XH_SimBslc0ice1_Post0_SP02994_SWAN01_Timeseries.h5.
%   Tokens are split on '_' and matched exactly (case-sensitive); folders
%   are allowed, only the name is read. The storm flag (token 2) varies
%   between CHS files: extratropical files use XC or XH, tropical files
%   TC or TS. STORM_FLAG_ALIASES (top of the code) maps each flag to the
%   storm type CHESS uses ('XC'/'TC'): add a new flag variant there only.
%   The data type is the last token and the model the second-to-last
%   token (e.g. ADCIRC01, STWAVE02, SWAN01); a water level file is one
%   whose model starts with ADCIRC. A storm file has a .h5 extension (any
%   case) and data type Peaks or Timeseries (HC/AEP/AEF files and other
%   extensions are not storm files). Used by chs_storm_file_names,
%   chs_study_identity, chs_storm_file_slots, chs_data_attributes,
%   call_chs_storm_quality_check, chs_h5_converter, call_input_parser,
%   CHESSPlotsBase and the GUI storm database wizard, so they cannot
%   disagree.
%
%   Inputs:
%     file_names - CHS file name(s), folders allowed, char, string or cell
%   Outputs:
%     parts - name parts, one element per file name (size(file_names),
%             1x1 for a char), struct array; fields:
%               region        - token 1 (e.g. 'CHS-NA'), char
%               storm_flag    - token 2 as written ('XH', 'TS', ...; ''
%                               if missing), char
%               storm_type    - 'XC' (XC/XH), 'TC' (TC/TS), '' if
%                               unrecognized, char
%               simulation    - token 3 (e.g. 'SimB'; '' if missing), char
%               post_type     - token 4 (e.g. 'Post0'; '' if missing), char
%               save_point_id - token 5 as written (e.g. 'SP05572'; '' if
%                               missing; chs_study_identity checks it),
%                               char
%               model         - second-to-last token (e.g. 'ADCIRC01'; ''
%                               if missing), char
%               data_type     - last token, as written (e.g. 'Peaks'), char
%               is_adcirc     - water level (ADCIRC) file: model starts
%                               with 'ADCIRC', logical
%               is_storm_file - .h5 and data type Peaks or Timeseries,
%                               logical
%
%   Tier: internal
%
%   See also chs_storm_file_names, chs_storm_file_slots,
%   storm_mat_name_parts.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
STORM_FLAG_ALIASES = {'XC', {'XC', 'XH'};...
                      'TC', {'TC', 'TS'}};
STORM_DATA_TYPES = {'Peaks', 'Timeseries'};

if ischar(file_names) || isstring(file_names)
    file_names = cellstr(file_names);
end
parts = repmat(struct('region', '', 'storm_flag', '', 'storm_type', '', 'simulation', '', 'post_type', '',...
    'save_point_id', '', 'model', '', 'data_type', '', 'is_adcirc', false, 'is_storm_file', false), size(file_names));
for ff = 1:numel(file_names)
    [~, name, extension] = fileparts(file_names{ff});
    tokens = strsplit(name, '_');
    parts(ff).region = tokens{1};
    parts(ff).data_type = tokens{end};
    if numel(tokens) >= 2
        parts(ff).storm_flag = tokens{2};
        parts(ff).model = tokens{end-1};
    end
    if numel(tokens) >= 5
        parts(ff).simulation = tokens{3};
        parts(ff).post_type = tokens{4};
        parts(ff).save_point_id = tokens{5};
    end
    for aa = 1:size(STORM_FLAG_ALIASES, 1)
        if ismember(parts(ff).storm_flag, STORM_FLAG_ALIASES{aa, 2})
            parts(ff).storm_type = STORM_FLAG_ALIASES{aa, 1};
        end
    end
    parts(ff).is_adcirc = startsWith(parts(ff).model, 'ADCIRC');
    parts(ff).is_storm_file = strcmpi(extension, '.h5') && ismember(parts(ff).data_type, STORM_DATA_TYPES);
end
end

function [study, errors] = chs_study_identity(file_names)
%{
    %% DESCRIPTION
        CHS study identity of the storm files of an input, by file name only
        (called by chs_storm_file_slots.m, before any unzip or .h5
        conversion). CHS file names read
        <region>_<storm type>_<simulation>_<post type>_SP<id>_<model>_<data type>
        (e.g. CHS-NA_XH_SimB_Post0_SP05572_ADCIRC01_Peaks.h5). Only storm
        files (chs_storm_file_names.m: .h5, data type Peaks or Timeseries)
        are checked; HC/AEF and other files are ignored. Errors (each naming
        the offending values and files):
            - a file name given more than once (case-insensitive, e.g. the
              same file in two zip subfolders);
            - a name without a save point token (token 5, SP<id>);
            - more than one water level (ADCIRC) save point or more than one
              wave save point;
            - more than one CHS region (token 1, e.g. CHS-NA), simulation
              (token 3, e.g. SimB) or post type (token 4, e.g. Post0).

    %% INPUTS
        file_names: .h5 file names (folders allowed, only the name is read). | cell

    %% OUTPUTS
        study: Study identity of the storm files. | struct
               Fields: region, simulation, post_type ('' unless unique),
               sp_ID (ADCIRC save point), sp_ID_wave (wave save point) ([]
               unless unique).
        errors: Identity errors ({} when the input passes). | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
errors = {};
study = struct('region', '', 'simulation', '', 'post_type', '', 'sp_ID', [], 'sp_ID_wave', []);

%% STORM FILE NAMES
[~, names, exts] = cellfun(@fileparts, chs_storm_file_names(file_names(:)'), 'un', false);
names = strcat(names, exts);

%% DUPLICATE FILE NAMES
[~, first_idx, name_idx] = unique(lower(names), 'stable');
name_count = accumarray(name_idx(:), 1);
for dd = find(name_count > 1)'
    errors{end+1} = sprintf('%s is in the input %d times (e.g. in more than one zip subfolder): keep one copy',...
        names{first_idx(dd)}, name_count(dd)); %#ok<AGROW>
end
names = names(first_idx);

%% NAME TOKENS
region = cell(1, 0);
simulation = cell(1, 0);
post_type = cell(1, 0);
sp_token = cell(1, 0);
is_wl = false(1, 0);
valid = cell(1, 0);
for ff = 1:numel(names)
    [~, fname] = fileparts(names{ff});
    tokens = strsplit(fname, '_');
    if numel(tokens) < 5 || ~startsWith(tokens{5}, 'SP') || isnan(str2double(tokens{5}(3:end)))
        errors{end+1} = sprintf('%s: name token 5 must be the save point (SP<id>), expected <region>_<storm type>_<simulation>_<post type>_SP<id>_<model>_<data type>',...
            names{ff}); %#ok<AGROW>
        continue
    end
    valid{end+1} = names{ff}; %#ok<AGROW>
    region{end+1} = tokens{1}; %#ok<AGROW>
    simulation{end+1} = tokens{3}; %#ok<AGROW>
    post_type{end+1} = tokens{4}; %#ok<AGROW>
    sp_token{end+1} = tokens{5}; %#ok<AGROW>
    is_wl(end+1) = contains(fname, 'ADCIRC'); %#ok<AGROW>
end

%% ONE SAVE POINT PAIR, ONE REGION, ONE SIMULATION, ONE POST TYPE
[errors, wl_sp] = single_value(errors, sp_token(is_wl), valid(is_wl), 'water level (ADCIRC) save point');
[errors, wv_sp] = single_value(errors, sp_token(~is_wl), valid(~is_wl), 'wave save point');
[errors, study.region] = single_value(errors, region, valid, 'CHS region (name token 1)');
[errors, study.simulation] = single_value(errors, simulation, valid, 'simulation (name token 3)');
[errors, study.post_type] = single_value(errors, post_type, valid, 'post type (name token 4)');
if ~isempty(wl_sp)
    study.sp_ID = str2double(wl_sp(3:end));
end
if ~isempty(wv_sp)
    study.sp_ID_wave = str2double(wv_sp(3:end));
end
end

%% AUX FUNCTION: ONE VALUE ACROSS THE FILES (ERROR NAMING EACH VALUE AND ITS FILES)
function [errors, value] = single_value(errors, values, files, label)
value = '';
[vals, ~, val_idx] = unique(values, 'stable');
if isscalar(vals)
    value = vals{1};
elseif numel(vals) > 1
    parts = cell(1, numel(vals));
    for vv = 1:numel(vals)
        parts{vv} = sprintf('%s (%s)', vals{vv}, strjoin(files(val_idx == vv), ', '));
    end
    errors{end+1} = sprintf('more than one %s, found %s', label, strjoin(parts, ' | '));
end
end

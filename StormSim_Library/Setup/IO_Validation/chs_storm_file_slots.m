function [slots, errors, study] = chs_storm_file_slots(file_names, request)
%{
    %% DESCRIPTION
        CHS storm file check, by file name only (run it before any unzip or
        .h5 conversion). The study identity is checked first
        (chs_study_identity.m: a file name given twice, more than one
        ADCIRC or wave save point, simulation or post type are errors).
        Every CHS storm file (chs_storm_file_names.m: .h5, data type Peaks
        or Timeseries; other files such as HC/AEF files are ignored) goes
        to a slot: storm type (name token 2: XH/XC -> XC, TS/TC -> TC) x
        data type (Peaks/Timeseries). A slot is either empty or holds
        exactly one water level (ADCIRC) file and one wave (STWAVE/SWAN/WAM)
        file: a half pair or a duplicate is an error naming the slot and its
        files. When the slots are valid and a request is given, the request
        is checked against the complete slots:
            storm_sampling: XC/TC need that storm type, CC needs both.
            use_peaks / use_timeseries: Peaks / Timeseries of every requested storm type.
            create_wlp / create_whp: Peaks and Timeseries of every requested storm type.

    %% INPUTS
        file_names: .h5 file names (folders allowed, only the name is read). | cell
        request: Request to check ([] = slots only). Fields: | struct
                 storm_sampling ('XC','TC','CC'), use_peaks, use_timeseries,
                 create_wlp, create_whp (0/1).

    %% OUTPUTS
        slots: One row per slot (XC Peaks, XC Timeseries, TC Peaks, TC Timeseries). | table
               Variables: storm_type, data_type, water_level (file names),
               wave (file names), complete (one water level + one wave file).
        errors: Identity and slot errors, else request errors ({} when the input passes). | cell
        study: Study identity (region, simulation, post_type, sp_ID, sp_ID_wave), | struct
               from chs_study_identity.m.

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if nargin < 2
    request = [];
end
storm_type = {'XC'; 'XC'; 'TC'; 'TC'};
data_type = {'Peaks'; 'Timeseries'; 'Peaks'; 'Timeseries'};
water_level = repmat({cell(1, 0)}, 4, 1);
wave = repmat({cell(1, 0)}, 4, 1);
[study, errors] = chs_study_identity(file_names);

%% SORT STORM FILES INTO SLOTS (A Repeated File Name Counts Once: chs_study_identity.m Reports It)
[~, fnames, fexts] = cellfun(@fileparts, chs_storm_file_names(file_names), 'un', false);
fnames = strcat(fnames, fexts);
[~, keep] = unique(lower(fnames), 'stable');
for ff = keep(:)'
    [~, fname] = fileparts(fnames{ff});
    fname_ext = fnames{ff};
    tokens = strsplit(fname, '_');
    if numel(tokens) < 2 || ~ismember(tokens{2}, {'XH', 'XC', 'TS', 'TC'})
        errors{end+1} = sprintf('%s: unknown storm type (name token 2 must be XH/XC or TS/TC)', fname_ext); %#ok<AGROW>
        continue
    end
    st = strrep(strrep(tokens{2}, 'XH', 'XC'), 'TS', 'TC');
    row = find(strcmp(storm_type, st) & strcmp(data_type, tokens{end}));
    if contains(fname, 'ADCIRC')
        water_level{row}{end+1} = fname_ext;
    else
        wave{row}{end+1} = fname_ext;
    end
end
n_wl = cellfun(@numel, water_level);
n_wv = cellfun(@numel, wave);
complete = n_wl == 1 & n_wv == 1;
slots = table(storm_type, data_type, water_level, wave, complete);
for rr = find(~complete & (n_wl + n_wv) > 0)'
    errors{end+1} = sprintf('%s %s needs exactly one water level (ADCIRC) file and one wave (STWAVE/SWAN) file, found water level: %s | wave: %s',...
        storm_type{rr}, data_type{rr}, file_list(water_level{rr}), file_list(wave{rr})); %#ok<AGROW>
end
if ~isempty(errors) || isempty(request)
    return
end

%% CHECK THE REQUEST AGAINST THE COMPLETE SLOTS
if strcmp(request.storm_sampling, 'CC')
    req_types = {'XC', 'TC'};
else
    req_types = {request.storm_sampling};
end
switches = {'use_peaks', {'Peaks'}; 'use_timeseries', {'Timeseries'};...
    'create_wlp', {'Peaks', 'Timeseries'}; 'create_whp', {'Peaks', 'Timeseries'}};
for tt = 1:numel(req_types)
    has_type = complete(strcmp(storm_type, req_types{tt}));
    if ~any(has_type)
        errors{end+1} = sprintf('%s storm sampling needs %s storms: %s has no Peaks or Timeseries files in this input',...
            request.storm_sampling, req_types{tt}, req_types{tt}); %#ok<AGROW>
        continue
    end
    for dd = {'Peaks', 'Timeseries'}
        if complete(strcmp(storm_type, req_types{tt}) & strcmp(data_type, dd{1}))
            continue
        end
        needed_by = {};
        for ss = 1:size(switches, 1)
            if request.(switches{ss, 1}) == 1 && ismember(dd{1}, switches{ss, 2})
                needed_by{end+1} = sprintf('%s = 1', switches{ss, 1}); %#ok<AGROW>
            end
        end
        if ~isempty(needed_by)
            errors{end+1} = sprintf('%s has no %s in this input (needed by %s)', req_types{tt}, dd{1}, strjoin(needed_by, ', ')); %#ok<AGROW>
        end
    end
end
end

%% AUX FUNCTION: FILE NAMES FOR MESSAGES
function str = file_list(names)
if isempty(names)
    str = 'none';
else
    str = strjoin(names, ', ');
end
end

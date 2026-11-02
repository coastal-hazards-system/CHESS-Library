function parts = storm_mat_name_parts(file)
%{
    %% DESCRIPTION
        The one rule for reading a storm .mat file name (storm_data input:
        a user storm database, any naming). The name without folders and
        extension is split on '_'; the save point is the first token that
        reads SP<digits> (e.g. SP05572) and the CHS region the first token
        that starts with 'CHS-' (e.g. CHS-NA). A name without such a token
        gives an empty value; each caller sets its own default. Used by
        call_input_parser.m and the GUI storm database wizard
        (CHSStormDBImportUI.m), so they cannot disagree. CHS .h5 names
        are read by chs_file_name_parts.m.

    %% INPUTS
        file: Storm .mat file name (folders allowed). | char/string

    %% OUTPUTS
        parts: Name parts. | struct
               sp_ID: Save point id ([] when no token reads SP<digits>). | double
               region: CHS region ('' when no token starts with 'CHS-'). | char

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
[~, name] = fileparts(char(file));
tokens = strsplit(name, '_');
parts = struct('sp_ID', [], 'region', '');
sp_token = tokens(~cellfun(@isempty, regexp(tokens, '^SP\d+$', 'once')));
if ~isempty(sp_token)
    parts.sp_ID = str2double(sp_token{1}(3:end));
end
region = tokens(startsWith(tokens, 'CHS-'));
if ~isempty(region)
    parts.region = region{1};
end
end

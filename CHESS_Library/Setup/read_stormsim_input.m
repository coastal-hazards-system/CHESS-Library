function [sections, rows] = read_stormsim_input(file)
%{
    %% DESCRIPTION
        Reads a StormSim input file or PSE template (.xlsx or .csv), shared
        by the library (call_input_parser.m) and the GUI
        (stormsimProject.get_library_template). Layout independent: every
        'Model Variable Symbol' header cell (any row, any column; sections
        may sit side by side in several column blocks, in any order) starts
        a section whose title is the cell above the header. Section rows
        are the rows below the header in that column block: symbol (header
        column), description, units (next two columns) and value (the
        'Value' header column of that section, else 3 columns right of the
        symbol). A section ends at the next section title (the row above
        the next header in the same column) or at the end of the data.
        Blank rows (no symbol) are skipped, never treated as terminators,
        so a .csv (blank lines kept) or a sheet with blank rows added or
        removed reads the same. Missing cells become ''.

    %% INPUTS
        file: StormSim input file / PSE template (.xlsx or .csv).      | char

    %% OUTPUTS
        sections: One field per known section (general, forcing,        | struct
                  geometry, properties, responses, mcs, csr, pros), each
                  an N x 4 cell {symbol, description, units, value},
                  matched by title keyword (contains(lower(title), key),
                  first key in that order; a later section with the same
                  key replaces an earlier one). Sections with other
                  titles give no field but still contribute to rows.
        rows: Rows of every section (header order: column-major), N x 4. | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
[~, ~, ext] = fileparts(file);
if strcmpi(ext, '.csv')
    raw = readcell(file, 'FileType', 'text', 'Delimiter', ',', 'EmptyLineRule', 'read');
else
    raw = readcell(file);
end
keys = {'general', 'forcing', 'geometry', 'properties', 'responses', 'mcs', 'csr', 'pros'};
sections = cell2struct(repmat({cell(0, 4)}, numel(keys), 1), keys, 1);
rows = cell(0, 4);
is_txt = cellfun(@(x) (ischar(x) || isstring(x)) && ~isempty(strtrim(char(x))), raw);
is_hdr = false(size(raw));
is_val = false(size(raw));
is_hdr(is_txt) = strcmp(strtrim(cellfun(@char, raw(is_txt), 'un', false)), 'Model Variable Symbol');
is_val(is_txt) = strcmp(strtrim(cellfun(@char, raw(is_txt), 'un', false)), 'Value');
[hdr_r, hdr_c] = find(is_hdr);
for kk = 1:numel(hdr_r)
    r = hdr_r(kk);
    c = hdr_c(kk);
    % Value Column: First 'Value' Header Right Of The Symbol Header On The Header Row
    v = find(is_val(r, c+1:end), 1) + c;
    if isempty(v)
        v = c + 3;
    end
    % Section End: Row Above The Next Section Title In This Column, Else End Of Data
    next_hdr = find(is_hdr(r+1:end, c), 1) + r;
    last_row = size(raw, 1);
    if ~isempty(next_hdr)
        last_row = next_hdr - 2;
    end
    keep = find(is_txt(r+1:last_row, c)) + r;
    sec = [raw(keep, c:c+2), raw(keep, v)];
    sec(cellfun(@(x) isa(x, 'missing'), sec)) = {''};
    rows = [rows; sec]; %#ok<AGROW>
    % Known Section By Title Keyword
    title_str = '';
    if r > 1 && is_txt(r-1, c)
        title_str = lower(char(raw{r-1, c}));
    end
    key = keys(cellfun(@(x) contains(title_str, x), keys));
    if ~isempty(key)
        sections.(key{1}) = sec;
    end
end
end

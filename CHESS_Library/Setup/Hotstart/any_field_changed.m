function [changed, changed_field] = any_field_changed(a, b, field_names)
% any_field_changed  True if any named field differs between two structs.
%   [changed, changed_field] = any_field_changed(a, b, field_names) compares
%   the named fields of two structs with isequaln and returns the first
%   one that differs.
%
%   Generic struct-field comparator with no domain knowledge of what the
%   fields mean. A field present in only one of the two structs counts as
%   not changed (not an error), so a freshly parsed config can be compared
%   with an older cached config that predates the field. NaN values compare
%   equal (isequaln): a NaN field (e.g. sp_lat/sp_lon when the CHS file has
%   no savepoint coordinates, blank input table cells) that is NaN in both
%   structs counts as unchanged.
%
%   Inputs:
%     a, b        - structs to compare, 1x1 struct
%     field_names - field names to check, in order, cellstr
%   Outputs:
%     changed       - true if a named field is present in both structs and
%                     its value differs (isequaln), false otherwise, logical
%     changed_field - name of the first field found to differ ('' when
%                     changed is false), char
%
%   Tier: internal
%
%   See also hotstart_level, hotstart_dependency_fields.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
changed = false;
changed_field = '';
for kk = 1:numel(field_names)
    fld = field_names{kk};
    if isfield(a, fld) && isfield(b, fld) && ~isequaln(a.(fld), b.(fld))
        changed = true;
        changed_field = fld;
        return
    end
end
end

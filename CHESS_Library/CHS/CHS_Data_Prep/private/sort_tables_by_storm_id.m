function varargout = sort_tables_by_storm_id(varargin)
% sort_tables_by_storm_id  Sort CHS storm tables by numeric Storm ID and check they pair.
%   [table_1, table_2, ...] = sort_tables_by_storm_id(table_1, table_2, ...)
%
%   Sorts each converted CHS table (chs_h5_converter Table_StormData) by
%   str2double of its 'Storm ID' column (text in the converted files, so
%   a text sort would put '10' before '9'), then checks that every table
%   holds the same storm IDs: the CHS formatters pair the ADCIRC and wave
%   model tables by row. Errors (sort_tables_by_storm_id:stormIdMismatch)
%   when the ID lists differ.
%
%   Inputs:
%     table_1, table_2, ... - converted CHS tables with a 'Storm ID'
%                             column (text IDs), table
%   Outputs:
%     table_1, table_2, ... - the input tables sorted by numeric Storm ID,
%                             table
%
%   Tier: internal
%
%   See also chs_timeseries_formatter, chs_peaks_formatter,
%   create_priority_dataset.

varargout = varargin;
ids = cell(1, nargin);
for kk = 1:nargin
    ids{kk} = str2double(varargin{kk}.("Storm ID"));
    [ids{kk}, order] = sort(ids{kk}(:));
    varargout{kk} = varargin{kk}(order, :);
end
for kk = 2:nargin
    if ~isequaln(ids{kk}, ids{1})
        error('sort_tables_by_storm_id:stormIdMismatch', ['CHS storm tables hold different storm IDs (%d vs %d storms; ',...
            '%d IDs not in both); the ADCIRC and wave model files are paired by storm ID.'],...
            numel(ids{1}), numel(ids{kk}), numel(setxor(ids{1}, ids{kk})));
    end
end
end

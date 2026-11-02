function [data, no_data] = parse_noaa_csv(reply_text, value_name)
%{
    %% DESCRIPTION
        Parses a csv reply of the NOAA CO-OPS data API (format=csv,
        time_zone=gmt) into a table. Recognized layouts (by header):
            'Date Time, Water Level, Sigma, O or I (for verified), F, R, L,
                Quality': 6-minute water_level (8 columns).
            'Date Time, Water Level, Sigma, I, L': hourly_height.
            'Date Time, Water Level,TY, I, L': high_low (Type column kept).
            'Date Time, Water Level, I, L': daily_mean.
            'Year, Month, Highest, MHHW, MHW, MSL, ...': monthly_mean;
                DateTime = first of the month, value = MSL column (the
                monthly mean water level on the requested datum).
            'Date Time, Prediction[, Type]': predictions (Type for
                hilo/hi/lo).
        The value is always the 2nd column of the 'Date Time' layouts; empty
        values become NaN.

        NOAA replies:
            "No data" (a data line containing "No data was found", e.g.
                "Error: No data was found. This product may not be offered
                at this station at the requested time.", or a header with no
                rows): an empty table with the layout columns and
                no_data = true. This is how callers tell "no data" from a
                failure: no_data is true only for these replies, and every
                other NOAA error raises.
            Any other error: error noaa:requestFailed carrying NOAA's message.
                Covers a header followed by 'Error: ...', 'No Predictions
                data was found. Please make sure the Datum input is valid.',
                a blank line followed by 'Wrong Date ... Range Limit
                Exceeded ...', 'There is no MSL for the station',
                'Great Lakes stations don't have Predictions data.', an empty
                reply and any reply without a recognized header.

    %% INPUTS
        reply_text: Raw reply text (noaa_web_request.m). | char/string
        value_name: Name of the value column (e.g. 'WaterLevel',
            'Prediction'). | char

    %% OUTPUTS
        data: Table with columns | table
            DateTime: Time stamp (TimeZone 'UTC'). | datetime
            <value_name>: Value [m] (NaN where NOAA left it empty). | double
            Type: (high_low and hilo/hi/lo predictions only) Tide type
                (e.g. 'H', 'HH', 'L', 'LL'). | string
        no_data: true when NOAA replied that no data was found. | logical

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
reply_lines = strtrim(regexp(char(reply_text), '\r?\n', 'split'));
reply_lines = reply_lines(~cellfun(@isempty, reply_lines));
if isempty(reply_lines)
    error('noaa:requestFailed', 'NOAA CO-OPS returned an empty reply.');
end

header = strtrim(strsplit(reply_lines{1}, ','));
is_date_time_layout = strcmp(header{1}, 'Date Time') && numel(header) >= 2;
is_monthly_layout = numel(header) >= 2 && strcmp(header{1}, 'Year') && strcmp(header{2}, 'Month');
if ~is_date_time_layout && ~is_monthly_layout
    error('noaa:requestFailed', 'NOAA CO-OPS returned an error: %s', strjoin(reply_lines, ' '));
end
type_column = find(ismember(header, {'TY', 'Type'}), 1);
has_type = is_date_time_layout && ~isempty(type_column);

% Empty Table With The Layout Columns
data = table(datetime.empty(0, 1), zeros(0, 1), 'VariableNames', {'DateTime', value_name});
data.DateTime.TimeZone = 'UTC';
if has_type
    data.Type = strings(0, 1);
end

% NOAA Messages After The Header
data_lines = reply_lines(2:end);
message_lines = cellfun(@(line) isempty(regexp(line, '^\d', 'once')), data_lines);
if any(message_lines)
    noaa_message = strjoin(data_lines(message_lines), ' ');
    if contains(lower(noaa_message), 'no data was found')
        no_data = true;
        return
    end
    error('noaa:requestFailed', 'NOAA CO-OPS returned an error: %s', noaa_message);
end
no_data = isempty(data_lines);
if no_data
    return
end

data_block = strjoin(data_lines, newline);
if is_monthly_layout
    msl_column = find(strcmp(header, 'MSL'), 1);
    if isempty(msl_column)
        error('noaa:requestFailed', 'NOAA CO-OPS monthly mean reply has no MSL column: %s', reply_lines{1});
    end
    columns = textscan(data_block, repmat('%f', 1, numel(header)), 'Delimiter', ',',...
        'EmptyValue', NaN, 'CollectOutput', true);
    values = columns{1};
    date_time = datetime(values(:, 1), values(:, 2), 1, 'TimeZone', 'UTC');
    data = table(date_time, values(:, msl_column), 'VariableNames', {'DateTime', value_name});
    return
end

% Date Time Layouts: Text Columns Read Up To The Next Comma
column_formats = repmat({'%*s'}, 1, numel(header));
column_formats{1} = '%s';
column_formats{2} = '%f';
if has_type
    column_formats{type_column} = '%s';
end
columns = textscan(data_block, [column_formats{:}], 'Delimiter', ',', 'Whitespace', '',...
    'EmptyValue', NaN);
date_time = datetime(columns{1}, 'InputFormat', 'yyyy-MM-dd HH:mm', 'TimeZone', 'UTC');
data = table(date_time, columns{2}, 'VariableNames', {'DateTime', value_name});
if has_type
    data.Type = strtrim(string(columns{3}));
end
end

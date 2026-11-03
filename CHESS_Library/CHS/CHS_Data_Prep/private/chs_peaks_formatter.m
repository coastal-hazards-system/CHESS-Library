function [Storm, storm2rm] = chs_peaks_formatter(swl_peaks_table, hm0_peaks_table, STWAVE_headers_location, Tp_special)
% chs_peaks_formatter  Match ADCIRC and wave model Peaks per storm.
%   [Storm, storm2rm] = chs_peaks_formatter(swl_peaks_table,
%       hm0_peaks_table, STWAVE_headers_location, Tp_special)
%
%   Builds the Peaks.Default dataset of one storm type from the converted
%   CHS Peaks tables (chs_h5_converter). Both tables are sorted by Storm
%   ID and paired by row. A flagged SWL (< -90) becomes NaN; a flagged
%   wave value (Hm0, Tp or wave dir < -90 or 0) makes Hm0, Tp and wave dir
%   NaN. The storms with a NaN SWL, Hm0, Tp or wave dir are listed in
%   storm2rm (kept in Storm). A missing peak time gives a NaN
%   peak_datenum. Tp_special = 1 gives Tp = 1.2 * Tm.
%
%   Inputs:
%     swl_peaks_table         - converted ADCIRC (water level) Peaks table
%                               (Storm ID, yyyymmddHHMM, Water
%                               Elevation), table
%     hm0_peaks_table         - converted wave model (STWAVE, SWAN or WAM)
%                               Peaks table (Storm ID and the columns
%                               named in STWAVE_headers_location), table
%     STWAVE_headers_location - wave model column names (fields Hm0, Tp,
%                               wDir; chs_wave_model_header_locator),
%                               struct
%     Tp_special              - 1 when the wave file gives the mean period
%                               Tm instead of Tp, else 0, double
%   Outputs:
%     Storm    - Peaks dataset, number_of_storms x 2 cell {storm ID, 1x5
%                [SWL Hm0 Tp wave_dir peak_datenum]}
%     storm2rm - IDs of the storms with NaN values, column double
%
%   Tier: internal
%
%   See also call_chs_storm_quality_check, chs_wave_model_header_locator,
%   chs_timeseries_formatter, chs_h5_converter.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% INITIALIZE VARIABLES
% Initialize Storm Matrix
Storm = zeros(height(swl_peaks_table),5);

%% STORM SURGE (ADCIRC) 
% Get Storm Data Table
swl_peaks_table = sortrows(swl_peaks_table,'Storm ID','ascend');
% Extract Storm ID From ADCIRC Table
stm_id = num2cell(str2double(swl_peaks_table.("Storm ID")));
% Extract Water Level From ADyCIRC Table
Storm(:,1) = swl_peaks_table.("Water Elevation");
% Assign NaN's If Needed
Storm(Storm(:,1)<-90,1) = NaN(1,1);

%% WAVES (STWAVE, SWAN, WAM)
% Sort Data Table
hm0_peaks_table = sortrows(hm0_peaks_table,'Storm ID','ascend');
%%%%%% Hm0 %%%%%%%
% Extract Hm0 Peak Values From Data Table
Storm(:,2) = hm0_peaks_table.(STWAVE_headers_location.Hm0);
%%%%%% Tp %%%%%%
% Extract Peak Period From STWAVE Tabley
Storm(:,3) = hm0_peaks_table.(STWAVE_headers_location.Tp);
% Convert From Tm to Tp (Special Case)
if Tp_special == 1
    % Convert Tm to Tp (Lake Ontario Case)
    Storm(:,3) = Storm(:,3)*1.2;  % Remove This For Release, Need to inform user
end
%%%%%% Wave Direction %%%%%%
% Extract Wave Direction From STWAVE Table
Storm(:,4) = hm0_peaks_table.(STWAVE_headers_location.wDir);
% Assign NaN's If Needed
Storm(sum(Storm(:,2:4)<-90,2)>=1,2:4) = NaN(1,1);
Storm(sum(Storm(:,2:4)==0,2)>=1,2:4) = NaN(1,1);
% Check For NaT
nan_rows = isnat(swl_peaks_table.("yyyymmddHHMM"));
% Assign NaN
Storm(nan_rows,5) = NaN;
Storm(~nan_rows,5) = datenum(swl_peaks_table.("yyyymmddHHMM")(~nan_rows));
% Find NaN's In "Default" Dataset
storm2rm = cell2mat(stm_id(unique([find(isnan(Storm(:,1)));find(isnan(Storm(:,2)));...
    find(isnan(Storm(:,3)));find(isnan(Storm(:,4)))])));
% Append Data
Storm = [stm_id, num2cell(Storm, 2)];
end

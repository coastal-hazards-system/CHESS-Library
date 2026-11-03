function [STWAVE_headers_location,Tp_special] = chs_wave_model_header_locator(STWAVE)
% chs_wave_model_header_locator  Wave file column names of Hm0, Tp and wave dir.
%   [STWAVE_headers_location, Tp_special] =
%       chs_wave_model_header_locator(STWAVE)
%
%   Finds the column names of Hm0, Tp and the mean wave direction in a
%   converted CHS wave model file (STWAVE, WAM and SWAN name them
%   differently), and flags a file that gives the mean period Tm instead
%   of Tp. Hm0: 'Zero Moment Wave Height', 'Significant Wave Height' or
%   'Significant Wave Height Total Sea'. Tp: 'Peak Spectral Wave Period
%   Total Sea', 'Peak Period', 'Smoothed Peak Period' or 'Peak Wave
%   Period', else 'Mean Wave Period' (Tm, Tp_special = 1). Wave direction:
%   'Mean Wave Direction Total Sea' or 'Mean Wave Direction'. Errors
%   'Hm0 not found.', 'Tp not found.' or 'Mean Wave Direction not found.'
%   (no error ID) when none of the names is present. The file comes from
%   chs_h5_converter or convert_chs_zip.
%
%   Inputs:
%     STWAVE - converted CHS wave model file (Filename, Conv_Data;
%              Conv_Data.headers holds the column names), 1x1 struct
%   Outputs:
%     STWAVE_headers_location - column names, struct; fields Hm0, Tp,
%                               wDir (char)
%     Tp_special              - 1 when the file gives Tm instead of Tp,
%                               else 0, double
%
%   Tier: internal
%
%   See also call_chs_storm_quality_check, chs_peaks_formatter,
%   chs_timeseries_formatter, chs_h5_converter.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL
    
    %% DETERMINE Hm0 DATA COLUMN LOCATION
    % Determine What Header To Call For Hm0
    headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
        {'Zero Moment Wave Height','Significant Wave Height','Significant Wave Height Total Sea'})==1),...
        STWAVE.Conv_Data.headers,'un',false));
    if isempty(headerIndx)
        % Throw Error
        error('Hm0 not found.');
    end
    % Define Posible Header Values
    headerName = {'Zero Moment Wave Height','Significant Wave Height','Significant Wave Height Total Sea'};
    % Store Header To Use
    STWAVE_headers_location.Hm0 = headerName{headerIndx};
    
    %% DETERMINE Tp DATA COLUMN LOCATION
    % Determine What Header To Call For Tp
    headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
        {'Peak Spectral Wave Period Total Sea','Peak Period','Smoothed Peak Period','Peak Wave Period'})==1),...
        STWAVE.Conv_Data.headers,'un',false));
    % Define Possible Header Values
    if isempty(headerIndx) % Final Option Try For Tm
        % Determine What Header To Call For Tm
        headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
            {'Mean Wave Period'})==1),...
            STWAVE.Conv_Data.headers,'un',false));
        % Flag For Special Case
        Tp_special = 1;
        % Unrecognized Header
        if isempty(headerIndx)
            % Throw Error
            error('Tp not found.');
        end
        % Define Posible Header Values
        headerName = {'Mean Wave Period'};
    else
        % Dataset Offers Tp
        Tp_special = 0;
        % Define Posible Header Values
        headerName = {'Peak Spectral Wave Period Total Sea','Peak Period','Smoothed Peak Period','Peak Wave Period'};
    end
    % Store Header To Use
    STWAVE_headers_location.Tp = headerName{headerIndx};
    
    %% DETERMINE WAVE DIRECTION DATA COLUMN LOCATION
    % Determine What Header To Call For Hm0
    headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
        {'Mean Wave Direction Total Sea','Mean Wave Direction'})==1),...
        STWAVE.Conv_Data.headers,'un',false));
    % Unrecognized Header
    if isempty(headerIndx)
        % Throw Error
        error('Mean Wave Direction not found.');
    end
    % Define Posible Header Values
    headerName = {'Mean Wave Direction Total Sea','Mean Wave Direction'};
    % Store Header To Use
    STWAVE_headers_location.wDir = headerName{headerIndx};
    
end
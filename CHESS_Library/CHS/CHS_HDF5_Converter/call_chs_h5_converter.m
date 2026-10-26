function Data_out = call_chs_h5_converter(files_2_convert, print_progress, progress_fcn)
%{
    %% DESCRIPTION
        Converts a list of CHS .h5 files (chs_h5_converter.m) into one
        struct array (Filename, Conv_Data).

    %% INPUTS
        files_2_convert: Full paths of the .h5 files.                     | cell | 1 x number_of_files
        print_progress: Print progress to the command window (disp_toggle). | logical | 1 x 1
        progress_fcn: Optional. Called before each file as                 | function_handle | 1 x 1
                      progress_fcn(jj, n, file_name) (file_name: name only,
                      no path). Omitted or empty: command window only.

    %% OUTPUTS
        Data_out: Converted CHS files (Filename, Conv_Data).              | struct | 1 x number_of_files

    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
    if nargin < 3
        progress_fcn = [];
    end
    n_files = length(files_2_convert);
    % Pre-allocate output struct array
    Data_out = struct('Filename', cell(1, n_files), ...
                      'Conv_Data', cell(1, n_files));
    % Loop Through H5 Files In Zip Folder
    for jj = 1:n_files
        disp_toggle(print_progress,['   - ' files_2_convert{jj} '...']);
        if ~isempty(progress_fcn)
            [~, f_name, f_ext] = fileparts(files_2_convert{jj});
            progress_fcn(jj, n_files, [f_name f_ext]);
        end
        % Call H5 Converter
        [cData] = chs_h5_converter(files_2_convert{jj});
        % Store Converted Filename
        Data_out(jj).Filename = files_2_convert{jj};
        % Store Converted Data
        Data_out(jj).Conv_Data = cData;
    end
    disp_toggle(print_progress,'H5 conversion was successful...');
end
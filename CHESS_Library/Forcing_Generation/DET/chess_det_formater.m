function project_forcing = chess_det_formater(storm_sampling, storm, print_progress)
%{
    %% DESCRIPTION
        Formats the storm suite for CHESS: Deterministic (workflow 2).
        Same layout as chess_pros_formater (data type > match type >
        storm type) but without replicates: every storm is used once, as
        recorded in the storm database. SWL/Hm0/Tp and their *_no_rep
        copies start out identical; adjust_project_forcing later adjusts
        SWL, SWL_no_rep and Hm0 (tides, SLR, depth limitation), so
        Hm0_no_rep keeps the original (not depth limited) wave height.

    %% INPUTS
        storm_sampling: 'XC', 'TC' or 'CC'. | char
        storm: CHESS storm database. | struc
        print_progress: Toggle status print outs. | logical

    %% OUTPUTS
        project_forcing.(data_type).(match_type).(storm_type) with fields:
            SWL, Hm0, Tp: Forcing per storm (nSteps x 1 each). | cell
            SWL_no_rep, Hm0_no_rep, Tp_no_rep: Copies (see above). | cell
            dt: Time step per storm [days]. | cell
            storm_id: Storm IDs. | double (nStorms x 1)
            time: Time stamp(s) per storm [datenum]. | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
switch storm_sampling
    case 'CC'
        storm_types = {'TC','XC'};
    otherwise
        storm_types = {storm_sampling};
end
% Storm Data Columns: [SWL Hm0 Tp wDir datenum dt]
col_time = 5;

for st = 1:length(storm_types)
    disp_toggle(print_progress, ['Formatting ' storm_types{st} ' forcing data for deterministic analysis....']);
    data_type = fieldnames(storm.(storm_types{st}));
    data_type(~contains(data_type, {'Peaks', 'Timeseries'})) = [];
    for kk = 1:length(data_type)
        match_types = fieldnames(storm.(storm_types{st}).(data_type{kk}));
        for ii = 1:length(match_types)
            storm_data = storm.(storm_types{st}).(data_type{kk}).(match_types{ii});
            data_out.SWL = cellfun(@(x) x(:, 1), storm_data(:, 2), 'un', false);
            data_out.Hm0 = cellfun(@(x) x(:, 2), storm_data(:, 2), 'un', false);
            data_out.Tp = cellfun(@(x) x(:, 3), storm_data(:, 2), 'un', false);
            data_out.SWL_no_rep = data_out.SWL;
            data_out.Hm0_no_rep = data_out.Hm0;
            data_out.Tp_no_rep = data_out.Tp;
            data_out.dt = cellfun(@(x) x(:, end), storm_data(:, 2), 'un', false);
            data_out.storm_id = cell2mat(storm_data(:, 1));
            data_out.time = cellfun(@(x) x(:, col_time), storm_data(:, 2), 'un', false);
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}) = data_out;
        end
    end
end
end

function project_forcing = chess_det_formater(storm_sampling, storm, print_progress, storm_duration, compute_storm_duration)
%{
    %% DESCRIPTION
        Formats the storm suite for CHESS: Deterministic (workflow 2).
        Same layout as chess_pros_formater (data type > match type >
        storm type) but without replicates: every storm is used once, as
        recorded in the storm database. adjust_project_forcing later
        adjusts SWL (tides, SLR) and adds Hm0_toe (depth limited at the
        toe), so Hm0_offshore keeps the database wave height.

    %% INPUTS
        storm_sampling: 'XC', 'TC' or 'CC'. | char
        storm: CHESS storm database. | struc
        print_progress: Toggle status print outs. | logical
        storm_duration: Storm duration [hrs] (config.storm_duration). | double
        compute_storm_duration: 1 = Timeseries storm_duration from each
            storm's SWL (timeseries_storm_durations.m). | double

    %% OUTPUTS
        project_forcing.(data_type).(match_type).(storm_type) with fields:
            SWL, Hm0_offshore, Tp: Forcing per storm (nSteps x 1 each). | cell
            storm_duration: Event length per storm [days], repeated on
                every row of a Timeseries storm (Peaks:
                config.storm_duration). | cell
            dt: Timeseries only, time step per storm [days]. | cell
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
            data_out = struct();
            data_out.SWL = cellfun(@(x) x(:, 1), storm_data(:, 2), 'un', false);
            data_out.Hm0_offshore = cellfun(@(x) x(:, 2), storm_data(:, 2), 'un', false);
            data_out.Tp = cellfun(@(x) x(:, 3), storm_data(:, 2), 'un', false);
            if strcmp(data_type{kk}, 'Timeseries')
                data_out.dt = cellfun(@(x) x(:, end), storm_data(:, 2), 'un', false);
                data_out.storm_duration = cellfun(@(x, d) repmat(d, size(x, 1), 1), storm_data(:, 2),...
                    num2cell(timeseries_storm_durations(storm_data(:, 2), storm_duration, compute_storm_duration)), 'un', false);
            else % Peaks: config.storm_duration (Restamped By build_boundary_conditions), No dt
                data_out.storm_duration = cellfun(@(x) x(1, end), storm_data(:, 2), 'un', false);
            end
            data_out.storm_id = cell2mat(storm_data(:, 1));
            data_out.time = cellfun(@(x) x(:, col_time), storm_data(:, 2), 'un', false);
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}) = data_out;
        end
    end
end
end

function project_forcing = chess_forcing_formatter(storm_sampling, storm, prob_mass, print_progress, storm_duration, compute_storm_duration, with_replicates)
%{
    %% DESCRIPTION
        Formats the storm suite for CHESS: PROS (RB/FB, workflows 1, 4)
        and CHESS: Deterministic (workflow 2). Layout: data type > match
        type > storm type.
            - with_replicates = true (PROS): every storm is repeated over
              one column per discrete normal z-score (XC 21, TC 445; z = 0
              in the middle column keeps the database values). TC datasets
              also carry TC_Prob (prob_mass.TC_Freq).
            - with_replicates = false (DET): every storm is used once, as
              recorded in the storm database (one column); prob_mass is
              not read.
        adjust_project_forcing later adjusts SWL (tides, SLR) and adds
        Hm0_toe (depth limited at the toe), so Hm0_offshore keeps the
        database wave height.

    %% INPUTS
        storm_sampling: 'XC', 'TC' or 'CC'. | char
        storm: CHESS storm database. | struct
        prob_mass: Storm probability masses (PROS TC: TC_Freq). | struct
        print_progress: Toggle status print outs. | logical
        storm_duration: Storm duration [hrs] (config.storm_duration). | double
        compute_storm_duration: 1 = Timeseries storm_duration from each
            storm's SWL (timeseries_storm_durations.m). | double
        with_replicates: true = PROS replicates, false = DET. | logical

    %% OUTPUTS
        project_forcing.(data_type).(match_type).(storm_type) with fields:
            SWL, Hm0_offshore, Tp: Forcing per storm (nSteps x
                n_replicates each; DET: nSteps x 1). | cell
            storm_id: Storm IDs. | double (nStorms x 1)
            time: Time stamp(s) per storm [datenum]. | cell
            TC_Prob: PROS TC only, prob_mass.TC_Freq. | double
            dt: Timeseries only, time step per storm [days]. | cell
            storm_duration: Event length per storm [days], repeated on
                every row of a Timeseries storm (Peaks:
                config.storm_duration). | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
storm_types = storm_types_for_sampling(storm_sampling, {'TC','XC'});
% Storm Data Columns: Peaks [SWL Hm0 Tp wDir datenum]; Timeseries [SWL Hm0 Tp wDir datenum dt]
col_time = 5;

for st = 1:length(storm_types)
    if with_replicates
        disp_toggle(print_progress, ['Reshaping ' storm_types{st} ' forcing data for response base analysis....']);
        % One Column Per Discrete Normal z-Score (XC 21, TC 445; z = 0 In The Middle Column)
        n_replicates = numel(discrete_standard_normal_scores(storm_types{st}));
    else
        disp_toggle(print_progress, ['Formatting ' storm_types{st} ' forcing data for deterministic analysis....']);
        n_replicates = 1;
    end
    data_type = fieldnames(storm.(storm_types{st}));
    data_type(~contains(data_type, {'Peaks', 'Timeseries'})) = [];
    for kk = 1:length(data_type)
        match_types = fieldnames(storm.(storm_types{st}).(data_type{kk}));
        for ii = 1:length(match_types)
            storm_rows = storm.(storm_types{st}).(data_type{kk}).(match_types{ii});
            storm_data = storm_rows(:, 2);
            data_out = struct();
            data_out.SWL = cellfun(@(x) repmat(x(:, 1), 1, n_replicates), storm_data, 'un', false);
            data_out.Hm0_offshore = cellfun(@(x) repmat(x(:, 2), 1, n_replicates), storm_data, 'un', false);
            data_out.Tp = cellfun(@(x) repmat(x(:, 3), 1, n_replicates), storm_data, 'un', false);
            data_out.storm_id = cell2mat(storm_rows(:, 1));
            data_out.time = cellfun(@(x) x(:, col_time), storm_data, 'un', false);
            if with_replicates && strcmp(storm_types{st}, 'TC')
                data_out.TC_Prob = prob_mass.TC_Freq;
            end
            if strcmp(data_type{kk}, 'Timeseries')
                data_out.dt = cellfun(@(x) x(:, end), storm_data, 'un', false);
                data_out.storm_duration = cellfun(@(x, d) repmat(d, size(x, 1), 1), storm_data,...
                    num2cell(timeseries_storm_durations(storm_data, storm_duration, compute_storm_duration)), 'un', false);
            else % Peaks: config.storm_duration [days], no dt
                data_out.storm_duration = num2cell(repmat(storm_duration/24, size(storm_rows, 1), 1));
            end
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}) = data_out;
        end
    end
end
end

function project_forcing = chess_forcing_formatter(storm_sampling, storm, prob_mass, print_progress, storm_duration, compute_storm_duration, with_replicates)
% chess_forcing_formatter  Format the storm suite as PROS or DET forcing.
%   project_forcing = chess_forcing_formatter(storm_sampling, storm,
%       prob_mass, print_progress, storm_duration, compute_storm_duration,
%       with_replicates)
%
%   Formats the storm suite for CHESS: PROS (RB/FB, workflows 1, 4) and
%   CHESS: Deterministic (workflow 2). Layout: data type > match type >
%   storm type (CC sampling gives the TC and XC datasets).
%     - with_replicates = true (PROS): every storm is repeated over one
%       column per discrete normal z-score (XC 21, TC 445; z = 0 in the
%       middle column keeps the database values). TC datasets also carry
%       TC_Prob (prob_mass.TC_Freq).
%     - with_replicates = false (DET): every storm is used once, as recorded
%       in the storm database (one column); prob_mass is not read.
%   adjust_project_forcing later adjusts SWL (tides, SLR) and adds Hm0_toe
%   (depth limited at the toe), so Hm0_offshore keeps the database wave
%   height.
%
%   Inputs:
%     storm_sampling         - storm sampling, 'XC', 'TC' or 'CC', char
%     storm                  - storm database request, struct
%     prob_mass              - storm probability masses (PROS TC: TC_Freq),
%                              struct
%     print_progress         - print progress (0/1), double or logical
%     storm_duration         - storm duration (config storm_duration)
%                              [hours], scalar double
%     compute_storm_duration - 1 = Timeseries storm_duration from each
%                              storm's SWL (timeseries_storm_durations),
%                              else storm_duration (0/1), double
%     with_replicates        - true = PROS replicates, false = DET, logical
%   Outputs:
%     project_forcing - project_forcing.<data type>.<match type>.<storm
%                       type>, struct with fields:
%                         SWL, Hm0_offshore, Tp - forcing per storm [m, m,
%                             s], nStorms x 1 cell of nSteps x
%                             n_replicates (DET: nSteps x 1)
%                         storm_id       - storm IDs, nStorms x 1 double
%                         time           - time stamp(s) per storm
%                                          [datenum], nStorms x 1 cell
%                         TC_Prob        - PROS TC only, prob_mass.TC_Freq
%                         dt             - Timeseries only, time step per
%                                          row [days], nStorms x 1 cell
%                         storm_duration - event length per storm [days],
%                                          repeated on every row of a
%                                          Timeseries storm (Peaks: the
%                                          storm_duration input),
%                                          nStorms x 1 cell
%
%   Tier: internal
%
%   See also build_boundary_conditions, timeseries_storm_durations,
%   discrete_standard_normal_scores, adjust_project_forcing.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

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
                    num2cell(timeseries_storm_durations(storm_data, storm_duration, compute_storm_duration, data_out.storm_id, storm_types{st})), 'un', false);
            else % Peaks: config.storm_duration [days], no dt
                data_out.storm_duration = num2cell(repmat(storm_duration/24, size(storm_rows, 1), 1));
            end
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}) = data_out;
        end
    end
end
end

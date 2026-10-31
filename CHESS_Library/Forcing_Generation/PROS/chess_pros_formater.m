function project_forcing = chess_pros_formater(storm_sampling, storm, prob_mass, print_progress, storm_duration, compute_storm_duration)
%% PREP INPUTS
% Execute Code Block According To Strom Type Being Calle
switch storm_sampling
    case 'CC'
        storm_types = {'TC','XC'};
    otherwise
        storm_types = {storm_sampling};
end

%% RESHAPE FORCING PARAMETERS FOR CHESS:PROS
% Loop Across Each Storm Type
for st = 1:length(storm_types)
    % Disp
    disp_toggle(print_progress, ['Reshaping ' storm_types{st} ' forcing data for response base analysis....']);
    % Get Data Types (Peaks/Timeseries)
    data_type = fieldnames(storm.(storm_types{st}));
    data_type(~contains(data_type, {'Peaks', 'Timeseries'})) = [];
    % Loop Across Each Data Type
    for kk = 1:length(data_type)
        % Determine Match Types
        match_types = fieldnames(storm.(storm_types{st}).(data_type{kk}));
        % Loop Across Each Match Type
        for ii = 1:length(match_types)
            % Define Normal Discretization To Use
            switch storm_types{st}
                case 'XC'
                    RandNorm = 21; % 20 values for XC because there is 1000 bootstrap samples in SST code, + z = 0 (Middle Column)
                case 'TC'
                    RandNorm = 445; % 444 values covering the (-3,3) z-score range, + z = 0 (Middle Column)
            end
            % Create Replicates
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}) = create_reps(storm.(storm_types{st}).(data_type{kk}).(match_types{ii})(:, 2), RandNorm, [1 2 3]);
            % Storm IDs And Time Stamps [datenum] (Rows Match The Forcing; Storm Event Viewer / Response Table)
            storm_rows = storm.(storm_types{st}).(data_type{kk}).(match_types{ii});
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}).storm_id = cell2mat(storm_rows(:, 1));
            project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}).time = cellfun(@(x) x(:, 5), storm_rows(:, 2), 'un', false);
            % Reshape Storm Probability Masses To Be nStorms * normal_discretization
            if strcmp(storm_types{st}, 'TC')
                project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}).TC_Prob = prob_mass.TC_Freq;%./RandNorm;
            end
            % Storm Duration [days] Per Storm (Event Length) And, Timeseries Only, dt [days] (Row Time Step). Timeseries Is
            % Always The Default Match Type, So Its Fields Are Stored Once Under .Default
            if strcmp(data_type{kk}, 'Timeseries')
                ts_data = storm.(storm_types{st}).(data_type{kk}).('Default')(:, 2);
                project_forcing.(data_type{kk}).Default.(storm_types{st}).dt = cellfun(@(x) x(:, end), ts_data,'un',false);
                project_forcing.(data_type{kk}).Default.(storm_types{st}).storm_duration = cellfun(@(x, d) repmat(d, size(x, 1), 1),...
                    ts_data, num2cell(timeseries_storm_durations(ts_data, storm_duration, compute_storm_duration)), 'un', false);
            else % Peaks: config.storm_duration (Restamped By build_boundary_conditions), No dt
                project_forcing.(data_type{kk}).(match_types{ii}).(storm_types{st}).storm_duration = cellfun(@(x) x(1, end),...
                    storm.(storm_types{st}).(data_type{kk}).(match_types{ii})(:, 2),...
                    'un', false);
            end
        end
    end
end

%% AUX FUNCTIONS
    function data_out = create_reps(storm_data, n_reps, col_indx)
        % Reshape Peaks Data To Be nStorms * normal_discretization (The z = 0 Column Keeps The Database Values)
        data_out.SWL = cellfun(@(x) repmat(x(:,col_indx(1)),1,n_reps),storm_data,'un',false); % SWL
        data_out.Hm0_offshore = cellfun(@(x) repmat(x(:,col_indx(2)),1,n_reps),storm_data,'un',false); % Hm0 (Hm0_toe Added By adjust_project_forcing)
        data_out.Tp = cellfun(@(x) repmat(x(:,col_indx(3)),1,n_reps),storm_data,'un',false); %  Tp
    end
end


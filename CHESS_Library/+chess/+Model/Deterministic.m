classdef Deterministic < chess.Model
    % Deterministic  Responses straight from the storms of the database (DET, workflow 2).
    %   model = chess.Model.create(inputs) returns this class for workflow 2.
    %
    %   No replicates, no uncertainty and no hazard curves: every storm gives
    %   its response history, and the maximum of each response per storm.
    %
    %   See also chess.Model.

    properties (Constant, Access = protected)
        run_label = 'Deterministic'
    end

    methods
        function obj = Deterministic(varargin)
            % Deterministic  Deterministic model of a ready configuration (see chess.Model.create).
            %   obj = chess.Model.Deterministic(config, protection_system, storm_database)
            obj@chess.Model(varargin{:});
        end
    end

    methods (Static)
        function rules = workflow_input_rules()
            % workflow_input_rules  Inputs only DET needs (chess.Model.input_rules): none.
            rules = chess.Config.input_rule('none', 'switch');
            rules = rules([]);
        end
    end

    methods (Access = protected)
        function forcing = build_storm_forcing(obj, storm, prob_mass)
            % One value per storm record (no replicates)
            forcing = obj.format_storm_forcing(storm, prob_mass, false);
        end

        function Resp = dataset_responses(obj, project_forcing, data_type, dataset_name) %#ok<INUSD>
            % Response histories and per-storm maxima of one forcing dataset
            %   Per storm type: storm_id, depth h and freeboard Rc, every
            %   response (full history), Max (one value per storm; Rc uses
            %   the minimum; time of peak SWL) and Max_time (time of that
            %   value, per variable; a storm total such as Q_vol has none).
            %   The forcing itself is read from
            %   the project forcing (same rows), not copied.
            config = obj.config;
            % Overtopping Volume (Q_vol) Is Timeseries Only
            if strcmp(data_type, 'Peaks')
                config.compute_q_vol = 0;
            end
            storm_types = fieldnames(project_forcing);
            for st = 1:length(storm_types)
                pf = project_forcing.(storm_types{st});
                % Forcing As Used By The Response Equations (Forcing Copies Only Feed storm_maxima, Dropped Below)
                out.storm_id = pf.storm_id;
                out.time = pf.time;
                out.SWL = pf.SWL;
                out.Hm0_offshore = pf.Hm0_offshore; % Database Wave Height
                out.Hm0_toe = pf.Hm0_toe; % After Depth Limitation (Equal To Hm0_offshore When Off; NaN On A Dry Toe When On)
                out.Tp = pf.Tp;
                out.h = cellfun(@(x) x - obj.protection_system.toe_elevation, pf.SWL, 'un', false);
                out.Rc = cellfun(@(x) obj.protection_system.crest_elevation - x, pf.SWL, 'un', false);
                % Structure Responses (Full Histories)
                R = obj.hydraulic_responses(config, pf, 0);
                if ~isempty(R)
                    resp_names = fieldnames(R);
                    for rr = 1:length(resp_names)
                        out.(resp_names{rr}) = R.(resp_names{rr});
                    end
                end
                % One Value Per Storm (Forcing Maxima Included), Then The Forcing Copies Are Dropped (Rows Match project_forcing)
                [out.Max, out.Max_time] = storm_maxima(out);
                out = rmfield(out, [{'time'}, chess.Common.response_registry('output', 'names', 'pros_forcing_curve', true)]);
                Resp.(storm_types{st}) = out;
                clear out
            end
        end

        function tf = uses_peaks_dataset(obj, name)
            tf = ~((strcmp(name, 'WLP') && ~obj.config.create_wlp) || (strcmp(name, 'WHP') && ~obj.config.create_whp));
        end
    end
end

%% LOCAL FUNCTIONS
function [Max, Max_time] = storm_maxima(out)
skip = {'storm_id', 'time'};
names = setdiff(fieldnames(out), skip, 'stable');
Max.storm_id = out.storm_id;
Max_time = struct();
for kk = 1:length(names)
    v = out.(names{kk});
    if iscell(v) && all(cellfun(@(x) isnumeric(x) && size(x, 2) == 1, v))
        if strcmp(names{kk}, 'Rc')
            [Max.(names{kk}), peak_row] = cellfun(@(x) min(x, [], 1), v);
        else
            [Max.(names{kk}), peak_row] = cellfun(@(x) max(x, [], 1), v);
        end
        % Time Of The Value (Only A History On The Storm Time Steps Has One; A Storm Total Does Not)
        if all(cellfun(@numel, v) == cellfun(@numel, out.time))
            Max_time.(names{kk}) = cellfun(@(t, i) t(i), out.time, num2cell(peak_row));
        end
    end
end
% Time Of Peak SWL (Peaks: The Single Record)
[~, ix] = cellfun(@(x) max(x, [], 1), out.SWL);
Max.time = cellfun(@(t, i) t(i), out.time, num2cell(ix));
end

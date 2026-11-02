function t_size = forcing_storm_lengths(workflow, data)
%{
    %% DESCRIPTION
        Time steps per storm of one project forcing dataset (one data type >
        match type > storm type), as used by the random tide: a storm covers
        tide hours idx : idx + t_size - 1.

    %% INPUTS
        workflow: config.workflow. | double
        data: PROS/DET dataset struct (SWL: one cell per storm) or LCS
            dataset (one life-cycle matrix per cell; Timeseries layout: lcs_columns.m). | struct/cell

    %% OUTPUTS
        t_size: PROS/DET: one cell per storm holding its row count. LCS: one
            cell per life cycle holding a column of per-storm lengths. | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
switch workflow
    case {1, 2, 4}
        t_size = cellfun(@(x) size(x,1), data.SWL, 'un', false);
    case {3} % LCS
        if size(data{1}, 2) == lcs_columns().n_timeseries % Timeseries Layout (Step Counter Column)
            t_size = cellfun(@storm_lengths, data, 'un', false);
        else
            t_size = cellfun(@(x) ones(size(x, 1), 1), data, 'un', false);
        end
        % Logic Behind storm_lengths
        % Add nan on top -> Keep Dimensions Consistent But Remove 0 of first Storm
        % Add Zero To End -> Want to flag final timestep of final storm
        % - 1 -> Gives the end row index of each storm
        % + 1 -> The Step Counter Goes From 0:n_stsp-1 Hence Need To Add 1 To Get Proper Length
end
end

%% AUX FUNCTION: TIMESTEPS PER STORM OF A TIMESERIES LIFE CYCLE
function t_size = storm_lengths(x)
if isempty(x) % Life Cycle Without Storms
    t_size = zeros(0, 1);
else
    step = lcs_columns().step;
    t_size = x(find([nan;x(2:end, step);0]== 0)-1, step)+1;
end
end

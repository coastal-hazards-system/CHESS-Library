function [SWL, tide_indx] = apply_random_tide(tide_file, SWL, t_size, tide_indx)
%% IMPORT TIDAL DATA
tidal_data = read_tide_series(tide_file);

%% ADD RANDOM TIDE ACCORDINGLY
% Start Hours: Drawn If None Were Given; Each Storm Hydrograph Fits The Tide Record
tide_indx = tide_start_hours(length(tidal_data), t_size, tide_indx);
rand_tide = {};
% For Each Event
for stm = 1:length(tide_indx)
    % Add Tide To Storm Data
    rand_tide{stm, 1} = cell2mat(arrayfun(@(x, y) tidal_data(x:x+y-1), tide_indx{stm}, t_size{stm},'un',false));
    % Life Cycle Without Storms: cell2mat Gives 0x0, Keep A Column (0x0 Assigned To A Column Deletes It Downstream)
    if isempty(rand_tide{stm, 1})
        rand_tide{stm, 1} = zeros(0, 1);
    end
end
% Add To Surge
for gg = 1:size(SWL, 2)
    % Add Tidal Signal To Storm Data
    SWL(:, gg) = cellfun(@(x,y) x + y, SWL(:, gg), rand_tide, 'un', false);
end
end
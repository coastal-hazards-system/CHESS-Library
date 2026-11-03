function tide_indx = tide_start_hours(n_tide, t_size, tide_indx)
% tide_start_hours  Random tide start hours that fit the tide record.
%   tide_indx = tide_start_hours(n_tide, t_size, tide_indx)
%
%   Random tide start hours (rows of the tide record) per storm. A storm of
%   L time steps covers tide hours idx : idx + L - 1, so it fits when
%   idx + L - 1 <= n_tide. New start hours are drawn uniformly from
%   [1, n_tide - L + 1]; supplied start hours are kept, except those whose
%   storm does not fit, which are redrawn the same way (that storm only).
%   A tide record shorter than the longest storm is an error
%   (tide_start_hours:tideTooShort).
%
%   Inputs:
%     n_tide    - number of hourly records in the tide file, double
%     t_size    - time steps per storm (forcing_storm_lengths), cell
%     tide_indx - start hours to keep ([] = draw all), cell (same shape as
%                 t_size)
%   Outputs:
%     tide_indx - start hours, every storm fitting the tide record, cell
%
%   Tier: internal
%
%   See also apply_random_tide, draw_tide_indices, forcing_storm_lengths.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

L_max = max([0; cell2mat(cellfun(@(x) x(:), t_size(:), 'un', false))]);
if L_max > n_tide
    error('tide_start_hours:tideTooShort', ['The tide file holds %d hourly records, fewer than the %d time steps ',...
        'of the longest storm; random tides cannot be applied.'], n_tide, L_max);
end
if isempty(tide_indx)
    tide_indx = cellfun(@(L) draw(n_tide, L), t_size, 'un', false);
    return
end
for stm = 1:numel(tide_indx)
    no_fit = tide_indx{stm} + t_size{stm} - 1 > n_tide;
    if any(no_fit)
        L = t_size{stm} .* ones(size(tide_indx{stm}));
        tide_indx{stm}(no_fit) = draw(n_tide, L(no_fit));
    end
end
end

%% AUX FUNCTION: UNIFORM START HOURS OVER [1, n_tide - L + 1] (ONE randi CALL PER DISTINCT LENGTH)
function idx = draw(n_tide, L)
idx = zeros(size(L));
for l = unique(L(:))'
    k = L == l;
    idx(k) = randi([1 n_tide - l + 1], nnz(k), 1);
end
end

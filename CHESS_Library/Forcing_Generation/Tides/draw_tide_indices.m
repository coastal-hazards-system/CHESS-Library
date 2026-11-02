function config = draw_tide_indices(config, project_forcing)
%{
    %% DESCRIPTION
        Random tide start hours drawn before any dataset is adjusted
        (call_chess_boundary_conditions.m), so every dataset of a storm type
        uses the same config.tide_indx_<type> and a storm gets the same
        tide start hour in each of them.
        - Storm types with Timeseries (CC excluded): each start hour is drawn
          from [1, N - L + 1] (N = tide records, L = that storm's hydrograph
          length), so every hydrograph fits and the Timeseries pass never
          redraws. Peaks rows and Timeseries storms correspond one to one
          (LCS: chess_lcs.m builds both from the same sampled life
          cycles; PROS/DET: both storm DB datasets are sorted by storm ID
          with the same storms removed).
        - LCS combined sampling (CC): CC holds the TC and XC storms of each
          life cycle, so its start hours are not drawn but derived from
          tide_indx_tc / tide_indx_xc: the TC-then-XC stacked start hours
          are reordered with the permutation chess_lcs.m used to build
          CC (stable sortrows of [TC; XC] by year, order, bin: lcs_columns.m). That sort
          keeps each Timeseries hydrograph contiguous (constant key within
          a storm) and keeps TC before XC on ties, so the Timeseries CC
          storms come in the same order as the Peaks CC rows. TC/XC
          without Timeseries are drawn here from their Peaks rows first.
          Without Peaks (use_peaks = 0) the permutation comes from the
          Timeseries first-step rows (step == 0: one row per storm, same
          keys and order), so it equals the Peaks-based one.
          tide_indx_cc is always overwritten (never carried or reused), so
          the same storm has the same start hour in XC/TC and CC.
        Start hours already in config (hotstart carry: resolve_hotstart_state.m;
        LCS reference case: load_reference_tide_indices.m) are kept; only a
        storm whose hydrograph does not fit is redrawn (tide_start_hours.m).
        Other storm types without Timeseries are left alone: their Peaks draw
        over [1, N] in adjust_project_forcing.m, as before.

    %% INPUTS
        config: Run configuration (workflow, apply_random_tides, tide_file,
            tide_indx_<type> when carried). | struct
        project_forcing: Project forcing before adjustment. | struct

    %% OUTPUTS
        config: With tide_indx_<type> for each storm type with Timeseries,
            plus tide_indx_tc / _xc / _cc for LCS CC. | struct

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
if config.apply_random_tides ~= 1 || exist(config.tide_file, 'file') ~= 2
    return
end
has_ts = isfield(project_forcing, 'Timeseries');
has_peaks = isfield(project_forcing, 'Peaks');
is_cc = config.workflow == 3 && ((has_peaks && isfield(project_forcing.Peaks.Default, 'CC')) ||...
    (has_ts && isfield(project_forcing.Timeseries.Default, 'CC')));
if ~has_ts && ~is_cc
    return
end
n_tide = numel(read_tide_series(config.tide_file));
if has_ts
    for st = setdiff(fieldnames(project_forcing.Timeseries.Default)', {'CC'}, 'stable')
        config = draw_type(config, st{1}, project_forcing.Timeseries.Default.(st{1}), n_tide);
    end
end
if is_cc
    if has_peaks
        % Storms Already Drawn From Their Timeseries Fit, So The Peaks Pass Keeps Them As Given
        for st = storm_types_for_sampling('CC', {'TC', 'XC'})
            config = draw_type(config, st{1}, project_forcing.Peaks.Default.(st{1}), n_tide);
        end
        storm_rows = project_forcing.Peaks.Default;
    else
        storm_rows = timeseries_first_step_rows(project_forcing.Timeseries.Default);
    end
    config.tide_indx_cc = cc_tide_indices(config.tide_indx_tc, config.tide_indx_xc, storm_rows);
end
end

%% AUX FUNCTION: START HOURS OF ONE STORM TYPE (KEEPS CARRIED ONES THAT FIT)
function config = draw_type(config, st_type, data, n_tide)
fld = ['tide_indx_' lower(st_type)];
if ~isfield(config, fld)
    config.(fld) = [];
end
config.(fld) = tide_start_hours(n_tide, forcing_storm_lengths(config.workflow, data), config.(fld));
end

%% AUX FUNCTION: ONE ROW PER STORM OF THE TC / XC / CC TIMESERIES LIFE CYCLES (FIRST STEP, step == 0)
function storm_rows = timeseries_first_step_rows(timeseries)
step = lcs_columns().step;
for st = {'TC', 'XC', 'CC'}
    storm_rows.(st{1}) = cellfun(@(x) x(x(:, step) == 0, :), timeseries.(st{1}), 'un', false);
end
end

%% AUX FUNCTION: CC START HOURS = TC-THEN-XC START HOURS IN THE CC ORDER OF chess_lcs.m
% storm_rows: One Row Per Storm (Peaks Rows Or Timeseries First-Step Rows) Of TC, XC And CC
function cc = cc_tide_indices(tc, xc, storm_rows)
cc = cell(size(storm_rows.CC));
for lc = 1:numel(cc)
    C = lcs_columns();
    [~, p] = sortrows([storm_rows.TC{lc}; storm_rows.XC{lc}], [C.year, C.order, C.bin]);
    stacked = [tc{lc}(:); xc{lc}(:)];
    cc{lc} = stacked(p);
end
end

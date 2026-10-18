function config = draw_tide_indices(config, project_forcing)
%{
    %% DESCRIPTION
        Random tide start hours drawn before any dataset is adjusted
        (call_project_forcing_adjuster.m), so every dataset of a storm type
        uses the same config.tide_indx_<type> and a storm gets the same
        tide start hour in each of them.
        - Storm types with Timeseries (CC excluded): each start hour is drawn
          from [1, N - L + 1] (N = tide records, L = that storm's hydrograph
          length), so every hydrograph fits and the Timeseries pass never
          redraws. Peaks rows and Timeseries storms correspond one to one
          (LCS: stormsim_lcs.m builds both from the same sampled life
          cycles; PROS/DET: both storm DB datasets are sorted by storm ID
          with the same storms removed).
        - LCS combined sampling (CC): CC holds the TC and XC storms of each
          life cycle, so its start hours are not drawn but derived from
          tide_indx_tc / tide_indx_xc: the TC-then-XC stacked start hours
          are reordered with the permutation stormsim_lcs.m used to build
          CC (stable sortrows of [TC; XC] by columns [3, 4, 2]). That sort
          keeps each Timeseries hydrograph contiguous (constant key within
          a storm) and keeps TC before XC on ties, so the Timeseries CC
          storms come in the same order as the Peaks CC rows. TC/XC
          without Timeseries are drawn here from their Peaks rows first.
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
is_cc = config.workflow == 3 && isfield(project_forcing, 'Peaks') && isfield(project_forcing.Peaks.Default, 'CC');
if ~has_ts && ~is_cc
    return
end
warning('off');
tidal_data = readcell(config.tide_file, 'NumHeaderLines', 1);
warning('on');
n_tide = size(tidal_data, 1);
if has_ts
    for st = setdiff(fieldnames(project_forcing.Timeseries.Default)', {'CC'}, 'stable')
        config = draw_type(config, st{1}, project_forcing.Timeseries.Default.(st{1}), n_tide);
    end
end
if is_cc
    % Storms Already Drawn From Their Timeseries Fit, So The Peaks Pass Keeps Them As Given
    for st = {'TC', 'XC'}
        config = draw_type(config, st{1}, project_forcing.Peaks.Default.(st{1}), n_tide);
    end
    config.tide_indx_cc = cc_tide_indices(config.tide_indx_tc, config.tide_indx_xc, project_forcing.Peaks.Default);
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

%% AUX FUNCTION: CC START HOURS = TC-THEN-XC START HOURS IN THE CC ORDER OF stormsim_lcs.m
function cc = cc_tide_indices(tc, xc, peaks)
cc = cell(size(peaks.CC));
for lc = 1:numel(cc)
    [~, p] = sortrows([peaks.TC{lc}; peaks.XC{lc}], [3, 4, 2]);
    stacked = [tc{lc}(:); xc{lc}(:)];
    cc{lc} = stacked(p);
end
end

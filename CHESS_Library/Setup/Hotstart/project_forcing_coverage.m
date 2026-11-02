function [covers, missing_desc] = project_forcing_coverage(config, project_forcing)
%PROJECT_FORCING_COVERAGE True if a cached project_forcing satisfies the current request.
%{
%% DESCRIPTION
Checks whether a loaded project_forcing.mat already contains everything
the current run needs (Peaks/WLP/WHP/Timeseries, and TC/XC storm-type
coverage per config.storm_sampling). A cache having MORE than requested
(e.g. cached CC data satisfying an XC-only request) is valid and is not
flagged as missing.

Peaks are required exactly when use_peaks == 1, in every workflow (LCS
builds Peaks life cycles only with use_peaks == 1: chess_lcs.m).

%% INPUTS
config: Current run's parsed config struct.
project_forcing: Loaded contents of a cached project_forcing.mat.

%% OUTPUTS
covers: true if project_forcing satisfies everything config requests.
missing_desc: comma-joined string of human-readable labels for whichever
              requested items are missing (for logging); '' if covers is true.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
has_peaks = isfield(project_forcing, 'Peaks');
has_wlp = has_peaks && isfield(project_forcing.Peaks, 'WLP');
has_whp = has_peaks && isfield(project_forcing.Peaks, 'WHP');
has_timeseries = isfield(project_forcing, 'Timeseries');
if has_peaks
    storm_types = project_forcing.Peaks.Default;
else
    storm_types = project_forcing.Timeseries.Default;
end
has_xc = isfield(storm_types, 'XC');
has_tc = isfield(storm_types, 'TC');
sampled_types = storm_types_for_sampling(config.storm_sampling, {'TC', 'XC'});
tc_conf = ismember('TC', sampled_types);
xc_conf = ismember('XC', sampled_types);
have = [has_peaks;has_wlp;has_whp;has_timeseries;has_tc;has_xc];
need = [cellfun(@(x) logical(config.(x)), {'use_peaks','create_wlp','create_whp','use_timeseries'}, 'un', true)';tc_conf;xc_conf];
labels = {'Peaks';'WLP';'WHP';'Timeseries';'TC';'XC'};
missing_mask = need & ~have;
covers = ~any(missing_mask);
missing_desc = strjoin(labels(missing_mask), ', ');
end

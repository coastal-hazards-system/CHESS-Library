function seed_file = lcs_sampling_seed_file(pf_file)
% lcs_sampling_seed_file  Sampling seed file name of a project forcing file.
%   seed_file = lcs_sampling_seed_file(pf_file)
%
%   LCS sampling seed file written by chess_lcs next to the project
%   forcing file: same folder, the name without its _project_forcing
%   suffix plus _sampling_seed.mat (<prefix>_sampling_seed.mat). The file
%   need not exist. It holds the effective sampling mode
%   (lcs_restrict_sampling_rate), the sampled life cycles per storm type
%   (sampled_ids.XC/.TC: identity columns [storm_ID, intensity_bin,
%   Sim_Year, order], empty life cycles included) and, with use_peaks = 1,
%   the raw XC Default peaks (xc_peaks.Default; XC WLP/WHP life cycles are
%   copies of it).
%
%   Inputs:
%     pf_file - project forcing file (<prefix>_project_forcing.mat), char
%   Outputs:
%     seed_file - sampling seed file, char
%
%   Tier: internal
%
%   See also chess_lcs, lcs_reference_reuse, chess_paths.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

[pth, nm] = fileparts(pf_file);
seed_file = fullfile(pth, [regexprep(nm, '_project_forcing$', '') '_sampling_seed.mat']);
end

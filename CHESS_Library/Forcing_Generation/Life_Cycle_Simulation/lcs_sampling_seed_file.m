function seed_file = lcs_sampling_seed_file(pf_file)
%{
    %% DESCRIPTION
        LCS sampling seed file written by chess_lcs next to the project forcing
        file (<prefix>_sampling_seed.mat): effective sampling mode
        (lcs_restrict_sampling_rate), sampled life cycles per storm type
        (sampled_ids.XC/.TC: identity columns [storm_ID, intensity_bin, Sim_Year,
        order], empty life cycles included) and raw XC Default peaks
        (xc_peaks.Default; XC WLP/WHP life cycles are copies of it).

    %% INPUTS
        pf_file: Project forcing file (<prefix>_project_forcing.mat). | char

    %% OUTPUTS
        seed_file: Sampling seed file. | char

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
[pth, nm] = fileparts(pf_file);
seed_file = fullfile(pth, [regexprep(nm, '_project_forcing$', '') '_sampling_seed.mat']);
end

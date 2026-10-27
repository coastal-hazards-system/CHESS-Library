function fields = multiline_inherited_fields()
%{
    %% DESCRIPTION
        Config fields a multi-line transect stage 2 run takes from the
        stage 1 run it is coupled to (multiline_stage2_config.m). They
        describe the stage 1 forcing that stage 2 reuses (its storms or
        life cycles, storm duration, tides and SLR), so stage 2's own
        values are not used. Read by multiline_stage2_config.m and by the
        GUI (stage 2 inputs shown from stage 1, not editable).

    %% OUTPUTS
        fields: Config field names (missing ones in the stage 1 config,
                e.g. LCS fields of a PROS run, are skipped). | cell

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
fields = {'storm_duration', 'mcs_nYears', 'mcs_nLC', 'lcs_restrict_sampling_rate', 'lcs_effective_sampling_rate',...
    'lcs_convergence_results', 'swl_slr', 'apply_random_tides', 'tide_file', 'tide_indx_xc', 'tide_indx_tc', 'tide_indx_cc'};
end

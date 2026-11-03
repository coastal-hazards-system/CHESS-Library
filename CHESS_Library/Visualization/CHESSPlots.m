function sp = CHESSPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
% CHESSPlots  Create the plotting object for the workflow of a CHESS run.
%   sp = CHESSPlots(config, Resp, storm, project_forcing, dsw, structure,
%       base_fnt, unit_system) returns the plotting object of the workflow
%       in config.workflow. Its methods draw the plots of the saved run
%       results into axes, grid layouts or figures (nothing is recomputed
%       except where a method says so).
%
%   config.workflow selects the class:
%     1 (PROS-RB) or 4 (PROS-FB) - pros_methods
%     2 (DET)                    - det_methods
%     3 (LCS)                    - lcs_methods
%   Every class derives from CHESSPlotsBase, so the shared plots (PSE
%   transect, storm data space, event hydrograph, storm event viewer,
%   response table) are available for every workflow. Any other workflow
%   number errors with CHESSPlots:unsupportedWorkflow.
%
%   Inputs:
%     config          - run configuration struct (call_input_parser /
%                       call_chess_boundary_conditions); workflow selects
%                       the class, the plots read labels and settings
%                       from it (region, sp_ID, struc_id, case_name,
%                       project_datum, add_toe_berm, pros_use_aep,
%                       project_CLs, mcs_nYears, ...)
%     Resp            - saved structure responses of the run
%                       (Resp.<data_type>.<match_type>.<storm_type>);
%                       [] when only forcing or storm plots are drawn
%     storm           - storm database variable "storm"
%                       (storm.<storm_type>.<data_type>.<match_type>);
%                       [] when no storm database plot is drawn
%     project_forcing - project forcing of the run
%                       (call_chess_boundary_conditions output); [] when
%                       not needed
%     dsw             - storm probability masses of the storm database
%                       ("prob_mass": TC_Freq, TC_SRR, smpl1-smpl3), used
%                       by the PROS run-sample overlay (TC) and the LCS
%                       sampling scheme dashboard; [] otherwise
%     structure       - PSE structure struct saved with the run
%                       (struc_type, elevations, slopes, berm geometry)
%     base_fnt        - base font size [pt] (titles +2, ticks -2); the
%                       GUI passes app.plotFontSize (12)
%     unit_system     - 'SI' or 'Imperial': unit symbols written in axis
%                       labels (aux_methods.build_unit_library); the data
%                       are not converted
%   Outputs:
%     sp - pros_methods, det_methods or lcs_methods object
%
%   Tier: public
%
%   See also CHESSPlotsBase, pros_methods, det_methods, lcs_methods.

switch config.workflow
    case {1, 4}
        sp = pros_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    case 2
        sp = det_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    case 3
        sp = lcs_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    otherwise
        error('CHESSPlots:unsupportedWorkflow', 'Workflow %d is not supported.', config.workflow);
end
end

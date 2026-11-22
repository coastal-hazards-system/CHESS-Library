function sp = CHESSPlots(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system)
% chess.Visualization.CHESSPlots  Create the plotting object for the workflow of a CHESS run.
%   sp = chess.Visualization.CHESSPlots(config, Resp, storm, project_forcing, dsw, structure,
%       base_fnt, unit_system) returns the plotting object of the workflow
%       in config.workflow. Its methods draw the plots of the saved run
%       results into axes, grid layouts or figures (nothing is recomputed
%       except where a method says so).
%
%   config.workflow selects the class:
%     1 (PROS-RB) or 4 (PROS-FB) - chess.Visualization.pros_methods
%     2 (DET)                    - chess.Visualization.det_methods
%     3 (LCS)                    - chess.Visualization.lcs_methods
%   Every class derives from chess.Visualization.CHESSPlotsBase, so the shared plots (PSE
%   transect, storm data space, event hydrograph, storm event viewer,
%   response table) are available for every workflow. Any other workflow
%   number errors with chess:Visualization:CHESSPlots:unsupportedWorkflow.
%
%   Inputs:
%     config          - run configuration struct (chess.Model.create /
%                       chess.Model.build_forcing); workflow selects
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
%                       (chess.Model.build_forcing output); [] when
%                       not needed
%     dsw             - storm probability masses of the storm database
%                       ("prob_mass": TC_Freq, TC_SRR, smpl1-smpl3), used
%                       by the PROS run-sample overlay (TC) and the LCS
%                       sampling scheme dashboard; [] otherwise
%     structure       - PSE structure struct saved with the run
%                       (struc_type, elevations, slopes, berm geometry)
%     base_fnt        - base font size [pt] (titles +2, ticks -2); the
%                       GUI passes app.plotFontSize (12)
%     unit_system     - 'SI' or 'Imperial': unit system of the plots,
%                       tables and labels (chess.Common.chess_units); the
%                       other inputs are SI and are shown through display
%                       copies (chess.Visualization.CHESSPlotsBase)
%   Outputs:
%     sp - chess.Visualization.pros_methods, chess.Visualization.det_methods or chess.Visualization.lcs_methods object
%
%   See also chess.Visualization.CHESSPlotsBase, chess.Visualization.pros_methods, chess.Visualization.det_methods, chess.Visualization.lcs_methods.

switch config.workflow
    case {1, 4}
        sp = chess.Visualization.pros_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    case 2
        sp = chess.Visualization.det_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    case 3
        sp = chess.Visualization.lcs_methods(config, Resp, storm, project_forcing, dsw, structure, base_fnt, unit_system);
    otherwise
        error('chess:Visualization:CHESSPlots:unsupportedWorkflow', 'Workflow %d is not supported.', config.workflow);
end
end

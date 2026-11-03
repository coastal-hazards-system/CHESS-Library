function fb_curve = frequency_based_hazard_curve(config, structure, hazard_curves, storm_type, response_name)
% frequency_based_hazard_curve  Frequency-based hazard curve of one response.
%   fb_curve = frequency_based_hazard_curve(config, structure,
%       hazard_curves, storm_type, response_name)
%
%   Frequency-based (FB, EB2) hazard curve of one PROS response, for the
%   comparison with its response-based (RB) curve. The best-estimate
%   forcing hazard curves (pros_forcing_curves: SWL, Hm0_offshore,
%   Hm0_toe, Tp) are paired at equal AEF/AEP, the response is evaluated on
%   a Monte Carlo of those paired forcing values perturbed with the run's
%   forcing uncertainties, and its confidence limits are read from the
%   sorted samples (chess_pros_frequency_base, workflow 4).
%   The saved forcing hazard curves of the run are reused (no refit); only
%   the requested response is computed and nothing is written to disk.
%   The Monte Carlo draws are not seeded.
%   Errors: frequency_based_hazard_curve:missingForcingCurves (a forcing
%   curve is missing), frequency_based_hazard_curve:notEligible.
%
%   Inputs:
%     config        - saved run config (PROS-RB), 1x1 struct
%     structure     - saved run structure, 1x1 struct
%     hazard_curves - saved hazard curves of one dataset and storm type
%                     (Resp.<data type>.<match type>.<storm type>), struct
%                     array
%     storm_type    - 'XC', 'TC' or 'CC' (sets the uncertainty
%                     partition), char
%     response_name - response to compute; must be a response_registry row
%                     fitted_by_pros_rb that is computed for Peaks (not
%                     Q_vol*) and applies to config.struc_type (else
%                     frequency_based_hazard_curve:notEligible), char
%   Outputs:
%     fb_curve - FB hazard curve entry (same fields as the saved entries;
%                POT is a note), [] if the response was not produced,
%                struct
%
%   Tier: internal
%
%   See also chess_pros_frequency_base, chess_pros, pros_forcing_curves,
%   response_registry.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

forcing_names = pros_forcing_curves();
missing = setdiff(forcing_names, {hazard_curves.var}, 'stable');
if ~isempty(missing)
    error('frequency_based_hazard_curve:missingForcingCurves',...
        'The %s hazard curves have no forcing curve for %s: run PROS with the forcing hazard curves on.',...
        storm_type, strjoin(missing, ', '));
end
row = response_registry('name', response_name, 'fitted_by_pros_rb', true, 'data_type', 'Peaks', 'structure_type', config.struc_type);
if isempty(row)
    error('frequency_based_hazard_curve:notEligible',...
        '%s has no frequency-based hazard curve for this structure type (PROS-RB fitted responses computed for Peaks only).', response_name);
end

config_fb = config;
for switch_name = response_registry('output', 'switches')
    config_fb.(switch_name{1}) = 0;
end
config_fb.(row.compute_switch) = 1;
config_fb.compute_q_vol = 0;

forcing_entries = hazard_curves(ismember({hazard_curves.var}, forcing_names));
fb_curves = chess_pros_frequency_base(config_fb, structure, struct(storm_type, forcing_entries), '', 4);
fb_curves = fb_curves.(storm_type);
fb_curve = fb_curves(strcmp({fb_curves.var}, response_name));
if isempty(fb_curve)
    fb_curve = [];
end
end

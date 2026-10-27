function Resp = chess_det(config, project_forcing, structure, emp_coeff)
%{
    %% DESCRIPTION
        CHESS: Deterministic (workflow 2). Computes structure responses
        for every storm in one dataset (Peaks Default/WLP/WHP or
        Timeseries), straight from the adjusted storm forcing: no
        replicates, no uncertainty, no hazard curves.
        Full histories are kept (one value per time step; Peaks have a
        single step per storm). "Max" holds one value per storm: the
        maximum of each variable over the storm, taken independently
        (non-concurrent), except Rc, which takes the minimum (smallest
        freeboard). Same reduction as compute_structure_response with
        get_max = 1.

    %% INPUTS
        config: CHESS configuration. | struc
        project_forcing: One dataset, project_forcing.(data).(match). | struc
            Fields per storm type, from chess_det_formater and
            adjust_project_forcing.
        structure: CHESS structure geometry. | struc
        emp_coeff: Empirical coefficients (load_empirical_coefficients). | struc

    %% OUTPUTS
        Resp.(storm_type) with fields:
            storm_id: Storm IDs. | double (nStorms x 1)
            h, Rc: Derived forcing per storm, h = SWL - toe_elevation,
                Rc = crest_elevation - SWL. | cell
            <response>: Every response computed by
                compute_structure_response (R2p, q, Dn50, ...). | cell
            Max: One value per storm for storm_id, the forcing (SWL,
                Hm0_offshore, Hm0_toe, Tp), h, Rc and every response,
                plus time (datenum of the peak SWL). | struc
        The forcing itself (time, dt, SWL, Hm0_offshore, Hm0_toe, Tp) is
        not copied: read it from project_forcing, same data type, match
        type and storm type, same row order (one row per storm).
        Hm0_offshore is the database wave height (Goda pressures, damaging
        depth), Hm0_toe the one depth limited at the toe (every other
        response).

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
storm_types = fieldnames(project_forcing);
for st = 1:length(storm_types)
    pf = project_forcing.(storm_types{st});
    % Forcing As Used By The Response Equations (Forcing Copies Only Feed storm_maxima, Dropped Below)
    out.storm_id = pf.storm_id;
    out.time = pf.time;
    out.dt = pf.dt;
    out.SWL = pf.SWL;
    out.Hm0_offshore = pf.Hm0_offshore; % Database Wave Height
    out.Hm0_toe = pf.Hm0_toe; % After Depth Limitation (Equal To Hm0_offshore When Off, Except An Emergent Toe)
    out.Tp = pf.Tp;
    out.h = cellfun(@(x) x - structure.toe_elevation, pf.SWL, 'un', false);
    out.Rc = cellfun(@(x) structure.crest_elevation - x, pf.SWL, 'un', false);
    % Structure Responses (Full Histories)
    R = compute_structure_response(config, structure, pf, emp_coeff, 0);
    if ~isempty(R)
        resp_names = fieldnames(R);
        for rr = 1:length(resp_names)
            out.(resp_names{rr}) = R.(resp_names{rr});
        end
    end
    % One Value Per Storm (Forcing Maxima Included), Then The Forcing Copies Are Dropped (Rows Match project_forcing)
    out.Max = storm_maxima(out);
    out = rmfield(out, {'time', 'dt', 'SWL', 'Hm0_offshore', 'Hm0_toe', 'Tp'});
    Resp.(storm_types{st}) = out;
    clear out
end
end

function Max = storm_maxima(out)
skip = {'storm_id', 'time', 'dt'};
names = setdiff(fieldnames(out), skip, 'stable');
Max.storm_id = out.storm_id;
for kk = 1:length(names)
    v = out.(names{kk});
    if isnumeric(v) && numel(v) == numel(out.storm_id) % Already One Value Per Storm (Q_vol)
        Max.(names{kk}) = v(:);
    elseif iscell(v) && all(cellfun(@(x) isnumeric(x) && size(x, 2) == 1, v))
        if strcmp(names{kk}, 'Rc')
            Max.(names{kk}) = cellfun(@(x) min(x, [], 1), v);
        else
            Max.(names{kk}) = cellfun(@(x) max(x, [], 1), v);
        end
    end
end
% Time Of Peak SWL (Peaks: The Single Record)
[~, ix] = cellfun(@(x) max(x, [], 1), out.SWL);
Max.time = cellfun(@(t, i) t(i), out.time, num2cell(ix));
end

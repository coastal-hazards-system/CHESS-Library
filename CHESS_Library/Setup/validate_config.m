function problems = validate_config(config)
% validate_config  Check a CHESS config against the inputs of its workflow and structure.
%   validate_config(config)            errors with every problem found
%   problems = validate_config(config) returns the problems, no error
%
%   Run by call_input_parser right after the input file is read and by the
%   GUI before a run (chessRunPlanner.plan_run), so a run with a missing or
%   invalid input stops at the start with the full list instead of at the
%   first step that reads it. Rules (local input_rule):
%     run settings (every workflow) - project_name, struc_id, case_name,
%       outfolder, project_CLs, tide_file (text); project_datum (text,
%       may be blank); storm_sampling (XC, TC or CC); swl_slr (number);
%       apply_random_tides, apply_depth_limitation, use_peaks,
%       use_timeseries, create_wlp, create_whp (0/1); storm_duration
%       (> 0); compute_storm_duration (0/1), chs_zip and chs_dependencies
%       (text) optional
%     PROS (workflows 1, 4) - pros_use_aep, pros_compute_forcing_HC (0/1)
%     DET (workflow 2)      - none
%     LCS (workflow 3)      - mcs_nLC, mcs_nYears (whole, >= 1);
%       load_project_forcing (0/1); ref_case_name (text, when
%       load_project_forcing is 1); csr_call_dpa (0/1, optional);
%       csr_apply_structure_repair (0-3), csr_apply_cutoff_correction
%       (0/1), csr_cutoff_offset (>= 0) when csr_call_dpa is 1;
%       lcs_restrict_sampling_rate (0/1), lcs_convergence_tol (> 0),
%       lcs_convergence_confidence (> 0, <= 1), lcs_convergence_prompt
%       (0/1), all optional
%     every structure - crest_elevation (number), crest_width (>= 0),
%       water_density, roughness_ifactor, offshore_slope (> 0),
%       offshore_elevation (number, optional: check_offshore_elevation
%       requires it once the storm database value is known),
%       compute_damaging_depth_Ks (>= 0, when compute_damaging_depth is 1)
%       and every response_registry compute switch of the structure type
%       (0/1)
%     Levee       - toe_elevation (number), seaside_slope, leeside_slope
%                   (> 0)
%     Floodwall   - wall_bottom_elevation (number)
%     Rubblemound - toe_elevation (number), seaside_slope, leeside_slope,
%                   nearshore_slope, armor_delta, seaside_mass,
%                   leeside_mass, seaside_design_S, leeside_design_S,
%                   seaside_S_uls, leeside_S_uls (> 0), cem_P (> 0, <= 1),
%                   dn50_use_legacy_model and
%                   dn50_legacy_submerged_correction (0/1, optional)
%   workflow (chess_workflows number) and struc_type (1, 2 or 3) are
%   checked first; when either is invalid only they are reported, since
%   they select the other rules. Combined checks: at least one of
%   use_peaks and use_timeseries is 1, tide_file exists when
%   apply_random_tides is 1, and the crest is above the toe (floodwall:
%   above the wall bottom). Inputs that are not listed by a rule are not
%   checked.
%
%   Inputs:
%     config - CHESS configuration as read (call_input_parser) or built by
%              the GUI (chessRunPlanner.run_config), 1x1 struct
%   Outputs:
%     problems - one line per problem, '<input> (<owner>): <problem>',
%                n x 1 cell of char (empty when the config is valid).
%                Without this output a non-empty list raises
%                validate_config:invalidInputs.
%
%   Tier: internal
%
%   See also call_input_parser, finalize_config, check_offshore_elevation,
%   response_registry, chess_workflows.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% WORKFLOW AND STRUCTURE TYPE (THEY SELECT THE OTHER RULES)
selector_rules = [input_rule('workflow', 'choice', 'choices', [chess_workflows().number]),...
    input_rule('struc_type', 'choice', 'choices', [1 2 3])];
problems = rule_problems(config, selector_rules);

if isempty(problems)
    %% INPUTS OF THE WORKFLOW AND OF THE STRUCTURE
    rules = [workflow_input_rules(config.workflow), structure_input_rules(config.struc_type)];
    problems = rule_problems(config, rules);

    %% COMBINED CHECKS
    if is_switch(config, 'use_peaks') && is_switch(config, 'use_timeseries') &&...
            config.use_peaks == 0 && config.use_timeseries == 0
        problems{end+1, 1} = 'use_peaks, use_timeseries: at least one must be 1.';
    end
    if is_switch(config, 'apply_random_tides') && config.apply_random_tides == 1 && isfield(config, 'tide_file') &&...
            is_text(config.tide_file) && exist(char(config.tide_file), 'file') ~= 2
        problems{end+1, 1} = sprintf('tide_file: file not found (needed when apply_random_tides is 1; got ''%s'').',...
            char(config.tide_file));
    end
    base_field = 'toe_elevation';
    if config.struc_type == 2
        base_field = 'wall_bottom_elevation';
    end
    if is_number(config, 'crest_elevation') && is_number(config, base_field) &&...
            config.crest_elevation <= config.(base_field)
        problems{end+1, 1} = sprintf('crest_elevation: must be above %s (got %g and %g).', base_field,...
            config.crest_elevation, config.(base_field));
    end
end

if nargout == 0 && ~isempty(problems)
    error('validate_config:invalidInputs', 'The CHESS inputs have %d problem(s):\n%s', numel(problems),...
        strjoin(strcat({'   - '}, problems), newline));
end
end

%% AUX FUNCTION: RULES OF THE RUN SETTINGS AND OF THE WORKFLOW'S OWN INPUTS
function rules = workflow_input_rules(workflow)
% Storm Data Inputs (chs_zip, chs_dependencies) Are Optional
shared = [...
    input_rule('project_name', 'text'),...
    input_rule('struc_id', 'text'),...
    input_rule('case_name', 'text'),...
    input_rule('outfolder', 'text'),...
    input_rule('project_datum', 'text', 'allow_blank', true),...
    input_rule('project_CLs', 'text'),...
    input_rule('storm_sampling', 'choice', 'choices', {'XC', 'TC', 'CC'}),...
    input_rule('swl_slr', 'number'),...
    input_rule('apply_random_tides', 'switch'),...
    input_rule('tide_file', 'text'),...
    input_rule('apply_depth_limitation', 'switch'),...
    input_rule('use_peaks', 'switch'),...
    input_rule('use_timeseries', 'switch'),...
    input_rule('create_wlp', 'switch'),...
    input_rule('create_whp', 'switch'),...
    input_rule('storm_duration', 'number', 'exclusive_minimum', 0),...
    input_rule('compute_storm_duration', 'switch', 'optional', true),...
    input_rule('chs_zip', 'text', 'optional', true),...
    input_rule('chs_dependencies', 'text', 'optional', true)];
[shared.owner] = deal('run');
switch workflow
    case {1, 4} % PROS-RB, PROS-FB
        own = [...
            input_rule('pros_use_aep', 'switch'),...
            input_rule('pros_compute_forcing_HC', 'switch')];
    case 2 % DET
        own = shared([]);
    case 3 % LCS: Damage Progression Inputs Only When csr_call_dpa Is 1; Hidden Sampling Settings Optional (finalize_config Defaults)
        own = [...
            input_rule('mcs_nLC', 'integer', 'minimum', 1),...
            input_rule('mcs_nYears', 'integer', 'minimum', 1),...
            input_rule('load_project_forcing', 'switch'),...
            input_rule('ref_case_name', 'text', 'required_if', 'load_project_forcing'),...
            input_rule('csr_call_dpa', 'switch', 'optional', true),...
            input_rule('csr_apply_structure_repair', 'choice', 'choices', [0 1 2 3], 'required_if', 'csr_call_dpa'),...
            input_rule('csr_apply_cutoff_correction', 'switch', 'required_if', 'csr_call_dpa'),...
            input_rule('csr_cutoff_offset', 'number', 'minimum', 0, 'required_if', 'csr_call_dpa'),...
            input_rule('lcs_restrict_sampling_rate', 'switch', 'optional', true),...
            input_rule('lcs_convergence_tol', 'number', 'exclusive_minimum', 0, 'optional', true),...
            input_rule('lcs_convergence_confidence', 'number', 'exclusive_minimum', 0, 'maximum', 1, 'optional', true),...
            input_rule('lcs_convergence_prompt', 'switch', 'optional', true)];
end
[own.owner] = deal(chess_workflows(workflow).wflow_name);
rules = [shared, own];
end

%% AUX FUNCTION: RULES OF THE STRUCTURE INPUTS AND OF THE RESPONSE SWITCHES OF THE STRUCTURE TYPE
function rules = structure_input_rules(struc_type)
shared = [...
    input_rule('crest_elevation', 'number'),...
    input_rule('crest_width', 'number', 'minimum', 0),...
    input_rule('water_density', 'number', 'exclusive_minimum', 0),...
    input_rule('roughness_ifactor', 'number', 'exclusive_minimum', 0),...
    input_rule('offshore_slope', 'number', 'exclusive_minimum', 0),...
    input_rule('offshore_elevation', 'number', 'optional', true),...
    input_rule('compute_damaging_depth_Ks', 'number', 'minimum', 0, 'required_if', 'compute_damaging_depth')];
switch struc_type
    case 1
        own = [...
            input_rule('toe_elevation', 'number'),...
            input_rule('seaside_slope', 'number', 'exclusive_minimum', 0),...
            input_rule('leeside_slope', 'number', 'exclusive_minimum', 0)];
        owner = 'levee';
    case 2 % toe_elevation Is Not An Input: A Floodwall Sits On Its Wall Bottom (finalize_structure_config)
        own = input_rule('wall_bottom_elevation', 'number');
        owner = 'floodwall';
    case 3
        own = [...
            input_rule('toe_elevation', 'number'),...
            input_rule('seaside_slope', 'number', 'exclusive_minimum', 0),...
            input_rule('leeside_slope', 'number', 'exclusive_minimum', 0),...
            input_rule('nearshore_slope', 'number', 'exclusive_minimum', 0),...
            input_rule('armor_delta', 'number', 'exclusive_minimum', 0),...
            input_rule('seaside_mass', 'number', 'exclusive_minimum', 0),...
            input_rule('leeside_mass', 'number', 'exclusive_minimum', 0),...
            input_rule('cem_P', 'number', 'exclusive_minimum', 0, 'maximum', 1),...
            input_rule('seaside_design_S', 'number', 'exclusive_minimum', 0),...
            input_rule('leeside_design_S', 'number', 'exclusive_minimum', 0),...
            input_rule('seaside_S_uls', 'number', 'exclusive_minimum', 0),...
            input_rule('leeside_S_uls', 'number', 'exclusive_minimum', 0),...
            input_rule('dn50_use_legacy_model', 'switch', 'optional', true),...
            input_rule('dn50_legacy_submerged_correction', 'switch', 'optional', true)];
        owner = 'rubblemound';
end
switches = cellfun(@(name) input_rule(name, 'switch'),...
    response_registry('output', 'switches', 'structure_type', struc_type));
rules = [shared, own, switches];
[rules.owner] = deal(owner);
end

%% AUX FUNCTION: ONE INPUT RULE (NAME, KIND: switch | number | integer | text | choice, OPTIONS AS NAME-VALUE PAIRS)
function rule = input_rule(name, kind, varargin)
% optional: may be missing or empty; required_if: required only when that config field is 1; allow_blank: a text
% input may be blank; minimum / exclusive_minimum / maximum: limits of a number; choices: values of a choice
rule = struct('name', name, 'kind', kind, 'owner', '', 'optional', false, 'required_if', '', 'allow_blank', false,...
    'minimum', [], 'exclusive_minimum', [], 'maximum', [], 'choices', []);
for ii = 1:2:numel(varargin)
    rule.(varargin{ii}) = varargin{ii+1};
end
end

%% AUX FUNCTION: ONE LINE PER RULE THE CONFIG DOES NOT MEET
function problems = rule_problems(config, rules)
problems = cell(0, 1);
for ii = 1:numel(rules)
    message = rule_problem(config, rules(ii));
    if ~isempty(message)
        owner = '';
        if ~isempty(rules(ii).owner)
            owner = [' (' rules(ii).owner ')'];
        end
        problems{end+1, 1} = sprintf('%s%s: %s', rules(ii).name, owner, message); %#ok<AGROW>
    end
end
end

%% AUX FUNCTION: PROBLEM OF ONE INPUT ('' WHEN IT MEETS ITS RULE)
function message = rule_problem(config, rule)
message = '';
is_missing = ~isfield(config, rule.name) || isempty(config.(rule.name)) || ...
    (isstring(config.(rule.name)) && isscalar(config.(rule.name)) && ismissing(config.(rule.name)));
if is_missing
    blank_text_allowed = strcmp(rule.kind, 'text') && rule.allow_blank && isfield(config, rule.name);
    required = ~rule.optional;
    if ~isempty(rule.required_if)
        required = is_switch(config, rule.required_if) && config.(rule.required_if) == 1;
    end
    if required && ~blank_text_allowed
        message = 'missing.';
        if ~isempty(rule.required_if)
            message = sprintf('missing (needed when %s is 1).', rule.required_if);
        end
    end
    return
end
value = config.(rule.name);
switch rule.kind
    case 'switch'
        if ~is_switch(config, rule.name)
            message = ['must be 0 or 1' got(value)];
        end
    case {'number', 'integer'}
        if ~is_number(config, rule.name)
            message = ['must be a number' got(value)];
        elseif strcmp(rule.kind, 'integer') && value ~= round(value)
            message = ['must be a whole number' got(value)];
        elseif ~isempty(rule.minimum) && value < rule.minimum
            message = sprintf('must be %g or larger%s', rule.minimum, got(value));
        elseif ~isempty(rule.exclusive_minimum) && value <= rule.exclusive_minimum
            message = sprintf('must be larger than %g%s', rule.exclusive_minimum, got(value));
        elseif ~isempty(rule.maximum) && value > rule.maximum
            message = sprintf('must be %g or smaller%s', rule.maximum, got(value));
        end
    case 'text'
        if ~is_text(value)
            message = ['must be text' got(value)];
        elseif ~rule.allow_blank && isempty(strtrim(char(value)))
            message = 'must not be blank.';
        end
    case 'choice'
        if iscell(rule.choices)
            if ~is_text(value) || ~ismember(char(value), rule.choices)
                message = sprintf('must be one of %s%s', strjoin(rule.choices, ', '), got(value));
            end
        elseif ~is_number(config, rule.name) || ~ismember(value, rule.choices)
            message = sprintf('must be one of %s%s', strjoin(arrayfun(@num2str, rule.choices, 'un', false), ', '), got(value));
        end
end
end

%% AUX FUNCTION: 0/1 SCALAR
function tf = is_switch(config, name)
tf = isfield(config, name) && (isnumeric(config.(name)) || islogical(config.(name))) && isscalar(config.(name)) &&...
    ismember(double(config.(name)), [0 1]);
end

%% AUX FUNCTION: FINITE REAL SCALAR
function tf = is_number(config, name)
tf = isfield(config, name) && isnumeric(config.(name)) && isscalar(config.(name)) && isreal(config.(name)) &&...
    isfinite(config.(name));
end

%% AUX FUNCTION: CHAR ROW OR STRING SCALAR
function tf = is_text(value)
tf = (ischar(value) && (isrow(value) || isempty(value))) || (isstring(value) && isscalar(value));
end

%% AUX FUNCTION: ' (got <value>).' FOR THE PROBLEM LINE
function text = got(value)
if is_text(value)
    text = sprintf(' (got ''%s'').', char(value));
elseif (isnumeric(value) || islogical(value)) && isscalar(value)
    text = sprintf(' (got %g).', double(value));
else
    text = sprintf(' (got a %s %s).', mat2str(size(value)), class(value));
end
end

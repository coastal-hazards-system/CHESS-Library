function problems = validate(config)
% validate  Check a CHESS config against the inputs its classes need.
%   chess.Config.validate(config)            errors with every problem found
%   problems = chess.Config.validate(config) returns the problems, no error
%
%   Run by chess.Model.create before anything else, so a run with a
%   missing or invalid input stops at the start with the full list
%   instead of at the first step that reads it. The rules come from the
%   classes of the run:
%     chess.Model.input_rules(workflow)              run settings and the
%                                                    workflow's own inputs
%     chess.ProtectionSystem.input_rules(struc_type) geometry, properties
%                                                    and response switches
%                                                    of the structure
%   workflow and struc_type are checked first; when either is invalid
%   only they are reported, since they select the other rules.
%   Combined checks: at least one of use_peaks and use_timeseries is 1,
%   tide_file exists when apply_random_tides is 1, and the crest is above
%   the toe (floodwall: above the wall bottom).
%   Inputs that are not listed by a rule are not checked.
%
%   Inputs:
%     config - CHESS configuration as read (chess.Config.read) or built
%              by the caller, 1x1 struct
%   Outputs:
%     problems - one line per problem, n x 1 cell of char (empty when the
%                config is valid). Without this output a non-empty list
%                raises chess:Config:validate:invalidInputs.
%
%   See also chess.Config.input_rule, chess.Model.input_rules,
%   chess.ProtectionSystem.input_rules, chess.Config.apply_rules.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% WORKFLOW AND STRUCTURE TYPE (THEY SELECT THE OTHER RULES)
selector_rules = [chess.Config.input_rule('workflow', 'choice', 'choices', [chess.Model.workflows().number]),...
    chess.Config.input_rule('struc_type', 'choice', 'choices', [1 2 3])];
problems = rule_problems(config, selector_rules);

if isempty(problems)
    %% INPUTS OF THE WORKFLOW AND OF THE STRUCTURE
    rules = [chess.Model.input_rules(config.workflow), chess.ProtectionSystem.input_rules(config.struc_type)];
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
    error('chess:Config:validate:invalidInputs', 'The CHESS inputs have %d problem(s):\n%s', numel(problems),...
        strjoin(strcat({'   - '}, problems), newline));
end
end

%% LOCAL FUNCTIONS
function problems = rule_problems(config, rules)
% One Line Per Rule The Config Does Not Meet
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

function message = rule_problem(config, rule)
% Problem Of One Input ('' When It Meets Its Rule)
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
    otherwise
        error('chess:Config:validate:unknownRuleKind', 'Unknown input rule kind %s (input %s).', rule.kind, rule.name);
end
end

function tf = is_switch(config, name)
tf = isfield(config, name) && (isnumeric(config.(name)) || islogical(config.(name))) && isscalar(config.(name)) &&...
    ismember(double(config.(name)), [0 1]);
end

function tf = is_number(config, name)
tf = isfield(config, name) && isnumeric(config.(name)) && isscalar(config.(name)) && isreal(config.(name)) &&...
    isfinite(config.(name));
end

function tf = is_text(value)
tf = (ischar(value) && (isrow(value) || isempty(value))) || (isstring(value) && isscalar(value));
end

function text = got(value)
% ' (got <value>).' For The Problem Line
if is_text(value)
    text = sprintf(' (got ''%s'').', char(value));
elseif (isnumeric(value) || islogical(value)) && isscalar(value)
    text = sprintf(' (got %g).', double(value));
else
    text = sprintf(' (got a %s %s).', mat2str(size(value)), class(value));
end
end

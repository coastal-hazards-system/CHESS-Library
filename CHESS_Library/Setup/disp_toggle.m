function disp_toggle(response, prompt)
% disp_toggle  Display a message when progress printing is on.
%   disp_toggle(response, prompt) displays prompt (disp) when response is
%   true; nothing happens otherwise.
%
%   Inputs:
%     response - print switch (callers pass config.print_progress), logical
%                or 0/1
%     prompt   - message to display, char or string
%   Outputs:
%     none; prompt printed to the Command Window
%
%   Tier: internal
if response
    disp(prompt);
end
end
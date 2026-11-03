function customColormap = chess_colormap(target)
% chess_colormap  Apply the CHESS colormap (magenta-blue into jet).
%   customColormap = chess_colormap(target) sets the 64-color CHESS
%       colormap (8 colors from magenta to blue followed by jet(56)) on
%       target and returns it.
%
%   Inputs:
%     target - figure, axes or other colormap-bearing graphics object
%   Outputs:
%     customColormap - the colormap applied, 64 x 3 double (optional)
%
%   Tier: internal
%
%   See also det_methods, lcs_methods.

% Define the number of colors
numColors = 64;
% Number of colors for the transition zone
transitionColors = 8;
% Create a colormap ranging from magenta to blue
startColor = [0.8 0 1];  % Magenta
endColor = [0 0 1];      % Blue
magentaSection = [linspace(startColor(1), endColor(1), transitionColors);
    linspace(startColor(2), endColor(2), transitionColors);
    linspace(startColor(3), endColor(3), transitionColors)]';
% Append the rest of the jet colormap
jetMap = jet(numColors - transitionColors);
% Concatenate magenta to blue and jet colormap
customColormap = [magentaSection; jetMap];
colormap(target, customColormap);
end
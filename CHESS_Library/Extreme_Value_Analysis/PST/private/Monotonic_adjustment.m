function [y_in] = Monotonic_adjustment(x_in,y_in)
% Monotonic_adjustment  Remove jumps from a hazard curve.
%   y_out = Monotonic_adjustment(x_in, y_in)
%
%   PST can give non-monotonic curves when the MRL threshold is too low
%   (incomplete random samples, jumps in the mean curve and CLs). On
%   log(x_in), every segment with a positive slope (response increasing
%   with the exceedance frequency) is replaced: its end value becomes the
%   start value plus the mean of the two preceding slopes times the
%   segment length. NaN values are kept in place.
%
%   Inputs:
%     x_in - AEF or AEP of the curve, vector > 0
%     y_in - hazard curve response at x_in, vector (numel(x_in))
%   Outputs:
%     y_out - adjusted response, 1 x numel(y_in) double (row vector; the
%             output variable is named y_in in the code)
%
%   Tier: internal
%
%   See also CHESS_PST_Fit.
%
%   Developed by: E. Ramos-Santiago

% History of revisions:
% 20210310-ERS: created function to patch the SST tool.

% Change inputs to column vector
y_in=y_in(:);x_in=log(x_in(:));

% Take numbers
idx3=~isnan(y_in);y=y_in(idx3);x=x_in(idx3);

% Compute slope
dx=diff(x);dy=diff(y);s=dy./dx;

% Identify positive slopes
id_pos=find(s>0);

% Adjust y values with positive slopes
if ~isempty(id_pos)
    for i=1:length(id_pos)
        y(id_pos(i)+1)=mean(s(id_pos(i)-2:id_pos(i)-1))*dx(id_pos(i))+y(id_pos(i));
    end
    
    % Return values to original position
    y_in(idx3)=y;
end
y_in=y_in';
end
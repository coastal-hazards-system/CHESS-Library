function [in] = aef2aep(in)
% aef2aep  Convert annual exceedance frequency (AEF) to probability (AEP).
%   aep = aef2aep(aef)
%
%   AEP = 1 - exp(-AEF), the probability of at least one exceedance in a
%   year for a Poisson event rate AEF (inverse of aep2aef). The code
%   names the output in (the input is overwritten).
%
%   Inputs:
%     aef - annual exceedance frequency [1/yr], any size
%   Outputs:
%     aep - annual exceedance probability [-], size of aef
%
%   Tier: public
%
%   See also aep2aef, CHESS_JPM, CHESS_PST.
in = (exp(in)-1)./exp(in);
end
function aef = aep2aef(aep)
% aep2aef  Convert annual exceedance probability (AEP) to frequency (AEF).
%   aef = aep2aef(aep)
%
%   AEF = -log(1 - AEP), the Poisson event rate with probability AEP of at
%   least one exceedance in a year (inverse of aef2aep).
%
%   Inputs:
%     aep - annual exceedance probability [-], any size, values in [0 1)
%   Outputs:
%     aef - annual exceedance frequency [1/yr], size of aep
%
%   Tier: public
%
%   See also aef2aep, CHESS_JPM, CHESS_PST.
aef = -log(1-aep);
end


function boot = ecdf_boot(empHC,Nsim)
% ecdf_boot  Bootstrap samples of an empirical response sample.
%   boot = ecdf_boot(empHC, Nsim)
%
%   Each simulation draws numel(empHC) values with replacement
%   (datasample), adds normal noise scaled by the gap between the drawn
%   value and the next one of the input (the last gap repeated), and sorts
%   the result in descending order. The random generator is reset
%   (rng('default')) on every call, so the samples are reproducible.
%
%   Inputs:
%     empHC - response sample sorted in descending order, column vector
%     Nsim  - number of bootstrap simulations, scalar
%   Outputs:
%     boot - bootstrap samples, one row per simulation sorted in
%            descending order, Nsim x numel(empHC) double
%
%   Tier: internal
%
%   See also CHESS_PST_Fit.
%
%   Developed by: Norberto C. Nadal-Caraballo, PhD (NCNC)

% CONTRIBUTORS:
%     Efrain Ramos-Santiago (ERS)
%
% HISTORY OF REVISIONS:
% 20201015-ERS: revised. Updated documentation.
%
% ***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
rng('default');
Nstrm = size(empHC,1);
dlt = abs(diff(empHC)); dlt = [dlt;dlt(end)];
boot=zeros(Nsim,Nstrm);
for i = 1:Nsim
    [x,idx] = datasample(empHC,Nstrm);
    y = x + randn(Nstrm,1).*dlt(idx);
    boot(i,:) = sort(y,'descend')';
end
end
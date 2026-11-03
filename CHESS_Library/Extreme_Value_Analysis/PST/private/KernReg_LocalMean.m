function [X,Y] = KernReg_LocalMean(x,y,H)
% KernReg_LocalMean  Local mean (Nadaraya-Watson) kernel regression.
%   [X, Y] = KernReg_LocalMean(x, y, H)
%
%   Non-parametric local mean (order 0) regression with a normal kernel,
%   following Wand & Jones (1994, Ch. 5, Sec. 2): Y(i) is the kernel
%   weighted mean of y around X(i,:). Uni- or multivariate predictors,
%   with the same kernel and bandwidth for every predictor; the prediction
%   grid is the predictors themselves. Adapted from a local polynomial
%   (order 0 or 1) script; only the local mean is kept. CHESS_MRL uses it
%   to remove the noise of the WMSE curve.
%   Reference: Wand, M. P., and Jones, M. C. (1994). Kernel smoothing.
%   Chapman & Hall/CRC Monographs on Statistics & Applied Probability.
%
%   Inputs:
%     x - predictor matrix, one predictor per column, n x k double
%     y - response, n x 1 double
%     H - kernel bandwidth [x units], scalar > 0 (CHESS_MRL passes the
%         ksdensity bandwidth of x divided by 7)
%   Outputs:
%     X - prediction grid (= x), n x k double
%     Y - local mean prediction at X, n x 1 double
%
%   Tier: internal
%
%   See also CHESS_MRL.
%
%   Developed by: E. Ramos-Santiago

% History of revisions:
% 20171206-ERS: developed first draft of function.
% 20180228-ERS: made revision.
% 20190109-ERS: expanded algorithm to incorporate multivariate regression using p=0/p=1, only.
% 20210505-ERS: adapted.
[n,k] = size(x); %sample size and dimensionality
X = x;

% setup regression parameters
NN=size(X,1);Y=zeros(NN,1);
Kh =@(H,t,k)H^(-k)*(2*pi)^(k/2)*exp(-0.5*t); %d-variate Normal kernel

%do regression
for i = 1:NN %grid point loop
    t = sum(bsxfun(@minus, X(i,:), x).^2,2)./(H^2);
    Xx = ones(n,1);
    Wx = diag(Kh(H,t,k));
    Y(i) = (Xx'*Wx*Xx)\(Xx'*Wx)*y;
end
end
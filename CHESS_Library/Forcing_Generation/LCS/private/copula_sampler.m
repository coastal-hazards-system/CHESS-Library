function Y = copula_sampler(storm_peaks, storm_indexes)  
% copula_sampler  Draw XC peak values from a Gaussian copula of the peaks.
%   Y = copula_sampler(storm_peaks, storm_indexes)
%
%   Fits a Gaussian copula to the four peak columns (marginals: kernel
%   density CDFs, ksdensity; correlation from Kendall's tau, copulaparam)
%   and draws one row per element of storm_indexes (copularnd), mapped
%   back to values with the kernel inverse CDFs. The drawn values are not
%   tied to the sampled storm IDs: storm_indexes only sets the number of
%   draws. Each column is then scaled so its mean equals the storm_peaks
%   column mean (NaN omitted), and Hm0 values below 0.05 m are set to
%   0.05 m. Uses the global random number stream.
%
%   Inputs:
%     storm_peaks   - XC peak values [SWL, Hm0, Tp, wDir]: SWL [m, study
%                     datum], Hm0 [m], Tp [s], wDir [deg], nStorms x 4
%                     double
%     storm_indexes - sampled storm IDs (only the row count is used),
%                     nEvents x 1 double
%   Outputs:
%     Y - sampled peak values [SWL, Hm0, Tp, wDir] (units as storm_peaks),
%         nEvents x 4 double
%
%   Tier: internal
%
%   See also sample_xc_storm.

%% COMPUTE GAUSSIAN COPULA STATISTICAL PARAMETERS & SAMPLE STORMS
    % Returns a probability density estimate, f, for each sample data column
    for k = 1:4
        X(:,k) = ksdensity(storm_peaks(:,k),storm_peaks(:,k),'function','cdf');
    end
    % Compute Tau
    Tau = corr(X,'type','Kendall'); % Maximums
    % Compute matrix of linear correlations (Rho)
    Rho = copulaparam('Gaussian',Tau,'type','Kendall'); % Maximums
    % Compute random values; where 'r' = normal probabilities (pdf)
    %sample random values from Gaussian copula
    r = copularnd('Gaussian',Rho,size(storm_indexes,1)); % Maximums
    % Computes 'inverse cumulative probability' (real values)
    for k = 1:4
        Y(:,k) = ksdensity(storm_peaks(:,k),r(:,k),'function','icdf');
    end

    %% SCALE SAMPLED STORM RESPONSES
    % Scale Responses By Individual Means
    Y = Y.*mean(storm_peaks, 1, "omitnan")./mean(Y, 1, "omitnan");
    % Cap sampled waves to positive values
    Y(Y(:,2)<0.05,2)=0.05;
end
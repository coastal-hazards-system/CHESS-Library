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
%   column mean (NaN omitted); the scale factors come from the first draw
%   and are kept. Rows whose scaled Hm0 is below 0.1 m are drawn again
%   (copula, kernel inverse CDFs, the same scale factors) until none
%   remain; errors (copula_sampler:copulaResampleLimit) when rows are
%   still below 0.1 m after 100 redraw rounds. Uses the global random
%   number stream.
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
    minimum_wave_height = 0.1; % [m]
    maximum_redraw_rounds = 100;
    % Returns a probability density estimate, f, for each sample data column
    for k = 1:4
        X(:,k) = ksdensity(storm_peaks(:,k),storm_peaks(:,k),'function','cdf');
    end
    % Compute Tau
    Tau = corr(X,'type','Kendall'); % Maximums
    % Compute matrix of linear correlations (Rho)
    Rho = copulaparam('Gaussian',Tau,'type','Kendall'); % Maximums
    Y = copula_draw(storm_peaks, Rho, size(storm_indexes,1));

    %% SCALE SAMPLED STORM RESPONSES
    % Scale Responses By Individual Means (Factors Of The First Draw, Kept For The Redraws)
    scale_factors = mean(storm_peaks, 1, "omitnan")./mean(Y, 1, "omitnan");
    Y = Y.*scale_factors;

    %% REDRAW STORMS WITH TOO SMALL WAVES
    redraw = Y(:,2) < minimum_wave_height;
    redraw_round = 0;
    while any(redraw)
        if redraw_round == maximum_redraw_rounds
            error('copula_sampler:copulaResampleLimit',...
                ['%d copula sampled XC storms still have Hm0 below %g m after %d redraw rounds: the XC peak ',...
                'wave heights are too small for the copula sampler.'], nnz(redraw), minimum_wave_height,...
                maximum_redraw_rounds);
        end
        redraw_round = redraw_round + 1;
        Y(redraw,:) = copula_draw(storm_peaks, Rho, nnz(redraw)).*scale_factors;
        redraw = Y(:,2) < minimum_wave_height;
    end
end

%% LOCAL FUNCTIONS
function Y = copula_draw(storm_peaks, Rho, number_of_draws)
% Gaussian Copula Draws Mapped Back To Peak Values With The Kernel Inverse CDFs Of The storm_peaks Columns
r = copularnd('Gaussian',Rho,number_of_draws);
Y = zeros(number_of_draws, 4);
for k = 1:4
    Y(:,k) = ksdensity(storm_peaks(:,k),r(:,k),'function','icdf');
end
end
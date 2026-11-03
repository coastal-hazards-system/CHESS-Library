function  [Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2, smpl3] = chs_probability_mass_loader(chs_dependencies_path, region, Nsvpt, sp_coords)
% chs_probability_mass_loader  Load the TC probability masses of a savepoint.
%   [Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2, smpl3] =
%       chs_probability_mass_loader(chs_dependencies_path, region, Nsvpt,
%       sp_coords)
%
%   Loads the CHS TC storm probability masses of the region's
%   CHS_Dependencies files (chs_dependency_files), needed by every TC
%   storm sampling. The savepoint's study grid point (savepoint_grid_row:
%   unique savepoint ID match, else the grid point nearest to sp_coords;
%   CHS-NA nearest only) gives the nearest coastal reference location
%   (CRL), whose storm recurrence rates (storms/yr/km) times 600 km give
%   TC_SRR, and the TC storms whose track passes within 200 km, split
%   into the intensity bins by central pressure deficit dP [hPa]: low
%   dP < 28, mid 28 <= dP < 48, high dP >= 48. Every output is empty
%   when the region has no TC statistics (tropical_statistics_available).
%
%   Inputs:
%     chs_dependencies_path - CHS_Dependencies folder, char
%     region                - CHS region, char
%     Nsvpt                 - ADCIRC savepoint ID (config.sp_ID), double
%     sp_coords             - savepoint [latitude longitude] [deg] ([] or
%                             NaN: not available), 1x2 double
%   Outputs:
%     Param     - TC storm parameters (Param_ITCS of the storm parameters
%                 file; column 1 storm ID; columns 1-4, 7, 5, 6 of the
%                 file, so dP is column 5), number_of_TC_storms x 7 double
%     TC_SRR    - TC storm recurrence rates at the CRL [storms/yr],
%                 1x4 double [low, mid, high, all]
%     TC_Freq   - TC discrete storm weights (DSW_ITCS of the discrete
%                 storm weights file) [storms/yr], double
%     TotalFreq - total TC storm suite frequency, sum(TC_Freq)
%                 [storms/yr], scalar double
%     smpl1     - storm IDs of the low intensity bin, column double
%     smpl2     - storm IDs of the mid intensity bin, column double
%     smpl3     - storm IDs of the high intensity bin, column double
%
%   Tier: internal
%
%   See also build_storm_database, chs_dependency_files,
%   savepoint_grid_row, prob_mass_validation.
%
%   Developed by: Fabian A. Garcia Moreno ERDC-CHL

%% CHS_DEPENDENCIES FILES (chs_dependency_files.m)
files = chs_dependency_files(chs_dependencies_path, region);

%% LOAD FILES BASED ON REGION
if files.tropical_statistics_available
    % CRL location info
    load(files.coastal_reference_locations_file, 'CRL');
    % Low intensity (LI) storm recurrence rate (SRR) at each CRL (storms/year/km).
    SRR_LI = load(files.storm_recurrence_rate_files.low_intensity);SRR_LI = SRR_LI.SRR;
    % Medium intensity (MI) storm SRR at each CRL.
    SRR_MI = load(files.storm_recurrence_rate_files.medium_intensity);SRR_MI = SRR_MI.SRR;
    % High intensity (HI) storm SRR at each CRL.
    SRR_HI = load(files.storm_recurrence_rate_files.high_intensity);SRR_HI = SRR_HI.SRR;
    % All storm SRR at each CRL.
    SRR_All = load(files.storm_recurrence_rate_files.all_intensities);SRR_All = SRR_All.SRR;
    % Storms relative probability at each save point.
    ProbMass = load(files.tc_discrete_storm_weights_file);ProbMass = ProbMass.DSW_ITCS;
    % Define Radius Of Influence For SRR
    radKm = 600;
    % Synthetic Storm Parameters
    Param = load(files.tc_storm_parameters_file);Param = Param.Param_ITCS;
    %{
                Load storm recurrence rate (SRR) associated with project save point. The
                SRR was computed at 1050 coastal reference locations (CRL) and the SRR from the closest CRL to the
                savepoint is used.

                            The SRR was converted to storms per year by
                multiplying by 600 km to represent the recurrence rate associated with
                storms passing within 200 km of the coastal reference location (CRL)
                closest to save point
    %}
    % Savepoint Location: Study Grid Row (savepoint_grid_row.m)
    loc = savepoint_grid_row(files, Nsvpt, sp_coords);
    % Find CRL closest to savepoint
    [~, ic] = min(haversine_km(loc.lat, loc.lon, CRL(:,1), CRL(:,2)));
    % Convert LI SRR to storms/year using a 600 km diameter.
    TC_SRR = SRR_LI(ic)*radKm;
    % Convert MI SRR to storms/year using a 600 km diameter.
    TC_SRR(1,2) = SRR_MI(ic)*radKm;
    % Convert HI SRR to storms/year using a 600 km diameter.
    TC_SRR(1,3) = SRR_HI(ic)*radKm;
    % SRR for all TC intensities.
    TC_SRR(1,4) = SRR_All(ic)*radKm;
    % Get Frequency Vector
    TC_Freq = ProbMass;
    % Get Total Frequency
    TotalFreq=sum(TC_Freq);

    % Find storms within 200 km of savepoint
    trk_dist=200;
    trk_lat=Param(:,4); trk_lon=Param(:,5);
    dist200=find(haversine_km(loc.lat, loc.lon, trk_lat, trk_lon)<=trk_dist);
    ReducedSet = Param(dist200, :);
    % Low Intensity Storm Population
    smpl1 = ReducedSet(ReducedSet(:,7)<28, 1);
    % Medium Intensity Storm Population
    smpl2 = ReducedSet((ReducedSet(:,7)>=28) & (ReducedSet(:,7)<48), 1);
    % High Intensity Storm Population
    smpl3 = ReducedSet(ReducedSet(:,7)>=48, 1);
    % Make DP Col Be The 5
    Param = [Param(:,1:4), Param(:,7), Param(:,5:6)];
else
    Param = [];
    TC_SRR = [];
    TC_Freq = [];
    TotalFreq=[];
    smpl1 = [];
    smpl3 = [];
    smpl2 = [];
end
end
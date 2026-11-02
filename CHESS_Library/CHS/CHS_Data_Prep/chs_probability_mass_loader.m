function  [Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2, smpl3] = chs_probability_mass_loader(chs_dependencies_path, region, Nsvpt)
%{
    %% DESCRIPTION
        This function is responsible for leading CHS TC storm probability
        masses. Files loaded are controlled by the CHS region being 
        requested. These files are necessary if performing any kind of TC 
        storm sampling method.
        
    %% INPUTS
        chs_dependencies_path: CHS_Dependencies folder (files from          | char
                               chs_dependency_files.m; empty outputs
                               without tropical_statistics_available).
        region: CHS region being requested. | char | 1 x size_varies
        Nsvpt: CHS ADCIRC savepoint ID. | double | 1 x 1

    %% OUTPUTS
        Param:
        TC_SRR:
        TC_Freq:
        dist:
        TotalFreq:
      
    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
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
    switch region
        case 'CHS-LA'
            % Load Savepoint -> ADCIRC Node Map
            load(files.savepoint_node_map_file, 'SPs');  % SPs
            % Load Selected Nodes List
            load(files.study_grid_file, 'staID');
            % Get Row
            adcirc_node_id = SPs(SPs(:,1) == Nsvpt, 2);
            % Find Correct Row ID For DSWs
            bias_indx = find(staID(:,2) == adcirc_node_id); % Row INdex For Bias And Uncertainty
            % Define Latitude Column
            col_indx = 3;
        otherwise
            % Load Grid Files (nodeID -> [SP_ID Node_ID Lat Lon Depth]; staID -> [SP_ID Lat Lon Depth])
            staID = load(files.study_grid_file, files.study_grid_variable);staID = staID.(files.study_grid_variable);
            % Define Latitude Column
            switch files.study_grid_variable
                case 'nodeID'
                    col_indx = 3;
                case 'staID'
                    col_indx = 2;
            end
            % Find Correct Row ID For DSWs
            bias_indx = find(staID(:,1) == Nsvpt); % Row INdex For Bias And Uncertainty
    end
    % Find CRL closest to savepoint
    [nearest_lat, nearest_lon, ~, dist, ic] = find_nearest_latlon(staID(bias_indx, col_indx), staID(bias_indx, col_indx+1), CRL(:,1), CRL(:,2), []);
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
    [~, ~, ~, dist, ~] = find_nearest_latlon(staID(bias_indx, col_indx), staID(bias_indx, col_indx+1),...
        trk_lat, trk_lon, []);
    dist200=find(dist<=trk_dist);
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
    dist = [];
    TotalFreq=[];
    smpl1 = [];
    smpl3 = [];
    smpl2 = [];
end
end
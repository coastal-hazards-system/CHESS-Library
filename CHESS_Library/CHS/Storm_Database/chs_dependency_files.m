function files = chs_dependency_files(chs_dependencies_folder, region)
%{
    %% DESCRIPTION
        CHS_Dependencies registry: the only place that knows the
        CHS_Dependencies folder layout and file names. Every library and
        GUI reader of CHS_Dependencies files gets its paths and the
        availability flags from here. Files are found by name pattern
        (dir, first match in name order); a file not found gives ''.
        Never errors: an empty or unknown region, an empty or missing
        folder just give empty paths and false flags.

        Layout (<r> = region, e.g. CHS-NA):
          Bias_and_Uncertainty\<r>\
              <r>_Comb_*.mat, else <r>_WL_*.mat          water level (SWL)
                                                         bias & uncertainty
              <r>_STWAVE_Hm0_*.mat, else <r>_SWAN_Hm0_*.mat
                                                         wave height (Hm0)
                                                         bias & uncertainty
          Grid_Files\<r>\
              <r>_nodeID*.mat (variable nodeID), else    study grid
              <r>_staID*.mat (variable staID)
              <r>_ADCIRC_SPs.mat (CHS-LA only)           savepoint ->
                                                         ADCIRC node map
          Probability_Masses\<r>\
              <r>_ITCS_DSW_*.mat                         TC discrete storm
                                                         weights
              <r>_ITCS_Param.mat                         TC storm parameters
          Probability_Masses\ (shared by every region)
              CHS_Atl_CRLs*.mat                          coastal reference
                                                         locations
              SRR_TC_LI_*.mat, SRR_TC_MI_*.mat,          TC storm recurrence
              SRR_TC_HI_*.mat, SRR_TC_All_*.mat          rates (low, medium,
                                                         high, all intensities)
        Great Lakes studies (CHS-GLM, CHS-GLH) have no TC files; CHS-S2G has
        no TC discrete storm weights. CHS-TX and CHS-PR study grids have no
        value column (no offshore elevation).

    %% INPUTS
        chs_dependencies_folder: CHS_Dependencies folder (config.chs_dependencies; | char
                                 '' or [] allowed).
        region: CHS region (config.region; '' allowed: shared files and     | char
                available_regions only).

    %% OUTPUTS
        files: | struct
            folder, region: Inputs (char).
            supported_regions: CHS regions CHESS reads (1 x 9 cell).
            region_supported: region is one of supported_regions.
            folder_exists: The folder exists.
            folder_layout_ok: The folder holds Bias_and_Uncertainty,
                              Grid_Files and Probability_Masses.
            folders.bias_uncertainty | study_grid | probability_masses:
                              Bias_and_Uncertainty\<r>, Grid_Files\<r>,
                              Probability_Masses\<r> ('' without folder or
                              region).
            folders.shared_probability_masses: Probability_Masses ('' without
                              folder).
            water_level_bias_uncertainty_file, wave_height_bias_uncertainty_file,
            study_grid_file, savepoint_node_map_file,
            tc_discrete_storm_weights_file, tc_storm_parameters_file,
            coastal_reference_locations_file: Full paths ('' when not found).
            storm_recurrence_rate_files.low_intensity | medium_intensity |
                              high_intensity | all_intensities: Full paths.
            study_grid_variable: 'nodeID' | 'staID' | '' (variable to load
                              from study_grid_file).
            study_grid_has_elevation: The region's study grid has a value
                              column (false for CHS-TX, CHS-PR and
                              unsupported regions).
            exists: Same file fields as above (storm_recurrence_rate_files
                              nested), true when the file was found.
            bias_uncertainty_available: Water level and wave height bias &
                              uncertainty files found.
            study_grid_available: Study grid file found.
            tropical_statistics_available: Every file the TC probability
                              masses need (chs_probability_mass_loader.m):
                              discrete storm weights, storm parameters,
                              coastal reference locations, the four storm
                              recurrence rates, the study grid and (CHS-LA)
                              the savepoint node map.
            region_files: Found files of the region (column cell, full paths).
            shared_files: Found shared Probability_Masses files (column cell).
            available_regions: Only for region '': supported_regions with a
                              study grid and both bias & uncertainty files
                              in the folder (1 x N cell); {} (1 x 0) otherwise.

    %% DEV SIGNATURE
        Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
supported_regions = {'CHS-NA', 'CHS-SA', 'CHS-GoM', 'CHS-LA', 'CHS-TX', 'CHS-PR', 'CHS-GLM', 'CHS-GLH', 'CHS-S2G'};
folder = char(chs_dependencies_folder);
region = char(region);
layout_folders = {'Bias_and_Uncertainty', 'Grid_Files', 'Probability_Masses'};

files.folder = folder;
files.region = region;
files.supported_regions = supported_regions;
files.region_supported = ismember(region, supported_regions);
files.folder_exists = ~isempty(folder) && isfolder(folder);
files.folder_layout_ok = files.folder_exists && all(isfolder(fullfile(folder, layout_folders)));

%% REGION FILES
[region_part, region_exists] = region_lookup(folder, files.folder_exists, region);
files.folders = region_part.folders;
files.water_level_bias_uncertainty_file = region_part.water_level_bias_uncertainty_file;
files.wave_height_bias_uncertainty_file = region_part.wave_height_bias_uncertainty_file;
files.study_grid_file = region_part.study_grid_file;
files.study_grid_variable = region_part.study_grid_variable;
files.study_grid_has_elevation = files.region_supported && ~ismember(region, {'CHS-TX', 'CHS-PR'});
files.savepoint_node_map_file = region_part.savepoint_node_map_file;
files.tc_discrete_storm_weights_file = region_part.tc_discrete_storm_weights_file;
files.tc_storm_parameters_file = region_part.tc_storm_parameters_file;

%% SHARED FILES (Probability_Masses Root)
shared_folder = '';
if files.folder_exists
    shared_folder = fullfile(folder, 'Probability_Masses');
end
files.folders.shared_probability_masses = shared_folder;
files.coastal_reference_locations_file = find_file(shared_folder, {'CHS_Atl_CRLs*.mat'});
files.storm_recurrence_rate_files = struct(...
    'low_intensity', find_file(shared_folder, {'SRR_TC_LI_*.mat'}),...
    'medium_intensity', find_file(shared_folder, {'SRR_TC_MI_*.mat'}),...
    'high_intensity', find_file(shared_folder, {'SRR_TC_HI_*.mat'}),...
    'all_intensities', find_file(shared_folder, {'SRR_TC_All_*.mat'}));

%% EXISTS FLAGS
files.exists = region_exists;
files.exists.coastal_reference_locations_file = ~isempty(files.coastal_reference_locations_file);
files.exists.storm_recurrence_rate_files = structfun(@(f) ~isempty(f), files.storm_recurrence_rate_files, 'un', false);

%% AVAILABILITY
files.bias_uncertainty_available = region_exists.water_level_bias_uncertainty_file && region_exists.wave_height_bias_uncertainty_file;
files.study_grid_available = region_exists.study_grid_file;
files.tropical_statistics_available = region_exists.tc_discrete_storm_weights_file && region_exists.tc_storm_parameters_file &&...
    files.exists.coastal_reference_locations_file && all(cell2mat(struct2cell(files.exists.storm_recurrence_rate_files))) &&...
    region_exists.study_grid_file && (region_exists.savepoint_node_map_file || ~uses_node_map(region));

%% FILE LISTS
region_list = {files.water_level_bias_uncertainty_file; files.wave_height_bias_uncertainty_file; files.study_grid_file;...
    files.savepoint_node_map_file; files.tc_discrete_storm_weights_file; files.tc_storm_parameters_file};
files.region_files = region_list(~cellfun(@isempty, region_list));
shared_list = [{files.coastal_reference_locations_file}; struct2cell(files.storm_recurrence_rate_files)];
files.shared_files = shared_list(~cellfun(@isempty, shared_list));
files.available_regions = cell(1, 0);
if isempty(region)
    available = false(size(supported_regions));
    if files.folder_layout_ok
        for rr = 1:numel(supported_regions)
            [~, other_exists] = region_lookup(folder, true, supported_regions{rr});
            available(rr) = other_exists.study_grid_file && other_exists.water_level_bias_uncertainty_file &&...
                other_exists.wave_height_bias_uncertainty_file;
        end
    end
    files.available_regions = supported_regions(available);
end
end

%% AUX FUNCTION: FILES OF ONE REGION (Empty Paths Without Folder Or Region)
function [part, exists] = region_lookup(folder, folder_exists, region)
part.folders = struct('bias_uncertainty', '', 'study_grid', '', 'probability_masses', '');
if folder_exists && ~isempty(region)
    part.folders.bias_uncertainty = fullfile(folder, 'Bias_and_Uncertainty', region);
    part.folders.study_grid = fullfile(folder, 'Grid_Files', region);
    part.folders.probability_masses = fullfile(folder, 'Probability_Masses', region);
end
part.water_level_bias_uncertainty_file = find_file(part.folders.bias_uncertainty, {[region '_Comb_*.mat'], [region '_WL_*.mat']});
part.wave_height_bias_uncertainty_file = find_file(part.folders.bias_uncertainty, {[region '_STWAVE_Hm0_*.mat'], [region '_SWAN_Hm0_*.mat']});
[part.study_grid_file, hit] = find_file(part.folders.study_grid, {[region '_nodeID*.mat'], [region '_staID*.mat']});
grid_variables = {'nodeID', 'staID'};
part.study_grid_variable = '';
if hit > 0
    part.study_grid_variable = grid_variables{hit};
end
part.savepoint_node_map_file = '';
if uses_node_map(region)
    part.savepoint_node_map_file = find_file(part.folders.study_grid, {[region '_ADCIRC_SPs.mat']});
end
part.tc_discrete_storm_weights_file = find_file(part.folders.probability_masses, {[region '_ITCS_DSW_*.mat']});
part.tc_storm_parameters_file = find_file(part.folders.probability_masses, {[region '_ITCS_Param.mat']});
exists = struct();
for ff = {'water_level_bias_uncertainty_file', 'wave_height_bias_uncertainty_file', 'study_grid_file',...
        'savepoint_node_map_file', 'tc_discrete_storm_weights_file', 'tc_storm_parameters_file'}
    exists.(ff{1}) = ~isempty(part.(ff{1}));
end
end

%% AUX FUNCTION: STUDY GRID ROWS ARE ADCIRC NODES, SAVEPOINTS MAPPED THROUGH <r>_ADCIRC_SPs.mat
function tf = uses_node_map(region)
tf = strcmp(region, 'CHS-LA');
end

%% AUX FUNCTION: FIRST FILE MATCHING THE FIRST PATTERN THAT HAS ONE ('' And hit 0 When None Or No Folder)
function [file, hit] = find_file(folder, patterns)
file = '';
hit = 0;
if isempty(folder)
    return
end
for pp = 1:numel(patterns)
    d = dir(fullfile(folder, patterns{pp}));
    d = d(~[d.isdir]);
    if ~isempty(d)
        file = fullfile(d(1).folder, d(1).name);
        hit = pp;
        return
    end
end
end

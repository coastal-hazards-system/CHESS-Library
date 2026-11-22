classdef CoastalHazardSystem < handle
    % CoastalHazardSystem  Storm database of a Coastal Hazards System (CHS) savepoint.
    %   chs = chess.CoastalHazardSystem(source, chs_dependencies, database_file)
    %
    %   The object is a light description of the storm data (region,
    %   savepoint, files, db_info, datasets available). The storm data
    %   itself (storm, prob_mass) is heavy: build saves it to
    %   database_file and read returns it.
    %
    %   source is one of:
    %     CHS .zip            - HDF5 storm files downloaded from the CHS
    %     CHS_Data .mat       - storm files already converted (CHS_Data)
    %     storm .mat          - user storm data (storm + prob_mass)
    %
    %   Typical use:
    %     chs = chess.CoastalHazardSystem('CHS_files.zip', 'CHS_Dependencies', 'Event_Database\DB.mat');
    %     if ~chs.covers('CC', 1, 0, 0, 0)
    %         chs.build('CC', 1, 0, 0, 0);
    %     end
    %     [storm, prob_mass] = chs.read();
    %
    %   A storm .mat does not say which study it is of: set_study states the
    %   region, the savepoint and, for a study without CHS_Dependencies, the
    %   uncertainties. source_contents lists what the input holds.
    %
    %   The HDF5 conversion is in chess.CoastalHazardSystem.convert_h5 and
    %   chess.CoastalHazardSystem.convert_zip.
    %
    %   Every dataset is curated (curate_storm_forcing: Hm0 floor with its
    %   Wilson Tp, SWL <= -100 m to NaN) when the database is built from CHS
    %   files or imported from a storm .mat.
    %
    %   See also chess.Model, chess.CoastalHazardSystem.convert_zip.

    properties (SetAccess = private)
        source                      % storm data input (.zip, CHS_Data .mat or storm .mat)
        source_kind                 % 'chs_zip', 'chs_data_mat' or 'storm_mat'
        storm_files = {}            % CHS storm file names of the source (.h5)
        chs_dependencies            % CHS_Dependencies folder
        region                      % CHS region, e.g. 'CHS-NA'
        savepoint_id                % ADCIRC savepoint ID
        wave_savepoint_id           % wave model savepoint ID
        savepoint_latitude = NaN    % savepoint latitude [deg]
        savepoint_longitude = NaN   % savepoint longitude [deg]
        vertical_datum = ''         % vertical datum of the storm data ('' when the input does not state it)
        database_file               % storm database .mat (storm, prob_mass, db_info)
        raw_file                    % converted CHS files .mat (CHS_Data), next to database_file
        db_info = []                % database details (bias and uncertainty, XC record, offshore elevation, build date)
        available_datasets = []     % datasets in the database: per storm type the Peaks / Timeseries dataset names
    end

    properties
        prompt_for_uncertainty = true   % bias and uncertainty CHS_Dependencies does not hold: true asks in the command window, false is an error
    end

    properties (Access = private)
        provided_bias_uncertainty = []  % uncertainties given with set_study (storm .mat of a study without CHS_Dependencies)
        contents = []                   % what the source holds (source_contents), read once
    end

    properties (Constant, Access = {?matlab.unittest.TestCase, ?chess.Visualization.CHESSPlotsBase}) % CHS Data Flags And Settings: Private To The Class, Open To Unit Tests And The Raw-Signal Plot
        FLAG_BELOW = -90               % [m] ADCIRC SWL and Peaks wave values below this are no-data flags
        WAVE_FLAG_BELOW = -400         % wave model Timeseries values (Hm0, Tp, wave direction) below this are no-data flags (directions may be negative)
        GRID_FILL_LIMIT = -99999       % study grid depths at or below this are fill values (e.g. CHS-GLH -999999)
        FLAGGED_HM0_FILL = 0.01        % [m] Hm0 written over flagged / non-positive raw Timeseries Hm0 before interpolation
        TIMESERIES_STEP_HOURS = 1      % [h] Timeseries interpolation step
        PEAK_WINDOW_HOURS = 3          % [h] +/- window around the Peaks time used to pull the Timeseries response
        GRID_DISTANCE_WARNING_M = 0.5  % [m] grid point farther than this from the savepoint coordinates is printed
    end

    methods
        function obj = CoastalHazardSystem(source, chs_dependencies, database_file)
            % CoastalHazardSystem  Describe a storm data input and its database file.
            %   obj = chess.CoastalHazardSystem(source, chs_dependencies, database_file)
            %   Reads file names and attributes only; nothing is converted or built.
            obj.source = source;
            obj.chs_dependencies = chs_dependencies;
            obj.database_file = database_file;
            [db_folder, db_name] = fileparts(database_file);
            obj.raw_file = fullfile(db_folder, [db_name '_raw_files.mat']);
            info = chess.CoastalHazardSystem.inspect(source);
            obj.source_kind = info.kind;
            obj.storm_files = info.storm_files;
            obj.region = info.region;
            obj.savepoint_id = info.savepoint_id;
            obj.wave_savepoint_id = info.wave_savepoint_id;
            obj.vertical_datum = info.vertical_datum;
            % Existing Database: Its Details
            if isfile(database_file)
                obj.read_details();
            end
            % Savepoint Coordinates (Study Grid Lookup When The Database Is Built)
            if ~strcmp(obj.source_kind, 'storm_mat')
                obj.find_savepoint_coordinates(info.savepoint_coordinates);
            end
        end

        function build(obj, storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp, print_progress, progress_function)
            % build  Build the storm database from the CHS input and save it.
            %   chs.build(storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp)
            %   chs.build(..., print_progress, progress_function)
            %   The CHS storm files are converted (once; saved to raw_file),
            %   screened and formatted, and storm, prob_mass and db_info are
            %   saved to database_file. Every complete storm type of the
            %   input is built; the request is only checked against the
            %   input. WLP / WHP already in the database are kept.
            %   progress_function: called as progress_function(fraction,
            %   message) while the storm files are converted and the
            %   database is built (fraction 0 to 1, NaN when not known);
            %   an error it raises stops the build.
            if nargin < 7 || isempty(print_progress)
                print_progress = true;
            end
            if nargin < 8
                progress_function = [];
            end
            if strcmp(obj.source_kind, 'storm_mat')
                error('chess:CoastalHazardSystem:noRebuild', 'A storm .mat input cannot be rebuilt: use import_user_storm.');
            end
            request = struct('storm_sampling', storm_sampling, 'use_peaks', use_peaks, 'use_timeseries', use_timeseries,...
                'create_wlp', create_wlp, 'create_whp', create_whp);
            raw_exists = isfile(obj.raw_file);
            files_to_convert = obj.storm_files;
            if raw_exists
                chess.Common.disp_toggle(print_progress, 'Building storm database from CHESS generated CHS_Data .mat....');
                S = load(obj.raw_file, 'CHS_Data');
                CHS_Data = S.CHS_Data;
                [~, files_to_convert, h5_ext] = cellfun(@fileparts, {CHS_Data.Filename}', 'un', false);
                files_to_convert = strcat(files_to_convert, h5_ext);
            end
            files_to_convert = chess.CoastalHazardSystem.storm_file_names(files_to_convert);
            [slots, slot_errors] = chess.CoastalHazardSystem.storm_file_slots(files_to_convert, request);
            if ~isempty(slot_errors)
                error('chess:CoastalHazardSystem:incompleteStormFiles', 'CHS input ''%s'' does not meet the storm data requirements: %s.',...
                    obj.source, strjoin(slot_errors, '; '));
            end
            % Every Complete Storm Type Of The Input; TC Needs The CHS_Dependencies TC Statistics
            db_types = intersect({'TC','XC'}, slots.storm_type(slots.complete)', 'stable');
            chs_files = chess.CoastalHazardSystem.dependency_files(obj.chs_dependencies, obj.region);
            if ismember('TC', db_types) && ~chs_files.tropical_statistics_available
                if ~strcmp(storm_sampling, 'XC')
                    error('chess:CoastalHazardSystem:noTropicalStatistics', '%s', chess.CoastalHazardSystem.dependencies_message(storm_sampling, obj.region));
                end
                chess.Common.disp_toggle(print_progress, 'CHS_Dependencies not available for this region: storm database built with XC only (TC files kept in the raw file)....');
                db_types = setdiff(db_types, {'TC'}, 'stable');
            end
            % Datasets Already In The Database Are Kept
            [had_wlp, had_whp] = obj.has_priority_datasets();
            sp_coords = [obj.savepoint_latitude obj.savepoint_longitude];
            previous_info = [];
            if chess.CoastalHazardSystem.is_valid_db_info(obj.db_info)
                previous_info = obj.db_info;
            end
            bnu = obj.study_bias_uncertainty(sp_coords, previous_info);
            [~, source_name, source_ext] = fileparts(obj.source);
            build_options = struct('chs_dependencies', obj.chs_dependencies, 'region', obj.region, 'sp_ID', obj.savepoint_id,...
                'storm_types', {db_types}, 'storm_file_slots', slots,...
                'create_wlp', +(create_wlp == 1 || had_wlp), 'create_whp', +(create_whp == 1 || had_whp),...
                'bias_uncertainty', bnu, 'source_file', [source_name source_ext], 'print_progress', print_progress,...
                'progress_fcn', progress_function);
            % Convert The CHS h5 Storm Files Once (Saved To The Raw File)
            if ~raw_exists
                switch obj.source_kind
                    case 'chs_zip'
                        chess.Common.disp_toggle(print_progress, 'Begin CHS h5 file conversion....');
                        conversion_progress = [];
                        if ~isempty(progress_function)
                            progress_function(NaN, 'Unzipping CHS storm files...');
                            % Files Done ((jj - 1)/n): The Bar Is Full Only When The Database Is Built
                            conversion_progress = @(jj, n, file_name) progress_function((jj - 1)/n,...
                                sprintf('Converting CHS .h5 files (%d of %d): %s', jj, n, file_name));
                        end
                        CHS_Data = chess.CoastalHazardSystem.convert_zip(obj.source, files_to_convert, print_progress, conversion_progress);
                    case 'chs_data_mat'
                        S = load(obj.source, 'CHS_Data');
                        CHS_Data = chess.CoastalHazardSystem.strip_data_folders(S.CHS_Data);
                end
                if ~isempty(progress_function)
                    progress_function(NaN, 'Writing the converted CHS storm files...');
                end
                save(obj.raw_file, 'CHS_Data', '-v7.3');
            end
            [storm, prob_mass, db_info] = chess.CoastalHazardSystem.build_storm_database(CHS_Data, build_options); %#ok<ASGLU>
            if ~isempty(progress_function)
                progress_function(8.9/9, 'Writing the storm database...');
            end
            save(obj.database_file, 'storm', 'prob_mass', 'db_info', '-v7.3');
            if ~isempty(progress_function)
                progress_function(1, 'Complete');
            end
            obj.db_info = db_info;
            obj.available_datasets = db_info.datasets;
        end

        function import_user_storm(obj, storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp)
            % import_user_storm  Validate a storm .mat input and save it as the storm database.
            %   chs.import_user_storm(storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp)
            %   The request must be in the provided data (there are no CHS
            %   files to rebuild from). The XC record (Nyrs_XC, Nstm_XC)
            %   moves from storm.XC to db_info. Every dataset is curated
            %   (chess.CoastalHazardSystem.curate_storm_forcing) before it is
            %   saved. Then every storm whose curated SWL is NaN in a Peaks
            %   dataset (Default, WLP, WHP) leaves every dataset of its storm
            %   type (Peaks and Timeseries, by storm ID) and, TC, the
            %   probability masses (TC_Freq and Param rows of its Default row,
            %   rescaled to TotalFreq as in quality_check; smpl1, smpl2,
            %   smpl3 by ID); its ID is added to removed_storms.Default.
            %   Warning chess:CoastalHazardSystem:removedStormsWithoutWaterLevel
            %   lists the removed IDs; error
            %   chess:CoastalHazardSystem:noStormsWithWaterLevel when a storm
            %   type keeps no storm.
            S = load(obj.source, 'storm', 'prob_mass');
            storm = curate_storm_database(chess.CoastalHazardSystem.validate_user_storm([], S.storm));
            prob_mass = S.prob_mass;
            if isfield(storm, 'TC')
                prob_mass = chess.CoastalHazardSystem.validate_user_prob_mass([], prob_mass, storm);
            end
            [storm, prob_mass] = remove_storms_without_water_level(storm, prob_mass);
            [stm_ok, dtype_ok, alt_ok] = chess.CoastalHazardSystem.storm_data_covers(storm, prob_mass, storm_sampling,...
                use_peaks, use_timeseries, create_wlp, create_whp);
            if ~alt_ok
                missing = {'storm types (storm_sampling; TC needs prob_mass)', 'data types (use_peaks/use_timeseries)', 'Peaks datasets (create_wlp/create_whp)'};
                error('chess:CoastalHazardSystem:requestNotCovered', 'Requested %s not in the provided storm data ''%s''.', missing{find(~[stm_ok, dtype_ok, alt_ok], 1)}, obj.source);
            end
            Nyrs_XC = [];
            Nstm_XC = [];
            if isfield(storm, 'XC')
                Nyrs_XC = storm.XC.Nyrs_XC;
                Nstm_XC = storm.XC.Nstm_XC;
                storm.XC = rmfield(storm.XC, {'Nyrs_XC','Nstm_XC'});
            end
            % Bias & Uncertainty (Given With set_study, Else CHS_Dependencies, Else Entered Once); No Savepoint Coordinates In A Storm .mat
            bnu = obj.provided_bias_uncertainty;
            if isempty(bnu)
                bnu = obj.study_bias_uncertainty([], []);
            end
            [~, source_name, source_ext] = fileparts(obj.source);
            db_info = chess.CoastalHazardSystem.create_db_info(bnu, 0, Nyrs_XC, Nstm_XC, [source_name source_ext]);
            db_info.datasets = chess.CoastalHazardSystem.summarize_datasets(storm, prob_mass);
            save(obj.database_file, 'storm', 'prob_mass', 'db_info', '-v7.3');
            obj.db_info = db_info;
            obj.available_datasets = db_info.datasets;
        end

        function set_study(obj, region, savepoint_id, swl_uncertainty, hm0_uncertainty)
            % set_study  State the study of a storm .mat input (the file does not hold it).
            %   chs.set_study(region, savepoint_id)
            %   chs.set_study(region, savepoint_id, swl_uncertainty, hm0_uncertainty)
            %   region: CHS region, or 'Custom_Modeling' for storm data
            %   that is not of a CHS study. savepoint_id: savepoint ID.
            %   swl_uncertainty, hm0_uncertainty: [absolute (m), relative (-)]
            %   uncertainty of the water level and of the wave height, for
            %   a study without CHS_Dependencies files (no bias is
            %   applied). Without them the values come from
            %   CHS_Dependencies (prompt_for_uncertainty when it has none).
            if ~strcmp(obj.source_kind, 'storm_mat')
                error('chess:CoastalHazardSystem:studyFromFiles', 'The study of a CHS input is read from its storm file names: set_study is for a storm .mat.');
            end
            obj.region = char(region);
            obj.savepoint_id = savepoint_id;
            obj.provided_bias_uncertainty = [];
            if nargin > 3 && ~isempty(swl_uncertainty)
                obj.provided_bias_uncertainty = struct('chs_swl_b_a', 0, 'chs_swl_b_r', 0,...
                    'chs_swl_u_a', swl_uncertainty(1), 'chs_swl_u_r', swl_uncertainty(2), 'chs_swl_bu_source', 'provided',...
                    'chs_hm0_b_a', 0, 'chs_hm0_b_r', 0,...
                    'chs_hm0_u_a', hm0_uncertainty(1), 'chs_hm0_u_r', hm0_uncertainty(2), 'chs_hm0_bu_source', 'provided',...
                    'offshore_elevation', [], 'offshore_elevation_source', '', 'grid_distance_m', [], 'sp_lat', [], 'sp_lon', []);
            end
        end

        function contents = source_contents(obj)
            % source_contents  What the storm data input holds: the most a database built from it can cover.
            %   contents = chs.source_contents()
            %   contents.storm_types     - complete storm types (XC, TC), cell
            %   contents.storm_sampling  - 'XC', 'TC', or 'CC' when it holds both
            %   contents.has_peaks, contents.has_timeseries - every storm
            %       type holds Peaks / Timeseries, logical
            %   contents.has_wlp, contents.has_whp - water level / wave
            %       height priority Peaks in a storm .mat (a CHS input
            %       has none: build makes them), logical
            %   A CHS input is read by file names (an error when the storm
            %   files do not pair up, storm_file_slots); a storm .mat is
            %   loaded once.
            if ~isempty(obj.contents)
                contents = obj.contents;
                return
            end
            contents = struct('storm_types', {{}}, 'storm_sampling', '', 'has_peaks', false, 'has_timeseries', false,...
                'has_wlp', false, 'has_whp', false);
            if strcmp(obj.source_kind, 'storm_mat')
                S = load(obj.source, 'storm', 'prob_mass');
                datasets = chess.CoastalHazardSystem.summarize_datasets(S.storm, S.prob_mass);
                contents.storm_types = intersect({'XC', 'TC'}, fieldnames(datasets)', 'stable');
                holds = @(data_type) all(cellfun(@(type) isfield(datasets.(type), data_type), contents.storm_types));
                has_dataset = @(dataset) any(cellfun(@(type) isfield(datasets.(type), 'Peaks')...
                    && ismember(dataset, datasets.(type).Peaks), contents.storm_types));
                contents.has_wlp = has_dataset('WLP');
                contents.has_whp = has_dataset('WHP');
            else
                [slots, slot_errors] = chess.CoastalHazardSystem.storm_file_slots(obj.storm_files);
                if ~isempty(slot_errors)
                    error('chess:CoastalHazardSystem:stormData', 'The storm data does not meet the storm file requirements: %s.', strjoin(slot_errors, '; '));
                end
                complete = slots(slots.complete, :);
                contents.storm_types = intersect({'XC', 'TC'}, complete.storm_type', 'stable');
                holds = @(data_type) all(cellfun(@(type) any(strcmp(complete.storm_type, type)...
                    & strcmp(complete.data_type, data_type)), contents.storm_types));
            end
            if isempty(contents.storm_types)
                error('chess:CoastalHazardSystem:stormData', 'The storm data holds no complete storm type (XC or TC): %s', obj.source);
            end
            contents.has_peaks = holds('Peaks');
            contents.has_timeseries = holds('Timeseries');
            contents.storm_sampling = 'CC';
            if isscalar(contents.storm_types)
                contents.storm_sampling = contents.storm_types{1};
            end
            obj.contents = contents;
        end

        function apply_datum_offset(obj, offset)
            % apply_datum_offset  Add an offset to the water levels of every storm of the database file.
            %   chs.apply_datum_offset(offset)
            %   offset [m]: study datum to another datum. Every dataset
            %   (Peaks and Timeseries, Default / WLP / WHP) of every storm
            %   type is shifted. Offsets add up: the opposite value takes
            %   one back.
            if offset == 0
                return
            end
            S = load(obj.database_file, 'storm');
            storm = S.storm;
            for st = intersect(fieldnames(storm)', {'TC', 'XC'})
                for dtype = intersect(fieldnames(storm.(st{1}))', {'Peaks', 'Timeseries'})
                    for dataset = fieldnames(storm.(st{1}).(dtype{1}))'
                        events = storm.(st{1}).(dtype{1}).(dataset{1});
                        for ee = 1:size(events, 1)
                            events{ee, 2}(:, 1) = events{ee, 2}(:, 1) + offset; % Column 1: Water Level
                        end
                        storm.(st{1}).(dtype{1}).(dataset{1}) = events;
                    end
                end
            end
            save(obj.database_file, '-append', 'storm');
        end

        function delete_database(obj)
            % delete_database  Delete the database file, so the next build holds only what it is asked for.
            %   chs.delete_database()
            %   The converted CHS storm files (raw_file) are kept: the next
            %   build does not convert them again.
            if isfile(obj.database_file)
                delete(obj.database_file);
            end
            obj.db_info = [];
            obj.available_datasets = [];
        end

        function [storm, prob_mass] = read(obj)
            % read  Storm data and probability masses of the database file.
            %   [storm, prob_mass] = chs.read()
            S = load(obj.database_file, 'storm', 'prob_mass');
            storm = S.storm;
            prob_mass = S.prob_mass;
            if isempty(obj.available_datasets)
                obj.available_datasets = chess.CoastalHazardSystem.summarize_datasets(storm, prob_mass);
            end
        end

        function [covered, storm_type_ok, data_type_ok, datasets_ok] = covers(obj, storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp)
            % covers  True when the database holds what a run requests.
            %   covered = chs.covers(storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp)
            %   [covered, storm_type_ok, data_type_ok, datasets_ok] = chs.covers(...)
            %   Checked on the light details (no storm data is loaded):
            %   storm types (TC needs its probability masses), Peaks /
            %   Timeseries, WLP / WHP, and a valid db_info.
            covered = false; storm_type_ok = false; data_type_ok = false; datasets_ok = false;
            if ~isfile(obj.database_file)
                return
            end
            if isempty(obj.available_datasets)
                obj.read_details();
            end
            % Skeleton Of The Stored Data: Same Check As On The Data Itself
            storm = struct();
            for st = intersect(fieldnames(obj.available_datasets)', {'TC', 'XC'})
                for dtype = fieldnames(obj.available_datasets.(st{1}))'
                    for dataset = obj.available_datasets.(st{1}).(dtype{1})
                        storm.(st{1}).(dtype{1}).(dataset{1}) = [];
                    end
                end
            end
            prob_mass = [];
            if obj.available_datasets.has_tc_probability_masses
                prob_mass = struct('TC_Freq', 1);
            end
            [storm_type_ok, data_type_ok, datasets_ok] = chess.CoastalHazardSystem.storm_data_covers(storm, prob_mass,...
                storm_sampling, use_peaks, use_timeseries, create_wlp, create_whp);
            covered = datasets_ok && chess.CoastalHazardSystem.is_valid_db_info(obj.db_info);
        end
    end

    methods (Access = private)
        function read_details(obj)
            % db_info and the dataset summary of the database file (the storm data is read only when the summary is missing)
            if any(strcmp(who('-file', obj.database_file), 'db_info'))
                S = load(obj.database_file, 'db_info');
                obj.db_info = S.db_info;
            end
            if isstruct(obj.db_info) && isfield(obj.db_info, 'datasets')
                obj.available_datasets = obj.db_info.datasets;
            else
                S = load(obj.database_file, 'storm', 'prob_mass');
                obj.available_datasets = chess.CoastalHazardSystem.summarize_datasets(S.storm, S.prob_mass);
            end
        end

        function bnu = study_bias_uncertainty(obj, sp_coords, previous_info)
            % Bias and uncertainty of the study from CHS_Dependencies (bias_and_uncertainty); without prompt_for_uncertainty, values it does not hold are an error
            bnu = chess.CoastalHazardSystem.bias_and_uncertainty(obj.chs_dependencies, obj.region, obj.savepoint_id, sp_coords,...
                previous_info, obj.prompt_for_uncertainty);
            if isempty(bnu.chs_swl_bu_source) || isempty(bnu.chs_hm0_bu_source)
                error('chess:CoastalHazardSystem:noUncertainty', 'The CHS_Dependencies folder "%s" has no %s bias and uncertainty files (savepoint %d).',...
                    obj.chs_dependencies, obj.region, obj.savepoint_id);
            end
        end

        function find_savepoint_coordinates(obj, sp_coords)
            % Savepoint coordinates (and the vertical datum) from the converted file attributes, else from the first ADCIRC .h5 of the zip
            where = 'CHS_Data attributes';
            datum = '';
            if isempty(sp_coords)
                if isfile(obj.raw_file)
                    S = load(obj.raw_file, 'CHS_Data');
                    [datum, sp_coords] = chess.CoastalHazardSystem.data_attributes(S.CHS_Data);
                else
                    where = 'h5 attributes';
                    file_parts = chess.CoastalHazardSystem.file_name_parts(obj.storm_files);
                    adcirc_files = obj.storm_files([file_parts.is_adcirc]);
                    if ~isempty(adcirc_files)
                        try
                            [datum, sp_coords] = chess.CoastalHazardSystem.zip_h5_attributes(obj.source, adcirc_files{1});
                        catch
                            % Entry Not Readable: The Savepoint ID Is Matched In The Study Grid
                        end
                    end
                end
            end
            if isempty(obj.vertical_datum) && ~isempty(datum)
                obj.vertical_datum = char(datum);
            end
            if numel(sp_coords) == 2 && all(isfinite(sp_coords))
                obj.savepoint_latitude = sp_coords(1);
                obj.savepoint_longitude = sp_coords(2);
            else
                fprintf('Warning: could not find ADCIRC savepoint coordinates on %s. The storm database build will match the savepoint ID in the study grid instead....\n', where);
            end
        end

        function [has_wlp, has_whp] = has_priority_datasets(obj)
            % WLP / WHP Peaks already in the database
            has_wlp = false;
            has_whp = false;
            if isempty(obj.available_datasets)
                return
            end
            for st = intersect(fieldnames(obj.available_datasets)', {'TC', 'XC'})
                if isfield(obj.available_datasets.(st{1}), 'Peaks')
                    has_wlp = has_wlp || ismember('WLP', obj.available_datasets.(st{1}).Peaks);
                    has_whp = has_whp || ismember('WHP', obj.available_datasets.(st{1}).Peaks);
                end
            end
        end
    end

    methods (Static)
        function info = inspect(source)
            % inspect  What a storm data input holds, by file names only.
            %   info = chess.CoastalHazardSystem.inspect(source)
            %   info.kind                  - 'chs_zip', 'chs_data_mat' or 'storm_mat'
            %   info.storm_files           - CHS storm file names (.h5), cell
            %   info.storm_file_folders    - their folders (CHS_Data .mat), cell
            %   info.slots, info.slot_errors - storm file slots (storm_file_slots)
            %   info.region, info.savepoint_id, info.wave_savepoint_id
            %   info.savepoint_coordinates - [lat lon] when the input carries
            %                                them (CHS_Data .mat), else []
            %   info.vertical_datum        - vertical datum when the input
            %                                carries it (CHS_Data .mat), else ''
            %   A CHS_Data .mat is loaded to read its file names; a .zip is
            %   not decompressed.
            [~, ~, file_extension] = fileparts(source);
            info = struct('kind', '', 'storm_files', {{}}, 'storm_file_folders', {{}}, 'slots', [], 'slot_errors', {{}},...
                'region', '', 'savepoint_id', [], 'wave_savepoint_id', [], 'savepoint_coordinates', [], 'vertical_datum', '');
            switch file_extension
                case '.mat' % "storm" + "prob_mass", Or "CHS_Data"
                    vars = who(matfile(source));
                    var_pass = contains({'CHS_Data','storm'}, vars);
                    if sum(var_pass) == 0 || sum(var_pass) > 1
                        error('chess:CoastalHazardSystem:invalidMatFile', 'A storm data .mat file must hold either a "CHS_Data" or a "storm" variable (not both): %s.', source);
                    end
                    kinds = {'chs_data_mat', 'storm_mat'};
                    info.kind = kinds{var_pass};
                    if strcmp(info.kind, 'storm_mat') && ~any(contains(vars, 'prob_mass'))
                        error('chess:CoastalHazardSystem:missingProbabilityMass', 'A storm .mat file needs both "storm" and "prob_mass" variables: %s.', source);
                    end
                case '.zip' % Zip Folder Downloaded From CHS
                    info.kind = 'chs_zip';
                otherwise
                    error('chess:CoastalHazardSystem:unsupportedSource', 'Unsupported storm data file type "%s" (%s): use a CHS .zip folder or a .mat file.', file_extension, source);
            end
            switch info.kind
                case 'chs_data_mat'
                    S = load(source, 'CHS_Data');
                    [info.storm_file_folders, names, h5_ext] = cellfun(@fileparts,...
                        chess.CoastalHazardSystem.storm_file_names({S.CHS_Data.Filename}), 'un', false);
                    info.storm_files = strcat(names, h5_ext);
                    [datum, info.savepoint_coordinates] = chess.CoastalHazardSystem.data_attributes(S.CHS_Data);
                    if ~isempty(datum)
                        info.vertical_datum = char(datum);
                    end
                    if isempty(info.savepoint_coordinates)
                        info.savepoint_coordinates = [NaN NaN];
                    end
                case 'chs_zip'
                    info.storm_files = chess.CoastalHazardSystem.storm_file_names(chess.CoastalHazardSystem.zip_h5_names(source));
                    info.storm_file_folders = repmat({''}, numel(info.storm_files), 1);
                case 'storm_mat'
                    name_parts = chess.CoastalHazardSystem.storm_mat_name_parts(source);
                    info.savepoint_id = 1;
                    if ~isempty(name_parts.sp_ID)
                        info.savepoint_id = name_parts.sp_ID;
                    end
                    info.region = 'Custom_Modeling'; % User Provides The Probability Masses
                    if ~isempty(name_parts.region)
                        info.region = name_parts.region;
                    end
                    return
            end
            [info.slots, info.slot_errors, study] = chess.CoastalHazardSystem.storm_file_slots(info.storm_files);
            info.region = study.region;
            info.savepoint_id = study.sp_ID;
            info.wave_savepoint_id = study.sp_ID_wave;
        end

        function chs = load(database_file, chs_dependencies)
            % load  Describe an existing storm database file (no storm data input).
            %   chs = chess.CoastalHazardSystem.load(database_file)
            %   chs = chess.CoastalHazardSystem.load(database_file, chs_dependencies)
            %   Only db_info is read; region and savepoint come from the file
            %   name when it follows <region>_SP<id>.
            if nargin < 2
                chs_dependencies = '';
            end
            chs = chess.CoastalHazardSystem(database_file, chs_dependencies, database_file);
        end

        function db_info = create_db_info(bnu, tc_bias_corrected, Nyrs_XC, Nstm_XC, source_file)
            % create_db_info  Details stored with a storm database when it is built.
            %   db_info = chess.CoastalHazardSystem.create_db_info(bnu,
            %       tc_bias_corrected, Nyrs_XC, Nstm_XC, source_file)
            %   bnu: bias, uncertainty and offshore elevation
            %   (bias_and_uncertainty). Fields: tc_bias_corrected, the bias and
            %   uncertainty fields, offshore_elevation, offshore_elevation_source,
            %   grid_distance_m, sp_lat, sp_lon, Nyrs_XC, Nstm_XC, source_file,
            %   build_date.
            [bnu_fields, loc_fields] = db_info_fields();
            db_info = struct('tc_bias_corrected', double(tc_bias_corrected));
            for ff = [bnu_fields, loc_fields]
                db_info.(ff{1}) = bnu.(ff{1});
            end
            db_info.Nyrs_XC = Nyrs_XC;
            db_info.Nstm_XC = Nstm_XC;
            db_info.source_file = char(source_file);
            db_info.build_date = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
        end

        function valid = is_valid_db_info(db_info)
            % is_valid_db_info  True when db_info holds every required field.
            bnu_fields = db_info_fields();
            all_fields = [{'tc_bias_corrected'}, bnu_fields, {'Nyrs_XC', 'Nstm_XC', 'source_file', 'build_date'}];
            valid = isstruct(db_info) && isscalar(db_info) && all(isfield(db_info, all_fields));
        end

        function datasets = summarize_datasets(storm, prob_mass)
            % summarize_datasets  Dataset names of storm data, per storm type and data type.
            %   datasets = chess.CoastalHazardSystem.summarize_datasets(storm, prob_mass)
            %   datasets.<TC|XC>.<Peaks|Timeseries> - dataset names (Default, WLP, WHP), cell
            %   datasets.has_tc_probability_masses  - TC probability masses present, logical
            datasets = struct();
            for st = intersect(fieldnames(storm)', {'TC', 'XC'})
                datasets.(st{1}) = struct();
                for dtype = intersect(fieldnames(storm.(st{1}))', {'Peaks', 'Timeseries'})
                    datasets.(st{1}).(dtype{1}) = fieldnames(storm.(st{1}).(dtype{1}))';
                end
            end
            datasets.has_tc_probability_masses = isstruct(prob_mass) && isfield(prob_mass, 'TC_Freq') && ~isempty(prob_mass.TC_Freq);
        end

        function dataset = curate_storm_forcing(dataset)
            % curate_storm_forcing  Forcing curation of one storm dataset (the one place of these rules).
            %   dataset = chess.CoastalHazardSystem.curate_storm_forcing(dataset)
            %   Applied to every dataset of a storm database when it is built
            %   from CHS files (build_storm_database) and when a storm .mat is
            %   imported (import_user_storm); works on any dataset of that
            %   layout. Rules, row by row:
            %     Hm0 <= 0.01 m: Hm0 = 0.01 m and Tp = 1.1*3.3*Hm0^0.63
            %                    (Wilson wind-sea period of that height,
            %                    about 0.199 s; SI: Hm0 in m, Tp in s;
            %                    chess.CoastalHazardSystem.floor_wave_height)
            %     SWL <= -100 m: SWL = NaN (no forcing)
            %   NaN values are kept. The other columns are not changed.
            %   Input / output:
            %     dataset - N x 2 cell: column 1 storm ID, column 2 storm data
            %               with SWL [m, study datum] in column 1, Hm0 [m] in
            %               column 2 and Tp [s] in column 3 (Peaks 1 x 5
            %               [SWL Hm0 Tp wDir datenum], Timeseries M x 6
            %               [SWL Hm0 Tp wDir datenum dt])
            dataset(:, 2) = cellfun(@curate_storm_rows, dataset(:, 2), 'UniformOutput', false);
        end

        function [Hm0, Tp] = floor_wave_height(Hm0, Tp)
            % floor_wave_height  Wave height floor with its Wilson peak period (the one place of this rule).
            %   [Hm0, Tp] = chess.CoastalHazardSystem.floor_wave_height(Hm0, Tp)
            %   Hm0 <= 0.01 m: Hm0 = 0.01 m and Tp = 1.1*3.3*Hm0^0.63 (Wilson
            %   wind-sea period of that height, about 0.199 s) on exactly
            %   those entries; the other entries and NaN are kept. Used by the
            %   storm database curation (curate_storm_forcing) and by PROS
            %   after the forcing uncertainty (chess.Model.Pros).
            %   Inputs:
            %     Hm0 - significant wave height [m], numeric array
            %     Tp  - peak wave period [s], numeric array of the size of Hm0
            %   Outputs:
            %     Hm0 - floored wave height [m], size of the input
            %     Tp  - peak wave period [s], Wilson value where Hm0 was floored
            floored = Hm0 <= 0.01;
            Hm0(floored) = 0.01;
            Tp(floored) = 1.1*3.3*Hm0(floored).^0.63;
        end

        function files = dependency_files(chs_dependencies_folder, region)
        % dependency_files  Paths and availability of the CHS_Dependencies files.
        %   files = chess.CoastalHazardSystem.dependency_files(chs_dependencies_folder, region)
        %
        %   CHS_Dependencies registry: the only place that knows the
        %   CHS_Dependencies folder layout and file names. Every library and GUI
        %   reader of CHS_Dependencies files gets its paths and the availability
        %   flags from here. Files are found by name pattern (dir, first match in
        %   name order); a file not found gives ''. Never errors: an empty or
        %   unknown region, an empty or missing folder just give empty paths and
        %   false flags.
        %
        %   Layout (<r> = region, e.g. CHS-NA):
        %     Bias_and_Uncertainty\<r>\
        %         <r>_Comb_*.mat, else <r>_WL_*.mat          water level (SWL)
        %                                                    bias & uncertainty
        %         <r>_STWAVE_Hm0_*.mat, else <r>_SWAN_Hm0_*.mat
        %                                                    wave height (Hm0)
        %                                                    bias & uncertainty
        %     Grid_Files\<r>\
        %         <r>_nodeID*.mat (variable nodeID), else    study grid
        %         <r>_staID*.mat (variable staID)
        %         <r>_ADCIRC_SPs.mat (CHS-LA only)           savepoint ->
        %                                                    ADCIRC node map
        %     Probability_Masses\<r>\
        %         <r>_ITCS_DSW_*.mat                         TC discrete storm
        %                                                    weights
        %         <r>_ITCS_Param.mat                         TC storm parameters
        %     Probability_Masses\ (shared by every region)
        %         CHS_Atl_CRLs*.mat                          coastal reference
        %                                                    locations
        %         SRR_TC_LI_*.mat, SRR_TC_MI_*.mat,          TC storm recurrence
        %         SRR_TC_HI_*.mat, SRR_TC_All_*.mat          rates (low, medium,
        %                                                    high, all intensities)
        %   Great Lakes studies (CHS-GLM, CHS-GLH) have no TC files; CHS-S2G has
        %   no TC discrete storm weights. CHS-TX and CHS-PR study grids have no
        %   value column (no offshore elevation).
        %
        %   Inputs:
        %     chs_dependencies_folder - CHS_Dependencies folder
        %                               (config.chs_dependencies; '' or []
        %                               allowed), char
        %     region                  - CHS region (config.region; '' allowed:
        %                               shared files and available_regions only),
        %                               char
        %   Outputs:
        %     files - file paths and flags, struct; fields:
        %               folder, region - the inputs, char
        %               supported_regions - CHS regions CHESS reads, 1 x 9 cell
        %               region_supported - region is one of supported_regions,
        %                   logical
        %               folder_exists - the folder exists, logical
        %               folder_layout_ok - the folder holds Bias_and_Uncertainty,
        %                   Grid_Files and Probability_Masses, logical
        %               folders - struct; bias_uncertainty, study_grid,
        %                   probability_masses: Bias_and_Uncertainty\<r>,
        %                   Grid_Files\<r>, Probability_Masses\<r> ('' without
        %                   folder or region); shared_probability_masses:
        %                   Probability_Masses ('' without folder), char
        %               water_level_bias_uncertainty_file,
        %               wave_height_bias_uncertainty_file, study_grid_file,
        %               savepoint_node_map_file, tc_discrete_storm_weights_file,
        %               tc_storm_parameters_file,
        %               coastal_reference_locations_file - full paths ('' when
        %                   not found), char
        %               storm_recurrence_rate_files - struct; low_intensity,
        %                   medium_intensity, high_intensity, all_intensities:
        %                   full paths ('' when not found), char
        %               study_grid_variable - 'nodeID', 'staID' or '' (variable
        %                   to load from study_grid_file), char
        %               uses_savepoint_node_map - study grid rows are ADCIRC
        %                   nodes, savepoints are mapped through the savepoint
        %                   node map file (CHS-LA), logical
        %               study_grid_has_elevation - the region's study grid has a
        %                   value column (false for CHS-TX, CHS-PR and
        %                   unsupported regions), logical
        %               exists - same file fields as above
        %                   (storm_recurrence_rate_files nested), true when the
        %                   file was found, struct of logical
        %               bias_uncertainty_available - water level and wave height
        %                   bias & uncertainty files found, logical
        %               study_grid_available - study grid file found, logical
        %               tropical_statistics_available - every file the TC
        %                   probability masses need (chess.CoastalHazardSystem.load_probability_masses):
        %                   discrete storm weights, storm parameters, coastal
        %                   reference locations, the four storm recurrence rates,
        %                   the study grid and (CHS-LA) the savepoint node map,
        %                   logical
        %               region_files - found files of the region (full paths),
        %                   column cell
        %               shared_files - found shared Probability_Masses files,
        %                   column cell
        %               available_regions - only for region '': supported_regions
        %                   with a study grid and both bias & uncertainty files
        %                   in the folder, 1 x N cell; {} (1 x 0) otherwise
        %
        %   See also chess.CoastalHazardSystem.savepoint_grid_row, chess.CoastalHazardSystem.bias_and_uncertainty,
        %   chess.CoastalHazardSystem.dependencies_message, chess.CoastalHazardSystem.load_probability_masses.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
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
        files.uses_savepoint_node_map = uses_node_map(region);
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

        function msg = dependencies_message(storm_sampling, region)
        % dependencies_message  Error message: TC/CC without CHS_Dependencies.
        %   msg = chess.CoastalHazardSystem.dependencies_message(storm_sampling, region)
        %
        %   Error message of a TC/CC request without CHS_Dependencies covering
        %   the region (chess.CoastalHazardSystem.dependency_files tropical_statistics_available).
        %   Shared by chess.Model.create (early check), chess.Model.prepare_storm_database
        %   (storm database build) and the GUI storm database wizard.
        %
        %   Inputs:
        %     storm_sampling - requested storm sampling, 'TC' or 'CC', char
        %     region         - CHS region (config.region), char
        %   Outputs:
        %     msg            - error message, char
        %
        %   See also chess.CoastalHazardSystem.dependency_files, chess.Model.create,
        %   chess.Model.prepare_storm_database.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        msg = sprintf(['%s storm sampling needs the CHS_Dependencies folder covering region %s (TC probability masses, ',...
            'bias & uncertainty). Without it CHESS runs XC only. Download from: https://chs.erdc.dren.mil/Home/Library'],...
            storm_sampling, region);
        end

        function bnu = bias_and_uncertainty(chs_dependencies, region, sp_ID, sp_coords, prev_info, prompt)
        % bias_and_uncertainty  Storm database bias, uncertainty, offshore elevation.
        %   bnu = chess.CoastalHazardSystem.bias_and_uncertainty(chs_dependencies, region, sp_ID, sp_coords)
        %   bnu = chess.CoastalHazardSystem.bias_and_uncertainty(..., prev_info, prompt)
        %
        %   CHS modeling bias & uncertainty and offshore elevation of a storm
        %   database, determined once when the database is built (stored in
        %   db_info, chess.CoastalHazardSystem.create_db_info). Shared by the library and the GUI storm
        %   database wizard.
        %   CHS_Dependencies files come from chess.CoastalHazardSystem.dependency_files (read when the
        %   folder exists and the region is supported).
        %   Study grid row (chess.CoastalHazardSystem.savepoint_grid_row, shared with the TC probability
        %   masses): one lookup gives the grid row and the offshore elevation
        %   (value column of that row). The savepoint ID is matched when the
        %   match is unique (CHS-LA: savepoint -> ADCIRC node through the
        %   savepoint node map file), else the grid point nearest to the
        %   savepoint coordinates is used (CHS-NA: nearest only, the grid holds
        %   mesh nodes). Printed: a grid point more than GRID_DISTANCE_WARNING_M
        %   (0.5 m) from the coordinates, an ID matched without coordinates.
        %   Lookup errors
        %   (chess:CoastalHazardSystem:gridNotFound | noCoordinates | spNotFound) are
        %   raised there.
        %   Offshore elevation: the grid stores depth, positive down (study
        %   datum); it is negated to an elevation, positive up. None for grids
        %   without a value column (CHS-TX, CHS-PR), NaN or fill values
        %   (<= GRID_FILL_LIMIT, -99999, e.g. CHS-GLH -999999).
        %   SWL values come from the water level bias & uncertainty file (Comb:
        %   PBL + ADCIRC, else WL: ADCIRC only) at the grid row; a row beyond
        %   that file is an error (chess:CoastalHazardSystem:biasUncertaintyRowNotFound, naming
        %   the row and both files). Hm0 values come from the wave height bias &
        %   uncertainty file (STWAVE/SWAN): global values, the regional average
        %   (_avg) when given per savepoint. Values not available there (no
        %   CHS_Dependencies for the region, no file) are entered once in the
        %   command window (source 'manual'); a database being rebuilt keeps its
        %   earlier 'manual'/'provided' values instead (prev_info). Hm0 bias is
        %   stored only when the wave file has it (not prompted, not applied).
        %
        %   Inputs:
        %     chs_dependencies - CHS_Dependencies folder (config.chs_dependencies),
        %                        char
        %     region           - CHS region (config.region), char
        %     sp_ID            - CHS ADCIRC savepoint ID (config.sp_ID), scalar
        %                        double
        %     sp_coords        - savepoint [latitude longitude] [deg] ([] or NaN:
        %                        not available), 1x2 double
        %     prev_info        - db_info of the database being rebuilt (optional,
        %                        default []: none), struct
        %     prompt           - false: never prompts, values not available stay
        %                        empty with an empty source (GUI wizard)
        %                        (optional, default true), logical
        %   Outputs:
        %     bnu - bias & uncertainty and savepoint location, struct; fields:
        %             chs_swl_b_a, chs_swl_b_r - SWL bias, absolute [m] /
        %                 relative [-], double
        %             chs_swl_u_a, chs_swl_u_r - SWL uncertainty, absolute [m] /
        %                 relative [-], double
        %             chs_hm0_b_a, chs_hm0_b_r - Hm0 bias, absolute [m] /
        %                 relative [-] ([] when the wave file has none), double
        %             chs_hm0_u_a, chs_hm0_u_r - Hm0 uncertainty, absolute [m] /
        %                 relative [-], double
        %             chs_swl_bu_source, chs_hm0_bu_source - 'chs_dependencies',
        %                 'manual', prev_info's 'manual'/'provided', or '' when
        %                 not prompted, char
        %             offshore_elevation - minus the grid depth [m, study datum,
        %                 positive up] ([] when none), double
        %             offshore_elevation_source - 'chs_dependencies' or '', char
        %             grid_distance_m - distance from the savepoint coordinates
        %                 to the grid point [m] ([] without coordinates or grid),
        %                 double
        %             sp_lat, sp_lon - savepoint coordinates [deg] ([] when not
        %                 available), double
        %
        %   See also chess.CoastalHazardSystem.create_db_info, chess.CoastalHazardSystem.savepoint_grid_row, chess.CoastalHazardSystem.dependency_files,
        %   chess.CoastalHazardSystem.build_storm_database.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        if nargin < 5
            prev_info = [];
        end
        if nargin < 6
            prompt = true;
        end
        bnu = struct('chs_swl_b_a', [], 'chs_swl_b_r', [], 'chs_swl_u_a', [], 'chs_swl_u_r', [], 'chs_swl_bu_source', '',...
            'chs_hm0_b_a', [], 'chs_hm0_b_r', [], 'chs_hm0_u_a', [], 'chs_hm0_u_r', [], 'chs_hm0_bu_source', '',...
            'offshore_elevation', [], 'offshore_elevation_source', '', 'grid_distance_m', [], 'sp_lat', [], 'sp_lon', []);
        if numel(sp_coords) == 2 && all(isfinite(sp_coords))
            bnu.sp_lat = sp_coords(1);
            bnu.sp_lon = sp_coords(2);
        else
            sp_coords = [];
        end

        %% CHS_DEPENDENCIES STUDY GRID, BIAS & UNCERTAINTY FILES
        files = chess.CoastalHazardSystem.dependency_files(chs_dependencies, region);
        if files.folder_exists && files.region_supported
            % Study Grid Row (savepoint_grid_row.m) And Offshore Elevation (Grid Depth, Positive Down, Negated)
            loc = chess.CoastalHazardSystem.savepoint_grid_row(files, sp_ID, sp_coords);
            grid_row = loc.row;
            bnu.grid_distance_m = loc.distance_m;
            report_grid_point(loc, sp_ID, region);
            if ~isempty(loc.value) && ~isnan(loc.value) && loc.value > chess.CoastalHazardSystem.GRID_FILL_LIMIT
                bnu.offshore_elevation = -loc.value;
                bnu.offshore_elevation_source = 'chs_dependencies';
            end
            % SWL: Study Grid Row
            if files.exists.water_level_bias_uncertainty_file
                circ_file = files.water_level_bias_uncertainty_file;
                [~, circ_name, circ_ext] = fileparts(circ_file);
                circ_name = [circ_name circ_ext];
                if any(strcmp(who('-file', circ_file), 'Comb'))
                    u_data = load(circ_file, 'Comb'); % PBL + ADCIRC
                    u_data = u_data.Comb;
                else
                    u_data = load(circ_file, 'WL'); % ADCIRC Only
                    u_data = u_data.WL;
                end
                if grid_row > numel(u_data.U_a)
                    error('chess:CoastalHazardSystem:biasUncertaintyRowNotFound', 'Save point SP%d (row %d of the %s study grid file %s) not found in the %s bias/uncertainty file %s.',...
                        sp_ID, grid_row, region, loc.grid_name, region, circ_name);
                end
                bnu.chs_swl_b_a = u_data.B_a(grid_row);
                bnu.chs_swl_b_r = u_data.B_r(grid_row);
                bnu.chs_swl_u_a = u_data.U_a(grid_row); % SWL absolute uncertainty
                bnu.chs_swl_u_r = u_data.U_r(grid_row); % SWL Proportional uncertainty
                bnu.chs_swl_bu_source = 'chs_dependencies';
            end
            % Hm0: Global Values (Region Average When Given Per Savepoint)
            if files.exists.wave_height_bias_uncertainty_file
                u_hm0 = load(files.wave_height_bias_uncertainty_file, 'Hm0');
                u_hm0 = u_hm0.Hm0;
                bnu.chs_hm0_u_a = global_value(u_hm0, 'U_a');
                bnu.chs_hm0_u_r = global_value(u_hm0, 'U_r');
                bnu.chs_hm0_b_a = global_value(u_hm0, 'B_a');
                bnu.chs_hm0_b_r = global_value(u_hm0, 'B_r');
                bnu.chs_hm0_bu_source = 'chs_dependencies';
            end
        end

        %% VALUES ENTERED FOR THE DATABASE BEING REBUILT
        groups = {'chs_swl_', {'b_a','b_r','u_a','u_r'}; 'chs_hm0_', {'b_a','b_r','u_a','u_r'}};
        if ~isempty(prev_info)
            for gg = 1:size(groups, 1)
                src = [groups{gg, 1} 'bu_source'];
                if isempty(bnu.(src)) && any(strcmp(prev_info.(src), {'manual', 'provided'}))
                    for ff = groups{gg, 2}
                        bnu.([groups{gg, 1} ff{1}]) = prev_info.([groups{gg, 1} ff{1}]);
                    end
                    bnu.(src) = prev_info.(src);
                end
            end
        end

        %% MANUAL ENTRY (ONCE, WHEN THE STORM DATABASE IS BUILT)
        if ~prompt
            return
        end
        if isempty(bnu.chs_swl_bu_source) || isempty(bnu.chs_hm0_bu_source)
            disp('Storm database: bias/uncertainty values not available from CHS_Dependencies. Please provide values manually:');
        end
        if isempty(bnu.chs_swl_bu_source)
            bnu.chs_swl_b_a = input('  SWL Absolute Bias [m]:         ');
            bnu.chs_swl_b_r = input('  SWL Relative Bias [-]:         ');
            bnu.chs_swl_u_a = input('  SWL Absolute Uncertainty [m]:  ');
            bnu.chs_swl_u_r = input('  SWL Relative Uncertainty [-]:  ');
            bnu.chs_swl_bu_source = 'manual';
        end
        if isempty(bnu.chs_hm0_bu_source)
            bnu.chs_hm0_u_a = input('  Hm0 Absolute Uncertainty [m]:  ');
            bnu.chs_hm0_u_r = input('  Hm0 Relative Uncertainty [-]:  ');
            bnu.chs_hm0_bu_source = 'manual';
        end
        end

        function [stm_type_chk, data_type_chk, alt_chk] = storm_data_covers(storm, prob_mass, storm_sampling,...
            use_peaks, use_timeseries, create_wlp, create_whp)
        % storm_data_covers  Check that a storm database holds the requested storm data.
        %   [stm_type_chk, data_type_chk, alt_chk] = chess.CoastalHazardSystem.storm_data_covers(storm,
        %       prob_mass, storm_sampling, use_peaks, use_timeseries, create_wlp,
        %       create_whp)
        %
        %   Storm database holds the request: storm types, data types and
        %   alternate Peaks datasets (WLP/WHP). TC counts as present only with
        %   its probability masses (prob_mass.TC_Freq not empty): a database
        %   built without CHS_Dependencies has XC only. Each check includes the
        %   previous one.
        %
        %   Inputs:
        %     storm          - storm database content (<db>.mat), struct
        %     prob_mass      - TC probability masses (<db>.mat), struct or []
        %     storm_sampling - requested storm sampling, 'XC', 'TC' or 'CC', char
        %     use_peaks      - Peaks requested (0/1), scalar double
        %     use_timeseries - Timeseries requested (0/1), scalar double
        %     create_wlp     - WLP Peaks dataset requested (0/1), scalar double
        %     create_whp     - WHP Peaks dataset requested (0/1), scalar double
        %   Outputs:
        %     stm_type_chk   - requested storm types present, logical
        %     data_type_chk  - ... and their requested data types, logical
        %     alt_chk        - ... and their requested alternate Peaks datasets
        %                      (the database holds the request), logical
        %
        %   See also chess.CoastalHazardSystem.create_db_info, chess.CoastalHazardSystem.build_storm_database, chess.CoastalHazardSystem.validate_user_storm.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        need_types = {'TC','XC'};
        need_types = need_types([any(strcmp(storm_sampling, {'TC','CC'})), any(strcmp(storm_sampling, {'XC','CC'}))]);
        has_tc = isfield(storm, 'TC') && isstruct(prob_mass) && isfield(prob_mass, 'TC_Freq') && ~isempty(prob_mass.TC_Freq);
        stm_type_chk = all(isfield(storm, need_types)) && (has_tc || ~ismember('TC', need_types));
        data_type_chk = stm_type_chk && all(cellfun(@(t) (use_peaks == 0 || isfield(storm.(t), 'Peaks')) &&...
            (use_timeseries == 0 || isfield(storm.(t), 'Timeseries')), need_types));
        alt_chk = data_type_chk && all(cellfun(@(t) (create_wlp == 0 || (use_peaks == 1 && isfield(storm.(t).Peaks, 'WLP'))) &&...
            (create_whp == 0 || (use_peaks == 1 && isfield(storm.(t).Peaks, 'WHP'))), need_types));
        end

        function parts = file_name_parts(file_names)
        % file_name_parts  Split CHS file names into their name tokens.
        %   parts = chess.CoastalHazardSystem.file_name_parts(file_names)
        %
        %   The one rule for reading a CHS file name. CHS file names read
        %       <region>_<storm flag>_<simulation>_<post type>_SP<id>_<model>_<data type>.h5
        %   e.g. CHS-NA_XH_SimB_Post0_SP05572_ADCIRC01_Peaks.h5,
        %        CHS-NA_TS_SimB_Post0_SP024_STWAVE02_Timeseries.h5,
        %        CHS-GLMH_XH_SimBslc0ice1_Post0_SP02994_SWAN01_Timeseries.h5.
        %   Tokens are split on '_' and matched exactly (case-sensitive); folders
        %   are allowed, only the name is read. The storm flag (token 2) varies
        %   between CHS files: extratropical files use XC or XH, tropical files
        %   TC or TS. STORM_FLAG_ALIASES (top of the code) maps each flag to the
        %   storm type CHESS uses ('XC'/'TC'): add a new flag variant there only.
        %   The data type is the last token and the model the second-to-last
        %   token (e.g. ADCIRC01, STWAVE02, SWAN01); a water level file is one
        %   whose model starts with ADCIRC. A storm file has a .h5 extension (any
        %   case) and data type Peaks or Timeseries (HC/AEP/AEF files and other
        %   extensions are not storm files). Used by chess.CoastalHazardSystem.storm_file_names,
        %   chess.CoastalHazardSystem.study_identity, chess.CoastalHazardSystem.storm_file_slots, chess.CoastalHazardSystem.data_attributes,
        %   chess.CoastalHazardSystem.quality_check, chess.CoastalHazardSystem.convert_h5, chess.Model.create,
        %   CHESSPlotsBase and the GUI storm database wizard, so they cannot
        %   disagree.
        %
        %   Inputs:
        %     file_names - CHS file name(s), folders allowed, char, string or cell
        %   Outputs:
        %     parts - name parts, one element per file name (size(file_names),
        %             1x1 for a char), struct array; fields:
        %               region        - token 1 (e.g. 'CHS-NA'), char
        %               storm_flag    - token 2 as written ('XH', 'TS', ...; ''
        %                               if missing), char
        %               storm_type    - 'XC' (XC/XH), 'TC' (TC/TS), '' if
        %                               unrecognized, char
        %               simulation    - token 3 (e.g. 'SimB'; '' if missing), char
        %               post_type     - token 4 (e.g. 'Post0'; '' if missing), char
        %               save_point_id - token 5 as written (e.g. 'SP05572'; '' if
        %                               missing; chess.CoastalHazardSystem.study_identity checks it),
        %                               char
        %               model         - second-to-last token (e.g. 'ADCIRC01'; ''
        %                               if missing), char
        %               data_type     - last token, as written (e.g. 'Peaks'), char
        %               is_adcirc     - water level (ADCIRC) file: model starts
        %                               with 'ADCIRC', logical
        %               is_storm_file - .h5 and data type Peaks or Timeseries,
        %                               logical
        %
        %   See also chess.CoastalHazardSystem.storm_file_names, chess.CoastalHazardSystem.storm_file_slots,
        %   chess.CoastalHazardSystem.storm_mat_name_parts.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        STORM_FLAG_ALIASES = {'XC', {'XC', 'XH'};...
                              'TC', {'TC', 'TS'}};
        STORM_DATA_TYPES = {'Peaks', 'Timeseries'};

        if ischar(file_names) || isstring(file_names)
            file_names = cellstr(file_names);
        end
        parts = repmat(struct('region', '', 'storm_flag', '', 'storm_type', '', 'simulation', '', 'post_type', '',...
            'save_point_id', '', 'model', '', 'data_type', '', 'is_adcirc', false, 'is_storm_file', false), size(file_names));
        for ff = 1:numel(file_names)
            [~, name, extension] = fileparts(file_names{ff});
            tokens = strsplit(name, '_');
            parts(ff).region = tokens{1};
            parts(ff).data_type = tokens{end};
            if numel(tokens) >= 2
                parts(ff).storm_flag = tokens{2};
                parts(ff).model = tokens{end-1};
            end
            if numel(tokens) >= 5
                parts(ff).simulation = tokens{3};
                parts(ff).post_type = tokens{4};
                parts(ff).save_point_id = tokens{5};
            end
            for aa = 1:size(STORM_FLAG_ALIASES, 1)
                if ismember(parts(ff).storm_flag, STORM_FLAG_ALIASES{aa, 2})
                    parts(ff).storm_type = STORM_FLAG_ALIASES{aa, 1};
                end
            end
            parts(ff).is_adcirc = startsWith(parts(ff).model, 'ADCIRC');
            parts(ff).is_storm_file = strcmpi(extension, '.h5') && ismember(parts(ff).data_type, STORM_DATA_TYPES);
        end
        end

        function [storm_names, is_storm] = storm_file_names(file_names)
        % storm_file_names  Keep the CHS storm files (.h5 Peaks or Timeseries).
        %   [storm_names, is_storm] = chess.CoastalHazardSystem.storm_file_names(file_names)
        %
        %   CHS storm files of a list of file names: the one rule deciding which
        %   CHS files CHESS reads. A storm file has a .h5 extension (any case)
        %   and a Peaks or Timeseries data type token (last name token:
        %   chess.CoastalHazardSystem.file_name_parts, the CHS file name rule <region>_<storm
        %   flag>_<simulation>_<post type>_SP<id>_<model>_<data type>). Every
        %   other file (HC/AEP/AEF .h5 files, other extensions) is dropped
        %   silently. Used where the CHS input file names are read
        %   (chess.Model.create: .zip and CHS_Data .mat; chess.Model.prepare_storm_database;
        %   the GUI storm database wizard), so the storm file check
        %   (chess.CoastalHazardSystem.storm_file_slots, chess.CoastalHazardSystem.study_identity, also applying it), the
        %   study datum and savepoint coordinates read and the conversion lists
        %   only see storm files.
        %
        %   Inputs:
        %     file_names  - file names (folders allowed, only the name is read),
        %                   cell
        %   Outputs:
        %     storm_names - the storm files of file_names, as given, cell
        %     is_storm    - storm file flag of each file name, logical,
        %                   size(file_names)
        %
        %   See also chess.CoastalHazardSystem.file_name_parts, chess.CoastalHazardSystem.storm_file_slots, chess.CoastalHazardSystem.zip_h5_names.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        name_parts = chess.CoastalHazardSystem.file_name_parts(file_names);
        is_storm = reshape(logical([name_parts.is_storm_file]), size(file_names));
        storm_names = file_names(is_storm);
        end

        function [slots, errors, study] = storm_file_slots(file_names, request)
        % storm_file_slots  Sort CHS storm files into slots and check a request.
        %   [slots, errors, study] = chess.CoastalHazardSystem.storm_file_slots(file_names)
        %   [slots, errors, study] = chess.CoastalHazardSystem.storm_file_slots(file_names, request)
        %
        %   CHS storm file check, by file name only (run it before any unzip or
        %   .h5 conversion). The study identity is checked first
        %   (chess.CoastalHazardSystem.study_identity: a file name given twice, more than one ADCIRC or
        %   wave save point, simulation or post type are errors). Every CHS
        %   storm file (chess.CoastalHazardSystem.storm_file_names: .h5, data type Peaks or
        %   Timeseries; other files such as HC/AEF files are ignored) goes to a
        %   slot: storm type (name token 2: XH/XC -> XC, TS/TC -> TC) x data type
        %   (Peaks/Timeseries), read by chess.CoastalHazardSystem.file_name_parts. A slot is either
        %   empty or holds exactly one water level (ADCIRC model) file and one
        %   wave (STWAVE/SWAN/WAM) file: a half pair or a duplicate is an error
        %   naming the slot and its files. When the slots are valid and a
        %   request is given, the request is checked against the complete slots:
        %       storm_sampling: XC/TC need that storm type, CC needs both.
        %       use_peaks / use_timeseries: Peaks / Timeseries of every requested
        %           storm type.
        %       create_wlp / create_whp: Peaks and Timeseries of every requested
        %           storm type.
        %
        %   Inputs:
        %     file_names - .h5 file names (folders allowed, only the name is
        %                  read), cell
        %     request    - request to check (optional, default []: slots only),
        %                  struct; fields storm_sampling ('XC', 'TC' or 'CC'),
        %                  use_peaks, use_timeseries, create_wlp, create_whp
        %                  (0/1)
        %   Outputs:
        %     slots  - one row per slot (XC Peaks, XC Timeseries, TC Peaks, TC
        %              Timeseries), 4 x 5 table; variables storm_type, data_type,
        %              water_level (file names), wave (file names), complete (one
        %              water level + one wave file)
        %     errors - identity and slot errors, else request errors ({} when the
        %              input passes), cell of char
        %     study  - study identity (region, simulation, post_type, sp_ID,
        %              sp_ID_wave) from chess.CoastalHazardSystem.study_identity, struct
        %
        %   See also chess.CoastalHazardSystem.study_identity, chess.CoastalHazardSystem.storm_file_names, chess.CoastalHazardSystem.file_name_parts,
        %   chess.CoastalHazardSystem.build_storm_database.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        if nargin < 2
            request = [];
        end
        storm_type = {'XC'; 'XC'; 'TC'; 'TC'};
        data_type = {'Peaks'; 'Timeseries'; 'Peaks'; 'Timeseries'};
        water_level = repmat({cell(1, 0)}, 4, 1);
        wave = repmat({cell(1, 0)}, 4, 1);
        [study, errors] = chess.CoastalHazardSystem.study_identity(file_names);

        %% SORT STORM FILES INTO SLOTS (A Repeated File Name Counts Once: chess.CoastalHazardSystem.study_identity Reports It)
        [~, fnames, fexts] = cellfun(@fileparts, chess.CoastalHazardSystem.storm_file_names(file_names), 'un', false);
        fnames = strcat(fnames, fexts);
        [~, keep] = unique(lower(fnames), 'stable');
        for ff = keep(:)'
            fname_ext = fnames{ff};
            name_parts = chess.CoastalHazardSystem.file_name_parts(fname_ext);
            if isempty(name_parts.storm_type)
                errors{end+1} = sprintf('%s: unknown storm type (name token 2 must be XH/XC or TS/TC)', fname_ext); %#ok<AGROW>
                continue
            end
            row = find(strcmp(storm_type, name_parts.storm_type) & strcmp(data_type, name_parts.data_type));
            if name_parts.is_adcirc
                water_level{row}{end+1} = fname_ext;
            else
                wave{row}{end+1} = fname_ext;
            end
        end
        n_wl = cellfun(@numel, water_level);
        n_wv = cellfun(@numel, wave);
        complete = n_wl == 1 & n_wv == 1;
        slots = table(storm_type, data_type, water_level, wave, complete);
        for rr = find(~complete & (n_wl + n_wv) > 0)'
            errors{end+1} = sprintf('%s %s needs exactly one water level (ADCIRC) file and one wave (STWAVE/SWAN) file, found water level: %s | wave: %s',...
                storm_type{rr}, data_type{rr}, file_list(water_level{rr}), file_list(wave{rr})); %#ok<AGROW>
        end
        if ~isempty(errors) || isempty(request)
            return
        end

        %% CHECK THE REQUEST AGAINST THE COMPLETE SLOTS
        if strcmp(request.storm_sampling, 'CC')
            req_types = {'XC', 'TC'};
        else
            req_types = {request.storm_sampling};
        end
        switches = {'use_peaks', {'Peaks'}; 'use_timeseries', {'Timeseries'};...
            'create_wlp', {'Peaks', 'Timeseries'}; 'create_whp', {'Peaks', 'Timeseries'}};
        for tt = 1:numel(req_types)
            has_type = complete(strcmp(storm_type, req_types{tt}));
            if ~any(has_type)
                errors{end+1} = sprintf('%s storm sampling needs %s storms: %s has no Peaks or Timeseries files in this input',...
                    request.storm_sampling, req_types{tt}, req_types{tt}); %#ok<AGROW>
                continue
            end
            for dd = {'Peaks', 'Timeseries'}
                if complete(strcmp(storm_type, req_types{tt}) & strcmp(data_type, dd{1}))
                    continue
                end
                needed_by = {};
                for ss = 1:size(switches, 1)
                    if request.(switches{ss, 1}) == 1 && ismember(dd{1}, switches{ss, 2})
                        needed_by{end+1} = sprintf('%s = 1', switches{ss, 1}); %#ok<AGROW>
                    end
                end
                if ~isempty(needed_by)
                    errors{end+1} = sprintf('%s has no %s in this input (needed by %s)', req_types{tt}, dd{1}, strjoin(needed_by, ', ')); %#ok<AGROW>
                end
            end
        end
        end

        function [study, errors] = study_identity(file_names)
        % study_identity  Study identity (region, save points) of CHS storm files.
        %   [study, errors] = chess.CoastalHazardSystem.study_identity(file_names)
        %
        %   CHS study identity of the storm files of an input, by file name only
        %   (called by chess.CoastalHazardSystem.storm_file_slots, before any unzip or .h5
        %   conversion). CHS file names read
        %   <region>_<storm type>_<simulation>_<post type>_SP<id>_<model>_<data type>
        %   (e.g. CHS-NA_XH_SimB_Post0_SP05572_ADCIRC01_Peaks.h5; tokens and
        %   water level (ADCIRC model) file from chess.CoastalHazardSystem.file_name_parts). Only storm
        %   files (chess.CoastalHazardSystem.storm_file_names: .h5, data type Peaks or Timeseries) are
        %   checked; HC/AEF and other files are ignored. Errors (each naming the
        %   offending values and files):
        %       - a file name given more than once (case-insensitive, e.g. the
        %         same file in two zip subfolders);
        %       - a name without a save point token (token 5, SP<id>);
        %       - more than one water level (ADCIRC) save point or more than one
        %         wave save point;
        %       - more than one CHS region (token 1, e.g. CHS-NA), simulation
        %         (token 3, e.g. SimB) or post type (token 4, e.g. Post0).
        %
        %   Inputs:
        %     file_names - .h5 file names (folders allowed, only the name is
        %                  read), cell
        %   Outputs:
        %     study  - study identity of the storm files, struct; fields region,
        %              simulation, post_type (char, '' unless unique), sp_ID
        %              (ADCIRC save point) and sp_ID_wave (wave save point)
        %              (double, [] unless unique)
        %     errors - identity errors ({} when the input passes), cell of char
        %
        %   See also chess.CoastalHazardSystem.storm_file_slots, chess.CoastalHazardSystem.file_name_parts,
        %   chess.CoastalHazardSystem.storm_file_names.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        errors = {};
        study = struct('region', '', 'simulation', '', 'post_type', '', 'sp_ID', [], 'sp_ID_wave', []);

        %% STORM FILE NAMES
        [~, names, exts] = cellfun(@fileparts, chess.CoastalHazardSystem.storm_file_names(file_names(:)'), 'un', false);
        names = strcat(names, exts);

        %% DUPLICATE FILE NAMES
        [~, first_idx, name_idx] = unique(lower(names), 'stable');
        name_count = accumarray(name_idx(:), 1);
        for dd = find(name_count > 1)'
            errors{end+1} = sprintf('%s is in the input %d times (e.g. in more than one zip subfolder): keep one copy',...
                names{first_idx(dd)}, name_count(dd)); %#ok<AGROW>
        end
        names = names(first_idx);

        %% NAME TOKENS
        region = cell(1, 0);
        simulation = cell(1, 0);
        post_type = cell(1, 0);
        sp_token = cell(1, 0);
        is_wl = false(1, 0);
        valid = cell(1, 0);
        for ff = 1:numel(names)
            name_parts = chess.CoastalHazardSystem.file_name_parts(names{ff});
            if ~startsWith(name_parts.save_point_id, 'SP') || isnan(str2double(name_parts.save_point_id(3:end)))
                errors{end+1} = sprintf('%s: name token 5 must be the save point (SP<id>), expected <region>_<storm type>_<simulation>_<post type>_SP<id>_<model>_<data type>',...
                    names{ff}); %#ok<AGROW>
                continue
            end
            valid{end+1} = names{ff}; %#ok<AGROW>
            region{end+1} = name_parts.region; %#ok<AGROW>
            simulation{end+1} = name_parts.simulation; %#ok<AGROW>
            post_type{end+1} = name_parts.post_type; %#ok<AGROW>
            sp_token{end+1} = name_parts.save_point_id; %#ok<AGROW>
            is_wl(end+1) = name_parts.is_adcirc; %#ok<AGROW>
        end

        %% ONE SAVE POINT PAIR, ONE REGION, ONE SIMULATION, ONE POST TYPE
        [errors, wl_sp] = single_value(errors, sp_token(is_wl), valid(is_wl), 'water level (ADCIRC) save point');
        [errors, wv_sp] = single_value(errors, sp_token(~is_wl), valid(~is_wl), 'wave save point');
        [errors, study.region] = single_value(errors, region, valid, 'CHS region (name token 1)');
        [errors, study.simulation] = single_value(errors, simulation, valid, 'simulation (name token 3)');
        [errors, study.post_type] = single_value(errors, post_type, valid, 'post type (name token 4)');
        if ~isempty(wl_sp)
            study.sp_ID = str2double(wl_sp(3:end));
        end
        if ~isempty(wv_sp)
            study.sp_ID_wave = str2double(wv_sp(3:end));
        end
        end

        function parts = storm_mat_name_parts(file)
        % chess.CoastalHazardSystem.storm_mat_name_parts  Save point ID and CHS region of a storm .mat name.
        %   parts = chess.CoastalHazardSystem.storm_mat_name_parts(file)
        %
        %   The one rule for reading a storm .mat file name (storm_data input: a
        %   user storm database, any naming). The name without folders and
        %   extension is split on '_'; the save point is the first token that
        %   reads SP<digits> (e.g. SP05572) and the CHS region the first token
        %   that starts with 'CHS-' (e.g. CHS-NA). A name without such a token
        %   gives an empty value; each caller sets its own default. Used by
        %   chess.Model.create and the GUI storm database wizard
        %   (CHSStormDBImportUI), so they cannot disagree. CHS .h5 names are read
        %   by chess.CoastalHazardSystem.file_name_parts.
        %
        %   Inputs:
        %     file  - storm .mat file name (folders allowed), char or string
        %   Outputs:
        %     parts - name parts, struct; fields:
        %               sp_ID  - save point ID ([] when no token reads
        %                        SP<digits>), double
        %               region - CHS region ('' when no token starts with
        %                        'CHS-'), char
        %
        %   See also chess.CoastalHazardSystem.file_name_parts, chess.Model.create.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        [~, name] = fileparts(char(file));
        tokens = strsplit(name, '_');
        parts = struct('sp_ID', [], 'region', '');
        sp_token = tokens(~cellfun(@isempty, regexp(tokens, '^SP\d+$', 'once')));
        if ~isempty(sp_token)
            parts.sp_ID = str2double(sp_token{1}(3:end));
        end
        region = tokens(startsWith(tokens, 'CHS-'));
        if ~isempty(region)
            parts.region = region{1};
        end
        end

        function h5_names = zip_h5_names(zip_name)
        % chess.CoastalHazardSystem.zip_h5_names  Names of the .h5 files in a zip file, without decompressing.
        %   h5_names = chess.CoastalHazardSystem.zip_h5_names(zip_name)
        %
        %   HDF5 file names in a zip folder (sorted, folders stripped, .h5
        %   extension in any case, names kept as stored), read without
        %   decompressing. macOS metadata (entries under __MACOSX/, names
        %   starting with '._') is skipped. A path that cannot be resolved or a
        %   file that is not a readable zip is an error (chess:CoastalHazardSystem:badZip).
        %   Shared by chess.Model.create and the GUI storm database wizard (storm
        %   file check before any unzip).
        %
        %   Inputs:
        %     zip_name - zip folder (relative or full path), char
        %   Outputs:
        %     h5_names - .h5 file names (name + extension), n x 1 cell
        %
        %   See also chess.CoastalHazardSystem.storm_file_names, chess.CoastalHazardSystem.zip_h5_attributes, chess.CoastalHazardSystem.zip_extract_entry.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        % Absolute Path (Java Resolves Relative Paths Against Its Own Working Folder; exist() Also Finds Files On The MATLAB Path)
        zip_info = dir(zip_name);
        if isscalar(zip_info) && ~zip_info.isdir
            zip_path = fullfile(zip_info.folder, zip_info.name);
        else
            zip_path = which(zip_name);
        end
        if isempty(zip_path)
            error('chess:CoastalHazardSystem:badZip', 'could not resolve the full path of zip folder ''%s''.', zip_name);
        end
        try
            zip_obj = java.util.zip.ZipFile(zip_path);
        catch
            error('chess:CoastalHazardSystem:badZip', '''%s'' is not a readable zip folder.', zip_path);
        end
        zip_cleanup = onCleanup(@() zip_obj.close());
        try
            zip_entries = zip_obj.entries();
            h5_names = cell(0, 1);
            while zip_entries.hasMoreElements()
                entry_path = char(zip_entries.nextElement().getName());
                [~, entry_name, entry_ext] = fileparts(entry_path);
                if contains(['/' entry_path], '/__MACOSX/') || startsWith(entry_name, '._')
                    continue
                end
                if strcmpi(entry_ext, '.h5')
                    h5_names{end+1, 1} = [entry_name entry_ext]; %#ok<AGROW>
                end
            end
        catch
            error('chess:CoastalHazardSystem:badZip', '''%s'' is not a readable zip folder.', zip_path);
        end
        h5_names = sort(h5_names);
        end

        function [vertical_datum, sp_coords] = zip_h5_attributes(zip_name, h5_file)
        % chess.CoastalHazardSystem.zip_h5_attributes  Study datum and savepoint coordinates from a CHS zip.
        %   [vertical_datum, sp_coords] = chess.CoastalHazardSystem.zip_h5_attributes(zip_name, h5_file)
        %
        %   Study vertical datum and ADCIRC save point coordinates from the root
        %   attributes ('Vertical Datum', 'Save Point Latitude', 'Save Point
        %   Longitude') of one ADCIRC storm .h5 entry of a CHS zip folder, with
        %   the same contract as chess.CoastalHazardSystem.data_attributes (which reads them from
        %   converted CHS data and is reused here). Only that entry is extracted
        %   (chess.CoastalHazardSystem.zip_extract_entry), into a system temp folder removed on return,
        %   errors included. An entry that cannot be extracted is an error
        %   (chess.CoastalHazardSystem.zip_extract_entry errors). Shared by chess.Model.create and the GUI
        %   storm database wizard (CHSStormDBImportUI).
        %
        %   Inputs:
        %     zip_name       - CHS zip folder (relative or full path), char
        %     h5_file        - ADCIRC storm .h5 entry name (name + extension),
        %                      char
        %   Outputs:
        %     vertical_datum - study vertical datum ('' if not found), char
        %     sp_coords      - ADCIRC save point [latitude longitude] [deg],
        %                      1x2 double ([] if either is not found)
        %
        %   See also chess.CoastalHazardSystem.data_attributes, chess.CoastalHazardSystem.zip_extract_entry, chess.CoastalHazardSystem.zip_h5_names.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        temp_path = tempname;
        temp_cleanup = onCleanup(@() remove_temp_folder(temp_path)); %#ok<NASGU>
        h5_path = chess.CoastalHazardSystem.zip_extract_entry(zip_name, h5_file, temp_path);
        % Root Attributes Found, In The Converted CHS Data Layout Read By chess.CoastalHazardSystem.data_attributes
        attribute_names = {'Vertical Datum', 'Save Point Latitude', 'Save Point Longitude'};
        root_attributes = struct('Name', {}, 'Value', {});
        for k = 1:numel(attribute_names)
            try
                attribute_value = h5readatt(h5_path, '/', attribute_names{k});
                root_attributes(end+1).Name = attribute_names{k}; %#ok<AGROW>
                root_attributes(end).Value = attribute_value;
            catch
                % Attribute Not In The File
            end
        end
        CHS_Data = struct('Filename', h5_file, 'Conv_Data', struct('Attributes', root_attributes));
        [vertical_datum, sp_coords] = chess.CoastalHazardSystem.data_attributes(CHS_Data);
        end

        function [vertical_datum, sp_coords] = data_attributes(CHS_Data)
        % data_attributes  Vertical datum and savepoint coordinates from CHS_Data.
        %   [vertical_datum, sp_coords] = chess.CoastalHazardSystem.data_attributes(CHS_Data)
        %
        %   Pulls the CHS study vertical datum and ADCIRC save point coordinates
        %   from converted CHS data (output of chess.CoastalHazardSystem.convert_zip). Lets callers
        %   that only have a CHS_Data .mat (no .h5 files) recover the same
        %   details read from the .h5 root attributes ('Vertical Datum', 'Save
        %   Point Latitude', 'Save Point Longitude'). Read from the first ADCIRC
        %   storm file (chess.CoastalHazardSystem.file_name_parts: Peaks/Timeseries; HC/AEF files are
        %   ignored). The coordinates locate the savepoint in the
        %   CHS_Dependencies study grid (chess.CoastalHazardSystem.bias_and_uncertainty).
        %
        %   Inputs:
        %     CHS_Data - converted CHS files (Filename, Conv_Data),
        %                1 x number_of_files struct
        %   Outputs:
        %     vertical_datum - study vertical datum ('' if not found), char
        %     sp_coords      - ADCIRC save point [latitude longitude] [deg] ([] if
        %                      either is not found), 1x2 double
        %
        %   See also chess.CoastalHazardSystem.zip_h5_attributes, chess.CoastalHazardSystem.file_name_parts,
        %   chess.CoastalHazardSystem.bias_and_uncertainty, chess.Model.create.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        vertical_datum = '';
        sp_coords = [];
        % ADCIRC Reference File (First Storm File Found)
        file_parts = chess.CoastalHazardSystem.file_name_parts({CHS_Data.Filename});
        ad_indx = find([file_parts.is_storm_file] & [file_parts.is_adcirc], 1);
        if isempty(ad_indx)
            return
        end
        cData = CHS_Data(ad_indx).Conv_Data;
        % File (Root) Attributes: Vertical Datum & Save Point Coordinates
        if isfield(cData, 'Attributes') && isstruct(cData.Attributes) && ~isempty(cData.Attributes)
            att_names = {cData.Attributes.Name};
            att_indx = strcmp(att_names, 'Vertical Datum');
            if any(att_indx)
                vertical_datum = char(cData.Attributes(att_indx).Value);
            end
            lat_indx = find(strcmp(att_names, 'Save Point Latitude'), 1);
            lon_indx = find(strcmp(att_names, 'Save Point Longitude'), 1);
            if ~isempty(lat_indx) && ~isempty(lon_indx)
                sp_coords = [to_double(cData.Attributes(lat_indx).Value), to_double(cData.Attributes(lon_indx).Value)];
                if any(isnan(sp_coords))
                    sp_coords = [];
                end
            end
        end
        end

        function CHS_Data = strip_data_folders(CHS_Data)
        % strip_data_folders  Keep only the file name in CHS_Data.Filename.
        %   CHS_Data = chess.CoastalHazardSystem.strip_data_folders(CHS_Data)
        %
        %   Keeps only the file name (name + extension) in CHS_Data.Filename.
        %   Storm files are selected by name tokens (chess.CoastalHazardSystem.file_name_parts reads the
        %   name only), and a folder (temp folder, user folder) must never reach
        %   the stored file names. Used by chess.CoastalHazardSystem.convert_zip (raw files hold names
        %   only), chess.CoastalHazardSystem.build_storm_database (CHS_Data .mat inputs), chess.Model.create
        %   and the GUI storm database wizard (CHS_Data .mat import).
        %
        %   Inputs:
        %     CHS_Data - converted CHS files (Filename, Conv_Data),
        %                1 x number_of_files struct
        %   Outputs:
        %     CHS_Data - same, Filename without folders, 1 x number_of_files
        %                struct
        %
        %   See also chess.CoastalHazardSystem.convert_zip, chess.CoastalHazardSystem.build_storm_database, chess.CoastalHazardSystem.file_name_parts.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        [~, file_names, file_extensions] = cellfun(@fileparts, {CHS_Data.Filename}, 'un', false);
        file_names = strcat(file_names, file_extensions);
        [CHS_Data.Filename] = file_names{:};
        end

        function loc = savepoint_grid_row(files, sp_ID, sp_coords)
        % chess.CoastalHazardSystem.savepoint_grid_row  Study grid row of a CHS savepoint (ID match, else nearest).
        %   loc = chess.CoastalHazardSystem.savepoint_grid_row(files, sp_ID, sp_coords)
        %
        %   Study grid row of a savepoint: the one lookup shared by the TC
        %   probability masses (chess.CoastalHazardSystem.load_probability_masses) and the storm
        %   database bias & uncertainty / offshore elevation
        %   (chess.CoastalHazardSystem.bias_and_uncertainty). Prints nothing.
        %   Study grid (chess.CoastalHazardSystem.dependency_files): [ID Node Lat Lon Value] (5
        %   columns), [ID Lat Lon Value] (4) or [ID Lat Lon] (3, no value).
        %   Resolution:
        %     - staID grids: savepoint ID in column 1; CHS-LA (study grid rows
        %       are ADCIRC nodes): savepoint -> ADCIRC node through the savepoint
        %       node map file, node in column 2. The ID match is used when it is
        %       unique; otherwise (ID missing or repeated, e.g. the CHS-TX grid)
        %       the grid point nearest to sp_coords.
        %     - nodeID grids (CHS-NA: mesh nodes, no savepoint IDs): the grid
        %       point nearest to sp_coords only.
        %   Nearest: great-circle distance (chess.Common.haversine_km), ties to the first row.
        %   Errors: no study grid file, or no CHS-LA savepoint node map when the
        %   ID is needed (chess:CoastalHazardSystem:gridNotFound, naming the folder);
        %   nodeID grid without coordinates (chess:CoastalHazardSystem:noCoordinates);
        %   no unique ID match and no coordinates (chess:CoastalHazardSystem:spNotFound,
        %   naming the file searched).
        %
        %   Inputs:
        %     files     - chess.CoastalHazardSystem.dependency_files output of the region, struct
        %     sp_ID     - CHS ADCIRC savepoint ID, scalar double
        %     sp_coords - savepoint [latitude longitude] [deg] ([] or NaN: not
        %                 available), 1x2 double
        %   Outputs:
        %     loc - study grid point, struct; fields:
        %             row        - study grid row, double
        %             lat, lon   - grid point coordinates [deg], double
        %             value      - grid value column of the row (depth [m,
        %                          study datum, positive down]; [] for grids
        %                          without a value column), double
        %             method     - 'id' (savepoint ID matched) or 'nearest', char
        %             distance_m - distance from sp_coords to the grid point [m]
        %                          ([] without coordinates), double
        %             grid_name  - study grid file name (with extension), char
        %
        %   See also chess.CoastalHazardSystem.dependency_files, chess.Common.haversine_km, chess.CoastalHazardSystem.bias_and_uncertainty,
        %   chess.CoastalHazardSystem.load_probability_masses.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        region = files.region;
        if ~files.study_grid_available
            error('chess:CoastalHazardSystem:gridNotFound', 'No %s study grid file (%s_nodeID*.mat or %s_staID*.mat) found in %s.',...
                region, region, region, files.folders.study_grid);
        end
        has_coords = numel(sp_coords) == 2 && all(isfinite(sp_coords));
        grid_name = file_name(files.study_grid_file);
        grid_data = load(files.study_grid_file, files.study_grid_variable); grid_data = grid_data.(files.study_grid_variable);
        lat_col = 2 + (size(grid_data, 2) == 5);
        grid_holds_mesh_nodes_only = strcmp(files.study_grid_variable, 'nodeID');

        %% SAVEPOINT ID MATCH (staID Grids, CHS-LA Through The Savepoint Node Map)
        id_rows = [];
        searched_name = grid_name;
        if grid_holds_mesh_nodes_only
            if ~has_coords
                error('chess:CoastalHazardSystem:noCoordinates', ['The %s study grid file %s holds mesh nodes, not savepoint IDs: ',...
                    'the savepoint SP%d latitude/longitude are needed to find its grid point.'], region, grid_name, sp_ID);
            end
        elseif files.uses_savepoint_node_map
            if files.exists.savepoint_node_map_file
                node_map = load(files.savepoint_node_map_file, 'SPs'); node_map = node_map.SPs; % [SP_ID Node Lon Lat Depth]
                adcirc_node_id = node_map(node_map(:,1) == sp_ID, 2);
                if isscalar(adcirc_node_id)
                    id_rows = find(grid_data(:,2) == adcirc_node_id);
                else
                    searched_name = file_name(files.savepoint_node_map_file);
                end
            elseif ~has_coords
                error('chess:CoastalHazardSystem:gridNotFound', 'No %s savepoint node map file (%s_ADCIRC_SPs.mat) found in %s.',...
                    region, region, files.folders.study_grid);
            end
        else
            id_rows = find(grid_data(:,1) == sp_ID);
        end

        %% ROW: UNIQUE ID MATCH, ELSE NEAREST GRID POINT
        if isscalar(id_rows)
            row = id_rows;
            method = 'id';
        elseif has_coords
            [~, row] = min(chess.Common.haversine_km(sp_coords(1), sp_coords(2), grid_data(:, lat_col), grid_data(:, lat_col + 1)));
            method = 'nearest';
        else
            error('chess:CoastalHazardSystem:spNotFound', 'Save point SP%d not found (or not unique) in the %s study grid file %s.',...
                sp_ID, region, searched_name);
        end
        loc.row = row;
        loc.lat = grid_data(row, lat_col);
        loc.lon = grid_data(row, lat_col + 1);
        loc.value = [];
        if size(grid_data, 2) >= lat_col + 2
            loc.value = grid_data(row, lat_col + 2);
        end
        loc.method = method;
        loc.distance_m = [];
        if has_coords
            loc.distance_m = 1000*chess.Common.haversine_km(sp_coords(1), sp_coords(2), loc.lat, loc.lon);
        end
        loc.grid_name = grid_name;
        end

        function storm = validate_user_storm(config, storm)
        % validate_user_storm  Check the layout of the storm variable of a user storm .mat.
        %   storm = chess.CoastalHazardSystem.validate_user_storm(config, storm)
        %
        %   Checks the storm variable of a user storm .mat (storm_data input)
        %   and returns it with only the supported fields; called by
        %   chess.Model.create and the GUI storm database wizard. Fields are kept
        %   by exact name (others are dropped, then the shapes are checked):
        %     storm      - XC, TC
        %     storm.XC   - Peaks, Timeseries, Nyrs_XC, Nstm_XC, removed_storms
        %     storm.TC   - Peaks, Timeseries, removed_storms
        %     Peaks      - Default, WLP, WHP
        %     Timeseries - Default
        %   Errors when storm has no XC or TC field
        %   (chess:CoastalHazardSystem:noStormType), a storm type has no Peaks or
        %   Timeseries field (chess:CoastalHazardSystem:noDataType), storm.XC lacks
        %   Nyrs_XC or Nstm_XC (chess:CoastalHazardSystem:missingXcRecord), a data type has
        %   no Default dataset (chess:CoastalHazardSystem:missingDefault), a dataset is not
        %   an N x 2 cell (chess:CoastalHazardSystem:datasetShape), or the data of its
        %   first storm is not 1 x 5 for Peaks (chess:CoastalHazardSystem:peaksShape) or
        %   M x 6 for Timeseries (chess:CoastalHazardSystem:timeseriesShape).
        %
        %   Expected layout: storm.(st_type).(data_type).(match_type)
        %     st_type    - 'XC' and/or 'TC'
        %     data_type  - 'Peaks' and/or 'Timeseries'
        %     match_type - storm matching of the circulation and wave models:
        %                    'Default' - peak responses of the circulation (surge)
        %                                and wave models (wave height, peak
        %                                period, wave direction) regardless of
        %                                their phase.
        %                    'WLP' - Peaks only: alternate Peaks dataset (Water
        %                            Level Priority) built from Peaks and
        %                            Timeseries, matched on the peak circulation
        %                            model response; the wave model response is
        %                            the Timeseries value nearest to that peak's
        %                            phase.
        %                    'WHP' - Peaks only: alternate Peaks dataset (Wave
        %                            Height Priority), matched on the peak wave
        %                            model response; the circulation model
        %                            response is the Timeseries value nearest to
        %                            that peak's phase.
        %                  Timeseries supports 'Default' only.
        %   Each dataset is an N x 2 cell: column 1 storm ID, column 2 storm
        %   data, 1 x 5 [SWL Hm0 Tp wDir datenum] for Peaks, M x 6 [SWL Hm0 Tp
        %   wDir datenum dt] for Timeseries. storm.XC also holds Nyrs_XC (XC
        %   record length [years]) and Nstm_XC (number of XC storms in the storm
        %   suite); chess.Model.create moves them to db_info.
        %
        %   Inputs:
        %     config - CHESS configuration, 1x1 struct; not read (kept for the
        %              call shape shared with chess.CoastalHazardSystem.validate_user_prob_mass)
        %     storm  - user storm database (layout above), struct
        %   Outputs:
        %     storm  - storm with only the supported fields above, struct
        %
        %   See also chess.CoastalHazardSystem.validate_user_prob_mass, chess.CoastalHazardSystem.storm_data_covers, chess.Model.create.

        st_types = intersect({'XC', 'TC'}, fieldnames(storm), 'stable');
        if isempty(st_types)
            error('chess:CoastalHazardSystem:noStormType', 'CHESS only supports "XC" and/or "TC" storm types. Rename fields as such.');
        end
        storm = keep_fields(storm, st_types);
        match_whitelist = struct('Peaks', {{'Default', 'WLP', 'WHP'}}, 'Timeseries', {{'Default'}});
        for kk = 1:numel(st_types)
            st = st_types{kk};
            type_fields = {'Peaks', 'Timeseries', 'removed_storms'};
            if strcmp(st, 'XC')
                type_fields = [type_fields, {'Nyrs_XC', 'Nstm_XC'}]; %#ok<AGROW>
            end
            storm.(st) = keep_fields(storm.(st), type_fields);
            data_types = intersect({'Peaks', 'Timeseries'}, fieldnames(storm.(st)), 'stable');
            if isempty(data_types)
                error('chess:CoastalHazardSystem:noDataType', 'Could not find the data types "Peaks" and/or "Timeseries" in storm.%s.', st);
            end
            if strcmp(st, 'XC') && ~all(isfield(storm.XC, {'Nyrs_XC', 'Nstm_XC'}))
                error('chess:CoastalHazardSystem:missingXcRecord', ['Could not find the XC storm record fields. Include the record length ',...
                    '(Nyrs_XC) and number of XC storms (Nstm_XC) in storm.XC.']);
            end
            for ii = 1:numel(data_types)
                dtype = data_types{ii};
                storm.(st).(dtype) = keep_fields(storm.(st).(dtype), match_whitelist.(dtype));
                if ~isfield(storm.(st).(dtype), 'Default')
                    error('chess:CoastalHazardSystem:missingDefault', 'storm.%s.%s has no Default dataset.', st, dtype);
                end
                match_types = fieldnames(storm.(st).(dtype));
                for jj = 1:numel(match_types)
                    data = storm.(st).(dtype).(match_types{jj});
                    if ~iscell(data) || size(data, 2) ~= 2
                        error('chess:CoastalHazardSystem:datasetShape', ['Wrong data shape for storm.%s.%s.%s. Use an N x 2 cell array ',...
                            '(col 1: storm ID, col 2: storm data).'], st, dtype, match_types{jj});
                    end
                    [stm_row, stm_col] = size(data{1, 2});
                    if strcmp(dtype, 'Peaks')
                        if stm_row ~= 1 || stm_col ~= 5
                            error('chess:CoastalHazardSystem:peaksShape', 'Storm data must be 1 x 5 [SWL Hm0 Tp wDir datenum] for "Peaks" (storm.%s.Peaks.%s).', st, match_types{jj});
                        end
                    elseif stm_col ~= 6
                        error('chess:CoastalHazardSystem:timeseriesShape', 'Storm data must be M x 6 [SWL Hm0 Tp wDir datenum dt] for "Timeseries" (storm.%s.Timeseries.%s).', st, match_types{jj});
                    end
                end
            end
        end
        end

        function prob_mass = validate_user_prob_mass(config, prob_mass, storm)
        % validate_user_prob_mass  Check the TC probability masses of a user storm .mat.
        %   prob_mass = chess.CoastalHazardSystem.validate_user_prob_mass(config, prob_mass, storm)
        %
        %   Checks the prob_mass variable of a user storm .mat (storm_data
        %   input) against the TC storms of storm and returns it with the missing
        %   intensity bins added and TotalFreq set to sum(TC_Freq); called by chess.Model.create and the GUI storm
        %   database wizard when the storm data has TC storms, after
        %   chess.CoastalHazardSystem.validate_user_storm. Errors when:
        %     - TC_SRR or TC_Freq is missing
        %       (chess:CoastalHazardSystem:missingField);
        %     - TC_SRR is not 1 x 4 (chess:CoastalHazardSystem:tcSrrSize);
        %     - TC_Freq is not N x 1, N = rows of every TC Default dataset of
        %       storm (chess:CoastalHazardSystem:tcFreqSize);
        %     - Param is present and its row count differs from numel(TC_Freq)
        %       (chess:CoastalHazardSystem:paramRows);
        %     - smpl1, smpl2 or smpl3 is not a column vector
        %       (chess:CoastalHazardSystem:smplShape) or holds IDs that are not TC
        %       storm IDs of storm (chess:CoastalHazardSystem:smplIds);
        %     - smpl1, smpl2 and smpl3 are all empty
        %       (chess:CoastalHazardSystem:noBinStorms).
        %   A missing smpl1, smpl2 or smpl3 is added as zeros(0,1) and an empty
        %   bin is returned as zeros(0,1). Warnings: an empty bin with a TC_SRR
        %   rate > 0 (chess:CoastalHazardSystem:emptyBin; sample_tropical_storms redraws an
        %   empty bin, so its share of the rate goes to the other bins) and the
        %   TC_SRR total differing from the sum of the three bin rates by more than
        %   a relative 1e-9 (chess:CoastalHazardSystem:srrTotalMismatch).
        %
        %   Inputs:
        %     config    - CHESS configuration, 1x1 struct; not read
        %     prob_mass - TC probability masses, struct; fields:
        %                   TC_SRR    - TC storm recurrence rates per intensity
        %                               bin [storms/yr], 1x4 double [low, mid,
        %                               high, total]; bins by central pressure
        %                               deficit dP [hPa]: low dP < 28, mid
        %                               28 <= dP < 48, high dP >= 48
        %                   TC_Freq   - TC discrete storm weights (probability
        %                               masses) [storms/yr], N x 1 double
        %                   TotalFreq - optional; ignored and set to sum(TC_Freq)
        %                               [storms/yr] (total TC storm suite frequency)
        %                   Param     - optional; TC storm parameters, one row per
        %                               storm, N x number_of_parameters double
        %                   smpl1, smpl2, smpl3 - optional; storm IDs of the low,
        %                               mid and high intensity bins (TC storm IDs
        %                               of storm), column double
        %     storm     - user storm database (chess.CoastalHazardSystem.validate_user_storm output), struct;
        %                 storm.TC.Peaks.Default and storm.TC.Timeseries.Default
        %                 are read (row counts, storm IDs)
        %   Outputs:
        %     prob_mass - prob_mass with smpl1, smpl2 and smpl3 as column vectors
        %                 (missing or empty bins as zeros(0,1)), struct
        %
        %   See also chess.CoastalHazardSystem.validate_user_storm, chess.CoastalHazardSystem.storm_data_covers, chess.Model.create,
        %   sample_tropical_storms.

        intensity_bins = {'smpl1', 'smpl2', 'smpl3'};
        required = {'TC_SRR', 'TC_Freq'};
        missing = required(~isfield(prob_mass, required));
        if ~isempty(missing)
            error('chess:CoastalHazardSystem:missingField', 'Provided "prob_mass" variable lacks the field(s) %s.', strjoin(missing, ', '));
        end
        if ~isequal(size(prob_mass.TC_SRR), [1 4])
            error('chess:CoastalHazardSystem:tcSrrSize', ['Field "prob_mass.TC_SRR" must be 1 x 4 double (yearly recurrence rate ',...
                'per intensity bin [low, mid, high, total]); found %s.'], mat2str(size(prob_mass.TC_SRR)));
        end
        tc_ids = [];
        for dtype = intersect({'Peaks', 'Timeseries'}, fieldnames(storm.TC), 'stable')
            tc_ids = cell2mat(storm.TC.(dtype{1}).Default(:, 1));
            if ~iscolumn(prob_mass.TC_Freq) || numel(prob_mass.TC_Freq) ~= numel(tc_ids)
                error('chess:CoastalHazardSystem:tcFreqSize', ['Field "prob_mass.TC_Freq" must be N x 1 with N = %d TC storms ',...
                    '(storm.TC.%s.Default); found %s.'], numel(tc_ids), dtype{1}, mat2str(size(prob_mass.TC_Freq)));
            end
        end
        prob_mass.TotalFreq = sum(prob_mass.TC_Freq);
        if isfield(prob_mass, 'Param') && size(prob_mass.Param, 1) ~= numel(prob_mass.TC_Freq)
            error('chess:CoastalHazardSystem:paramRows', 'Field "prob_mass.Param" has %d rows; expected one per TC storm (%d).',...
                size(prob_mass.Param, 1), numel(prob_mass.TC_Freq));
        end
        for bb = 1:numel(intensity_bins)
            bin = intensity_bins{bb};
            if ~isfield(prob_mass, bin) || isempty(prob_mass.(bin))
                prob_mass.(bin) = zeros(0, 1);
                if prob_mass.TC_SRR(bb) > 0
                    warning('chess:CoastalHazardSystem:emptyBin', ['Intensity bin "%s" has no storms but a TC_SRR rate of %g storms/yr; ',...
                        'the sampler moves that share to the other bins.'], bin, prob_mass.TC_SRR(bb));
                end
            elseif ~iscolumn(prob_mass.(bin))
                error('chess:CoastalHazardSystem:smplShape', 'Field "prob_mass.%s" must be a column vector of TC storm IDs.', bin);
            elseif ~all(ismember(prob_mass.(bin), tc_ids))
                error('chess:CoastalHazardSystem:smplIds', 'Field "prob_mass.%s" holds IDs that are not TC storm IDs of the storm data.', bin);
            end
        end
        if all(cellfun(@(bin) isempty(prob_mass.(bin)), intensity_bins))
            error('chess:CoastalHazardSystem:noBinStorms', 'No storm IDs assigned to the intensity bins (smpl1, smpl2, smpl3).');
        end
        if ~totals_match(sum(prob_mass.TC_SRR(1:3)), prob_mass.TC_SRR(4))
            warning('chess:CoastalHazardSystem:srrTotalMismatch', 'Provided total SRR does not match sum(SRR_low, SRR_mid, SRR_high).');
        end
        end

        function [storm, prob_mass, db_info] = build_storm_database(CHS_Data, options)
        % chess.CoastalHazardSystem.build_storm_database  Build the storm database (storm, prob_mass, db_info).
        %   [storm, prob_mass, db_info] = chess.CoastalHazardSystem.build_storm_database(CHS_Data, options)
        %
        %   Builds the storm database from converted CHS files. The one builder
        %   of the library (chess.Model.prepare_storm_database) and the GUI storm database
        %   wizard (CHSStormDBImportUI.create_storm_database), so both give the
        %   same database from the same input. Steps, TC first:
        %       1. TC probability masses (chess.CoastalHazardSystem.load_probability_masses).
        %       2. Per storm type: format, match and screen the CHS files
        %          (chess.CoastalHazardSystem.quality_check; TC SWL bias correction with the
        %          database bias when the region's bias & uncertainty files
        %          exist).
        %       3. Per storm type with Peaks and Timeseries: hydrograph peaks
        %          replaced by the Peaks file values (chess.CoastalHazardSystem.replace_timeseries_peaks).
        %       4. Storm ID alignment: every dataset of a storm type holds the
        %          same storm IDs in the same order, and for TC so do
        %          prob_mass.Param(:,1) and TC_Freq (when the probability masses
        %          were loaded); error chess:CoastalHazardSystem:stormIdMismatch.
        %       5. Forcing curation of every dataset (Peaks, Timeseries, WLP,
        %          WHP; chess.CoastalHazardSystem.curate_storm_forcing).
        %       6. db_info (chess.CoastalHazardSystem.create_db_info 'create').
        %   Data types and WLP/WHP datasets are decided per storm type from the
        %   storm file slots (chess.CoastalHazardSystem.storm_file_slots): Peaks / Timeseries when that
        %   storm type's slot is complete; WLP / WHP when requested and that
        %   storm type has both Peaks and Timeseries. Bias & uncertainty
        %   (CHS_Dependencies or manual), the CHS_Dependencies availability
        %   decision (which storm types to build), the forcing cache reset, the
        %   datum adjustment and the saves stay with the callers.
        %
        %   Inputs:
        %     CHS_Data - converted CHS files (Filename, Conv_Data; folders in
        %                Filename are dropped before the file selection),
        %                1 x number_of_files struct
        %     options  - build settings, struct; fields (all required):
        %                  .chs_dependencies - CHS_Dependencies folder, char
        %                  .region           - CHS region (e.g. 'CHS-NA'), char
        %                  .sp_ID            - ADCIRC savepoint ID, scalar double
        %                  .storm_types      - storm types to build ('TC' and/or
        %                                      'XC'), cell
        %                  .storm_file_slots - storm file slots of the input
        %                                      (chess.CoastalHazardSystem.storm_file_slots slots
        %                                      output), table
        %                  .create_wlp       - build the Water Level Priority
        %                                      dataset (0/1), scalar double
        %                  .create_whp       - build the Wave Height Priority
        %                                      dataset (0/1), scalar double
        %                  .bias_uncertainty - bias & uncertainty and savepoint
        %                                      location of the database
        %                                      (chess.CoastalHazardSystem.bias_and_uncertainty output),
        %                                      struct; chs_swl_b_a/_b_r drive the
        %                                      TC bias correction, sp_lat/sp_lon
        %                                      locate the savepoint for the TC
        %                                      probability masses
        %                  .source_file      - input the database is built from
        %                                      (name + extension), char
        %                  .print_progress   - print progress to the command
        %                                      window (0/1), scalar double
        %                  .progress_fcn     - called before each step as
        %                                      progress_fcn(fraction, message),
        %                                      fraction in [0 1) ([]: none); an
        %                                      error raised there stops the build
        %                                      (GUI cancel: chess:GUI:CHSStormDBImportUI:importCancelled),
        %                                      function_handle
        %   Outputs:
        %     storm     - storm database (storm.TC / storm.XC: Peaks, Timeseries,
        %                 removed_storms; chess.CoastalHazardSystem.format_peaks row layout), struct
        %     prob_mass - TC probability masses (Param, TC_SRR, TC_Freq,
        %                 TotalFreq, smpl1, smpl2, smpl3; [] without TC), struct
        %     db_info   - storm database details (chess.CoastalHazardSystem.create_db_info), struct
        %
        %   See also chess.Model.prepare_storm_database, chess.CoastalHazardSystem.create_db_info,
        %   chess.CoastalHazardSystem.bias_and_uncertainty, chess.CoastalHazardSystem.storm_file_slots, chess.CoastalHazardSystem.convert_zip.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
        CHS_Data = chess.CoastalHazardSystem.strip_data_folders(CHS_Data);
        storm_types = reshape(intersect({'TC', 'XC'}, options.storm_types, 'stable'), 1, []);
        slots = options.storm_file_slots;
        slot_complete = @(storm_type, data_type) any(slots.complete & strcmp(slots.storm_type, storm_type) & strcmp(slots.data_type, data_type));
        % Quality Check Settings (quality_check Reads Only These Fields)
        quality_check_config = struct('region', options.region, 'sp_ID', options.sp_ID,...
            'chs_dependencies', options.chs_dependencies, 'print_progress', options.print_progress,...
            'chs_swl_b_a', options.bias_uncertainty.chs_swl_b_a, 'chs_swl_b_r', options.bias_uncertainty.chs_swl_b_r);
        storm = struct();
        prob_mass = [];
        tc_bias_corrected = 0;
        Nyrs_XC = [];
        Nstm_XC = [];
        has_peaks_and_timeseries = false(size(storm_types));

        %% FORMAT AND INSPECT CHS STORMS (TC First: Probability Masses), Data Types Per Storm Type
        for tt = 1:numel(storm_types)
            storm_type = storm_types{tt};
            has_peaks = slot_complete(storm_type, 'Peaks');
            has_timeseries = slot_complete(storm_type, 'Timeseries');
            has_peaks_and_timeseries(tt) = has_peaks && has_timeseries;
            quality_check_config.use_peaks = +has_peaks;
            quality_check_config.use_timeseries = +has_timeseries;
            quality_check_config.create_wlp = +(has_peaks_and_timeseries(tt) && options.create_wlp == 1);
            quality_check_config.create_whp = +(has_peaks_and_timeseries(tt) && options.create_whp == 1);
            switch storm_type
                case 'TC'
                    report_progress(options, 1/9, 'Setting-up TC modeling suite regional statistics');
                    [prob_mass.Param, prob_mass.TC_SRR,...
                        prob_mass.TC_Freq, prob_mass.TotalFreq,...
                        prob_mass.smpl1, prob_mass.smpl2, prob_mass.smpl3] = chess.CoastalHazardSystem.load_probability_masses(options.chs_dependencies, options.region, options.sp_ID,...
                        [options.bias_uncertainty.sp_lat options.bias_uncertainty.sp_lon]);
                    report_progress(options, 2/9, 'Matching TC modeling results (surge+waves)');
                    [tc_checked_config, storm.('TC'), storm.('TC').removed_storms,...
                        ~, ~, prob_mass] = chess.CoastalHazardSystem.quality_check(quality_check_config, CHS_Data, prob_mass, 'TC');
                    tc_bias_corrected = tc_checked_config.tc_bias_corrected;
                case 'XC'
                    report_progress(options, 4/9, 'Matching XC modeling results (surge+waves)');
                    [~, storm.('XC'), storm.('XC').removed_storms,...
                        Nyrs_XC, Nstm_XC, ~] = chess.CoastalHazardSystem.quality_check(quality_check_config, CHS_Data, [], 'XC');
            end
        end

        %% TIMESERIES PEAK REPLACER: Replace Hydrograph Peak Responses With Peaks Files Responses
        if any(has_peaks_and_timeseries)
            report_progress(options, 7/9, 'Adjusting hydrographs peak responses');
            for storm_type = storm_types(has_peaks_and_timeseries)
                storm.(storm_type{1}) = chess.CoastalHazardSystem.replace_timeseries_peaks(storm.(storm_type{1}));
            end
        end

        %% STORM ID ALIGNMENT: Every Dataset Of A Storm Type (And The TC Probability Masses) Holds The Same Storms In The Same Order
        check_storm_id_alignment(storm, prob_mass);

        %% FORCING CURATION OF EVERY DATASET (Peaks, Timeseries, WLP, WHP)
        storm = curate_storm_database(storm);

        %% STORM DATABASE DETAILS (Bias & Uncertainty, TC Bias Correction, XC Record)
        db_info = chess.CoastalHazardSystem.create_db_info(options.bias_uncertainty, tc_bias_corrected, Nyrs_XC, Nstm_XC, options.source_file);
        db_info.datasets = chess.CoastalHazardSystem.summarize_datasets(storm, prob_mass);
        end
    end

    methods (Static, Access = ?matlab.unittest.TestCase) % Internal Steps: Private To The Class, Open To Unit Tests
        function  [Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2, smpl3] = load_probability_masses(chs_dependencies_path, region, Nsvpt, sp_coords)
        % load_probability_masses  Load the TC probability masses of a savepoint.
        %   [Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2, smpl3] =
        %       chess.CoastalHazardSystem.load_probability_masses(chs_dependencies_path, region, Nsvpt,
        %       sp_coords)
        %
        %   Loads the CHS TC storm probability masses of the region's
        %   CHS_Dependencies files (chess.CoastalHazardSystem.dependency_files), needed by every TC
        %   storm sampling. The savepoint's study grid point (chess.CoastalHazardSystem.savepoint_grid_row:
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
        %   See also chess.CoastalHazardSystem.build_storm_database, chess.CoastalHazardSystem.dependency_files,
        %   chess.CoastalHazardSystem.savepoint_grid_row, chess.CoastalHazardSystem.validate_user_prob_mass.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        %% CHS_DEPENDENCIES FILES (chess.CoastalHazardSystem.dependency_files)
        files = chess.CoastalHazardSystem.dependency_files(chs_dependencies_path, region);

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
            loc = chess.CoastalHazardSystem.savepoint_grid_row(files, Nsvpt, sp_coords);
            % Find CRL closest to savepoint
            [~, ic] = min(chess.Common.haversine_km(loc.lat, loc.lon, CRL(:,1), CRL(:,2)));
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
            dist200=find(chess.Common.haversine_km(loc.lat, loc.lon, trk_lat, trk_lon)<=trk_dist);
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

        function [config, storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass] = quality_check(config, CHS_Data, prob_mass, storm_type)
        % quality_check  Format, match and screen CHS storm files.
        %   [config, storm, removed_storms, XC_Nyrs, XC_Nstm, prob_mass] =
        %       chess.CoastalHazardSystem.quality_check(config, CHS_Data, prob_mass, storm_type)
        %
        %   Builds the storm datasets of one storm type from converted CHS files;
        %   chess.CoastalHazardSystem.build_storm_database calls it per storm type, TC first. Peaks: the
        %   ADCIRC and wave model Peaks files are matched per storm ID
        %   (chess.CoastalHazardSystem.format_peaks, Peaks.Default). Timeseries: the ADCIRC and wave
        %   model Timeseries are matched on an hourly time step
        %   (chess.CoastalHazardSystem.format_timeseries, Timeseries.Default). With both data types,
        %   the Water Level Priority / Wave Height Priority Peaks datasets are
        %   built when requested (chess.CoastalHazardSystem.priority_dataset, Peaks.WLP /
        %   Peaks.WHP). The wave model columns come from
        %   chess.CoastalHazardSystem.wave_model_columns.
        %   Timeseries wave flags: before the Timeseries and WLP datasets are
        %   built, flagged raw wave steps are filled (chess.CoastalHazardSystem.fill_flagged_wave_steps:
        %   Hm0 NaN/<= 0 -> 0.01 m, Tp NaN/<= 0 -> nearest valid Tp of the storm)
        %   so the step is kept.
        %   Screening: storms with NaN or flagged Peaks values, a one-value water
        %   level Timeseries, no valid Tp step, no common ADCIRC/wave time range,
        %   an interior gap of dropped Timeseries steps (chess.CoastalHazardSystem.format_timeseries)
        %   or no WLP/WHP match (chess.CoastalHazardSystem.priority_dataset) are listed in
        %   removed_storms.Default and every dataset (Peaks Default / WLP / WHP,
        %   Timeseries Default) drops them by its own storm IDs. TC: the removed
        %   storms also leave prob_mass (Param and TC_Freq rows by the storm ID
        %   in Param column 1; smpl1, smpl2, smpl3; TC_Freq rescaled to
        %   TotalFreq), and the SWL is
        %   bias corrected when the region's bias & uncertainty files exist
        %   (chess.CoastalHazardSystem.dependency_files bias_uncertainty_available). XC: never bias
        %   corrected; XC_Nstm and XC_Nyrs come from the ADCIRC Peaks file (else
        %   from the ADCIRC Timeseries file).
        %
        %   Inputs:
        %     config     - quality check settings (chess.CoastalHazardSystem.build_storm_database), 1x1
        %                  struct; fields:
        %                    use_peaks        - storm type has complete Peaks
        %                                       files (0/1), double
        %                    use_timeseries   - storm type has complete
        %                                       Timeseries files (0/1), double
        %                    create_wlp       - build the WLP dataset (0/1), double
        %                    create_whp       - build the WHP dataset (0/1), double
        %                    region           - CHS region, char
        %                    sp_ID            - ADCIRC savepoint ID, double
        %                    chs_dependencies - CHS_Dependencies folder, char
        %                    chs_swl_b_a      - SWL bias, absolute [m], double
        %                    chs_swl_b_r      - SWL bias, relative [-], double
        %                    print_progress   - print progress (0/1), double
        %     CHS_Data   - converted CHS files (Filename, Conv_Data),
        %                  1 x number_of_files struct
        %     prob_mass  - TC probability masses (chess.CoastalHazardSystem.load_probability_masses:
        %                  Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2,
        %                  smpl3), struct; not read for XC
        %     storm_type - storm type, 'TC' or 'XC', char
        %   Outputs:
        %     config         - input config; TC adds tc_bias_corrected (1 if the
        %                      SWL bias correction was applied, else 0), struct
        %     storm          - storm datasets of the storm type (Peaks.Default,
        %                      Peaks.WLP, Peaks.WHP, Timeseries.Default; rows
        %                      {storm ID, data}), struct
        %     removed_storms - IDs of the removed storms (field Default), struct
        %     XC_Nyrs        - XC record length [years] ([] for TC), double
        %     XC_Nstm        - XC storm count, before screening ([] for TC),
        %                      double
        %     prob_mass      - TC probability masses without the removed storms
        %                      ([] for XC), struct
        %
        %   See also chess.CoastalHazardSystem.build_storm_database, chess.CoastalHazardSystem.format_peaks,
        %   chess.CoastalHazardSystem.format_timeseries, chess.CoastalHazardSystem.priority_dataset, chess.CoastalHazardSystem.fill_flagged_wave_steps,
        %   chess.CoastalHazardSystem.wave_model_columns, chess.CoastalHazardSystem.load_probability_masses.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        %% GRAB INFORMATION FROM "config"
        use_timeseries = config.use_timeseries;
        use_peaks = config.use_peaks;
        WLP_switch = config.create_wlp;
        WHP_switch = config.create_whp;
        % CHS Region
        chs_region = config.region;
        % Save Point ID
        spID = config.sp_ID;
        %
        disp_on = config.print_progress;

        %% DEFINE AUX VARIABLES
        % No Probability Masses For Extratropical Storms
        if strcmp(storm_type, 'XC')
            prob_mass = [];
        end

        %% PROCESS CHS PEAKS DATASET TO CREATE "storm.Peaks"
        if use_peaks == 1
            % Display Progress Step
            if strcmp(storm_type,'XC')
                chess.Common.disp_toggle(disp_on,['Matching CHS extratropical peak waves and water levels....']);
            else
                chess.Common.disp_toggle(disp_on,['Matching CHS tropical peak waves and water levels....']);
            end
            % Pull Storm Data From Parsed H5 Files
            [peaks_data, adcirc_bool,  STWAVE_headers_location, Tp_special] = chs_file_selection(CHS_Data, 'Peaks', storm_type);
            % Format storm Data
            [storm.('Peaks').Default, storm2rm] = chess.CoastalHazardSystem.format_peaks(peaks_data{adcirc_bool},...
                peaks_data{~adcirc_bool}, STWAVE_headers_location, Tp_special); % storm2rm is a storm ID
        else
            storm2rm = [];
        end

        %% PROCESS CHS TIMESERIES DATASET TO CREATE "storm.Timeseries" & PRIORITY DATASETS ("storm.Peaks.WLP" and/or "storm.Peaks.WHP")
        if use_timeseries == 1
            % Display Progress Step
            if strcmp(storm_type,'XC')
                chess.Common.disp_toggle(disp_on,['Matching CHS extratropical timeseries waves and water levels....']);
            else
                chess.Common.disp_toggle(disp_on,['Matching CHS tropical timeseries waves and water levels....']);
            end
            % Pull Storm Data From Parsed H5 Files
            [timeseries_data, adcirc_bool_ts,  STWAVE_headers_location_ts, Tp_special_ts] = chs_file_selection(CHS_Data, 'Timeseries', storm_type);
            % Fill Flagged Raw Wave Steps Before Any Interpolation (Timeseries.Default And WLP); No Valid Tp: Bad Storm
            [timeseries_data{~adcirc_bool_ts}, no_tp_storms] = chess.CoastalHazardSystem.fill_flagged_wave_steps(timeseries_data{~adcirc_bool_ts}, STWAVE_headers_location_ts);
            storm2rm = unique([storm2rm(:); no_tp_storms]);
            % Create ADCIRC-STWAVE TimeSeries Dataset
            [storm.Timeseries.Default, storm2rm] = chess.CoastalHazardSystem.format_timeseries(timeseries_data{adcirc_bool_ts},...
                timeseries_data{~adcirc_bool_ts},...
                storm2rm, STWAVE_headers_location_ts, Tp_special_ts, disp_on);
            % Create Alternate Datasets
            if use_peaks == 1
                % Create Water Level Priority
                if WLP_switch == 1
                    [storm.('Peaks').WLP, wlp_storm2rm] = chess.CoastalHazardSystem.priority_dataset(peaks_data{adcirc_bool},...
                        timeseries_data{adcirc_bool_ts}, timeseries_data{~adcirc_bool_ts},...
                        storm2rm, STWAVE_headers_location_ts, Tp_special_ts, 'wlp', disp_on);
                    storm2rm = unique([storm2rm; wlp_storm2rm(:)]);
                end
                % Create Wave Height Priority
                if WHP_switch == 1
                    [storm.('Peaks').WHP, whp_storm2rm] = chess.CoastalHazardSystem.priority_dataset(peaks_data{~adcirc_bool}, ...
                        timeseries_data{adcirc_bool_ts}, timeseries_data{~adcirc_bool_ts},...
                        storm2rm, STWAVE_headers_location, Tp_special, 'whp', disp_on);
                    storm2rm = unique([storm2rm; whp_storm2rm(:)]);
                end
            end
        end
        % Store Invalid Storms
        removed_storms.Default = storm2rm;

        %% REMOVE FLAGED STORMS
        % Each Dataset (Peaks Default/WLP/WHP, Timeseries Default) Drops The Removed Storms By Its Own Storm IDs
        for dtype = reshape(fieldnames(storm), 1, [])
            for mtype = reshape(fieldnames(storm.(dtype{1})), 1, [])
                rm_bool = ismember(cell2mat(storm.(dtype{1}).(mtype{1})(:, 1)), removed_storms.Default);
                storm.(dtype{1}).(mtype{1})(rm_bool, :) = [];
            end
        end

        %% ADJUST STORM DEPENDANT PARAMETERS
        % Adjust storm Type Dependant Fields
        switch storm_type
            case 'TC'% Tropical Cyclones
                if isempty(prob_mass.TC_Freq)
                    % Something Went Wrong In PM Load
                    warning('chess:CoastalHazardSystem:emptyProbabilityMass', 'The TC probability masses loaded from CHS_Dependencies are empty (prob_mass.TC_Freq).');
                else
                    % Probability Mass Rows By Storm ID (Param Column 1)
                    pm_rm = ismember(prob_mass.Param(:, 1), removed_storms.Default);
                    prob_mass.TC_Freq(pm_rm, :) = [];
                    % Redifine New Frequency Vector
                    if ~isempty(storm2rm)
                        prob_mass.TC_Freq = prob_mass.TC_Freq*prob_mass.TotalFreq/sum(prob_mass.TC_Freq);
                    end
                    prob_mass.Param(pm_rm, :) = [];
                    %
                    prob_mass.smpl1(ismember(prob_mass.smpl1,removed_storms.Default)) = [];
                    prob_mass.smpl2(ismember(prob_mass.smpl2,removed_storms.Default)) = [];
                    prob_mass.smpl3(ismember(prob_mass.smpl3,removed_storms.Default)) = [];
                end
                % Define Empty Var For Outputs
                XC_Nyrs = [];XC_Nstm = [];
            case 'XC' % Extratropical storms
                if use_peaks == 1
                    % Determine Number Of Events
                    XC_Nstm = height(peaks_data{adcirc_bool==1});
                    % Get Timestamp Vector
                    tVector = peaks_data{adcirc_bool==1}.yyyymmddHHMM;
                    % Check For NaTs
                    hIndx = ~isnat(tVector);
                    % Get Event Record Years
                    record_years = year(tVector(hIndx));
                    % Compute Number Of Years
                    XC_Nyrs=max(record_years)-min(record_years)+1;
                else
                    % Determine Number Of Events
                    XC_Nstm = height(timeseries_data{adcirc_bool_ts==1});
                    % Get Timestamp Vector
                    tVector = timeseries_data{adcirc_bool_ts==1}.yyyymmddHHMM;
                    % Check For NaTs
                    hIndx = cellfun(@(x) ~isnat(x), tVector, 'un', false);
                    % Get Event Record Years
                    for kk = 1:length(hIndx)
                        if any(hIndx{kk})
                            record_years{kk} = year(tVector{kk}(hIndx{kk}));
                        else
                            record_years{kk} = NaN;
                        end
                    end
                    % Compute Number Of Years
                    XC_Nyrs = max(cellfun(@max, record_years), [], "omitnan") - min(cellfun(@min, record_years), [], "omitnan")+1;
                end
        end

        %% APPLY BIAS CORRECTION
        % Applied When The Region's Water Level And Wave Height Bias & Uncertainty Files Exist (chess.CoastalHazardSystem.dependency_files)
        chs_files = chess.CoastalHazardSystem.dependency_files(config.chs_dependencies, chs_region);
        bias_tgr = double(chs_files.bias_uncertainty_available);
        % Enforce No Bias Correction For XCs
        if strcmp(storm_type, 'XC')
            bias_tgr = 0;
        end
        % Record TC Bias Correction State (Plots Apply The Same Correction To Raw CHS SWL)
        if strcmp(storm_type, 'TC')
            config.tc_bias_corrected = bias_tgr;
        end
        % Apply Bias Correction (If Applicable)
        if bias_tgr == 1
            % Determine Structure Fields
            sNames = fieldnames(storm);
            % Define Function
            f_u = @(x) chess.CoastalHazardSystem.swl_bias_correction(x, config.chs_swl_b_a, config.chs_swl_b_r); % Bias Correction Formula
            % Adjust SWL Bias
            for ii = 1:length(sNames) % Data Types: Peaks, Timeseries
                % Get Level_2 Fieldnames
                level_2 = fieldnames(storm.(sNames{ii}));
                % Apply Bias Correction
                for kk = 1:length(level_2) % Match Type: Default, WLP, WHP
                    for ss = 1:length(storm.(sNames{ii}).(level_2{kk})) % Number Of Storms
                        storm.(sNames{ii}).(level_2{kk}){ss, 2}(:, 1) = f_u(storm.(sNames{ii}).(level_2{kk}){ss, 2}(:, 1)); % Apply Bias Correction To SSL (Surge)
                    end
                end
            end
        end

        %% AUX FUNCTION
            function [storm_data, ad_indx, STWAVE_headers_location, Tp_special] = chs_file_selection(CHS_Data, data_type, selected_storm_type)
                % Pull CHS Parsed H5 Files Accordin To Data Type & Storm Type (CHS File Name Rule: chess.CoastalHazardSystem.file_name_parts)
                file_parts = chess.CoastalHazardSystem.file_name_parts({CHS_Data.Filename});
                file_indx = strcmp({file_parts.data_type}, data_type) &...
                    strcmp({file_parts.storm_type}, selected_storm_type);
                % Extract Peaks Files
                storm_data = CHS_Data(file_indx);
                % Find ADCIRC Filename
                ad_indx = logical([file_parts(file_indx).is_adcirc]);
                % Get Headers For Hm0,Tp,wDir
                [STWAVE_headers_location, Tp_special] = chess.CoastalHazardSystem.wave_model_columns(storm_data(~ad_indx));
                % Extract "Strom_Table" Field
                storm_data = cellfun(@(x) x.Table_StormData, {CHS_Data(file_indx).Conv_Data}, 'un', false)';
            end
        end

        function [Storm, storm2rm] = format_peaks(swl_peaks_table, hm0_peaks_table, STWAVE_headers_location, Tp_special)
        % format_peaks  Match ADCIRC and wave model Peaks per storm.
        %   [Storm, storm2rm] = chess.CoastalHazardSystem.format_peaks(swl_peaks_table,
        %       hm0_peaks_table, STWAVE_headers_location, Tp_special)
        %
        %   Builds the Peaks.Default dataset of one storm type from the converted
        %   CHS Peaks tables (chess.CoastalHazardSystem.convert_h5). Both tables are sorted by
        %   numeric Storm ID and paired by row; they must hold the same storm IDs
        %   (error chess:CoastalHazardSystem:adcircWaveIdMismatch). A flagged SWL (< -90) becomes NaN; a flagged
        %   wave value (Hm0, Tp or wave dir < -90 or 0) makes Hm0, Tp and wave dir
        %   NaN. The storms with a NaN SWL, Hm0, Tp or wave dir are listed in
        %   storm2rm (kept in Storm). A missing peak time gives a NaN
        %   peak_datenum. Tp_special = 1 gives Tp = 1.2 * Tm.
        %
        %   Inputs:
        %     swl_peaks_table         - converted ADCIRC (water level) Peaks table
        %                               (Storm ID, yyyymmddHHMM, Water
        %                               Elevation), table
        %     hm0_peaks_table         - converted wave model (STWAVE, SWAN or WAM)
        %                               Peaks table (Storm ID and the columns
        %                               named in STWAVE_headers_location), table
        %     STWAVE_headers_location - wave model column names (fields Hm0, Tp,
        %                               wDir; chess.CoastalHazardSystem.wave_model_columns),
        %                               struct
        %     Tp_special              - 1 when the wave file gives the mean period
        %                               Tm instead of Tp, else 0, double
        %   Outputs:
        %     Storm    - Peaks dataset, number_of_storms x 2 cell {storm ID, 1x5
        %                [SWL Hm0 Tp wave_dir peak_datenum]}
        %     storm2rm - IDs of the storms with NaN values, column double
        %
        %   See also chess.CoastalHazardSystem.quality_check, chess.CoastalHazardSystem.wave_model_columns,
        %   chess.CoastalHazardSystem.format_timeseries, chess.CoastalHazardSystem.convert_h5.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        %% INITIALIZE VARIABLES
        % Initialize Storm Matrix
        Storm = zeros(height(swl_peaks_table),5);

        %% STORM SURGE (ADCIRC) 
        % Sort By Numeric Storm ID; Both Tables Must Hold The Same Storms (Paired By Row)
        [swl_peaks_table, hm0_peaks_table] = chess.CoastalHazardSystem.sort_tables_by_storm_id(swl_peaks_table, hm0_peaks_table);
        % Extract Storm ID From ADCIRC Table
        stm_id = num2cell(str2double(swl_peaks_table.("Storm ID")));
        % Extract Water Level From ADyCIRC Table
        Storm(:,1) = swl_peaks_table.("Water Elevation");
        % Assign NaN's If Needed
        Storm(Storm(:,1)<chess.CoastalHazardSystem.FLAG_BELOW,1) = NaN(1,1);

        %% WAVES (STWAVE, SWAN, WAM)
        %%%%%% Hm0 %%%%%%%
        % Extract Hm0 Peak Values From Data Table
        Storm(:,2) = hm0_peaks_table.(STWAVE_headers_location.Hm0);
        %%%%%% Tp %%%%%%
        % Extract Peak Period From STWAVE Tabley
        Storm(:,3) = hm0_peaks_table.(STWAVE_headers_location.Tp);
        % Convert From Tm to Tp (Special Case)
        if Tp_special == 1
            % Convert Tm to Tp (Lake Ontario Case)
            Storm(:,3) = chess.BoundaryConditions.waves.period_from_peak(Storm(:,3), 'peak_from_mean');  % Remove This For Release, Need to inform user
        end
        %%%%%% Wave Direction %%%%%%
        % Extract Wave Direction From STWAVE Table
        Storm(:,4) = hm0_peaks_table.(STWAVE_headers_location.wDir);
        % Assign NaN's If Needed
        Storm(sum(Storm(:,2:4)<chess.CoastalHazardSystem.FLAG_BELOW,2)>=1,2:4) = NaN(1,1);
        Storm(sum(Storm(:,2:4)==0,2)>=1,2:4) = NaN(1,1);
        % Check For NaT
        nan_rows = isnat(swl_peaks_table.("yyyymmddHHMM"));
        % Assign NaN
        Storm(nan_rows,5) = NaN;
        Storm(~nan_rows,5) = datenum(swl_peaks_table.("yyyymmddHHMM")(~nan_rows));
        % Find NaN's In "Default" Dataset
        storm2rm = cell2mat(stm_id(unique([find(isnan(Storm(:,1)));find(isnan(Storm(:,2)));...
            find(isnan(Storm(:,3)));find(isnan(Storm(:,4)))])));
        % Append Data
        Storm = [stm_id, num2cell(Storm, 2)];
        end

        function [storm_data, ts_storm2rm] = format_timeseries(swl_timeseries, hm0_timeseries, storms2rm,...
            STWAVE_headers_location, Tp_special, print_progress)
        % format_timeseries  Match ADCIRC and wave model Timeseries per storm.
        %   [storm_data, ts_storm2rm] = chess.CoastalHazardSystem.format_timeseries(swl_timeseries,
        %       hm0_timeseries, storms2rm, STWAVE_headers_location, Tp_special,
        %       print_progress)
        %
        %   Builds the Timeseries.Default dataset of one storm type. Both tables
        %   are sorted by numeric Storm ID and paired by row; they must hold the
        %   same storm IDs (error chess:CoastalHazardSystem:adcircWaveIdMismatch). For
        %   each storm the ADCIRC
        %   water level is kept within the wave model time range, then both are
        %   linearly interpolated to an hourly time step over their common time
        %   range. A raw peak (SWL, Hm0, Tp, wave dir) missed by the interpolation
        %   is written at the hourly time step nearest its time, so each
        %   hydrograph keeps its raw peak. The raw wave records are expected with
        %   their flagged steps already filled (chess.CoastalHazardSystem.quality_check:
        %   chess.CoastalHazardSystem.fill_flagged_wave_steps). Rows with flagged values (SWL < -90; Hm0
        %   or Tp < -400, a safety net) or NaN SWL, Hm0 or Tp are dropped: at the
        %   start or end of the record they are trimmed, any other dropped row
        %   (an interior gap) makes the storm bad. The wave direction never drops
        %   a row. Tp_special = 1 gives Tp = 1.2 *
        %   Tm. A storm in storms2rm or with a single water level value gets NaN
        %   data, a storm with an interior gap or no rows left gets empty data;
        %   all are added to ts_storm2rm.
        %
        %   Inputs:
        %     swl_timeseries          - converted ADCIRC Timeseries table
        %                               (Table_StormData: Storm ID, yyyymmddHHMM,
        %                               Water Elevation; one row per storm, cells
        %                               hold the series), table
        %     hm0_timeseries          - converted wave model Timeseries table
        %                               (Storm ID, yyyymmddHHMM and the columns
        %                               named in STWAVE_headers_location), table
        %     storms2rm               - IDs of storms already removed (Peaks
        %                               screening; [] without Peaks), double
        %     STWAVE_headers_location - wave model column names (fields Hm0, Tp,
        %                               wDir; chess.CoastalHazardSystem.wave_model_columns),
        %                               struct
        %     Tp_special              - 1 when the wave file gives the mean period
        %                               Tm instead of Tp, else 0, double
        %     print_progress          - print the completion percentage (0/1),
        %                               double
        %   Outputs:
        %     storm_data  - Timeseries dataset, number_of_storms x 2 cell
        %                   {storm ID, M x 6 [SWL Hm0 Tp wave_dir datenum dt]};
        %                   dt is the time step (1 hour) as a datenum span [days]
        %     ts_storm2rm - unique IDs of storms2rm and of the storms removed
        %                   here, column double
        %
        %   See also chess.CoastalHazardSystem.quality_check, chess.CoastalHazardSystem.wave_model_columns,
        %   chess.CoastalHazardSystem.replace_timeseries_peaks, chess.CoastalHazardSystem.format_peaks.

        %% DEFINE INPUTS AND PRE-ALLOCATE
        if print_progress
            fprintf(1,'   Completion Progress:  0%%\n');
        end

        % Sort By Numeric Storm ID; Both Tables Must Hold The Same Storms (Paired By Row)
        [swl_timeseries, hm0_timeseries] = chess.CoastalHazardSystem.sort_tables_by_storm_id(swl_timeseries, hm0_timeseries);

        % Extract Storm IDs quickly as a numeric matrix
        stmID_vec = cellfun(@str2double, swl_timeseries.('Storm ID'));
        num_storms = length(stmID_vec);

        % Initialize Storage Cell Matrix 
        storm_data = [num2cell(stmID_vec), cell(num_storms, 1)];

        % Pre-allocate space for bad storms to prevent dynamic array resizing
        bad_storms_buffer = nan(num_storms, 1);
        bad_count = 0;

        %% PROACTIVE VECTORIZED DATETIME PARSING (MASSIVE SPEEDUP)
        % Determine date formats and convert entire columns outside the loop
        dformat = 'yyyyMMddHHmmss';
        % yyyymmddHHMM columns are already datetime — pass through directly
        all_ad_dtime = swl_timeseries.("yyyymmddHHMM");
        all_wv_dtime = hm0_timeseries.("yyyymmddHHMM");
        dt_final = hours(chess.CoastalHazardSystem.TIMESERIES_STEP_HOURS);
        dt_final_datenum = datenum(dt_final);

        %% ADCIRC-STWAVE TIMESERIES MATCHING PROCESS
        for stm = 1:num_storms
            % Print Status
            if print_progress % Only print every 10 iterations to minimize I/O overhead
                fprintf(1,'\b\b\b\b%3.0f%%',(100*(stm/num_storms)));
                drawnow;
            end
    
            current_stmID = stmID_vec(stm);
    
            % Skip Bad Storm
            if ismember(current_stmID, storms2rm) || length(swl_timeseries.("Water Elevation"){stm,1}) == 1
                storm_data{stm, 2} = nan(1,1);
                bad_count = bad_count + 1;
                bad_storms_buffer(bad_count) = current_stmID;
                continue;
            end
    
            %% EXTRACT STORM DATA (Direct Indexing via 'stm' replaces 'pull_indx')
            WL = swl_timeseries.("Water Elevation"){stm, 1};
    
            waves = [hm0_timeseries.(STWAVE_headers_location.Hm0){stm, 1},...
                     hm0_timeseries.(STWAVE_headers_location.Tp){stm, 1},...
                     hm0_timeseries.(STWAVE_headers_location.wDir){stm, 1}];
         
            wv_dtime = all_wv_dtime{stm};
            ad_dtime = all_ad_dtime{stm};
    
            % Lake Ontario Special Case: Wave Model Provides Tm, Convert To Tp (waves = [Hm0, Tp, wDir])
            if Tp_special == 1
                waves(:,2) = chess.BoundaryConditions.waves.period_from_peak(waves(:,2), 'peak_from_mean');
            end
    
            %% EXTRACT ADCIRC DATA RESIDING INSIDE STWAVE TEMPORAL RANGE
            min_wv = wv_dtime(1);    % Optimization: avoid min/max function overhead over sorted arrays
            max_wv = wv_dtime(end);
    
            ad_mask = (ad_dtime >= min_wv) & (ad_dtime <= max_wv);
            WL = WL(ad_mask, :);
            ad_dtime = ad_dtime(ad_mask, :);
    
            %% ADJUST MODEL OUTPUTS VIA INTERPOLATION
            min_bound = max(min_wv, ad_dtime(1));
            max_bound = min(max_wv, ad_dtime(end));
    
            date_final = (min_bound:dt_final:max_bound)';
            len_final = length(date_final);
    
            % Perform Interpolation
            WL_interp = interp1(ad_dtime, WL, date_final, 'linear');
            waves_interp = interp1(wv_dtime, waves, date_final, 'linear'); % Interpolates all 3 columns simultaneously
            %% PRESERVE RAW PEAKS (SWL, Hm0, Tp, wDir)
            % Hourly Interpolation Can Miss A Raw Peak Between Grid Points: Keep It At The Nearest Grid Point
            WL_interp = preserve_raw_peak(WL_interp, date_final, WL, ad_dtime);
            for cc = 1:size(waves, 2)
                waves_interp(:, cc) = preserve_raw_peak(waves_interp(:, cc), date_final, waves(:, cc), wv_dtime);
            end
    
            % Build Storm Data Matrix [ SWL, Hm0, Tp, wDir, date, dt ]
            storm_mat = [WL_interp, waves_interp, datenum(date_final), repmat(dt_final_datenum, len_final, 1)];
    
            %% REMOVE BAD ENTRIES
            % ADCIRC Flag Check
            storm_mat(storm_mat(:, 1) < chess.CoastalHazardSystem.FLAG_BELOW, :) = NaN;
            % STWAVE Flag Check On Hm0/Tp (Safety Net: Raw Wave Flags Are Filled Upstream, chess.CoastalHazardSystem.fill_flagged_wave_steps); Wave Direction Not Checked
            storm_mat(any(storm_mat(:, 2:3) < chess.CoastalHazardSystem.WAVE_FLAG_BELOW, 2), 2:3) = NaN;
            % Rows With NaN SWL/Hm0/Tp Are Dropped: Trimmed At The Start/End; An Interior Gap Or No Row Left Makes A Bad Storm
            kept = find(~any(isnan(storm_mat(:, 1:3)), 2));
            if isempty(kept) || numel(kept) ~= kept(end) - kept(1) + 1
                bad_count = bad_count + 1;
                bad_storms_buffer(bad_count) = current_stmID;
                continue;
            end
            storm_mat = storm_mat(kept(1):kept(end), :);
    
            % Store Final Results
            storm_data{stm, 2} = storm_mat;
        end

        %% POST-PROCESSING CONSOLIDATION
        % Prune unused pre-allocated elements and combine with input array
        bad_storms_buffer = bad_storms_buffer(1:bad_count);
        ts_storm2rm = unique([storms2rm(:); bad_storms_buffer]);

        % Print Final Status Completion
        if print_progress
            fprintf(1, '\b\b\b\b100%%\n');
        end
        end

        function storm_type_data = replace_timeseries_peaks(storm_type_data)
        % replace_timeseries_peaks  Set the Timeseries peaks to the Peaks values.
        %   storm_type_data = chess.CoastalHazardSystem.replace_timeseries_peaks(storm_type_data)
        %
        %   For each storm of the Peaks.Default dataset found in the
        %   Timeseries.Default dataset (matched by storm ID; a storm missing from
        %   the Timeseries is skipped), the maximum of each hydrograph column
        %   (SWL, Hm0, Tp, wave dir) is replaced by the Peaks value of that
        %   column. chess.CoastalHazardSystem.build_storm_database calls it for every storm type that has
        %   both Peaks and Timeseries files.
        %
        %   Inputs:
        %     storm_type_data - storm datasets of one storm type (storm.TC or
        %                       storm.XC) with Peaks.Default ({storm ID, 1x5
        %                       [SWL Hm0 Tp wave_dir peak_datenum]}) and
        %                       Timeseries.Default ({storm ID, M x 6 [SWL Hm0 Tp
        %                       wave_dir datenum dt]}), struct
        %   Outputs:
        %     storm_type_data - same, with the Timeseries.Default hydrograph
        %                       maxima replaced, struct
        %
        %   See also chess.CoastalHazardSystem.build_storm_database, chess.CoastalHazardSystem.format_timeseries.
        dPeaks = storm_type_data.('Peaks').('Default');
        timeseries_ids = cell2mat(storm_type_data.('Timeseries').('Default')(:,1));
        % For Each Storm ID
        for kk = 1:length(dPeaks(:,1))
            % Find Storm ID Entry Row, Skip Storm If Not Found
            rowID = timeseries_ids == dPeaks{kk,1};
            if ~any(rowID)
                continue;
            end
            for jj = 1:4 % For Each Column SWL, Hm0, Tp, wDir
                % Find Max On Hydrograph
                [~, tsIndx] = max(storm_type_data.('Timeseries').('Default'){rowID, 2}(:, jj));
                % Replace Timestep With Value In Peaks File
                storm_type_data.('Timeseries').('Default'){rowID, 2}(tsIndx, jj) = dPeaks{kk, 2}(1, jj);
            end
        end
        end

        function [storm_data, ts_storm2rm] = priority_dataset(peaks_table, timeseries_table_surge, timeseries_table_wave, storms2rm, wave_headers, Tp_special, priority_type, print_progress)
        % priority_dataset  Build the WLP or WHP Peaks dataset of a storm type.
        %   [storm_data, ts_storm2rm] = chess.CoastalHazardSystem.priority_dataset(peaks_table,
        %       timeseries_table_surge, timeseries_table_wave, storms2rm,
        %       wave_headers, Tp_special, priority_type, print_progress)
        %
        %   Pairs the Peaks values of one model with the Timeseries values of the
        %   other. All tables are sorted by numeric Storm ID and paired by row;
        %   they must hold the same storm IDs (error
        %   chess:CoastalHazardSystem:adcircWaveIdMismatch).
        %   'wlp' (Water Level Priority): peaks_table is the ADCIRC Peaks table;
        %   its SWL is paired with the wave Timeseries Hm0, Tp and wave dir at the
        %   time step nearest the SWL peak time, within +/- 3 hours. When no wave
        %   time step is that close, the peak time becomes the time of the ADCIRC
        %   Timeseries maximum within the wave Timeseries time range (the SWL
        %   stays the Peaks value).
        %   'whp' (Wave Height Priority): peaks_table is the wave model Peaks
        %   table; its Hm0, Tp and wave dir are paired with the ADCIRC Timeseries
        %   SWL at the time step nearest the wave peak time, within +/- 3 hours.
        %   Tp_special = 1 gives Tp = 1.2 * Tm. The wave Timeseries are expected
        %   with their flagged raw steps already filled (chess.CoastalHazardSystem.fill_flagged_wave_steps),
        %   so a WLP wave value is never a flag. A storm in storms2rm, with a
        %   single value in the paired Timeseries or with no match gets NaN data
        %   and is added to ts_storm2rm; chess.CoastalHazardSystem.quality_check removes the
        %   ts_storm2rm storms from every dataset of the storm type.
        %
        %   Inputs:
        %     peaks_table            - converted Peaks table, ADCIRC for 'wlp' or
        %                              wave model for 'whp' (Storm ID,
        %                              yyyymmddHHMM, data columns), table
        %     timeseries_table_surge - converted ADCIRC Timeseries table (Storm ID,
        %                              yyyymmddHHMM, Water Elevation), table
        %     timeseries_table_wave  - converted wave model Timeseries table,
        %                              table
        %     storms2rm              - IDs of storms already removed, double
        %     wave_headers           - wave model column names (fields Hm0, Tp,
        %                              wDir; chess.CoastalHazardSystem.wave_model_columns),
        %                              struct
        %     Tp_special             - 1 when the wave file gives the mean period
        %                              Tm instead of Tp, else 0, double
        %     priority_type          - 'wlp' or 'whp', char
        %     print_progress         - print progress (0/1), double
        %   Outputs:
        %     storm_data  - WLP or WHP dataset, number_of_storms x 2 cell
        %                   {storm ID, 1x5 [SWL Hm0 Tp wave_dir peak_datenum]}
        %     ts_storm2rm - unique IDs of storms2rm and of the storms removed
        %                   here, double
        %
        %   See also chess.CoastalHazardSystem.quality_check, chess.CoastalHazardSystem.format_peaks,
        %   chess.CoastalHazardSystem.format_timeseries, chess.CoastalHazardSystem.wave_model_columns.

        %% DEFINE INPUTS
        ts_storm2rm = storms2rm;
        % Define Time Window Around Peak To Pull Response From Timeseries
        tdelta = chess.Common.chess_units('convert', chess.CoastalHazardSystem.PEAK_WINDOW_HOURS, 'h', 'day'); % +/- window [days]
        % Sort By Numeric Storm ID; All Tables Must Hold The Same Storms (Paired By Row)
        [peaks_table, timeseries_table_surge, timeseries_table_wave] = chess.CoastalHazardSystem.sort_tables_by_storm_id(peaks_table,...
            timeseries_table_surge, timeseries_table_wave);
        % Grab Storm IDs
        stmID = num2cell(str2double(peaks_table.("Storm ID")));
        % Initialize Storage Matrix
        storm_data = [stmID ,cell(length(stmID(:,1)),1)];

        %% PROMT USER
        % Display Progress Step
        switch priority_type
            case 'wlp'
                chess.Common.disp_toggle(print_progress,'Building water level priority (WLP) dataset....');
                timeseries_table = timeseries_table_wave;
                chk_field = wave_headers.Hm0;
            case 'whp'
                chess.Common.disp_toggle(print_progress,'Building wave height priority (WHP) dataset....');
                timeseries_table = timeseries_table_surge;
                chk_field = "Water Elevation";
        end
        % Display Completion Progress Initial Print
        if print_progress
            fprintf(1,'   Completion Progress: %3d%%\n',0);
        end
        %%
        % Find Table Row To Extract
        for stm = 1:length(stmID)
            % Print Status
            if print_progress
                fprintf(1,'\b\b\b\b%3.0f%%',(100*(stm/length(stmID))));
            end
            % Skip Bad Storm
            if ismember(stmID{stm}, storms2rm) || length(timeseries_table.(chk_field){stm,1}) == 1
                % Assign NaN
                storm_data(stm, 2) = {nan(1,1)};
                % Store Bad Storm ID
                ts_storm2rm = [ts_storm2rm;stmID{stm}];
                % Move To Next Storm
                continue;
            end
            % Get Storm Timeseries Timestamp
            ts_date =  datenum(timeseries_table.('yyyymmddHHMM'){stm,1});
            % Get Priority Response Peak Timestamp
            peak_date = datenum(peaks_table.('yyyymmddHHMM')(stm,1));
            % Find Timeseries Data Points Withing The +/- Time Window (tdelta)
            wIndx = find(abs(ts_date-peak_date)<=tdelta);
            % Remove Storm For Failed Peak Match
            if isempty(wIndx)
                % Water Level Priority Failsafe
                if strcmp(priority_type, 'wlp') % Find Surge Timeseries Within Wave Timeseries
                    % Get Wave Timestamp
                    ts_date_surge = datenum(timeseries_table_surge.('yyyymmddHHMM'){stm,1});
                    % Find Surge Timseries Rows Within Wave Timeseries
                    wl_indx = ts_date_surge >= min(ts_date) & ts_date_surge <= max(ts_date);
                    % Execute Data Assignment
                    if ~any(wl_indx) % Bad Storm
                        % Assign NaN
                        storm_data(stm, 2) = {nan(1,1)};
                        % Store Bad Storm ID
                        ts_storm2rm = [ts_storm2rm;stmID{stm}];
                        % Move To Next Storm
                        continue;
                    else % Find Corresponding Peak Wave Response
                        % Find New Peak Surge
                        [~, peak_indx] = max(timeseries_table_surge.('Water Elevation'){stm,1}(wl_indx, 1));
                        % Grab Surge Timeseries Timestamp Within Wave Temporal Range
                        ts_date_surge = ts_date_surge(wl_indx);
                        % Find Peak Response Date
                        peak_date = ts_date_surge(peak_indx);
                        % Find Timeseries Data Points Withing The +/- Time Window (tdelta)
                        wIndx = find(abs(ts_date-peak_date)<=tdelta);
                    end
                else
                    % Assign NaN
                    storm_data(stm, 2) = {nan(1,1)};
                    % Store Bad Storm ID
                    ts_storm2rm = [ts_storm2rm;stmID{stm}];
                    % Move To Next Storm
                    continue;
                end
            end
            % Determine The CLoses Timestamp
            [~, wIndx2] = min(abs(ts_date(wIndx)-peak_date));
            % Redefine Index To Final Selection
            wIndx = wIndx(wIndx2);
            % Assign Storm Data
            switch priority_type
                case 'wlp'
                    storm_data{stm, 2} = [peaks_table.('Water Elevation')(stm,1),...
                        timeseries_table.(wave_headers.Hm0){stm,1}(wIndx),...
                        timeseries_table.(wave_headers.Tp){stm,1}(wIndx),...
                        timeseries_table.(wave_headers.wDir){stm,1}(wIndx),...
                        peak_date];
                case 'whp'
                    storm_data{stm, 2} = [timeseries_table.('Water Elevation'){stm,1}(wIndx),...
                        peaks_table.(wave_headers.Hm0)(stm,1),...
                        peaks_table.(wave_headers.Tp)(stm,1),...
                        peaks_table.(wave_headers.wDir)(stm,1),...
                        peak_date];
            end
            % Check For Special Tp Case
            if Tp_special == 1
                storm_data{stm, 2}(:, 3) = chess.BoundaryConditions.waves.period_from_peak(storm_data{stm, 2}(:, 3), 'peak_from_mean');
            end
        end
        % Do Unique
        ts_storm2rm = unique(ts_storm2rm);
        % Print Status
        if print_progress
            fprintf(1,['\b\b\b\b%3.0f%%' newline],(100*(stm/length(stmID))));
        end
        end

        function [wave_table, no_tp_ids] = fill_flagged_wave_steps(wave_table, wave_headers)
        % chess.CoastalHazardSystem.fill_flagged_wave_steps  Replace flagged steps of raw wave model Timeseries.
        %   [wave_table, no_tp_ids] = chess.CoastalHazardSystem.fill_flagged_wave_steps(wave_table, wave_headers)
        %
        %   Fills the flagged steps of the raw (converted, not interpolated) wave
        %   model Timeseries of one storm type so the step is kept with a small
        %   wave instead of being dropped; chess.CoastalHazardSystem.quality_check applies it
        %   before chess.CoastalHazardSystem.format_timeseries and chess.CoastalHazardSystem.priority_dataset (WLP), so
        %   no interpolated step mixes a flag with a valid value. Per storm:
        %     Hm0 NaN or <= 0 (flags < -400 and 0 included) -> 0.01 m;
        %     Tp NaN or <= 0 (flags included) -> the valid Tp of the same storm
        %       nearest in time (independent of Hm0: a valid Hm0 keeps its value);
        %     wave direction NaN or < -400 (flags) -> the valid direction of the
        %       same storm nearest in time (left unchanged when the storm has
        %       none; the direction never makes a storm bad).
        %   A storm without any valid Tp is listed in no_tp_ids (bad storm; its
        %   Tp is left unchanged).
        %
        %   Inputs:
        %     wave_table   - converted wave model Timeseries table (Storm ID,
        %                    yyyymmddHHMM and the columns named in wave_headers;
        %                    one row per storm, cells hold the series), table
        %     wave_headers - wave model column names (fields Hm0, Tp, wDir;
        %                    chess.CoastalHazardSystem.wave_model_columns), struct
        %   Outputs:
        %     wave_table   - wave_table with the flagged Hm0, Tp and wave
        %                    direction steps filled,
        %                    table
        %     no_tp_ids    - IDs of the storms without a valid Tp step, column
        %                    double
        %
        %   See also chess.CoastalHazardSystem.quality_check, chess.CoastalHazardSystem.format_timeseries,
        %   chess.CoastalHazardSystem.priority_dataset.

        hm0 = wave_table.(wave_headers.Hm0);
        tp = wave_table.(wave_headers.Tp);
        wdir = wave_table.(wave_headers.wDir);
        no_tp = false(height(wave_table), 1);
        for stm = 1:height(wave_table)
            hm0{stm}(isnan(hm0{stm}) | hm0{stm} <= 0) = chess.CoastalHazardSystem.FLAGGED_HM0_FILL;
            t = datenum(wave_table.yyyymmddHHMM{stm});
            bad_tp = isnan(tp{stm}) | tp{stm} <= 0;
            if all(bad_tp)
                no_tp(stm) = true;
            else
                tp{stm} = fill_nearest(tp{stm}, t, bad_tp);
            end
            bad_dir = isnan(wdir{stm}) | wdir{stm} < chess.CoastalHazardSystem.WAVE_FLAG_BELOW;
            if ~all(bad_dir)
                wdir{stm} = fill_nearest(wdir{stm}, t, bad_dir);
            end
        end
        wave_table.(wave_headers.Hm0) = hm0;
        wave_table.(wave_headers.Tp) = tp;
        wave_table.(wave_headers.wDir) = wdir;
        no_tp_ids = str2double(wave_table.("Storm ID")(no_tp));
        no_tp_ids = no_tp_ids(:);
        end

        function [STWAVE_headers_location,Tp_special] = wave_model_columns(STWAVE)
        % wave_model_columns  Wave file column names of Hm0, Tp and wave dir.
        %   [STWAVE_headers_location, Tp_special] =
        %       chess.CoastalHazardSystem.wave_model_columns(STWAVE)
        %
        %   Finds the column names of Hm0, Tp and the mean wave direction in a
        %   converted CHS wave model file (STWAVE, WAM and SWAN name them
        %   differently), and flags a file that gives the mean period Tm instead
        %   of Tp. Hm0: 'Zero Moment Wave Height', 'Significant Wave Height' or
        %   'Significant Wave Height Total Sea'. Tp: 'Peak Spectral Wave Period
        %   Total Sea', 'Peak Period', 'Smoothed Peak Period' or 'Peak Wave
        %   Period', else 'Mean Wave Period' (Tm, Tp_special = 1). Wave direction:
        %   'Mean Wave Direction Total Sea' or 'Mean Wave Direction'. Errors
        %   'Hm0 not found.', 'Tp not found.' or 'Mean Wave Direction not found.'
        %   (no error ID) when none of the names is present. The file comes from
        %   chess.CoastalHazardSystem.convert_h5 or chess.CoastalHazardSystem.convert_zip.
        %
        %   Inputs:
        %     STWAVE - converted CHS wave model file (Filename, Conv_Data;
        %              Conv_Data.headers holds the column names), 1x1 struct
        %   Outputs:
        %     STWAVE_headers_location - column names, struct; fields Hm0, Tp,
        %                               wDir (char)
        %     Tp_special              - 1 when the file gives Tm instead of Tp,
        %                               else 0, double
        %
        %   See also chess.CoastalHazardSystem.quality_check, chess.CoastalHazardSystem.format_peaks,
        %   chess.CoastalHazardSystem.format_timeseries, chess.CoastalHazardSystem.convert_h5.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL
    
            %% DETERMINE Hm0 DATA COLUMN LOCATION
            % Determine What Header To Call For Hm0
            headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
                {'Zero Moment Wave Height','Significant Wave Height','Significant Wave Height Total Sea'})==1),...
                STWAVE.Conv_Data.headers,'un',false));
            if isempty(headerIndx)
                % Throw Error
                error('chess:CoastalHazardSystem:hm0ColumnNotFound', 'The wave model file has no Hm0 column (headers "Zero Moment Wave Height", "Significant Wave Height" or "... Total Sea").');
            end
            % Define Posible Header Values
            headerName = {'Zero Moment Wave Height','Significant Wave Height','Significant Wave Height Total Sea'};
            % Store Header To Use
            STWAVE_headers_location.Hm0 = headerName{headerIndx};
    
            %% DETERMINE Tp DATA COLUMN LOCATION
            % Determine What Header To Call For Tp
            headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
                {'Peak Spectral Wave Period Total Sea','Peak Period','Smoothed Peak Period','Peak Wave Period'})==1),...
                STWAVE.Conv_Data.headers,'un',false));
            % Define Possible Header Values
            if isempty(headerIndx) % Final Option Try For Tm
                % Determine What Header To Call For Tm
                headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
                    {'Mean Wave Period'})==1),...
                    STWAVE.Conv_Data.headers,'un',false));
                % Flag For Special Case
                Tp_special = 1;
                % Unrecognized Header
                if isempty(headerIndx)
                    % Throw Error
                    error('chess:CoastalHazardSystem:tpColumnNotFound', 'The wave model file has no peak period (Tp) column.');
                end
                % Define Posible Header Values
                headerName = {'Mean Wave Period'};
            else
                % Dataset Offers Tp
                Tp_special = 0;
                % Define Posible Header Values
                headerName = {'Peak Spectral Wave Period Total Sea','Peak Period','Smoothed Peak Period','Peak Wave Period'};
            end
            % Store Header To Use
            STWAVE_headers_location.Tp = headerName{headerIndx};
    
            %% DETERMINE WAVE DIRECTION DATA COLUMN LOCATION
            % Determine What Header To Call For Hm0
            headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
                {'Mean Wave Direction Total Sea','Mean Wave Direction'})==1),...
                STWAVE.Conv_Data.headers,'un',false));
            % Unrecognized Header
            if isempty(headerIndx)
                % Throw Error
                error('chess:CoastalHazardSystem:wdirColumnNotFound', 'The wave model file has no mean wave direction column.');
            end
            % Define Posible Header Values
            headerName = {'Mean Wave Direction Total Sea','Mean Wave Direction'};
            % Store Header To Use
            STWAVE_headers_location.wDir = headerName{headerIndx};
    
        end

        function varargout = sort_tables_by_storm_id(varargin)
        % chess.CoastalHazardSystem.sort_tables_by_storm_id  Sort CHS storm tables by numeric Storm ID and check they pair.
        %   [table_1, table_2, ...] = chess.CoastalHazardSystem.sort_tables_by_storm_id(table_1, table_2, ...)
        %
        %   Sorts each converted CHS table (chess.CoastalHazardSystem.convert_h5 Table_StormData) by
        %   str2double of its 'Storm ID' column (text in the converted files, so
        %   a text sort would put '10' before '9'), then checks that every table
        %   holds the same storm IDs: the CHS formatters pair the ADCIRC and wave
        %   model tables by row. Errors (chess:CoastalHazardSystem:adcircWaveIdMismatch)
        %   when the ID lists differ.
        %
        %   Inputs:
        %     table_1, table_2, ... - converted CHS tables with a 'Storm ID'
        %                             column (text IDs), table
        %   Outputs:
        %     table_1, table_2, ... - the input tables sorted by numeric Storm ID,
        %                             table
        %
        %   See also chess.CoastalHazardSystem.format_timeseries, chess.CoastalHazardSystem.format_peaks,
        %   chess.CoastalHazardSystem.priority_dataset.

        varargout = varargin;
        ids = cell(1, nargin);
        for kk = 1:nargin
            ids{kk} = str2double(varargin{kk}.("Storm ID"));
            [ids{kk}, order] = sort(ids{kk}(:));
            varargout{kk} = varargin{kk}(order, :);
        end
        for kk = 2:nargin
            if ~isequaln(ids{kk}, ids{1})
                error('chess:CoastalHazardSystem:adcircWaveIdMismatch', ['CHS storm tables hold different storm IDs (%d vs %d storms; ',...
                    '%d IDs not in both); the ADCIRC and wave model files are paired by storm ID.'],...
                    numel(ids{1}), numel(ids{kk}), numel(setxor(ids{1}, ids{kk})));
            end
        end
        end

        function out_file = zip_extract_entry(zip_name, entry_file, out_dir)
        % chess.CoastalHazardSystem.zip_extract_entry  Extract one entry of a zip file by name, without the rest.
        %   out_file = chess.CoastalHazardSystem.zip_extract_entry(zip_name, entry_file, out_dir)
        %
        %   Extracts one entry of a zip folder, by file name (any zip subfolder,
        %   case-insensitive), into out_dir without decompressing the rest; a
        %   file of that name in out_dir is replaced. Used by chess.CoastalHazardSystem.zip_h5_attributes
        %   (study datum and savepoint coordinates for chess.Model.create and the
        %   GUI storm database wizard). An entry not in the zip folder is an
        %   error (chess:CoastalHazardSystem:zipEntryNotFound).
        %
        %   Inputs:
        %     zip_name   - zip folder (relative or full path), char
        %     entry_file - entry file name (name + extension, no folder), char
        %     out_dir    - destination folder (created if missing), char
        %   Outputs:
        %     out_file   - full path of the extracted file, char
        %
        %   See also chess.CoastalHazardSystem.zip_h5_attributes, chess.CoastalHazardSystem.zip_h5_names.
        %
        %   Developed by: Fabian A. Garcia Moreno ERDC-CHL

        % Absolute Path (Java Resolves Relative Paths Against Its Own Working Folder; exist() Also Finds Files On The MATLAB Path)
        zip_info = dir(zip_name);
        if isscalar(zip_info) && ~zip_info.isdir
            zip_path = fullfile(zip_info.folder, zip_info.name);
        else
            zip_path = which(zip_name);
        end
        zip_obj = java.util.zip.ZipFile(zip_path);
        zip_cleanup = onCleanup(@() zip_obj.close());
        zip_entries = zip_obj.entries();
        while zip_entries.hasMoreElements()
            zip_entry = zip_entries.nextElement();
            [~, entry_name, entry_ext] = fileparts(char(zip_entry.getName()));
            if strcmpi([entry_name entry_ext], entry_file)
                if ~isfolder(out_dir)
                    mkdir(out_dir);
                end
                out_file = fullfile(out_dir, entry_file);
                in_stream = zip_obj.getInputStream(zip_entry);
                stream_cleanup = onCleanup(@() in_stream.close());
                copy_options = javaArray('java.nio.file.CopyOption', 1);
                copy_options(1) = java.nio.file.StandardCopyOption.REPLACE_EXISTING;
                java.nio.file.Files.copy(in_stream, java.io.File(out_file).toPath(), copy_options);
                return
            end
        end
        error('chess:CoastalHazardSystem:zipEntryNotFound', '''%s'' not found in zip folder ''%s''.', entry_file, zip_path);
        end
    end

    methods (Static, Access = {?matlab.unittest.TestCase, ?chess.Visualization.CHESSPlotsBase}) % Shared With The Raw-Signal Plot And Unit Tests
        function swl = swl_bias_correction(swl, b_a, b_r)
        % swl_bias_correction  CHS TC still water level bias correction (single source).
        %   swl = chess.CoastalHazardSystem.swl_bias_correction(swl, b_a, b_r)
        %   returns, element-wise,
        %     swl - b_a/|b_a|/sqrt(1/b_a^2 + 1/(b_r*swl)^2)
        %   the combined absolute and relative bias correction applied to
        %   the TC SWL by quality_check and to the raw CHS signal of the
        %   storm event viewer.
        %
        %   Inputs:
        %     swl - still water level [m], double scalar or array
        %     b_a - absolute SWL bias [m] (config.chs_swl_b_a), scalar double
        %     b_r - relative SWL bias [-] (config.chs_swl_b_r), scalar double
        %   Outputs:
        %     swl - bias corrected still water level [m], size of swl
        %
        %   See also chess.CoastalHazardSystem.bias_and_uncertainty.
        swl = swl - b_a./abs(b_a)./sqrt(1./b_a.^2 + 1./(b_r.*swl).^2);
        end
    end
end

%% LOCAL FUNCTIONS
function [bnu_fields, loc_fields] = db_info_fields()
% Bias & uncertainty and location fields of db_info
bnu_fields = {'chs_swl_b_a', 'chs_swl_b_r', 'chs_swl_u_a', 'chs_swl_u_r', 'chs_swl_bu_source',...
    'chs_hm0_b_a', 'chs_hm0_b_r', 'chs_hm0_u_a', 'chs_hm0_u_r', 'chs_hm0_bu_source'};
loc_fields = {'offshore_elevation', 'offshore_elevation_source', 'grid_distance_m', 'sp_lat', 'sp_lon'};
end

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

function tf = uses_node_map(region)
tf = strcmp(region, 'CHS-LA');
end

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

function report_grid_point(loc, sp_ID, region)
if isempty(loc.distance_m)
    fprintf('Warning: Savepoint coordinates not found. Savepoint ID SP%d matched in the %s study grid instead.\n', sp_ID, region);
elseif loc.distance_m > chess.CoastalHazardSystem.GRID_DISTANCE_WARNING_M
    switch loc.method
        case 'nearest'
            fprintf('Warning: Nearest grid point found was %.1f m away. This is caused by using SP data.\n', loc.distance_m);
        case 'id'
            fprintf('Warning: Savepoint SP%d grid point (ID match) is %.1f m from the savepoint coordinates.\n', sp_ID, loc.distance_m);
    end
end
end

function val = global_value(u_hm0, fld)
val = [];
if ~isfield(u_hm0, fld)
    return
end
val = u_hm0.(fld);
if ~isscalar(val)
    if isfield(u_hm0, [fld '_avg'])
        val = u_hm0.([fld '_avg']);
    else
        val = [];
    end
end
end

function str = file_list(names)
if isempty(names)
    str = 'none';
else
    str = strjoin(names, ', ');
end
end

function [errors, value] = single_value(errors, values, files, label)
value = '';
[vals, ~, val_idx] = unique(values, 'stable');
if isscalar(vals)
    value = vals{1};
elseif numel(vals) > 1
    parts = cell(1, numel(vals));
    for vv = 1:numel(vals)
        parts{vv} = sprintf('%s (%s)', vals{vv}, strjoin(files(val_idx == vv), ', '));
    end
    errors{end+1} = sprintf('more than one %s, found %s', label, strjoin(parts, ' | '));
end
end

function remove_temp_folder(temp_path)
if isfolder(temp_path)
    rmdir(temp_path, 's');
end
end

function val = to_double(val)
if iscell(val)
    val = val{1};
end
if ischar(val) || isstring(val)
    val = str2double(val);
end
if isempty(val)
    val = NaN;
end
val = double(val(1));
end

function name = file_name(file)
[~, name, ext] = fileparts(file);
name = [name ext];
end

function data = curate_storm_rows(data)
% Rules of chess.CoastalHazardSystem.curate_storm_forcing on the rows of one storm [SWL Hm0 Tp ...]
[data(:, 2), data(:, 3)] = chess.CoastalHazardSystem.floor_wave_height(data(:, 2), data(:, 3));
data(data(:, 1) <= -100, 1) = NaN;
end

function storm = curate_storm_database(storm)
% chess.CoastalHazardSystem.curate_storm_forcing on every Peaks and Timeseries dataset of a storm database
for st = reshape(intersect({'TC', 'XC'}, fieldnames(storm), 'stable'), 1, [])
    for dtype = reshape(intersect({'Peaks', 'Timeseries'}, fieldnames(storm.(st{1})), 'stable'), 1, [])
        for mtype = reshape(fieldnames(storm.(st{1}).(dtype{1})), 1, [])
            storm.(st{1}).(dtype{1}).(mtype{1}) = chess.CoastalHazardSystem.curate_storm_forcing(storm.(st{1}).(dtype{1}).(mtype{1}));
        end
    end
end
end

function [storm, prob_mass] = remove_storms_without_water_level(storm, prob_mass)
% Storms with a NaN curated Peaks SWL leave every dataset of their storm type (and the TC probability masses)
for st = reshape(intersect({'TC', 'XC'}, fieldnames(storm), 'stable'), 1, [])
    if ~isfield(storm.(st{1}), 'Peaks')
        continue
    end
    removed_ids = [];
    for mtype = reshape(fieldnames(storm.(st{1}).Peaks), 1, [])
        dataset = storm.(st{1}).Peaks.(mtype{1});
        no_water_level = cellfun(@(peak) isnan(peak(1)), dataset(:, 2));
        removed_ids = union(removed_ids, cell2mat(dataset(no_water_level, 1)));
    end
    if isempty(removed_ids)
        continue
    end
    removed_ids = removed_ids(:);
    if strcmp(st{1}, 'TC') && isfield(prob_mass, 'TC_Freq') && ~isempty(prob_mass.TC_Freq)
        % TC_Freq And Param Rows Follow The Rows Of The Default Datasets (chess.CoastalHazardSystem.validate_user_prob_mass)
        removed_rows = ismember(cell2mat(storm.TC.Peaks.Default(:, 1)), removed_ids);
        prob_mass.TC_Freq(removed_rows, :) = [];
        prob_mass.TC_Freq = prob_mass.TC_Freq*prob_mass.TotalFreq/sum(prob_mass.TC_Freq);
        if isfield(prob_mass, 'Param')
            prob_mass.Param(removed_rows, :) = [];
        end
        for bin = {'smpl1', 'smpl2', 'smpl3'}
            kept = prob_mass.(bin{1})(~ismember(prob_mass.(bin{1}), removed_ids));
            prob_mass.(bin{1}) = kept(:);
        end
    end
    for dtype = reshape(intersect({'Peaks', 'Timeseries'}, fieldnames(storm.(st{1})), 'stable'), 1, [])
        for mtype = reshape(fieldnames(storm.(st{1}).(dtype{1})), 1, [])
            dataset = storm.(st{1}).(dtype{1}).(mtype{1});
            storm.(st{1}).(dtype{1}).(mtype{1}) = dataset(~ismember(cell2mat(dataset(:, 1)), removed_ids), :);
        end
    end
    previously_removed = [];
    if isfield(storm.(st{1}), 'removed_storms') && isfield(storm.(st{1}).removed_storms, 'Default')
        previously_removed = storm.(st{1}).removed_storms.Default(:);
    end
    storm.(st{1}).removed_storms.Default = union(previously_removed, removed_ids);
    warning('chess:CoastalHazardSystem:removedStormsWithoutWaterLevel',...
        '%d %s storms have no water level (curated Peaks SWL NaN) and are removed from the storm database: storm IDs %s.',...
        numel(removed_ids), st{1}, mat2str(removed_ids'));
    if isempty(storm.(st{1}).Peaks.Default)
        error('chess:CoastalHazardSystem:noStormsWithWaterLevel',...
            'No %s storm of the storm data has a water level (every curated Peaks SWL is NaN).', st{1});
    end
end
end

function s = keep_fields(s, names)
s = rmfield(s, setdiff(fieldnames(s), names));
end

function tf = totals_match(a, b)
% Totals agree within a relative tolerance of 1e-9 (floating-point sums).
tf = abs(a - b) <= 1e-9 * max(abs(a), abs(b));
end

function check_storm_id_alignment(storm, prob_mass)
for st = reshape(fieldnames(storm), 1, [])
    ref_ids = [];
    ref_name = '';
    for dtype = reshape(intersect({'Peaks', 'Timeseries'}, fieldnames(storm.(st{1})), 'stable'), 1, [])
        for mtype = reshape(fieldnames(storm.(st{1}).(dtype{1})), 1, [])
            name = sprintf('storm.%s.%s.%s', st{1}, dtype{1}, mtype{1});
            ids = cell2mat(storm.(st{1}).(dtype{1}).(mtype{1})(:, 1));
            if isempty(ref_name)
                ref_ids = ids;
                ref_name = name;
            elseif ~isequal(ids, ref_ids)
                error('chess:CoastalHazardSystem:stormIdMismatch', '%s and %s do not hold the same storm IDs in the same order.', name, ref_name);
            end
        end
    end
    if strcmp(st{1}, 'TC') && ~isempty(prob_mass) && ~isempty(prob_mass.TC_Freq)
        if ~isequal(prob_mass.Param(:, 1), ref_ids) || numel(prob_mass.TC_Freq) ~= numel(ref_ids)
            error('chess:CoastalHazardSystem:stormIdMismatch', ['prob_mass (Param column 1, TC_Freq) does not hold the storm IDs ',...
                'of %s in the same order.'], ref_name);
        end
    end
end
end

function report_progress(options, fraction, message)
if ~isempty(options.progress_fcn)
    options.progress_fcn(fraction, message);
end
end

function interp_vals = preserve_raw_peak(interp_vals, t_grid, raw_vals, t_raw)
% If The Raw Peak (Within The Interpolation Window) Exceeds The Interpolated Peak,
% Write It At The Grid Point Nearest The Raw Peak Time. Only Applied When Higher, So
% The Resulting Peak Always Equals The Raw Peak And Is Never Lower Than Before.
in_window = t_raw >= t_grid(1) & t_raw <= t_grid(end);
raw_vals = raw_vals(in_window);
t_raw = t_raw(in_window);
[raw_max, i_raw] = max(raw_vals, [], 'omitnan');
if isempty(raw_max) || isnan(raw_max) || ~(raw_max > max(interp_vals, [], 'omitnan'))
    return
end
[~, i_grid] = min(abs(t_grid - t_raw(i_raw)));
interp_vals(i_grid) = raw_max;
end

function x = fill_nearest(x, t, bad)
% Bad steps take the valid value nearest in time.
if any(bad)
    t_valid = t(~bad);
    x_valid = x(~bad);
    [~, nearest] = min(abs(t(bad) - t_valid'), [], 2);
    x(bad) = x_valid(nearest);
end
end

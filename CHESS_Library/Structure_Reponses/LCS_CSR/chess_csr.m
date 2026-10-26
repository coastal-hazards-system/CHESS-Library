function Resp = chess_csr(config, project_forcing, structure, emp_coeff, data_type, outfolder)
% Get Storm Types
storm_type = fieldnames(project_forcing);
% Compute Structure Respose: q, R2%, Dn50, Dn50 LCBW, P1
for ii = 1:length(storm_type)
    Resp.(storm_type{ii}) = compute_structure_response(config, structure,...
        project_forcing.(storm_type{ii}),...
        emp_coeff, 0);
    % Rubblemound Only
    if config.struc_type == 3
        switch data_type
            case 'peaks'
                % Compute Structure Response: Peaks Reliability
                [Resp.(storm_type{ii}).('PF_Summary'),...
                    Resp.(storm_type{ii}).('Reliab_Summary')] = chess_csr_peaks(config,...
                    structure, emp_coeff,...
                    project_forcing.(storm_type{ii}));
            case 'timeseries'
                if config.csr_call_dpa == 1 && strcmp(storm_type{ii}, config.storm_sampling) % Limit To one Storm Type
                    [Resp.(storm_type{ii}).S] = ...
                        chess_csr_dpa(config, structure, emp_coeff,...
                        project_forcing.(storm_type{ii}));
                    % Create Subdirectory
                    if ~exist(fullfile(outfolder, 'LCS_DPA'),'dir')
                        mkdir(fullfile(outfolder, 'LCS_DPA'));
                    end
                end
        end
    end
end
end




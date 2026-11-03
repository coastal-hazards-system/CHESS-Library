function Resp = chess_csr(config, project_forcing, structure, emp_coeff, data_type, outfolder)
% chess_csr  LCS structure responses of one dataset.
%   Resp = chess_csr(config, project_forcing, structure, emp_coeff,
%       data_type, outfolder)
%
%   CHESS: LCS (workflow 3). For every storm type of the dataset, computes
%   the structure responses of every life cycle (compute_structure_response,
%   full histories). Rubble mounds (struc_type 3) also get:
%     Peaks      - PF_Summary and Reliab_Summary (chess_csr_peaks);
%     Timeseries - S, the damage progression analysis (chess_csr_dpa),
%                  when csr_call_dpa = 1 and only for the storm type named
%                  by storm_sampling; the folder <outfolder>\LCS_DPA is
%                  created.
%   Peaks datasets run with compute_q_vol = 0 (the overtopping volume is
%   Timeseries only).
%
%   Inputs:
%     config          - CHESS configuration, 1x1 struct; reads struc_type,
%                       csr_call_dpa (0/1), storm_sampling and the fields
%                       read by compute_structure_response,
%                       chess_csr_peaks and chess_csr_dpa
%     project_forcing - one dataset, struct with one field per storm type,
%                       each nLC x 1 cell of life-cycle matrices (Peaks
%                       nStorms x 10, Timeseries nRows x 12; lcs_columns)
%     structure       - structure geometry, 1x1 struct
%     emp_coeff       - armor damage coefficients
%                       (load_empirical_coefficients), struct
%     data_type       - 'peaks' or 'timeseries', char
%     outfolder       - workflow folder of the alternative (chess_paths
%                       wf_dir), char
%   Outputs:
%     Resp - Resp.<storm type>: the compute_structure_response fields
%            (nLC x 1 cell, one value per life-cycle row) plus, for rubble
%            mounds, PF_Summary and Reliab_Summary (Peaks, tables) or S
%            (Timeseries, struct), struct
%
%   Tier: internal
%
%   See also call_project_response, compute_structure_response,
%   chess_csr_peaks, chess_csr_dpa, load_empirical_coefficients.

% Overtopping Volume (Q_vol) Is Timeseries Only
if strcmp(data_type, 'peaks')
    config.compute_q_vol = 0;
end
% Get Storm Types
storm_type = fieldnames(project_forcing);
% Compute Structure Respose: q, R2%, Dn50, Dn50 Lee, P1
for ii = 1:length(storm_type)
    Resp.(storm_type{ii}) = compute_structure_response(config, structure,...
        project_forcing.(storm_type{ii}), 0);
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




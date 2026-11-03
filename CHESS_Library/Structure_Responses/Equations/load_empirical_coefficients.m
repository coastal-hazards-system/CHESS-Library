function [emp_coeff] = load_empirical_coefficients()
% load_empirical_coefficients  Read the CSR empirical damage coefficients.
%   emp_coeff = load_empirical_coefficients() reads
%   CHESS_empirical_coefficients.txt (found on the MATLAB path, next to
%   this file) and returns the mean value and standard deviation of every
%   coefficient listed there.
%
%   The file is a table with one header row and the columns symbol,
%   description, units, value (mean) and standard deviation. Called once
%   per LCS run by call_project_response and passed to the CSR damage
%   models (chess_csr, chess_csr_peaks, chess_csr_dpa).
%
%   Outputs:
%     emp_coeff - struct with one field per coefficient symbol (e.g. km1,
%                 km2, k_si, k_sp) holding its mean value, and the
%                 substruct std with the same fields holding the standard
%                 deviations (units as listed in the file, mostly
%                 dimensionless)
%
%   Tier: internal
%
%   See also call_project_response, chess_csr, chess_csr_peaks, chess_csr_dpa.

%% READ & FORMAT EMPIRICAL COEFFICIENTS FILE
% Import Empirical Coefficients Reference Document
emp_coeff2 = readcell('CHESS_empirical_coefficients.txt'); % [ variable_name, description, Units, Value, Std ]
% Remove Headers
emp_coeff2 = emp_coeff2(2:end,:);
% Grab Fieldnames
fields_2_read = emp_coeff2(:,1);
% % Create Fields
for ii = 1:length(fields_2_read)
    emp_coeff.(fields_2_read{ii}) = emp_coeff2{ii,4}; % Mean Value
    emp_coeff.std.(fields_2_read{ii}) = emp_coeff2{ii,5}; % Std
end
end
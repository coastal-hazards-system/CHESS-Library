function [wave_table, no_tp_ids] = fill_flagged_wave_steps(wave_table, wave_headers)
% fill_flagged_wave_steps  Replace flagged steps of raw wave model Timeseries.
%   [wave_table, no_tp_ids] = fill_flagged_wave_steps(wave_table, wave_headers)
%
%   Fills the flagged steps of the raw (converted, not interpolated) wave
%   model Timeseries of one storm type so the step is kept with a small
%   wave instead of being dropped; call_chs_storm_quality_check applies it
%   before chs_timeseries_formatter and create_priority_dataset (WLP), so
%   no interpolated step mixes a flag with a valid value. Per storm:
%     Hm0 NaN or <= 0 (flags < -400 and 0 included) -> 0.01 m;
%     Tp NaN or <= 0 (flags included) -> the valid Tp of the same storm
%       nearest in time (independent of Hm0: a valid Hm0 keeps its value);
%     wave direction unchanged (not checked).
%   A storm without any valid Tp is listed in no_tp_ids (bad storm; its
%   Tp is left unchanged).
%
%   Inputs:
%     wave_table   - converted wave model Timeseries table (Storm ID,
%                    yyyymmddHHMM and the columns named in wave_headers;
%                    one row per storm, cells hold the series), table
%     wave_headers - wave model column names (fields Hm0, Tp, wDir;
%                    chs_wave_model_header_locator), struct
%   Outputs:
%     wave_table   - wave_table with the flagged Hm0 and Tp steps filled,
%                    table
%     no_tp_ids    - IDs of the storms without a valid Tp step, column
%                    double
%
%   Tier: internal
%
%   See also call_chs_storm_quality_check, chs_timeseries_formatter,
%   create_priority_dataset.

small_hm0 = 0.01;
hm0 = wave_table.(wave_headers.Hm0);
tp = wave_table.(wave_headers.Tp);
no_tp = false(height(wave_table), 1);
for stm = 1:height(wave_table)
    hm0{stm}(isnan(hm0{stm}) | hm0{stm} <= 0) = small_hm0;
    bad_tp = isnan(tp{stm}) | tp{stm} <= 0;
    if all(bad_tp)
        no_tp(stm) = true;
    elseif any(bad_tp)
        t = datenum(wave_table.yyyymmddHHMM{stm});
        t_valid = t(~bad_tp);
        tp_valid = tp{stm}(~bad_tp);
        [~, nearest] = min(abs(t(bad_tp) - t_valid'), [], 2);
        tp{stm}(bad_tp) = tp_valid(nearest);
    end
end
wave_table.(wave_headers.Hm0) = hm0;
wave_table.(wave_headers.Tp) = tp;
no_tp_ids = str2double(wave_table.("Storm ID")(no_tp));
no_tp_ids = no_tp_ids(:);
end

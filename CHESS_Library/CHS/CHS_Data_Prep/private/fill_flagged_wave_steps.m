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
%                    chs_wave_model_header_locator), struct
%   Outputs:
%     wave_table   - wave_table with the flagged Hm0, Tp and wave
%                    direction steps filled,
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
wdir = wave_table.(wave_headers.wDir);
no_tp = false(height(wave_table), 1);
for stm = 1:height(wave_table)
    hm0{stm}(isnan(hm0{stm}) | hm0{stm} <= 0) = small_hm0;
    t = datenum(wave_table.yyyymmddHHMM{stm});
    bad_tp = isnan(tp{stm}) | tp{stm} <= 0;
    if all(bad_tp)
        no_tp(stm) = true;
    else
        tp{stm} = fill_nearest(tp{stm}, t, bad_tp);
    end
    bad_dir = isnan(wdir{stm}) | wdir{stm} < -400;
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

function x = fill_nearest(x, t, bad)
% Bad steps take the valid value nearest in time.
if any(bad)
    t_valid = t(~bad);
    x_valid = x(~bad);
    [~, nearest] = min(abs(t(bad) - t_valid'), [], 2);
    x(bad) = x_valid(nearest);
end
end

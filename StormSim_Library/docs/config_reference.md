# StormSim Config Reference

The `config` struct is the single data object that flows through the entire StormSim pipeline. It is built in two stages: first from the user-supplied Excel input file, then augmented at runtime by the MATLAB setup and processing functions. This page documents every field — its type, units, default value, and which structure types it applies to.

**Structure types:**
- **Type 1** — Levee
- **Type 2** — Floodwall
- **Type 3** — Rubblemound
- **Type 4** — Low-Crested Breakwater (LCBW)

> Note: the `struc_type` description text inside the Levee, Floodwall, and Rubblemound `CHESS_*_inputs.xlsx` templates still reads "(Levee - 1, Floodwalls - 2, Rubblemound - 3)" with no mention of Type 4; only the LCBW template's description text has been updated to list all four. This is a cosmetic inconsistency in the Excel template content itself (out of scope for this doc).

---

## Table of Contents

1. [Project & Output Settings](#1-project--output-settings)
2. [CHS Forcing Data](#2-chs-forcing-data)
3. [Structure Geometry](#3-structure-geometry)
4. [Structure Properties](#4-structure-properties)
5. [Response Switches](#5-response-switches)
6. [Forcing Uncertainty](#6-forcing-uncertainty)
7. [MCS Module (LCS Workflow)](#7-mcs-module-lcs-workflow)
8. [CSR Module (LCS Workflow)](#8-csr-module-lcs-workflow)
9. [PROS Module](#9-pros-module)
   - [9b. Deterministic Workflow (DET)](#9b-deterministic-workflow-det-workflow2)
10. [Runtime / Code-Added Fields](#10-runtime--code-added-fields)

---

## How Config Is Built

```
CHESS_*_inputs.xlsx  ──►  call_input_parser.m  ──►  call_environment_setup.m
                          (parses Excel rows,         (derives out_files paths,
                           adds runtime metadata)      enforces type-specific
                                                       constraints, sets hotstart
                                                       state flags)
                                 │
                                 ▼
                        CHS / Forcing / Response pipeline
                        (may overwrite bias, uncertainty,
                         and state flag fields)
```

Most fields in Sections 1–9 originate from the Excel file (`Model Variable Symbol` column). **Input file format:** the GUI reads its PSE templates from `PSE_Templates/<name>.csv` (primary, no Excel needed; falls back to `<name>.xlsx`); the `.xlsx` copies are kept for now for filling out by hand and will move outside the library, so edit the `.csv` (or regenerate it from the `.xlsx`; `ReadStormsimInputTest.testShippedCsvMatchesXlsx` fails while they differ). `.xlsx` or `.csv` (same cells), read by `Setup/read_stormsim_input.m`, shared by `call_input_parser.m` and the GUI (`stormsimProject.get_library_template`, PSE templates `<name>.xlsx`, else `<name>.csv`). Layout independent: every `Model Variable Symbol` header cell (any row/column; sections may sit side by side and in any order) starts a section titled by the cell above it; its rows are symbol, description, units (next two columns) and the value from that section's `Value` header column, down to the next section title in the same column or the end of the data. Blank rows are skipped (not terminators), so blank rows added or removed, or a `.csv` (blank lines kept), read the same; missing cells become `''`; a symbol given twice: the last one (column-major order) wins. The former reader ended each section 3 rows above the next header, so a `.csv` (or a sheet missing the blank row between sections) silently lost the last row of a section. Exceptions are called out inline: the berm fields in Section 3 and all of Section 6 (Forcing Uncertainty) are set exclusively by MATLAB code and do not appear in any Excel template, despite being grouped here by subject matter rather than by source. Fields in Section 10 are also set exclusively by MATLAB code and do not appear in the Excel schema.

---

## 1. Project & Output Settings

Applies to all structure types. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `project_name` | string | — | `'Chicago Shoreline GRR'` | All | Project name: the project folder `<outfolder>/<project_name>` (see [Output layout](#output-layout)), also used in plot file names and titles |
| `struc_id` | string | — | `'R7175_T3'` | All | Structure or transect identifier (the PSE): folder `<project>/PSE/<struc_id>`. Not part of the run file names |
| `case_name` | string | — | `'Seawall_existing'` | All | Case name (the alternative): folder `<project>/PSE/<struc_id>/<case_name>`. Not part of the run file names |
| `outfolder` | string | — | `'SS_Outputs_7175_T3'` | All | Root StormSim output folder path (relative or absolute); holds one folder per project |
| `storm_db` | string | — | `''` (hidden) | All | Storm database name `<db>`: names the storm database files (`<project>/Event_Database/<db>.mat`, `<db>_raw_files.mat`) and prefixes every run file (`<db>_<workflow>_*`). Not in the Excel templates: parsed only when its row is added to the input file. A numeric cell is used as its digits. Empty or absent: `<region>_SP<sp_ID>` (CHS region and savepoint ID read from the provided CHS `.zip`/`CHS_Data` `.mat`); for a `storm` + `prob_mass` `.mat` input, the file's base name (`call_input_parser.m`), so different storm files never share a database. GUI runs set it to the Run-tab storm DB. Built by `stormsim_paths.m` |
| `project_datum` | string | — | `'IGLD85'` | All | Vertical datum label used in plot titles and axis labels |
| `project_CLs` | string | — | `'[84 90]'` | All | Confidence limit percentiles to compute (max 4; 50th always included). Entered as a string expression, e.g. `'[84 90]'` |
| `workflow` | integer | — | `1` | All | StormSim workflow selector: `1`=PROS, `2`=DET (deterministic, see Section 9b), `3`=LCS, `4`=PROS-FB. Any other value raises an explicit validation error in `call_input_parser.m`. (`2` was formerly an EVA alias for `1`; it now selects the deterministic workflow) |
| `struc_type` | integer | — | `1` / `2` / `3` / `4` | All | Structure type: `1`=Levee, `2`=Floodwall, `3`=Rubblemound, `4`=Low-Crested Breakwater (LCBW) |
| `storm_sampling` | string | — | `'XC'` | All | Storm sampling scheme: `'XC'` (extratropical), `'TC'` (tropical), or `'CC'` (combined) |
| `swl_slr` | numeric | m | — | All | Sea level rise applied as a vertical offset to still water level (SWL) |
| `apply_random_tides` | logical | — | `0` | All | Apply random tidal sampling to storm SWL: `0`=Off, `1`=On. Each storm gets one tide start hour, stored per storm type in `tide_indx_tc`/`_xc`/`_cc`. For a storm type with Timeseries, the start hours are drawn once before any dataset is adjusted (`draw_tide_indices.m`, called by `call_project_forcing_adjuster.m`), and every dataset of that type (Peaks Default/WLP/WHP and Timeseries) uses the same hour: Peaks get the tide at the start hour, Timeseries the tide from that hour on (the tide is not aligned with the hydrograph peak). Storm types without Timeseries draw their Peaks start hours over the whole tide record, as before. LCS with `storm_sampling='CC'`: `tide_indx_cc` is not drawn but derived from `tide_indx_tc`/`_xc` (drawn first, before any dataset is adjusted) with the same permutation `stormsim_lcs.m` uses to build CC (stable `sortrows` of [TC; XC] by columns [3, 4, 2]; ties keep TC first, and Timeseries CC storms follow the Peaks CC order), so the same storm has the same tide start hour in its XC/TC datasets and in CC. `tide_indx_cc` is saved in the config. It is carried only at hotstart level `full` (`apply_hotstart_level.m`), where it stays consistent because the cached forcing is reused and the adjuster is skipped; otherwise it is always re-derived from the TC/XC start hours, never carried or reused. Start hours already in the config (hotstart `reuse_sampling`/`full` carry, LCS reference reuse; TC/XC only, plus CC at `full`) are used as given; only a storm whose hydrograph does not fit is redrawn (fit rule under `tide_file`) |
| `apply_depth_limitation` | logical | — | `1` | All | Apply depth limitation to incident waves: `0`=Off, `1`=On |
| `use_peaks` | logical | — | `0` | All | Include CHS peaks files in the forcing dataset: `0`=Off, `1`=On |
| `use_timeseries` | logical | — | `1` | All | Include CHS timeseries files in the forcing dataset: `0`=Off, `1`=On |
| `create_wlp` | logical | — | `0` | All | Create Water Level Priority (WLP) peaks dataset (requires both `use_peaks=1` and `use_timeseries=1`): `0`=Off, `1`=On. LCS: XC WLP life cycles are an exact copy of the Default XC life cycles (copula never re-sampled; `storm.XC.Peaks.WLP` is required in the storm database but not read); TC WLP life cycles hold the same storms as Default with their WLP database values; CC combines the two |
| `create_whp` | logical | — | `0` | All | Create Wave Height Priority (WHP) peaks dataset (requires both `use_peaks=1` and `use_timeseries=1`): `0`=Off, `1`=On. LCS: XC WHP life cycles are an exact copy of the Default XC life cycles (copula never re-sampled; `storm.XC.Peaks.WHP` is required in the storm database but not read); TC WHP life cycles hold the same storms as Default with their WHP database values; CC combines the two |
| `create_plots` | logical | — | `1` | All | Generate output visualizations: `0`=Off, `1`=On |
| `load_project_forcing` | logical | — | `1` | All | Load `project_forcing` from a previously run case instead of re-sampling: `0`=sample new, `1`=load from `ref_case_name`. LCS: `1` reuses the reference's sampled life cycles (storm identities from its `*_sampling_seed.mat` `sampled_ids`, mode from its `lcs_restrict_sampling_rate`, XC copula values from its `xc_peaks.Default`, copied to XC WLP/WHP); storm values are rebuilt from the storm database. A reference whose project forcing is missing (`stormsim_lcs:referenceNotFound`) or whose seed file is missing or lacks `lcs_restrict_sampling_rate`/`sampled_ids` (`stormsim_lcs:referenceSeedNotFound`) reuses nothing: every storm type is sampled fresh, as if `load_project_forcing = 0` (configured mode, normal rate and convergence checks). With random tides on in both cases and the same `tide_file`, the reference's tide start hours are reused only for the storm types whose life cycles were actually reused from it (`load_reference_tide_indices.m`, via `lcs_reference_reuse.m`). Only `tide_indx_tc`/`_xc` are copied; for `storm_sampling='CC'` the CC start hours are derived from them (`draw_tide_indices.m`), so when both TC and XC are reused the CC tides equal the reference's too |
| `ref_case_name` | string | — | `'none'` | All | Name of the reference case to load `project_forcing` from when `load_project_forcing=1`. Set to `'none'` to load from the current case. LCS: the reference is the alternative `ref_case_name` of the same project and PSE, run with LCS and the same storm DB (`<project>/PSE/<struc_id>/<ref_case_name>/LCS/<db>_LCS_project_forcing.mat`, `stormsim_paths.m`); its project forcing file and its sampling seed file (`<db>_LCS_sampling_seed.mat` next to it, `lcs_sampling_seed_file.m`) must both exist; see `load_project_forcing` |

### Output layout

Every output folder and file name comes from `Setup/stormsim_paths.m`, shared by the library and the GUI (identical layout):

```
<outfolder>/<project_name>/
    Event_Database/<db>.mat               storm + prob_mass (out_files.storm_and_prob_mass), shared by every PSE/alternative
    Event_Database/<db>_raw_files.mat     raw CHS_Data (out_files.chs_data)
    Tides/                                GUI only
    StormSim_project_<project_name>.mat   GUI only
    PSE/<struc_id>/<case_name>/<WF folder>/
        <db>_<wflow>_config_file.mat        out_files.config
        <db>_<wflow>_project_forcing.mat    out_files.project_forcing
        <db>_<wflow>_project_responses.mat  out_files.resp_data
        <db>_<wflow>_sampling_seed.mat      LCS (lcs_sampling_seed_file.m)
        RB1_<dataset>/ RB3/ FB1_<dataset>/ FB3/ LCS_DPA/   plots and per-dataset outputs
```

| `workflow` | WF folder | `<wflow>` |
|---|---|---|
| 1 | `PROS` | `PROS-RB` |
| 2 | `DET` | `DET` |
| 3 | `LCS` | `LCS` |
| 4 | `PROS` | `PROS-FB` |

`<db>` is `storm_db` when non-empty, else `<region>_SP<sp_ID>` (CHS `.zip`/`CHS_Data` `.mat` input) or the input file's base name (`storm` + `prob_mass` `.mat` input, set by `call_input_parser.m`). In library runs `call_input_parser.m` reads `region`/`sp_ID` from the provided CHS data first (HDF5 names inside the `.zip`, read without decompressing, `.h5` extension in any case, macOS metadata entries under `__MACOSX/` or named `._*` skipped (`zip_h5_names.m`); `CHS_Data.Filename` of a `.mat`; the file name of a `storm` + `prob_mass` `.mat`), then builds the paths, then looks for `Event_Database/<db>.mat` and `<db>_raw_files.mat` to skip reprocessing. Because they are shared by every PSE/alternative, both files always hold the whole CHS input (`call_chs_data_formater.m`): every storm file is converted and every storm type and data type present is built into `<db>.mat`, whatever this run requests; each run then selects its `storm_sampling`/`use_peaks`/`use_timeseries`/`create_wlp`/`create_whp` from it. The storm files are checked by name before any unzip or conversion by `Setup/IO_Validation/chs_storm_file_slots.m` (called by `call_input_parser.m`, again by `call_chs_data_formater.m` before a build, and by the GUI wizard). Only CHS storm files are ever read: `Setup/IO_Validation/chs_storm_file_names.m` keeps the names with a `.h5` extension (any case) and a `Peaks` or `Timeseries` data type token (last name token), and every other file (HC/AEP/AEF `.h5` files, other extensions) is silently ignored. It is applied where the input names are read (`call_input_parser.m` for the `.zip` and `CHS_Data` `.mat`, `call_chs_data_formater.m`, `chs_data_attributes.m`, the GUI wizard, and inside the identity and slot checks), so the storm file check, the savepoint coordinates/datum read and `chs_files_2_convert` see storm files only. The check first checks the study identity of the storm files with `Setup/IO_Validation/chs_study_identity.m`, names read as `<region>_<storm type>_<simulation>_<post type>_SP<id>_<model>_<data type>` (e.g. `CHS-NA_XH_SimB_Post0_SP05572_ADCIRC01_Peaks.h5`): a file name given more than once (case-insensitive, e.g. the same file in two zip subfolders; "<file> is in the input 2 times ..."), a name without the save point token (token 5, `SP<id>`), more than one water level (ADCIRC) save point or more than one wave save point, more than one CHS region (token 1), more than one simulation (token 3) or more than one post type (token 4) is an error naming each value and its files (e.g. "more than one water level (ADCIRC) save point, found SP05572 (...) | SP09999 (...)"); `region` (token 1), `sp_ID` and `sp_ID_wave` come from this check. Then every storm file goes to a slot, storm type (name token 2: `XH`/`XC` -> XC, `TS`/`TC` -> TC) x data type, and each slot is empty or holds exactly one water level (ADCIRC) file and one wave (STWAVE/SWAN) file; a half pair or a duplicate is an error naming the slot and its files. The request must then be covered by the complete slots (`CC` needs TC and XC, `use_peaks`/`use_timeseries` need that data type for every requested storm type, `create_wlp`/`create_whp` need both), e.g. "XC has no Timeseries in this input". Without CHS_Dependencies covering the region (`chs_dependencies_available.m`) a TC or CC request stops in `call_input_parser.m` (and in `call_chs_data_formater.m`, same message, should a build otherwise drop TC); an XC run builds `<db>.mat` with XC only (no TC quality check, no probability masses) while `<db>_raw_files.mat` still holds every file, and a later run with CHS_Dependencies requesting TC/CC finds the database incompatible (`storm_db_check.m`: TC counts only with a non-empty `prob_mass.TC_Freq`) and rebuilds it from the raw file. `<db>.mat` also holds `db_info` (`Setup/storm_db_info.m`, see [Storm database details](#storm-database-details-db_info)); a database without it (older version) is rebuilt from the raw file, or the run stops ("rebuild the storm database"). A `storm` + `prob_mass` `.mat` input has no slots: the request must be in the provided storm data, else the run stops (no rebuild possible); its older database without `db_info` is created again from the input file. WLP/WHP are built when requested (or already in the database being rebuilt), as in the GUI storm database wizard; a later run requesting a WLP/WHP dataset the database lacks rebuilds `<db>.mat` from `<db>_raw_files.mat` (no `.h5` conversion) and deletes that run's cached project forcing. A different savepoint or region therefore writes different files; nothing is deleted. An LCS reference case (`ref_case_name`) is looked up in the same project/PSE, alternative `ref_case_name`, workflow 3, with this run's `<db>` (reference reuse needs the same storms). Names are used as given (no sanitising). Output folders of the older layouts are not read.

---

## 2. CHS Forcing Data

Applies to all structure types. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `storm_duration` | numeric | hrs | `1` | All | Storm duration in **hours** (config, GUI project and CHS Storm DB wizard alike; the wizard builds its databases with 1 h). Runs always use this config value (Excel input table, or the GUI Run tab inputs table, which always shows the row; template default 1 h), never the storm DB's build duration. Data columns keep datenum **days**, derived as `storm_duration/24`: storm DB Peaks column 6 (`call_chs_storm_quality_check.m`; restamped in memory from this config by `restamp_peaks_storm_duration.m`, called by `call_project_forcing_formater.m` and the storm event viewer (`StormsimPlotsBase.storm_event_viewer`), before the forcing is built, for every storm type and Peaks match type, so a storm DB built with another duration never reaches the run; the storm DB file is not modified and Timeseries `dt` is untouched), LCS life-cycle column 9 (`stormsim_lcs.m`; also for storms reused from a reference case, XC included: only the XC copula values, columns 5:8, come from the reference seed), `project_forcing.dt` of the PROS frequency base (`datenum(0,0,0,storm_duration,0,0)`). Uses: LCS Peaks overtopping volume (`Q_vol = sum(q*dt)` per life cycle, `dt` = column 9 x 86400 s; PROS/DET Peaks get no `Q_vol`, `compute_structure_response.m` integrates multi-step storms only, but their `project_forcing.dt` = column 6 is kept in the outputs), Dn50 Melby/van Gent number of waves (`compute_structure_response.m`: `storm_duration*3600` s, every data type), LCS CSR Peaks `Nz = storm_duration*3600/Tm` (`stormsim_csr_peaks.m`). **Open question (team discussion):** for Timeseries, Dn50 still uses this config value as the storm duration, not the hydrograph length. Hotstart: `deps.forcing_build` (level `reuse_sampling`: the forcing is rebuilt, LCS keeps its sampled life cycles; see [Hotstart levels](#hotstart-levels)) |
| `chs_dependencies` | string | — | `'..\CHS_Dependencies'` | All | Relative path to the CHS_Dependencies folder (read-only regional data: `Grid_Files`, `Probability_Masses`, `Bias_and_Uncertainty`). Used throughout `call_environment_setup.m` for regional file discovery via `dir()`/`contains()` |
| `chs_zip` | string | — | — | All | Relative path to the CHS zip archive or custom modeling .mat file containing storm data |
| `tide_file` | string | — | `'none'` | All | Relative path to tidal record file for random tidal sampling of storm SWL. Set to `'none'` if `apply_random_tides=0`. Hourly record of N values; a storm of L time steps starting at hour `idx` covers `idx : idx+L-1` and fits when `idx + L - 1 <= N`. New start hours are drawn uniformly from `[1, N-L+1]` (`tide_start_hours.m`; Peaks: L = 1). A record shorter than the longest hydrograph stops the run (`tide_start_hours:tideTooShort`) |

---

## 3. Structure Geometry

Several fields are structure-type-specific. Sourced from Excel, except the berm fields noted below.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `crest_elevation` | numeric | m | — | All | Crest elevation (levee/rubblemound) or top of wall elevation (floodwall) |
| `crest_width` | numeric | m | — | All | Crest width (levee/rubblemound) or wall thickness (floodwall) |
| `toe_elevation` | numeric | m | — | Types 1, 3, 4 | Mound toe elevation, as a **signed** elevation in the project datum: negative values are below datum zero (e.g. a toe 1 m below a datum zero of 176.45 m IGLD85 is entered as 175.45 in IGLD85, or -1.00 in the local datum). Do not enter it as a positive depth: since 2026-10-05 the code no longer applies `abs()`, so water depth is `h = SWL - toe_elevation` as entered. Also present and populated in the Type 2 (floodwall) template, but gets overwritten by `wall_bottom_elevation` for Type 2 at runtime (see runtime override table in Section 10) |
| `wall_bottom_elevation` | numeric | m | — | Type 2 | Signed elevation of the bottom of the wall (negative below datum zero). Wall height is `hw = crest_elevation - wall_bottom_elevation`. Only applicable to floodwall (Type 2) |
| `seaside_slope` | numeric | — | — | Types 1, 3, 4 | Seaward face slope expressed as cot(α). Not applicable to Type 2 |
| `leeside_slope` | numeric | — | — | Types 1, 3, 4 | Landward face slope expressed as cot(α). Not applicable to Type 2 |
| `offshore_elevation` | numeric | m | — | All | Offshore (savepoint) **elevation, positive up**, in the CHS study datum, used by the damaging depth (`DamDepth = DamDepthElev - offshore_elevation`, clipped to 0 when negative, i.e. a storm below an offshore elevation above datum; NaN kept, `damaging_depth.m`) and shown in the PSE transect text box. **The storm DB study grid wins:** when the storm database is built, `storm_db_bias_uncertainty.m` takes minus the value column (a depth, positive down) of the CHS_Dependencies study grid point (`Grid_Files/<region>`: `*nodeID*` file if present, else `*staID*`) nearest to the savepoint coordinates (`sp_lat`/`sp_lon`; great-circle distance, no threshold; without coordinates the savepoint ID row), stored as `db_info.offshore_elevation` and applied by `storm_db_info('apply', ...)` on every run (library and GUI). This template row (**Structure Geometry section**, next to `offshore_slope`, in the PSE templates (`PSE_Templates/*_pse.xlsx`, Structure Geometry; the external `CHESS_*_inputs.xlsx` files do not have the row yet)) is only the **fallback**, used when the database has no grid value: no CHS_Dependencies for the region, CHS-TX/CHS-PR grids (no value column), grid fill values (<= -99999 or NaN, e.g. CHS-GLH -999999), GUI Custom_Modeling databases, databases built before this field existed. Grid depths are negated to an elevation (e.g. CHS-GLM SP2994: grid depth -173.69 -> `offshore_elevation` +173.69 m IGLD85). No longer read from the h5 `Save Point Depth` attribute. Replaces `chs_sp_depth`: **the fallback must be entered as an elevation, so old `chs_sp_depth` values flip sign** (e.g. Rogers Park -173.29/-173.69 -> +173.29/+173.69; the old forcing-section row is gone). GUI: entered per PSE in the PSE creation dialog and editable afterwards in the PSE Viewer table (Value column, `PSETableCellEdit`; rows cannot be added there, so PSEs created before the row have none; the PSE Viewer shows the row only when the Run tab storm DB has no study grid value or there is no Run tab storm DB, display filtering only: `pse_tables` / `pse_geometry` keep it), kept in `pse_geometry.offshore_elevation` by `stormsimProject.create_geometry`; `create_resp_config` copies it into config, then `storm_db_info('apply', ...)` overrides it with the grid value. The Run tab constants table shows the resolved value (storm DB grid, else PSE, else NaN) as display-only row 3 "Offshore Elevation (Storm DB / PSE)" (the Run tab inputs table has no offshore elevation row). **Always required (offshore end of the PSE transect conceptual model) when the storm DB has no grid value, whatever `compute_damaging_depth` is:** `check_offshore_elevation.m` stops the run (`check_offshore_elevation:missing`) when the field is missing, empty or NaN, right after the storm database's db_info is applied (end of `call_chs_data_formater.m`, before any forcing work; GUI: `RunSimulationButtonPushed`, before the Run dialog and the run-file backup), e.g. "StormSim needs offshore_elevation (offshore end of the PSE transect; elevation, positive up, study datum): the storm database <db> has no study grid value for SP<id> (<reason>) and the PSE geometry gives none. Enter offshore_elevation in the PSE geometry (GUI: PSE creation; input file: row offshore_elevation)." With the damaging depth off the field is not read (`compute_structure_response.m`). **Run time:** `call_project_response.m` (library and GUI runs) copies the resolved value (after `storm_db_info('apply', ...)` and `check_offshore_elevation.m`) and `offshore_elevation_source` into `structure.offshore_elevation` / `structure.offshore_elevation_source` and appends `structure` to the run config file; the damaging depth and the PSE transect text box read it from `structure` (else from `config`, for structures built outside a run). The GUI Results tab plots with that saved run `structure` (geometry and resolved offshore elevation of the run, not the current PSE). Not a hotstart dependency |

Not user-configurable via any current Excel template. `call_input_parser.m` (~lines 336-340) unconditionally hardcodes these four fields every run, with the code comment "Hide Berms Until Conceptual Models Are Set":

| Field | Type | Units | Hardcoded Value | Applicability | Description |
|-------|------|-------|------------------|---------------|-------------|
| `add_berm` | logical | — | `0` | All | Add a seaward berm to the structure cross-section: `0`=No berm, `1`=Add berm. Currently disabled pending future conceptual-model support |
| `berm_slope` | numeric | — | `1` | All | Berm slope (seaward and landward assumed equal). Ignored and set to 0 at runtime when `add_berm=0` |
| `berm_width` | numeric | m | `0` | All | Berm width. Set to 0 at runtime when `add_berm=0` |
| `berm_elevation` | numeric | m | `0` | All | Berm elevation. Set to `toe_elevation` (Types 1,3,4) or `wall_bottom_elevation` (Type 2) at runtime when `add_berm=0` |

**`offshore_elevation` is a template geometry row (the fallback) but not a `create_structure_geometry.m` field.** The parser reads it by name like any row; `create_structure_geometry.m` does not copy it (not in `vars_2_grab`). Run-time structure fields: `structure.offshore_elevation` [m, study datum, positive up] and `structure.offshore_elevation_source`, the resolved value (storm DB grid wins, else this row) copied from `config` by `call_project_response.m`, so the PSE transect (offshore elevation, `offshore_slope`, structure geometry) lives in `structure`. GUI: `stormsimProject.create_geometry` keeps the PSE table value in `pse_geometry.offshore_elevation` (GUI field, like `add_toe_berm`); the PSE pop-out (`stormsimProject.plot_geometry`) shows the storm DB grid value, else that PSE value; the Results tab uses the saved run's resolved value.

Since `add_berm` is currently hardcoded to `0` on every run, this override logic in `call_environment_setup.m` (~lines 78-88) is always exercised; the fields remain live in `config` and would only vary if a future Excel template re-exposed `add_berm`.

---

## 4. Structure Properties

Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `water_density` | numeric | kg/m³ | `1000` | All | Water density used in wave force and stability calculations |
| `roughness_ifactor` | numeric | — | `0.9` | All | Roughness influence factor γ_f (EurOtop Table 6.2): `2`=grass, `1`=concrete/asphalt/closed blocks, `0.9`=basalt/placed revetment blocks, `0.8`=stepped structure |
| `armor_delta` | numeric | — | `1.65` | Types 2, 3, 4 | Armor stone immersed relative density Δ = (ρ_s − ρ_w) / ρ_w |
| `cem_P` | numeric | — | `0.4` | Types 3, 4 | Mean value of the notational permeability coefficient P (CEM Fig. VI-5-11) for Hudson/Van der Meer stability |
| `seaside_mass` | numeric | kg | — | Types 3, 4 | Seaside armor stone mass; used to derive existing Dn50 for damage number calculations |
| `leeside_mass` | numeric | kg | — | Type 3 | Leeside armor stone mass; used to derive existing Dn50 for damage number calculations |
| `seaside_design_S` | numeric | — | `0` | Type 3 | PROS design seaside damage limit state S for stone sizing. Set to `0` to compute required Dn50 |
| `leeside_design_S` | numeric | — | `0` | Type 3 | PROS design leeside damage limit state S for stone sizing. Set to `0` to compute required Dn50 |
| `seaside_S_uls` | numeric | — | `15` | Type 3 | LCS-CSR seaside ultimate limit state (ULS) damage number |
| `leeside_S_uls` | numeric | — | `15` | Type 3 | LCS-CSR leeside ultimate limit state (ULS) damage number |

---

## 5. Response Switches

Control which structural response quantities are computed. Sourced from Excel; some are enforced or overridden at runtime by `call_environment_setup.m` based on `struc_type`.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `compute_q` | logical | — | `1` | All | Compute mean overtopping discharge rate per unit width q (EurOtop): `0`=Off, `1`=On. Forced to `1` at runtime if `compute_nappe=1` |
| `compute_q_vol` | logical | — | `1` | All | Compute overtopping discharge volume per unit width (EurOtop): `0`=Off, `1`=On. Excel description text notes "RB3 Only" — RB3 refers to the Timeseries-derived response basis (Q_vol is integrated from a full discharge timeseries; see `compute_structure_response.m` comment "Find Max Responses For Timeseries (RB3)"), as opposed to RB1 (Peaks-derived response basis), not a "rubblemound-only" restriction. Forced to `0` for workflow=4 |
| `compute_wave_transmission` | logical | — | `1` | All | Compute wave transmission coefficient Kt (EurOtop): `0`=Off, `1`=On |
| `compute_damaging_depth` | logical | — | `0` | All | Compute damaging depth response: `0`=Off, `1`=On |
| `compute_damaging_depth_Ks` | numeric | — | `1` | All | Shielding parameter Ks used in damaging depth calculation. Only used when `compute_damaging_depth=1` |
| `compute_damaging_depth_slope` | numeric | — | — | All | Bottom slope tan(β) used in damaging depth calculation. Only used when `compute_damaging_depth=1` |
| `compute_r2p` | logical | — | `1` | Types 1, 3, 4 | Compute 2% run-up height R2% (EurOtop): `0`=Off, `1`=On. Not applicable to Type 2 |
| `compute_dn50_seaside` | logical | — | `1` | Type 3 | Compute seaward median stone size Dn50 response (Melby momentum flux method): `0`=Off, `1`=On |
| `compute_dn50_leeside` | logical | — | `1` | Type 3 | Compute landward median stone size Dn50 response (Van Gent): `0`=Off, `1`=On |
| `compute_dn50_submerged` | logical | — | `1` | Type 3 | Compute Dn50 responses when the structure is submerged (CEM VI-5-25): `0`=Off, `1`=On |
| `compute_dn50_lcbw` | logical | — | `1` | Type 4 | Compute seaward median stone size / stability response for low-crested breakwaters (Melby, `melby_low_crested_stability` → `Resp.Dn50_LCBW`/`Resp.FS_LCBW`): `0`=Off, `1`=On. Forced to `0` for Types 1–3 |
| `compute_p1` | logical | — | `1` | Type 2 | Compute surface pressure P1 (Goda): `0`=Off, `1`=On. Only applicable to Type 2 |
| `compute_p2_p3` | logical | — | `1` | Type 2 | Compute uplift pressure P2 and toe pressure P3 (Goda): `0`=Off, `1`=On. Only applicable to Type 2 |
| `compute_nappe` | logical | — | `1` | Type 2 | Compute nappe responses: `0`=Off, `1`=On. Only applicable to Type 2. Enabling this forces `compute_q=1` |

---

## 6. Forcing Uncertainty

Uncertainty parameters used by the uncertainty engine. **None of these fields appear in any `CHESS_*_inputs.xlsx` template** — they are all set by MATLAB code rather than sourced from Excel:

- `dn50_u`, `p1_u`, `q_u`, `r2p_u` are loaded unconditionally (regardless of `struc_type`) from `StormSim_Library/Structure_Reponses/Equations/primary_responses_epistemic_uncertainties.txt` in `call_input_parser.m` (~lines 343-349).
- `chs_swl_u_a`, `chs_swl_u_r`, `chs_hm0_u_a`, `chs_hm0_u_r` come from the storm database's `db_info` (see [Storm database details](#storm-database-details-db_info)), applied to config on every run (`storm_db_info('apply', ...)` in `call_input_parser.m`, or in `call_chs_data_formater.m` when the database is built). They are determined once, when the database is built (`storm_db_bias_uncertainty.m`, shared with the GUI wizard): SWL from the CHS_Dependencies circulation bias/uncertainty file at the savepoint row, Hm0 from the wave file (global value, the regional average `_avg` when the file gives values per savepoint), or, when not available there (no CHS_Dependencies for the region, no file), entered once in the command window (the GUI wizard never prompts: it stops with an error dialog). A savepoint missing from the study grid is an error (`storm_db_bias_uncertainty:spNotFound`, "Save point SP<id> not found in the <region> bias/uncertainty file <file>") in the library and the GUI. They have no fixed default. DET (`workflow=2`) applies no uncertainty; `call_environment_setup.m` zero-fills them only while they are still unset (database not built yet).

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `chs_swl_u_a` | numeric | m | — | All | Still water level (SWL) absolute uncertainty U_a. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `chs_swl_u_r` | numeric | — | — | All | Still water level (SWL) proportional uncertainty U_r. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `chs_hm0_u_a` | numeric | m | — | All | Significant wave height Hm0 absolute uncertainty U_a. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `chs_hm0_u_r` | numeric | — | — | All | Significant wave height Hm0 proportional uncertainty U_r. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `dn50_u` | numeric | m | `0.15` | All | Median stone size Dn50 uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` |
| `q_u` | numeric | m³/s/m | `0.78` | All | Mean overtopping discharge uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` |
| `r2p_u` | numeric | m | `0.13` | All | Run-up R2% uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` |
| `p1_u` | numeric | N/m² | `0.43` | Type 2 | Surface pressure P1 uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` for all structure types; only meaningful for Type 2 (Floodwall), the only type that computes P1 |

---

## 7. MCS Module (LCS Workflow)

Only used when `workflow=3` (Life Cycle Simulation). Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `mcs_nLC` | integer | — | `1000` | All (workflow=3) | Number of life cycles to simulate in the Monte Carlo simulation. Hotstart: `deps.sampling` (a change draws new life cycles; see [Hotstart levels](#hotstart-levels)) |
| `mcs_nYears` | integer | years | `50` | All (workflow=3) | Number of years per life cycle. Hotstart: `deps.sampling` (a change draws new life cycles) |

### Hidden LCS sampling settings

These four fields are **hidden**: they are not in the `CHESS_*_inputs.xlsx` templates or the GUI inputs table. `call_input_parser.m` picks one up only if the user adds its row (symbol in the "Model Variable Symbol" column, value in "Value") to the input file; otherwise `finalize_config.m` sets the default (an empty value also gets the default).

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `lcs_restrict_sampling_rate` | logical | — | `0` | All (workflow=3) | Life-cycle storm sampling mode. `0` = full Poisson: each year's storm count is a Poisson draw and the first draw is kept, so a life cycle can have no storms (reliability 1, PF 0, final damage 0). `1` = rate matched (ERDC/CHL TR-20-5): yearly counts are redrawn until the life-cycle total is within rate × `mcs_nYears` ± 1. This requires rate × `mcs_nYears` > 1. Mode 1 runs no convergence check. Life-cycle percentiles are computed in both modes; in mode 1 they are conditional on rate-matched storm counts: they include storm selection, intensity and timing variability, but not storm-count variability (`stormsim_lcs.m` and `call_project_response.m` each print a notice saying so). When storms are reused from a reference case (`load_project_forcing=1`), **the reference's mode is used**, taken from its `*_sampling_seed.mat`. A reference without a usable seed file reuses nothing, so the configured mode applies (`stormsim_lcs:referenceSeedNotFound`). `stormsim_lcs.m` prints a notice when it differs from the configured one. This field always keeps the **configured** value; the mode actually used is `lcs_effective_sampling_rate` (Section 10). Part of `deps.sampling` (a change draws new life cycles; see [Hotstart levels](#hotstart-levels)) |
| `lcs_convergence_tol` | numeric | — | `0.05` | All (workflow=3), mode 0 | Relative tolerance of the LCS convergence check (`lcs_convergence_check.m`). It applies to the mean storm count per life cycle and to the storm-count percentiles in `project_CLs`, where the allowed error is max(1 storm, tol × exact percentile) |
| `lcs_convergence_confidence` | numeric | — | `0.95` | All (workflow=3), mode 0 | Confidence level of the convergence check |
| `lcs_convergence_prompt` | logical | — | `1` | All (workflow=3), mode 0 | What to do when `mcs_nLC` is below the required number of life cycles. `1` = ask "proceed or cancel" in the command window; cancel raises `stormsim_lcs:notConverged`. `0` = issue a warning (`stormsim_lcs:notConverged`) and continue. Use `0` for unit tests and batch runs. The GUI always sets `0`: before an LCS run it shows its own dialog built from `lcs_convergence_checks.m` |

The convergence check runs in `stormsim_lcs.m` before sampling, once per sampled storm type (CC runs it for TC and XC), through `lcs_convergence_checks.m` (storm rates: XC `Nstm_XC/Nyrs_XC`, TC `prob_mass.TC_SRR(end)`). It runs only when the effective mode is 0, and only for storm types not reused from a reference case or from the case's own cached sampling (hotstart level `reuse_sampling`). Its random draws do not change the sampled storms, because the global rng state is restored. `lcs_convergence_check.m` takes an optional 8th input `quiet` (no printed report), used by the GUI dialog and by panel 6 of `lcs_methods.sampling_scheme_dashboard`. Which storm types are reused, the effective mode and the storm types to check come from `lcs_reference_reuse.m`, which `stormsim_lcs.m` and the GUI dialog share: a storm type is reused only when the reference project forcing file exists and the reference's sampling seed file holds `lcs_restrict_sampling_rate` and that storm type's `sampled_ids` (`reuse.seed_found` is false when the seed file is missing or lacks those variables; then no storm type is reused). A storm type the seed does not hold (e.g. TC for an XC-only reference) is sampled fresh and checked; the effective mode is still the reference's when another storm type is reused. The GUI dialog is shown only when the run samples life cycles (coldstart or first run). A GUI hotstart reuses the cached forcing (`full`) or this case's sampling (`reuse_sampling`; see [Hotstart levels](#hotstart-levels)). The results are kept in `lcs_convergence_results` (Section 10). Panel 6 of the dashboard uses them in mode 0 and computes the check (quiet) only when they are absent. In mode 1 panel 6 shows only the running mean (with its 95% CI), the running `project_CLs` percentiles and the λN line: no tolerance bands, Poisson percentiles, `nLC_req` line or verdict, because rate-matched storm counts do not follow those targets by design.

When `load_project_forcing = 1` and the reference's project forcing file is not found, `stormsim_lcs.m` issues the warning `stormsim_lcs:referenceNotFound` (with `ref_case_name` and the path checked) and samples fresh storms. When the file exists but its sampling seed file is missing or lacks `lcs_restrict_sampling_rate`/`sampled_ids`, it issues `stormsim_lcs:referenceSeedNotFound` (with `ref_case_name` and the seed path) and samples every storm type fresh, as if `load_project_forcing = 0`: configured mode, rate and convergence checks as normal.

---

## 8. CSR Module (LCS Workflow)

Cumulative Storm Response (CSR) / Damage Progression Analysis (DPA) settings. Only active when `workflow=3`. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `csr_call_dpa` | logical | — | `0` | Type 3 | Activate the CSR-DPA module: `0`=Off, `1`=On. Only meaningful for Type 3 |
| `csr_apply_structure_repair` | logical | — | `0` | Type 3 | Allow structure repair during DPA analysis: `0`=Off, `1`=On |
| `csr_compute_S_submerged` | logical | — | `1` | Type 3 | Compute Dn50 responses when submerged during DPA (CEM VI-5-25): `0`=Off, `1`=On |
| `csr_apply_cutoff_correction` | logical | — | `0` | All | Apply a cutoff elevation correction in DPA: `0`=Off, `1`=On |
| `csr_cutoff_offset` | numeric | m | `0` | All | Cutoff elevation delta for DPA correction. Must be ≥ 0. Only used when `csr_apply_cutoff_correction=1` |

---

## 9. PROS Module

Probabilistic Response Output System (PROS) settings. Only active when `workflow=1` or `workflow=4`. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `pros_compute_forcing_HC` | integer | — | `1` | All (workflow=1,4) | Compute hazard curves for waves and water level: `1`=On, `0`=Off. Forced to `1` at runtime when workflow=4 or when nappe/P2P3 responses are requested. Forced to `0` for workflow=2 (DET computes P2/P3 and nappe directly from the equations) |
| `pros_use_aep` | logical | — | `0` | All (workflow=1,4) | Hazard curve x-axis convention: `1`=Annual Exceedance Probability (AEP), `0`=Annual Exceedance Frequency (AEF) |
| `pros_plot_hc` | logical | — | `1` | All (workflow=1,4) | Plot individual response hazard curves: `0`=Off, `1`=On |
| `pros_plot_forcing_hc_w_pot` | logical | — | `1` | All (workflow=1,4) | Plot forcing hazard curves with POT sample overlay: `0`=Off, `1`=On |
| `pros_plot_prioty_comp` | logical | — | `0` | All (workflow=1,4) | Plot RB1 priority dataset response comparisons: `0`=Off, `1`=On |
| `pros_plot_hc_xsec` | logical | — | `1` | All (workflow=1,4) | Plot hazard curve cross-section plots: `0`=Off, `1`=On |

---

## 9b. Deterministic Workflow (DET, `workflow=2`)

A "calculator" run: structure responses are computed for **every storm in the storm database**, straight from the recorded forcing. There are no replicates, no forcing uncertainty and no hazard curves. It reads the same Excel fields as PROS, and the `pros_*` and `mcs_*`/`csr_*` sections are ignored.

- **Pipeline:** `stormsim_det_formater.m` (no replicates) → `call_uncertainty_engine.m` (skipped, `u_engine` is set to 1) → `call_project_forcing_adjuster.m` (SLR, random tides, depth limitation, as configured) → `call_project_response.m` → `Structure_Reponses/Deterministic/stormsim_det.m`.
- **Datasets:** Peaks (Default/WLP/WHP per `create_wlp`/`create_whp`) and Timeseries, per `use_peaks`/`use_timeseries` and `storm_sampling`.
- **Tides:** `apply_random_tides=1` is allowed. The tide start hours drawn for each storm are saved in the DET config (`tide_indx_xc`/`tide_indx_tc`). As in PROS, those start hours are shared across the datasets of a storm type; with Timeseries they are drawn so every hydrograph fits the tide record, so Peaks and Timeseries always use the same start hour. A Peaks record gets the tide at the start hour, while its Timeseries version gets the tide series from that hour, so the tide at the storm peak differs between the two. `peaks_vs_timeseries_plot` shows these differences on purpose.
- **Depth limitation:** follows `apply_depth_limitation`. Independently of it, when the toe is dry (`SWL < toe`, `h < 0`; for floodwalls the toe is `toe_elevation` (berm toe) when a toe berm is included, else `wall_bottom_elevation`), `adjust_project_forcing.m` sets Hm0 to 0 (all workflows). Database storms with Hm0 = 0 also stay at 0 through forcing uncertainty (`apply_uncertainty.m`). In both cases: wave-driven responses are NaN, the storm is kept, and surge-only responses (`DamDepthElev = SWL`, `DamDepth`) are still computed. Floodwall P2/P3/pu are NaN wherever P1 is NaN, and the nappe outputs are NaN wherever q is NaN (`compute_structure_response.m`).
- **Uncertainty prompts:** the manual SWL/Hm0 *uncertainty* prompts in `call_environment_setup.m` are skipped. Bias prompts are unchanged. Missing `chs_*_u_*` fields are set to 0.
- **Outputs** (`<outfolder>/<project>/PSE/<struc_id>/<case>/DET/<db>_DET_{config_file,project_forcing,project_responses}.mat`, see [Output layout](#output-layout)): `Resp.(Peaks|Timeseries).(Default|WLP|WHP).(XC|TC)` holds:
  - `storm_id`, `time`, `dt`
  - forcing: `SWL`, `Hm0` (database), `Hm0_DL` (depth limited, used by the equations), `Tp`, `h = SWL − toe_elevation`, `Rc = crest_elevation − SWL`
  - every computed response as full histories (one value per time step; Peaks have one step)
  - `Max`: one value per storm (independent maxima; `Rc` is the minimum)
- **Plots** (`Visualization/det_methods.m` via `StormsimPlots`): `response_vs_forcing_plot`, `response_table` (pop-out) and `peaks_vs_timeseries_plot`.

## 10. Runtime / Code-Added Fields

These fields are **not present in the Excel input files**. They are computed and appended to `config` by MATLAB setup and processing functions.

### Set by `call_input_parser.m`

| Field | Type | Source File | Description |
|-------|------|-------------|-------------|
| `stormsim_input_file` | string | `call_input_parser.m` | Absolute path to the Excel input file used for the run |
| `gravity_constant` | numeric | `call_input_parser.m` | Gravitational acceleration constant (9.80665 m/s²) |
| `chs_files_2_convert` | cell (Nx2) | `call_input_parser.m` | CHS storm files (Peaks/Timeseries `.h5`, `chs_storm_file_names.m`; HC/AEF files left out) of the input `[path, name]`; `call_chs_data_formater.m` reads the names only. Path column from `CHS_Data.Filename` for a `CHS_Data` `.mat` or an existing raw file, `''` for a `.zip` input (not unzipped by the parser: `call_chs_data_formater.m` unzips it, only when converting, into a system temp folder (`tempname`) removed on every exit: success, errors, an aborted bias/uncertainty prompt). Empty (0x2) for a `storm` + `prob_mass` `.mat` |
| `region` | string | `call_input_parser.m` | CHS study region identifier parsed from the CHS filename (e.g., `'CHS-GLMH'`): the single name token 1 of the storm files (`chs_study_identity.m`; more than one is an error) |
| `sp_ID` | numeric | `call_input_parser.m` | CHS ADCIRC savepoint ID (integer, or `[]` if not applicable). CHS input: the single ADCIRC save point (name token 5) of the storm files (`chs_study_identity.m`; more than one is an error) |
| `sp_ID_wave` | numeric | `call_input_parser.m` | CHS wave model savepoint ID (integer, or `[]` if not applicable). CHS input: the single wave save point of the storm files (`chs_study_identity.m`; more than one is an error) |
| `sp_lat`, `sp_lon` | numeric | `call_input_parser.m` | ADCIRC savepoint latitude/longitude [deg] (CHS input only): `Save Point Latitude`/`Save Point Longitude` root attributes of the first ADCIRC storm file (from `CHS_Data` attributes, `chs_data_attributes.m`, or, for a `.zip` without raw file, from that single `.h5` entry extracted to a system temp folder removed before the parser returns). `NaN` when not found (a warning is printed; the storm database build then matches the savepoint ID in the study grid). Passed by `call_chs_data_formater.m` to `storm_db_bias_uncertainty.m` (nearest study grid point: bias/uncertainty row and `offshore_elevation`) |
| `Nyrs_XC` | numeric | `db_info` (`call_input_parser.m` / `call_chs_data_formater.m`) | Number of years in the extratropical storm record, from the storm database's `db_info` (no longer stored in `storm.XC`); `0` (`finalize_config.m`) if the database has no XC |
| `Nstm_XC` | numeric | `db_info` (`call_input_parser.m` / `call_chs_data_formater.m`) | Number of extratropical storms in the record, from `db_info`; not set when the database has no XC |
| `u_engine` | logical | `call_input_parser.m` | Hotstart state flag: `1` if uncertainty engine has already been applied to `project_forcing`, `0` otherwise. Carried from the cached config only at hotstart level `full`; reset to `0` when `call_chs_data_formater.m` builds the storm database |
| `f_adjust` | logical | `call_input_parser.m` | Hotstart state flag: `1` if forcing adjustments have been applied, `0` otherwise. Carried from the cached config only at hotstart level `full`; reset to `0` when `call_chs_data_formater.m` builds the storm database |
| `structure_dir` | numeric | `call_input_parser.m` | Structure orientation direction relative to waves (0 = shore-normal). Not yet implemented; hardcoded `0` |
| `chs_wDir_u_a` | numeric | `call_input_parser.m` | Wave direction absolute uncertainty. Not yet implemented; hardcoded `0` |
| `tide_std` | numeric | `call_input_parser.m` | Tidal standard deviation. Not yet implemented; hardcoded `0` |
| `print_progress` | logical | `call_input_parser.m` | Toggle progress output to the command window; always `true` |

### Set by `call_environment_setup.m`

| Field | Type | Source File | Description |
|-------|------|-------------|-------------|
| `out_files` | struct | `finalize_config.m`, `call_environment_setup.m` | Struct holding all output file paths for the simulation run (see subfields below and [Output layout](#output-layout)); all built by `stormsim_paths.m` |
| `out_files.storm_and_prob_mass` | string | `call_environment_setup.m` | Full path to the project-level storm + prob_mass file `<project>/Event_Database/<db>.mat` |
| `out_files.chs_data` | string | `call_environment_setup.m` | Full path to the raw CHS_Data file `<project>/Event_Database/<db>_raw_files.mat` |
| `out_files.config` | string | `finalize_config.m` | Full path to the alternative's config file `<WF dir>/<db>_<wflow>_config_file.mat` |
| `out_files.resp_data` | string | `finalize_config.m` | Full path to the response data file `<WF dir>/<db>_<wflow>_project_responses.mat` |
| `out_files.project_forcing` | string | `finalize_config.m` | Full path to the project forcing file `<WF dir>/<db>_<wflow>_project_forcing.mat` |
| `tc_bias_corrected` | numeric | `db_info` | `1` if the TC SWL bias correction was applied when the storm database was built (`call_chs_storm_quality_check.m`: both CHS_Dependencies bias files present), else `0` (no TC, storm `.mat` input). Plots apply the same correction to raw CHS SWL (`StormsimPlotsBase`) |
| `chs_swl_b_a` | numeric | `db_info` | SWL absolute bias. Determined when the storm database is built (`storm_db_bias_uncertainty.m`: CHS_Dependencies circulation bias/uncertainty file at the study grid row of the grid point nearest to the savepoint coordinates (`sp_lat`/`sp_lon`; a distance above 0.5 m prints `Warning: Nearest grid point found was X m away. This is caused by using SP data.`, expected for the CHS-NA mesh-node grid); without coordinates (storm `.mat` input) the savepoint ID row, with a printed warning, and an error when that ID is not in the study grid (`storm_db_bias_uncertainty:spNotFound`, naming the file searched); a grid row beyond the bias file is `storm_db_bias_uncertainty:spNotFound` naming the row and both files; `Grid_Files/<region>` missing or empty is `storm_db_bias_uncertainty:gridNotFound`; else entered once). `call_chs_data_formater.m` passes it to `call_chs_storm_quality_check.m`, which applies the TC SWL bias correction with it |
| `chs_swl_b_r` | numeric | `db_info` | SWL proportional bias. Same source as `chs_swl_b_a` |
| `chs_swl_u_a` | numeric | `db_info` | SWL absolute uncertainty. Same source as `chs_swl_b_a` |
| `chs_swl_u_r` | numeric | `db_info` | SWL proportional uncertainty. Same source as `chs_swl_b_a` |
| `chs_hm0_b_a` | numeric | `db_info` | Hm0 absolute bias from the CHS_Dependencies wave file (global value, else the regional average `B_a_avg`; `[]` when not available; not prompted). Stored only: StormSim applies no Hm0 bias |
| `chs_hm0_b_r` | numeric | `db_info` | Hm0 proportional bias. Same as `chs_hm0_b_a` |
| `chs_hm0_u_a` | numeric | `db_info` | Hm0 absolute uncertainty (CHS_Dependencies wave file: global value, else the regional average `U_a_avg`; else entered once) |
| `chs_hm0_u_r` | numeric | `db_info` | Hm0 proportional uncertainty. Same source as `chs_hm0_u_a` |
| `chs_swl_bu_source` | string | `db_info` | Source of the SWL bias/uncertainty: `'chs_dependencies'`, `'manual'` (entered when the database was built; a rebuild keeps them) or `'provided'` (GUI wizard, Custom_Modeling storm data). Descriptive only: nothing is carried between runs (`resolve_hotstart_state.m` no longer touches these fields) |
| `chs_hm0_bu_source` | string | `db_info` | Same as `chs_swl_bu_source`, for the Hm0 values (replaces `chs_hm0_u_source`) |
| `offshore_elevation` | numeric | `db_info` | Overwritten by `storm_db_info('apply', ...)` with `db_info.offshore_elevation` when the storm database has a study grid value (see the Structure Geometry row in section 3); otherwise the config value is kept (input file row / GUI: PSE geometry) |
| `offshore_elevation_source` | string | `db_info` | `'Storm DB grid'` when `offshore_elevation` came from the storm database's study grid, `'config'` when the config fallback is used (input file row; GUI: PSE geometry). Shown next to the value in the PSE transect text box (`StormsimPlotsBase`; the GUI pop-out passes `'Storm DB: <db>'` / `'PSE geometry'`) |
| `storm_db_build_date` | string | `db_info` | The storm database's `db_info.build_date` (`'yyyy-mm-dd HH:MM:SS'`), applied by `storm_db_info('apply', ...)` (library and GUI `create_resp_config`). Hotstart: `deps.sampling`, so a database rebuilt since the cached run (by this or another PSE/alternative, e.g. first built with manual values and later with CHS_Dependencies) gives `resample` instead of reusing forcing made with the old database |
| `hotstart_level` | string | `resolve_hotstart_state.m` (called by `call_environment_setup.m`); `call_chs_data_formater.m` | How much of the cached run of the same case is reused: `'full'`, `'reuse_sampling'`, `'resample'` (from `hotstart_level.m`, see [Hotstart levels](#hotstart-levels)), or `'cold'` (no cache or unreadable cache; a different sp_ID/region means a different `<db>`, so no cache is found). Set to `'resample'` by `call_chs_data_formater.m` whenever it builds the storm database (fresh or rebuild), after `resolve_hotstart_state.m` ran, once every build step succeeded (right before the new `<db>.mat` is saved; a build that stops changes nothing): it deletes the case's project forcing and LCS sampling seed, resets `u_engine`/`f_adjust` and removes carried `tide_indx_tc`/`_xc`/`_cc` (a missing `<db>.mat` leaves no `storm_db_build_date` to compare when the level is decided), appended to the config file with the `db_info` fields. Read by `lcs_reference_reuse.m` (`'reuse_sampling'` rebuilds the LCS life cycles from the case's own sampling seed file). Not a hotstart dependency. GUI runs set it too: `'cold'` on a coldstart (or a first run), else the level of the Run dialog's "Hotstart" (`apply_hotstart_level.m`) |

### Storm database details (`db_info`)

`<db>.mat` holds `storm`, `prob_mass` and `db_info` (plain struct, `Setup/storm_db_info.m`, shared by the library and the GUI wizard): `tc_bias_corrected`, `chs_swl_b_a`/`_b_r`/`_u_a`/`_u_r`, `chs_swl_bu_source`, `chs_hm0_b_a`/`_b_r`/`_u_a`/`_u_r`, `chs_hm0_bu_source`, `offshore_elevation` (minus the depth of the study grid point nearest to the savepoint: elevation, positive up; `[]` when the grid has none or no grid was read), `offshore_elevation_source` (`'chs_dependencies'` or `''`), `grid_distance_m` (distance to that grid point [m]; `[]` when the savepoint ID was matched or no grid was read), `sp_lat`/`sp_lon` (savepoint coordinates, `[]` when not available), `Nyrs_XC`, `Nstm_XC` (`[]` without XC), `source_file` (input name + extension) and `build_date`. `storm_db_info('valid', ...)` does not require the offshore/location fields: a database without them uses the config `offshore_elevation` fallback. Writers: `call_chs_data_formater.m` (CHS input), `call_input_parser.m` (storm `.mat` input: `Nyrs_XC`/`Nstm_XC` move out of `storm.XC`, where `storm_validation.m` still requires them in the input file), the GUI wizard (`CHSStormDBImportUI.create_storm_database`). Every database load applies it to config (`storm_db_info('apply', db_info, config)`: every field above except `source_file` and the offshore/location fields; `offshore_elevation` only when not empty (the grid wins over the config fallback), with `offshore_elevation_source`; `build_date` as `storm_db_build_date`; `Nyrs_XC`/`Nstm_XC` only when not empty); the GUI does the same in `create_resp_config` (`dbObj.get_db_info()`). `storm.XC` no longer holds `Nyrs_XC`/`Nstm_XC`.

### Hotstart levels

On a rerun of the same project/struc_id/case_name, workflow and storm DB (`<db>`), `resolve_hotstart_state.m` compares the new config with the cached `*_config_file.mat` through `hotstart_plan.m` (`hotstart_level.m` plus the LCS sampling seed check below; no side effects) and acts on the level with `apply_hotstart_level.m`. Both helpers are shared with the GUI. The cached file is this run's own `out_files.config`, so the paths stored inside it are not compared: a moved or renamed project (or a relative `outfolder` resolved from another working folder) is reused by the same rules. A storm database built by `call_chs_data_formater.m` later in the same run (missing `<db>.mat`, or a rebuild) overrides the level with `resample` (see `hotstart_level` above); the forcing/seed deletion and the flag reset happen only once every build step succeeded, right before the new `<db>.mat` is saved, so a build that stops (storm file check, CHS_Dependencies, bias lookup, an aborted prompt) leaves the cache and the saved config untouched. A cache that fails to load, or lacks a field read here, runs cold (`hotstart_level = 'cold'`, `u_engine`/`f_adjust` = 0) after deleting only this run's project forcing and LCS sampling seed. The dependency lists live in `hotstart_cache_dependencies.m`; the first matching level wins:

| Level | Triggered by | What happens |
|-------|--------------|--------------|
| `resample` | `deps.sampling`: `mcs_nYears`, `mcs_nLC`, `lcs_restrict_sampling_rate`, `storm_db_build_date` (storm database rebuilt since the cached run). `deps.data_shape` when the cached run does not cover the request: `create_wlp`, `create_whp`, `use_timeseries` switched on, or `storm_sampling` asking for a storm type the cached run lacks (e.g. XC → CC); `use_peaks` switched on outside LCS. A cache holding more than requested still covers the request | Cached `project_forcing.mat` deleted, `u_engine`/`f_adjust` reset. LCS: the case's `*_sampling_seed.mat` is deleted too and new life cycles are drawn (convergence check runs as usual) |
| `reuse_sampling` | `deps.forcing_build`: `storm_duration`. `deps.f_adjust`: `apply_depth_limitation`, `apply_random_tides`, `tide_file`, `swl_slr`, `toe_elevation`, `wall_bottom_elevation`, `berm_crest_elevation`, `berm_seaward_slope`, `berm_crest_width`, `add_toe_berm`, `struc_type`. `deps.u_engine` (currently empty) | Cached `project_forcing.mat` deleted (it holds adjusted/perturbed values and is never used as a value source), `u_engine`/`f_adjust` reset, so adjustments and uncertainty are applied once to freshly built forcing. LCS keeps its sampled life cycles: `stormsim_lcs.m` rebuilds them from the case's own `*_sampling_seed.mat` (`sampled_ids`: storm IDs, intensity bin, simulation year, order, empty life cycles included), pulls TC values, Timeseries and TC WLP/WHP fresh from the storm database, keeps the sampled XC copula values (`xc_peaks.Default`, columns 5:8; storm duration rebuilt; XC WLP/WHP are copies of them) and keeps the effective sampling mode. No convergence check runs. With random tides on in both runs and the same `tide_file`, the cached run's tide start hours (`tide_indx_tc`/`_xc`) are kept; `tide_indx_cc` is derived from them, so the CC tides are kept too. A seed file that is missing or does not cover the request falls back to `resample` (logged) |
| `full` | Nothing above changed | Cached project forcing and `u_engine`/`f_adjust` reused. LCS also keeps the cached tide start hours in the saved config |

PROS (`workflow` 1, 4) and DET (2) have no random sampling: `reuse_sampling` and `resample` both rebuild their forcing from the storm database, as before. When `load_project_forcing = 1` and the reference case's forcing exists, the reference's storms take precedence over the case's own cached sampling. Each level prints a `Hotstart:` line naming the triggering field.

**GUI.** A saved simulation is keyed by alternative + workflow + Run-tab storm DB (`<DB>_<workflow>_config_file.mat` + `_project_responses.mat`). Pressing Run when one exists opens a dialog (Hotstart | Coldstart | Load existing | Cancel) that states the level from `hotstart_plan.m` and its reason field. A re-imported storm DB gives `resample` through the library's `storm_db_build_date` (`deps.sampling`; the GUI no longer records `storm_db_datenum`). The GUI-only inputs `region` and `chs_swl_u_a`/`_u_r`/`chs_hm0_u_a`/`_u_r` count as `resample`. Hotstart is hidden at `resample`, or when the cached forcing (`full`) or the sampling seed (LCS `reuse_sampling`) is missing; the dialog says why. Hotstart applies `apply_hotstart_level.m`. Coldstart deletes the cached project forcing and the LCS sampling seed, and sets `hotstart_level = 'cold'`. The GUI does not call `resolve_hotstart_state.m`: the level comes from the Run dialog. Both take bias/uncertainty from the storm DB's `db_info` on every run. A GUI run backs up the slot first (`backup_sim_files`: config copied to `*_prev.mat`; project forcing moved, except at `full`; LCS seed moved, copied at `reuse_sampling`, kept at `full`), deletes the backups once the results are saved and restores them if the run fails; backups left by a run that never finished are restored at the next run start. `resolve_hotstart_state.m` deletes no folders: a cache that fails to load runs cold after deleting only that run's project forcing and LCS sampling seed. The GUI LCS convergence dialog runs after the Run dialog, and only when life cycles are sampled (a coldstart, or a first run).

### Set by `stormsim_lcs.m` / `call_project_forcing_formater.m` (workflow = 3)

| Field | Type | Source File | Description |
|-------|------|-------------|-------------|
| `lcs_effective_sampling_rate` | logical | `stormsim_lcs.m` | LCS sampling mode the life cycles were actually sampled with: the configured `lcs_restrict_sampling_rate`, or the stored mode of the reused sampling (reference case, or the case's own cached sampling at hotstart level `reuse_sampling`). Stored in the case's `*_sampling_seed.mat` (as `lcs_restrict_sampling_rate`). When the cached project forcing is reused, `call_project_forcing_formater.m` reads it back from that file. Not a hotstart dependency (it is not in any `hotstart_cache_dependencies` list). Read through `lcs_sampling_mode.m`, which falls back to `lcs_restrict_sampling_rate` when the field is absent. Used by the mode-1 notices, the convergence-check skip and the sampling dashboard |
| `lcs_convergence_results` | struct | `stormsim_lcs.m` | Results of the LCS convergence check run before sampling, one field per checked storm type (`XC`, `TC`): the `lcs_convergence_checks.m` output (`lamN`, `cv`, `p0`, `zero_pct`, `nLC_mean`, `nLC_pct`, `nLC_req`, `nLC`, `nLC_cap`, `converged`, `stm_type`, `rate`). Empty struct when no check ran (effective mode 1, or every storm type reused from the reference or from the case's own cached sampling). Absent when the cached project forcing is reused (`stormsim_lcs.m` does not run). Saved with the config. Read by panel 6 of `lcs_methods.sampling_scheme_dashboard`, which falls back to computing the check when the storm type's field is absent. Not a hotstart dependency |

The following fields are **overridden** at runtime by `call_environment_setup.m` based on structure type and configuration logic:

| Field | Override Condition | Effect |
|-------|--------------------|--------|
| `berm_elevation` | `add_berm == 0` | Set to `toe_elevation` (Types 1,3,4) or `wall_bottom_elevation` (Type 2) |
| `toe_elevation` | Type 2 and `add_berm == 0` | Set to `wall_bottom_elevation` |
| `berm_slope` | `add_berm == 0` | Forced to `0` |
| `berm_width` | `add_berm == 0` | Forced to `0` |
| `compute_q` | `compute_nappe == 1` | Forced to `1` (nappe computation requires q) |
| `create_wlp` | `use_peaks` or `use_timeseries` is `0` | Forced to `0` |
| `create_whp` | `use_peaks` or `use_timeseries` is `0` | Forced to `0` |
| `storm_sampling` | TC/CC without CHS_Dependencies for the region | Not forced: the run stops in `call_input_parser.m`, and again in `call_chs_data_formater.m` if a storm database build would drop TC (same message, `chs_dependencies_message.m`; StormSim runs XC only without CHS_Dependencies) |
| `pros_compute_forcing_HC` | `workflow == 4` or nappe/P2P3 requested | Forced to `1` |
| `compute_q_vol` | `workflow == 4` | Forced to `0` (cannot integrate q hazard curve in FB mode) |

### `call_chs_storm_quality_check.m`'s role

This function does **not set** `chs_swl_b_a`, `chs_swl_b_r`, `chs_swl_u_a`, or `chs_swl_u_r`: they come from `db_info` (see table above; `call_chs_data_formater.m` passes the database's bias to it). `call_chs_storm_quality_check.m` is a **consumer**: it reads `chs_swl_b_a`/`chs_swl_b_r` and applies the bias correction formula to TC storm SWL values; it sets `tc_bias_corrected`, stored in `db_info`.

---

> **Note:** The authoritative schema for user-configurable fields is the `CHESS_*_inputs.xlsx` Excel input files (`Model Variable Symbol` column). This document is derived from `StormSim_Library` source code and the four Excel input files (levee, floodwall, rubblemound, low-crested breakwater).

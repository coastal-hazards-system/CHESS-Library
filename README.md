NOTE TO ALL: CHESS (Coastal Hazards, Engineering and Structures System) is in active development. Current release: **v2.0.0**. Make sure to check for version updates.


![CHESS logo](CHESS_Library/GUI/CHESS_logo_NOAA_white-outline.png)
## 👋 Welcome
Thank you for your interest in CHG's probabilistic tool suite, the Coastal Hazards, Engineering and Structures System (CHESS) library (CHESS-Library), formerly StormSim. Version 2.0.0 is a major release: the library was renamed to CHESS and now ships with the CHESS GUI, a deterministic workflow, multi-line transects and a class-based plotting library. A few reminders:

🚀 Passion Project: The entire development of this tool suite has been without a direct source of funding. Your enthusiasm and engagement make it all worthwhile!

🧪 Active Development: While we've put the existing tools through extensive testing, CHESS is still in active development. Bugs might pop up based on inputs or application, but fear not—we're here to tackle them head-on.

🗺️ Limited Data Landscape: Currently, we're working with CHS native data, but don't let that hold you back! Custom modeling is absolutely supported; it just requires a little one-on-one setup. Let's make it happen together.

🤝 Your Input Matters: We value your feedback on various aspects—whether it's about the ease of use, missing physics or responses, data visualizations, or post-processing computations. Your insights help us shape this tool into something extraordinary.

## CHESS External Dependencies 
### 1. Coastal Hazard System (CHS) regional study modeling results (https://chs.erdc.dren.mil)
CHS is a unique data resource that spans probability space, was developed with high-fidelity modeling, is spatially uniform and dense on a national scale, and includes aleatory and epistemic uncertainty information necessary for determining probabilistic responses. Modeling results are reported through save points across regional studies. Save points include modeling results for both circulation (ADCIRC) and wave models (STWAVE/WAM/SWAN). Additionally, results hosted on CHS include different Sea Level Rise (SLR) scenarios and tidal conditions for tropical (TC) and/or extra-tropical (XC) events. Currently, CHESS supports the use of Base Conditions modeling results (peaks and timeseries) for the following regional studies: CHS-NACCS, CHS-SACS, and FEMA RiskMap studies. The CHS regional study statistical results that CHESS needs for tropical storms (discrete storm weights, SWL bias and uncertainty) and the savepoint offshore elevations come in the CHS_Dependencies folder; see [Getting Started](https://github.com/Coastal-Hazards-System/CHESS-Library/wiki/Getting-Started).

![image](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/df664577-5593-4410-99c1-b967f68ba59f)

The following figure summarizes the CHS data download process; 1) choose a regional study, 2) apply the **Base Modeling** filter, 3). Through CHS, you can choose the most suitable save point for your project. When selecting project-forcing data, consider the hazards you want to include (XC vs TC vs both) and the level of fidelity (Peaks vs Timeseries vs both). Currently, CHESS only supports base modeling conditions as a forcing input. Utilizing CHS data means any analysis will involve the full storm suite for a given regional study. The downloaded zip folder must contain Peaks and/or Timeseries files for both models associated with a savepoint (ADCIRC + Wave Model). For a more detailed guide on accessing and navigating CHS files/website, visit (https://chs.erdc.dren.mil/Content/documents/CHSQuickGuide.pdf).

<p align="center" width="100%">
    <img width="100%" src="https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/f8f5a12f-3e75-44bd-a6b5-e7af0845a877">
</p>

### 2. Tidal prediction file
File can be created with the GUI (Tides window) or by running "create_tide_file.m" (CHESS_Library/External_API/NOAA_COOPS) with a NOAA harmonic tide prediction station ID, a datum and a start date: one year of hourly predictions. Harmonic stations can be found at: https://tidesandcurrents.noaa.gov/tide_predictions.html (subordinate stations are not supported). File must be a 2 column csv file with headers [Date, Prediction [m]]. 

## Getting Started  
Project conceptualization within the CHESS library is achived through 4 main components: 1) configuration file, 2) Protective System Elements (PSEs), 3) wave and water level storm forcing events, and 4) associated parameter aleatory and epistemic uncertainty. The configuration file holds project details, identifies directory paths to the other three components, and governs toolkit behavior. PSEs represent 1-D coastal structure transects. Storm forcing and associated uncertainties are downloaded from CHS as spatially distributed data containing peak and time series files.

![image](https://github.com/Coastal-Hazards-System/StormSim-Library/assets/51959561/09ff69a1-ba3b-4214-a6d3-4b63ab608b32)

### Available CHESS Modules
The CHESS_Usage_Example.m script (or the CHESS GUI, launched with CHESS_UI_Call.m) provided with the CHESS library allows the seamless execution of several computational modules. Hosted modules include:
#### 1. CHESS: Probabilistic Responses  Of Structures (PROS)
CHESS-PROS probabilistically estimates structure response hazards using response-based methods. Coastal structure responses include floodwall, levee, and rubble mound overtopping and volume discharge, levee and rubble mound runup, floodwall hydrodynamic and hydrostatic pressures, and rubble mound stone stability. CHESS is a component of the Coastal Hazards System (CHS https://chs.erdc.dren.mil/, Nadal-Caraballo et al. 2020) which is a national-scale initiative to quantify coastal storm hazards. Results from high-fidelity, physics-informed numerical modeling of coastal storm events spanning the practical probability space for the U.S. coastline are stored on an online database (CHS-DB). Synthetic TCs and XCs were modeled in a high-fidelity coupled hydrodynamic framework (Massey et al. 2012) for regional studies to produce coastal wave and water level responses. This was completed for multiple sea level rise conditions. Discrete storm weights (DSW) define TC storm probability and are used to estimate hazards. Both peak and timeseries values are available. CHESS can evaluate responses over entire timeseries within a probabilistic framework with relatively small computational costs. Tides can be either randomly sampled, applied as uncertainty, or applied as a skew tide to account for nonlinearities. Structure responses are computed for hundreds of thousands of storm realizations following the CHESS-JPM and CHESS-PST workflows. Exceedance probabilities of the structure responses themselves are estimated. CHESS-PROS maintains the high fidelity multivariate statistical and physical interdependencies between storm forcing parameters without assuming identical probabilities of forcing parameters and structure responses (Stehno and Melby, in review). Epistemic uncertainties associated with storm response and empirical equations are applied as confidence limits to the BE response hazards. Results from CHESS-PROS are used for coastal structure designs when designs require non-exceedance of a structure response hazard at a given probability.
#### 2. CHESS: Life Cycle Simulation (LCS)
CHESS-LCS computes time-dependent stochastic analysis of coastal structure responses. Current coastal structure responses include dune and beach morphology and rubble mound armor stone damage progression. CHESS is a component of the Coastal Hazards System (CHS https://chs.erdc.dren.mil/, Nadal-Caraballo et al. 2020) which is a national-scale initiative to quantify coastal storm hazards. Results from high-fidelity, physics-informed numerical modeling of coastal storm events spanning the practical probability space for the U.S. coastline are stored on an online database (CHS-DB). Synthetic TCs and XCs were modeled in a high-fidelity coupled hydrodynamic framework (Massey et al. 2012) for regional studies to produce coastal wave and water level responses. This was completed for multiple sea level rise conditions. Discrete storm weights (DSW) define TC storm probability and are used to estimate hazards. Both peak and timeseries values are available. CHESS can evaluate responses over entire timeseries within a probabilistic framework with relatively small computational costs. Tides can be either randomly sampled, applied as uncertainty, or applied as a skew tide to account for nonlinearities. Life cycles are generated from sampled storms, sampled using a Poisson distribution to create a life cycle reflective of the larger population of storm intensities and associated probabilities at the study location. TCs are sampled using DSWs and XCs are sampled either historically or from stochastic simulation using bivariate or multivariate Gaussian copulas. Storms may also be sampled by binning storms by intensity prior to sampling, then sampling from intensity bins to represent storm intensity probabilities more accurately throughout the entire life cycle. Aleatory uncertainties are accounted by stochastically creating hundreds of life cycles, which also ensure statistical convergence. Structure life-cycle responses can be used to estimate statistical structure reliability and performance. 
#### 3. CHESS: Probabilistic Simulation Technique (PST)
CHESS-PST estimates extra-tropical cyclone (XC) storm response hazards. CHESS is a component of the Coastal Hazards System (CHS https://chs.erdc.dren.mil/, Nadal-Caraballo et al. 2020) which is a national-scale initiative to quantify coastal storm hazards. Results from high-fidelity, physics-informed numerical modeling of coastal storm events spanning the practical probability space for the U.S. coastline are stored on an online database (CHS-DB). Historical XCs were modeled in a high-fidelity coupled hydrodynamic framework (Massey et al. 2012) for regional studies to produce coastal wave and water level responses. This was completed for multiple sea level rise conditions. Both peak and timeseries values are available. CHESS can evaluate responses over entire timeseries within a probabilistic framework with relatively small computational costs. Tides can be either randomly sampled, applied as uncertainty, or applied as a skew tide to account for nonlinearities. CHESS-PST ingests modeled historical storm responses. Responses are bootstrapped sampled, including aleatory uncertainty, to encompass multiple sequences or life cycles of storm responses. Peaks-over-threshold is used to identify extreme events from sampling. These extreme events are fit to a generalized Pareto distribution (GPD), which captures the low-frequency tail of response hazards. See [CHESS PST](https://github.com/Coastal-Hazards-System/CHESS-Library/wiki/CHESS-PST).
#### 4. CHESS: Joint Probability Method (JPM)
CHESS-JPM estimates tropical cyclone (TC) storm response hazards (Nadal-Caraballo and Melby 2014). CHESS is a component of the Coastal Hazards System (CHS https://chs.erdc.dren.mil/, Nadal-Caraballo et al. 2020) which is a national-scale initiative to quantify coastal storm hazards. Results from high-fidelity, physics-informed numerical modeling of coastal storm events spanning the practical probability space for the U.S. coastline are stored on an online database (CHS-DB). Synthetic TCs were modeled in a high-fidelity coupled hydrodynamic framework (Massey et al. 2012) for regional studies to produce coastal wave and water level responses. This was completed for multiple sea level rise conditions. Discrete storm weights (DSW) define TC storm probability and are used to estimate hazards. Both peak and timeseries values are available. CHESS can evaluate responses over entire timeseries within a probabilistic framework with relatively small computational costs. Tides can be either randomly sampled, applied as uncertainty, or applied as a skew tide to account for nonlinearities. TC responses, such as waves and water levels, are ingested into CHESS-JPM, aleatory uncertainty is applied to these storm responses using hundreds of thousands of storms, and associated DSWs are used to estimate best-estimate (BE) exceedance probabilities. Confidence limits are computed by applying epistemic uncertainties to BE hazard curves. Additional details about coastal storm uncertainties are in Gonzalez et al. (2019).

## CHESS Input File (config)
The CHESS-Library is fully controlled trhough the configuration file (CHESS_<structure>_inputs.xlsx). The following section will cover all items in the input file. 
1. CHESS Project General Inputs
   *
3. CHESS Project Foricng Data
4. Structure Geometry
5. Structure Properties
6. CHESS Project Forcing Uncertainty
7. CHESS Project Structure Response Uncertainty
8. CHESS Module Specific 
 
## Project Folder Structure (Outputs)
CHESS keeps track of all project files by storing outputs in one folder hierarchy (defined in `chess_paths.m`, shared by the library and the GUI):

```
<outfolder>\<project_name>\
    Event_Database\
        <db>.mat                 storm database (storm, prob_mass, db_info)
        <db>_raw_files.mat       converted CHS files (CHS_Data)
    PSE\<struc_id>\<case_name>\<PROS|DET|LCS>\
        <db>_<workflow>_config_file.mat
        <db>_<workflow>_project_forcing.mat
        <db>_<workflow>_project_responses.mat
```

- `<db>` is the storm database name (by default `<region>_SP<sp_ID>`, e.g. `CHS-NA_SP5572`). Storm databases sit at project level and are shared by every PSE and alternative.
- `<struc_id>` is the PSE (Protective System Element, a 1-D structure transect) and `<case_name>` the alternative being evaluated for it.
- `<workflow>` is `PROS-RB`, `DET`, `LCS` or `PROS-FB` (workflows 1-4). PROS-RB and PROS-FB share the `PROS` folder.

Every run file of an alternative starts with `<db>_<workflow>`, so runs with different storm databases never share a file. The files serve as checkpoints (hotstart): when iterating alternatives, CHESS reuses whatever stage is still valid instead of recomputing it.

## Project Files (Outputs)
Storm data are sorted by storm type (`TC`, `XC`), data type (`Peaks`, `Timeseries`) and matching type (`Default`, `WLP` water level priority, `WHP` wave height priority); e.g. `storm.XC.Peaks.Default`.

1. `Event_Database\<db>_raw_files.mat`: created by `call_chs_data_formatter.m`. Raw CHS files converted with CHESS's native CHS h5 converter (storm data, attributes, headers and units). Variable: `CHS_Data`.
2. `Event_Database\<db>.mat`: created by `call_chs_data_formatter.m` (or the GUI storm database wizard). Processed CHS data and the TC storm probability masses. Processing includes ADCIRC/wave model storm matching, hydrograph QA/QC (time step matching and correction) and removal of incomplete/bad storms. Variables: `storm`, `prob_mass`, `db_info`.
3. `<db>_<workflow>_config_file.mat`: the parsed configuration (`call_input_parser.m`, completed by `call_environment_setup.m`), including the structure geometry. Config is the central schema of the CHESS library.
4. `<db>_<workflow>_project_forcing.mat`: created by `call_chess_boundary_conditions.m`. The workflow's project forcing: storm replicates for PROS/DET, sampled life cycles for LCS, with the forcing adjustments (SLR, tides, depth limitation) and uncertainty applied. Variable: `project_forcing`.
5. `<db>_<workflow>_project_responses.mat`: created by `call_project_response.m`. The structure responses computed for the workflow.

## Bug Reporting 
Create an issue with the following information:
* Error message print out in the command window (red text).
* Input file (config)
* CHS SP Lat, Lon, ADCIRC SP ID, STWAVE SP ID

## Feedback/Ideas 
Please feel free to use this space to communicate any feedback/ideas. Any idea that needs further discussion (potential SoN) can be transitioned to a Discussion item on the repo.

## References
- [1] Gonzalez, Nadal-Caraballo, Melby, Cialone, (2019). Quantification of uncertainty in probabilistic storm surge models: Literature review. ERDC/CHL SR-19-1. Vicksburg, MS: U.S. Army Engineer Research and Development Center. 
- [2] Massey, Wamsley, and Cialone (2012): Coastal Storm Modeling – System Integration. In Proceedings of Solutions to Coastal Disasters Conference 2011, pp. 99–108.
- [3] Nadal-Caraballo, Melby, (2014). North Atlantic Coast Comprehensive Study Phase 1: statistical analysis of historical extreme water levels with sea level change. Technical Report ERDC/CHL TR-14-7, US Army Engineer R&D Center, Vicksburg, MS. 
- [4] Nadal-Caraballo, Campbell, Gonzalez, Torres, Melby, Taflanidis, (2020). Coastal Hazards System: A Probabilistic Coastal Hazard Analysis Framework. In: Malvárez, G. and Navas, F. eds., Global Coastal Issues of 2020. Journal of Coastal Research, Special Issue No. 95, pp. 1211-1216. 
- [5] Stehno, Melby (in review). Practical coastal structure stochastic response simulation using multi-variate hazards. Coastal Engineering (In review). 



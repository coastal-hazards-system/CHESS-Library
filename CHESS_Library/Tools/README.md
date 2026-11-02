# Tools

Stand-alone utilities and generators. Not used by the CHESS workflows; kept off the path by `chess_setup_path.m`. Add a tool's folder to the path yourself to run it.

- `normal_curve_discretizer.m` - discretizes a normal curve into a given number of samples (no callers in the library).
- `main_storm_duration.m` - example driver for the storm-duration functions (the library uses `Forcing_Generation/Storm_Duration/estimate_storm_durations.m`).
- `plot_storm_duration.m` - plot helper called only by `main_storm_duration.m`.

# Tools

Stand-alone utilities and generators. Not used by the CHESS workflows; kept off the path by `chess_setup_path.m`. Add a tool's folder to the path yourself to run it.

- `normal_curve_discretizer.m` - discretizes a normal curve into a given number of samples (no callers in the library).
- `main_storm_duration.m` - example driver for the storm-duration functions (the library function is `chess.BoundaryConditions.storm_duration`).
- `plot_storm_duration.m` - plot helper called only by `main_storm_duration.m`.
- `convert_v2_project/` - one-time conversion of a v2.0.0 GUI project file (`chessProject` object) to the `chess.Project` format; see its README.md. Holds the class `chessProject`, which must stay off the normal path.

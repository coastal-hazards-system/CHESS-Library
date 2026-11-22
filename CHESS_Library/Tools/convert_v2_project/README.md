# convert_v2_project

One-time conversion of a project file written by the v2.0.0 CHESS GUI to the `chess.Project` format.

The v2.0.0 GUI saved `CHESS_project_<name>.mat` with a `chessProject` object (variable `chess_project`). The library and the GUI now read only the `chess.Project` format; `chess.Project.open` refuses an old file with the error `chess:Project:oldProjectFormat`. Convert each old project once:

```matlab
addpath('CHESS_Library'); chess_setup_path;
addpath('CHESS_Library/Tools/convert_v2_project');
convert_v2_project('D:\Projects\My_Project');   % project folder, or its CHESS_project_<name>.mat
project = chess.Project.open('D:\Projects\My_Project');
```

What it does on disk:

- copies the original file, unchanged, to `CHESS_project_<name>_before_conversion.mat` (if that file already exists the tool stops with an error and writes nothing);
- overwrites `CHESS_project_<name>.mat` with the converted project (PSEs, alternatives and their inputs, multi-line stages, runs, storm database records, tide files, CHS_Dependencies folder; paths under the old project folder point into the folder the file is in now).

Nothing else in the project folder is touched. The converted file cannot be opened by the v2.0.0 GUI; keep the backup if you still need it there.

Notes:

- Alternative inputs are kept as saved. Alternatives whose inputs do not build their structure with this CHESS version (for example an input added after v2.0.0, such as `nearshore_slope`) are listed in the warning `convert_v2_project:incompleteInputs`; complete them (GUI PSE Viewer table or `chess.Project.set_inputs`) before running them.
- The stage 1 alternative of a multi-line PSE is placed first in that PSE.
- Files that hold their storm databases as import window objects (older than storm database records) are not converted.
- `chessProject.m` exists only so MATLAB can load the old object. The tool puts this folder on the path only while it runs; `chess_setup_path` never adds it (`Tools` folders are kept off the path).

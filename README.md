# Hack my ride

- The `data` directory is needed to run the code in `index.ipynb` which must contain the 13 `json` files. Since `data` is contains large files therefore, it is added to `.gitignore`.

## Changelog

All notable changes to this project will be documented in this file.

## 1.0.1 - 2022-11-06
### Added
- Restructured `Scripts/json_to_csv.py` to be used as recursive utility in `index.ipynb`.
- Added the functionality to merge all the CSV files into single file `~717 MB`.


## 1.0.2 - 2022-11-21
### Modified `index.py`
- Preprocessed the GTFS23Sep files individually.
- Merged the files on common fields and exported final `csv` file as `data/gtfs23sep/gtfs_23_merged.csv`.
- Preprocessing involves removing redundant fields, getting rid of duplicate rows/columns, and merging bitmap fields where necessary.
- Note: Because the processing files are huge than `100 MB` that's why they are not being tracked on git.


## 1.0.3 - 2022-11-23
### Modified `index.py`
- Preprocessed the `gps_track.csv` and produced `gps_track_processed.csv`.
- Dropped `NA` and reformated time.

# Study CDISCPILOT01: workshop project

This project builds ADSL in SAS, moves it to R, checks it against the define.xml, and builds TLFs in R. The data is the CDISC pilot study.

## Layout

- `data/sdtm/`: SDTM data as SAS transport files (.xpt). Read-only.
- `data/adam/`: ADSL from SAS (`adsl.sas7bdat`) and its parquet copy for R (`adsl.parquet`).
- `data/submission/`: the submission folder: `datasets/` (.xpt) and `programs/` (programs as .txt).
- `data/reference/adsl.xpt`: the ADSL from the original CDISC pilot, made in SAS. Use it for comparison only.
- `metadata/ADaM_define_CDISC_pilot3.xml`: the study spec (define.xml).
- `programs/sas/`: SAS programs and their logs. `adsl.sas` is the study ADSL program.
- `programs/r/`: R programs.
- `trusted/`: approved company code. Use these functions before writing your own. Do not edit this folder.
- `sop/`: company procedures written for people.
- `output/tables/`: TLF outputs (HTML and RTF).
- `commons_app/`: the {commons} review app.

If `data/sdtm/` is empty, run `source("setup_data.R")`. If a package is missing, run `source("check_packages.R")`.

## SAS

SAS runs in the Positron console session "SAS (workshop-sas)", not in the terminal. Set the SAS working folder to this project folder first. The study-standards skill has the details.

## Data trail

`data/sdtm/*.xpt` -> `programs/sas/adsl.sas` (SAS) -> `data/adam/adsl.sas7bdat` -> R -> `data/adam/adsl.parquet` -> define.xml check, TLFs, {commons} app -> `data/submission/datasets/adsl.xpt` + programs as .txt in `data/submission/programs/`.

## Rules

- For any programming task in this project, load the `study-standards` skill.
- Report findings; the programmer decides. Never call an output validated or final.
- Keep answers short and say which file or function produced each result.

# Agentic AI in Clinical Programming: Separating Hype from Production-Ready Practice in SAS, R and Python

## Slides: https://pub.current.posit.team/public/Agentic_AI_in_Clinical_Programming_Phuse_EU_2026/

A hands-on workshop in Positron and Posit Workbench. You work with Posit Assistant (agent) to build ADSL in SAS from a study SAS program and read its log, move the data to R, check ADSL against the study's define.xml, build TLFs in R with AI skills, and get answers from approved code in a {commons} Shiny app.

## Start here

1. In Positron, clone this repository (New Folder from Git) and trust the folder.
2. Run `source("check_packages.R")`.
3. Run `source("setup_data.R")`.
4. Run `source("create_workshop_docs.R")`, then open `01_adsl.qmd`.
5. Start a SAS console session ("SAS (workshop-sas)") from the console picker in the top right of Positron.

## What's in each folder

- `.posit/assistant/skills/study-standards/`: the project skill (company programming standards for SAS and R).
- `AGENTS.md`: project notes Posit Assistant (agent) reads first.
- `programs/sas/`: the study ADSL program in SAS (`adsl.sas`).
- `programs/r/`: where R programs go.
- `programs/python/`: empty at the start. In the optional Python step, Posit Assistant (agent) writes the same demographics table in Python (polars and Great Tables), read from the same parquet file.
- `trusted/`: approved company code: the spec check and the review measures.
- `sop/`: a table SOP you turn into your own skill.
- `commons_app/`: the {commons} review app. Run `shiny::runApp("commons_app")`.
- `loop/`: the check-and-explain loop in your own R code with {ellmer}. Run `source("loop/ellmer_check.R")`.
- `data/`: SDTM (`data/sdtm/`, downloaded by `setup_data.R`), ADSL (`data/adam/`) and the data-fix script.
- `metadata/`: the study define.xml (copied by `setup_data.R`).

## Data trail

`data/sdtm/*.xpt` -> `programs/sas/adsl.sas` (SAS) -> `data/adam/adsl.sas7bdat` -> R -> `data/adam/adsl.parquet` -> define.xml check, TLFs, {commons} -> `data/submission/` (datasets/adsl.xpt, programs/adsl-sas.txt, programs/t_dm-r.txt)

## Data

CDISC pilot study (CDISCPILOT01) SDTM and ADaM files from the PHUSE Test Data Factory, https://github.com/phuse-org/phuse-scripts (MIT license). The define.xml ships with the {metacore} package.

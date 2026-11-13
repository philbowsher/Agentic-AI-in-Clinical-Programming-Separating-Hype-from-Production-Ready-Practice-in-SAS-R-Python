---
name: study-standards
description: Company statistical programming standards for study CDISCPILOT01. Use for any task in this project that reads study data, writes or runs a SAS program, derives an ADaM dataset, moves data from SAS to R, checks a dataset against the define.xml, builds a TLF, or writes R code for the study.
---

# Study programming standards (example company standard v2.0, SAS + R)

This study uses SAS for the data steps (SDTM review and ADaM) and R for everything after ADSL is built (spec check, TLFs, review app, submission export).

## Approved tools

- SAS: Base SAS and PROC SORT, SQL, FREQ, MEANS, CONTENTS, PRINT, PRINTTO.
- R: dplyr, tidyr, stringr, lubridate, haven, duckdb, DBI, metacore, xportr, pointblank, gt, gtsummary, cards, shiny, bslib, and the functions in `trusted/`.
- Python: polars and great_tables. Python reads `data/adam/adsl.parquet` with `polars.read_parquet()`. Save Python programs in `programs/python/<name>.py`, run them from the project folder, and write tables to `output/tables/`. Follow the same table standards as R. Python's `round()` rounds half to even, so for display values round half away from zero with `decimal.Decimal(...).quantize(..., rounding=ROUND_HALF_UP)`.
- If something else seems needed, stop and ask.

## The data trail (every step uses the previous step's output)

1. `data/sdtm/<domain>.xpt`: SDTM as delivered by data management (SAS transport files).
2. `programs/sas/adsl.sas` (SAS) reads `data/sdtm/` and writes `data/adam/adsl.sas7bdat`. Its log goes to `programs/sas/adsl.log`.
3. R reads `data/adam/adsl.sas7bdat` and saves `data/adam/adsl.parquet`. This is where the work moves from SAS to R.
4. The define.xml check, the TLFs and the {commons} app all read `data/adam/adsl.parquet`.
5. `data/submission/datasets/adsl.xpt` is exported from `data/adam/adsl.parquet`.
6. The submission folder `data/submission/` holds the datasets and the programs as text files, the way a hybrid SAS + R submission is sent to a regulatory agency.

Always tell the programmer which file you read, where you wrote the code, and which file you wrote.

## Running SAS

- SAS runs in the Positron console session named "SAS (workshop-sas)". Send SAS code to that console. There is no `sas` command in the terminal, so do not look for one.
- The SAS server shares the home folder with Positron, but not `/tmp`. Keep every SAS file inside the project folder.
- Before every SAS run, set the SAS working folder to the project folder, so the relative paths in the programs work. The SAS session can restart on its own and then starts in its WORK folder again:
  `data _null_; rc = dlgcdir("<full path of the project folder>"); put rc=; run;`
- If a SAS step fails with "Physical file does not exist" or a missing libref, the SAS session has most likely restarted. Set the working folder again, re-run the step, and tell the programmer that the session restarted.
- The SAS session's page size is only 21 lines, so PROC FREQ crosstabs fail with "ERROR: Insufficient page size to print frequency table". Start every SAS program that prints output with `options pagesize=max linesize=max;`.
- Save SAS programs in `programs/sas/<name>.sas`. SAS work lives in .sas files and their logs, not in Quarto documents. Explain SAS results in the chat.
- Run a program with its log saved to a file:
  `proc printto log="programs/sas/<name>.log" new; run; %include "programs/sas/<name>.sas"; proc printto; run;`
- Then read the log file and report: any ERROR or WARNING lines (quote them), the number of observations and variables of each dataset written to `data/adam/`, and any NOTE about uninitialized variables or merge issues. A program is not done until its log is clean or every message is explained.
- Read SDTM transport files with the XPORT engine, one file at a time:
  `libname xdm xport "data/sdtm/dm.xpt"; data dm; set xdm.dm; run; libname xdm clear;`
- Use `options validvarname=upcase;` so variable names match the define.xml.
- SAS cannot write parquet here. Save ADaM datasets from SAS as `data/adam/<name>.sas7bdat` and let R make the parquet copy.

## Reviewing the SDTM data

- When asked to review SDTM in SAS, write `programs/sas/review_sdtm.sas` (PROC CONTENTS and PROC FREQ on the domains asked for), run it, and summarize in the chat what you found: records, subjects, key variables, anything unusual.

## Understanding and fixing the SAS ADSL program

- When asked what a SAS program does, describe it step by step for the programmer who will review it: the input datasets, each derived variable (source and rule), and the output. Explain it in the chat.
- If the SAS logic disagrees with the define.xml (`metadata/ADaM_define_CDISC_pilot3.xml`), list each difference, but do not change the program unless the programmer asks.
- When asked to fix a failure, change only `programs/sas/adsl.sas`, with a short comment on each changed line naming the define.xml rule. Re-run it (it rewrites `data/adam/adsl.sas7bdat`), read the log, repeat step 3 of the data trail, re-run the check, and say what changed. The program is under git, so the programmer can see every change in the diff.

## Moving ADSL from SAS to R

- Read `data/adam/adsl.sas7bdat` with `haven::read_sas()`, then save it to `data/adam/adsl.parquet` with duckdb (`COPY ... TO ... (FORMAT parquet)`), and read it back to confirm the row count.
- R code that uses ADSL reads `data/adam/adsl.parquet` with duckdb (`SELECT * FROM read_parquet('data/adam/adsl.parquet')`).
- Before the first duckdb connection in a session, run `dir.create("~/.duckdb", showWarnings = FALSE)`. Without the folder, duckdb asks "create ~/.duckdb? (Yes/no/cancel)" in the console and the console waits for a typed answer. If the console is already stuck on that question, stop and ask the programmer to type `Yes` in the console. Do not run more code until they have.

## Checking a dataset against the spec

- Use the approved check: `source("trusted/spec_check.R")`, then `check_adsl(adsl)`, with `adsl` read from `data/adam/adsl.parquet`. Print the result so the report opens in the Viewer.
- Summarize each failing rule in one line with the number of records that fail.
- Never edit `trusted/`, never loosen a rule, and never drop a failing rule to make the check pass. Fixes go in the SAS program.

## Exporting for submission

- Write submission datasets to `data/submission/datasets/<name>.xpt` with {xportr}, using the define.xml (read with {metacore}) for types, lengths, labels, order and formats. File names must be 8 characters or fewer, for example `adsl.xpt`. In the installed {xportr}, `xportr_write()` takes `path`, `metadata`, `domain` and `strict_checks`; it has no `label` argument.
- The define.xml holds several datasets. Read it with `metacore::define_to_metacore()`, then keep only ADSL with `metacore::select_dataset(mc, "ADSL")` before any xportr call. If you pass the full object, labels are silently missing for some variables.
- Export only the variables that the define.xml lists for ADSL. `programs/sas/adsl.sas` carries extra DM columns through (for example DOMAIN, ARMCD, COUNTRY). Drop them and name them in the chat. Expect 254 rows and 22 variables after the fix in SAS.

## Building the submission folder

When asked to build the submission folder:

1. Regulatory agencies ask for program source code as plain text files (single-byte ASCII). Copy each program into `data/submission/programs/`, renamed to `.txt` with its language in the name: `programs/sas/adsl.sas` becomes `adsl-sas.txt`, and an R program `programs/r/t_dm.R` becomes `t_dm-r.txt`.
2. The TLF program must exist as its own file. If the demographics TLF code is only in `02_tlf.qmd`, save it first as `programs/r/t_dm.R` (it reads `data/adam/adsl.parquet` and writes to `output/tables/`), and run it in a fresh R session to confirm it works on its own.
3. Check that every `.txt` file is plain ASCII. If a file has other characters, list the lines and ask before changing them.
4. Make sure `data/submission/datasets/adsl.xpt` exists (see Exporting for submission).
5. Report the folder tree and, for each file, which program or step made it.

## Quarto documents

- Each Quarto document must render on its own in a fresh R session. Load data from files (data/adam/), never from objects that only exist in the console.
- Before rendering or publishing 02_tlf.qmd, make sure data/adam/adsl.parquet exists.

## Skills

- A skill that is installed or created during a chat loads in the next chat. After installing or creating one, tell the programmer to start a new Posit Assistant chat. Until then, read the skill's SKILL.md directly and follow it.

## Never

- Never edit `data/sdtm/` or `trusted/`.
- Never edit `programs/sas/adsl.sas` unless the programmer asks for a fix.
- Never call an output validated, final or submission-ready.

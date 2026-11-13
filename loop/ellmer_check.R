# The check-and-explain loop in your own R code, with {ellmer}.
# Run: source("loop/ellmer_check.R")
#
# The model cannot read files or data by itself. It only knows what its tools
# return. With only the rule summary, it guessed the cause of the ARM failures
# (a "mapping problem") and was wrong. So it gets three small tools:
#   1. run_adsl_check:      the approved define.xml check (trusted/spec_check.R)
#   2. show_failing_values: the values in the records that fail one rule
#   3. read_sas_program:    the text of programs/sas/adsl.sas
# The data stays in this R session; only short text goes to the model.

library(ellmer)
source("trusted/spec_check.R")

con <- DBI::dbConnect(duckdb::duckdb())
adsl <- DBI::dbGetQuery(con, "SELECT * FROM read_parquet('data/adam/adsl.parquet')")
DBI::dbDisconnect(con, shutdown = TRUE)

agent <- qc_spec_agent(adsl, dataset = "ADSL") |>
  qc_adsl_derivations(adsl) |>
  pointblank::interrogate(progress = FALSE, extract_failed = TRUE)
summ <- qc_agent_summary(agent)

run_adsl_check <- tool(
  function() {
    failing <- summ[summ$status != "PASS", ]
    if (nrow(failing) == 0) return("All rules pass.")
    paste(sprintf("Step %d: %s: %d of %d records fail", failing$step, failing$rule,
                  failing$n_failed, failing$n), collapse = "\n")
  },
  name = "run_adsl_check",
  description = "Run the approved define.xml check on ADSL. Returns each failing rule with its step number and record count."
)

show_failing_values <- tool(
  function(step) {
    rows <- pointblank::get_data_extracts(agent, i = step)
    cols <- strsplit(summ$column[summ$step == step], ", ")[[1]]
    cols <- unique(c(cols, intersect(c("ARMCD", "AGE", "EOSSTT"), names(rows))))
    counts <- dplyr::count(rows, dplyr::across(dplyr::all_of(cols)), sort = TRUE)
    paste(utils::capture.output(print(utils::head(counts, 10))), collapse = "\n")
  },
  name = "show_failing_values",
  description = "For one failing step of the check, show the most common values in the failing records.",
  arguments = list(step = type_integer("Step number from run_adsl_check."))
)

read_sas_program <- tool(
  function() paste(readLines("programs/sas/adsl.sas"), collapse = "\n"),
  name = "read_sas_program",
  description = "Return the text of the study ADSL program, programs/sas/adsl.sas."
)

chat <- chat_aws_bedrock(model = "us.anthropic.claude-sonnet-5")
chat$register_tools(list(run_adsl_check, show_failing_values, read_sas_program))
chat$chat(paste(
  "Run the ADSL check. For each failing rule, look at the failing values and the SAS program.",
  "Then explain in one sentence the cause and the line to change in programs/sas/adsl.sas.",
  "If the tool results don't show the cause, say so instead of guessing."
))

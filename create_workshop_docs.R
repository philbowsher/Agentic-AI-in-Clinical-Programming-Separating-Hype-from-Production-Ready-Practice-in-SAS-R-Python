# Creates the two workshop documents with their section headers in place.
# Run once: source("create_workshop_docs.R")
# Then open each document and ask Posit Assistant (agent) to fill in one section at a time.

docs <- list(
  "01_adsl.qmd" = c(
    "---",
    'title: "Study CDISCPILOT01: ADSL from SAS, checked in R"',
    "format: html",
    "---",
    "",
    "<!-- The SAS steps (review SDTM, understand and run programs/sas/adsl.sas) happen in SAS and in the Posit Assistant chat. This document starts once ADSL exists. -->",
    "",
    "## Move ADSL from SAS to R",
    "",
    "## Check ADSL against the define.xml",
    "",
    "## Fix in SAS and check again",
    "",
    "## Export ADSL for submission",
    ""
  ),
  "02_tlf.qmd" = c(
    "---",
    'title: "Study CDISCPILOT01: TLFs"',
    "format: html",
    "---",
    "",
    "```{r}",
    "#| label: setup",
    "#| message: false",
    "# Loads the ADSL saved in 01_adsl.qmd, so this document can render on its own",
    "library(dplyr)",
    "con <- DBI::dbConnect(duckdb::duckdb())",
    "adsl <- DBI::dbGetQuery(con, \"SELECT * FROM read_parquet('data/adam/adsl.parquet')\")",
    "DBI::dbDisconnect(con, shutdown = TRUE)",
    "```",
    "",
    "## Demographics TLF (Table 14-2.01)",
    "",
    "## Rounding review, R vs SAS",
    "",
    "## Build the submission folder (SAS + R)",
    ""
  )
)

for (f in names(docs)) {
  if (file.exists(f)) {
    message(f, " already exists, leaving it as is.")
  } else {
    writeLines(docs[[f]], f)
    message("Created ", f)
  }
}

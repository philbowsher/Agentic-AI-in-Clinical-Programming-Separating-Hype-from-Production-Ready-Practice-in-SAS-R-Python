# Downloads the study data and spec for the workshop. Run once:
# source("setup_data.R")
#
# Data: CDISC pilot study (CDISCPILOT01) from the PHUSE Test Data Factory,
# https://github.com/phuse-org/phuse-scripts (MIT license). These are the
# original SAS transport (.xpt) files.
# Spec: the CDISC pilot ADaM define.xml that ships with {metacore}.

phuse <- "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data"

files <- c(
  "data/sdtm/dm.xpt"      = "sdtm/cdiscpilot01/dm.xpt",
  "data/sdtm/ds.xpt"      = "sdtm/cdiscpilot01/ds.xpt",
  "data/sdtm/ex.xpt"      = "sdtm/cdiscpilot01/ex.xpt",
  "data/sdtm/ae.xpt"      = "sdtm/cdiscpilot01/ae.xpt",
  "data/sdtm/vs.xpt"      = "sdtm/cdiscpilot01/vs.xpt",
  "data/reference/adsl.xpt" = "adam/cdiscpilot01/adsl.xpt"
)

for (dest in names(files)) {
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(dest)) {
    download.file(file.path(phuse, files[[dest]]), dest, mode = "wb", quiet = TRUE)
  }
}

dir.create("metadata", showWarnings = FALSE)
file.copy(
  metacore::metacore_example("ADaM_define_CDISC_pilot3.xml"),
  "metadata/ADaM_define_CDISC_pilot3.xml",
  overwrite = FALSE
)

for (d in c("data/adam", "data/submission", "output/tables")) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

message("Study data is ready:\n", paste0("  ", list.files("data", pattern = "[.]xpt$", recursive = TRUE), collapse = "\n"))

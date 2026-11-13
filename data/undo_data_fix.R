# Puts back the original dm.xpt and ex.xpt (before the data fix).
# Run: source("data/undo_data_fix.R")

for (f in c("dm.xpt", "ex.xpt")) {
  src <- file.path("data/sdtm_original", f)
  if (file.exists(src)) file.copy(src, file.path("data/sdtm", f), overwrite = TRUE)
}
message("Original SDTM files restored in data/sdtm/. Re-run programs/sas/adsl.sas.")

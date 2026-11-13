# A data fix just came in from data management (example for the workshop).
# Run: source("data/apply_data_fix.R")
#
# What changed:
#   - EX: last dose dates confirmed from the CRF for 3 subjects
#     (01-705-1018, 01-705-1377, 01-705-1382).
#   - DM: age corrected for 1 subject (01-703-1042, 64 -> 66).
#
# The fix updates data/sdtm/dm.xpt and data/sdtm/ex.xpt, so the next run of
# programs/sas/adsl.sas picks it up. The files are written as version 5
# transport files, the version the SAS XPORT engine reads.
#
# The original files are kept in data/sdtm_original/ so the fix can be undone:
# source("data/undo_data_fix.R")

dir.create("data/sdtm_original", showWarnings = FALSE)
for (f in c("dm.xpt", "ex.xpt")) {
  if (!file.exists(file.path("data/sdtm_original", f))) {
    file.copy(file.path("data/sdtm", f), file.path("data/sdtm_original", f))
  }
}

ex <- haven::read_xpt("data/sdtm_original/ex.xpt")
last_dose <- c(
  "01-705-1018" = "2013-07-12",
  "01-705-1377" = "2014-03-07",
  "01-705-1382" = "2013-05-13"
)
for (id in names(last_dose)) {
  i <- which(ex$USUBJID == id & (is.na(ex$EXENDTC) | ex$EXENDTC == ""))
  ex$EXENDTC[i] <- last_dose[[id]]
}
haven::write_xpt(ex, "data/sdtm/ex.xpt", version = 5, name = "EX")

dm <- haven::read_xpt("data/sdtm_original/dm.xpt")
dm$AGE[dm$USUBJID == "01-703-1042"] <- 66
haven::write_xpt(dm, "data/sdtm/dm.xpt", version = 5, name = "DM")

message("Data fix applied to data/sdtm/dm.xpt and data/sdtm/ex.xpt. Re-run programs/sas/adsl.sas.")

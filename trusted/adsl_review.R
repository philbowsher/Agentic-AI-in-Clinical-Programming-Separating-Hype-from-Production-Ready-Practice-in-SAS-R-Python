# =============================================================================
# TRUSTED CODE BANK :: ADSL review measures (CDISCPILOT01)
# Status : APPROVED (v1.0.0) -- example of company-approved code
# Owner  : Statistical Programming Standards
# Note   : Functions tagged @measure are loaded by the {commons} app
#          (commons_app/). Answers that use them get a green shield.
# Origin : Adapted from github.com/philbowsher/Open-Source-AI-Pit-of-Success-Governance-within-the-ACE
# =============================================================================

#' Population counts by treatment
#'
#' Number of subjects in the ITT and safety populations for each planned
#' treatment in the study ADSL. Uses ITTFL and SAFFL as defined in the
#' define.xml.
#'
#' @return A gt table, one row per treatment.
#' @provenance https://github.com/pharmaverse/examples/blob/main/adam/adsl.R
#' @measure
population_counts <- function(adam) {
  DBI::dbReadTable(adam, "adsl") |>
    dplyr::group_by(Treatment = TRT01P) |>
    dplyr::summarise(
      Subjects = dplyr::n(),
      ITT = sum(ITTFL == "Y", na.rm = TRUE),
      Safety = sum(SAFFL == "Y", na.rm = TRUE),
      .groups = "drop"
    ) |>
    gt::gt() |>
    gt::tab_header("ADSL population counts by treatment")
}

#' Treatment duration by treatment
#'
#' Summary of treatment duration in days (TRTEDT - TRTSDT + 1) for the safety
#' population, as defined in the define.xml.
#'
#' @return A gt table with n, mean, median, min and max per treatment.
#' @measure
treatment_duration <- function(adam) {
  DBI::dbReadTable(adam, "adsl") |>
    dplyr::filter(SAFFL == "Y") |>
    dplyr::mutate(dur = as.numeric(as.Date(TRTEDT) - as.Date(TRTSDT)) + 1) |>
    dplyr::group_by(Treatment = TRT01P) |>
    dplyr::summarise(
      n = sum(!is.na(dur)),
      Missing = sum(is.na(dur)),
      Mean = round(mean(dur, na.rm = TRUE), 1),
      Median = stats::median(dur, na.rm = TRUE),
      Min = min(dur, na.rm = TRUE),
      Max = max(dur, na.rm = TRUE),
      .groups = "drop"
    ) |>
    gt::gt() |>
    gt::tab_header("Treatment duration (days), safety population")
}

#' Study ADSL vs the original CDISC pilot ADSL
#'
#' Compares the study ADSL (built by programs/sas/adsl.sas) with the ADSL from the original CDISC
#' pilot (made in SAS), matched on USUBJID. Lists each subject that differs on
#' the chosen variable, and counts subjects found in only one of the two.
#'
#' @param variable `enum[TRT01P, AGEGR1, SAFFL, TRTSDT, TRTEDT]` Variable to compare.
#' @return A gt table of differing subjects, or a one-row table if all match.
#' @provenance https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdiscpilot01
#' @measure
study_vs_reference <- function(variable = "AGEGR1", adam) {
  study <- DBI::dbReadTable(adam, "adsl")
  ref <- DBI::dbReadTable(adam, "adsl_ref")
  only_study <- length(setdiff(study$USUBJID, ref$USUBJID))
  only_ref <- length(setdiff(ref$USUBJID, study$USUBJID))
  both <- dplyr::inner_join(
    study[, c("USUBJID", variable)],
    ref[, c("USUBJID", variable)],
    by = "USUBJID", suffix = c("_study", "_reference")
  )
  a <- as.character(both[[paste0(variable, "_study")]])
  b <- as.character(both[[paste0(variable, "_reference")]])
  diff <- both[!mapply(identical, a, b), ]
  if (nrow(diff) == 0) {
    diff <- tibble::tibble(Result = paste("All", nrow(both), "matched subjects agree on", variable))
  }
  gt::gt(diff) |>
    gt::tab_header(
      paste(variable, ": study ADSL vs original CDISC pilot ADSL"),
      subtitle = sprintf("%d subjects matched; %d only in study ADSL; %d only in original",
                         nrow(both), only_study, only_ref)
    )
}

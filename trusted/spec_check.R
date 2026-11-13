# =============================================================================
# TRUSTED CODE BANK :: Check a dataset against the study spec (define.xml)
# -----------------------------------------------------------------------------
# Status : APPROVED (v1.0.0) -- example of company-approved code
# Owner  : Statistical Programming Standards
# Use    : source("trusted/spec_check.R"); check_adsl(adsl)
# How    : define.xml -> {metacore} -> {pointblank}. Every rule comes from the
#          spec: keys, data types, SAS lengths, controlled terminology, plus a
#          few derivation rules written out from the define.xml methods.
# Origin : Adapted from github.com/philbowsher/Agentic-QC-for-R-Python-SAS-in-Positron
# =============================================================================

#' Locate the study define.xml
#'
#' Project copy first (metadata/), falling back to the CDISC pilot 3 define
#' shipped with {metacore}.
#' @noRd
qc_define_path <- function() {
  local <- file.path("metadata", "ADaM_define_CDISC_pilot3.xml")
  if (file.exists(local)) {
    return(local)
  }
  metacore::metacore_example("ADaM_define_CDISC_pilot3.xml")
}

#' Read the define.xml into a dataset-level metacore object
#' @noRd
qc_read_spec <- function(dataset = "ADSL", path = qc_define_path()) {
  mc <- suppressWarnings(suppressMessages(
    metacore::define_to_metacore(path, verbose = "silent")
  ))
  suppressWarnings(suppressMessages(
    metacore::select_dataset(mc, dataset, verbose = "silent")
  ))
}

#' Variable-level spec as a flat table: type, length, format, codelist
#' @noRd
qc_spec_table <- function(mc) {
  ct <- mc$codelist |>
    dplyr::filter(type %in% c("code_decode", "permitted_val")) |>
    dplyr::mutate(codes = purrr::map(codes, \(x) unique(as.character(x$code)))) |>
    dplyr::select(code_id, codes)

  mc$ds_vars |>
    dplyr::select(variable, order, key_seq) |>
    dplyr::left_join(
      mc$var_spec |> dplyr::select(variable, label, type, length, format),
      by = "variable"
    ) |>
    dplyr::left_join(
      mc$value_spec |>
        dplyr::distinct(variable, code_id, derivation_id),
      by = "variable"
    ) |>
    dplyr::left_join(ct, by = "code_id") |>
    dplyr::arrange(order)
}

#' Build a pointblank agent from the define.xml for one dataset
#'
#' Every rule is derived from the spec, not hand-written:
#'   * keys            -> col_vals_not_null() + rows_distinct()
#'   * data type       -> col_is_character() / col_is_numeric() / col_is_date()
#'   * SAS length      -> col_vals_expr(nchar(x) <= length)
#'   * controlled term -> col_vals_in_set(set = codelist codes)
#' Variables in the spec but absent from the data are reported via
#' attr(agent, "spec_vars_missing") rather than failing the agent, so a
#' partially-built dataset can still be QC'd.
#' @noRd
qc_spec_agent <- function(data,
                          dataset = "ADSL",
                          spec = qc_read_spec(dataset),
                          tbl_name = tolower(dataset),
                          label = paste(dataset, "vs define.xml (CDISC pilot 3)"),
                          warn_at = 1) {
  st <- qc_spec_table(spec)
  in_data <- st$variable[st$variable %in% names(data)]
  st_in <- st[st$variable %in% in_data, ]

  agent <- pointblank::create_agent(
    tbl = data,
    tbl_name = tbl_name,
    label = label,
    actions = pointblank::action_levels(warn_at = warn_at)
  )

  # Keys: required, non-missing, unique
  keys <- st$variable[!is.na(st$key_seq)]
  keys <- union(intersect(c("STUDYID", "USUBJID"), in_data), intersect(keys, in_data))
  for (v in keys) {
    agent <- pointblank::col_vals_not_null(
      agent, columns = dplyr::all_of(v),
      brief = sprintf("Key %s must be populated", v)
    )
  }
  agent <- pointblank::rows_distinct(
    agent, columns = dplyr::all_of(keys),
    brief = sprintf("One record per %s (define.xml structure)", paste(keys, collapse = "/"))
  )

  # Data types
  for (i in seq_len(nrow(st_in))) {
    v <- st_in$variable[i]
    is_date <- !is.na(st_in$format[i]) && grepl("^DATE", st_in$format[i])
    agent <- if (is_date) {
      pointblank::col_is_date(agent, columns = dplyr::all_of(v),
                              brief = sprintf("%s is a date (%s)", v, st_in$format[i]))
    } else if (st_in$type[i] == "text") {
      pointblank::col_is_character(agent, columns = dplyr::all_of(v),
                                   brief = sprintf("%s is character (define type: text)", v))
    } else {
      pointblank::col_is_numeric(agent, columns = dplyr::all_of(v),
                                 brief = sprintf("%s is numeric (define type: %s)", v, st_in$type[i]))
    }
  }

  # SAS lengths for character variables (Pinnacle 21-style check)
  for (i in which(st_in$type == "text" & !is.na(st_in$length))) {
    v <- st_in$variable[i]
    len <- st_in$length[i]
    if (is.character(data[[v]])) {
      agent <- pointblank::col_vals_expr(
        agent,
        expr = rlang::expr(is.na(!!rlang::sym(v)) | nchar(!!rlang::sym(v)) <= !!len),
        brief = sprintf("%s length <= %d (define.xml)", v, len)
      )
    }
  }

  # Controlled terminology
  for (i in which(!vapply(st_in$codes, is.null, logical(1)))) {
    v <- st_in$variable[i]
    set <- st_in$codes[[i]]
    if (is.numeric(data[[v]])) set <- suppressWarnings(as.numeric(set))
    agent <- pointblank::col_vals_in_set(
      agent, columns = dplyr::all_of(v), set = set,
      brief = sprintf("%s values in codelist %s", v, st_in$code_id[i])
    )
  }

  attr(agent, "spec_vars_missing") <- setdiff(st$variable, names(data))
  attr(agent, "data_vars_not_in_spec") <- setdiff(names(data), st$variable)
  agent
}

#' One-row-per-step summary of an interrogated agent (plain tibble)
#' @noRd
qc_agent_summary <- function(agent) {
  x <- agent$validation_set
  tibble::tibble(
    step = x$i,
    check = x$assertion_type,
    column = vapply(x$column, \(c) paste(unlist(c), collapse = ", "), character(1)),
    rule = x$brief,
    n = x$n,
    n_failed = x$n_failed,
    status = dplyr::case_when(
      x$eval_error ~ "ERROR",
      x$all_passed ~ "PASS",
      TRUE ~ "FAIL"
    )
  )
}

#' Age group from age, using the define.xml AGEGR1 codelist (<65, 65-80, >80)
#' @noRd
expected_agegr1 <- function(age) {
  ifelse(age < 65, "<65", ifelse(age <= 80, "65-80", ">80"))
}

#' Add derivation rules from the define.xml methods for ADSL
#' @noRd
qc_adsl_derivations <- function(agent, data) {
  has <- function(...) all(c(...) %in% names(data))
  if (has("AGE", "AGEGR1")) {
    agent <- pointblank::col_vals_expr(
      agent,
      expr = ~ is.na(AGE) | AGEGR1 == expected_agegr1(AGE),
      brief = "AGEGR1 matches AGE (<65, 65-80, >80; define.xml codelist)"
    )
  }
  if (has("SAFFL", "ITTFL", "TRTSDT")) {
    agent <- pointblank::col_vals_expr(
      agent,
      expr = ~ SAFFL == ifelse(ITTFL == "Y" & !is.na(TRTSDT), "Y", "N"),
      brief = "SAFFL = Y if ITTFL = Y and TRTSDT is present (define.xml method MT.ADSL.SAFFL)"
    )
  }
  if (has("SAFFL", "TRTEDT")) {
    agent <- pointblank::col_vals_expr(
      agent,
      expr = ~ SAFFL != "Y" | !is.na(TRTEDT),
      brief = "TRTEDT is present for every treated subject; use the discontinuation date if the last dose date is missing (MT.ADSL.TRTEDT)"
    )
  }
  if (has("TRTDURD", "TRTEDT", "TRTSDT")) {
    agent <- pointblank::col_vals_expr(
      agent,
      expr = ~ is.na(TRTEDT) | is.na(TRTSDT) | TRTDURD == as.numeric(TRTEDT - TRTSDT) + 1,
      brief = "TRTDURD = TRTEDT - TRTSDT + 1 (define.xml method MT.ADSL.TRTDUR)"
    )
  }
  agent
}

#' Check ADSL against the define.xml
#'
#' Runs every spec rule on an ADSL data frame and returns the {pointblank}
#' report. Print it to see the report in the Viewer. The rule-by-rule result
#' is in attr(result, "summary").
#'
#' @param adsl ADSL data frame.
#' @return A pointblank agent report (gt table).
check_adsl <- function(adsl) {
  for (v in grep("DT$", names(adsl), value = TRUE)) {
    if (!inherits(adsl[[v]], "Date")) adsl[[v]] <- as.Date(adsl[[v]])
  }
  agent <- qc_spec_agent(adsl, dataset = "ADSL") |>
    qc_adsl_derivations(adsl) |>
    pointblank::interrogate(progress = FALSE)
  summ <- qc_agent_summary(agent)
  report <- pointblank::get_agent_report(agent, title = "ADSL vs define.xml",
                                         arrange_by = "severity")
  attr(report, "summary") <- summ
  attr(report, "spec_vars_missing") <- attr(agent, "spec_vars_missing")
  message(sprintf("%d rules checked: %d passed, %d failed.",
                  nrow(summ), sum(summ$status == "PASS"), sum(summ$status != "PASS")))
  report
}

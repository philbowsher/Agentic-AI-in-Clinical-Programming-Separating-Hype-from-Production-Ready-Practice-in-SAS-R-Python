# Installs the packages this workshop needs that are not in the shared library.
# Run once at the start: source("check_packages.R")

needed <- c(
  "pointblank",  # checks a dataset against the spec
  "commons",     # trusted-answer chat app
  "paws.common"  # lets {ellmer} sign in to Amazon Bedrock
)

# New accounts have no personal library yet, and the shared one is read-only
user_lib <- Sys.getenv("R_LIBS_USER")
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))

missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) > 0) {
  message("Installing: ", paste(missing, collapse = ", "))
  install.packages(missing, lib = user_lib)
}

also_needed <- c("haven", "duckdb", "DBI", "dplyr", "metacore", "xportr", "gt", "gtsummary",
                 "ellmer", "shinychat", "shiny", "bslib")
still_missing <- c(needed, also_needed)[!vapply(c(needed, also_needed), requireNamespace,
                                                logical(1), quietly = TRUE)]

if (length(still_missing) == 0) {
  message("All workshop packages are ready.")
} else {
  message("Could not find: ", paste(still_missing, collapse = ", "),
          ". Raise your hand and we'll help.")
}

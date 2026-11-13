# ADSL Review: a {commons} chat app for study CDISCPILOT01
# Run from the project root: shiny::runApp("commons_app")
# Answers that use approved code in trusted/ show a green shield.
# To script against the agent outside the app (e.g. for testing), use
# build_agent()$chat_async(), not $chat(): some of its tools are async.

root <- if (dir.exists("trusted")) "." else ".."

read_adsl <- function() {
  f <- file.path(root, "data/adam/adsl.parquet")
  if (!file.exists(f)) {
    stop("data/adam/adsl.parquet not found. Run programs/sas/adsl.sas and save ADSL as parquet first (01_adsl.qmd).", call. = FALSE)
  }
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  DBI::dbGetQuery(con, sprintf("SELECT * FROM read_parquet('%s')", f))
}

adam <- commons::data_source(
  adsl = read_adsl(),
  adsl_ref = as.data.frame(haven::zap_labels(haven::read_xpt(file.path(root, "data/reference/adsl.xpt")))),
  dictionary = file.path(root, "commons_app/dictionaries/adam.yaml")
)

build_agent <- function() {
  commons::commons(
    client = ellmer::chat_aws_bedrock(
      model = getOption("adsl_review.model", "us.anthropic.claude-sonnet-5"),
      echo = "none"
    ),
    data_sources = list(adam = adam),
    semantic_layer = commons::semantic_layer(file.path(root, "trusted")),
    context_layer = commons::context_layer(
      list.files(file.path(root, "commons_app/context"), pattern = "[.]md$", full.names = TRUE)
    ),
    instructions = file.path(root, "commons_app/instructions.md")
  )
}

greeting <- paste(
  "Ask me about the ADSL you built in SAS.",
  "Answers that run approved company code show a **green shield**.",
  "",
  "* <span class=\"suggestion\">How many subjects are in the safety population by treatment?</span>",
  "* <span class=\"suggestion\">Which subjects differ from the original CDISC pilot ADSL on AGEGR1?</span>",
  "* <span class=\"suggestion\">What is the median age of women in the high dose arm?</span>",
  sep = "\n"
)

ui <- shinychat::page_chat(
  "ADSL Review: CDISCPILOT01",
  id = "chat",
  greeting = greeting,
  theme = commons::commons_theme()
)

server <- function(input, output, session) {
  commons::commons_server("chat", build_agent())
}

shiny::shinyApp(ui, server)

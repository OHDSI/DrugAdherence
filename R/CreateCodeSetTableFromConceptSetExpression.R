#' Generate a Temporary Codeset Table from a Concept Set Expression
#'
#' This function takes a Circe-generated `conceptSetExpression` object (list) and creates a temporary table
#' containing unique concept IDs.
#'
#' @template Connection
#' @template VocabularyDatabaseSchema
#' @template TempEmulationSchema
#' @template ConceptSetExpression
#' @template ConceptSetTable
#'
createCodeSetTableFromConceptSetExpression <-
  function(connection,
           vocabularyDatabaseSchema,
           conceptSetExpression,
           tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
           conceptSetTable = "#concept_sets") {
    checkmate::assertCharacter(vocabularyDatabaseSchema, len = 1)
    checkmate::assertList(conceptSetExpression, min.len = 1)
    checkmate::assertCharacter(tempEmulationSchema, len = 1, null.ok = TRUE)
    checkmate::assertCharacter(conceptSetTable, len = 1)

    conceptSetSql <-
      CirceR::buildConceptSetQuery(
        conceptSetJSON =
          conceptSetExpression |>
            RJSONIO::toJSON(digits = 23)
      )

    conceptSetSql <- paste0(
      "DROP TABLE IF EXISTS @concept_set_table;

       SELECT concept_id
       INTO @concept_set_table
       FROM
       ( ",
      conceptSetSql,
      " ) f;"
    )

    writeLines("Creating codeset table....")
    DatabaseConnector::renderTranslateExecuteSql(
      connection = connection,
      sql = conceptSetSql,
      tempEmulationSchema = tempEmulationSchema,
      vocabulary_database_schema = vocabularyDatabaseSchema,
      concept_set_table = conceptSetTable,
      progressBar = FALSE,
      reportOverallTime = FALSE
    )
  }

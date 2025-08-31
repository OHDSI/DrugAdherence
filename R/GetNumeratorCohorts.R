#' Create Numerator Cohorts
#'
#' This function takes an input a cohort (called denominator to bind the numerator cohort to), a concept set expression
#' to create the numerator cohort.
#'
#' @template Connection
#' @template CdmDatabaseSchema
#' @template TempEmulationSchema
#' @param numeratorCohortTableBaseName The name of the output table
#' @template GapDays
#' @param DrugAdherenceTable The name of the table with "#drug_exposure". Should be a temp table.
#' @param baseCohortDefinitionId The minimum cohortId to create cohorts for all gapDays
getNumeratorCohorts <- function(connection = NULL,
                                cdmDatabaseSchema,
                                tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
                                numeratorCohortTableBaseName = "#numerator",
                                DrugAdherenceTable = "#drug_exposure",
                                gapDays = c(0),
                                baseCohortDefinitionId = 100) {
  gapDays <- gapDays |>
    unique() |>
    sort()

  sqlNonOverlappingEraWithPad <-
    SqlRender::readSql(
      system.file(
        "sql",
        "sql_server",
        "sqlNonOverlappingEraWithPad.sql",
        package = utils::packageName()
      )
    )

  cohortDefinitionSet <- c()
  writeLines("Creating numerator cohorts....")
  for (i in (1:length(gapDays))) {
    cohortDefinitionId <- baseCohortDefinitionId + i

    DatabaseConnector::renderTranslateExecuteSql(
      connection = connection,
      sql = sqlNonOverlappingEraWithPad,
      start_date_col = "drug_exposure_start_date",
      end_date_col = "drug_exposure_end_date",
      source_table = DrugAdherenceTable,
      output_table = paste0(numeratorCohortTableBaseName, "_", cohortDefinitionId),
      cohort_definition_id = cohortDefinitionId,
      cohort_definition_id_not_null = !is.null(cohortDefinitionId),
      person_id_col = "person_id",
      cdm_database_schema = cdmDatabaseSchema,
      era_constructor_pad = gapDays[[i]],
      tempEmulationSchema = tempEmulationSchema,
      progressBar = FALSE,
      reportOverallTime = FALSE
    )

    cohortDefinitionSet[[i]] <-
      dplyr::tibble(
        cohortId = cohortDefinitionId,
        cohortName = paste0("gap days ", gapDays[[i]]),
        persistenceDay = gapDays[[i]],
        cohortTableName = paste0(numeratorCohortTableBaseName, "_", cohortDefinitionId)
      )
  }

  cohortDefinitionSet <- dplyr::bind_rows(cohortDefinitionSet)

  return(cohortDefinitionSet)
}

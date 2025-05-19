#' get drug exposure events for a person
#'
#' Given a concept set expression and a denominator cohort to restrict the persons
#' and exposure event to period in the denominator cohort, this function creates a temp table
#' that has the records from drug_exposure table.
#'
#' @template Connection
#' @template QuerySource
#' @template CdmDatabaseSchema
#' @template TempEmulationSchema
#' @template ConceptSetTable
#' @template DenominatorCohortDatabaseSchema
#' @template DenominatorCohortTable
#' @template DenominatorCohortId
#' @param forceMinimumDaysSupply (Default 1, i.e. not used). Acceptable values are NULL, or any integer value to represent days.
#' @param DrugAdherenceOutputTable the output table
#' @param restrictToCohortPeriod Do you want to restrict to cohort period? Default = TRUE.
#'
getDrugAdherenceInDenominatorCohort <-
  function(connection = NULL,
           querySource = TRUE,
           cdmDatabaseSchema,
           tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
           conceptSetTable = "#concept_sets",
           denominatorCohortDatabaseSchema = NULL,
           denominatorCohortTable = "#denominator",
           denominatorCohortId = 0,
           forceMinimumDaysSupply = 1,
           DrugAdherenceOutputTable = "#drug_exposure",
           restrictToCohortPeriod = TRUE) {
    # Validate inputs
    checkmate::assertCharacter(cdmDatabaseSchema, len = 1)
    checkmate::assertCharacter(tempEmulationSchema, len = 1, null.ok = TRUE)
    checkmate::assertCharacter(denominatorCohortTable, len = 1)
    checkmate::assertIntegerish(denominatorCohortId, lower = 0)
    checkmate::assertCharacter(conceptSetTable, len = 1)
    checkmate::assert_flag(querySource)
    checkmate::assertInt(x = forceMinimumDaysSupply, null.ok = TRUE, lower = 0)

    sqlDrugAdherenceInFirstExposuresObservationPeriod <-
      SqlRender::readSql(
        system.file(
          "sql",
          "sql_server",
          "sqlDrugAdherenceInDenominatorCohort.sql",
          package = utils::packageName()
        )
      )

    if (!is.null(denominatorCohortDatabaseSchema)) {
      denominatorCohortTable <-
        paste0(
          denominatorCohortDatabaseSchema,
          ".",
          denominatorCohortTable
        )
    }

    writeLines("Creating drug exposure....")
    DatabaseConnector::renderTranslateExecuteSql(
      connection = connection,
      sql = sqlDrugAdherenceInFirstExposuresObservationPeriod,
      cdm_database_schema = cdmDatabaseSchema,
      tempEmulationSchema = tempEmulationSchema,
      drug_exposure_output = DrugAdherenceOutputTable,
      concept_set_table = conceptSetTable,
      denominator_cohort_table = denominatorCohortTable,
      denominator_cohort_id = denominatorCohortId,
      query_source = as.logical(querySource),
      restrict_to_cohort_period = restrictToCohortPeriod,
      force_minimum_days_supply = !is.null(forceMinimumDaysSupply),
      force_minimum_days_suppply_value = forceMinimumDaysSupply,
      progressBar = FALSE,
      reportOverallTime = FALSE
    )
  }

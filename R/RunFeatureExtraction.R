#' Run feature extraction
#'
#' @details
#' This function executes feature extraction
#'
#' @template ConnectionDetails
#' @template Connection
#' @template CdmDatabaseSchema
#' @template cohortDatabaseSchema
#' @template TempEmulationSchema
#' @param cohortIds          cohort ids to run feature extraction on. Only one cohort id if aggregated = FALSE.
#' @param cohortTable        cohort Table Name.
#' @param outputFolder       Name of local folder to place results; make sure to use
#'                           forward slashes (/). Do not use a folder on a network
#'                           drive since this greatly impacts performance.
#' @param covariateSettings   See FeatureExtraction covariateSettings.
#' @param aggregated See `aggregated` in FeatureExtraction:getDbCovariateData.
#'
runFeatureExtraction <-
  function(connectionDetails = NULL,
           connection = NULL,
           cdmDatabaseSchema,
           cohortDatabaseSchema,
           cohortIds,
           cohortTable,
           covariateSettings,
           tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
           outputFolder = NULL,
           aggregated = TRUE) {
    rowIdField <- "subject_id"

    if (!is.null(outputFolder)) {
      if (!file.exists(outputFolder)) {
        dir.create(outputFolder, recursive = TRUE)
      }
    }

    if (!aggregated) {
      if (length(cohortIds) > 1) {
        stop("Only one cohort ID is allowed when 'aggregated' is set to FALSE.")
      }

      sql <- "
      DROP TABLE  IF EXISTS #cohort_person;

      SELECT ROW_NUMBER() OVER (ORDER BY subject_id, cohort_start_date) AS row_id,
              cohort_definition_id,
              subject_id,
              cohort_start_date,
              cohort_end_date
      INTO #cohort_person
      FROM @cohort_database_schema.@cohort_table
      WHERE cohort_definition_id IN (@target_cohort_id);

      "
      DatabaseConnector::renderTranslateExecuteSql(
        connection = connection,
        sql = sql,
        cohort_database_schema = cohortDatabaseSchema,
        cohort_table = cohortTable,
        target_cohort_id = cohortIds,
        profile = FALSE,
        progressBar = FALSE,
        reportOverallTime = FALSE
      )
      cohortDatabaseSchema <- NULL
      cohortTable <- "#cohort_person"
      rowIdField <- "row_id"
    }

    if (is.null(connection)) {
      connection <- DatabaseConnector::connect(connectionDetails)
      on.exit(DatabaseConnector::disconnect(connection))
    }

    covariateData <-
      FeatureExtraction::getDbCovariateData(
        connection = connection,
        oracleTempSchema = tempEmulationSchema,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cdmVersion = 5,
        cohortTable = cohortTable,
        cohortIds = cohortIds,
        covariateSettings = covariateSettings,
        aggregated = aggregated,
        cohortTableIsTemp = is.null(cohortDatabaseSchema),
        rowIdField = rowIdField
      )

    if (!is.null(outputFolder)) {
      FeatureExtraction::saveCovariateData(
        covariateData = covariateData,
        file = file.path(outputFolder, "covariateData")
      )
    }

    if (!aggregated) {
      sql <- "DROP TABLE  IF EXISTS #cohort_person;"
      DatabaseConnector::renderTranslateExecuteSql(
        connection = connection,
        sql = sql,
        profile = FALSE,
        progressBar = FALSE,
        reportOverallTime = FALSE
      )
    }
    return(covariateData)
  }

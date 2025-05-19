testthat::test_that("Test run drug exposure", {
  # first create a denominator cohort table that is a permanent table in cohort databaseschema
  connection <-
    DatabaseConnector::connect(connectionDetails = connectionDetails)

  DrugAdherence:::createCodeSetTableFromConceptSetExpression(
    connection = connection,
    conceptSetExpression = conceptSetExpression,
    vocabularyDatabaseSchema = vocabularyDatabaseSchema,
    conceptSetTable = "#concept_sets"
  )

  DatabaseConnector::renderTranslateExecuteSql(
    connection = connection,
    sql = sqlDenominatorCohort,
    tempEmulationSchema = tempEmulationSchema,
    use_cohort_database_schema = TRUE,
    cohort_database_schema = cohortDatabaseSchema,
    cdm_database_schema = cdmDatabaseSchema,
    denominator_cohort_table = denominatorCohortTable
  )
  DatabaseConnector::disconnect(connection = connection)

  # now there should be a permanent cohort table that is cohortDatabaseSchema.denominatorCohortTable

  output <- DrugAdherence:::runDrugAdherence(
    connectionDetails = connectionDetails,
    conceptSetExpression = conceptSetExpression,
    cdmDatabaseSchema = cdmDatabaseSchema,
    tempEmulationSchema = tempEmulationSchema,
    denominatorCohortDatabaseSchema = cohortDatabaseSchema,
    denominatorCohortId = 0,
    denominatorCohortTable = denominatorCohortTable,
    gapDays = c(0, 100, 1000)
  )

  testthat::expect_gte(object = length(output), expected = 0)

  connection <-
    DatabaseConnector::connect(connectionDetails = connectionDetails)
  DatabaseConnector::renderTranslateExecuteSql(
    connection = connection,
    sql = "DROP TABLE IF EXISTS @cohort_database_schema.@cohort_table;",
    cohort_database_schema = cohortDatabaseSchema,
    cohort_table = denominatorCohortTable
  )
  DatabaseConnector::disconnect(connection = connection)
})

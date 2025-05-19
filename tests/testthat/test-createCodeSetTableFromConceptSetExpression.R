testthat::test_that("Create CodeSet Table From ConceptSetExpression", {
  connection <-
    DatabaseConnector::connect(connectionDetails = connectionDetails)

  createCodeSetTableFromConceptSetExpression(
    connection = connection,
    conceptSetExpression = conceptSetExpression,
    vocabularyDatabaseSchema = vocabularyDatabaseSchema
  )
  codeSetId <- DatabaseConnector::renderTranslateQuerySql(
    connection = connection,
    sql = "SELECT * FROM #concept_sets;",
    tempEmulationSchema = tempEmulationSchema,
    snakeCaseToCamelCase = TRUE
  )

  testthat::expect_true(object = nrow(codeSetId) > 0)
  DatabaseConnector::disconnect(connection = connection)
})

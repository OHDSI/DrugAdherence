library(testthat)
library(DrugAdherence)
library(dplyr)


dbms <- getOption("dbms", default = "postgresql")
message("************* Testing on ", dbms, " *************")

if (dir.exists(Sys.getenv("DATABASECONNECTOR_JAR_FOLDER"))) {
  jdbcDriverFolder <- Sys.getenv("DATABASECONNECTOR_JAR_FOLDER")
} else {
  jdbcDriverFolder <- tempfile("jdbcDrivers")
  dir.create(jdbcDriverFolder, showWarnings = FALSE)
  DatabaseConnector::downloadJdbcDrivers("postgresql", pathToDriver = jdbcDriverFolder)

  if (!dbms %in% c("postgresql")) {
    DatabaseConnector::downloadJdbcDrivers(dbms, pathToDriver = jdbcDriverFolder)
  }

  withr::defer(
    {
      unlink(jdbcDriverFolder, recursive = TRUE, force = TRUE)
    },
    testthat::teardown_env()
  )
}

folder <- tempfile()
dir.create(folder, recursive = TRUE)
skipCdmTests <- FALSE



if (dbms == "sqlite") {
  databaseFile <- paste0(Sys.getpid(), "testEunomia.sqlite")

  connectionDetails <-
    Eunomia::getEunomiaConnectionDetails(databaseFile = databaseFile)
  withr::defer(
    {
      unlink(databaseFile, recursive = TRUE, force = TRUE)
    },
    testthat::teardown_env()
  )
  cdmDatabaseSchema <- "main"
  cohortDatabaseSchema <- "main"
  vocabularyDatabaseSchema <- cohortDatabaseSchema
  denominatorCohortTable <- "cohort"
  tempEmulationSchema <- NULL
} else {
  denominatorCohortTable <-
    paste0(
      "ct_",
      Sys.getpid(),
      format(Sys.time(), "%s"),
      sample(101:200, 1)
    )
}

if (dbms == "postgresql") {
  dbUser <- Sys.getenv("CDM5_POSTGRESQL_USER")
  dbPassword <- Sys.getenv("CDM5_POSTGRESQL_PASSWORD")
  dbServer <- Sys.getenv("CDM5_POSTGRESQL_SERVER")
  cdmDatabaseSchema <- Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
  vocabularyDatabaseSchema <-
    Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA")
  tempEmulationSchema <- NULL
  cohortDatabaseSchema <-
    Sys.getenv("CDM5_POSTGRESQL_OHDSI_SCHEMA")
} else if (dbms == "oracle") {
  dbUser <- Sys.getenv("CDM5_ORACLE_USER")
  dbPassword <- Sys.getenv("CDM5_ORACLE_PASSWORD")
  dbServer <- Sys.getenv("CDM5_ORACLE_SERVER")
  cdmDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
  vocabularyDatabaseSchema <- Sys.getenv("CDM5_ORACLE_CDM_SCHEMA")
  tempEmulationSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
  cohortDatabaseSchema <- Sys.getenv("CDM5_ORACLE_OHDSI_SCHEMA")
  options(sqlRenderTempEmulationSchema = tempEmulationSchema)
} else if (dbms == "redshift") {
  dbUser <- Sys.getenv("CDM5_REDSHIFT_USER")
  dbPassword <- Sys.getenv("CDM5_REDSHIFT_PASSWORD")
  dbServer <- Sys.getenv("CDM5_REDSHIFT_SERVER")
  cdmDatabaseSchema <- Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA")
  vocabularyDatabaseSchema <-
    Sys.getenv("CDM5_REDSHIFT_CDM_SCHEMA")
  tempEmulationSchema <- NULL
  cohortDatabaseSchema <- Sys.getenv("CDM5_REDSHIFT_OHDSI_SCHEMA")
} else if (dbms == "sql server") {
  dbUser <- Sys.getenv("CDM5_SQL_SERVER_USER")
  dbPassword <- Sys.getenv("CDM5_SQL_SERVER_PASSWORD")
  dbServer <- Sys.getenv("CDM5_SQL_SERVER_SERVER")
  cdmDatabaseSchema <- Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
  vocabularyDatabaseSchema <-
    Sys.getenv("CDM5_SQL_SERVER_CDM_SCHEMA")
  tempEmulationSchema <- NULL
  cohortDatabaseSchema <-
    Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA")
}

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = dbms,
  user = dbUser,
  password = URLdecode(dbPassword),
  server = dbServer,
  pathToDriver = jdbcDriverFolder
)

if (cdmDatabaseSchema == "" || dbServer == "") {
  skipCdmTests <- TRUE
}

conceptSetExpressionDataFrame <- dplyr::tibble(
  CONCEPT_CLASS_ID = "Ingredient",
  CONCEPT_CODE = "140587",
  CONCEPT_ID = 1118084,
  CONCEPT_NAME = "celecoxib",
  DOMAIN_ID = "Drug",
  INVALID_REASON = "V",
  INVALID_REASON_CAPTION = "Valid",
  STANDARD_CONCEPT = "S",
  STANDARD_CONCEPT_CAPTION = "Standard",
  VOCABULARY_ID = "RxNorm",
  VALID_START_DATE = as.Date("1969-12-31"),
  VALID_END_DATE = as.Date("2099-12-30")
)

conceptSetExpression <- list()
conceptSetExpression$items <- list()
conceptSetExpression$items[[1]] <- list()
conceptSetExpression$items[[1]]$concept <-
  conceptSetExpressionDataFrame[1, ] |>
  as.list()
conceptSetExpression$items[[1]]$isExcluded <- FALSE
conceptSetExpression$items[[1]]$includeDescendants <- TRUE
conceptSetExpression$items[[1]]$includeMapped <- FALSE

sqlDenominatorCohort <- "DROP TABLE IF EXISTS {@use_cohort_database_schema} ? {@cohort_database_schema.@denominator_cohort_table} : {@denominator_cohort_table};
                          SELECT CAST(0 as BIGINT) as cohort_definition_id,
                              op.person_id subject_id,
                              de2.drug_exposure_start_date cohort_start_date,
                              op.observation_period_end_date cohort_end_date
                          INTO {@use_cohort_database_schema} ? {@cohort_database_schema.@denominator_cohort_table} : {@denominator_cohort_table}
                          FROM @cdm_database_schema.observation_period op
                          INNER JOIN
                              (
                                  SELECT person_id,
                                          min(drug_exposure_start_date) drug_exposure_start_date
                                  FROM @cdm_database_schema.drug_exposure de
                                  INNER JOIN #concept_sets co
                                  ON de.drug_concept_id = co.concept_id
                                  GROUP BY person_id
                              ) de2
                          ON op.person_id = de2.person_id
                            AND drug_exposure_start_date >= observation_period_start_date
                            AND drug_exposure_start_date <= observation_period_end_date;"

# Cleanup
sql <- "DROP TABLE IF EXISTS @cohort_database_schema.@cohort_table;"

withr::defer(
  {
    connection <- DatabaseConnector::connect(connectionDetails)
    DatabaseConnector::renderTranslateExecuteSql(connection,
      sql,
      cohort_database_schema = cohortDatabaseSchema,
      cohort_table = denominatorCohortTable
    )
    DatabaseConnector::disconnect(connection)
  },
  testthat::teardown_env()
)

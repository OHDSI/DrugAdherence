#' @param cohortDatabaseSchema   Schema name where your cohort table exists. cohort table should have columns cohort_definition_id,
#'                                subject_id, cohort_start_date, cohort_end_date. The dates for the same subject_id, cohort_definition_id
#'                                should be non overlapping. Note that for SQL Server, this should include both the database and
#'                                schema name, for example 'cdm_data.dbo'.

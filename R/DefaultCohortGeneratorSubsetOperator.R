#' #' Create Default Subset Operators for Cohort Generation
#' #'
#' #' This function configures a set of default subset operators used in cohort generation. It uses CohortGenerator package
#' #' subset operator, and allows for easily specifying demographic and temporal parameters to subset a cohort and create
#' #' a new cohort.
#' #'
#' #' @param minAge Integer, optional. The minimum age at first drug exposure. Defaults to 0 years.
#' #' @param maxAge Integer, optional. The maximum age at first drug exposure. Defaults to 90 years.
#' #' @param genderSubset Numeric vector, optional. Identifies genders using concept IDs. Defaults to c(8532, 8507).
#' #' @param race Integer, optional. Concept ID for specifying race.
#' #' @param ethnicity Integer, optional. Concept ID for specifying ethnicity.
#' #' @param restrictToEarliestOccurrence Logical, optional. Specifies whether to restrict the analysis to the earliest
#' #'        occurrence of the drug exposure. Defaults to TRUE.
#' #' @param calendarStartDate Date, optional. Specifies the earliest date from which to consider drug exposures, used to
#' #'        left-censor data. Defaults to '2016-01-01'.
#' #' @param calendarEndDate Date, optional. The latest date up to which to consider drug exposures, used to right-censor
#' #'        data. By default, it is set to one year before the current date to account for claims accrual lag.
#' #' @param priorTime Integer, optional. Represents the number of days of prior observation required before the start of
#' #'        drug exposure. Defaults to 365 days.
#' #' @param followUpTime Integer, optional. Represents the number of days of follow-up observation after the start of
#' #'        drug exposure. Defaults to 365 days.
#' #' @param limitTo Character, optional. Describes whether to restrict the analysis to the first-ever observation period
#' #'        or to all observation periods with drug exposure. Defaults to 'firstEver'.
#' #'
#' #' @return A list of configured subset operators suitable for use in cohort generation functions.
#' defaultCohortGeneratorSubsetOperator <- function(minAge = 0,
#'                                                  maxAge = 90,
#'                                                  genderSubset = c(8532, 8507),
#'                                                  restrictToEarliestOccurrence = TRUE,
#'                                                  race = NULL,
#'                                                  calendarStartDate = "2016-01-01",
#'                                                  calendarEndDate = Sys.Date() - 365,
#'                                                  priorTime = 365,
#'                                                  followUpTime = 365,
#'                                                  ethnicity = NULL,
#'                                                  limitTo = "firstEver") {
#'   # Convert string dates to Date objects and validate
#'   if (!is.null(calendarStartDate)) {
#'     if (is.character(calendarStartDate)) {
#'       calendarStartDate <- as.Date(calendarStartDate)
#'     }
#'     checkmate::assertDate(calendarStartDate, add = NA)
#'   }
#'
#'   if (!is.null(calendarEndDate)) {
#'     if (is.character(calendarEndDate)) {
#'       calendarEndDate <- as.Date(calendarEndDate)
#'     }
#'     checkmate::assertDate(calendarEndDate, add = NA)
#'   }
#'
#'   # Validate inputs using checkmate
#'   checkmate::assertIntegerish(minAge, lower = 0, upper = 150)
#'   checkmate::assertIntegerish(maxAge, lower = 0, upper = 150)
#'   checkmate::assertIntegerish(genderSubset, any.missing = FALSE, lower = 1)
#'   checkmate::assertFlag(restrictToEarliestOccurrence)
#'   checkmate::assertIntegerish(priorTime, lower = 1)
#'   checkmate::assertIntegerish(followUpTime, lower = 1)
#'   checkmate::assertCharacter(limitTo)
#'
#'   subsetOperators <- list()
#'   subsetOperators$limitValidGenderAgeMin0 <-
#'     CohortGenerator::createDemographicSubset(
#'       name = "",
#'       gender = c(8532, 8507),
#'       ageMin = minAge,
#'       ageMax = maxAge,
#'       race = race,
#'       ethnicity = ethnicity
#'     )
#'
#'   subsetOperators$limitSubset <- CohortGenerator::createLimitSubset(
#'     name = "",
#'     priorTime = priorTime,
#'     followUpTime = followUpTime,
#'     limitTo = limitTo
#'   )
#'   return(subsetOperators)
#' }

# DrugAdherence

[![Build Status](https://github.com/OHDSI/DrugAdherence/workflows/R-CMD-check/badge.svg)](https://github.com/OHDSI/DrugAdherence/actions?query=workflow%3AR-CMD-check)
[![codecov.io](https://codecov.io/github/OHDSI/DrugAdherence/coverage.svg?branch=main)](https://codecov.io/github/OHDSI/DrugAdherence?branch=main)

## Introduction

THIS PACKAGE IS UNDER ACTIVE DEVELOPMENT. IT IS NOT PART OF HADES.

The `DrugAdherence` R package is a tool for researchers to analyze medication adherence, compliance, and persistence patterns within patient cohorts in the [OMOP Common Data Model (CDM)](https://ohdsi.github.io/CommonDataModel/). As part of the [Observational Health Data Sciences and Informatics (OHDSI)](https://www.ohdsi.org/) ecosystem, this package provides a standardized way to generate evidence about drug utilization from observational health data.

It assesses drug utilization from the first exposure and calculates key metrics that are crucial for understanding real-world adherence, which can ultimately help in improving patient outcomes.

## Features

-   **Standardized Adherence Metrics**: Calculates key adherence metrics such as:
    -   Medication Possession Ratio (MPR)
    -   Proportional Days Covered (PDC)
    -   Persistence proportion over time.
-   **Flexible Cohort and Drug Definition**:
    -   Uses a "denominator" cohort as the study population.
    -   Defines the drugs of interest using a Circe-compatible concept set expression.
-   **Temporal Analysis**: Assesses drug utilization from the first exposure through user-defined persistence windows, with customizable gap days.
-   **Rich Outputs**: Generates a comprehensive set of results, including:
    -   Data frames with summary statistics for adherence.
    -   Time-series data for persistence.
    -   Resolved concept sets and cohort definitions.
-   **Visualizations**: Creates plots to visualize adherence patterns, such as:
    -   Violin plots for the distribution of adherence days.
    -   Line plots showing persistence proportion over time.
-   **Database Agnostic**: Built on top of `DatabaseConnector` and `SqlRender`, allowing it to run against any database supported by these packages (e.g., PostgreSQL, SQL Server, Redshift, Oracle).

## Technology

`DrugAdherence` is an R package that uses `DatabaseConnector` to connect to a database in the OMOP CDM format.

## System Requirements

-   R (version 4.1.0 or higher).
-   A database in OMOP CDM format (version 5.3 or higher).

## Installation

1.  See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including RTools and Java.
2.  In R, use the following commands to download and install `DrugAdherence`:

    ```r
    install.packages("remotes")
    remotes::install_github("ohdsi/DrugAdherence")
    ```

## Usage

Here is a conceptual example of how to use the `DrugAdherence` package.

```r
library(DrugAdherence)

# 1. Set up connection to the database
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                                                server = "localhost/ohdsi",
                                                                user = "user",
                                                                password = "password")

cdmDatabaseSchema <- "cdm_schema"
vocabularyDatabaseSchema <- "vocabulary_schema"
denominatorCohortDatabaseSchema <- "results_schema"
denominatorCohortTable <- "cohort"
denominatorCohortId <- 1234 # The cohort_definition_id for your study population

# 2. Define the drug concept set
# This is a Circe-compatible concept set expression.
# For example, to select all antihypertensive drugs.
conceptSetExpression <- '
{
  "items": [
    {
      "concept": {
        "CONCEPT_ID": 21603991,
        "CONCEPT_NAME": "Antihypertensive drugs",
        "STANDARD_CONCEPT": "C",
        "STANDARD_CONCEPT_CAPTION": "Classification",
        "INVALID_REASON": "V",
        "INVALID_REASON_CAPTION": "Valid",
        "CONCEPT_CODE": "C03",
        "DOMAIN_ID": "Drug",
        "VOCABULARY_ID": "ATC",
        "CONCEPT_CLASS_ID": "ATC 2nd"
      },
      "isExcluded": false,
      "includeDescendants": true,
      "includeMapped": false
    }
  ]
}
'

# 3. Run the analysis
drugAdherenceResults <- runDrugAdherence(connectionDetails = connectionDetails,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         vocabularyDatabaseSchema = vocabularyDatabaseSchema,
                                         denominatorCohortDatabaseSchema = denominatorCohortDatabaseSchema,
                                         denominatorCohortTable = denominatorCohortTable,
                                         denominatorCohortId = denominatorCohortId,
                                         conceptSetExpression = conceptSetExpression,
                                         gapDays = c(0, 30, 60, 90), # Define persistence gaps
                                         maxFollowUpDays = 365)

# 4. Explore the results
# The output is a list containing various data frames and plots.
# For example, view the summary statistics for adherence:
print(drugAdherenceResults$drugAdherence)

# View the persistence proportion data:
print(drugAdherenceResults$drugPersistenceProportion)

# Display the adherence violin plot:
print(drugAdherenceResults$drugAherencePlot)

# Display the persistence proportion plot:
print(drugAdherenceResults$drugPersistenceProportionGraph)

```

### Output Structure

The `runDrugAdherence` function returns a list containing the following main components:

-   `resolvedConcepts`: A tibble of the concepts resolved from the concept set expression.
-   `cohortDefinitionSet`: A tibble defining the numerator cohorts generated based on the `gapDays`.
-   `person`: A tibble with demographic information of the people in the denominator cohort.
-   `denominator`: A tibble of the denominator cohort.
-   `DrugAdherence`: A tibble containing the raw drug exposure records for the subjects.
-   `cohorts`: A combined tibble of all generated cohorts (denominator, numerators).
-   `drugAdherence`: A tibble with summary statistics (mean, median, sd, etc.) for adherence days.
-   `drugPersistenceProportion`: A tibble with the persistence proportion at different time thresholds.
-   `drugAherencePlot`: A violin plot of adherence days, showing the distribution of days supply.
-   `drugAherencePlotRightCensored`: A violin plot of adherence days, right-censored at `maxFollowUpDays`.
-   `drugPersistenceProportionGraph`: A ggplot object showing the persistence proportion over time for each cohort.

## User Documentation

Documentation can be found on the [package website](https://ohdsi.github.io/DrugAdherence).

PDF versions of the documentation are also available:

-   Package manual: [DrugAdherence.pdf](https://raw.githubusercontent.com/OHDSI/DrugAdherence/main/extras/DrugAdherence.pdf)

## Support

-   Developer questions/comments/feedback: [OHDSI Forum](http://forums.ohdsi.org/c/developers)
-   We use the [GitHub issue tracker](https://github.com/OHDSI/DrugAdherence/issues) for all bugs/issues/enhancements.

## Contributing

Read [here](https://ohdsi.github.io/Hades/contribute.html) how you can contribute to this package.

## License

`DrugAdherence` is licensed under Apache License 2.0.

## Development

`DrugAdherence` is being developed in R Studio.

### Development status

`DrugAdherence` is under development.

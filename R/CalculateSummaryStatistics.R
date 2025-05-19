#' Calculate summary statistics
#'
#' This function, given a data frame (df) with a continuous variable and a group,
#' computes distribution statistics.
#'
#' @param df Data frame to perform calculations on
#' @param value Field in the data frame that has the data to calculate.
#' @param group Any optional grouping variable
#' @export
calculateSummaryStatistics <-
  function(df, value = "value", group = NULL) {
    # Dynamically select and rename columns
    if (!is.null(group)) {
      dataFrame <- df |>
        dplyr::select({{ group }}, {{ value }}) |>
        dplyr::rename(group = {{ group }}, value = {{ value }}) |>
        dplyr::group_by(group)
    } else {
      dataFrame <- df |>
        dplyr::select({{ value }}) |>
        dplyr::rename(value = {{ value }})
    }

    # Helper function to calculate mode
    calculateMode <- function(x) {
      ux <- unique(x)
      ux[which.max(tabulate(match(x, ux)))]
    }

    # Compute summary statistics using consistent column names
    output <- dataFrame |>
      dplyr::summarize(
        mean = mean(value, na.rm = TRUE),
        sd = stats::sd(value, na.rm = TRUE),
        median = stats::median(value, na.rm = TRUE),
        p01 = stats::quantile(value, 0.01, na.rm = TRUE),
        p05 = stats::quantile(value, 0.05, na.rm = TRUE),
        p25 = stats::quantile(value, 0.25, na.rm = TRUE),
        p75 = stats::quantile(value, 0.75, na.rm = TRUE),
        p95 = stats::quantile(value, 0.95, na.rm = TRUE),
        p99 = stats::quantile(value, 0.99, na.rm = TRUE),
        mode = calculateMode(value),
        count = dplyr::n(),
        count_distinct = dplyr::n_distinct(value)
      )

    # Optionally reshape the output for grouped data
    if (!is.null(group)) {
      output <- output |>
        tidyr::pivot_longer(
          cols = -group,
          names_to = "statistic",
          values_to = "value"
        )
    }

    return(output)
  }

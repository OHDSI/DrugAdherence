#' Process Dates for STL Time Series Analysis
#'
#' This function performs STL decomposition on a data frame for specified time representations.
#' It requires a date field and can optionally use a weight field to aggregate data. The function
#' handles different time aggregations (e.g., Day, Month, Quarter, Year) and returns a list of
#' models, components, and plots for each time representation.
#'
#' @param df A data frame containing the time series data.
#' @param timeRepresentations A character vector specifying the time units to aggregate by.
#'                            Accepted values are 'Day', 'Month', 'Quarter', 'Year'.
#'                            Default is c('Day', 'Month', 'Quarter', 'Year').
#' @param dateField The name of the column in `df` that contains the date information.
#'                  Defaults to 'cohortStartDate'.
#' @param weight An optional name of the column that contains weights for aggregation.
#'               If NULL, each record is assumed to have an equal weight of 1.
#'
#' @return A list where each element corresponds to a specified time representation and
#'         contains the processed data, the fitted model, its components, and a plot of the
#'         decomposition.
#'
#' @export
processTimeSeries <-
  function(df,
           timeRepresentations = c("Day", "Week", "Month", "Quarter", "Year"),
           dateField = "cohortStartDate",
           weight = NULL) {
    # Check input validity
    checkmate::assertDataFrame(df)
    checkmate::assertCharacter(dateField, len = 1, min.chars = 1)
    checkmate::assertCharacter(
      timeRepresentations,
      min.len = 1,
      any.missing = FALSE,
      min.chars = 1
    )
    checkmate::assertSubset(timeRepresentations,
      choices = c("Day", "Week", "Month", "Quarter", "Year")
    )

    if (!is.null(weight)) {
      checkmate::assertSubset(weight,
        choices = colnames(df)
      )
    }

    if (!is.null(weight)) {
      df <- df |>
        dplyr::select(all_of(dateField), all_of(weight)) |>
        dplyr::mutate(
          dateField = !!sym(dateField),
          weight = !!sym(weight)
        ) |>
        dplyr::group_by(dateField) |>
        dplyr::summarise(weight = sum(weight, na.rm = TRUE))
    } else {
      df <- df |>
        dplyr::select(all_of(dateField)) |>
        dplyr::mutate(
          dateField = !!sym(dateField),
          weight = 1
        ) |>
        dplyr::group_by(dateField) |>
        dplyr::summarise(weight = sum(weight, na.rm = TRUE))
    }

    result <- list()

    for (timeRep in timeRepresentations) {
      # Data handling and conversion to regular tsibble
      if (timeRep == "Day") {
        processedData <- df |>
          dplyr::rename(timeGroup = dateField)
      } else if (timeRep == "Month") {
        processedData <- df |>
          dplyr::mutate(timeGroup = tsibble::yearmonth(dateField)) |>
          dplyr::select("timeGroup", "weight")
      } else if (timeRep == "Quarter") {
        processedData <- df |>
          dplyr::mutate(timeGroup = tsibble::yearquarter(dateField)) |>
          dplyr::select("timeGroup", "weight")
      } else if (timeRep == "Week") {
        processedData <- df |>
          dplyr::mutate(timeGroup = tsibble::yearweek(dateField)) |>
          dplyr::select("timeGroup", "weight")
      } else if (timeRep == "Year") {
        processedData <- df |>
          dplyr::mutate(timeGroup = format(dateField, "%Y") |> as.integer()) |>
          dplyr::select("timeGroup", "weight")
      }

      processedData <- processedData |>
        dplyr::group_by(.data$timeGroup) |>
        dplyr::summarise(weight = sum(weight)) |>
        tsibble::as_tsibble(index = .data$timeGroup) |>
        tsibble::fill_gaps(weight = 0)

      # Calculate model
      model <- processedData |>
        fabletools::model(feasts::STL(weight ~ season(window = "periodic")))

      # Extract components and plot
      components <- model |> fabletools::components()

      # Create plot
      plot <- components |>
        feasts::autoplot() +
        ggplot2::ggtitle(sprintf("Unit: %s (%s)", timeRep, dateField)) +
        ggplot2::labs(x = "Time", y = "Value", subtitle = "Seasonal-Trend Decomposition") +
        ggplot2::theme_minimal() +
        ggplot2::scale_color_viridis_d()

      # Store results in the list
      result[[timeRep]] <-
        list(
          processedData = processedData,
          model = model,
          components = components,
          plot = plot
        )
    }

    return(result)
  }

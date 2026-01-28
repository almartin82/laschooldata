# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Louisiana
# LEAP assessment data.
#
# Data source: Louisiana Department of Education (LDOE)
# Assessment: LEAP 2025 (Louisiana Educational Assessment Program)
# Available years: 2018-2025 (no 2020 due to COVID waiver)
#
# Proficiency levels:
# - Unsatisfactory (Level 1)
# - Approaching Basic (Level 2)
# - Basic (Level 3)
# - Mastery (Level 4)
# - Advanced (Level 5)
#
# NOTE: LDOE website uses Cloudflare protection. If automated downloads fail,
# use import_local_assessment() with manually downloaded files.
#
# ==============================================================================


#' Fetch Louisiana LEAP assessment data
#'
#' Downloads and processes LEAP assessment data from the Louisiana Department
#' of Education. Includes data from 2018-2025 (no 2020 due to COVID waiver).
#'
#' Proficiency levels:
#' - **Unsatisfactory** (Level 1): Below grade level
#' - **Approaching Basic** (Level 2): Near grade level
#' - **Basic** (Level 3): At grade level
#' - **Mastery** (Level 4): Above grade level (proficient)
#' - **Advanced** (Level 5): Well above grade level (proficient)
#'
#' "Proficient" typically means Mastery + Advanced.
#'
#' @param end_year School year end (2023-24 = 2024). Valid range: 2018-2025 (no 2020).
#' @param level Level of data to fetch: "all" (default), "state_lea", or "school"
#' @param tidy If TRUE (default), returns data in long (tidy) format with proficiency_level
#'   column. If FALSE, returns wide format with separate pct_* columns.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Data frame with assessment data
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 LEAP assessment data
#' assess_2024 <- fetch_assessment(2024)
#'
#' # Get only state and district level data
#' state_dist <- fetch_assessment(2024, level = "state_lea")
#'
#' # Get wide format (pct columns not pivoted)
#' assess_wide <- fetch_assessment(2024, tidy = FALSE)
#'
#' # Force fresh download
#' assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
#' }
fetch_assessment <- function(end_year, level = "all", tidy = TRUE, use_cache = TRUE) {

  # Get available years
  available <- get_available_assessment_years()

  # Special handling for 2020 (COVID waiver year)
  if (end_year == 2020) {
    stop("2020 assessment data is not available due to COVID-19 testing waiver. ",
         "No statewide testing was administered in Spring 2020.")
  }

  # Validate year
  if (!end_year %in% available$years) {
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "), ". ",
      "Got: ", end_year, "\n",
      "Note: 2020 had no testing due to COVID-19 pandemic."
    ))
  }

  # Validate level
  level <- tolower(level)
  if (!level %in% c("all", "state_lea", "school")) {
    stop("level must be one of 'all', 'state_lea', 'school'")
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "assessment_tidy" else "assessment_wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached assessment data for", end_year))
    df <- read_cache(end_year, cache_type)

    # Filter by level if needed
    if (level != "all") {
      if (level == "state_lea") {
        df <- df[df$type %in% c("State", "District"), ]
      } else if (level == "school") {
        df <- df[df$type == "School", ]
      }
    }

    return(df)
  }

  # Get raw data from LDOE
  raw <- get_raw_assessment(end_year, level)

  # Check if we got any data
  if (length(raw) == 0 || all(sapply(raw, nrow) == 0)) {
    warning(paste(
      "No assessment data available for year", end_year, ".",
      "\nThe LDOE website may be blocking automated downloads.",
      "\nTry downloading manually from:",
      "\n  https://doe.louisiana.gov/data-and-reports/elementary-and-middle-school-performance",
      "\nThen use import_local_assessment() to load the file."
    ))
    return(if (tidy) create_empty_tidy_assessment() else create_empty_assessment_result(end_year))
  }

  # Process to standard schema
  processed <- process_assessment(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_assessment(processed)
  } else {
    # Add aggregation flags to wide format too
    processed <- id_assessment_aggs(processed)
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#' Note: 2020 is automatically excluded (COVID-19 testing waiver).
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param level Level of data to fetch: "all" (default), "state_lea", or "school"
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' assess_multi <- fetch_assessment_multi(2022:2024)
#'
#' # Get post-COVID recovery years
#' recovery <- fetch_assessment_multi(2021:2024)
#'
#' # Track proficiency trends at state level
#' assess_multi |>
#'   dplyr::filter(is_state, subject == "Math", grade == "All") |>
#'   dplyr::filter(proficiency_level %in% c("mastery", "advanced")) |>
#'   dplyr::group_by(end_year) |>
#'   dplyr::summarize(pct_proficient = sum(pct, na.rm = TRUE))
#' }
fetch_assessment_multi <- function(end_years, level = "all", tidy = TRUE, use_cache = TRUE) {

  # Get available years
  available <- get_available_assessment_years()

  # Remove 2020 if present (COVID waiver year)
  if (2020 %in% end_years) {
    warning("2020 excluded: No assessment data due to COVID-19 testing waiver.")
    end_years <- end_years[end_years != 2020]
  }

  # Validate years
  invalid_years <- end_years[!end_years %in% available$years]
  if (length(invalid_years) > 0) {
    stop(paste0(
      "Invalid years: ", paste(invalid_years, collapse = ", "), "\n",
      "Valid years are: ", paste(available$years, collapse = ", ")
    ))
  }

  if (length(end_years) == 0) {
    stop("No valid years to fetch")
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      tryCatch({
        fetch_assessment(yr, level = level, tidy = tidy, use_cache = use_cache)
      }, error = function(e) {
        warning(paste("Failed to fetch year", yr, ":", e$message))
        if (tidy) create_empty_tidy_assessment() else create_empty_assessment_result(yr)
      })
    }
  )

  # Combine, filtering out empty data frames
  results <- results[sapply(results, nrow) > 0]

  if (length(results) == 0) {
    warning("No data fetched for any year")
    return(if (tidy) create_empty_tidy_assessment() else create_empty_assessment_result(end_years[1]))
  }

  dplyr::bind_rows(results)
}


#' Get assessment data for a specific district
#'
#' Convenience function to fetch assessment data for a single district (parish).
#'
#' @param end_year School year end
#' @param district_id 3-digit parish code (e.g., "036" for Orleans)
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified district
#' @export
#' @examples
#' \dontrun{
#' # Get East Baton Rouge (district 017) assessment data
#' ebr_assess <- fetch_district_assessment(2024, "017")
#'
#' # Get Orleans Parish (district 036) data
#' orleans_assess <- fetch_district_assessment(2024, "036")
#' }
fetch_district_assessment <- function(end_year, district_id, tidy = TRUE, use_cache = TRUE) {

  # Normalize district_id to 3 digits
  district_id <- sprintf("%03d", as.integer(district_id))

  # Fetch state_lea level data (faster than fetching all)
  df <- fetch_assessment(end_year, level = "state_lea", tidy = tidy, use_cache = use_cache)

  # Filter to requested district
  df |>
    dplyr::filter(district_id == !!district_id)
}


#' Get assessment data for a specific school
#'
#' Convenience function to fetch assessment data for a single school.
#'
#' @param end_year School year end
#' @param school_id 6-digit school code
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cached data
#' @return Data frame filtered to specified school
#' @export
#' @examples
#' \dontrun{
#' # Get a specific school's assessment data
#' school_assess <- fetch_school_assessment(2024, "036001")
#' }
fetch_school_assessment <- function(end_year, school_id, tidy = TRUE, use_cache = TRUE) {

  # Normalize school_id to 6 digits
  school_id <- sprintf("%06d", as.integer(school_id))

  # Fetch school-level data
  df <- fetch_assessment(end_year, level = "school", tidy = tidy, use_cache = use_cache)

  # Filter to requested school
  df |>
    dplyr::filter(school_id == !!school_id)
}

# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from the
# Louisiana Department of Education (LDOE).
#
# Data sources:
# - LEAP 2025: 2018-present, grades 3-8 and high school
# - Proficiency levels: Unsatisfactory, Approaching Basic, Basic, Mastery, Advanced
# - Subjects: ELA, Math, Science, Social Studies
#
# NOTE: The LDOE website (doe.louisiana.gov) uses Cloudflare protection which
# may block automated downloads. If direct downloads fail, use import_local_assessment()
# with manually downloaded files.
#
# ==============================================================================


#' Get available assessment years for Louisiana
#'
#' Returns the years for which LEAP assessment data is available from LDOE.
#' Note: 2020 data is not available due to COVID-19 testing waiver.
#'
#' @return Named list with min_year, max_year, years vector, and note about 2020
#' @export
#' @examples
#' get_available_assessment_years()
get_available_assessment_years <- function() {
  list(
    min_year = 2018,
    max_year = 2025,
    # 2020 excluded due to COVID testing waiver
    years = c(2018, 2019, 2021:2025),
    covid_waiver_year = 2020,
    note = "2020 assessment data unavailable due to COVID-19 testing waiver"
  )
}


#' Get assessment URL for a given year and level
#'
#' Constructs the URL for downloading LEAP assessment data from LDOE.
#' URLs follow patterns discovered from louisianabelieves.com/doe.louisiana.gov.
#'
#' @param end_year School year end
#' @param level One of "state_lea" (state and district), "school"
#' @param file_type One of "mastery_summary", "achievement_level", "subgroup"
#' @return URL string or NULL if not found
#' @keywords internal
get_assessment_url <- function(end_year, level = "state_lea", file_type = "mastery_summary") {

  # Base URL for test results data
  # Note: louisianabelieves.com redirects to doe.louisiana.gov
  base_url <- "https://doe.louisiana.gov/docs/default-source/"

  # URL patterns by year
  # Based on discovered patterns from search results
  url_patterns <- list(
    "2025" = list(
      state_lea_mastery = "data-management/2025-state-lea-leap-2025-mastery-summary.xlsx",
      school_mastery = "test-results/2025-school-leap-2025-mastery-summary.xlsx",
      state_lea_subgroup = "test-results/2025-state-lea-leap-2025-mastery-subgroup-summary.xlsx",
      school_subgroup = "test-results/2025-school-leap-2025-mastery-subgroup-summary.xlsx"
    ),
    "2024" = list(
      state_lea_mastery = "test-results/2024-state-lea-leap-2025-mastery-summary.xlsx",
      school_mastery = "test-results/2024-school-leap-2025-mastery-summary.xlsx",
      state_lea_subgroup = "test-results/2024-state-lea-leap-2025-mastery-subgroup-summary.xlsx",
      school_subgroup = "test-results/2024-school-leap-2025-mastery-subgroup-summary.xlsx"
    ),
    "2023" = list(
      state_lea_mastery = "test-results/2023-state-lea-leap-2025-mastery-summary.xlsx",
      school_mastery = "test-results/2023-school-leap-2025-mastery-summary.xlsx",
      state_lea_subgroup = "test-results/2023-state-lea-leap-2025-mastery-subgroup-summary.xlsx"
    ),
    "2022" = list(
      state_lea_mastery = "test-results/2022-state-lea-leap-2025-mastery-summary.xlsx",
      school_mastery = "test-results/2022-school-leap-2025-mastery-summary.xlsx"
    ),
    "2021" = list(
      state_lea_mastery = "test-results/2021-state-lea-leap-2025-mastery-summary.xlsx",
      school_mastery = "test-results/2021-school-leap-2025-mastery-summary.xlsx"
    ),
    "2019" = list(
      state_lea_mastery = "test-results/2019-state-lea-leap-2025-mastery-summary.xlsx",
      school_mastery = "test-results/2019-school-leap-2025-mastery-summary.xlsx"
    ),
    "2018" = list(
      state_lea_mastery = "test-results/spring-2018-leap-2025-state-lea-school-mastery-summary.xlsx"
    )
  )

  year_str <- as.character(end_year)

  if (!year_str %in% names(url_patterns)) {
    return(NULL)
  }

  # Build the key for the specific file type
  key <- paste0(level, "_", file_type)

  if (!key %in% names(url_patterns[[year_str]])) {
    # Try without level for combined files (2018)
    if ("state_lea_mastery" %in% names(url_patterns[[year_str]]) && file_type == "mastery_summary") {
      key <- "state_lea_mastery"
    } else {
      return(NULL)
    }
  }

  paste0(base_url, url_patterns[[year_str]][[key]])
}


#' Download raw assessment data from LDOE
#'
#' Downloads LEAP assessment data from Louisiana DOE.
#'
#' IMPORTANT: The LDOE website uses Cloudflare protection which may block
#' automated downloads. If this function fails with a 403 error, you have
#' two options:
#' 1. Use import_local_assessment() with a manually downloaded file
#' 2. Try again later (Cloudflare sometimes allows requests)
#'
#' @param end_year School year end (2018-2025, excluding 2020)
#' @param level One of "all", "state_lea", "school"
#' @return List with data frames for each level downloaded
#' @keywords internal
get_raw_assessment <- function(end_year, level = "all") {

  # Validate year
  available <- get_available_assessment_years()
  if (!end_year %in% available$years) {
    if (end_year == 2020) {
      stop("Assessment data is not available for 2020 due to COVID-19 testing waiver.")
    }
    stop(paste0(
      "end_year must be one of: ", paste(available$years, collapse = ", "),
      "\nGot: ", end_year
    ))
  }

  message(paste("Downloading LDOE LEAP assessment data for", end_year, "..."))

  # Determine which levels to download
  level <- tolower(level)
  if (level == "all") {
    levels_to_download <- c("state_lea", "school")
  } else if (level %in% c("state_lea", "school")) {
    levels_to_download <- level
  } else {
    stop("level must be one of 'all', 'state_lea', 'school'")
  }

  # Download each level
  result <- list()

  for (lv in levels_to_download) {
    message(paste("  Downloading", lv, "level data..."))
    df <- download_assessment_file(end_year, lv)
    if (!is.null(df) && nrow(df) > 0) {
      result[[lv]] <- df
    }
  }

  if (length(result) == 0) {
    warning(paste(
      "Could not download assessment data for", end_year, ".",
      "\nThe LDOE website may be blocking automated downloads.",
      "\nTry using import_local_assessment() with a manually downloaded file.",
      "\nDownload URL: ", get_assessment_url(end_year, "state_lea", "mastery_summary")
    ))
  }

  result
}


#' Download a single assessment file
#'
#' @param end_year School year end
#' @param level One of "state_lea", "school"
#' @return Data frame or NULL if download fails
#' @keywords internal
download_assessment_file <- function(end_year, level) {

  url <- get_assessment_url(end_year, level, "mastery_summary")

  if (is.null(url)) {
    message(paste("  No URL pattern defined for", end_year, level))
    return(NULL)
  }

  # Create temp file
  tname <- tempfile(
    pattern = paste0("ldoe_leap_", level, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  result <- tryCatch({
    # Try download with browser-like headers
    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(180),
      httr::config(
        followlocation = TRUE
      ),
      httr::add_headers(
        "Accept" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/octet-stream,*/*",
        "Accept-Language" = "en-US,en;q=0.9",
        "Cache-Control" = "no-cache",
        "Referer" = "https://doe.louisiana.gov/data-and-reports/elementary-and-middle-school-performance"
      ),
      httr::user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    )

    if (httr::http_error(response)) {
      status <- httr::status_code(response)
      if (status == 403) {
        message(paste("  Access blocked (HTTP 403) for", level))
        message("  The LDOE website is blocking automated downloads.")
        message("  Please download manually from: ", url)
      } else {
        message(paste("  HTTP error", status, "for", level))
      }
      unlink(tname)
      return(NULL)
    }

    # Check file size and content type
    file_info <- file.info(tname)
    content_type <- httr::headers(response)[["content-type"]]

    if (is.na(file_info$size) || file_info$size < 1000) {
      message(paste("  Downloaded file too small for", level))
      unlink(tname)
      return(NULL)
    }

    # Check if we got HTML instead of Excel (Cloudflare challenge page)
    if (!is.null(content_type) && grepl("text/html", content_type)) {
      message(paste("  Received HTML instead of Excel for", level, "(Cloudflare block)"))
      unlink(tname)
      return(NULL)
    }

    # Read Excel file
    df <- readxl::read_excel(tname, col_types = "text")

    unlink(tname)

    if (nrow(df) == 0) {
      message(paste("  Empty data for", level))
      return(NULL)
    }

    # Add source level indicator
    df$source_level <- level

    df

  }, error = function(e) {
    message(paste("  Download error for", level, ":", e$message))
    unlink(tname)
    NULL
  })

  result
}


#' Import local assessment data file
#'
#' Imports a LEAP assessment Excel file that was downloaded manually.
#' Use this when the automatic download is blocked by Cloudflare.
#'
#' To download the file manually:
#' 1. Visit https://doe.louisiana.gov/data-and-reports/elementary-and-middle-school-performance
#' 2. Download the LEAP mastery summary file for your desired year
#' 3. Pass the file path to this function
#'
#' @param file_path Path to the downloaded Excel file
#' @param end_year School year end (for labeling)
#' @return Data frame with assessment data
#' @export
#' @examples
#' \dontrun{
#' # Download file manually, then import
#' assess <- import_local_assessment(
#'   "~/Downloads/2024-state-lea-leap-2025-mastery-summary.xlsx",
#'   end_year = 2024
#' )
#' }
import_local_assessment <- function(file_path, end_year) {

  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }

  message(paste("Importing local assessment file for", end_year, "..."))

  # Read Excel file
  df <- readxl::read_excel(file_path, col_types = "text")

  if (nrow(df) == 0) {
    stop("File contains no data")
  }

  # Add end_year if not present
  if (!"end_year" %in% tolower(names(df))) {
    df$end_year <- as.character(end_year)
  }

  # Determine source level from file name or content
  if (grepl("school", tolower(basename(file_path))) && !grepl("state", tolower(basename(file_path)))) {
    df$source_level <- "school"
  } else {
    df$source_level <- "state_lea"
  }

  message(paste("  Loaded", nrow(df), "rows"))

  df
}


#' Create empty assessment raw data frame
#'
#' Returns an empty data frame with expected column structure for assessment data.
#'
#' @return Empty data frame with assessment columns
#' @keywords internal
create_empty_assessment_raw <- function() {
  data.frame(
    school_system_code = character(0),
    school_system_name = character(0),
    school_code = character(0),
    school_name = character(0),
    grade = character(0),
    subject = character(0),
    total_students = character(0),
    pct_unsatisfactory = character(0),
    pct_approaching_basic = character(0),
    pct_basic = character(0),
    pct_mastery = character(0),
    pct_advanced = character(0),
    source_level = character(0),
    stringsAsFactors = FALSE
  )
}

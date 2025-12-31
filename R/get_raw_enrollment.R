# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from LDOE.
# Data comes from the Multi Stats reports on louisianabelieves.com.
#
# Data is available in two formats:
# - Modern format (2019+): "Oct 20XX Multi Stats (Total by Site and School System)"
# - Legacy format (2007-2018): "Oct 20XX Multi Stats" variants with different naming
#
# The Multi Stats files contain:
# - Site-level (school) enrollment by demographics and grade
# - LEA-level (district/parish) enrollment summaries
# - Enrollment counts for MFP (Minimum Foundation Program) and Total
#
# ==============================================================================

#' Download raw enrollment data from LDOE
#'
#' Downloads site and LEA enrollment data from LDOE's Multi Stats files.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with site and lea data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  if (end_year < 2007 || end_year > 2025) {
    stop("end_year must be between 2007 and 2025")
  }

  message(paste("Downloading LDOE enrollment data for", end_year, "..."))

  # Build URL based on year and naming convention
  url <- build_multistats_url(end_year)

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("ldoe_multistats_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  # Download the file
  tryCatch({
    message(paste("  Downloading from:", url))

    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(300),
      httr::user_agent("Mozilla/5.0 (compatible; R laschooldata package)")
    )

    # Check for HTTP errors
    if (httr::http_error(response)) {
      # Try alternate URL patterns
      alt_urls <- get_alternate_urls(end_year)
      success <- FALSE

      for (alt_url in alt_urls) {
        message(paste("  Trying alternate URL:", alt_url))
        response <- httr::GET(
          alt_url,
          httr::write_disk(tname, overwrite = TRUE),
          httr::timeout(300),
          httr::user_agent("Mozilla/5.0 (compatible; R laschooldata package)")
        )
        if (!httr::http_error(response)) {
          success <- TRUE
          break
        }
      }

      if (!success) {
        stop(paste("HTTP error:", httr::status_code(response),
                   "\nCould not find Multi Stats file for year", end_year))
      }
    }

    # Verify file is valid Excel
    file_info <- file.info(tname)
    if (file_info$size < 1000) {
      stop(paste("Downloaded file is too small, likely an error page for year", end_year))
    }

  }, error = function(e) {
    stop(paste("Failed to download Multi Stats data for year", end_year,
               "\nError:", e$message))
  })

  # Read the Excel file - it typically has multiple sheets
  message("  Reading Excel file...")

  # Get sheet names
  sheets <- readxl::excel_sheets(tname)

  # Find the site-level and LEA-level sheets
  # Common patterns: "Site", "School System", "LEA", "District"
  site_sheet <- find_sheet(sheets, c("Site", "site", "School", "school", "Campus"))
  lea_sheet <- find_sheet(sheets, c("System", "LEA", "District", "Parish"))

  # If we can't find specific sheets, try reading first sheet
  if (is.null(site_sheet) && is.null(lea_sheet)) {
    message("  Could not identify specific sheets, reading all data from first sheet...")
    all_data <- readxl::read_excel(
      tname,
      sheet = 1,
      col_types = "text"
    )

    # Split into site and LEA based on content
    result <- split_combined_data(all_data, end_year)
  } else {
    # Read identified sheets
    site_data <- NULL
    lea_data <- NULL

    if (!is.null(site_sheet)) {
      message(paste("  Reading site sheet:", site_sheet))
      site_data <- readxl::read_excel(
        tname,
        sheet = site_sheet,
        col_types = "text"
      )
    }

    if (!is.null(lea_sheet)) {
      message(paste("  Reading LEA sheet:", lea_sheet))
      lea_data <- readxl::read_excel(
        tname,
        sheet = lea_sheet,
        col_types = "text"
      )
    }

    # If only one sheet found, try to split it
    if (is.null(site_data) && !is.null(lea_data)) {
      result <- list(site = lea_data, lea = lea_data)
    } else if (!is.null(site_data) && is.null(lea_data)) {
      result <- list(site = site_data, lea = site_data)
    } else {
      result <- list(site = site_data, lea = lea_data)
    }
  }

  # Clean up temp file
  unlink(tname)

  # Add end_year to data
  if (!is.null(result$site)) {
    result$site$end_year <- end_year
  }
  if (!is.null(result$lea)) {
    result$lea$end_year <- end_year
  }

  result
}


#' Build Multi Stats URL for a given year
#'
#' Constructs the URL for downloading Multi Stats files based on year.
#' LDOE uses varying URL patterns across years.
#'
#' @param end_year School year end
#' @return URL string
#' @keywords internal
build_multistats_url <- function(end_year) {

  # Base URL for louisianabelieves.com data management
  base_url <- "https://www.louisianabelieves.com/docs/default-source/data-management/"

  # Construct month string (Oct for October 1 counts)
  # LDOE uses October 1 as their enrollment snapshot date
  month <- "oct"

  # Modern format (2020+): consistent naming with underscores
  if (end_year >= 2020) {
    # Pattern: oct-YYYY-multi-stats-(total-by-site-and-school-system)_web.xlsx
    # or: oct-YYYY-multi-stats-(total-by-site-and-school-system).xlsx
    filename <- paste0(month, "-", end_year, "-multi-stats-(total-by-site-and-school-system)_web.xlsx")
    return(paste0(base_url, filename))
  }

  # 2019: Transition year
  if (end_year == 2019) {
    filename <- paste0(month, "-", end_year, "-multi-stats-(total-by-site-and-school-system).xlsx")
    return(paste0(base_url, filename))
  }

  # Legacy format (2007-2018): Various patterns
  # Pattern: oct-YYYY-multi-stats-(total-by-site).xlsx
  # or: oct-YYYY-multi-stats-(mfp-by-site).xlsx
  filename <- paste0(month, "-", end_year, "-multi-stats-(total-by-site).xlsx")
  paste0(base_url, filename)
}


#' Get alternate URL patterns for a year
#'
#' Returns a list of alternate URL patterns to try if primary URL fails.
#'
#' @param end_year School year end
#' @return Vector of alternate URLs
#' @keywords internal
get_alternate_urls <- function(end_year) {

  base_url <- "https://www.louisianabelieves.com/docs/default-source/data-management/"

  # Generate various URL patterns that LDOE has used
  patterns <- c(
    # With _web suffix
    paste0("oct-", end_year, "-multi-stats-(total-by-site-and-school-system)_web.xlsx"),
    # Without _web suffix
    paste0("oct-", end_year, "-multi-stats-(total-by-site-and-school-system).xlsx"),
    # Just site
    paste0("oct-", end_year, "-multi-stats-(total-by-site).xlsx"),
    # MFP variant
    paste0("oct-", end_year, "-multi-stats-(mfp-by-site).xlsx"),
    # With sfvrsn parameter (Sitefinity versioning)
    paste0("oct-", end_year, "-multi-stats-(total-by-site-and-school-system)_web.xlsx?sfvrsn=2"),
    # Lowercase multi stats
    paste0("oct-", end_year, "-multistats-(total-by-site-and-school-system).xlsx"),
    # Space replaced with hyphen
    paste0("oct-", end_year, "-multi-stats.xlsx"),
    # February data as fallback
    paste0("feb-", end_year, "-multi-stats-(total-by-site-and-school-system).xlsx")
  )

  paste0(base_url, patterns)
}


#' Find matching sheet name
#'
#' @param sheets Vector of sheet names
#' @param patterns Vector of patterns to match
#' @return Matching sheet name or NULL
#' @keywords internal
find_sheet <- function(sheets, patterns) {
  for (pattern in patterns) {
    matches <- grep(pattern, sheets, ignore.case = TRUE, value = TRUE)
    if (length(matches) > 0) {
      return(matches[1])
    }
  }
  NULL
}


#' Split combined data into site and LEA
#'
#' When data is in a single sheet, split based on content.
#'
#' @param df Combined data frame
#' @param end_year School year end
#' @return List with site and lea data frames
#' @keywords internal
split_combined_data <- function(df, end_year) {

  # Look for columns that indicate site vs LEA level
  cols <- tolower(names(df))

  # If there's a site_code or school_name column, it's likely combined

  if (any(grepl("site|school|campus", cols))) {
    # Data includes both - need to separate
    # LEA rows typically have empty site codes or "ALL" values

    site_col <- grep("site.*code|site_code|sitecode", cols, value = TRUE)[1]

    if (!is.na(site_col)) {
      # Split based on whether site code is populated
      site_data <- df[!is.na(df[[site_col]]) & df[[site_col]] != "", ]
      lea_data <- df[is.na(df[[site_col]]) | df[[site_col]] == "", ]

      return(list(site = site_data, lea = lea_data))
    }
  }

  # Can't split - return same data for both
  list(site = df, lea = df)
}


#' Download file with retry logic
#'
#' @param url URL to download
#' @param destfile Destination file path
#' @param max_retries Maximum number of retry attempts
#' @return TRUE if successful
#' @keywords internal
download_with_retry <- function(url, destfile, max_retries = 3) {

  for (i in seq_len(max_retries)) {
    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(destfile, overwrite = TRUE),
        httr::timeout(300),
        httr::user_agent("Mozilla/5.0 (compatible; R laschooldata package)")
      )

      if (!httr::http_error(response)) {
        return(TRUE)
      }

    }, error = function(e) {
      if (i < max_retries) {
        message(paste("  Retry", i, "of", max_retries, "..."))
        Sys.sleep(2)
      }
    })
  }

  FALSE
}

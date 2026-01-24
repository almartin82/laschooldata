# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from LDOE.
# Data comes from the Multi Stats reports on louisianabelieves.com.
#
# IMPORTANT: Louisiana Multi Stats Excel files have a specific structure:
# - Row 1: Title (e.g., "Multiple Statistics By School System...")
# - Row 2: FERPA disclaimer
# - Row 3: Main category headers (e.g., "School System", "Students by Gender")
# - Row 4: Column sub-headers (e.g., "% Female", "% Male", "American Indian")
# - Row 5: Blank row
# - Row 6+: Data rows
#
# Key data quirks:
# - Gender is stored as PERCENTAGES ("48.8%", "51.2%"), not counts
# - LEP is also stored as percentages
# - Race/ethnicity are stored as counts
# - Grade enrollment is stored as counts
#
# Available years: 2019-2024 (confirmed working)
#
# ==============================================================================

#' Download raw enrollment data from LDOE
#'
#' Downloads site and LEA enrollment data from LDOE's Multi Stats files.
#' Properly handles the multi-row header structure.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with site and lea data frames, with proper column names
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year - only 2019-2024 are confirmed working
  if (end_year < 2019 || end_year > 2024) {
    stop("end_year must be between 2019 and 2024 (confirmed available years)")
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

  # Download the file with retry logic
  tryCatch({
    message(paste("  Downloading from:", url))

    response <- download_with_retry(url, tname)

    # Check for HTTP errors
    if (is.null(response) || httr::http_error(response)) {
      # Try alternate URL patterns
      alt_urls <- get_alternate_urls(end_year)
      success <- FALSE

      for (alt_url in alt_urls) {
        message(paste("  Trying alternate URL:", alt_url))
        response <- download_with_retry(alt_url, tname, quiet = TRUE)
        if (!is.null(response) && !httr::http_error(response)) {
          success <- TRUE
          break
        }
      }

      if (!success) {
        stop(paste("HTTP error:", if (!is.null(response)) httr::status_code(response) else "connection failed",
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
  site_sheet <- find_sheet(sheets, c("Total by Site", "Site"))
  lea_sheet <- find_sheet(sheets, c("Total by School System", "School System"))

  result <- list(site = NULL, lea = NULL)

  if (!is.null(lea_sheet)) {
    message(paste("  Reading LEA sheet:", lea_sheet))
    result$lea <- read_multistats_sheet(tname, lea_sheet, "lea")
  }

  if (!is.null(site_sheet)) {
    message(paste("  Reading site sheet:", site_sheet))
    result$site <- read_multistats_sheet(tname, site_sheet, "site")
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


#' Read a Multi Stats Excel sheet with proper header handling
#'
#' Handles the multi-row header structure of LDOE Multi Stats files.
#'
#' @param file_path Path to Excel file
#' @param sheet_name Name of sheet to read
#' @param sheet_type Either "lea" or "site"
#' @return Data frame with proper column names
#' @keywords internal
read_multistats_sheet <- function(file_path, sheet_name, sheet_type) {

  # Read without column names to see the raw structure
  raw <- readxl::read_excel(
    file_path,
    sheet = sheet_name,
    col_names = FALSE,
    col_types = "text"
  )

  # Row 4 contains the actual column names (1-indexed in R after read)
  # But readxl uses 1-based indexing so row 4 in Excel = row 4 in R
  header_row <- as.character(raw[4, ])

  # Row 3 has category headers that we can use for columns with NA in row 4
  category_row <- as.character(raw[3, ])

  # Build proper column names
  col_names <- character(length(header_row))
  for (i in seq_along(header_row)) {
    if (!is.na(header_row[i]) && header_row[i] != "") {
      col_names[i] <- header_row[i]
    } else if (!is.na(category_row[i]) && category_row[i] != "") {
      col_names[i] <- category_row[i]
    } else {
      col_names[i] <- paste0("col_", i)
    }
  }

  # Clean column names
  col_names <- janitor::make_clean_names(col_names)

  # Data starts at row 6 (after blank row 5)
  # Find the first data row - look for numeric values in first column
  first_data_row <- 6
  for (i in 5:min(10, nrow(raw))) {
    val <- raw[[1]][i]
    if (!is.na(val) && grepl("^\\d{3}$", val)) {
      first_data_row <- i
      break
    }
  }

  # Extract data rows (skip header and blank rows)
  data_df <- raw[first_data_row:nrow(raw), ]
  names(data_df) <- col_names

  # Remove any rows that are completely NA or are footer rows
  data_df <- data_df[!is.na(data_df[[1]]) & data_df[[1]] != "", ]

  # Remove any rows that look like headers (non-numeric first column)
  data_df <- data_df[grepl("^\\d", data_df[[1]]), ]

  data_df
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



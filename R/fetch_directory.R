# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Louisiana Department of Education (LDOE) website.
#
# Data Source: Louisiana DOE School Directory
# URL: https://doe.louisiana.gov/docs/default-source/data-management/
#
# The directory file contains:
# - All Public Schools (main sheet)
# - Public Charter Schools
# - Nonpublic Schools
# - District Superintendents
# - Diocesan Superintendents
#
# ==============================================================================

#' Fetch Louisiana school directory data
#'
#' Downloads and processes school directory data from the Louisiana Department
#' of Education. The directory includes school names, site codes, principal
#' names, addresses, and grades served.
#'
#' @param end_year A school year. Year is the end of the academic year - e.g.,
#'   2025-26 school year is year '2026'. If NULL (default), uses the most
#'   recent available year. Currently only 2026 is available.
#' @param tidy If TRUE (default), returns data with standardized column names.
#'   If FALSE, returns the raw data with original column names.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from LDOE.
#' @param include_charter If TRUE (default), includes charter schools in
#'   the output. Set to FALSE for only traditional public schools.
#' @return Data frame with school directory information including:
#'   \item{end_year}{School year end}
#'   \item{site_code}{School site code (unique identifier)}
#'   \item{parish_code}{Parish code (3-digit)}
#'   \item{district_code}{District/sponsor code (3-digit)}
#'   \item{school_name}{Name of the school}
#'   \item{district_name}{Name of the district/parish}
#'   \item{principal_first_name}{Principal's first name}
#'   \item{principal_last_name}{Principal's last name}
#'   \item{grades_served}{Grades served (e.g., "K-5", "9-12")}
#'   \item{address}{Physical street address}
#'   \item{city}{Physical city}
#'   \item{zip}{Physical ZIP code}
#'   \item{latitude}{Latitude coordinate}
#'   \item{longitude}{Longitude coordinate}
#'   \item{is_charter}{TRUE if school is a charter school}
#' @export
#' @examples
#' \dontrun{
#' # Get current school directory
#' dir <- fetch_directory()
#'
#' # Get only traditional public schools
#' traditional <- fetch_directory(include_charter = FALSE)
#'
#' # Filter to specific parish
#' orleans <- dir |>
#'   dplyr::filter(parish_code == "36")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE,
                            include_charter = TRUE) {

  # Default to most recent year if not specified
  if (is.null(end_year)) {
    end_year <- get_directory_available_years()$max_year
  }

  # Validate year - currently only 2026 is confirmed working
  if (end_year < 2026 || end_year > 2026) {
    stop("end_year must be 2026 (currently the only available year)")
  }

  # Determine cache type
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached directory data for", end_year))
    result <- read_cache(end_year, cache_type)

    # Filter out charters if requested
    if (!include_charter && "is_charter" %in% names(result)) {
      result <- result[!result$is_charter, ]
    }

    return(result)
  }

  # Get raw data from LDOE
  raw <- get_raw_directory(end_year)

  # Process to standard schema
  if (tidy) {
    processed <- process_directory(raw, end_year, include_charter)
  } else {
    processed <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  # Filter out charters if requested (for tidy data)
  if (!include_charter && "is_charter" %in% names(processed)) {
    processed <- processed[!processed$is_charter, ]
  }

  processed
}


#' Get available years for school directory data
#'
#' Returns the range of years for which school directory data is available.
#'
#' @return A list with:
#'   \item{min_year}{First available year (2026)}
#'   \item{max_year}{Last available year (2026)}
#'   \item{description}{Description of data availability}
#' @export
#' @examples
#' years <- get_directory_available_years()
#' print(years$max_year)
get_directory_available_years <- function() {
  list(
    min_year = 2026,
    max_year = 2026,
    description = paste(
      "Louisiana school directory data from LDOE.",
      "Currently only the 2025-2026 directory (end_year = 2026) is available.",
      "Historical directories may be added as they are discovered."
    )
  )
}


#' Download raw school directory data from LDOE
#'
#' Downloads the school directory Excel file from LDOE.
#'
#' @param end_year School year end (2025-26 = 2026)
#' @return List with data frames for each sheet (public, charter, nonpublic)
#' @keywords internal
get_raw_directory <- function(end_year) {

  # Validate year
  if (end_year < 2026 || end_year > 2026) {
    stop("end_year must be 2026 (currently the only available year)")
  }

  message(paste("Downloading LDOE school directory for", end_year, "..."))

  # Build URL
  url <- build_directory_url(end_year)

  # Create temp file for download
  tname <- tempfile(
    pattern = paste0("ldoe_directory_", end_year, "_"),
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
      stop(paste("HTTP error:", httr::status_code(response),
                 "\nCould not download school directory for year", end_year))
    }

    # Verify file is valid Excel
    file_info <- file.info(tname)
    if (file_info$size < 10000) {
      stop(paste("Downloaded file is too small, likely an error page for year", end_year))
    }

  }, error = function(e) {
    stop(paste("Failed to download school directory for year", end_year,
               "\nError:", e$message))
  })

  # Read the Excel file sheets
  message("  Reading Excel file...")

  sheets <- readxl::excel_sheets(tname)

  result <- list()

  # Read All Public Schools sheet
  public_sheet <- find_directory_sheet(sheets, c("All Public", "Public Schools"))
  if (!is.null(public_sheet)) {
    message(paste("  Reading sheet:", public_sheet))
    result$public <- readxl::read_excel(tname, sheet = public_sheet)
  }

  # Read Public Charter Schools sheet
  charter_sheet <- find_directory_sheet(sheets, c("Charter", "Public Charter"))
  if (!is.null(charter_sheet)) {
    message(paste("  Reading sheet:", charter_sheet))
    result$charter <- readxl::read_excel(tname, sheet = charter_sheet)
  }

  # Read Nonpublic Schools sheet (for reference, not included by default)
  nonpublic_sheet <- find_directory_sheet(sheets, c("Nonpublic"))
  if (!is.null(nonpublic_sheet)) {
    message(paste("  Reading sheet:", nonpublic_sheet))
    result$nonpublic <- readxl::read_excel(tname, sheet = nonpublic_sheet)
  }

  # Clean up temp file
  unlink(tname)

  result
}


#' Build school directory URL for a given year
#'
#' Constructs the URL for downloading the school directory file.
#'
#' @param end_year School year end
#' @return URL string
#' @keywords internal
build_directory_url <- function(end_year) {

  # Base URL for Louisiana DOE data management
  base_url <- "https://doe.louisiana.gov/docs/default-source/data-management/"

  # Currently known URL pattern for 2025-2026 directory
  if (end_year == 2026) {
    filename <- "2025-2026-school-directory.xlsx"
    return(paste0(base_url, filename))
  }

  # For future years, try to guess the pattern
  start_year <- end_year - 1
  filename <- paste0(start_year, "-", end_year, "-school-directory.xlsx")
  paste0(base_url, filename)
}


#' Find matching sheet name in directory Excel file
#'
#' @param sheets Vector of sheet names
#' @param patterns Vector of patterns to match
#' @return Matching sheet name or NULL
#' @keywords internal
find_directory_sheet <- function(sheets, patterns) {
  for (pattern in patterns) {
    matches <- grep(pattern, sheets, ignore.case = TRUE, value = TRUE)
    if (length(matches) > 0) {
      return(matches[1])
    }
  }
  NULL
}


#' Process raw school directory data
#'
#' Transforms raw directory data into a standardized schema.
#'
#' @param raw_data List containing public, charter, and nonpublic data frames
#' @param end_year School year end
#' @param include_charter Whether to include charter schools
#' @return Processed data frame with standardized columns
#' @keywords internal
process_directory <- function(raw_data, end_year, include_charter = TRUE) {

  result_list <- list()

  # Process public schools
  if (!is.null(raw_data$public) && nrow(raw_data$public) > 0) {
    public_df <- process_directory_sheet(raw_data$public, end_year, is_charter = FALSE)
    result_list$public <- public_df
  }

  # Process charter schools if requested
  if (include_charter && !is.null(raw_data$charter) && nrow(raw_data$charter) > 0) {
    charter_df <- process_directory_sheet(raw_data$charter, end_year, is_charter = TRUE)
    result_list$charter <- charter_df
  }

  # Combine all
  result <- dplyr::bind_rows(result_list)

  # Sort by district_code, site_code
  if (nrow(result) > 0) {
    result <- result[order(result$district_code, result$site_code), ]
    rownames(result) <- NULL
  }

  result
}


#' Process a single directory sheet
#'
#' @param df Data frame from a directory sheet
#' @param end_year School year end
#' @param is_charter Whether this is a charter school sheet
#' @return Processed data frame
#' @keywords internal
process_directory_sheet <- function(df, end_year, is_charter = FALSE) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result data frame
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    stringsAsFactors = FALSE
  )

  # Site code
  site_col <- find_col(c("^SiteCd$", "^Site.*Code", "^SiteCode"))
  if (!is.null(site_col)) {
    result$site_code <- trimws(as.character(df[[site_col]]))
  }

  # Parish code
  parish_col <- find_col(c("^ParishCd$", "^Parish.*Code"))
  if (!is.null(parish_col)) {
    # Ensure 2-digit format with leading zero
    result$parish_code <- sprintf("%02s", trimws(as.character(df[[parish_col]])))
  }

  # District/Sponsor code
  sponsor_col <- find_col(c("^SponsorCd$", "^Sponsor.*Code", "^DistrictCd"))
  if (!is.null(sponsor_col)) {
    # Ensure 3-digit format with leading zeros
    result$district_code <- sprintf("%03s", trimws(as.character(df[[sponsor_col]])))
  }

  # School name
  site_name_col <- find_col(c("^SiteName$", "^Site.*Name", "^SchoolName"))
  if (!is.null(site_name_col)) {
    result$school_name <- trimws(as.character(df[[site_name_col]]))
  }

  # District/Sponsor name
  sponsor_name_col <- find_col(c("^SponsorName$", "^Sponsor.*Name", "^DistrictName"))
  if (!is.null(sponsor_name_col)) {
    result$district_name <- trimws(as.character(df[[sponsor_name_col]]))
  }

  # Principal first name
  first_name_col <- find_col(c("^FirstName$", "^First.*Name", "^PrincipalFirst"))
  if (!is.null(first_name_col)) {
    result$principal_first_name <- trimws(as.character(df[[first_name_col]]))
  }

  # Principal last name (note: charter sheet has "Lastname" vs "LastName")
  last_name_col <- find_col(c("^LastName$", "^Lastname$", "^Last.*Name", "^PrincipalLast"))
  if (!is.null(last_name_col)) {
    result$principal_last_name <- trimws(as.character(df[[last_name_col]]))
  }

  # Grades served
  grades_col <- find_col(c("^GradeConfigDesc$", "^Grade.*Config", "^Grades"))
  if (!is.null(grades_col)) {
    result$grades_served <- trimws(as.character(df[[grades_col]]))
  }

  # Physical address
  addr_col <- find_col(c("^PhysicalStAddr$", "^Physical.*Addr", "^Address"))
  if (!is.null(addr_col)) {
    result$address <- trimws(as.character(df[[addr_col]]))
  }

  # City
  city_col <- find_col(c("^PhysicalCityAddr$", "^Physical.*City", "^City"))
  if (!is.null(city_col)) {
    result$city <- trimws(as.character(df[[city_col]]))
  }

  # ZIP code
  zip_col <- find_col(c("^PhysicalZipAddr$", "^Physical.*Zip", "^Zip"))
  if (!is.null(zip_col)) {
    result$zip <- trimws(as.character(df[[zip_col]]))
  }

  # State (always Louisiana)
  result$state <- "LA"

  # Latitude
  lat_col <- find_col(c("^Latitude$", "^Lat$"))
  if (!is.null(lat_col)) {
    result$latitude <- as.numeric(df[[lat_col]])
  }

  # Longitude
  lon_col <- find_col(c("^Longitude$", "^Long$", "^Lon$"))
  if (!is.null(lon_col)) {
    result$longitude <- as.numeric(df[[lon_col]])
  }

  # Charter flag
  result$is_charter <- rep(is_charter, n_rows)

  result
}

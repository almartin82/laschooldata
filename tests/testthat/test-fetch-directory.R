# ==============================================================================
# Tests for fetch_directory.R
# ==============================================================================
#
# These tests verify the school directory data fetching functionality.
# Tests are designed to:
# 1. Verify data can be fetched for available years
# 2. Verify data structure and column names
# 3. Check for data quality issues
# 4. Validate charter school filtering
#
# ==============================================================================

# Skip all tests if we're in CI or offline
skip_if_offline <- function() {
  skip_on_cran()
  skip_if_not(
    tryCatch({
      response <- httr::HEAD(
        "https://doe.louisiana.gov",
        httr::timeout(5)
      )
      httr::status_code(response) == 200
    }, error = function(e) FALSE),
    "Louisiana DOE website not reachable"
  )
}


# ==============================================================================
# Tests for get_directory_available_years()
# ==============================================================================

test_that("get_directory_available_years returns expected structure", {
  years <- get_directory_available_years()

  expect_type(years, "list")
  expect_named(years, c("min_year", "max_year", "description"))
  expect_equal(years$min_year, 2025)
  expect_equal(years$max_year, 2025)
  expect_type(years$description, "character")
})


# ==============================================================================
# Tests for fetch_directory() - Year Validation
# ==============================================================================

test_that("fetch_directory rejects invalid years", {
  expect_error(fetch_directory(2024), "2025")
  expect_error(fetch_directory(2026), "2025")
  expect_error(fetch_directory(2020), "2025")
})


# ==============================================================================
# Tests for fetch_directory() - Data Structure
# ==============================================================================

test_that("fetch_directory returns expected columns", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  # Core ID columns
  expect_true("end_year" %in% names(dir))
  expect_true("site_code" %in% names(dir))
  expect_true("parish_code" %in% names(dir))
  expect_true("district_code" %in% names(dir))

  # Name columns
  expect_true("school_name" %in% names(dir))
  expect_true("district_name" %in% names(dir))
  expect_true("principal_first_name" %in% names(dir))
  expect_true("principal_last_name" %in% names(dir))

  # Address columns
  expect_true("address" %in% names(dir))
  expect_true("city" %in% names(dir))
  expect_true("zip" %in% names(dir))
  expect_true("state" %in% names(dir))

  # Other columns
  expect_true("grades_served" %in% names(dir))
  expect_true("is_charter" %in% names(dir))
  expect_true("latitude" %in% names(dir))
  expect_true("longitude" %in% names(dir))
})


test_that("fetch_directory returns reasonable number of schools", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  # Louisiana should have at least 1000 public schools
  expect_gt(nrow(dir), 1000,
    label = "Should have at least 1000 schools")

  # But not more than 3000
  expect_lt(nrow(dir), 3000,
    label = "Should have fewer than 3000 schools")
})


# ==============================================================================
# Tests for Charter School Filtering
# ==============================================================================

test_that("fetch_directory includes charter schools by default", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  # Should have both charter and non-charter schools
  expect_true(any(dir$is_charter == TRUE),
    label = "Should include charter schools")
  expect_true(any(dir$is_charter == FALSE),
    label = "Should include non-charter schools")
})


test_that("fetch_directory can exclude charter schools", {
  skip_if_offline()

  dir_all <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)
  dir_traditional <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE,
                                     include_charter = FALSE)

  # Traditional should be a subset
  expect_lt(nrow(dir_traditional), nrow(dir_all))

  # All schools in traditional should be non-charter
  expect_true(all(dir_traditional$is_charter == FALSE))

  # The difference should equal the number of charter schools
  n_charter_all <- sum(dir_all$is_charter)
  expect_equal(nrow(dir_all) - nrow(dir_traditional), n_charter_all)
})


# ==============================================================================
# Tests for Data Quality
# ==============================================================================

test_that("all schools have required fields", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  # Every school should have a site code
  expect_true(all(!is.na(dir$site_code) & dir$site_code != ""),
    label = "All schools should have site codes")

  # Every school should have a name
  expect_true(all(!is.na(dir$school_name) & dir$school_name != ""),
    label = "All schools should have names")

  # Every school should have a district code
  expect_true(all(!is.na(dir$district_code) & dir$district_code != ""),
    label = "All schools should have district codes")
})


test_that("coordinates are valid when present", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  # Get rows with coordinates
  has_coords <- !is.na(dir$latitude) & !is.na(dir$longitude)

  if (any(has_coords)) {
    lats <- dir$latitude[has_coords]
    lons <- dir$longitude[has_coords]

    # Louisiana latitude: approximately 29-33 degrees N
    expect_true(all(lats > 28 & lats < 34),
      label = "Latitudes should be within Louisiana bounds")

    # Louisiana longitude: approximately -94 to -89 degrees W
    expect_true(all(lons > -95 & lons < -88),
      label = "Longitudes should be within Louisiana bounds")
  }
})


test_that("parish codes have expected format", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  # Parish codes should be 2-digit with leading zeros
  # (Louisiana has 64 parishes numbered 01-64, but also special districts)
  parish_codes <- unique(dir$parish_code)

  # Should have at least 50 different parishes
  expect_gt(length(parish_codes), 50,
    label = "Should have at least 50 different parishes")

  # All should be 2-character strings
  expect_true(all(nchar(parish_codes) == 2),
    label = "Parish codes should be 2 characters")
})


# ==============================================================================
# Tests for Major Districts
# ==============================================================================

test_that("major districts are present", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  # Check for some major Louisiana school districts
  district_names <- unique(tolower(dir$district_name))

  expect_true(any(grepl("orleans", district_names)),
    label = "Orleans Parish should be present")
  expect_true(any(grepl("jefferson", district_names)),
    label = "Jefferson Parish should be present")
  expect_true(any(grepl("east baton rouge", district_names)),
    label = "East Baton Rouge Parish should be present")
  expect_true(any(grepl("caddo", district_names)),
    label = "Caddo Parish should be present")
})


test_that("all years in data match requested year", {
  skip_if_offline()

  dir <- fetch_directory(2025, tidy = TRUE, use_cache = TRUE)

  expect_true(all(dir$end_year == 2025),
    label = "All end_year values should be 2025")
})


# ==============================================================================
# Tests for Raw Data
# ==============================================================================

test_that("get_raw_directory returns list with expected sheets", {
  skip_if_offline()

  raw <- get_raw_directory(2025)

  expect_type(raw, "list")
  expect_true("public" %in% names(raw),
    label = "Raw data should have 'public' sheet")
  expect_true("charter" %in% names(raw),
    label = "Raw data should have 'charter' sheet")

  # Both should have data
  expect_gt(nrow(raw$public), 0,
    label = "Public schools sheet should have rows")
  expect_gt(nrow(raw$charter), 0,
    label = "Charter schools sheet should have rows")
})


test_that("tidy=FALSE returns raw column names", {
  skip_if_offline()

  # This tests that raw data is accessible
  raw <- get_raw_directory(2025)

  # Check for expected raw column names
  public_cols <- names(raw$public)

  expect_true("SiteCd" %in% public_cols,
    label = "Raw data should have SiteCd column")
  expect_true("SiteName" %in% public_cols,
    label = "Raw data should have SiteName column")
  expect_true("SponsorCd" %in% public_cols,
    label = "Raw data should have SponsorCd column")
})

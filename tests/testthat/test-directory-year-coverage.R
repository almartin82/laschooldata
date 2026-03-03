# ==============================================================================
# Directory Year Coverage Tests
# ==============================================================================
#
# Tests for Louisiana school directory data (currently only 2026 available).
# Pinned values from the LDOE 2025-2026 School Directory file.
#
# Verifies:
# - Required fields present
# - Entity counts (total, charter, non-charter)
# - Known parish lookups (Orleans, Jefferson, EBR)
# - Coordinate bounds (Louisiana geographic bounds)
# - Parish code format (2-digit)
# - District code format (3-digit)
#
# ==============================================================================

library(testthat)
library(laschooldata)

# Skip helper
skip_if_no_directory <- function() {
  skip_on_cran()
  tryCatch({
    dir <- fetch_directory(2026, use_cache = TRUE)
    if (is.null(dir) || nrow(dir) == 0) {
      skip("No directory data available")
    }
  }, error = function(e) {
    skip(paste("Cannot fetch directory data -", e$message))
  })
}


# ==============================================================================
# Year Availability
# ==============================================================================

test_that("directory available years returns 2026 only", {
  years <- get_directory_available_years()
  expect_equal(years$min_year, 2026)
  expect_equal(years$max_year, 2026)
})

test_that("fetch_directory rejects years outside range", {
  expect_error(fetch_directory(2024), "2026")
  expect_error(fetch_directory(2025), "2026")
  expect_error(fetch_directory(2027), "2026")
})


# ==============================================================================
# 2026 Pinned Entity Counts
# ==============================================================================

test_that("2026: total school count = 1,454", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_equal(nrow(dir), 1454)
})

test_that("2026: charter school count = 144", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_equal(sum(dir$is_charter), 144)
})

test_that("2026: non-charter school count = 1,310", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_equal(sum(!dir$is_charter), 1310)
})

test_that("2026: unique parish count = 69", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_equal(length(unique(dir$parish_code)), 69)
})

test_that("2026: unique district count >= 60", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_gte(length(unique(dir$district_code)), 60)
})


# ==============================================================================
# Required Fields
# ==============================================================================

test_that("2026: all required columns present", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)

  required_cols <- c(
    "end_year", "site_code", "parish_code", "district_code",
    "school_name", "district_name",
    "principal_first_name", "principal_last_name",
    "grades_served", "address", "city", "zip", "state",
    "latitude", "longitude", "is_charter"
  )

  for (col in required_cols) {
    expect_true(
      col %in% names(dir),
      label = paste("Missing required column:", col)
    )
  }
})

test_that("2026: every school has a site_code", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(all(!is.na(dir$site_code) & dir$site_code != ""))
})

test_that("2026: every school has a school_name", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(all(!is.na(dir$school_name) & dir$school_name != ""))
})

test_that("2026: every school has a district_code", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(all(!is.na(dir$district_code) & dir$district_code != ""))
})

test_that("2026: every school has a parish_code", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(all(!is.na(dir$parish_code) & dir$parish_code != ""))
})

test_that("2026: all end_year values are 2026", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(all(dir$end_year == 2026))
})

test_that("2026: state column is always LA", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(all(dir$state == "LA"))
})


# ==============================================================================
# Known Parish Lookups
# ==============================================================================

test_that("2026: Orleans Parish has 139 schools", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  orleans <- dir[dir$parish_code == "36", ]
  expect_equal(nrow(orleans), 139)
})

test_that("2026: Orleans Parish has 68 charter schools", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  orleans_charter <- dir[dir$parish_code == "36" & dir$is_charter, ]
  expect_equal(nrow(orleans_charter), 68)
})

test_that("2026: Jefferson Parish has 88 schools", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  jeff <- dir[dir$parish_code == "26", ]
  expect_equal(nrow(jeff), 88)
})

test_that("2026: East Baton Rouge has 126 schools", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  ebr <- dir[dir$parish_code == "17", ]
  expect_equal(nrow(ebr), 126)
})

test_that("2026: major parishes are present", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  district_names <- unique(tolower(dir$district_name))

  expect_true(any(grepl("orleans", district_names)),
    label = "Orleans should be present")
  expect_true(any(grepl("jefferson", district_names)),
    label = "Jefferson should be present")
  expect_true(any(grepl("east baton rouge", district_names)),
    label = "East Baton Rouge should be present")
  expect_true(any(grepl("caddo", district_names)),
    label = "Caddo should be present")
  expect_true(any(grepl("lafayette", district_names)),
    label = "Lafayette should be present")
  expect_true(any(grepl("calcasieu", district_names)),
    label = "Calcasieu should be present")
})


# ==============================================================================
# Code Format Tests
# ==============================================================================

test_that("2026: parish codes are 2-digit with leading zeros", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(
    all(nchar(dir$parish_code) == 2),
    label = "All parish codes should be exactly 2 characters"
  )
})

test_that("2026: district codes are 3-digit with leading zeros", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)
  expect_true(
    all(nchar(dir$district_code) == 3),
    label = "All district codes should be exactly 3 characters"
  )
})


# ==============================================================================
# Geographic Coordinate Bounds
# ==============================================================================

test_that("2026: latitudes are within Louisiana bounds", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)

  has_lat <- !is.na(dir$latitude)
  if (any(has_lat)) {
    lats <- dir$latitude[has_lat]
    # Louisiana latitude: approximately 28.9 to 33.0 degrees N
    expect_true(all(lats > 28 & lats < 34),
      label = "All latitudes should be within Louisiana bounds (28-34)")
  }
})

test_that("2026: longitudes are within Louisiana bounds", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)

  has_lon <- !is.na(dir$longitude)
  if (any(has_lon)) {
    lons <- dir$longitude[has_lon]
    # Louisiana longitude: approximately -94.1 to -88.8 degrees W
    expect_true(all(lons > -95 & lons < -88),
      label = "All longitudes should be within Louisiana bounds (-95 to -88)")
  }
})


# ==============================================================================
# Charter Filtering
# ==============================================================================

test_that("2026: include_charter=FALSE excludes charter schools", {
  skip_if_no_directory()
  dir_all <- fetch_directory(2026, use_cache = TRUE, include_charter = TRUE)
  dir_trad <- fetch_directory(2026, use_cache = TRUE, include_charter = FALSE)

  expect_lt(nrow(dir_trad), nrow(dir_all))
  expect_true(all(!dir_trad$is_charter))
  expect_equal(nrow(dir_all) - nrow(dir_trad), sum(dir_all$is_charter))
})


# ==============================================================================
# Grades Served Field
# ==============================================================================

test_that("2026: grades_served is populated for most schools", {
  skip_if_no_directory()
  dir <- fetch_directory(2026, use_cache = TRUE)

  non_na_grades <- sum(!is.na(dir$grades_served) & dir$grades_served != "")
  pct_with_grades <- non_na_grades / nrow(dir) * 100

  # At least 90% of schools should have grades_served

  expect_gt(pct_with_grades, 90,
    label = "At least 90% of schools should have grades_served populated")
})

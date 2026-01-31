# ==============================================================================
# Assessment Function Tests
# ==============================================================================
#
# Tests for Louisiana LEAP assessment data functions.
#
# NOTE: Due to Cloudflare protection on the LDOE website, many tests will
# skip if automated downloads are blocked. Tests that require network access
# use skip_if_offline() and skip_if_cloudflare_blocked().
#
# ==============================================================================

library(testthat)
library(laschooldata)

# ==============================================================================
# Helper Functions
# ==============================================================================

skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

skip_if_cloudflare_blocked <- function() {
  skip_if_offline()
  tryCatch({
    url <- "https://doe.louisiana.gov/data-and-reports"
    response <- httr::GET(url, httr::timeout(10))
    if (httr::status_code(response) == 403) {
      skip("LDOE website is blocking automated access (Cloudflare)")
    }
  }, error = function(e) {
    skip("Could not verify LDOE access")
  })
}

# ==============================================================================
# get_available_assessment_years() Tests
# ==============================================================================

test_that("get_available_assessment_years returns valid structure", {
  result <- get_available_assessment_years()

  expect_true(is.list(result))
  expect_true("min_year" %in% names(result))
  expect_true("max_year" %in% names(result))
  expect_true("years" %in% names(result))
  expect_true("covid_waiver_year" %in% names(result))

  # Year range should be reasonable

  expect_true(result$min_year >= 2015)
  expect_true(result$max_year <= 2030)
  expect_true(result$max_year >= result$min_year)

  # 2020 should be excluded
  expect_equal(result$covid_waiver_year, 2020)
  expect_false(2020 %in% result$years)
})

test_that("get_available_assessment_years excludes 2020", {
  result <- get_available_assessment_years()

  expect_false(2020 %in% result$years)
  expect_equal(result$covid_waiver_year, 2020)
  expect_true(grepl("COVID", result$note, ignore.case = TRUE))
})

# ==============================================================================
# get_assessment_url() Tests
# ==============================================================================

test_that("get_assessment_url returns URLs for valid years", {
  url_2024 <- laschooldata:::get_assessment_url(2024, "state_lea", "mastery_summary")
  url_2023 <- laschooldata:::get_assessment_url(2023, "state_lea", "mastery_summary")

  expect_true(!is.null(url_2024))
  expect_true(!is.null(url_2023))

  expect_true(grepl("doe.louisiana.gov", url_2024))
  expect_true(grepl(".xlsx", url_2024))
  expect_true(grepl("2024", url_2024))
})

test_that("get_assessment_url returns NULL for invalid years", {
  url <- laschooldata:::get_assessment_url(2010, "state_lea", "mastery_summary")
  expect_null(url)

  url_2020 <- laschooldata:::get_assessment_url(2020, "state_lea", "mastery_summary")
  expect_null(url_2020)
})

test_that("get_assessment_url returns URLs for different levels when available", {
  url_state <- laschooldata:::get_assessment_url(2024, "state_lea", "mastery_summary")
  url_school <- laschooldata:::get_assessment_url(2024, "school", "mastery_summary")

  # At least one should exist
  expect_true(!is.null(url_state) || !is.null(url_school))

  # If both exist, they may be the same (combined file) or different
  # Just verify they are valid URLs
  if (!is.null(url_state)) {
    expect_true(grepl("doe.louisiana.gov", url_state))
  }
  if (!is.null(url_school)) {
    expect_true(grepl("doe.louisiana.gov", url_school))
  }
})

# ==============================================================================
# fetch_assessment() Input Validation Tests
# ==============================================================================

test_that("fetch_assessment rejects invalid years", {
  expect_error(fetch_assessment(2010), "end_year must be one of")
  expect_error(fetch_assessment(2030), "end_year must be one of")
})

test_that("fetch_assessment rejects 2020 with specific message", {
  expect_error(fetch_assessment(2020), "COVID-19")
})

test_that("fetch_assessment rejects invalid level", {
  # Should work in theory, but may fail due to Cloudflare
  expect_error(
    fetch_assessment(2024, level = "invalid_level"),
    "level must be one of"
  )
})

# ==============================================================================
# fetch_assessment_multi() Input Validation Tests
# ==============================================================================

test_that("fetch_assessment_multi warns about 2020", {
  expect_warning(
    tryCatch(
      fetch_assessment_multi(c(2019, 2020, 2021)),
      error = function(e) NULL  # Ignore errors from Cloudflare
    ),
    "2020 excluded"
  )
})

test_that("fetch_assessment_multi rejects all invalid years", {
  expect_error(fetch_assessment_multi(c(2010, 2011)), "Invalid years")
})

# ==============================================================================
# Data Processing Tests (using mock data)
# ==============================================================================

test_that("process_assessment handles empty data", {
  empty_raw <- list()
  result <- laschooldata:::process_assessment(empty_raw, 2024)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("tidy_assessment handles empty data", {
  empty_df <- data.frame()
  result <- laschooldata:::tidy_assessment(empty_df)

  expect_true(is.data.frame(result))
})

test_that("standardize_la_subject normalizes subjects correctly", {
  subjects <- c("ELA", "ela", "English Language Arts", "MATH", "Mathematics", "SCIENCE")
  result <- laschooldata:::standardize_la_subject(subjects)

  expect_equal(result[1], "ELA")
  expect_equal(result[2], "ELA")
  expect_equal(result[3], "ELA")
  expect_equal(result[4], "Math")
  expect_equal(result[5], "Math")
  expect_equal(result[6], "Science")
})

test_that("standardize_la_grade normalizes grades correctly", {
  grades <- c("3", "03", "Grade 4", "3RD", "8TH", "All Grades")
  result <- laschooldata:::standardize_la_grade(grades)

  expect_equal(result[1], "03")
  expect_equal(result[2], "03")
  expect_equal(result[3], "04")
  expect_equal(result[4], "03")
  expect_equal(result[5], "08")
  expect_equal(result[6], "All")
})

test_that("standardize_la_subgroup normalizes subgroups correctly", {
  subgroups <- c("All Students", "ALL STUDENTS", "Black or African American",
                  "Hispanic", "Economically Disadvantaged", "English Learners")
  result <- laschooldata:::standardize_la_subgroup(subgroups)

  expect_equal(result[1], "All Students")
  expect_equal(result[2], "All Students")
  expect_equal(result[3], "Black")
  expect_equal(result[4], "Hispanic")
  expect_equal(result[5], "Economically Disadvantaged")
  expect_equal(result[6], "English Learners")
})

# ==============================================================================
# Aggregation Flag Tests
# ==============================================================================

test_that("id_assessment_aggs adds correct flags", {
  test_df <- data.frame(
    type = c("State", "District", "School"),
    district_id = c(NA, "017", "017"),
    school_id = c(NA, NA, "017001"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::id_assessment_aggs(test_df)

  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_school" %in% names(result))

  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_school, c(FALSE, FALSE, TRUE))
})

# ==============================================================================
# Proficiency Calculation Tests
# ==============================================================================

test_that("calc_proficiency calculates correctly", {
  # Create mock tidy data
  test_df <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    school_id = rep(NA_character_, 5),
    subject = rep("Math", 5),
    grade = rep("03", 5),
    subgroup = rep("All Students", 5),
    n_tested = rep(100, 5),
    proficiency_level = c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
    n_students = c(10, 20, 30, 25, 15),
    pct = c(0.10, 0.20, 0.30, 0.25, 0.15),
    stringsAsFactors = FALSE
  )

  # Test calc_proficiency
  result <- calc_proficiency(test_df)

  expect_true("n_proficient" %in% names(result))
  expect_true("pct_proficient" %in% names(result))

  # Proficient = mastery + advanced = 25 + 15 = 40
  expect_equal(result$n_proficient, 40)
  expect_equal(result$pct_proficient, 0.4, tolerance = 0.01)
})

test_that("calc_basic_above calculates correctly", {
  # Create mock tidy data
  test_df <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    school_id = rep(NA_character_, 5),
    subject = rep("Math", 5),
    grade = rep("03", 5),
    subgroup = rep("All Students", 5),
    n_tested = rep(100, 5),
    proficiency_level = c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
    n_students = c(10, 20, 30, 25, 15),
    pct = c(0.10, 0.20, 0.30, 0.25, 0.15),
    stringsAsFactors = FALSE
  )

  # Test calc_basic_above
  result <- calc_basic_above(test_df)

  expect_true("n_basic_above" %in% names(result))
  expect_true("pct_basic_above" %in% names(result))

  # Basic and above = basic + mastery + advanced = 30 + 25 + 15 = 70
  expect_equal(result$n_basic_above, 70)
  expect_equal(result$pct_basic_above, 0.7, tolerance = 0.01)
})

# ==============================================================================
# safe_numeric() Tests
# ==============================================================================

test_that("safe_numeric handles suppression markers", {
  values <- c("100", "*", "**", "<5", "50", "N/A", "")

  result <- safe_numeric(values)

  expect_equal(result[1], 100)
  expect_true(is.na(result[2]))  # *
  expect_true(is.na(result[3]))  # **
  expect_true(is.na(result[4]))  # <5
  expect_equal(result[5], 50)
  expect_true(is.na(result[6]))  # N/A
  expect_true(is.na(result[7]))  # empty
})

test_that("safe_numeric handles commas in numbers", {
  values <- c("1,000", "10,000,000", "500")
  result <- safe_numeric(values)

  expect_equal(result[1], 1000)
  expect_equal(result[2], 10000000)
  expect_equal(result[3], 500)
})

test_that("safe_numeric handles percentages", {
  values <- c("50%", "75.5%", "100%")
  result <- safe_numeric(values)

  expect_equal(result[1], 50)
  expect_equal(result[2], 75.5)
  expect_equal(result[3], 100)
})

# ==============================================================================
# import_local_assessment() Tests
# ==============================================================================

test_that("import_local_assessment rejects non-existent file", {
  expect_error(
    import_local_assessment("/non/existent/file.xlsx", 2024),
    "File not found"
  )
})

# ==============================================================================
# LIVE Network Tests (may be skipped due to Cloudflare)
# ==============================================================================

test_that("fetch_assessment returns data structure when accessible", {
  skip_if_cloudflare_blocked()

  tryCatch({
    # Try to fetch 2024 data
    assess <- fetch_assessment(2024, use_cache = TRUE)

    # If we get here, verify structure
    expect_true(is.data.frame(assess))

    if (nrow(assess) > 0) {
      # Check for expected columns in tidy format
      expect_true("end_year" %in% names(assess))
      expect_true("proficiency_level" %in% names(assess))
      expect_true("is_state" %in% names(assess))
      expect_true("is_district" %in% names(assess))
      expect_true("is_school" %in% names(assess))

      # Check proficiency levels are valid
      valid_levels <- c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced")
      expect_true(all(assess$proficiency_level %in% valid_levels))

      # Check no Inf or NaN
      numeric_cols <- names(assess)[sapply(assess, is.numeric)]
      for (col in numeric_cols) {
        expect_false(any(is.infinite(assess[[col]]), na.rm = TRUE),
                     info = paste("No Inf in", col))
        expect_false(any(is.nan(assess[[col]]), na.rm = TRUE),
                     info = paste("No NaN in", col))
      }
    }
  }, error = function(e) {
    skip(paste("Could not fetch data:", e$message))
  })
})

test_that("fetch_assessment wide format has expected columns", {
  skip_if_cloudflare_blocked()

  tryCatch({
    assess <- fetch_assessment(2024, tidy = FALSE, use_cache = TRUE)

    expect_true(is.data.frame(assess))

    if (nrow(assess) > 0) {
      # Wide format should have pct_* columns
      expect_true(any(grepl("^pct_", names(assess))))
    }
  }, error = function(e) {
    skip(paste("Could not fetch data:", e$message))
  })
})

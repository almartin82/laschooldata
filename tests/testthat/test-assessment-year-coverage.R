# ==============================================================================
# Assessment Year Coverage Tests
# ==============================================================================
#
# Per-year tests for Louisiana LEAP assessment data.
#
# IMPORTANT: The current fetch_assessment() downloads a summary mastery file
# from LDOE that only has % Mastery+ data. The detailed proficiency-level
# breakdowns (Unsatisfactory, Approaching Basic, Basic, Mastery, Advanced) are
# in the bundled inst/extdata/assessment_samples/ files but NOT in the live
# fetch path.
#
# These tests verify:
# - Year availability and validation
# - COVID-19 2020 exclusion
# - Assessment data structure when data is available
# - Proficiency level handling
# - import_local_assessment() with bundled sample files
# - Percentage format detection (% sign vs decimal)
#
# ==============================================================================

library(testthat)
library(laschooldata)

# Skip helper for assessment tests - uses cache
skip_if_no_assessment <- function(yr) {
  skip_on_cran()
  tryCatch({
    assess <- fetch_assessment(yr, use_cache = TRUE, tidy = TRUE)
    if (is.null(assess) || nrow(assess) == 0) {
      skip(paste("No assessment data available for", yr))
    }
  }, error = function(e) {
    skip(paste("Cannot fetch assessment data for", yr, "-", e$message))
  })
}


# ==============================================================================
# Year Availability and Validation
# ==============================================================================

test_that("available assessment years are 2018-2025 excluding 2020", {
  years <- get_available_assessment_years()
  expect_equal(years$min_year, 2018)
  expect_equal(years$max_year, 2025)
  expect_equal(years$covid_waiver_year, 2020)
  expect_setequal(years$years, c(2018, 2019, 2021, 2022, 2023, 2024, 2025))
  expect_false(2020 %in% years$years)
})

test_that("fetch_assessment rejects 2020 with COVID message", {
  expect_error(fetch_assessment(2020), "COVID-19")
})

test_that("fetch_assessment rejects years outside range", {
  expect_error(fetch_assessment(2010), "end_year must be one of")
  expect_error(fetch_assessment(2030), "end_year must be one of")
})

test_that("fetch_assessment_multi warns and excludes 2020", {
  expect_warning(
    tryCatch(
      fetch_assessment_multi(c(2019, 2020, 2021), use_cache = TRUE),
      error = function(e) NULL
    ),
    "2020 excluded"
  )
})


# ==============================================================================
# Per-Year Structure Tests (for all available years)
# ==============================================================================

test_that("assessment tidy output has required columns for each year", {
  required_cols <- c("end_year", "type", "district_id", "school_id",
                     "proficiency_level", "is_state", "is_district", "is_school")

  for (yr in c(2019, 2021:2025)) {
    skip_if_no_assessment(yr)
    assess <- fetch_assessment(yr, use_cache = TRUE, tidy = TRUE)

    for (col in required_cols) {
      expect_true(
        col %in% names(assess),
        label = paste(yr, "missing required column:", col)
      )
    }

    # end_year should match
    expect_true(
      all(assess$end_year == yr),
      label = paste(yr, "all rows should have matching end_year")
    )
  }
})

test_that("assessment has exactly 5 proficiency levels when data is valid", {
  expected_levels <- c("unsatisfactory", "approaching_basic", "basic",
                       "mastery", "advanced")

  for (yr in c(2019, 2021:2025)) {
    skip_if_no_assessment(yr)
    assess <- fetch_assessment(yr, use_cache = TRUE, tidy = TRUE)

    actual_levels <- unique(as.character(assess$proficiency_level))
    actual_levels <- actual_levels[!is.na(actual_levels)]

    if (length(actual_levels) > 0) {
      for (lv in expected_levels) {
        expect_true(
          lv %in% actual_levels,
          label = paste(yr, "missing proficiency level:", lv)
        )
      }
      for (lv in actual_levels) {
        expect_true(
          lv %in% expected_levels,
          label = paste(yr, "unexpected proficiency level:", lv)
        )
      }
    }
  }
})


# ==============================================================================
# Entity Flag Tests (Assessment)
# ==============================================================================

test_that("assessment entity flags are mutually exclusive", {
  for (yr in c(2019, 2021:2025)) {
    skip_if_no_assessment(yr)
    assess <- fetch_assessment(yr, use_cache = TRUE, tidy = TRUE)

    flag_sum <- assess$is_state + assess$is_district + assess$is_school
    expect_true(
      all(flag_sum == 1),
      label = paste(yr, "each row should have exactly one entity flag TRUE")
    )
  }
})


# ==============================================================================
# Wide Format Tests
# ==============================================================================

test_that("assessment wide format has pct_ columns", {
  for (yr in c(2024)) {
    skip_if_no_assessment(yr)
    assess_w <- fetch_assessment(yr, use_cache = TRUE, tidy = FALSE)

    if (nrow(assess_w) > 0) {
      pct_cols <- grep("^pct_", names(assess_w), value = TRUE)
      expect_gt(
        length(pct_cols), 0,
        label = paste(yr, "wide format should have pct_ columns")
      )
    }
  }
})


# ==============================================================================
# Bundled Sample File Tests (import_local_assessment)
# ==============================================================================

test_that("import_local_assessment reads 2024 grades 3-8 sample", {
  sample_path <- system.file("extdata/assessment_samples/2024_leap_g38.xlsx",
                              package = "laschooldata")
  skip_if(sample_path == "", "2024 grades 3-8 sample file not found")

  df <- import_local_assessment(sample_path, 2024)
  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 1000)
})

test_that("import_local_assessment reads 2025 grades 3-8 sample", {
  sample_path <- system.file("extdata/assessment_samples/2025_leap_grade_3_8.xlsx",
                              package = "laschooldata")
  skip_if(sample_path == "", "2025 grades 3-8 sample file not found")

  df <- import_local_assessment(sample_path, 2025)
  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 100)
})

test_that("import_local_assessment reads 2025 HS sample", {
  sample_path <- system.file("extdata/assessment_samples/2025_leap_high_school.xlsx",
                              package = "laschooldata")
  skip_if(sample_path == "", "2025 high school sample file not found")

  df <- import_local_assessment(sample_path, 2025)
  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 100)
})

test_that("import_local_assessment rejects non-existent file", {
  expect_error(
    import_local_assessment("/nonexistent/path/fake.xlsx", 2024),
    "File not found"
  )
})


# ==============================================================================
# Percentage Format Detection (Key LA Quirk)
# ==============================================================================
#
# Louisiana assessment data may use either "48.8%" (with percent sign) or
# 0.488 (decimal) format across years. The safe_percentage() function
# in process_enrollment.R handles this, but the same issue can appear in
# assessment data that uses percentage columns.
#
# This test verifies the format detection logic via safe_percentage().
# ==============================================================================

test_that("safe_percentage handles both percentage formats correctly", {
  # 2024+ format: "48.8%" (with % sign)
  pct_format <- c("48.8%", "51.2%", "5.3%")
  result_pct <- laschooldata:::safe_percentage(pct_format)
  expect_equal(result_pct[1], 48.8)
  expect_equal(result_pct[2], 51.2)
  expect_equal(result_pct[3], 5.3)

  # 2019-2023 format: 0.488 (decimal)
  decimal_format <- c("0.488", "0.512", "0.053")
  result_dec <- laschooldata:::safe_percentage(decimal_format)
  expect_equal(result_dec[1], 48.8)
  expect_equal(result_dec[2], 51.2)
  expect_equal(result_dec[3], 5.3)

  # Mixed NAs and suppression markers
  mixed <- c("48.8%", "*", NA, "0%")
  result_mixed <- laschooldata:::safe_percentage(mixed)
  expect_equal(result_mixed[1], 48.8)
  expect_true(is.na(result_mixed[2]))
  expect_true(is.na(result_mixed[3]))
  expect_equal(result_mixed[4], 0)
})


# ==============================================================================
# Proficiency Calculation Tests
# ==============================================================================

test_that("calc_proficiency sums mastery + advanced correctly", {
  test_df <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    school_id = rep(NA_character_, 5),
    subject = rep("ELA", 5),
    grade = rep("03", 5),
    subgroup = rep("All Students", 5),
    n_tested = rep(50000, 5),
    proficiency_level = factor(
      c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
      levels = c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
      ordered = TRUE
    ),
    n_students = c(8500, 10000, 11000, 13000, 7500),
    pct = c(0.17, 0.20, 0.22, 0.26, 0.15),
    stringsAsFactors = FALSE
  )

  result <- calc_proficiency(test_df)
  expect_equal(result$n_proficient, 13000 + 7500)  # mastery + advanced
  expect_equal(result$pct_proficient, (13000 + 7500) / 50000, tolerance = 0.01)
})

test_that("calc_basic_above sums basic + mastery + advanced correctly", {
  test_df <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    school_id = rep(NA_character_, 5),
    subject = rep("Math", 5),
    grade = rep("04", 5),
    subgroup = rep("All Students", 5),
    n_tested = rep(50000, 5),
    proficiency_level = factor(
      c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
      levels = c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
      ordered = TRUE
    ),
    n_students = c(7000, 12000, 13500, 13000, 4500),
    pct = c(0.14, 0.24, 0.27, 0.26, 0.09),
    stringsAsFactors = FALSE
  )

  result <- calc_basic_above(test_df)
  expect_equal(result$n_basic_above, 13500 + 13000 + 4500)  # basic + mastery + advanced
  expect_equal(result$pct_basic_above, (13500 + 13000 + 4500) / 50000, tolerance = 0.01)
})


# ==============================================================================
# Subject and Grade Normalization Tests
# ==============================================================================

test_that("standardize_la_subject normalizes all known subject names", {
  subjects <- c("ELA", "ela", "English Language Arts", "ENGLISH LANGUAGE ARTS",
                "MATH", "Mathematics", "MATHEMATICS",
                "SCIENCE", "Science",
                "SOCIAL STUDIES", "Social Studies",
                "ALGEBRA I", "Algebra I",
                "GEOMETRY", "Geometry",
                "ENGLISH II",
                "BIOLOGY",
                "US HISTORY", "U.S. HISTORY")

  result <- laschooldata:::standardize_la_subject(subjects)
  expect_equal(result[1], "ELA")
  expect_equal(result[2], "ELA")
  expect_equal(result[3], "ELA")
  expect_equal(result[4], "ELA")
  expect_equal(result[5], "Math")
  expect_equal(result[6], "Math")
  expect_equal(result[7], "Math")
  expect_equal(result[8], "Science")
  expect_equal(result[9], "Science")
  expect_equal(result[10], "Social Studies")
  expect_equal(result[11], "Social Studies")
  expect_equal(result[12], "Algebra I")
  expect_equal(result[13], "Algebra I")
  expect_equal(result[14], "Geometry")
  expect_equal(result[15], "Geometry")
  expect_equal(result[16], "English II")
  expect_equal(result[17], "Biology")
  expect_equal(result[18], "US History")
  expect_equal(result[19], "US History")
})

test_that("standardize_la_grade normalizes all grade formats", {
  grades <- c("3", "03", "Grade 4", "3RD", "4TH", "5TH",
              "6TH", "7TH", "8TH", "All Grades", "All",
              "EOC", "End of Course", "HS", "High School")

  result <- laschooldata:::standardize_la_grade(grades)
  expect_equal(result[1], "03")
  expect_equal(result[2], "03")
  expect_equal(result[3], "04")
  expect_equal(result[4], "03")
  expect_equal(result[5], "04")
  expect_equal(result[6], "05")
  expect_equal(result[7], "06")
  expect_equal(result[8], "07")
  expect_equal(result[9], "08")
  expect_equal(result[10], "All")
  expect_equal(result[11], "All")
  expect_equal(result[12], "HS")
  expect_equal(result[13], "HS")
  expect_equal(result[14], "HS")
  expect_equal(result[15], "HS")
})

test_that("standardize_la_subgroup normalizes assessment subgroups", {
  subgroups <- c(
    "All Students", "ALL STUDENTS", "All",
    "Black or African American", "BLACK OR AFRICAN AMERICAN",
    "White", "Hispanic",
    "Economically Disadvantaged", "ED",
    "Students with Disabilities", "SWD",
    "English Learners", "EL", "LEP"
  )

  result <- laschooldata:::standardize_la_subgroup(subgroups)
  expect_equal(result[1], "All Students")
  expect_equal(result[2], "All Students")
  expect_equal(result[3], "All Students")
  expect_equal(result[4], "Black")
  expect_equal(result[5], "Black")
  expect_equal(result[6], "White")
  expect_equal(result[7], "Hispanic")
  expect_equal(result[8], "Economically Disadvantaged")
  expect_equal(result[9], "Economically Disadvantaged")
  expect_equal(result[10], "Students with Disabilities")
  expect_equal(result[11], "Students with Disabilities")
  expect_equal(result[12], "English Learners")
  expect_equal(result[13], "English Learners")
  expect_equal(result[14], "English Learners")
})


# ==============================================================================
# Multi-Year Fetch Tests
# ==============================================================================

test_that("fetch_assessment_multi combines years correctly", {
  skip_if_no_assessment(2023)
  skip_if_no_assessment(2024)

  assess_multi <- fetch_assessment_multi(2023:2024, use_cache = TRUE)
  years_present <- unique(assess_multi$end_year)

  expect_true(2023 %in% years_present, label = "2023 should be in multi-year data")
  expect_true(2024 %in% years_present, label = "2024 should be in multi-year data")
})

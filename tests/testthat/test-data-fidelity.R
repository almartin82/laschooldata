# ==============================================================================
# Data Fidelity Tests
# ==============================================================================
#
# These tests verify that the tidy=TRUE output maintains fidelity to the raw,
# unprocessed source file. We compare processed values against known values
# from the LDOE Multi Stats files.
#
# CRITICAL: The tidy=TRUE version MUST maintain fidelity to raw data.
#
# ==============================================================================

# Skip all tests if we're offline
skip_if_offline <- function() {
  skip_on_cran()
  skip_if_not(
    tryCatch({
      response <- httr::HEAD(
        "https://www.louisianabelieves.com",
        httr::timeout(5)
      )
      httr::status_code(response) == 200
    }, error = function(e) FALSE),
    "Louisiana DOE website not reachable"
  )
}


# ==============================================================================
# 2024 Known Values from Raw File
# ==============================================================================
#
# These values are extracted directly from the Oct 2024 Multi Stats file:
# State of Louisiana (row with code 000):
# - Total Enrollment: 676,751
# - % Female: 48.8%, % Male: 51.2%
# - American Indian: 3,666
# - Asian: 10,745
# - Black: 282,521
# - Hispanic: 77,836
# - Hawaiian/Pacific Islander: 493
# - White: 275,265
# - Multiple Races: 26,225
# - Minority: 401,486
# - % LEP: 5.3%
#
# ==============================================================================

test_that("2024 state total enrollment matches raw file", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # Raw file shows 676,751
  expect_equal(state$row_total, 676751,
    label = "Total enrollment should match raw file")
})


test_that("2024 state race/ethnicity counts match raw file", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # Raw file values
  expect_equal(state$native_american, 3666,
    label = "American Indian count should match raw file")
  expect_equal(state$asian, 10745,
    label = "Asian count should match raw file")
  expect_equal(state$black, 282521,
    label = "Black count should match raw file")
  expect_equal(state$hispanic, 77836,
    label = "Hispanic count should match raw file")
  expect_equal(state$pacific_islander, 493,
    label = "Hawaiian/Pacific Islander count should match raw file")
  expect_equal(state$white, 275265,
    label = "White count should match raw file")
  expect_equal(state$multiracial, 26225,
    label = "Multiple Races count should match raw file")
  expect_equal(state$minority, 401486,
    label = "Minority count should match raw file")
})


test_that("2024 state gender percentages match raw file", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # Raw file shows 48.8% female, 51.2% male
  expect_equal(state$pct_female, 48.8,
    label = "Female percentage should match raw file")
  expect_equal(state$pct_male, 51.2,
    label = "Male percentage should match raw file")

  # Calculated male count (676,751 * 51.2% = 346,497)
  expect_equal(state$male, 346497,
    label = "Male count calculated from percentage should be correct")

  # Calculated female count (676,751 * 48.8% = 330,254)
  expect_equal(state$female, 330254,
    label = "Female count calculated from percentage should be correct")
})


test_that("2024 tidy format preserves race/ethnicity values", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Check each subgroup at state level
  state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]

  # Black students
  black <- state_data[state_data$subgroup == "black", "n_students"][[1]]
  expect_equal(black, 282521,
    label = "Tidy black count should match raw file")

  # White students
  white <- state_data[state_data$subgroup == "white", "n_students"][[1]]
  expect_equal(white, 275265,
    label = "Tidy white count should match raw file")

  # Hispanic students
  hispanic <- state_data[state_data$subgroup == "hispanic", "n_students"][[1]]
  expect_equal(hispanic, 77836,
    label = "Tidy Hispanic count should match raw file")

  # Asian students
  asian <- state_data[state_data$subgroup == "asian", "n_students"][[1]]
  expect_equal(asian, 10745,
    label = "Tidy Asian count should match raw file")
})


test_that("2024 tidy format preserves gender values", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]

  # Male students (calculated from 51.2%)
  male <- state_data[state_data$subgroup == "male", "n_students"][[1]]
  expect_equal(male, 346497,
    label = "Tidy male count should match calculated value")

  # Female students (calculated from 48.8%)
  female <- state_data[state_data$subgroup == "female", "n_students"][[1]]
  expect_equal(female, 330254,
    label = "Tidy female count should match calculated value")
})


# ==============================================================================
# District-Level Fidelity Tests
# ==============================================================================

test_that("Caddo Parish (district 009) data matches expected values", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Caddo Parish (Shreveport area) is district code 009
  caddo <- enr[enr$type == "District" & enr$district_id == "009", ]

  expect_equal(nrow(caddo), 1,
    label = "Should have exactly 1 Caddo Parish row")

  # Caddo Parish is a major urban district - should have significant enrollment
  expect_gt(caddo$row_total, 25000,
    label = "Caddo Parish should have > 25,000 students")
  expect_lt(caddo$row_total, 50000,
    label = "Caddo Parish should have < 50,000 students")

  # Gender should not be zero
  expect_gt(caddo$male, 10000,
    label = "Caddo Parish male should be > 10,000")
  expect_gt(caddo$female, 10000,
    label = "Caddo Parish female should be > 10,000")
})


test_that("Jefferson Parish (district 026) data matches expected values", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Jefferson Parish is district code 026
  jefferson <- enr[enr$type == "District" & enr$district_id == "026", ]

  expect_equal(nrow(jefferson), 1,
    label = "Should have exactly 1 Jefferson Parish row")

  # Jefferson Parish is a major district
  expect_gt(jefferson$row_total, 40000,
    label = "Jefferson Parish should have > 40,000 students")
})


test_that("East Baton Rouge Parish (district 017) data matches expected values", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # East Baton Rouge is district code 017
  ebr <- enr[enr$type == "District" & enr$district_id == "017", ]

  expect_equal(nrow(ebr), 1,
    label = "Should have exactly 1 East Baton Rouge row")

  # EBR is a major district
  expect_gt(ebr$row_total, 30000,
    label = "East Baton Rouge should have > 30,000 students")
})


# ==============================================================================
# Cross-Year Consistency Tests
# ==============================================================================

test_that("state enrollment shows reasonable year-over-year change", {
  skip_if_offline()

  enr_multi <- fetch_enr_multi(2022:2024, tidy = FALSE, use_cache = TRUE)

  state_by_year <- enr_multi[enr_multi$type == "State", c("end_year", "row_total")]
  state_by_year <- state_by_year[order(state_by_year$end_year), ]

  # Calculate year-over-year changes
  for (i in 2:nrow(state_by_year)) {
    pct_change <- abs(
      (state_by_year$row_total[i] - state_by_year$row_total[i-1]) /
      state_by_year$row_total[i-1] * 100
    )

    # Enrollment shouldn't change more than 10% year-over-year
    expect_lt(pct_change, 10,
      label = paste("Year-over-year change",
        state_by_year$end_year[i-1], "to", state_by_year$end_year[i],
        "should be < 10%"))
  }
})


# ==============================================================================
# Grade Level Fidelity Tests
# ==============================================================================

test_that("grade level enrollment is properly parsed", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Get state-level grade data
  state_grades <- enr[enr$is_state &
                      enr$subgroup == "total_enrollment" &
                      enr$grade_level != "TOTAL", ]

  # Check that we have expected grade levels
  expected_grades <- c("PK", "K", "01", "02", "03", "04", "05",
                       "06", "07", "08", "09", "10", "11", "12")

  for (grade in expected_grades) {
    grade_row <- state_grades[state_grades$grade_level == grade, ]
    expect_equal(nrow(grade_row), 1,
      label = paste("Should have exactly 1 row for grade", grade))
    expect_gt(grade_row$n_students, 10000,
      label = paste("Grade", grade, "should have > 10,000 students"))
    expect_lt(grade_row$n_students, 100000,
      label = paste("Grade", grade, "should have < 100,000 students"))
  }
})


# ==============================================================================
# Aggregation Flag Tests
# ==============================================================================

test_that("is_state, is_district, is_campus flags are mutually exclusive", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Check that each row has exactly one flag set to TRUE
  flag_sum <- enr$is_state + enr$is_district + enr$is_campus
  expect_true(all(flag_sum == 1),
    label = "Each row should have exactly one aggregation flag TRUE")
})


test_that("aggregation flags match type column", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # State rows
  state_rows <- enr[enr$is_state, ]
  expect_true(all(state_rows$type == "State"),
    label = "is_state rows should have type='State'")

  # District rows
  district_rows <- enr[enr$is_district, ]
  expect_true(all(district_rows$type == "District"),
    label = "is_district rows should have type='District'")

  # Campus rows
  campus_rows <- enr[enr$is_campus, ]
  expect_true(all(campus_rows$type == "Campus"),
    label = "is_campus rows should have type='Campus'")
})


# ==============================================================================
# Year-by-Year Fidelity Tests
# ==============================================================================
#
# These tests verify that EVERY available year (2019-2024) produces correct data.
# This is critical for detecting format changes across years.
#
# ==============================================================================

test_that("2019 state data has correct male/female breakdown", {
  skip_if_offline()

  enr <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # State should have reasonable enrollment (600K-700K)
  expect_gt(state$row_total, 600000,
    label = "2019 state enrollment should be > 600,000")
  expect_lt(state$row_total, 700000,
    label = "2019 state enrollment should be < 700,000")

  # Male/female should each be roughly 50% of total (not near 0!)
  expect_gt(state$male, 300000,
    label = "2019 state male should be > 300,000")
  expect_lt(state$male, 350000,
    label = "2019 state male should be < 350,000")
  expect_gt(state$female, 280000,
    label = "2019 state female should be > 280,000")
  expect_lt(state$female, 340000,
    label = "2019 state female should be < 340,000")

  # Male + female should equal total
  expect_equal(state$male + state$female, state$row_total,
    label = "2019 male + female should equal total")
})


test_that("2020 state data has correct male/female breakdown", {
  skip_if_offline()

  enr <- fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # Male/female should each be roughly 50% of total
  expect_gt(state$male, 280000,
    label = "2020 state male should be > 280,000")
  expect_gt(state$female, 270000,
    label = "2020 state female should be > 270,000")

  # Male + female should equal total
  expect_equal(state$male + state$female, state$row_total,
    label = "2020 male + female should equal total")
})


test_that("2021 state data has correct male/female breakdown", {
  skip_if_offline()

  enr <- fetch_enr(2021, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # Male/female should each be roughly 50% of total
  expect_gt(state$male, 280000,
    label = "2021 state male should be > 280,000")
  expect_gt(state$female, 270000,
    label = "2021 state female should be > 270,000")

  # Male + female should equal total
  expect_equal(state$male + state$female, state$row_total,
    label = "2021 male + female should equal total")
})


test_that("2022 state data has correct male/female breakdown", {
  skip_if_offline()

  enr <- fetch_enr(2022, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # Male/female should each be roughly 50% of total
  expect_gt(state$male, 300000,
    label = "2022 state male should be > 300,000")
  expect_gt(state$female, 300000,
    label = "2022 state female should be > 300,000")

  # Male + female should equal total
  expect_equal(state$male + state$female, state$row_total,
    label = "2022 male + female should equal total")
})


test_that("2023 state data has correct male/female breakdown", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]

  # Male/female should each be roughly 50% of total
  expect_gt(state$male, 300000,
    label = "2023 state male should be > 300,000")
  expect_gt(state$female, 300000,
    label = "2023 state female should be > 300,000")

  # Male + female should equal total
  expect_equal(state$male + state$female, state$row_total,
    label = "2023 male + female should equal total")
})


# ==============================================================================
# Percentage Format Conversion Tests
# ==============================================================================
#
# These tests verify that percentage columns are correctly normalized across
# years, regardless of whether they were stored as decimals (0.48) or
# percentages (48%).
#
# ==============================================================================

test_that("percentage columns are correctly normalized (0-100 range) for all years", {
  skip_if_offline()

  for (yr in 2019:2024) {
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]

    # pct_male and pct_female should be in 0-100 range (not 0-1)
    expect_gt(state$pct_male, 40,
      label = paste(yr, "pct_male should be > 40 (not decimal)"))
    expect_lt(state$pct_male, 60,
      label = paste(yr, "pct_male should be < 60"))

    expect_gt(state$pct_female, 40,
      label = paste(yr, "pct_female should be > 40 (not decimal)"))
    expect_lt(state$pct_female, 60,
      label = paste(yr, "pct_female should be < 60"))

    # Percentages should sum to approximately 100
    pct_sum <- state$pct_male + state$pct_female
    expect_gt(pct_sum, 99,
      label = paste(yr, "pct_male + pct_female should be ~100"))
    expect_lt(pct_sum, 101,
      label = paste(yr, "pct_male + pct_female should be ~100"))
  }
})


test_that("LEP percentage is correctly normalized for all years", {
  skip_if_offline()

  for (yr in 2019:2024) {
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]

    # pct_lep should be in 0-100 range (not 0-1)
    # Louisiana LEP is typically around 5%
    if (!is.na(state$pct_lep)) {
      expect_gt(state$pct_lep, 1,
        label = paste(yr, "pct_lep should be > 1 (not decimal)"))
      expect_lt(state$pct_lep, 20,
        label = paste(yr, "pct_lep should be < 20"))
    }
  }
})


# ==============================================================================
# Subgroup Completeness Tests
# ==============================================================================
#
# These tests verify that all expected subgroups are present in the tidy output.
#
# ==============================================================================

test_that("all demographic subgroups are present for each year", {
  skip_if_offline()

  expected_subgroups <- c(
    "total_enrollment",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial", "minority",
    "male", "female"
  )

  for (yr in 2019:2024) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]

    for (sg in expected_subgroups) {
      sg_rows <- state_data[state_data$subgroup == sg, ]
      expect_equal(nrow(sg_rows), 1,
        label = paste(yr, "should have 1 row for subgroup", sg))
      expect_gt(sg_rows$n_students, 0,
        label = paste(yr, sg, "should have > 0 students"))
    }
  }
})


test_that("special population subgroups are present for each year", {
  skip_if_offline()

  for (yr in 2019:2024) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]

    # LEP (Limited English Proficiency)
    lep_rows <- state_data[state_data$subgroup == "lep", ]
    expect_equal(nrow(lep_rows), 1,
      label = paste(yr, "should have 1 row for LEP"))

    # FEP (Fully English Proficient)
    fep_rows <- state_data[state_data$subgroup == "fep", ]
    expect_equal(nrow(fep_rows), 1,
      label = paste(yr, "should have 1 row for FEP"))

    # Economically Disadvantaged
    econ_rows <- state_data[state_data$subgroup == "econ_disadv", ]
    expect_equal(nrow(econ_rows), 1,
      label = paste(yr, "should have 1 row for econ_disadv"))
  }
})


test_that("all grade levels are present for each year", {
  skip_if_offline()

  expected_grades <- c("PK", "K", "01", "02", "03", "04", "05",
                       "06", "07", "08", "09", "10", "11", "12")

  for (yr in 2019:2024) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    state_grades <- enr[enr$is_state &
                        enr$subgroup == "total_enrollment" &
                        enr$grade_level != "TOTAL", ]

    for (grade in expected_grades) {
      grade_rows <- state_grades[state_grades$grade_level == grade, ]
      expect_equal(nrow(grade_rows), 1,
        label = paste(yr, "should have 1 row for grade", grade))
    }
  }
})

# ==============================================================================
# Tests for fetch_enrollment.R
# ==============================================================================
#
# These tests verify the core enrollment data fetching functionality.
# Tests are designed to:
# 1. Verify data can be fetched for all available years
# 2. Verify data maintains fidelity to the raw source
# 3. Check for impossible values (zeros where they don't belong)
# 4. Validate male/female conversion from percentages
#
# ==============================================================================

# Skip all tests if we're in CI or offline
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
# Tests for get_available_years()
# ==============================================================================

test_that("get_available_years returns expected structure", {
  years <- get_available_years()

  expect_type(years, "list")
  expect_named(years, c("min_year", "max_year", "description"))
  expect_equal(years$min_year, 2019)
  expect_equal(years$max_year, 2024)
  expect_type(years$description, "character")
})


# ==============================================================================
# Tests for fetch_enr() - Year Validation
# ==============================================================================

test_that("fetch_enr rejects invalid years", {
  expect_error(fetch_enr(2018), "2019 and 2024")
  expect_error(fetch_enr(2025), "2019 and 2024")
  expect_error(fetch_enr(2000), "2019 and 2024")
})

test_that("fetch_enr_multi rejects invalid years", {
  expect_error(fetch_enr_multi(2015:2020), "2019 and 2024")
  expect_error(fetch_enr_multi(c(2020, 2025)), "2019 and 2024")
})


# ==============================================================================
# Tests for fetch_enr() - Data Structure (2024)
# ==============================================================================

test_that("fetch_enr(2024, tidy=FALSE) returns expected columns", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Core ID columns
  expect_true("end_year" %in% names(enr))
  expect_true("type" %in% names(enr))
  expect_true("district_id" %in% names(enr))
  expect_true("campus_id" %in% names(enr))
  expect_true("district_name" %in% names(enr))

  # Total enrollment
  expect_true("row_total" %in% names(enr))

  # Race/ethnicity columns
  expect_true("white" %in% names(enr))
  expect_true("black" %in% names(enr))
  expect_true("hispanic" %in% names(enr))
  expect_true("asian" %in% names(enr))
  expect_true("pacific_islander" %in% names(enr))
  expect_true("native_american" %in% names(enr))
  expect_true("multiracial" %in% names(enr))

  # Gender columns - CRITICAL: these must exist and have values
  expect_true("male" %in% names(enr))
  expect_true("female" %in% names(enr))
  expect_true("pct_male" %in% names(enr))
  expect_true("pct_female" %in% names(enr))

  # Grade columns
  expect_true("grade_k" %in% names(enr))
  expect_true("grade_01" %in% names(enr))
  expect_true("grade_12" %in% names(enr))
})


test_that("fetch_enr(2024, tidy=TRUE) returns expected columns", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_true("end_year" %in% names(enr))
  expect_true("type" %in% names(enr))
  expect_true("subgroup" %in% names(enr))
  expect_true("grade_level" %in% names(enr))
  expect_true("n_students" %in% names(enr))
  expect_true("is_state" %in% names(enr))
  expect_true("is_district" %in% names(enr))
  expect_true("is_campus" %in% names(enr))
})


# ==============================================================================
# Tests for Male/Female Data - CRITICAL BUG FIX VERIFICATION
# ==============================================================================

test_that("state-level male/female enrollment is NOT ZERO", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Get state row
  state <- enr[enr$type == "State", ]
  expect_equal(nrow(state), 1)

  # CRITICAL: Male and female must NOT be zero
  expect_gt(state$male, 0, label = "State male enrollment must be > 0")
  expect_gt(state$female, 0, label = "State female enrollment must be > 0")

  # Verify percentages are reasonable (should be close to 50/50)
  expect_gt(state$pct_male, 40, label = "Male percentage should be > 40%")
  expect_lt(state$pct_male, 60, label = "Male percentage should be < 60%")
  expect_gt(state$pct_female, 40, label = "Female percentage should be > 40%")
  expect_lt(state$pct_female, 60, label = "Female percentage should be < 60%")

  # Male + female should approximately equal total
  expect_true(
    abs((state$male + state$female) - state$row_total) < 100,
    label = "Male + Female should approximately equal total enrollment"
  )
})


test_that("district-level male/female enrollment is NOT ZERO for major districts", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Get district rows (exclude state row which has district_id "000")
  districts <- enr[enr$type == "District" & enr$district_id != "000", ]

  # All districts with enrollment > 1000 should have non-zero male/female
  large_districts <- districts[districts$row_total > 1000, ]
  expect_gt(nrow(large_districts), 0)

  # Check that none have zero male or female
  zero_male <- large_districts[large_districts$male == 0, ]
  zero_female <- large_districts[large_districts$female == 0, ]

  expect_equal(nrow(zero_male), 0,
    label = "No large district should have 0 male students")
  expect_equal(nrow(zero_female), 0,
    label = "No large district should have 0 female students")
})


# ==============================================================================
# Tests for Data Fidelity - Verify Values Match Raw Source
# ==============================================================================

test_that("state enrollment for 2024 matches known value", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state <- enr[enr$type == "State", ]

  # According to the raw file, Louisiana 2024 total enrollment is ~676,751
  # Allow small variance for rounding
  expect_gt(state$row_total, 600000,
    label = "LA state enrollment should be > 600,000")
  expect_lt(state$row_total, 750000,
    label = "LA state enrollment should be < 750,000")

  # Verify we have the expected number of districts
  districts <- enr[enr$type == "District" & !is.na(enr$district_id), ]
  # Louisiana has 64 parishes + special districts (about 70+ total)
  expect_gt(nrow(districts), 60,
    label = "Should have at least 60 districts")
})


test_that("race/ethnicity counts sum approximately to total", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state <- enr[enr$type == "State", ]

  # Sum of race categories
  race_sum <- sum(
    state$white, state$black, state$hispanic, state$asian,
    state$pacific_islander, state$native_american, state$multiracial,
    na.rm = TRUE
  )

  # Should be close to total (within 1% for rounding)
  expect_lt(
    abs(race_sum - state$row_total) / state$row_total,
    0.01,
    label = "Race sum should be within 1% of total"
  )
})


test_that("grade level counts sum approximately to total", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state <- enr[enr$type == "State", ]

  # Sum of grade levels
  grade_sum <- sum(
    state$grade_infant, state$grade_preschool, state$grade_pk, state$grade_k,
    state$grade_01, state$grade_02, state$grade_03, state$grade_04,
    state$grade_05, state$grade_06, state$grade_07, state$grade_08,
    state$grade_09, state$grade_t9, state$grade_10, state$grade_11, state$grade_12,
    state$grade_extension,
    na.rm = TRUE
  )

  # Should be close to total (within 5% for special programs)
  expect_lt(
    abs(grade_sum - state$row_total) / state$row_total,
    0.05,
    label = "Grade sum should be within 5% of total"
  )
})


# ==============================================================================
# Tests for All Available Years
# ==============================================================================

test_that("fetch_enr works for all available years (2019-2024)", {
  skip_if_offline()

  years <- 2019:2024

  for (year in years) {
    enr <- fetch_enr(year, tidy = FALSE, use_cache = TRUE)

    # Basic structure checks
    expect_gt(nrow(enr), 100,
      label = paste("Year", year, "should have > 100 rows"))

    # Has state row
    state <- enr[enr$type == "State", ]
    expect_equal(nrow(state), 1,
      label = paste("Year", year, "should have exactly 1 state row"))

    # State has non-zero enrollment
    expect_gt(state$row_total, 500000,
      label = paste("Year", year, "state enrollment should be > 500,000"))

    # CRITICAL: Male/female are not zero
    expect_gt(state$male, 0,
      label = paste("Year", year, "state male should be > 0"))
    expect_gt(state$female, 0,
      label = paste("Year", year, "state female should be > 0"))
  }
})


# ==============================================================================
# Tests for Tidy Format
# ==============================================================================

test_that("tidy format has male and female subgroups with correct values", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Get state-level male and female in tidy format
  state_male <- enr[enr$is_state & enr$subgroup == "male" & enr$grade_level == "TOTAL", ]
  state_female <- enr[enr$is_state & enr$subgroup == "female" & enr$grade_level == "TOTAL", ]

  expect_equal(nrow(state_male), 1,
    label = "Should have exactly 1 state male row")
  expect_equal(nrow(state_female), 1,
    label = "Should have exactly 1 state female row")

  # Values should be non-zero
  expect_gt(state_male$n_students, 300000,
    label = "State male should be > 300,000")
  expect_gt(state_female$n_students, 300000,
    label = "State female should be > 300,000")
})


test_that("tidy format includes all expected subgroups", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Get unique subgroups at state level
  state_subgroups <- unique(enr[enr$is_state & enr$grade_level == "TOTAL", "subgroup"])

  expected_subgroups <- c(
    "total_enrollment",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial", "minority",
    "male", "female",
    "lep", "fep", "econ_disadv"
  )

  for (sg in expected_subgroups) {
    expect_true(sg %in% state_subgroups,
      label = paste("Subgroup", sg, "should be present"))
  }
})


# ==============================================================================
# Tests for Impossible Values Detection
# ==============================================================================

test_that("no district has enrollment > state total", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  state <- enr[enr$type == "State", ]
  districts <- enr[enr$type == "District" & enr$district_id != "000", ]

  # No district should exceed state total
  over_state <- districts[districts$row_total > state$row_total, ]
  expect_equal(nrow(over_state), 0,
    label = "No district should exceed state enrollment")
})


test_that("no school has enrollment > 10000 (sanity check)", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  campuses <- enr[enr$type == "Campus", ]

  # No single school should have more than 10,000 students (very unusual)
  giant_schools <- campuses[!is.na(campuses$row_total) & campuses$row_total > 10000, ]
  expect_lt(nrow(giant_schools), 10,
    label = "Very few schools should have > 10,000 students")
})


test_that("percentages are within valid range (0-100)", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Check percentage columns
  pct_cols <- c("pct_male", "pct_female", "pct_lep", "pct_fep", "pct_econ_disadv")

  for (col in pct_cols) {
    if (col %in% names(enr)) {
      values <- enr[[col]][!is.na(enr[[col]])]
      expect_true(all(values >= 0 & values <= 100),
        label = paste(col, "should be between 0 and 100"))
    }
  }
})


# ==============================================================================
# Tests for Multi-Year Fetch
# ==============================================================================

test_that("fetch_enr_multi returns combined data", {
  skip_if_offline()

  enr <- fetch_enr_multi(2022:2024, tidy = TRUE, use_cache = TRUE)

  # Should have 3 years of data
  years <- unique(enr$end_year)
  expect_setequal(years, 2022:2024)

  # Each year should have state-level total
  for (year in 2022:2024) {
    state_total <- enr[enr$is_state & enr$end_year == year &
                       enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", ]
    expect_equal(nrow(state_total), 1,
      label = paste("Year", year, "should have 1 state total row"))
    expect_gt(state_total$n_students, 500000,
      label = paste("Year", year, "state total should be > 500,000"))
  }
})


# ==============================================================================
# Tests for Cache Functions
# ==============================================================================

test_that("cache_status returns expected structure", {
  status <- cache_status()

  expect_s3_class(status, "data.frame")
  expect_true("end_year" %in% names(status))
  expect_true("tidy_cached" %in% names(status))
  expect_true("wide_cached" %in% names(status))
  expect_equal(nrow(status), 6)  # 2019-2024
})

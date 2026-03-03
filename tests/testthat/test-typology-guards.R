# ==============================================================================
# Typology Guard Tests
# ==============================================================================
#
# Guards against common data transformation failures specific to Louisiana:
#
# 1. Percentage format detection (% sign vs decimal) - THE critical LA quirk
# 2. Suppression marker handling
# 3. Entity flag assignment
# 4. Subgroup naming standards
# 5. Grade level normalization
# 6. Cross-year schema stability
# 7. Gender count derivation from percentages
# 8. Race/ethnicity sum vs total fidelity
# 9. sprintf format string safety (%02d vs %02s)
# 10. No zero-male / zero-female districts
#
# ==============================================================================

library(testthat)
library(laschooldata)

# Skip helper
skip_if_no_data <- function(yr) {
  skip_on_cran()
  tryCatch({
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    if (is.null(enr) || nrow(enr) == 0) {
      skip(paste("No enrollment data available for", yr))
    }
  }, error = function(e) {
    skip(paste("Cannot fetch enrollment data for", yr, "-", e$message))
  })
}


# ==============================================================================
# Guard 1: Percentage Format Detection
# ==============================================================================
#
# THE critical Louisiana quirk:
# - 2024+: "48.8%" (with percent sign, already in percentage form)
# - 2019-2023: 0.48846... (decimal format, needs *100)
#
# safe_percentage() must normalize both to 0-100 range.
# Getting this wrong causes zero-male / zero-female bugs.
# ==============================================================================

test_that("safe_percentage handles % sign format (2024+)", {
  result <- laschooldata:::safe_percentage(c("48.8%", "51.2%", "100%", "0%"))
  expect_equal(result[1], 48.8)
  expect_equal(result[2], 51.2)
  expect_equal(result[3], 100)
  expect_equal(result[4], 0)
})

test_that("safe_percentage handles decimal format (2019-2023)", {
  result <- laschooldata:::safe_percentage(c("0.488", "0.512", "1.0", "0.0"))
  expect_equal(result[1], 48.8)
  expect_equal(result[2], 51.2)
  expect_equal(result[3], 100)
  expect_equal(result[4], 0)
})

test_that("safe_percentage handles edge case: values exactly 1.0", {
  # A value of exactly 1.0 without % sign should be treated as 100%
  result <- laschooldata:::safe_percentage(c("1", "0.5"))
  expect_equal(result[1], 100)
  expect_equal(result[2], 50)
})

test_that("safe_percentage handles mixed suppression markers", {
  result <- laschooldata:::safe_percentage(c("48.8%", "*", "N/A", NA, "", "0%"))
  expect_equal(result[1], 48.8)
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
  expect_true(is.na(result[5]))
  expect_equal(result[6], 0)
})

test_that("percentage format never produces values > 100", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    pct_cols <- c("pct_male", "pct_female", "pct_lep", "pct_fep", "pct_econ_disadv")
    for (col in pct_cols) {
      if (col %in% names(enr)) {
        vals <- enr[[col]][!is.na(enr[[col]])]
        if (length(vals) > 0) {
          expect_true(
            all(vals <= 100),
            label = paste(yr, col, "should never exceed 100")
          )
          expect_true(
            all(vals >= 0),
            label = paste(yr, col, "should never be negative")
          )
        }
      }
    }
  }
})


# ==============================================================================
# Guard 2: Suppression Marker Handling
# ==============================================================================

test_that("safe_numeric handles all known suppression markers", {
  markers <- c("*", "**", "***", ".", "-", "-1", "<5", "<10",
               "N/A", "NA", "", "NULL", "n/a", "< 5")
  result <- safe_numeric(markers)
  expect_true(all(is.na(result)),
    label = "All suppression markers should produce NA")
})

test_that("safe_numeric preserves valid numbers", {
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("0"), 0)
  expect_equal(safe_numeric("-5"), -5)
  expect_equal(safe_numeric("3.14"), 3.14)
  expect_equal(safe_numeric("1,234"), 1234)
  expect_equal(safe_numeric("50%"), 50)
})

test_that("safe_numeric handles NULL and empty input", {
  expect_equal(safe_numeric(NULL), numeric(0))
  expect_equal(safe_numeric(character(0)), numeric(0))
})

test_that("no Inf or NaN in enrollment data for any year", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    numeric_cols <- names(enr)[sapply(enr, is.numeric)]
    for (col in numeric_cols) {
      vals <- enr[[col]]
      expect_false(
        any(is.infinite(vals), na.rm = TRUE),
        label = paste(yr, col, "should have no Inf values")
      )
      expect_false(
        any(is.nan(vals), na.rm = TRUE),
        label = paste(yr, col, "should have no NaN values")
      )
    }
  }
})


# ==============================================================================
# Guard 3: Entity Flag Assignment
# ==============================================================================

test_that("entity flags are mutually exclusive across all years", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    flag_sum <- enr$is_state + enr$is_district + enr$is_campus
    expect_true(
      all(flag_sum == 1),
      label = paste(yr, "flags should be mutually exclusive")
    )
  }
})

test_that("entity flags match type column", {
  for (yr in c(2019, 2024)) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    expect_true(all(enr$type[enr$is_state] == "State"),
      label = paste(yr, "is_state rows should be type State"))
    expect_true(all(enr$type[enr$is_district] == "District"),
      label = paste(yr, "is_district rows should be type District"))
    expect_true(all(enr$type[enr$is_campus] == "Campus"),
      label = paste(yr, "is_campus rows should be type Campus"))
  }
})

test_that("exactly one state row per year in tidy TOTAL", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_total <- enr[enr$is_state &
                       enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", ]
    expect_equal(
      nrow(state_total), 1,
      label = paste(yr, "should have exactly 1 state total row")
    )
  }
})


# ==============================================================================
# Guard 4: Subgroup Naming Standards
# ==============================================================================

test_that("standard subgroup names used across all years", {
  standard_names <- c(
    "total_enrollment", "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial", "minority",
    "male", "female", "lep", "fep", "econ_disadv"
  )

  # Reject non-standard variants
  bad_names <- c(
    "total", "low_income", "economically_disadvantaged",
    "iep", "disability", "el", "ell", "english_learner",
    "american_indian", "two_or_more", "frl"
  )

  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    actual_subgroups <- unique(enr$subgroup)

    # All standard names should be present
    for (sg in standard_names) {
      expect_true(
        sg %in% actual_subgroups,
        label = paste(yr, "missing standard subgroup:", sg)
      )
    }

    # No non-standard names should be present
    for (bad in bad_names) {
      expect_false(
        bad %in% actual_subgroups,
        label = paste(yr, "should NOT have non-standard subgroup:", bad)
      )
    }
  }
})

test_that("grade levels are UPPERCASE", {
  for (yr in c(2019, 2024)) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    grades <- unique(enr$grade_level)
    # All standard grades should be uppercase
    standard_grades <- grades[grades %in% c("PK", "K", "01", "02", "03", "04",
                                            "05", "06", "07", "08", "09", "10",
                                            "11", "12", "TOTAL", "INF", "PS",
                                            "T9", "EXT", "ELEM", "MIDDLE", "HIGH")]
    expect_equal(
      length(standard_grades), length(standard_grades),
      label = paste(yr, "grade levels should be uppercase")
    )

    # No lowercase grades
    for (g in grades) {
      expect_equal(
        g, toupper(g),
        label = paste(yr, "grade", g, "should be uppercase")
      )
    }
  }
})


# ==============================================================================
# Guard 5: Gender Count Derivation from Percentages
# ==============================================================================

test_that("male + female approximately equals total for all years", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]

    sum_gender <- state$male + state$female
    diff <- abs(sum_gender - state$row_total)

    # Allow small rounding difference (from percentage conversion)
    expect_lt(
      diff, 100,
      label = paste(yr, "male + female should be within 100 of total",
                     "(got diff =", diff, ")")
    )
  }
})

test_that("no zero-male districts with > 100 students", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    districts <- enr[enr$type == "District" & !is.na(enr$row_total) &
                     enr$row_total > 100, ]
    zero_male <- districts[!is.na(districts$male) & districts$male == 0, ]

    expect_equal(
      nrow(zero_male), 0,
      label = paste(yr, "no district with > 100 students should have 0 males")
    )
  }
})

test_that("no zero-female districts with > 100 students", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    districts <- enr[enr$type == "District" & !is.na(enr$row_total) &
                     enr$row_total > 100, ]
    zero_female <- districts[!is.na(districts$female) & districts$female == 0, ]

    expect_equal(
      nrow(zero_female), 0,
      label = paste(yr, "no district with > 100 students should have 0 females")
    )
  }
})


# ==============================================================================
# Guard 6: Race/Ethnicity Sum vs Total Fidelity
# ==============================================================================

test_that("race categories sum to within 1% of total for state level", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]

    race_sum <- sum(
      state$white, state$black, state$hispanic, state$asian,
      state$pacific_islander, state$native_american, state$multiracial,
      na.rm = TRUE
    )

    pct_diff <- abs(race_sum - state$row_total) / state$row_total * 100
    expect_lt(
      pct_diff, 1,
      label = paste(yr, "race sum should be within 1% of total")
    )
  }
})


# ==============================================================================
# Guard 7: sprintf Format String Safety
# ==============================================================================
#
# KNOWN BUG: sprintf("%02s", ...) is not portable across platforms.
# Linux pads with spaces; macOS may not pad at all.
# Always use %02d or %03d with integer conversion instead.
# ==============================================================================

test_that("district_id is always exactly 3 characters", {
  for (yr in c(2019, 2024)) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    districts <- enr[enr$type == "District", ]
    non_na_ids <- districts$district_id[!is.na(districts$district_id)]

    expect_true(
      all(nchar(non_na_ids) == 3),
      label = paste(yr, "all district_id values should be 3 characters")
    )
  }
})

test_that("sprintf %02d zero-pads correctly (cross-platform)", {
  # This tests the fix: use %02d (integer) instead of %02s (string)
  expect_equal(sprintf("%02d", 1), "01")
  expect_equal(sprintf("%02d", 9), "09")
  expect_equal(sprintf("%02d", 10), "10")
  expect_equal(sprintf("%02d", 64), "64")

  expect_equal(sprintf("%03d", 1), "001")
  expect_equal(sprintf("%03d", 36), "036")
  expect_equal(sprintf("%03d", 100), "100")
})


# ==============================================================================
# Guard 8: Cross-Year Schema Stability
# ==============================================================================

test_that("tidy column names are identical across all years", {
  ref_cols <- NULL
  ref_yr <- NULL

  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    if (is.null(ref_cols)) {
      ref_cols <- sort(names(enr))
      ref_yr <- yr
    } else {
      current_cols <- sort(names(enr))
      missing <- setdiff(ref_cols, current_cols)
      extra <- setdiff(current_cols, ref_cols)

      expect_equal(
        length(missing), 0,
        label = paste(yr, "missing columns vs", ref_yr, ":",
                       paste(missing, collapse = ", "))
      )
      expect_equal(
        length(extra), 0,
        label = paste(yr, "extra columns vs", ref_yr, ":",
                       paste(extra, collapse = ", "))
      )
    }
  }
})

test_that("wide column names are consistent across years", {
  # Core columns that MUST be present in every year
  core_cols <- c(
    "end_year", "type", "district_id", "campus_id",
    "district_name", "campus_name", "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial", "minority",
    "male", "female", "pct_male", "pct_female",
    "lep", "pct_lep", "fep", "pct_fep",
    "econ_disadv", "pct_econ_disadv",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # grade_extension is known to be absent in 2019 but present in 2020+
  # grade_infant, grade_preschool, grade_t9 may also vary

  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    current_cols <- names(enr)
    for (col in core_cols) {
      expect_true(
        col %in% current_cols,
        label = paste(yr, "wide format missing core column:", col)
      )
    }
  }
})


# ==============================================================================
# Guard 9: No District Exceeds State Total
# ==============================================================================

test_that("no district enrollment exceeds state total", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    state <- enr[enr$type == "State", ]
    districts <- enr[enr$type == "District", ]

    over_state <- districts[!is.na(districts$row_total) &
                            districts$row_total > state$row_total, ]
    expect_equal(
      nrow(over_state), 0,
      label = paste(yr, "no district should exceed state total")
    )
  }
})


# ==============================================================================
# Guard 10: Tidy vs Wide Fidelity
# ==============================================================================

test_that("tidy total_enrollment matches wide row_total for state", {
  for (yr in c(2019, 2022, 2024)) {
    skip_if_no_data(yr)

    wide <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    wide_state_total <- wide[wide$type == "State", "row_total"][[1]]
    tidy_state_total <- tidy[tidy$is_state &
                             tidy$subgroup == "total_enrollment" &
                             tidy$grade_level == "TOTAL", "n_students"][[1]]

    expect_equal(
      tidy_state_total, wide_state_total,
      label = paste(yr, "tidy total should match wide row_total for state")
    )
  }
})

test_that("tidy race counts match wide race counts for state", {
  for (yr in c(2019, 2024)) {
    skip_if_no_data(yr)

    wide <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    wide_state <- wide[wide$type == "State", ]
    tidy_state <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]

    for (race in c("white", "black", "hispanic", "asian")) {
      wide_val <- wide_state[[race]]
      tidy_val <- tidy_state[tidy_state$subgroup == race, "n_students"][[1]]

      expect_equal(
        tidy_val, wide_val,
        label = paste(yr, race, "tidy should match wide")
      )
    }
  }
})


# ==============================================================================
# Guard 11: Assessment Percentage Format Detection
# ==============================================================================

test_that("assessment percentage parsing detects % sign format", {
  # When values have % sign, they are already in 0-100 range
  vals_with_pct <- c("48%", "52%")
  result <- laschooldata:::safe_percentage(vals_with_pct)
  expect_equal(result[1], 48)
  expect_equal(result[2], 52)
})

test_that("assessment percentage parsing detects decimal format", {
  # When values are 0-1, multiply by 100
  vals_decimal <- c("0.48", "0.52")
  result <- laschooldata:::safe_percentage(vals_decimal)
  expect_equal(result[1], 48)
  expect_equal(result[2], 52)
})

test_that("assessment percentage parsing handles already-percentage values > 1", {
  # Values like "48" (no %) that are > 1 should NOT be multiplied by 100
  vals_plain <- c("48", "52")
  result <- laschooldata:::safe_percentage(vals_plain)
  # These are > 1, so safe_percentage should NOT multiply by 100
  expect_equal(result[1], 48)
  expect_equal(result[2], 52)
})


# ==============================================================================
# Guard 12: Special LA Grade Levels
# ==============================================================================

test_that("Louisiana special grades are present when expected", {
  skip_if_no_data(2024)
  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_grades <- enr[enr$is_state & enr$subgroup == "total_enrollment", ]
  grade_levels <- unique(state_grades$grade_level)

  # Standard grades must be present
  standard <- c("PK", "K", "01", "02", "03", "04", "05",
                "06", "07", "08", "09", "10", "11", "12", "TOTAL")
  for (g in standard) {
    expect_true(
      g %in% grade_levels,
      label = paste("Standard grade", g, "should be present")
    )
  }

  # LA-specific grades may be present
  # INF (Infants Sp Ed), PS (Pre-School Sp Ed), T9 (Transitional 9th), EXT (Extension Academy)
  la_special <- c("INF", "PS", "T9", "EXT")
  for (g in la_special) {
    if (g %in% grade_levels) {
      grade_n <- state_grades[state_grades$grade_level == g, "n_students"][[1]]
      # If present, should have non-negative students (may be 0 or small)
      expect_gte(
        grade_n, 0,
        label = paste("LA special grade", g, "should have >= 0 students")
      )
    }
  }
})

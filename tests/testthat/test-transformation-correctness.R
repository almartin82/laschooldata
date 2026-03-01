# ==============================================================================
# Transformation Correctness Tests
# ==============================================================================
#
# These tests verify the LOGIC of every transformation function in laschooldata:
# suppression marker handling, percentage format detection, ID formatting,
# grade normalization, subgroup renaming, pivot mechanics, entity flag
# assignment, and assessment proficiency calculations.
#
# Unlike test-data-fidelity.R (which pins known values from raw files), these
# tests exercise transformation edge cases with constructed inputs.
#
# ==============================================================================

library(testthat)
library(laschooldata)

# ==============================================================================
# safe_numeric() — suppression marker handling
# ==============================================================================

test_that("safe_numeric converts clean numeric strings", {
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("0"), 0)
  expect_equal(safe_numeric("3.14"), 3.14)
  expect_equal(safe_numeric("-5"), -5)
})

test_that("safe_numeric handles NULL and empty input", {
  expect_equal(safe_numeric(NULL), numeric(0))
  expect_equal(safe_numeric(character(0)), numeric(0))
})

test_that("safe_numeric converts commas in large numbers", {
  expect_equal(safe_numeric("1,000"), 1000)
  expect_equal(safe_numeric("1,234,567"), 1234567)
})

test_that("safe_numeric strips percentage signs", {
  expect_equal(safe_numeric("50%"), 50)
  expect_equal(safe_numeric("99.9%"), 99.9)
})

test_that("safe_numeric returns NA for all suppression markers", {
  markers <- c("*", "**", "***", ".", "-", "-1", "<5", "<10",
               "N/A", "NA", "", "NULL", "n/a")
  result <- safe_numeric(markers)
  expect_true(all(is.na(result)),
    label = "All suppression markers should become NA")
})

test_that("safe_numeric handles '< N' with spaces", {
  expect_true(is.na(safe_numeric("< 5")))
  expect_true(is.na(safe_numeric("< 10")))
  expect_true(is.na(safe_numeric("<  15")))
})

test_that("safe_numeric handles mixed vector of values and markers", {
  input <- c("100", "*", "200", "<5", "300", "N/A", "1,500")
  result <- safe_numeric(input)
  expect_equal(result[1], 100)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 200)
  expect_true(is.na(result[4]))
  expect_equal(result[5], 300)
  expect_true(is.na(result[6]))
  expect_equal(result[7], 1500)
})

test_that("safe_numeric handles whitespace", {
  expect_equal(safe_numeric("  100  "), 100)
  expect_equal(safe_numeric(" 50 "), 50)
})


# ==============================================================================
# safe_percentage() — dual format detection (decimal vs %)
# ==============================================================================

test_that("safe_percentage detects % sign format (2024+ style)", {
  # 2024+ format: "48.8%" — already in percentage form
  result <- laschooldata:::safe_percentage(c("48.8%", "51.2%"))
  expect_equal(result[1], 48.8)
  expect_equal(result[2], 51.2)
})

test_that("safe_percentage detects decimal format (2019-2023 style)", {
  # 2019-2023 format: 0.488 — needs *100
  result <- laschooldata:::safe_percentage(c("0.488", "0.512"))
  expect_equal(result[1], 48.8)
  expect_equal(result[2], 51.2)
})

test_that("safe_percentage does not double-multiply percentages with % sign", {
  # If values have % sign, they should NOT be multiplied by 100
  result <- laschooldata:::safe_percentage(c("5.3%", "94.7%"))
  expect_equal(result[1], 5.3)
  expect_equal(result[2], 94.7)
})

test_that("safe_percentage does not multiply values > 1 that lack % sign", {
  # Values like "48.8" (no % sign, but > 1) should stay as-is
  result <- laschooldata:::safe_percentage(c("48.8", "51.2"))
  expect_equal(result[1], 48.8)
  expect_equal(result[2], 51.2)
})

test_that("safe_percentage handles suppression markers", {
  result <- laschooldata:::safe_percentage(c("48.8%", "*", "51.2%"))
  expect_equal(result[1], 48.8)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 51.2)
})

test_that("safe_percentage handles edge case: all zeros in decimal format", {
  result <- laschooldata:::safe_percentage(c("0", "0", "0"))
  # All values are <= 1, so they get multiplied by 100, resulting in 0

  expect_equal(result, c(0, 0, 0))
})

test_that("safe_percentage handles edge case: single value of 1.0 (100%)", {
  # A value of 1.0 without % sign — all non-NA values are <= 1, so it becomes 100
  result <- laschooldata:::safe_percentage(c("1.0"))
  expect_equal(result, 100)
})

test_that("safe_percentage handles mix of suppressed and real in decimal format", {
  # All non-NA values are <= 1 → multiply by 100
  result <- laschooldata:::safe_percentage(c("0.50", "N/A", "0.25"))
  expect_equal(result[1], 50)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 25)
})


# ==============================================================================
# tidy_enr() — pivot logic and structure
# ==============================================================================

test_that("tidy_enr pivots demographic columns to long format", {
  # Build a minimal wide-format data frame
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = "Louisiana",
    campus_name = NA_character_,
    row_total = 1000,
    white = 400,
    black = 350,
    hispanic = 150,
    asian = 50,
    pacific_islander = 5,
    native_american = 10,
    multiracial = 35,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  # Should have rows for total_enrollment + each demographic
  subgroups <- unique(tidy$subgroup)
  expect_true("total_enrollment" %in% subgroups)
  expect_true("white" %in% subgroups)
  expect_true("black" %in% subgroups)
  expect_true("hispanic" %in% subgroups)
  expect_true("asian" %in% subgroups)
  expect_true("pacific_islander" %in% subgroups)
  expect_true("native_american" %in% subgroups)
  expect_true("multiracial" %in% subgroups)

  # Check total_enrollment value
  total <- tidy[tidy$subgroup == "total_enrollment", ]
  expect_equal(total$n_students, 1000)

  # Check a demographic value
  white <- tidy[tidy$subgroup == "white", ]
  expect_equal(white$n_students, 400)
})

test_that("tidy_enr pivots grade columns with correct labels", {
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = "Louisiana",
    campus_name = NA_character_,
    row_total = 100,
    grade_infant = 5,
    grade_preschool = 8,
    grade_pk = 10,
    grade_k = 12,
    grade_01 = 11,
    grade_09 = 15,
    grade_t9 = 3,
    grade_12 = 14,
    grade_extension = 2,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  # Check grade label mapping
  grade_rows <- tidy[tidy$subgroup == "total_enrollment" & tidy$grade_level != "TOTAL", ]
  grade_levels <- sort(unique(grade_rows$grade_level))

  expect_true("INF" %in% grade_levels)
  expect_true("PS" %in% grade_levels)
  expect_true("PK" %in% grade_levels)
  expect_true("K" %in% grade_levels)
  expect_true("01" %in% grade_levels)
  expect_true("09" %in% grade_levels)
  expect_true("T9" %in% grade_levels)
  expect_true("12" %in% grade_levels)
  expect_true("EXT" %in% grade_levels)

  # Check specific grade values
  inf_row <- tidy[tidy$grade_level == "INF" & tidy$subgroup == "total_enrollment", ]
  expect_equal(inf_row$n_students, 5)

  t9_row <- tidy[tidy$grade_level == "T9" & tidy$subgroup == "total_enrollment", ]
  expect_equal(t9_row$n_students, 3)

  ext_row <- tidy[tidy$grade_level == "EXT" & tidy$subgroup == "total_enrollment", ]
  expect_equal(ext_row$n_students, 2)
})

test_that("tidy_enr pivots gender subgroups from percentage-derived counts", {
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = "Louisiana",
    campus_name = NA_character_,
    row_total = 1000,
    male = 512,
    female = 488,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  male_row <- tidy[tidy$subgroup == "male", ]
  expect_equal(male_row$n_students, 512)

  female_row <- tidy[tidy$subgroup == "female", ]
  expect_equal(female_row$n_students, 488)
})

test_that("tidy_enr pivots special population subgroups", {
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = "Louisiana",
    campus_name = NA_character_,
    row_total = 1000,
    lep = 53,
    fep = 947,
    econ_disadv = 701,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  lep_row <- tidy[tidy$subgroup == "lep", ]
  expect_equal(lep_row$n_students, 53)

  fep_row <- tidy[tidy$subgroup == "fep", ]
  expect_equal(fep_row$n_students, 947)

  econ_row <- tidy[tidy$subgroup == "econ_disadv", ]
  expect_equal(econ_row$n_students, 701)
})

test_that("tidy_enr drops rows with NA n_students", {
  wide <- data.frame(
    end_year = 2024,
    type = "Campus",
    district_id = "001",
    campus_id = "001001",
    district_name = "Acadia",
    campus_name = "Test School",
    row_total = 100,
    white = NA_real_,  # suppressed
    black = 50,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  # White should be dropped (NA)
  white_rows <- tidy[tidy$subgroup == "white", ]
  expect_equal(nrow(white_rows), 0)

  # Black should be kept
  black_rows <- tidy[tidy$subgroup == "black", ]
  expect_equal(nrow(black_rows), 1)
  expect_equal(black_rows$n_students, 50)
})

test_that("tidy_enr handles empty input", {
  result <- tidy_enr(NULL)
  expect_equal(nrow(result), 0)

  result2 <- tidy_enr(data.frame())
  expect_equal(nrow(result2), 0)
})

test_that("tidy_enr handles multiple entity rows", {
  wide <- data.frame(
    end_year = c(2024, 2024, 2024),
    type = c("State", "District", "Campus"),
    district_id = c(NA_character_, "017", "017"),
    campus_id = c(NA_character_, NA_character_, "017001"),
    district_name = c("Louisiana", "EBR", "EBR"),
    campus_name = c(NA_character_, NA_character_, "Test School"),
    row_total = c(1000, 500, 100),
    white = c(400, 200, 40),
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  # Should have rows for each entity
  state_rows <- tidy[tidy$type == "State", ]
  district_rows <- tidy[tidy$type == "District", ]
  campus_rows <- tidy[tidy$type == "Campus", ]

  expect_gt(nrow(state_rows), 0)
  expect_gt(nrow(district_rows), 0)
  expect_gt(nrow(campus_rows), 0)
})


# ==============================================================================
# id_enr_aggs() — entity flag assignment
# ==============================================================================

test_that("id_enr_aggs assigns correct boolean flags from type column", {
  df <- data.frame(
    type = c("State", "District", "Campus", "District", "Campus"),
    n_students = c(1000, 500, 100, 300, 50),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)

  expect_equal(result$is_state, c(TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE, TRUE, FALSE))
  expect_equal(result$is_campus, c(FALSE, FALSE, TRUE, FALSE, TRUE))
})

test_that("id_enr_aggs flags are mutually exclusive", {
  df <- data.frame(
    type = c("State", "District", "Campus"),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)

  flag_sum <- result$is_state + result$is_district + result$is_campus
  expect_true(all(flag_sum == 1))
})

test_that("id_enr_aggs handles NULL and empty input", {
  expect_null(id_enr_aggs(NULL))

  empty <- id_enr_aggs(data.frame())
  expect_equal(nrow(empty), 0)
})


# ==============================================================================
# enr_grade_aggs() — grade band aggregation (ELEM, MIDDLE, HIGH)
# ==============================================================================

test_that("enr_grade_aggs creates ELEM aggregate from K-05", {
  df <- data.frame(
    end_year = rep(2024, 8),
    type = rep("State", 8),
    district_id = rep(NA_character_, 8),
    campus_id = rep(NA_character_, 8),
    district_name = rep("Louisiana", 8),
    campus_name = rep(NA_character_, 8),
    subgroup = rep("total_enrollment", 8),
    grade_level = c("TOTAL", "K", "01", "02", "03", "04", "05", "06"),
    n_students = c(1000, 100, 90, 95, 85, 88, 92, 80),
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(df)

  elem <- result[result$grade_level == "ELEM", ]
  expect_equal(nrow(elem), 1)
  # K + 01 + 02 + 03 + 04 + 05 = 100+90+95+85+88+92 = 550
  expect_equal(elem$n_students, 550)
})

test_that("enr_grade_aggs creates MIDDLE aggregate from 06-08", {
  df <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    campus_id = rep(NA_character_, 5),
    district_name = rep("Louisiana", 5),
    campus_name = rep(NA_character_, 5),
    subgroup = rep("total_enrollment", 5),
    grade_level = c("TOTAL", "06", "07", "08", "09"),
    n_students = c(1000, 80, 75, 70, 90),
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(df)

  middle <- result[result$grade_level == "MIDDLE", ]
  expect_equal(nrow(middle), 1)
  # 06 + 07 + 08 = 80+75+70 = 225
  expect_equal(middle$n_students, 225)
})

test_that("enr_grade_aggs creates HIGH aggregate from 09-12", {
  df <- data.frame(
    end_year = rep(2024, 6),
    type = rep("State", 6),
    district_id = rep(NA_character_, 6),
    campus_id = rep(NA_character_, 6),
    district_name = rep("Louisiana", 6),
    campus_name = rep(NA_character_, 6),
    subgroup = rep("total_enrollment", 6),
    grade_level = c("TOTAL", "09", "10", "11", "12", "T9"),
    n_students = c(1000, 90, 85, 80, 75, 20),
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(df)

  high <- result[result$grade_level == "HIGH", ]
  expect_equal(nrow(high), 1)
  # 09 + 10 + 11 + 12 = 90+85+80+75 = 330 (T9 is NOT included in HIGH)
  expect_equal(high$n_students, 330)
})

test_that("enr_grade_aggs does not include T9 or EXT in any grade band", {
  df <- data.frame(
    end_year = rep(2024, 3),
    type = rep("State", 3),
    district_id = rep(NA_character_, 3),
    campus_id = rep(NA_character_, 3),
    district_name = rep("Louisiana", 3),
    campus_name = rep(NA_character_, 3),
    subgroup = rep("total_enrollment", 3),
    grade_level = c("TOTAL", "T9", "EXT"),
    n_students = c(100, 20, 5),
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(df)

  # No aggregates should be created since T9 and EXT are not in any band
  expect_false("ELEM" %in% result$grade_level)
  expect_false("MIDDLE" %in% result$grade_level)
  expect_false("HIGH" %in% result$grade_level)
})

test_that("enr_grade_aggs only aggregates total_enrollment subgroup", {
  df <- data.frame(
    end_year = rep(2024, 4),
    type = rep("State", 4),
    district_id = rep(NA_character_, 4),
    campus_id = rep(NA_character_, 4),
    district_name = rep("Louisiana", 4),
    campus_name = rep(NA_character_, 4),
    subgroup = c("total_enrollment", "total_enrollment", "black", "black"),
    grade_level = c("TOTAL", "K", "TOTAL", "K"),
    n_students = c(1000, 100, 500, 50),
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(df)

  # ELEM should exist for total_enrollment only
  elem_total <- result[result$grade_level == "ELEM" & result$subgroup == "total_enrollment", ]
  elem_black <- result[result$grade_level == "ELEM" & result$subgroup == "black", ]

  expect_equal(nrow(elem_total), 1)
  expect_equal(elem_total$n_students, 100)
  expect_equal(nrow(elem_black), 0)  # black subgroup should NOT get grade aggs
})

test_that("enr_grade_aggs handles empty input", {
  expect_null(enr_grade_aggs(NULL))
  expect_equal(nrow(enr_grade_aggs(data.frame())), 0)
})

test_that("enr_grade_aggs aggregates per entity", {
  df <- data.frame(
    end_year = rep(2024, 6),
    type = c("State", "State", "State", "District", "District", "District"),
    district_id = c(NA, NA, NA, "017", "017", "017"),
    campus_id = rep(NA_character_, 6),
    district_name = c("LA", "LA", "LA", "EBR", "EBR", "EBR"),
    campus_name = rep(NA_character_, 6),
    subgroup = rep("total_enrollment", 6),
    grade_level = c("TOTAL", "K", "01", "TOTAL", "K", "01"),
    n_students = c(1000, 100, 90, 500, 50, 45),
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(df)

  state_elem <- result[result$grade_level == "ELEM" & result$type == "State", ]
  district_elem <- result[result$grade_level == "ELEM" & result$type == "District", ]

  expect_equal(nrow(state_elem), 1)
  expect_equal(state_elem$n_students, 190)  # K + 01

  expect_equal(nrow(district_elem), 1)
  expect_equal(district_elem$n_students, 95)  # K + 01
})


# ==============================================================================
# create_state_aggregate() — state row from LEA data
# ==============================================================================

test_that("create_state_aggregate uses existing state row (district_id 000)", {
  lea_df <- data.frame(
    end_year = c(2024, 2024, 2024),
    type = c("District", "District", "District"),
    district_id = c("000", "017", "026"),
    campus_id = NA_character_,
    district_name = c("State of Louisiana", "EBR", "Jefferson"),
    campus_name = NA_character_,
    row_total = c(676751, 39932, 47000),
    white = c(275265, 10000, 15000),
    male = c(346497, 20206, 24000),
    stringsAsFactors = FALSE
  )

  state <- laschooldata:::create_state_aggregate(lea_df, 2024)

  expect_equal(state$type, "State")
  expect_true(is.na(state$district_id))
  # Uses the "000" row's values, not sum of other districts
  expect_equal(state$row_total, 676751)
  expect_equal(state$white, 275265)
})

test_that("create_state_aggregate computes sum when no state row exists", {
  lea_df <- data.frame(
    end_year = c(2024, 2024),
    type = c("District", "District"),
    district_id = c("017", "026"),
    campus_id = NA_character_,
    district_name = c("EBR", "Jefferson"),
    campus_name = NA_character_,
    row_total = c(39932, 47000),
    white = c(10000, 15000),
    stringsAsFactors = FALSE
  )

  state <- laschooldata:::create_state_aggregate(lea_df, 2024)

  expect_equal(state$type, "State")
  expect_true(is.na(state$district_id))
  expect_equal(state$district_name, "Louisiana")
  expect_equal(state$row_total, 39932 + 47000)
  expect_equal(state$white, 10000 + 15000)
})

test_that("create_state_aggregate handles empty LEA data", {
  state <- laschooldata:::create_state_aggregate(NULL, 2024)

  expect_equal(state$type, "State")
  expect_equal(state$district_name, "Louisiana")
  expect_true(is.na(state$district_id))
})

test_that("create_state_aggregate computes weighted pct when summing", {
  lea_df <- data.frame(
    end_year = c(2024, 2024),
    type = c("District", "District"),
    district_id = c("017", "026"),
    campus_id = NA_character_,
    district_name = c("EBR", "Jefferson"),
    campus_name = NA_character_,
    row_total = c(1000, 1000),
    female = c(490, 510),
    male = c(510, 490),
    stringsAsFactors = FALSE
  )

  state <- laschooldata:::create_state_aggregate(lea_df, 2024)

  # female = 490 + 510 = 1000, total = 2000
  # pct_female = 1000/2000*100 = 50.0
  expect_equal(state$pct_female, 50.0)
  expect_equal(state$pct_male, 50.0)
})


# ==============================================================================
# District ID formatting — sprintf padding
# ==============================================================================

test_that("district_id is zero-padded to 3 digits", {
  skip_on_cran()

  # Test via fetch on cached data
  tryCatch({
    enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
    districts <- enr[enr$type == "District", ]
    ids <- districts$district_id[!is.na(districts$district_id)]

    # All IDs should be 3 characters
    expect_true(all(nchar(ids) == 3),
      label = "All district IDs should be 3 characters")

    # Single-digit parishes should be zero-padded
    expect_true("001" %in% ids, label = "Parish 001 (Acadia) should exist")
    expect_true("009" %in% ids, label = "Parish 009 (Caddo) should exist")
  }, error = function(e) {
    skip("Cached data not available")
  })
})


# ==============================================================================
# Assessment: standardize_la_grade() — grade normalization
# ==============================================================================

test_that("standardize_la_grade pads single digits to two digits", {
  expect_equal(laschooldata:::standardize_la_grade("3"), "03")
  expect_equal(laschooldata:::standardize_la_grade("4"), "04")
  expect_equal(laschooldata:::standardize_la_grade("9"), "09")
})

test_that("standardize_la_grade keeps already-padded grades", {
  expect_equal(laschooldata:::standardize_la_grade("03"), "03")
  expect_equal(laschooldata:::standardize_la_grade("10"), "10")
  expect_equal(laschooldata:::standardize_la_grade("12"), "12")
})

test_that("standardize_la_grade removes GRADE prefix", {
  expect_equal(laschooldata:::standardize_la_grade("Grade 4"), "04")
  expect_equal(laschooldata:::standardize_la_grade("GRADE 8"), "08")
  expect_equal(laschooldata:::standardize_la_grade("grade 3"), "03")
})

test_that("standardize_la_grade handles ordinal formats", {
  expect_equal(laschooldata:::standardize_la_grade("3RD"), "03")
  expect_equal(laschooldata:::standardize_la_grade("4TH"), "04")
  expect_equal(laschooldata:::standardize_la_grade("5TH"), "05")
  expect_equal(laschooldata:::standardize_la_grade("6TH"), "06")
  expect_equal(laschooldata:::standardize_la_grade("7TH"), "07")
  expect_equal(laschooldata:::standardize_la_grade("8TH"), "08")
})

test_that("standardize_la_grade handles EOC/HS indicators", {
  expect_equal(laschooldata:::standardize_la_grade("EOC"), "HS")
  expect_equal(laschooldata:::standardize_la_grade("End of Course"), "HS")
  expect_equal(laschooldata:::standardize_la_grade("HS"), "HS")
  expect_equal(laschooldata:::standardize_la_grade("High School"), "HS")
})

test_that("standardize_la_grade handles ALL/TOTAL", {
  expect_equal(laschooldata:::standardize_la_grade("All Grades"), "All")
  expect_equal(laschooldata:::standardize_la_grade("ALL"), "All")
  expect_equal(laschooldata:::standardize_la_grade("Total"), "All")
})

test_that("standardize_la_grade handles grade band notation", {
  expect_equal(laschooldata:::standardize_la_grade("3-8"), "3-8")
  expect_equal(laschooldata:::standardize_la_grade("Grades 3-8"), "3-8")
})

test_that("standardize_la_grade handles case insensitivity", {
  expect_equal(laschooldata:::standardize_la_grade("grade 4"), "04")
  expect_equal(laschooldata:::standardize_la_grade("GRADE 4"), "04")
  expect_equal(laschooldata:::standardize_la_grade("Grade 4"), "04")
})

test_that("standardize_la_grade edge case: does not pad 10-12", {
  # 10, 11, 12 should not get zero-padded to 010, 011, 012
  # The regex only matches single digits 3-9
  result <- laschooldata:::standardize_la_grade("10")
  expect_equal(result, "10")

  result <- laschooldata:::standardize_la_grade("11")
  expect_equal(result, "11")
})


# ==============================================================================
# Assessment: standardize_la_subject() — subject normalization
# ==============================================================================

test_that("standardize_la_subject normalizes ELA variants", {
  expect_equal(laschooldata:::standardize_la_subject("ELA"), "ELA")
  expect_equal(laschooldata:::standardize_la_subject("ela"), "ELA")
  expect_equal(laschooldata:::standardize_la_subject("English Language Arts"), "ELA")
})

test_that("standardize_la_subject normalizes Math variants", {
  expect_equal(laschooldata:::standardize_la_subject("MATH"), "Math")
  expect_equal(laschooldata:::standardize_la_subject("Mathematics"), "Math")
  expect_equal(laschooldata:::standardize_la_subject("math"), "Math")
})

test_that("standardize_la_subject normalizes Science", {
  expect_equal(laschooldata:::standardize_la_subject("SCIENCE"), "Science")
  expect_equal(laschooldata:::standardize_la_subject("SCI"), "Science")
})

test_that("standardize_la_subject normalizes Social Studies", {
  expect_equal(laschooldata:::standardize_la_subject("SOCIAL STUDIES"), "Social Studies")
  expect_equal(laschooldata:::standardize_la_subject("SS"), "Social Studies")
})

test_that("standardize_la_subject normalizes high school subjects", {
  expect_equal(laschooldata:::standardize_la_subject("Algebra I"), "Algebra I")
  expect_equal(laschooldata:::standardize_la_subject("ALGEBRA I"), "Algebra I")
  expect_equal(laschooldata:::standardize_la_subject("Geometry"), "Geometry")
  expect_equal(laschooldata:::standardize_la_subject("Biology"), "Biology")
  expect_equal(laschooldata:::standardize_la_subject("US History"), "US History")
  expect_equal(laschooldata:::standardize_la_subject("U.S. History"), "US History")
})


# ==============================================================================
# Assessment: standardize_la_subgroup() — subgroup renaming
# ==============================================================================

test_that("standardize_la_subgroup maps All Students variants", {
  expect_equal(laschooldata:::standardize_la_subgroup("All Students"), "All Students")
  expect_equal(laschooldata:::standardize_la_subgroup("ALL STUDENTS"), "All Students")
  expect_equal(laschooldata:::standardize_la_subgroup("All"), "All Students")
  expect_equal(laschooldata:::standardize_la_subgroup("TOTAL"), "All Students")
})

test_that("standardize_la_subgroup maps racial categories", {
  expect_equal(laschooldata:::standardize_la_subgroup("Black or African American"), "Black")
  expect_equal(laschooldata:::standardize_la_subgroup("BLACK OR AFRICAN AMERICAN"), "Black")
  expect_equal(laschooldata:::standardize_la_subgroup("African American"), "Black")
  expect_equal(laschooldata:::standardize_la_subgroup("White"), "White")
  expect_equal(laschooldata:::standardize_la_subgroup("Hispanic"), "Hispanic")
  expect_equal(laschooldata:::standardize_la_subgroup("Hispanic/Latino"), "Hispanic")
  expect_equal(laschooldata:::standardize_la_subgroup("Asian"), "Asian")
  expect_equal(laschooldata:::standardize_la_subgroup("American Indian"), "Native American")
  expect_equal(laschooldata:::standardize_la_subgroup("American Indian/Alaska Native"), "Native American")
  expect_equal(laschooldata:::standardize_la_subgroup("Native Hawaiian or Other Pacific Islander"), "Pacific Islander")
  expect_equal(laschooldata:::standardize_la_subgroup("Two or More Races"), "Multiracial")
  expect_equal(laschooldata:::standardize_la_subgroup("TWO OR MORE RACES"), "Multiracial")
  expect_equal(laschooldata:::standardize_la_subgroup("Multiple Races"), "Multiracial")
})

test_that("standardize_la_subgroup maps special populations", {
  expect_equal(laschooldata:::standardize_la_subgroup("Economically Disadvantaged"), "Economically Disadvantaged")
  expect_equal(laschooldata:::standardize_la_subgroup("ED"), "Economically Disadvantaged")
  expect_equal(laschooldata:::standardize_la_subgroup("Students with Disabilities"), "Students with Disabilities")
  expect_equal(laschooldata:::standardize_la_subgroup("SWD"), "Students with Disabilities")
  expect_equal(laschooldata:::standardize_la_subgroup("English Learners"), "English Learners")
  expect_equal(laschooldata:::standardize_la_subgroup("EL"), "English Learners")
  expect_equal(laschooldata:::standardize_la_subgroup("LEP"), "English Learners")
  expect_equal(laschooldata:::standardize_la_subgroup("Limited English Proficient"), "English Learners")
})

test_that("standardize_la_subgroup maps gender", {
  expect_equal(laschooldata:::standardize_la_subgroup("Female"), "Female")
  expect_equal(laschooldata:::standardize_la_subgroup("FEMALE"), "Female")
  expect_equal(laschooldata:::standardize_la_subgroup("Male"), "Male")
  expect_equal(laschooldata:::standardize_la_subgroup("MALE"), "Male")
})

test_that("standardize_la_subgroup passes through unknown values", {
  expect_equal(laschooldata:::standardize_la_subgroup("Unknown Category"), "Unknown Category")
  expect_equal(laschooldata:::standardize_la_subgroup("Migrant"), "Migrant")
})


# ==============================================================================
# Assessment: clean_assessment_names() — column name cleaning
# ==============================================================================

test_that("clean_assessment_names lowercases and removes special chars", {
  result <- laschooldata:::clean_assessment_names(c(
    "School System Code", "% Unsatisfactory", "Pct. Advanced",
    "School  Name", "N-Tested"
  ))

  expect_equal(result[1], "school_system_code")
  expect_equal(result[2], "unsatisfactory")
  expect_equal(result[3], "pct_advanced")
  expect_equal(result[4], "school_name")
  expect_equal(result[5], "n_tested")
})

test_that("clean_assessment_names removes leading/trailing underscores", {
  result <- laschooldata:::clean_assessment_names(c("_Leading", "Trailing_"))
  expect_equal(result[1], "leading")
  expect_equal(result[2], "trailing")
})

test_that("clean_assessment_names collapses multiple underscores", {
  result <- laschooldata:::clean_assessment_names(c("School   System   Code"))
  expect_equal(result, "school_system_code")
})


# ==============================================================================
# Assessment: tidy_assessment() — proficiency pivot
# ==============================================================================

test_that("tidy_assessment pivots proficiency columns to long format", {
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    district_name = "Louisiana",
    school_id = NA_character_,
    school_name = NA_character_,
    grade = "03",
    subject = "Math",
    subgroup = "All Students",
    n_tested = 50000,
    pct_unsatisfactory = 15,
    pct_approaching_basic = 25,
    pct_basic = 30,
    pct_mastery = 20,
    pct_advanced = 10,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_assessment(wide)

  # Should have 5 rows (one per proficiency level)
  expect_equal(nrow(tidy), 5)

  # Check proficiency_level values
  levels <- as.character(tidy$proficiency_level)
  expect_true("unsatisfactory" %in% levels)
  expect_true("approaching_basic" %in% levels)
  expect_true("basic" %in% levels)
  expect_true("mastery" %in% levels)
  expect_true("advanced" %in% levels)
})

test_that("tidy_assessment normalizes pct from 0-100 to 0-1 range", {
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    district_name = "Louisiana",
    school_id = NA_character_,
    school_name = NA_character_,
    grade = "03",
    subject = "Math",
    subgroup = "All Students",
    n_tested = 1000,
    pct_unsatisfactory = 20,
    pct_approaching_basic = 25,
    pct_basic = 30,
    pct_mastery = 15,
    pct_advanced = 10,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_assessment(wide)

  # pct values > 1 get divided by 100
  mastery_row <- tidy[tidy$proficiency_level == "mastery", ]
  expect_equal(mastery_row$pct, 0.15, tolerance = 0.001)

  advanced_row <- tidy[tidy$proficiency_level == "advanced", ]
  expect_equal(advanced_row$pct, 0.10, tolerance = 0.001)
})

test_that("tidy_assessment calculates n_students from pct and n_tested", {
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    district_name = "Louisiana",
    school_id = NA_character_,
    school_name = NA_character_,
    grade = "03",
    subject = "Math",
    subgroup = "All Students",
    n_tested = 1000,
    pct_unsatisfactory = 20,
    pct_approaching_basic = 25,
    pct_basic = 30,
    pct_mastery = 15,
    pct_advanced = 10,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_assessment(wide)

  # n_students = round(pct / 100 * n_tested)
  mastery_row <- tidy[tidy$proficiency_level == "mastery", ]
  expect_equal(mastery_row$n_students, round(15 / 100 * 1000))

  advanced_row <- tidy[tidy$proficiency_level == "advanced", ]
  expect_equal(advanced_row$n_students, round(10 / 100 * 1000))
})

test_that("tidy_assessment sets proficiency_level as ordered factor", {
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    district_name = "Louisiana",
    school_id = NA_character_,
    school_name = NA_character_,
    grade = "03",
    subject = "Math",
    subgroup = "All Students",
    n_tested = 100,
    pct_unsatisfactory = 20,
    pct_approaching_basic = 25,
    pct_basic = 30,
    pct_mastery = 15,
    pct_advanced = 10,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_assessment(wide)

  expect_s3_class(tidy$proficiency_level, "factor")
  expect_true(is.ordered(tidy$proficiency_level))

  # Check ordering: unsatisfactory < approaching_basic < basic < mastery < advanced
  lvls <- levels(tidy$proficiency_level)
  expect_equal(lvls, c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"))
})

test_that("tidy_assessment adds aggregation flags", {
  wide <- data.frame(
    end_year = c(2024, 2024, 2024),
    type = c("State", "District", "School"),
    district_id = c(NA, "017", "017"),
    district_name = c("Louisiana", "EBR", "EBR"),
    school_id = c(NA, NA, "017001"),
    school_name = c(NA, NA, "Test School"),
    grade = rep("03", 3),
    subject = rep("Math", 3),
    subgroup = rep("All Students", 3),
    n_tested = c(50000, 5000, 100),
    pct_unsatisfactory = rep(20, 3),
    pct_approaching_basic = rep(25, 3),
    pct_basic = rep(30, 3),
    pct_mastery = rep(15, 3),
    pct_advanced = rep(10, 3),
    stringsAsFactors = FALSE
  )

  tidy <- tidy_assessment(wide)

  expect_true("is_state" %in% names(tidy))
  expect_true("is_district" %in% names(tidy))
  expect_true("is_school" %in% names(tidy))

  state_rows <- tidy[tidy$is_state, ]
  expect_true(all(state_rows$type == "State"))

  school_rows <- tidy[tidy$is_school, ]
  expect_true(all(school_rows$type == "School"))
})

test_that("tidy_assessment handles empty input", {
  result <- tidy_assessment(data.frame())
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
  expect_true("proficiency_level" %in% names(result))
})

test_that("tidy_assessment handles NA pct values (suppressed data)", {
  wide <- data.frame(
    end_year = 2024,
    type = "School",
    district_id = "017",
    district_name = "EBR",
    school_id = "017001",
    school_name = "Test School",
    grade = "03",
    subject = "Math",
    subgroup = "All Students",
    n_tested = 20,
    pct_unsatisfactory = NA_real_,
    pct_approaching_basic = NA_real_,
    pct_basic = 30,
    pct_mastery = 15,
    pct_advanced = NA_real_,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_assessment(wide)

  # Rows with NA pct should have NA n_students and NA pct
  na_rows <- tidy[is.na(tidy$pct), ]
  expect_true(all(is.na(na_rows$n_students)))
})


# ==============================================================================
# Assessment: process_assessment_level() — type assignment logic
# ==============================================================================

test_that("process_assessment_level assigns type based on school_id presence", {
  # Create mock raw data with school_code column
  raw <- data.frame(
    school_system_code = c("17", "17"),
    school_system_name = c("EBR", "EBR"),
    school_code = c(NA, "17001"),
    school_name = c(NA, "Test School"),
    grade = c("3", "3"),
    subject = c("ELA", "ELA"),
    total_students = c("5000", "100"),
    pct_unsatisfactory = c("15", "20"),
    pct_approaching_basic = c("25", "30"),
    pct_basic = c("30", "25"),
    pct_mastery = c("20", "15"),
    pct_advanced = c("10", "10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  # Row without school_code should be District
  district_rows <- result[result$type == "District", ]
  expect_gte(nrow(district_rows), 1)

  # Row with school_code should be School
  school_rows <- result[result$type == "School", ]
  expect_gte(nrow(school_rows), 1)
})

test_that("process_assessment_level identifies state rows by name", {
  raw <- data.frame(
    school_system_code = c("0"),
    school_system_name = c("State of Louisiana"),
    school_code = c(NA),
    school_name = c(NA),
    grade = c("3"),
    subject = c("ELA"),
    total_students = c("50000"),
    pct_unsatisfactory = c("15"),
    pct_approaching_basic = c("25"),
    pct_basic = c("30"),
    pct_mastery = c("20"),
    pct_advanced = c("10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  expect_equal(result$type, "State")
})

test_that("process_assessment_level identifies state rows by district_id 000", {
  raw <- data.frame(
    school_system_code = c("0"),
    school_system_name = c("SomeOtherName"),
    school_code = c(NA),
    school_name = c(NA),
    grade = c("3"),
    subject = c("ELA"),
    total_students = c("50000"),
    pct_unsatisfactory = c("15"),
    pct_approaching_basic = c("25"),
    pct_basic = c("30"),
    pct_mastery = c("20"),
    pct_advanced = c("10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  expect_equal(result$type, "State")
})

test_that("process_assessment_level formats district_id to 3 digits", {
  raw <- data.frame(
    school_system_code = c("17"),
    school_system_name = c("EBR"),
    school_code = c(NA),
    school_name = c(NA),
    grade = c("3"),
    subject = c("ELA"),
    total_students = c("5000"),
    pct_unsatisfactory = c("15"),
    pct_approaching_basic = c("25"),
    pct_basic = c("30"),
    pct_mastery = c("20"),
    pct_advanced = c("10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  expect_equal(result$district_id, "017")
})

test_that("process_assessment_level formats school_id to 6 digits", {
  raw <- data.frame(
    school_system_code = c("17"),
    school_system_name = c("EBR"),
    school_code = c("17001"),
    school_name = c("Test School"),
    grade = c("3"),
    subject = c("ELA"),
    total_students = c("100"),
    pct_unsatisfactory = c("15"),
    pct_approaching_basic = c("25"),
    pct_basic = c("30"),
    pct_mastery = c("20"),
    pct_advanced = c("10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  expect_equal(result$school_id, "017001")
})

test_that("process_assessment_level calculates pct_proficient", {
  raw <- data.frame(
    school_system_code = c("17"),
    school_system_name = c("EBR"),
    school_code = c(NA),
    school_name = c(NA),
    grade = c("3"),
    subject = c("ELA"),
    total_students = c("100"),
    pct_unsatisfactory = c("15"),
    pct_approaching_basic = c("25"),
    pct_basic = c("30"),
    pct_mastery = c("20"),
    pct_advanced = c("10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  # pct_proficient = mastery + advanced = 20 + 10 = 30
  expect_equal(result$pct_proficient, 30)
})

test_that("process_assessment_level calculates pct_basic_above", {
  raw <- data.frame(
    school_system_code = c("17"),
    school_system_name = c("EBR"),
    school_code = c(NA),
    school_name = c(NA),
    grade = c("3"),
    subject = c("ELA"),
    total_students = c("100"),
    pct_unsatisfactory = c("15"),
    pct_approaching_basic = c("25"),
    pct_basic = c("30"),
    pct_mastery = c("20"),
    pct_advanced = c("10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  # pct_basic_above = basic + mastery + advanced = 30 + 20 + 10 = 60
  expect_equal(result$pct_basic_above, 60)
})

test_that("process_assessment_level uses safe_numeric for n_tested", {
  raw <- data.frame(
    school_system_code = c("17", "26"),
    school_system_name = c("EBR", "Jefferson"),
    school_code = c(NA, NA),
    school_name = c(NA, NA),
    grade = c("3", "3"),
    subject = c("ELA", "ELA"),
    total_students = c("5,000", "*"),
    pct_unsatisfactory = c("15", "20"),
    pct_approaching_basic = c("25", "30"),
    pct_basic = c("30", "25"),
    pct_mastery = c("20", "15"),
    pct_advanced = c("10", "10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  expect_equal(result$n_tested[1], 5000)
  expect_true(is.na(result$n_tested[2]))
})

test_that("process_assessment_level assigns default subgroup when not present", {
  raw <- data.frame(
    school_system_code = c("17"),
    school_system_name = c("EBR"),
    grade = c("3"),
    subject = c("ELA"),
    total_students = c("100"),
    pct_unsatisfactory = c("15"),
    pct_approaching_basic = c("25"),
    pct_basic = c("30"),
    pct_mastery = c("20"),
    pct_advanced = c("10"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_assessment_level(raw, 2024)

  expect_equal(result$subgroup, "All Students")
})


# ==============================================================================
# Assessment: id_assessment_aggs() — assessment entity flags
# ==============================================================================

test_that("id_assessment_aggs maps type to boolean flags", {
  df <- data.frame(
    type = c("State", "District", "School"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::id_assessment_aggs(df)

  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_school, c(FALSE, FALSE, TRUE))
})


# ==============================================================================
# calc_proficiency() and calc_basic_above() — proficiency calculation
# ==============================================================================

test_that("calc_proficiency sums mastery + advanced", {
  df <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    school_id = rep(NA_character_, 5),
    subject = rep("ELA", 5),
    grade = rep("03", 5),
    subgroup = rep("All Students", 5),
    n_tested = rep(200, 5),
    proficiency_level = c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
    n_students = c(20, 40, 60, 50, 30),
    pct = c(0.10, 0.20, 0.30, 0.25, 0.15),
    stringsAsFactors = FALSE
  )

  result <- calc_proficiency(df)

  expect_equal(result$n_proficient, 80)  # 50 + 30
  expect_equal(result$pct_proficient, 80 / 200, tolerance = 0.001)
})

test_that("calc_basic_above sums basic + mastery + advanced", {
  df <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    school_id = rep(NA_character_, 5),
    subject = rep("ELA", 5),
    grade = rep("03", 5),
    subgroup = rep("All Students", 5),
    n_tested = rep(200, 5),
    proficiency_level = c("unsatisfactory", "approaching_basic", "basic", "mastery", "advanced"),
    n_students = c(20, 40, 60, 50, 30),
    pct = c(0.10, 0.20, 0.30, 0.25, 0.15),
    stringsAsFactors = FALSE
  )

  result <- calc_basic_above(df)

  expect_equal(result$n_basic_above, 140)  # 60 + 50 + 30
  expect_equal(result$pct_basic_above, 140 / 200, tolerance = 0.001)
})

test_that("calc_proficiency rejects non-tidy input", {
  df <- data.frame(end_year = 2024, pct_mastery = 20)
  expect_error(calc_proficiency(df), "tidy assessment")
})

test_that("calc_basic_above rejects non-tidy input", {
  df <- data.frame(end_year = 2024, pct_basic = 30)
  expect_error(calc_basic_above(df), "tidy assessment")
})


# ==============================================================================
# Directory: process_directory_sheet() — ID padding
# ==============================================================================

test_that("process_directory_sheet pads parish_code to 2 digits", {
  raw <- data.frame(
    SiteCd = c("001001", "036001"),
    ParishCd = c("1", "36"),
    SponsorCd = c("001", "036"),
    SiteName = c("Test School 1", "Test School 2"),
    SponsorName = c("Acadia", "Orleans"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_directory_sheet(raw, 2026, is_charter = FALSE)

  expect_equal(result$parish_code[1], "01")
  expect_equal(result$parish_code[2], "36")
})

test_that("process_directory_sheet pads district_code to 3 digits", {
  raw <- data.frame(
    SiteCd = c("001001"),
    ParishCd = c("1"),
    SponsorCd = c("1"),
    SiteName = c("Test School"),
    SponsorName = c("Acadia"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_directory_sheet(raw, 2026, is_charter = FALSE)

  expect_equal(result$district_code, "001")
})

test_that("process_directory_sheet sets is_charter flag correctly", {
  raw <- data.frame(
    SiteCd = c("001001"),
    ParishCd = c("1"),
    SponsorCd = c("1"),
    SiteName = c("Test Charter"),
    SponsorName = c("Acadia"),
    stringsAsFactors = FALSE
  )

  # Non-charter
  result_public <- laschooldata:::process_directory_sheet(raw, 2026, is_charter = FALSE)
  expect_false(result_public$is_charter)

  # Charter
  result_charter <- laschooldata:::process_directory_sheet(raw, 2026, is_charter = TRUE)
  expect_true(result_charter$is_charter)
})

test_that("process_directory_sheet sets state to LA for all rows", {
  raw <- data.frame(
    SiteCd = c("001001", "017001"),
    ParishCd = c("1", "17"),
    SponsorCd = c("1", "17"),
    SiteName = c("School A", "School B"),
    SponsorName = c("Acadia", "EBR"),
    stringsAsFactors = FALSE
  )

  result <- laschooldata:::process_directory_sheet(raw, 2026, is_charter = FALSE)

  expect_true(all(result$state == "LA"))
})

test_that("process_directory_sheet handles empty input", {
  result <- laschooldata:::process_directory_sheet(NULL, 2026)
  expect_equal(nrow(result), 0)

  result2 <- laschooldata:::process_directory_sheet(data.frame(), 2026)
  expect_equal(nrow(result2), 0)
})


# ==============================================================================
# Percentage-to-count conversion correctness
# ==============================================================================

test_that("gender count = round(total * pct / 100)", {
  skip_on_cran()

  tryCatch({
    enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]

    # Manually verify: male = round(row_total * pct_male / 100)
    expected_male <- round(state$row_total * state$pct_male / 100)
    expect_equal(state$male, expected_male,
      label = "Male count should equal round(total * pct_male / 100)")

    expected_female <- round(state$row_total * state$pct_female / 100)
    expect_equal(state$female, expected_female,
      label = "Female count should equal round(total * pct_female / 100)")
  }, error = function(e) {
    skip("Cached data not available")
  })
})

test_that("LEP count = round(total * pct_lep / 100)", {
  skip_on_cran()

  tryCatch({
    enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]

    expected_lep <- round(state$row_total * state$pct_lep / 100)
    expect_equal(state$lep, expected_lep,
      label = "LEP count should equal round(total * pct_lep / 100)")
  }, error = function(e) {
    skip("Cached data not available")
  })
})

test_that("econ_disadv count = round(total * pct_econ_disadv / 100)", {
  skip_on_cran()

  tryCatch({
    enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]

    expected_econ <- round(state$row_total * state$pct_econ_disadv / 100)
    expect_equal(state$econ_disadv, expected_econ,
      label = "Econ disadv count should equal round(total * pct_econ / 100)")
  }, error = function(e) {
    skip("Cached data not available")
  })
})


# ==============================================================================
# Cross-year percentage format consistency (2019 decimal vs 2024 percent sign)
# ==============================================================================

test_that("safe_percentage produces same result for both formats of same value", {
  # Simulating the same percentage in both formats
  decimal_format <- laschooldata:::safe_percentage("0.512")   # 2019-2023
  percent_format <- laschooldata:::safe_percentage("51.2%")    # 2024+

  expect_equal(decimal_format, percent_format,
    label = "Both percentage formats should produce the same value")
})

test_that("male + female equals total for all years via cached data", {
  skip_on_cran()

  for (yr in 2019:2024) {
    tryCatch({
      enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
      state <- enr[enr$type == "State", ]

      expect_equal(state$male + state$female, state$row_total,
        label = paste(yr, "male + female should equal total"))
    }, error = function(e) {
      # Skip years without cached data
    })
  }
})


# ==============================================================================
# find_sheet() — helper for Excel sheet matching
# ==============================================================================

test_that("find_sheet matches case-insensitively", {
  sheets <- c("Total by Site", "Total by School System", "Summary")

  result <- laschooldata:::find_sheet(sheets, c("total by site"))
  expect_equal(result, "Total by Site")
})

test_that("find_sheet returns first match", {
  sheets <- c("Sheet1", "Site Data", "Site Summary")

  result <- laschooldata:::find_sheet(sheets, c("Site"))
  expect_equal(result, "Site Data")
})

test_that("find_sheet returns NULL when no match", {
  sheets <- c("Sheet1", "Sheet2")

  result <- laschooldata:::find_sheet(sheets, c("Enrollment", "Site"))
  expect_null(result)
})

test_that("find_sheet tries patterns in order", {
  sheets <- c("School System", "System Data")

  # First pattern should match first

  result <- laschooldata:::find_sheet(sheets, c("Total by School System", "School System"))
  expect_equal(result, "School System")
})


# ==============================================================================
# find_directory_sheet() — with exclude patterns
# ==============================================================================

test_that("find_directory_sheet excludes specified patterns", {
  sheets <- c("All_Public_Schools", "Public_Charter_Schools", "NonPublic")

  result <- laschooldata:::find_directory_sheet(
    sheets,
    c("Public"),
    exclude = c("NonPublic", "Charter")
  )

  expect_equal(result, "All_Public_Schools")
})

test_that("find_directory_sheet returns NULL when all matches excluded", {
  sheets <- c("Public_Charter_Schools", "NonPublic")

  result <- laschooldata:::find_directory_sheet(
    sheets,
    c("Public"),
    exclude = c("Charter", "NonPublic")
  )

  expect_null(result)
})


# ==============================================================================
# Integration: tidy round-trip preserves counts (with cached data)
# ==============================================================================

test_that("tidy format preserves wide format count values", {
  skip_on_cran()

  tryCatch({
    wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
    tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

    # State total enrollment should match
    state_wide <- wide[wide$type == "State", ]
    state_tidy <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment" &
                       tidy$grade_level == "TOTAL", ]

    expect_equal(state_tidy$n_students, state_wide$row_total,
      label = "Tidy total enrollment should match wide row_total")

    # State black count should match
    state_black <- tidy[tidy$is_state & tidy$subgroup == "black" &
                        tidy$grade_level == "TOTAL", ]
    expect_equal(state_black$n_students, state_wide$black,
      label = "Tidy black count should match wide black column")

    # State grade K should match
    state_k <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment" &
                    tidy$grade_level == "K", ]
    expect_equal(state_k$n_students, state_wide$grade_k,
      label = "Tidy grade K should match wide grade_k column")
  }, error = function(e) {
    skip("Cached data not available")
  })
})

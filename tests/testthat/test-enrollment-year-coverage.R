# ==============================================================================
# Enrollment Year Coverage Tests
# ==============================================================================
#
# Per-year pinned-value tests for ALL enrollment years (2019-2024).
# Every pinned number traces back to the LDOE Multi Stats file for that year.
#
# Verifies:
# - State total enrollment
# - East Baton Rouge Parish enrollment
# - Subgroup completeness
# - Grade level completeness
# - Entity flags
# - District and campus counts
#
# ==============================================================================

library(testthat)
library(laschooldata)

# Skip helper - uses cache, no network needed if cached
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
# 2019 Pinned Values
# ==============================================================================

test_that("2019: state total = 643,986", {
  skip_if_no_data(2019)
  enr <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(nrow(state), 1)
  expect_equal(state$row_total, 643986)
})

test_that("2019: state race counts match LDOE", {
  skip_if_no_data(2019)
  enr <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$black, 252683)
  expect_equal(state$white, 303149)
  expect_equal(state$hispanic, 53778)
  expect_equal(state$asian, 10452)
  expect_equal(state$pacific_islander, 560)
  expect_equal(state$native_american, 4186)
  expect_equal(state$multiracial, 19178)
  expect_equal(state$minority, 340837)
})

test_that("2019: state gender from percentages", {
  skip_if_no_data(2019)
  enr <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$pct_male, 51.3)
  expect_equal(state$pct_female, 48.7)
  expect_equal(state$male, 330669)
  expect_equal(state$female, 313317)
})

test_that("2019: EBR Parish total = 41,637", {
  skip_if_no_data(2019)
  enr <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  ebr <- enr[enr$type == "District" & enr$district_id == "017", ]
  expect_equal(nrow(ebr), 1)
  expect_equal(ebr$row_total, 41637)
  expect_equal(ebr$black, 29909)
  expect_equal(ebr$white, 4770)
})

test_that("2019: entity counts", {
  skip_if_no_data(2019)
  enr <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(enr[enr$type == "District", ]), 76)
  expect_equal(nrow(enr[enr$type == "Campus", ]), 1273)
})

test_that("2019: special populations", {
  skip_if_no_data(2019)
  enr <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$lep, 24908)
  expect_equal(state$pct_lep, 3.9)
  expect_equal(state$econ_disadv, 436524)
  expect_equal(state$pct_econ_disadv, 67.8)
})


# ==============================================================================
# 2020 Pinned Values
# ==============================================================================

test_that("2020: state total = 624,527", {
  skip_if_no_data(2020)
  enr <- fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(nrow(state), 1)
  expect_equal(state$row_total, 624527)
})

test_that("2020: state race counts match LDOE", {
  skip_if_no_data(2020)
  enr <- fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$black, 243908)
  expect_equal(state$white, 291772)
  expect_equal(state$hispanic, 54251)
  expect_equal(state$asian, 10232)
  expect_equal(state$pacific_islander, 538)
  expect_equal(state$native_american, 3984)
  expect_equal(state$multiracial, 19842)
  expect_equal(state$minority, 332755)
})

test_that("2020: state gender from percentages", {
  skip_if_no_data(2020)
  enr <- fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$pct_male, 51.3)
  expect_equal(state$pct_female, 48.7)
  expect_equal(state$male, 320170)
  expect_equal(state$female, 304357)
})

test_that("2020: EBR Parish total = 40,577", {
  skip_if_no_data(2020)
  enr <- fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  ebr <- enr[enr$type == "District" & enr$district_id == "017", ]
  expect_equal(nrow(ebr), 1)
  expect_equal(ebr$row_total, 40577)
  expect_equal(ebr$black, 28906)
  expect_equal(ebr$white, 4653)
})

test_that("2020: entity counts", {
  skip_if_no_data(2020)
  enr <- fetch_enr(2020, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(enr[enr$type == "District", ]), 75)
  expect_equal(nrow(enr[enr$type == "Campus", ]), 1273)
})


# ==============================================================================
# 2021 Pinned Values
# ==============================================================================

test_that("2021: state total = 615,839", {
  skip_if_no_data(2021)
  enr <- fetch_enr(2021, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(nrow(state), 1)
  expect_equal(state$row_total, 615839)
})

test_that("2021: state race counts match LDOE", {
  skip_if_no_data(2021)
  enr <- fetch_enr(2021, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$black, 239200)
  expect_equal(state$white, 283770)
  expect_equal(state$hispanic, 57761)
  expect_equal(state$asian, 9930)
  expect_equal(state$pacific_islander, 500)
  expect_equal(state$native_american, 3752)
  expect_equal(state$multiracial, 20926)
  expect_equal(state$minority, 332069)
})

test_that("2021: state gender from percentages", {
  skip_if_no_data(2021)
  enr <- fetch_enr(2021, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$pct_male, 51.2)
  expect_equal(state$pct_female, 48.8)
  expect_equal(state$male, 315193)
  expect_equal(state$female, 300646)
})

test_that("2021: EBR Parish total = 41,332", {
  skip_if_no_data(2021)
  enr <- fetch_enr(2021, tidy = FALSE, use_cache = TRUE)
  ebr <- enr[enr$type == "District" & enr$district_id == "017", ]
  expect_equal(nrow(ebr), 1)
  expect_equal(ebr$row_total, 41332)
  expect_equal(ebr$black, 29121)
  expect_equal(ebr$white, 4707)
})

test_that("2021: entity counts", {
  skip_if_no_data(2021)
  enr <- fetch_enr(2021, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(enr[enr$type == "District", ]), 75)
  expect_equal(nrow(enr[enr$type == "Campus", ]), 1266)
})


# ==============================================================================
# 2022 Pinned Values
# ==============================================================================

test_that("2022: state total = 685,606", {
  skip_if_no_data(2022)
  enr <- fetch_enr(2022, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(nrow(state), 1)
  expect_equal(state$row_total, 685606)
})

test_that("2022: state race counts match LDOE", {
  skip_if_no_data(2022)
  enr <- fetch_enr(2022, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$black, 286605)
  expect_equal(state$white, 289590)
  expect_equal(state$hispanic, 70054)
  expect_equal(state$asian, 10768)
  expect_equal(state$pacific_islander, 529)
  expect_equal(state$native_american, 3854)
  expect_equal(state$multiracial, 24206)
  expect_equal(state$minority, 396016)
})

test_that("2022: state gender from percentages (decimal format)", {
  skip_if_no_data(2022)
  enr <- fetch_enr(2022, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  # 2022 uses decimal format (0.511...) which safe_percentage normalizes
  expect_gt(state$pct_male, 50)
  expect_lt(state$pct_male, 52)
  expect_gt(state$pct_female, 48)
  expect_lt(state$pct_female, 50)
  expect_equal(state$male, 350850)
  expect_equal(state$female, 334756)
})

test_that("2022: EBR Parish total = 40,660", {
  skip_if_no_data(2022)
  enr <- fetch_enr(2022, tidy = FALSE, use_cache = TRUE)
  ebr <- enr[enr$type == "District" & enr$district_id == "017", ]
  expect_equal(nrow(ebr), 1)
  expect_equal(ebr$row_total, 40660)
  expect_equal(ebr$black, 28090)
  expect_equal(ebr$white, 4641)
})

test_that("2022: entity counts", {
  skip_if_no_data(2022)
  enr <- fetch_enr(2022, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(enr[enr$type == "District", ]), 76)
  expect_equal(nrow(enr[enr$type == "Campus", ]), 1260)
})


# ==============================================================================
# 2023 Pinned Values
# ==============================================================================

test_that("2023: state total = 681,176", {
  skip_if_no_data(2023)
  enr <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(nrow(state), 1)
  expect_equal(state$row_total, 681176)
})

test_that("2023: state race counts match LDOE", {
  skip_if_no_data(2023)
  enr <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$black, 284847)
  expect_equal(state$white, 282308)
  expect_equal(state$hispanic, 73627)
  expect_equal(state$asian, 10816)
  expect_equal(state$pacific_islander, 555)
  expect_equal(state$native_american, 3771)
  expect_equal(state$multiracial, 25252)
  expect_equal(state$minority, 398868)
})

test_that("2023: state gender from percentages (decimal format)", {
  skip_if_no_data(2023)
  enr <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_gt(state$pct_male, 50)
  expect_lt(state$pct_male, 52)
  expect_gt(state$pct_female, 48)
  expect_lt(state$pct_female, 50)
  expect_equal(state$male, 348443)
  expect_equal(state$female, 332733)
})

test_that("2023: EBR Parish total = 40,443", {
  skip_if_no_data(2023)
  enr <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  ebr <- enr[enr$type == "District" & enr$district_id == "017", ]
  expect_equal(nrow(ebr), 1)
  expect_equal(ebr$row_total, 40443)
  expect_equal(ebr$black, 27937)
  expect_equal(ebr$white, 4488)
})

test_that("2023: entity counts", {
  skip_if_no_data(2023)
  enr <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(enr[enr$type == "District", ]), 76)
  expect_equal(nrow(enr[enr$type == "Campus", ]), 1250)
})


# ==============================================================================
# 2024 Pinned Values
# ==============================================================================

test_that("2024: state total = 676,751", {
  skip_if_no_data(2024)
  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(nrow(state), 1)
  expect_equal(state$row_total, 676751)
})

test_that("2024: state race counts match LDOE", {
  skip_if_no_data(2024)
  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$black, 282521)
  expect_equal(state$white, 275265)
  expect_equal(state$hispanic, 77836)
  expect_equal(state$asian, 10745)
  expect_equal(state$pacific_islander, 493)
  expect_equal(state$native_american, 3666)
  expect_equal(state$multiracial, 26225)
  expect_equal(state$minority, 401486)
})

test_that("2024: state gender from percentages (% format)", {
  skip_if_no_data(2024)
  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$pct_male, 51.2)
  expect_equal(state$pct_female, 48.8)
  expect_equal(state$male, 346497)
  expect_equal(state$female, 330254)
})

test_that("2024: EBR Parish total = 39,932", {
  skip_if_no_data(2024)
  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  ebr <- enr[enr$type == "District" & enr$district_id == "017", ]
  expect_equal(nrow(ebr), 1)
  expect_equal(ebr$row_total, 39932)
  expect_equal(ebr$black, 27194)
  expect_equal(ebr$white, 4376)
})

test_that("2024: entity counts", {
  skip_if_no_data(2024)
  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(enr[enr$type == "District", ]), 76)
  expect_equal(nrow(enr[enr$type == "Campus", ]), 1257)
})

test_that("2024: special populations", {
  skip_if_no_data(2024)
  enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state <- enr[enr$type == "State", ]
  expect_equal(state$lep, 35868)
  expect_equal(state$pct_lep, 5.3)
  expect_equal(state$econ_disadv, 474402)
  expect_equal(state$pct_econ_disadv, 70.1)
})


# ==============================================================================
# Per-Year Tidy Subgroup Completeness (all years)
# ==============================================================================

test_that("tidy subgroup completeness for all years", {
  expected_subgroups <- c(
    "total_enrollment", "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial", "minority",
    "male", "female", "lep", "fep", "econ_disadv"
  )

  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    state_data <- enr[enr$is_state & enr$grade_level == "TOTAL", ]
    present <- unique(state_data$subgroup)

    for (sg in expected_subgroups) {
      expect_true(
        sg %in% present,
        label = paste(yr, "missing subgroup:", sg)
      )
      sg_n <- state_data[state_data$subgroup == sg, "n_students"][[1]]
      expect_gt(
        sg_n, 0,
        label = paste(yr, sg, "should have > 0 students")
      )
    }
  }
})


# ==============================================================================
# Per-Year Grade Level Completeness (all years)
# ==============================================================================

test_that("grade level completeness for all years", {
  expected_grades <- c("PK", "K", "01", "02", "03", "04", "05",
                       "06", "07", "08", "09", "10", "11", "12")

  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    state_grades <- enr[enr$is_state &
                        enr$subgroup == "total_enrollment" &
                        enr$grade_level != "TOTAL", ]

    for (grade in expected_grades) {
      grade_rows <- state_grades[state_grades$grade_level == grade, ]
      expect_equal(
        nrow(grade_rows), 1,
        label = paste(yr, "should have exactly 1 row for grade", grade)
      )
      expect_gt(
        grade_rows$n_students, 10000,
        label = paste(yr, "grade", grade, "should have > 10,000 students")
      )
    }
  }
})


# ==============================================================================
# Per-Year Entity Flag Correctness (all years)
# ==============================================================================

test_that("entity flags mutually exclusive for all years", {
  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    flag_sum <- enr$is_state + enr$is_district + enr$is_campus
    expect_true(
      all(flag_sum == 1),
      label = paste(yr, "each row should have exactly one flag TRUE")
    )
  }
})


# ==============================================================================
# Trend Consistency: Enrollment Should Not Jump > 15% Year-to-Year
# ==============================================================================

test_that("state enrollment year-over-year changes are reasonable", {
  state_totals <- numeric(0)

  for (yr in 2019:2024) {
    skip_if_no_data(yr)
    enr <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    state <- enr[enr$type == "State", ]
    state_totals[as.character(yr)] <- state$row_total
  }

  years_avail <- as.integer(names(state_totals))
  if (length(years_avail) >= 2) {
    for (i in 2:length(years_avail)) {
      pct_change <- abs(
        (state_totals[i] - state_totals[i - 1]) / state_totals[i - 1] * 100
      )
      expect_lt(
        pct_change, 15,
        label = paste("Change from", years_avail[i - 1], "to", years_avail[i],
                       "=", round(pct_change, 1), "% should be < 15%")
      )
    }
  }
})


# ==============================================================================
# EBR Declining Trend: District Should Show Declining Enrollment 2019-2024
# ==============================================================================

test_that("EBR enrollment shows expected decline from 2019 to 2024", {
  skip_if_no_data(2019)
  skip_if_no_data(2024)

  enr_2019 <- fetch_enr(2019, tidy = FALSE, use_cache = TRUE)
  enr_2024 <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  ebr_2019 <- enr_2019[enr_2019$type == "District" & enr_2019$district_id == "017", ]
  ebr_2024 <- enr_2024[enr_2024$type == "District" & enr_2024$district_id == "017", ]

  # EBR has declined from ~41,637 to ~39,932

  expect_gt(ebr_2019$row_total, ebr_2024$row_total,
    label = "EBR enrollment should have declined from 2019 to 2024")
})

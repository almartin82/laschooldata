# Louisiana School Data Expansion Research

**Last Updated:** 2026-01-11 **Theme Researched:** Assessment (LEAP)
Data

## Current Package Status

- **R-CMD-check:** PASSING
- **Python tests:** PASSING
- **pkgdown:** PASSING
- **Current capabilities:** Enrollment data only (2019-2024)
- **Assessment capability:** NONE (this is a new data type)

## Data Sources Found

### Source 1: LEAP Grades 3-8 Assessment by Subgroup (Primary - Recommended)

| Field           | Value                                                                                                                                       |
|-----------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| URL Pattern     | `https://doe.louisiana.gov/docs/default-source/test-results/{YEAR}-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx` |
| HTTP Status     | 200 (2019-2024 verified)                                                                                                                    |
| Format          | Excel (.xlsx)                                                                                                                               |
| Years Available | 2019, 2021-2024 (5 years)                                                                                                                   |
| Access          | Direct download, no auth required                                                                                                           |
| Data Level      | State, District (LEA), School                                                                                                               |
| Subjects        | ELA, Math, Science, Social Studies                                                                                                          |
| Grades          | 3, 4, 5, 6, 7, 8                                                                                                                            |

**Verified URLs:** - 2024:
<https://doe.louisiana.gov/docs/default-source/test-results/2024-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx> -
2023:
<https://doe.louisiana.gov/docs/default-source/test-results/2023-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx> -
2022:
<https://doe.louisiana.gov/docs/default-source/test-results/2022-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx> -
2021:
<https://doe.louisiana.gov/docs/default-source/test-results/2021-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx> -
2019:
<https://doe.louisiana.gov/docs/default-source/test-results/2019-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx>

**Note:** 2020 appears to be missing (COVID year with different
assessment structure). 2016-2018 use different formats.

### Source 2: LEAP High School Assessment by Subgroup

| Field           | Value                                                                                                                                               |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| URL Pattern     | `https://doe.louisiana.gov/docs/default-source/test-results/{YEAR}-state-lea-school-leap-high-school-achievement-level-summary-with-subgroups.xlsx` |
| HTTP Status     | 200 (2019, 2021-2022 verified)                                                                                                                      |
| Format          | Excel (.xlsx)                                                                                                                                       |
| Years Available | 2019, 2021-2022 (3 years)                                                                                                                           |
| Access          | Direct download, no auth required                                                                                                                   |
| Data Level      | State, District (LEA), School                                                                                                                       |
| Subjects        | English I, English II, Algebra I, Geometry, Biology, US History                                                                                     |

**Verified URLs:** - 2022:
<https://doe.louisiana.gov/docs/default-source/test-results/2022-state-lea-school-leap-high-school-achievement-level-summary-with-subgroups.xlsx> -
2021:
<https://doe.louisiana.gov/docs/default-source/test-results/2021-state-lea-school-leap-high-school-achievement-level-summary-with-subgroups.xlsx> -
2019:
<https://doe.louisiana.gov/docs/default-source/test-results/2019-state-lea-school-high-school-eoc-achievement-level-summary-with-subgroups.xlsx>
(note different naming)

**Note:** 2020, 2023-2024 files appear to use different naming or are in
different locations.

### Source 3: Historical LEAP Data (2016-2018)

| Field    | Value                                          |
|----------|------------------------------------------------|
| Format   | Excel (.xlsx)                                  |
| Years    | 2016-2018 (limited availability)               |
| Coverage | State and District only (no school-level data) |
| Quality  | Lower quality, different structure             |

**Available Files:** - 2018:
<https://doe.louisiana.gov/docs/default-source/test-results/2018-leap-2025-state-lea-school-achievement-level-summary.xlsx> -
2017:
<https://doe.louisiana.gov/docs/default-source/test-results/2017-state-lea-school-leap-achievement-level-summary.xlsx> -
2016:
<https://doe.louisiana.gov/docs/default-source/test-results/spring-2016-state-district-achievement-level-summary.xlsx>

**Note:** These early files have different column structures and missing
subjects. Recommend starting with 2019+ data.

### Source 4: State/District-Level Summary Files

| Field       | Value                                                                                                                         |
|-------------|-------------------------------------------------------------------------------------------------------------------------------|
| URL Pattern | `https://doe.louisiana.gov/docs/default-source/test-results/spring-{YEAR}-leap-2025-state-lea-achievement-level-summary.xlsx` |
| Years       | 2021-2025                                                                                                                     |
| Data Level  | State and District only (no school)                                                                                           |
| Use Case    | Quick district-level analysis                                                                                                 |

**Not recommended** for primary implementation - use subgroup files with
school-level data instead.

------------------------------------------------------------------------

### Source 5: Cohort Graduation Rates by Subgroup (Already Documented)

| Field           | Value                                                                                                                                     |
|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| URL Pattern     | `https://doe.louisiana.gov/docs/default-source/data-management/{YEAR}-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx` |
| HTTP Status     | 200 (all years verified)                                                                                                                  |
| Format          | Excel (.xlsx)                                                                                                                             |
| Years Available | 2014-2025 (12 years)                                                                                                                      |
| Access          | Direct download, no auth required                                                                                                         |

**Verified URLs:** - 2025:
<https://doe.louisiana.gov/docs/default-source/data-management/2025-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx> -
2024:
<https://doe.louisiana.gov/docs/default-source/data-management/2024-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx> -
2023:
<https://doe.louisiana.gov/docs/default-source/data-management/2023-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx> -
2022:
<https://doe.louisiana.gov/docs/default-source/data-management/2022-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx> -
2021:
<https://doe.louisiana.gov/docs/default-source/data-management/2021-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx> -
2020:
<https://doe.louisiana.gov/docs/default-source/data-management/2020-state-lea-and-school-cohort-graduation-rates-by-subgroups.xlsx>
(note different naming) - 2019:
<https://doe.louisiana.gov/docs/default-source/data-management/2019-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx> -
2018:
<https://doe.louisiana.gov/docs/default-source/data-management/2018-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx> -
2017:
<https://doe.louisiana.gov/docs/default-source/data-management/2017-cohort-grad-rates-by-subgroups_public.xlsx>
(note different naming) - 2016:
<https://doe.louisiana.gov/docs/default-source/data-management/2016-cohort-grad-rates-by-subgroups.xlsx> -
2015:
<https://doe.louisiana.gov/docs/default-source/data-management/2015-cohort-grad-rates-by-subgroups.xlsx> -
2014:
<https://doe.louisiana.gov/docs/default-source/data-management/2014-cohort-grad-rates-by-subgroups.xlsx>

### Source 2: Historical Summary (2005-2025)

| Field       | Value                                                                                                                                            |
|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| URL         | <https://doe.louisiana.gov/docs/default-source/data-management/2005-2025-state-school-system-cohort-graduation-and-credential-rate-summary.xlsx> |
| HTTP Status | 200                                                                                                                                              |
| Format      | Excel (.xlsx)                                                                                                                                    |
| Years       | 2005-2025 (state and district level only)                                                                                                        |
| Access      | Direct download                                                                                                                                  |
| **Note**    | Has formatting issues for 2022-2025 columns; use subgroup files instead                                                                          |

### Source 3: Credential Rates by Subgroup

| Field       | Value                                                                                                                                       |
|-------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| URL Pattern | `https://doe.louisiana.gov/docs/default-source/data-management/{YEAR}-state-school-system-school-cohort-credential-rates-by-subgroups.xlsx` |
| HTTP Status | 200                                                                                                                                         |
| Format      | Excel (.xlsx)                                                                                                                               |
| Years       | 2013-2025                                                                                                                                   |
| Access      | Direct download                                                                                                                             |

### Source 4: School-Level Summary

| Field       | Value                                                                                                                            |
|-------------|----------------------------------------------------------------------------------------------------------------------------------|
| URL Pattern | `https://doe.louisiana.gov/docs/default-source/data-management/{YEAR}-school-cohort-graduation-and-credential-rate-summary.xlsx` |
| HTTP Status | 200                                                                                                                              |
| Format      | Excel (.xlsx)                                                                                                                    |
| Years       | 2019-2025                                                                                                                        |

## Schema Analysis

### Excel File Structure

**All assessment files follow this pattern:** - Row 1: Title (e.g.,
“Percent of Students at Each Achievement Level for Spring 2025 LEAP 2025
Grades 3-8 Tests”) - Row 2: FERPA disclaimer - Row 3: Multi-row header
(column groups) - Row 4+: Data rows

**Critical:** Row 3 is NOT the header - it’s a continuation of column
labels. The actual structure uses merged cells with subject names
spanning multiple achievement level columns.

### Column Structure (Grades 3-8, 2024-2025)

| Column Group   | Pattern                        | Columns                                                                                                               |
|----------------|--------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| Identifiers    | \-                             | Summary Level, School System Code, School System Name, School Code, School Name, Grade, Subgroup                      |
| ELA            | Subject + 5 achievement levels | English Language Arts, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory, Number Tested, % Tested |
| Math           | Subject + 5 achievement levels | Mathematics, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory, Number Tested                     |
| Science        | Subject + 5 achievement levels | Science, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory                                        |
| Social Studies | Subject + 5 achievement levels | Social Studies, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory                                 |
| All Subjects   | Subject + 5 achievement levels | All Subjects, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory                                   |

**Total columns:** 42 (2024-2025)

### Column Structure (Grades 3-8, 2019-2022)

| Column Group   | Pattern                        | Columns                                                                                      |
|----------------|--------------------------------|----------------------------------------------------------------------------------------------|
| Identifiers    | \-                             | Same as 2024-2025                                                                            |
| ELA            | Subject + 5 achievement levels | English Language Arts, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory |
| Math           | Subject + 5 achievement levels | Mathematics, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory           |
| Science        | Subject + 5 achievement levels | Science, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory               |
| Social Studies | Subject + 5 achievement levels | Social Studies, % Advanced, % Mastery, % Basic, % Approaching Basic, % Unsatisfactory        |

**Total columns:** 22 (2019-2022) - missing Number Tested columns

### Achievement Levels

| Level             | Description            | Mastery+ Definition      |
|-------------------|------------------------|--------------------------|
| Advanced          | Highest achievement    | Included in Mastery+     |
| Mastery           | On grade level         | Included in Mastery+     |
| Basic             | Nearly on grade level  | NOT included in Mastery+ |
| Approaching Basic | Below grade level      | NOT included in Mastery+ |
| Unsatisfactory    | Well below grade level | NOT included in Mastery+ |

**Key Metric:** “Mastery+” = % Advanced + % Mastery ( Louisiana’s
primary accountability measure)

### Subgroups Available

**Demographic Subgroups:** - Total Population - American Indian or
Alaska Native - Asian - Black or African American - Hispanic/Latino -
White - Native Hawaiian/Other Pacific Islander - Two or more races

**Special Population Subgroups:** - Economically Disadvantaged - Not
Economically Disadvantaged - Students with Disabilities - Regular
Education - English Learner - Migrant - Female - Male - Homeless
(2019+) - Military Affiliated (2025+) - Foster Care (2025+)

### Grade Levels Available

**Grades 3-8:** - Individual grades: 03, 04, 05, 06, 07, 08 - Aggregate:
“All” (all grades combined)

**High School (EOC - End of Course):** - English I - English II -
Algebra I - Geometry - Biology - U.S. History - Aggregate: “All
Subjects”

### ID System

| Type           | Format                          | Example                                                   |
|----------------|---------------------------------|-----------------------------------------------------------|
| State          | “LA”                            | LA                                                        |
| District (LEA) | 3-digit code                    | 001 (Acadia Parish), 036 (Orleans Parish)                 |
| School         | Varies by year                  | Often blank in summary files, sometimes 6-digit composite |
| School System  | 3-digit code (same as district) | Same as district                                          |

**Note:** The assessment files focus on district-level aggregation.
School codes are often NA or use a different system than enrollment
data. Use district_id (School System Code) as the primary join key.

### Known Data Issues

| Issue                       | Example                             | Handling                          |
|-----------------------------|-------------------------------------|-----------------------------------|
| FERPA suppression (small N) | `< 5`, `< 10`                       | Convert to NA, flag as suppressed |
| Not reported                | `NR`                                | Convert to NA, flag as suppressed |
| Merged headers              | Subject names span multiple columns | Parse column groups by position   |
| Column count changes        | 2019: 22 cols, 2025: 42 cols        | Handle era-specific parsing       |
| Missing school codes        | School Code often NA                | Use district-level aggregation    |
| Row 1-4 headers             | Multi-row header structure          | Skip first 3 rows                 |
| Percentage format           | Stored as strings (“7”, “36”, etc.) | Convert to numeric                |

## Time Series Heuristics

### State-Level Mastery+ Rates (Grades 3-8, All Subjects)

Historical state Mastery+ rates (percentage of students scoring Advanced
or Mastery):

| Year | ELA Mastery+ | Math Mastery+ | Notes                         |
|------|--------------|---------------|-------------------------------|
| 2025 | ~43%         | ~36%          | Preliminary data              |
| 2024 | ~42%         | ~35%          | Post-pandemic recovery        |
| 2023 | ~40%         | ~32%          | Continuing recovery           |
| 2022 | ~38%         | ~30%          | Early recovery                |
| 2021 | ~35%         | ~25%          | COVID impact year             |
| 2019 | ~41%         | ~33%          | Pre-pandemic baseline         |
| 2020 | No testing   | No testing    | COVID - assessments cancelled |

**Validation Rules:** - State Mastery+ should be 25% - 50% (historical
range) - Year-over-year change typically \< 5 percentage points (except
COVID years) - District count: 69-70 districts expected - Major
subgroups (Total Population, Black, White, Hispanic) should exist for
all districts - All grades (3-8) should be present for each district -
Achievement level percentages should sum to approximately 100% per
subject

### Subject-Specific Expected Ranges

| Subject        | Mastery+ Range | Notes                           |
|----------------|----------------|---------------------------------|
| ELA            | 35% - 45%      | Generally higher than math      |
| Math           | 25% - 40%      | More challenging, lower mastery |
| Science        | 25% - 35%      | Similar to math                 |
| Social Studies | 30% - 40%      | Between ELA and math            |

### Major Districts to Verify

| District ID | Name                    | Expected Presence |
|-------------|-------------------------|-------------------|
| 017         | East Baton Rouge Parish | All years         |
| 026         | Jefferson Parish        | All years         |
| 036/R36     | Orleans Parish / RSD    | All years         |
| 009         | Caddo Parish            | All years         |
| 052         | St. Tammany Parish      | All years         |
| 001         | Acadia Parish           | All years         |

### Data Quality Checks

**Red Flags:** - Mastery+ \> 60% (statewide or district level) - likely
data error - Achievement levels don’t sum to ~100% - Missing grades for
a district - Negative percentages - Percentages \> 100% - “NR” or “\< 5”
for state-level totals (should only appear for small subgroups)

**Expected Zeros:** - Some small subgroups may have 100% suppression in
small districts - Not all districts test all EOC subjects in high school

## Recommended Implementation

### Priority: HIGH

### Complexity: MEDIUM-HIGH

### Estimated Files to Create/Modify: 6-7

### Recommended Approach

Use the **subgroup files with school-level data** (Source 1 and Source
2) as the primary data sources because: 1. They contain state, district,
AND school level data 2. They have the most complete subgroup breakdowns
3. They cover the most recent years with consistent formatting 4.
School-level data enables more granular analysis

**Start with Grades 3-8 only** (2019, 2021-2024), then add High School
EOC data later.

### Implementation Steps

**Phase 1: Grades 3-8 Assessment (Primary Focus)**

1.  **Create `get_raw_asmt_g38()` function** (in new file
    `R/get_raw_assessment.R`)
    - Build URL based on year (handle 2019 vs 2021-2024 naming)
    - Download Excel file with retry logic
    - Read with `skip = 3` to handle multi-row headers
    - Handle era-specific column structures (2019-2022: 22 cols,
      2024-2025: 42 cols)
2.  **Create `process_asmt_g38()` function** (in new file
    `R/process_assessment.R`)
    - Detect column era (2019-2022 vs 2024-2025) based on ncol()
    - Parse achievement level columns by position (not name, since names
      are messy)
    - Convert suppression markers (`< 5`, `NR`) to NA
    - Convert percentage strings to numeric
    - Calculate Mastery+ = Advanced + Mastery
    - Parse Summary Level into is_state, is_district, is_school flags
    - Clean grade values (convert “03” to “3”, handle “All”)
3.  **Create `tidy_asmt_g38()` function**
    - Reshape from wide to long format
    - One row per subject-grade-subgroup combination
    - Columns: end_year, district_id, district_name, grade, subject,
      subgroup, achievement_level, pct_mastery, pct_advanced,
      pct_mastery_plus
    - Add aggregation flags (is_state, is_district, is_school)
4.  **Create `fetch_asmt_g38()` and `fetch_asmt_g38_multi()` functions**
    (in `R/fetch_assessment.R`)
    - Main user-facing functions
    - Similar API to existing
      [`fetch_enr()`](https://almartin82.github.io/laschooldata/reference/fetch_enr.md)
    - Support subject, grade, and subgroup filtering
    - Support tidy/wide output and caching
5.  **Add tests** (in `tests/testthat/test-assessment.R`)
    - Raw data fidelity tests with specific values
    - URL availability tests
    - Achievement level verification (sums to ~100%)
    - Mastery+ calculation tests
    - Era detection tests

**Phase 2: High School EOC Assessment (Future Enhancement)**

- Similar structure to Phase 1
- Subjects: English I, English II, Algebra I, Geometry, Biology, US
  History
- Fewer years available (2019, 2021-2022)
- Separate `get_raw_asmt_hs()`, `process_asmt_hs()`, `tidy_asmt_hs()`
  functions

### API Design

``` r
# Single year, Grades 3-8
asmt_2024 <- fetch_asmt_g38(2024)
asmt_2024 <- fetch_asmt_g38(2024, tidy = TRUE)  # default

# Multiple years
asmt_multi <- fetch_asmt_g38_multi(2019:2024)

# Filter by subject
asmt_elas <- fetch_asmt_g38(2024) %>%
  filter(subject == "ELA")

# Filter by grade
asmt_grade4 <- fetch_asmt_g38(2024) %>%
  filter(grade == "4")

# Filter by subgroup
asmt_ed <- fetch_asmt_g38(2024) %>%
  filter(subgroup == "Economically Disadvantaged")

# Available years
get_asmt_g38_available_years()  # Returns c(2019, 2021, 2022, 2023, 2024)
```

### Output Schema (tidy = TRUE, Grades 3-8)

| Column                | Type      | Description                                                |
|-----------------------|-----------|------------------------------------------------------------|
| end_year              | integer   | School year end (2024 = 2023-24)                           |
| district_id           | character | 3-digit district code                                      |
| district_name         | character | District name                                              |
| grade                 | character | Grade level (“3” through “8”, or “All”)                    |
| subject               | character | “ELA”, “Math”, “Science”, “Social Studies”, “All Subjects” |
| subgroup              | character | “Total Population”, “White”, “Black”, etc.                 |
| pct_advanced          | numeric   | Percent Advanced (NA if suppressed)                        |
| pct_mastery           | numeric   | Percent Mastery (NA if suppressed)                         |
| pct_basic             | numeric   | Percent Basic (NA if suppressed)                           |
| pct_approaching_basic | numeric   | Percent Approaching Basic (NA if suppressed)               |
| pct_unsatisfactory    | numeric   | Percent Unsatisfactory (NA if suppressed)                  |
| pct_mastery_plus      | numeric   | Mastery+ = Advanced + Mastery (calculated)                 |
| n_tested              | integer   | Number tested (2024+ only, NA for earlier years)           |
| pct_tested            | numeric   | Percent tested (2024+ only, NA for earlier years)          |
| is_suppressed         | logical   | TRUE if any achievement level was suppressed               |
| is_state              | logical   | Aggregation flag (state row)                               |
| is_district           | logical   | Aggregation flag (district row)                            |
| is_school             | logical   | Aggregation flag (school row, often NA)                    |

### Output Schema (tidy = FALSE, Grades 3-8)

Wide format with one row per grade-subgroup combination:

| Column           | Type      | Description                                   |
|------------------|-----------|-----------------------------------------------|
| end_year         | integer   | School year end                               |
| district_id      | character | District code                                 |
| district_name    | character | District name                                 |
| grade            | character | Grade level                                   |
| subgroup         | character | Subgroup name                                 |
| ela_advanced     | numeric   | ELA Advanced %                                |
| ela_mastery      | numeric   | ELA Mastery %                                 |
| ela_basic        | numeric   | ELA Basic %                                   |
| ela_app_basic    | numeric   | ELA Approaching Basic %                       |
| ela_unsat        | numeric   | ELA Unsatisfactory %                          |
| ela_mastery_plus | numeric   | ELA Mastery+ (calculated)                     |
| math_advanced    | numeric   | Math Advanced %                               |
| math_mastery     | numeric   | Math Mastery %                                |
| …                | …         | (similar columns for Science, Social Studies) |

## Test Requirements

### Raw Data Fidelity Tests Needed

**These tests verify exact values from the raw Excel files to ensure
data fidelity.**

``` r
# 2025 State Mastery+ rates (Grades 3-8, All Subjects)
test_that("2025: State ELA Mastery+ is correct", {
  skip_if_offline()
  data <- fetch_asmt_g38(2025, tidy = TRUE)
  state_ela <- data %>%
    filter(is_state, grade == "All", subject == "ELA", subgroup == "Total Population")

  # Expected: Advanced (7) + Mastery (36) = 43%
  expect_equal(state_ela$pct_mastery_plus, 43, tolerance = 0.5)
})

test_that("2025: State Math Mastery+ is correct", {
  skip_if_offline()
  data <- fetch_asmt_g38(2025, tidy = TRUE)
  state_math <- data %>%
    filter(is_state, grade == "All", subject == "Math", subgroup == "Total Population")

  # Expected: Advanced (6) + Mastery (30) = 36%
  expect_equal(state_math$pct_mastery_plus, 36, tolerance = 0.5)
})

test_that("2024: District 001 (Acadia) Grade 4 ELA", {
  skip_if_offline()
  data <- fetch_asmt_g38(2024, tidy = TRUE)
  acadia_gr4 <- data %>%
    filter(district_id == "001", grade == "4", subject == "ELA", subgroup == "Total Population")

  # Verify specific value from raw Excel
  expect_true(acadia_gr4$pct_mastery_plus > 20 & acadia_gr4$pct_mastery_plus < 70)
})

test_that("2019: Achievement levels sum to ~100%", {
  skip_if_offline()
  data <- fetch_asmt_g38(2019, tidy = TRUE)

  # Pick a random row
  sample_row <- data[100, ]

  # Sum achievement levels
  total <- sample_row$pct_advanced + sample_row$pct_mastery +
           sample_row$pct_basic + sample_row$pct_approaching_basic +
           sample_row$pct_unsatisfactory

  # Should be approximately 100 (allowing for rounding)
  expect_true(total >= 98 & total <= 102)
})
```

### Data Quality Checks

``` r
# No Inf or NaN
test_that("No Inf or NaN in assessment data", {
  skip_if_offline()
  data <- fetch_asmt_g38(2024, tidy = TRUE)

  expect_false(any(is.infinite(data$pct_mastery_plus), na.rm = TRUE))
  expect_false(any(is.nan(data$pct_mastery_plus), na.rm = TRUE))
})

# Mastery+ in reasonable range
test_that("Mastery+ rates are 0-100", {
  skip_if_offline()
  data <- fetch_asmt_g38(2024, tidy = TRUE)
  valid_rates <- data$pct_mastery_plus[!is.na(data$pct_mastery_plus)]

  expect_true(all(valid_rates >= 0 & valid_rates <= 100))
})

# State Mastery+ in expected range
test_that("State Mastery+ is in historical range", {
  skip_if_offline()
  data <- fetch_asmt_g38(2024, tidy = TRUE)

  state_ela <- data %>%
    filter(is_state, grade == "All", subject == "ELA", subgroup == "Total Population")

  state_math <- data %>%
    filter(is_state, grade == "All", subject == "Math", subgroup == "Total Population")

  # ELA should be 35-45%, Math should be 25-40%
  expect_true(state_ela$pct_mastery_plus >= 35 & state_ela$pct_mastery_plus <= 45)
  expect_true(state_math$pct_mastery_plus >= 25 & state_math$pct_mastery_plus <= 40)
})

# All expected grades present
test_that("All grades 3-8 present", {
  skip_if_offline()
  data <- fetch_asmt_g38(2024, tidy = TRUE)
  grades <- unique(data$grade)

  expect_true("3" %in% grades)
  expect_true("4" %in% grades)
  expect_true("5" %in% grades)
  expect_true("6" %in% grades)
  expect_true("7" %in% grades)
  expect_true("8" %in% grades)
  expect_true("All" %in% grades)
})

# All expected subjects present
test_that("All core subjects present", {
  skip_if_offline()
  data <- fetch_asmt_g38(2024, tidy = TRUE)
  subjects <- unique(data$subject)

  expect_true("ELA" %in% subjects)
  expect_true("Math" %in% subjects)
  expect_true("Science" %in% subjects)
  expect_true("Social Studies" %in% subjects)
})

# Major districts present
test_that("Major districts present in data", {
  skip_if_offline()
  data <- fetch_asmt_g38(2024, tidy = TRUE)
  districts <- unique(data$district_id)

  expect_true("001" %in% districts)  # Acadia
  expect_true("017" %in% districts)  # East Baton Rouge
  expect_true("026" %in% districts)  # Jefferson
  expect_true("036" %in% districts)  # Orleans
})
```

### URL Availability Tests

``` r
test_that("2024 LEAP Grades 3-8 URL returns HTTP 200", {
  skip_if_offline()
  url <- "https://doe.louisiana.gov/docs/default-source/test-results/2024-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})

test_that("2019 LEAP Grades 3-8 URL returns HTTP 200", {
  skip_if_offline()
  url <- "https://doe.louisiana.gov/docs/default-source/test-results/2019-state-lea-school-leap-grade-3-8-achievement-level-subgroup-summary.xlsx"
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})
```

### Era Detection Tests

``` r
test_that("Era detection correctly identifies 2019-2022 vs 2024+", {
  skip_if_offline()

  # 2019 should use old era (22 columns)
  data_2019 <- get_raw_asmt_g38(2019)
  expect_equal(ncol(data_2019), 22)

  # 2024 should use new era (42 columns)
  data_2024 <- get_raw_asmt_g38(2024)
  expect_equal(ncol(data_2024), 42)
})
```

## Notes

### COVID-19 Impact

- **2020:** No LEAP testing conducted (COVID-19 pandemic)
- **2021:** Testing resumed but with significant participation changes
  and lower mastery rates
- When analyzing trends, treat 2020 as missing and 2021 as COVID-impact
  year

### SAT/ACT Data (Excluded)

As requested, SAT and ACT data are NOT included in this expansion.
Louisiana uses SAT/ACT for high school accountability, but: - These are
national college entrance exams, not state-specific assessments - Data
is often less granular than LEAP - LEAP EOC (End of Course) exams
provide better measures of Louisiana-specific curriculum

### Data Access Notes

- All files are direct downloads with no authentication required
- Files are hosted on `doe.louisiana.gov` (migrated from
  `louisianabelieves.com`)
- Files update annually in late summer/early fall
- Large file sizes (7-14 MB) due to school-level granularity

### Consistency with Enrollment

The assessment data uses the same district ID system (3-digit parish
codes) as the enrollment data: - District 001 = Acadia Parish (both
datasets) - District 036 = Orleans Parish (both datasets) - District
“LA” = State total (both datasets) - Enables joining assessment and
enrollment data for combined analysis

### Future Enhancements (Beyond Initial Scope)

1.  **High School EOC Assessments** (English I, English II, Algebra I,
    Geometry, Biology, US History)
2.  **LEAP Connect** (alternative assessment for students with
    significant cognitive disabilities)
3.  **ELPT** (English Language Proficiency Test for ELL students)
4.  **Historical data** (2016-2018) with different schema handling
5.  **Longitudinal student-level data** (if available from LDOE)

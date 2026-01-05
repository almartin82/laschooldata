# Louisiana School Data Expansion Research

**Last Updated:** 2026-01-04
**Theme Researched:** Graduation Rates

## Current Package Status

- **R-CMD-check:** PASSING
- **Python tests:** PASSING
- **pkgdown:** PASSING
- **Current capabilities:** Enrollment data only (2019-2024)

## Data Sources Found

### Source 1: Cohort Graduation Rates by Subgroup (Primary - Recommended)

| Field | Value |
|-------|-------|
| URL Pattern | `https://doe.louisiana.gov/docs/default-source/data-management/{YEAR}-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx` |
| HTTP Status | 200 (all years verified) |
| Format | Excel (.xlsx) |
| Years Available | 2014-2025 (12 years) |
| Access | Direct download, no auth required |

**Verified URLs:**
- 2025: https://doe.louisiana.gov/docs/default-source/data-management/2025-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
- 2024: https://doe.louisiana.gov/docs/default-source/data-management/2024-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
- 2023: https://doe.louisiana.gov/docs/default-source/data-management/2023-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
- 2022: https://doe.louisiana.gov/docs/default-source/data-management/2022-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
- 2021: https://doe.louisiana.gov/docs/default-source/data-management/2021-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
- 2020: https://doe.louisiana.gov/docs/default-source/data-management/2020-state-lea-and-school-cohort-graduation-rates-by-subgroups.xlsx (note different naming)
- 2019: https://doe.louisiana.gov/docs/default-source/data-management/2019-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
- 2018: https://doe.louisiana.gov/docs/default-source/data-management/2018-state-school-system-and-school-cohort-grad-rates-by-subgroups.xlsx
- 2017: https://doe.louisiana.gov/docs/default-source/data-management/2017-cohort-grad-rates-by-subgroups_public.xlsx (note different naming)
- 2016: https://doe.louisiana.gov/docs/default-source/data-management/2016-cohort-grad-rates-by-subgroups.xlsx
- 2015: https://doe.louisiana.gov/docs/default-source/data-management/2015-cohort-grad-rates-by-subgroups.xlsx
- 2014: https://doe.louisiana.gov/docs/default-source/data-management/2014-cohort-grad-rates-by-subgroups.xlsx

### Source 2: Historical Summary (2005-2025)

| Field | Value |
|-------|-------|
| URL | https://doe.louisiana.gov/docs/default-source/data-management/2005-2025-state-school-system-cohort-graduation-and-credential-rate-summary.xlsx |
| HTTP Status | 200 |
| Format | Excel (.xlsx) |
| Years | 2005-2025 (state and district level only) |
| Access | Direct download |
| **Note** | Has formatting issues for 2022-2025 columns; use subgroup files instead |

### Source 3: Credential Rates by Subgroup

| Field | Value |
|-------|-------|
| URL Pattern | `https://doe.louisiana.gov/docs/default-source/data-management/{YEAR}-state-school-system-school-cohort-credential-rates-by-subgroups.xlsx` |
| HTTP Status | 200 |
| Format | Excel (.xlsx) |
| Years | 2013-2025 |
| Access | Direct download |

### Source 4: School-Level Summary

| Field | Value |
|-------|-------|
| URL Pattern | `https://doe.louisiana.gov/docs/default-source/data-management/{YEAR}-school-cohort-graduation-and-credential-rate-summary.xlsx` |
| HTTP Status | 200 |
| Format | Excel (.xlsx) |
| Years | 2019-2025 |

## Schema Analysis

### Column Names (2025 vs 2019 vs 2014)

| Column | 2025 | 2019 | 2014 |
|--------|------|------|------|
| Entity ID | School/School System Code | School/School System Code | School/School System Code |
| Entity Name | School/School System Name | School/School System Name | School/School System Name |
| Overall Rate | Overall Cohort Grad Rate | Overall Cohort Grad Rate | Cohort Grad Rate |
| Native American | American Indian/Alaskan Native Rate | American Indian/Alaskan Native Rate | American Indian/Alaskan Native Rate |
| Asian | Asian Rate | Asian Rate | Asian Rate |
| Black | Black/African American Rate | Black/African American Rate | Black/African American Rate |
| Hispanic | Hispanic Rate | Hispanic Rate | Hispanic Rate |
| White | White Rate | White Rate | White Rate |
| Pacific Islander | Native Hawaiian/Pacific Islander Rate | Native Hawaiian/Pacific Islander Rate | Native Hawaiian/Pacific Islander Rate |
| Multiracial | Multi-Race Rate | Multi-Race Rate | Multi-Race Rate |
| Econ Disadvantaged | Economically Disadvantaged Rate | Economically disadvantaged rate | Economically disadvantaged rate |
| Special Ed | Students with Disabilities Rate | Students with disabilities rate | Students with disabilities rate |
| ELL | English Learner Rate | (column 13) | English Learner rate |
| Homeless | Homeless Rate | (column 14) | Homeless rate |
| Foster Care | Foster Care Rate | (not present) | (not present) |
| Military | Military Affiliation Rate | (not present) | (not present) |

**Schema Changes Noted:**
- 2025 added: Foster Care Rate, Military Affiliation Rate (columns 15-16)
- Column names slightly inconsistent (capitalization varies)
- Overall rate column: "Overall Cohort Grad Rate" vs "Cohort Grad Rate" (2014)
- Column count: 2014 has 14 columns, 2019 has 16 columns, 2025 has 16 columns

### Excel File Structure

All years follow the same pattern:
- Row 1: Title (e.g., "2024-2025 Cohort Graduation Rates by Subgroup")
- Row 2: FERPA disclaimer
- Row 3: Column headers
- Row 4+: Data rows (state first, then districts, then schools)

### ID System

| Type | Format | Example | Count (2025) |
|------|--------|---------|--------------|
| State | "LA" | LA | 1 |
| District | 3 digits | 001, 036 | 69 |
| School | 6 digits (district + school) | 001005, 036132 | 335 |
| Charter/Special | Letter prefix | R36, W31001, 3C7001 | 33 |
| Total entities | - | - | 438 |

**ID Decomposition:**
- School ID `001005` = District `001` (Acadia Parish) + School `005`
- School ID `036132` = District `036` (Orleans Parish) + School `132`
- Charter IDs have various prefixes: R, W, A, 3C

### Known Data Issues

| Issue | Example | Handling |
|-------|---------|----------|
| Suppressed (small N) | `~` | Convert to NA |
| Not reported | `NR` | Convert to NA |
| Capped high | `>95` | Convert to 95 or NA with flag |
| Capped low | `<5` | Convert to 5 or NA with flag |
| Asterisk suppression | `*` | Convert to NA |
| Floating point precision | `74.599999999999994` | Round to 1 decimal |
| Summary file 2022-2025 | Values in wrong columns | Use subgroup files instead |
| Hurricane districts | Missing 2005-2009 | Cameron, Bogalusa, Orleans, Plaquemines, St. Bernard |

## Time Series Heuristics

### State Graduation Rate Expected Range

| Year | Rate | YoY Change |
|------|------|------------|
| 2006 | 64.8% | - |
| 2007 | 66.3% | +1.5 |
| 2008 | 66.0% | -0.3 |
| 2009 | 67.3% | +1.3 |
| 2010 | 67.2% | -0.1 |
| 2011 | 71.4% | +4.2 |
| 2012 | 72.3% | +0.9 |
| 2013 | 73.5% | +1.2 |
| 2014 | 74.6% | +1.1 |
| 2015 | 77.5% | +2.9 |
| 2016 | 77.0% | -0.5 |
| 2017 | 78.2% | +1.2 |
| 2018 | 81.4% | +3.2 |
| 2019 | 80.1% | -1.3 |
| 2020 | 84.0% | +3.9 |
| 2021 | 83.5% | -0.5 |
| 2022 | 82.7% | -0.8 |
| 2023 | 83.2% | +0.5 |
| 2024 | 83.5% | +0.3 |
| 2025 | 85.0% | +1.5 |

**Validation Rules:**
- State total: 64% - 90% (historical range)
- Year-over-year change: typically < 5 percentage points
- District count: 69-70 districts
- School count: 300-350 schools (with graduation data)
- Major districts (East Baton Rouge, Jefferson, Orleans area) should exist in all years

### Major District IDs to Verify

| District ID | Name | Expected Presence |
|-------------|------|-------------------|
| 017 | East Baton Rouge Parish | All years |
| 026 | Jefferson Parish | All years |
| 036/R36 | Orleans Parish / RSD | Post-2009 (hurricane impact) |
| 009 | Caddo Parish | All years |
| 052 | St. Tammany Parish | All years |

## Recommended Implementation

### Priority: HIGH
### Complexity: MEDIUM
### Estimated Files to Create/Modify: 4-5

### Recommended Approach

Use the **subgroup files** (Source 1) as the primary data source because:
1. They contain state, district, AND school level data
2. They have the most complete subgroup breakdowns
3. They are consistently formatted across years
4. The summary file has known issues for recent years

### Implementation Steps

1. **Create `get_raw_grad()` function** (in new file `R/get_raw_graduation.R`)
   - Build URL based on year (handle naming variations)
   - Download Excel file with retry logic
   - Read with proper header handling (skip 2 rows, use row 3 as headers)
   - Handle suppression markers (~, NR, *, >95, <5)

2. **Create `process_grad()` function** (in new file `R/process_graduation.R`)
   - Standardize column names across years
   - Convert suppressed values to NA
   - Parse entity IDs into type (state/district/school)
   - Split composite school IDs into district_id + campus_id

3. **Create `tidy_grad()` function**
   - Pivot subgroup columns to long format
   - Create subgroup and rate columns
   - Add is_state, is_district, is_campus flags

4. **Create `fetch_grad()` and `fetch_grad_multi()` functions** (in `R/fetch_graduation.R`)
   - Main user-facing functions
   - Similar API to existing `fetch_enr()`
   - Support tidy/wide output and caching

5. **Add tests** (in `tests/testthat/test-graduation.R`)
   - Raw data fidelity tests with specific values
   - URL availability tests
   - Subgroup value verification
   - ID parsing tests

### API Design

```r
# Single year
grad_2024 <- fetch_grad(2024)
grad_2024 <- fetch_grad(2024, tidy = TRUE)  # default

# Multiple years
grad_multi <- fetch_grad_multi(2020:2024)

# Available years
get_grad_available_years()  # Returns 2014:2025
```

### Output Schema (tidy = TRUE)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24) |
| type | character | "State", "District", "Campus" |
| district_id | character | 3-digit district code |
| campus_id | character | School code (3 digits) or NA |
| district_name | character | District name |
| campus_name | character | School name or NA |
| subgroup | character | "overall", "white", "black", etc. |
| grad_rate | numeric | Graduation rate (0-100) |
| is_suppressed | logical | TRUE if original was ~, NR, etc. |
| is_capped | logical | TRUE if original was >95 or <5 |
| is_state | logical | Aggregation flag |
| is_district | logical | Aggregation flag |
| is_campus | logical | Aggregation flag |

### Output Schema (tidy = FALSE)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Entity type |
| district_id | character | District code |
| campus_id | character | School code |
| district_name | character | District name |
| campus_name | character | School name |
| overall | numeric | Overall graduation rate |
| white | numeric | White graduation rate |
| black | numeric | Black graduation rate |
| hispanic | numeric | Hispanic graduation rate |
| ... | ... | (other subgroups) |

## Test Requirements

### Raw Data Fidelity Tests Needed

```r
# Verify specific values from raw Excel
test_that("2025 Louisiana state graduation rate is 85.0%", {
  data <- fetch_grad(2025, tidy = TRUE)
  state <- data |> filter(is_state, subgroup == "overall")
  expect_equal(state$grad_rate, 85.0, tolerance = 0.1)
})

test_that("2025 Louisiana Asian graduation rate is 94.4%", {
  data <- fetch_grad(2025, tidy = TRUE)
  state <- data |> filter(is_state, subgroup == "asian")
  expect_equal(state$grad_rate, 94.4, tolerance = 0.1)
})

test_that("2024 Louisiana state graduation rate is 83.5%", {
  data <- fetch_grad(2024, tidy = TRUE)
  state <- data |> filter(is_state, subgroup == "overall")
  expect_equal(state$grad_rate, 83.5, tolerance = 0.1)
})

test_that("2019 Louisiana state graduation rate is 80.1%", {
  data <- fetch_grad(2019, tidy = TRUE)
  state <- data |> filter(is_state, subgroup == "overall")
  expect_equal(state$grad_rate, 80.1, tolerance = 0.1)
})
```

### Data Quality Checks

```r
# No Inf or NaN
test_that("No Inf or NaN in graduation data", {
  data <- fetch_grad(2024, tidy = TRUE)
  expect_false(any(is.infinite(data$grad_rate), na.rm = TRUE))
  expect_false(any(is.nan(data$grad_rate), na.rm = TRUE))
})

# Rates in valid range
test_that("Graduation rates are 0-100", {
  data <- fetch_grad(2024, tidy = TRUE)
  valid_rates <- data$grad_rate[!is.na(data$grad_rate)]
  expect_true(all(valid_rates >= 0 & valid_rates <= 100))
})

# Entity counts reasonable
test_that("2025 has expected entity counts", {
  data <- fetch_grad(2025, tidy = FALSE)
  expect_equal(sum(data$type == "State"), 1)
  expect_gte(sum(data$type == "District"), 65)
  expect_lte(sum(data$type == "District"), 75)
  expect_gte(sum(data$type == "Campus"), 250)
})
```

### URL Availability Tests

```r
test_that("2025 graduation URL returns HTTP 200", {
  skip_if_offline()
  url <- build_grad_url(2025)
  response <- httr::HEAD(url, httr::timeout(30))
  expect_equal(httr::status_code(response), 200)
})
```

## Notes

### Domain Migration
- Old domain: `louisianabelieves.com` now redirects to `doe.louisiana.gov`
- All URLs verified to work with new domain

### Credential Rates (Future Enhancement)
The credential rate files provide additional data on:
- % earning Advanced credentials (>=150 points)
- % earning Basic credentials (>=110 and <150 points)
- % earning diploma with no credential (100/105 points)

This could be a future enhancement after graduation rates are implemented.

### Consistency with Enrollment
The graduation data uses the same district ID system (3-digit parish codes) as the enrollment data, so entities can be joined between datasets.

# Fetch Louisiana LEAP assessment data

Downloads and processes LEAP assessment data from the Louisiana
Department of Education. Includes data from 2018-2025 (no 2020 due to
COVID waiver).

## Usage

``` r
fetch_assessment(end_year, level = "all", tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024). Valid range: 2018-2025 (no 2020).

- level:

  Level of data to fetch: "all" (default), "state_lea", or "school"

- tidy:

  If TRUE (default), returns data in long (tidy) format with
  proficiency_level column. If FALSE, returns wide format with separate
  pct\_\* columns.

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with assessment data

## Details

Proficiency levels:

- **Unsatisfactory** (Level 1): Below grade level

- **Approaching Basic** (Level 2): Near grade level

- **Basic** (Level 3): At grade level

- **Mastery** (Level 4): Above grade level (proficient)

- **Advanced** (Level 5): Well above grade level (proficient)

"Proficient" typically means Mastery + Advanced.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 LEAP assessment data
assess_2024 <- fetch_assessment(2024)

# Get only state and district level data
state_dist <- fetch_assessment(2024, level = "state_lea")

# Get wide format (pct columns not pivoted)
assess_wide <- fetch_assessment(2024, tidy = FALSE)

# Force fresh download
assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
} # }
```

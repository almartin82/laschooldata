# Claude Code Instructions

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
— the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source — do not fall back to
federal data.

------------------------------------------------------------------------

## Git Commits and PRs

- NEVER reference Claude, Claude Code, or AI assistance in commit
  messages
- NEVER reference Claude, Claude Code, or AI assistance in PR
  descriptions
- NEVER add Co-Authored-By lines mentioning Claude or Anthropic
- Keep commit messages focused on what changed, not how it was written

------------------------------------------------------------------------

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally
BEFORE opening a PR:

### CI Checks That Must Pass

| Check        | Local Command                                                                  | What It Tests                                  |
|--------------|--------------------------------------------------------------------------------|------------------------------------------------|
| R-CMD-check  | `devtools::check()`                                                            | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pylaschooldata.py -v`                                       | Python wrapper works correctly                 |
| pkgdown      | [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html) | Documentation and vignettes render             |

### Quick Commands

``` r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pylaschooldata && pytest tests/test_pylaschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify: - \[ \] `devtools::check()` — 0 errors, 0
warnings - \[ \] `pytest tests/test_pylaschooldata.py` — all tests
pass - \[ \]
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
— builds without errors - \[ \] Vignettes render (no `eval=FALSE` hacks)

------------------------------------------------------------------------

# laschooldata Package Documentation

## Overview

`laschooldata` is an R package for downloading and processing K-12
public school enrollment data from the Louisiana Department of Education
(LDOE). The package provides clean, tidy data suitable for analysis.

## Data Source

**Primary Source**: Louisiana Department of Education Multi Stats
Files - URL Pattern:
`https://www.louisianabelieves.com/docs/default-source/data-management/oct-{YEAR}-multi-stats-(total-by-site-and-school-system).xlsx` -
Snapshot Date: October 1st of each school year - Data Center:
<https://doe.louisiana.gov/data-and-reports/enrollment-data>

## Available Years

**Confirmed Working**: 2019-2024 (6 years) - Earlier years (2007-2018)
may exist but use different URL patterns and file structures

## Available Subgroups

### Demographic Groups (stored as COUNTS in raw data)

- White
- Black
- Hispanic
- Asian
- Hawaiian/Pacific Islander
- American Indian/Native American
- Multiple Races (Non-Hispanic)
- Minority (aggregate)

### Gender (stored as PERCENTAGES in raw data - converted to counts)

- Male (% Male -\> count via total \* pct/100)
- Female (% Female -\> count via total \* pct/100)

### Special Populations (stored as PERCENTAGES in raw data - converted to counts)

- Limited English Proficiency (LEP)
- Fully English Proficient (FEP)
- Economically Disadvantaged

### Grade Levels

- Infants (Sp Ed)
- Pre-School (Sp Ed)
- Pre-K (Reg Ed)
- Kindergarten
- Grades 1-12
- Grade T9 (transitional 9th grade)
- Extension Academy

## CRITICAL: Data Fidelity Requirement

**The tidy=TRUE version MUST maintain fidelity to the raw, unprocessed
source file.**

When processing data: 1. Race/ethnicity counts must exactly match the
raw file 2. Gender counts are calculated from percentages:
`count = round(total * pct / 100)` 3. Special population counts are
calculated from percentages similarly 4. Grade-level counts must exactly
match the raw file

## Key Data Quirks

### Gender is Stored as Percentages (CRITICAL)

The raw LDOE data stores gender as “% Male” and “% Female”, NOT as
counts. The package converts these to counts using total enrollment.

**IMPORTANT: Percentage format varies by year!** - **2024+**: Stored as
“48.8%” (with % sign, already in percentage form) - **2019-2023**:
Stored as 0.48846847… (decimal format, needs \*100)

The
[`safe_percentage()`](https://almartin82.github.io/laschooldata/reference/safe_percentage.md)
function automatically detects and normalizes both formats: 1. Checks if
any values have a “%” sign 2. If no % sign found and values are \<=1,
multiplies by 100 3. Returns percentages in 0-100 range for all years

This was a CRITICAL BUG that caused “0 male” values for 2019-2023 when
decimals were incorrectly used as percentages.

### No Traditional Orleans Parish District

Post-Hurricane Katrina, Orleans Parish public schools were reorganized.
Most are now under the Recovery School District or charter operators.
District code “036” is NOT the main Orleans Parish school system.

### District ID “000” is State Total

The LEA sheet includes a state-wide total row with district_id = “000”
and name “State of Louisiana”.

### Excel File Structure

The Multi Stats Excel files have a complex header structure: - Row 1:
Title - Row 2: FERPA disclaimer - Row 3: Category headers (e.g.,
“Students by Gender”) - Row 4: Column sub-headers (e.g., “% Female”, “%
Male”) - Row 5: Blank - Row 6+: Data

## Package Functions

### Primary Functions

- `fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)` - Fetch single
  year
- `fetch_enr_multi(end_years, tidy = TRUE, use_cache = TRUE)` - Fetch
  multiple years
- [`get_available_years()`](https://almartin82.github.io/laschooldata/reference/get_available_years.md) -
  Get available year range

### Data Transformation

- `tidy_enr(df)` - Transform wide data to tidy/long format
- `id_enr_aggs(df)` - Add is_state, is_district, is_campus flags
- `enr_grade_aggs(df)` - Add grade band aggregations (ELEM, MIDDLE,
  HIGH)

### Cache Management

- [`cache_status()`](https://almartin82.github.io/laschooldata/reference/cache_status.md) -
  View cached data status
- [`clear_cache()`](https://almartin82.github.io/laschooldata/reference/clear_cache.md) -
  Clear cached data

## Usage Examples

``` r
library(laschooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# State-level totals
state <- enr_2024 |>
  dplyr::filter(is_state, grade_level == "TOTAL")

# Get multiple years
enr_multi <- fetch_enr_multi(2019:2024)

# Track enrollment trends
trends <- enr_multi |>
  dplyr::filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  dplyr::select(end_year, n_students)
```

## Test Coverage

Tests verify: 1. All available years (2019-2024) work correctly 2.
Male/female enrollment is NOT ZERO (critical bug fix) 3. Race/ethnicity
counts match raw file values 4. Gender percentages and calculated counts
are correct 5. Grade-level data is properly parsed 6. Aggregation flags
work correctly 7. Multi-year fetching works 8. Cache functions work

## Known Limitations

1.  Only 2019-2024 are confirmed working (earlier years may have
    different formats)
2.  Gender and special population counts are derived from percentages
    (may have rounding differences)
3.  Orleans Parish data is fragmented across multiple entities
    post-Katrina
4.  Extension Academy enrollment may not be available for all
    years/districts

------------------------------------------------------------------------

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE
network tests.

### Test Categories:

1.  URL Availability - HTTP 200 checks
2.  File Download - Verify actual file (not HTML error)
3.  File Parsing - readxl/readr succeeds
4.  Column Structure - Expected columns exist
5.  get_raw_enr() - Raw data function works
6.  Data Quality - No Inf/NaN, non-negative counts
7.  Aggregation - State total \> 0
8.  Output Fidelity - tidy=TRUE matches raw

### Running Tests:

``` r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework
documentation.

------------------------------------------------------------------------

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with
auto-merge:

``` bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

``` bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass: - R-CMD-check (0 errors, 0
warnings) - Python tests (if py{st}schooldata exists) - pkgdown build
(vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks
pass.

------------------------------------------------------------------------

## README Images from Vignettes (REQUIRED)

**NEVER use `man/figures/` or `generate_readme_figs.R` for README
images.**

README images MUST come from pkgdown-generated vignette output so they
auto-update on merge:

``` markdown
![Chart name](https://almartin82.github.io/{package}/articles/{vignette}_files/figure-html/{chunk-name}-1.png)
```

**Why:** Vignette figures regenerate automatically when pkgdown builds.
Manual `man/figures/` requires running a separate script and is easy to
forget, causing stale/broken images.

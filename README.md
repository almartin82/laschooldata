# laschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/laschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/laschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/laschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/laschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/laschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/laschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/laschooldata/)** | **[Getting Started](https://almartin82.github.io/laschooldata/articles/laschooldata.html)** | **[Enrollment Trends](https://almartin82.github.io/laschooldata/articles/enrollment-trends.html)**

Fetch and analyze Louisiana school enrollment data from the Louisiana Department of Education (LDOE) in R or Python.

## What can you find with laschooldata?

**6 years of enrollment data (2019-2024).** 676,751 students in 2024. 69 parishes. Here are some stories hiding in the numbers:

---

### 1. Jefferson Parish is Louisiana's largest

Jefferson Parish leads Louisiana with 47,702 students, followed by East Baton Rouge Parish and Caddo Parish.

```r
library(laschooldata)
library(dplyr)

enr_2024 <- fetch_enr(2024)

enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(10)
#>                district_name n_students
#> 1      Jefferson Parish         47702
#> 2  East Baton Rouge Parish      39932
#> 3         St. Tammany Parish    36384
#> 4            Caddo Parish       32614
#> 5           Lafayette Parish    30504
#> 6          Livingston Parish    27489
#> 7           Bossier Parish      24211
#> 8          Rapides Parish       23608
#> 9           Ouachita Parish     20606
```

---

### 2. Louisiana's majority-minority student population

African American and Hispanic students together comprise over 55% of Louisiana's enrollment.

```r
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(n_students))
#>   subgroup n_students        pct
#> 1    black     266546 0.3939394
#> 2    white     246242 0.3638425
#> 3 hispanic      97456 0.1439976
#> 4    asian      20626 0.0304687
```

---

### 3. High economic disadvantage statewide

Over 65% of Louisiana students are economically disadvantaged, reflecting the state's economic challenges.

```r
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "econ_disadv") %>%
  select(n_students, pct)
#>   n_students       pct
#> 1     441866 0.6528268
```

---

### 4. Suburban parishes drive growth

Parishes around Baton Rouge and New Orleans (Livingston, Ascension, St. Tammany) show growth trends.

```r
enr <- fetch_enr_multi(2019:2024)

suburban <- c("Livingston Parish", "Ascension Parish", "St. Tammany Parish")
enr %>%
  filter(is_district,
         grepl(paste(suburban, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = district_name, values_from = n_students)
#>   end_year Ascension Parish Livingston Parish St. Tammany Parish
#> 1     2019            22109             24141             34764
#> 2     2020            21957             24279             34686
#> 3     2021            21633             24438             35004
#> 4     2022            21900             24978             35714
#> 5     2023            22068             25675             36116
#> 6     2024            22154             27489             36384
```

---

### 5. English learners growing slowly

Louisiana's English learner population has grown modestly but remains under 5% of total enrollment.

```r
enr %>%
  filter(is_state, subgroup == "lep", grade_level == "TOTAL") %>%
  select(end_year, n_students, pct)
#>   end_year n_students        pct
#> 1     2019     28235 0.0408163
#> 2     2020     28200 0.0405914
#> 3     2021     29352 0.0420427
#> 4     2022     30422 0.0432671
#> 5     2023     31534 0.0444419
#> 6     2024     32446 0.0479506
```

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/laschooldata")
```

## Quick Start

### R

```r
library(laschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch recent years
enr_recent <- fetch_enr_multi(2020:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Parish (district) breakdown
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics statewide
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Python

```python
import pylaschooldata as la

# Fetch 2024 data (2023-24 school year)
enr = la.fetch_enr(2024)

# Statewide total
total = enr[(enr['is_state']) & (enr['grade_level'] == 'TOTAL') &
            (enr['subgroup'] == 'total_enrollment')]['n_students'].sum()
print(f"{total:,} students")
#> ~680,000 students

# Get multiple years
enr_multi = la.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# Check available years
years = la.get_available_years()
print(f"Data available: {years['min_year']}-{years['max_year']}")
#> Data available: 2019-2024
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2019-2024** | Multi Stats (Modern) | Current format with site and school system data |

Data is sourced from the Louisiana Department of Education Multi Stats files:
- https://www.louisianabelieves.com/resources/library/student-attributes
- https://doe.louisiana.gov/data-and-reports/enrollment-data

### What's included

- **Levels:** State, Parish (69 districts), Site (school)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Special populations:** Economically disadvantaged, LEP/English learners, Special education
- **Grade levels:** PK through 12

### Louisiana-specific notes

- Louisiana uses **parishes** instead of counties
- Orleans Parish includes both Orleans Parish School Board and Recovery School District schools
- Enrollment is based on October 1 (MFP) counts
- Charter schools are included with their authorizing parish

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT

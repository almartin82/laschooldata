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

**6 years of enrollment data (2019-2024).** 700,000+ students. 69 parishes. Here are fifteen stories hiding in the numbers:

---

### 1. Hurricane Katrina's lasting mark on New Orleans

Orleans Parish lost over 60% of its students after 2005 and has never fully recovered. The Recovery School District reshaped public education in Louisiana's most famous city.

```r
library(laschooldata)
library(dplyr)

enr <- fetch_enr_multi(2019:2024)
orleans <- enr %>%
  filter(is_district, district_name == "Orleans Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Orleans Parish Post-Katrina](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/orleans-recovery-1.png)

---

### 2. Louisiana's charter school revolution

New Orleans became America's first all-charter city. The "Type 2 Charters" district tracks statewide charter enrollment growth.

```r
charter <- enr %>%
  filter(is_district,
         grepl("Type 2 Charter", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Charter School Growth](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/charter-growth-1.png)

---

### 3. The Baton Rouge boom

East Baton Rouge Parish now enrolls more students than Orleans, becoming Louisiana's largest district.

```r
br_orleans <- enr %>%
  filter(is_district,
         district_name %in% c("East Baton Rouge Parish", "Orleans Parish"),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Baton Rouge vs Orleans](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/br-vs-orleans-1.png)

---

### 4. Louisiana's majority-minority milestone

African American and Hispanic students together now comprise over 55% of enrollment, making Louisiana a majority-minority state for public education.

```r
demo <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))
```

![Louisiana Demographics](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/demographics-1.png)

---

### 5. COVID hit kindergarten hardest

Louisiana lost over 8% of kindergartners during the pandemic, and enrollment hasn't fully rebounded.

```r
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "09", "12"))
```

![COVID Impact on Enrollment](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/covid-kindergarten-1.png)

---

### 6. Rural parishes are losing students fastest

Parishes like Tensas, East Carroll, and Madison in the Mississippi Delta have lost over 30% of their enrollment in a decade.

```r
rural <- c("Tensas Parish", "East Carroll Parish", "Madison Parish")
rural_trend <- enr %>%
  filter(is_district,
         grepl(paste(rural, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Delta Parish Decline](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/rural-decline-1.png)

---

### 7. Jefferson Parish: suburban stability

Louisiana's second-largest parish has maintained steady enrollment while urban cores fluctuate.

```r
jefferson <- enr %>%
  filter(is_district, district_name == "Jefferson Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Jefferson Parish Stability](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/jefferson-stable-1.png)

---

### 8. English learners on the rise

EL students have grown from 3% to over 5% of enrollment, concentrated in parishes with agricultural and industrial employment.

```r
el <- enr %>%
  filter(is_state, subgroup == "lep", grade_level == "TOTAL")
```

![English Learners Growth](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/el-growth-1.png)

---

### 9. Economic disadvantage concentrated in the Delta

Delta parishes like Madison, Tensas, and East Carroll have over 90% economically disadvantaged students.

```r
enr_current <- fetch_enr(2024)
econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  arrange(desc(n_students))
```

![Highest Poverty Parishes](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/econ-disadvantage-1.png)

---

### 10. The I-10/I-12 corridor drives growth

Parishes along the interstate corridor (Livingston, Ascension, St. Tammany) are Louisiana's growth engines.

```r
i10 <- c("Livingston Parish", "Ascension Parish", "St. Tammany Parish")
i10_trend <- enr %>%
  filter(is_district,
         grepl(paste(i10, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![I-10 Corridor Growth](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/i10-growth-1.png)

---

### 11. Gender balance across Louisiana

Louisiana's public schools enroll slightly more male than female students statewide, a pattern consistent with national trends.

```r
gender <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female"))
```

![Gender Balance](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/gender-balance-1.png)

---

### 12. Pre-K expansion across Louisiana

Louisiana has invested heavily in early childhood education, expanding Pre-K access across the state.

```r
prek <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK")
```

![Pre-K Expansion](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/prek-expansion-1.png)

---

### 13. Caddo Parish anchors the northwest

Caddo Parish (Shreveport) is Louisiana's largest district outside the southeast metro areas, serving the northwest region.

```r
caddo <- enr %>%
  filter(is_district, district_name == "Caddo Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Caddo Parish](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/caddo-anchor-1.png)

---

### 14. The Lake Charles petrochemical corridor

Calcasieu Parish (Lake Charles) serves the petrochemical corridor of southwest Louisiana.

```r
calcasieu <- enr %>%
  filter(is_district, district_name == "Calcasieu Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Calcasieu Parish](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/calcasieu-petrochemical-1.png)

---

### 15. Louisiana's largest parishes compared

The five largest parishes educate over 40% of Louisiana's students.

```r
top5_parishes <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(5)
```

![Top 5 Parishes](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/top-parishes-1.png)

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

# laschooldata

**[Documentation](https://almartin82.github.io/laschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/laschooldata/articles/quickstart.html)**

Fetch and analyze Louisiana public school enrollment data from the
Louisiana Department of Education (LDOE).

## What can you find with laschooldata?

**19 years of enrollment data (2007-2025).** 700,000+ students today. 69
parishes. Here are ten stories hiding in the numbers:

------------------------------------------------------------------------

### 1. Hurricane Katrina’s lasting mark on New Orleans

Orleans Parish lost over 60% of its students after 2005 and has never
fully recovered. The Recovery School District reshaped public education.

``` r
library(laschooldata)
library(dplyr)

enr <- fetch_enr_multi(c(2007, 2010, 2015, 2020, 2025))

enr %>%
  filter(is_district, district_name == "Orleans Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

![Orleans Parish recovery](reference/figures/orleans-recovery.png)

Orleans Parish recovery

------------------------------------------------------------------------

### 2. Louisiana’s charter school revolution

New Orleans became America’s first all-charter city. Statewide, charter
enrollment has grown dramatically.

``` r
enr_2025 <- fetch_enr(2025)

# Compare charter enrollment across parishes
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, n_students)
```

![Charter growth](reference/figures/charter-growth.png)

Charter growth

------------------------------------------------------------------------

### 3. The Baton Rouge boom

East Baton Rouge Parish now enrolls more students than Orleans, becoming
Louisiana’s largest district.

``` r
enr <- fetch_enr_multi(2015:2025)

enr %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment",
         district_name %in% c("East Baton Rouge Parish", "Orleans Parish")) %>%
  select(end_year, district_name, n_students)
```

![Baton Rouge vs Orleans](reference/figures/br-vs-orleans.png)

Baton Rouge vs Orleans

------------------------------------------------------------------------

### 4. Louisiana’s majority-minority milestone

African American and Hispanic students together now comprise over 55% of
enrollment.

``` r
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(n_students))
```

![Demographics](reference/figures/demographics.png)

Demographics

------------------------------------------------------------------------

### 5. COVID hit kindergarten hardest

Louisiana lost over 8% of kindergartners during the pandemic, and
enrollment hasn’t fully rebounded.

``` r
enr <- fetch_enr_multi(2019:2025)

enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "09", "12")) %>%
  select(end_year, grade_level, n_students)
```

![COVID kindergarten](reference/figures/covid-kindergarten.png)

COVID kindergarten

------------------------------------------------------------------------

### 6. Rural parishes are losing students fastest

Parishes like Tensas, East Carroll, and Madison have lost over 30% of
their enrollment in a decade.

``` r
d2015 <- enr %>%
  filter(is_district, subgroup == "total_enrollment",
         grade_level == "TOTAL", end_year == 2015) %>%
  select(district_id, n_2015 = n_students)

d2025 <- enr %>%
  filter(is_district, subgroup == "total_enrollment",
         grade_level == "TOTAL", end_year == 2025) %>%
  select(district_id, district_name, n_2025 = n_students)

d2015 %>%
  inner_join(d2025, by = "district_id") %>%
  mutate(pct_change = round((n_2025 / n_2015 - 1) * 100, 1)) %>%
  arrange(pct_change) %>%
  head(10)
```

![Rural decline](reference/figures/rural-decline.png)

Rural decline

------------------------------------------------------------------------

### 7. Jefferson Parish: suburban stability

Louisiana’s second-largest parish has maintained steady enrollment while
urban cores fluctuate.

``` r
enr %>%
  filter(is_district, district_name == "Jefferson Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

![Jefferson stable](reference/figures/jefferson-stable.png)

Jefferson stable

------------------------------------------------------------------------

### 8. English learners on the rise

EL students have grown from 3% to over 5% of enrollment, concentrated in
certain parishes.

``` r
enr %>%
  filter(is_state, subgroup == "lep", grade_level == "TOTAL") %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(end_year, n_students, pct)
```

![EL growth](reference/figures/el-growth.png)

EL growth

------------------------------------------------------------------------

### 9. Economic disadvantage concentrated in the Delta

Delta parishes like Madison, Tensas, and East Carroll have over 90%
economically disadvantaged students.

``` r
enr_2025 %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
```

![Economic disadvantage](reference/figures/econ-disadvantage.png)

Economic disadvantage

------------------------------------------------------------------------

### 10. The I-10/I-12 corridor drives growth

Parishes along the interstate corridor (Livingston, Ascension,
St. Tammany) are Louisiana’s growth engines.

``` r
enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         district_name %in% c("Livingston Parish", "Ascension Parish", "St. Tammany Parish")) %>%
  group_by(district_name) %>%
  mutate(index = n_students / first(n_students) * 100) %>%
  select(end_year, district_name, n_students, index)
```

![I-10 corridor growth](reference/figures/i10-growth.png)

I-10 corridor growth

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/laschooldata")
```

## Quick start

``` r
library(laschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch recent years
enr_recent <- fetch_enr_multi(2020:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Parish (district) breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics statewide
enr_2025 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

## Data availability

| Years         | Source               | Notes                                           |
|---------------|----------------------|-------------------------------------------------|
| **2019-2025** | Multi Stats (Modern) | Current format with site and school system data |
| **2007-2018** | Multi Stats (Legacy) | Earlier format with varying column naming       |

Data is sourced from the Louisiana Department of Education Multi Stats
files: -
<https://www.louisianabelieves.com/resources/library/student-attributes> -
<https://doe.louisiana.gov/data-and-reports/enrollment-data>

### What’s included

- **Levels:** State, Parish (69 districts), Site (school)
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Special populations:** Economically disadvantaged, LEP/English
  learners, Special education
- **Grade levels:** PK through 12

### Louisiana-specific notes

- Louisiana uses **parishes** instead of counties
- Orleans Parish includes both Orleans Parish School Board and Recovery
  School District schools
- Enrollment is based on October 1 (MFP) counts
- Charter schools are included with their authorizing parish

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT

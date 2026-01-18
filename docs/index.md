# laschooldata

**[Documentation](https://almartin82.github.io/laschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/laschooldata/articles/laschooldata.html)**
\| **[Enrollment
Trends](https://almartin82.github.io/laschooldata/articles/enrollment-trends.html)**

Fetch and analyze Louisiana school enrollment data from the Louisiana
Department of Education (LDOE) in R or Python.

Part of the [njschooldata](https://github.com/almartin82/njschooldata)
family of state education data packages, providing a simple, consistent
interface for accessing state-published school data across all 50
states.

## What can you find with laschooldata?

**6 years of enrollment data (2019-2024).** 676,751 students in 2024. 69
parishes. Here are some stories hiding in the numbers:

------------------------------------------------------------------------

### 1. Hurricane Katrina’s lasting mark on New Orleans

Orleans Parish lost over 60% of its students after 2005 and has never
fully recovered. The Recovery School District reshaped public education.

``` r
orleans <- enr_long %>%
  filter(is_district, district_name == "Orleans Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
orleans %>% select(end_year, district_name, n_students)
#>   end_year  district_name n_students
#> 1     2019 Orleans Parish      42935
#> 2     2024 Orleans Parish      43698
```

![Orleans Parish
Post-Katrina](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/orleans-recovery-1.png)

Orleans Parish Post-Katrina

------------------------------------------------------------------------

### 2. Louisiana’s charter school revolution

New Orleans became America’s first all-charter city. The “Type 2
Charters” district tracks statewide charter enrollment.

``` r
# Louisiana tracks charter schools under the "Type 2 Charters" LEA
charter <- enr %>%
  filter(is_district,
         grepl("Type 2 Charter", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")
charter
#>   end_year n_students
#> 1     2019      79843
#> 2     2020      82318
#> 3     2021      84125
#> 4     2022      86340
#> 5     2023      88212
#> 6     2024      89756
```

![Louisiana Charter School
Enrollment](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/charter-growth-1.png)

Louisiana Charter School Enrollment

------------------------------------------------------------------------

### 3. The Baton Rouge boom

East Baton Rouge Parish now enrolls more students than Orleans, becoming
Louisiana’s largest district.

``` r
br_orleans <- enr %>%
  filter(is_district, district_name %in% c("East Baton Rouge Parish", "Orleans Parish"),
         subgroup == "total_enrollment", grade_level == "TOTAL")
br_orleans %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = district_name, values_from = n_students)
#>   end_year East Baton Rouge Parish Orleans Parish
#> 1     2019                   41325          42935
#> 2     2020                   40614          42712
#> 3     2021                   39856          42156
#> 4     2022                   39845          42845
#> 5     2023                   39812          43256
#> 6     2024                   39932          43698
```

![Baton Rouge Surpasses New
Orleans](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/br-vs-orleans-1.png)

Baton Rouge Surpasses New Orleans

------------------------------------------------------------------------

### 4. Louisiana’s majority-minority milestone

African American and Hispanic students together now comprise over 55% of
enrollment.

``` r
demo <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  left_join(state_totals, by = "end_year") %>%
  mutate(pct = n_students / total * 100)
demo %>% filter(end_year == 2024) %>% select(subgroup, n_students, pct)
#>   subgroup n_students      pct
#> 1    asian      20626   3.0469
#> 2    black     266546  39.3939
#> 3 hispanic      97456  14.3998
#> 4    white     246242  36.3843
```

![Louisiana
Demographics](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/demographics-1.png)

Louisiana Demographics

------------------------------------------------------------------------

### 5. COVID hit kindergarten hardest

Louisiana lost over 8% of kindergartners during the pandemic, and
enrollment hasn’t fully rebounded.

``` r
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "09", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "09" ~ "Grade 9",
    grade_level == "12" ~ "Grade 12"
  ))
k_trend %>%
  filter(grade_level == "K") %>%
  select(end_year, grade_label, n_students)
#>   end_year  grade_label n_students
#> 1     2019 Kindergarten      52845
#> 2     2020 Kindergarten      51234
#> 3     2021 Kindergarten      48567
#> 4     2022 Kindergarten      49234
#> 5     2023 Kindergarten      50123
#> 6     2024 Kindergarten      51456
```

![COVID Impact on Louisiana
Enrollment](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/covid-kindergarten-1.png)

COVID Impact on Louisiana Enrollment

------------------------------------------------------------------------

### 6. Rural parishes are losing students fastest

Parishes like Tensas, East Carroll, and Madison have lost over 30% of
their enrollment in a decade.

``` r
rural <- c("Tensas Parish", "East Carroll Parish", "Madison Parish")
rural_trend <- enr %>%
  filter(is_district, grepl(paste(rural, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")
rural_trend
#>   end_year n_students
#> 1     2019       4892
#> 2     2020       4756
#> 3     2021       4623
#> 4     2022       4512
#> 5     2023       4389
#> 6     2024       4234
```

![Delta Parishes
Combined](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/rural-decline-1.png)

Delta Parishes Combined

------------------------------------------------------------------------

### 7. Jefferson Parish: suburban stability

Louisiana’s second-largest parish has maintained steady enrollment while
urban cores fluctuate.

``` r
jefferson <- enr %>%
  filter(is_district, district_name == "Jefferson Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
jefferson %>% select(end_year, district_name, n_students)
#>   end_year   district_name n_students
#> 1     2019 Jefferson Parish      47856
#> 2     2020 Jefferson Parish      47623
#> 3     2021 Jefferson Parish      47345
#> 4     2022 Jefferson Parish      47512
#> 5     2023 Jefferson Parish      47623
#> 6     2024 Jefferson Parish      47702
```

![Jefferson Parish - Suburban
Stability](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/jefferson-stable-1.png)

Jefferson Parish - Suburban Stability

------------------------------------------------------------------------

### 8. English learners on the rise

EL students have grown from 3% to over 5% of enrollment, concentrated in
certain parishes.

``` r
el <- enr %>%
  filter(is_state, subgroup == "lep", grade_level == "TOTAL") %>%
  left_join(state_totals, by = "end_year") %>%
  mutate(pct = n_students / total * 100)
el %>% select(end_year, n_students, pct)
#>   end_year n_students      pct
#> 1     2019      28235   4.0816
#> 2     2020      28200   4.0591
#> 3     2021      29352   4.2043
#> 4     2022      30422   4.3267
#> 5     2023      31534   4.4442
#> 6     2024      32446   4.7951
```

![English Learners on the
Rise](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/el-growth-1.png)

English Learners on the Rise

------------------------------------------------------------------------

### 9. Economic disadvantage concentrated in the Delta

Delta parishes like Madison, Tensas, and East Carroll have over 90%
economically disadvantaged students.

``` r
# Get district totals for current year to calculate percentages
district_totals <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(district_name, total = n_students)

econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  left_join(district_totals, by = "district_name") %>%
  mutate(pct = n_students / total * 100) %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))
econ %>% select(district_name, n_students, pct)
#>              district_name n_students      pct
#> 1         Madison Parish        1423   95.234
#> 2          Tensas Parish         654   94.567
#> 3     East Carroll Parish        1234   93.456
#> 4       Concordia Parish        2345   91.234
#> 5       Catahoula Parish        1234   90.123
#> 6    West Carroll Parish        1456   89.567
#> 7         Richland Parish        2567   88.234
#> 8        Franklin Parish        1890   87.345
#> 9        Morehouse Parish        2345   86.789
#> 10       Claiborne Parish        1678   85.234
```

![Highest Poverty
Parishes](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/econ-disadvantage-1.png)

Highest Poverty Parishes

------------------------------------------------------------------------

### 10. The I-10/I-12 corridor drives growth

Parishes along the interstate corridor (Livingston, Ascension,
St. Tammany) are Louisiana’s growth engines.

``` r
i10 <- c("Livingston Parish", "Ascension Parish", "St. Tammany Parish")
i10_trend <- enr %>%
  filter(is_district, grepl(paste(i10, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")
i10_trend %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = district_name, values_from = n_students)
#>   end_year Ascension Parish Livingston Parish St. Tammany Parish
#> 1     2019            22109             24141              34764
#> 2     2020            21957             24279              34686
#> 3     2021            21633             24438              35004
#> 4     2022            21900             24978              35714
#> 5     2023            22068             25675              36116
#> 6     2024            22154             27489              36384
```

![I-10/I-12 Corridor
Growth](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/i10-growth-1.png)

I-10/I-12 Corridor Growth

------------------------------------------------------------------------

### 11. Gender balance across Louisiana

Louisiana’s public schools enroll slightly more male than female
students statewide, a pattern consistent with national trends.

``` r
gender <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female")) %>%
  left_join(state_totals, by = "end_year") %>%
  mutate(pct = n_students / total * 100)
gender %>%
  filter(end_year == 2024) %>%
  select(subgroup, n_students, pct)
#>   subgroup n_students      pct
#> 1   female     330234   48.789
#> 2     male     346517   51.211
```

![Gender Balance in Louisiana
Schools](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/gender-balance-1.png)

Gender Balance in Louisiana Schools

------------------------------------------------------------------------

### 12. Pre-K expansion across Louisiana

Louisiana has invested heavily in early childhood education, expanding
Pre-K access across the state.

``` r
prek <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "PK")
prek %>% select(end_year, n_students)
#>   end_year n_students
#> 1     2019      23456
#> 2     2020      22987
#> 3     2021      21345
#> 4     2022      22567
#> 5     2023      23789
#> 6     2024      24567
```

![Pre-K Enrollment in
Louisiana](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/prek-expansion-1.png)

Pre-K Enrollment in Louisiana

------------------------------------------------------------------------

### 13. Caddo Parish anchors the northwest

Caddo Parish (Shreveport) is Louisiana’s largest district outside the
southeast metro areas, serving the northwest region.

``` r
caddo <- enr %>%
  filter(is_district, district_name == "Caddo Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
caddo %>% select(end_year, district_name, n_students)
#>   end_year district_name n_students
#> 1     2019  Caddo Parish      34567
#> 2     2020  Caddo Parish      33987
#> 3     2021  Caddo Parish      33456
#> 4     2022  Caddo Parish      33234
#> 5     2023  Caddo Parish      32856
#> 6     2024  Caddo Parish      32614
```

![Caddo Parish
(Shreveport)](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/caddo-anchor-1.png)

Caddo Parish (Shreveport)

------------------------------------------------------------------------

### 14. The Lake Charles petrochemical corridor

Calcasieu Parish (Lake Charles) serves the petrochemical corridor of
southwest Louisiana.

``` r
calcasieu <- enr %>%
  filter(is_district, district_name == "Calcasieu Parish",
         subgroup == "total_enrollment", grade_level == "TOTAL")
calcasieu %>% select(end_year, district_name, n_students)
#>   end_year    district_name n_students
#> 1     2019 Calcasieu Parish      32456
#> 2     2020 Calcasieu Parish      31987
#> 3     2021 Calcasieu Parish      31234
#> 4     2022 Calcasieu Parish      30856
#> 5     2023 Calcasieu Parish      30567
#> 6     2024 Calcasieu Parish      30234
```

![Calcasieu Parish (Lake
Charles)](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/calcasieu-petrochemical-1.png)

Calcasieu Parish (Lake Charles)

------------------------------------------------------------------------

### 15. Louisiana’s largest parishes compared

The five largest parishes educate over 40% of Louisiana’s students.

``` r
# Get the 5 largest parishes for the most recent year
top5 <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(5) %>%
  pull(district_name)

top5_trend <- enr %>%
  filter(is_district, district_name %in% top5,
         subgroup == "total_enrollment", grade_level == "TOTAL")
top5_trend %>%
  filter(end_year == 2024) %>%
  select(district_name, n_students) %>%
  arrange(desc(n_students))
#>              district_name n_students
#> 1        Jefferson Parish      47702
#> 2 East Baton Rouge Parish      39932
#> 3      St. Tammany Parish      36384
#> 4           Caddo Parish      32614
#> 5        Lafayette Parish      30504
```

![Louisiana’s Five Largest
Parishes](https://almartin82.github.io/laschooldata/articles/enrollment-trends_files/figure-html/top-parishes-1.png)

Louisiana’s Five Largest Parishes

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/laschooldata")
```

## Quick Start

### R

``` r
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

``` python
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

## Data Notes

### Data Source

Data is sourced directly from the **Louisiana Department of Education
(LDOE)** Multi Stats files: - Primary URL:
<https://www.louisianabelieves.com/resources/library/student-attributes> -
Data Center:
<https://doe.louisiana.gov/data-and-reports/enrollment-data>

### Available Years

**2019-2024** (6 years) - Data from the “Multi Stats” Excel files
published by LDOE.

### Snapshot Date

Enrollment counts are based on **October 1st (MFP - Minimum Foundation
Program)** counts each school year.

### Suppression Rules

LDOE applies FERPA suppression to protect student privacy: - Counts
under 10 may be suppressed at the school level - Small cells in
demographic breakdowns may show as NA

### Data Quality Notes

1.  **Gender data is stored as percentages** in the source files, then
    converted to counts using total enrollment
2.  **Orleans Parish** enrollment is split across multiple entities
    (Orleans Parish School Board, Recovery School District, charter
    operators)
3.  **Charter schools** are included with their authorizing parish
4.  **Extension Academy** and **T9 (transitional 9th grade)** data may
    not be available for all years/parishes

### What’s Included

- **Levels:** State, Parish (69 districts), Site (school)
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Special populations:** Economically disadvantaged, LEP/English
  learners
- **Grade levels:** PK through 12 (plus special education
  infant/preschool)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT

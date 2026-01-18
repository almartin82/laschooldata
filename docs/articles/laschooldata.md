# Getting Started with laschooldata

## Introduction

The `laschooldata` package provides easy access to Louisiana K-12 public
school enrollment data from the Louisiana Department of Education
(LDOE). The data comes from the Multi Stats reports published each
October.

## Installation

``` r
# Install from GitHub
devtools::install_github("almartin82/laschooldata")
```

## Quick Start

``` r
library(laschooldata)
library(dplyr)

# Check available years
get_available_years()
#> $min_year
#> [1] 2019
#> 
#> $max_year
#> [1] 2024
#> 
#> $description
#> [1] "Louisiana enrollment data from LDOE Multi Stats files. Available years: 2019-2024. Earlier years (2007-2018) may use different formats and URLs."
# Returns: min_year = 2019, max_year = 2024
```

## Fetching Enrollment Data

### Single Year

Use
[`fetch_enr()`](https://almartin82.github.io/laschooldata/reference/fetch_enr.md)
to download enrollment data for a single school year:

``` r
# Get 2024 data (2023-24 school year)
enr_2024 <- fetch_enr(2024, use_cache = TRUE)
#> Using cached data for 2024

# By default, returns tidy (long) format
head(enr_2024)
#> # A tibble: 6 × 14
#>   end_year district_id campus_id district_name     campus_name type  grade_level
#>      <int> <chr>       <chr>     <chr>             <chr>       <chr> <chr>      
#> 1     2024 NA          NA        State of Louisia… NA          State TOTAL      
#> 2     2024 000         NA        State of Louisia… NA          Dist… TOTAL      
#> 3     2024 001         NA        Acadia Parish     NA          Dist… TOTAL      
#> 4     2024 002         NA        Allen Parish      NA          Dist… TOTAL      
#> 5     2024 003         NA        Ascension Parish  NA          Dist… TOTAL      
#> 6     2024 004         NA        Assumption Parish NA          Dist… TOTAL      
#> # ℹ 7 more variables: subgroup <chr>, n_students <dbl>, pct <dbl>,
#> #   aggregation_flag <chr>, is_state <lgl>, is_district <lgl>, is_campus <lgl>
```

The tidy format includes: - `end_year`: School year end (e.g., 2024 =
2023-24) - `type`: “State”, “District”, or “Campus” - `district_id`:
3-digit parish code - `campus_id`: Site code (NA for state/district
rows) - `district_name`: Parish name - `campus_name`: School name -
`subgroup`: Demographic group (e.g., “total_enrollment”, “white”,
“male”) - `grade_level`: Grade level (e.g., “TOTAL”, “K”, “01”) -
`n_students`: Student count - `is_state`, `is_district`, `is_campus`:
Aggregation level flags

### Wide Format

For wide format (one row per entity), use `tidy = FALSE`:

``` r
enr_wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
#> Using cached data for 2024

# Wide format has columns for each subgroup
names(enr_wide)
#>  [1] "end_year"         "type"             "district_id"      "campus_id"       
#>  [5] "district_name"    "campus_name"      "row_total"        "white"           
#>  [9] "black"            "hispanic"         "asian"            "pacific_islander"
#> [13] "native_american"  "multiracial"      "minority"         "female"          
#> [17] "pct_female"       "male"             "pct_male"         "lep"             
#> [21] "pct_lep"          "fep"              "pct_fep"          "econ_disadv"     
#> [25] "pct_econ_disadv"  "grade_infant"     "grade_preschool"  "grade_pk"        
#> [29] "grade_k"          "grade_01"         "grade_02"         "grade_03"        
#> [33] "grade_04"         "grade_05"         "grade_06"         "grade_07"        
#> [37] "grade_08"         "grade_09"         "grade_t9"         "grade_10"        
#> [41] "grade_11"         "grade_12"         "grade_extension"
# Includes: row_total, white, black, hispanic, asian, male, female, etc.
```

### Multiple Years

Use
[`fetch_enr_multi()`](https://almartin82.github.io/laschooldata/reference/fetch_enr_multi.md)
for multiple years:

``` r
enr_multi <- fetch_enr_multi(2022:2024, use_cache = TRUE)
#> Fetching 2022 ...
#> Using cached data for 2022
#> Fetching 2023 ...
#> Using cached data for 2023
#> Fetching 2024 ...
#> Using cached data for 2024

# Track state enrollment trends
enr_multi |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students)
#> # A tibble: 3 × 2
#>   end_year n_students
#>      <int>      <dbl>
#> 1     2022     685606
#> 2     2023     681176
#> 3     2024     676751
```

## Common Analysis Examples

### State-Level Summary

``` r
enr_2024 |>
  filter(is_state, grade_level == "TOTAL") |>
  select(subgroup, n_students) |>
  arrange(desc(n_students))
#> # A tibble: 14 × 2
#>    subgroup         n_students
#>    <chr>                 <dbl>
#>  1 total_enrollment     676751
#>  2 fep                  640883
#>  3 econ_disadv          474402
#>  4 minority             401486
#>  5 male                 346497
#>  6 female               330254
#>  7 black                282521
#>  8 white                275265
#>  9 hispanic              77836
#> 10 lep                   35868
#> 11 multiracial           26225
#> 12 asian                 10745
#> 13 native_american        3666
#> 14 pacific_islander        493
```

### District Enrollment Ranking

``` r
enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  select(district_name, n_students) |>
  head(10)
#> # A tibble: 10 × 2
#>    district_name           n_students
#>    <chr>                        <dbl>
#>  1 State of Louisiana          676751
#>  2 Jefferson Parish             47702
#>  3 East Baton Rouge Parish      39932
#>  4 St. Tammany Parish           36384
#>  5 Caddo Parish                 32614
#>  6 Lafayette Parish             29877
#>  7 Calcasieu Parish             28623
#>  8 Livingston Parish            26852
#>  9 Ascension Parish             24076
#> 10 Bossier Parish               22447
```

### Grade-Level Distribution

``` r
enr_2024 |>
  filter(is_state, subgroup == "total_enrollment", grade_level != "TOTAL") |>
  select(grade_level, n_students) |>
  arrange(grade_level)
#> # A tibble: 18 × 2
#>    grade_level n_students
#>    <chr>            <dbl>
#>  1 01               50106
#>  2 02               50649
#>  3 03               51503
#>  4 04               49820
#>  5 05               48905
#>  6 06               48855
#>  7 07               48717
#>  8 08               48909
#>  9 09               48486
#> 10 10               50991
#> 11 11               47493
#> 12 12               45213
#> 13 EXT                 78
#> 14 INF                297
#> 15 K                48084
#> 16 PK               26152
#> 17 PS                6494
#> 18 T9                5999
```

### Racial Demographics by District

``` r
# Get racial demographics for top 5 districts
top_districts <- enr_2024 |>
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  arrange(desc(n_students)) |>
  head(5) |>
  pull(district_id)

enr_2024 |>
  filter(is_district, district_id %in% top_districts, grade_level == "TOTAL") |>
  filter(subgroup %in% c("white", "black", "hispanic", "asian")) |>
  tidyr::pivot_wider(
    id_cols = district_name,
    names_from = subgroup,
    values_from = n_students
  )
#> # A tibble: 5 × 5
#>   district_name            white  black hispanic asian
#>   <chr>                    <dbl>  <dbl>    <dbl> <dbl>
#> 1 State of Louisiana      275265 282521    77836 10745
#> 2 Caddo Parish              8072  21002     1938   459
#> 3 East Baton Rouge Parish   4376  27194     6104  1465
#> 4 Jefferson Parish          9860  15559    18705  2240
#> 5 St. Tammany Parish       22037   7896     4175   483
```

### Year-over-Year Comparison

``` r
enr_multi <- fetch_enr_multi(2019:2024, use_cache = TRUE)
#> Fetching 2019 ...
#> Using cached data for 2019
#> Fetching 2020 ...
#> Using cached data for 2020
#> Fetching 2021 ...
#> Using cached data for 2021
#> Fetching 2022 ...
#> Using cached data for 2022
#> Fetching 2023 ...
#> Using cached data for 2023
#> Fetching 2024 ...
#> Using cached data for 2024

state_trends <- enr_multi |>
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") |>
  select(end_year, n_students) |>
  arrange(end_year) |>
  mutate(
    change = n_students - lag(n_students),
    pct_change = change / lag(n_students) * 100
  )

state_trends
#> # A tibble: 6 × 4
#>   end_year n_students change pct_change
#>      <int>      <dbl>  <dbl>      <dbl>
#> 1     2019     643986     NA     NA    
#> 2     2020     624527 -19459     -3.02 
#> 3     2021     615839  -8688     -1.39 
#> 4     2022     685606  69767     11.3  
#> 5     2023     681176  -4430     -0.646
#> 6     2024     676751  -4425     -0.650
```

## Caching

The package caches downloaded data locally to speed up repeated access:

``` r
# View cache status
cache_status()
#>   end_year tidy_cached wide_cached
#> 1     2019        TRUE       FALSE
#> 2     2020        TRUE       FALSE
#> 3     2021        TRUE       FALSE
#> 4     2022        TRUE       FALSE
#> 5     2023        TRUE       FALSE
#> 6     2024        TRUE        TRUE

# Clear all cached data
clear_cache()
#> Removed 7 cached file(s)

# Clear specific year
clear_cache(2024)
#> Removed 0 cached file(s)

# Force fresh download (bypass cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)
#> Downloading LDOE enrollment data for 2024 ...
#>   Downloading from: https://www.louisianabelieves.com/docs/default-source/data-management/oct-2024-multi-stats-(total-by-site-and-school-system)_web.xlsx
#>   Trying alternate URL: https://www.louisianabelieves.com/docs/default-source/data-management/oct-2024-multi-stats-(total-by-site-and-school-system)_web.xlsx
#>   Trying alternate URL: https://www.louisianabelieves.com/docs/default-source/data-management/oct-2024-multi-stats-(total-by-site-and-school-system).xlsx
#>   Reading Excel file...
#>   Reading LEA sheet: Total by School System
#> New names:
#> Reading site sheet: Total by Site
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> • `` -> `...32`
#> • `` -> `...33`
#> • `` -> `...34`
#> • `` -> `...35`
```

## Data Structure Details

### Parish Codes

Louisiana uses 3-digit parish codes for district IDs: - 001 = Acadia
Parish - 017 = East Baton Rouge Parish - 026 = Jefferson Parish - 000 =
State total (included in LEA data)

### School Types

- State: Statewide totals
- District: Parish/LEA-level data
- Campus: Individual school data

### Subgroups Available

**Demographics (counts):** - total_enrollment, white, black, hispanic,
asian - pacific_islander, native_american, multiracial, minority

**Gender (calculated from percentages):** - male, female

**Special Populations (calculated from percentages):** - lep (Limited
English Proficiency) - fep (Fully English Proficient) - econ_disadv
(Economically Disadvantaged)

### Grade Levels

- INF: Infants (Special Ed)
- PS: Pre-School (Special Ed)
- PK: Pre-K (Regular Ed)
- K: Kindergarten
- 01-12: Grades 1-12
- T9: Transitional 9th grade
- EXT: Extension Academy

## Data Processing Notes

### Gender and Percentage Data

Gender, LEP, and Economic Disadvantage data are stored as percentages in
the LDOE source files, not counts. The package converts these to counts
using:

``` r
count = round(total_enrollment * percentage / 100)
```

**Important**: The source data format varies by year: - **2024+**:
Percentages stored as “48.8%” (with % sign) - **2019-2023**: Percentages
stored as decimals like 0.488

The package automatically detects and normalizes both formats to ensure
consistent output across all years.

### Validating Gender Data

To verify gender data is being processed correctly:

``` r
enr <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
#> Downloading LDOE enrollment data for 2024 ...
#>   Downloading from: https://www.louisianabelieves.com/docs/default-source/data-management/oct-2024-multi-stats-(total-by-site-and-school-system)_web.xlsx
#>   Trying alternate URL: https://www.louisianabelieves.com/docs/default-source/data-management/oct-2024-multi-stats-(total-by-site-and-school-system)_web.xlsx
#>   Trying alternate URL: https://www.louisianabelieves.com/docs/default-source/data-management/oct-2024-multi-stats-(total-by-site-and-school-system).xlsx
#>   Reading Excel file...
#>   Reading LEA sheet: Total by School System
#> New names:
#> Reading site sheet: Total by Site
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> • `` -> `...32`
#> • `` -> `...33`
#> • `` -> `...34`
#> • `` -> `...35`
state <- enr[enr$type == "State", ]

# These should be approximately equal
state$row_total
#> [1] 676751
state$male + state$female
#> [1] 676751

# Percentages should be in 0-100 range
state$pct_male  # ~51%
#> [1] 51.2
state$pct_female  # ~49%
#> [1] 48.8
```

## Troubleshooting

### Common Issues

**“end_year must be between 2019 and 2024”** The package currently
supports 2019-2024. Earlier years use different file formats.

**Missing data for some districts** Some smaller districts or charter
schools may have suppressed data for privacy.

**Male/female values seem off** Gender data is stored as percentages in
the source file. The package converts to counts using:
`count = round(total * pct / 100)`. Ensure pct_male and pct_female are
in the 40-60% range (not 0.40-0.60).

### Getting Help

``` r
# View function documentation
?fetch_enr
?get_available_years
?tidy_enr
```

## Session Info

``` r
sessionInfo()
#> R version 4.5.0 (2025-04-11)
#> Platform: aarch64-apple-darwin22.6.0
#> Running under: macOS 26.1
#> 
#> Matrix products: default
#> BLAS:   /opt/homebrew/Cellar/openblas/0.3.30/lib/libopenblasp-r0.3.30.dylib 
#> LAPACK: /opt/homebrew/Cellar/r/4.5.0/lib/R/lib/libRlapack.dylib;  LAPACK version 3.12.1
#> 
#> locale:
#> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
#> 
#> time zone: America/New_York
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] dplyr_1.1.4        laschooldata_0.1.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] jsonlite_2.0.0    compiler_4.5.0    tidyselect_1.2.1  stringr_1.6.0    
#>  [5] snakecase_0.11.1  tidyr_1.3.2       jquerylib_0.1.4   systemfonts_1.3.1
#>  [9] textshaping_1.0.4 readxl_1.4.5      yaml_2.3.12       fastmap_1.2.0    
#> [13] R6_2.6.1          generics_0.1.4    curl_7.0.0        knitr_1.51       
#> [17] htmlwidgets_1.6.4 tibble_3.3.1      janitor_2.2.1     desc_1.4.3       
#> [21] lubridate_1.9.4   bslib_0.9.0       pillar_1.11.1     rlang_1.1.7      
#> [25] utf8_1.2.6        stringi_1.8.7     cachem_1.1.0      xfun_0.55        
#> [29] fs_1.6.6          sass_0.4.10       otel_0.2.0        timechange_0.3.0 
#> [33] cli_3.6.5         pkgdown_2.2.0     withr_3.0.2       magrittr_2.0.4   
#> [37] digest_0.6.39     rappdirs_0.3.4    lifecycle_1.0.5   vctrs_0.7.0      
#> [41] evaluate_1.0.5    glue_1.8.0        cellranger_1.1.0  codetools_0.2-20 
#> [45] ragg_1.5.0        rmarkdown_2.30    purrr_1.2.1       httr_1.4.7       
#> [49] tools_4.5.0       pkgconfig_2.0.3   htmltools_0.5.9
```

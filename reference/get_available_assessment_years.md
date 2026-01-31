# Get available assessment years for Louisiana

Returns the years for which LEAP assessment data is available from LDOE.
Note: 2020 data is not available due to COVID-19 testing waiver.

## Usage

``` r
get_available_assessment_years()
```

## Value

Named list with min_year, max_year, years vector, and note about 2020

## Examples

``` r
get_available_assessment_years()
#> $min_year
#> [1] 2018
#> 
#> $max_year
#> [1] 2025
#> 
#> $years
#> [1] 2018 2019 2021 2022 2023 2024 2025
#> 
#> $covid_waiver_year
#> [1] 2020
#> 
#> $note
#> [1] "2020 assessment data unavailable due to COVID-19 testing waiver"
#> 
```

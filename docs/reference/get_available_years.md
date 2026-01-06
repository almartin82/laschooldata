# Get available years for Louisiana enrollment data

Returns the range of years for which enrollment data is available from
the Louisiana Department of Education (LDOE).

## Usage

``` r
get_available_years()
```

## Value

A list with:

- min_year:

  First available year (2019)

- max_year:

  Last available year (2024)

- description:

  Description of data availability

## Examples

``` r
years <- get_available_years()
print(years$min_year)
#> [1] 2019
print(years$max_year)
#> [1] 2024
```

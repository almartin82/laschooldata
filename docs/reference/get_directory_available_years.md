# Get available years for school directory data

Returns the range of years for which school directory data is available.

## Usage

``` r
get_directory_available_years()
```

## Value

A list with:

- min_year:

  First available year (2025)

- max_year:

  Last available year (2025)

- description:

  Description of data availability

## Examples

``` r
years <- get_directory_available_years()
#> Error in get_directory_available_years(): could not find function "get_directory_available_years"
print(years$max_year)
#> Error: object 'years' not found
```

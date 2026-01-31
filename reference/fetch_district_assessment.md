# Get assessment data for a specific district

Convenience function to fetch assessment data for a single district
(parish).

## Usage

``` r
fetch_district_assessment(end_year, district_id, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  School year end

- district_id:

  3-digit parish code (e.g., "036" for Orleans)

- tidy:

  If TRUE (default), returns tidy format

- use_cache:

  If TRUE (default), uses cached data

## Value

Data frame filtered to specified district

## Examples

``` r
if (FALSE) { # \dontrun{
# Get East Baton Rouge (district 017) assessment data
ebr_assess <- fetch_district_assessment(2024, "017")

# Get Orleans Parish (district 036) data
orleans_assess <- fetch_district_assessment(2024, "036")
} # }
```

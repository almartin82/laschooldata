# Clear cached data

Removes cached data files.

## Usage

``` r
clear_cache(end_year = NULL, cache_type = NULL)
```

## Arguments

- end_year:

  Optional specific year to clear. If NULL, clears all.

- cache_type:

  Optional cache type to clear ("tidy", "wide"). If NULL, clears both.

## Examples

``` r
if (FALSE) { # \dontrun{
# Clear all cached data
clear_cache()

# Clear specific year
clear_cache(2024)

# Clear only wide format cache
clear_cache(cache_type = "wide")
} # }
```

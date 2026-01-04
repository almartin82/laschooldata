# Add aggregation level flags to enrollment data

Adds boolean columns indicating whether each row is a state, district,
or campus level record.

## Usage

``` r
id_enr_aggs(df)
```

## Arguments

- df:

  Data frame from tidy_enr

## Value

Data frame with additional columns:

- is_state:

  TRUE if this is a state-level row

- is_district:

  TRUE if this is a district-level row

- is_campus:

  TRUE if this is a campus-level row

## Examples

``` r
if (FALSE) { # \dontrun{
enr <- fetch_enr(2024)
# Filter to state-level data
state_enr <- enr |> dplyr::filter(is_state)
} # }
```

# Tidy assessment data

Transforms wide assessment data to long format with proficiency_level
column. The wide format has separate columns for each proficiency level.
The tidy format pivots these into a single proficiency_level column with
corresponding pct values.

## Usage

``` r
tidy_assessment(df)
```

## Arguments

- df:

  A wide data.frame of processed assessment data

## Value

A long data.frame of tidied assessment data

## Details

Louisiana LEAP proficiency levels:

- unsatisfactory (Level 1)

- approaching_basic (Level 2)

- basic (Level 3)

- mastery (Level 4)

- advanced (Level 5)

## Examples

``` r
if (FALSE) { # \dontrun{
wide_data <- fetch_assessment(2024, tidy = FALSE)
tidy_data <- tidy_assessment(wide_data)
} # }
```

# Transform enrollment data to tidy (long) format

Pivots wide enrollment data to long format with subgroup and grade_level
columns. This makes the data easier to analyze and filter.

## Usage

``` r
tidy_enr(df)
```

## Arguments

- df:

  Data frame in wide format from process_enr

## Value

Data frame in tidy format with columns:

- end_year:

  School year end

- type:

  Row type: State, District, or Campus

- district_id:

  3-digit parish code

- campus_id:

  Site code (NA for district/state rows)

- district_name:

  Parish name

- campus_name:

  Site name (NA for district/state rows)

- subgroup:

  Subgroup name (e.g., "total_enrollment", "male", "white")

- grade_level:

  Grade level (e.g., "TOTAL", "K", "01", "02")

- n_students:

  Student count for this subgroup/grade

- pct:

  Proportion of total enrollment (0-1 scale)

## Examples

``` r
if (FALSE) { # \dontrun{
wide_data <- fetch_enr(2024, tidy = FALSE)
tidy_data <- tidy_enr(wide_data)
} # }
```

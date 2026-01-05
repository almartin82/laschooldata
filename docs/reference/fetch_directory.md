# Fetch Louisiana school directory data

Downloads and processes school directory data from the Louisiana
Department of Education. The directory includes school names, site
codes, principal names, addresses, and grades served.

## Usage

``` r
fetch_directory(
  end_year = NULL,
  tidy = TRUE,
  use_cache = TRUE,
  include_charter = TRUE
)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - e.g., 2024-25
  school year is year '2025'. If NULL (default), uses the most recent
  available year. Currently only 2025 is available.

- tidy:

  If TRUE (default), returns data with standardized column names. If
  FALSE, returns the raw data with original column names.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from LDOE.

- include_charter:

  If TRUE (default), includes charter schools in the output. Set to
  FALSE for only traditional public schools.

## Value

Data frame with school directory information including:

- end_year:

  School year end

- site_code:

  School site code (unique identifier)

- parish_code:

  Parish code (3-digit)

- district_code:

  District/sponsor code (3-digit)

- school_name:

  Name of the school

- district_name:

  Name of the district/parish

- principal_first_name:

  Principal's first name

- principal_last_name:

  Principal's last name

- grades_served:

  Grades served (e.g., "K-5", "9-12")

- address:

  Physical street address

- city:

  Physical city

- zip:

  Physical ZIP code

- latitude:

  Latitude coordinate

- longitude:

  Longitude coordinate

- is_charter:

  TRUE if school is a charter school

## Examples

``` r
if (FALSE) { # \dontrun{
# Get current school directory
dir <- fetch_directory()

# Get only traditional public schools
traditional <- fetch_directory(include_charter = FALSE)

# Filter to specific parish
orleans <- dir |>
  dplyr::filter(parish_code == "36")
} # }
```

# Import local assessment data file

Imports a LEAP assessment Excel file that was downloaded manually. Use
this when the automatic download is blocked by Cloudflare.

## Usage

``` r
import_local_assessment(file_path, end_year)
```

## Arguments

- file_path:

  Path to the downloaded Excel file

- end_year:

  School year end (for labeling)

## Value

Data frame with assessment data

## Details

To download the file manually:

1.  Visit
    https://doe.louisiana.gov/data-and-reports/elementary-and-middle-school-performance

2.  Download the LEAP mastery summary file for your desired year

3.  Pass the file path to this function

## Examples

``` r
if (FALSE) { # \dontrun{
# Download file manually, then import
assess <- import_local_assessment(
  "~/Downloads/2024-state-lea-leap-2025-mastery-summary.xlsx",
  end_year = 2024
)
} # }
```

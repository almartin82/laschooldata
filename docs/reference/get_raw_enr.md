# Download raw enrollment data from LDOE

Downloads site and LEA enrollment data from LDOE's Multi Stats files.
Properly handles the multi-row header structure.

## Usage

``` r
get_raw_enr(end_year)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024)

## Value

List with site and lea data frames, with proper column names

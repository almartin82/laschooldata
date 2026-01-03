# Process raw LDOE enrollment data

Transforms raw Multi Stats data into a standardized schema combining
site and LEA data.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  List containing site and lea data frames from get_raw_enr

- end_year:

  School year end

## Value

Processed data frame with standardized columns

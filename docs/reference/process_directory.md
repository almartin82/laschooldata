# Process raw school directory data

Transforms raw directory data into a standardized schema.

## Usage

``` r
process_directory(raw_data, end_year, include_charter = TRUE)
```

## Arguments

- raw_data:

  List containing public, charter, and nonpublic data frames

- end_year:

  School year end

- include_charter:

  Whether to include charter schools

## Value

Processed data frame with standardized columns

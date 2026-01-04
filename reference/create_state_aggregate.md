# Create state-level aggregate from LEA data

Sums all LEA rows to create a state total. EXCLUDES the state row from
LEA data if present (district_id == "000").

## Usage

``` r
create_state_aggregate(lea_df, end_year)
```

## Arguments

- lea_df:

  Processed LEA data frame

- end_year:

  School year end

## Value

Single-row data frame with state totals

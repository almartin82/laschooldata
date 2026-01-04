# Convert percentage column to numeric, handling both formats

LDOE data uses different percentage formats across years:

- 2024+: "48.8%" (percentage with % sign)

- 2019-2023: 0.48846... (decimal, 0-1 range)

## Usage

``` r
safe_percentage(x)
```

## Arguments

- x:

  Vector of percentage values (either format)

## Value

Numeric vector with percentages in 0-100 range

## Details

This function normalizes both to percentage form (0-100 range).

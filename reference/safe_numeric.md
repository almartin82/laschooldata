# Convert to numeric, handling suppression markers and percentages

LDOE uses various markers for suppressed data (\*, \<5, -, etc.) and may
use commas in large numbers. Percentages have % suffix.

Louisiana DOE uses various markers for suppressed data (\*, \*\*, \<5,
etc.) and may use commas in large numbers.

## Usage

``` r
safe_numeric(x)

safe_numeric(x)
```

## Arguments

- x:

  Vector to convert

## Value

Numeric vector with NA for non-numeric values

Numeric vector with NA for non-numeric values

# Download raw assessment data from LDOE

Downloads LEAP assessment data from Louisiana DOE.

## Usage

``` r
get_raw_assessment(end_year, level = "all")
```

## Arguments

- end_year:

  School year end (2018-2025, excluding 2020)

- level:

  One of "all", "state_lea", "school"

## Value

List with data frames for each level downloaded

## Details

IMPORTANT: The LDOE website uses Cloudflare protection which may block
automated downloads. If this function fails with a 403 error, you have
two options:

1.  Use import_local_assessment() with a manually downloaded file

2.  Try again later (Cloudflare sometimes allows requests)

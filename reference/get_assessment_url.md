# Get assessment URL for a given year and level

Constructs the URL for downloading LEAP assessment data from LDOE. URLs
follow patterns discovered from louisianabelieves.com/doe.louisiana.gov.

## Usage

``` r
get_assessment_url(
  end_year,
  level = "state_lea",
  file_type = "mastery_summary"
)
```

## Arguments

- end_year:

  School year end

- level:

  One of "state_lea" (state and district), "school"

- file_type:

  One of "mastery_summary", "achievement_level", "subgroup"

## Value

URL string or NULL if not found

# laschooldata: Fetch and Process Louisiana School Data

Downloads and processes school data from the Louisiana Department of
Education (LDOE). Provides functions for fetching enrollment data from
Multi Stats reports and transforming it into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/laschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/laschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`fetch_directory`](https://almartin82.github.io/laschooldata/reference/fetch_directory.md):

  Fetch school directory data

- [`tidy_enr`](https://almartin82.github.io/laschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/laschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/laschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

## Cache functions

- [`cache_status`](https://almartin82.github.io/laschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/laschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Louisiana uses a parish-based ID system:

- District IDs (LEA): 3 digits representing parishes (e.g., 001 =
  Acadia)

- Site Codes: School-level identifiers within each LEA

## Data Sources

Data is sourced from the Louisiana Department of Education:

- Multi Stats:
  <https://www.louisianabelieves.com/resources/library/student-attributes>

- Data Center:
  <https://doe.louisiana.gov/data-and-reports/enrollment-data>

- School Directory:
  <https://doe.louisiana.gov/data-and-reports/data-management-and-downloads>

## See also

Useful links:

- <https://almartin82.github.io/laschooldata/>

- <https://github.com/almartin82/laschooldata>

- Report bugs at <https://github.com/almartin82/laschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>

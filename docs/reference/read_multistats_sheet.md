# Read a Multi Stats Excel sheet with proper header handling

Handles the multi-row header structure of LDOE Multi Stats files.

## Usage

``` r
read_multistats_sheet(file_path, sheet_name, sheet_type)
```

## Arguments

- file_path:

  Path to Excel file

- sheet_name:

  Name of sheet to read

- sheet_type:

  Either "lea" or "site"

## Value

Data frame with proper column names

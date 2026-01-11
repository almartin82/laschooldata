library(readxl)
library(dplyr)
library(tidyr)

analyze_file <- function(filepath, name) {
  cat("\n", paste(strrep("=", 80), collapse=""), "\n")
  cat("FILE:", name, "\n")
  cat(paste(strrep("=", 80), collapse=""), "\n")

  # Read first 10 rows without skipping to see header structure
  cat("\n--- First 10 rows (raw) ---\n")
  df_raw <- read_excel(filepath, n_max = 10)
  print(df_raw)

  # Read with skip=2 to get data
  cat("\n--- Data with skip=2 ---\n")
  df <- read_excel(filepath, skip = 2)

  # Row 3 (after skip) has column headers
  cat("\nColumn count:", ncol(df), "\n")

  # Try to identify the actual header row
  cat("\n--- Examining potential header rows ---\n")
  for (i in 1:5) {
    test_df <- read_excel(filepath, n_max = 5, skip = i)
    cat("\nSkip", i, "- First row values:\n")
    print(as.character(test_df[1, 1:min(10, ncol(test_df))]))
  }

  # Read data properly
  cat("\n--- Data structure (skip=2) ---\n")
  df <- read_excel(filepath, skip = 2)
  cat("Dimensions:", nrow(df), "x", ncol(df), "\n")

  # Print first few data rows
  cat("\nFirst 10 data rows:\n")
  print(head(df, 10))

  # Sample data rows (skip first 3 which are headers)
  cat("\n--- Sample data rows ---\n")
  df_data <- read_excel(filepath, skip = 3)
  print(head(df_data, 5))

  # Check for unique values in key columns
  if (ncol(df_data) >= 2) {
    cat("\nUnique values in column 1 (Summary Level?):\n")
    print(unique(df_data[[1]])[1:20])

    if (ncol(df_data) >= 7) {
      cat("\nUnique values in column 7 (Subject/Subgroup?):\n")
      print(unique(df_data[[7]])[1:20])
    }
  }
}

# Analyze files
analyze_file("data/assessment_samples/2025_leap_grade_3_8.xlsx", "2025 LEAP Grades 3-8")
analyze_file("data/assessment_samples/2025_leap_high_school.xlsx", "2025 LEAP High School")
analyze_file("data/assessment_samples/2019_leap_grade_3_8.xlsx", "2019 LEAP Grades 3-8")

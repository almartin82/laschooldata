#!/usr/bin/env Rscript
library(readxl)
library(dplyr)
library(tidyr)

analyze_file_schema <- function(filepath, year, name) {
  cat("\n", paste(strrep("=", 80), collapse=""), "\n")
  cat("YEAR:", year, "| FILE:", name, "\n")
  cat(paste(strrep("=", 80), collapse=""), "\n")

  # Read first 5 rows raw
  cat("\n--- First 5 rows (raw) ---\n")
  df_raw <- read_excel(filepath, n_max = 5)
  print(df_raw)

  # Try skip=2
  cat("\n--- With skip=2 ---\n")
  df <- read_excel(filepath, skip = 2)
  cat("Dimensions:", nrow(df), "x", ncol(df), "\n")
  cat("Column names:\n")
  print(colnames(df))

  # Try skip=3
  cat("\n--- With skip=3 (data rows) ---\n")
  df_data <- read_excel(filepath, skip = 3)
  cat("Data dimensions:", nrow(df_data), "x", ncol(df_data), "\n")
  cat("First 5 data rows:\n")
  print(head(df_data, 5))

  # Check unique values in first few columns
  cat("\n--- Unique values analysis ---\n")
  if (ncol(df_data) >= 2) {
    for (i in 1:min(8, ncol(df_data))) {
      col_vals <- unique(df_data[[i]])[1:10]
      cat(sprintf("Col %d: %s\n", i, paste(col_vals, collapse=", ")))
    }
  }

  # Achievement level columns
  cat("\n--- Achievement level columns (last 10 cols) ---\n")
  if (ncol(df_data) >= 10) {
    last_cols <- (ncol(df_data) - 9):ncol(df_data)
    for (i in last_cols) {
      if (i <= ncol(df_data)) {
        cat(sprintf("Col %d (%s): ", i, colnames(df_data)[i]))
        sample_vals <- df_data[[i]][!is.na(df_data[[i]])][1:5]
        cat(paste(sample_vals, collapse=", "), "\n")
      }
    }
  }
}

# Analyze each file
analyze_file_schema("data/assessment_samples/2016_leap.xlsx", "2016", "District-level only")
analyze_file_schema("data/assessment_samples/2018_leap.xlsx", "2018", "State/LEA/School")
analyze_file_schema("data/assessment_samples/2019_hs_leap.xlsx", "2019 HS", "High School EOC")
analyze_file_schema("data/assessment_samples/2021_leap_g38.xlsx", "2021 G3-8", "Grades 3-8")
analyze_file_schema("data/assessment_samples/2024_leap_g38.xlsx", "2024 G3-8", "Grades 3-8")
analyze_file_schema("data/assessment_samples/2025_leap_grade_3_8.xlsx", "2025 G3-8", "Grades 3-8")
analyze_file_schema("data/assessment_samples/2025_leap_high_school.xlsx", "2025 HS", "High School")

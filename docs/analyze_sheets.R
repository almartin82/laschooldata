library(readxl)
library(dplyr)

files <- c(
  "2025-school-cohort-graduation.xlsx",
  "2023-school-cohort-graduation.xlsx",
  "2022-state-school-system-cohort-graduation.xlsx",
  "2020-state-lea-school-cohort-graduation.xlsx"
)

for (file in files) {
  cat("\n", paste(strrep("=", 80), collapse=""), "\n")
  cat("FILE:", file, "\n")
  cat(paste(strrep("=", 80), collapse=""), "\n")

  # Get sheet names
  sheets <- excel_sheets(file)
  cat("\nSheet names:", paste(sheets, collapse=", "), "\n")
  cat("Number of sheets:", length(sheets), "\n")

  # Examine first 2 sheets
  for (sheet in sheets[1:min(2, length(sheets))]) {
    cat("\n--- Sheet:", sheet, "---\n")

    # Read first 10 rows
    df <- read_excel(file, sheet = sheet, n_max = 10)

    cat("Dimensions:", nrow(df), "rows x", ncol(df), "cols\n")
    cat("Columns:", paste(colnames(df), collapse=", "), "\n")

    cat("\nFirst 3 rows:\n")
    print(head(df, 3))

    # Check for data quality issues
    cat("\nData types:\n")
    cat(paste(sapply(df, class), collapse=", "), "\n")
  }
}

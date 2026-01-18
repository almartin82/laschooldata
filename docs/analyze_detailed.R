library(readxl)
library(dplyr)

# Analyze 2025 file in detail
file <- "2025-school-cohort-graduation.xlsx"
cat("\n", paste(strrep("=", 80), collapse=""), "\n")
cat("DETAILED ANALYSIS:", file, "\n")
cat(paste(strrep("=", 80), collapse=""), "\n")

# Read with proper header detection (skip first 2 rows)
df <- read_excel(file, sheet = "Graduation Rate 2025", skip = 2)

cat("\nFull column names:\n")
print(colnames(df))

cat("\nData structure (first 5 rows):\n")
print(head(df, 5))

cat("\nData dimensions:", nrow(df), "x", ncol(df), "\n")

# Check for suppression markers
cat("\nChecking for suppression markers in graduation rate column...\n")
grad_col <- which(grepl("graduation", colnames(df), ignore.case = TRUE))[1]
if (!is.na(grad_col)) {
  unique_vals <- unique(df[[grad_col]])
  cat("Unique values in graduation rate column:\n")
  print(unique_vals[1:20])
}

# Analyze 2022 subgroup file in detail
file2 <- "2022-state-school-system-cohort-graduation.xlsx"
cat("\n", paste(strrep("=", 80), collapse=""), "\n")
cat("DETAILED ANALYSIS:", file2, "\n")
cat(paste(strrep("=", 80), collapse=""), "\n")

df2 <- read_excel(file2, sheet = 1, skip = 2)

cat("\nFull column names:\n")
print(colnames(df2))

cat("\nData structure (first 5 rows):\n")
print(head(df2, 5))

cat("\nData dimensions:", nrow(df2), "x", ncol(df2), "\n")

# Check race/ethnicity columns
cat("\nChecking subgroup columns...\n")
for (i in 3:ncol(df2)) {
  unique_vals <- unique(df2[[i]])
  unique_vals <- unique_vals[!is.na(unique_vals)]
  cat(paste0("\nColumn '", colnames(df2)[i], "':\n"))
  print(unique_vals[1:10])
}

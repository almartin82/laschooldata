# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw LDOE enrollment data into a
# clean, standardized format.
#
# Louisiana Multi Stats files contain:
# - LEA Code (3-digit parish/district code)
# - Site Code (school identifier)
# - Names (LEA Name, Site Name)
# - Enrollment by race: American Indian, Asian, Black, Hispanic, Hawaiian/PI, White, Multiple Races
# - Gender: % Female, % Male (PERCENTAGES, not counts!)
# - English Proficiency: % Fully English Proficient, % Limited English Proficiency
# - Enrollment by grade: Infants, Pre-School, Pre-K, K, 1-12, Extension Academy
# - Economically Disadvantaged: percentage
#
# CRITICAL: Gender and LEP are stored as PERCENTAGES in the source data.
# We convert them to counts using total enrollment.
#
# ==============================================================================

#' Convert to numeric, handling suppression markers and percentages
#'
#' LDOE uses various markers for suppressed data (*, <5, -, etc.)
#' and may use commas in large numbers. Percentages have % suffix.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas, percentage signs, and whitespace
  x <- gsub(",", "", x)
  x <- gsub("%", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "NULL")] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Convert percentage column to numeric, handling both formats
#'
#' LDOE data uses different percentage formats across years:
#' - 2024+: "48.8%" (percentage with % sign)
#' - 2019-2023: 0.48846... (decimal, 0-1 range)
#'
#' This function normalizes both to percentage form (0-100 range).
#'
#' @param x Vector of percentage values (either format)
#' @return Numeric vector with percentages in 0-100 range
#' @keywords internal
safe_percentage <- function(x) {
  # Check if any values have % sign - indicates 2024+ format
  has_percent_sign <- any(grepl("%", x, fixed = TRUE), na.rm = TRUE)

  # Clean the values
  x <- gsub(",", "", x)
  x <- gsub("%", "", x)
  x <- trimws(x)

  # Handle suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "NULL")] <- NA_character_

  result <- suppressWarnings(as.numeric(x))

  # If no % sign was present and values are in 0-1 range, multiply by 100
  if (!has_percent_sign) {
    # Check if values look like decimals (all non-NA values are <= 1)
    non_na_vals <- result[!is.na(result)]
    if (length(non_na_vals) > 0 && all(non_na_vals <= 1)) {
      result <- result * 100
    }
  }

  result
}


#' Process raw LDOE enrollment data
#'
#' Transforms raw Multi Stats data into a standardized schema combining site
#' and LEA data. Converts percentage columns (gender, LEP) to counts.
#'
#' @param raw_data List containing site and lea data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process LEA (district) data first - this is used for state aggregate
  lea_processed <- process_lea_enr(raw_data$lea, end_year)

  # Process site (campus) data
  site_processed <- process_site_enr(raw_data$site, end_year)

  # Create state aggregate from LEA data
  state_processed <- create_state_aggregate(lea_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, lea_processed, site_processed)

  result
}


#' Process site-level enrollment data
#'
#' @param df Raw site data frame
#' @param end_year School year end
#' @return Processed site data frame
#' @keywords internal
process_site_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),
    stringsAsFactors = FALSE
  )

  # IDs - Louisiana uses LEA Code (3-digit parish) and Site Code
  lea_col <- find_col(c("^school_system$", "^lea.*code", "^district.*code", "^parish.*code"))
  if (!is.null(lea_col)) {
    # Pad to 3 digits
    result$district_id <- sprintf("%03s", trimws(df[[lea_col]]))
  }

  site_col <- find_col(c("^sis_submit_site_code$", "^site.*code", "^school.*code", "^campus.*code"))
  if (!is.null(site_col)) {
    result$campus_id <- trimws(df[[site_col]])
  }

  # Names
  lea_name_col <- find_col(c("^school_system_name$", "^lea.*name", "^district.*name", "^parish.*name"))
  if (!is.null(lea_name_col)) {
    result$district_name <- trimws(df[[lea_name_col]])
  }

  site_name_col <- find_col(c("^site_name$", "^school.*name", "^campus.*name"))
  if (!is.null(site_name_col)) {
    result$campus_name <- trimws(df[[site_name_col]])
  }

  # Total enrollment
  total_col <- find_col(c("^total_enrollment$", "^total$", "^grand.*total", "^all.*students"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Louisiana reports race/ethnicity as COUNTS
  demo_map <- list(
    white = c("^white$"),
    black = c("^black$"),
    hispanic = c("^hispanic$"),
    asian = c("^asian$"),
    pacific_islander = c("^hawaiian_pacific_islander$", "^hawaiian$", "^pacific"),
    native_american = c("^american_indian$", "^native.*american"),
    multiracial = c("^multiple_races_non_hispanic$", "^multiple.*race", "^two.*more")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Minority count
  minority_col <- find_col(c("^minority$"))
  if (!is.null(minority_col)) {
    result$minority <- safe_numeric(df[[minority_col]])
  }

  # Gender - stored as PERCENTAGES, convert to counts
  # CRITICAL FIX: The columns are "percent_female" and "percent_male" after cleaning
  # NOTE: 2024+ uses "48.8%" format, 2019-2023 uses 0.4884 (decimal) format
  pct_female_col <- find_col(c("^percent_female$", "^x_percent_female$", "^pct.*female", "^female"))
  pct_male_col <- find_col(c("^percent_male$", "^x_percent_male$", "^pct.*male", "^male"))

  if (!is.null(pct_female_col) && !is.null(result$row_total)) {
    pct_female <- safe_percentage(df[[pct_female_col]])
    result$female <- round(result$row_total * pct_female / 100)
    result$pct_female <- pct_female
  }

  if (!is.null(pct_male_col) && !is.null(result$row_total)) {
    pct_male <- safe_percentage(df[[pct_male_col]])
    result$male <- round(result$row_total * pct_male / 100)
    result$pct_male <- pct_male
  }

  # English Proficiency - stored as PERCENTAGES
  pct_lep_col <- find_col(c("^percent_limited_english_proficiency$", "^x_percent_limited", "^pct.*lep", "^limited.*english"))
  pct_fep_col <- find_col(c("^percent_fully_english_proficient$", "^x_percent_fully", "^fully.*english"))

  if (!is.null(pct_lep_col) && !is.null(result$row_total)) {
    pct_lep <- safe_percentage(df[[pct_lep_col]])
    result$lep <- round(result$row_total * pct_lep / 100)
    result$pct_lep <- pct_lep
  }

  if (!is.null(pct_fep_col) && !is.null(result$row_total)) {
    pct_fep <- safe_percentage(df[[pct_fep_col]])
    result$fep <- round(result$row_total * pct_fep / 100)
    result$pct_fep <- pct_fep
  }

  # Economically Disadvantaged - stored as PERCENTAGE
  pct_econ_col <- find_col(c("^percent_economically_disadvantaged$", "^x_percent_economically", "^econ.*disadv"))
  if (!is.null(pct_econ_col) && !is.null(result$row_total)) {
    pct_econ <- safe_percentage(df[[pct_econ_col]])
    result$econ_disadv <- round(result$row_total * pct_econ / 100)
    result$pct_econ_disadv <- pct_econ
  }

  # Grade levels - Louisiana uses counts
  grade_map <- list(
    grade_infant = c("^infants_sp_ed$", "^infant"),
    grade_preschool = c("^pre_school_sp_ed$", "^pre.*school"),
    grade_pk = c("^pre_k_reg_ed$", "^pre_k$", "^prek$"),
    grade_k = c("^kindergarten$", "^kg$"),
    grade_01 = c("^grade_1$", "^grade1$"),
    grade_02 = c("^grade_2$", "^grade2$"),
    grade_03 = c("^grade_3$", "^grade3$"),
    grade_04 = c("^grade_4$", "^grade4$"),
    grade_05 = c("^grade_5$", "^grade5$"),
    grade_06 = c("^grade_6$", "^grade6$"),
    grade_07 = c("^grade_7$", "^grade7$"),
    grade_08 = c("^grade_8$", "^grade8$"),
    grade_09 = c("^grade_9$", "^grade9$"),
    grade_t9 = c("^grade_t9$", "^t9$"),
    grade_10 = c("^grade_10$", "^grade10$"),
    grade_11 = c("^grade_11$", "^grade11$"),
    grade_12 = c("^grade_12$", "^grade12$"),
    grade_extension = c("^extension_academy$", "^extension$")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Process LEA-level enrollment data
#'
#' @param df Raw LEA data frame
#' @param end_year School year end
#' @return Processed LEA data frame
#' @keywords internal
process_lea_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # IDs - LEA sheet has school_system column
  lea_col <- find_col(c("^school_system$", "^lea.*code", "^district.*code", "^parish.*code"))
  if (!is.null(lea_col)) {
    result$district_id <- sprintf("%03s", trimws(df[[lea_col]]))
  }

  # Campus ID is NA for district rows
  result$campus_id <- rep(NA_character_, n_rows)

  # Names
  lea_name_col <- find_col(c("^school_system_name$", "^lea.*name", "^district.*name", "^parish.*name"))
  if (!is.null(lea_name_col)) {
    result$district_name <- trimws(df[[lea_name_col]])
  }

  result$campus_name <- rep(NA_character_, n_rows)

  # Total enrollment
  total_col <- find_col(c("^total_enrollment$", "^total$", "^grand.*total"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics
  demo_map <- list(
    white = c("^white$"),
    black = c("^black$"),
    hispanic = c("^hispanic$"),
    asian = c("^asian$"),
    pacific_islander = c("^hawaiian_pacific_islander$", "^hawaiian$", "^pacific"),
    native_american = c("^american_indian$", "^native.*american"),
    multiracial = c("^multiple_races_non_hispanic$", "^multiple.*race", "^two.*more")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Minority count
  minority_col <- find_col(c("^minority$"))
  if (!is.null(minority_col)) {
    result$minority <- safe_numeric(df[[minority_col]])
  }

  # Gender - stored as PERCENTAGES, convert to counts
  # NOTE: 2024+ uses "48.8%" format, 2019-2023 uses 0.4884 (decimal) format
  pct_female_col <- find_col(c("^percent_female$", "^x_percent_female$", "^pct.*female"))
  pct_male_col <- find_col(c("^percent_male$", "^x_percent_male$", "^pct.*male"))

  if (!is.null(pct_female_col) && !is.null(result$row_total)) {
    pct_female <- safe_percentage(df[[pct_female_col]])
    result$female <- round(result$row_total * pct_female / 100)
    result$pct_female <- pct_female
  }

  if (!is.null(pct_male_col) && !is.null(result$row_total)) {
    pct_male <- safe_percentage(df[[pct_male_col]])
    result$male <- round(result$row_total * pct_male / 100)
    result$pct_male <- pct_male
  }

  # English Proficiency - stored as PERCENTAGES
  pct_lep_col <- find_col(c("^percent_limited_english_proficiency$", "^x_percent_limited", "^pct.*lep"))
  pct_fep_col <- find_col(c("^percent_fully_english_proficient$", "^x_percent_fully"))

  if (!is.null(pct_lep_col) && !is.null(result$row_total)) {
    pct_lep <- safe_percentage(df[[pct_lep_col]])
    result$lep <- round(result$row_total * pct_lep / 100)
    result$pct_lep <- pct_lep
  }

  if (!is.null(pct_fep_col) && !is.null(result$row_total)) {
    pct_fep <- safe_percentage(df[[pct_fep_col]])
    result$fep <- round(result$row_total * pct_fep / 100)
    result$pct_fep <- pct_fep
  }

  # Economically Disadvantaged - stored as PERCENTAGE
  pct_econ_col <- find_col(c("^percent_economically_disadvantaged$", "^x_percent_economically"))
  if (!is.null(pct_econ_col) && !is.null(result$row_total)) {
    pct_econ <- safe_percentage(df[[pct_econ_col]])
    result$econ_disadv <- round(result$row_total * pct_econ / 100)
    result$pct_econ_disadv <- pct_econ
  }

  # Grade levels
  grade_map <- list(
    grade_infant = c("^infants_sp_ed$", "^infant"),
    grade_preschool = c("^pre_school_sp_ed$", "^pre.*school"),
    grade_pk = c("^pre_k_reg_ed$", "^pre_k$", "^prek$"),
    grade_k = c("^kindergarten$", "^kg$"),
    grade_01 = c("^grade_1$", "^grade1$"),
    grade_02 = c("^grade_2$", "^grade2$"),
    grade_03 = c("^grade_3$", "^grade3$"),
    grade_04 = c("^grade_4$", "^grade4$"),
    grade_05 = c("^grade_5$", "^grade5$"),
    grade_06 = c("^grade_6$", "^grade6$"),
    grade_07 = c("^grade_7$", "^grade7$"),
    grade_08 = c("^grade_8$", "^grade8$"),
    grade_09 = c("^grade_9$", "^grade9$"),
    grade_t9 = c("^grade_t9$", "^t9$"),
    grade_10 = c("^grade_10$", "^grade10$"),
    grade_11 = c("^grade_11$", "^grade11$"),
    grade_12 = c("^grade_12$", "^grade12$"),
    grade_extension = c("^extension_academy$", "^extension$")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Create state-level aggregate from LEA data
#'
#' Sums all LEA rows to create a state total.
#' EXCLUDES the state row from LEA data if present (district_id == "000").
#'
#' @param lea_df Processed LEA data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(lea_df, end_year) {

  if (is.null(lea_df) || nrow(lea_df) == 0) {
    # Return minimal state row
    return(data.frame(
      end_year = end_year,
      type = "State",
      district_id = NA_character_,
      campus_id = NA_character_,
      district_name = "Louisiana",
      campus_name = NA_character_,
      stringsAsFactors = FALSE
    ))
  }

  # Check if there's already a state row in the data (district_id == "000")
  state_row_idx <- which(lea_df$district_id == "000")

  if (length(state_row_idx) > 0) {
    # Use the existing state row from the data
    state_row <- lea_df[state_row_idx[1], ]
    state_row$type <- "State"
    state_row$district_id <- NA_character_

    # Get the name from the source if available
    if (is.na(state_row$district_name) || state_row$district_name == "") {
      state_row$district_name <- "Louisiana"
    }

    # Remove the state row from lea_df to avoid double counting later
    lea_df <- lea_df[-state_row_idx, ]

    return(state_row)
  }

  # If no state row exists, compute aggregate
  # Columns to sum (numeric count columns only)
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial", "minority",
    "male", "female",
    "lep", "fep", "econ_disadv",
    "grade_infant", "grade_preschool", "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_t9", "grade_10", "grade_11", "grade_12",
    "grade_extension"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(lea_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = "Louisiana",
    campus_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(lea_df[[col]], na.rm = TRUE)
  }

  # Compute weighted average percentages for state
  if ("row_total" %in% names(state_row) && state_row$row_total > 0) {
    total <- state_row$row_total

    if ("female" %in% names(state_row)) {
      state_row$pct_female <- round(state_row$female / total * 100, 1)
    }
    if ("male" %in% names(state_row)) {
      state_row$pct_male <- round(state_row$male / total * 100, 1)
    }
    if ("lep" %in% names(state_row)) {
      state_row$pct_lep <- round(state_row$lep / total * 100, 1)
    }
    if ("fep" %in% names(state_row)) {
      state_row$pct_fep <- round(state_row$fep / total * 100, 1)
    }
    if ("econ_disadv" %in% names(state_row)) {
      state_row$pct_econ_disadv <- round(state_row$econ_disadv / total * 100, 1)
    }
  }

  state_row
}

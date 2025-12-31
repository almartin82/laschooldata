# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw LDOE enrollment data into a
# clean, standardized format.
#
# Louisiana Multi Stats files typically contain:
# - LEA Code (3-digit parish/district code)
# - Site Code (school identifier)
# - Names (LEA Name, Site Name)
# - Enrollment by race: White, Black, Hispanic, Asian, American Indian, etc.
# - Enrollment by grade: PK, K, 1-12
# - Special population flags
#
# ==============================================================================

#' Convert to numeric, handling suppression markers
#'
#' LDOE uses various markers for suppressed data (*, <5, -, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "NULL")] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Process raw LDOE enrollment data
#'
#' Transforms raw Multi Stats data into a standardized schema combining site
#' and LEA data.
#'
#' @param raw_data List containing site and lea data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process site (campus) data
  site_processed <- process_site_enr(raw_data$site, end_year)

  # Process LEA (district) data
  lea_processed <- process_lea_enr(raw_data$lea, end_year)

  # Create state aggregate
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
  lea_col <- find_col(c("^LEA.*Code", "^LEA_Code", "^LEACODE", "^District.*Code", "^Parish.*Code"))
  if (!is.null(lea_col)) {
    # Pad to 3 digits
    result$district_id <- sprintf("%03s", trimws(df[[lea_col]]))
  }

  site_col <- find_col(c("^Site.*Code", "^SITE_CODE", "^SITECODE", "^School.*Code", "^Campus.*Code"))
  if (!is.null(site_col)) {
    result$campus_id <- trimws(df[[site_col]])
  }

  # Names
  lea_name_col <- find_col(c("^LEA.*Name", "^District.*Name", "^Parish.*Name", "^System.*Name"))
  if (!is.null(lea_name_col)) {
    result$district_name <- trimws(df[[lea_name_col]])
  }

  site_name_col <- find_col(c("^Site.*Name", "^School.*Name", "^Campus.*Name"))
  if (!is.null(site_name_col)) {
    result$campus_name <- trimws(df[[site_name_col]])
  }

  # School type
  type_col <- find_col(c("^School.*Type", "^Site.*Type", "^Type"))
  if (!is.null(type_col)) {
    result$school_type <- trimws(df[[type_col]])
  }

  # Total enrollment - look for various patterns
  total_col <- find_col(c("^Total$", "^Total.*Enrollment", "^Enrollment.*Total",
                          "^Grand.*Total", "^All.*Students", "^MFP.*Total"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Louisiana reports race/ethnicity
  demo_map <- list(
    white = c("^White", "^WHITE", "^Wh$"),
    black = c("^Black", "^BLACK", "^African.*American", "^Bl$", "^Blk$"),
    hispanic = c("^Hispanic", "^HISPANIC", "^Latino", "^His$"),
    asian = c("^Asian", "^ASIAN", "^As$"),
    pacific_islander = c("^Pacific.*Islander", "^Native.*Hawaiian", "^PI$", "^Hawaiian"),
    native_american = c("^American.*Indian", "^Native.*American", "^AI$", "^Indian"),
    multiracial = c("^Two.*More", "^Multi.*Racial", "^Multiple", "^2.*More", "^Two$")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Gender
  gender_map <- list(
    male = c("^Male$", "^Males$", "^M$"),
    female = c("^Female$", "^Females$", "^F$")
  )

  for (name in names(gender_map)) {
    col <- find_col(gender_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Special populations
  special_map <- list(
    econ_disadv = c("^Econ.*Disadv", "^Free.*Reduced", "^FRL", "^Low.*Income"),
    lep = c("^LEP", "^English.*Learner", "^ELL", "^Limited.*English"),
    special_ed = c("^Special.*Ed", "^SPED", "^Disabled", "^IEP")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels - Louisiana uses PK, K, 1-12
  # Note: Louisiana may also have PreK 3, PreK 4, etc.
  grade_map <- list(
    grade_pk3 = c("^PK3$", "^PreK.*3", "^Pre-K.*3"),
    grade_pk4 = c("^PK4$", "^PreK.*4", "^Pre-K.*4"),
    grade_pk = c("^PK$", "^PreK$", "^Pre-K$", "^Prekindergarten$"),
    grade_k = c("^K$", "^KG$", "^Kindergarten$"),
    grade_01 = c("^1$", "^01$", "^Grade.*1$", "^1st$"),
    grade_02 = c("^2$", "^02$", "^Grade.*2$", "^2nd$"),
    grade_03 = c("^3$", "^03$", "^Grade.*3$", "^3rd$"),
    grade_04 = c("^4$", "^04$", "^Grade.*4$", "^4th$"),
    grade_05 = c("^5$", "^05$", "^Grade.*5$", "^5th$"),
    grade_06 = c("^6$", "^06$", "^Grade.*6$", "^6th$"),
    grade_07 = c("^7$", "^07$", "^Grade.*7$", "^7th$"),
    grade_08 = c("^8$", "^08$", "^Grade.*8$", "^8th$"),
    grade_09 = c("^9$", "^09$", "^Grade.*9$", "^9th$"),
    grade_10 = c("^10$", "^Grade.*10$", "^10th$"),
    grade_11 = c("^11$", "^Grade.*11$", "^11th$"),
    grade_12 = c("^12$", "^Grade.*12$", "^12th$")
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

  # IDs
  lea_col <- find_col(c("^LEA.*Code", "^LEA_Code", "^LEACODE", "^District.*Code", "^Parish.*Code"))
  if (!is.null(lea_col)) {
    result$district_id <- sprintf("%03s", trimws(df[[lea_col]]))
  }

  # Campus ID is NA for district rows
  result$campus_id <- rep(NA_character_, n_rows)

  # Names
  lea_name_col <- find_col(c("^LEA.*Name", "^District.*Name", "^Parish.*Name", "^System.*Name"))
  if (!is.null(lea_name_col)) {
    result$district_name <- trimws(df[[lea_name_col]])
  }

  result$campus_name <- rep(NA_character_, n_rows)

  # Total enrollment
  total_col <- find_col(c("^Total$", "^Total.*Enrollment", "^Enrollment.*Total",
                          "^Grand.*Total", "^All.*Students", "^MFP.*Total"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics
  demo_map <- list(
    white = c("^White", "^WHITE", "^Wh$"),
    black = c("^Black", "^BLACK", "^African.*American", "^Bl$", "^Blk$"),
    hispanic = c("^Hispanic", "^HISPANIC", "^Latino", "^His$"),
    asian = c("^Asian", "^ASIAN", "^As$"),
    pacific_islander = c("^Pacific.*Islander", "^Native.*Hawaiian", "^PI$", "^Hawaiian"),
    native_american = c("^American.*Indian", "^Native.*American", "^AI$", "^Indian"),
    multiracial = c("^Two.*More", "^Multi.*Racial", "^Multiple", "^2.*More", "^Two$")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Gender
  gender_map <- list(
    male = c("^Male$", "^Males$", "^M$"),
    female = c("^Female$", "^Females$", "^F$")
  )

  for (name in names(gender_map)) {
    col <- find_col(gender_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Special populations
  special_map <- list(
    econ_disadv = c("^Econ.*Disadv", "^Free.*Reduced", "^FRL", "^Low.*Income"),
    lep = c("^LEP", "^English.*Learner", "^ELL", "^Limited.*English"),
    special_ed = c("^Special.*Ed", "^SPED", "^Disabled", "^IEP")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_map <- list(
    grade_pk3 = c("^PK3$", "^PreK.*3", "^Pre-K.*3"),
    grade_pk4 = c("^PK4$", "^PreK.*4", "^Pre-K.*4"),
    grade_pk = c("^PK$", "^PreK$", "^Pre-K$", "^Prekindergarten$"),
    grade_k = c("^K$", "^KG$", "^Kindergarten$"),
    grade_01 = c("^1$", "^01$", "^Grade.*1$", "^1st$"),
    grade_02 = c("^2$", "^02$", "^Grade.*2$", "^2nd$"),
    grade_03 = c("^3$", "^03$", "^Grade.*3$", "^3rd$"),
    grade_04 = c("^4$", "^04$", "^Grade.*4$", "^4th$"),
    grade_05 = c("^5$", "^05$", "^Grade.*5$", "^5th$"),
    grade_06 = c("^6$", "^06$", "^Grade.*6$", "^6th$"),
    grade_07 = c("^7$", "^07$", "^Grade.*7$", "^7th$"),
    grade_08 = c("^8$", "^08$", "^Grade.*8$", "^8th$"),
    grade_09 = c("^9$", "^09$", "^Grade.*9$", "^9th$"),
    grade_10 = c("^10$", "^Grade.*10$", "^10th$"),
    grade_11 = c("^11$", "^Grade.*11$", "^11th$"),
    grade_12 = c("^12$", "^Grade.*12$", "^12th$")
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

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk3", "grade_pk4", "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
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

  state_row
}

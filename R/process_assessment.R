# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw LDOE assessment data into a
# clean, standardized format.
#
# Louisiana LEAP 2025 uses five proficiency levels:
# - Unsatisfactory (Level 1)
# - Approaching Basic (Level 2)
# - Basic (Level 3)
# - Mastery (Level 4)
# - Advanced (Level 5)
#
# "Proficient" typically means Mastery or Advanced (Levels 4-5)
# "Basic and Above" means Basic, Mastery, or Advanced (Levels 3-5)
#
# ==============================================================================


#' Process raw LDOE assessment data
#'
#' Transforms raw LDOE assessment data into a standardized schema combining
#' state, district, and school data.
#'
#' @param raw_data List containing state_lea and/or school data frames from get_raw_assessment
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_assessment <- function(raw_data, end_year) {

  result_list <- list()

  # Process state_lea level if present
  if ("state_lea" %in% names(raw_data) && !is.null(raw_data$state_lea) && nrow(raw_data$state_lea) > 0) {
    result_list$state_lea <- process_assessment_level(raw_data$state_lea, end_year)
  }

  # Process school level if present
  if ("school" %in% names(raw_data) && !is.null(raw_data$school) && nrow(raw_data$school) > 0) {
    result_list$school <- process_assessment_level(raw_data$school, end_year)
  }

  # Combine all levels
  if (length(result_list) == 0) {
    return(create_empty_assessment_result(end_year))
  }

  dplyr::bind_rows(result_list)
}


#' Process a single level of assessment data
#'
#' @param df Raw data frame for one level
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_assessment_level <- function(df, end_year) {

  if (nrow(df) == 0) {
    return(create_empty_assessment_result(end_year))
  }

  # Clean column names
  names(df) <- clean_assessment_names(names(df))

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

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    stringsAsFactors = FALSE
  )

  # District/System Code - Louisiana uses "School System Code"
  district_col <- find_col(c("school_system_code", "lea_code", "district_code", "system_code"))
  if (!is.null(district_col)) {
    district_vals <- trimws(as.character(df[[district_col]]))
    result$district_id <- sprintf("%03d", as.integer(district_vals))
    result$district_id[is.na(as.integer(district_vals))] <- NA_character_
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # District/System Name
  district_name_col <- find_col(c("school_system_name", "school_system", "lea_name", "district_name", "system_name"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  # School Code (only for school-level data)
  school_col <- find_col(c("school_code", "site_code", "school_id"))
  if (!is.null(school_col)) {
    school_vals <- trimws(as.character(df[[school_col]]))
    result$school_id <- sprintf("%06d", as.integer(school_vals))
    result$school_id[is.na(as.integer(school_vals))] <- NA_character_
  } else {
    result$school_id <- rep(NA_character_, n_rows)
  }

  # School Name
  school_name_col <- find_col(c("^school_name$", "^school$", "^site_name$"))
  if (!is.null(school_name_col)) {
    result$school_name <- trimws(as.character(df[[school_name_col]]))
  } else {
    result$school_name <- rep(NA_character_, n_rows)
  }

  # Grade
  grade_col <- find_col(c("^grade$", "^grade_level$", "^tested_grade$"))
  if (!is.null(grade_col)) {
    result$grade <- standardize_la_grade(df[[grade_col]])
  } else {
    result$grade <- rep(NA_character_, n_rows)
  }

  # Subject
  subject_col <- find_col(c("^subject$", "^content_area$", "^assessment_subject$"))
  if (!is.null(subject_col)) {
    result$subject <- standardize_la_subject(df[[subject_col]])
  } else {
    result$subject <- rep(NA_character_, n_rows)
  }

  # Subgroup (if present)
  subgroup_col <- find_col(c("^subgroup$", "^student_group$", "^demographic$"))
  if (!is.null(subgroup_col)) {
    result$subgroup <- standardize_la_subgroup(df[[subgroup_col]])
  } else {
    result$subgroup <- rep("All Students", n_rows)
  }

  # Number tested
  n_tested_col <- find_col(c("total_students", "n_tested", "tested", "num_tested", "number_tested",
                              "students_tested", "total_tested"))
  if (!is.null(n_tested_col)) {
    result$n_tested <- safe_numeric(df[[n_tested_col]])
  } else {
    result$n_tested <- rep(NA_integer_, n_rows)
  }

  # Proficiency level percentages
  # Louisiana uses: Unsatisfactory, Approaching Basic, Basic, Mastery, Advanced

  # Unsatisfactory
  pct_unsatisfactory_col <- find_col(c("pct_unsatisfactory", "percent_unsatisfactory",
                                        "unsatisfactory_pct", "unsatisfactory"))
  if (!is.null(pct_unsatisfactory_col)) {
    result$pct_unsatisfactory <- safe_numeric(df[[pct_unsatisfactory_col]])
  } else {
    result$pct_unsatisfactory <- rep(NA_real_, n_rows)
  }

  # Approaching Basic
  pct_approaching_col <- find_col(c("pct_approaching_basic", "percent_approaching_basic",
                                     "approaching_basic_pct", "approaching_basic",
                                     "pct_approaching", "approaching"))
  if (!is.null(pct_approaching_col)) {
    result$pct_approaching_basic <- safe_numeric(df[[pct_approaching_col]])
  } else {
    result$pct_approaching_basic <- rep(NA_real_, n_rows)
  }

  # Basic
  pct_basic_col <- find_col(c("pct_basic", "percent_basic", "basic_pct", "^basic$"))
  if (!is.null(pct_basic_col)) {
    result$pct_basic <- safe_numeric(df[[pct_basic_col]])
  } else {
    result$pct_basic <- rep(NA_real_, n_rows)
  }

  # Mastery
  pct_mastery_col <- find_col(c("pct_mastery", "percent_mastery", "mastery_pct", "^mastery$"))
  if (!is.null(pct_mastery_col)) {
    result$pct_mastery <- safe_numeric(df[[pct_mastery_col]])
  } else {
    result$pct_mastery <- rep(NA_real_, n_rows)
  }

  # Advanced
  pct_advanced_col <- find_col(c("pct_advanced", "percent_advanced", "advanced_pct", "^advanced$"))
  if (!is.null(pct_advanced_col)) {
    result$pct_advanced <- safe_numeric(df[[pct_advanced_col]])
  } else {
    result$pct_advanced <- rep(NA_real_, n_rows)
  }

  # Calculate proficient (Mastery + Advanced)
  result$pct_proficient <- dplyr::case_when(
    !is.na(result$pct_mastery) & !is.na(result$pct_advanced) ~
      result$pct_mastery + result$pct_advanced,
    TRUE ~ NA_real_
  )

  # Calculate basic and above (Basic + Mastery + Advanced)
  result$pct_basic_above <- dplyr::case_when(
    !is.na(result$pct_basic) & !is.na(result$pct_mastery) & !is.na(result$pct_advanced) ~
      result$pct_basic + result$pct_mastery + result$pct_advanced,
    TRUE ~ NA_real_
  )

  # Determine record type
  result$type <- dplyr::case_when(
    !is.na(result$school_id) & result$school_id != "" ~ "School",
    !is.na(result$district_id) & result$district_id != "" ~ "District",
    TRUE ~ "State"
  )

  # Also check for state total rows (usually district_id = "000" or "State")
  if ("district_name" %in% names(result)) {
    result$type <- dplyr::case_when(
      tolower(result$district_name) %in% c("state of louisiana", "state", "louisiana", "statewide") ~ "State",
      result$district_id == "000" ~ "State",
      TRUE ~ result$type
    )
  }

  result
}


#' Clean assessment column names
#'
#' @param x Vector of column names
#' @return Cleaned column names
#' @keywords internal
clean_assessment_names <- function(x) {
  # Convert to lowercase
  x <- tolower(x)
  # Replace spaces and special chars with underscore
  x <- gsub("[^a-z0-9]+", "_", x)
  # Remove leading/trailing underscores
  x <- gsub("^_+|_+$", "", x)
  # Remove duplicate underscores
  x <- gsub("_+", "_", x)
  x
}


#' Standardize Louisiana subject names
#'
#' @param x Vector of subject names
#' @return Standardized subject names
#' @keywords internal
standardize_la_subject <- function(x) {
  x <- toupper(trimws(as.character(x)))

  # Standard subject mappings
  x <- gsub("^ELA$|^ENGLISH.*LANGUAGE.*ARTS$|^ENGLISH$", "ELA", x)
  x <- gsub("^MATH$|^MATHEMATICS$", "Math", x)
  x <- gsub("^SCIENCE$|^SCI$", "Science", x)
  x <- gsub("^SOCIAL.*STUDIES$|^SS$|^SOC.*STUD$", "Social Studies", x)
  x <- gsub("^TOTAL$|^ALL.*SUBJECTS$|^OVERALL$", "All Subjects", x)

  # High school subjects
  x <- gsub("^ALGEBRA\\s*I$|^ALG\\s*1$", "Algebra I", x)
  x <- gsub("^GEOMETRY$|^GEO$", "Geometry", x)
  x <- gsub("^ENGLISH\\s*II$|^ENG\\s*2$", "English II", x)
  x <- gsub("^BIOLOGY$|^BIO$", "Biology", x)
  x <- gsub("^U\\.?S\\.?\\s*HISTORY$|^US\\s*HIST$", "US History", x)

  x
}


#' Standardize Louisiana grade levels
#'
#' @param x Vector of grade values
#' @return Standardized grade levels
#' @keywords internal
standardize_la_grade <- function(x) {
  x <- toupper(trimws(as.character(x)))

  # Remove GRADE prefix
  x <- gsub("^GRADE\\s*", "", x)

  # Handle ordinal formats
  x <- gsub("^3RD$", "03", x)
  x <- gsub("^4TH$", "04", x)
  x <- gsub("^5TH$", "05", x)
  x <- gsub("^6TH$", "06", x)
  x <- gsub("^7TH$", "07", x)
  x <- gsub("^8TH$", "08", x)

  # Pad single digits to two digits
  x <- gsub("^([3-9])$", "0\\1", x)

  # EOC/HS indicators
  x <- gsub("^EOC$|^END.*OF.*COURSE$|^HS$|^HIGH.*SCHOOL$", "HS", x)
  x <- gsub("^ALL.*GRADES$|^ALL$|^TOTAL$", "All", x)

  # Grade bands
  x <- gsub("^3-8$|^GRADES\\s*3-8$", "3-8", x)

  x
}


#' Standardize Louisiana subgroup names
#'
#' @param x Vector of subgroup names
#' @return Standardized subgroup names
#' @keywords internal
standardize_la_subgroup <- function(x) {
  x <- trimws(as.character(x))

  subgroup_map <- c(
    # All students
    "All Students" = "All Students",
    "ALL STUDENTS" = "All Students",
    "All" = "All Students",
    "TOTAL" = "All Students",

    # Race/ethnicity
    "Black or African American" = "Black",
    "BLACK OR AFRICAN AMERICAN" = "Black",
    "Black" = "Black",
    "African American" = "Black",

    "White" = "White",
    "WHITE" = "White",

    "Hispanic" = "Hispanic",
    "HISPANIC" = "Hispanic",
    "Hispanic/Latino" = "Hispanic",

    "Asian" = "Asian",
    "ASIAN" = "Asian",

    "American Indian" = "Native American",
    "AMERICAN INDIAN" = "Native American",
    "American Indian/Alaska Native" = "Native American",
    "Native American" = "Native American",

    "Native Hawaiian or Other Pacific Islander" = "Pacific Islander",
    "Pacific Islander" = "Pacific Islander",
    "Hawaiian/Pacific Islander" = "Pacific Islander",

    "Two or More Races" = "Multiracial",
    "TWO OR MORE RACES" = "Multiracial",
    "Multiple Races" = "Multiracial",
    "Multiracial" = "Multiracial",

    # Gender
    "Female" = "Female",
    "FEMALE" = "Female",
    "Male" = "Male",
    "MALE" = "Male",

    # Special populations
    "Economically Disadvantaged" = "Economically Disadvantaged",
    "ECONOMICALLY DISADVANTAGED" = "Economically Disadvantaged",
    "ED" = "Economically Disadvantaged",

    "Students with Disabilities" = "Students with Disabilities",
    "STUDENTS WITH DISABILITIES" = "Students with Disabilities",
    "SWD" = "Students with Disabilities",

    "English Learners" = "English Learners",
    "ENGLISH LEARNERS" = "English Learners",
    "EL" = "English Learners",
    "LEP" = "English Learners",
    "Limited English Proficient" = "English Learners"
  )

  result <- subgroup_map[x]
  result[is.na(result)] <- x[is.na(result)]
  unname(result)
}


#' Create empty assessment result data frame
#'
#' @param end_year School year end
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_assessment_result <- function(end_year) {
  data.frame(
    end_year = integer(0),
    type = character(0),
    district_id = character(0),
    district_name = character(0),
    school_id = character(0),
    school_name = character(0),
    grade = character(0),
    subject = character(0),
    subgroup = character(0),
    n_tested = integer(0),
    pct_unsatisfactory = numeric(0),
    pct_approaching_basic = numeric(0),
    pct_basic = numeric(0),
    pct_mastery = numeric(0),
    pct_advanced = numeric(0),
    pct_proficient = numeric(0),
    pct_basic_above = numeric(0),
    stringsAsFactors = FALSE
  )
}

# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
NULL


#' Get available years for Louisiana enrollment data
#'
#' Returns the range of years for which enrollment data is available
#' from the Louisiana Department of Education (LDOE).
#'
#' @return A list with:
#'   \item{min_year}{First available year (2019)}
#'   \item{max_year}{Last available year (2024)}
#'   \item{description}{Description of data availability}
#' @export
#' @examples
#' years <- get_available_years()
#' print(years$min_year)
#' print(years$max_year)
get_available_years <- function() {
  list(
    min_year = 2019,
    max_year = 2024,
    description = paste(
      "Louisiana enrollment data from LDOE Multi Stats files.",
      "Available years: 2019-2024.",
      "Earlier years (2007-2018) may use different formats and URLs."
    )
  )
}


#' Louisiana Parish Codes
#'
#' Returns a data frame mapping Louisiana LEA codes to parish names.
#' Louisiana has 64 parishes (equivalent to counties) plus special districts.
#'
#' @return Data frame with lea_code and parish_name columns
#' @keywords internal
get_parish_codes <- function() {
  data.frame(
    lea_code = sprintf("%03d", c(
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
      21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
      39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56,
      57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73
    )),
    parish_name = c(
      "Acadia", "Allen", "Ascension", "Assumption", "Avoyelles",
      "Beauregard", "Bienville", "Bossier", "Caddo", "Calcasieu",
      "Caldwell", "Cameron", "Catahoula", "Claiborne", "Concordia",
      "De Soto", "East Baton Rouge", "East Carroll", "East Feliciana",
      "Evangeline", "Franklin", "Grant", "Iberia", "Iberville",
      "Jackson", "Jefferson", "Jefferson Davis", "Lafayette", "Lafourche",
      "La Salle", "Lincoln", "Livingston", "Madison", "Morehouse",
      "Natchitoches", "Orleans", "Ouachita", "Plaquemines", "Pointe Coupee",
      "Rapides", "Red River", "Richland", "Sabine", "St. Bernard",
      "St. Charles", "St. Helena", "St. James", "St. John the Baptist",
      "St. Landry", "St. Martin", "St. Mary", "St. Tammany", "Tangipahoa",
      "Tensas", "Terrebonne", "Union", "Vermilion", "Vernon",
      "Washington", "Webster", "West Baton Rouge", "West Carroll",
      "West Feliciana", "Winn", "City of Monroe", "City of Bogalusa",
      "Zachary Community", "Central Community", "Baker",
      "Recovery School District", "Special School District", "Type 2 Charters",
      "State-Run Schools"
    ),
    stringsAsFactors = FALSE
  )
}


# ==============================================================================
# Tidy Format Functions
# ==============================================================================

#' Transform enrollment data to tidy (long) format
#'
#' Pivots wide enrollment data to long format with subgroup and grade_level
#' columns. This makes the data easier to analyze and filter.
#'
#' @param df Data frame in wide format from process_enr
#' @return Data frame in tidy format with columns:
#'   \item{end_year}{School year end}
#'   \item{type}{Row type: State, District, or Campus}
#'   \item{district_id}{3-digit parish code}
#'   \item{campus_id}{Site code (NA for district/state rows)}
#'   \item{district_name}{Parish name}
#'   \item{campus_name}{Site name (NA for district/state rows)}
#'   \item{subgroup}{Subgroup name (e.g., "total_enrollment", "male", "white")}
#'   \item{grade_level}{Grade level (e.g., "TOTAL", "K", "01", "02")}
#'   \item{n_students}{Student count for this subgroup/grade}
#' @export
#' @examples
#' \dontrun{
#' wide_data <- fetch_enr(2024, tidy = FALSE)
#' tidy_data <- tidy_enr(wide_data)
#' }
tidy_enr <- function(df) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  # ID columns that stay as-is
  id_cols <- c("end_year", "type", "district_id", "campus_id",
               "district_name", "campus_name")

  # Keep only ID columns that exist
  id_cols <- id_cols[id_cols %in% names(df)]

  # Create total enrollment rows
  total_rows <- NULL
  if ("row_total" %in% names(df)) {
    total_rows <- df[, id_cols, drop = FALSE]
    total_rows$subgroup <- "total_enrollment"
    total_rows$grade_level <- "TOTAL"
    total_rows$n_students <- df$row_total
  }

  # Create demographic subgroup rows
  demo_subgroups <- c("white", "black", "hispanic", "asian",
                      "pacific_islander", "native_american", "multiracial",
                      "minority")
  demo_rows <- purrr::map_dfr(demo_subgroups, function(sg) {
    if (sg %in% names(df)) {
      rows <- df[, id_cols, drop = FALSE]
      rows$subgroup <- sg
      rows$grade_level <- "TOTAL"
      rows$n_students <- df[[sg]]
      rows
    } else {
      NULL
    }
  })

  # Create gender subgroup rows
  gender_subgroups <- c("male", "female")
  gender_rows <- purrr::map_dfr(gender_subgroups, function(sg) {
    if (sg %in% names(df)) {
      rows <- df[, id_cols, drop = FALSE]
      rows$subgroup <- sg
      rows$grade_level <- "TOTAL"
      rows$n_students <- df[[sg]]
      rows
    } else {
      NULL
    }
  })

  # Create special population subgroup rows
  special_subgroups <- c("lep", "fep", "econ_disadv")
  special_rows <- purrr::map_dfr(special_subgroups, function(sg) {
    if (sg %in% names(df)) {
      rows <- df[, id_cols, drop = FALSE]
      rows$subgroup <- sg
      rows$grade_level <- "TOTAL"
      rows$n_students <- df[[sg]]
      rows
    } else {
      NULL
    }
  })

  # Create grade-level rows (for total enrollment by grade)
  grade_cols <- c("grade_infant", "grade_preschool", "grade_pk", "grade_k",
                  "grade_01", "grade_02", "grade_03", "grade_04",
                  "grade_05", "grade_06", "grade_07", "grade_08",
                  "grade_09", "grade_t9", "grade_10", "grade_11", "grade_12",
                  "grade_extension")

  grade_level_map <- c(
    grade_infant = "INF", grade_preschool = "PS", grade_pk = "PK", grade_k = "K",
    grade_01 = "01", grade_02 = "02", grade_03 = "03", grade_04 = "04",
    grade_05 = "05", grade_06 = "06", grade_07 = "07", grade_08 = "08",
    grade_09 = "09", grade_t9 = "T9", grade_10 = "10", grade_11 = "11", grade_12 = "12",
    grade_extension = "EXT"
  )

  grade_rows <- purrr::map_dfr(grade_cols, function(gc) {
    if (gc %in% names(df)) {
      rows <- df[, id_cols, drop = FALSE]
      rows$subgroup <- "total_enrollment"
      rows$grade_level <- grade_level_map[gc]
      rows$n_students <- df[[gc]]
      rows
    } else {
      NULL
    }
  })

  # Combine all rows
  result <- dplyr::bind_rows(total_rows, demo_rows, gender_rows, special_rows, grade_rows)

  # Remove rows with NA n_students
  result <- result[!is.na(result$n_students), ]

  result
}


#' Add aggregation level flags to enrollment data
#'
#' Adds boolean columns indicating whether each row is a state, district,
#' or campus level record.
#'
#' @param df Data frame from tidy_enr
#' @return Data frame with additional columns:
#'   \item{is_state}{TRUE if this is a state-level row}
#'   \item{is_district}{TRUE if this is a district-level row}
#'   \item{is_campus}{TRUE if this is a campus-level row}
#' @export
#' @examples
#' \dontrun{
#' enr <- fetch_enr(2024)
#' # Filter to state-level data
#' state_enr <- enr |> dplyr::filter(is_state)
#' }
id_enr_aggs <- function(df) {

  if (is.null(df) || nrow(df) == 0) {
    return(df)
  }

  df$is_state <- df$type == "State"
  df$is_district <- df$type == "District"
  df$is_campus <- df$type == "Campus"

  df
}


#' Create grade-level aggregations
#'
#' Creates summary rows by grade level bands (elementary, middle, high).
#'
#' @param df Data frame from tidy_enr
#' @return Data frame with additional grade band rows
#' @export
#' @keywords internal
enr_grade_aggs <- function(df) {

  if (is.null(df) || nrow(df) == 0) {
    return(df)
  }

  # Define grade bands
  elem_grades <- c("K", "01", "02", "03", "04", "05")
  middle_grades <- c("06", "07", "08")
  high_grades <- c("09", "10", "11", "12")

  # Get total enrollment rows by grade
  grade_data <- df[df$subgroup == "total_enrollment" &
                   df$grade_level != "TOTAL", ]

  if (nrow(grade_data) == 0) {
    return(df)
  }

  # Create elementary total
  elem_data <- grade_data[grade_data$grade_level %in% elem_grades, ]
  if (nrow(elem_data) > 0) {
    elem_agg <- elem_data |>
      dplyr::group_by(.data$end_year, .data$type, .data$district_id,
                      .data$campus_id, .data$district_name, .data$campus_name,
                      .data$subgroup) |>
      dplyr::summarize(n_students = sum(.data$n_students, na.rm = TRUE),
                       .groups = "drop") |>
      dplyr::mutate(grade_level = "ELEM")
    df <- dplyr::bind_rows(df, elem_agg)
  }

  # Create middle school total
  middle_data <- grade_data[grade_data$grade_level %in% middle_grades, ]
  if (nrow(middle_data) > 0) {
    middle_agg <- middle_data |>
      dplyr::group_by(.data$end_year, .data$type, .data$district_id,
                      .data$campus_id, .data$district_name, .data$campus_name,
                      .data$subgroup) |>
      dplyr::summarize(n_students = sum(.data$n_students, na.rm = TRUE),
                       .groups = "drop") |>
      dplyr::mutate(grade_level = "MIDDLE")
    df <- dplyr::bind_rows(df, middle_agg)
  }

  # Create high school total
  high_data <- grade_data[grade_data$grade_level %in% high_grades, ]
  if (nrow(high_data) > 0) {
    high_agg <- high_data |>
      dplyr::group_by(.data$end_year, .data$type, .data$district_id,
                      .data$campus_id, .data$district_name, .data$campus_name,
                      .data$subgroup) |>
      dplyr::summarize(n_students = sum(.data$n_students, na.rm = TRUE),
                       .groups = "drop") |>
      dplyr::mutate(grade_level = "HIGH")
    df <- dplyr::bind_rows(df, high_agg)
  }

  df
}


# ==============================================================================
# Caching Functions
# ==============================================================================

#' Get cache directory path
#'
#' Returns the path to the package cache directory.
#'
#' @return Path to cache directory
#' @keywords internal
get_cache_dir <- function() {
  cache_dir <- rappdirs::user_cache_dir("laschooldata")
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  cache_dir
}


#' Get cache file path for a year
#'
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy" or "wide")
#' @return Path to cache file
#' @keywords internal
get_cache_path <- function(end_year, cache_type = "tidy") {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0("la_enr_", end_year, "_", cache_type, ".rds"))
}


#' Check if cached data exists for a year
#'
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy" or "wide")
#' @return TRUE if cache exists
#' @keywords internal
cache_exists <- function(end_year, cache_type = "tidy") {
  file.exists(get_cache_path(end_year, cache_type))
}


#' Read cached data for a year
#'
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy" or "wide")
#' @return Cached data frame
#' @keywords internal
read_cache <- function(end_year, cache_type = "tidy") {
  readRDS(get_cache_path(end_year, cache_type))
}


#' Write data to cache for a year
#'
#' @param df Data frame to cache
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy" or "wide")
#' @keywords internal
write_cache <- function(df, end_year, cache_type = "tidy") {
  saveRDS(df, get_cache_path(end_year, cache_type))
}


#' View cache status
#'
#' Shows which years have cached data.
#'
#' @return Data frame with cache status for each year
#' @export
#' @examples
#' cache_status()
cache_status <- function() {
  years <- get_available_years()
  all_years <- years$min_year:years$max_year

  status <- data.frame(
    end_year = all_years,
    tidy_cached = sapply(all_years, function(y) cache_exists(y, "tidy")),
    wide_cached = sapply(all_years, function(y) cache_exists(y, "wide")),
    stringsAsFactors = FALSE
  )

  status
}


#' Clear cached data
#'
#' Removes cached data files.
#'
#' @param end_year Optional specific year to clear. If NULL, clears all.
#' @param cache_type Optional cache type to clear ("tidy", "wide"). If NULL, clears both.
#' @export
#' @examples
#' \dontrun{
#' # Clear all cached data
#' clear_cache()
#'
#' # Clear specific year
#' clear_cache(2024)
#'
#' # Clear only wide format cache
#' clear_cache(cache_type = "wide")
#' }
clear_cache <- function(end_year = NULL, cache_type = NULL) {

  cache_dir <- get_cache_dir()

  if (is.null(end_year)) {
    # Clear all years
    years <- get_available_years()
    all_years <- years$min_year:years$max_year
  } else {
    all_years <- end_year
  }

  if (is.null(cache_type)) {
    cache_types <- c("tidy", "wide")
  } else {
    cache_types <- cache_type
  }

  removed <- 0
  for (y in all_years) {
    for (ct in cache_types) {
      path <- get_cache_path(y, ct)
      if (file.exists(path)) {
        file.remove(path)
        removed <- removed + 1
      }
    }
  }

  message(paste("Removed", removed, "cached file(s)"))
  invisible(removed)
}

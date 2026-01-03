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
#'   \item{min_year}{First available year (2007)}
#'   \item{max_year}{Last available year (2024)}
#'   \item{description}{Description of data availability}
#' @export
#' @examples
#' years <- get_available_years()
#' print(years$min_year)
#' print(years$max_year)
get_available_years <- function() {
  list(
    min_year = 2007,
    max_year = 2024,
    description = paste(
      "Louisiana enrollment data from LDOE Multi Stats files.",
      "Available years: 2007-2024.",
      "Data for 2006 and earlier uses a different format and is not supported."
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

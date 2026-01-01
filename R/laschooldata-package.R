#' laschooldata: Fetch and Process Louisiana School Data
#'
#' Downloads and processes school data from the Louisiana Department of
#' Education (LDOE). Provides functions for fetching enrollment data from
#' Multi Stats reports and transforming it into tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Louisiana uses a parish-based ID system:
#' \itemize{
#'   \item District IDs (LEA): 3 digits representing parishes (e.g., 001 = Acadia)
#'   \item Site Codes: School-level identifiers within each LEA
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Louisiana Department of Education:
#' \itemize{
#'   \item Multi Stats: \url{https://www.louisianabelieves.com/resources/library/student-attributes}
#'   \item Data Center: \url{https://doe.louisiana.gov/data-and-reports/enrollment-data}
#' }
#'
#' @docType package
#' @name laschooldata-package
#' @aliases laschooldata
#' @keywords internal
"_PACKAGE"


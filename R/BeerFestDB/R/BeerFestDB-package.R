###############################################################################
#' Utility functions used to query and analyse dip data from the BeerFestDB
#' database
#' @description This is a package used to help manage the development of code
#'   used in generating sales reports and other analyses of the data stored in
#'   a BeerFestDB instance.
#' @details The primary function of interest is \code{\link{getFestivalData}},
#'   which retrieves all the dip data from a given festival and places it into
#'   a data frame suitable for subsequent analysis.  For a turn-key approach
#'   to such analyses, see \code{\link{analyseData}}.
#' @author Tim F. Rayner \email{tfrayner@@gmail.com}
#' @examples
#' \dontrun{
#'   baseuri  <- "http://localhost:3000"
#'   festname <- "38th Cambridge Beer Festival"
#'   prodcat  <- "beer"
#'
#'   cp <- getFestivalData(baseuri, festname, prodcat)
#'   write.csv(cp, "full_dip_dump.csv", row.names = FALSE)
#'
#'   analyseData(cp)
#' }
#' @keywords internal
"_PACKAGE"
###############################################################################

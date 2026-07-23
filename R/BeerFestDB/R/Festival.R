##
## This file is part of BeerFestDB, a beer festival product management
## system.
##
## Copyright (C) 2011-2026 Tim F. Rayner
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

###############################################################################
#' Festival data object
#'
#' @description An R6 class that wraps the data frame returned by
#'   [getFestivalData()] and provides structured access to cask metadata,
#'   product details, and dip measurements.
#'
#' @details The class separates the combined data frame into *metadata* columns
#'   (all columns whose names do **not** start with `"dip."`) and *dip* columns
#'   (all columns whose names start with `"dip."`).
#'
#'   Use `$subset()` to filter casks by any metadata attribute, returning a new
#'   `Festival` object so that calls can be chained.  Use `$cask_dips()` to
#'   retrieve the raw dip time-series for a single cask, and `$product_dips()`
#'   to obtain the column-summed dip volumes across all casks for a named
#'   product.
#'
#' @examples
#' \dontrun{
#' cp <- getFestivalData(baseuri, "My Fest", "Beer", auth = auth)
#' fest <- Festival$new(cp)
#'
#' # Inspect column sets
#' fest$meta_cols
#' fest$dip_cols
#'
#' # Subset to uncondemed casks in a particular region
#' sub <- fest$subset(is_condemned = 0, region = "West Midlands")
#'
#' # Dip time-series for all casks
#' fest$cask_dips()
#'
#' # Summed dip volumes for all products across all their casks
#' fest$product_dips()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom dplyr group_by summarise across select '%>%'
#' @export
###############################################################################
Festival <- R6::R6Class(
  "Festival",

  public = list(

    #' @field meta_cols Character vector of column names that are **not** dip
    #'   measurements (i.e., all columns whose names do not start with
    #'   `"dip."`).
    meta_cols = NULL,

    #' @description Create a new `Festival` object.
    #' @param data A data frame as returned by [getFestivalData()].  Must
    #'   contain at least a `festival_ref` column and at least one column whose
    #'   name starts with `"dip."`.
    #' @param dipnames Optional character vector of display names for the dip
    #'   columns.  If supplied, must have the same length as the number of dip
    #'   columns.  If not supplied, the `"dip."` prefix is removed from the dip
    #'   column names to create display names.
    initialize = function(data, dipnames = NULL) {
      if (!is.data.frame(data)) {
        stop("`data` must be a data frame (e.g. the output of getFestivalData()).")
      }
      if (!"festival_ref" %in% names(data)) {
        stop("`data` must contain a `festival_ref` column.")
      }
      if (!any(grepl("^dip\\.", names(data)))) {
        stop("`data` must contain at least one `dip.*` column.")
      }
      private$data <- data

      # Identify dip columns and rename them to remove the "dip." prefix
      private$dip_idx <- grep("^dip\\.", names(data))
      if (!is.null(dipnames)) {
        if (length(dipnames) != length(private$dip_idx)) {
          stop("`dipnames` must have the same length as the number of dip columns.")
        }
        names(private$dip_idx) <- dipnames
      } else {
        names(private$dip_idx) <- sub("^dip\\.", "", names(private$data)[private$dip_idx])
      }
      # Record metadata column names (all columns that are not dip columns)
      self$meta_cols <- setdiff(names(private$data), names(private$data)[private$dip_idx])
    },

    #' @description Subset casks by one or more metadata attributes.
    #'
    #'   Each named argument is matched against the corresponding column in
    #'   `$data`.  A row is retained when its value for **every** supplied
    #'   argument is contained in the argument's value vector (i.e., multiple
    #'   values are treated as an OR within a column, and columns are combined
    #'   with AND).  Dip column names are not valid filter keys.
    #'
    #' @param ... Named arguments whose names are non-dip column names and
    #'   whose values are the allowed value(s) for that column.
    #' @return A new `Festival` object containing only the matching rows.
    subset = function(...) {
      args <- list(...)
      if (length(args) == 0) {
        return(Festival$new(private$data))
      }
      dip_names <- grep("^dip\\.", names(private$data), value = TRUE)
      bad <- intersect(names(args), dip_names)
      if (length(bad) > 0) {
        stop("Cannot subset by dip column(s): ", paste(bad, collapse = ", "),
             ". Use `$cask_dips()` or `$product_dips()` for dip access.")
      }
      unknown <- setdiff(names(args), names(private$data))
      if (length(unknown) > 0) {
        stop("Unknown column(s): ", paste(unknown, collapse = ", "))
      }
      keep <- rep(TRUE, nrow(private$data))
      for (col in names(args)) {
        keep <- keep & (private$data[[col]] %in% args[[col]])
      }
      Festival$new(private$data[keep, , drop = FALSE])
    },

    #' @description Retrieve the dip time-series for a single cask.
    #' @return A data frame with one row per cask and one column per dip measurement
    #'   batch.  Names are c("festival_ref", "product_name", "company_name") followed by 
    #'   the dip column names.
    cask_dips = function() {
      w <- c("festival_ref", "product_name", "company_name")
      rows <- private$data[, c(w, self$dip_cols), drop = FALSE] %>%
        select(all_of(c(w, self$dip_cols)))
      return(private$remap_dip_names(rows))
    },

    #' @description Retrieve column-summed dip volumes for all casks belonging
    #'   to a named product.
    #' @return A data frame with one row per product and one column per dip measurement
    #'   batch.  Each value is the sum of that batch's dip volumes across all casks for
    #'   the product, ignoring `NA` values.  Names are c("product_name", "company_name")
    #'   followed by the dip column names.
    product_dips = function() {
      w <- c("product_name", "company_name")
      missing <- setdiff(w, names(private$data))
      if (length(missing) > 0) {
        stop("`data` is missing required column(s): ", paste(missing, collapse = ", "))
      }
      rows <- private$data %>%
        group_by(company_name, product_name) %>%
        summarise(across(all_of(self$dip_cols), sum, na.rm = TRUE), .groups = "drop") %>%
        select(all_of(c(w, self$dip_cols)))
      return(private$remap_dip_names(rows))
    }
  ),

  active = list(

    #' @field dip_cols Character vector of dip column names (all columns whose
    #'   names start with `"dip."`).
    dip_cols = function() {
      return(names(private$data)[private$dip_idx])
    },

    #' @field  stillages Character vector of unique stillage identifiers in the dataset.  
    stillages = function() {
      if (!"stillage" %in% names(private$data)) {
        stop("`data` does not contain a `stillage` column.")
      }
      return(unique(private$data$stillage))
    }
  ),

  private = list(
    # @field data The complete data frame as returned by [getFestivalData()],
    #   containing both metadata and `dip.*` columns.
    data = NULL,

    # @field dip_idx Integer vector of column indices for all dip columns. Names are the
    #   dip column names with the `"dip."` prefix removed.
    dip_idx = NULL,

    # @description Remap dip column names in a data frame to their corresponding
    #   display names stored in the `Festival` object (i.e., remove the `"dip."`
    #   prefix).  This is useful when creating plots using these datasets.
    # @param df A data frame containing dip columns
    # @return A data frame with dip column names remapped to their corresponding
    #   names in the `Festival` object.
    remap_dip_names = function(df) {
      if (!is.data.frame(df)) {
        stop("`df` must be a data frame.")
      }
      mapping <- setNames(names(private$dip_idx), names(private$data)[private$dip_idx])
      return(df %>% rename_with(~ mapping[.x], all_of(names(mapping))))
    }
  )
)

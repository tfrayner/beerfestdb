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
    initialize = function(data, dipnames = NULL, abv_breaks = c(2,3.5,4,4.5,5,7,12)) {
      if (!is.data.frame(data)) {
        stop("`data` must be a data frame (e.g. the output of getFestivalData()).")
      }
      if (!"festival_ref" %in% names(data)) {
        stop("`data` must contain a `festival_ref` column.")
      }
      if (!any(grepl("^dip\\.", names(data)))) {
        stop("`data` must contain at least one `dip.*` column.")
      }

      # Keep a record of this for subsetting support, and to create the abv_class column in the dataset
      private$abv_breaks <- abv_breaks

      # Identify dip columns and rename them to remove the "dip." prefix
      private$dip_idx <- grep("^dip\\.", names(data))
      if (!is.null(dipnames)) {
        if (length(dipnames) != length(private$dip_idx)) {
          stop("`dipnames` must have the same length as the number of dip columns.")
        }
        names(private$dip_idx) <- dipnames
      } else {
        names(private$dip_idx) <- sub("^dip\\.", "", names(data)[private$dip_idx])
      }
      # Record metadata column names (all columns that are not dip columns). This is used for subsetting
      # and for writing CSV output. Note that we drop the database cask_id column here as well.
      self$meta_cols <- c(setdiff(names(data), c(names(data)[private$dip_idx],
                                  c("cask_id", "volume_lost", "volume_sold", "abv_class"))),
                          c("volume_lost", "volume_sold", "abv_class"))

      # Some data cleanup: replace NA stillage with "Unassigned", truncate long stillage names, 
      # compute volume lost and volume sold
      data <- data %>%
        replace_na(list(stillage = "Unassigned")) %>%
        mutate(
          stillage = ifelse(nchar(stillage) > 15, paste0(substr(stillage, 1, 12), "..."), stillage)
        ) %>%
        rowwise() %>%
        mutate(volume_lost = c_across(starts_with("dip.")) %>% tail(1)) %>%
        ungroup() %>%
        mutate(volume_lost = ifelse(is_condemned == 1, cask_volume, volume_lost)) %>%
        mutate(volume_sold = cask_volume - volume_lost) %>%
        mutate(abv_class = cut(abv, breaks = private$abv_breaks))

      # Clean up the abv_class factor levels to remove parentheses and replace commas with " - "
      levels(data$abv_class) <- gsub('\\(|\\]', '', gsub(',',' - ',levels(data$abv_class)))

      private$.data <- data
    },

    #' @description Subset casks by a logical mask, named metadata attributes, or both.
    #'
    #'   If `.mask` is supplied it must be a logical vector of length
    #'   `nrow(self$data)`.  Any additional named arguments are matched against
    #'   the corresponding columns in `$data`: a row is retained when its value
    #'   for **every** supplied argument is contained in the argument's value
    #'   vector (i.e., multiple values are treated as OR within a column, and
    #'   columns are ANDed together).  The mask and named filters are ANDed
    #'   together.  Dip column names are not valid filter keys.
    #'
    #' @param .mask Optional logical vector of length `nrow(self$data)`.  Rows
    #'   corresponding to `TRUE` are retained.
    #' @param ... Named arguments whose names are non-dip column names and
    #'   whose values are the allowed value(s) for that column.
    #' @return A new `Festival` object containing only the matching rows.
    subset = function(.mask = NULL, ...) {
      args <- list(...)

      # Validate and apply the logical mask if supplied.
      if (!is.null(.mask)) {
        if (!is.logical(.mask)) {
          stop("`.mask` must be a logical vector.")
        }
        if (length(.mask) != nrow(private$.data)) {
          stop("`.mask` must have the same length as the number of rows in the data (",
               nrow(private$.data), ").")
        }
        keep <- .mask & !is.na(.mask)
      } else {
        keep <- rep(TRUE, nrow(private$.data))
      }

      if (length(args) == 0) {
        return(Festival$new(private$.data[keep, , drop = FALSE],
                            dipnames = names(private$dip_idx),
                            abv_breaks = private$abv_breaks))
      }
      dip_names <- grep("^dip\\.", names(private$.data), value = TRUE)
      bad <- intersect(names(args), dip_names)
      if (length(bad) > 0) {
        stop("Cannot subset by dip column(s): ", paste(bad, collapse = ", "),
             ". Use `$cask_dips()` or `$product_dips()` for dip access.")
      }
      unknown <- setdiff(names(args), names(private$.data))
      if (length(unknown) > 0) {
        stop("Unknown column(s): ", paste(unknown, collapse = ", "))
      }
      for (col in names(args)) {
        keep <- keep & (private$.data[[col]] %in% args[[col]])
      }
      Festival$new(private$.data[keep, , drop = FALSE],
                   dipnames = names(private$dip_idx),
                   abv_breaks = private$abv_breaks)
    },

    #' @description Retrieve the dip time-series for a single cask.
    #' @return A data frame with one row per cask and one column per dip measurement
    #'   batch.  Names are c("festival_ref", "product_name", "company_name") followed by 
    #'   the dip column names.
    cask_dips = function() {
      w <- c("festival_ref", "product_name", "company_name")
      rows <- private$.data[, c(w, self$dip_cols), drop = FALSE] %>%
        select(all_of(c(w, self$dip_cols)))
      return(private$remap_dip_names(rows))
    },

    #' @description Retrieve column-summed dip volumes for all casks belonging
    #'   to a named product.
    #' @return A data frame with one row per product and one column per dip measurement
    #'   batch.  Each value is the sum of that batch's dip volumes across all casks for
    #'   the product, ignoring `NA` values.  Names are c("product_name", "company_name")
    #'   followed by the dip column names.  This is a special case of `$grouped_dips()` 
    #'   where the grouping columns are the product name and company name.
    product_dips = function() {
      w <- c("product_name", "company_name")
      missing <- setdiff(w, names(private$.data))
      if (length(missing) > 0) {
        stop("`data` is missing required column(s): ", paste(missing, collapse = ", "))
      }
      rows <- private$.data %>%
        group_by(company_name, product_name) %>%
        summarise(across(all_of(self$dip_cols), sum, na.rm = TRUE), .groups = "drop") %>%
        select(all_of(c(w, self$dip_cols)))
      return(private$remap_dip_names(rows))
    },

    #' @description Retrieve column-summed dip volumes for all casks, grouped by one
    #'   or more metadata columns.
    #' @param group_cols Character vector of metadata column names to group by.
    #' @return A data frame with one row per group and one column per dip measurement
    #'   batch.  Each value is the sum of that batch's dip volumes across all
    #'   casks in the group, ignoring `NA` values.  Names are the grouping metadata 
    #'   columns followed by the dip column names.
    grouped_dips = function(group_cols) {
      if (!all(group_cols %in% self$meta_cols)) {
        stop("All `group_cols` must be metadata columns.")
      }
      rows <- private$.data %>%
        group_by(across(all_of(group_cols))) %>%
        summarise(across(all_of(self$dip_cols), sum, na.rm = TRUE), .groups = "drop") %>%
        select(all_of(c(group_cols, self$dip_cols)))
      return(private$remap_dip_names(rows))
    },

    #' @description Compute the per-diem sales volumes for all casks in the dataset.
    #' @return A data frame with one row per cask and one column per dip measurement
    #'   batch.  Each value is the difference between that batch's dip volume and the
    #'   previous batch's dip volume, rounded to 6 decimal places.  Names are
    #'   all the festival metadata columns followed by the dip column names.
    #' @param remap_names Logical; if `TRUE` (default), remap the dip column names 
    #'   to their display names (i.e., remove the `"dip."` prefix).
    per_diem_sales = function(remap_names = TRUE) {
      rows <- private$.data
      dip_cols <- c("cask_volume", self$dip_cols)
      pd <- round(rows[,dip_cols][,-length(dip_cols)] - rows[,dip_cols][,-1], 6)
      colnames(pd) <- self$dip_cols
      pd <- if (remap_names) private$remap_dip_names(pd) else pd
      if ( ! all(pd >= 0) ) {
        bad <- apply(pd, 1, function(x) any(x < 0))
        badstr <- paste(apply(rows[bad, c('company_name', 'product_name', 'festival_ref')], 1,
                        function(x) do.call('sprintf', as.list(c("%s %s (cask %s)", x)))), collapse=', ')
        stop(sprintf("Negative per diem dips found: probable dip data error in the database for the following: %s", badstr))
      }
      return(cbind(rows[, self$meta_cols, drop = FALSE], pd))
    },

    #' @description Compute the per-diem sales volumes for all casks in the dataset,
    #'   grouped by one or more metadata columns.
    #' @param group_cols Character vector of metadata column names to group by.
    #' @return A data frame with one row per group and one column per dip measurement
    #'   batch.  Each value is the sum of that batch's per-diem sales volumes across 
    #'   all casks in the group, ignoring `NA` values.  Names are the grouping metadata 
    #'   columns followed by the dip column names.
    grouped_per_diem_sales = function(group_cols) {
      if (!all(group_cols %in% self$meta_cols)) {
        stop("All `group_cols` must be metadata columns.")
      }
      pd <- self$per_diem_sales(remap_names = FALSE)
      pd_grouped <- pd %>%
        group_by(across(all_of(group_cols))) %>%
        summarise(across(all_of(self$dip_cols), sum, na.rm = TRUE), .groups = "drop")
      return(private$remap_dip_names(pd_grouped))
    },

    #' @description Write the complete dataset to a CSV file. Internally-computed columns
    #'   such as `volume_lost` and `volume_sold` are included, and the dip column 
    #'   names are remapped to their display names (i.e., the `"dip."` prefix is removed).
    #' @param file The path to the output CSV file.
    write_csv = function(file) {
      rows <- private$.data %>%
        select(all_of(c(self$meta_cols, self$dip_cols))) %>%
        private$remap_dip_names()
      write.csv(rows, file = file, row.names = FALSE)
    }
  ),

  active = list(

    #' @field data The complete data frame as returned by [getFestivalData()],
    #'   containing both metadata and `dip.*` columns.  The dip column names are
    #'   remapped to their display names (i.e., the `"dip."` prefix is removed).
    data = function() {
      return(private$.data %>% private$remap_dip_names())
    },

    #' @field dip_cols Character vector of dip column names (all columns whose
    #'   names start with `"dip."`).
    dip_cols = function() {
      return(names(private$.data)[private$dip_idx])
    },

    #' @field  stillages Character vector of unique stillage identifiers in the dataset.  
    stillages = function() {
      if (!"stillage" %in% names(private$.data)) {
        stop("`data` does not contain a `stillage` column.")
      }
      return(unique(private$.data$stillage))
    }
  ),

  private = list(
    # @field _data The complete data frame as returned by [getFestivalData()],
    #   containing both metadata and `dip.*` columns.
    .data = NULL,

    # @field dip_idx Integer vector of column indices for all dip columns. Names are the
    #   dip column names with the `"dip."` prefix removed.
    dip_idx = NULL,

    #' @field  abv_breaks Numeric vector of breakpoints for ABV classes.  Used to create 
    #'   the `abv_class` column in the dataset. Stored for subsetting support.
    abv_breaks = NULL,

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
      mapping <- setNames(names(private$dip_idx), names(private$.data)[private$dip_idx])
      return(df %>% rename_with(~ mapping[.x], all_of(names(mapping))))
    }
  )
)

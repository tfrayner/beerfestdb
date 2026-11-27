##
## This file is part of BeerFestDB, a beer festival product management
## system.
##
## Copyright (C) 2011 Tim F. Rayner
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
##
## $Id$

###############################################################################
#' Draw a pie chart of row counts from a given category
#' @description Takes a data frame and a column name, counts the number of
#'   rows in each category, and draws a pie chart illustrating the relative
#'   numbers of rows per category.  Categories that together account for less
#'   than 1\% of the total are collapsed into an \code{"Other"} slice.
#' @details The default output of \code{\link{getFestivalData}} lists dip
#'   measurements by cask.  To obtain counts of distinct products per category
#'   you should first aggregate the data frame as shown in the example below.
#' @param cp A data frame.
#' @param colname A character string naming the column in \code{cp} to tally.
#' @param cols A vector of colours used to fill the pie slices.  Expanded via
#'   \code{\link[grDevices]{colorRampPalette}} when more slices than colours
#'   are required.
#' @param radius Radius of the pie chart passed to
#'   \code{\link[graphics]{pie}}.
#' @param ... Additional arguments passed to \code{\link[graphics]{pie}}.
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @examples
#' \dontrun{
#'   cp <- getFestivalData(baseuri, festname, prodcat)
#'   byprod <- aggregate(cp[, c("region", "style")],
#'                       list(cp$company_name, cp$product_name), unique)
#'   drawPie(byprod, "region")
#' }
#' @seealso \code{\link{getFestivalData}}, \code{\link{analyseData}}
#' @importFrom grDevices colorRampPalette
#' @importFrom graphics pie
#' @importFrom RColorBrewer brewer.pal
#' @importFrom stats aggregate
#' @export
###############################################################################
drawPie <- function(cp, colname, cols = brewer.pal(9, "Set1"),
                    radius = 0.8, ...) {
  counts <- aggregate(rep(1, nrow(cp)), list(cp[, colname]), sum)

  w <- counts[, 2] / sum(counts[, 2]) < 0.01
  if (sum(w) > 0) {
    s <- sum(counts[w, 2])
    counts <- rbind(counts[!w, ], c("Other", s))
  }

  if (nrow(counts) > length(cols)) {
    cols <- colorRampPalette(cols)(nrow(counts))
  }

  pie(as.numeric(counts[, 2]),
    labels = counts[, 1],
    radius = radius, col = cols, ...
  )
}

################################################################################
#' Draw a pie chart of total volume from a given category
#' @description Takes a data frame and a column name, sums the total volume in
#'   each category, and draws a pie chart illustrating the relative total volume
#'   per category.  Categories that together account for less than 1\% of
#'   the total are collapsed into an \code{"Other"} slice.
#' @details The default output of \code{\link{getFestivalData}} lists dip
#'   measurements by cask.  To obtain total volume per category you should first
#'   aggregate the data frame as shown in the example below.
#' @param festival A data frame.
#' @param colname A character string naming the column in \code{festival$data} to tally.
#' @param cols A vector of colours used to fill the pie slices.  Expanded via
#'   \code{\link[grDevices]{colorRampPalette}} when more slices than colours are required.
#' @param radius Radius of the pie chart passed to
#'   \code{\link[graphics]{pie}}.
#' @param ... Additional arguments passed to \code{\link[graphics]{pie}}.
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @examples
#' \dontrun{
#'   festival <- getFestivalData(baseuri, festname, prodcat)
#'   drawPieByVolume(festival, "region")
#' }
#' @seealso \code{\link{getFestivalData}}, \code{\link{drawPie}}
#' @importFrom grDevices colorRampPalette
#' @importFrom graphics pie
#' @importFrom RColorBrewer brewer.pal
#' @importFrom stats aggregate
#' @export
################################################################################
drawPieByVolume <- function(festival, colname, cols = brewer.pal(9, "Set1"),
                    radius = 0.8, ...) {
  counts <- aggregate(festival$data$cask_volume, list(festival$data[[colname]]), sum)

  w <- counts[, 2] / sum(counts[, 2]) < 0.01
  if (sum(w) > 0) {
    s <- sum(counts[w, 2])
    counts <- rbind(counts[!w, ], c("Other", s))
  }

  if (nrow(counts) > length(cols)) {
    cols <- colorRampPalette(cols)(nrow(counts))
  }

  pie(as.numeric(counts[, 2]),
    labels = counts[, 1],
    radius = radius, col = cols, ...
  )
}
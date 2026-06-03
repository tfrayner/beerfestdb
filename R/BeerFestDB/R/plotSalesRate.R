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
#' Plot sales rates for a given set of categories over time
#' @description Aggregates cask volume data by \code{colname}, normalises
#'   each group to its starting volume, and calls \code{\link{plotFractions}}
#'   to display the fraction-remaining profile over time for each group.
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param colname A character string naming the column in \code{cp} to use
#'   as the grouping variable (e.g., \code{"region"}, \code{"style"}).
#' @param w A logical vector selecting the volume and dip columns of
#'   \code{cp}.
#' @param ... Additional arguments passed to \code{\link{plotFractions}}.
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @seealso \code{\link{plotFractions}}, \code{\link{aggData}},
#'   \code{\link{analyseData}}
#' @importFrom RColorBrewer brewer.pal
#' @export
###############################################################################
plotSalesRate <- function(cp, colname, w = TRUE, ...) {
  dp <- aggData(cp, colname, w)
  cols <- brewer.pal(9, "Set1")
  plotFractions(dp / dp[, 1], cols = cols, ...)
}

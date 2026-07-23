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
##
## $Id$

###############################################################################
#' Plot sales rates for a given set of categories over time
#' @description Aggregates cask volume data by \code{colname}, normalises
#'   each group to its starting volume, and calls \code{\link{plotFractions}}
#'   to display the fraction-remaining profile over time for each group.
#' @param festival A data frame of cask/dip data, typically from the `data` slot of a Festival object returned by
#'   \code{\link{getFestivalData}}.
#' @param colname A character string naming the column in \code{festival$data} to use
#'   as the grouping variable (e.g., \code{"region"}, \code{"style"}).
#' @param ... Additional arguments passed to \code{\link{plotFractions}}.
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @seealso \code{\link{plotFractions}}, \code{\link{aggData}},
#'   \code{\link{analyseData}}
#' @importFrom RColorBrewer brewer.pal
#' @export
###############################################################################
plotSalesRate <- function(festival, colname, ...) {

  festival <- with(festival$data, festival$subset(!is.na(get(colname))))

  dp <- festival$grouped_per_diem_sales(colname) %>% 
    column_to_rownames(colname)

  start <- festival$data %>%
    group_by(get(colname)) %>%
    summarise(start = sum(cask_volume, na.rm = TRUE)) %>%
    column_to_rownames('get(colname)')

  cols <- brewer.pal(9, "Set1")

  plotFractions(dp / start[rownames(dp), "start"], cols = cols, ylim = c(0, NA), ylab = "Fraction Sold", ...)
}

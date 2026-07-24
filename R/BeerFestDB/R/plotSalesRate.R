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
#' @seealso \code{\link{plotFractions}}, \code{\link{analyseData}}
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

  plotFractions(dp / start[rownames(dp), "start"], ylim = c(0, NA), ylab = "Fraction Sold", ...)
}

###############################################################################
#' Draw a heatmap of sales rates for a given set of categories over time
#' @description Aggregates cask volume data by \code{colname}, scales the data
#'   for each group to the same mean and variance, and draws a heatmap of the
#'   result showing which sessions were outliers for each group.
#' @param festival A data frame of cask/dip data, typically from the `data` slot of a Festival object returned by
#'   \code{\link{getFestivalData}}.
#' @param colname A character string naming the column in \code{festival$data} to use
#'   as the grouping variable (e.g., \code{"region"}, \code{"style"}).
#' @return Invisibly returns \code{NULL} (called for its side effect of producing a plot).
#' @seealso \code{\link{plotSalesRate}}, \code{\link{analyseData}}
#' @importFrom ggplot2 ggplot aes geom_tile scale_fill_gradient2 labs theme theme_minimal ggtitle element_text
#' @importFrom reshape2 melt
#' @importFrom tibble column_to_rownames
#' @export
###############################################################################
plotSalesHeatmap <- function(festival, colname) {

  festival <- with(festival$data, festival$subset(!is.na(get(colname))))

  dp <- festival$grouped_per_diem_sales(colname) %>% 
    column_to_rownames(colname)

  ggplot(reshape2::melt(t(scale(t(dp)))), aes(x=as.numeric(Var2), y=Var1, fill=value)) +
    geom_tile() + scale_fill_gradient2(low="blue", mid="white", high="red", midpoint=0) +
    scale_x_continuous(breaks=1:ncol(dp), labels=colnames(dp)) +
    labs(x='Festival Day', y='Volume Sold (gallons)') +
    theme_minimal() +
    theme(legend.position='right', legend.title=element_text(size=12), legend.text=element_text(size=10))
}

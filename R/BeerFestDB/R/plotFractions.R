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
#' Plot the fraction of product remaining over time
#' @description Draws a multi-line chart showing the fraction of the starting
#'   volume remaining at each dip time for each group (cluster).  Typically
#'   called via \code{\link{plotSalesRate}} rather than directly.
#' @param data A matrix or data frame with groups as rows and dip times as
#'   columns.  Typically the output of \code{Festival$grouped_per_diem_sales()} divided by its
#'   first column.
#' @param clusters Character vector of row names from \code{data} to include
#'   in the plot.  Defaults to all rows.
#' @param cols A vector of colours, one per cluster.  Expanded via
#'   \code{\link[grDevices]{colorRampPalette}} when more clusters than colours
#'   are present.
#' @param lty Line-type vector (recycled as needed by
#'   \code{\link[graphics]{matplot}}).
#' @param ylim Numeric vector of length two giving the y-axis limits.
#' @param ylab Y-axis label.
#' @param ... Additional arguments passed to \code{\link[graphics]{matplot}}.
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @seealso \code{\link{Festival}}, \code{\link{plotSalesRate}}
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @importFrom ggplot2 ggplot aes geom_line scale_color_manual labs theme_minimal theme element_text
#' @importFrom dplyr filter
#' @importFrom tibble rownames_to_column
#' @importFrom reshape2 melt
#' @export
###############################################################################
plotFractions <- function(data, clusters = rownames(data),
                          cols = brewer.pal(9, "Set1"), lty = 1:9,
                          ylim = c(0, 1),
                          ylab = "Fraction remaining", ...) {
  
  if (length(clusters) > length(cols)) {
    cols <- colorRampPalette(cols)(length(clusters))
  }

  as.data.frame(data) %>%
    rownames_to_column(var = "cluster") %>%
    filter(cluster %in% clusters) %>%
    reshape2::melt(id.vars = "cluster", variable.name = "time", value.name = "fraction") %>%
    ggplot(aes(x = time, y = fraction, group = cluster, colour = cluster)) +
    geom_line(size = 2) +
    scale_color_manual(values = cols) +
    labs(x = "Dip Time", y = ylab, colour = "Cluster") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          axis.title = element_text(size = 14),
          legend.title = element_text(size = 12),
          legend.text = element_text(size = 10)) +
    ylim(ylim)
}

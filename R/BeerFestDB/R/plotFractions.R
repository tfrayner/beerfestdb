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
#' Plot the fraction of product remaining over time
#' @description Draws a multi-line chart showing the fraction of the starting
#'   volume remaining at each dip time for each group (cluster).  Typically
#'   called via \code{\link{plotSalesRate}} rather than directly.
#' @param data A matrix or data frame with groups as rows and dip times as
#'   columns.  Typically the output of \code{\link{aggData}} divided by its
#'   first column.
#' @param clusters Character vector of row names from \code{data} to include
#'   in the plot.  Defaults to all rows.
#' @param cols A vector of colours, one per cluster.  Expanded via
#'   \code{\link[grDevices]{colorRampPalette}} when more clusters than colours
#'   are present.
#' @param lty Line-type vector (recycled as needed by
#'   \code{\link[graphics]{matplot}}).
#' @param ylim Numeric vector of length two giving the y-axis limits.
#' @param leg.pos Position keyword for the legend, passed to
#'   \code{\link[graphics]{legend}}.
#' @param ylab Y-axis label.
#' @param ... Additional arguments passed to \code{\link[graphics]{matplot}}.
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @seealso \code{\link{plotSalesRate}}, \code{\link{aggData}}
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @importFrom graphics matplot axis legend
#' @export
###############################################################################
plotFractions <- function(data, clusters = rownames(data),
                          cols = brewer.pal(9, "Set1"), lty = 1:9,
                          ylim = c(0, 1),
                          leg.pos = "bottomleft",
                          ylab = "Fraction remaining", ...) {
  if (length(clusters) > length(cols)) {
    cols <- colorRampPalette(cols)(length(clusters))
  }

  matplot(
    t(data[clusters, , drop = FALSE]),
    col = cols,
    type = "l", lwd = 2, lty = lty, ylim = ylim, axes = FALSE,
    xlab = "Dip Time", ylab = ylab, cex.lab = 1.5, cex.main = 1.5, ...
  )

  axis(2, cex.axis = 1.5)

  axis(1, cex.axis = 1.5, labels = colnames(data), at = 1:ncol(data))

  legend(leg.pos, legend = clusters, fill = cols, cex = 1.3)
}

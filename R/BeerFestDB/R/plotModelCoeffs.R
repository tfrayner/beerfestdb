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
#' Plot a bar chart comparing starting quantities with observed sales rates
#' @description Fits a linear model of cumulative sales as a function of dip
#'   time and category, then draws a horizontal grouped bar chart comparing
#'   each category's observed sale-rate share with the share predicted from
#'   its starting volume.
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param colname A character string naming the column in \code{cp} to use
#'   as the grouping category (e.g., \code{"style"}, \code{"region"}).
#' @param drop A character vector of dip-time column names to exclude from
#'   the model (typically the final sessions where sales become non-linear).
#' @param w A logical vector selecting the volume and dip columns of
#'   \code{cp}.
#' @param ... Additional arguments (currently unused).
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @seealso \code{\link{aggData}}, \code{\link{analyseData}}
#' @importFrom graphics barplot text par
#' @importFrom stats aggregate lm
#' @export
###############################################################################
plotModelCoeffs <- function(cp, colname, drop, w = TRUE, ...) {
  pred <- aggregate(cp$cask_volume, list(cp[, colname]), sum)[, 2]
  pred <- (pred / sum(pred)) * 100

  dp <- aggData(cp, colname, w)
  dp <- dp[, !colnames(dp) %in% drop]
  dp <- dp$Start - dp

  fm <- data.frame(
    dip = as.numeric(t(dp)),
    time = rep(0:(ncol(dp) - 1), nrow(dp)),
    category = factor(unlist(lapply(rownames(dp), rep, ncol(dp))))
  )

  ## We're looking for the time:category interaction term
  ## here.
  l <- lm(dip ~ time * category, data = fm)

  ## FIXME consider also using the std. error estimates to generate error bars.

  ncat <- nlevels(fm$category)
  x <- l$coefficients
  x <- c(x[2], x[(ncat + 2):(2 * ncat)] + x[2])
  x <- (x / sum(x)) * 100
  names(x) <- levels(fm$category)

  old.par <- par(mar = c(5, 12, 2, 2))
  bp <- barplot(rbind(x, pred),
    beside = TRUE, ylab = "", yaxt = "n", horiz = TRUE,
    xlab = "Percent total", legend.text = c("Observed", "Predicted"),
    args.legend = list(x = "topright", cex = 1.2), col = c("blue", "yellow"),
    cex.axis = 1.5, cex.lab = 1.5
  )
  text(y = apply(bp, 2, mean), labels = names(x),
       x = par("usr")[1] - 1.5, adj = 1, xpd = TRUE, cex = 1.5)
  par(old.par)
}

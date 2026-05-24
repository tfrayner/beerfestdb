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
#' Rank products by their observed sale rate (experimental)
#' @description Estimates the sale rate for each active cask using a linear
#'   model, averages the per-cask rates by product, and returns products
#'   sorted from slowest to fastest seller.  This is quite experimental due
#'   to the complexities of determining a sale rate from sparse data affected
#'   by multiple confounding factors.
#' @details Casks that show no change over the query period are excluded
#'   before fitting.  Each cask's rate is estimated independently via
#'   \code{\link{productSaleRate}} and then averaged across all casks of the
#'   same product.  The \code{drop} argument is used to exclude the final
#'   sessions of the festival, where sales typically become non-linear.
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param drop A character vector of dip-time column names to exclude from
#'   the analysis (typically the last sessions of the festival).
#' @param w A logical vector selecting the volume and dip columns of
#'   \code{cp}.
#' @return A data frame with one row per product, sorted ascending by
#'   \code{gallons_per_session}.  Columns: \code{company_name},
#'   \code{product_name}, \code{style}, \code{abv},
#'   \code{gallons_per_session}.
#' @seealso \code{\link{productSaleRate}}, \code{\link{analyseData}}
#' @importFrom dplyr %>% group_by summarise arrange
#' @importFrom stats lm aggregate
#' @export
###############################################################################
rankProducts <- function(cp, drop, w) {
  ## Doesn't work very well since occasionally a cask gets held back.
  #    byprod <- aggData(cp, c('company_name','product_name'))
  #    rates <- as.data.frame(t(apply(byprod, 1, productSaleRate)))

  ## Better approach: once a cask is started, it's not usually held
  ## back any further. Get sales rates per cask and average
  ## them. This also works most believably if we drop the last part
  ## of the festival; note that some beers lose out in this case.
  x <- cp[, w]
  x <- x[, !colnames(x) %in% drop]
  x <- cbind(cp[, c("company_name", "product_name", "style", "abv")], x)

  ## Have to throw out all those beers which never changed in the query period.
  x <- x[apply(x[, -c(1:4)], 1, function(x) {
    sum(x != x[1])
  }) != 0, ]

  z <- as.data.frame(t(apply(x[, -c(1:4)], 1, productSaleRate)))
  z <- aggregate(z$Estimate, list(x$company_name, x$product_name, x$style, x$abv), mean)
  z <- z[order(z$x), ]

  colnames(z) <- c("company_name", "product_name", "style", "abv", "gallons_per_session")

  return(z)
}

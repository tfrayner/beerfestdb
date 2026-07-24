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
#' Calculate the sale rate for a single cask using a linear model
#' @description Estimates the sale rate (gallons per session) for a single
#'   cask by fitting a linear model to its trimmed, normalised dip readings.
#'   Leading and trailing non-sale plateaux are removed before fitting.
#'   Used internally by \code{\link{rankProducts}}.
#' @param y A numeric vector of dip readings (volume remaining in gallons)
#'   for a single cask, ordered by measurement session.
#' @return A named numeric vector with two elements:
#'   \describe{
#'     \item{Estimate}{Estimated gallons sold per session (positive).}
#'     \item{Std. Error}{Standard error of the estimate from \code{\link[stats]{lm}}.}
#'   }
#' @seealso \code{\link{rankProducts}}
#' @importFrom stats lm
#' @export
###############################################################################
caskSaleRate <- function(y) {

  .trimPlateau <- function(y) c(y[1], y[y != y[1]])

  ## Trim off initial non-sale plateau.
  y <- .trimPlateau(y)

  ## Trim off trailing non-sale plateau.
  y <- rev(.trimPlateau(rev(y)))

  # Number of sessions, starting at zero.
  m <- 1:length(y) - 1

  ## Fit a linear model to the trimmed, normalised data: slope represents -(gallons sold per session).
  l <- lm(y ~ m)

  ## Return Estimate and Std. Error values from the model summary, with the sign 
  ## of the Estimate reversed to give a positive gallons-per-session value. 
  suppressWarnings(r <- summary(l)$coefficients[-1, c(1, 2)])
  return(c(-r[1], r[2]))
}

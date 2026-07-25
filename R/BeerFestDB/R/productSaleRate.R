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

.trimData <- function(y) {

  ## Round to 2 decimal places to avoid floating point issues when comparing
  ## values. Measurement precision is 1 d.p. at best in any case.
  .trimPlateau <- function(y) c(y[1], y[round(y,2) != round(y[1],2)])

  ## Trim off initial non-sale plateau.
  y <- .trimPlateau(y)

  ## Trim off trailing non-sale plateau.
  y <- rev(.trimPlateau(rev(y)))

  return(y)
}

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
#' @seealso \code{\link{rankProducts}}, \code{\link{productSaleRate}}
#' @importFrom stats lm
#' @export
###############################################################################
caskSaleRate <- function(y) {

  y <- .trimData(y)

  # Number of sessions, starting at zero.
  m <- 1:length(y) - 1

  ## Fit a linear model to the trimmed, normalised data: slope represents -(gallons sold per session).
  l <- lm(y ~ m)

  ## Return Estimate and Std. Error values from the model summary, with the sign 
  ## of the Estimate reversed to give a positive gallons-per-session value. 
  suppressWarnings(r <- summary(l)$coefficients[-1, c(1, 2)])
  return(c(-r[1], r[2]))
}

################################################################################
#' Calculate the sale rate from product dips across multiple casks
#' @description Estimates the sale rate (gallons per session) for a single
#'   product by fitting a linear model to its trimmed, normalised dip readings
#'   across multiple casks.  Leading and trailing non-sale plateaux are removed
#'   before fitting. 
#' @details The behaviour of this function differs from \code{\link{caskSaleRate}}
#'   in that it operates on a data frame of multiple casks, rather than a single cask.
#'   The consequence of this is that the results tend to be more influenced by slow-selling 
#'   casks for which there are more dip measurements. This is often not what we want,
#'   so treat the results of this function with caution.
#' @param df A data frame containing a column of cask volumes and one or more
#'   columns of dip readings (volume remaining in gallons) for each cask, ordered
#'   by measurement session.
#' @param dip_cols A character vector of column names in \code{df} containing
#'   the dip readings to be used in the analysis.
#' @return A numeric value representing the estimated gallons sold per session
#'   (positive).
#' @seealso \code{\link{rankProducts}}, \code{\link{caskSaleRate}}
#' @importFrom dplyr select all_of group_by mutate ungroup n
#' @importFrom reshape2 melt
#' @importFrom stats lm coef
#' @export
################################################################################
productSaleRate <- function(df, dip_cols) {

  df <- df %>%
    select(all_of(c('cask_volume', dip_cols)))
  
  ## Trim the data to remove casks which were never put on sale,
  ## trim leading and trailing non-sale plateaux, then reshape
  ## to long format and add a time column for the linear model.
  df <- df %>%
    subset(apply(df, 1, function(x) round(sum(x[1]-x),2) != 0))  # non-sale casks
    
  if (nrow(df) == 0) return(NA)
  if (nrow(df) < 2) return(caskSaleRate(as.numeric(df[1,]))[['Estimate']])

  df <- df %>%
    t() %>% as.data.frame() %>%
    lapply(.trimData) %>%  # plateau trimming
    reshape2::melt() %>%
    group_by(L1) %>%  # L1 is a cask ID
    mutate(time = seq_len(n())) %>%
    ungroup()

  df[['L1']] <- as.factor(df[['L1']])
  
  l <- lm(value ~ L1 + time, data = df)
  
  rate <- -coef(l)['time']
  
  return(as.numeric(round(rate, 2)))
}

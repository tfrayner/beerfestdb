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
#' Aggregate dip data by a given factor
#' @description Aggregates (sums) the columns of \code{cp} selected by the
#'   logical vector \code{w}, grouped by one or more named columns.  Grouping
#'   columns are dropped from the result, row names are set to the pasted
#'   group-key values, and the first aggregated column is renamed
#'   \code{"Start"}.
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param group A character vector of one or more column names in \code{cp}
#'   to use as grouping variables.
#' @param w A vector selecting the columns to aggregate. May be a logical
#'  vector of the same length as \code{ncol(cp)}, or a character vector of
#'  column names in \code{cp}.  Defaults to \code{TRUE} (all columns).
#' @return A data frame with one row per unique group.  Row names are the
#'   pasted group-key values (separated by \code{":"}), grouping columns are
#'   absent, and the first column is named \code{"Start"}.
#' @seealso \code{\link{getFestivalData}}, \code{\link{plotSalesRate}},
#'   \code{\link{plotModelCoeffs}}
#' @importFrom stats aggregate
#' @export
###############################################################################
aggData <- function(cp, group, w = TRUE) {
  dp <- aggregate(cp[, w], cp[, group], sum)

  rownames(dp) <- apply(dp[, c(1:length(group)), drop = FALSE], 1,
                        paste, collapse = ":")
  dp <- dp[, -c(1:length(group)), drop = FALSE]
  colnames(dp)[1] <- "Start"

  return(dp)
}

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
#' Retrieve the dip figures for a given cask
#' @description Retrieves the dip (volume) readings for a single cask from
#'   the BeerFestDB JSON API, keyed by measurement-batch ID.
#' @param baseuri Base URI of the BeerFestDB web application
#'   (e.g., \code{"https://example.org/bfdb"}).
#' @param id Integer cask ID.
#' @param auth Authentication object: a \code{CURLHandle} with a live
#'   session, a list with elements \code{username} and \code{password}, or
#'   \code{NULL} to prompt interactively.
#' @param .opts Named list of additional options forwarded to
#'   \code{\link[RCurl]{curlPerform}}.
#' @return A named list mapping measurement-batch IDs (as character strings)
#'   to the recorded volume in gallons.
#' @seealso \code{\link{getFestivalData}}, \code{\link{queryBFDB}}
#' @export
###############################################################################
retrieveDips <- function(baseuri, id, auth = NULL, .opts = list()) {
  if (is.null(auth) || !inherits(auth, "CURLHandle")) {
    auth <- .getBFDBHandle(baseuri = baseuri, auth = auth, .opts = .opts)
  }

  objects <- queryBFDB("Cask", "list_dips", id,
    baseuri = baseuri, auth = auth, .opts = .opts
  )

  return(objects)
}

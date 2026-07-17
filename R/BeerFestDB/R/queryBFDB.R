##
## This file is part of BeerFestDB, a beer festival product management
## system.
##
## Copyright (C) 2011-2025 Tim F. Rayner
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
## $Id$

###############################################################################
#' Query the BeerFestDB JSON API and return a normalised data frame
#' @description Calls \code{\link{queryBFDB}} with the supplied object class
#'   and action, then converts the resulting list of records into a regular
#'   character data frame.  Any column whose name ends in \code{_id} is
#'   coerced to integer.  Fields absent from some records are padded with
#'   \code{NA}.
#' @param dbclass Character string naming the BeerFestDB object class to
#'   query (e.g., \code{"Cask"}, \code{"Festival"}, \code{"Company"}).
#' @param action Character string naming the API action
#'   (e.g., \code{"list"}, \code{"list_by_festival"}).
#' @param params Optional numeric or character vector of path parameters
#'   appended to the request URI (e.g., a festival ID).
#' @param columns Optional character vector of column names to retain.  An
#'   error is raised if any requested column is absent from the API response.
#' @param auth Authentication object: a \code{CURLHandle} with a live
#'   session, a list with elements \code{username} and \code{password}, or
#'   \code{NULL} to prompt interactively.  When \code{auth} is not a
#'   \code{CURLHandle} the \code{baseuri} argument must also be supplied.
#' @param .opts Named list of additional options forwarded to
#'   \code{\link[RCurl]{curlPerform}}.
#' @param ... Additional arguments passed to \code{\link{queryBFDB}}.
#' @return A data frame with one row per API record.  All columns are
#'   character except those whose names end in \code{_id}, which are integer.
#' @seealso \code{\link{queryBFDB}}, \code{\link{getFestivalData}}
#' @export
###############################################################################
getBFData <- function(dbclass, action, params = c(), columns = NULL,
                      auth, .opts = list(), ...) {
  objects <- queryBFDB(dbclass, action, params, auth, .opts, ...)

  terms <- sort(Reduce(union, sapply(objects, names)))
  cleaned <- lapply(objects, function(x) {
    w <- terms[!terms %in% names(x)]
    v <- rep(NA_character_, length(w))
    names(v) <- w
    x <- c(x, v)
    x <- x[terms]
    ## Convert each element to a character scalar so that do.call(rbind, ...)
    ## produces a character matrix rather than a list-matrix, preserving NAs.
    vapply(x, function(el) {
      if (is.null(el) || (length(el) == 1L && is.na(el))) {
        NA_character_
      } else {
        as.character(el)[[1L]]
      }
    }, character(1L))
  })

  res <- as.data.frame(do.call("rbind", cleaned), stringsAsFactors = FALSE)
  if (ncol(res) > 0) {
    for (n in 1:ncol(res)) res[, n] <- as.character(res[, n])
  }

  for (x in colnames(res)) {
    if (grepl("_id$", x)) {
      suppressWarnings(res[, x] <- as.integer(res[, x]))
    }
  }

  if (!is.null(columns)) {
    if (nrow(res) > 0) {
      if (!all(columns %in% colnames(res))) {
        stop(sprintf(
          "Unexpected BFDB query result from class %s, action %s; missing columns: %s",
          dbclass, action,
          paste(setdiff(columns, colnames(res)), collapse = ", ")
        ))
      }
      res <- res[, columns]
    } else {
      res <- as.data.frame(matrix(
        nrow = 0,
        ncol = length(columns),
        dimnames = list(NULL, columns)
      ))
    }
  }

  return(res)
}

###############################################################################
#' Query the BeerFestDB database via JSON API
#' @description S4 generic that issues an HTTP request to the BeerFestDB JSON
#'   API and returns the \code{objects} list from the response.  Dispatch is
#'   on the class of \code{auth}: supply a \code{CURLHandle} for an existing
#'   authenticated session, or a list / \code{NULL} / missing \code{auth}
#'   together with a \code{baseuri} character string to authenticate
#'   automatically.
#' @param dbclass Character string naming the BeerFestDB object class
#'   (e.g., \code{"Cask"}).
#' @param action Character string naming the API action
#'   (e.g., \code{"list"}).
#' @param params Optional numeric or character vector of additional path
#'   parameters.
#' @param auth Authentication object; see Description for dispatch details.
#' @param .opts Named list of options forwarded to
#'   \code{\link[RCurl]{curlPerform}}.
#' @param ... Additional arguments (reserved for future use).
#' @return A list of named lists, one element per API record.
#' @seealso \code{\link{getBFData}}, \code{\link{getFestivalData}}
#' @import methods
#' @export
###############################################################################
setGeneric("queryBFDB", def = function(dbclass, action, params = c(),
                                       auth, .opts = list(), ...)
  standardGeneric("queryBFDB")
)

################################################################################
#' queryBFDB method where auth=CURLHandle
#' @importFrom rjson fromJSON toJSON
#' @importFrom RCurl curlPerform getCurlHandle curlSetOpt
#'  basicTextGatherer curlEscape
#' @inherit queryBFDB
#' @param auth A \code{CURLHandle} object representing an authenticated session.
setMethod(
  "queryBFDB", signature(auth = "CURLHandle"),
  function(dbclass, action, params = c(),
           auth, .opts = list(), ...) {
    # Assumes that all JSON query actions in the web server behave
    # roughly the same; i.e. they act on a set of (usually only one or
    # two) numeric parameters which will be encoded in the query URI,
    # and return JSON with a 'success' flag attribute, an 'message'
    # attribute where necessary, and the actual returned data in an
    # 'objects' attribute. Returns just the objects list.

    if (!is.list(.opts)) {
      stop("Error: .opts must be a list object")
    }

    ## Workaround for a known SSL session reuse bug
    ## ("SSL3_GET_RECORD:bad decompression"). Presumably this would
    ## also be fixable on the server, but it doesn't hurt to have a
    ## fix here as well.
    if (is.null(.opts$ssl.sessionid.cache)) {
      .opts$ssl.sessionid.cache <- FALSE
    }

    baseuri <- attr(auth, "baseuri")
    if (is.null(baseuri)) {
      stop("CURLHandle object must have an additional baseuri attribute set.")
    }

    uri <- paste(baseuri, tolower(dbclass), action, sep = "/")
    if (!missing(params)) {
      uri <- paste(c(uri, params), collapse = "/")
    }

    ## Run the query.
    status <- RCurl::basicTextGatherer()
    res <- RCurl::curlPerform(
      url = uri,
      .opts = .opts,
      curl = auth,
      writefunction = status$update
    )

    ## Check the response for errors.
    rc <- try(status <- rjson::fromJSON(status$value()))

    if (inherits(rc, "try-error")) {
      stop(sprintf("Error encountered: %s", rc))
    }

    if (!isTRUE(status$success)) {
      stop(status$message)
    }

    return(status$objects)
  }
)

################################################################################
#' queryBFDB method where auth is a list of credentials, missing or NULL; baseuri 
#'   is required in any of these cases.
#' @inherit queryBFDB
#' @param baseuri Base URI of the BeerFestDB web application.  Required
#'   unless \code{auth} is a \code{CURLHandle}.
setMethod(
  "queryBFDB", signature(auth = "ANY"),
  function(dbclass, action, params = c(),
           auth = NULL, .opts = list(), baseuri = NULL, ...) {

    if (is.null(baseuri)) {
      stop("Error: baseuri argument is required unless using CURLHandle-based authentication.")
    }

    curl <- .getBFDBHandle(baseuri = baseuri, auth = auth, .opts = .opts)

    response <- queryBFDB(dbclass, action, params, auth = curl, .opts = .opts, ...)

    ## Log out for the sake of completeness (check for failure and warn).
    .logoutBFDBHandle(curl, .opts)

    return(response)
  }
)

################################################################################
#' Return a CURLHandle object which contains details for a logged-in BFDB session.
#' @importFrom rjson fromJSON toJSON
#' @importFrom RCurl curlPerform getCurlHandle curlSetOpt
#'  basicTextGatherer curlEscape
#' @param baseuri Base URI of the BeerFestDB web application.  Required.
#' @param auth Authentication object: a list with elements \code{username} and
#'   \code{password}, or \code{NULL} to prompt interactively.
#' @param .opts Named list of additional options forwarded to
#'   \code{\link[RCurl]{curlPerform}}.
#' @return A \code{CURLHandle} object representing an authenticated session.
.getBFDBHandle <- function(baseuri = NULL, auth, .opts = list()) {
  if (is.null(baseuri)) {
    stop("Error: baseuri argument must be provided.")
  }

  if (!is.list(.opts)) {
    stop("Error: .opts must be a list object")
  }

  ## It's entirely possible to get here with just a baseuri.
  if (missing(auth)) {
    auth <- NULL
  }
  if (is.null(auth)) {
    auth <- .getCredentials()
    if (any(is.na(auth))) {
      stop("User cancelled database connection.")
    }
  }

  ## Set up our session and authenticate.
  curl <- RCurl::getCurlHandle()
  cookies <- file.path(Sys.getenv("HOME"), ".cookies.txt")
  RCurl::curlSetOpt(cookiefile = cookies, curl = curl)

  ## Fetch the login page to obtain a session cookie and CSRF token.
  header_buf <- RCurl::basicTextGatherer()
  body_sink   <- RCurl::basicTextGatherer()
  RCurl::curlPerform(
    url            = paste(baseuri, "login", sep = "/"),
    .opts          = .opts,
    curl           = curl,
    writefunction  = body_sink$update,
    headerfunction = header_buf$update
  )
  raw_headers <- header_buf$value()
  m <- regmatches(
    raw_headers,
    regexpr("X-CSRF-Token:\\s*(\\S+)", raw_headers,
            perl = TRUE, ignore.case = TRUE)
  )
  csrf_token <- if (length(m) > 0L) {
    sub("(?i)X-CSRF-Token:\\s*", "", m[[1L]], perl = TRUE)
  } else {
    NULL
  }

  ## We need to detect login failures here.
  query <- list(username = auth$username, password = auth$password)
  query <- rjson::toJSON(query)
  query <- RCurl::curlEscape(query)

  ## Build the POST body. Append the CSRF token as an ordinary form parameter
  ## so that Catalyst::Plugin::CSRFToken can find it in body_parameters (the
  ## X-CSRF-Token request-header route proved unreliable with RCurl).
  post_body <- paste("data", query, sep = "=")
  if (is.null(csrf_token)) {
    warning("Unable to obtain CSRF token; login may fail.")
  } else {
    post_body <- paste(post_body,
                       paste("csrf_token",
                             RCurl::curlEscape(csrf_token),
                             sep = "="),
                       sep = "&")
  }

  status <- RCurl::basicTextGatherer()
  res <- RCurl::curlPerform(
    url           = paste(baseuri, "login", sep = "/"),
    postfields    = post_body,
    .opts         = .opts,
    curl          = curl,
    writefunction = status$update
  )

  ## Check the response for errors.
  status <- rjson::fromJSON(status$value())
  if (!isTRUE(status$success)) {
    stop(status$message)
  }

  attr(curl, "baseuri") <- baseuri

  return(curl)
}

################################################################################
#' Log out a given CURLHandle session from the web site authentication system.
#' @importFrom rjson fromJSON toJSON
#' @importFrom RCurl curlPerform basicTextGatherer
#' @param auth A \code{CURLHandle} object representing an authenticated session.
#' @param .opts Named list of additional options forwarded to
#'   \code{\link[RCurl]{curlPerform}}.
#' @param ... Additional arguments (reserved for future use).
#' @return Invisibly returns \code{NULL}.  Raises a warning if the logout
#'   request fails, and an error if the server returns a failure status.
.logoutBFDBHandle <- function(auth, .opts = list(), ...) {
  ## N.B. ... argument included to allow generous use of ... in upstream
  ## functions.

  if (!inherits(auth, "CURLHandle")) {
    stop("Must pass in a CURLHandle object.")
  }

  baseuri <- attr(auth, "baseuri")

  if (is.null(baseuri)) {
    stop("CURLHandle object must have a baseuri attribute set.")
  }

  if (!is.list(.opts)) {
    stop("Error: .opts must be a list object")
  }

  status <- RCurl::basicTextGatherer()
  res <- RCurl::curlPerform(
    url = paste(baseuri, "json_logout", sep = "/"),
    .opts = .opts,
    curl = auth,
    writefunction = status$update
  )

  ## Check the response for errors. FIXME test this part once the
  ## json_logout method has been properly installed on the server.
  status <- rjson::fromJSON(status$value())
  if (!isTRUE(status$success)) {
    stop(status$message)
  }

  if (res != 0) {
    warning("Unable to log out.")
  }

  return()
}

################################################################################
#' Simple user query for login credentials. Replaces old tcl/tk version.
#' @importFrom getPass getPass
#' @return A list with elements \code{username} and \code{password}.
.getCredentials <- function() {
  username <- readline(prompt = "Username: ")
  password <- getPass(msg = "Password: ", noblank = TRUE)

  return(list(username = username, password = password))
}

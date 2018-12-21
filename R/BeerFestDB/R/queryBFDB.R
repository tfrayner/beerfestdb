##
## This file is part of BeerFestDB, a beer festival product management
## system.
## 
## Copyright (C) 2011-2015 Tim F. Rayner
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

################################################################################
## Method used to extract data from the JSON API and organise it into
## a data frame, regularised by the passed column names if available.
getBFData <- function(dbclass, action, params=c(), columns=NULL, auth, .opts=list(), ...) {

    objects <- queryBFDB(dbclass, action, params, auth, .opts, ...)

    terms <- sort(Reduce(union, sapply(objects, names)))
    cleaned <- lapply(objects, function(x) {
        w <- terms[ ! terms %in% names(x) ]
        v <- rep(NA, length(w))
        names(v) <- w
        x <- c(x, v)
        return(x[terms])
    })

    res <- as.data.frame(do.call('rbind', cleaned), stringsAsFactors=FALSE)
    for (n in 1:ncol(res)) res[,n] <- as.character(res[,n])

    for ( x in colnames(res) )
        if ( grepl( '_id$', x ) )
            suppressWarnings(res[, x] <- as.integer( res[, x] ))

    if ( ! is.null(columns) ) {
        if ( nrow(res) > 0 ) {
            if ( ! all(columns %in% colnames(res)) ) {
	        stop(sprintf("Unexpected BFDB query result from class %s, action %s; missing columns: %s",
 		             dbclass, action, paste(setdiff(columns, colnames(res)), collapse=', ')))
	    }
            res <- res[, columns]
        } else {
            res <- as.data.frame(matrix(nrow=0,
                                        ncol=length(columns),
                                        dimnames=list(NULL, columns)))
	}	
    }

    return(res)

}

################################################################################
## Core method to interact with the BeerFestDB web site via its JSON
## API. See below for specific method signatures.
setGeneric('queryBFDB', def=function( dbclass, action, params=c(),
                            auth, .opts=list(), baseuri, ... ) {
               standardGeneric('queryBFDB')
           })

################################################################################
## queryBFDB method where auth=CURLHandle
.queryBFDBCurl <- function( dbclass, action, params=c(),
                           auth, .opts=list(), ... ) {

    # Assumes that all JSON query actions in the web server behave
    # roughly the same; i.e. they act on a set of (usually only one or
    # two) numeric parameters which will be encoded in the query URI,
    # and return JSON with a 'success' flag attribute, an 'message'
    # attribute where necessary, and the actual returned data in an
    # 'objects' attribute. Returns just the objects list.

    if ( ! is.list(.opts) )
        stop("Error: .opts must be a list object")

    ## Workaround for a known SSL session reuse bug
    ## ("SSL3_GET_RECORD:bad decompression"). Presumably this would
    ## also be fixable on the server, but it doesn't hurt to have a
    ## fix here as well.
    if ( is.null( .opts$ssl.sessionid.cache ) )
        .opts$ssl.sessionid.cache <- FALSE

    baseuri <- attr(auth, 'baseuri')
    if ( is.null(baseuri) )
        stop("CURLHandle object must have an additional baseuri attribute set.")

    uri <- paste(baseuri, tolower(dbclass), action, sep='/')
    if ( ! missing(params) )
        uri <- paste(c(uri, params), collapse='/')

    ## Run the query.
    status <- RCurl::basicTextGatherer()
    res    <- RCurl::curlPerform(url=uri,
                                 .opts=.opts,
                                 curl=auth,
                                 writefunction=status$update)
    
    ## Check the response for errors.
    rc <- try(status  <- rjson::fromJSON(status$value()))

    if ( inherits(rc, 'try-error') )
        stop(sprintf("Error encountered: %s", rc))

    if ( ! isTRUE(status$success) )
        stop(status$message)

    return(status$objects)
}

setMethod('queryBFDB', signature(auth='CURLHandle'), .queryBFDBCurl)

################################################################################
## queryBFDB method where auth==list(username, password) or auth==NULL;
## uri is required in either case.
.queryBFDBCred <- function( dbclass, action, params=c(),
                           auth=NULL, .opts=list(), baseuri, ... ) {

    curl <- .getBFDBHandle( baseuri=baseuri, auth=auth, .opts=.opts )

    response <- queryBFDB( dbclass, action, params, auth=curl, .opts=.opts, ... )

    ## Log out for the sake of completeness (check for failure and warn).
    .logoutBFDBHandle( curl, .opts )

    return(response)
}

setMethod('queryBFDB', signature(auth='list',    baseuri='character'),  .queryBFDBCred)
setMethod('queryBFDB', signature(auth='NULL',    baseuri='character'),  .queryBFDBCred)
setMethod('queryBFDB', signature(auth='missing', baseuri='character'),  .queryBFDBCred)

################################################################################
## Catch-all method to yield a more user-friendly error message.
.queryBFDBError <- function(dbclass, action, params,
                            auth, .opts, baseuri, ...) {
    stop('Error: baseuri argument is required unless using CURLHandle-based authentication.')
}

setMethod('queryBFDB', signature(auth='missing', baseuri='missing'), .queryBFDBError)
setMethod('queryBFDB', signature(auth='NULL', baseuri='missing'), .queryBFDBError)
setMethod('queryBFDB', signature(auth='list', baseuri='missing'), .queryBFDBError)

################################################################################
## Returns a CURLHandle object which contains details for a logged-in
## BFDB session.
.getBFDBHandle <- function( baseuri=NULL, auth, .opts=list() ) {

    if ( is.null(baseuri) )
        stop('Error: baseuri argument must be provided.')

    if ( ! is.list(.opts) )
        stop("Error: .opts must be a list object")

    ## It's entirely possible to get here with just a baseuri.
    if ( missing(auth) )
        auth <- NULL
    if ( is.null(auth) ) {
        auth <- .getCredentials()
        if ( any( is.na(auth) ) )
            stop('User cancelled database connection.')
    }

    ## Set up our session and authenticate.
    curl    <- RCurl::getCurlHandle()
    cookies <- file.path(Sys.getenv('HOME'), '.cookies.txt')
    RCurl::curlSetOpt(cookiefile=cookies, curl=curl)

    ## We need to detect login failures here.
    query  <- list(username=auth$username, password=auth$password)
    query  <- rjson::toJSON(query)
    query  <- RCurl::curlEscape(query)
    status <- RCurl::basicTextGatherer()
    res    <- RCurl::curlPerform(url=paste(baseuri, 'login', sep='/'),
                                 postfields=paste('data', query, sep='='),
                                 .opts=.opts,
                                 curl=curl,
                                 writefunction=status$update)

    ## Check the response for errors.
    status  <- rjson::fromJSON(status$value())
    if ( ! isTRUE(status$success) )
        stop(status$message)

    attr(curl, 'baseuri') <- baseuri

    return(curl)
}

################################################################################
## Log out a given CURLHandle session from the web site authentication system.
.logoutBFDBHandle <- function( auth, .opts=list(), ... ) {

    ## N.B. ... argument included to allow generous use of ... in upstream functions.

    if ( ! inherits(auth, 'CURLHandle') )
        stop("Must pass in a CURLHandle object.")

    baseuri <- attr(auth, 'baseuri')

    if ( is.null(baseuri) )
        stop("CURLHandle object must have a baseuri attribute set.")

    if ( ! is.list(.opts) )
        stop("Error: .opts must be a list object")

    status <- RCurl::basicTextGatherer()
    res    <- RCurl::curlPerform(url=paste(baseuri, 'json_logout', sep='/'),
                                 .opts=.opts,
                                 curl=auth,
                                 writefunction=status$update)

    ## Check the response for errors. FIXME test this part once the
    ## json_logout method has been properly installed on the server.
    status  <- rjson::fromJSON(status$value())
    if ( ! isTRUE(status$success) )
        stop(status$message)

    if ( res != 0 )
        warning('Unable to log out.')

    return()
}

################################################################################
## Fairly generic method to open a Tcl/Tk dialog and ask the user for
## login credentials.
##
## Code copied from
## http://bioinf.wehi.edu.au/~wettenhall/RTclTkExamples/modalDialog.html
## and modified.
.getCredentials <- function(title='BeerFestDB Authentication',
                            entryWidth=30, returnValOnCancel=NA, parent) {

    ## Previous versions checked X11 here but that doesn't make sense
    ## for the MS Windows version of R, which pushes tcltk through the
    ## internal R graphics device.
    if ( ! capabilities()['tcltk'] )
        stop("Error: tcltk windowing system is not available.")

    require(tcltk)

    username <- returnValOnCancel
    password <- returnValOnCancel
    username.tcl <- tclVar('')
    password.tcl <- tclVar('')

    if ( missing(parent) ) {
        dlg <- tktoplevel()

        tkwm.geometry(dlg, .calcTkWmGeometry(350,130))
        tkwm.geometry(dlg, '') # Shrink back to default size
        tkwm.deiconify(dlg)
        tkgrab.set(dlg)
        tkfocus(dlg)
        tkwm.title(dlg,title)
    }
    else {
        dlg <- tkframe(parent)
        tkpack(dlg, expand=TRUE)
    }

    onOK <- function() {
        username <<- tclvalue(username.tcl)
        password <<- tclvalue(password.tcl)
        tkgrab.release(dlg)
        tkdestroy(dlg)
    }

    onCancel <- function() {
        username <<- returnValOnCancel
        password <<- returnValOnCancel
        tkgrab.release(dlg)
        tkdestroy(dlg)
    }

    # Put our buttons into a frame.
    f.buttons <- tkframe(dlg, borderwidth=15)
    b.OK     <- tkbutton(f.buttons, text="   OK   ", command=onOK)
    b.cancel <- tkbutton(f.buttons, text=" Cancel ", command=onCancel)
    tkpack(b.OK, b.cancel, side='right')

    # Text entry fields belong in a grid inside a frame.
    f.entries <- tkframe(dlg, borderwidth=15)

    e.user       <- tkentry(f.entries, width=paste(entryWidth),
                            textvariable=username.tcl)
    l.user       <- tklabel(f.entries, text='Username: ')
    e.pass       <- tkentry(f.entries, width=paste(entryWidth),
                            textvariable=password.tcl, show='*')
    l.pass       <- tklabel(f.entries, text='Password: ')
    
    tkgrid(l.user, e.user)
    tkgrid(l.pass, e.pass)

    # Line the fields and labels up in the middle.
    tkgrid.configure(e.user, e.pass, sticky='w')
    tkgrid.configure(l.user, l.pass, sticky='e')

    tkpack(f.entries, side='top')
    tkpack(f.buttons, anchor='se')
    
    tkfocus(e.user)
    tkbind(dlg, "<Destroy>", function() tkgrab.release(dlg))
    tkbind(e.user, "<Return>", onOK)
    tkbind(e.pass, "<Return>", onOK)
    tkwait.window(dlg)

    return(list(username=username, password=password))
}

################################################################################
## Simply calculate where to draw the dialog box relative to the
## parent viewpane/window. This function determines the placement of a
## subwindow in the center of the parent.
.calcTkWmGeometry <- function( width, height ) {

    px <- as.numeric(tkwinfo('screenwidth', '.'))
    py <- as.numeric(tkwinfo('screenheight', '.'))

    sprintf('%dx%d+%d+%d', width, height, (px/2)-(width/2), (py/2)-(height/2))
}

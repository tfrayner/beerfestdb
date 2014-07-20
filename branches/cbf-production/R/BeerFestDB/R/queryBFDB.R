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

queryBFDB <- function( uri, columns ) {

    res <- RCurl::getURI(uri)
    res  <- rjson::fromJSON(res)
    stopifnot( isTRUE(res$success) )

    terms <- sort(Reduce(union, sapply(res$objects, names)))
    cleaned <- lapply(res$objects, function(x) {
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

    if ( ! missing(columns) ) {
        if ( nrow(res) > 0 ) {
            stopifnot( all(columns %in% colnames(res)) )
            res <- res[, columns]
        } else {
            res <- as.data.frame(matrix(nrow=0,
                                        ncol=length(columns),
                                        dimnames=list(NULL, columns)))
	}	
    }

    return(res)
}


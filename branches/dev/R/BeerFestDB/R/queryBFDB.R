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

    res <- getURI(uri)
    res  <- rjson::fromJSON(res)
    stopifnot( isTRUE(res$success) )
    
    res <- as.data.frame(do.call('rbind', res$objects), stringsAsFactors=FALSE)
    suppressWarnings(res <- as.data.frame(apply(res, 2, as.character), stringsAsFactors=FALSE))

    for ( x in colnames(res) )
        if ( grepl( '_id$', x ) )
            suppressWarnings(res[, x] <- as.integer( res[, x] ))

    if ( ! missing(columns) )
        res <- res[, columns]

    return(res)
}


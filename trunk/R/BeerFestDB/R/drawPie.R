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

drawPie <- function(cp, colname, cols=1:9, radius=0.8, ...) {

    counts <- aggregate(rep(1, nrow(cp)), list(cp[, colname]), sum)

    w <- counts[,2]/sum(counts[,2]) < 0.01
    if ( sum(w) > 0 ) {
        s <- sum(counts[w, 2])
        counts <- rbind(counts[!w,], c('Other', s))
    }

    if ( nrow( counts ) > length( cols ) )
        cols <- colorRampPalette( cols )( nrow( counts ) )

    pie(as.numeric(counts[,2]), labels=counts[,1], radius=radius, col=cols, ...)
}


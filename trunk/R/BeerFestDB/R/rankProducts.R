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

rankProducts <- function( cp, drop, w ) {

    ## Doesn't work very well since occasionally a cask gets held back.
#    byprod <- aggData(cp, c('company_name','product_name'))
#    rates <- as.data.frame(t(apply(byprod, 1, productSaleRate)))

    ## Better approach: once a cask is started, it's not usually held
    ## back any further. Get sales rates per cask and average
    ## them. This also works most believably if we drop the last part
    ## of the festival; note that some beers lose out in this case.
    x <- cp[,w]
    x <- x[, ! colnames(x) %in% drop ]
    x <- cbind(cp[, c('company_name','product_name')], x)

    ## Have to throw out all those beers which never changed in the query period.
    x <- x[apply(x[,-c(1:2)], 1, function(x) { sum(x != x[1]) }) != 0,]

    z <- as.data.frame(t(apply(x[,-c(1:2)], 1, productSaleRate)))
    z <- aggregate(z$Estimate, list(x$company_name, x$product_name), median)
    z <- z[order(z$x),]

    return(z)
}


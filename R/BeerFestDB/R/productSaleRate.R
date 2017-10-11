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

productSaleRate <- function(y) {

    ## Trim off initial non-sale period.
    y <- c(y[1], y[ y!=y[1] ])

    ## Trim off trailing non-sale period.
    n <- length(y)
    y <- c(y[ y!=y[n] ], y[n])

    ## Normalise to zero at end of sale period.
    y <- y - y[length(y)]

    m <- 1:length(y) - 1

    l <- lm( y ~ m )

    ## FIXME we could also return the std. error here.
    suppressWarnings(r <- summary(l)$coefficients[-1, c(1,2)])
    return( c(-r[1], r[2] ) )
}


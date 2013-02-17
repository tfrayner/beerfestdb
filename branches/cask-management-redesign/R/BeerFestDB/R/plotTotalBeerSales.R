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

plotTotalBeerSales <- function( pd, ... ) {
    d <- apply(pd, 2, sum)
    
    plot(d, ylim=c(0, max(d) ),
         lwd=2, type='l', ylab='Gallons sold', xlab='Day',
         axes=FALSE, cex.lab=1.5, ...)
    axis(2, cex.axis=1.5)
    axis(1, cex.axis=1.5, labels=colnames(pd), at=1:ncol(pd))
}


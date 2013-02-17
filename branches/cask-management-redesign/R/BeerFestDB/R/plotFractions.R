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

plotFractions <- function(data, clusters=rownames(data),
                          cols=1:9, lty=1:9, ylim=c(0,1),
                          leg.pos='bottomleft', ylab='Fraction remaining', ...) {

    if ( length( clusters ) > length( cols ) )
        cols <- colorRampPalette( cols )( length( clusters ) )

    matplot(t(data[clusters,, drop=FALSE]), col=cols,
            type='l', lwd=2, lty=lty, ylim=ylim, axes=FALSE,
            xlab='Dip Time', ylab=ylab, cex.lab=1.5, cex.main=1.5, ...)

    axis(2, cex.axis=1.5)

    axis(1, cex.axis=1.5, labels=colnames(data), at=1:ncol(data))

    legend(leg.pos, legend=clusters, fill=cols, cex=1.3)
}


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

analyseData <- function(cp) {

    cp <- cp[ cp$is_condemned == 0, ]
    
    cp$abv_class <- cut(cp$abv, breaks=c(2,3.5,4,4.5,5,7,12))
    levels(cp$abv_class) <- gsub('\\(|\\]', '', gsub(',',' - ',levels(cp$abv_class)))
    
    w  <- colnames(cp) == 'cask_volume' | grepl('^dip\\.', colnames(cp))
    colnames(cp)[w][-1] <- gsub('^dip\\.', '', colnames(cp)[w][-1])

    stopifnot( colnames(cp)[w][1] == 'cask_volume' )

    pd <- cp[,w][,-sum(w)] - cp[,w][,-1]
    colnames(pd) <- colnames(cp)[w][-1]

    ## The rounding here is to try and address floating point errors upstream. Not Ideal (FIXME).
    pd <- round(cp[,w][,-sum(w)] - cp[,w][,-1], 6)
    colnames(pd) <- colnames(cp)[w][-1]
    if ( ! all(pd >= 0) ) {
        stop("Negative per diem dips found: probable dip data error in the database.")
    }

    plotToFile( 'total_beer_sales.pdf', plotTotalBeerSales, pd )

    plotToFile( 'sales_by_region.pdf', plotSalesRate, cp, 'region', w=w )
    plotToFile( 'sales_by_stillage.pdf', plotSalesRate, cp, 'stillage', w=w )
    plotToFile( 'sales_by_abv_class.pdf', plotSalesRate, cp, 'abv_class', w=w )

    cols <- brewer.pal(9, 'Set1')
    byprod <- aggregate(cp[,c('region','style')], list( cp$company_name, cp$product_name ), unique)
    plotToFile( 'beers_per_region.pdf', drawPie,
               byprod, 'region', cols=cols, cex=1.25 )
    plotToFile( 'beers_per_style.pdf', drawPie,
               byprod, 'style', cols=cols, cex=1.25 )

    dp <- aggData( cp, 'style', w )
    plotToFile( 'clusters_by_style.pdf', heatmap.2, as.matrix(dp/dp[,1]),
               dendrogram='row', key=FALSE, margins=c(5,12), trace='none',
               Colv=FALSE, lhei=c(2, 10), lwid=c(2, 5), cexRow=1.5, cexCol=1.5)

    ## Drop the last part of the festival (1/4 rounded up) since it'll
    ## usually be non-linear by then.
    dn <- ceiling((ncol(dp)-1)/4) - 1
    drop <- colnames(dp)[ (ncol(dp)-dn):ncol(dp) ]

    plotToFile( 'sale_profile_by_style.pdf', plotModelCoeffs, cp, 'style', drop=drop, w=w)
    plotToFile( 'sale_profile_by_abv_class.pdf', plotModelCoeffs, cp, 'abv_class', drop=drop, w=w)
    plotToFile( 'sale_profile_by_region.pdf', plotModelCoeffs, cp, 'region', drop=drop, w=w)
    plotToFile( 'sale_profile_by_stillage.pdf', plotModelCoeffs, cp, 'stillage', drop=drop, w=w)

    ## Probably don't want to publish this until we're happier with
    ## the algorithm.
    prodrank <- rankProducts( cp, drop, w )
    write.csv(prodrank, file='product_sales_ranking.csv', row.names=FALSE)

    invisible(prodrank)
}


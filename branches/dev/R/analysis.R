##
## $Id$
##

library(RCurl)
library(rjson)
library(RColorBrewer)
library(gplots)

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

retrieveDips <- function( baseuri, id ) {

    res <- getURI(paste(baseuri, 'cask/list_dips', id, sep='/'))
    res <- rjson::fromJSON(res)
    stopifnot(isTRUE(res$success))

    return(res$objects)
}

getFestivalData <- function( baseuri, festname, prodcat ) {

    ## Begin building the main data frame.
    fest <- queryBFDB(paste(baseuri, 'festival/list', sep='/'))

    batch <- queryBFDB(paste(baseuri, 'measurementbatch/list',
                             fest[ fest$name==festname, 'festival_id'], sep='/'))
    batch$measurement_time <- as.Date(batch$measurement_time)
    batch <- batch[ order(batch$measurement_time), ]

    cat <- queryBFDB(paste(baseuri, 'productcategory/list', sep='/'))

    cask <- queryBFDB(paste(baseuri, 'cask/list',
                            fest[ fest$name==festname, 'festival_id'],
                            cat[cat$description==prodcat, 'product_category_id'], sep='/'),
                      c('cask_id','product_id','container_size_id',
                        'stillage_location_id','festival_ref','is_condemned'))
    suppressWarnings(cask <- as.data.frame(apply(cask, 2, as.integer)))
    cask[ is.na(cask$is_condemned), 'is_condemned' ] <- 0

    sizes <- queryBFDB(paste(baseuri, 'containersize/list', sep='/'),
                       c('container_size_id','volume'))
    colnames(sizes)[2] <- 'cask_volume'

    cp <- merge(cask, sizes, by='container_size_id')

    product <- queryBFDB(paste(baseuri, 'product/list', sep='/'),
                         c('product_id','company_id','nominal_abv','name','product_style_id'))
    colnames(product)[4]<-'product_name'

    cp <- merge(cp, product, by='product_id')

    style <- queryBFDB(paste(baseuri, 'productstyle/list', sep='/'),
                       c('product_style_id','description'))
    colnames(style)[2] <- 'style'

    cp <- merge(cp, style, by='product_style_id', all.x=TRUE)
    
    company <- queryBFDB(paste(baseuri, 'company/list', sep='/'),
                         c('company_id','name','company_region_id'))
    colnames(company)[2]<-'company_name'

    cp <- merge(cp, company, by='company_id')
    
    region <- queryBFDB(paste(baseuri, 'companyregion/list', sep='/'),
                        c('company_region_id','description'))
    colnames(region)[2] <- 'region'

    cp <- merge(cp, region, by='company_region_id', all.x=TRUE)

    stillage <- queryBFDB(paste(baseuri, 'stillagelocation/list',
                                fest[ fest$name==festname, 'festival_id'],
                                sep='/'),
                        c('stillage_location_id','description'))
    colnames(stillage)[2] <- 'stillage'

    cp <- merge(cp, stillage, by='stillage_location_id', all.x=TRUE)

    ## Throw out all database ID columns except cask_id.
    cp <- cp[, ! grepl('(?<!cask)_id$', colnames(cp), perl=TRUE)]

    dipmat <- as.data.frame(matrix( NA, nrow=nrow(cp), ncol=nrow(batch) ))
    rownames(dipmat) <- cp$cask_id
    colnames(dipmat) <- paste('dip', batch$description, sep='.')

    for ( id in cp$cask_id ) {
        d <- retrieveDips(baseuri, id)
        d <- unlist(lapply(batch$measurement_batch_id, function(n) { d[[as.character(n)]] }))
        dipmat[ as.character(id), ] <- d
    }

    cp <- merge(cp, dipmat, by.x='cask_id', by.y=0, all.x=TRUE)

    ## Dip figures need to be numeric.
    w <- grepl('^dip\\.', colnames(cp))
    cp[,w] <- apply(cp[,w], 2, as.numeric)
    cp$cask_volume <- as.numeric(cp$cask_volume)
    cp$nominal_abv <- as.numeric(cp$nominal_abv)

    return(cp)
}

plotToFile <- function( file, fn, ... ) {
    pdf( file=file )
    fn( ... )
    dev.off()
}

aggData <- function( cp, colname, w=TRUE ) {
    dp <- aggregate( cp[ ,w], lapply(colname, function(x) { cp[, x] }), sum)

    rownames(dp) <- apply(dp[,c(1:length(colname)), drop=FALSE], 1, paste, collapse=':')
    dp <- dp[,-c(1:length(colname))]
    colnames(dp)[1] <- 'Start'

    return(dp)
}

plotSalesRate <- function( cp, colname, w=TRUE, ... ) {
    dp <- aggData( cp, colname, w )
    cols <- brewer.pal(9, 'Set1')
    plotFractions( dp / dp[,1], cols=cols, ... )
}

plotModelCoeffs <- function(cp, colname, drop, w=TRUE, ... ) {

    dp <- aggData(cp, colname, w)

    pred <- aggregate( cp$cask_volume, list(cp[, colname]), sum )[,2] / ncol(dp)
    pred <- (pred/sum(pred)) * 100

    dp <- dp[, ! colnames(dp) %in% drop ]

    fm <- data.frame(dip=as.numeric(t(dp)),
                     time=rep(0:(ncol(dp)-1), nrow(dp)),
                     category=unlist(lapply(rownames(dp), rep, ncol(dp))))
    l <- lm(dip~0+time+category, data=fm)

    ## FIXME consider also using the std. error estimates to generate error bars.

    x <- summary(l)$coefficients[-1,1]
    x <- (x/sum(x)) * 100
    names(x) <- sub('category', '', names(x))

    old.par <- par(mar=c(5,12,2,2))
    bp <- barplot(rbind(x, pred), beside=TRUE, ylab='', yaxt='n', horiz=TRUE,
                  xlab='Percent total', legend.text=c('Observed', 'Predicted'),
                  args.legend=list(x='topright', cex=1.2), col=c('blue','yellow'),
                  cex.axis=1.5, cex.lab=1.5)
    text(y=apply(bp, 2, mean), labels=names(x), x=par("usr")[1] - 1.5, adj = 1, xpd = TRUE, cex=1.5)
    par(old.par)
}

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
    z <- aggregate(z$Estimate, list(x$company_name, x$product_name), mean)
    z <- z[order(z$x),]

    return(z)
}

productSaleRate <- function(y) {

    y <- c(y[1], y[ y!=y[1] ])

    if ( y[ length(y) ] == 0 )
        y <- c( y[ y!=0 ], 0 )

    n <- 1:length(y) - 1

    l <- lm( y~n )

    ## FIXME we could also return the std. error here.
    r <- summary(l)$coefficients[-1, c(1,2)]
    return( c(-r[1], r[2] ) )
}

plotTotalBeerSales <- function( pd, ... ) {
    d <- apply(pd, 2, sum)
    
    plot(d, ylim=c(0, max(d) ),
         lwd=2, type='l', ylab='Gallons sold', xlab='Day',
         axes=FALSE, cex.lab=1.5, ...)
    axis(2, cex.axis=1.5)
    axis(1, cex.axis=1.5, labels=colnames(pd), at=1:ncol(pd))
}

analyseData <- function(cp) {

    ## Currently a dumping ground for some thoughts.
    cp <- cp[ cp$is_condemned == 0, ]
    
    cp$abv_class <- cut(cp$nominal_abv, breaks=c(2,3.5,4,4.5,5,7,12))
    levels(cp$abv_class) <- gsub('\\(|\\]', '', gsub(',',' - ',levels(cp$abv_class)))
    
    w  <- colnames(cp) == 'cask_volume' | grepl('^dip\\.', colnames(cp))
    colnames(cp)[w][-1] <- gsub('^dip\\.', '', colnames(cp)[w][-1])

    stopifnot( colnames(cp)[w][1] == 'cask_volume' )

    pd <- cp[,w][,-sum(w)] - cp[,w][,-1]
    colnames(pd) <- colnames(cp)[w][-1]
    stopifnot( all(pd >= 0 ) )

    plotToFile( 'total_beer_sales.pdf', plotTotalBeerSales, pd )

    plotToFile( 'sales_by_stillage.pdf', plotSalesRate, cp, 'region', w=w )
    plotToFile( 'sales_by_region.pdf', plotSalesRate, cp, 'stillage', w=w )
    plotToFile( 'sales_by_abv_class.pdf', plotSalesRate, cp, 'abv_class', w=w )

    cols <- brewer.pal(9, 'Set1')
    plotToFile( 'beers_per_region.pdf', drawPie,
               cp, 'region', cols=cols, cex=1.25 )
    plotToFile( 'beers_per_style.pdf', drawPie,
               cp, 'style', cols=cols, cex=1.25 )

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

if ( ! interactive() ) {

    ## Ideally these would be set either by config or command-line arguments.
    baseuri  <- 'http://localhost:3000'
    festname <- '38th Cambridge Beer Festival'
    prodcat  <- 'beer'

    cp <- getFestivalData(baseuri, festname, prodcat)
    write.csv(cp, 'full_dip_dump.csv', row.names=FALSE)

    analyseData(cp)
}

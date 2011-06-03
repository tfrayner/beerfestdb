##
## $Id$
##

library(RCurl)

queryBFDB <- function( uri, columns ) {

    res <- getURI(uri)
    res  <- rjson::fromJSON(res)
    stopifnot( isTRUE(res$success) )
    
    res <- as.data.frame(do.call('rbind', res$objects))
    res <- as.data.frame(apply(res, 2, as.character))

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
                      c('cask_id','product_id','festival_ref'))
    cask <- as.data.frame(apply(cask, 2, as.integer))

    product <- queryBFDB(paste(baseuri, 'product/list', sep='/'),
                         c('product_id','company_id','nominal_abv','name','product_style_id'))
    colnames(product)[4]<-'product_name'

    cp <- merge(cask, product, by='product_id')

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

    return(cp)
}

## Ideally these would be set either by config or command-line arguments.
baseuri  <- 'http://localhost:3000'
festname <- '38th Cambridge Beer Festival'
prodcat  <- 'beer'

cp <- getFestivalData(baseuri, festname, prodcat)

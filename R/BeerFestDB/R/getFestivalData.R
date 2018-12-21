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

getFestivalData <- function( baseuri, festname, prodcat, auth=NULL, .opts=list() ) {

    if ( is.null(auth) || ! inherits(auth, 'CURLHandle') )
        auth <- .getBFDBHandle(baseuri=baseuri, auth=auth, .opts=.opts)

    ## Begin building the main data frame.
    fest <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                      'Festival', 'list')
    festival_id <- fest[ fest$name==festname, 'festival_id']

    batch <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                       'MeasurementBatch', 'list',
                       params=festival_id)
    batch$measurement_time <- as.Date(batch$measurement_time)
    batch <- batch[ order(batch$measurement_time), ]

    cat <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                     'ProductCategory', 'list')
    prodcat_id <- cat[cat$description==prodcat, 'product_category_id']

    cask <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                      'Cask', 'list',
                      params=c(festival_id, prodcat_id),
                      columns=c('cask_id','product_id','container_size_id',
                          'order_batch_id','gyle_id','stillage_location_id',
                          'festival_ref','is_condemned','is_sale_or_return','comment'))

    w <- colnames(cask) != 'comment'
    suppressWarnings(cask[,w] <- as.data.frame(apply(cask[,w], 2, as.integer)))
    cask[ is.na(cask$is_condemned), 'is_condemned' ] <- 0
    cask[ is.na(cask$is_sale_or_return), 'is_sale_or_return' ] <- 0
    cask[ is.na(cask$comment), 'comment' ] <- ''

    measures <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                          'ContainerMeasure', 'list',
                          columns=c('description', 'litre_multiplier'))
    default_cask_measure <- as.numeric(with(measures, litre_multiplier[ description == 'gallon' ]))
    stopifnot(length(default_cask_measure) == 1)

    sizes <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                       'ContainerSize', 'list',
                       columns=c('container_size_id','volume','litre_multiplier','description'))
    colnames(sizes)[2] <- 'cask_volume'
    for ( n in 2:3 )
        sizes[,n] <- as.numeric(sizes[,n])
    sizes$cask_volume <- with(sizes, cask_volume * litre_multiplier) / default_cask_measure
    sizes <- sizes[,1:2]
    cp <- merge(cask, sizes, by='container_size_id')

    product <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                         'Product', 'list_by_festival',
                         params=c(festival_id, prodcat_id),
                         columns=c('product_id','company_id','nominal_abv',
                             'name','product_style_id'))
    colnames(product)[4]<-'product_name'
    cp <- merge(cp, product, by='product_id')

    gyle <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                      'Gyle', 'list_by_festival',
                      params=festival_id,
                      columns=c('gyle_id','abv'))
    colnames(gyle)[2] <- 'gyle_abv'
    cp <- merge(cp, gyle, by='gyle_id')

    ## Sort out ABVs. If a gyle ABV is present, use it preferentially.
    suppressWarnings(cp$nominal_abv <- as.numeric(cp$nominal_abv))
    suppressWarnings(cp$gyle_abv    <- as.numeric(cp$gyle_abv))
    cp$abv <- ifelse(is.na(cp$gyle_abv), cp$nominal_abv, cp$gyle_abv)
    cp <- cp[, ! colnames(cp) %in% c('nominal_abv', 'gyle_abv') ]

    style <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                       'ProductStyle', 'list',
                       columns=c('product_style_id','description'))
    colnames(style)[2] <- 'style'
    cp <- merge(cp, style, by='product_style_id', all.x=TRUE)
    
    company <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                         'company', 'list',
                         columns=c('company_id','name','company_region_id'))
    colnames(company)[2]<-'company_name'
    cp <- merge(cp, company, by='company_id')
    
    region <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                        'CompanyRegion', 'list',
                        columns=c('company_region_id','description'))
    colnames(region)[2] <- 'region'
    cp <- merge(cp, region, by='company_region_id', all.x=TRUE)

    stillage <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                          'StillageLocation', 'list',
                          params=festival_id,
                          columns=c('stillage_location_id','description'))
    colnames(stillage)[2] <- 'stillage'
    cp <- merge(cp, stillage, by='stillage_location_id', all.x=TRUE)

    orderbatch <- getBFData(baseuri=baseuri, auth=auth, .opts=.opts,
                            'OrderBatch', 'list',
                            params=festival_id,
                            columns=c('order_batch_id','description'))
    colnames(orderbatch)[2] <- 'order_batch'
    cp <- merge(cp, orderbatch, by='order_batch_id', all.x=TRUE)
    cp[ is.na(cp$order_batch), 'order_batch' ] <- 'Other'

    ## Throw out all database ID columns except cask_id.
    cp <- cp[, ! grepl('(?<!cask)_id$', colnames(cp), perl=TRUE)]

    dipmat <- as.data.frame(matrix( NA, nrow=nrow(cp), ncol=nrow(batch) ))
    rownames(dipmat) <- cp$cask_id
    colnames(dipmat) <- paste('dip', batch$description, sep='.')

    for ( id in cp$cask_id ) {
        d <- retrieveDips(baseuri=baseuri, auth=auth, .opts=.opts, id)
        d <- unlist(lapply(batch$measurement_batch_id, function(n) { d[[as.character(n)]] }))
        dipmat[ as.character(id), ] <- d
    }
    cp <- merge(cp, dipmat, by.x='cask_id', by.y=0, all.x=TRUE)

    ## Dip figures need to be numeric.
    w <- grepl('^dip\\.', colnames(cp))
    cp[,w] <- apply(cp[,w], 2, as.numeric)
    cp$cask_volume <- as.numeric(cp$cask_volume)

    return(cp)
}


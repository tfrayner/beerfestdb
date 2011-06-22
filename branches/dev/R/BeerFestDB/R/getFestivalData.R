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
                      c('cask_id','product_id','container_size_id','order_batch_id','gyle_id',
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

    gyle <- queryBFDB(paste(baseuri, 'gyle/list_by_festival',
                            fest[ fest$name==festname, 'festival_id'], sep='/'),
                       c('gyle_id','abv'))
    colnames(gyle)[2] <- 'gyle_abv'
    cp <- merge(cp, gyle, by='gyle_id')

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

    orderbatch <- queryBFDB(paste(baseuri, 'orderbatch/list',
                                  fest[ fest$name==festname, 'festival_id'],
                                  sep='/'),
                        c('order_batch_id','description'))
    colnames(orderbatch)[2] <- 'order_batch'
    cp <- merge(cp, orderbatch, by='order_batch_id', all.x=TRUE)
    cp[ is.na(cp$order_batch), 'order_batch' ] <- 'Other'

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
    suppressWarnings(cp$nominal_abv <- as.numeric(cp$nominal_abv))
    suppressWarnings(cp$gyle_abv    <- as.numeric(cp$gyle_abv))

    return(cp)
}


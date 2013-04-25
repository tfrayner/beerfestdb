\name{getFestivalData}
\alias{getFestivalData}
\title{
  Retrieve full festival dip data from the BeerFestDB database.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
getFestivalData(baseuri, festname, prodcat)
}
\arguments{
  \item{baseuri}{
%%     ~~Describe \code{baseuri} here~~
}
  \item{festname}{
%%     ~~Describe \code{festname} here~~
}
  \item{prodcat}{
%%     ~~Describe \code{prodcat} here~~
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function( baseuri, festname, prodcat ) {

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
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

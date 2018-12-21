##
## $Id$
##

library(RCurl)
library(rjson)
library(RColorBrewer)
library(gplots)

library(BeerFestDB)

args <- commandArgs(trailingOnly=TRUE)

if ( is.null(args[1]) || args[1] == '' )
  stop("Please provide a Festival name to process.")

if ( ! interactive() ) {

    ## Ideally these would be set either by config or command-line arguments.
    baseuri  <- 'https://beerfestdb.cambridgebeerfestival.uk/'
    festname <- args[1]
    prodcat  <- 'beer'

    cp <- getFestivalData(baseuri, festname, prodcat)
    write.csv(cp, 'full_dip_dump.csv', row.names=FALSE)

    analyseData(cp)
}

##
## $Id$
##

library(RCurl)
library(rjson)
library(RColorBrewer)
library(gplots)

library(BeerFestDB)

if ( ! interactive() ) {

    ## Ideally these would be set either by config or command-line arguments.
    baseuri  <- 'https://secure.cambridge-camra.org.uk/beerfestdb'
    festname <- '42nd Cambridge Beer Festival'
    prodcat  <- 'beer'

    cp <- getFestivalData(baseuri, festname, prodcat)
    write.csv(cp, 'full_dip_dump.csv', row.names=FALSE)

    analyseData(cp)
}

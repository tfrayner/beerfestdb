\name{BeerFestDB-package}
\alias{BeerFestDB-package}
\alias{BeerFestDB}
\docType{package}
\title{
Utility functions used to query and analyse dip data from the BeerFestDB database.
}
\description{
This is a package used to help manage the development of code used in generating sales reports and other analyses of the data stored in a BeerFestDB instance.
}
\details{
\tabular{ll}{
Package: \tab BeerFestDB\cr
Type: \tab Package\cr
Version: \tab 0.1\cr
Date: \tab 2011-06-18\cr
License: \tab GPL (>= 3)\cr
LazyLoad: \tab yes\cr
}
The primary function of interest which this package provides is
\code{getFestivalData()}, which retrieves all the dip data from a given
festival and places it into a data frame suitable for subsequent
analysis. For a turn-key approach to such analyses, see the
\code{analyseData()} function.
}
\author{
Tim F. Rayner

Maintainer: Tim F. Rayner <tfrayner@gmail.com>
}
\keyword{ package }
\examples{
  \dontrun{
    baseuri  <- 'http://localhost:3000'
    festname <- '38th Cambridge Beer Festival'
    prodcat  <- 'beer'

    cp <- getFestivalData(baseuri, festname, prodcat)
    write.csv(cp, 'full_dip_dump.csv', row.names=FALSE)

    analyseData(cp)
  }
}

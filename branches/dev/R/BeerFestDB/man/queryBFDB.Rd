\name{queryBFDB}
\alias{queryBFDB}
\title{
  Query the BeerFestDB database via JSON API.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
queryBFDB(uri, columns)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{uri}{
%%     ~~Describe \code{uri} here~~
}
  \item{columns}{
%%     ~~Describe \code{columns} here~~
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
function( uri, columns ) {

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
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

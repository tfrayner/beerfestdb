\name{rankProducts}
\alias{rankProducts}
\title{
  Experimental function to rank products by their observed sales rate.
}
\description{
  This is quite experimental due to the complexities of determining a
  sales rate from sparse data affected by multiple confounding factors.
}
\usage{
rankProducts(cp, drop, w)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{cp}{
%%     ~~Describe \code{cp} here~~
}
  \item{drop}{
%%     ~~Describe \code{drop} here~~
}
  \item{w}{
%%     ~~Describe \code{w} here~~
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
function( cp, drop, w ) {

    ## Doesn't work very well since occasionally a cask gets held back.
#    byprod <- aggData(cp, c('company_name','product_name'))
#    rates <- as.data.frame(t(apply(byprod, 1, productSaleRate)))

    ## Better approach: once a cask is started, it's not usually held
    ## back any further. Get sales rates per cask and average
    ## them. This also works most believably if we drop the last part
    ## of the festival; note that some beers lose out in this case.
    x <- cp[,w]
    x <- x[, ! colnames(x) \%in\% drop ]
    x <- cbind(cp[, c('company_name','product_name')], x)

    ## Have to throw out all those beers which never changed in the query period.
    x <- x[apply(x[,-c(1:2)], 1, function(x) { sum(x != x[1]) }) != 0,]

    z <- as.data.frame(t(apply(x[,-c(1:2)], 1, productSaleRate)))
    z <- aggregate(z$Estimate, list(x$company_name, x$product_name), mean)
    z <- z[order(z$x),]

    return(z)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

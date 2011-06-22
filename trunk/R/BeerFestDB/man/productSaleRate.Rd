\name{productSaleRate}
\alias{productSaleRate}
\title{
  Calculate the sales rate for a given category using a linear model.
}
\description{
  Used internally by plotModelCoeffs.
}
\usage{
productSaleRate(y)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{y}{
%%     ~~Describe \code{y} here~~
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
function(y) {

    y <- c(y[1], y[ y!=y[1] ])

    if ( y[ length(y) ] == 0 )
        y <- c( y[ y!=0 ], 0 )

    n <- 1:length(y) - 1

    l <- lm( y~n )

    ## FIXME we could also return the std. error here.
    r <- summary(l)$coefficients[-1, c(1,2)]
    return( c(-r[1], r[2] ) )
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

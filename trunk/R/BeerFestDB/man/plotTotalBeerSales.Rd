\name{plotTotalBeerSales}
\alias{plotTotalBeerSales}
\title{
  Generate a plot of overall sales over time.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
plotTotalBeerSales(pd, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{pd}{
%%     ~~Describe \code{pd} here~~
}
  \item{\dots}{
%%     ~~Describe \code{\dots} here~~
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
function( pd, ... ) {
    d <- apply(pd, 2, sum)
    
    plot(d, ylim=c(0, max(d) ),
         lwd=2, type='l', ylab='Gallons sold', xlab='Day',
         axes=FALSE, cex.lab=1.5, ...)
    axis(2, cex.axis=1.5)
    axis(1, cex.axis=1.5, labels=colnames(pd), at=1:ncol(pd))
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

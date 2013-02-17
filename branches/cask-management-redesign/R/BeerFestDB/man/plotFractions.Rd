\name{plotFractions}
\alias{plotFractions}
\title{
  Plot a graph of the fraction of product remaining over time.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
plotFractions(data, clusters = rownames(data), cols = 1:9, lty = 1:9, ylim = c(0, 1), leg.pos = "bottomleft", ylab = "Fraction remaining", ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{data}{
%%     ~~Describe \code{data} here~~
}
  \item{clusters}{
%%     ~~Describe \code{clusters} here~~
}
  \item{cols}{
%%     ~~Describe \code{cols} here~~
}
  \item{lty}{
%%     ~~Describe \code{lty} here~~
}
  \item{ylim}{
%%     ~~Describe \code{ylim} here~~
}
  \item{leg.pos}{
%%     ~~Describe \code{leg.pos} here~~
}
  \item{ylab}{
%%     ~~Describe \code{ylab} here~~
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
function(data, clusters=rownames(data),
                          cols=1:9, lty=1:9, ylim=c(0,1),
                          leg.pos='bottomleft', ylab='Fraction remaining', ...) {

    if ( length( clusters ) > length( cols ) )
        cols <- colorRampPalette( cols )( length( clusters ) )

    matplot(t(data[clusters,, drop=FALSE]), col=cols,
            type='l', lwd=2, lty=lty, ylim=ylim, axes=FALSE,
            xlab='Dip Time', ylab=ylab, cex.lab=1.5, cex.main=1.5, ...)

    axis(2, cex.axis=1.5)

    axis(1, cex.axis=1.5, labels=colnames(data), at=1:ncol(data))

    legend(leg.pos, legend=clusters, fill=cols, cex=1.3)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

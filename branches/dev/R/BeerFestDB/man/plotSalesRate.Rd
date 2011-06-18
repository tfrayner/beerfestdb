\name{plotSalesRate}
\alias{plotSalesRate}
\title{
  Use plotFractions to plot sales rates for a given set of categories
  over time.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
plotSalesRate(cp, colname, w = TRUE, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{cp}{
%%     ~~Describe \code{cp} here~~
}
  \item{colname}{
%%     ~~Describe \code{colname} here~~
}
  \item{w}{
%%     ~~Describe \code{w} here~~
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
function( cp, colname, w=TRUE, ... ) {
    dp <- aggData( cp, colname, w )
    cols <- brewer.pal(9, 'Set1')
    plotFractions( dp / dp[,1], cols=cols, ... )
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

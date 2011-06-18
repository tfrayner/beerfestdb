\name{aggData}
\alias{aggData}
\title{
Function to aggregate dip data by a given factor.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
aggData(cp, colname, w = TRUE)
}
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
function( cp, colname, w=TRUE ) {
    dp <- aggregate( cp[ ,w], lapply(colname, function(x) { cp[, x] }), sum)

    rownames(dp) <- apply(dp[,c(1:length(colname)), drop=FALSE], 1, paste, collapse=':')
    dp <- dp[,-c(1:length(colname))]
    colnames(dp)[1] <- 'Start'

    return(dp)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

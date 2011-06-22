\name{plotModelCoeffs}
\alias{plotModelCoeffs}
\title{
Plot a bar graph comparing starting quantities with observed sales rates.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
plotModelCoeffs(cp, colname, drop, w = TRUE, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{cp}{
%%     ~~Describe \code{cp} here~~
}
  \item{colname}{
%%     ~~Describe \code{colname} here~~
}
  \item{drop}{
%%     ~~Describe \code{drop} here~~
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
function(cp, colname, drop, w=TRUE, ... ) {

    dp <- aggData(cp, colname, w)

    pred <- aggregate( cp$cask_volume, list(cp[, colname]), sum )[,2] / ncol(dp)
    pred <- (pred/sum(pred)) * 100

    dp <- dp[, ! colnames(dp) \%in\% drop ]

    fm <- data.frame(dip=as.numeric(t(dp)),
                     time=rep(0:(ncol(dp)-1), nrow(dp)),
                     category=unlist(lapply(rownames(dp), rep, ncol(dp))))
    l <- lm(dip~0+time+category, data=fm)

    ## FIXME consider also using the std. error estimates to generate error bars.

    x <- summary(l)$coefficients[-1,1]
    x <- (x/sum(x)) * 100
    names(x) <- sub('category', '', names(x))

    old.par <- par(mar=c(5,12,2,2))
    bp <- barplot(rbind(x, pred), beside=TRUE, ylab='', yaxt='n', horiz=TRUE,
                  xlab='Percent total', legend.text=c('Observed', 'Predicted'),
                  args.legend=list(x='topright', cex=1.2), col=c('blue','yellow'),
                  cex.axis=1.5, cex.lab=1.5)
    text(y=apply(bp, 2, mean), labels=names(x), x=par("usr")[1] - 1.5, adj = 1, xpd = TRUE, cex=1.5)
    par(old.par)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line

##
## This file is part of BeerFestDB, a beer festival product management
## system.
##
## Copyright (C) 2011 Tim F. Rayner
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
## $Id$

###############################################################################
#' Fit a linear model to grouped dip values over time
#' @description Fits a linear model of cumulative sales as a function of dip
#'   time and category and returns the resulting model.
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param group A character string naming the column in \code{cp} to use
#'   as the grouping category (e.g., \code{"style"}, \code{"region"}).
#' @param drop A character vector of dip-time column names to exclude from
#'   the model (typically the final sessions where sales become non-linear).
#' @param w A logical vector selecting the volume and dip columns of
#'   \code{cp}.
#' @param ... Additional arguments (currently unused).
#' @return lm model with time*category coefficients.
#' @importFrom stats lm
#' @importFrom tibble rownames_to_column
#' @importFrom reshape2 melt
fitModelCoeffs <- function(cp, group, drop, w = TRUE, ...) {
  
  cp[[group]] <- factor(cp[[group]])

  # Sum the remaining dip volumes by group for each dip time
  dp <- aggData(cp, group, w)

  # Drop the columns as specified. These will typically be trailing dips late in
  # the festival which are expected to be non-linear.
  dp <- dp[, !colnames(dp) %in% drop]
  
  # Convert to cumulative sales by subtracting the remaining volume from the
  # starting volume
  dp <- dp$Start - dp

  fm <- dp %>%
    rownames_to_column(var = group) %>%
    reshape2::melt(id.vars = group, variable.name = "time", value.name = "dip")
  
  levels(fm$time) <- 1:nlevels(fm$time)
  fm$time <- as.numeric(fm$time) - 1
  colnames(fm)[1] <- 'category'
  fm$category <- factor(fm$category, levels=levels(cp[[group]]))

  ## We're looking for the time:category interaction term
  ## here.
  l <- lm(dip ~ time * category, data = fm)

  return(l)
}

###############################################################################
#' Summarize the output of fitModelCoeffs into a data frame for plotting
#' @description Summarizes the output of \code{fitModelCoeffs} into a data frame
#'   suitable for plotting.
#' @param l The linear model returned by \code{fitModelCoeffs}.
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param group A character string naming the column in \code{cp} to use
#'   as the grouping category (e.g., \code{"style"}, \code{"region"}).
#' @return A data frame suitable for plotting, containing the predicted and observed sales rates for each category.
#' @seealso \code{\link{fitModelCoeffs}}, \code{\link{plotModelCoeffs}}
#' @importFrom dplyr '%>%' group_by summarize mutate pull
summarizeModel <- function(l, cp, group) {
  
  cp[[group]] <- factor(cp[[group]])

  # Calculate the percentage of the initial order that corresponds to each group.
  # This is treated as our prediction for the sales rate going into the festival.
  pred <- cp %>% drop_na() %>%
    group_by(get(group)) %>%
    summarize(total=sum(cask_volume, na.rm=TRUE)) %>%
    mutate(pred = (total / sum(total)) * 100) %>%
    pull(pred)

  ## FIXME consider also using the model std. error estimates to generate error bars.

  # For each category, calculate the total time coefficient for sales (total
  # sales rate) and express it as a percentage of the total sales across all categories.
  ncat <- nlevels(cp[[group]])
  x <- l$coefficients
  x <- data.frame(
    category = levels(cp[[group]]),
    pred = pred,
    rate = c(x[2], x[(ncat + 2):(2 * ncat)] + x[2])
  ) %>%
    mutate(rate = (rate / sum(rate)) * 100)

  return(x)
}

###############################################################################
#' Plot a bar chart comparing starting quantities with observed sales rates
#' @description Fits a linear model of cumulative sales as a function of dip
#'   time and category, then draws a horizontal grouped bar chart comparing
#'   each category's observed sale-rate share with the share predicted from
#'   its starting volume.
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param group A character string naming the column in \code{cp} to use
#'   as the grouping category (e.g., \code{"style"}, \code{"region"}).
#' @param drop A character vector of dip-time column names to exclude from
#'   the model (typically the final sessions where sales become non-linear).
#' @param w A logical vector selecting the volume and dip columns of
#'   \code{cp}.
#' @param ... Additional arguments (currently unused).
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @seealso \code{\link{aggData}}, \code{\link{analyseData}}
#' @importFrom ggplot2 ggplot aes geom_bar labs theme_minimal coord_flip scale_fill_manual theme element_text
#' @importFrom reshape2 melt
#' @export
###############################################################################
plotModelCoeffs <- function(cp, group, drop, w = TRUE, ...) {
  
  cp[[group]] <- factor(cp[[group]])

  l <- fitModelCoeffs(cp, group, drop, w, ...)

  x <- summarizeModel(l, cp, group)

  x %>% reshape2::melt() %>%
  ggplot(aes(x = category, y = value, fill = variable)) +
    geom_bar(stat = "identity", position = "dodge", colour = "black") +
    labs(x = group, y = "Percent total") +
    theme_minimal() + coord_flip() +
    scale_fill_manual(values = c("blue", "yellow"), name = "", labels = c("Observed", "Predicted")) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

###############################################################################
#' Plot a bar chart showing ratio of observed sales rates to starting quantities
#' @description Fits a linear model of cumulative sales as a function of dip
#'   time and category, then draws a horizontal grouped bar chart showing
#'   the ratio of each category's observed sale-rate share to the share predicted from
#'   its starting volume. In principle one can take these ratios as a recommendation of
#'   how to modify future orders (i.e. multiply previous order by the ratio to get a
#'   closer match to sales).
#' @param cp A data frame of cask/dip data, typically from
#'   \code{\link{getFestivalData}}.
#' @param group A character string naming the column in \code{cp} to use
#'   as the grouping category (e.g., \code{"style"}, \code{"region"}).
#' @param drop A character vector of dip-time column names to exclude from
#'   the model (typically the final sessions where sales become non-linear).
#' @param w A logical vector selecting the volume and dip columns of
#'   \code{cp}.
#' @param ... Additional arguments (currently unused).
#' @return Invisibly returns \code{NULL} (called for its side effect of
#'   producing a plot).
#' @seealso \code{\link{aggData}}, \code{\link{analyseData}}
#' @importFrom ggplot2 ggplot aes geom_bar labs theme_minimal coord_flip scale_fill_manual theme element_text
#' @importFrom reshape2 melt
#' @export
###############################################################################
plotModelRatio <- function(cp, group, drop, w = TRUE, ...) {
  
  cp[[group]] <- factor(cp[[group]])

  l <- fitModelCoeffs(cp, group, drop, w, ...)

  x <- summarizeModel(l, cp, group) %>%
    mutate(ratio = rate / pred)

  x %>%
  ggplot(aes(x = category, y = ratio)) +
    geom_bar(stat = "identity", position = "dodge", colour = "black") +
    labs(x = group, y = "Recommended change") +
    theme_minimal() +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
    coord_cartesian(ylim = c(0, max(x$ratio, 2))) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

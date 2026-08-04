##
## This file is part of BeerFestDB, a beer festival product management
## system.
##
## Copyright (C) 2011-2026 Tim F. Rayner
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
#' Plot overall beer sales over time
#' @description Sums per-session sales across all products and draws a line
#'   chart of total gallons sold per session.
#' @param festival A Festival object as returned by \code{\link{getFestivalData}}.
#' @return A ggplot2 object.
#' @seealso \code{\link{analyseData}}
#' @importFrom ggplot2 ggplot aes geom_line geom_point labs theme_minimal theme element_text
#' @export
###############################################################################
plotTotalBeerSales <- function(festival) {
  sales <- festival$per_diem_sales() %>%
    select(all_of(festival$dip_cols)) %>%
    apply(2, sum)

  day <- factor(festival$dip_cols, levels = festival$dip_cols)
  d <- data.frame(day = day, gallons_sold = sales)

  ggplot(d, aes(x = day, y = gallons_sold, group = 1)) +
    geom_line(size = 1) +
    geom_point(size = 2) +
    labs(x = "Day", y = "Gallons sold") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

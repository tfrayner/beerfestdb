###############################################################################
#' Programmatic tabset creation in quarto/Rmd
#' @description This is a utility function that can be used to transform a list
#' of R objects (e.g. ggplot objects) into an HTML tabset embedded in your
#' quarto or Rmarkdown document.
#' @details Chunks which include a call to this function should also include
#' the `#| results: asis` directive so that the output renders properly. For a
#' full explanation, see
#' [quarto
#' tabsets](https://josh.quarto.pub/posts/2022-09-29-quarto-tabsets/2022-09-29-quarto-tabsets.html).
#' Known bug: the output of the `summary.lm()` function is known to interfere
#' with the rendering of outputs (presenting as a YAML parsing bug during
#' processing).
#' @author Josh Cowley
#' @param .x A list of R objects (e.g. ggplot or data frame objects)
#' @param .f A function that transforms the R objects into the desired visual output (e.g. `plot`; `DT::datatable`)
#' @param type The type of document we're creating (`quarto` or `rmd`)
#' @param ... additional arguments passed to the `.f` function
#' @return a list containing the results and plot data
#' @importFrom purrr as_mapper
#' @export
###############################################################################

knitr_tabset <- function(.x, .f, type = c("quarto", "rmd"), ...) {
  if (missing(.f)) .f <- print
  .f <- purrr::as_mapper(.f, ...)

  nms <- if (is.null(names(.x))) seq_along(.x) else names(.x)

  header <-
    switch(match.arg(type),
      quarto = ":::: {.panel-tabset}",
      rmd = "#### { .tabset .unlisted .unnumbered}"
    )

  footer <-
    switch(match.arg(type),
      quarto = "::::",
      rmd = "#### {.unlisted .unnumbered}"
    )

  cat(header, "\n\n", sep = "")

  for (i in seq_along(.x)) {
    cat("##### ", nms[i], "\n\n", sep = "")
    .f(.x[[i]], ...)
    cat("\n\n")
  }

  cat(footer)

  invisible(.x)
}

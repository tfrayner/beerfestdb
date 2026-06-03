## Tests for knitr_tabset()
##
## knitr_tabset() writes quarto/Rmd tabset markup to stdout and calls the
## supplied function on each list element.  capture.output() is used to
## inspect the printed output without side-effects.

test_that("knitr_tabset emits quarto panel-tabset delimiters", {
  out <- capture.output(
    knitr_tabset(list(a = 1, b = 2), print, type = "quarto")
  )

  expect_true(any(grepl("panel-tabset", out, fixed = TRUE)))
  expect_true(any(grepl("::::", out, fixed = TRUE)))
})

test_that("knitr_tabset emits rmd tabset delimiters", {
  out <- capture.output(
    knitr_tabset(list(x = 1), print, type = "rmd")
  )

  expect_true(any(grepl("tabset", out, fixed = TRUE)))
})

test_that("knitr_tabset emits a header for each named element", {
  out <- capture.output(
    knitr_tabset(list(Alpha = 1, Beta = 2), print, type = "quarto")
  )

  expect_true(any(grepl("##### Alpha", out, fixed = TRUE)))
  expect_true(any(grepl("##### Beta",  out, fixed = TRUE)))
})

test_that("knitr_tabset uses integer indices for unnamed lists", {
  out <- capture.output(
    knitr_tabset(list(10, 20), print, type = "quarto")
  )

  expect_true(any(grepl("##### 1", out, fixed = TRUE)))
  expect_true(any(grepl("##### 2", out, fixed = TRUE)))
})

test_that("knitr_tabset calls the transform function for every element", {
  calls <- 0L
  counter <- function(x) { calls <<- calls + 1L }

  capture.output(
    knitr_tabset(list(a = 1, b = 2, c = 3), counter, type = "quarto")
  )

  expect_equal(calls, 3L)
})

test_that("knitr_tabset returns the input list invisibly", {
  input <- list(a = 1, b = 2)
  result <- capture.output(ret <- knitr_tabset(input, print, type = "quarto"))

  expect_equal(ret, input)
})

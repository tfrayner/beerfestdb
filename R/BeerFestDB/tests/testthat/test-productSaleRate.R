## Tests for productSaleRate()
##
## productSaleRate() trims leading and trailing non-sale plateaux from a
## vector of dip readings, normalises to zero at the end, then fits a
## simple linear model and returns c(Estimate, Std.Error) for the slope.
## A positive estimate means volume is decreasing (selling).

test_that("productSaleRate returns correct rate for a perfect linear decrease", {
  y <- c(10, 8, 6, 4, 2, 0)
  result <- productSaleRate(y)

  expect_length(result, 2)
  expect_equal(result[["Estimate"]],   2.0, tolerance = 1e-10)
  expect_equal(result[["Std. Error"]], 0.0, tolerance = 1e-10)
})

test_that("productSaleRate trims a leading plateau before fitting", {
  ## The leading plateau of 10s should be collapsed to a single leading value.
  y <- c(10, 10, 10, 8, 6, 4, 2, 0)
  result <- productSaleRate(y)

  expect_equal(result[["Estimate"]], 2.0, tolerance = 1e-10)
})

test_that("productSaleRate trims a trailing plateau before fitting", {
  ## The trailing plateau of 0s should be collapsed to a single trailing value.
  y <- c(10, 8, 6, 4, 2, 0, 0, 0)
  result <- productSaleRate(y)

  expect_equal(result[["Estimate"]], 2.0, tolerance = 1e-10)
})

test_that("productSaleRate handles both leading and trailing plateaux", {
  y <- c(12, 12, 10, 8, 6, 4, 2, 0, 0)
  result <- productSaleRate(y)

  expect_equal(result[["Estimate"]], 2.0, tolerance = 1e-10)
})

test_that("productSaleRate returns a named numeric vector", {
  result <- productSaleRate(c(6, 4, 2, 0))

  expect_true(is.numeric(result))
  expect_named(result, c("Estimate", "Std. Error"))
})

test_that("productSaleRate estimate scales with the rate of decrease", {
  slow <- productSaleRate(c(10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0))
  fast <- productSaleRate(c(10, 8, 6, 4, 2, 0))

  expect_equal(slow[["Estimate"]], 1.0, tolerance = 1e-10)
  expect_equal(fast[["Estimate"]], 2.0, tolerance = 1e-10)
  expect_gt(fast[["Estimate"]], slow[["Estimate"]])
})

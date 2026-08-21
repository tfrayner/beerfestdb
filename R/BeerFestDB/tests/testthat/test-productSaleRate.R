## Tests for productSaleRate() (productSaleRate.R)
##
## productSaleRate() takes a data frame with a 'cask_volume' column and one or
## more dip columns, removes casks that were never put on sale, trims leading
## and trailing non-sale plateaux, fits a mixed-effects linear model across all
## casks, and returns the estimated gallons sold per session (positive numeric).

## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------

## Build a simple single-cask data frame with a perfect linear decrease.
make_single_cask_df <- function(dips = c(10, 8, 6, 4, 2, 0), volume = 10) {
  df <- as.data.frame(matrix(c(volume, dips), nrow = 1))
  colnames(df) <- c("cask_volume", paste0("dip.", seq_along(dips)))
  df
}

## Build a two-cask data frame where both casks have perfect linear decreases.
make_two_cask_df <- function() {
  data.frame(
    cask_volume = c(10, 20),
    dip.1 = c(8, 16),
    dip.2 = c(6, 12),
    dip.3 = c(4,  8),
    dip.4 = c(2,  4)
  )
}

## ---------------------------------------------------------------------------
## Tests
## ---------------------------------------------------------------------------

test_that("productSaleRate returns a positive numeric for a perfect linear cask", {
  df     <- make_single_cask_df()
  result <- productSaleRate(df, paste0("dip.", 1:6))
  expect_true(is.numeric(result))
  expect_length(result, 1)
  expect_gt(result, 0)
})

test_that("productSaleRate estimates the correct rate for a single linearly decreasing cask", {
  ## Volume drops by 2 per session → expected rate ≈ 2
  df     <- make_single_cask_df(dips = c(10, 8, 6, 4, 2, 0), volume = 10)
  result <- productSaleRate(df, paste0("dip.", 1:6))
  expect_equal(result, 2.0, tolerance = 0.1)
})

test_that("productSaleRate returns NA when all casks were never put on sale", {
  df <- data.frame(
    cask_volume = c(10, 10),
    dip.1 = c(10, 10),
    dip.2 = c(10, 10),
    dip.3 = c(10, 10)
  )
  result <- productSaleRate(df, paste0("dip.", 1:3))
  expect_true(is.na(result))
})

test_that("productSaleRate handles a data frame with two casks", {
  df     <- make_two_cask_df()
  result <- productSaleRate(df, paste0("dip.", 1:4))
  expect_true(is.numeric(result))
  expect_gt(result, 0)
})

test_that("productSaleRate rate scales with the speed of decrease", {
  slow_df <- data.frame(cask_volume = 10,
                        dip.1 = 9, dip.2 = 8, dip.3 = 7,
                        dip.4 = 6, dip.5 = 5, dip.6 = 4)
  fast_df <- data.frame(cask_volume = 10,
                        dip.1 = 8, dip.2 = 6, dip.3 = 4, dip.4 = 2)

  slow <- productSaleRate(slow_df, paste0("dip.", 1:6))
  fast <- productSaleRate(fast_df, paste0("dip.", 1:4))

  expect_gt(fast, slow)
})

test_that("productSaleRate uses only the specified dip_cols", {
  ## Provide extra dip columns that are all flat; only the active columns
  ## should be used and the result should still be positive.
  df <- data.frame(
    cask_volume = 10,
    dip.1 = 8, dip.2 = 6, dip.3 = 4,
    dip.extra = 99  # should be ignored
  )
  result <- productSaleRate(df, c("dip.1", "dip.2", "dip.3"))
  expect_gt(result, 0)
})

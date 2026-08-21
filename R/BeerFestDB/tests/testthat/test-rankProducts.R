## Tests for rankProducts()
##
## rankProducts() takes a cask data frame (cp), a character vector of
## dip-time columns to exclude (drop), and a logical column-selector (w).
## It returns a data frame of products ranked by average sales rate
## (gallons per session), ascending.

## Helper: build a minimal cask data frame with two beers whose dips
## decrease perfectly linearly.
make_cp <- function() {
    data.frame(
      festival_ref = c(1,           2),
      company_name = c("Brewery A", "Brewery B"),
      product_name = c("Beer 1",    "Beer 2"),
      stillage     = c("Bar 1",     "Bar 1"),
      style        = c("Bitter",    "IPA"),
      abv          = c(4.0,         5.0),
      is_condemned = c(FALSE,       FALSE),
      cask_volume  = c(10.0,        20.0),
      dip.1        = c(8.0,         16.0),
      dip.2        = c(6.0,         12.0),
      dip.3        = c(4.0,          8.0),
      dip.4        = c(2.0,          4.0),
      stringsAsFactors = FALSE
    )
}

make_festival <- function() {
  Festival$new(make_cp())
}

test_that("rankProducts returns a data frame with the expected columns", {
  result <- rankProducts(make_festival(), character(0))

  expect_s3_class(result, "data.frame")
  expect_equal(
    colnames(result),
    c("company_name", "product_name", "style", "abv", "gallons_per_session")
  )
})

test_that("rankProducts includes one row per product", {
  result <- rankProducts(make_festival(), character(0))
  expect_equal(nrow(result), 2)
})

test_that("rankProducts estimates sale rates from dip data", {
  result <- rankProducts(make_festival(), character(0))

  ## Beer 1 drops by 2 per session → rate ≈ 2; Beer 2 by 4 → rate ≈ 4
  beer1 <- result[result$product_name == "Beer 1",][["gallons_per_session"]]
  beer2 <- result[result$product_name == "Beer 2",][["gallons_per_session"]]

  expect_equal(beer1, 2.0, tolerance = 1e-6)
  expect_equal(beer2, 4.0, tolerance = 1e-6)
})

test_that("rankProducts sorts results descending by gallons_per_session", {
  result <- rankProducts(make_festival(), character(0))

  expect_true(result$gallons_per_session[2] <= result$gallons_per_session[1])
})

test_that("rankProducts excludes beers that never changed during the query period", {
  cp <- make_cp()
  ## Append a third beer whose dips never change (no sales)
  static_row <- data.frame(
    festival_ref = 3,
    company_name = "Brewery C", product_name = "Beer 3",
    stillage = "Bar 2",
    style = "Lager", abv = 3.5,
    is_condemned = FALSE,
    cask_volume = 8.0, dip.1 = 8.0, dip.2 = 8.0, dip.3 = 8.0, dip.4 = 8.0,
    stringsAsFactors = FALSE
  )
  cp3 <- Festival$new(rbind(cp, static_row))

  result <- rankProducts(cp3, character(0))

  expect_equal(nrow(result), 2)
  expect_false("Beer 3" %in% result$product_name)
})

test_that("rankProducts respects the drop argument", {
  cp <- make_festival()
  ## Drop the last two dip columns; the remaining data still has a
  ## linear trend so rates should still be estimable.
  result_full <- rankProducts(cp, character(0))
  result_drop <- rankProducts(cp, c("dip.3", "dip.4"))

  ## Both should return 2 rows
  expect_equal(nrow(result_drop), 2)
  ## Beer ordering should be preserved (fastest first)
  expect_true(result_drop$gallons_per_session[2] <= result_drop$gallons_per_session[1])
})

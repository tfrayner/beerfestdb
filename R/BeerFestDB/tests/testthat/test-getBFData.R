## Tests for getBFData()
##
## getBFData() calls queryBFDB() to fetch a list of named lists from the API,
## then converts the result into a normalised data frame. queryBFDB() is
## mocked using testthat::local_mocked_bindings() so no network connection
## is needed.

test_that("getBFData constructs a data frame from query results", {
  mock_objects <- list(
    list(name = "Beer A", brewery = "Brewery 1", beer_id = "1"),
    list(name = "Beer B", beer_id = "2")   # missing 'brewery'
  )

  local_mocked_bindings(
    queryBFDB = function(...) mock_objects,
    .package = "BeerFestDB"
  )

  result <- getBFData("Cask", "list", auth = list())

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_setequal(colnames(result), c("name", "brewery", "beer_id"))
})

test_that("getBFData fills missing fields with NA", {
  mock_objects <- list(
    list(name = "Beer A", brewery = "Brewery 1", beer_id = "1"),
    list(name = "Beer B", beer_id = "2")   # missing 'brewery'
  )

  local_mocked_bindings(
    queryBFDB = function(...) mock_objects,
    .package = "BeerFestDB"
  )

  result <- getBFData("Cask", "list", auth = list())

  expect_setequal(colnames(result), c("name", "brewery", "beer_id"))
  expect_equal(nrow(result), 2)
  expect_equal(result[result$name == "Beer A", "brewery"], "Brewery 1")
  expect_true(is.na(result[result$name == "Beer B", "brewery"]))
})

test_that("getBFData converts *_id columns to integer", {
  mock_objects <- list(
    list(name = "Beer A", beer_id = "1"),
    list(name = "Beer B", beer_id = "2")
  )

  local_mocked_bindings(
    queryBFDB = function(...) mock_objects,
    .package = "BeerFestDB"
  )

  result <- getBFData("Cask", "list", auth = list())

  expect_true(is.integer(result$beer_id))
  expect_equal(result[result$name == "Beer A", "beer_id"], 1L)
  expect_equal(result[result$name == "Beer B", "beer_id"], 2L)
})

test_that("getBFData selects only the specified columns", {
  mock_objects <- list(
    list(name = "Beer A", brewery = "Brewery 1", beer_id = "1"),
    list(name = "Beer B", brewery = "Brewery 2", beer_id = "2")
  )

  local_mocked_bindings(
    queryBFDB = function(...) mock_objects,
    .package = "BeerFestDB"
  )

  result <- getBFData("Cask", "list", columns = c("name", "beer_id"), auth = list())

  expect_equal(colnames(result), c("name", "beer_id"))
  expect_equal(nrow(result), 2)
  expect_false("brewery" %in% colnames(result))
})

test_that("getBFData returns an empty data frame with correct columns when no results", {
  local_mocked_bindings(
    queryBFDB = function(...) list(),
    .package = "BeerFestDB"
  )

  result <- getBFData("Cask", "list", columns = c("name", "beer_id"), auth = list())

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_equal(colnames(result), c("name", "beer_id"))
})

test_that("getBFData errors when results are missing a requested column", {
  mock_objects <- list(
    list(name = "Beer A", beer_id = "1")
  )

  local_mocked_bindings(
    queryBFDB = function(...) mock_objects,
    .package = "BeerFestDB"
  )

  expect_error(
    getBFData("Cask", "list", columns = c("name", "nonexistent_col"), auth = list()),
    "missing columns"
  )
})

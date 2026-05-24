## Tests for aggData()
##
## aggData() aggregates (sums) the numeric columns of a data frame
## selected by a logical vector `w`, grouped by one or more named columns
## (`colname`). The grouping columns are removed from the result,
## rownames are set to pasted group keys, and the first numeric column
## is renamed "Start".

test_that("aggData sums values by a single grouping column", {
  cp <- data.frame(
    style        = c("Bitter", "Bitter", "IPA", "IPA"),
    cask_volume  = c(10.0, 20.0, 15.0, 25.0),
    dip_t1       = c(8.0,  16.0, 12.0, 20.0),
    stringsAsFactors = FALSE
  )
  w <- c(FALSE, TRUE, TRUE)  # select cask_volume and dip_t1

  result <- aggData(cp, "style", w)

  expect_equal(nrow(result), 2)
  ## aggregate() sorts groups alphabetically
  expect_equal(rownames(result), c("Bitter", "IPA"))
  ## First numeric column is renamed "Start"
  expect_equal(colnames(result)[1], "Start")
  ## Check summed values
  expect_equal(result["Bitter", "Start"],  30.0)  # 10 + 20
  expect_equal(result["IPA",    "Start"],  40.0)  # 15 + 25
  expect_equal(result["Bitter", "dip_t1"], 24.0)  # 8 + 16
  expect_equal(result["IPA",    "dip_t1"], 32.0)  # 12 + 20
})

test_that("aggData removes the grouping column(s) from the result", {
  cp <- data.frame(
    style       = c("Bitter", "IPA"),
    cask_volume = c(10.0, 20.0),
    stringsAsFactors = FALSE
  )
  w <- c(FALSE, TRUE)

  result <- aggData(cp, "style", w)

  expect_false("style"   %in% colnames(result))
  expect_false("Group.1" %in% colnames(result))
})

test_that("aggData handles two grouping columns and builds composite rownames", {
  cp <- data.frame(
    style  = c("Bitter", "Bitter", "IPA"),
    region = c("East",   "East",   "West"),
    val    = c(10.0, 20.0, 30.0),
    stringsAsFactors = FALSE
  )
  w <- c(FALSE, FALSE, TRUE)

  result <- aggData(cp, c("style", "region"), w)

  expect_equal(nrow(result), 2)
  expect_true("Bitter:East" %in% rownames(result))
  expect_true("IPA:West"    %in% rownames(result))
  expect_equal(result["Bitter:East", "Start"], 30.0)  # 10 + 20
  expect_equal(result["IPA:West",    "Start"], 30.0)
})

test_that("aggData produces a single-row result when all rows share the same group", {
  cp <- data.frame(
    style       = c("Bitter", "Bitter", "Bitter"),
    cask_volume = c(5.0, 10.0, 15.0),
    stringsAsFactors = FALSE
  )
  w <- c(FALSE, TRUE)

  result <- aggData(cp, "style", w)

  expect_equal(nrow(result), 1)
  expect_equal(rownames(result), "Bitter")
  expect_equal(result["Bitter", "Start"], 30.0)  # 5 + 10 + 15
})

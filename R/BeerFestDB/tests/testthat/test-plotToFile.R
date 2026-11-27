## Tests for plotToFile() (plotToFile.R)
##
## plotToFile() opens a PDF device, calls the supplied plotting function, and
## closes the device.  Tests use a trivial plotting function to avoid any
## dependency on festival data or external packages.

## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------

## A minimal plotting function that draws nothing but returns a sentinel value.
null_plot <- function(...) {
  plot.new()
  invisible("sentinel")
}

## ---------------------------------------------------------------------------
## Tests
## ---------------------------------------------------------------------------

test_that("plotToFile() creates a PDF file at the specified path", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))

  plotToFile(tmp, null_plot)

  expect_true(file.exists(tmp))
  expect_gt(file.size(tmp), 0L)
})

test_that("plotToFile() creates valid PDF output (magic bytes)", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))

  plotToFile(tmp, null_plot)

  raw_header <- readBin(tmp, what = "raw", n = 4)
  ## PDF files start with the bytes for "%PDF"
  expect_equal(rawToChar(raw_header), "%PDF")
})

test_that("plotToFile() calls the supplied function with extra arguments", {
  tmp    <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  called <- FALSE

  spy_fn <- function(x, y) {
    called <<- TRUE
    expect_equal(x, "arg1")
    expect_equal(y, 42)
    plot.new()
    invisible(NULL)
  }

  plotToFile(tmp, spy_fn, "arg1", 42)
  expect_true(called)
})

test_that("plotToFile() closes the device even after the plotting function returns", {
  ## Record the open device count before and after; it should be the same.
  tmp        <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  dev_before <- length(grDevices::dev.list())

  plotToFile(tmp, null_plot)

  dev_after <- length(grDevices::dev.list())
  expect_equal(dev_after, dev_before)
})

test_that("plotToFile() returns invisibly", {
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))

  ## withVisible() tells us whether the return value was visible.
  result <- withVisible(plotToFile(tmp, null_plot))
  expect_false(result$visible)
})

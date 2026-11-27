## Tests for the Festival R6 class (Festival.R)
##
## Covers: initialize(), $data, $dip_cols, $meta_cols, $stillages,
##         $subset(), $cask_dips(), $product_dips(), $grouped_dips(),
##         $per_diem_sales(), $grouped_per_diem_sales(), $write_csv().

## ---------------------------------------------------------------------------
## Shared helpers
## ---------------------------------------------------------------------------

make_minimal_df <- function() {
  data.frame(
    festival_ref = c(1L, 2L, 3L),
    company_name = c("Brewery A", "Brewery A", "Brewery B"),
    product_name = c("Ale",       "Ale",       "Stout"),
    stillage     = c("Bar 1",     "Bar 1",     "Bar 2"),
    style        = c("Bitter",    "Bitter",    "Stout"),
    region       = c("Midlands",  "Midlands",  "London"),
    abv          = c(4.0,          4.0,         5.0),
    is_condemned = c(0L,           0L,          0L),
    cask_volume  = c(10.0,        10.0,        20.0),
    dip.1        = c(8.0,          8.0,        16.0),
    dip.2        = c(6.0,          6.0,        12.0),
    dip.3        = c(4.0,          4.0,         8.0),
    stringsAsFactors = FALSE
  )
}

make_fest <- function() Festival$new(make_minimal_df())

## ---------------------------------------------------------------------------
## initialize()
## ---------------------------------------------------------------------------

test_that("Festival$new() accepts a valid data frame and returns a Festival", {
  fest <- make_fest()
  expect_s3_class(fest, "Festival")
})

test_that("Festival$new() stops when `data` is not a data frame", {
  expect_error(Festival$new(list(a = 1)), "`data` must be a data frame")
})

test_that("Festival$new() stops when a required column is missing", {
  df <- make_minimal_df()
  df$cask_volume <- NULL
  expect_error(Festival$new(df), "cask_volume")
})

test_that("Festival$new() stops when there are no dip columns", {
  df <- make_minimal_df()
  df$dip.1 <- NULL
  df$dip.2 <- NULL
  df$dip.3 <- NULL
  expect_error(Festival$new(df), "dip")
})

test_that("Festival$new() stops when dipnames length mismatches dip column count", {
  expect_error(
    Festival$new(make_minimal_df(), dipnames = c("Mon", "Tue")),
    "dipnames"
  )
})

test_that("Festival$new() accepts custom dipnames", {
  fest <- Festival$new(make_minimal_df(), dipnames = c("Mon", "Tue", "Wed"))
  expect_equal(fest$dip_cols, c("Mon", "Tue", "Wed"))
})

test_that("Festival$new() replaces NA stillage with 'Unassigned'", {
  df <- make_minimal_df()
  df$stillage[1] <- NA_character_
  fest <- Festival$new(df)
  expect_true("Unassigned" %in% fest$data$stillage)
})

test_that("Festival$new() truncates long stillage names", {
  df <- make_minimal_df()
  df$stillage[1] <- "This is a very long stillage name"
  fest <- Festival$new(df)
  expect_true(any(nchar(fest$data$stillage) <= 15))
})

test_that("Festival$new() computes volume_sold correctly", {
  fest <- make_fest()
  ## volume_sold = cask_volume - volume_lost (= last dip)
  expect_equal(fest$data$volume_sold[1], 10.0 - 4.0)
})

test_that("Festival$new() computes volume_lost as cask_volume for condemned casks", {
  df <- make_minimal_df()
  df$is_condemned[1] <- 1L
  fest <- Festival$new(df)
  expect_equal(fest$data$volume_lost[1], df$cask_volume[1])
})

test_that("Festival$new() creates an abv_class factor column", {
  fest <- make_fest()
  expect_true(is.factor(fest$data$abv_class))
})

## ---------------------------------------------------------------------------
## Active bindings: $data, $dip_cols, $meta_cols, $stillages
## ---------------------------------------------------------------------------

test_that("$data renames dip columns removing the 'dip.' prefix", {
  fest <- make_fest()
  dip_names <- grep("^dip\\.", colnames(fest$data), value = TRUE)
  expect_length(dip_names, 0)
  expect_true(all(c("1", "2", "3") %in% colnames(fest$data)))
})

test_that("$dip_cols returns the display names of dip columns", {
  fest <- make_fest()
  expect_equal(fest$dip_cols, c("1", "2", "3"))
})

test_that("$meta_cols does not contain dip column names", {
  fest <- make_fest()
  expect_false(any(grepl("^dip\\.", fest$meta_cols)))
})

test_that("$stillages returns the unique stillage values", {
  fest <- make_fest()
  expect_setequal(fest$stillages, c("Bar 1", "Bar 2"))
})

## ---------------------------------------------------------------------------
## $subset()
## ---------------------------------------------------------------------------

test_that("$subset() filters by a named argument", {
  fest <- make_fest()
  sub  <- fest$subset(company_name = "Brewery B")
  expect_equal(nrow(sub$data), 1L)
  expect_equal(sub$data$product_name, "Stout")
})

test_that("$subset() accepts multiple values for a column (OR within column)", {
  fest <- make_fest()
  sub  <- fest$subset(company_name = c("Brewery A", "Brewery B"))
  expect_equal(nrow(sub$data), 3L)
})

test_that("$subset() ANDs multiple named arguments", {
  fest <- make_fest()
  sub  <- fest$subset(company_name = "Brewery A", stillage = "Bar 1")
  expect_equal(nrow(sub$data), 2L)
})

test_that("$subset() applies a logical mask", {
  fest <- make_fest()
  mask <- c(TRUE, FALSE, TRUE)
  sub  <- fest$subset(.mask = mask)
  expect_equal(nrow(sub$data), 2L)
})

test_that("$subset() combines mask and named arguments", {
  fest  <- make_fest()
  mask  <- c(TRUE, TRUE, FALSE)
  sub   <- fest$subset(.mask = mask, company_name = "Brewery A")
  expect_equal(nrow(sub$data), 2L)
})

test_that("$subset() stops on an unknown column", {
  fest <- make_fest()
  expect_error(fest$subset(nonexistent_col = "x"), "Unknown column")
})

test_that("$subset() stops when trying to filter by a dip column", {
  fest <- make_fest()
  expect_error(fest$subset(dip.1 = 8.0), "dip column")
})

test_that("$subset() stops when mask has wrong length", {
  fest <- make_fest()
  expect_error(fest$subset(.mask = c(TRUE, FALSE)), "same length")
})

test_that("$subset() stops when mask is not logical", {
  fest <- make_fest()
  expect_error(fest$subset(.mask = c(1, 0, 1)), "logical vector")
})

test_that("$subset() returns a Festival object", {
  fest <- make_fest()
  sub  <- fest$subset(company_name = "Brewery A")
  expect_s3_class(sub, "Festival")
})

## ---------------------------------------------------------------------------
## $cask_dips()
## ---------------------------------------------------------------------------

test_that("$cask_dips() returns a data frame with one row per cask", {
  fest <- make_fest()
  cd   <- fest$cask_dips()
  expect_equal(nrow(cd), 3L)
})

test_that("$cask_dips() includes festival_ref, product_name, company_name and dip columns", {
  fest <- make_fest()
  cd   <- fest$cask_dips()
  expect_true(all(c("festival_ref", "product_name", "company_name") %in% colnames(cd)))
  expect_true(all(fest$dip_cols %in% colnames(cd)))
})

test_that("$cask_dips() contains correct dip values", {
  fest <- make_fest()
  cd   <- fest$cask_dips()
  ## First row corresponds to festival_ref = 1, dip.1 = 8
  r1 <- cd[cd$festival_ref == 1, ]
  expect_equal(r1[["1"]], 8.0)
})

## ---------------------------------------------------------------------------
## $product_dips()
## ---------------------------------------------------------------------------

test_that("$product_dips() returns one row per product", {
  fest <- make_fest()
  pd   <- fest$product_dips()
  expect_equal(nrow(pd), 2L)   # "Ale" and "Stout"
})

test_that("$product_dips() sums dip volumes across casks for the same product", {
  fest <- make_fest()
  pd   <- fest$product_dips()
  ale  <- pd[pd$product_name == "Ale", ]
  ## Two Ale casks each with dip.1 = 8 → sum = 16
  expect_equal(ale[["1"]], 16.0)
})

test_that("$product_dips() includes product_name, company_name and dip columns", {
  fest <- make_fest()
  pd   <- fest$product_dips()
  expect_true(all(c("product_name", "company_name") %in% colnames(pd)))
  expect_true(all(fest$dip_cols %in% colnames(pd)))
})

## ---------------------------------------------------------------------------
## $grouped_dips()
## ---------------------------------------------------------------------------

test_that("$grouped_dips() groups by the requested metadata column", {
  fest <- make_fest()
  gd   <- fest$grouped_dips("stillage")
  expect_equal(nrow(gd), 2L)   # "Bar 1" and "Bar 2"
  expect_true("stillage" %in% colnames(gd))
})

test_that("$grouped_dips() sums dip values within each group", {
  fest <- make_fest()
  gd   <- fest$grouped_dips("stillage")
  bar1 <- gd[gd$stillage == "Bar 1", ]
  ## Two casks in Bar 1 with dip.1 = 8 each → sum = 16
  expect_equal(bar1[["1"]], 16.0)
})

test_that("$grouped_dips() stops when a non-metadata column is requested", {
  fest <- make_fest()
  expect_error(fest$grouped_dips("dip.1"), "metadata columns")
})

## ---------------------------------------------------------------------------
## $per_diem_sales()
## ---------------------------------------------------------------------------

test_that("$per_diem_sales() returns a data frame with one row per cask", {
  fest <- make_fest()
  pd   <- fest$per_diem_sales()
  expect_equal(nrow(pd), 3L)
})

test_that("$per_diem_sales() computes correct differences for dip columns", {
  fest <- make_fest()
  pd   <- fest$per_diem_sales()
  ## cask 1: dip.1=8, dip.2=6, dip.3=4; cask_volume=10
  ## per_diem col 1 = cask_volume - dip.1 = 10 - 8 = 2
  ## per_diem col 2 = dip.1 - dip.2 = 8 - 6 = 2
  r1 <- pd[pd$festival_ref == 1, ]
  expect_equal(r1[["1"]], 2.0)
  expect_equal(r1[["2"]], 2.0)
})

test_that("$per_diem_sales() stops when dip data contains increases (probable error)", {
  df <- make_minimal_df()
  ## Introduce an increase in dip readings for cask 1 (dip.2 > dip.1)
  df$dip.2[1] <- 9.0
  fest <- Festival$new(df)
  expect_error(fest$per_diem_sales(), "Negative per diem")
})

## ---------------------------------------------------------------------------
## $grouped_per_diem_sales()
## ---------------------------------------------------------------------------

test_that("$grouped_per_diem_sales() returns one row per group", {
  fest <- make_fest()
  gpd  <- fest$grouped_per_diem_sales("stillage")
  expect_equal(nrow(gpd), 2L)
})

test_that("$grouped_per_diem_sales() sums per-diem values within each group", {
  fest <- make_fest()
  gpd  <- fest$grouped_per_diem_sales("stillage")
  bar1 <- gpd[gpd$stillage == "Bar 1", ]
  ## Bar 1 has 2 casks, each losing 2 per session in the first period
  ## (cask_volume - dip.1 = 10 - 8 = 2 per cask)
  expect_equal(bar1[["1"]], 4.0)
})

## ---------------------------------------------------------------------------
## $write_csv()
## ---------------------------------------------------------------------------

test_that("$write_csv() creates a readable CSV file", {
  fest <- make_fest()
  tmp  <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  fest$write_csv(tmp)
  expect_true(file.exists(tmp))
  written <- read.csv(tmp, stringsAsFactors = FALSE)
  expect_s3_class(written, "data.frame")
  expect_equal(nrow(written), 3L)
})

test_that("$write_csv() output contains display dip column names (no 'dip.' prefix)", {
  fest <- make_fest()
  tmp  <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  fest$write_csv(tmp)
  written <- read.csv(tmp, stringsAsFactors = FALSE)
  expect_false(any(grepl("^dip\\.", colnames(written))))
})

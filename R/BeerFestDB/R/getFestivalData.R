##
## This file is part of BeerFestDB, a beer festival product management
## system.
##
## Copyright (C) 2011-2025 Tim F. Rayner
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

getFestivalData <- function(baseuri, festname, prodcat, auth = NULL, .opts = list()) {
  if (is.null(auth) || !inherits(auth, "CURLHandle")) {
    auth <- .getBFDBHandle(baseuri = baseuri, auth = auth, .opts = .opts)
  }

  ## Begin building the main data frame.
  festival_id <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "Festival", "list"
  ) %>%
    subset(name == festname) %>%
    pull(festival_id)

  batch <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "MeasurementBatch", "list",
    params = festival_id
  ) %>%
    mutate(measurement_time = as.Date(measurement_time)) %>%
    arrange(measurement_time)

  prodcat_id <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "ProductCategory", "list"
  ) %>%
    subset(description == prodcat) %>%
    pull(product_category_id)

  cask <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "Cask", "list",
    params = c(festival_id, prodcat_id),
    columns = c(
      "cask_id", "product_id", "container_size_id",
      "order_batch_id", "gyle_id", "stillage_location_id",
      "festival_ref", "is_condemned", "is_sale_or_return",
      "price", "comment"
    )
  ) %>%
    rename(cask_price = "price") %>%
    mutate(
      festival_ref = as.integer(festival_ref),
      is_condemned = as.integer(is_condemned),
      is_sale_or_return = as.integer(is_sale_or_return)
    ) %>%
    replace_na(list(is_condemned = 0, is_sale_or_return = 0, comment = ""))

  # FIXME we want to map between sale_price_currency and cask_price_currency, with
  # similar treatment for sale_volume and cask_volume as well. Skipped for now for convenience.
  cask <- cask %>%
    left_join(
      getBFData(
        baseuri = baseuri, auth = auth, .opts = .opts,
        "FestivalProduct", "list",
        params = c(festival_id, prodcat_id),
        columns = c(
          "product_id",
          "sale_price"
        )
      ),
      by = "product_id"
    )

  default_cask_measure <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "ContainerMeasure", "list",
    columns = c("description", "litre_multiplier")
  ) %>%
    subset(description == "gallon") %>%
    pull(litre_multiplier) %>%
    as.numeric()
  stopifnot(length(default_cask_measure) == 1)

  sizes <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "ContainerSize", "list",
    columns = c("container_size_id", "volume", "litre_multiplier", "description")
  ) %>%
    rename(cask_volume = "volume", size_name = "description") %>%
    mutate(litre_multiplier = as.numeric(litre_multiplier)) %>%
    mutate(cask_volume = as.numeric(cask_volume) * litre_multiplier / default_cask_measure) %>%
    select(container_size_id, cask_volume, size_name)

  cp <- cask %>%
    left_join(sizes, by = "container_size_id")

  product <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "Product", "list_by_festival",
    params = c(festival_id, prodcat_id),
    columns = c(
      "product_id", "company_id", "nominal_abv",
      "name", "product_style_id"
    )
  ) %>%
    rename(product_name = "name")
  cp <- cp %>%
    left_join(product, by = "product_id")

  gyle <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "Gyle", "list_by_festival",
    params = festival_id,
    columns = c("gyle_id", "abv")
  ) %>%
    rename(gyle_abv = "abv")
  cp <- cp %>%
    left_join(gyle, by = "gyle_id")

  ## Prices should be numeric.
  suppressWarnings(cp$cask_price <- as.numeric(cp$cask_price))
  suppressWarnings(cp$sale_price <- as.numeric(cp$sale_price))

  ## Sort out ABVs. If a gyle ABV is present, use it preferentially.
  suppressWarnings(cp$nominal_abv <- as.numeric(cp$nominal_abv))
  suppressWarnings(cp$gyle_abv <- as.numeric(cp$gyle_abv))
  cp <- cp %>%
    mutate(abv = ifelse(is.na(gyle_abv), nominal_abv, gyle_abv)) %>%
    select(-any_of(c("nominal_abv", "gyle_abv")))

  style <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "ProductStyle", "list",
    columns = c("product_style_id", "description")
  ) %>%
    rename(style = "description")
  cp <- cp %>%
    left_join(style, by = "product_style_id")

  company <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "Company", "list",
    columns = c("company_id", "name", "company_region_id")
  ) %>%
    rename(company_name = "name")
  cp <- cp %>%
    left_join(company, by = "company_id")

  region <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "CompanyRegion", "list",
    columns = c("company_region_id", "description")
  ) %>%
    rename(region = "description")
  cp <- cp %>%
    left_join(region, by = "company_region_id")

  stillage <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "StillageLocation", "list",
    params = festival_id,
    columns = c("stillage_location_id", "description")
  ) %>%
    rename(stillage = "description")
  cp <- cp %>%
    left_join(stillage, by = "stillage_location_id")

  orderbatch <- getBFData(
    baseuri = baseuri, auth = auth, .opts = .opts,
    "OrderBatch", "list",
    params = festival_id,
    columns = c("order_batch_id", "description")
  )
  # In the absence of an order batch in the database, the returned value will be NA
  if (nrow(orderbatch) > 0) {
    orderbatch <- orderbatch %>%
      rename(order_batch = "description")
    cp <- cp %>%
      left_join(orderbatch, by = "order_batch_id") %>%
      replace_na(list(order_batch = "Other"))
  } else {
    cp$order_batch <- NA
  }

  ## Throw out all database ID columns except cask_id.
  cp <- cp %>%
    select(-matches("(?<!cask)_id$", perl = TRUE))

  dipmat <- as.data.frame(matrix(NA, nrow = nrow(cp), ncol = nrow(batch)))
  rownames(dipmat) <- cp$cask_id
  colnames(dipmat) <- paste("dip", batch$description, sep = ".")

  for (id in cp$cask_id) {
    d <- retrieveDips(baseuri = baseuri, auth = auth, .opts = .opts, id)
    d <- unlist(lapply(batch$measurement_batch_id, function(n) {
      d[[as.character(n)]]
    }))
    dipmat[as.character(id), ] <- d
  }
  ## Dip figures need to be numeric.
  dipmat <- apply(dipmat, c(1, 2), as.numeric)
  cp <- merge(cp, dipmat, by.x = "cask_id", by.y = 0, all.x = TRUE) %>%
    mutate(cask_volume = as.numeric(cask_volume))

  return(cp)
}

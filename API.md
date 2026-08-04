# BeerFestDB Web API Documentation

BeerFestDB exposes a JSON-based API used by its ExtJS front end. All JSON
endpoints return an object of the form:

```json
{"success": true, "objects": [...]}
```

or, on error:

```json
{"success": false, "error": "message"}
```

HTTP status 403 is returned on authorisation failures. The application uses
session-based authentication; a valid session cookie must accompany all
requests except `/login` and `/openidconnect/*`.

---

## Conventions

### URL structure

Every controller maps to a path prefix derived from its name, e.g. the
`Festival` controller responds at `/festival/*`. Paths are lowercase in the
URL.

### Common actions

Most resource controllers implement the following standard actions:

| Action | Method | Path | Description |
|---|---|---|---|
| `list` | GET | `/{prefix}/list[/...]` | Returns `{success, objects:[...]}` |
| `load_form` | GET | `/{prefix}/load_form?{pk}=N` | Returns `{success, data:{...}}` for a single record |
| `submit` | POST | `/{prefix}/submit` | Create or update records. Body param `changes` = JSON array of record hashes. Returns `{success, ids:[...]}` listing the database ids for changed records |
| `delete` | POST | `/{prefix}/delete` | Delete records. Body param `changes` = JSON array of integer IDs. Returns `{success}` |
| `grid` | GET | `/{prefix}/grid[/...]` | HTML page (not a JSON endpoint) |
| `view` | GET | `/{prefix}/view/{id}` | HTML page (not a JSON endpoint) |

### Request/response formats

**List response:**
```json
{
  "success": true,
  "objects": [
    { "field1": "value", "field2": 123, ... },
    ...
  ]
}
```

**Submit request** (`application/x-www-form-urlencoded`):
```
changes=[{"field1":"value","field2":123,...},...]
```

**Delete request** (`application/x-www-form-urlencoded`):
```
changes=[1,2,3]
```

**Load-form response:**
```json
{ "success": true, "data": { "field1": "value", ... } }
```

### CSRF Protection

All state-mutating requests (POST) are protected by a CSRF token checked
automatically by the server (`Catalyst::Plugin::CSRFToken` with
`auto_check` enabled).

**Token lifetime:** 3600 seconds (1 hour).

**Obtaining the token:**

- Every response — including those to unauthenticated GET requests such as
  the login page — includes the current token in the `X-CSRF-Token`
  response header.
- HTML pages also embed the token as a JavaScript variable:
  ```js
  var csrf_token = '<token>';
  ```

**Sending the token:**

Include the token as a form body parameter named `csrf_token` in every
POST request:

```
csrf_token=<token>&changes=[...]
```

If the token is missing, stale, or invalid the server returns HTTP **403**.

**Non-browser clients** should:
1. Make a GET request to any endpoint (e.g. `GET /login`) and read the
   `X-CSRF-Token` response header.
2. Include that value as `csrf_token` in the body of all subsequent POST
   requests.
3. Refresh the token (repeat step 1) if a 403 is received due to token
   expiry.

---

### Authentication

Two authentication mechanisms are supported:

- **Password login** — `POST /login` with JSON payload (see below).
- **OpenID Connect** — handled by `/openidconnect/*` (see below).

### Authorisation

- **Admin** users can edit all records.
- **Manager** users can edit non-category-restricted records.
- **Regular users** may only edit records within their assigned product
  categories (`category_auths`).
- `User::load_form` additionally requires that the caller is either the
  target user or an admin.

---

## Authentication Endpoints

### `POST /login`

Authenticate with username and password.

**Request body param:** `data` = JSON object:
```json
{ "username": "alice", "password": "secret" }
```

**Responses:**

| Status | Body |
|---|---|
| 200 | `{"success": true, "url": "/"}` (redirect URI in stash) |
| 401 | `{"success": false, "message": "Login failed."}` |
| 403 | (no `data` param supplied — returns login form) |

---

### `GET /logout`

Destroys the current session and redirects to `/`.

---

### `GET /json_logout`

Destroys the current session and returns JSON:
```json
{ "success": true }
```

---

### `GET /openidconnect/*`

OpenID Connect flow handled by the `Catalyst::Plugin::OpenIDConnect`
plugin. Typical routes:

| Path | Description |
|---|---|
| **`/.well-known/openid-configuration`** | **OIDC discovery endpoint** |
| `/openidconnect/authorize` | OIDC authorization endpoint |
| `/openidconnect/token` | OIDC auth-token exchange |
| `/openidconnect/userinfo` | OIDC user claim retrieval |
| `/openidconnect/jwks` | OIDC jwks key discovery |
| `/openidconnect/logout` | OIDC-aware logout |

After a successful OIDC login, the browser is redirected back to the site-configured
target URI corresponding to the originator site. This destination will have been inserted as the
`back` query parameter to the top-level `/login` endpoint (which actually handles the 
authentication). Please see the OIDC specification RFCs and the `Catalyst::Plugin::OpenIDConnect` 
documentation for more information. Also see the [tool dashboard](./tool_dashboard/README.md) 
for an example of this system in use.

---

## Festival

Base path: `/festival`

### Fields

| Field | Type | Description |
|---|---|---|
| `festival_id` | integer | Primary key |
| `year` | integer | Festival year |
| `name` | string | Short name |
| `description` | string | Longer description |
| `fst_start_date` | date | Start date |
| `fst_end_date` | date | End date |
| `public_status_tag` | string | Tag identifier for public website upload (`upload_beerlist.pl`) |

### Endpoints

#### `GET /festival/list`

Returns all festivals.

**Response:** `{success, objects:[festival, ...]}`

---

#### `GET /festival/load_form?festival_id=N`

Returns a single festival record.

**Response:** `{success, data:{...}}`

---

#### `GET /festival/current_festival`

Returns the record for the current festival.

**Response:** `{success, data:{...}}`

---

#### `POST /festival/submit`

Create or update festival records.

---

#### `POST /festival/delete`

Delete festival records by ID.

---

#### `GET /festival/status/{id}` or `GET /festival/status?festival_id=N`

Returns a summary of festival stock status.

**Response:**
```json
{
  "success": true,
  "data": {
    "kils_ordered":         12.5,
    "kils_sale_or_return":  2.0,
    "kils_remaining":       8.3,
    "pct_consumed":         33.6,
    "num_beers_available":  42
  }
}
```

`kils_ordered` and `kils_sale_or_return` are totals from finalised
`ProductOrder` records, normalised to kilderkin equivalents.
`kils_remaining` is derived from the most-recent `CaskMeasurement` dip
readings. `num_beers_available` is the count of beers with on-tap casks.

---

## Company (Brewery / Distributor)

Base path: `/company`

### Fields

| Field | Type | Description |
|---|---|---|
| `company_id` | integer | Primary key |
| `name` | string | Short trading name |
| `full_name` | string | Full legal name |
| `loc_desc` | string | Location description |
| `year_founded` | integer | Year company was founded |
| `url` | string | Website URL |
| `comment` | string | Free-text notes |
| `awrs_urn` | string | HMRC AWRS registration number |
| `company_region_id` | integer | FK → CompanyRegion |

### Endpoints

#### `GET /company/list`

Returns companies. Optional query parameters filter results:

| Param | Effect |
|---|---|
| *(none)* | All companies |
| `brewer_festival_id=N` | Breweries with products entered at festival N |
| `brewer_order_batch_id=N` | Breweries present in order batch N |
| `supplier_order_batch_id=N` | Distributor companies in order batch N |

---

#### `GET /company/load_form?company_id=N`

Returns a single company record.

---

#### `POST /company/submit`

Create or update company records.

---

#### `POST /company/delete`

Delete company records by ID.

---

## Product

Base path: `/product`

### Fields

| Field | Type | Description |
|---|---|---|
| `product_id` | integer | Primary key |
| `company_id` | integer | FK → Company (brewer) |
| `company_name` | string | Brewer name (read-only, from join) |
| `name` | string | Product name |
| `description` | string | Short tasting notes |
| `long_description` | string | Extended tasting notes |
| `comment` | string | Internal notes |
| `nominal_abv` | decimal | ABV percentage |
| `product_style_id` | integer | FK → ProductStyle |
| `product_category_id` | integer | FK → ProductCategory |
| `category_name` | string | Category description (read-only, from join) |
| `is_vegan` | boolean | Whether product is vegan |
| `allergens_present` | string | Comma-separated `product_allergen_type_id` values where allergen is present |
| `allergens_absent` | string | Comma-separated `product_allergen_type_id` values where allergen is absent |

### Endpoints

#### `GET /product/list/{category_id}/{festival_id}`

Products in a category at a given festival.

#### `GET /product/list/{category_id}`

All products in a category.

#### `GET /product/list?company_id=N`

Redirects internally to `list_by_company`.

---

#### `GET /product/list_by_company/{company_id}/{category_id}`

Products by a specific company within a category.

---

#### `GET /product/list_by_festival/{festival_id}/{category_id}`

Products available at a festival within a category.

---

#### `GET /product/list_by_order_batch/{batch_id}/{category_id}`

Products within an order batch. If `?company_id=N` is also supplied,
redirects to `list_by_company`.

---

#### `GET /product/load_form?product_id=N`

Returns a single product record.

---

#### `POST /product/submit`

Create or update product records. `allergens_present` and
`allergens_absent` are stored as comma-separated ID lists; the controller
synchronises the `ProductAllergen` join table accordingly.

---

#### `POST /product/delete`

Delete product records by ID.

---

## ProductCharacteristic

A `ProductCharacteristic` records a single typed attribute value (e.g. colour,
clarity) for a `Product`. The composite primary key is
`(product_id, product_characteristic_type_id)`.

Base path: `/productcharacteristic`

### Fields

| Field | Type | Description |
|---|---|---|
| `product_id` | integer | FK → Product (part of composite PK) |
| `product_characteristic_type_id` | integer | FK → ProductCharacteristicType (part of composite PK) |
| `value` | string | The characteristic value |

### Endpoints

#### `GET /productcharacteristic/list?product_id=N`

Redirects internally to `list_by_product`.

---

#### `GET /productcharacteristic/list_by_product/{product_id}`

All characteristics for a product.

---

#### `GET /productcharacteristic/load_form?product_characteristic_id=N`

Returns a single characteristic record.

---

#### `POST /productcharacteristic/submit`

Create or update characteristic records. The controller validates that the
`ProductCharacteristicType` belongs to the same `ProductCategory` as the
`Product`; mismatches are rejected with a transaction failure.

---

#### `POST /productcharacteristic/delete`

Delete characteristic records. Because the table has a composite primary key,
`changes` must be a JSON array of **objects** rather than plain integers:

```json
[
  { "product_id": 42, "product_characteristic_type_id": 7 },
  ...
]
```

---

## FestivalProduct

Links a `Product` to a specific `Festival`, recording its sale price and
volume measure.

Base path: `/festivalproduct`

### Fields

| Field | Type | Description |
|---|---|---|
| `festival_product_id` | integer | Primary key |
| `product_id` | integer | FK → Product |
| `product_name` | string | Product name (read-only, from join) |
| `festival_id` | integer | FK → Festival |
| `festival_name` | string | Festival name (read-only, from join) |
| `festival_year` | integer | Festival year (read-only, from join) |
| `sale_price` | string | Formatted price (e.g. `"£3.50"`) |
| `sale_currency_id` | integer | FK → Currency |
| `sale_volume_id` | integer | FK → SaleVolume |
| `company_id` | integer | FK → Company (read-only, via product) |
| `company_name` | string | Company name (read-only, from join) |
| `comment` | string | Notes |

### Endpoints

#### `GET /festivalproduct/list/{festival_id}/{category_id}`

Festival products for a festival and product category.

---

#### `GET /festivalproduct/list_by_product/{product_id}`

All festival entries for a product.

---

#### `GET /festivalproduct/list_by_company/{company_id}`

All festival product entries for a company.

---

#### `GET /festivalproduct/load_form?festival_product_id=N`

Returns a single record.

---

#### `POST /festivalproduct/submit`

Create or update festival product records. `sale_price` is parsed from a
formatted string (e.g. `"3.50"` or `"£3.50"`) to a numeric value before
storage.

---

#### `POST /festivalproduct/delete`

Delete festival product records by ID.

---

#### `GET /festivalproduct/list_status/{festival_id}/{category_id}`

Returns a public-facing status list suitable for programme generation or a
live availability board.

**Authorisation:** The caller must be authorised for the requested product
category. Returns HTTP 403 if the user's roles do not hold the appropriate
`CategoryAuth` for the category.

**Response:**
```json
{
  "success": true,
  "objects": [
    {
      "id":               "sha1-hash-of-product_id",
      "company":          "Brewery Name",
      "company_id":       "sha1-hash-of-company_id",
      "location":         "Location string",
      "year_founded":     1842,
      "product":          "Beer Name",
      "abv":              4.2,
      "style":            "Pale Ale",
      "description":      "Short tasting notes",
      "long_description": "Extended notes",
      "allergens": {
        "Gluten":   true,
        "Nuts":     false
      },
      "is_vegan":         true,
      "status":           "available",
      "css_status":       "status-available",
      "dispense_method":  "Cask"
    }
  ]
}
```

Before the festival opens, status is derived from finalised `ProductOrder`
records (`"Ordered"`). Once the festival is open, status reflects live
`Cask` / `CaskMeasurement` dip data.

> **Note:** Company and product IDs are SHA-1 hashes of the underlying
> integer IDs to avoid leaking sequential primary keys in public responses.

---

## Gyle

A `Gyle` represents a specific brewing batch of a `FestivalProduct`.

Base path: `/gyle`

### Fields

| Field | Type | Description |
|---|---|---|
| `gyle_id` | integer | Primary key |
| `company_id` | integer | FK → Company (actual brewer for this batch) |
| `festival_product_id` | integer | FK → FestivalProduct |
| `abv` | decimal | Actual ABV for this batch |
| `comment` | string | Notes |
| `ext_reference` | string | Brewer's own batch reference |
| `int_reference` | string | Internal batch reference |
| `festival_name` | string | Festival name (read-only, from join) |
| `company_name` | string | Company name (read-only, from join) |

### Endpoints

#### `GET /gyle/list_by_festival_product/{festival_product_id}`

All gyles for a festival product.

---

#### `GET /gyle/list_by_festival/{festival_id}`

All gyles for a festival.

---

#### `GET /gyle/load_form?gyle_id=N`

Returns a single gyle record.

---

#### `POST /gyle/submit`

Create or update gyle records.

---

#### `POST /gyle/delete`

Delete gyle records by ID.

---

## Cask

A `Cask` is a physical container assigned to a festival. It is linked to a
`Gyle` and managed by a `CaskManagement` record that stores cellar logistics
(location, stillage, price, etc.).

Base path: `/cask`

### Fields

| Field | Type | Description |
|---|---|---|
| `cask_id` | integer | Primary key |
| `cask_management_id` | integer | FK → CaskManagement |
| `festival_id` | integer | Festival (read-only, via CaskManagement) |
| `festival_name` | string | Festival name (read-only) |
| `distributor_id` | integer | FK → Company (distributor) |
| `order_batch_id` | integer | FK → OrderBatch |
| `order_batch_name` | string | Order batch description (read-only) |
| `container_size_id` | integer | FK → ContainerSize |
| `bar_id` | integer | FK → Bar |
| `stillage_location_id` | integer | FK → StillageLocation |
| `currency_id` | integer | FK → Currency |
| `price` | string | Formatted purchase price |
| `gyle_id` | integer | FK → Gyle |
| `product_id` | integer | FK → Product (read-only, via Gyle) |
| `product_name` | string | Product name (read-only) |
| `company_id` | integer | FK → Company (brewer, read-only) |
| `company_name` | string | Company name (read-only) |
| `stillage_bay` | integer | Bay number on the stillage |
| `bay_position_id` | integer | FK → BayPosition |
| `stillage_x` | integer | X coordinate on stillage plan |
| `stillage_y` | integer | Y coordinate on stillage plan |
| `stillage_z` | integer | Z coordinate (layer/shelf) |
| `comment` | string | Notes |
| `ext_reference` | string | External reference (e.g. brewer's label) |
| `int_reference` | string | Internal cellar reference |
| `festival_ref` | string | Cellar reference number |
| `is_vented` | boolean | Cask has been vented |
| `is_tapped` | boolean | Cask is on tap |
| `is_ready` | boolean | Cask is ready to serve |
| `is_condemned` | boolean | Cask has been taken off |
| `is_sale_or_return` | boolean | Sale-or-return cask |
| `cask_graveyard` | boolean | Cask is in the graveyard section |

### Endpoints

#### `GET /cask/list/{festival_id}/{category_id}`

All casks at a festival for a product category.

---

#### `GET /cask/list_by_stillage/{stillage_location_id}`

Casks at a given stillage location.

---

#### `GET /cask/list_by_festival_product/{festival_product_id}`

Casks for a specific festival product.

---

#### `GET /cask/list_dips/{cask_id}`

Returns dip (measurement) history for a cask.

**Response:**
```json
{
  "success": true,
  "objects": [
    {
      "cask_measurement_id": 10,
      "measurement_time":    "2026-05-03T14:00:00",
      "volume":              18.0,
      "container_measure":   "pint"
    }
  ]
}
```

---

#### `GET /cask/load_form?cask_id=N`

Returns a single cask record.

---

#### `POST /cask/submit`

Create or update cask records. When creating a new cask (no
`cask_management_id` supplied), the controller also creates the associated
`CaskManagement` row in the same transaction.

---

#### `POST /cask/delete`

Delete cask records. If the associated `CaskManagement` row has no linked
`ProductOrder`, it is also deleted.

---

#### `POST /cask/delete_from_stillage`

Remove casks from their stillage location without deleting them.

**Request body param:** `changes` = JSON array of cask IDs.

Sets `stillage_location_id` to `NULL` on the associated `CaskManagement`
rows.

---

## CaskMeasurement (Dip)

Records volumetric measurements (dips) of individual casks.

Base path: `/caskmeasurement`

### Fields

| Field | Type | Description |
|---|---|---|
| `cask_measurement_id` | integer | Primary key |
| `cask_id` | integer | FK → Cask |
| `measurement_batch_id` | integer | FK → MeasurementBatch |
| `measurement_time` | datetime | Time of the batch (read-only, from join) |
| `measurement_batch_name` | string | Batch description (read-only, from join) |
| `volume` | decimal | Measured remaining volume |
| `container_measure_id` | integer | FK → ContainerMeasure (auto-set from cask) |
| `comment` | string | Notes |

### Endpoints

#### `GET /caskmeasurement/list/{batch_id}/{stillage_id}`

Returns a **cask-centric** list for all casks at a stillage location
within a measurement batch. Each object includes status flags and the
most-recent previous measurement:

```json
{
  "cask_id":              42,
  "is_vented":            true,
  "is_tapped":            true,
  "is_ready":             true,
  "is_condemned":         false,
  "internal_reference":   "C042",
  "cellar_reference":     "14",
  "measurement_batch_id": 7,
  "cask_comment":         "",
  "container_measure":    "pint",
  "brewer":               "Brewery Name",
  "product":              "Beer Name",
  "volume":               12.0,
  "cask_measurement_id":  99,
  "previous_volume":      18.0
}
```

---

#### `GET /caskmeasurement/list_by_cask/{cask_id}`

All measurements for a single cask in chronological order.

---

#### `GET /caskmeasurement/load_form?cask_measurement_id=N`

Returns a single measurement record.

---

#### `POST /caskmeasurement/submit`

Create or update measurements. Each record may also update Cask status
flags (`is_vented`, `is_tapped`, `is_ready`, `is_condemned`) and
`cask_comment` in the same operation. If `volume` is an empty string the
dip record is deleted rather than updated. `container_measure_id` is
auto-populated from the cask's container size if not supplied.

---

#### `POST /caskmeasurement/delete`

Delete measurement records by ID.

---

## MeasurementBatch

Groups a set of simultaneous dip readings taken at a point in time.

Base path: `/measurementbatch`

### Fields

| Field | Type | Description |
|---|---|---|
| `measurement_batch_id` | integer | Primary key |
| `measurement_time` | datetime | When the batch was taken |
| `festival_id` | integer | FK → Festival |
| `description` | string | Name / label for the batch |

### Endpoints

#### `GET /measurementbatch/list/{festival_id}`

All measurement batches for a festival, ordered by `measurement_time` ascending.

---

#### `POST /measurementbatch/submit`

Create or update measurement batches.

---

#### `POST /measurementbatch/delete`

Delete measurement batches by ID.

---

## OrderBatch

An `OrderBatch` groups `ProductOrder` records for a single ordering round.

Base path: `/orderbatch`

### Fields

| Field | Type | Description |
|---|---|---|
| `order_batch_id` | integer | Primary key |
| `festival_id` | integer | FK → Festival |
| `description` | string | Batch name / label |
| `order_date` | date | Date the order was placed |

### Endpoints

#### `GET /orderbatch/list/{festival_id}`

All order batches for a festival.

---

#### `POST /orderbatch/submit`

Create or update order batches.

---

#### `POST /orderbatch/delete`

Delete order batches by ID.

---

## ProductOrder

A `ProductOrder` is a line item within an `OrderBatch`, representing a
quantity of a specific product ordered from a supplier.

Base path: `/productorder`

### Fields

| Field | Type | Description |
|---|---|---|
| `product_order_id` | integer | Primary key |
| `company_id` | integer | FK → Company (brewer, read-only via product) |
| `company_name` | string | Brewer name (read-only) |
| `product_id` | integer | FK → Product |
| `product_name` | string | Product name (read-only) |
| `order_batch_id` | integer | FK → OrderBatch |
| `festival_id` | integer | Festival (read-only, via order batch) |
| `distributor_id` | integer | FK → Company (distributor) |
| `container_size_id` | integer | FK → ContainerSize |
| `cask_count` | integer | Number of containers ordered |
| `currency_id` | integer | FK → Currency |
| `price` | string | Formatted advertised price per unit |
| `is_final` | boolean | Order is finalised |
| `is_received` | boolean | Delivery has been received |
| `is_sale_or_return` | boolean | Sale-or-return arrangement |
| `comment` | string | Notes |

### Endpoints

#### `GET /productorder/list/{order_batch_id}/{category_id}`

All product orders in a batch for a product category.

---

#### `GET /productorder/load_form?product_order_id=N`

Returns a single product order record.

---

#### `POST /productorder/submit`

Create or update product orders. When `is_received` is set to `true` the
order is automatically finalised (`is_final=1`) and downstream
`FestivalProduct`, `Gyle`, and `Cask` records are pre-populated via the
`CaskPreloader` role. Subsequent receipt of an already-received order is
rejected.

---

#### `POST /productorder/delete`

Delete product order records by ID.

---

## StillageLocation

Base path: `/stillagelocation`

### Fields

| Field | Type | Description |
|---|---|---|
| `stillage_location_id` | integer | Primary key |
| `festival_id` | integer | FK → Festival |
| `description` | string | Location name |

### Endpoints

#### `GET /stillagelocation/list/{festival_id}`

All stillage locations for a festival.

---

#### `POST /stillagelocation/submit`

Create or update stillage locations.

---

#### `POST /stillagelocation/delete`

Delete stillage locations by ID.

---

## SaleVolume

Base path: `/salevolume`

### Fields

| Field | Type | Description |
|---|---|---|
| `sale_volume_id` | integer | Primary key |
| `container_measure_id` | integer | FK → ContainerMeasure |
| `description` | string | Label (e.g. `"pint"`) |
| `volume` | decimal | Volume amount |

### Endpoints

#### `GET /salevolume/list`

All sale volumes.

#### `GET /salevolume/load_form?sale_volume_id=N`

Returns a single record.

#### `POST /salevolume/submit`

Create or update sale volumes.

#### `POST /salevolume/delete`

Delete sale volumes by ID.

---

## BayPosition

Base path: `/bayposition`

### Fields

| Field | Type | Description |
|---|---|---|
| `bay_position_id` | integer | Primary key |
| `description` | string | Position name (e.g. `"front"`, `"back"`) |

### Endpoints

#### `GET /bayposition/list`

All bay positions (no filtering).

---

## Contact

Base path: `/contact`

### Fields

| Field | Type | Description |
|---|---|---|
| `contact_id` | integer | Primary key |
| `company_id` | integer | FK → Company |
| `company_name` | string | Company name (read-only) |
| `contact_type_id` | integer | FK → ContactType |
| `contact_type_desc` | string | Contact type description (read-only) |
| `first_name` | string | First name |
| `last_name` | string | Last name |
| `street_address` | string | Street address |
| `postcode` | string | Postcode / ZIP |
| `email` | string | Email address |
| `country_id` | integer | FK → Country |
| `comment` | string | Notes |

### Endpoints

#### `GET /contact/list_by_company/{company_id}`

All contacts for a company.

#### `GET /contact/load_form?contact_id=N`

Returns a single contact record.

#### `POST /contact/submit`

Create or update contacts.

#### `POST /contact/delete`

Delete contacts by ID.

---

## Telephone

Base path: `/telephone`

### Fields

| Field | Type | Description |
|---|---|---|
| `telephone_id` | integer | Primary key |
| `contact_id` | integer | FK → Contact |
| `company_name` | string | Company name (read-only, via contact) |
| `contact_type_desc` | string | Contact type (read-only, via contact) |
| `telephone_type_id` | integer | FK → TelephoneType |
| `international_code` | string | IDD code (e.g. `"44"`) |
| `area_code` | string | Area / STD code |
| `local_number` | string | Local number |
| `extension` | string | Extension number |

### Endpoints

#### `GET /telephone/list_by_contact/{contact_id}`

All telephone numbers for a contact.

#### `GET /telephone/load_form?telephone_id=N`

Returns a single record.

#### `POST /telephone/submit`

Create or update telephone records.

#### `POST /telephone/delete`

Delete telephone records by ID.

---

## User

Base path: `/user`

### Fields

| Field | Type | Description |
|---|---|---|
| `user_id` | integer | Primary key |
| `username` | string | Login name |
| `password` | string | Password (write-only; SHA-1 salted hash stored; blank values are rejected) |
| `name` | string | Display name |
| `email` | string | Email address |
| `roles` | string | Comma-separated `role_id` values |

### Endpoints

#### `GET /user/list`

All users.

#### `GET /user/load_form?user_id=N`

Returns a single user record. The caller must be either the target user or
an administrator.

#### `POST /user/submit`

Create or update users. The `password` field is hashed before storage;
supplying an empty string is rejected. Role memberships are synchronised
via the `UserRole` join table.

#### `POST /user/delete`

Delete users by ID.

---

## Role

Base path: `/role`

### Fields

| Field | Type | Description |
|---|---|---|
| `role_id` | integer | Primary key |
| `rolename` | string | Role name (e.g. `"admin"`, `"manager"`, `"cellar"`, `"wine and mead"`) |
| `categories` | string | Comma-separated `product_category_id` values representing the role's `CategoryAuth` entries (empty string for unrestricted roles such as `"admin"`) |

### Endpoints

#### `GET /role/list`

All roles.

---

#### `GET /role/load_form?role_id=N`

Returns a single role record, including its `categories` field.

---

#### `POST /role/submit`

Create or update role records. The `categories` field is a comma-separated
list of `product_category_id` values; the controller synchronises the
`CategoryAuth` join table so that only the supplied categories are retained.
Omitting `categories` leaves existing category associations unchanged.

---

#### `POST /role/delete`

Delete role records by ID.

---

## SystemDefaults

Base path: `/systemdefaults`

Stores a single singleton row (enforced by a `CHECK (id = 1)` constraint) that
holds application-wide defaults used when no explicit value is supplied.

**Access:** admin only. There are no `list` or `grid` endpoints.

### Fields

| Field | Type | Description |
|---|---|---|
| `id` | integer | Always `1` (singleton primary key) |
| `festival_id` | integer | FK → Festival — the current active festival |
| `currency_id` | integer | FK → Currency — default currency |
| `sale_volume_id` | integer | FK → SaleVolume — default sale volume |
| `product_category_id` | integer | FK → ProductCategory — default product category |
| `container_measure_id` | integer | FK → ContainerMeasure — default container measure |

### Endpoints

#### `GET /systemdefaults/load_form?id=1`

Returns the singleton system-defaults record.

**Response:** `{success, data:{...}}`

---

#### `POST /systemdefaults/submit`

Update the singleton system-defaults record. Body param `changes` = JSON array
containing a single record hash (the row is created if absent, updated if
present).

---

#### `POST /systemdefaults/delete`

Not supported. The controller rejects this with a flash error and redirects
to `/systemdefaults/view`. Do not call this endpoint.

---

## Reference / Vocabulary Tables

The following controllers expose read-only (or lightly managed) reference
data. All support `list`, `submit`, and `delete` unless marked otherwise.

### CompanyRegion

Base path: `/companyregion`

| Field | Type | Description |
|---|---|---|
| `company_region_id` | integer | Primary key |
| `description` | string | Region name |

Extra: `GET /companyregion/load_form?company_region_id=N`

---

### Country

Base path: `/country`

| Field | Type | Description |
|---|---|---|
| `country_id` | integer | Primary key |
| `country_code_iso2` | string | ISO 3166-1 alpha-2 code |
| `country_code_iso3` | string | ISO 3166-1 alpha-3 code |
| `country_code_num3` | string | ISO 3166-1 numeric code |
| `country_name` | string | Full country name |

**Endpoints:** `GET /country/list` only (read-only reference table).

---

### Currency

Base path: `/currency`

| Field | Type | Description |
|---|---|---|
| `currency_id` | integer | Primary key |
| `currency_code` | string | ISO 4217 code (e.g. `"GBP"`) |
| `currency_number` | string | ISO 4217 numeric code |
| `currency_format` | string | printf-style format string |
| `exponent` | integer | Decimal places (e.g. `2` for pence) |
| `currency_symbol` | string | Symbol (e.g. `"£"`) |

**Endpoints:** `GET /currency/list` only (read-only reference table).

---

### ContainerMeasure

Base path: `/containermeasure`

| Field | Type | Description |
|---|---|---|
| `container_measure_id` | integer | Primary key |
| `description` | string | Name (e.g. `"pint"`) |
| `litre_multiplier` | decimal | Conversion factor to litres |

Endpoints: `list`, `submit`, `delete`.

---

### ContainerSize

Base path: `/containersize`

| Field | Type | Description |
|---|---|---|
| `container_size_id` | integer | Primary key |
| `volume` | decimal | Container volume (in the associated measure) |
| `container_measure_id` | integer | FK → ContainerMeasure |
| `description` | string | Name (e.g. `"kilderkin"`) |
| `dispense_method_id` | integer | FK → DispenseMethod |
| `litre_multiplier` | decimal | Litres per unit (read-only, from ContainerMeasure) |

Extra: `GET /containersize/load_form?container_size_id=N`

---

### DispenseMethod

Base path: `/dispensemethod`

| Field | Type | Description |
|---|---|---|
| `dispense_method_id` | integer | Primary key |
| `description` | string | Method (e.g. `"Cask"`, `"Keg"`, `"Craft Keg"`) |

Extra: `GET /dispensemethod/load_form?dispense_method_id=N`

---

### ProductCategory

Base path: `/productcategory`

| Field | Type | Description |
|---|---|---|
| `product_category_id` | integer | Primary key |
| `description` | string | Category (e.g. `"beer"`, `"cider"`) |
| `is_status_public` | boolean | Upload product details to public website (`upload_beerlist.pl`) |
| `is_stock_public` | boolean | Upload product stock levels to public website |

Endpoints: `list`, `submit`, `delete`.

---

### ProductStyle

Base path: `/productstyle`

| Field | Type | Description |
|---|---|---|
| `product_style_id` | integer | Primary key |
| `product_category_id` | integer | FK → ProductCategory |
| `description` | string | Style name (e.g. `"Pale Ale"`) |

Extra endpoints:

- `GET /productstyle/list?product_category_id=N` — redirects to `list_by_category`
- `GET /productstyle/list_by_category/{category_id}`
- `GET /productstyle/load_form?product_style_id=N`

---

### ProductAllergenType

Base path: `/productallergentype`

| Field | Type | Description |
|---|---|---|
| `product_allergen_type_id` | integer | Primary key |
| `description` | string | Allergen name (e.g. `"Gluten"`, `"Nuts"`) |

Extra: `GET /productallergentype/load_form?product_allergen_type_id=N`

---

### ProductCharacteristicType

Base path: `/productcharacteristictype`

| Field | Type | Description |
|---|---|---|
| `product_characteristic_type_id` | integer | Primary key |
| `product_category_id` | integer | FK → ProductCategory (type is scoped to a category) |
| `description` | string | Type name (e.g. `"Colour"`, `"Clarity"`) |

Extra endpoints:

- `GET /productcharacteristictype/list?product_category_id=N` — redirects to `list_by_category`
- `GET /productcharacteristictype/list_by_category/{category_id}`
- `GET /productcharacteristictype/load_form?product_characteristic_type_id=N`

---

### ContactType

Base path: `/contacttype`

| Field | Type | Description |
|---|---|---|
| `contact_type_id` | integer | Primary key |
| `description` | string | Type name |

**Endpoints:** `GET /contacttype/list` only (read-only reference table).

---

### Protected

Base path: `/protected`

Records which ORM classes are shielded from bulk-loader creation/updates.
The `list` endpoint is accessible to all authenticated users; all other
operations require admin access.

| Field | Type | Description |
|---|---|---|
| `protected_id` | integer | Primary key |
| `classname` | string | ORM class name (e.g. `"Product"`, `"Festival"`); unique |
| `loader` | boolean | `1` if the Loader is blocked from creating/updating instances of this class; `0` otherwise |

**Endpoints:**

- `GET /protected/list` — all protected class entries (user-level access)
- `GET /protected/load_form?protected_id=N`
- `POST /protected/submit` — create or update entries (admin only)
- `POST /protected/delete` — delete entries by ID (admin only)

---

### TelephoneType

Base path: `/telephonetype`

| Field | Type | Description |
|---|---|---|
| `telephone_type_id` | integer | Primary key |
| `description` | string | Type name (e.g. `"mobile"`, `"work"`) |

**Endpoints:** `GET /telephonetype/list` only (read-only reference table).

---

## Error Responses

All JSON-returning endpoints follow a consistent error contract:

| Situation | HTTP status | Body |
|---|---|---|
| Success | 200 | `{"success": true, ...}` |
| Transaction / validation failure | 403 | `{"success": false, "error": "message"}` |
| Unauthenticated access | 403 | redirect to `/login` (or JSON for AJAX) |
| Not found | 404 | HTML `not_found.tt2` page |
| Category authorisation failure | 403 | `{"success": false, "error": "..."}` |

---

## Configuration

The following application configuration keys affect API behaviour:

| Key | Default | Description |
|---|---|---|
| `default_currency` | *(unset)* | Currency code used when no currency is specified (e.g. `GBP`) |
| `default_sale_volume` | *(unset)* | Sale volume description for default measure (e.g. `pint`) |
| `default_measurement_unit` | *(unset)* | ContainerMeasure description for dip calculations |
| `default_product_category` | *(unset)* | Default product category used in some list views |
| `base_path` | *(unset)* | Path prefix when app is hosted under a subdirectory (reverse proxy support) |
| `current_festival` | *(unset)* | Name of the currently active festival |

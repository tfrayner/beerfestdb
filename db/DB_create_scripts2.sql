-- ------------------------------------------------------------
-- Table structure for table `currency`
-- Stores a ISO standard currency code exponent usually 0,2,3. Database should
-- store all amounts as integers so there is not a loss of presision with 
-- decimal/floats. Format dor example are '#0','#0.00','#0.000' where there 
-- are any ',' and '.' to allow currency specific formatting of amounts id 
-- required any number of '#' are used in any desired format so for GBP with
-- comma separated 1000's and '.' as minor separatot the format would be
-- '#,###,###,###,##0.00' and JPY '#,###,###,###,##0'. All currencies except
--  the Malagasy ariary, and Mauritanian Ouguiya fit into thsi structure.
-- ------------------------------------------------------------

CREATE TABLE currency (
  currency_code CHAR(3) NOT NULL,
  currency_number CHAR(3) NOT NULL,
  currency_format VARCHAR(20) NOT NULL,
  exponent TINYINT(4) NOT NULL,
  currency_symbol VARCHAR(10) NOT NULL,
  PRIMARY KEY(currency_code),
  INDEX CUR_currencynumber(currency_number)
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `festival`
-- Simple table storing information about the festival, auto generated id as
-- the primary key as nothing else is unique. The start_date and end_date are
-- for use a a broad indication of when the festival is running not when it
-- is opening, see festival_opening for that.
-- 
-- ------------------------------------------------------------

CREATE TABLE festival (
  festival_id INTEGER(3) NOT NULL AUTO_INCREMENT,
  year YEAR(4) NOT NULL,
  name VARCHAR(60) NULL,
  description TEXT NULL,
  fst_start_date DATETIME NULL,
  fst_end_date DATETIME NULL,
  PRIMARY KEY(festival_id)
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `container_measure`
-- Simple table to store a multiplier so all container types can be converted into the same volume e.g. from litres into gallons
-- ------------------------------------------------------------

CREATE TABLE container_measure (
  container_measure_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  litre_multiplier FLOAT NULL,
  description VARCHAR(50) NULL,
  PRIMARY KEY(container_measure_id)
)
TYPE=InnoDB;


INSERT INTO container_measure (litre_multiplier, description) VALUES(1, 'litre');
INSERT INTO container_measure (litre_multiplier, description) VALUES(4.54609188,'Gallons');
INSERT INTO container_measure (litre_multiplier, description) VALUES(0.5682,'pint');
INSERT INTO container_measure (litre_multiplier, description) VALUES(0.2841,'half pint');


-- ------------------------------------------------------------
-- Table structure fortable `country`
-- Simple table to be able to refer to a country by a code rather than name if
-- various other table (an example might be a contact/address). Primary key 
-- country_code_iso2.
-- ------------------------------------------------------------

CREATE TABLE country (
  country_code_iso2 CHAR(2) NOT NULL,
  country_code_iso3 CHAR(3) NOT NULL,
  country_code_num3 CHAR(3) NOT NULL,
  country_name VARCHAR(100) NOT NULL,
  PRIMARY KEY(country_code_iso2),
  INDEX IDX_CNTRY_countrycode3(country_code_iso3),
  INDEX IDX_CNTRY_countrynum3(country_code_num3)
)
TYPE=InnoDB;


INSERT INTO country (country_code_iso2, country_code_iso3, country_code_num3, country_name) VALUES ('GB','GBR', '826', 'Great Britain');
INSERT INTO country (country_code_iso2, country_code_iso3, country_code_num3, country_name) VALUES ('IE','IRL', '372', 'Ireland');
INSERT INTO country (country_code_iso2, country_code_iso3, country_code_num3, country_name) VALUES ('NL','NLD', '528', 'Netherlands');
INSERT INTO country (country_code_iso2, country_code_iso3, country_code_num3, country_name) VALUES ('DE','DEU', '276', 'Germany');
INSERT INTO country (country_code_iso2, country_code_iso3, country_code_num3, country_name) VALUES ('BE','BEL', '056', 'Belgium');
INSERT INTO country (country_code_iso2, country_code_iso3, country_code_num3, country_name) VALUES ('CZ','CZE', '203', 'Czech Republic');


-- ------------------------------------------------------------
-- Table structure for table `stillage_location`
-- stillage_location_id in autogenerated. The description is 
-- the physical location of some particular stillageing for
-- example 'main tent','staff tent',igloo'.
-- ------------------------------------------------------------

CREATE TABLE stillage_location (
  stillage_location_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  description VARCHAR(255) NULL,
  PRIMARY KEY(stillage_location_id)
)
TYPE=InnoDB;


INSERT INTO stillage_location (description) VALUES ('igloo');
INSERT INTO stillage_location (description) VALUES ('main tent south');
INSERT INTO stillage_location (description) VALUES ('main tent north');
INSERT INTO stillage_location (description) VALUES ('main tent left');
INSERT INTO stillage_location (description) VALUES ('main tent right');


-- ------------------------------------------------------------
-- Static Table structure for table `telephone_type`
-- Simple table that describes different types of telephone that a telephone
-- is one of e.g. telephone,fax,mobile.
-- ------------------------------------------------------------

CREATE TABLE telephone_type (
  telephone_type_id INTEGER(4) NOT NULL AUTO_INCREMENT,
  description VARCHAR(30) NULL,
  PRIMARY KEY(telephone_type_id)
)
TYPE=InnoDB;

INSERT INTO telephone_type (description) VALUES('telephone');
INSERT INTO telephone_type (description) VALUES('fax');
INSERT INTO telephone_type (description) VALUES('mobile');


-- ------------------------------------------------------------
-- Table structure for table `festival_entry_type`
-- Simple table to contain a list of the different types of entry that are 
-- allowed, such as FULL, CAMRA, Student etc. The festival_entry_type_id
-- is autogenerated
-- ------------------------------------------------------------

CREATE TABLE festival_entry_type (
  festival_entry_type_id INTEGER(4) NOT NULL AUTO_INCREMENT,
  description VARCHAR(30) NOT NULL,
  PRIMARY KEY(festival_entry_type_id)
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `product_category`
-- Simple table to store a list of the product categories that we sell. These 
-- would simply be things like 'beer','cider', 'perry','foreign beer'
-- ------------------------------------------------------------

CREATE TABLE product_category (
  product_category_id INTEGER(4) NOT NULL AUTO_INCREMENT,
  description VARCHAR(100) NOT NULL,
  PRIMARY KEY(product_category_id)
)
TYPE=InnoDB;


INSERT INTO product_category (description) VALUES ('beer');
INSERT INTO product_category (description) VALUES ('foreign beer');
INSERT INTO product_category (description) VALUES ('cider');
INSERT INTO product_category (description) VALUES ('wine');
INSERT INTO product_category (description) VALUES ('perry');
INSERT INTO product_category (description) VALUES ('cyser');
INSERT INTO product_category (description) VALUES ('mead');


-- ------------------------------------------------------------
-- Table structure for table `contact_type`
-- Simple table to store the different types of contact that there may be 
-- against a contact. Examples may be 'main', 'invoice'
-- ------------------------------------------------------------

CREATE TABLE contact_type (
  contact_type_id INTEGER(4) NOT NULL AUTO_INCREMENT,
  contact_type_description VARCHAR(30) NOT NULL,
  PRIMARY KEY(contact_type_id)
)
TYPE=InnoDB;


INSERT INTO contact_type (contact_type_description) VALUES ('Main');
INSERT INTO contact_type (contact_type_description) VALUES ('Customer Service');


-- ------------------------------------------------------------
-- Table structure for table `company`
-- Simple table to store the basic details of a company be that a brewery of
-- some other suplier such as a cider maker. A company can have more than one
-- contact through the compant_contact table.
-- ------------------------------------------------------------

CREATE TABLE company (
  company_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NULL,
  loc_desc VARCHAR(100) NULL,
  year_founded YEAR(4) NULL,
  comment VARCHAR(255) NULL,
  PRIMARY KEY(company_id)
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `bar`
-- Simple table to store a description of a bar against a unique bar id
-- these can be used against multiple festivals. a valid bit allows one of 
-- bars to be used and then not used in future, this may arise in the case
-- of brewery bars where they are not repeated at other festivals. It is a 
-- descriptive table and is not regarded as for use in possitioning of 
-- casks within a bar.
-- ------------------------------------------------------------

CREATE TABLE bar (
  bar_id INTEGER(3) NOT NULL AUTO_INCREMENT,
  description TEXT NULL,
  PRIMARY KEY(bar_id)
)
TYPE=InnoDB;

INSERT INTO bar (description) VALUES ('Main tent');
INSERT INTO bar (description) VALUES ('Woodfords');
INSERT INTO bar (description) VALUES ('Staff bar');

-- ------------------------------------------------------------
-- Table maintaining a record of which bars are used for each festival.
-- ------------------------------------------------------------

CREATE TABLE festival_bar (
  bar_id INTEGER(3) NOT NULL,
  festival_id INTEGER(3) NOT NULL,
  FOREIGN KEY FK_FB_barid_BAR_barid(bar_id)
    REFERENCES bar(bar_id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_FB_fstid_FST_fstid(festival_id)
    REFERENCES festival(festival_id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Contains a list of characteristics about a particular product category
-- ------------------------------------------------------------

CREATE TABLE product_characteristic_type (
  product_characteristic_type_id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  product_category_id INTEGER(4) NOT NULL,
  description VARCHAR(50) NULL,
  PRIMARY KEY(product_characteristic_type_id, product_category_id),
  FOREIGN KEY FK_PC_pcid_PCT_pcid(product_category_id)
    REFERENCES product_category(product_category_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `festival_opening`
-- Simple table for storing all the festival opening sessions, with a 
-- festival_opening_id auto generated with the start_date, end_date.
-- References fetival by vestival_id
-- add last orders as date? 
-- ------------------------------------------------------------

CREATE TABLE festival_opening (
  festival_opening_id INTEGER(4) NOT NULL AUTO_INCREMENT,
  festival_id INTEGER(3) NOT NULL,
  op_start_date DATETIME NOT NULL,
  op_end_date DATETIME NOT NULL,
  PRIMARY KEY(festival_opening_id),
  FOREIGN KEY FK_FO_fo_FE_fo(festival_id)
    REFERENCES festival(festival_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `telephone`
-- Simple table to store all the elements that make up a telephone number
-- the interational code, area_code,telephone and extenstion
-- ------------------------------------------------------------

CREATE TABLE telephone (
  telephone_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  telephone_type_id INTEGER(4) NOT NULL,
  interational_code VARCHAR(10) NULL,
  area_code VARCHAR(10) NULL,
  telephone VARCHAR(50) NULL,
  extension VARCHAR(10) NULL,
  PRIMARY KEY(telephone_id),
  INDEX IDX_TEL_ttid(telephone_type_id),
  FOREIGN KEY FK_TEL_ttid_TT_ttid(telephone_type_id)
    REFERENCES telephone_type(telephone_type_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `container_size`
-- Simple table to be able to refer to a container_size by a container_size_id
-- rather than name name.
-- ------------------------------------------------------------

CREATE TABLE container_size (
  container_size_id INTEGER(4) NOT NULL AUTO_INCREMENT,
  container_volume DECIMAL(4,2) NOT NULL,
  container_measure_id INTEGER UNSIGNED NOT NULL,
  container_description VARCHAR(100) NULL,
  PRIMARY KEY(container_size_id),
  FOREIGN KEY FK_CS_cmid_CM_cmid(container_measure_id)
    REFERENCES container_measure(container_measure_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

INSERT INTO container_size (container_volume, container_measure_id, container_description) VALUES (9,2,'Firkin'); 
INSERT INTO container_size (container_volume, container_measure_id, container_description) VALUES (18,2,'Kilderkin'); 
INSERT INTO container_size (container_volume, container_measure_id, container_description) VALUES (22,2,'22 Gallon'); 
INSERT INTO container_size (container_volume, container_measure_id, container_description) VALUES (36,2,'Barrel'); 


-- ------------------------------------------------------------
-- Table structure for table `product_style`
-- Complex table to allow us to store many different types of product style
-- agant a product category. Examples are for a product_category of 'beer'
-- to have product_styles of 'IPA','Porter','Mild' etc
-- ------------------------------------------------------------

CREATE TABLE product_style (
  product_style_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  product_category_id INTEGER(4) NOT NULL,
  description VARCHAR(100) NULL,
  PRIMARY KEY(product_style_id),
  INDEX IDX_PS_pcid(product_category_id),
  FOREIGN KEY FK_PS_pcid_PC_pcid(product_category_id)
    REFERENCES product_category(product_category_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;


INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Mild');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Bitter');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Golden Ale');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Pale Ale');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'IPA');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Porter');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Stout');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Barley Wine');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Old Ale');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Scottish Beer');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'beer'), 'Light Bitter');


INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'cider'), 'very dry');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'cider'), 'dry');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'cider'), 'medium dry');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'cider'), 'medium');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'cider'), 'sweet');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'cider'), 'medium sweet');
INSERT INTO product_style (product_category_id,description) VALUES ((SELECT product_category_id FROM product_category WHERE description = 'cider'), 'very sweet');


-- ------------------------------------------------------------
-- Table structure for table `sale_volume`
-- Simple table to store the type of volume that we sell liquid products in.
-- These would typically be 'pint','half pint','small wine','large wine' all
-- volumes are stored as integers expected to be ml as these can be converted
-- to other units.
-- 
-- REQUIRES SOME MORE THOUGHT
-- ------------------------------------------------------------

CREATE TABLE sale_volume (
  sale_volume_id INTEGER(3) NOT NULL AUTO_INCREMENT,
  container_measure_id INTEGER UNSIGNED NOT NULL,
  sale_volume_description VARCHAR(30) NOT NULL,
  volume DECIMAL(4,2) NULL,
  PRIMARY KEY(sale_volume_id),
  FOREIGN KEY FK_SV_cmid_CM_cmid(container_measure_id)
    REFERENCES container_measure(container_measure_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `contact`
-- Complex table building contact, at present contains only name (first name,
-- last name, address, post code, country and the type of contact it is) it 
-- could contain a more complex address and title of the person. Does not 
-- contain a telephone as this is covered by contact_telephone. 
-- ------------------------------------------------------------

CREATE TABLE contact (
  contact_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  contact_type_id INTEGER(4) NOT NULL,
  last_name VARCHAR(100) NULL,
  first_name VARCHAR(100) NULL,
  street_address VARCHAR(255) NULL,
  postcode VARCHAR(10) NULL,
  country_code_iso2 CHAR(2) NULL,
  comment VARCHAR(255) NULL,
  PRIMARY KEY(contact_id),
  INDEX IDX_CNT_cc2(country_code_iso2),
  INDEX IDX_CNT_cnttyid(contact_type_id),
  FOREIGN KEY FK_CON_ctid_CTPY_ctid(contact_type_id)
    REFERENCES contact_type(contact_type_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CON_ccode_CNTRY_ccode(country_code_iso2)
    REFERENCES country(country_code_iso2)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `contact_telephone`
-- Joining table to allow more than one telephone number of each contact.
-- ------------------------------------------------------------

CREATE TABLE contact_telephone (
  contact_id INTEGER(6) NOT NULL,
  telephone_id INTEGER(6) NOT NULL,
  PRIMARY KEY(contact_id, telephone_id),
  INDEX IDX_CT_tid(telephone_id),
  INDEX IDX_CT_cntid(contact_id),
  FOREIGN KEY FK_CNT_cntid_CT_cntid(contact_id)
    REFERENCES contact(contact_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CTEL_telid_TEL_telid(telephone_id)
    REFERENCES telephone(telephone_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `festival_entry`
-- Complex table referencing both the fesitival_opening and the 
-- festival_entry_type (as the primary key) so that each festival opening
-- and festival entry type can be charged a different amount in a single 
-- currency, does not support multi-currency at present.
-- ------------------------------------------------------------

CREATE TABLE festival_entry (
  festival_opening_id INTEGER(4) NOT NULL AUTO_INCREMENT,
  festival_entry_type_id INTEGER(4) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  price INTEGER(11) NOT NULL,
  PRIMARY KEY(festival_opening_id, festival_entry_type_id),
  FOREIGN KEY FK_FE_fo_FO_fo(festival_opening_id)
    REFERENCES festival_opening(festival_opening_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_FE_fet_FET_fet(festival_entry_type_id)
    REFERENCES festival_entry_type(festival_entry_type_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_FE_cc_CUR_cc(currency_code)
    REFERENCES currency(currency_code)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `product`
-- Contains a product id that is auto generated, a name, decription and
-- a product style id, from this the product type can be decuced. There is
-- a comment to allow a fuller description of the product.
-- ------------------------------------------------------------

CREATE TABLE product (
  product_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NULL,
  product_style_id INTEGER(6) NULL,
  description TEXT NULL,
  comment VARCHAR(255) NULL,
  PRIMARY KEY(product_id),
  INDEX IDX_pdc_psid(product_style_id),
  FOREIGN KEY FK_PDCT_ps_PS_ps(product_style_id)
    REFERENCES product_style(product_style_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- For each product, there ccan be multiple characteristics
-- ------------------------------------------------------------

CREATE TABLE product_characteristic (
  product_id INTEGER(6) NOT NULL,
  product_characteristic_type_id_2 INTEGER UNSIGNED NOT NULL,
  product_category_id INTEGER(4) NOT NULL,
  value INTEGER UNSIGNED NULL,
  PRIMARY KEY(product_id),
  FOREIGN KEY Rel_29(product_characteristic_type_id_2, product_category_id)
    REFERENCES product_characteristic_type(product_characteristic_type_id, product_category_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_PDCT_pdid_PC_pid(product_id)
    REFERENCES product(product_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `company_contact`
-- Simple table to link a company to a number of contacts so that a 
-- company can have any number of contacts.
-- ------------------------------------------------------------

CREATE TABLE company_contact (
  company_id INTEGER(6) NOT NULL,
  contact_id INTEGER(6) NOT NULL,
  PRIMARY KEY(company_id, contact_id),
  FOREIGN KEY FK_CMPCNT_coid_DMPcoid(company_id)
    REFERENCES company(company_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CMPCNT_cntid_CNT_cntid(contact_id)
    REFERENCES contact(contact_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `brew_batch`
-- Complex table, that stores details of a particular brew batch of a 
-- beer production run. Each brew batch has a brewery that is the company that
-- the beer is associated with and a brewer that is a contact of the 
-- individual that brewed the beer, if the beer is brewed outside the 
-- actual brewery the company that actually brewed the beer can be traced
-- through the company contact provided that there is a link there. 
-- ------------------------------------------------------------

CREATE TABLE gyle (
  gyle_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  company_id INTEGER(6) NULL,
  product_id INTEGER(6) NULL,
  abv DECIMAL(3,1) NULL,
  comment VARCHAR(255) NULL,
  external_reference VARCHAR(255) NULL,
  internal_reference VARCHAR(255) NULL,
  PRIMARY KEY(gyle_id),
  INDEX IDX_BB_bcpnyid(company_id),
  INDEX IDX_BB_bpid(product_id),
  INDEX IDX_BB_eref(external_reference),
  INDEX IDX_BB_iref(internal_reference),
  FOREIGN KEY FK_BB_coid_COMP_coid(company_id)
    REFERENCES company(company_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_PDCT_prdid_BB_prdid(product_id)
    REFERENCES product(product_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `cask`
-- Complex table that stores individual casks that we receive. Each cask 
-- comes from a a single brew batch. Because they can be delivered from different
-- sources the distribution company is stored here. Each cask is only used at
-- one festival and is only ever tapped at one bar, although this may not be
-- known at the time of delivery so this may have to be taken into account. 
-- The stillage<x,y,z>location is an indication of where the cask is actually 
-- placed in the 3D world of the stillageing. The stillage location is the
-- physical location of the stillage itself, this may be 'main tent',
-- 'staff tent','igloo' etc.
-- ------------------------------------------------------------

CREATE TABLE cask (
  cask_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  festival_id INTEGER(3) NOT NULL,
  gyle_id INTEGER(6) NOT NULL,
  distributor_company_id INTEGER(6) NULL,
  container_size_id INTEGER(4) NULL,
  bar_id INTEGER(3) NULL,
  currency_code CHAR(3) NOT NULL,
  price INTEGER UNSIGNED NULL,
  stillage_location_id INTEGER UNSIGNED NOT NULL,
  stillage_x_location INTEGER UNSIGNED NULL,
  stillage_y_location INTEGER UNSIGNED NULL,
  stillage_z_location INTEGER UNSIGNED NULL,
  comment TEXT NULL,
  external_reference VARCHAR(255) NULL,
  internal_reference VARCHAR(255) NULL,
  PRIMARY KEY(cask_id),
  INDEX IDX_CSK_bbid(gyle_id),
  INDEX IDX_CSK_dcid(distributor_company_id),
  INDEX IDX_CSK_bid(bar_id),
  INDEX FK_CSK_csid_CS_csid(container_size_id),
  INDEX FK_CSK_cc3_CUR_cc3(currency_code),
  INDEX IDX_CSK_exref(external_reference),
  INDEX IDX_CSK_iref(internal_reference),
  FOREIGN KEY FK_CSK_bid_BR_bid(bar_id)
    REFERENCES bar(bar_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSK_csid_CS_csid(container_size_id)
    REFERENCES container_size(container_size_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSK_fstId_FST_fstid(festival_id)
    REFERENCES festival(festival_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSK_curcd_CUR_curcd(currency_code)
    REFERENCES currency(currency_code)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSK_gyleid_GYLE_gyleid(gyle_id)
    REFERENCES gyle(gyle_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSK_locid_STILLOC_locid(stillage_location_id)
    REFERENCES stillage_location(stillage_location_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `cask_measure`
-- Complex table to store the volume in a cask at different points in time
-- along with a comment.
-- All measurments stored as ml converted for representation to users?
-- 'date' is a nominal date for reference such as the date and time that the
-- row was inserted into the table, should be editable
-- 'start_date' and 'end_date' are the date/time that the reading actually 
-- covers, it would normally be that the 'end_date' is the same as the next
-- -- 'start_date' for that cask but that is not guaranteed.
-- ------------------------------------------------------------

CREATE TABLE cask_measurement (
  cask_measurement_id INTEGER(6) NOT NULL AUTO_INCREMENT,
  cask_id INTEGER(6) NOT NULL,
  date DATETIME NULL,
  start_date DATETIME NULL,
  end_date DATETIME NULL,
  volume INTEGER(6) NULL,
  comment VARCHAR(255) NULL,
  PRIMARY KEY(cask_measurement_id),
  INDEX IDX_CM_cid(cask_id),
  FOREIGN KEY FK_CSKM_cskid_CSK_cskid(cask_id)
    REFERENCES cask(cask_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;

-- ------------------------------------------------------------
-- Table structure for table `cask_sale_price`
-- Complex table taking a cask id, volume id, currency, price and revision
-- so that each cask of a gyle can be changed in price if required, the valid
-- bit allows sets which price revision is the one currently in use. 
-- ------------------------------------------------------------

CREATE TABLE cask_sale_price (
  cask_sale_price_id INTEGER(3) NOT NULL AUTO_INCREMENT,
  cask_id INTEGER(6) NOT NULL,
  sale_volume_id INTEGER(3) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  sale_price INTEGER(11) NULL,
  valid BIT(1) NULL,
  PRIMARY KEY(cask_sale_price_id),
  INDEX IDX_CSP_svid(sale_volume_id),
  INDEX IDX_CSP_cskid(cask_id),
  FOREIGN KEY FK_CSKSP_cskid_CSK_cskid(cask_id)
    REFERENCES cask(cask_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSP_svid_SV_svid(sale_volume_id)
    REFERENCES sale_volume(sale_volume_id)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION,
  FOREIGN KEY FK_CSP_ccode_CUR_ccode(currency_code)
    REFERENCES currency(currency_code)
      ON DELETE RESTRICT
      ON UPDATE NO ACTION
)
TYPE=InnoDB;



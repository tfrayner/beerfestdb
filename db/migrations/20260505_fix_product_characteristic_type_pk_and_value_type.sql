-- Migration: Fix product_characteristic_type primary key; change product_characteristic.value type
-- Date: 2026-05-05

-- Change PRIMARY KEY on `product_characteristic_type` from composite
-- (product_characteristic_type_id, product_category_id) to single-column
-- (product_characteristic_type_id). The old composite PK caused new rows
-- to be incorrectly matched by category when inserting via find_or_new.
SET @pk_needs_fix := (
  SELECT COUNT(*)
  FROM information_schema.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'product_characteristic_type'
    AND CONSTRAINT_NAME = 'PRIMARY'
    AND COLUMN_NAME  = 'product_category_id'
);
SET @sql := IF(@pk_needs_fix > 0,
  'ALTER TABLE `product_characteristic_type` DROP PRIMARY KEY, ADD PRIMARY KEY (`product_characteristic_type_id`);',
  'SELECT "product_characteristic_type primary key already updated";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Change `product_characteristic`.`value` from int(11) unsigned NULL to varchar(32) NOT NULL.
-- First convert any NULL values to empty string so the NOT NULL constraint can be applied.
UPDATE `product_characteristic` SET `value` = '' WHERE `value` IS NULL;

SET @col_needs_fix := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'product_characteristic'
    AND COLUMN_NAME  = 'value'
    AND DATA_TYPE    = 'int'
);
SET @sql := IF(@col_needs_fix > 0,
  'ALTER TABLE `product_characteristic` MODIFY COLUMN `value` VARCHAR(32) NOT NULL;',
  'SELECT "product_characteristic.value already updated";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- End of migration

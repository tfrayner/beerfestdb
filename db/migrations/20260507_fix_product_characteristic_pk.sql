-- Migration: Fix product_characteristic primary key
-- Date: 2026-05-07

-- Change PRIMARY KEY on `product_characteristic` from single-column (product_id)
-- to composite (product_id, product_characteristic_type_id).  The old single-column
-- PK incorrectly restricted each product to at most one characteristic.
--
-- The check tests whether `product_characteristic_type_id` is NOT already part of
-- the PRIMARY KEY; if it is absent we drop and recreate the key.

SET @pk_needs_fix := (
  SELECT COUNT(*)
  FROM information_schema.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA     = DATABASE()
    AND TABLE_NAME       = 'product_characteristic'
    AND CONSTRAINT_NAME  = 'PRIMARY'
    AND COLUMN_NAME      = 'product_characteristic_type_id'
);
SET @sql := IF(@pk_needs_fix = 0,
  'ALTER TABLE `product_characteristic` DROP PRIMARY KEY, ADD PRIMARY KEY (`product_id`, `product_characteristic_type_id`);',
  'SELECT "product_characteristic primary key already updated";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- End of migration

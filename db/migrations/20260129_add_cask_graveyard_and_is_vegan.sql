-- Migration: Add `cask_graveyard` to `cask_management` and `is_vegan` to `product`
-- Date: 2026-01-29

-- Add `cask_graveyard` to `cask_management` if it does not already exist
SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'cask_management'
    AND COLUMN_NAME = 'cask_graveyard'
);
SET @sql := IF(@exists = 0,
  'ALTER TABLE `cask_management` ADD COLUMN `cask_graveyard` VARCHAR(32) DEFAULT NULL;',
  'SELECT "cask_graveyard already exists";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add `is_vegan` to `product` if it does not already exist
SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'product'
    AND COLUMN_NAME = 'is_vegan'
);
SET @sql := IF(@exists = 0,
  'ALTER TABLE `product` ADD COLUMN `is_vegan` TINYINT(1) DEFAULT NULL; -- nullable so we can record known unknowns',
  'SELECT "is_vegan already exists";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- End of migration

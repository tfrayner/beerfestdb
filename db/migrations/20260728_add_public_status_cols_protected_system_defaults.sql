-- Migration: Add public_status_tag to festival; is_status_public/is_stock_public
--            to product_category; create protected and system_defaults tables.
-- Date: 2026-07-28

-- 1. Add public_status_tag to festival
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'festival'
    AND COLUMN_NAME  = 'public_status_tag'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `festival` ADD COLUMN `public_status_tag` varchar(30) DEFAULT NULL',
  'SELECT "festival.public_status_tag already exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. Add is_status_public to product_category
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'product_category'
    AND COLUMN_NAME  = 'is_status_public'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `product_category` ADD COLUMN `is_status_public` tinyint(1) NOT NULL DEFAULT 0',
  'SELECT "product_category.is_status_public already exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. Add is_stock_public to product_category
SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'product_category'
    AND COLUMN_NAME  = 'is_stock_public'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `product_category` ADD COLUMN `is_stock_public` tinyint(1) NOT NULL DEFAULT 0',
  'SELECT "product_category.is_stock_public already exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4. Create protected table
SET @tbl_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'protected'
);
SET @sql := IF(@tbl_exists = 0,
  'CREATE TABLE `protected` (
    `protected_id`  int(11)      NOT NULL AUTO_INCREMENT,
    `classname`     varchar(255) NOT NULL,
    `loader_create` tinyint(1)   DEFAULT 0,
    PRIMARY KEY (`protected_id`),
    UNIQUE KEY `classname` (`classname`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8',
  'SELECT "protected already exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5. Create system_defaults table
SET @tbl_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'system_defaults'
);
SET @sql := IF(@tbl_exists = 0,
  'CREATE TABLE `system_defaults` (
    `id`             tinyint(1) NOT NULL DEFAULT 1,
    `festival_id`    int(6)     DEFAULT NULL,
    `currency_id`    int(6)     DEFAULT NULL,
    `sale_volume_id` int(6)     DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `system_defaults_singleton` CHECK (`id` = 1),
    CONSTRAINT `sd_ibfk_1` FOREIGN KEY (`festival_id`)
      REFERENCES `festival` (`festival_id`) ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT `sd_ibfk_2` FOREIGN KEY (`currency_id`)
      REFERENCES `currency` (`currency_id`) ON UPDATE NO ACTION ON DELETE SET NULL,
    CONSTRAINT `sd_ibfk_3` FOREIGN KEY (`sale_volume_id`)
      REFERENCES `sale_volume` (`sale_volume_id`) ON UPDATE NO ACTION ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8',
  'SELECT "system_defaults already exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- End of migration

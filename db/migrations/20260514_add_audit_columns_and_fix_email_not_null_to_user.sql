-- Migration: Add audit datetime columns and enforce NOT NULL on email in `user`
-- Date: 2026-05-14

-- Add `date_created` to `user` if it does not already exist
SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'user'
    AND COLUMN_NAME  = 'date_created'
);
SET @sql := IF(@exists = 0,
  'ALTER TABLE `user` ADD COLUMN `date_created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;',
  'SELECT "date_created already exists";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add `date_modified` to `user` if it does not already exist
SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'user'
    AND COLUMN_NAME  = 'date_modified'
);
SET @sql := IF(@exists = 0,
  'ALTER TABLE `user` ADD COLUMN `date_modified` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;',
  'SELECT "date_modified already exists";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add `date_accessed` to `user` if it does not already exist
SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'user'
    AND COLUMN_NAME  = 'date_accessed'
);
SET @sql := IF(@exists = 0,
  'ALTER TABLE `user` ADD COLUMN `date_accessed` DATETIME DEFAULT NULL;',
  'SELECT "date_accessed already exists";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add `date_password_changed` to `user` if it does not already exist
SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'user'
    AND COLUMN_NAME  = 'date_password_changed'
);
SET @sql := IF(@exists = 0,
  'ALTER TABLE `user` ADD COLUMN `date_password_changed` DATETIME DEFAULT NULL;',
  'SELECT "date_password_changed already exists";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Enforce NOT NULL on `email` in `user`:
-- First replace any NULL values with an empty string to avoid ALTER failure,
-- then tighten the column definition.
SET @needs_fix := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'user'
    AND COLUMN_NAME  = 'email'
    AND IS_NULLABLE  = 'YES'
);
SET @sql := IF(@needs_fix > 0,
  'UPDATE `user` SET `email` = \'\' WHERE `email` IS NULL;',
  'SELECT "email has no NULL rows to fix";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(@needs_fix > 0,
  'ALTER TABLE `user` MODIFY COLUMN `email` VARCHAR(255) NOT NULL;',
  'SELECT "email is already NOT NULL";'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- End of migration

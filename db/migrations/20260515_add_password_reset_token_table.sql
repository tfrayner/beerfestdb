-- Migration: Add password_reset_token table for email-based password reset
-- Date: 2026-05-15

SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'password_reset_token'
);
SET @sql := IF(@exists = 0,
  'CREATE TABLE `password_reset_token` (
    `token_id`    INT(11)      NOT NULL AUTO_INCREMENT,
    `user_id`     INT(11)      NOT NULL,
    `token_hash`  VARCHAR(64)  NOT NULL,
    `expires_at`  DATETIME     NOT NULL,
    `used`        TINYINT(1)   NOT NULL DEFAULT 0,
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`token_id`),
    UNIQUE KEY `token_hash` (`token_hash`),
    KEY `user_id` (`user_id`),
    CONSTRAINT `prt_ibfk_1` FOREIGN KEY (`user_id`)
      REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8',
  'SELECT "password_reset_token already exists"'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- End of migration

CREATE TABLE `dispense_method` (
  `dispense_method_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(100) NOT NULL,
  PRIMARY KEY (`dispense_method_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `dispense_method` (`dispense_method_id`, `description`) VALUES (1,'cask'),(2,'key keg'),(3,'cider tub'),(4,'bottle');

ALTER TABLE container_size add column dispense_method_id int(6) NOT NULL DEFAULT 1;

ALTER TABLE container_size add KEY `FK_CS_dmid_DM_dmid` (`dispense_method_id`);

ALTER TABLE container_size add CONSTRAINT `container_size_ibfk_2` FOREIGN KEY (`dispense_method_id`) REFERENCES `dispense_method` (`dispense_method_id`) ON UPDATE NO ACTION;

ALTER TABLE container_size DROP INDEX `container_volume`;
ALTER TABLE container_size add UNIQUE KEY `container_volume` (`container_volume`,`container_measure_id`,`dispense_method_id`);

ALTER TABLE container_size MODIFY COLUMN `dispense_method_id` int(6) NOT NULL;

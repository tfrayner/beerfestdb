--
-- Table structure for table `product_allergen_type`
--

DROP TABLE IF EXISTS `product_allergen_type`;
CREATE TABLE `product_allergen_type` (
  `product_allergen_type_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(50) NOT NULL,
  PRIMARY KEY (`product_allergen_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `product_allergen`
--

DROP TABLE IF EXISTS `product_allergen`;
CREATE TABLE `product_allergen` (
  `product_id` int(6) NOT NULL,
  `product_allergen_type_id` int(6) NOT NULL,
  `present` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `product_allergen_id` (`product_id`,`product_allergen_type_id`),
  CONSTRAINT `product_allergen_ibfk_1` FOREIGN KEY (`product_allergen_type_id`) REFERENCES `product_allergen_type` (`product_allergen_type_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_allergen_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


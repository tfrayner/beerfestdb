INSERT INTO `bay_position` (`bay_position_id`, `description`) VALUES (8,'Bottom Back'),(6,'Bottom Front'),(7,'Bottom Middle'),(5,'Middle Back'),(4,'Middle Front'),(9,'On Floor'),(3,'Top Back'),(1,'Top Front'),(2,'Top Middle');
INSERT INTO `company_region` (`company_region_id`, `description`) VALUES (5,'Cambridgeshire'),(4,'East Anglia'),(8,'Midlands'),(6,'North England'),(3,'Northern Ireland'),(2,'Scotland'),(7,'South England'),(1,'Wales');
INSERT INTO `contact_type` (`contact_type_id`, `description`) VALUES (2,'Customer Service'),(1,'Main');
INSERT INTO `container_measure` (`container_measure_id`, `litre_multiplier`, `description`, `symbol`) VALUES (1,1.000000000000,'litre','L'),(2,4.546091880000,'gallon','gal'),(3,0.568200000000,'pint','pt'),(4,0.284100000000,'half pint','hp');
INSERT INTO `currency` (`currency_id`, `currency_code`, `currency_number`, `currency_format`, `exponent`, `currency_symbol`) VALUES (1,'GBP',826,'#,###,###,###,##0.00',2,'£');
INSERT INTO `dispense_method` (`dispense_method_id`, `description`) VALUES (1,'cask'),(2,'key keg'),(3,'cider tub'),(4,'bottle');
INSERT INTO `container_size` (`container_size_id`, `container_volume`, `container_measure_id`, `dispense_method_id`, `description`) VALUES (1,9.00,2,1,'firkin'),(2,18.00,2,1,'kilderkin'),(3,22.00,2,1,'22 gallon'),(4,36.00,2,1,'barrel');
INSERT INTO `country` (`country_id`, `country_code_iso2`, `country_code_iso3`, `country_code_num3`, `country_name`) VALUES (1,'GB','GBR','826','Great Britain'),(2,'IE','IRL','372','Ireland'),(3,'NL','NLD','528','Netherlands'),(4,'DE','DEU','276','Germany'),(5,'BE','BEL','056','Belgium'),(6,'CZ','CZE','203','Czech Republic');
INSERT INTO `product_category` (`product_category_id`, `description`) VALUES (1,'beer'),(3,'cider'),(6,'cyser'),(2,'foreign beer'),(7,'mead'),(5,'perry'),(4,'wine');
INSERT INTO `product_style` (`product_style_id`, `product_category_id`, `description`) VALUES (8,1,'Barley Wine'),(2,1,'Bitter'),(3,1,'Golden Ale'),(5,1,'IPA'),(11,1,'Light Bitter'),(1,1,'Mild'),(9,1,'Old Ale'),(4,1,'Pale Ale'),(6,1,'Porter'),(10,1,'Scottish Beer'),(7,1,'Stout'),(13,3,'dry'),(15,3,'medium'),(14,3,'medium dry'),(17,3,'medium sweet'),(16,3,'sweet'),(12,3,'very dry'),(18,3,'very sweet');
INSERT INTO `role` (`role_id`, `rolename`) VALUES (1,'admin'),(2,'user'),(3,'manager');
INSERT INTO `sale_volume` (`sale_volume_id`,`container_measure_id`,`description`,`volume`) VALUES (1,3,'pint',1.0),(2,5,'500ml bottle',1.0),(3,6,'175ml glass',1.0);
INSERT INTO `telephone_type` (`telephone_type_id`, `description`) VALUES (2,'fax'),(1,'landline'),(3,'mobile');
INSERT INTO `user` (`user_id`, `username`, `name`, `email`, `password`) VALUES (1,'admin',NULL,NULL,'{SSHA}phihZR8gSGUPNV0GYRRixWhlNS6rnO9q'),(2,'cellar',NULL,NULL,'{SSHA}CqSE3cPzRBmuAnVo7yhusv1EfkqdKIKK');
INSERT INTO `user_role` (`user_role_id`, `user_id`, `role_id`) VALUES (1,1,1),(2,1,2),(3,2,3),(4,2,2);

insert into role (`rolename`) values ('cellar');
insert into user_role (`role_id`, `user_id`)
       values ( (select role_id from role where rolename='cellar'),
                (select user_id from user where username='cellar'));
insert into category_auth (`role_id`, `product_category_id`)
       values ( (select role_id from role where rolename='cellar'),
                (select product_category_id from product_category where description='beer'));

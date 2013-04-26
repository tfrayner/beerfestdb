--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `category_auth`;
CREATE TABLE `category_auth` (
  `category_auth_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_category_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  PRIMARY KEY (`category_auth_id`),
  UNIQUE KEY `category_role_id` (`product_category_id`,`role_id`),
  KEY `product_category_id` (`product_category_id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `category_auth_ibfk_1` FOREIGN KEY (`product_category_id`) REFERENCES `product_category` (`product_category_id`) ON DELETE CASCADE,
  CONSTRAINT `category_auth_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Assumes that the initialise_vocabs.sql user accounts are still active.
insert into role (`rolename`) values ('cellar');
insert into user_role (`role_id`, `user_id`)
       values ( (select role_id from role where rolename='cellar'),
                (select user_id from user where username='cellar'));
insert into category_auth (`role_id`, `product_category_id`)
       values ( (select role_id from role where rolename='cellar'),
                (select product_category_id from product_category where description='beer'));


-- MySQL dump 10.13  Distrib 5.6.20, for osx10.9 (x86_64)
--
-- Host: localhost    Database: beerfestdb
-- ------------------------------------------------------
-- Server version	5.6.20

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bar`
--

DROP TABLE IF EXISTS `bar`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bar` (
  `bar_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_id` int(6) NOT NULL,
  `description` varchar(255) NOT NULL,
  `is_private` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`bar_id`),
  UNIQUE KEY `description` (`description`),
  KEY `FK_BAR_fstid_FST_fstid` (`festival_id`),
  CONSTRAINT `bar_ibfk_1` FOREIGN KEY (`festival_id`) REFERENCES `festival` (`festival_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bay_position`
--

DROP TABLE IF EXISTS `bay_position`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bay_position` (
  `bay_position_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(50) NOT NULL,
  PRIMARY KEY (`bay_position_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cask`
--

DROP TABLE IF EXISTS `cask`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cask` (
  `cask_id` int(6) NOT NULL AUTO_INCREMENT,
  `gyle_id` int(6) NOT NULL,
  `comment` text,
  `external_reference` varchar(255) DEFAULT NULL,
  `is_vented` tinyint(1) DEFAULT NULL,
  `is_tapped` tinyint(1) DEFAULT NULL,
  `is_ready` tinyint(1) DEFAULT NULL,
  `is_condemned` tinyint(1) DEFAULT '0', -- web json list drops this silently if NULL (a problem for our R code).
  `cask_management_id` int(6) NOT NULL,
  PRIMARY KEY (`cask_id`),
  UNIQUE KEY `cask_management` (`cask_management_id`),
  KEY `FK_CSK_bbid` (`gyle_id`),
  CONSTRAINT `cask_ibfk_10` FOREIGN KEY (`cask_management_id`) REFERENCES `cask_management` (`cask_management_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_ibfk_6` FOREIGN KEY (`gyle_id`) REFERENCES `gyle` (`gyle_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `cask_fp_insert_trigger`
    before insert on cask
for each row
begin
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( (select count(fp.festival_id)
            from festival_product fp, gyle g, cask_management cg
            where new.gyle_id=g.gyle_id
            and g.festival_product_id=fp.festival_product_id
            and fp.festival_id=cg.festival_id
            and cg.cask_management_id=new.cask_management_id) = 0 ) then
        call ERROR_CASK_FP_INSERT_TRIGGER();
    end if;
    
    if (  
         (select count(cg.cask_management_id)
            from cask_management cg
            where cg.cask_management_id=new.cask_management_id
            and cg.product_order_id is not null) = 1
       and 
         (select count(ob.order_batch_id)
            from cask_management cg, product_order po, order_batch ob
            where ob.festival_id=cg.festival_id
            and cg.cask_management_id=new.cask_management_id
            and po.order_batch_id=ob.order_batch_id
            and cg.product_order_id=po.product_order_id) = 0 ) then
        call ERROR_CASK_OB_INSERT_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `cask_update_trigger`
    before update on cask
for each row
begin
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( (select count(fp.festival_id)
            from festival_product fp, gyle g, cask_management cg
            where new.gyle_id=g.gyle_id
            and g.festival_product_id=fp.festival_product_id
            and fp.festival_id=cg.festival_id
            and cg.cask_management_id=new.cask_management_id) = 0 ) then
        call ERROR_CASK_FP_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `cask_management`
--

DROP TABLE IF EXISTS `cask_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cask_management` (
  `cask_management_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_id` int(6) NOT NULL,
  `distributor_company_id` int(6) DEFAULT NULL,
  `product_order_id` int(6) DEFAULT NULL,
  `container_size_id` int(6) NOT NULL,
  `bar_id` int(6) DEFAULT NULL,
  `currency_id` int(6) NOT NULL,
  `price` int(11) unsigned DEFAULT NULL,
  `stillage_location_id` int(6) DEFAULT NULL,
  `stillage_bay` int(4) unsigned DEFAULT NULL,
  `bay_position_id` int(6) DEFAULT NULL,
  `stillage_x_location` int(6) unsigned DEFAULT NULL,
  `stillage_y_location` int(6) unsigned DEFAULT NULL,
  `stillage_z_location` int(6) unsigned DEFAULT NULL,
  `internal_reference` int(6) DEFAULT NULL,
  `cellar_reference` int(6) NOT NULL,
  `is_sale_or_return` tinyint(1) DEFAULT '0', -- web json list drops this silently if NULL (a problem for our R code).
  PRIMARY KEY (`cask_management_id`),
  UNIQUE KEY `festival_cellar_ref` (`festival_id`,`cellar_reference`),
  KEY `IDX_CSKMAN_dfid` (`distributor_company_id`),
  KEY `IDX_CSKMAN_poid` (`product_order_id`),
  KEY `IDX_CSKMAN_bid` (`bar_id`),
  KEY `IDX_CSKMAN_stid` (`stillage_location_id`),
  KEY `IDX_CSKMAN_bpid` (`bay_position_id`),
  KEY `IDX_CSKMAN_csid_CS_csid` (`container_size_id`),
  KEY `IDX_CSKMAN_cc3_CUR_cc3` (`currency_id`),
  KEY `IDX_CSKMAN_iref` (`internal_reference`),
  CONSTRAINT `cask_management_ibfk_1` FOREIGN KEY (`bar_id`) REFERENCES `bar` (`bar_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_management_ibfk_2` FOREIGN KEY (`container_size_id`) REFERENCES `container_size` (`container_size_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_management_ibfk_3` FOREIGN KEY (`festival_id`) REFERENCES `festival` (`festival_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_management_ibfk_4` FOREIGN KEY (`distributor_company_id`) REFERENCES `company` (`company_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_management_ibfk_5` FOREIGN KEY (`product_order_id`) REFERENCES `product_order` (`product_order_id`) ON DELETE CASCADE ON UPDATE NO ACTION,  -- prevents inadvertent cask_management orphanage.
  CONSTRAINT `cask_management_ibfk_6` FOREIGN KEY (`currency_id`) REFERENCES `currency` (`currency_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_management_ibfk_7` FOREIGN KEY (`bay_position_id`) REFERENCES `bay_position` (`bay_position_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_management_ibfk_8` FOREIGN KEY (`stillage_location_id`) REFERENCES `stillage_location` (`stillage_location_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `cask_management_update_trigger`
    before update on cask_management
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( new.product_order_id is not null
        and new.product_order_id != old.product_order_id
        and (select count(ob.order_batch_id)
             from product_order po, order_batch ob
             where new.product_order_id=po.product_order_id
             and po.order_batch_id=ob.order_batch_id
             and ob.festival_id=new.festival_id) = 0 ) then
        call ERROR_CASKMAN_OB_UPDATE_TRIGGER();
    end if;
    if ( new.festival_id != old.festival_id and
           (select count(cm.cask_id)
            from cask c, cask_measurement cm, measurement_batch mb, cask_management cg
            where old.festival_id=mb.festival_id
            and cm.measurement_batch_id=mb.measurement_batch_id
            and c.cask_id=cm.cask_id
            and c.cask_management_id=old.cask_management_id) != 0 ) then
        call ERROR_CASKMAN_MB_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `cask_measurement`
--

DROP TABLE IF EXISTS `cask_measurement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cask_measurement` (
  `cask_measurement_id` int(6) NOT NULL AUTO_INCREMENT,
  `cask_id` int(6) NOT NULL,
  `measurement_batch_id` int(6) NOT NULL,
  `volume` decimal(5,2) NOT NULL,
  `container_measure_id` int(6) NOT NULL,
  `comment` text,
  PRIMARY KEY (`cask_measurement_id`),
  UNIQUE KEY `cask_measurement_batch` (`cask_id`,`measurement_batch_id`),
  KEY `IDX_CM_cid` (`cask_id`),
  KEY `FK_CSKM_batchid_BATCH_batchid` (`measurement_batch_id`),
  KEY `FK_CSKM_cskid_CM_cmid` (`container_measure_id`),
  CONSTRAINT `cask_measurement_ibfk_1` FOREIGN KEY (`cask_id`) REFERENCES `cask` (`cask_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_measurement_ibfk_2` FOREIGN KEY (`measurement_batch_id`) REFERENCES `measurement_batch` (`measurement_batch_id`) ON UPDATE NO ACTION,
  CONSTRAINT `cask_measurement_ibfk_3` FOREIGN KEY (`container_measure_id`) REFERENCES `container_measure` (`container_measure_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `cask_measurement_insert_trigger`
    before insert on cask_measurement
for each row
begin
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( (select count(mb.measurement_batch_id)
            from cask c, measurement_batch mb, cask_management cg
            where new.cask_id=c.cask_id
            and c.cask_management_id=cg.cask_management_id
            and mb.festival_id=cg.festival_id
            and mb.measurement_batch_id=new.measurement_batch_id) = 0 ) then
        call ERROR_CASK_MEASUREMENT_INSERT_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `cask_measurement_update_trigger`
    before update on cask_measurement
for each row
begin
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( (select count(mb.measurement_batch_id)
            from cask c, measurement_batch mb, cask_management cg
            where new.cask_id=c.cask_id
            and c.cask_management_id=cg.cask_management_id
            and mb.festival_id=cg.festival_id
            and mb.measurement_batch_id=new.measurement_batch_id) = 0 ) then
        call ERROR_CASK_MEASUREMENT_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `category_auth`
--

DROP TABLE IF EXISTS `category_auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `company`
--

DROP TABLE IF EXISTS `company`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `company` (
  `company_id` int(6) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `loc_desc` varchar(100) DEFAULT NULL,
  `company_region_id` int(6) DEFAULT NULL,
  `year_founded` int(4) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `awrs_urn` varchar(31) DEFAULT NULL,
  `comment` text,
  PRIMARY KEY (`company_id`),
  UNIQUE KEY `name` (`name`),
  KEY `FK_CO_rgnid_RGN_rgnid` (`company_region_id`),
  CONSTRAINT `company_ibfk_1` FOREIGN KEY (`company_region_id`) REFERENCES `company_region` (`company_region_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `company_region`
--

DROP TABLE IF EXISTS `company_region`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `company_region` (
  `company_region_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(30) NOT NULL,
  PRIMARY KEY (`company_region_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contact`
--

DROP TABLE IF EXISTS `contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contact` (
  `contact_id` int(6) NOT NULL AUTO_INCREMENT,
  `company_id` int(6) NOT NULL,
  `contact_type_id` int(6) NOT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `street_address` text,
  `postcode` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `country_id` int(6) DEFAULT NULL,
  `comment` text,
  PRIMARY KEY (`contact_id`),
  UNIQUE KEY `company_id` (`company_id`,`contact_type_id`),
  KEY `IDX_CNT_cc2` (`country_id`),
  KEY `IDX_CNT_cnttyid` (`contact_type_id`),
  CONSTRAINT `contact_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `company` (`company_id`) ON UPDATE NO ACTION,
  CONSTRAINT `contact_ibfk_2` FOREIGN KEY (`contact_type_id`) REFERENCES `contact_type` (`contact_type_id`) ON UPDATE NO ACTION,
  CONSTRAINT `contact_ibfk_3` FOREIGN KEY (`country_id`) REFERENCES `country` (`country_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contact_type`
--

DROP TABLE IF EXISTS `contact_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contact_type` (
  `contact_type_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(30) NOT NULL,
  PRIMARY KEY (`contact_type_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `container_measure`
--

DROP TABLE IF EXISTS `container_measure`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `container_measure` (
  `container_measure_id` int(6) NOT NULL AUTO_INCREMENT,
  `litre_multiplier` decimal(15,12) NOT NULL,
  `description` varchar(50) NOT NULL,
  `symbol` varchar(16) NOT NULL,
  PRIMARY KEY (`container_measure_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dispense_method`
--

DROP TABLE IF EXISTS `dispense_method`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dispense_method` (
  `dispense_method_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(100) NOT NULL,
  PRIMARY KEY (`dispense_method_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `container_size`
--

DROP TABLE IF EXISTS `container_size`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `container_size` (
  `container_size_id` int(6) NOT NULL AUTO_INCREMENT,
  `container_volume` decimal(4,2) NOT NULL,
  `container_measure_id` int(6) NOT NULL,
  `dispense_method_id` int(6) NOT NULL,
  `description` varchar(100) NOT NULL,
  PRIMARY KEY (`container_size_id`),
  UNIQUE KEY `container_volume` (`container_volume`,`container_measure_id`,`dispense_method_id`),
  UNIQUE KEY `description` (`description`),
  KEY `FK_CS_cmid_CM_cmid` (`container_measure_id`),
  KEY `FK_CS_dmid_DM_dmid` (`dispense_method_id`),
  CONSTRAINT `container_size_ibfk_1` FOREIGN KEY (`container_measure_id`) REFERENCES `container_measure` (`container_measure_id`) ON UPDATE NO ACTION,
  CONSTRAINT `container_size_ibfk_2` FOREIGN KEY (`dispense_method_id`) REFERENCES `dispense_method` (`dispense_method_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `country`
--

DROP TABLE IF EXISTS `country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `country` (
  `country_id` int(6) NOT NULL AUTO_INCREMENT,
  `country_code_iso2` char(2) NOT NULL,
  `country_code_iso3` char(3) NOT NULL,
  `country_code_num3` char(3) NOT NULL,
  `country_name` varchar(100) NOT NULL,
  PRIMARY KEY (`country_id`),
  KEY `IDX_CNTRY_countrycode3` (`country_code_iso3`),
  KEY `IDX_CNTRY_countrynum3` (`country_code_num3`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `currency`
--

DROP TABLE IF EXISTS `currency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `currency` (
  `currency_id` int(6) NOT NULL AUTO_INCREMENT,
  `currency_code` char(3) NOT NULL,
  `currency_number` char(3) NOT NULL,
  `currency_format` varchar(20) NOT NULL,
  `exponent` tinyint(4) NOT NULL,
  `currency_symbol` varchar(10) NOT NULL,
  PRIMARY KEY (`currency_id`),
  UNIQUE KEY `currency_code` (`currency_code`),
  KEY `CUR_currencynumber` (`currency_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `festival`
--

DROP TABLE IF EXISTS `festival`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `festival` (
  `festival_id` int(6) NOT NULL AUTO_INCREMENT,
  `year` year(4) NOT NULL,
  `name` varchar(60) NOT NULL,
  `description` text,
  `fst_start_date` date DEFAULT NULL,
  `fst_end_date` date DEFAULT NULL,
  PRIMARY KEY (`festival_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `festival_entry`
--

DROP TABLE IF EXISTS `festival_entry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `festival_entry` (
  `festival_opening_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_entry_type_id` int(6) NOT NULL,
  `currency_id` int(6) NOT NULL,
  `price` int(11) unsigned NOT NULL,
  PRIMARY KEY (`festival_opening_id`,`festival_entry_type_id`),
  KEY `FK_FE_fet_FET_fet` (`festival_entry_type_id`),
  KEY `FK_FE_cc_CUR_cc` (`currency_id`),
  CONSTRAINT `festival_entry_ibfk_1` FOREIGN KEY (`festival_opening_id`) REFERENCES `festival_opening` (`festival_opening_id`) ON UPDATE NO ACTION,
  CONSTRAINT `festival_entry_ibfk_2` FOREIGN KEY (`festival_entry_type_id`) REFERENCES `festival_entry_type` (`festival_entry_type_id`) ON UPDATE NO ACTION,
  CONSTRAINT `festival_entry_ibfk_3` FOREIGN KEY (`currency_id`) REFERENCES `currency` (`currency_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `festival_entry_type`
--

DROP TABLE IF EXISTS `festival_entry_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `festival_entry_type` (
  `festival_entry_type_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(30) NOT NULL,
  PRIMARY KEY (`festival_entry_type_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `festival_opening`
--

DROP TABLE IF EXISTS `festival_opening`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `festival_opening` (
  `festival_opening_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_id` int(6) NOT NULL,
  `op_start_date` datetime NOT NULL,
  `op_end_date` datetime NOT NULL,
  PRIMARY KEY (`festival_opening_id`),
  KEY `FK_FO_fo_FE_fo` (`festival_id`),
  CONSTRAINT `festival_opening_ibfk_1` FOREIGN KEY (`festival_id`) REFERENCES `festival` (`festival_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `festival_product`
--

DROP TABLE IF EXISTS `festival_product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `festival_product` (
  `festival_product_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_id` int(6) NOT NULL,
  `sale_volume_id` int(6) NOT NULL,
  `sale_currency_id` int(6) NOT NULL,
  `sale_price` int(11) unsigned DEFAULT NULL,
  `product_id` int(6) NOT NULL,
  `comment` text,
  PRIMARY KEY (`festival_product_id`),
  UNIQUE KEY `festival_id` (`festival_id`,`product_id`),
  KEY `FK_FP_prodid_PROD_prodid` (`product_id`),
  KEY `IDX_PDCT_svid` (`sale_volume_id`),
  KEY `FK_PDCT_slccode_CUR_ccode` (`sale_currency_id`),
  CONSTRAINT `festival_product_ibfk_1` FOREIGN KEY (`festival_id`) REFERENCES `festival` (`festival_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `festival_product_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `festival_product_ibfk_3` FOREIGN KEY (`sale_volume_id`) REFERENCES `sale_volume` (`sale_volume_id`) ON UPDATE NO ACTION,
  CONSTRAINT `festival_product_ibfk_4` FOREIGN KEY (`sale_currency_id`) REFERENCES `currency` (`currency_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `fp_cask_update_trigger`
    before update on festival_product
for each row
begin
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if (  new.festival_id != old.festival_id and
         (select count(f.festival_id)
          from festival f, gyle g, cask c, cask_management cg
          where old.festival_id=cg.festival_id
          and cg.cask_management_id=c.cask_management_id
          and c.gyle_id=g.gyle_id
          and g.festival_product_id=old.festival_product_id) != 0 ) then
        call ERROR_FP_CASK_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `gyle`
--

DROP TABLE IF EXISTS `gyle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gyle` (
  `gyle_id` int(6) NOT NULL AUTO_INCREMENT,
  `company_id` int(6) NOT NULL,
  `festival_product_id` int(6) NOT NULL,
  `abv` decimal(3,1) DEFAULT NULL,
  `comment` text,
  `external_reference` varchar(255) DEFAULT NULL,
  `internal_reference` varchar(255) NOT NULL,
  PRIMARY KEY (`gyle_id`),
  UNIQUE KEY `festival_product_id` (`festival_product_id`,`internal_reference`),
  KEY `IDX_BB_bcpnyid` (`company_id`),
  KEY `IDX_BB_bpid` (`festival_product_id`),
  KEY `IDX_BB_eref` (`external_reference`),
  KEY `IDX_BB_iref` (`internal_reference`),
  CONSTRAINT `gyle_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `company` (`company_id`) ON UPDATE NO ACTION,
  CONSTRAINT `gyle_ibfk_2` FOREIGN KEY (`festival_product_id`) REFERENCES `festival_product` (`festival_product_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `gyle_fp_update_trigger`
    before update on gyle
for each row
begin
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( new.festival_product_id != old.festival_product_id and
           (select count(fp.festival_id)
            from festival_product fp, cask c, cask_management cg
            where old.gyle_id=c.gyle_id
            and c.cask_management_id=cg.cask_management_id
            and cg.festival_id=fp.festival_id
            and fp.festival_product_id=old.festival_product_id) != 0 ) then
        call ERROR_GYLE_FP_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `measurement_batch`
--

DROP TABLE IF EXISTS `measurement_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `measurement_batch` (
  `measurement_batch_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_id` int(6) NOT NULL,
  `measurement_time` datetime NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`measurement_batch_id`),
  UNIQUE KEY `festival_measurement_batch` (`festival_id`,`measurement_time`),
  KEY `FK_ORDER_fid` (`festival_id`),
  CONSTRAINT `measurement_batch_ibfk_1` FOREIGN KEY (`festival_id`) REFERENCES `festival` (`festival_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `measurement_batch_update_trigger`
    before update on measurement_batch
for each row
begin
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( new.festival_id != old.festival_id and
           (select count(cm.measurement_batch_id)
            from cask_measurement cm, cask c, cask_management cg
            where old.measurement_batch_id=cm.measurement_batch_id
            and cm.cask_id=c.cask_id
            and cg.cask_management_id=c.cask_management_id
            and cg.festival_id=old.festival_id) != 0 ) then
        call ERROR_MEASUREMENT_BATCH_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `order_batch`
--

DROP TABLE IF EXISTS `order_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_batch` (
  `order_batch_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_id` int(6) NOT NULL,
  `description` varchar(255) NOT NULL,
  `order_date` date DEFAULT NULL,
  PRIMARY KEY (`order_batch_id`),
  UNIQUE KEY `festival_order_batch` (`festival_id`,`description`),
  KEY `FK_ORDER_fid` (`festival_id`),
  CONSTRAINT `order_batch_ibfk_1` FOREIGN KEY (`festival_id`) REFERENCES `festival` (`festival_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `order_batch_update_trigger`
    before update on order_batch
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( old.festival_id != new.festival_id
         and (select count(c.order_batch_id)
              from cask c, cask_management cg, product_order po
              where c.cask_management_id=cg.cask_management_id
              and cg.product_order_id=po.product_order_id
              and po.order_batch_id=old.order_batch_id
              ) > 0 ) then
        call ERROR_ORDER_BATCH_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary view structure for view `order_summary_view`
--

DROP TABLE IF EXISTS `order_summary_view`;
/*!50001 DROP VIEW IF EXISTS `order_summary_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `order_summary_view` AS SELECT 
 1 AS `festival`,
 1 AS `category`,
 1 AS `brewery`,
 1 AS `beer`,
 1 AS `style`,
 1 AS `sale_or_return`,
 1 AS `abv`,
 1 AS `kils`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product` (
  `product_id` int(6) NOT NULL AUTO_INCREMENT,
  `company_id` int(6) NOT NULL,
  `name` varchar(100) NOT NULL,
  `product_category_id` int(6) NOT NULL,
  `product_style_id` int(6) DEFAULT NULL,
  `nominal_abv` decimal(3,1) DEFAULT NULL,
  `description` text,
  `long_description` text,
  `comment` text,
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `company_id` (`company_id`,`name`),
  KEY `IDX_pdc_pcid` (`product_category_id`),
  KEY `IDX_pdc_psid` (`product_style_id`),
  CONSTRAINT `product_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `company` (`company_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `product_ibfk_2` FOREIGN KEY (`product_category_id`) REFERENCES `product_category` (`product_category_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_ibfk_3` FOREIGN KEY (`product_style_id`) REFERENCES `product_style` (`product_style_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `product_insert_trigger`
    before insert on product
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( new.product_style_id is not null
       and (select count(product_style_id)
            from product_style
            where product_category_id=new.product_category_id
            and product_style_id=new.product_style_id) = 0 ) then
        call ERROR_PRODUCT_INSERT_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `product_update_trigger`
    before update on product
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( new.product_style_id is not null
        and (select count(product_style_id)
             from product_style
             where product_category_id=new.product_category_id
             and product_style_id=new.product_style_id) = 0 ) then
        call ERROR_PRODUCT_UPDATE_TRIGGER();
    end if;
    
    if ( (select count(t.product_characteristic_type_id)
          from product_characteristic t
          where t.product_id=new.product_id)
          !=
         (select count(t.product_characteristic_type_id)
          from product_characteristic_type t, product_characteristic c
          where c.product_id=new.product_id
          and t.product_characteristic_type_id=c.product_characteristic_type_id
          and t.product_category_id=new.product_category_id) ) then
        call ERROR_PRODUCT_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `product_allergen`
--

DROP TABLE IF EXISTS `product_allergen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_allergen` (
  `product_allergen_id` int(6) NOT NULL AUTO_INCREMENT,
  `product_id` int(6) NOT NULL,
  `product_allergen_type_id` int(6) NOT NULL,
  `present` tinyint(1) DEFAULT NULL, -- nullable so we can record 'known unknowns' positively
  PRIMARY KEY (`product_allergen_id`),
  UNIQUE KEY `product_allergen_mapping` (`product_id`,`product_allergen_type_id`),
  KEY `product_allergen_ibfk_1` (`product_allergen_type_id`),
  CONSTRAINT `product_allergen_ibfk_1` FOREIGN KEY (`product_allergen_type_id`) REFERENCES `product_allergen_type` (`product_allergen_type_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_allergen_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_allergen_type`
--

DROP TABLE IF EXISTS `product_allergen_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_allergen_type` (
  `product_allergen_type_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(50) NOT NULL,
  PRIMARY KEY (`product_allergen_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_category`
--

DROP TABLE IF EXISTS `product_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_category` (
  `product_category_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(100) NOT NULL,
  PRIMARY KEY (`product_category_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_characteristic`
--

DROP TABLE IF EXISTS `product_characteristic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_characteristic` (
  `product_id` int(6) NOT NULL,
  `product_characteristic_type_id` int(6) NOT NULL,
  `value` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`product_id`),
  KEY `Rel_29` (`product_characteristic_type_id`),
  CONSTRAINT `product_characteristic_ibfk_1` FOREIGN KEY (`product_characteristic_type_id`) REFERENCES `product_characteristic_type` (`product_characteristic_type_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_characteristic_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `product_characteristic_insert_trigger`
    before insert on product_characteristic
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( (select count(t.product_characteristic_type_id)
          from product_characteristic_type t, product p
          where t.product_characteristic_type_id=new.product_characteristic_type_id
          and p.product_id=ne .product_id
          and t.product_category_id=p.product_category_id) = 0 ) then
        call ERROR_PRODUCT_CHARACTERISTIC_INSERT_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `product_characteristic_update_trigger`
    before update on product_characteristic
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( (select count(t.product_characteristic_type_id)
          from product_characteristic_type t, product p
          where t.product_characteristic_type_id=new.product_characteristic_type_id
          and p.product_id=new.product_id
          and t.product_category_id=p.product_category_id) = 0 ) then
        call ERROR_PRODUCT_CHARACTERISTIC_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `product_characteristic_type`
--

DROP TABLE IF EXISTS `product_characteristic_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_characteristic_type` (
  `product_characteristic_type_id` int(6) NOT NULL AUTO_INCREMENT,
  `product_category_id` int(6) NOT NULL,
  `description` varchar(50) NOT NULL,
  PRIMARY KEY (`product_characteristic_type_id`,`product_category_id`),
  UNIQUE KEY `product_category_id` (`product_category_id`,`description`),
  CONSTRAINT `product_characteristic_type_ibfk_1` FOREIGN KEY (`product_category_id`) REFERENCES `product_category` (`product_category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `product_characteristic_type_update_trigger`
    before update on product_characteristic_type
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( old.product_category_id != new.product_category_id
         and (select count(c.product_characteristic_type_id)
              from product_characteristic c
              where c.product_characteristic_type_id=old.product_characteristic_type_id) > 0 ) then
        call ERROR_PRODUCT_CHARACTERISTIC_TYPE_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `product_order`
--

DROP TABLE IF EXISTS `product_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_order` (
  `product_order_id` int(6) NOT NULL AUTO_INCREMENT,
  `order_batch_id` int(6) NOT NULL,
  `product_id` int(6) NOT NULL,
  `distributor_company_id` int(6) NOT NULL,
  `container_size_id` int(6) NOT NULL,
  `cask_count` int(10) unsigned NOT NULL,
  `currency_id` int(6) NOT NULL,
  `advertised_price` int(10) unsigned DEFAULT NULL,
  `is_final` tinyint(1) DEFAULT NULL,
  `is_received` tinyint(1) DEFAULT NULL,
  `comment` text,
  `is_sale_or_return` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`product_order_id`),
  UNIQUE KEY `product_order_batch` (`order_batch_id`,`product_id`,`distributor_company_id`,`container_size_id`,`cask_count`,`is_sale_or_return`),
  KEY `FK_ORDER_fid` (`order_batch_id`),
  KEY `FK_ORDER_pid` (`product_id`),
  KEY `FK_ORDER_dcid` (`distributor_company_id`),
  KEY `FK_ORDER_cc3_CUR_cc3` (`currency_id`),
  KEY `FK_ORDER_csid_CS_csid` (`container_size_id`),
  CONSTRAINT `product_order_ibfk_1` FOREIGN KEY (`order_batch_id`) REFERENCES `order_batch` (`order_batch_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_order_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_order_ibfk_3` FOREIGN KEY (`distributor_company_id`) REFERENCES `company` (`company_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_order_ibfk_4` FOREIGN KEY (`currency_id`) REFERENCES `currency` (`currency_id`) ON UPDATE NO ACTION,
  CONSTRAINT `product_order_ibfk_5` FOREIGN KEY (`container_size_id`) REFERENCES `container_size` (`container_size_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_style`
--

DROP TABLE IF EXISTS `product_style`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_style` (
  `product_style_id` int(6) NOT NULL AUTO_INCREMENT,
  `product_category_id` int(6) NOT NULL,
  `description` varchar(100) NOT NULL,
  PRIMARY KEY (`product_style_id`),
  UNIQUE KEY `product_category_id` (`product_category_id`,`description`),
  KEY `IDX_PS_pcid` (`product_category_id`),
  CONSTRAINT `product_style_ibfk_1` FOREIGN KEY (`product_category_id`) REFERENCES `product_category` (`product_category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 trigger `product_style_update_trigger`
    before update on product_style
for each row
begin
    
    if ( @TRIGGER_DISABLED is NULL or @TRIGGER_DISABLED=0 ) THEN
    if ( old.product_category_id != new.product_category_id
         and (select count(p.product_style_id)
              from product p
              where p.product_style_id=old.product_style_id) > 0 ) then
        call ERROR_PRODUCT_STYLE_UPDATE_TRIGGER();
    end if;
    end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary view structure for view `programme_notes_view`
--

DROP TABLE IF EXISTS `programme_notes_view`;
/*!50001 DROP VIEW IF EXISTS `programme_notes_view`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `programme_notes_view` AS SELECT 
 1 AS `festival`,
 1 AS `category`,
 1 AS `brewer`,
 1 AS `location`,
 1 AS `year_established`,
 1 AS `beer`,
 1 AS `abv`,
 1 AS `tasting_notes`,
 1 AS `tasting_essay`,
 1 AS `style`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `role` (
  `role_id` int(11) NOT NULL AUTO_INCREMENT,
  `rolename` varchar(255) NOT NULL,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `rolename` (`rolename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sale_volume`
--

DROP TABLE IF EXISTS `sale_volume`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sale_volume` (
  `sale_volume_id` int(6) NOT NULL AUTO_INCREMENT,
  `container_measure_id` int(6) NOT NULL,
  `description` varchar(30) NOT NULL,
  `volume` decimal(4,2) NOT NULL,
  PRIMARY KEY (`sale_volume_id`),
  UNIQUE KEY `description` (`description`),
  KEY `FK_SV_cmid_CM_cmid` (`container_measure_id`),
  CONSTRAINT `sale_volume_ibfk_1` FOREIGN KEY (`container_measure_id`) REFERENCES `container_measure` (`container_measure_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stillage_location`
--

DROP TABLE IF EXISTS `stillage_location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stillage_location` (
  `stillage_location_id` int(6) NOT NULL AUTO_INCREMENT,
  `festival_id` int(6) NOT NULL,
  `description` varchar(50) NOT NULL,
  PRIMARY KEY (`stillage_location_id`),
  UNIQUE KEY `festival_id` (`festival_id`,`description`),
  CONSTRAINT `stillage_location_ibfk_1` FOREIGN KEY (`festival_id`) REFERENCES `festival` (`festival_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `telephone`
--

DROP TABLE IF EXISTS `telephone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `telephone` (
  `telephone_id` int(6) NOT NULL AUTO_INCREMENT,
  `telephone_type_id` int(6) DEFAULT NULL,
  `contact_id` int(6) NOT NULL,
  `international_code` varchar(10) DEFAULT NULL,
  `area_code` varchar(10) DEFAULT NULL,
  `local_number` varchar(50) NOT NULL,
  `extension` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`telephone_id`),
  KEY `IDX_TEL_ttid` (`telephone_type_id`),
  KEY `IDX_TEL_cntid` (`contact_id`),
  CONSTRAINT `telephone_ibfk_1` FOREIGN KEY (`contact_id`) REFERENCES `contact` (`contact_id`) ON UPDATE NO ACTION,
  CONSTRAINT `telephone_ibfk_2` FOREIGN KEY (`telephone_type_id`) REFERENCES `telephone_type` (`telephone_type_id`) ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `telephone_type`
--

DROP TABLE IF EXISTS `telephone_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `telephone_type` (
  `telephone_type_id` int(6) NOT NULL AUTO_INCREMENT,
  `description` varchar(30) NOT NULL,
  PRIMARY KEY (`telephone_type_id`),
  UNIQUE KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password` varchar(40) NOT NULL DEFAULT '*',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `user_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_role` (
  `user_role_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  PRIMARY KEY (`user_role_id`),
  UNIQUE KEY `user_id` (`user_id`,`role_id`),
  KEY `user_id_2` (`user_id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `user_role_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `user_role_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Final view structure for view `order_summary_view`
--

/*!50001 DROP TABLE IF EXISTS `order_summary_view`*/;
/*!50001 DROP VIEW IF EXISTS `order_summary_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `order_summary_view` AS (select `f`.`name` AS `festival`,`pc`.`description` AS `category`,`c`.`name` AS `brewery`,`p`.`name` AS `beer`,`st`.`description` AS `style`,if((`po`.`is_sale_or_return` = 1),'Yes','No') AS `sale_or_return`,`p`.`nominal_abv` AS `abv`,round(sum((((`po`.`cask_count` * `cs`.`container_volume`) * `cm`.`litre_multiplier`) / (18 * 4.5461))),1) AS `kils` from (((((((`company` `c` join `product_category` `pc`) join (`product` `p` left join `product_style` `st` on((`p`.`product_style_id` = `st`.`product_style_id`)))) join `product_order` `po`) join `order_batch` `ob`) join `container_size` `cs`) join `container_measure` `cm`) join `festival` `f`) where ((`f`.`festival_id` = `ob`.`festival_id`) and (`ob`.`order_batch_id` = `po`.`order_batch_id`) and (`p`.`product_id` = `po`.`product_id`) and (`p`.`company_id` = `c`.`company_id`) and (`po`.`container_size_id` = `cs`.`container_size_id`) and (`cs`.`container_measure_id` = `cm`.`container_measure_id`) and (`p`.`product_category_id` = `pc`.`product_category_id`) and (`po`.`is_final` = 1)) group by `f`.`name`,`pc`.`description`,`c`.`name`,`p`.`name`,`st`.`description`,if((`po`.`is_sale_or_return` = 1),'Yes','No'),`p`.`nominal_abv`,((`po`.`cask_count` * `cs`.`container_volume`) * `cm`.`litre_multiplier`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `programme_notes_view`
--

/*!50001 DROP VIEW IF EXISTS `programme_notes_view`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `programme_notes_view` AS (select distinct `f`.`name` AS `festival`,`pc`.`description` AS `category`,`c`.`name` AS `brewer`,`c`.`loc_desc` AS `location`,`c`.`year_founded` AS `year_established`,`p`.`name` AS `beer`,`p`.`nominal_abv` AS `abv`,`p`.`description` AS `tasting_notes`,`p`.`long_description` AS `tasting_essay`,`ps`.`description` AS `style`,`dm`.`description` AS `dispense_method` from (((((((`company` `c` join (`product` `p` left join `product_style` `ps` on((`ps`.`product_style_id` = `p`.`product_style_id`)))) join `product_category` `pc`) join `product_order` `po`) join `order_batch` `ob`) join `festival` `f`) join `container_size` `cs`) join `dispense_method` `dm`) where ((`f`.`festival_id` = `ob`.`festival_id`) and (`ob`.`order_batch_id` = `po`.`order_batch_id`) and (`po`.`product_id` = `p`.`product_id`) and (`p`.`company_id` = `c`.`company_id`) and (`pc`.`product_category_id` = `p`.`product_category_id`) and (`po`.`container_size_id` = `cs`.`container_size_id`) and (`cs`.`dispense_method_id` = `dm`.`dispense_method_id`) and (`po`.`is_final` = 1)) order by `f`.`name`,`pc`.`description`,`c`.`name`,`p`.`name`,`dm`.`description`) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-02-01 13:09:55

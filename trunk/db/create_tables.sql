-- MySQL dump 10.10
--
-- Host: localhost    Database: beerfestdb
-- ------------------------------------------------------
-- Server version	5.0.27

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
-- Table structure for table `address`
--

DROP TABLE IF EXISTS `address`;
CREATE TABLE `address` (
  `id` int(6) NOT NULL auto_increment,
  `street_address` varchar(255) default NULL,
  `postcode` varchar(10) default NULL,
  `email` varchar(100) default NULL,
  `phone_no` varchar(15) default NULL,
  `fax_no` varchar(15) default NULL,
  `comment` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
/*!40000 ALTER TABLE `address` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bar`
--

DROP TABLE IF EXISTS `bar`;
CREATE TABLE `bar` (
  `id` int(3) NOT NULL auto_increment,
  `description` text NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `bar`
--

LOCK TABLES `bar` WRITE;
/*!40000 ALTER TABLE `bar` DISABLE KEYS */;
/*!40000 ALTER TABLE `bar` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `beer`
--

DROP TABLE IF EXISTS `beer`;
CREATE TABLE `beer` (
  `id` int(6) NOT NULL auto_increment,
  `name` varchar(100) NOT NULL,
  `style` varchar(20) default NULL,
  `description` text,
  `comment` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `beer`
--

LOCK TABLES `beer` WRITE;
/*!40000 ALTER TABLE `beer` DISABLE KEYS */;
/*!40000 ALTER TABLE `beer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cask`
--

DROP TABLE IF EXISTS `cask`;
CREATE TABLE `cask` (
  `id` int(6) NOT NULL auto_increment,
  `gyle` int(6) NOT NULL,
  `distributor` int(6) default NULL,
  `festival` int(6) NOT NULL,
  `size` int(2) default NULL,
  `cask_price` decimal(5,2) default NULL,
  `bar` int(6) NOT NULL,
  `comment` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `gyle` (`gyle`),
  KEY `distributor` (`distributor`),
  KEY `festival` (`festival`),
  KEY `bar` (`bar`),
  CONSTRAINT `cask_ibfk_1` FOREIGN KEY (`gyle`) REFERENCES `gyle` (`id`),
  CONSTRAINT `cask_ibfk_2` FOREIGN KEY (`distributor`) REFERENCES `company` (`id`),
  CONSTRAINT `cask_ibfk_3` FOREIGN KEY (`festival`) REFERENCES `festival` (`id`),
  CONSTRAINT `cask_ibfk_4` FOREIGN KEY (`bar`) REFERENCES `bar` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cask`
--

LOCK TABLES `cask` WRITE;
/*!40000 ALTER TABLE `cask` DISABLE KEYS */;
/*!40000 ALTER TABLE `cask` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cask_measurement`
--

DROP TABLE IF EXISTS `cask_measurement`;
CREATE TABLE `cask_measurement` (
  `id` int(6) NOT NULL auto_increment,
  `cask` int(6) NOT NULL,
  `date` datetime NOT NULL,
  `volume` varchar(10) NOT NULL,
  `comment` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `cask` (`cask`),
  CONSTRAINT `cask_measurement_ibfk_1` FOREIGN KEY (`cask`) REFERENCES `cask` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cask_measurement`
--

LOCK TABLES `cask_measurement` WRITE;
/*!40000 ALTER TABLE `cask_measurement` DISABLE KEYS */;
/*!40000 ALTER TABLE `cask_measurement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company`
--

DROP TABLE IF EXISTS `company`;
CREATE TABLE `company` (
  `id` int(6) NOT NULL auto_increment,
  `name` varchar(100) NOT NULL,
  `loc_desc` varchar(100) default NULL,
  `year_founded` year default NULL,
  `comment` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `company`
--

LOCK TABLES `company` WRITE;
/*!40000 ALTER TABLE `company` DISABLE KEYS */;
/*!40000 ALTER TABLE `company` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `company_address`
--

DROP TABLE IF EXISTS `company_address`;
CREATE TABLE `company_address` (
  `company` int(6) NOT NULL,
  `address` int(6) NOT NULL,
  PRIMARY KEY  (`company`,`address`),
  KEY `address` (`address`),
  CONSTRAINT `company_address_ibfk_1` FOREIGN KEY (`company`) REFERENCES `company` (`id`),
  CONSTRAINT `company_address_ibfk_2` FOREIGN KEY (`address`) REFERENCES `address` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `company_address`
--

LOCK TABLES `company_address` WRITE;
/*!40000 ALTER TABLE `company_address` DISABLE KEYS */;
/*!40000 ALTER TABLE `company_address` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `festival`
--

DROP TABLE IF EXISTS `festival`;
CREATE TABLE `festival` (
  `id` int(4) NOT NULL auto_increment,
  `year` year NOT NULL,
  `description` varchar(60) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `festival`
--

LOCK TABLES `festival` WRITE;
/*!40000 ALTER TABLE `festival` DISABLE KEYS */;
/*!40000 ALTER TABLE `festival` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gyle`
--

DROP TABLE IF EXISTS `gyle`;
CREATE TABLE `gyle` (
  `id` int(6) NOT NULL auto_increment,
  `brewery_number` varchar(10) default NULL,
  `brewer` int(6) NOT NULL,
  `beer` int(6) NOT NULL,
  `abv` decimal(3,1) default NULL,
  `pint_price` decimal(4,2) default NULL,
  `comment` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `brewer` (`brewer`),
  KEY `beer` (`beer`),
  CONSTRAINT `gyle_ibfk_1` FOREIGN KEY (`brewer`) REFERENCES `company` (`id`),
  CONSTRAINT `gyle_ibfk_2` FOREIGN KEY (`beer`) REFERENCES `beer` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `gyle`
--

LOCK TABLES `gyle` WRITE;
/*!40000 ALTER TABLE `gyle` DISABLE KEYS */;
/*!40000 ALTER TABLE `gyle` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2008-03-16 15:48:28

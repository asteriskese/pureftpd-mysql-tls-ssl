-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               5.6.21 - Source distribution
-- Server OS:                    Linux
-- HeidiSQL Version:             9.1.0.4867
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Dumping database structure for pureftpd
CREATE DATABASE IF NOT EXISTS `pureftpd` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */;
USE `pureftpd`;


-- Dumping structure for event pureftpd.DISABLED_ACCT
DELIMITER //
CREATE DEFINER=`tinhcx`@`%` EVENT `DISABLED_ACCT` ON SCHEDULE EVERY 5 SECOND STARTS '2015-02-06 12:55:00' ON COMPLETION NOT PRESERVE ENABLE DO UPDATE ftpd SET status=0 WHERE DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') > DATE_FORMAT(expirieddate, '%Y%m%d%H%i%s')//
DELIMITER ;


-- Dumping structure for table pureftpd.ftpd
CREATE TABLE IF NOT EXISTS `ftpd` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `user` varchar(16) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `password` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2e4e106f70093bd3ef9b9d4c62acc14f' COMMENT 'md5(''310212'')',
  `uid` varchar(11) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2002' COMMENT 'nginx uid: 2002',
  `gid` varchar(11) COLLATE utf8_unicode_ci NOT NULL DEFAULT '2002' COMMENT 'nginx gid: 2002',
  `ipaccess` varchar(15) COLLATE utf8_unicode_ci NOT NULL DEFAULT '*' COMMENT '*-all | 192.168.1.0/24 | ...',
  `ulbandwidth` smallint(5) NOT NULL DEFAULT '1024' COMMENT 'ULBandwidth: 1024 KB/sec ~ 1 MB/s | 0-unlimited',
  `dlbandwidth` smallint(5) NOT NULL DEFAULT '1024' COMMENT 'DLBandwidth: 1024 KB/sec ~ 1 MB/s | 0-unlimited',
  `quotasize` bigint(10) NOT NULL DEFAULT '4096' COMMENT 'in MB, 10240000~10.000GB',
  `quotafiles` int(11) NOT NULL DEFAULT '0' COMMENT '0 means unlimited.',
  `status` enum('0','1') COLLATE utf8_unicode_ci NOT NULL DEFAULT '1' COMMENT '1-enable | 0-disable',
  `createdtime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'now()',
  `lastupdate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'now()',
  `expirieddate` datetime NOT NULL COMMENT 'Su dung MySQL Event de cau hinh status=0',
  `comments` varchar(10000) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'desc',
  `dir` varchar(254) COLLATE utf8_unicode_ci NOT NULL DEFAULT '/opt/gluster-storage/www/' COMMENT '/opt/gluster-storage/www/',
  PRIMARY KEY (`user`),
  UNIQUE KEY `User` (`user`),
  UNIQUE KEY `id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='-- status: 1-enable | 0-disable\r\n-- password: md5(''<string>'')\r\n-- uid: 2001\r\n-- gid: 2001\r\n-- dir: /opt/xampp_www/manga247.com\r\n-- ULBandwidth: 1024 KB/sec ~ 1 MB/s\r\n-- DLBandwidth: 1024 KB/sec ~ 1 MB/s\r\n-- comment: ftp user manga247_com\r\n-- ipaccess: *-all | 192.168.1.0/24 | ...\r\n-- QuotaSize: 4096 MB\r\n-- QuotaFiles: 0 means unlimited.';

-- Data exporting was unselected.


-- Dumping structure for event pureftpd.UPDATE_CURRENT_TIME_1
DELIMITER //
CREATE DEFINER=`tinhcx`@`%` EVENT `UPDATE_CURRENT_TIME_1` ON SCHEDULE EVERY 5 SECOND STARTS '2015-02-06 12:55:00' ON COMPLETION NOT PRESERVE ENABLE DO UPDATE ftpd SET lastupdate=DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') WHERE USER='seq_no'//
DELIMITER ;


-- Dumping structure for view pureftpd.v_acct_info
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE `v_acct_info` (
	`id` INT(3) NOT NULL,
	`user` VARCHAR(16) NOT NULL COLLATE 'utf8_unicode_ci',
	`status` ENUM('0','1') NOT NULL COMMENT '1-enable | 0-disable' COLLATE 'utf8_unicode_ci',
	`createdtime` DATETIME NOT NULL COMMENT 'now()',
	`lastupdate` DATETIME NOT NULL COMMENT 'now()',
	`expirieddate` DATETIME NOT NULL COMMENT 'Su dung MySQL Event de cau hinh status=0',
	`dir` VARCHAR(254) NOT NULL COMMENT '/opt/gluster-storage/www/' COLLATE 'utf8_unicode_ci'
) ENGINE=MyISAM;


-- Dumping structure for view pureftpd.v_acct_info
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `v_acct_info`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_acct_info` AS select `ftpd`.`id` AS `id`,`ftpd`.`user` AS `user`,`ftpd`.`status` AS `status`,`ftpd`.`createdtime` AS `createdtime`,`ftpd`.`lastupdate` AS `lastupdate`,`ftpd`.`expirieddate` AS `expirieddate`,`ftpd`.`dir` AS `dir` from `ftpd`;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;

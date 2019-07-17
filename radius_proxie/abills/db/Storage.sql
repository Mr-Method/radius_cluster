CREATE TABLE IF NOT EXISTS `storage_accountability` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `storage_incoming_articles_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `count` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATETIME NOT NULL,
  `comments` TEXT,
  KEY `id` (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
);


CREATE TABLE IF NOT EXISTS `storage_articles` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL DEFAULT '',
  `article_type` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `measure` VARCHAR(2) NOT NULL DEFAULT '0',
  `comments` TEXT,
  `add_date` DATE NOT NULL,
  PRIMARY KEY (`id`),
  KEY `article_type` (`article_type`)
);

CREATE TABLE IF NOT EXISTS `storage_article_types` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) DEFAULT NULL,
  `comments` TEXT,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `storage_discard` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_incoming_articles_id` INT(10) UNSIGNED DEFAULT '0',
  `count` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `aid` INT(10) UNSIGNED DEFAULT '0',
  `date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `comments` MEDIUMTEXT,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
)
  COMMENT = 'Storage discard items';

CREATE TABLE IF NOT EXISTS `storage_incoming` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATETIME NOT NULL,
  `aid` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `supplier_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `storage_id` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `supplier_id` (`supplier_id`)
);


CREATE TABLE IF NOT EXISTS `storage_incoming_articles` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `article_id` SMALLINT(6) UNSIGNED DEFAULT NULL,
  `count` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `sn` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `main_article_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `storage_incoming_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `sell_price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `rent_price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `storage_incoming_id` (`storage_incoming_id`),
  KEY `article_id` (`article_id`)
);


CREATE TABLE IF NOT EXISTS `storage_installation` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_incoming_articles_id` INT(10) UNSIGNED DEFAULT '0',
  `location_id` INT(10) UNSIGNED DEFAULT '0',
  `count` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `installed_aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `mac` VARCHAR(40) NOT NULL DEFAULT '',
  `type` SMALLINT(1) NOT NULL DEFAULT 0,
  `grounds` VARCHAR(40) NOT NULL DEFAULT '',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
)
  COMMENT = 'Storage user installation';


CREATE TABLE IF NOT EXISTS `storage_log` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `date` DATETIME NOT NULL,
  `aid` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `storage_main_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `storage_id` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  `action` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `count` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `storage_installation_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `storage_reserve` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_incoming_articles_id` INT(10) UNSIGNED DEFAULT '0',
  `count` INT(10) UNSIGNED DEFAULT '0',
  `aid` INT(10) UNSIGNED DEFAULT '0',
  `date` DATETIME DEFAULT NULL,
  `comments` TEXT,
  PRIMARY KEY (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
);

CREATE TABLE IF NOT EXISTS `storage_suppliers` (
  `id` SMALLINT(6) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(15) NOT NULL DEFAULT '',
  `date` DATE NOT NULL,
  `okpo` VARCHAR(12) NOT NULL DEFAULT '',
  `inn` VARCHAR(20) NOT NULL DEFAULT '',
  `inn_svid` VARCHAR(40) NOT NULL DEFAULT '',
  `bank_name` VARCHAR(200) NOT NULL DEFAULT '',
  `mfo` VARCHAR(8) NOT NULL DEFAULT '',
  `account` VARCHAR(16) NOT NULL DEFAULT '',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `phone2` VARCHAR(16) NOT NULL DEFAULT '',
  `fax` VARCHAR(16) NOT NULL DEFAULT '',
  `url` VARCHAR(100) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `icq` VARCHAR(12) NOT NULL DEFAULT '',
  `accountant` VARCHAR(150) NOT NULL DEFAULT '',
  `director` VARCHAR(150) NOT NULL DEFAULT '',
  `managment` VARCHAR(150) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
);

CREATE TABLE IF NOT EXISTS `storage_sn` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_incoming_articles_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `storage_installation_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `serial` TEXT CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Storage serial numbers';

CREATE TABLE IF NOT EXISTS `storage_storages` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` VARCHAR(60) NOT NULL DEFAULT '',
  PRIMARY KEY `storage_id` (`id`)
)
  COMMENT = 'List of storages';




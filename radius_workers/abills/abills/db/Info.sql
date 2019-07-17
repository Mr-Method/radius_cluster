CREATE TABLE IF NOT EXISTS `info_info`
(
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `obj_type` VARCHAR(30) DEFAULT ''         NOT NULL,
  `obj_id` INT DEFAULT 0                  NOT NULL,
  `comment_id` SMALLINT(6) DEFAULT 0          NOT NULL,
  `media_id` SMALLINT(6) DEFAULT 0          NOT NULL,
  `location_id` INT(11) NOT NULL DEFAULT '0',
  `date` DATETIME NOT NULL,
  `admin_id` INT NOT NULL,
  `document_id` SMALLINT(6) NOT NULL DEFAULT '0',

  PRIMARY KEY `id` (`id`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal info';

CREATE TABLE IF NOT EXISTS `info_media`
(
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `filename` VARCHAR(50) NOT NULL,
  `real_name` TEXT,
  `content_type` VARCHAR(30) NOT NULL,
  `file` BLOB NULL,
  `content_size` VARCHAR(30) DEFAULT '0' NOT NULL
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal media';

CREATE TABLE IF NOT EXISTS `info_comments`
(
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `text` VARCHAR(300) NOT NULL,
  PRIMARY KEY `id` (`id`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal comments';

CREATE TABLE IF NOT EXISTS `info_locations` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `timestamp` DATETIME NOT NULL DEFAULT '0000-00-00',
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  `comment` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal GPS location';


CREATE TABLE IF NOT EXISTS `info_documents`
(
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `filename` VARCHAR(50) NOT NULL,
  `real_name` TEXT,
  `file` BLOB NULL,
  `content_type` VARCHAR(30) NOT NULL,
  `content_size` VARCHAR(30) DEFAULT '0' NOT NULL
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'Info universal documents';

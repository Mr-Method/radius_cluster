CREATE TABLE IF NOT EXISTS `paysys_log` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `system_id` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `commission` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `transaction_id` VARCHAR(24) NOT NULL DEFAULT '',
  `info` TEXT NOT NULL,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `code` BLOB NOT NULL,
  `paysys_ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `ps_transaction_id` (`domain_id`, `transaction_id`)
)
  COMMENT = 'Paysys log';

CREATE TABLE IF NOT EXISTS `paysys_main` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `token` TINYTEXT,
  `sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `paysys_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `external_last_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `attempts` SMALLINT(2) NOT NULL DEFAULT 0,
  `closed` SMALLINT(1) NOT NULL DEFAULT 0,
  `external_user_ip` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE (`uid`, `paysys_id`)
) COMMENT = 'Paysys user account';

CREATE TABLE IF NOT EXISTS `paysys_terminals` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `type` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `status` SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `location_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `comment` TEXT,
  UNIQUE KEY `id` (`id`)
) COMMENT = 'Table for paysys terminals';

CREATE TABLE IF NOT EXISTS `paysys_terminals_types` (
  `id` INT(3) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `comment` TEXT,
  UNIQUE KEY `id` (`id`)
) COMMENT = 'Table for paysys terminals types';

CREATE TABLE IF NOT EXISTS `paysys_tyme_report` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `txn_id` BIGINT(20) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `user` VARCHAR(20) NOT NULL DEFAULT '',
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `terminal` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `txn_id` (`txn_id`)
)
  COMMENT = 'Table for Tyme report';
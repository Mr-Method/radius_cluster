CREATE TABLE IF NOT EXISTS `iptv_main` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(100) NOT NULL DEFAULT '',
  `cid` VARCHAR(35) NOT NULL DEFAULT '',
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `registration` DATE DEFAULT '0000-00-00',
  `pin` BLOB NOT NULL,
  `vod` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `dvcrypt_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `subscribe_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `email` VARCHAR(100) NOT NULL DEFAULT '',
  `service_id` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `tp_id` (`tp_id`)
)
  COMMENT = 'IPTV users settings';

CREATE TABLE IF NOT EXISTS `iptv_tps` (
  `id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `day_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `week_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `month_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `max_session_duration` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `min_session_cost` DOUBLE(15, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `rad_pairs` TEXT NOT NULL,
  `first_period` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `first_period_step` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `next_period` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `next_period_step` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `free_time` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `service_id` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'IPTV TPs';

CREATE TABLE IF NOT EXISTS `iptv_channels` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `num` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `port` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `filter_id` VARCHAR(100) NOT NULL DEFAULT '',
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `stream` VARCHAR(150) NOT NULL DEFAULT '',
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `genre_id` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `num` (`num`)
)
  COMMENT = 'IPTV channels';

CREATE TABLE IF NOT EXISTS `iptv_ti_channels` (
  `interval_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `channel_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `month_price` DOUBLE(15, 2) NOT NULL DEFAULT '0.00',
  `day_price` DOUBLE(15, 2) NOT NULL DEFAULT '0.00',
  `mandatory` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `channel_id` (`channel_id`, `interval_id`)
)
  COMMENT = 'IPTV channels prices';

CREATE TABLE IF NOT EXISTS `iptv_users_channels` (
  `id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `channel_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `changed` DATETIME NOT NULL,
  UNIQUE KEY `id` (`id`, `channel_id`, `tp_id`)
)
  COMMENT = 'Iptv users channels';


CREATE TABLE IF NOT EXISTS `iptv_calls` (
  `status` INT(3) NOT NULL DEFAULT '0',
  `started` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `nas_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `nas_port_id` INT(6) UNSIGNED NOT NULL DEFAULT '0',
  `acct_session_id` VARCHAR(25) NOT NULL DEFAULT '',
  `acct_session_time` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `connect_term_reason` INT(4) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `lupdated` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000',
  `CID` VARCHAR(18) NOT NULL DEFAULT '',
  `CONNECT_INFO` VARCHAR(35) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `join_service` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `turbo_mode` VARCHAR(30) NOT NULL DEFAULT '',
  `guest` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  KEY `acct_session_id` (`acct_session_id`),
  KEY `uid` (`uid`)
) COMMENT = 'Iptv online';


CREATE TABLE IF NOT EXISTS `iptv_subscribes` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `status` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `ext_id` VARCHAR(20) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `password` BLOB NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ext_id` (`ext_id`)
)
  COMMENT = 'IPTV Subscribes';


CREATE TABLE IF NOT EXISTS `iptv_screens` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `num` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(60) NOT NULL DEFAULT '',
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `month_fee` DOUBLE(15, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `day_fee` DOUBLE(15, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tp_id` (`tp_id`, `num`)
)
  COMMENT = 'IPTV Extra screens';


CREATE TABLE IF NOT EXISTS `iptv_users_screens` (
  `service_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `screen_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `cid` VARCHAR(60) NOT NULL DEFAULT '',
  `serial` VARCHAR(60) NOT NULL DEFAULT '',
  `hardware_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `service_id` (`service_id`, `screen_id`)
)
  COMMENT = 'IPTV Extra screens';


CREATE TABLE IF NOT EXISTS `iptv_services` (
  `id` TINYINT(2) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `module` VARCHAR(24) NOT NULL DEFAULT '',
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `comment` VARCHAR(250) DEFAULT '',
  `login` VARCHAR(24) NOT NULL DEFAULT '',
  `password` BLOB,
  `url` VARCHAR(120) NOT NULL DEFAULT '',
  `user_portal` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `debug` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `subscribe_count` TINYINT(2) UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'IPTV Services';

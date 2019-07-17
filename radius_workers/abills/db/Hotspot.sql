CREATE TABLE IF NOT EXISTS `hotspot_visits` (
  `id` VARCHAR(32) PRIMARY KEY NOT NULL,
  `first_seen` DATETIME NOT NULL DEFAULT NOW(),
  `browser_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `os_id` SMALLINT(6) NOT NULL DEFAULT 0,
  `language` VARCHAR(32) NOT NULL DEFAULT '',
  `country` VARCHAR(32) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS `hotspot_oses` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
  `version` SMALLINT(6) NOT NULL DEFAULT 0,
  `mobile` TINYINT(1) NOT NULL DEFAULT 0
)
  COMMENT = 'Visitors OSes';

CREATE TABLE IF NOT EXISTS `hotspot_user_agents` (
  `id` VARCHAR(32) PRIMARY KEY NOT NULL REFERENCES `hotspot_visits` (`id`)
    ON DELETE CASCADE,
  `user_agent` TEXT
)
  COMMENT = 'Hotspot user agents';

CREATE TABLE IF NOT EXISTS `hotspot_browsers` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
  `version` SMALLINT(6) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS `hotspot_logins` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
  `visit_id` VARCHAR(32) NOT NULL REFERENCES `hotspot_visits` (`id`)
    ON DELETE CASCADE,
  `uid` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`),
  `login_time` DATETIME NOT NULL DEFAULT NOW()
)
  COMMENT = 'Hotspot visitors browsers';

CREATE TABLE IF NOT EXISTS `hotspot_adverts` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `comments` TEXT,
  `price_per_show` DOUBLE(11, 2) NOT NULL DEFAULT 0,
  `price_per_period` DOUBLE(11, 2) NOT NULL DEFAULT 0,
  `period` ENUM ('month', 'week', 'day', 'year') NOT NULL DEFAULT 'month',
  `url` TEXT,
  `nas_id` SMALLINT(5) UNSIGNED NOT NULL REFERENCES `nas` (`id`)
);

CREATE TABLE IF NOT EXISTS `hotspot_advert_shows` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT NOT NULL  PRIMARY KEY,
  `uid` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`),
  `ad_id` INT(11) UNSIGNED NOT NULL REFERENCES `hotspot_adverts` (`id`),
  `showed` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP
);


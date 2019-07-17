CREATE TABLE IF NOT EXISTS `gps_tracker_locations`
(
  `id` INT(11) PRIMARY KEY AUTO_INCREMENT,
  `aid` SMALLINT(6) NOT NULL,
  `gps_time` TIMESTAMP NOT NULL,
  `coord_x` DOUBLE NOT NULL,
  `coord_y` DOUBLE NOT NULL,
  `speed` DOUBLE DEFAULT '0' NOT NULL,
  `altitude` DOUBLE DEFAULT '0' NOT NULL,
  `bearing` DOUBLE DEFAULT '0' NOT NULL,
  `batt` DOUBLE DEFAULT '0' NOT NULL,
  INDEX `aid` (`aid`),
  INDEX `gps_time`(`gps_time`)
)
  COMMENT = 'Locations got from GPS trackers';

CREATE TABLE IF NOT EXISTS `gps_unregistered_trackers`
(
  `gps_imei` VARCHAR(30) PRIMARY KEY NOT NULL,
  `gps_time` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ip` INT(11) UNSIGNED NOT NULL     DEFAULT 0
)
  COMMENT = 'Trackers that were not registered when location got';

CREATE TABLE IF NOT EXISTS `gps_admins_thumbnails` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL UNIQUE REFERENCES `admins` (`aid`),
  `thumbnail_path` VARCHAR(40) NOT NULL DEFAULT '',
  PRIMARY KEY `thumbnail_id` (`id`)
)
  COMMENT = 'GPS Admin Thumbnails';
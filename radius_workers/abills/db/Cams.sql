CREATE TABLE IF NOT EXISTS `cams_tp` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL,
  `abon_id` SMALLINT(6) UNSIGNED UNIQUE NOT NULL REFERENCES `abon_tariffs` (`id`) ON DELETE RESTRICT,
  `streams_count` SMALLINT(6) UNSIGNED
)
  COMMENT = 'Cams use Abon module subscribes';

CREATE TABLE IF NOT EXISTS `cams_main` (
  `uid` INT(11) UNSIGNED PRIMARY KEY REFERENCES `users` (`uid`) ON DELETE CASCADE,
  `tp_id` INT(11) UNSIGNED REFERENCES `cams_tp` (`id`) ON DELETE RESTRICT,
  `created` DATETIME
)
  COMMENT = 'Users subscribed to cams';

CREATE TABLE IF NOT EXISTS `cams_streams` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uid` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`),
  `disabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `name` VARCHAR(32) NOT NULL,
  `host` VARCHAR(255) NOT NULL DEFAULT '0.0.0.0',
  `rtsp_path` TEXT,
  `rtsp_port` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 554,
  `login` VARCHAR(32) NOT NULL,
  `password` BLOB NOT NULL,
  `zoneminder_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `orientation` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0
)
  COMMENT = 'Storing all streams';

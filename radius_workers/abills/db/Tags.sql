CREATE TABLE IF NOT EXISTS `tags` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `priority` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(20) NOT NULL DEFAULT '',
  `comments` TEXT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Tags';


CREATE TABLE IF NOT EXISTS `tags_users` (
  `uid` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `tag_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  UNIQUE KEY `uid_tag_id` (`uid`, `tag_id`)
)
  COMMENT = 'Users Tags';


CREATE TABLE IF NOT EXISTS `internet_users_pool` (
  `service_id`  SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `pool_id`   SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `comments`    VARCHAR(60) NOT NULL DEFAULT '',
  PRIMARY KEY (`service_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Internet users ip pool';
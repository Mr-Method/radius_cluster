SET SQL_MODE='NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `tasks_main` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `task_type` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `descr` TEXT NOT NULL,
  `state` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `responsible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `plan_date` DATE NOT NULL DEFAULT '0000-00-00',
  `control_date` DATE NOT NULL DEFAULT '0000-00-00',
  `additional_values` TEXT NOT NULL,
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Tasks';

CREATE TABLE IF NOT EXISTS `tasks_type` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `additional_fields` TEXT NOT NULL,
  `plugins` TEXT NOT NULL,
  `admins` TEXT NOT NULL,
  `partcipiants` TEXT NOT NULL,
  `hidden` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Tasks type';

CREATE TABLE IF NOT EXISTS `tasks_admins` (
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `responsible` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `admin` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `sysadmin` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`aid`)
)
  COMMENT = 'Tasks admins';

CREATE TABLE IF NOT EXISTS `tasks_partcipiants` (
  `id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  CONSTRAINT id_aid PRIMARY KEY (id,aid)
)
  COMMENT = 'Tasks partcipiants';

CREATE TABLE IF NOT EXISTS `tasks_plugins` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `enable` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `descr` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Tasks plugins';
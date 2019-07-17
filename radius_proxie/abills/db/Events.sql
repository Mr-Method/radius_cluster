CREATE TABLE IF NOT EXISTS `events_state` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  PRIMARY KEY `event_state_id` (`id`)
)
  COMMENT = 'Events_state and name';

INSERT INTO `events_state` VALUES
  (NULL, '$lang{NEW}'),
  (NULL, '$lang{RECV}'),
  (NULL, '$lang{CLOSED}'),
  (NULL, '$lang{IN_WORK}');

CREATE TABLE IF NOT EXISTS `events_priority` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  `value` SMALLINT(6) NOT NULL,
  PRIMARY KEY `event_priority_id` (`id`)
)
  COMMENT = 'Events priorities name';


CREATE TABLE IF NOT EXISTS `events_priority_send_types` (
  `aid` SMALLINT(6) UNSIGNED NOT NULL REFERENCES `admins` (`aid`)
    ON DELETE CASCADE,
  `priority_id` SMALLINT(6) UNSIGNED NOT NULL REFERENCES `events_priority` (`id`)
    ON DELETE RESTRICT,
  `send_types` VARCHAR(255) NOT NULL DEFAULT '',
  UNIQUE `aid_priority` (`aid`, `priority_id`)
)
  COMMENT = 'Defines how each admin will recieve notifications for defined priority';

INSERT INTO `events_priority` VALUES
  (NULL, '$lang{VERY_LOW}', 0),
  (NULL, '$lang{LOW}', 1),
  (NULL, '$lang{NORMAL}', 2),
  (NULL, '$lang{HIGH}', 3),
  (NULL, '$lang{CRITICAL}', 4);

CREATE TABLE IF NOT EXISTS `events_privacy` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL,
  `value` SMALLINT(6) NOT NULL,
  PRIMARY KEY `event_privacy_id` (`id`)
)
  COMMENT = 'Events privacy settings';

INSERT INTO `events_privacy` VALUES
  (NULL, '$lang{ALL}', 0),
  (NULL, '$lang{ADMIN} $lang{GROUP}', 1),
  (NULL, '$lang{ADMIN} $lang{USER} $lang{GROUP}', 2),
  (NULL, '$lang{ADMIN} $lang{GEOZONE}', 3);


CREATE TABLE IF NOT EXISTS `events_group` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL,
  `modules` TEXT NOT NULL,
  PRIMARY KEY `event_groups_id` (`id`),
  UNIQUE `event_group_name` (`name`)
)
  COMMENT = 'Events privacy settings';
REPLACE INTO `events_group` (`id`, `name`, `modules`) VALUES (1, 'BASE', 'Events,Msgs,SYSTEM');

CREATE TABLE IF NOT EXISTS `events` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT,
  `module` VARCHAR(30) NOT NULL DEFAULT 'EXTERNAL',
  `comments` VARCHAR(60) NOT NULL DEFAULT 'Event comment',
  `extra` VARCHAR(60) NOT NULL DEFAULT '',
  `state_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_state` (`id`)
    ON DELETE RESTRICT,
  `priority_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_priority` (`id`)
    ON DELETE RESTRICT,
  `privacy_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_privacy` (`id`)
    ON DELETE RESTRICT,
  `group_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1 REFERENCES `events_group` (`id`)
    ON DELETE RESTRICT,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY `event_id` (`id`)
)
  COMMENT = 'Events is some information that admin have to see';

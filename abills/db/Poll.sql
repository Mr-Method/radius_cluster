CREATE TABLE IF NOT EXISTS `poll_polls` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `subject` CHAR(40) NOT NULL DEFAULT '',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `description` TEXT NULL,
  `status` SMALLINT NOT NULL DEFAULT 0,
  UNIQUE (`id`)
)
  COMMENT = 'Table for polls';

CREATE TABLE IF NOT EXISTS `poll_answers` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `poll_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `answer` CHAR(40) NOT NULL DEFAULT '',
  UNIQUE (`id`),
  FOREIGN KEY (`poll_id`) REFERENCES `poll_polls` (`id`) ON DELETE CASCADE
)
  COMMENT = 'Table for polls answers';

CREATE TABLE IF NOT EXISTS `poll_votes` (
  `answer_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `poll_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `voter` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE (`poll_id`, `voter`),
  FOREIGN KEY (`poll_id`) REFERENCES `poll_polls` (`id`) ON DELETE CASCADE
)
  COMMENT = 'Table for votes';

CREATE TABLE IF NOT EXISTS `poll_discussion` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `poll_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `message` TEXT NOT NULL,
  `voter` VARCHAR(20) NOT NULL DEFAULT '',
  UNIQUE (`id`),
  FOREIGN KEY (`poll_id`) REFERENCES `poll_polls` (`id`) ON DELETE CASCADE
)
  COMMENT = 'Table for discussion';
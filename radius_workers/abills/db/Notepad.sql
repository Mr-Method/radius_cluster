CREATE TABLE IF NOT EXISTS `notepad` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `notified` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `create_date` DATE DEFAULT '0000-00-00',
  `status` INT(3) UNSIGNED NOT NULL DEFAULT 0,
  `subject` VARCHAR(60) NOT NULL DEFAULT '',
  `text` VARCHAR(200),
  `aid` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE `subject_text` (`subject`, `aid`, `status`),
  PRIMARY KEY (`id`)
)
  COMMENT = 'Notepad';

CREATE TABLE IF NOT EXISTS `notepad_reminders` (
  `id` INT(11) UNSIGNED NOT NULL REFERENCES `notepad` (`id`)
    ON DELETE CASCADE,
  `minute` SMALLINT(2) NOT NULL  DEFAULT '0',
  `hour` SMALLINT(2) NOT NULL  DEFAULT '0',
  `week_day` SMALLINT(2) NOT NULL  DEFAULT '0',
  `month_day` VARCHAR(30) NOT NULL  DEFAULT '0',
  `month` SMALLINT(2) NOT NULL  DEFAULT '0',
  `year` SMALLINT(6) NOT NULL  DEFAULT '0',
  `holidays` TINYINT(1) NOT NULL  DEFAULT '0'
)
  COMMENT = 'Periodic reminders';

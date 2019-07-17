CREATE TABLE IF NOT EXISTS `employees_positions` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `position` CHAR(40) UNIQUE NOT NULL DEFAULT '',
  `subordination` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `vacancy` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Employees positions';

INSERT INTO `employees_positions` VALUES
  (1, "$lang{ADMIN}", 0, 0),
  (2, "$lang{ACCOUNTANT}", 0, 0),
  (3, "$lang{MANAGER}", 0, 0);


CREATE TABLE IF NOT EXISTS `employees_geolocation` (
  `employee_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `district_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `street_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `build_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0
)
  COMMENT = 'Employees geolocation';

CREATE TABLE IF NOT EXISTS `employees_profile` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `fio` VARCHAR(188) NOT NULL DEFAULT '',
  `date_of_birth` DATE NOT NULL DEFAULT '0000-00-00',
  `email` VARCHAR(188) UNIQUE NOT NULL DEFAULT '',
  `phone` VARCHAR(188) UNIQUE NOT NULL DEFAULT '',
  `position_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `rating` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Employees profile';

CREATE TABLE IF NOT EXISTS `employees_profile_question` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `position_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `question` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY `position_id` (`position_id`) REFERENCES `employees_positions` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
  COMMENT = 'Employees profile question';

CREATE TABLE IF NOT EXISTS `employees_profile_reply` (
  `question_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `profile_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `reply` TEXT NOT NULL,
  FOREIGN KEY `question_id` (`question_id`) REFERENCES `employees_profile_question` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
  COMMENT = 'Employees profile reply';

CREATE TABLE IF NOT EXISTS `employees_rfid_log` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL DEFAULT NOW(),
  `rfid` INT(10) UNSIGNED,
  `aid` SMALLINT(6) NOT NULL DEFAULT 0
)
  COMMENT = 'All registered RFID entries';

CREATE INDEX `_ik_datetime`
  ON `employees_rfid_log` (`datetime`);
CREATE INDEX `_ik_rfid`
  ON `employees_rfid_log` (`rfid`);


CREATE TABLE IF NOT EXISTS `employees_daily_notes` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `day` DATE NOT NULL DEFAULT '0000-00-00',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL
)
  COMMENT = 'Admins daily notes';

CREATE TABLE IF NOT EXISTS `employees_vacations` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `start_date` DATE NOT NULL DEFAULT '0000-00-00',
  `end_date` DATE NOT NULL DEFAULT '0000-00-00'
)
  COMMENT = 'Employees vacations';

CREATE TABLE IF NOT EXISTS  `employees_duty` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `start_date` DATE NOT NULL DEFAULT '0000-00-00',
  `duration` INT NOT NULL DEFAULT 0
)
  COMMENT = 'Employees duty';

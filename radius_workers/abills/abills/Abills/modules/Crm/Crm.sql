CREATE TABLE IF NOT EXISTS `cashbox_cashboxes` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Cashboxes';

CREATE TABLE IF NOT EXISTS `cashbox_spending` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `amount` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  `spending_type_id` SMALLINT NOT NULL DEFAULT 0,
  `cashbox_id` SMALLINT NOT NULL DEFAULT 0,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Spending';

CREATE TABLE IF NOT EXISTS `cashbox_spending_types` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Spending types';

CREATE TABLE IF NOT EXISTS `cashbox_coming` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `amount` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  `coming_type_id` SMALLINT NOT NULL DEFAULT 0,
  `cashbox_id` SMALLINT NOT NULL DEFAULT 0,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Coming';

CREATE TABLE IF NOT EXISTS `cashbox_coming_types` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `comments` TEXT,
  PRIMARY KEY (`id`)
) COMMENT = 'Coming types';

CREATE TABLE IF NOT EXISTS `crm_bet` (
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `type` SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `bet` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  `bet_per_hour` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  `bet_overtime` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`aid`)
)
  COMMENT = 'Work schedule for admins';

CREATE TABLE IF NOT EXISTS `crm_salaries_payed` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `year` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
  `month` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `bet` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Work schedule for admins';

CREATE TABLE IF NOT EXISTS `crm_reference_works` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` CHAR(60) NOT NULL DEFAULT '',
  `time` INT UNSIGNED NOT NULL DEFAULT 0,
  `units` CHAR(40) NOT NULL DEFAULT '',
  `sum` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  `disabled` TINYINT(1) NOT NULL DEFAULT 0,
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Reference works';

CREATE TABLE IF NOT EXISTS `crm_works` (
  `id` INT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
  `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `employee_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `work_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `ratio` DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `sum` DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `extra_sum` DOUBLE(6, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `comments` TEXT NOT NULL,
  `paid` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `ext_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  KEY `ext_id` (`ext_id`),
  UNIQUE `employee_ext_id` (`employee_id`, `ext_id`, `work_id`)
)
  COMMENT = 'Employes works';

CREATE TABLE IF NOT EXISTS `crm_leads` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `fio` VARCHAR(120) NOT NULL DEFAULT '',
  `phone` VARCHAR(120) NOT NULL DEFAULT '',
  `company` VARCHAR(120) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `country` VARCHAR(80) NOT NULL DEFAULT '',
  `city` VARCHAR(80) NOT NULL DEFAULT '',
  `address` VARCHAR(100) NOT NULL DEFAULT '',
  `source` int(1) NOT NULL DEFAULT 0,
  `responsible` SMALLINT(4) NOT NULL DEFAULT 0,
  `date` date NOT NULL DEFAULT '0000-00-00',
  `current_step` int NOT NULL DEFAULT 0,
  `priority` SMALLINT(1) NOT NULL DEFAULT 0,
  `comments` TEXT,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm leads';

CREATE TABLE IF NOT EXISTS `crm_progressbar_steps` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `step_number` INT UNSIGNED NOT NULL DEFAULT 0,
  `name` CHAR(40) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  `description` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm progressbar steps';

REPLACE INTO `crm_progressbar_steps` (`id`, `step_number`, `name`, `color`, `description`) VALUE
  ('1', '1', '$lang{NEW_LEAD}', '#5479e7', ''),
  ('2', '2', '$lang{CONTRACT_SIGNED}', '#25d2f1', ''),
  ('3', '3', '$lang{THE_WORKS}', '#ff8000', ''),
  ('4', '4', '$lang{CONVERSION}', '#f1233d', '');

CREATE TABLE IF NOT EXISTS `crm_leads_sources` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` CHAR(40) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm leads source';

REPLACE INTO `crm_leads_sources` (`id`, `name`, `comments`) VALUE
  ('1', '$lang{PHONE}', ''),
  ('2', 'E-mail', ''),
  ('3', '$lang{SOCIAL_NETWORKS}', ''),
  ('4', '$lang{REFERRALS}', '');

CREATE TABLE IF NOT EXISTS `crm_progressbar_step_comments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `step_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `lead_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `message` TEXT NOT NULL,
  `date` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `action_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `status` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `planned_date` DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`),
  UNIQUE (`lead_id`, `date`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Comments for each step in progressbar';

CREATE TABLE IF NOT EXISTS `crm_actions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` char(60) NOT NULL DEFAULT '',
  `action` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Entity ACTION';

CREATE TABLE IF NOT EXISTS `crm_working_time_norms` (
  `year` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
  `month` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `hours` SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  `days`SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY `year_month` (`year`, `month`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Entity working time norms';
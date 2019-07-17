CREATE TABLE IF NOT EXISTS `cashbox_cashboxes` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `comments` TEXT,
  PRIMARY KEY (`id`)
) COMMENT = 'Cashboxes';

CREATE TABLE IF NOT EXISTS `cashbox_spending` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `amount` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  `spending_type_id` SMALLINT NOT NULL DEFAULT 0,
  `cashbox_id` SMALLINT NOT NULL DEFAULT 0,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `comments` TEXT,
  PRIMARY KEY (`id`)
) COMMENT = 'Spending';

CREATE TABLE IF NOT EXISTS `cashbox_spending_types` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `comments` TEXT,
  PRIMARY KEY (`id`)
) COMMENT = 'Spending types';

CREATE TABLE IF NOT EXISTS `cashbox_coming` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `amount` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  `coming_type_id` SMALLINT NOT NULL DEFAULT 0,
  `cashbox_id` SMALLINT NOT NULL DEFAULT 0,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `comments` TEXT,
  PRIMARY KEY (`id`)
) COMMENT = 'Coming';

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
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `year` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
  `month` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `bet` DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`aid`, `month`)
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

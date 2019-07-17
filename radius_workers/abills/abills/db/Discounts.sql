CREATE TABLE IF NOT EXISTS `discounts_discounts` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `name` CHAR(40) NOT NULL,
  `size` SMALLINT NOT NULL DEFAULT '0',
  `comments` TEXT,
  PRIMARY KEY (`id`)
) COMMENT = 'Discounts table';

CREATE TABLE IF NOT EXISTS `discounts_user_discounts` (
  `uid` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `discount_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  UNIQUE KEY `uid_discount_id` (`uid`, `discount_id`)
) COMMENT = 'User discounts';
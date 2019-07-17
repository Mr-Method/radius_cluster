CREATE TABLE IF NOT EXISTS `price_services_list` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL DEFAULT '',
  `price` FLOAT(12, 2) UNSIGNED NOT NULL DEFAULT 0,
  `comments` TEXT NOT NULL,
  PRIMARY KEY `services_list_id` (`id`)
);
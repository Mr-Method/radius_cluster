DROP TABLE IF EXISTS `cablecat_cables`;
DROP TABLE IF EXISTS `cablecat_color_schemes`;
DROP TABLE IF EXISTS `cablecat_cable_types`;
DROP TABLE IF EXISTS `cablecat_wells`;
DROP TABLE IF EXISTS `cablecat_connecters`;
DROP TABLE IF EXISTS `cablecat_connecter_types`;
DROP TABLE IF EXISTS `cablecat_splitter_types`;
DROP TABLE IF EXISTS `cablecat_splitters`;
DROP TABLE IF EXISTS `cablecat_links`;
DROP TABLE IF EXISTS `cablecat_commutations`;
DROP TABLE IF EXISTS `cablecat_commutation_cables`;
DROP TABLE IF EXISTS `cablecat_commutations_cables`;
DROP TABLE IF EXISTS `cablecat_commutation_links`;

CREATE TABLE IF NOT EXISTS `cablecat_color_schemes` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `colors` TEXT
)
  CHARSET = utf8
  COMMENT = 'Cable color schemes names';

CREATE TABLE IF NOT EXISTS `cablecat_cable_types` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `color_scheme_id` SMALLINT(6) NOT NULL    DEFAULT 1 REFERENCES `cablecat_color_schemes` (`id`),
  `modules_color_scheme_id` SMALLINT(6) NOT NULL    DEFAULT 1 REFERENCES `cablecat_color_schemes` (`id`),
  `fibers_count` SMALLINT(6) NOT NULL    DEFAULT 1,
  `modules_count` SMALLINT(6) NOT NULL    DEFAULT 1,
  `outer_color` VARCHAR(32) NOT NULL    DEFAULT '#000000',
  `fibers_type_name` VARCHAR(32) NOT NULL    DEFAULT '',
  `comments` TEXT,
  `line_width` SMALLINT(3) NOT NULL DEFAULT 1
)
  CHARSET = utf8
  COMMENT = 'Cable types';

CREATE TABLE IF NOT EXISTS `cablecat_cables` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `type_id` SMALLINT(6) NOT NULL REFERENCES `cablecat_cable_types` (`id`),
  `well_1` INT(11) UNSIGNED DEFAULT 0 REFERENCES `cablecat_wells` (`id`)
    ON DELETE RESTRICT,
  `well_2` INT(11) UNSIGNED DEFAULT 0 REFERENCES `cablecat_wells` (`id`)
    ON DELETE RESTRICT,
  `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE SET NULL,
  `length` DOUBLE NOT NULL DEFAULT 0,
  `reserve` DOUBLE NOT NULL DEFAULT 0
)
  CHARSET = utf8
  COMMENT = 'Installed cables';

REPLACE INTO `cablecat_color_schemes` (`id`, `name`, `colors`)
VALUES (1, 'Старлинк, Инкаб, Интегра-Кабель',
        'fc0204,fcfe04,048204,0402fc,840204,040204,fc9a04,840284,fcfefc,848284,04fefc,fc9acc,fc0204+,fcfe04+,048204+,0402fc+,840204+,040204+,fc9a04+,840284+,fcfefc+,848284+,04fefc+,fc9acc+'),
  (2, 'Оптен-2', 'fc0204,fcfe04'),
  (3, 'Оптен-4', 'fc0204,fcfe04,048204,0402fc'),
  (4, 'Оптен-6', 'fc0204,fcfe04,048204,0402fc,840204,040204'),
  (5, 'Оптен-8', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204'),
  (6, 'Оптен-10', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284'),
  (7, 'Оптен-12', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284,04fefc,fc9acc'),
  (8, 'Оптен-14', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284,04fefc,fc9acc,04fe04,9cce04'),
  (9, 'Оптен-16', 'fc0204,fc9a04,fcfe04,048204,0402fc,840284,840204,040204,fcfefc,848284,04fefc,fc9acc,04fe04,9cce04,fcfe9c,dbefdb'),
  (10, 'ОКС 01-4', '048204,fc0204,0402fc,fcfe04'),
  (11, 'ОКС 01-6', '04fefc,fcfe04,fc9a04,fc9acc,848284,dbefdb'),
  (12, 'ОКС 01-8', '048204,fc0204,0402fc,fcfe04,840204,fc9a04,848284,840284'),
  (13, 'ОКС 01-10', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,fc9a04,fc9acc,848284,840284'),
  (14, 'ОКС 01-12', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,840204,fc9a04,fc9acc,848284,840284,fde910'),
  (15, 'ОКС 01-16', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,fc9acc,840204,fc9a04,848284,840284,040204,9cce04,fde910,fcfe9c,fcfefc'),
  (16, 'СОКК', 'fcfefc,fc9a04,840204,048204,fc0204,0402fc,fcfe04,848284,040204,840284,fc9acc,04fefc,fde910,fcfe9c,9cce04,9c3232'),
  (17, 'Завод «Южкабель»', 'dbefdb,fc0204,0402fc,048204,fcfe04,840284,fc9a04,840204,04fefc,fc9acc,848284,040204'),
  (18, 'Электрокабель', 'dbefdb,048204,fc0204,0402fc,04fefc,fcfe04,840204,fc9a04,fc9acc,840284,848284,040204'),
  (19, ' IEC 60304', 'fcfefc,fc0204,040204,fcfe04,0402fc,048204,fc9a04,848284,840204,04fefc,840284,fc9acc,fcfefc+,fc0204+,040204+,fcfe04+,0402fc+,048204+,fc9a04+,848284+,840204+,04fefc+,840284+,fc9acc+'),
  (20, 'Belden (FinMark)', '0402fc,fc9a04,048204,840204,848284,fcfefc,fc0204,040204,fcfe04,840284,fc9acc,04fefc,0402fc+,fc9a04+,048204+,840204+,848284+,fcfefc+,fc0204+,040204+,fcfe04+,840284+,fc9acc+,04fefc+'),
  (21, 'nkt', 'fc0204,048204,fcfe04,0402fc,dbefdb,848284,840204,840284,04fefc,fcfefc,fc9acc,fc9a04,fc0204+,048204+,fcfe04+,0402fc+,dbefdb+,848284+,840204+,840284+,04fefc+,fcfefc+,fc9acc+,fc9a04+'),
  (22, 'R&M',
   'fc0204,048204,fcfe04,0402fc,fcfefc,848284,840204,840284,04fefc,040204,fc9acc,fc9a04,fc0204+,048204+,fcfe04+,0402fc+,fcfefc+,848284+,840204+,840284+,04fefc+,040204+,fc9acc+,fc9a04+'),
  (23, 'ГОСТ Р 53246-2008',
   '0402fc,fc9a04,048204,840204,848284,fcfefc,fc0204,040204,fcfe04,840284,fc9acc,04fefc,0402fc+,fc9a04+,048204+,840204+,848284+,fcfefc+,fc0204+,040204+,fcfe04+,840284+,fc9acc+,04fefc+');


CREATE TABLE IF NOT EXISTS `cablecat_well_types`(
  `id` SMALLINT(6) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL DEFAULT '',
  `icon` VARCHAR(120) NOT NULL DEFAULT 'well_green',
  `comments` TEXT
);

REPLACE INTO `cablecat_well_types`(`id`, `name`) VALUES (1, '$lang{WELL}');

CREATE TABLE IF NOT EXISTS `cablecat_wells` (
  `id` INT(11) AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(32) NOT NULL,
  `parent_id` INT(11) UNSIGNED,
  `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE SET NULL,
  `type_id` SMALLINT(6) UNSIGNED DEFAULT 1
  REFERENCES `cablecat_well_types` (`id`) ON DELETE RESTRICT
)
  CHARSET = utf8
  COMMENT = 'Boxes for custom network equipment';

CREATE TABLE IF NOT EXISTS `cablecat_connecter_types` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(32) NOT NULL,
  `cartridges` SMALLINT(3) NOT NULL DEFAULT 1
)
  CHARSET = utf8
  COMMENT = 'Types of connecters (muffs)';

CREATE TABLE IF NOT EXISTS `cablecat_connecters` (
  `id` INT(11) AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `type_id` SMALLINT(6) UNSIGNED REFERENCES `cablecat_connecter_types` (`id`)
    ON DELETE RESTRICT,
  `well_id` INT(11) UNSIGNED REFERENCES `cablecat_wells` (`id`),
  `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE RESTRICT
)
  CHARSET = utf8
  COMMENT = 'Connecters where optic fibers are linked (muffs)';

CREATE TABLE IF NOT EXISTS `cablecat_splitter_types` (
  `id` SMALLINT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(32) NOT NULL,
  `fibers_in` SMALLINT(3) UNSIGNED,
  `fibers_out` SMALLINT(3) UNSIGNED
)
  CHARSET = utf8
  COMMENT = 'Types of splitters';

CREATE TABLE IF NOT EXISTS `cablecat_splitters` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `type_id` SMALLINT(6) UNSIGNED REFERENCES `cablecat_splitter_types` (`id`)
    ON DELETE RESTRICT,
  `well_id` INT(11) UNSIGNED REFERENCES `cablecat_wells` (`id`),
  `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE RESTRICT
)
  CHARSET = utf8
  COMMENT = 'Dividers of fiber signals (PON)';

CREATE TABLE IF NOT EXISTS `cablecat_connecters_links` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `connecter_1` INT(11) UNSIGNED REFERENCES `cablecat_connecters` (`id`)
    ON DELETE CASCADE,
  `connecter_2` INT(11) UNSIGNED REFERENCES `cablecat_connecters` (`id`)
    ON DELETE CASCADE,
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
  CHARSET = utf8
  COMMENT = 'Links among connecters';

CREATE TABLE IF NOT EXISTS `cablecat_links` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `length` INT(6) UNSIGNED NOT NULL DEFAULT 0,
  `name` VARCHAR(32) NOT NULL DEFAULT '',
  `cable_id` INT(11) UNSIGNED REFERENCES `cablecat_cables` (`id`)
    ON DELETE RESTRICT,
  `fiber_num` SMALLINT(3) UNSIGNED,
  `point_id` INT(11) UNSIGNED REFERENCES `maps_points` (`id`)
    ON DELETE RESTRICT,
  `linked_to` INT(11) UNSIGNED REFERENCES `cablecat_links` (`id`)
    ON DELETE CASCADE,
  `equipment_id` SMALLINT(6) UNSIGNED REFERENCES `equipment_infos` (`nas_id`),
  `equipment_port` SMALLINT(3) UNSIGNED,
  `uid` INT(11) UNSIGNED REFERENCES `users` (`uid`),
  `splitter_id` INT(11) UNSIGNED REFERENCES `cablecat_splitters` (`id`)
    ON DELETE RESTRICT,
  `splitter_port` SMALLINT(6) UNSIGNED,
  `splitter_direction` TINYINT(1) UNSIGNED,
  `direction` TINYINT(1) UNSIGNED
)
  CHARSET = utf8
  COMMENT = 'Stores information about fiber links (end_points)';
CREATE INDEX `_links_cable_key`
  ON `cablecat_links` (`cable_id`);
CREATE INDEX `_links_cable_fiber`
  ON `cablecat_links` (`cable_id`, `fiber_num`);


CREATE TABLE IF NOT EXISTS `cablecat_commutations` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `connecter_id` INT(11) UNSIGNED REFERENCES `cablecat_connecters` (`id`)
    ON DELETE RESTRICT,
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `cablecat_commutation_cables` (
  `commutation_id` INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`)
    ON DELETE CASCADE,
  `connecter_id` INT(11) UNSIGNED REFERENCES `cablecat_connecters` (`id`)
    ON DELETE CASCADE,
  `cable_id` INT(11) UNSIGNED REFERENCES `cablecat_cables` (`id`)
    ON DELETE CASCADE,
  INDEX `_connecter_ik` (`connecter_id`),
  INDEX `_commutation_ik` (`commutation_id`)
);

CREATE TABLE IF NOT EXISTS `cablecat_commutation_links` (
  `id` INT(11) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `commutation_id` INT(11) UNSIGNED REFERENCES `cablecat_commutations` (`id`)
    ON DELETE CASCADE,
  `cable_id_1` INT(11) UNSIGNED REFERENCES `cablecat_cables` (`id`)
    ON DELETE CASCADE,
  `fiber_num_1` SMALLINT(3) UNSIGNED,
  `cable_id_2` INT(11) UNSIGNED REFERENCES `cablecat_cables` (`id`)
    ON DELETE CASCADE,
  `fiber_num_2` SMALLINT(3) UNSIGNED,
  `attenuation` DOUBLE NOT NULL DEFAULT 0,
  `direction` TINYINT(2) NOT NULL DEFAULT 0,
  `comments` VARCHAR(40) NOT NULL DEFAULT '',
  KEY `_commutation_key` (`commutation_id`)
);

CREATE UNIQUE INDEX `_cablecat_cable_name`
  ON `cablecat_cables` (`name`);
CREATE UNIQUE INDEX `_cablecat_well_name`
  ON `cablecat_wells` (`name`);
CREATE UNIQUE INDEX `_cablecat_connecter_name`
  ON `cablecat_connecters` (`name`);
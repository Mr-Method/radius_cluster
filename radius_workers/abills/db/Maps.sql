DROP TABLE IF EXISTS `maps_routes`;
DROP TABLE IF EXISTS `maps_routes_coords`;
DROP TABLE IF EXISTS `maps_route_groups`;
DROP TABLE IF EXISTS `maps_route_types`;
DROP TABLE IF EXISTS `maps_wells`;
DROP TABLE IF EXISTS `maps_wifi_zones`;
DROP TABLE IF EXISTS `maps_point_types`;
DROP TABLE IF EXISTS `maps_points`;
DROP TABLE IF EXISTS `maps_coords`;
DROP TABLE IF EXISTS `maps_layers`;
DROP TABLE IF EXISTS `maps_circles`;
DROP TABLE IF EXISTS `maps_polylines`;
DROP TABLE IF EXISTS `maps_polyline_points`;
DROP TABLE IF EXISTS `maps_polygons`;
DROP TABLE IF EXISTS `maps_polygon_points`;
DROP TABLE IF EXISTS `maps_text`;
DROP TABLE IF EXISTS `maps_icons`;

CREATE TABLE IF NOT EXISTS `maps_routes` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) DEFAULT NULL,
  `type` SMALLINT(6) UNSIGNED DEFAULT '0',
  `descr` TEXT,
  `nas1` SMALLINT(5) UNSIGNED DEFAULT '0',
  `nas2` SMALLINT(5) UNSIGNED DEFAULT '0',
  `nas1_port` TINYINT(3) UNSIGNED DEFAULT '0',
  `nas2_port` TINYINT(3) UNSIGNED DEFAULT '0',
  `length` SMALLINT(5) UNSIGNED DEFAULT '0',
  `parent_id` INT(10) UNSIGNED NOT NULL DEFAULT 0 REFERENCES `maps_routes` (`id`)
    ON DELETE RESTRICT,
  `group_id` SMALLINT(6) NOT NULL DEFAULT 0 REFERENCES `maps_route_groups` (`id`)
    ON DELETE RESTRICT,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`)
)
  COMMENT = 'Routes information';

CREATE TABLE IF NOT EXISTS `maps_routes_coords` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `routes_id` INT(10) UNSIGNED DEFAULT '0',
  `coordx` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  `coordy` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Routes coords';


CREATE TABLE IF NOT EXISTS `maps_route_groups` (
  `id` SMALLINT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `comments` TEXT,
  `parent_id` SMALLINT(6) NOT NULL DEFAULT 0 REFERENCES `maps_route_groups` (`id`)
    ON DELETE RESTRICT
)
  COMMENT = 'Route groups';

CREATE TABLE IF NOT EXISTS `maps_route_types` (
  `id` SMALLINT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '#FFFFFF',
  `fibers_count` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1,
  `line_width` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1,
  `comments` TEXT,
  UNIQUE KEY (`name`)
)
  COMMENT = 'Route types';

REPLACE INTO `maps_route_types` (`id`, `name`, `color`) VALUES (1, '$lang{COAXIAL}', '#FF0000');
REPLACE INTO `maps_route_types` (`id`, `name`, `color`) VALUES (2, '$lang{FIBER_OPTIC}', '#000000');
REPLACE INTO `maps_route_types` (`id`, `name`, `color`) VALUES (3, '$lang{TWISTED_PAIR}', '#0000FF');

CREATE TABLE IF NOT EXISTS `maps_wells` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) DEFAULT NULL,
  `type_id` TINYINT(1) UNSIGNED DEFAULT '0',
  `coordx` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  `coordy` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  `comment` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Wells coord';

CREATE TABLE IF NOT EXISTS `maps_wifi_zones` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `radius` INT(10) UNSIGNED DEFAULT '0',
  `coordx` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  `coordy` DOUBLE(20, 14) DEFAULT '0.00000000000000',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Wifi zones';

CREATE TABLE IF NOT EXISTS `maps_point_types` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL UNIQUE,
  `icon` VARCHAR(30) NOT NULL    DEFAULT 'default',
  `comments` TEXT
)
  COMMENT = 'Types of custom points';

REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (1, '$lang{WELL}', 'well_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (2, '$lang{WIFI}', 'wifi_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (3, '$lang{BUILD}', 'build_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (4, '$lang{DISTRICT}', '');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (5, '$lang{MUFF}', 'muff_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (6, '$lang{SPLITTER}', 'splitter_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (7, '$lang{CABLE}', 'cable_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (8, '$lang{EQUIPMENT}', 'equipment_green');
REPLACE INTO `maps_point_types` (`id`, `name`, `icon`) VALUES (9, '$lang{PILLAR}', 'route_green');


CREATE TABLE IF NOT EXISTS `maps_coords` (
  `id` INT(11) PRIMARY KEY AUTO_INCREMENT,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL
)
  COMMENT = 'Coordinates for custom points';

CREATE TABLE IF NOT EXISTS `maps_points` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  `coord_id` INT(11) REFERENCES `maps_coords` (`id`)
    ON DELETE CASCADE,
  `type_id` SMALLINT(6) REFERENCES `maps_point_types` (`id`)
    ON DELETE RESTRICT,
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `parent_id` INT(11) REFERENCES `maps_points` (`id`)
    ON DELETE RESTRICT,
  `comments` TEXT,
  `location_id` INT(11) UNSIGNED REFERENCES `builds` (`id`)
    ON DELETE RESTRICT,
  `planned` TINYINT(1) NOT NULL DEFAULT 0,
  `installed` DATETIME,
  `external` TINYINT(1) NOT NULL DEFAULT 0
)
  COMMENT = 'Custom points';


CREATE TABLE IF NOT EXISTS `maps_layers` (
  `id` SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  `type` VARCHAR(32) NOT NULL DEFAULT 'build',
  `structure` VARCHAR(32) NOT NULL DEFAULT 'MARKER',
  `module` VARCHAR(32) NOT NULL DEFAULT 'Maps',
  `markers_in_cluster` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `comments` TEXT
)
  AUTO_INCREMENT = 100
  COMMENT = 'Map layers';

REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (1, '$lang{BUILD}', 'MARKER', 'build');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (2, '$lang{WIFI}', 'MARKER_CIRCLE', 'wifi');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (3, '$lang{ROUTE}', 'MARKERS_POLYLINE', 'route');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (4, '$lang{DISTRICT}', 'POLYGON', 'district');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (5, '$lang{TRAFFIC}', 'MARKER', 'build');
REPLACE INTO `maps_layers` (`id`, `name`, `structure`, `type`) VALUES (6, '$lang{OBJECTS}', 'MARKER', 'custom');
# ID 7 is reserved for Equipment
# ID 8 is reserved for GPS
# ID 9 is reserved for GPS_ROUTE
# ID 10 is reserved for cablecat CABLES
# ID 11 is reserved for cablecat WELLS

CREATE TABLE IF NOT EXISTS `maps_circles` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `layer_id` SMALLINT(6) REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  `radius` DOUBLE NOT NULL  DEFAULT 1.0,
  `name` VARCHAR(32) NOT NULL,
  `comments` TEXT
)
  COMMENT = 'Custom drawed circles';

CREATE TABLE IF NOT EXISTS `maps_polylines` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `layer_id` SMALLINT(6) REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `name` VARCHAR(32) NOT NULL  DEFAULT '',
  `comments` TEXT,
  `length` DOUBLE NOT NULL DEFAULT 0
)
  COMMENT = 'Custom drawed polylines';

CREATE TABLE IF NOT EXISTS `maps_polyline_points` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `polyline_id` INT(11) UNSIGNED REFERENCES `maps_polylines` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  KEY `polyline_id` (`polyline_id`)
)
  COMMENT = 'Custom drawed polyline points';

CREATE TABLE IF NOT EXISTS `maps_polygons` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `layer_id` SMALLINT(6) REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `name` VARCHAR(32) NOT NULL,
  `color` VARCHAR(32) NOT NULL  DEFAULT 'silver',
  `comments` TEXT
)
  COMMENT = 'Custom drawed polygons';

CREATE TABLE IF NOT EXISTS `maps_polygon_points` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `polygon_id` SMALLINT(6) REFERENCES `maps_polygons` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL
)
  COMMENT = 'Custom drawed polygons points';

CREATE TABLE IF NOT EXISTS `maps_text` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `layer_id` SMALLINT(6) REFERENCES `maps_layers` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE,
  `coordx` DOUBLE NOT NULL,
  `coordy` DOUBLE NOT NULL,
  `text` TEXT
)
  COMMENT = 'Custom drawed text';

CREATE TABLE IF NOT EXISTS `maps_icons` (
  `id` INT(11) UNSIGNED PRIMARY KEY  AUTO_INCREMENT,
  `name` VARCHAR(32) NOT NULL,
  `filename` VARCHAR(255) NOT NULL,
  `comments` TEXT
)
  COMMENT = 'User-defined icons';

CREATE TABLE IF NOT EXISTS `maps_districts` (
  `district_id` SMALLINT(6) UNSIGNED REFERENCES `districts` (`id`)
    ON DELETE CASCADE,
  `object_id` INT(11) REFERENCES `maps_points` (`id`)
    ON DELETE CASCADE
)
  COMMENT = 'District polygons';
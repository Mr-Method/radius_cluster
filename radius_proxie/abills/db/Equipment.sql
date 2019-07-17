CREATE TABLE IF NOT EXISTS `equipment_vendors` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `support` VARCHAR(50) NOT NULL DEFAULT '',
  `site` VARCHAR(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Netlist equipment vendor';

REPLACE INTO `equipment_vendors` (`id`, `name`, `support`, `site`) VALUES
  (1, 'Cisco', '', 'http://cisco.com'),
  (2, 'D-link', '', 'http://www.dlink.ru/'),
  (3, 'Zyxel', '', 'http://zyxel.ru'),
  (4, 'Juniper', '', 'http://juniper.com'),
  (5, 'Edge-Core', '', 'http://www.edge-core.ru'),
  (6, 'Mikrotik', '', 'http://www.mikrotik.com'),
  (7, 'Ericsson', '', 'http://www.ericsson.com/ua'),
  (8, '3com', '', 'http://3com.com'),
  (9, 'TP-Link', '', 'http://www.tplink.com'),
  (10, 'Dell', '', 'http://www.dell.com'),
  (11, 'BDCOM', '', 'http://www.bdcom.com'),
  (12, 'ZTE', '', 'http://zte.ru/'),
  (13, 'ELTEX', '', 'http://www.eltex.ru/'),
  (14, 'GWdelight', '', 'http://www.gwdelight.com'),
  (15, 'Ruckus', '', 'http://www.ruckuswireless.com/'),
  (16, 'Ubiquiti', '', 'https://www.ubnt.com/'),
  (17, 'Nortel', '', 'http://www.nortel.com/'),
  (18, 'H3C', '', 'http://www.h3c.com'),
  (19, 'Foundry Networks', '', 'http://www.brocade.com/en.html'),
  (20, 'Alcatel', '', 'https://www.alcatel-lucent.com/'),
  (21, 'Hewlett-Packard', '', 'http://www8.hp.com/ru/ru/home.html');


CREATE TABLE IF NOT EXISTS `equipment_types` (
  `id` TINYINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Netlist equipment type';

INSERT INTO `equipment_types` VALUES (1, 'Switch'),
  (2, 'WiFi'),
  (3, 'Router'),
  (4, 'PON'),
  (5, 'Server'),
  (6, 'DOCSIS'),
  (7, 'Set-top box');

CREATE TABLE IF NOT EXISTS `equipment_models` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_id` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `vendor_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `sys_oid` VARCHAR(50) NOT NULL DEFAULT '',
  `model_name` VARCHAR(50) NOT NULL DEFAULT '',
  `site` VARCHAR(150) NOT NULL DEFAULT '',
  `ports` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `manage_web` VARCHAR(50) NOT NULL DEFAULT '',
  `manage_ssh` VARCHAR(50) NOT NULL DEFAULT '',
  `snmp_tpl` VARCHAR(50) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `rows_count` INT(11) UNSIGNED NOT NULL DEFAULT '1',
  `block_size` INT(11) UNSIGNED DEFAULT '0',
  `port_numbering` TINYINT(1) UNSIGNED DEFAULT '0'
  COMMENT 'FALSE is ROWS, TRUE is COLUMNS',
  `first_position` TINYINT(1) UNSIGNED DEFAULT '0'
  COMMENT 'FALSE is UP, TRUE is DOWN',
  `extra_port1` SMALLINT(6) UNSIGNED DEFAULT '0',
  `extra_port2` SMALLINT(6) UNSIGNED DEFAULT '0',
  `extra_port3` SMALLINT(6) UNSIGNED DEFAULT '0',
  `extra_port4` SMALLINT(6) UNSIGNED DEFAULT '0',
  `ports_type` SMALLINT(5) UNSIGNED DEFAULT '1',
  PRIMARY KEY (`id`)
)
  ENGINE = InnoDB
  AUTO_INCREMENT = 164
  DEFAULT CHARSET = utf8
  COMMENT = 'Equipment models';


CREATE TABLE IF NOT EXISTS `equipment_infos` (
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `model_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `system_id` VARCHAR(30) NOT NULL DEFAULT '',
  `ports` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `firmware` VARCHAR(20) NOT NULL DEFAULT '',
  `firmware2` VARCHAR(20) NOT NULL DEFAULT '',
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `start_up_date` DATE,
  `comments` TEXT,
  `serial` VARCHAR(100) NOT NULL DEFAULT '',
  `revision` VARCHAR(10) NOT NULL DEFAULT '',
  `snmp_version` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  UNIQUE (`nas_id`)
)
  COMMENT = 'Equipment info';

CREATE TABLE IF NOT EXISTS `equipment_ports` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `port` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `uplink` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `comments` VARCHAR(250) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nas_port` (`nas_id`, `port`)
)
  COMMENT = 'Equipment ports';

CREATE TABLE IF NOT EXISTS `pon_onus` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `mac` VARCHAR(16) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `status` TINYINT(1) NOT NULL DEFAULT 0
)
  COMMENT = 'PON onu list';


CREATE TABLE IF NOT EXISTS `equipment_box_types` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `marking` VARCHAR(30) NOT NULL DEFAULT '',
  `vendor` VARCHAR(40) NOT NULL DEFAULT '',
  `units` SMALLINT(6) NOT NULL DEFAULT '0',
  `width` SMALLINT(6) NOT NULL DEFAULT '0',
  `hieght` SMALLINT(6) NOT NULL DEFAULT '0',
  `length` SMALLINT(6) NOT NULL DEFAULT '0',
  `diameter` SMALLINT(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Equipment box types';

CREATE TABLE IF NOT EXISTS `equipment_boxes` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `serial` VARCHAR(30) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Equipment boxes';

CREATE TABLE IF NOT EXISTS `equipment_vlans` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `number` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` TEXT NULL,
  UNIQUE (`id`)
)
  COMMENT = 'Equipment vlans';

CREATE TABLE IF NOT EXISTS `equipment_extra_ports` (
  `model_id` SMALLINT UNSIGNED NOT NULL,
  `port_number` SMALLINT UNSIGNED NOT NULL,
  `port_type` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  `state` TINYINT UNSIGNED NOT NULL DEFAULT '0',
  `row` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY `model_port` (`model_id`, `port_number`)
)
  COMMENT = 'Table for extra ports for equipment models';

CREATE TABLE IF NOT EXISTS `equipment_traps` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `traptime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `port` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `eventname` VARCHAR(50) NOT NULL DEFAULT '',
  `trapoid` VARCHAR(100) NOT NULL DEFAULT '',
  `severity` VARCHAR(20) NOT NULL DEFAULT '',
  `varbinds` TEXT,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Equipment traps';

CREATE TABLE IF NOT EXISTS `equipment_backup` (

  `id` INT(11) UNSIGNED PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `nas_id` SMALLINT(11) UNSIGNED REFERENCES `equipment_infos` (`nas_id`),
  `md5` VARCHAR(32) NOT NULL DEFAULT '',
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (`name`)
)
  COMMENT = 'Equipment backup description';

CREATE TABLE IF NOT EXISTS `equipment_graphs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `nas_id` SMALLINT(11) UNSIGNED REFERENCES `equipment_infos` (`nas_id`),
  `port` VARCHAR(10) NOT NULL DEFAULT '',
  `param` VARCHAR(32) NOT NULL DEFAULT '',
  `comments` VARCHAR(80) NOT NULL DEFAULT '',
  `min_value` VARCHAR(10) NOT NULL DEFAULT '',
  `max_value` VARCHAR(10) NOT NULL DEFAULT '',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `measure_type` VARCHAR(10) NOT NULL DEFAULT '',
  KEY (`nas_id`)
)
  COMMENT = 'Equipment graph stats';

CREATE TABLE IF NOT EXISTS `equipment_graph_log` (
  `id` INT UNSIGNED NOT NULL DEFAULT 0 PRIMARY KEY,
  `value` VARCHAR(10) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL DEFAULT '0000-00-00'
)
  COMMENT = 'Equipment graph stats log';

CREATE TABLE IF NOT EXISTS `equipment_mac_log` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `mac` VARCHAR(17) NOT NULL DEFAULT '',
  `ip` INT UNSIGNED NOT NULL DEFAULT 0,
  `port` VARCHAR(10) NOT NULL DEFAULT '',
  `vlan` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `datetime` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `rem_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  KEY `mac` (`mac`),
  KEY `nas_id` (`nas_id`),
  KEY `id` (`id`)
)
  COMMENT = 'Equipment MAC log';

CREATE TABLE IF NOT EXISTS `equipment_pon_onu` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `port_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `onu_snmp_id` VARCHAR(30) NOT NULL DEFAULT '',
  `onu_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `onu_mac_serial` VARCHAR(20) NOT NULL DEFAULT '',
  `onu_desc` VARCHAR(50) NOT NULL DEFAULT '',
  `olt_rx_power` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `onu_rx_power` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `onu_tx_power` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `onu_status` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `onu_in_byte` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `onu_out_byte` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `onu_dhcp_port` VARCHAR(20) NOT NULL DEFAULT '',
  `onu_graph` VARCHAR(50) NOT NULL DEFAULT 'SIGNAL,TEMPERATURE,SPEED',
  `datetime` DATETIME NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8
  COMMENT = 'Equipment ONU';

CREATE TABLE IF NOT EXISTS `equipment_pon_ports` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `snmp_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `pon_type` VARCHAR(10) NOT NULL DEFAULT '',
  `branch` VARCHAR(20) NOT NULL DEFAULT '',
  `branch_desc` VARCHAR(30) NOT NULL DEFAULT '',
  `vlan_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Equipment PON ports';


CREATE TABLE IF NOT EXISTS `equipment_snmp_tpl` (
  `model_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `section` VARCHAR(50) NOT NULL DEFAULT '',
  `parameters` VARCHAR(500) NOT NULL DEFAULT '',
  PRIMARY KEY (`model_id`, `section`)
)
  COMMENT = 'Equipment snmp template';

CREATE TABLE IF NOT EXISTS `equipment_info` (
  `info_time` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `section` VARCHAR(50) NOT NULL DEFAULT '',
  `result` VARCHAR(500) DEFAULT NULL,
  UNIQUE KEY `nas_sect` (`nas_id`, `section`)
)
  COMMENT = 'Equipment info';

CREATE TABLE `equipment_trap_types` (
  `id` smallint(2) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '',
  `type` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `event` tinyint(1) NOT NULL DEFAULT '0',
  `color` varchar(7) NOT NULL DEFAULT '',
  `varbind` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) 
  COMMENT='Equipment trap types';

#ALTER TABLE  `equipment_graphs` CHANGE  `mesure_type`  `measure_type` VARCHAR( 10 ) NOT NULL DEFAULT  '';
#ALTER TABLE  `equipment_pon_onu` CHANGE  `onu_in_byte`  `onu_in_byte` BIGINT( 14 ) UNSIGNED NOT NULL DEFAULT  '0';
#ALTER TABLE  `equipment_pon_onu` CHANGE  `onu_out_byte`  `onu_out_byte` BIGINT( 14 ) UNSIGNED NOT NULL DEFAULT  '0';
#ALTER TABLE  `equipment_pon_onu` CHANGE  `onu_snmp_id`  `onu_snmp_id` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT  '';

CREATE TABLE `rkn_main` (
  `id` int(10) unsigned NOT NULL,
  `blocktype` varchar(20) NOT NULL DEFAULT '',
  `hash` char(32) NOT NULL DEFAULT '',
  `inctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) COMMENT='Rkn blocklist main table';

CREATE TABLE `rkn_domain` (
  `id` int(10) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`)
) COMMENT='Rkn domain table';

CREATE TABLE `rkn_domain_mask` (
  `id` int(10) unsigned NOT NULL,
  `mask` varchar(255) NOT NULL,
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`)
) COMMENT='Rkn domain mask table';

CREATE TABLE `rkn_ip` (
  `id` int(10) unsigned NOT NULL,
  `ip` int(11) unsigned NOT NULL DEFAULT '0',
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`)
) COMMENT='Rkn ip table';

CREATE TABLE `rkn_url` (
  `id` int(10) unsigned NOT NULL,
  `url` varchar(255) NOT NULL,
  `skip` tinyint(1) NOT NULL DEFAULT '0',
  KEY `id` (`id`)
) COMMENT='Rkn url table';

CREATE TABLE IF NOT EXISTS `admin_actions` (
  `actions` VARCHAR(100) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `module` VARCHAR(10) NOT NULL DEFAULT '',
  `action_type` TINYINT(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
)
  COMMENT = 'Users changes log';

CREATE TABLE IF NOT EXISTS `admin_settings` (
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `object` VARCHAR(20) NOT NULL DEFAULT '',
  `setting` TEXT NOT NULL,
  PRIMARY KEY (`aid`, `object`)
)
  COMMENT = 'Admins settings';

CREATE TABLE IF NOT EXISTS `admin_slides` (
  `slide_name` VARCHAR(30) NOT NULL DEFAULT '',
  `field_id` VARCHAR(30) NOT NULL DEFAULT '',
  `field_warning` VARCHAR(130) NOT NULL DEFAULT '',
  `field_comments` VARCHAR(200) NOT NULL DEFAULT '',
  `priority` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `size` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `aid` (`aid`, `slide_name`, `field_id`)
)
  COMMENT = 'Admin slides';

CREATE TABLE IF NOT EXISTS `admin_system_actions` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `actions` VARCHAR(200) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL,
  `ip` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `module` VARCHAR(10) NOT NULL DEFAULT '',
  `action_type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'System Changes';


CREATE TABLE IF NOT EXISTS `admins_time_sheet` (
  `aid` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL,
  `work_time` TINYINT(2) NOT NULL DEFAULT '0',
  `overtime` TINYINT(2) NOT NULL DEFAULT '0',
  `extra_fee` TINYINT(2) NOT NULL DEFAULT '0',
  `day_type` TINYINT(2) NOT NULL DEFAULT '0',
  UNIQUE KEY `aid_date` (`aid`, `date`)
)
  COMMENT = 'Admins time sheet';


CREATE TABLE IF NOT EXISTS `admin_permits` (
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `section` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `actions` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `module` VARCHAR(12) NOT NULL DEFAULT '',
  UNIQUE KEY `aid_modules` (`aid`, `module`, `section`, `actions`),
  KEY `aid` (`aid`)
)
  COMMENT = 'Admin permissions';


CREATE TABLE IF NOT EXISTS `admins` (
  `id` VARCHAR(12) NOT NULL DEFAULT '',
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `position` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `regdate` DATE NOT NULL,
  `password` BLOB NOT NULL,
  `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `web_options` TEXT NOT NULL,
  `email` VARCHAR(35) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `min_search_chars` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `max_rows` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `address` VARCHAR(60) NOT NULL DEFAULT '',
  `cell_phone` VARCHAR(20) NOT NULL DEFAULT '',
  `pasport_num` VARCHAR(16) NOT NULL DEFAULT '',
  `pasport_date` DATE NOT NULL,
  `pasport_grant` VARCHAR(100) NOT NULL DEFAULT '',
  `inn` VARCHAR(20) NOT NULL DEFAULT '',
  `birthday` DATE NOT NULL,
  `max_credit` DOUBLE(12, 4) NOT NULL DEFAULT '0.00',
  `credit_days` SMALLINT NOT NULL DEFAULT 0,
  `full_log` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `sip_number` VARCHAR(15) NOT NULL DEFAULT '',
  `api_key` VARCHAR(100) NOT NULL DEFAULT '',
  `gps_imei` VARCHAR(15) NOT NULL DEFAULT '',
  `start_work` DATE NOT NULL,
  `telegram_id` VARCHAR(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`aid`),
  UNIQUE KEY `aid` (`aid`),
  UNIQUE KEY `id` (`id`)
);

CREATE TABLE IF NOT EXISTS `admins_access` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `begin` TIME NOT NULL DEFAULT '00:00:00',
  `end` TIME NOT NULL DEFAULT '00:00:00',
  `day` TINYINT(4) UNSIGNED DEFAULT '0',
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `bit_mask` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `comments` TEXT NOT NULL,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY `id` (`id`)
)
  COMMENT = 'Admin access';

CREATE TABLE IF NOT EXISTS `admins_full_log` (
  `function_index` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `function_name` VARCHAR(32) NOT NULL DEFAULT '',
  `datetime` DATETIME NOT NULL,
  `ip` INT UNSIGNED NOT NULL DEFAULT 0,
  `sid` VARCHAR(32) NOT NULL DEFAULT '',
  `params` TEXT,
  KEY `aid` (`aid`)
)
  COMMENT = 'Admin full log';


CREATE TABLE IF NOT EXISTS `admins_groups` (
  `gid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  KEY `gid` (`gid`, `aid`)
)
  COMMENT = 'Admin group';

CREATE TABLE IF NOT EXISTS `billd_plugins` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `plugin_name` VARCHAR(100) NOT NULL DEFAULT '',
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `threads` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `make_lock` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `period` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `last_execute` DATETIME NOT NULL,
  `last_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `plugin_name` (`plugin_name`)
)
  COMMENT = 'billd plugin orginizer';

CREATE TABLE IF NOT EXISTS `bills` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `deposit` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `company_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `registration` DATE NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`, `company_id`)
)
  COMMENT = 'Users deposits';

CREATE TABLE IF NOT EXISTS `domains` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `created` DATE NOT NULL,
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Domains List';


CREATE TABLE IF NOT EXISTS `dv_calls` (
  `status` INT(3) NOT NULL DEFAULT '0',
  `user_name` VARCHAR(32) NOT NULL DEFAULT '',
  `started` DATETIME NOT NULL,
  `nas_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `nas_port_id` INT(6) UNSIGNED NOT NULL DEFAULT '0',
  `acct_session_id` VARCHAR(32) NOT NULL DEFAULT '',
  `acct_session_time` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `acct_input_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `acct_output_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `ex_input_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `ex_output_octets` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `connect_term_reason` INT(4) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ip_address` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ipv6_prefix` VARBINARY(16) NOT NULL DEFAULT '',
  `framed_interface_id` VARBINARY(16) NOT NULL DEFAULT '',
  `lupdated` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000',
  `CID` VARCHAR(20) NOT NULL DEFAULT '',
  `CONNECT_INFO` VARCHAR(35) NOT NULL DEFAULT '',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `acct_input_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `acct_output_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_input_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_output_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `join_service` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `turbo_mode` VARCHAR(30) NOT NULL DEFAULT '',
  `guest` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  KEY `user_name` (`user_name`),
  KEY `acct_session_id` (`acct_session_id`),
  KEY `framed_ip_address` (`framed_ip_address`),
  KEY `uid` (`uid`)
);


CREATE TABLE IF NOT EXISTS `dv_log_intervals` (
  `interval_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `sent` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `recv` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `duration` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `traffic_type` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) UNSIGNED NOT NULL DEFAULT '0.000000',
  `acct_session_id` VARCHAR(32) NOT NULL DEFAULT '',
  `added` TIMESTAMP NOT NULL,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  KEY `acct_session_id` (`acct_session_id`),
  KEY `session_interval` (`acct_session_id`, `interval_id`),
  KEY `uid` (`uid`)
)
  COMMENT = 'DV interval summary stats';


CREATE TABLE IF NOT EXISTS `errors_log` (
  `date` DATETIME NOT NULL,
  `log_type` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `action` VARCHAR(10) NOT NULL,
  `user` VARCHAR(20) NOT NULL,
  `message` VARCHAR(120) NOT NULL,
  `nas_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  KEY `i_user_date` (`user`, `date`),
  KEY `log_type` (`log_type`)
)
  COMMENT = 'Error log';

CREATE TABLE IF NOT EXISTS `companies` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tax_number` VARCHAR(250) NOT NULL DEFAULT '',
  `bank_account` VARCHAR(250) DEFAULT NULL,
  `bank_name` VARCHAR(150) DEFAULT NULL,
  `cor_bank_account` VARCHAR(150) DEFAULT NULL,
  `bank_bic` VARCHAR(100) DEFAULT NULL,
  `registration` DATE NOT NULL DEFAULT '0000-00-00',
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `credit` DOUBLE(8, 2) NOT NULL DEFAULT '0.00',
  `credit_date` DATE NOT NULL DEFAULT '0000-00-00',
  `address` VARCHAR(100) NOT NULL DEFAULT '',
  `phone` VARCHAR(20) NOT NULL DEFAULT '',
  `vat` DOUBLE(5, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `contract_id` VARCHAR(10) NOT NULL DEFAULT '',
  `contract_date` DATE NOT NULL DEFAULT '0000-00-00',
  `ext_bill_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `representative` VARCHAR(120) NOT NULL DEFAULT '',
  `contract_sufix` VARCHAR(5) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `bill_id` (`bill_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`domain_id`, `name`)
)
  COMMENT = 'Companies';


CREATE TABLE IF NOT EXISTS `companie_admins` (
  `company_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`company_id`, `uid`)
)
  COMMENT = 'Companie Super Users';

CREATE TABLE IF NOT EXISTS `config` (
  `param` VARCHAR(30) NOT NULL DEFAULT '',
  `value` VARCHAR(200) NOT NULL DEFAULT '',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `param` (`domain_id`, `param`)
)
  COMMENT = 'System config';


CREATE TABLE IF NOT EXISTS `config_variables` (
  `param` VARCHAR(30) NOT NULL DEFAULT '',
  `type` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `value` VARCHAR(250) NOT NULL DEFAULT '',
  `comments` TEXT,
  UNIQUE KEY `param` (`param`)
)
  COMMENT = 'System config variables list';


CREATE TABLE IF NOT EXISTS `docs_invoices` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `customer` VARCHAR(200) NOT NULL DEFAULT '',
  `phone` VARCHAR(16) NOT NULL DEFAULT '0',
  `user` VARCHAR(20) NOT NULL DEFAULT '',
  `invoice_num` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `vat` DOUBLE(5, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `payment_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `deposit` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `delivery_status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `exchange_rate` DOUBLE(12, 4) NOT NULL DEFAULT '0.0000',
  `currency` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `payment_id` (`payment_id`),
  KEY `domain_id` (`domain_id`)
)
  COMMENT = 'Docs Invoices';

CREATE TABLE IF NOT EXISTS `docs_invoice_orders` (
  `invoice_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `orders` VARCHAR(200) NOT NULL DEFAULT '',
  `counts` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `unit` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `fees_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  KEY `invoice_id` (`invoice_id`),
  KEY `fees_id` (`fees_id`),
  FOREIGN KEY (`invoice_id`) REFERENCES `docs_invoices` (`id`)
)
  COMMENT = 'Docs Invoice Orders';


CREATE TABLE IF NOT EXISTS `docs_acts` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `act_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `vat` DOUBLE(5, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `company_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `date` (`date`, `company_id`),
  KEY `domain_id` (`domain_id`)
)
  COMMENT = 'Docs Acts';

CREATE TABLE IF NOT EXISTS `docs_act_orders` (
  `act_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `orders` VARCHAR(200) NOT NULL DEFAULT '',
  `counts` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `unit` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `price` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `fees_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  KEY `act_id` (`act_id`),
  FOREIGN KEY (`act_id`) REFERENCES `docs_acts` (`id`)
)
  COMMENT = 'Docs act orders';


CREATE TABLE IF NOT EXISTS `docs_main` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0' PRIMARY KEY,
  `send_docs` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `personal_delivery` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `invoicing_period` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `periodic_create_docs` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `email` VARCHAR(200) NOT NULL DEFAULT '',
  `invoice_date` DATE NOT NULL DEFAULT '0000-00-00',
  `comments` TEXT NOT NULL
)
  COMMENT = 'Docs users settings';


CREATE TABLE IF NOT EXISTS `docs_tax_invoices` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `tax_invoice_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `vat` DOUBLE(5, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `company_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `account_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `date` (`date`, `company_id`),
  KEY `domain_id` (`domain_id`)
)
  COMMENT = 'Docs Tax Invoices';

CREATE TABLE IF NOT EXISTS `docs_tax_invoice_orders` (
  `tax_invoice_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `orders` VARCHAR(200) NOT NULL DEFAULT '',
  `counts` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `unit` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  KEY `aid` (`tax_invoice_id`)
)
  COMMENT = 'Docs Tax Invoices Orders';

CREATE TABLE IF NOT EXISTS `dv_main` (
  `uid` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `logins` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `registration` DATE DEFAULT '0000-00-00',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(150) NOT NULL DEFAULT '',
  `speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `netmask` INT(10) UNSIGNED NOT NULL DEFAULT '4294967295',
  `cid` VARCHAR(35) NOT NULL DEFAULT '',
  `password` BLOB NOT NULL,
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `callback` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `port` VARCHAR(40) NOT NULL DEFAULT '',
  `join_service` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `turbo_mode` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `free_turbo_mode` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `dv_login` VARCHAR(24) NOT NULL DEFAULT '',
  `detail_stats` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `personal_tp` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `traf_detail` smallint(1) unsigned NOT NULL default '0',
  PRIMARY KEY (`uid`),
  KEY `tp_id` (`tp_id`),
  KEY `CID` (`cid`)
)
  COMMENT = 'Dv accounts';

CREATE TABLE IF NOT EXISTS `exchange_rate` (
  `money` VARCHAR(30) NOT NULL DEFAULT '',
  `short_name` VARCHAR(30) NOT NULL DEFAULT '',
  `iso` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `rate` DOUBLE(12, 4) NOT NULL DEFAULT '0.0000',
  `changed` DATE NOT NULL DEFAULT '0000-00-00',
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  UNIQUE KEY `money` (`money`),
  UNIQUE KEY `short_name` (`short_name`),
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Exchange rate';


CREATE TABLE IF NOT EXISTS `exchange_rate_log` (
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `exchange_rate_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `rate` DOUBLE(12, 4) NOT NULL DEFAULT '0.0000',
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  KEY `date` (`date`)
)
  COMMENT = 'Exchange rate log';


CREATE TABLE IF NOT EXISTS `fees` (
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `sum` DOUBLE(12, 4) NOT NULL DEFAULT '0.00',
  `dsc` VARCHAR(80) NOT NULL DEFAULT '',
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `last_deposit` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `vat` DOUBLE(5, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `inner_describe` VARCHAR(80) NOT NULL DEFAULT '',
  `method` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `reg_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
);

CREATE TABLE IF NOT EXISTS `filters` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `filter` VARCHAR(100) NOT NULL DEFAULT '',
  `descr` VARCHAR(200) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `filter` (`filter`)
);

CREATE TABLE IF NOT EXISTS `groups` (
  `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `descr` VARCHAR(200) NOT NULL DEFAULT '',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `separate_docs` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `allow_credit` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `disable_paysys` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `disable_chg_tp` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `bonus` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`gid`),
  UNIQUE KEY `name` (`domain_id`, `name`)
)
  COMMENT = 'Users group';


CREATE TABLE IF NOT EXISTS `holidays` (
  `day` VARCHAR(5) NOT NULL DEFAULT '',
  `file` CHAR(50) NOT NULL DEFAULT '',
  `descr` VARCHAR(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`day`)
);

CREATE TABLE IF NOT EXISTS `intervals` (
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `begin` TIME NOT NULL DEFAULT '00:00:00',
  `end` TIME NOT NULL DEFAULT '00:00:00',
  `tarif` VARCHAR(7) NOT NULL DEFAULT '0',
  `day` TINYINT(4) UNSIGNED DEFAULT '0',
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `tp_intervals` (`tp_id`, `begin`, `day`)
);

CREATE TABLE IF NOT EXISTS `ippools` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nas` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `counts` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(25) NOT NULL,
  `priority` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `static` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `ipv6_prefix` VARBINARY(16) NOT NULL DEFAULT '',
  `next_pool_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `netmask` INT(11) UNSIGNED NOT NULL DEFAULT '4294967295',
  `dns` VARCHAR(32) NOT NULL DEFAULT '',
  `ntp` VARCHAR(80) NOT NULL DEFAULT '',
  `gateway` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `guest` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` smallint(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nas` (`nas`, `ip`)
)
  COMMENT = 'IP Pools';

CREATE TABLE IF NOT EXISTS `dv_log` (
  `start` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `duration` INT(11) NOT NULL DEFAULT '0',
  `sent` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `recv` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000',
  `port_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `ip` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `sent2` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `recv2` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `acct_session_id` VARCHAR(32) NOT NULL DEFAULT '',
  `CID` VARCHAR(18) NOT NULL DEFAULT '',
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `terminate_cause` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `framed_ipv6_prefix` VARBINARY(16) NOT NULL DEFAULT '',
  `acct_input_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `acct_output_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_input_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ex_output_octets_gigawords` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  KEY `uid` (`uid`, `start`)
)
  COMMENT = 'Internet sessions logs';



CREATE TABLE IF NOT EXISTS `msgs_admins` (
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `chapter_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `email_notify` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `deligation_level` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `aid` (`aid`, `chapter_id`)
)
  COMMENT = 'Msgs admins';

CREATE TABLE IF NOT EXISTS `msgs_attachments` (
  `id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `message_id` BIGINT(20) NOT NULL DEFAULT '0',
  `filename` VARCHAR(250) NOT NULL  DEFAULT '',
  `content_size` VARCHAR(30) NOT NULL DEFAULT '',
  `content_type` VARCHAR(250) NOT NULL DEFAULT '',
  `content` LONGBLOB NOT NULL,
  `create_time` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `create_by` INT(11) NOT NULL DEFAULT '0',
  `change_time` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `change_by` INT(11) NOT NULL DEFAULT '0',
  `message_type` TINYINT(2) NOT NULL DEFAULT '0',
  `coordx` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `coordy` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `article_attachment_article_id` (`message_id`)
)
  COMMENT = 'Messages Attachment table';


CREATE TABLE IF NOT EXISTS `msgs_chapters` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL DEFAULT '',
  `inner_chapter` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Msgs chapters';

CREATE TABLE IF NOT EXISTS `msgs_dispatch` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `created` DATETIME NOT NULL,
  `plan_date` DATE NOT NULL DEFAULT '0000-00-00',
  `comments` TEXT NOT NULL,
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `closed_date` DATE NOT NULL DEFAULT '0000-00-00',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `resposible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `plan_date` (`plan_date`, `state`)
)
  COMMENT = 'Msgs dispatches';

CREATE TABLE IF NOT EXISTS `msgs_dispatch_admins` (
  `dispatch_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0'
)
  COMMENT = 'Msgs Dispatch admins';

CREATE TABLE IF NOT EXISTS `msgs_proggress_bar` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `chapter_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `step_num` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `step_name` VARCHAR(100) NOT NULL DEFAULT '',
  `step_tip` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chapter_id_name` (`chapter_id`, `step_num`)
)
  COMMENT = 'Messages progress bar';

CREATE TABLE IF NOT EXISTS `msgs_message_pb` (
  `main_msg` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `step_num` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `step_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `coordx` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `coordy` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `aid` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  KEY (`main_msg`),
  UNIQUE KEY `msg_step` (`main_msg`, `step_num`)
)
  COMMENT = 'Messages message progress bar';

CREATE TABLE IF NOT EXISTS `msgs_messages` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `par` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `chapter` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `message` TEXT NOT NULL,
  `reply` TEXT NOT NULL,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `state` TINYINT(2) UNSIGNED DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `subject` VARCHAR(150) NOT NULL DEFAULT '',
  `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `lock_msg` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `closed_date` DATETIME NOT NULL DEFAULT '0000-00-00',
  `done_date` DATE NOT NULL DEFAULT '0000-00-00',
  `plan_date` DATE NOT NULL DEFAULT '0000-00-00',
  `plan_time` TIME NOT NULL DEFAULT '00:00:00',
  `user_read` DATETIME NOT NULL,
  `admin_read` DATETIME NOT NULL,
  `resposible` SMALLINT(6) UNSIGNED NULL DEFAULT '0',
  `inner_msg` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `dispatch_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `deligation` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `deligation_level` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `survey_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `rating` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `rating_comment` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `chapter` (`chapter`),
  KEY `state` (`state`),
  KEY `dispatch_id` (`dispatch_id`)
)
  COMMENT = 'Msgs Messages';

CREATE TABLE IF NOT EXISTS `msgs_watch` (
  `main_msg` INT(11) UNSIGNED NOT NULL DEFAULT 0  REFERENCES `msgs_messages` (`id`),
  `aid` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `add_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  KEY (`main_msg`),
  UNIQUE KEY `msg_aid` (`aid`, `main_msg`)
)
  COMMENT = 'Message watch';

CREATE TABLE IF NOT EXISTS `msgs_reply` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `main_msg` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `text` TEXT NOT NULL,
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `caption` VARCHAR(40) NOT NULL DEFAULT '',
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `inner_msg` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `survey_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `run_time` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `main_msg` (`main_msg`)
)
  COMMENT = 'Msgs replies';

CREATE TABLE IF NOT EXISTS `msgs_unreg_requests` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL,
  `received_admin` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `state` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `subject` VARCHAR(45) NOT NULL DEFAULT '',
  `chapter` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `request` TEXT NOT NULL,
  `comments` TEXT NOT NULL,
  `resposible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `fio` VARCHAR(40) NOT NULL DEFAULT '',
  `phone` BIGINT(16) UNSIGNED NOT NULL DEFAULT '0',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `company` VARCHAR(60) NOT NULL DEFAULT '',
  `country_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `address_street` VARCHAR(100) NOT NULL DEFAULT '',
  `address_build` VARCHAR(10) NOT NULL DEFAULT '',
  `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
  `location_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `ip` INTEGER(11) UNSIGNED NOT NULL,
  `closed_date` DATETIME NOT NULL DEFAULT '0000-00-00',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `login` VARCHAR(24) NOT NULL DEFAULT '',
  `connection_time` DATETIME NOT NULL DEFAULT '0000-00-00',
  `reaction_time` VARCHAR(100) NOT NULL DEFAULT '',
  `last_contact` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `planned_contact` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `contact_note` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `datetime` (`datetime`)
)
  COMMENT = 'Msgs from unregister users';

CREATE TABLE IF NOT EXISTS `msgs_survey_questions` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `survey_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `num` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `question` VARCHAR(200) NOT NULL,
  `params` VARCHAR(250) NOT NULL,
  `comments` TEXT NOT NULL,
  `user_comments` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `fill_default` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Messages Survey questions';

CREATE TABLE IF NOT EXISTS `msgs_survey_subjects` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `tpl` TEXT NOT NULL,
  `filename` VARCHAR(250) NOT NULL DEFAULT '',
  `file_size` VARCHAR(30) NOT NULL DEFAULT '',
  `file_content_type` VARCHAR(250) NOT NULL DEFAULT '',
  `file_contents` LONGBLOB NOT NULL,
  `msg_type` TINYINT(1) NOT NULL DEFAULT 0,
  `status` TINYINT(1) NOT NULL DEFAULT 0,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `created` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Messages Survey Subjects';


CREATE TABLE IF NOT EXISTS `msgs_survey_answers` (
  `question_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `answer` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `date_time` DATETIME NOT NULL,
  `survey_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `msg_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `reply_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`, `msg_id`, `reply_id`, `question_id`)
)
  COMMENT = 'Messages Survey Answers';

CREATE TABLE IF NOT EXISTS `msgs_status` (
  `id` SMALLINT(2) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(60) NOT NULL DEFAULT '',
  `readiness` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `task_closed` TINYINT(1) NOT NULL DEFAULT 0,
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  UNIQUE `name` (`name`),
  PRIMARY KEY (`id`)
)
  COMMENT = 'Messages statuses';

CREATE TABLE IF NOT EXISTS `msgs_delivery` (
  `id` SMALLINT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `send_date` DATE NOT NULL,
  `send_time` TIME NOT NULL,
  `added` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `text` TEXT NOT NULL,
  `subject` VARCHAR(250) NOT NULL DEFAULT '',
  `send_method` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  COMMENT = 'Msgs delivery list';

CREATE TABLE IF NOT EXISTS `msgs_delivery_users` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `mdelivery_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `sended_date` DATETIME NOT NULL,
  `send_method` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `mdelivery_id` (`mdelivery_id`, `uid`)
)
  COMMENT = 'Msgs delivery users';

SET SESSION sql_mode = 'NO_AUTO_VALUE_ON_ZERO';
REPLACE INTO `msgs_status` (`id`, `name`, `readiness`, `task_closed`, `color`) VALUE
  ('0', '$lang{OPEN}', '0', '0', '#0000FF'),
  ('1', '$lang{CLOSED_UNSUCCESSFUL}', '100', '1', '#ff0638'),
  ('2', '$lang{CLOSED_SUCCESSFUL}', '100', '1', '#009D00'),
  ('3', '$lang{IN_WORK}', '10', '0', '#707070'),
  ('4', '$lang{NEW_MESSAGE}', '0', '0', '#FF8000'),
  ('5', '$lang{HOLD_UP}', '0', '0', '0'),
  ('6', '$lang{ANSWER_WAIT}', '50', '0', ''),
  ('9', '$lang{NOTIFICATION_MSG}', '0', '0', ''),
  ('10', '$lang{NOTIFICATION_MSG}  $lang{READED}', '100', '0', ''),
  ('11', '$lang{POTENTIAL_CLIENT}', '0', '0', '');

CREATE TABLE IF NOT EXISTS `nas` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) DEFAULT NULL,
  `nas_identifier` VARCHAR(20) NOT NULL DEFAULT '',
  `descr` VARCHAR(250) DEFAULT NULL,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `nas_type` VARCHAR(20) DEFAULT NULL,
  `auth_type` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `mng_host_port` VARCHAR(28) NOT NULL DEFAULT '',
  `mng_user` VARCHAR(20) DEFAULT NULL,
  `mng_password` BLOB NOT NULL,
  `rad_pairs` TEXT NOT NULL,
  `alive` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `disable` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `ext_acct` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `address_street` VARCHAR(100) NOT NULL DEFAULT '',
  `address_build` VARCHAR(10) NOT NULL DEFAULT '',
  `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
  `zip` VARCHAR(7) NOT NULL DEFAULT '',
  `city` VARCHAR(20) NOT NULL DEFAULT '',
  `country` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `gid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `mac` VARCHAR(17) NOT NULL DEFAULT '',
  `changed` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `location_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `mac` (`mac`),
  UNIQUE KEY `domain_id` (`domain_id`, `ip`, `nas_identifier`)
)
  COMMENT = 'Nas servers list';

CREATE TABLE IF NOT EXISTS `nas_cmd` (
  `id` SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
  `nas_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `type` VARCHAR(10) NOT NULL DEFAULT 0,
  `comments` TEXT,
  `cmd` TEXT,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Nas console commands';

CREATE TABLE IF NOT EXISTS `nas_groups` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `disable` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `default` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `main_page` VARCHAR(120) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain_id` (`domain_id`, `name`)
)
  COMMENT = 'NAS servers groups';

CREATE TABLE IF NOT EXISTS `nas_ippools` (
  `pool_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `nas_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `nas` (`nas_id`, `pool_id`)
)
  COMMENT = 'NAS IP Pools';


CREATE TABLE IF NOT EXISTS `netflow_address` (
  `client_ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`client_ip`),
  UNIQUE KEY `client_ip` (`client_ip`)
);


CREATE TABLE IF NOT EXISTS `networks` (
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `netmask` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `domainname` VARCHAR(50) NOT NULL DEFAULT '',
  `hostname` VARCHAR(20) NOT NULL DEFAULT '',
  `descr` TEXT NOT NULL,
  `changed` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `type` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `mac` VARCHAR(17) NOT NULL DEFAULT '',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `web_control` VARCHAR(21) NOT NULL DEFAULT '',
  PRIMARY KEY (`ip`, `netmask`),
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Networks list';


CREATE TABLE IF NOT EXISTS `payments` (
  `date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `dsc` VARCHAR(80) DEFAULT NULL,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `last_deposit` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `method` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `ext_id` VARCHAR(28) NOT NULL DEFAULT '',
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `inner_describe` VARCHAR(80) NOT NULL DEFAULT '',
  `amount` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `currency` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `reg_date` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
)
  COMMENT = 'Payments log';

CREATE TABLE IF NOT EXISTS `payments_type` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  UNIQUE KEY `id` (`id`)
)
  COMMENT = 'Add new payment type';

SET SESSION sql_mode = 'NO_AUTO_VALUE_ON_ZERO';
REPLACE INTO `payments_type` (`id`, `name`, `color`) VALUES
  (0, '$lang{CASH}', ''),
  (1, '$lang{BANK}', ''),
  (2, '$lang{EXTERNAL_PAYMENTS}', ''),
  (3, 'Credit Card', ''),
  (4, '$lang{BONUS}', ''),
  (5, '$lang{CORRECTION}', ''),
  (6, '$lang{COMPENSATION}', ''),
  (7, '$lang{MONEY_TRANSFER}', ''),
  (8, '$lang{RECALCULATE}', '');

CREATE TABLE IF NOT EXISTS `docs_receipts` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `customer` VARCHAR(200) NOT NULL DEFAULT '',
  `phone` VARCHAR(16) NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `created` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `receipt_num` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `vat` DOUBLE(5, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `by_proxy_seria` VARCHAR(40) NOT NULL DEFAULT '',
  `by_proxy_person` VARCHAR(15) NOT NULL DEFAULT '',
  `by_proxy_date` DATE NOT NULL DEFAULT '0000-00-00',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `payment_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `deposit` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `delivery_status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `exchange_rate` DOUBLE(12, 4) NOT NULL DEFAULT '0.0000',
  `currency` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `payment_id` (`payment_id`),
  KEY `domain_id` (`domain_id`),
  FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`)
)
  COMMENT = 'Docs Receipts';

CREATE TABLE IF NOT EXISTS `docs_receipt_orders` (
  `receipt_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `orders` VARCHAR(200) NOT NULL DEFAULT '',
  `counts` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `unit` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `price` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `fees_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  KEY `receipt_id` (`receipt_id`),
  KEY `fees_id` (`fees_id`),
  FOREIGN KEY (`receipt_id`) REFERENCES `docs_receipts` (`id`)
)
  COMMENT = 'Docs receipt orders';

CREATE TABLE IF NOT EXISTS `docs_invoice2payments` (
  `invoice_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `payment_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY `invoice2payments` (`invoice_id`, `payment_id`),
  FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`),
  FOREIGN KEY (`invoice_id`) REFERENCES `docs_invoices` (`id`)
)
  COMMENT = 'Docs Invoice to payments';


CREATE TABLE IF NOT EXISTS `fees_types` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `default_describe` VARCHAR(80) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Payments types';


CREATE TABLE IF NOT EXISTS `s_detail` (
  `acct_session_id` VARCHAR(32) NOT NULL DEFAULT '',
  `nas_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `acct_status` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `start` DATETIME DEFAULT NULL,
  `last_update` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `sent1` BIGINT UNSIGNED NOT NULL DEFAULT '0',
  `recv1` BIGINT UNSIGNED NOT NULL DEFAULT '0',
  `sent2` BIGINT UNSIGNED NOT NULL DEFAULT '0',
  `recv2` BIGINT UNSIGNED NOT NULL DEFAULT '0',
  `id` VARCHAR(16) NOT NULL DEFAULT '',
  `uid` INT UNSIGNED NOT NULL DEFAULT 0,
  `sum` DOUBLE(14, 6) NOT NULL DEFAULT '0.000000',
  KEY `sid` (`acct_session_id`)
)
  COMMENT = 'Sessions details';


CREATE TABLE IF NOT EXISTS `shedule` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `type` VARCHAR(50) NOT NULL DEFAULT '',
  `action` TEXT NOT NULL,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `counts` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `d` CHAR(2) NOT NULL DEFAULT '*',
  `m` CHAR(2) NOT NULL DEFAULT '*',
  `y` VARCHAR(4) NOT NULL DEFAULT '*',
  `h` CHAR(2) NOT NULL DEFAULT '*',
  `module` VARCHAR(12) NOT NULL DEFAULT '',
  `comments` VARCHAR(120) NOT NULL DEFAULT '',
  `admin_action` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `uniq_action` (`h`, `d`, `m`, `y`, `type`, `uid`, `module`),
  KEY `date_type_uid` (`date`, `type`, `uid`)
)
  COMMENT = 'Shedules';

CREATE TABLE IF NOT EXISTS `tarif_plans` (
  `id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `month_fee` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `fixed_fees_day` TINYINT(1) NOT NULL DEFAULT '0',
  `uplimit` DOUBLE(14, 2) NOT NULL DEFAULT '0.00',
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `day_fee` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `active_day_fee` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `logins` TINYINT(4) NOT NULL DEFAULT '0',
  `day_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `week_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `month_time_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `day_traf_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `week_traf_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `month_traf_limit` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `prepaid_trafic` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `change_price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `activate_price` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `credit_tresshold` DOUBLE(8, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `age` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `octets_direction` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `max_session_duration` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `filter_id` VARCHAR(150) NOT NULL DEFAULT '',
  `payment_type` TINYINT(1) NOT NULL DEFAULT '0',
  `min_session_cost` DOUBLE(14, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `rad_pairs` TEXT NOT NULL,
  `reduction_fee` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `postpaid_daily_fee` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `postpaid_monthly_fee` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `module` VARCHAR(12) NOT NULL DEFAULT '',
  `traffic_transfer_period` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `gid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `neg_deposit_filter_id` VARCHAR(150) NOT NULL DEFAULT '',
  `tp_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `ext_bill_account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `credit` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `user_credit_limit` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `ippool` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `period_alignment` TINYINT(1) NOT NULL DEFAULT '0',
  `min_use` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `abon_distribution` TINYINT(1) NOT NULL DEFAULT '0',
  `small_deposit_action` SMALLINT(6) NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `total_time_limit` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `total_traf_limit` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `priority` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  `bills_priority` TINYINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `fine` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `neg_deposit_ippool` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `next_tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `fees_method` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `service_id` TINYINT(2) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`, `module`, `domain_id`),
  UNIQUE KEY `tp_id` (`tp_id`),
  KEY `name` (`name`, `domain_id`)
)
  COMMENT = 'Tarif plans';


CREATE TABLE IF NOT EXISTS `tp_bonus_rating` (
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `rating_from` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `rating_to` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `action` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `change_bonus` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `activate_bonus` DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `ext_bill_account` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`tp_id`)
)
  COMMENT = 'Tarif plans bonus rating';


CREATE TABLE IF NOT EXISTS `tp_groups` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL DEFAULT '',
  `user_chg_tp` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Tarif Plans Groups';


CREATE TABLE IF NOT EXISTS `tp_nas` (
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  KEY `vid` (`tp_id`)
)
  COMMENT = 'TP nas servers';

CREATE TABLE IF NOT EXISTS `trafic_tarifs` (
  `id` TINYINT(4) NOT NULL DEFAULT '0',
  `descr` VARCHAR(30) DEFAULT NULL,
  `net_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `nets` TEXT,
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `prepaid` INT(11) UNSIGNED DEFAULT '0',
  `in_price` DOUBLE(13, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `out_price` DOUBLE(13, 5) UNSIGNED NOT NULL DEFAULT '0.00000',
  `in_speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `interval_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `rad_pairs` TEXT NOT NULL,
  `out_speed` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `expression` VARCHAR(255) NOT NULL DEFAULT '',
  `burst_limit_dl` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `burst_limit_ul` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `burst_threshold_dl` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `burst_threshold_ul` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `burst_time_dl` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `burst_time_ul` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY `id` (`id`, `interval_id`)
)
  COMMENT = 'Traffic classes';

CREATE TABLE IF NOT EXISTS `traffic_classes` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(25) NOT NULL DEFAULT '',
  `nets` MEDIUMTEXT,
  `comments` TEXT NOT NULL,
  `changed` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'Traffic Classes';

INSERT INTO `traffic_classes` (`id`, `name`, `nets`, `comments`) VALUES (1, 'Global', '0.0.0.0/0', '');

CREATE TABLE IF NOT EXISTS `users` (
  `id` VARCHAR(20) NOT NULL DEFAULT '',
  `activate` DATE NOT NULL DEFAULT '0000-00-00',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  `credit` DOUBLE(10, 2) NOT NULL DEFAULT '0.00',
  `reduction` DOUBLE(6, 2) NOT NULL DEFAULT '0.00',
  `reduction_date` DATE NOT NULL DEFAULT '0000-00-00',
  `registration` DATE DEFAULT '0000-00-00',
  `password` BLOB NOT NULL,
  `uid` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `gid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `company_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `bill_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `ext_bill_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `credit_date` DATE DEFAULT '0000-00-00',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `id` (`domain_id`, `id`),
  KEY `bill_id` (`bill_id`),
  KEY `company_id` (`company_id`)
)
  COMMENT = 'Users list';


CREATE TABLE IF NOT EXISTS `web_users_sessions` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `datetime` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `login` VARCHAR(20) NOT NULL DEFAULT '',
  `remote_addr` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `sid` VARCHAR(32) NOT NULL DEFAULT '',
  `ext_info` VARCHAR(200) NOT NULL DEFAULT '',
  `coordx` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `coordy` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `sid` (`sid`)
)
  COMMENT = 'User Web Sessions';

CREATE TABLE IF NOT EXISTS `users_bruteforce` (
  `login` VARCHAR(20) NOT NULL DEFAULT '',
  `password` BLOB NOT NULL,
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `ip` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `auth_state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  KEY `login` (`login`)
);

CREATE TABLE IF NOT EXISTS `users_nas` (
  `uid` INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `nas_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  KEY `uid` (`uid`)
);

CREATE TABLE IF NOT EXISTS `users_pi` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `fio` VARCHAR(120) NOT NULL DEFAULT '',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `country_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `address_street` VARCHAR(100) NOT NULL DEFAULT '',
  `address_build` VARCHAR(10) NOT NULL DEFAULT '',
  `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `contract_id` VARCHAR(10) NOT NULL DEFAULT '',
  `contract_date` DATE NOT NULL DEFAULT '0000-00-00',
  `contract_sufix` VARCHAR(5) NOT NULL DEFAULT '',
  `pasport_num` VARCHAR(16) NOT NULL DEFAULT '',
  `pasport_date` DATE NOT NULL DEFAULT '0000-00-00',
  `pasport_grant` VARCHAR(100) NOT NULL DEFAULT '',
  `zip` VARCHAR(7) NOT NULL DEFAULT '',
  `city` VARCHAR(20) NOT NULL DEFAULT '',
  `accept_rules` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `location_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  KEY `location_id` (`location_id`)
)
  COMMENT = 'Users personal info';

CREATE TABLE IF NOT EXISTS `users_contact_types`
(
  `id` SMALLINT(6) PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `hidden` TINYINT(1) NOT NULL DEFAULT 0
)
  COMMENT = 'Types of user contacts';

CREATE TABLE IF NOT EXISTS `users_contacts` (
  `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `uid` INT(11) UNSIGNED NOT NULL,
  `type_id` SMALLINT(6),
  `value` VARCHAR(250) NOT NULL,
  `priority` SMALLINT(6) UNSIGNED,
  FOREIGN KEY (`uid`) REFERENCES `users` (`uid`) ON DELETE CASCADE,
  FOREIGN KEY (`type_id`) REFERENCES `users_contact_types` (`id`) ON DELETE CASCADE,
  INDEX `_uid_contact` (`uid`)
)
  COMMENT = 'Main user contacts table';

CREATE TABLE IF NOT EXISTS `sqlcmd_history` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '000000',
  `sql_query` TEXT NOT NULL,
  `db_id` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `aid` (`aid`)
)
  COMMENT = 'Sqlcmd history';

CREATE TABLE IF NOT EXISTS `radtest_history` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `rad_query` TEXT NOT NULL,
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Radtest history';

CREATE TABLE IF NOT EXISTS `help` (
  `function` VARCHAR(20) NOT NULL DEFAULT '',
  `title` VARCHAR(200) NOT NULL DEFAULT '',
  `help` TEXT NOT NULL,
  PRIMARY KEY (`function`),
  UNIQUE KEY `function` (`function`)
);

CREATE TABLE IF NOT EXISTS `streets` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `district_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `second_name` VARCHAR(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_district` (`name`, `district_id`)
)
  COMMENT = 'Locations streets';


CREATE TABLE IF NOT EXISTS `districts` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `country` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
  `zip` VARCHAR(7) NOT NULL DEFAULT '',
  `city` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `coordx` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `coordy` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `zoom` TINYINT(2) NOT NULL DEFAULT '0',
  `domain_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`city`, `name`)
)
  COMMENT = 'Locations districts';

INSERT INTO `districts` (`name`, `comments`) VALUES ('Main District', '');

CREATE TABLE IF NOT EXISTS `builds` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `street_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `number` VARCHAR(10) NOT NULL DEFAULT '',
  `flors` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `entrances` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `added` DATE NOT NULL,
  `map_x` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_x2` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y2` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_x3` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y3` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_x4` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y4` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `coordx` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `coordy` DOUBLE(20, 14) NOT NULL DEFAULT '0',
  `flats` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `contract_id` VARCHAR(12) NOT NULL DEFAULT '',
  `contract_date` DATE NOT NULL DEFAULT '0000-00-00',
  `contract_price` DOUBLE(15, 6) NOT NULL DEFAULT '0.000000',
  `comments` TEXT,
  `public_comments` TEXT,
  `zip` VARCHAR(7) NOT NULL DEFAULT '',
   planned_to_connect tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `street_id` (`street_id`, `number`)
)
  COMMENT = 'Builds';

CREATE TABLE IF NOT EXISTS `service_status` (
  `id` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `name` VARCHAR(40) NOT NULL DEFAULT '',
  `color` VARCHAR(6) NOT NULL DEFAULT '',
  `type` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  COMMENT = 'System service status list';


CREATE TABLE IF NOT EXISTS `location_media` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `location_id` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `comments` VARCHAR(200) NOT NULL DEFAULT '',
  `filename` VARCHAR(250) NOT NULL DEFAULT '',
  `content_size` VARCHAR(30) NOT NULL DEFAULT '',
  `content_type` VARCHAR(250) NOT NULL DEFAULT '',
  `content` LONGBLOB NOT NULL,
  `create_time` DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Location media';

CREATE TABLE IF NOT EXISTS `web_online` (
  `admin` VARCHAR(15) NOT NULL DEFAULT '',
  `ip` VARCHAR(15) NOT NULL DEFAULT '',
  `logtime` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `page_index` INT UNSIGNED NOT NULL DEFAULT 0,
  `sid` VARCHAR(32) NOT NULL DEFAULT '',
  `ext_info` VARCHAR(200) NOT NULL DEFAULT '',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `sip_number` VARCHAR(15) NOT NULL DEFAULT '',
  KEY (`aid`),
  UNIQUE KEY `sid` (`sid`)
)
  COMMENT = 'Online admins';

CREATE TABLE IF NOT EXISTS `reg_wizard` (
  `param` VARCHAR(40) NOT NULL DEFAULT '',
  `value` TEXT NOT NULL,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `module` VARCHAR(40) NOT NULL DEFAULT '',
  `step` TINYINT(2) NOT NULL DEFAULT '0',
  `session_id` VARCHAR(30) NOT NULL DEFAULT '',
  UNIQUE KEY `session_id` (`session_id`, `step`, `param`)
)
  COMMENT = 'Registration wizard temp table';

CREATE TABLE IF NOT EXISTS `users_social_info` (
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `social_network_id` INT(1) NOT NULL DEFAULT 0,
  `name` VARCHAR(120) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `birthday` DATE NOT NULL,
  `gender` VARCHAR(15) NOT NULL DEFAULT '',
  `likes` TEXT,
  `friends_count` INT(5) UNSIGNED NOT NULL DEFAULT 0,
  `locale` VARCHAR(10) NOT NULL DEFAULT '',
  `photo` TEXT,
  UNIQUE KEY `uid_sin` (`uid`, `social_network_id`)
)
  COMMENT = 'Info form social networks.';

INSERT INTO `admins` (`id`, `name`, `regdate`, `password`, `gid`, `aid`, `disable`, `phone`, `web_options`, `comments`, `pasport_date`, `birthday`, `start_work`
) VALUES
  ('abills', 'abills', curdate(), ENCODE('abills', 'test12345678901234567890'), 0, 1, 0, '', '', '', '2001-01-01',
   '2001-01-01', NOW());
INSERT INTO `admins` (`id`, `name`, `regdate`, `password`, `gid`, `aid`, `disable`, `phone`, `web_options`, `comments`, `pasport_date`, `birthday`, `start_work`)
VALUES ('system', 'System user', curdate(), ENCODE(md5(RAND()), 'test12345678901234567890'), 0, 2, 0, '', '', '',
                  '2001-01-01', '2001-01-01', NOW());
INSERT INTO `admins` (`id`, `name`, `regdate`, `password`, `gid`, `aid`, `disable`, `phone`, `web_options`, `comments`, `pasport_date`, `birthday`, `start_work`)
VALUES
  ('users_web', 'Users web portal', curdate(), ENCODE(md5(RAND()), 'test12345678901234567890'), 0, 3, 0, '', '', '',
                '2001-01-01', '2001-01-01', NOW());
INSERT INTO `admin_permits` (`aid`, `section`, `actions`, `module`) VALUES
  (1, 0, 0, ''),
  (1, 0, 1, ''),
  (1, 0, 2, ''),
  (1, 0, 3, ''),
  (1, 0, 4, ''),
  (1, 0, 5, ''),
  (1, 0, 6, ''),
  (1, 0, 7, ''),
  (1, 0, 8, ''),
  (1, 0, 9, ''),
  (1, 0, 10, ''),
  (1, 0, 11, ''),
  (1, 0, 14, ''),
  (1, 0, 16, ''),
  (1, 0, 17, ''),
  (1, 0, 18, ''),
  (1, 0, 19, ''),
  (1, 1, 0, ''),
  (1, 1, 1, ''),
  (1, 1, 2, ''),
  (1, 1, 3, ''),
  (1, 2, 0, ''),
  (1, 2, 1, ''),
  (1, 2, 2, ''),
  (1, 2, 3, ''),
  (1, 3, 0, ''),
  (1, 3, 1, ''),
  (1, 3, 2, ''),
  (1, 3, 3, ''),
  (1, 4, 0, ''),
  (1, 4, 1, ''),
  (1, 4, 2, ''),
  (1, 4, 3, ''),
  (1, 4, 4, ''),
  (1, 5, 0, ''),
  (1, 6, 0, ''),
  (1, 7, 0, ''),
  (1, 8, 0, '');


INSERT INTO `users` (`id`, `activate`, `expire`, `credit`, `reduction`, `registration`, `password`, `uid`, `gid`, `disable`, `company_id`, `bill_id`, `ext_bill_id`, `credit_date`, `domain_id`)
VALUES
  ('test', '0000-00-00', '0000-00-00', 0.00, 0.00, '2009-08-03', ENCODE('123456', 'test12345678901234567890'), 1, 0, 0,
           0, 1, 0, '0000-00-00', 0);

INSERT INTO `users_pi` (`uid`, `fio`, `comments`) VALUES (1, 'Test user', '');

INSERT INTO `bills` VALUES (1, 0.000000, 1, 0, '2009-08-03');

INSERT INTO `tarif_plans` (`id`, `name`, `payment_type`, `module`, `rad_pairs`, `comments`)
VALUES (100, 'Admin', 1, 'Dv', '', '');

INSERT INTO `dv_main`
SET
  `uid` = 1,
  `tp_id` = 100,
  `logins` = 0,
  `registration` = now(),
  `password` = '';

INSERT INTO `admin_actions` VALUES ('LOGIN:test', '2009-08-03 11:42:53', 1534854767, 1, 1, 1, '', 7),
  ('BILL_ID ->1;', '2009-08-03 11:42:53', 1534854767, 1, 1, 2, '', 2),
  ('PASSWORD *->*;', '2009-08-03 11:42:53', 1534854767, 1, 1, 3, '', 2),
  ('ADD PI', '2009-08-03 11:42:53', 1534854767, 1, 1, 4, '', 0),
  ('ACTIVE', '2009-08-03 11:42:53', 1534854767, 1, 1, 5, 'Dv', 1);

INSERT INTO `nas` (`id`, `name`, `nas_identifier`, `descr`, `ip`, `nas_type`, `auth_type`, `mng_host_port`, `mng_user`, `mng_password`, `alive`, `rad_pairs`)
VALUES (1, 'NAS Server', '', 'NAS Server', INET_ATON('127.0.0.1'), 'mpd5', 0, '127.0.0.1:5005', 'admin',
           ENCODE('secretpass', 'test12345678901234567890'), 300, '');
INSERT INTO `ippools` (`id`, `nas`, `ip`, `counts`, `name`, `priority`) VALUES (1, 1, 167772161, 256, 'Main', 0);

INSERT INTO `nas_ippools` (`pool_id`, `nas_id`) VALUES (1, 1);
INSERT INTO `msgs_chapters` (`name`) VALUES ('-');

INSERT INTO `fees_types` (`id`, `name`)
VALUES (1, '$lang{ABON}'), (2, '$lang{FINE}'), (3, '$lang{ACTIVATE}'), (4, '$lang{MONEY_TRANSFER}'),
  (0, '$lang{ONE_TIME}');
UPDATE `fees_types`
SET `id` = 0
WHERE `name` = '$lang{ONE_TIME}';

REPLACE INTO `service_status` (`id`, `name`, `color`, `type`) VALUES (0, '$lang{ENABLE}', '4CAF50', 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`) VALUES (1, '$lang{DISABLE}', 'F44336', 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`) VALUES (2, '$lang{NOT_ACTIVE}', 'FF9800', 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`) VALUES (3, '$lang{HOLD_UP}', '2196F3', 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`)
VALUES (4, '$lang{DISABLE} $lang{NON_PAYMENT}', '607D8B', 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`) VALUES (5, '$lang{ERR_SMALL_DEPOSIT}', '009688', 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`) VALUES (6, '$lang{VIRUS_ALERT}', '9C27B0', 0);
REPLACE INTO `service_status` (`id`, `name`, `color`, `type`) VALUES (7, '$lang{REPAIR}', '9E9E9E', 0);

REPLACE INTO `users_contact_types` (`id`, `name`, `is_default`, `hidden`) VALUES
  (1, 'CELL_PHONE', 0, 0),
  (2, 'PHONE', 1, 0),
  (3, 'Skype', 0, 0),
  (4, 'ICQ', 0, 0),
  (5, 'Viber', 0, 0),
  (6, 'Telegram', 0, 0),
  (7, 'Facebook', 0, 0),
  (8, 'VK', 0, 0),
  (9, 'EMail', 1, 0),
  (10, 'Google push', 0, 1);

CREATE TABLE IF NOT EXISTS `admins_contact_types` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `hidden` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  COMMENT='Types of admin contacts';

REPLACE INTO `admins_contact_types` (`id`, `name`, `is_default`, `hidden`) VALUES
  (1, 'CELL_PHONE', 0, 0),
  (2, 'PHONE', 1, 0),
  (3, 'Skype', 0, 0),
  (4, 'ICQ', 0, 0),
  (5, 'Viber', 0, 0),
  (6, 'Telegram', 0, 0),
  (7, 'Facebook', 0, 0),
  (8, 'VK', 0, 0),
  (9, 'EMail', 1, 0),
  (10, 'Google push', 0, 1);

CREATE TABLE IF NOT EXISTS `admins_contacts` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `aid` int(11) unsigned NOT NULL,
  `type_id` smallint(6) DEFAULT NULL,
  `value` varchar(250) NOT NULL,
  `priority` smallint(6) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `_type_value` (`type_id`,`value`),
  KEY `_aid_contact` (`aid`)
)
  COMMENT='Main admin contacts table';


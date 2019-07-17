CREATE TABLE IF NOT EXISTS `extreceipts` (
  `payments_id` INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `command_id`  INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `receipt_date` VARCHAR(30)        NOT NULL,
  `fdn`         INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `fda`         INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `cancel_id`   INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `status`      TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`payments_id`)
)
  COMMENT = 'External receipts';
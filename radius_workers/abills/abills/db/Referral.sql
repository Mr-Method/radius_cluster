CREATE TABLE IF NOT EXISTS `referral_main` (
  `uid` INT(11) PRIMARY KEY REFERENCES `users` (`uid`)
    ON DELETE CASCADE,
  `referrer` INT(11) NOT NULL REFERENCES `users` (`uid`)
    ON DELETE CASCADE
)
  COMMENT = 'Referral main table stores information about referrers and referrals';
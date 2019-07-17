CREATE TABLE IF NOT EXISTS `expert_question` (
  `id` INT(8) UNSIGNED PRIMARY KEY UNIQUE,
  `question` TEXT,
  `description` TEXT
)
  COMMENT = 'Expert system nodes';

  CREATE TABLE IF NOT EXISTS `expert_answer` (
  `id` INT(8) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `question_id` INT(8) UNSIGNED NOT NULL DEFAULT 0,
  `answer` TEXT
)
  COMMENT = 'Expert system links';
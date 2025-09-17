
CREATE TABLE IF NOT EXISTS `missions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `npc_model` VARCHAR(60) NOT NULL DEFAULT 'a_m_m_business_01',
  `type` ENUM('robable','interactivo') NOT NULL,
  `config` JSON DEFAULT NULL, -- loot, requisitos, recompensas, armas permitidas
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  `heading` FLOAT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabela de usuários do dashboard (não altera as tabelas do BI)
SET NAMES utf8mb4;
USE `auto_stylo_bi`;

-- A senha nunca fica em texto puro: guardamos só o hash SHA-256 (64 caracteres)
CREATE TABLE IF NOT EXISTS `Usuario` (
  `Usuario_ID` INT NOT NULL PRIMARY KEY,
  `login` VARCHAR(50) NOT NULL UNIQUE,
  `senha_hash` CHAR(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Usuário de exemplo: login admin / senha autostylo123
INSERT IGNORE INTO `Usuario` (`Usuario_ID`, `login`, `senha_hash`) VALUES
  (1, 'admin', '7a24dc4ef38f92fdd87915083fc1454b1d3b860f581a8634314d635f3a21087e');

-- Conferência
SELECT `Usuario_ID`, `login` FROM `Usuario`;

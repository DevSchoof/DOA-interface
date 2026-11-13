-- Rode como root no MySQL (MySQL Workbench ou: mysql -u root -p < criar-usuario.sql)
CREATE DATABASE IF NOT EXISTS doa CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER IF NOT EXISTS 'doa'@'%' IDENTIFIED BY 'doa';
GRANT ALL PRIVILEGES ON doa.* TO 'doa'@'%';
FLUSH PRIVILEGES;

-- Dôa API — esquema MySQL 8 (referência / criação manual).
-- Com SPRING_PROFILES_ACTIVE=mysql o Hibernate cria estas tabelas sozinho (ddl-auto=update);
-- este script existe para documentar o modelo e para quem preferir criar o banco à mão
-- (nesse caso rode a API com DDL_AUTO=validate).

CREATE DATABASE IF NOT EXISTS doa CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE doa;

CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL,                 -- DONOR | INSTITUTION | ADMIN
  active BIT NOT NULL,
  created_at DATETIME(6) NOT NULL,
  failed_attempts INT NOT NULL DEFAULT 0,
  locked_until DATETIME(6) NULL,
  fcm_token VARCHAR(500) NULL,
  CONSTRAINT uk_users_email UNIQUE (email)
) ENGINE=InnoDB;

CREATE TABLE food_categories (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(60) NOT NULL,
  description VARCHAR(200) NULL,
  active BIT NOT NULL,
  CONSTRAINT uk_category_name UNIQUE (name)
) ENGINE=InnoDB;

CREATE TABLE donors (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  person_type VARCHAR(20) NOT NULL,          -- PF | PJ
  name VARCHAR(255) NOT NULL,
  document VARCHAR(14) NOT NULL,             -- CPF/CNPJ só dígitos
  phone VARCHAR(11) NOT NULL,
  address VARCHAR(255) NOT NULL,
  city VARCHAR(255) NOT NULL,
  latitude DOUBLE NULL,
  longitude DOUBLE NULL,
  CONSTRAINT uk_donor_user UNIQUE (user_id),
  CONSTRAINT uk_donor_document UNIQUE (document),
  CONSTRAINT fk_donor_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB;

CREATE TABLE institutions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  cnpj VARCHAR(14) NOT NULL,
  address VARCHAR(255) NOT NULL,
  city VARCHAR(255) NOT NULL,
  area_of_activity VARCHAR(255) NOT NULL,
  storage_capacity_kg DOUBLE NOT NULL,
  status VARCHAR(20) NOT NULL,               -- PENDING | APPROVED | REJECTED
  rejection_reason VARCHAR(255) NULL,
  latitude DOUBLE NULL,
  longitude DOUBLE NULL,
  CONSTRAINT uk_inst_user UNIQUE (user_id),
  CONSTRAINT uk_inst_cnpj UNIQUE (cnpj),
  CONSTRAINT fk_inst_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB;

-- N:N  Instituição <-> Categoria de alimento
CREATE TABLE institution_category (
  institution_id BIGINT NOT NULL,
  category_id BIGINT NOT NULL,
  PRIMARY KEY (institution_id, category_id),
  CONSTRAINT fk_ic_inst FOREIGN KEY (institution_id) REFERENCES institutions (id),
  CONSTRAINT fk_ic_cat FOREIGN KEY (category_id) REFERENCES food_categories (id)
) ENGINE=InnoDB;

-- 1:N  Doador -> Doações
CREATE TABLE donations (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  version BIGINT NULL,                       -- bloqueio otimista (evita dupla reserva)
  donor_id BIGINT NOT NULL,
  category_id BIGINT NOT NULL,
  description VARCHAR(120) NOT NULL,
  quantity DOUBLE NOT NULL,
  unit VARCHAR(5) NOT NULL,
  expires_at DATE NOT NULL,
  storage_conditions VARCHAR(255) NULL,
  status VARCHAR(20) NOT NULL,               -- AVAILABLE | RESERVED | DELIVERED | CANCELLED | EXPIRED
  reserved_by_id BIGINT NULL,
  reserved_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL,
  CONSTRAINT fk_don_donor FOREIGN KEY (donor_id) REFERENCES donors (id),
  CONSTRAINT fk_don_cat FOREIGN KEY (category_id) REFERENCES food_categories (id),
  CONSTRAINT fk_don_inst FOREIGN KEY (reserved_by_id) REFERENCES institutions (id),
  INDEX idx_don_status_exp (status, expires_at)
) ENGINE=InnoDB;

-- 1:N  Doação -> Fotos (arquivo guardado no banco)
CREATE TABLE donation_photos (
  id VARCHAR(36) PRIMARY KEY,                -- UUID (URL pública não adivinhável)
  donation_id BIGINT NOT NULL,
  content_type VARCHAR(30) NOT NULL,
  size_bytes BIGINT NOT NULL,
  data LONGBLOB NOT NULL,
  created_at DATETIME(6) NOT NULL,
  CONSTRAINT fk_photo_donation FOREIGN KEY (donation_id) REFERENCES donations (id),
  INDEX idx_photo_donation (donation_id)
) ENGINE=InnoDB;

CREATE TABLE stock_items (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  institution_id BIGINT NOT NULL,
  category_id BIGINT NOT NULL,
  description VARCHAR(120) NOT NULL,
  quantity DOUBLE NOT NULL,
  unit VARCHAR(5) NOT NULL,
  received_at DATETIME(6) NOT NULL,
  expires_at DATE NOT NULL,
  CONSTRAINT fk_stock_inst FOREIGN KEY (institution_id) REFERENCES institutions (id),
  CONSTRAINT fk_stock_cat FOREIGN KEY (category_id) REFERENCES food_categories (id)
) ENGINE=InnoDB;

CREATE TABLE messages (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  donation_id BIGINT NOT NULL,
  sender_id BIGINT NOT NULL,
  content VARCHAR(1000) NOT NULL,
  sent_at DATETIME(6) NOT NULL,
  CONSTRAINT fk_msg_donation FOREIGN KEY (donation_id) REFERENCES donations (id),
  CONSTRAINT fk_msg_sender FOREIGN KEY (sender_id) REFERENCES users (id)
) ENGINE=InnoDB;

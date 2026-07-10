-- =============================================
-- NutriScan Database Schema
-- Jalankan: mysql -u root -p < schema.sql
-- =============================================

CREATE DATABASE IF NOT EXISTS nutriscan_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nutriscan_db;

-- ----------------------------------------
-- Tabel: users
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  email       VARCHAR(150) NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,
  role        ENUM('user', 'admin') DEFAULT 'user',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ----------------------------------------
-- Tabel: health_profiles
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS health_profiles (
  id                   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id              INT UNSIGNED NOT NULL UNIQUE,
  weight_kg            DECIMAL(5,2) NOT NULL,
  height_cm            DECIMAL(5,2) NOT NULL,
  age                  TINYINT UNSIGNED NOT NULL,
  gender               ENUM('male', 'female') NOT NULL,
  activity_level       ENUM('sedentary', 'light', 'moderate', 'active', 'very_active') DEFAULT 'sedentary',
  medical_condition    SET('none', 'diabetes', 'hypertension', 'cholesterol', 'kidney') DEFAULT 'none',
  bmi                  DECIMAL(5,2),
  bmr                  DECIMAL(7,2),
  daily_calorie_target DECIMAL(7,2),
  updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ----------------------------------------
-- Tabel: foods (database nutrisi lokal)
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS foods (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(150) NOT NULL,
  name_en         VARCHAR(150),
  yolo_label      VARCHAR(100) NOT NULL UNIQUE COMMENT 'Label output dari model YOLO',
  calories        DECIMAL(7,2) NOT NULL COMMENT 'per 100g',
  carbohydrates   DECIMAL(6,2) NOT NULL COMMENT 'gram per 100g',
  protein         DECIMAL(6,2) NOT NULL COMMENT 'gram per 100g',
  fat             DECIMAL(6,2) NOT NULL COMMENT 'gram per 100g',
  sugar           DECIMAL(6,2) DEFAULT 0 COMMENT 'gram per 100g',
  sodium          DECIMAL(7,2) DEFAULT 0 COMMENT 'mg per 100g',
  fiber           DECIMAL(6,2) DEFAULT 0 COMMENT 'gram per 100g',
  serving_size_g  DECIMAL(6,2) DEFAULT 100,
  category        VARCHAR(80),
  image_url       VARCHAR(255),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ----------------------------------------
-- Tabel: scan_history
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS scan_history (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id         INT UNSIGNED NOT NULL,
  food_id         INT UNSIGNED,
  detected_label  VARCHAR(100) NOT NULL,
  confidence_pct  DECIMAL(5,2),
  image_path      VARCHAR(255),
  warning_level   ENUM('green', 'yellow', 'red') DEFAULT 'green',
  warning_reason  TEXT,
  scanned_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE SET NULL
);

-- ----------------------------------------
-- Tabel: meal_logs
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS meal_logs (
  id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id            INT UNSIGNED NOT NULL,
  food_id            INT UNSIGNED NOT NULL,
  meal_type          ENUM('breakfast', 'lunch', 'dinner', 'snack') NOT NULL,
  portion_g          DECIMAL(7,2) DEFAULT 100,
  calories_consumed  DECIMAL(7,2),
  carbs_consumed     DECIMAL(6,2),
  protein_consumed   DECIMAL(6,2),
  fat_consumed       DECIMAL(6,2),
  sugar_consumed     DECIMAL(6,2),
  logged_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (food_id) REFERENCES foods(id)
);

-- ----------------------------------------
-- Tabel: reminders
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS reminders (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED NOT NULL,
  type        ENUM('medicine', 'water') NOT NULL,
  label       VARCHAR(100) NOT NULL COMMENT 'Misal: Metformin 500mg',
  time        TIME NOT NULL,
  days        SET('mon','tue','wed','thu','fri','sat','sun') DEFAULT 'mon,tue,wed,thu,fri,sat,sun',
  is_active   TINYINT(1) DEFAULT 1,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ----------------------------------------
-- Tabel: model_accuracy_logs (untuk skripsi)
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS model_accuracy_logs (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  scan_id         INT UNSIGNED,
  detected_label  VARCHAR(100) COMMENT 'NULL = objek tidak terdeteksi (false negative)',
  actual_label    VARCHAR(100) COMMENT 'Label sebenarnya (ground truth)',
  confidence_pct  DECIMAL(5,2),
  is_correct      TINYINT(1) COMMENT '1=benar, 0=salah (kompat lama)',
  verdict         ENUM('correct','wrong','missed') COMMENT 'Hasil verifikasi multi-object: benar/salah deteksi/tidak terdeteksi',
  image_path      VARCHAR(255) COMMENT 'Untuk mengelompokkan objek per foto (multi-object)',
  logged_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (scan_id) REFERENCES scan_history(id) ON DELETE SET NULL
);

-- =============================================
-- Seed Data: Contoh makanan Indonesia
-- =============================================
INSERT INTO foods (name, name_en, yolo_label, calories, carbohydrates, protein, fat, sugar, sodium, fiber, serving_size_g, category) VALUES
('Nasi Putih',       'White Rice',          'white_rice',        130, 28.2, 2.7, 0.3,  0.1,  1.0, 0.4, 100, 'Karbohidrat'),
('Sate Ayam',        'Chicken Satay',        'chicken_satay',     250, 10.5, 25.0, 12.0, 3.5, 380, 0.5, 100, 'Protein'),
('Rendang Sapi',     'Beef Rendang',         'beef_rendang',      390, 8.0,  28.0, 28.0, 2.0, 450, 1.5, 100, 'Protein'),
('Gado-Gado',        'Gado-Gado',            'gado_gado',         180, 15.0, 8.0,  10.0, 4.0, 320, 3.5, 150, 'Campuran'),
('Mie Goreng',       'Fried Noodles',        'mie_goreng',        340, 48.0, 10.0, 12.0, 3.0, 800, 2.0, 200, 'Karbohidrat'),
('Tempe Goreng',     'Fried Tempeh',         'tempe_goreng',      280, 18.0, 17.0, 16.0, 1.5, 200, 3.0, 100, 'Protein'),
('Tahu Goreng',      'Fried Tofu',           'tahu_goreng',       160, 5.0,  11.0, 11.0, 0.5, 150, 0.5, 100, 'Protein'),
('Pisang',           'Banana',               'banana',            89,  23.0, 1.1,  0.3,  12.0,  1.0, 2.6, 100, 'Buah'),
('Nasi Goreng',      'Fried Rice',           'nasi_goreng',       260, 38.0, 8.0,  9.0,  2.0, 620, 1.5, 200, 'Karbohidrat'),
('Ayam Goreng',      'Fried Chicken',        'ayam_goreng',       320, 8.0,  28.0, 19.0, 0.5, 520, 0.2, 100, 'Protein'),
('Soto Ayam',        'Chicken Soto',         'soto_ayam',         150, 12.0, 14.0, 5.0,  1.5, 780, 1.0, 250, 'Sup'),
('Bakso',            'Meatball Soup',        'bakso',             200, 15.0, 14.0, 9.0,  0.5, 850, 0.5, 250, 'Sup'),
('Ikan Bakar',       'Grilled Fish',         'ikan_bakar',        180, 0.5,  28.0, 7.0,  0.5, 350, 0.0, 100, 'Protein'),
('Kangkung Tumis',   'Stir Fried Kangkung',  'kangkung_tumis',    80,  6.0,  4.0,  5.0,  1.0, 280, 2.5, 100, 'Sayuran'),
('Martabak Manis',   'Sweet Martabak',       'martabak_manis',    380, 58.0, 9.0,  13.0, 28.0,280, 1.0, 100, 'Camilan');

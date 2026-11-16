// database/migrate.js
// Menyamakan database LAMA dengan schema.sql terbaru tanpa menghapus data.
// Aman dijalankan berulang kali (idempotent).
// Jalankan: npm run db:migrate
require('dotenv').config();
const mysql = require('mysql2/promise');

const COLUMNS = [
  ['users',           'onboarding_completed',     'TINYINT(1) NOT NULL DEFAULT 0'],
  ['health_profiles', 'blood_sugar_fasting',      'DECIMAL(6,2) NULL'],
  ['health_profiles', 'blood_pressure_systolic',  'SMALLINT UNSIGNED NULL'],
  ['health_profiles', 'blood_pressure_diastolic', 'SMALLINT UNSIGNED NULL'],
  ['model_accuracy_logs', 'verdict',    "ENUM('correct','wrong','missed') NULL"],
  ['model_accuracy_logs', 'image_path', 'VARCHAR(255) NULL'],
];

const RECOMMENDATIONS_TABLE = `
CREATE TABLE IF NOT EXISTS recommendations (
  id                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id               INT UNSIGNED NOT NULL UNIQUE,
  allowed_foods         TEXT,
  avoided_foods         TEXT,
  meal_pattern          VARCHAR(255),
  daily_calories        DECIMAL(7,2),
  max_sugar_g           DECIMAL(6,2),
  max_sodium_mg         DECIMAL(7,2),
  max_carbs_g           DECIMAL(6,2),
  min_protein_g         DECIMAL(6,2),
  max_fat_g             DECIMAL(6,2),
  exercise_type         VARCHAR(150),
  exercise_duration_min SMALLINT UNSIGNED,
  exercise_freq         VARCHAR(100),
  exercise_notes        TEXT,
  fired_rules           TEXT,
  generated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
)`;

(async () => {
  const dbName = process.env.DB_NAME || 'nutriscan_db';
  const conn = await mysql.createConnection({
    host:     process.env.DB_HOST     || 'localhost',
    port:     process.env.DB_PORT     || 3306,
    user:     process.env.DB_USER     || 'root',
    password: process.env.DB_PASSWORD || '',
    database: dbName,
  });

  for (const [table, column, def] of COLUMNS) {
    const [rows] = await conn.query(
      `SELECT 1 FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
      [dbName, table, column]
    );
    if (rows.length === 0) {
      await conn.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${def}`);
      console.log(`+ ${table}.${column}`);
    } else {
      console.log(`= ${table}.${column} (sudah ada)`);
    }
  }

  await conn.query(RECOMMENDATIONS_TABLE);
  console.log('= tabel recommendations siap');

  // User lama yang sudah punya profil kesehatan dianggap sudah onboarding
  const [res] = await conn.query(
    `UPDATE users u JOIN health_profiles hp ON hp.user_id = u.id
     SET u.onboarding_completed = 1 WHERE u.onboarding_completed = 0`
  );
  if (res.affectedRows) console.log(`~ ${res.affectedRows} user ditandai onboarding_completed`);

  await conn.end();
  console.log('✅ Migrasi selesai');
})().catch((err) => {
  console.error('❌ Migrasi gagal:', err.message || err);
  process.exit(1);
});

const db = require('../config/db');

// GET /api/admin/foods
const getAllFoods = async (req, res) => {
  const search = req.query.search || '';
  const [rows] = await db.query(
    `SELECT * FROM foods WHERE name LIKE ? OR yolo_label LIKE ? ORDER BY name ASC`,
    [`%${search}%`, `%${search}%`]
  );
  return res.json({ success: true, data: rows });
};

// POST /api/admin/foods
const createFood = async (req, res) => {
  const { name, name_en, yolo_label, calories, carbohydrates, protein, fat, sugar, sodium, fiber, serving_size_g, category } = req.body;
  if (!name || !yolo_label || !calories) {
    return res.status(400).json({ success: false, message: 'name, yolo_label, calories wajib diisi' });
  }
  try {
    const [result] = await db.query(
      `INSERT INTO foods (name, name_en, yolo_label, calories, carbohydrates, protein, fat, sugar, sodium, fiber, serving_size_g, category)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [name, name_en, yolo_label, calories, carbohydrates||0, protein||0, fat||0, sugar||0, sodium||0, fiber||0, serving_size_g||100, category]
    );
    return res.status(201).json({ success: true, message: 'Makanan ditambahkan', data: { id: result.insertId } });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'yolo_label sudah ada' });
    }
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// PUT /api/admin/foods/:id
const updateFood = async (req, res) => {
  const { id } = req.params;
  const fields  = req.body;
  const allowed = ['name','name_en','yolo_label','calories','carbohydrates','protein','fat','sugar','sodium','fiber','serving_size_g','category'];
  const sets    = Object.keys(fields).filter(k => allowed.includes(k));
  if (sets.length === 0) return res.status(400).json({ success: false, message: 'Tidak ada field valid' });

  const sql = `UPDATE foods SET ${sets.map(k => `${k} = ?`).join(', ')}, updated_at = NOW() WHERE id = ?`;
  const vals = [...sets.map(k => fields[k]), id];
  await db.query(sql, vals);
  return res.json({ success: true, message: 'Data makanan diperbarui' });
};

// DELETE /api/admin/foods/:id
const deleteFood = async (req, res) => {
  await db.query('DELETE FROM foods WHERE id = ?', [req.params.id]);
  return res.json({ success: true, message: 'Makanan dihapus' });
};

// GET /api/admin/accuracy-stats  (untuk lampiran skripsi)
const getAccuracyStats = async (req, res) => {
  const [overall] = await db.query(
    `SELECT
       COUNT(*)                                                AS total_scans,
       SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END)       AS correct,
       SUM(CASE WHEN is_correct = 0 THEN 1 ELSE 0 END)       AS incorrect,
       ROUND(AVG(confidence_pct), 2)                         AS avg_confidence,
       ROUND(
         SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN is_correct IS NOT NULL THEN 1 ELSE 0 END), 0) * 100
       , 2)                                                   AS accuracy_pct
     FROM model_accuracy_logs`
  );

  const [perLabel] = await db.query(
    `SELECT
       detected_label,
       COUNT(*)                                                AS total,
       SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END)       AS correct,
       ROUND(AVG(confidence_pct), 2)                         AS avg_confidence
     FROM model_accuracy_logs
     GROUP BY detected_label
     ORDER BY total DESC`
  );

  return res.json({
    success: true,
    data: {
      overall:   overall[0],
      per_label: perLabel,
    },
  });
};

module.exports = { getAllFoods, createFood, updateFood, deleteFood, getAccuracyStats };

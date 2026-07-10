const bcrypt = require('bcryptjs');
const db = require('../config/db');

// GET /api/admin/foods?search=&category=
const getAllFoods = async (req, res) => {
  try {
    const search   = req.query.search || '';
    const category = req.query.category || '';

    let sql  = `SELECT * FROM foods WHERE (name LIKE ? OR yolo_label LIKE ?)`;
    const params = [`%${search}%`, `%${search}%`];

    if (category) {
      sql += ` AND category = ?`;
      params.push(category);
    }
    sql += ` ORDER BY name ASC`;

    const [rows] = await db.query(sql, params);
    return res.json({ success: true, data: rows });
  } catch (err) {
    console.error('getAllFoods error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/admin/food-categories  (untuk dropdown filter)
const getFoodCategories = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT DISTINCT category FROM foods WHERE category IS NOT NULL AND category <> '' ORDER BY category ASC`
    );
    return res.json({ success: true, data: rows.map((r) => r.category) });
  } catch (err) {
    console.error('getFoodCategories error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
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
  try {
    const { id } = req.params;
    const fields  = req.body;
    const allowed = ['name','name_en','yolo_label','calories','carbohydrates','protein','fat','sugar','sodium','fiber','serving_size_g','category'];
    const sets    = Object.keys(fields).filter(k => allowed.includes(k));
    if (sets.length === 0) return res.status(400).json({ success: false, message: 'Tidak ada field valid' });

    const sql = `UPDATE foods SET ${sets.map(k => `${k} = ?`).join(', ')}, updated_at = NOW() WHERE id = ?`;
    const vals = [...sets.map(k => fields[k]), id];
    await db.query(sql, vals);
    return res.json({ success: true, message: 'Data makanan diperbarui' });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ success: false, message: 'yolo_label sudah ada' });
    }
    console.error('updateFood error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// DELETE /api/admin/foods/:id?force=true
const deleteFood = async (req, res) => {
  const { id } = req.params;
  const force  = req.query.force === 'true';
  try {
    if (force) {
      // Hapus paksa: bersihkan referensi dulu (meal_logs) lalu makanannya
      await db.query('DELETE FROM meal_logs WHERE food_id = ?', [id]);
      // scan_history.food_id sudah ON DELETE SET NULL, jadi aman
    }
    await db.query('DELETE FROM foods WHERE id = ?', [id]);
    return res.json({ success: true, message: 'Makanan dihapus' });
  } catch (err) {
    // FK constraint: makanan masih dipakai di meal_logs
    if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.errno === 1451) {
      const [[used]] = await db.query('SELECT COUNT(*) c FROM meal_logs WHERE food_id = ?', [id]);
      return res.status(409).json({
        success: false,
        code: 'IN_USE',
        message: `Makanan ini dipakai di ${used.c} catatan makan (meal log). Hapus paksa untuk menghapus beserta catatannya.`,
      });
    }
    console.error('deleteFood error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/admin/accuracy-stats  (untuk lampiran skripsi)
// Model 3 kategori: Benar (TP) / Salah deteksi (FP) / Tidak terdeteksi (FN)
const getAccuracyStats = async (req, res) => {
  try {
    const [overall] = await db.query(
      `SELECT
         SUM(CASE WHEN verdict = 'correct' THEN 1 ELSE 0 END)   AS correct,
         SUM(CASE WHEN verdict = 'wrong'   THEN 1 ELSE 0 END)   AS wrong,
         SUM(CASE WHEN verdict = 'missed'  THEN 1 ELSE 0 END)   AS missed,
         SUM(CASE WHEN verdict IS NOT NULL THEN 1 ELSE 0 END)   AS total_verified,
         ROUND(AVG(CASE WHEN detected_label IS NOT NULL THEN confidence_pct END), 2) AS avg_confidence,
         ROUND(
           SUM(CASE WHEN verdict = 'correct' THEN 1 ELSE 0 END)
           / NULLIF(SUM(CASE WHEN verdict IS NOT NULL THEN 1 ELSE 0 END), 0) * 100
         , 2)                                                   AS accuracy_pct
       FROM model_accuracy_logs`
    );

    // Per label ground-truth (untuk grafik agregat: makanan mana yang sering salah/terlewat)
    const [perLabel] = await db.query(
      `SELECT
         COALESCE(actual_label, detected_label)                 AS label,
         SUM(CASE WHEN verdict = 'correct' THEN 1 ELSE 0 END)   AS correct,
         SUM(CASE WHEN verdict = 'wrong'   THEN 1 ELSE 0 END)   AS wrong,
         SUM(CASE WHEN verdict = 'missed'  THEN 1 ELSE 0 END)   AS missed,
         SUM(CASE WHEN verdict IS NOT NULL THEN 1 ELSE 0 END)   AS total,
         ROUND(AVG(CASE WHEN detected_label IS NOT NULL THEN confidence_pct END), 2) AS avg_confidence
       FROM model_accuracy_logs
       WHERE verdict IS NOT NULL AND COALESCE(actual_label, detected_label) IS NOT NULL
       GROUP BY COALESCE(actual_label, detected_label)
       ORDER BY total DESC`
    );

    // Per FOTO/scan (1 baris = 1 foto, gabungan objek di dalamnya)
    const [perScan] = await db.query(
      `SELECT
         COALESCE(image_path, CONCAT('#', id))                  AS scan_key,
         MIN(image_path)                                        AS image_path,
         GROUP_CONCAT(DISTINCT COALESCE(actual_label, detected_label)
                      ORDER BY COALESCE(actual_label, detected_label) SEPARATOR ' + ') AS labels,
         SUM(CASE WHEN verdict = 'correct' THEN 1 ELSE 0 END)   AS correct,
         SUM(CASE WHEN verdict = 'wrong'   THEN 1 ELSE 0 END)   AS wrong,
         SUM(CASE WHEN verdict = 'missed'  THEN 1 ELSE 0 END)   AS missed,
         COUNT(*)                                               AS total,
         MIN(logged_at)                                         AS scanned_at,
         ROUND(AVG(CASE WHEN detected_label IS NOT NULL THEN confidence_pct END), 2) AS avg_confidence
       FROM model_accuracy_logs
       WHERE verdict IS NOT NULL
       GROUP BY COALESCE(image_path, CONCAT('#', id))
       ORDER BY scanned_at DESC`
    );

    return res.json({
      success: true,
      data: {
        overall:   overall[0],
        per_label: perLabel,
        per_scan:  perScan,
      },
    });
  } catch (err) {
    console.error('getAccuracyStats error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/admin/stats  (ringkasan untuk dashboard)
const getDashboardStats = async (req, res) => {
  try {
    const [[users]]  = await db.query(
      `SELECT
         COUNT(*)                                          AS total_users,
         SUM(CASE WHEN role = 'admin' THEN 1 ELSE 0 END)  AS total_admins
       FROM users`
    );
    const [[foods]]     = await db.query('SELECT COUNT(*) AS total_foods FROM foods');
    const [[scans]]     = await db.query('SELECT COUNT(*) AS total_scans FROM scan_history');
    const [[mealLogs]]  = await db.query('SELECT COUNT(*) AS total_meal_logs FROM meal_logs');

    // Akurasi = Benar / (Benar + Salah + Tidak terdeteksi)
    const [[accuracy]] = await db.query(
      `SELECT
         ROUND(
           SUM(CASE WHEN verdict = 'correct' THEN 1 ELSE 0 END)
           / NULLIF(SUM(CASE WHEN verdict IS NOT NULL THEN 1 ELSE 0 END), 0) * 100
         , 2) AS accuracy_pct
       FROM model_accuracy_logs`
    );

    // Makanan paling sering terdeteksi
    const [topFoods] = await db.query(
      `SELECT detected_label, COUNT(*) AS total
       FROM scan_history
       GROUP BY detected_label
       ORDER BY total DESC
       LIMIT 5`
    );

    // Scan 7 hari terakhir (grafik tren)
    const [scanTrend] = await db.query(
      `SELECT DATE(scanned_at) AS date, COUNT(*) AS total
       FROM scan_history
       WHERE scanned_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE(scanned_at)
       ORDER BY date ASC`
    );

    return res.json({
      success: true,
      data: {
        total_users:     users.total_users,
        total_admins:    users.total_admins,
        total_foods:     foods.total_foods,
        total_scans:     scans.total_scans,
        total_meal_logs: mealLogs.total_meal_logs,
        accuracy_pct:    accuracy.accuracy_pct,
        top_foods:       topFoods,
        scan_trend:      scanTrend,
      },
    });
  } catch (err) {
    console.error('getDashboardStats error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/admin/users
const getAllUsers = async (req, res) => {
  try {
    const search = req.query.search || '';
    const [rows] = await db.query(
      `SELECT id, name, email, role, created_at
       FROM users
       WHERE name LIKE ? OR email LIKE ?
       ORDER BY created_at DESC`,
      [`%${search}%`, `%${search}%`]
    );
    return res.json({ success: true, data: rows });
  } catch (err) {
    console.error('getAllUsers error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// PUT /api/admin/users/:id/role
const updateUserRole = async (req, res) => {
  const { id }   = req.params;
  const { role } = req.body;

  if (!['user', 'admin'].includes(role)) {
    return res.status(400).json({ success: false, message: "role harus 'user' atau 'admin'" });
  }
  // Cegah admin menurunkan role dirinya sendiri (bisa mengunci diri)
  if (Number(id) === req.user.id && role !== 'admin') {
    return res.status(400).json({ success: false, message: 'Tidak bisa menurunkan role akun sendiri' });
  }

  try {
    const [result] = await db.query('UPDATE users SET role = ? WHERE id = ?', [role, id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }
    return res.json({ success: true, message: 'Role user diperbarui' });
  } catch (err) {
    console.error('updateUserRole error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// DELETE /api/admin/users/:id
const deleteUser = async (req, res) => {
  const { id } = req.params;

  // Cegah admin menghapus akun sendiri
  if (Number(id) === req.user.id) {
    return res.status(400).json({ success: false, message: 'Tidak bisa menghapus akun sendiri' });
  }

  try {
    const [result] = await db.query('DELETE FROM users WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }
    return res.json({ success: true, message: 'User dihapus' });
  } catch (err) {
    console.error('deleteUser error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/admin/scans?status=all|verified|unverified&search=&limit=&offset=
// Dipakai Recent Activity (dashboard) & halaman Verifikasi Akurasi
const getScans = async (req, res) => {
  try {
    const status = req.query.status || 'all';
    const search = req.query.search || '';
    const limit  = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = parseInt(req.query.offset) || 0;

    let where = `WHERE (sh.detected_label LIKE ? OR u.name LIKE ?)`;
    const params = [`%${search}%`, `%${search}%`];

    if (status === 'verified')   where += ` AND mal.verdict IS NOT NULL`;
    if (status === 'unverified') where += ` AND mal.verdict IS NULL`;

    const [rows] = await db.query(
      `SELECT
         sh.id            AS scan_id,
         sh.detected_label,
         sh.confidence_pct,
         sh.warning_level,
         sh.image_path,
         sh.scanned_at,
         u.name           AS user_name,
         f.name           AS food_name,
         mal.verdict,
         mal.actual_label
       FROM scan_history sh
       LEFT JOIN users u              ON sh.user_id = u.id
       LEFT JOIN foods f              ON sh.food_id = f.id
       LEFT JOIN model_accuracy_logs mal ON mal.scan_id = sh.id
       ${where}
       ORDER BY sh.scanned_at DESC
       LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    const [[count]] = await db.query(
      `SELECT COUNT(*) AS total
       FROM scan_history sh
       LEFT JOIN users u ON sh.user_id = u.id
       LEFT JOIN model_accuracy_logs mal ON mal.scan_id = sh.id
       ${where}`,
      params
    );

    return res.json({ success: true, data: rows, total: count.total });
  } catch (err) {
    console.error('getScans error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/admin/scan-groups?status=all|verified|unverified&limit=&offset=
// Kelompokkan objek deteksi per FOTO (image_path) untuk verifikasi multi-object
const getScanGroups = async (req, res) => {
  try {
    const status = req.query.status || 'unverified';
    const limit  = Math.min(parseInt(req.query.limit) || 12, 50);
    const offset = parseInt(req.query.offset) || 0;

    // Ambil daftar foto (image_path) beserta status verifikasinya
    let having = '';
    if (status === 'unverified') having = 'HAVING unverified_count > 0';
    if (status === 'verified')   having = 'HAVING unverified_count = 0';

    const [groups] = await db.query(
      `SELECT
         image_path,
         MIN(logged_at)                                          AS scanned_at,
         COUNT(*)                                                AS total_objects,
         SUM(CASE WHEN verdict IS NULL THEN 1 ELSE 0 END)        AS unverified_count
       FROM model_accuracy_logs
       WHERE image_path IS NOT NULL
       GROUP BY image_path
       ${having}
       ORDER BY scanned_at DESC
       LIMIT ? OFFSET ?`,
      [limit, offset]
    );

    // Hitung total grup (untuk pagination)
    const [[count]] = await db.query(
      `SELECT COUNT(*) AS total FROM (
         SELECT image_path,
           SUM(CASE WHEN verdict IS NULL THEN 1 ELSE 0 END) AS unverified_count
         FROM model_accuracy_logs
         WHERE image_path IS NOT NULL
         GROUP BY image_path
         ${having}
       ) t`
    );

    // Ambil objek untuk tiap foto
    for (const g of groups) {
      const [objs] = await db.query(
        `SELECT mal.id AS log_id, mal.detected_label, mal.confidence_pct,
                mal.verdict, mal.actual_label, u.name AS user_name
         FROM model_accuracy_logs mal
         LEFT JOIN scan_history sh ON mal.scan_id = sh.id
         LEFT JOIN users u ON sh.user_id = u.id
         WHERE mal.image_path = ?
         ORDER BY (mal.detected_label IS NULL), mal.confidence_pct DESC`,
        [g.image_path]
      );
      g.objects = objs;
      g.user_name = objs.find((o) => o.user_name)?.user_name || null;
    }

    return res.json({ success: true, data: groups, total: count.total });
  } catch (err) {
    console.error('getScanGroups error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// PUT /api/admin/accuracy/:logId/verdict  { verdict: 'correct'|'wrong', actual_label? }
const setVerdict = async (req, res) => {
  const { logId } = req.params;
  const { verdict, actual_label } = req.body;

  if (!['correct', 'wrong'].includes(verdict)) {
    return res.status(400).json({ success: false, message: "verdict harus 'correct' atau 'wrong'" });
  }
  try {
    // correct: label sebenarnya = label terdeteksi. wrong: pakai actual_label pilihan admin.
    const [[row]] = await db.query('SELECT detected_label FROM model_accuracy_logs WHERE id = ?', [logId]);
    if (!row) return res.status(404).json({ success: false, message: 'Objek tidak ditemukan' });

    const truth = verdict === 'correct' ? row.detected_label : (actual_label || null);
    await db.query(
      `UPDATE model_accuracy_logs
       SET verdict = ?, actual_label = ?, is_correct = ?
       WHERE id = ?`,
      [verdict, truth, verdict === 'correct' ? 1 : 0, logId]
    );
    return res.json({ success: true, message: 'Verifikasi disimpan' });
  } catch (err) {
    console.error('setVerdict error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// POST /api/admin/accuracy/missed  { image_path, actual_label }
// Tambah objek yang ADA di foto tapi TIDAK terdeteksi model (false negative)
const addMissed = async (req, res) => {
  const { image_path, actual_label } = req.body;
  if (!image_path || !actual_label) {
    return res.status(400).json({ success: false, message: 'image_path & actual_label wajib diisi' });
  }
  try {
    const [result] = await db.query(
      `INSERT INTO model_accuracy_logs (scan_id, detected_label, actual_label, confidence_pct, is_correct, verdict, image_path)
       VALUES (NULL, NULL, ?, NULL, 0, 'missed', ?)`,
      [actual_label, image_path]
    );
    return res.status(201).json({ success: true, message: 'Objek tak terdeteksi ditambahkan', data: { id: result.insertId } });
  } catch (err) {
    console.error('addMissed error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// DELETE /api/admin/accuracy/:logId  (hapus entri 'missed' yang salah tambah)
const deleteAccuracyLog = async (req, res) => {
  try {
    // Hanya izinkan menghapus entri 'missed' (bukan objek hasil deteksi asli)
    const [result] = await db.query(
      `DELETE FROM model_accuracy_logs WHERE id = ? AND verdict = 'missed' AND scan_id IS NULL`,
      [req.params.logId]
    );
    if (result.affectedRows === 0) {
      return res.status(400).json({ success: false, message: 'Hanya objek "tidak terdeteksi" yang bisa dihapus' });
    }
    return res.json({ success: true, message: 'Objek dihapus' });
  } catch (err) {
    console.error('deleteAccuracyLog error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// POST /api/admin/users  (buat akun admin baru)
const createAdminUser = async (req, res) => {
  const { name, email, password, role } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ success: false, message: 'Nama, email, dan password wajib diisi' });
  }
  const newRole = role === 'admin' ? 'admin' : 'user';

  try {
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ success: false, message: 'Email sudah terdaftar' });
    }

    const hashed = await bcrypt.hash(password, 12);
    const [result] = await db.query(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, hashed, newRole]
    );
    return res.status(201).json({ success: true, message: 'Akun dibuat', data: { id: result.insertId } });
  } catch (err) {
    console.error('createAdminUser error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = {
  getAllFoods, getFoodCategories, createFood, updateFood, deleteFood, getAccuracyStats,
  getDashboardStats, getAllUsers, updateUserRole, deleteUser,
  getScans, getScanGroups, setVerdict, addMissed, deleteAccuracyLog, createAdminUser,
};

const db = require('../config/db');

// POST /api/meal-log
const addLog = async (req, res) => {
  const { food_id, meal_type, portion_g } = req.body;
  if (!food_id || !meal_type) {
    return res.status(400).json({ success: false, message: 'food_id dan meal_type wajib diisi' });
  }
  if (!['breakfast', 'lunch', 'dinner', 'snack'].includes(meal_type)) {
    return res.status(400).json({ success: false, message: 'meal_type tidak valid' });
  }
  const portion = portion_g === undefined || portion_g === null || portion_g === ''
    ? 100
    : parseFloat(portion_g);
  if (!Number.isFinite(portion) || portion <= 0 || portion > 5000) {
    return res.status(400).json({ success: false, message: 'Porsi harus antara 1 dan 5000 gram' });
  }

  try {
    const [foods] = await db.query('SELECT * FROM foods WHERE id = ?', [food_id]);
    if (foods.length === 0) {
      return res.status(404).json({ success: false, message: 'Makanan tidak ditemukan' });
    }

    const food   = foods[0];
    const factor = portion / 100;

    const [result] = await db.query(
      `INSERT INTO meal_logs
         (user_id, food_id, meal_type, portion_g, calories_consumed,
          carbs_consumed, protein_consumed, fat_consumed, sugar_consumed)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id, food_id, meal_type, portion,
        (food.calories      * factor).toFixed(2),
        (food.carbohydrates * factor).toFixed(2),
        (food.protein       * factor).toFixed(2),
        (food.fat           * factor).toFixed(2),
        (food.sugar         * factor).toFixed(2),
      ]
    );

    return res.status(201).json({
      success: true,
      message: 'Log makan berhasil ditambahkan',
      data: { id: result.insertId },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/meal-log/today
const getTodayLog = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT ml.*, f.name AS food_name, f.category, f.image_url
       FROM meal_logs ml
       JOIN foods f ON ml.food_id = f.id
       WHERE ml.user_id = ? AND DATE(ml.logged_at) = CURDATE()
       ORDER BY ml.logged_at ASC`,
      [req.user.id]
    );

    // Hitung total hari ini
    const total = rows.reduce((acc, r) => ({
      calories: acc.calories + parseFloat(r.calories_consumed),
      carbs:    acc.carbs    + parseFloat(r.carbs_consumed),
      protein:  acc.protein  + parseFloat(r.protein_consumed),
      fat:      acc.fat      + parseFloat(r.fat_consumed),
      sugar:    acc.sugar    + parseFloat(r.sugar_consumed),
    }), { calories: 0, carbs: 0, protein: 0, fat: 0, sugar: 0 });

    // Ambil target kalori dari profil
    const [profiles] = await db.query(
      'SELECT daily_calorie_target FROM health_profiles WHERE user_id = ?',
      [req.user.id]
    );
    const target = profiles.length > 0 ? parseFloat(profiles[0].daily_calorie_target) : 2000;

    // Kelompokkan per meal_type
    const grouped = { breakfast: [], lunch: [], dinner: [], snack: [] };
    rows.forEach(r => { if (grouped[r.meal_type]) grouped[r.meal_type].push(r); });

    return res.json({
      success: true,
      data: {
        logs:            grouped,
        total_today:     total,
        calorie_target:  target,
        calorie_remaining: parseFloat((target - total.calories).toFixed(1)),
        calorie_pct:     Math.min(100, Math.round((total.calories / target) * 100)),
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// DELETE /api/meal-log/:id
const deleteLog = async (req, res) => {
  try {
    const [result] = await db.query(
      'DELETE FROM meal_logs WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Log tidak ditemukan' });
    }
    return res.json({ success: true, message: 'Log dihapus' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { addLog, getTodayLog, deleteLog };

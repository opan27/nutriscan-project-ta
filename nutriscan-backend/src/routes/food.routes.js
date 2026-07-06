const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { authMiddleware } = require('../middleware/auth.middleware');

// GET /api/food/search?q=sate
router.get('/search', authMiddleware, async (req, res) => {
  const q = req.query.q || '';
  const [rows] = await db.query(
    `SELECT id, name, name_en, calories, carbohydrates, protein, fat, sugar, sodium, category, serving_size_g
     FROM foods WHERE name LIKE ? OR name_en LIKE ? LIMIT 20`,
    [`%${q}%`, `%${q}%`]
  );
  return res.json({ success: true, data: rows });
});

// GET /api/food/:id
router.get('/:id', authMiddleware, async (req, res) => {
  const [rows] = await db.query('SELECT * FROM foods WHERE id = ?', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ success: false, message: 'Makanan tidak ditemukan' });
  return res.json({ success: true, data: rows[0] });
});

module.exports = router;

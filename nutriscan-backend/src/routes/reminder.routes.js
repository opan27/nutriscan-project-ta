const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { authMiddleware } = require('../middleware/auth.middleware');

// GET /api/reminder
router.get('/', authMiddleware, async (req, res) => {
  const [rows] = await db.query(
    'SELECT * FROM reminders WHERE user_id = ? ORDER BY time ASC',
    [req.user.id]
  );
  return res.json({ success: true, data: rows });
});

// POST /api/reminder
router.post('/', authMiddleware, async (req, res) => {
  const { type, label, time, days } = req.body;
  if (!type || !label || !time) {
    return res.status(400).json({ success: false, message: 'type, label, dan time wajib diisi' });
  }
  const [result] = await db.query(
    'INSERT INTO reminders (user_id, type, label, time, days) VALUES (?, ?, ?, ?, ?)',
    [req.user.id, type, label, time, days || 'mon,tue,wed,thu,fri,sat,sun']
  );
  return res.status(201).json({ success: true, message: 'Pengingat ditambahkan', data: { id: result.insertId } });
});

// PUT /api/reminder/:id/toggle
router.put('/:id/toggle', authMiddleware, async (req, res) => {
  await db.query(
    'UPDATE reminders SET is_active = NOT is_active WHERE id = ? AND user_id = ?',
    [req.params.id, req.user.id]
  );
  return res.json({ success: true, message: 'Status pengingat diperbarui' });
});

// DELETE /api/reminder/:id
router.delete('/:id', authMiddleware, async (req, res) => {
  await db.query('DELETE FROM reminders WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
  return res.json({ success: true, message: 'Pengingat dihapus' });
});

module.exports = router;

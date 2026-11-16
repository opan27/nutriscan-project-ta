const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { authMiddleware } = require('../middleware/auth.middleware');

const VALID_TYPES = ['medicine', 'water'];
const VALID_DAYS  = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const TIME_RE     = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

// GET /api/reminder
router.get('/', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM reminders WHERE user_id = ? ORDER BY time ASC',
      [req.user.id]
    );
    return res.json({ success: true, data: rows });
  } catch (err) {
    console.error('getReminders error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/reminder
router.post('/', authMiddleware, async (req, res) => {
  const { type, label, time, days } = req.body;
  if (!type || !label || !time) {
    return res.status(400).json({ success: false, message: 'type, label, dan time wajib diisi' });
  }
  if (!VALID_TYPES.includes(type)) {
    return res.status(400).json({ success: false, message: "type harus 'medicine' atau 'water'" });
  }
  if (!TIME_RE.test(String(time))) {
    return res.status(400).json({ success: false, message: 'Format time harus HH:MM' });
  }
  const dayList = days ? String(days).split(',').map((d) => d.trim()) : VALID_DAYS;
  if (dayList.some((d) => !VALID_DAYS.includes(d))) {
    return res.status(400).json({ success: false, message: 'Format days tidak valid' });
  }

  try {
    const [result] = await db.query(
      'INSERT INTO reminders (user_id, type, label, time, days) VALUES (?, ?, ?, ?, ?)',
      [req.user.id, type, String(label).slice(0, 100), time, dayList.join(',')]
    );
    return res.status(201).json({ success: true, message: 'Pengingat ditambahkan', data: { id: result.insertId } });
  } catch (err) {
    console.error('createReminder error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// PUT /api/reminder/:id/toggle
router.put('/:id/toggle', authMiddleware, async (req, res) => {
  try {
    const [result] = await db.query(
      'UPDATE reminders SET is_active = NOT is_active WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Pengingat tidak ditemukan' });
    }
    return res.json({ success: true, message: 'Status pengingat diperbarui' });
  } catch (err) {
    console.error('toggleReminder error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// DELETE /api/reminder/:id
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const [result] = await db.query(
      'DELETE FROM reminders WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Pengingat tidak ditemukan' });
    }
    return res.json({ success: true, message: 'Pengingat dihapus' });
  } catch (err) {
    console.error('deleteReminder error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

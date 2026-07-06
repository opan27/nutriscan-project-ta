const express = require('express');
const cors    = require('cors');
require('dotenv').config();

const app = express();

// ─── Middleware Global ───────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static folder untuk gambar hasil scan
app.use('/uploads', express.static('uploads'));

// ─── Routes ─────────────────────────────────────────────────────────────────
app.use('/api/auth',      require('./routes/auth.routes'));
app.use('/api/scan',      require('./routes/scan.routes'));
app.use('/api/food',      require('./routes/food.routes'));
app.use('/api/meal-log',  require('./routes/mealLog.routes'));
app.use('/api/health',    require('./routes/health.routes'));
app.use('/api/analytics', require('./routes/analytics.routes'));
app.use('/api/reminder',  require('./routes/reminder.routes'));
app.use('/api/admin',     require('./routes/admin.routes'));

// ─── Health Check ────────────────────────────────────────────────────────────
app.get('/api/ping', (req, res) => {
  res.json({ success: true, message: 'NutriScan API is running 🥗', timestamp: new Date() });
});

// ─── 404 Handler ─────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} tidak ditemukan` });
});

// ─── Global Error Handler ────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ success: false, message: 'Ukuran file terlalu besar (maks 10MB)' });
  }
  res.status(500).json({ success: false, message: err.message || 'Internal server error' });
});

module.exports = app;

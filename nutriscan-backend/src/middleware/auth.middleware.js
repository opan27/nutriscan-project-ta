const jwt = require('jsonwebtoken');
const db  = require('../config/db');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Token tidak ditemukan' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, email, role }
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Token tidak valid atau sudah expired' });
  }
};

// Role dicek ulang ke database: role di JWT bisa basi (berlaku 7 hari),
// sehingga admin yang diturunkan/dihapus langsung kehilangan akses.
const adminMiddleware = async (req, res, next) => {
  try {
    const [rows] = await db.query('SELECT role FROM users WHERE id = ?', [req.user?.id]);
    if (rows.length === 0 || rows[0].role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Akses ditolak: hanya admin' });
    }
    next();
  } catch (err) {
    console.error('adminMiddleware error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { authMiddleware, adminMiddleware };

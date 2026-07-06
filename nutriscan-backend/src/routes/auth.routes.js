// ============================================
// routes/auth.routes.js
// ============================================
const express = require('express');
const router  = express.Router();
const { register, login, getMe } = require('../controllers/authController');
const { authMiddleware }         = require('../middleware/auth.middleware');

router.post('/register', register);
router.post('/login',    login);
router.get('/me',        authMiddleware, getMe);

module.exports = router;

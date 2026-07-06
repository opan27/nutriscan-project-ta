const express = require('express');
const router  = express.Router();
const { getWeeklyInsight, exportPDF } = require('../controllers/analyticsController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.get('/weekly',     authMiddleware, getWeeklyInsight);
router.get('/export-pdf', authMiddleware, exportPDF);

module.exports = router;

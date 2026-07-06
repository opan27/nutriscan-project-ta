const express = require('express');
const router  = express.Router();
const { addLog, getTodayLog, deleteLog } = require('../controllers/mealLogController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.post('/',         authMiddleware, addLog);
router.get('/today',     authMiddleware, getTodayLog);
router.delete('/:id',    authMiddleware, deleteLog);

module.exports = router;

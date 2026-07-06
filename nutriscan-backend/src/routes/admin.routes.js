const express = require('express');
const router  = express.Router();
const { getAllFoods, createFood, updateFood, deleteFood, getAccuracyStats } = require('../controllers/adminController');
const { authMiddleware, adminMiddleware } = require('../middleware/auth.middleware');

// Semua route admin butuh JWT + role admin
router.use(authMiddleware, adminMiddleware);

router.get('/foods',            getAllFoods);
router.post('/foods',           createFood);
router.put('/foods/:id',        updateFood);
router.delete('/foods/:id',     deleteFood);
router.get('/accuracy-stats',   getAccuracyStats);

module.exports = router;

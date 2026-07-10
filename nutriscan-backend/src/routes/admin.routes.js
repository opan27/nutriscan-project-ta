const express = require('express');
const router  = express.Router();
const {
  getAllFoods, getFoodCategories, createFood, updateFood, deleteFood, getAccuracyStats,
  getDashboardStats, getAllUsers, updateUserRole, deleteUser,
  getScans, getScanGroups, setVerdict, addMissed, deleteAccuracyLog, createAdminUser,
} = require('../controllers/adminController');
const { authMiddleware, adminMiddleware } = require('../middleware/auth.middleware');

// Semua route admin butuh JWT + role admin
router.use(authMiddleware, adminMiddleware);

// Dashboard
router.get('/stats',            getDashboardStats);

// Manajemen makanan
router.get('/foods',            getAllFoods);
router.get('/food-categories',  getFoodCategories);
router.post('/foods',           createFood);
router.put('/foods/:id',        updateFood);
router.delete('/foods/:id',     deleteFood);

// Statistik akurasi model
router.get('/accuracy-stats',   getAccuracyStats);

// Scan & verifikasi (Recent Activity + Verifikasi multi-object)
router.get('/scans',                 getScans);        // per objek (recent activity)
router.get('/scan-groups',           getScanGroups);   // dikelompokkan per foto
router.put('/accuracy/:logId/verdict', setVerdict);    // tandai benar/salah per objek
router.post('/accuracy/missed',      addMissed);       // tambah objek tak terdeteksi
router.delete('/accuracy/:logId',    deleteAccuracyLog);

// Manajemen user
router.get('/users',            getAllUsers);
router.post('/users',           createAdminUser);
router.put('/users/:id/role',   updateUserRole);
router.delete('/users/:id',     deleteUser);

module.exports = router;

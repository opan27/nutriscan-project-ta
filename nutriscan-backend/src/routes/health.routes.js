// src/routes/health.routes.js (UPDATED)
const express = require('express');
const router  = express.Router();
const { upsertProfile, getProfile, getRecommendation, getOnboardingStatus } = require('../controllers/healthController');
const { authMiddleware } = require('../middleware/auth.middleware');

router.post('/profile',           authMiddleware, upsertProfile);
router.get('/profile',            authMiddleware, getProfile);
router.get('/recommendation',     authMiddleware, getRecommendation);
router.get('/onboarding-status',  authMiddleware, getOnboardingStatus);

module.exports = router;
const express = require('express');
const router  = express.Router();
const { uploadAndScan, submitFeedback, getScanHistory } = require('../controllers/scanController');
const { authMiddleware } = require('../middleware/auth.middleware');
const upload             = require('../middleware/upload.middleware');

router.post('/',                    authMiddleware, upload.single('image'), uploadAndScan);
router.post('/:scanId/feedback',    authMiddleware, submitFeedback);
router.get('/history',              authMiddleware, getScanHistory);

module.exports = router;
